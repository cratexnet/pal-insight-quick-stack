local TAG = "[PIQS-RELIC-CONTRACT-7f31]"

local FUNCTIONS = {
    {
        name = "PalMapObjectRecyclerModel.IsValidRelicItem",
        paths = {
            "/Script/Pal.PalMapObjectRecyclerModel:IsValidRelicItem",
            "/Script/Pal.PalMapObjectRecyclerModel.IsValidRelicItem",
            "/Script/Pal.PalMapObjectRecyclerParameterComponent:IsValidRelicItem",
            "/Script/Pal.PalMapObjectRecyclerParameterComponent.IsValidRelicItem",
            "/Script/Pal.PalUIMapObjectRecyclerModel:IsValidRelicItem",
            "/Script/Pal.PalUIMapObjectRecyclerModel.IsValidRelicItem",
        },
    },
    {
        name = "PalMapObjectRecyclerModel.GetRelicItemContainer",
        paths = {
            "/Script/Pal.PalMapObjectRecyclerModel:GetRelicItemContainer",
            "/Script/Pal.PalMapObjectRecyclerModel.GetRelicItemContainer",
        },
    },
    {
        name = "PalUIMapObjectRecyclerModel.GetRelicItemContainer",
        paths = {
            "/Script/Pal.PalUIMapObjectRecyclerModel:GetRelicItemContainer",
            "/Script/Pal.PalUIMapObjectRecyclerModel.GetRelicItemContainer",
        },
    },
    {
        name = "PalMapObjectRecyclerModel.GetCurrentRelicItemId",
        paths = {
            "/Script/Pal.PalMapObjectRecyclerModel:GetCurrentRelicItemId",
            "/Script/Pal.PalMapObjectRecyclerModel.GetCurrentRelicItemId",
        },
    },
}

local CLASSES = {
    "/Script/Pal.PalMapObjectRecyclerModel",
    "/Script/Pal.PalMapObjectRecyclerParameterComponent",
    "/Script/Pal.PalUIMapObjectRecyclerModel",
}

local PARAMETER_PATHS = {
    "/Game/Pal/Blueprint/MapObject/BuildObject/BP_BuildObject_AncientRelicRecycler.BP_BuildObject_AncientRelicRecycler_C:RecyclerParameter_GEN_VARIABLE",
    "/Game/Pal/Blueprint/MapObject/BuildObject/BP_BuildObject_AncientRelicRecycler.Default__BP_BuildObject_AncientRelicRecycler_C:RecyclerParameter",
}

local function log(message)
    print(TAG .. "|" .. tostring(message) .. "\n")
end

local function isValid(object)
    if object == nil then return false end
    local ok, result = pcall(function() return object:IsValid() end)
    return ok and result == true
end

local function nameString(value)
    local result
    pcall(function() result = value:ToString() end)
    return type(result) == "string" and result or "?"
end

local function objectName(object)
    local result
    pcall(function() result = nameString(object:GetFName()) end)
    return result or "?"
end

local function propertyClassName(property)
    local result
    pcall(function() result = nameString(property:GetClass():GetFName()) end)
    return result or "?"
end

local function describeProperty(property)
    local propertyName = objectName(property)
    local className = propertyClassName(property)
    local detail
    if className == "StructProperty" then
        pcall(function() detail = objectName(property:GetStruct()) end)
    elseif className == "ObjectProperty" or className == "InterfaceProperty" then
        pcall(function() detail = objectName(property:GetPropertyClass()) end)
    elseif className == "ArrayProperty" then
        pcall(function()
            local inner = property:GetInner()
            detail = propertyClassName(inner)
            if detail == "StructProperty" then
                detail = detail .. "<" .. objectName(inner:GetStruct()) .. ">"
            end
        end)
    end
    if type(detail) == "string" and detail ~= "" then
        className = className .. "<" .. detail .. ">"
    end
    return propertyName, className
end

local function findObject(paths)
    for _, path in ipairs(paths) do
        local object
        local ok = pcall(function() object = StaticFindObject(path) end)
        if ok and isValid(object) then return object, path end
    end
    return nil, nil
end

local function inspectFunction(target)
    local fn, path = findObject(target.paths)
    if fn == nil then
        log("FUNCTION|name=" .. target.name .. "|status=not-found")
        return
    end
    local flags = "?"
    pcall(function() flags = string.format("0x%X", fn:GetFunctionFlags()) end)
    log("FUNCTION|name=" .. target.name .. "|status=found|path=" .. path
        .. "|flags=" .. flags)
    local count = 0
    local ok, errorMessage = pcall(function()
        fn:ForEachProperty(function(property)
            count = count + 1
            local propertyName, className = describeProperty(property)
            log(string.format("PARAM|function=%s|index=%d|name=%s|type=%s",
                target.name, count, propertyName, className))
        end)
    end)
    if not ok then
        log("FUNCTION|name=" .. target.name .. "|status=property-error|error="
            .. tostring(errorMessage))
        return
    end
    log("FUNCTION|name=" .. target.name .. "|status=complete|count=" .. count)
end

local function inspectClass(path)
    local class = findObject({ path })
    if class == nil then
        log("CLASS|path=" .. path .. "|status=not-found")
        return
    end
    log("CLASS|path=" .. path .. "|status=found")
    local count = 0
    local ok, errorMessage = pcall(function()
        class:ForEachProperty(function(property)
            count = count + 1
            local propertyName, className = describeProperty(property)
            log(string.format("PROPERTY|class=%s|index=%d|name=%s|type=%s",
                path, count, propertyName, className))
        end)
    end)
    if not ok then
        log("CLASS|path=" .. path .. "|status=property-error|error="
            .. tostring(errorMessage))
        return
    end
    log("CLASS|path=" .. path .. "|status=complete|count=" .. count)
