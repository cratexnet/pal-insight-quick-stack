local TAG = "[PalInsightQuickStack][RpcContractProbe] "
local TARGET_FUNCTION = "RequestMoveToContainer_ToServer"
local TARGET_PATHS = {
    "/Script/Pal.PalNetworkItemComponent:RequestMoveToContainer_ToServer",
    "/Script/Pal.PalNetworkItemComponent.RequestMoveToContainer_ToServer",
}

local function log(message)
    print(TAG .. tostring(message) .. "\n")
end

local function isValid(object)
    if object == nil then
        return false
    end

    local ok, result = pcall(function()
        return object:IsValid()
    end)
    return ok and result == true
end

local function fnameToString(value)
    local result
    pcall(function()
        result = value:ToString()
    end)
    return result or "?"
end

local function objectName(object)
    local result
    pcall(function()
        result = fnameToString(object:GetFName())
    end)
    return result or "?"
end

local function propertyClassName(property)
    local result
    pcall(function()
        result = fnameToString(property:GetClass():GetFName())
    end)
    return result or "?"
end

local function structName(property)
    local result
    pcall(function()
        result = objectName(property:GetStruct())
    end)
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
    elseif className == "ObjectProperty" then
        pcall(function()
            detail = objectName(property:GetPropertyClass())
        end)
    end

    if detail and detail ~= "" then
        className = className .. "<" .. detail .. ">"
    end

    return objectName(property), className
end

local function runProbe()
    log("BEGIN")

    pcall(function()
        if UE4SS ~= nil and UE4SS.GetVersion ~= nil then
            local major, minor, hotfix = UE4SS.GetVersion()
            log(string.format("UE4SS=%d.%d.%d", major, minor, hotfix))
        end
    end)

    local targetFunction
    local functionErrors = {}
    for _, path in ipairs(TARGET_PATHS) do
        local functionOk, functionError = pcall(function()
            targetFunction = StaticFindObject(path)
        end)
        if functionOk and isValid(targetFunction) then
            log("PATH|" .. path)
            break
        end
        targetFunction = nil
        functionErrors[#functionErrors + 1] = path .. "=" .. tostring(functionError)
    end
    if not isValid(targetFunction) then
        log("ERROR|function-not-found|" .. table.concat(functionErrors, ";"))
        log("END|failure")
        return
    end

    local flags = "?"
    pcall(function()
        flags = string.format("0x%X", targetFunction:GetFunctionFlags())
    end)
    log("FUNCTION|" .. TARGET_FUNCTION .. "|flags=" .. flags)

    local propertyCount = 0
    local propertyOk, propertyError = pcall(function()
        targetFunction:ForEachProperty(function(property)
            propertyCount = propertyCount + 1
            local name, className = describeProperty(property)
            log(string.format("PARAM|%d|%s|%s", propertyCount, name, className))
        end)
    end)
    if not propertyOk then
        log("ERROR|property-enumeration|" .. tostring(propertyError))
        log("END|failure")
        return
    end

    log("END|success|count=" .. tostring(propertyCount))
end

ExecuteWithDelay(1000, function()
    ExecuteInGameThread(function()
        local ok, errorMessage = pcall(runProbe)
        if not ok then
            log("ERROR|unhandled|" .. tostring(errorMessage))
            log("END|failure")
        end
    end)
end)
