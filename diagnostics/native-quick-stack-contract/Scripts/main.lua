local TAG = "[PIQS-NATIVE-CONTRACT-c3d8]"

local TARGETS = {
    {
        name = "PalBaseCampUtility.RequestMoveInventoryItemToBaseCamp",
        paths = {
            "/Script/Pal.PalBaseCampUtility:RequestMoveInventoryItemToBaseCamp",
            "/Script/Pal.PalBaseCampUtility.RequestMoveInventoryItemToBaseCamp",
        },
    },
    {
        name = "PalUIBaseCampItemDispenserModel.RequestMoveInventoryItemToBaseCamp",
        paths = {
            "/Script/Pal.PalUIBaseCampItemDispenserModel:RequestMoveInventoryItemToBaseCamp",
            "/Script/Pal.PalUIBaseCampItemDispenserModel.RequestMoveInventoryItemToBaseCamp",
        },
    },
    {
        name = "PalBaseCampUtility.RequestStartReplicateLocalPlayerBaseCampItemStackInfo",
        paths = {
            "/Script/Pal.PalBaseCampUtility:RequestStartReplicateLocalPlayerBaseCampItemStackInfo",
            "/Script/Pal.PalBaseCampUtility.RequestStartReplicateLocalPlayerBaseCampItemStackInfo",
        },
    },
    {
        name = "PalBaseCampUtility.CallOrRegisterOnReadyLocalPlayerBaseCampItemStackInfo",
        paths = {
            "/Script/Pal.PalBaseCampUtility:CallOrRegisterOnReadyLocalPlayerBaseCampItemStackInfo",
            "/Script/Pal.PalBaseCampUtility.CallOrRegisterOnReadyLocalPlayerBaseCampItemStackInfo",
        },
    },
    {
        name = "PalItemUtility.CollectLocalPlayerQuickStackTargetItemInfos",
        paths = {
            "/Script/Pal.PalItemUtility:CollectLocalPlayerQuickStackTargetItemInfos",
            "/Script/Pal.PalItemUtility.CollectLocalPlayerQuickStackTargetItemInfos",
        },
    },
    {
        name = "PalBaseCampUtility.RequestEndReplicateLocalPlayerBaseCampItemStackInfo",
        paths = {
            "/Script/Pal.PalBaseCampUtility:RequestEndReplicateLocalPlayerBaseCampItemStackInfo",
            "/Script/Pal.PalBaseCampUtility.RequestEndReplicateLocalPlayerBaseCampItemStackInfo",
        },
    },
}

local function log(message)
    print(TAG .. "|" .. tostring(message) .. "\n")
end

local function isValid(object)
    if object == nil then return false end
    local ok, result = pcall(function() return object:IsValid() end)
    return ok and result == true
end

local function fnameToString(value)
    local result
    pcall(function() result = value:ToString() end)
    return result or "?"
end

local function objectName(object)
    local result
    pcall(function() result = fnameToString(object:GetFName()) end)
    return result or "?"
end

local function propertyClassName(property)
    local result
    pcall(function() result = fnameToString(property:GetClass():GetFName()) end)
    return result or "?"
end

local function structName(property)
    local result
    pcall(function() result = objectName(property:GetStruct()) end)
    return result
end

local function describeProperty(property)
    local className = propertyClassName(property)
    local detail
    if className == "ArrayProperty" then
        pcall(function()
            local inner = property:GetInner()
            local innerClass = propertyClassName(inner)
            detail = innerClass
            if innerClass == "StructProperty" then
                detail = detail .. "<" .. tostring(structName(inner) or "?") .. ">"
            end
        end)
    elseif className == "StructProperty" then
        detail = structName(property)
    elseif className == "ObjectProperty" or className == "InterfaceProperty" then
        pcall(function() detail = objectName(property:GetPropertyClass()) end)
    end
    if detail and detail ~= "" then className = className .. "<" .. detail .. ">" end
    return objectName(property), className
end

local function resolveTarget(target)
    for _, path in ipairs(target.paths) do
        local object
        local ok = pcall(function() object = StaticFindObject(path) end)
        if ok and isValid(object) then return object, path end
    end
    return nil, nil
end

local function inspectTarget(target)
    local targetFunction, path = resolveTarget(target)
    if targetFunction == nil then
        log("FUNCTION|name=" .. target.name .. "|status=not-found")
        return
    end
    local flags = "?"
    pcall(function() flags = string.format("0x%X", targetFunction:GetFunctionFlags()) end)
    log("FUNCTION|name=" .. target.name .. "|status=found|path=" .. path
        .. "|flags=" .. flags)
    local propertyCount = 0
    local ok, errorMessage = pcall(function()
        targetFunction:ForEachProperty(function(property)
            propertyCount = propertyCount + 1
            local name, className = describeProperty(property)
            log(string.format("PARAM|function=%s|index=%d|name=%s|type=%s",
                target.name,
                propertyCount,
                name,
                className))
        end)
    end)
    if not ok then
        log("FUNCTION|name=" .. target.name .. "|status=property-error|error="
            .. tostring(errorMessage))
        return
    end
    log("FUNCTION|name=" .. target.name .. "|status=complete|count="
        .. tostring(propertyCount))
end

local function runProbe()
    log("BEGIN")
    pcall(function()
        if UE4SS ~= nil and UE4SS.GetVersion ~= nil then
            local major, minor, hotfix = UE4SS.GetVersion()
            log(string.format("UE4SS|version=%d.%d.%d", major, minor, hotfix))
        end
    end)
    for _, target in ipairs(TARGETS) do inspectTarget(target) end
    log("END")
end

ExecuteWithDelay(1000, function()
    ExecuteInGameThread(function()
        local ok, errorMessage = pcall(runProbe)
        if not ok then log("ERROR|unhandled=" .. tostring(errorMessage)) end
    end)
end)