end

local function inspectLiveModel()
    if type(FindFirstOf) ~= "function" then
        return false
    end
    local model
    local found = pcall(function() model = FindFirstOf("PalMapObjectRecyclerModel") end)
    if not found or not isValid(model) then
        return false
    end
    local address = "?"
    pcall(function() address = tostring(model:GetAddress()) end)
    log("LIVE|status=found|name=" .. objectName(model) .. "|address=" .. address)
    for _, field in ipairs({
        "RelicItemContainer", "BoostItemContainer", "RelicItemSlotCount",
    }) do
        local value
        local ok, errorMessage = pcall(function() value = model[field] end)
        log("LIVE_FIELD|name=" .. field .. "|status=" .. (ok and "read" or "error")
            .. "|valid=" .. tostring(isValid(value))
            .. (ok and "" or "|error=" .. tostring(errorMessage)))
    end
    local container
    local containerOk, containerError = pcall(function()
        container = model:GetRelicItemContainer()
    end)
    log("LIVE_CALL|name=GetRelicItemContainer|status="
        .. (containerOk and "called" or "error")
        .. "|valid=" .. tostring(isValid(container))
        .. (containerOk and "" or "|error=" .. tostring(containerError)))
    if isValid(container) then
        local slotCount = "?"
        local permissionItems = "?"
        pcall(function() slotCount = tostring(container.ItemSlotArray:GetArrayNum()) end)
        pcall(function()
            permissionItems = tostring(
                container.Permission.PermissionItemStaticIds:GetArrayNum())
        end)
        log("LIVE_CONTAINER|slots=" .. slotCount
            .. "|permission_item_ids=" .. permissionItems)
        local enumerated, enumerateError = pcall(function()
            local ids = container.Permission.PermissionItemStaticIds
            local count = ids:GetArrayNum()
            for index = 1, count do
                local raw = ids[index]
                local value = raw
                pcall(function() value = raw:get() end)
                log("LIVE_PERMISSION_ITEM|index=" .. index
                    .. "|item=" .. nameString(value))
            end
        end)
        log("LIVE_PERMISSION_ITEMS|status="
            .. (enumerated and "complete" or "error")
            .. (enumerated and "" or "|error=" .. tostring(enumerateError)))
    end
    local boostContainer
    local boostOk, boostError = pcall(function()
        boostContainer = model.BoostItemContainer
    end)
    local boostSlots = "?"
    local boostPermissionItems = "?"
    if isValid(boostContainer) then
        pcall(function()
            boostSlots = tostring(boostContainer.ItemSlotArray:GetArrayNum())
        end)
        pcall(function()
            boostPermissionItems = tostring(
                boostContainer.Permission.PermissionItemStaticIds:GetArrayNum())
        end)
    end
    log("LIVE_BOOST_CONTAINER|status=" .. (boostOk and "read" or "error")
        .. "|valid=" .. tostring(isValid(boostContainer))
        .. "|slots=" .. boostSlots
        .. "|permission_item_ids=" .. boostPermissionItems
        .. (boostOk and "" or "|error=" .. tostring(boostError)))
    return true
end

local function inspectParameterSettings()
    for _, path in ipairs(PARAMETER_PATHS) do
        local parameter = findObject({ path })
        if parameter ~= nil then
            local count = 0
            local iterated, errorMessage = pcall(function()
                parameter.RelicItemSettings:ForEach(function(rawKey)
                    local key = rawKey
                    pcall(function() key = rawKey.Key end)
                    count = count + 1
                    log("RELIC_SETTING|index=" .. count
                        .. "|item=" .. nameString(key))
                end)
            end)
            log("RELIC_SETTINGS|path=" .. path
                .. "|status=" .. (iterated and "complete" or "error")
                .. "|count=" .. count
                .. (iterated and "" or "|error=" .. tostring(errorMessage)))
            return iterated and count > 0
        end
    end
    log("RELIC_SETTINGS|status=not-found")
    return false
end

local LIVE_RETRY_LIMIT = 120
local liveAttempt = 0

local function inspectLiveModelWhenReady()
    liveAttempt = liveAttempt + 1
    if inspectLiveModel() then
        log("LIVE|status=complete|attempt=" .. liveAttempt)
        log("END")
        return
    end
    if liveAttempt >= LIVE_RETRY_LIMIT then
        log("LIVE|status=timeout|attempts=" .. liveAttempt)
        log("END")
        return
    end
    ExecuteWithDelay(2000, function()
        ExecuteInGameThread(function()
            local ok, errorMessage = pcall(inspectLiveModelWhenReady)
            if not ok then log("ERROR|live=" .. tostring(errorMessage)) end
        end)
    end)
end

local function runProbe()
    log("BEGIN")
    for _, target in ipairs(FUNCTIONS) do inspectFunction(target) end
    for _, path in ipairs(CLASSES) do inspectClass(path) end
    inspectParameterSettings()
    log("STATIC_END")
    inspectLiveModelWhenReady()
end

ExecuteWithDelay(1000, function()
    ExecuteInGameThread(function()
        local ok, errorMessage = pcall(runProbe)
        if not ok then log("ERROR|unhandled=" .. tostring(errorMessage)) end
    end)
end)
