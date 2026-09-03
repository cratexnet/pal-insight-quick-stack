local P = require("palworld")
local Notifications = require("notifications")

local QuickStack = {}

local NEXT_SLICE_MS = 16
local RPC_INTERVAL_MS = 34
local COMPLETION_POLL_MS = 120
local COMPLETION_TIMEOUT_SECONDS = 3
local JOB_TIMEOUT_SECONDS = 20
local INVENTORY_SLOTS_PER_SLICE = 64
local METADATA_ITEMS_PER_SLICE = 64
local BASE_OBJECTS_PER_SLICE = 256
local CONTAINERS_PER_SLICE = 16
local CONTAINER_SLOTS_PER_SLICE = 256
local RECHECK_SLOTS_PER_SLICE = 256
local PLAN_OPERATIONS_PER_SLICE = 64
local GUILD_REPLICATION_POLL_MS = 100
local GUILD_REPLICATION_MAX_POLLS = 15
local PERFORMANCE_PHASE_ORDER = {
    "resolve", "inventory", "metadata", "base", "guild", "containers",
    "plan", "request", "recheck", "completion",
}
local PERFORMANCE_DETAIL_ORDER = {
    "recheck_scan", "recheck_validate", "rpc_prepare", "rpc_call",
}

local state = {
    config = nil,
    log = nil,
    debugLog = nil,
    generation = 0,
    job = nil,
    requestSequence = 0,
}

local isValid = P.isValid
local arrayLength = P.arrayLength
local arrayValue = P.arrayValue
local guidKey = P.guidKey
local containerGuid = P.containerGuid
local slotGuid = P.slotGuid
local slotStaticId = P.slotStaticId
local enumValue = P.enumValue
local isEggId = P.isEggId

local RELIC_ITEM_IDS = {
    WorldTreeRelic_01 = true,
    WorldTreeRelic_02 = true,
    WorldTreeRelic_03 = true,
    WorldTreeRelic_04 = true,
    WorldTreeRelic_05 = true,
}
local WORLD_TREE_HOLY_WATER_ID = "WorldTreeHolyWater"

local function isRelicId(staticId)
    return RELIC_ITEM_IDS[staticId] == true
end

local function log(message)
    state.log(message)
end

local function debugLog(message)
    state.debugLog(message)
end

local function snapshotJobConfig(config)
    config = type(config) == "table" and config or {}
    return {
        ResultDisplay = config.ResultDisplay,
        IncludeExcludedItems = config.IncludeExcludedItems == true,
        IncludeNewItems = config.IncludeNewItems == true,
        IncludeGuildChest = config.IncludeGuildChest == true,
        PalEggRouting = config.PalEggRouting,
        RelicRouting = config.RelicRouting,
        WorldTreeHolyWaterMinimum = math.max(1, math.min(100,
            math.floor(tonumber(config.WorldTreeHolyWaterMinimum) or 10))),
    }
end

