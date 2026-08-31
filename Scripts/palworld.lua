local UEHelpers = require("UEHelpers")

local Palworld = {
    ZERO_GUID = "00000000-00000000-00000000-00000000",
}

local STORAGE_CLASS_PATHS = {
    "/Script/Pal.PalMapObjectItemStorageModel",
    "/Script/Pal.PalMapObjectItemChestModel",
    "/Script/Pal.PalMapObjectSupplyStorageModel",
    "/Script/Pal.PalMapObjectPalFoodBoxModel",
}

local INCUBATOR_CLASS_PATH = "/Script/Pal.PalMapObjectHatchingEggModelBase"
local GUILD_CHEST_CLASS_PATH = "/Script/Pal.PalMapObjectGuildChestModel"
local RECYCLER_CLASS_PATH = "/Script/Pal.PalMapObjectRecyclerModel"

local MAIN_MENU_CLASS_PATH =
    "/Game/Pal/Blueprint/UI/InGameMainMenu/WBP_InGameMainMenu.WBP_InGameMainMenu_C"
local INVENTORY_DISPLAY_CLASS_PATH =
    "/Game/Pal/Blueprint/UI/Inventory/WBP_InventoryEquipment_ForDisplay.WBP_InventoryEquipment_ForDisplay_C"

local inputUi = {
    mainMenu = nil,
    mainMenuAddress = nil,
    inventoryDisplayClass = nil,
    trackingReady = false,
}

function Palworld.isValid(object)
    if object == nil then return false end
    local ok, result = pcall(function() return object:IsValid() end)
    return ok and result == true
end

function Palworld.objectAddress(object)
    if not Palworld.isValid(object) then return nil end
    local ok, address = pcall(function() return object:GetAddress() end)
    if not ok or type(address) ~= "number" or address == 0 then return nil end
    return address
end

function Palworld.staticObject(path)
    local ok, object = pcall(StaticFindObject, path)
    if not ok or not Palworld.isValid(object) then return nil end
    return object
end

function Palworld.guidParts(value)
    if value == nil then return nil end
    local ok, parts = pcall(function()
        return { A = value.A, B = value.B, C = value.C, D = value.D }
    end)
    if not ok or parts.A == nil or parts.B == nil
        or parts.C == nil or parts.D == nil then return nil end
    return parts
end

function Palworld.guidKey(parts)
    if type(parts) ~= "table" or parts.A == nil then return nil end
    local function unsigned32(value)
        value = tonumber(value)
        if value == nil then return nil end
        if value < 0 then return value + 4294967296 end
        return value
    end
    local a = unsigned32(parts.A)
    local b = unsigned32(parts.B)
    local c = unsigned32(parts.C)
    local d = unsigned32(parts.D)
    if a == nil or b == nil or c == nil or d == nil then return nil end
    return string.format("%08X-%08X-%08X-%08X", a, b, c, d)
end