local function addItemCount(list, byId, id, staticId, amount)
    amount = math.floor(tonumber(amount) or 0)
    if id == nil or staticId == nil or amount <= 0 then return end
    local entry = byId[id]
    if entry == nil then
        entry = { id = id, staticId = staticId, num = 0 }
        byId[id] = entry
        list[#list + 1] = entry
    end
    entry.num = entry.num + amount
end

local function notificationDetails(job)
    local moved = {}
    local movedById = {}
    local movedTotal = 0
    if job.completionConfirmed then
        for _, item in ipairs(job.items or {}) do
            local amount = job.submittedByItem ~= nil
                and job.submittedByItem[item] or nil
            if amount ~= nil and amount > 0 then
                addItemCount(moved, movedById,
                    item.id, item.staticId, amount)
                movedTotal = movedTotal + amount
            end
        end
    end
    return {
        moved = moved,
        movedTotal = movedTotal,
        excluded = job.excludedItems or {},
        excludedTotal = job.excludedTotal or 0,
        full = job.fullItems or {},
        fullTotal = job.fullTotal or 0,
        performanceCapture = job.performance ~= nil,
    }
end

local function elapsedMilliseconds(startedAt)
    return math.max(0, (os.clock() - startedAt) * 1000)
end

local function beginPerformanceDetail(job)
    return job.performance ~= nil and os.clock() or nil
end

local function recordPerformanceDetail(job, name, startedAt)
    local performance = job.performance
    if performance == nil or startedAt == nil then return end
    local duration = elapsedMilliseconds(startedAt)
    local detail = performance.details[name]
    if detail == nil then
        detail = { calls = 0, totalMs = 0, maxMs = 0 }
        performance.details[name] = detail
    end
    detail.calls = detail.calls + 1
    detail.totalMs = detail.totalMs + duration
    detail.maxMs = math.max(detail.maxMs, duration)
end

local function beginPerformanceSlice(job, phase)
    local performance = job.performance
    if performance == nil then return end
    performance.activeSlice = {
        phase = tostring(phase or "unknown"),
        startedAt = os.clock(),
    }
end

local function recordPerformanceSlice(job)
    local performance = job.performance
    local active = performance ~= nil and performance.activeSlice or nil
    if active == nil then return end
    performance.activeSlice = nil
    local duration = elapsedMilliseconds(active.startedAt)
    local phase = performance.phases[active.phase]
    if phase == nil then
        phase = { slices = 0, totalMs = 0, maxMs = 0 }
        performance.phases[active.phase] = phase
    end
    phase.slices = phase.slices + 1
    phase.totalMs = phase.totalMs + duration
    phase.maxMs = math.max(phase.maxMs, duration)
    performance.slices = performance.slices + 1
    if duration > performance.maxSliceMs then
        performance.maxSliceMs = duration
        performance.maxSlicePhase = active.phase
    end
end

local function logPerformanceSummary(job, succeeded)
    local performance = job.performance
    if performance == nil then return end
    local parts = {
        "perf_capture",
        "generation=" .. tostring(job.generation or 0),
        "result=" .. (succeeded and "success" or "stopped"),
        string.format("total_ms=%.3f", elapsedMilliseconds(performance.startedAt)),
        "slices=" .. tostring(performance.slices),
        string.format("max_slice_ms=%.3f", performance.maxSliceMs),
        "max_phase=" .. tostring(performance.maxSlicePhase or "none"),
        string.format("notify_start_ms=%.3f", performance.notificationStartMs or 0),
        string.format("notify_finish_ms=%.3f", performance.notificationFinishMs or 0),
        "inventory_slots=" .. tostring(job.inventorySlotCount or 0),
        "eligible_items=" .. tostring(job.items ~= nil and #job.items or 0),
        "unique_items=" .. tostring(job.uniqueItems ~= nil and #job.uniqueItems or 0),
        "base_objects=" .. tostring(job.repCount or 0),
        "containers=" .. tostring(performance.containers or 0),
        "container_slots=" .. tostring(performance.containerSlots or 0),
        "requests=" .. tostring(job.requests ~= nil and #job.requests or 0),
        "submitted_requests=" .. tostring(job.submittedRequests or 0),
        "destination_reuses=" .. tostring(performance.destinationReuses or 0),
    }
    for _, phaseName in ipairs(PERFORMANCE_PHASE_ORDER) do
        local phase = performance.phases[phaseName]
        if phase ~= nil then
            parts[#parts + 1] = string.format("phase_%s=%d,%.3f,%.3f",
                phaseName, phase.slices, phase.totalMs, phase.maxMs)
        end
    end
    for _, detailName in ipairs(PERFORMANCE_DETAIL_ORDER) do
        local detail = performance.details[detailName]
        if detail ~= nil then
            parts[#parts + 1] = string.format("detail_%s=%d,%.3f,%.3f",
                detailName, detail.calls, detail.totalMs, detail.maxMs)
        end
    end
    log(table.concat(parts, "|"))
end

local finishJob

local function identityMatches(job)
    return state.job == job and P.identityMatches(job)
end

local function scheduleJobStep(job, delayMs, step, phase)
    if state.job ~= job or type(step) ~= "function" then return false end
    local scheduled = type(ExecuteInGameThreadWithDelay) == "function"
        and pcall(ExecuteInGameThreadWithDelay,
            delayMs or NEXT_SLICE_MS, function()
        if state.job ~= job then return end
        if os.time() - job.startedAt > JOB_TIMEOUT_SECONDS then
            finishJob(job, false, "job timed out")
            return
        end
        beginPerformanceSlice(job, phase)
        local ok, errorMessage = pcall(step, job)
        if not ok then
            finishJob(job, false, errorMessage)
        else
            recordPerformanceSlice(job)
        end
    end)
    if not scheduled then finishJob(job, false, "cannot schedule game-thread step") end
    return scheduled == true
end

finishJob = function(job, succeeded, message)
    if state.job ~= job then return end
    recordPerformanceSlice(job)
    for _, concrete in ipairs(job.guildReplicationModels or {}) do
        P.stopGuildChestReplication(concrete)
    end
    local outcome = "stopped"
    if succeeded then
        if job.completionConfirmed then
            outcome = "complete"
        elseif (job.submittedItems or 0) > 0 then
            outcome = "submitted"
        else
            outcome = "noop"
        end
    end
    local detailedResultAvailable = job.detailedResultRequested == true
    state.job = nil
    local notificationStartedAt = job.performance ~= nil and os.clock() or nil
    pcall(Notifications.finished,
        job.controller,
        job.notificationToken,
        outcome,
        job.submittedRequests or 0,
        job.submittedItems or 0,
        notificationDetails(job),
        detailedResultAvailable)
    if job.performance ~= nil then
        job.performance.notificationFinishMs =
            elapsedMilliseconds(notificationStartedAt)
        logPerformanceSummary(job, succeeded)
    end
    if succeeded then
        debugLog(message or "job complete")
    else
        log("quick stack stopped: " .. tostring(message or "unknown error"))
    end
end

local function resolveJobRoots(job)
    if not identityMatches(job) then return false, "local player or base changed" end

    local inventory, commonContainer, commonGuid, inventoryError =
        P.resolveCommonContainer(job.playerState)
    if inventory == nil then return false, inventoryError end
    local exclusions, exclusionError = P.resolveExclusions(job.playerState)
    if exclusions == nil then return false, exclusionError end

    local utility = P.utility()
    if utility == nil then return false, "PalUtility CDO is unavailable" end
    local itemManager
    local mapObjectManager
    local gameSetting
    local networkItem
    local repItems
    local rootsOk = pcall(function()
        itemManager = utility:GetItemIDManager(job.controller)
        mapObjectManager = utility:GetMapObjectManager(job.controller)
        gameSetting = utility:GetGameSetting(job.controller)
        networkItem = job.controller.Transmitter.Item
        repItems = job.base.MapObjectCollection
            .MapObjectInstanceIdRepInfoArray.Items
    end)
    if not rootsOk or not isValid(itemManager) or not isValid(mapObjectManager)
        or not isValid(gameSetting) or not isValid(networkItem) then
        return false, "required current-build manager route is unavailable"
    end
    local repCount = arrayLength(repItems)
    if repCount == nil then return false, "current-base object list is unreadable" end

    local categories, categoryError = P.readCategories(gameSetting)
    if categories == nil then return false, categoryError end
    local slotArray
    local slotsOk = pcall(function() slotArray = commonContainer.ItemSlotArray end)
    local slotCount = slotsOk and arrayLength(slotArray) or nil
    if slotCount == nil then return false, "common inventory slots are unreadable" end

    job.commonKey = guidKey(commonGuid)
    job.exclusions = exclusions
    job.itemManager = itemManager
    job.mapObjectManager = mapObjectManager
    job.categories = categories
    job.repItems = repItems
    job.repCount = repCount
    job.inventorySlots = slotArray
    job.inventorySlotCount = slotCount
    job.inventorySlotIndex = 1
    job.items = {}
    job.itemsById = {}
    job.uniqueItems = {}
    job.uniqueById = {}
    job.excludedItems = {}
    job.excludedById = {}
    job.excludedTotal = 0
    job.fullItems = {}
    job.fullById = {}
    job.fullTotal = 0
    if job.config.IncludeGuildChest then
        local guildContext, guildError = P.resolveGuildChestContext(job)
        job.guildContext = guildContext
        if guildContext == nil then
            debugLog("Guild Chest routing unavailable: " .. tostring(guildError))
        end
    end
    return true, nil
end

local startBaseSnapshot

local function scanMetadataSlice(job)
    if not identityMatches(job) then
        finishJob(job, false, "local player or base changed")
        return
    end
    local stop = math.min(job.metadataIndex + METADATA_ITEMS_PER_SLICE - 1,
        #job.uniqueItems)
    for index = job.metadataIndex, stop do
        local unique = job.uniqueItems[index]
        local data
        local ok = pcall(function()
            data = job.itemManager:GetStaticItemData(unique.staticId)
        end)
        if not ok or not isValid(data) then
            finishJob(job, false, "item metadata is unavailable for " .. unique.id)
            return
        end
        local typeA
        local typeB
        local maxStack
        local fieldsOk = pcall(function()
            typeA = enumValue(data.TypeA)
            typeB = enumValue(data.TypeB)
            maxStack = tonumber(data.MaxStackCount)
        end)
        if not fieldsOk or typeA == nil or typeB == nil
            or maxStack == nil or maxStack < 1 then
            finishJob(job, false, "item metadata is incomplete for " .. unique.id)
            return
        end
        local metadata = {
            typeA = typeA,
            typeB = typeB,
            maxStack = math.floor(maxStack),
        }
        metadata.category = P.itemCategory(job.categories, metadata)
        if metadata.category == nil then
            finishJob(job, false, "item category is unavailable for " .. unique.id)
            return
        end
        job.metadata[unique.id] = metadata
    end
    job.metadataIndex = stop + 1
    if job.metadataIndex <= #job.uniqueItems then
        scheduleJobStep(job, NEXT_SLICE_MS, scanMetadataSlice, "metadata")
        return
    end
    startBaseSnapshot(job)
end

local function beginMetadata(job)
    if #job.items == 0 then
        finishJob(job, true, "no eligible common-inventory items")
        return
    end
    job.metadata = {}
    job.metadataIndex = 1
    scheduleJobStep(job, NEXT_SLICE_MS, scanMetadataSlice, "metadata")
end

local function scanInventorySlice(job)
    if not identityMatches(job) then
        finishJob(job, false, "local player or base changed")
        return
    end
    local stop = math.min(job.inventorySlotIndex + INVENTORY_SLOTS_PER_SLICE - 1,
        job.inventorySlotCount)
    for index = job.inventorySlotIndex, stop do
        local slot, readable = arrayValue(job.inventorySlots, index)
        if not readable or not isValid(slot) then
            finishJob(job, false, "common inventory slot is unreadable")
            return
        end
        local slotParts, slotKey = slotGuid(slot)
        if slotParts == nil or slotKey ~= job.commonKey then
            finishJob(job, false, "common inventory slot identity changed")
            return
        end
        local staticId, rawStaticId = slotStaticId(slot)
        if staticId == nil then
            finishJob(job, false, "common inventory item id is unreadable")
            return
        end
        if staticId ~= "None" then
            local stackCount
            local stackOk = pcall(function() stackCount = tonumber(slot.StackCount) end)
            if not stackOk or stackCount == nil or stackCount < 1 then
                finishJob(job, false, "common inventory item state is incomplete")
                return
            end
            stackCount = math.floor(stackCount)
            local ignoredByUser = job.exclusions[staticId] == true
            local isEgg = isEggId(staticId)
            local isRelic = isRelicId(staticId)
            local excludedByUser = ignoredByUser
                and not job.config.IncludeExcludedItems
            local manualPlacement =
                (isEgg and job.config.PalEggRouting == "ManualPlacement")
                or (isRelic
                    and job.config.RelicRouting == "ManualPlacement")
            if excludedByUser then
                addItemCount(job.excludedItems, job.excludedById,
                    staticId, rawStaticId, stackCount)
                job.excludedTotal = job.excludedTotal + stackCount
            end
            if not excludedByUser and not manualPlacement then
                local slotIndex
                local slotOk = pcall(function() slotIndex = tonumber(slot.SlotIndex) end)
                if not slotOk or slotIndex == nil then
                    finishJob(job, false, "common inventory slot index is unreadable")
                    return
                end
                local item = {
                    slot = slot,
                    arrayIndex = index,
                    slotIndex = math.floor(slotIndex),
                    slotId = {
                        ContainerId = { ID = slotParts },
                        SlotIndex = math.floor(slotIndex),
                    },
                    id = staticId,
                    staticId = rawStaticId,
                    num = stackCount,
                    isEgg = isEgg,
                    isRelic = isRelic,
                    isHolyWater = staticId == WORLD_TREE_HOLY_WATER_ID,
                }
                job.items[#job.items + 1] = item
                local itemsById = job.itemsById[staticId]
                if itemsById == nil then
                    itemsById = {}
                    job.itemsById[staticId] = itemsById
                end
                itemsById[#itemsById + 1] = item
                if job.uniqueById[staticId] == nil then
                    local unique = {
                        id = staticId,
                        staticId = rawStaticId,
                        item = item,
                    }
                    job.uniqueById[staticId] = unique
                    job.uniqueItems[#job.uniqueItems + 1] = unique
                end
            end
        end
    end
    job.inventorySlotIndex = stop + 1
    if job.inventorySlotIndex <= job.inventorySlotCount then
        scheduleJobStep(job, NEXT_SLICE_MS, scanInventorySlice, "inventory")
        return
    end
    beginMetadata(job)
end

local scanContainerCandidatesSlice
local beginPlanning

local function indexContainer(job, entry)
    if job.performance ~= nil then
        job.performance.containers = job.performance.containers + 1
        job.performance.containerSlots =
            job.performance.containerSlots + entry.slotCount
    end
    if entry.isIncubator then
        if entry.free > 0 then job.incubators[#job.incubators + 1] = entry end
        return
    end
    if entry.isRecyclerBoost then
        job.recyclerBoosts[#job.recyclerBoosts + 1] = entry
        return
    end
    if entry.isRecycler then
        job.recyclers[#job.recyclers + 1] = entry
        for itemId in pairs(entry.permission.itemIds) do
            for _, item in ipairs(job.itemsById[itemId] or {}) do
                item.isRelic = true
            end
        end
        return
    end

    for itemId in pairs(entry.contains) do
        local unique = job.uniqueById[itemId]
        if unique ~= nil
            and P.destinationAllows(entry, unique.item, job.metadata[itemId]) then
            job.compatibleContainedItems[itemId] = true
        end
        if job.metadata[itemId] ~= nil
            and ((entry.stackRoom[itemId] or 0) > 0 or entry.free > 0) then
            local list = job.containersByContainedItem[itemId]
            if list == nil then
                list = {}
                job.containersByContainedItem[itemId] = list
            end
            list[#list + 1] = entry
        end
    end
    if job.config.IncludeNewItems then
        if not entry.permission.restricted then
            for _, category in ipairs(job.categories) do
                if not entry.filterOff[category.name] then
                    job.compatibleAcceptedCategories[category.name] = true
                end
            end
        else
            local visited = {}
            local function markUnique(unique)
                if unique == nil or visited[unique.id] then return end
                visited[unique.id] = true
                if P.destinationAllows(
                    entry, unique.item, job.metadata[unique.id]) then
                    job.compatibleAcceptedItems[unique.id] = true
                end
            end
            for itemId in pairs(entry.permission.itemIds) do
                markUnique(job.uniqueById[itemId])
            end
            for typeA in pairs(entry.permission.typeA) do
                for _, unique in ipairs(job.uniqueItemsByTypeA[typeA] or {}) do
                    markUnique(unique)
                end
            end
            for typeB in pairs(entry.permission.typeB) do
                for _, unique in ipairs(job.uniqueItemsByTypeB[typeB] or {}) do
                    markUnique(unique)
                end
            end
        end
    end
    if entry.free > 0 and job.config.IncludeNewItems then
        for _, category in ipairs(job.categories) do
            if not entry.filterOff[category.name] then
                local list = job.containersByAcceptedCategory[category.name]
                if list == nil then
                    list = {}
                    job.containersByAcceptedCategory[category.name] = list
                end
                list[#list + 1] = entry
            end
        end
    end
end

local function skipCurrentContainer(job, reason)
    debugLog("skipping destination: " .. tostring(reason))
    job.currentContainer = nil
    job.containerCandidateIndex = job.containerCandidateIndex + 1
end

local function prepareContainerEntry(job, candidate)
    if not isValid(candidate.model) or not isValid(candidate.concrete)
        or not isValid(candidate.container) then
        return nil, "destination object became invalid"
    end
    local containerGuidParts, containerKey = containerGuid(candidate.container)
    if containerGuidParts == nil or containerKey == nil
        or containerKey == P.ZERO_GUID then
        return nil, "destination container id is unavailable"
    end
    local slots
    local slotsOk = pcall(function() slots = candidate.container.ItemSlotArray end)
    local slotCount = slotsOk and arrayLength(slots) or nil
    if slotCount == nil then return nil, "destination slots are unreadable" end
    local filterOff = {}
    local permission = {
        typeA = {},
        typeB = {},
        itemIds = {},
        restricted = false,
    }
    if candidate.kind == "storage" or candidate.kind == "guild_storage" then
        local filterError
        filterOff, filterError = P.readFilterOff(candidate.container)
        if filterOff == nil then return nil, filterError end
    end
    if candidate.kind == "storage" or candidate.kind == "recycler"
        or candidate.kind == "guild_storage" then
        local permissionError
        permission, permissionError = P.readPermission(candidate.container)
        if permission == nil then return nil, permissionError end
    end

    local modelAddress = P.objectAddress(candidate.model)
    local concreteAddress = P.objectAddress(candidate.concrete)
    if modelAddress == nil or concreteAddress == nil then
        return nil, "destination model identity is unavailable"
    end

    return {
        kind = candidate.kind,
        isStorage = candidate.kind == "storage" or candidate.kind == "guild_storage",
        isGuildStorage = candidate.kind == "guild_storage",
        isIncubator = candidate.kind == "incubator",
        isRecycler = candidate.kind == "recycler",
        isRecyclerBoost = candidate.kind == "recycler_boost",
        boostItemId = candidate.kind == "recycler_boost"
            and WORLD_TREE_HOLY_WATER_ID or nil,
        instanceId = candidate.instanceId,
        model = candidate.model,
        modelAddress = modelAddress,
        concrete = candidate.concrete,
        concreteAddress = concreteAddress,
        container = candidate.container,
        containerId = { ID = containerGuidParts },
        containerKey = containerKey,
        slots = slots,
        slotCount = slotCount,
        slotIndex = 1,
        filterOff = filterOff,
        permission = permission,
        free = 0,
        contains = {},
        itemCounts = {},
        stackRoom = {},
    }, nil
end

scanContainerCandidatesSlice = function(job)
    if not identityMatches(job) then
        finishJob(job, false, "local player or base changed")
        return
    end

    local containersProcessed = 0
    local slotsProcessed = 0
    -- Share one bounded slot budget across several small containers so normal
    -- bases do not pay one scheduled callback per chest.
    while containersProcessed < CONTAINERS_PER_SLICE
        and slotsProcessed < CONTAINER_SLOTS_PER_SLICE do
        if job.currentContainer == nil then
            if job.containerCandidateIndex > #job.containerCandidates then
                beginPlanning(job)
                return
            end
            local candidate = job.containerCandidates[job.containerCandidateIndex]
            local entry, entryError = prepareContainerEntry(job, candidate)
            containersProcessed = containersProcessed + 1
            if entry == nil then
                skipCurrentContainer(job, entryError)
            else
                job.currentContainer = entry
            end
        end

        local entry = job.currentContainer
        if entry ~= nil then
            if not isValid(entry.container) then
                skipCurrentContainer(job, "container became invalid")
            else
                local first = entry.slotIndex
                local remainingSlots = CONTAINER_SLOTS_PER_SLICE - slotsProcessed
                local stop = math.min(first + remainingSlots - 1, entry.slotCount)
                local invalidReason
                for index = first, stop do
                    local slot, readable = arrayValue(entry.slots, index)
                    if not readable or not isValid(slot) then
                        invalidReason = "container slot is unreadable"
                        break
                    end
                    local staticId = slotStaticId(slot)
                    if staticId == nil then
                        invalidReason = "container item id is unreadable"
                        break
                    end
                    if staticId == "None" then
                        entry.free = entry.free + 1
                    else
                        entry.contains[staticId] = true
                        local metadata = job.metadata[staticId]
                        if entry.isRecyclerBoost
                            or (metadata ~= nil and metadata.maxStack > 1) then
                            local stackCount
                            local stackOk = pcall(function()
                                stackCount = tonumber(slot.StackCount)
                            end)
                            if not stackOk or stackCount == nil or stackCount < 1 then
                                invalidReason =
                                    "matching destination stack count is unreadable"
                                break
                            end
                            if entry.isRecyclerBoost then
                                entry.itemCounts[staticId] =
                                    (entry.itemCounts[staticId] or 0) + stackCount
                            end
                            if metadata ~= nil and metadata.maxStack > 1
                                and stackCount < metadata.maxStack then
                                entry.stackRoom[staticId] =
                                    (entry.stackRoom[staticId] or 0)
                                    + metadata.maxStack - stackCount
                            end
                        end
                    end
                end

                if invalidReason ~= nil then
                    skipCurrentContainer(job, invalidReason)
                else
                    slotsProcessed = slotsProcessed + math.max(0, stop - first + 1)
                    entry.slotIndex = stop + 1
                    if entry.slotIndex > entry.slotCount then
                        indexContainer(job, entry)
                        job.currentContainer = nil
                        job.containerCandidateIndex = job.containerCandidateIndex + 1
                    end
                end
            end
        end
    end

    if job.currentContainer == nil
        and job.containerCandidateIndex > #job.containerCandidates then
        beginPlanning(job)
        return
    end
    scheduleJobStep(job, NEXT_SLICE_MS, scanContainerCandidatesSlice,
        "containers")
end

local function appendCandidate(job, model, concrete, container, kind, instanceId)
    local _, key = containerGuid(container)
    if key == nil or key == P.ZERO_GUID or job.candidateKeys[key] then return end
    job.candidateKeys[key] = true
    job.containerCandidates[#job.containerCandidates + 1] = {
        kind = kind,
        instanceId = instanceId,
        model = model,
        concrete = concrete,
        container = container,
    }
end

local function addCandidate(job, model, concrete, kind, instanceId)
    local autoDestroy = false
    if kind == "storage" then
        pcall(function() autoDestroy = concrete.bAutoDestroyIfEmpty == true end)
        if autoDestroy then return end
    end

    local container
    if kind == "guild_storage" then
        if job.guildContext == nil then return end
        local eligible = P.guildChestEligible(concrete, job.guildContext)
        if not eligible then return end
        local address = P.objectAddress(concrete)
        if address == nil or job.guildReplicationKeys[address] then return end
        if not P.startGuildChestReplication(concrete) then return end
        job.guildReplicationKeys[address] = true
        job.guildReplicationModels[#job.guildReplicationModels + 1] = concrete
        job.pendingGuildCandidates[#job.pendingGuildCandidates + 1] = {
            kind = kind,
            instanceId = instanceId,
            model = model,
            concrete = concrete,
        }
        return
    elseif kind == "recycler" then
        local ok = pcall(function() container = concrete:GetRelicItemContainer() end)
        if not ok or not isValid(container) then return end
    elseif kind == "recycler_boost" then
        local ok = pcall(function() container = concrete.BoostItemContainer end)
        if not ok or not isValid(container) then return end
    else
        local module
        local ok = pcall(function()
            module = concrete:GetItemContainerModule()
            container = module.TargetContainer
        end)
        if not ok or not isValid(module) or not isValid(container) then return end
    end
    appendCandidate(job, model, concrete, container, kind, instanceId)
end

local function beginContainerCandidateScan(job)
    job.containerCandidateIndex = 1
    scheduleJobStep(job, NEXT_SLICE_MS, scanContainerCandidatesSlice,
        "containers")
end

local function resolvePendingGuildCandidates(job)
    if not identityMatches(job) then
        finishJob(job, false, "local player or base changed")
        return
    end
    local unresolved = {}
    for _, candidate in ipairs(job.pendingGuildCandidates) do
        local eligible = P.guildChestEligible(candidate.concrete, job.guildContext)
        local container = eligible
            and P.readyGuildChestContainer(candidate.concrete) or nil
        if isValid(container) then
            appendCandidate(job, candidate.model, candidate.concrete, container,
                candidate.kind, candidate.instanceId)
        elseif eligible then
            unresolved[#unresolved + 1] = candidate
        end
    end
    job.pendingGuildCandidates = unresolved
    job.guildReplicationPolls = job.guildReplicationPolls + 1
    if #unresolved > 0
        and job.guildReplicationPolls < GUILD_REPLICATION_MAX_POLLS then
        scheduleJobStep(job, GUILD_REPLICATION_POLL_MS,
            resolvePendingGuildCandidates, "guild")
        return
    end
    if #unresolved > 0 then
        debugLog("Guild Chest replication was not ready before the bounded timeout")
    end
    beginContainerCandidateScan(job)
end

local function scanBaseObjectsSlice(job)
    if not identityMatches(job) then
        finishJob(job, false, "local player or base changed")
        return
    end
    local stop = math.min(job.baseObjectIndex + BASE_OBJECTS_PER_SLICE - 1,
        job.repCount)
    for index = job.baseObjectIndex, stop do
        local repInfo, readable = arrayValue(job.repItems, index)
        if not readable or repInfo == nil then
            finishJob(job, false, "current-base object entry is unreadable")
            return
        end
        local instanceId
        local idOk = pcall(function() instanceId = repInfo.InstanceId end)
        if not idOk or instanceId == nil then
            finishJob(job, false, "current-base object id is unreadable")
            return
        end
        local model
        local concrete
        local modelOk = pcall(function()
            model = job.mapObjectManager:FindModel(instanceId)
            if isValid(model) then concrete = model.ConcreteModel end
        end)
        if modelOk and isValid(model) and isValid(concrete) then
            local kind = P.destinationKind(job, concrete)
            if kind ~= nil then
                addCandidate(job, model, concrete, kind, instanceId)
                if kind == "recycler"
                    and job.itemsById[WORLD_TREE_HOLY_WATER_ID] ~= nil then
                    addCandidate(job, model, concrete,
                        "recycler_boost", instanceId)
                end
            end
        end
    end
    job.baseObjectIndex = stop + 1
    if job.baseObjectIndex <= job.repCount then
        scheduleJobStep(job, NEXT_SLICE_MS, scanBaseObjectsSlice, "base")
        return
    end
    if #job.pendingGuildCandidates > 0 then
        job.guildReplicationPolls = 0
        scheduleJobStep(job, GUILD_REPLICATION_POLL_MS,
            resolvePendingGuildCandidates, "guild")
        return
    end
    beginContainerCandidateScan(job)
end

startBaseSnapshot = function(job)
    if not identityMatches(job) then
        finishJob(job, false, "local player or base changed")
        return
    end
    local loaded, classError = P.loadDestinationClasses(job)
    if not loaded then finishJob(job, false, classError); return end
    job.uniqueItemsByTypeA = {}
    job.uniqueItemsByTypeB = {}
    for _, unique in ipairs(job.uniqueItems) do
        local metadata = job.metadata[unique.id]
        local byTypeA = job.uniqueItemsByTypeA[metadata.typeA]
        if byTypeA == nil then
            byTypeA = {}
            job.uniqueItemsByTypeA[metadata.typeA] = byTypeA
        end
        byTypeA[#byTypeA + 1] = unique
        local byTypeB = job.uniqueItemsByTypeB[metadata.typeB]
        if byTypeB == nil then
            byTypeB = {}
            job.uniqueItemsByTypeB[metadata.typeB] = byTypeB
        end
        byTypeB[#byTypeB + 1] = unique
    end
    job.baseObjectIndex = 1
    job.containerCandidates = {}
    job.candidateKeys = {}
    job.pendingGuildCandidates = {}
    job.guildReplicationKeys = {}
    job.guildReplicationModels = {}
    job.containersByContainedItem = {}
    job.containersByAcceptedCategory = {}
    job.compatibleContainedItems = {}
    job.compatibleAcceptedCategories = {}
    job.compatibleAcceptedItems = {}
    job.incubators = {}
    job.recyclers = {}
    job.recyclerBoosts = {}
    scheduleJobStep(job, NEXT_SLICE_MS, scanBaseObjectsSlice, "base")
end

local function appendMove(job, entry, item, amount)
    if amount <= 0 then return end
    local request = job.requestByContainer[entry.containerKey]
    if request == nil then
        request = { entry = entry, sources = {} }
        job.requestByContainer[entry.containerKey] = request
        job.requests[#job.requests + 1] = request
    end
    for _, source in ipairs(request.sources) do
        if source.item == item then
            source.num = source.num + amount
            return
        end
    end
    request.sources[#request.sources + 1] = {
        item = item,
        id = item.id,
        num = amount,
    }
end

local function allocateNormal(job, entry, item, wanted)
    local metadata = job.metadata[item.id]
    if wanted <= 0 or not P.destinationAllows(entry, item, metadata) then return 0 end
    local reusesPlannedDestination =
        job.requestByContainer[entry.containerKey] ~= nil
    local received = 0
    local room = entry.stackRoom[item.id] or 0
    if room > 0 then
        local amount = math.min(wanted, room)
        entry.stackRoom[item.id] = room - amount
        received = received + amount
    end
    if received < wanted and entry.free > 0 then
        local remaining = wanted - received
        local slotsNeeded = math.ceil(remaining / metadata.maxStack)
        local slotsUsed = math.min(entry.free, slotsNeeded)
        local amount = math.min(remaining, slotsUsed * metadata.maxStack)
        entry.free = entry.free - slotsUsed
        local spare = slotsUsed * metadata.maxStack - amount
        if spare > 0 then
            entry.stackRoom[item.id] = (entry.stackRoom[item.id] or 0) + spare
        end
        received = received + amount
    end
    if received > 0 then
        entry.contains[item.id] = true
        appendMove(job, entry, item, received)
        if reusesPlannedDestination and job.performance ~= nil then
            job.performance.destinationReuses =
                job.performance.destinationReuses + 1
        end
    end
    return received
end

local function allocateIncubator(job, entry, item, wanted)
    if wanted <= 0 or not item.isEgg or entry.free <= 0 then return 0 end
    local received = math.min(wanted, entry.free)
    entry.free = entry.free - received
    appendMove(job, entry, item, received)
    return received
end

local function allocateRecycler(job, entry, item, wanted)
    if wanted <= 0 or not item.isRelic then return 0 end
    return allocateNormal(job, entry, item, wanted)
end

local function allocateRecyclerBoost(job, entry, item, wanted)
    if wanted <= 0 or not item.isHolyWater then return 0 end
    local current = entry.itemCounts[item.id] or 0
    local deficit = math.max(0,
        job.config.WorldTreeHolyWaterMinimum - current)
    if deficit <= 0 then return 0 end
    local received = allocateNormal(job, entry, item,
        math.min(wanted, deficit))
    entry.itemCounts[item.id] = current + received
    return received
end

local function preferPlannedDestinations(job, entries)
    local preferred
    for _, entry in ipairs(entries) do
        if job.requestByContainer[entry.containerKey] ~= nil then
            preferred = preferred or {}
            preferred[#preferred + 1] = entry
        end
    end
    if preferred == nil then return entries end
    for _, entry in ipairs(entries) do
        if job.requestByContainer[entry.containerKey] == nil then
            preferred[#preferred + 1] = entry
        end
    end
    return preferred
end

local function newRouteState(job, item)
    local incubators = {}
    if item.isEgg then
        incubators = job.incubators
    end
    local metadata = job.metadata[item.id]
    local contained = preferPlannedDestinations(
        job, job.containersByContainedItem[item.id] or {})
    local accepted = preferPlannedDestinations(
        job,
        job.config.IncludeNewItems
            and (job.containersByAcceptedCategory[metadata.category] or {}) or {})
    local recyclers = item.isRelic and job.recyclers or {}
    local recyclerBoosts = item.isHolyWater and job.recyclerBoosts or {}
    local ordinaryFallback = (not item.isEgg
            or job.config.PalEggRouting == "IncubatorThenStorage")
        and (not item.isRelic
            or job.config.RelicRouting == "RecyclerThenStorage")
    local stages = {}
    if #recyclerBoosts > 0 then
        stages[#stages + 1] = {
            kind = "recycler_boost",
            entries = recyclerBoosts,
        }
    end
    if #recyclers > 0 then
        stages[#stages + 1] = { kind = "recycler", entries = recyclers }
    end
    stages[#stages + 1] = { kind = "incubator", entries = incubators }
    if ordinaryFallback then
        stages[#stages + 1] = { kind = "normal", entries = contained }
        stages[#stages + 1] = { kind = "normal", entries = accepted }
    end
    local hasOrdinaryDestination =
        job.compatibleContainedItems[item.id]
        or (job.config.IncludeNewItems and (
            job.compatibleAcceptedItems[item.id]
            or job.compatibleAcceptedCategories[metadata.category]))
    return {
        item = item,
        remaining = item.num,
        visited = {},
        stageIndex = 1,
        candidateIndex = 1,
        stages = stages,
        reportRemainder = item.isEgg or item.isRelic
            or item.isHolyWater or #recyclers > 0 or hasOrdinaryDestination,
    }
end

local function routeOneOperation(job, route)
    if route.remaining <= 0 then return true end
    while route.stageIndex <= #route.stages do
        local stage = route.stages[route.stageIndex]
        local entry = stage.entries[route.candidateIndex]
        if entry == nil then
            route.stageIndex = route.stageIndex + 1
            route.candidateIndex = 1
        else
            route.candidateIndex = route.candidateIndex + 1
            if not route.visited[entry.containerKey] then
                route.visited[entry.containerKey] = true
                local received
                if stage.kind == "incubator" then
                    received = allocateIncubator(job, entry, route.item, route.remaining)
                elseif stage.kind == "recycler" then
                    received = allocateRecycler(job, entry, route.item, route.remaining)
                elseif stage.kind == "recycler_boost" then
                    received = allocateRecyclerBoost(
                        job, entry, route.item, route.remaining)
                else
                    received = allocateNormal(job, entry, route.item, route.remaining)
                end
                route.remaining = route.remaining - received
            end
            return route.remaining <= 0
        end
    end
    return true
end

local processNextRequest
local beginCompletionWait

local function planItemsSlice(job)
    if not identityMatches(job) then
        finishJob(job, false, "local player or base changed")
        return
    end
    local operations = 0
    while operations < PLAN_OPERATIONS_PER_SLICE
        and job.planItemIndex <= #job.items do
        if job.routeState == nil then
            job.routeState = newRouteState(job, job.items[job.planItemIndex])
        end
        local complete = routeOneOperation(job, job.routeState)
        operations = operations + 1
        if complete then
            if job.routeState.remaining > 0 then
                debugLog(job.routeState.item.id .. " kept "
                    .. job.routeState.remaining .. " item(s): no valid capacity")
                local item = job.routeState.item
                if job.routeState.reportRemainder then
                    addItemCount(job.fullItems, job.fullById,
                        item.id,
                        item.staticId,
                        job.routeState.remaining)
                    job.fullTotal = job.fullTotal + job.routeState.remaining
                end
            end
            job.routeState = nil
            job.planItemIndex = job.planItemIndex + 1
        end
    end
    if job.planItemIndex <= #job.items then
        scheduleJobStep(job, NEXT_SLICE_MS, planItemsSlice, "plan")
        return
    end
    if #job.requests == 0 then
        finishJob(job, true, "nothing has a valid destination")
        return
    end
    job.requestIndex = 1
    job.submittedRequests = 0
    job.submittedItems = 0
    job.failedRequests = 0
    job.submittedByItem = {}
    scheduleJobStep(job, NEXT_SLICE_MS, processNextRequest, "request")
end

beginPlanning = function(job)
    job.requests = {}
    job.requestByContainer = {}
    job.planItemIndex = 1
    job.routeState = nil
    scheduleJobStep(job, NEXT_SLICE_MS, planItemsSlice, "plan")
end

local function skipRequest(job, reason)
    debugLog("skipping stale destination request: " .. tostring(reason))
    job.recheck = nil
    job.requestIndex = job.requestIndex + 1
    scheduleJobStep(job, NEXT_SLICE_MS, processNextRequest, "request")
end

local function sourceStillMatches(job, item, required)
    if not isValid(item.slot) then return false end
    local staticId = slotStaticId(item.slot)
    local _, containerKey = slotGuid(item.slot)
    local slotIndex
    local stackCount
    local ok = pcall(function()
        slotIndex = tonumber(item.slot.SlotIndex)
        stackCount = tonumber(item.slot.StackCount)
    end)
    return ok and staticId == item.id and containerKey == job.commonKey
        and slotIndex == item.slotIndex and stackCount ~= nil and stackCount >= required
end

local function capacityAcceptsRequest(job, recheck)
    local free = recheck.free
    local room = recheck.stackRoom
    if recheck.entry.isIncubator then
        local needed = 0
        for _, source in ipairs(recheck.request.sources) do
            if not source.item.isEgg then return false end
            needed = needed + source.num
        end
        return needed <= free
    end

    for _, source in ipairs(recheck.request.sources) do
        if not job.config.IncludeNewItems and not recheck.entry.isRecycler
            and not recheck.entry.isRecyclerBoost
            and not recheck.containsNeeded[source.id] then return false end
        local metadata = job.metadata[source.id]
        local remaining = source.num
        local stackRoom = room[source.id] or 0
        if stackRoom > 0 then
            local amount = math.min(remaining, stackRoom)
            room[source.id] = stackRoom - amount
            remaining = remaining - amount
        end
        if remaining > 0 then
            local slotsNeeded = math.ceil(remaining / metadata.maxStack)
            if slotsNeeded > free then return false end
            free = free - slotsNeeded
            local spare = slotsNeeded * metadata.maxStack - remaining
            if spare > 0 then room[source.id] = (room[source.id] or 0) + spare end
        end
    end
    return true
end

local function submitRecheckedRequest(job)
    local recheck = job.recheck
    local request = recheck.request
    local validateStartedAt = beginPerformanceDetail(job)
    if recheck.entry.isRecyclerBoost then
        local allowed = math.max(0,
            job.config.WorldTreeHolyWaterMinimum
                - (recheck.itemCounts[WORLD_TREE_HOLY_WATER_ID] or 0))
        local trimmed = {}
        for _, source in ipairs(request.sources) do
            if allowed > 0 and source.id == WORLD_TREE_HOLY_WATER_ID then
                local amount = math.min(source.num, allowed)
                if amount > 0 then
                    trimmed[#trimmed + 1] = {
                        item = source.item,
                        id = source.id,
                        num = amount,
                    }
                    allowed = allowed - amount
                end
            end
        end
        request.sources = trimmed
        if #request.sources == 0 then
            recordPerformanceDetail(job, "recheck_validate", validateStartedAt)
            skipRequest(job, "World Tree Holy Water minimum is already met")
            return
        end
    end
    if not capacityAcceptsRequest(job, recheck) then
        recordPerformanceDetail(job, "recheck_validate", validateStartedAt)
        for _, source in ipairs(request.sources) do
            addItemCount(job.fullItems, job.fullById,
                source.id, source.item.staticId, source.num)
            job.fullTotal = job.fullTotal + source.num
        end
        skipRequest(job, "destination capacity changed")
        return
    end

    local sourceTotals = {}
    for _, source in ipairs(request.sources) do
        sourceTotals[source.item] = (sourceTotals[source.item] or 0) + source.num
    end
    for item, required in pairs(sourceTotals) do
        if not sourceStillMatches(job, item, required) then
            recordPerformanceDetail(job, "recheck_validate", validateStartedAt)
            skipRequest(job, "source inventory changed")
            return
        end
    end
    recordPerformanceDetail(job, "recheck_validate", validateStartedAt)

    local prepareStartedAt = beginPerformanceDetail(job)
    local networkItem
    local networkOk = pcall(function() networkItem = job.controller.Transmitter.Item end)
    if not networkOk or not isValid(networkItem) then
        recordPerformanceDetail(job, "rpc_prepare", prepareStartedAt)
        finishJob(job, false, "local item network component became unavailable")
        return
    end
    local rpcSources = {}
    local itemCount = 0
    for _, source in ipairs(request.sources) do
        rpcSources[#rpcSources + 1] = {
            SlotId = source.item.slotId,
            Num = source.num,
        }
        itemCount = itemCount + source.num
    end
    state.requestSequence = state.requestSequence + 1
    local requestId = {
        A = state.requestSequence % 2147483647,
        B = math.random(0, 2147483647),
        C = math.random(0, 2147483647),
        D = math.random(0, 2147483647),
    }
    recordPerformanceDetail(job, "rpc_prepare", prepareStartedAt)
    local rpcStartedAt = beginPerformanceDetail(job)
    local sent, sendError = pcall(function()
        networkItem:RequestMoveToContainer_ToServer(
            requestId,
            request.entry.containerId,
            rpcSources)
    end)
    recordPerformanceDetail(job, "rpc_call", rpcStartedAt)
    if not sent then
        job.failedRequests = job.failedRequests + 1
        log("destination move failed: " .. tostring(sendError))
    else
        job.submittedRequests = job.submittedRequests + 1
        job.submittedItems = job.submittedItems + itemCount
        for _, source in ipairs(request.sources) do
            job.submittedByItem[source.item] =
                (job.submittedByItem[source.item] or 0) + source.num
        end
    end
    job.recheck = nil
    job.requestIndex = job.requestIndex + 1
    scheduleJobStep(job, RPC_INTERVAL_MS, processNextRequest, "request")
end

local function scanRecheckSlotsSlice(job)
    if not identityMatches(job) then
        finishJob(job, false, "local player or base changed")
        return
    end
    local recheck = job.recheck
    if recheck == nil or not isValid(recheck.entry.container) then
        skipRequest(job, "destination became invalid")
        return
    end
    local stop = math.min(recheck.slotIndex + RECHECK_SLOTS_PER_SLICE - 1,
        recheck.slotCount)
    local scanStartedAt = beginPerformanceDetail(job)
    for index = recheck.slotIndex, stop do
        local slot, readable = arrayValue(recheck.slots, index)
        if not readable or not isValid(slot) then
            skipRequest(job, "destination slot is unreadable")
            return
        end
        local staticId = slotStaticId(slot)
        if staticId == nil then
            skipRequest(job, "destination item id is unreadable")
            return
        end
        if staticId == "None" then
            recheck.free = recheck.free + 1
        elseif recheck.neededIds[staticId] then
            recheck.containsNeeded[staticId] = true
            local metadata = job.metadata[staticId]
            if recheck.entry.isRecyclerBoost or metadata.maxStack > 1 then
                local stackCount
                local stackOk = pcall(function() stackCount = tonumber(slot.StackCount) end)
                if not stackOk or stackCount == nil or stackCount < 1 then
                    skipRequest(job, "destination stack count is unreadable")
                    return
                end
                if recheck.entry.isRecyclerBoost then
                    recheck.itemCounts[staticId] =
                        (recheck.itemCounts[staticId] or 0) + stackCount
                end
                if metadata.maxStack > 1 and stackCount < metadata.maxStack then
                    recheck.stackRoom[staticId] = (recheck.stackRoom[staticId] or 0)
                        + metadata.maxStack - stackCount
                end
            end
        end
    end
    recordPerformanceDetail(job, "recheck_scan", scanStartedAt)
    recheck.slotIndex = stop + 1
    if recheck.slotIndex <= recheck.slotCount then
        scheduleJobStep(job, NEXT_SLICE_MS, scanRecheckSlotsSlice, "recheck")
        return
    end
    submitRecheckedRequest(job)
end

local function submittedSourceReplicated(job, item, submitted)
    local slot, readable = arrayValue(job.inventorySlots, item.arrayIndex)
    if not readable or not isValid(slot) then return false end
    local staticId = slotStaticId(slot)
    local _, containerKey = slotGuid(slot)
    local slotIndex
    local stackCount
    local read = pcall(function()
        slotIndex = tonumber(slot.SlotIndex)
        stackCount = tonumber(slot.StackCount)
    end)
    if not read or staticId == nil or containerKey ~= job.commonKey
        or slotIndex ~= item.slotIndex or stackCount == nil then return false end

    local expectedMaximum = item.num - submitted
    if staticId == item.id then return stackCount <= expectedMaximum end
    return submitted >= item.num
end

local function checkCompletion(job)
    if not identityMatches(job) then
        finishJob(job, false, "local player or base changed")
        return
    end

    local replicated = true
    for item, submitted in pairs(job.submittedByItem) do
        if not submittedSourceReplicated(job, item, submitted) then
            replicated = false
            break
        end
    end
    if replicated then
        job.completionConfirmed = true
        finishJob(job, true, string.format(
            "confirmed %d destination request(s), %d item(s)",
            job.submittedRequests,
            job.submittedItems))
        return
    end
    if os.time() >= job.completionDeadline then
        finishJob(job, true, string.format(
            "submitted %d destination request(s), %d item(s); confirmation timed out",
            job.submittedRequests,
            job.submittedItems))
        return
    end
    scheduleJobStep(job, COMPLETION_POLL_MS, checkCompletion, "completion")
end

beginCompletionWait = function(job)
    if job.submittedRequests == 0 then
        if job.failedRequests > 0 then
            finishJob(job, false, "all destination move requests failed")
        else
            finishJob(job, true, "nothing was submitted")
        end
        return
    end
    job.completionDeadline = os.time() + COMPLETION_TIMEOUT_SECONDS
    scheduleJobStep(job, COMPLETION_POLL_MS, checkCompletion, "completion")
end

processNextRequest = function(job)
    if not identityMatches(job) then
        finishJob(job, false, "local player or base changed")
        return
    end
    if job.requestIndex > #job.requests then
        beginCompletionWait(job)
        return
    end

    local request = job.requests[job.requestIndex]
    local entry = request.entry
    if not isValid(entry.model) or not isValid(entry.concrete)
        or not isValid(entry.container) then
        skipRequest(job, "destination object became invalid")
        return
    end
    local currentModel
    local currentConcrete
    local currentContainer
    local currentRouteOk = pcall(function()
        currentModel = job.mapObjectManager:FindModel(entry.instanceId)
        currentConcrete = currentModel.ConcreteModel
        if entry.isGuildStorage then
            currentContainer = P.guildChestContainer(currentConcrete)
        elseif entry.isRecycler then
            currentContainer = currentConcrete:GetRelicItemContainer()
        elseif entry.isRecyclerBoost then
            currentContainer = currentConcrete.BoostItemContainer
        else
            local currentModule = currentConcrete:GetItemContainerModule()
            currentContainer = currentModule.TargetContainer
        end
    end)
    if not currentRouteOk or not isValid(currentModel) or not isValid(currentConcrete)
        or not isValid(currentContainer)
        or P.objectAddress(currentModel) ~= entry.modelAddress
        or P.objectAddress(currentConcrete) ~= entry.concreteAddress then
        skipRequest(job, "current-base destination model changed")
        return
    end
    local _, routedContainerKey = containerGuid(currentContainer)
    if routedContainerKey ~= entry.containerKey then
        skipRequest(job, "current-base destination container changed")
        return
    end
    entry.model = currentModel
    entry.concrete = currentConcrete
    entry.container = currentContainer

    if entry.isGuildStorage then
        local eligible, guildError = P.guildChestEligible(
            currentConcrete, job.guildContext)
        if not eligible then
            skipRequest(job, guildError)
            return
        end
    end

    if not job.config.IncludeExcludedItems then
        local currentExclusions, exclusionError = P.resolveExclusions(job.playerState)
        if currentExclusions == nil then
            finishJob(job, false, exclusionError)
            return
        end
        for _, source in ipairs(request.sources) do
            if currentExclusions[source.id] then
                skipRequest(job, "source item was added to the exclusion list")
                return
            end
        end
    end

    local currentFilter = {}
    local currentPermission = {
        typeA = {},
        typeB = {},
        itemIds = {},
        restricted = false,
    }
    if entry.isStorage then
        local filterError
        currentFilter, filterError = P.readFilterOff(entry.container)
        if currentFilter == nil then skipRequest(job, filterError); return end
    end
    if entry.isStorage or entry.isRecycler then
        local permissionError
        currentPermission, permissionError = P.readPermission(entry.container)
        if currentPermission == nil then skipRequest(job, permissionError); return end
    end
    local currentEntry = {
        isStorage = entry.isStorage,
        isGuildStorage = entry.isGuildStorage,
        isIncubator = entry.isIncubator,
        isRecycler = entry.isRecycler,
        isRecyclerBoost = entry.isRecyclerBoost,
        boostItemId = entry.boostItemId,
        filterOff = currentFilter,
        permission = currentPermission,
    }
    local neededIds = {}
    for _, source in ipairs(request.sources) do
        if not P.destinationAllows(currentEntry, source.item, job.metadata[source.id]) then
            skipRequest(job, "destination filter or permission changed")
            return
        end
        neededIds[source.id] = true
    end

    local slots
    local slotsOk = pcall(function() slots = entry.container.ItemSlotArray end)
    local slotCount = slotsOk and arrayLength(slots) or nil
    if slotCount == nil then skipRequest(job, "destination slots are unreadable"); return end
    job.recheck = {
        request = request,
        entry = entry,
        slots = slots,
        slotCount = slotCount,
        slotIndex = 1,
        neededIds = neededIds,
        free = 0,
        stackRoom = {},
        containsNeeded = {},
        itemCounts = {},
    }
    scheduleJobStep(job, NEXT_SLICE_MS, scanRecheckSlotsSlice, "recheck")
end

local function beginResolvedJob(job)
    local resolved, resolveError = resolveJobRoots(job)
    if not resolved then
        finishJob(job, false, resolveError)
        return
    end
    scheduleJobStep(job, NEXT_SLICE_MS, scanInventorySlice, "inventory")
end

function QuickStack.configure(config, logger, debugLogger)
    state.config = config
    state.log = logger
    state.debugLog = debugLogger
    Notifications.configure(logger, config.PerformanceCapture == true)
end

function QuickStack.begin()
    if state.job ~= nil then
        debugLog("previous job is still active; press ignored")
        return
    end

    local controller = P.currentController()
    if controller == nil then log("quick stack unavailable: no local controller"); return end
    local blocked, inputError, inventoryOpen = P.blockingUiOwnsInput(controller)
    if blocked == nil then log("quick stack unavailable: " .. tostring(inputError)); return end
    if blocked then debugLog("blocking UI owns input; press ignored"); return end

    local identity, identityError = P.identityFor(controller)
    if identity == nil then
        debugLog("quick stack ignored: " .. tostring(identityError))
        return
    end

    state.generation = state.generation + 1
    identity.generation = state.generation
    identity.startedAt = os.time()
    identity.config = snapshotJobConfig(state.config)
    identity.detailedResultRequested = identity.config.ResultDisplay == "ResultWindow"
        or (identity.config.ResultDisplay == "Default" and inventoryOpen == true)
    if state.config.PerformanceCapture == true then
        identity.performance = {
            startedAt = os.clock(),
            phases = {},
            details = {},
            slices = 0,
            maxSliceMs = 0,
            maxSlicePhase = nil,
            notificationStartMs = 0,
            notificationFinishMs = 0,
            containers = 0,
            containerSlots = 0,
            destinationReuses = 0,
        }
    end
    state.job = identity
    local notificationStartedAt = identity.performance ~= nil and os.clock() or nil
    local notified, token = pcall(Notifications.started, controller)
    if identity.performance ~= nil then
        identity.performance.notificationStartMs =
            elapsedMilliseconds(notificationStartedAt)
    end
    if notified then identity.notificationToken = token end
    debugLog("job generation " .. identity.generation .. " started")
    scheduleJobStep(identity, 0, beginResolvedJob, "resolve")
end

return QuickStack