function Palworld.arrayLength(array)
    if array == nil then return nil end
    local ok, count = pcall(function() return array:GetArrayNum() end)
    if not ok or type(count) ~= "number" then
        ok, count = pcall(function() return #array end)
    end
    if not ok or type(count) ~= "number" or count < 0 then return nil end
    return math.floor(count)
end

function Palworld.arrayValue(array, index)
    local ok, value = pcall(function() return array[index] end)
    if not ok then return nil, false end
    return value, true
end

function Palworld.nameString(value)
    if value == nil then return nil end
    local ok, result = pcall(function() return value:ToString() end)
    if not ok or type(result) ~= "string" or result == "" then return nil end
    return result
end

function Palworld.unwrap(value)
    if value == nil then return nil end
    local ok, result = pcall(function() return value:get() end)
    if ok and result ~= nil then return result end
    return value
end

function Palworld.enumValue(value)
    value = Palworld.unwrap(value)
    if type(value) == "number" then return value end
    local converted = tonumber(tostring(value))
    if type(converted) ~= "number" then return nil end
    return converted
end

function Palworld.readNameSet(array)
    local count = Palworld.arrayLength(array)
    if count == nil then return nil, "name array is unreadable" end
    local out = {}
    for index = 1, count do
        local raw, readable = Palworld.arrayValue(array, index)
        if not readable then return nil, "name array entry is unreadable" end
        local name = Palworld.nameString(Palworld.unwrap(raw))
        if name == nil then return nil, "name array entry cannot be decoded" end
        if name ~= "None" then out[name] = true end
    end
    return out, nil
end

function Palworld.readEnumSet(array)
    local count = Palworld.arrayLength(array)
    if count == nil then return nil, "enum array is unreadable" end
    local out = {}
    for index = 1, count do
        local raw, readable = Palworld.arrayValue(array, index)
        if not readable then return nil, "enum array entry is unreadable" end
        local value = Palworld.enumValue(raw)
        if value == nil then return nil, "enum array entry cannot be decoded" end
        out[value] = true
    end
    return out, nil
end

function Palworld.isEggId(staticId)
    return type(staticId) == "string" and staticId:find("^PalEgg") ~= nil
end

function Palworld.containerGuid(container)
    local parts
    local ok = pcall(function() parts = Palworld.guidParts(container.ID.ID) end)
    if not ok then return nil, nil end
    return parts, Palworld.guidKey(parts)
end

function Palworld.slotGuid(slot)
    local parts
    local ok = pcall(function() parts = Palworld.guidParts(slot.ContainerId.ID) end)
    if not ok then return nil, nil end
    return parts, Palworld.guidKey(parts)
end

function Palworld.slotStaticId(slot)
    local raw
    local ok = pcall(function() raw = slot.ItemId.StaticId end)
    if not ok or raw == nil then return nil, nil end
    return Palworld.nameString(raw), raw
end

local function isLocalController(controller)
    if not Palworld.isValid(controller) then return false end
    local ok, result = pcall(function()
        return controller:IsLocalPlayerController()
    end)
    return ok and result == true
end

local cachedController

function Palworld.currentController()
    if isLocalController(cachedController) then return cachedController end
    cachedController = nil

    if type(FindFirstOf) == "function" then
        local found, controller = pcall(FindFirstOf, "PlayerController")
        if found and isLocalController(controller) then
            cachedController = controller
            return controller
        end
    end

    local ok, controller = pcall(UEHelpers.GetPlayerController)
    if not ok or not isLocalController(controller) then return nil end
    cachedController = controller
    return controller
end

local function inventoryMenuIsActive()
    local menu = inputUi.mainMenu
    if not Palworld.isValid(menu)
        or Palworld.objectAddress(menu) ~= inputUi.mainMenuAddress then
        inputUi.mainMenu = nil
        inputUi.mainMenuAddress = nil
        return false
    end

    local active
    local content
    local ok = pcall(function()
        active = menu:IsActivated()
        content = Palworld.unwrap(menu.CurrentContentWidget)
    end)
    if not ok or active ~= true or not Palworld.isValid(content) then
        return false
    end

    local inventoryClass = inputUi.inventoryDisplayClass
    if not Palworld.isValid(inventoryClass) then
        inventoryClass = Palworld.staticObject(INVENTORY_DISPLAY_CLASS_PATH)
        inputUi.inventoryDisplayClass = inventoryClass
    end
    if inventoryClass == nil then return false end

    local typed, isInventory = pcall(function()
        return content:IsA(inventoryClass)
    end)
    return typed and isInventory == true
end

function Palworld.installInputUiTracking()
    if inputUi.trackingReady then return true, nil end
    if type(NotifyOnNewObject) ~= "function" then
        return false, "UE4SS object lifecycle API is unavailable"
    end

    local ok, errorMessage = pcall(NotifyOnNewObject,
        MAIN_MENU_CLASS_PATH, function(context)
            local menu = Palworld.unwrap(context)
            local address = Palworld.objectAddress(menu)
            if address ~= nil then
                inputUi.mainMenu = menu
                inputUi.mainMenuAddress = address
            end
            return false
        end)
    if not ok then return false, errorMessage end
    inputUi.trackingReady = true
    return true, nil
end

function Palworld.blockingUiOwnsInput(controller)
    local ok, cursorVisible = pcall(function() return controller.bShowMouseCursor end)
    if not ok then return nil, "input ownership state is unreadable" end
    if cursorVisible == true then
        local inventoryOpen = inventoryMenuIsActive()
        return not inventoryOpen, nil, inventoryOpen
    end
    return false, nil, false
end

function Palworld.identityFor(controller)
    local playerState
    local pawn
    local insideComponent
    local base
    local world
    local baseId
    local ok = pcall(function()
        playerState = controller.PlayerState
        pawn = controller.Pawn
        insideComponent = pawn.InsideBaseCampCheckComponent
        base = insideComponent:GetInsideBaseCampModel()
        world = controller:GetWorld()
        baseId = Palworld.guidParts(insideComponent.NowInsideBaseCampID)
    end)
    if not ok or not Palworld.isValid(controller)
        or not Palworld.isValid(playerState) or not Palworld.isValid(pawn)
        or not Palworld.isValid(insideComponent) or not Palworld.isValid(base)
        or not Palworld.isValid(world) then
        return nil, "local base context is unavailable"
    end
    local baseKey = Palworld.guidKey(baseId)
    if baseKey == nil or baseKey == Palworld.ZERO_GUID then
        return nil, "not inside a base"
    end

    local identity = {
        controller = controller,
        controllerAddress = Palworld.objectAddress(controller),
        playerState = playerState,
        playerStateAddress = Palworld.objectAddress(playerState),
        pawn = pawn,
        pawnAddress = Palworld.objectAddress(pawn),
        insideComponent = insideComponent,
        insideComponentAddress = Palworld.objectAddress(insideComponent),
        base = base,
        baseAddress = Palworld.objectAddress(base),
        world = world,
        worldAddress = Palworld.objectAddress(world),
        baseId = baseId,
        baseKey = baseKey,
    }
    if identity.controllerAddress == nil or identity.playerStateAddress == nil
        or identity.pawnAddress == nil or identity.insideComponentAddress == nil
        or identity.baseAddress == nil or identity.worldAddress == nil then
        return nil, "local identity is incomplete"
    end
    return identity, nil
end

local cachedUtility

function Palworld.utility()
    if Palworld.isValid(cachedUtility) then return cachedUtility end
    cachedUtility = Palworld.staticObject("/Script/Pal.Default__PalUtility")
    return cachedUtility
end

function Palworld.identityMatches(job)
    local current = Palworld.identityFor(job.controller)
    if current == nil then return false end
    return current.controllerAddress == job.controllerAddress
        and current.playerStateAddress == job.playerStateAddress
        and current.pawnAddress == job.pawnAddress
        and current.insideComponentAddress == job.insideComponentAddress
        and current.baseAddress == job.baseAddress
        and current.worldAddress == job.worldAddress
        and current.baseKey == job.baseKey
end

function Palworld.resolveCommonContainer(playerState)
    local inventory
    local commonGuid
    local containers
    local ok = pcall(function()
        inventory = playerState.InventoryData
        commonGuid = Palworld.guidParts(inventory.MyInventoryInfo.CommonContainerId.ID)
        containers = inventory.InventoryMultiHelper.Containers
    end)
    if not ok or not Palworld.isValid(inventory) then
        return nil, nil, nil, "common inventory roots are unavailable"
    end
    local commonKey = Palworld.guidKey(commonGuid)
    if commonKey == nil or commonKey == Palworld.ZERO_GUID then
        return nil, nil, nil, "common container id is unavailable"
    end

    local count = Palworld.arrayLength(containers)
    if count == nil then return nil, nil, nil, "owned container list is unreadable" end
    local matched
    local matchedCount = 0
    for index = 1, count do
        local container, readable = Palworld.arrayValue(containers, index)
        if not readable or not Palworld.isValid(container) then
            return nil, nil, nil, "owned container entry is unreadable"
        end
        local _, key = Palworld.containerGuid(container)
        if key == nil then return nil, nil, nil, "owned container id is unreadable" end
        if key == commonKey then
            matched = container
            matchedCount = matchedCount + 1
        end
    end
    if matchedCount ~= 1 then
        return nil, nil, nil,
            "common container match is missing or ambiguous (" .. matchedCount .. ")"
    end
    return inventory, matched, commonGuid, nil
end

function Palworld.resolveExclusions(playerState)
    local record
    local exclusions
    local ok = pcall(function()
        record = playerState:GetLocalRecordData()
        exclusions = record.Local_ItemQuickMoveExceptionIDList
    end)
    if not ok or not Palworld.isValid(record) or exclusions == nil then
        return nil, "quick-stack exclusion list is unavailable"
    end
    return Palworld.readNameSet(exclusions)
end

local cachedCategorySettingAddress
local cachedCategories

function Palworld.readCategories(gameSetting)
    local settingAddress = Palworld.objectAddress(gameSetting)
    if settingAddress ~= nil and settingAddress == cachedCategorySettingAddress
        and cachedCategories ~= nil then
        return cachedCategories, nil
    end

    local preferenceMap
    local ok = pcall(function()
        preferenceMap = gameSetting.ItemFilterPreference.PreferenceMap
    end)
    if not ok or preferenceMap == nil then
        return nil, "item filter preference map is unavailable"
    end

    local categories = {}
    local names = {}
    local decodeError
    local iterated = pcall(function()
        preferenceMap:ForEach(function(rawKey, rawValue)
            if decodeError ~= nil then return end
            local name = Palworld.nameString(Palworld.unwrap(rawKey))
            local value = Palworld.unwrap(rawValue)
            if name == nil or name == "None" or value == nil or names[name] then
                decodeError = "item filter category is invalid or duplicated"
                return
            end
            local typeA, typeAError = Palworld.readEnumSet(value.TypeA)
            local typeB, typeBError = Palworld.readEnumSet(value.TypeB)
            local typeBExcept, typeBExceptError =
                Palworld.readEnumSet(value.TypeB_Except)
            if typeA == nil or typeB == nil or typeBExcept == nil then
                decodeError = typeAError or typeBError or typeBExceptError
                return
            end
            names[name] = true
            categories[#categories + 1] = {
                name = name,
                typeA = typeA,
                typeB = typeB,
                typeBExcept = typeBExcept,
            }
        end)
    end)
    if not iterated or decodeError ~= nil or #categories == 0 then
        return nil, decodeError or "item filter categories cannot be enumerated"
    end
    cachedCategorySettingAddress = settingAddress
    cachedCategories = categories
    return categories, nil
end

function Palworld.itemCategory(categories, metadata)
    for _, category in ipairs(categories) do
        if next(category.typeB) ~= nil and category.typeB[metadata.typeB] then
            return category.name
        end
    end
    for _, category in ipairs(categories) do
        if next(category.typeB) == nil
            and category.typeA[metadata.typeA]
            and not category.typeBExcept[metadata.typeB] then
            return category.name
        end
    end
    return nil
end

local function isInstanceOf(object, classObject)
    if not Palworld.isValid(object) or not Palworld.isValid(classObject) then return false end
    local ok, result = pcall(function() return object:IsA(classObject) end)
    return ok and result == true
end

local cachedStorageClasses
local cachedIncubatorClass
local cachedGuildChestClass
local cachedRecyclerClass

local function destinationClassesAreValid(wantsRecycler)
    if type(cachedStorageClasses) ~= "table" or #cachedStorageClasses == 0 then
        return false
    end
    for _, classObject in ipairs(cachedStorageClasses) do
        if not Palworld.isValid(classObject) then return false end
    end
    return Palworld.isValid(cachedGuildChestClass)
        and (cachedIncubatorClass == nil or Palworld.isValid(cachedIncubatorClass))
        and (not wantsRecycler or Palworld.isValid(cachedRecyclerClass))
end

function Palworld.loadDestinationClasses(job)
    local wantsRecycler = true
    if destinationClassesAreValid(wantsRecycler) then
        job.storageClasses = cachedStorageClasses
        job.incubatorClass = cachedIncubatorClass
        job.guildChestClass = cachedGuildChestClass
        job.recyclerClass = wantsRecycler and cachedRecyclerClass or nil
        return true, nil
    end

    cachedStorageClasses = {}
    for _, path in ipairs(STORAGE_CLASS_PATHS) do
        local classObject = Palworld.staticObject(path)
        if classObject ~= nil then
            cachedStorageClasses[#cachedStorageClasses + 1] = classObject
        end
    end
    if #cachedStorageClasses == 0 then
        return false, "storage model classes are unavailable"
    end
    cachedIncubatorClass = Palworld.staticObject(INCUBATOR_CLASS_PATH)
    cachedGuildChestClass = Palworld.staticObject(GUILD_CHEST_CLASS_PATH)
    if wantsRecycler then
        cachedRecyclerClass = Palworld.staticObject(RECYCLER_CLASS_PATH)
    end
    if cachedGuildChestClass == nil then
        return false, "guild chest model class is unavailable"
    end
    job.storageClasses = cachedStorageClasses
    job.incubatorClass = cachedIncubatorClass
    job.guildChestClass = cachedGuildChestClass
    if wantsRecycler and cachedRecyclerClass == nil then
        return false, "Ancient Relic Recycler model class is unavailable"
    end
    job.recyclerClass = wantsRecycler and cachedRecyclerClass or nil
    return true, nil
end

function Palworld.destinationKind(job, concreteModel)
    if isInstanceOf(concreteModel, job.guildChestClass) then return nil end
    if job.recyclerClass ~= nil
        and isInstanceOf(concreteModel, job.recyclerClass) then return "recycler" end
    if job.incubatorClass ~= nil
        and isInstanceOf(concreteModel, job.incubatorClass) then return "incubator" end
    for _, classObject in ipairs(job.storageClasses) do
        if isInstanceOf(concreteModel, classObject) then return "storage" end
    end
    return nil
end

function Palworld.readFilterOff(container)
    local array
    local ok = pcall(function() array = container.FilterPreference.FilterOffList end)
    if not ok or array == nil then return nil, "container filter is unavailable" end
    return Palworld.readNameSet(array)
end

function Palworld.readPermission(container)
    local permission
    local typeAArray
    local typeBArray
    local itemIdArray
    local ok = pcall(function()
        permission = container.Permission
        typeAArray = permission.PermissionTypeA
        typeBArray = permission.PermissionTypeB
        itemIdArray = permission.PermissionItemStaticIds
    end)
    if not ok or permission == nil then return nil, "container permission is unavailable" end
    local typeA, typeAError = Palworld.readEnumSet(typeAArray)
    local typeB, typeBError = Palworld.readEnumSet(typeBArray)
    local itemIds, itemIdError = Palworld.readNameSet(itemIdArray)
    if typeA == nil or typeB == nil or itemIds == nil then
        return nil, typeAError or typeBError or itemIdError
    end
    return {
        typeA = typeA,
        typeB = typeB,
        itemIds = itemIds,
        restricted = next(typeA) ~= nil or next(typeB) ~= nil or next(itemIds) ~= nil,
    }, nil
end

function Palworld.destinationAllows(entry, item, metadata)
    if entry.isIncubator then return item.isEgg == true end
    if entry.isRecyclerBoost then
        return item.id == entry.boostItemId
    end
    if entry.isRecycler then
        return entry.permission ~= nil
            and entry.permission.itemIds[item.id] == true
    end
    if metadata == nil or metadata.category == nil
        or entry.filterOff == nil or entry.permission == nil then return false end
    if entry.filterOff[metadata.category] then return false end
    local permission = entry.permission
    if permission.restricted
        and not permission.typeA[metadata.typeA]
        and not permission.typeB[metadata.typeB]
        and not permission.itemIds[item.id] then
        return false
    end
    return true
end

return Palworld
