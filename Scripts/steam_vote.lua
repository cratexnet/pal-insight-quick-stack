local SteamVote = {}

SteamVote.statuses = {
    unavailable = 0,
    querying = 1,
    noVote = 2,
    down = 3,
    up = 4,
    settingUp = 5,
}

local state = {
    log = nil,
    loadAttempted = false,
    ready = false,
    polling = false,
    path = nil,
    sentinel = nil,
    nibbleArgs = {},
    exports = {},
}

local function log(message)
    if type(state.log) == "function" then state.log(tostring(message)) end
end

local function loadExport(exportName)
    if type(package) ~= "table" or type(package.loadlib) ~= "function"
        or type(state.path) ~= "string" then return nil end
    local loaded, functionOrError, loadError = pcall(
        package.loadlib, state.path, exportName)
    if loaded and type(functionOrError) == "function" then
        return functionOrError
    end
    log("Steam Workshop vote export failed: " .. tostring(exportName)
        .. " -- " .. tostring(loadError or functionOrError))
    return nil
end

local function readNibble(fn)
    if type(fn) ~= "function" then return nil end
    local called, value = pcall(function()
        return select("#", fn(table.unpack(state.nibbleArgs)))
    end)
    if not called or type(value) ~= "number" or value < 0 or value > 15 then
        return nil
    end
    return value
end

local function logNativeError()
    if state.ready ~= true then return false end
    local kind = readNibble(state.exports.errorKind) or 0
    if kind == 0 then return false end
    local low = readNibble(state.exports.errorLow) or 0
    local high = readNibble(state.exports.errorHigh) or 0
    local names = {
        [1] = "query-start", [2] = "query-result",
        [3] = "set-start", [4] = "set-result", [5] = "timeout",
    }
    log("Steam Workshop vote request failed: "
        .. tostring(names[kind] or kind) .. " (EResult "
        .. tostring(low | (high << 4)) .. ")")
    pcall(state.exports.clearError, state.sentinel)
    return true
end

function SteamVote.configure(logger)
    state.log = logger
end

function SteamVote.initialize()
    if state.loadAttempted then
        if state.ready then SteamVote.refresh() end
        return state.ready
    end
    state.loadAttempted = true
    if type(package) ~= "table" or type(package.searchpath) ~= "function"
        or type(package.loadlib) ~= "function" then return false end
    local searched, helperPath = pcall(package.searchpath,
        "PalInsightQuickStackSteamVote", package.cpath)
    if not searched or type(helperPath) ~= "string" then return false end
    local normalizedPath = helperPath:gsub("/", "\\"):lower()
    local expectedSuffix =
        "\\palinsightquickstack\\scripts\\palinsightquickstacksteamvote.dll"
    if normalizedPath:sub(-#expectedSuffix) ~= expectedSuffix then
        log("Steam Workshop vote helper rejected outside this mod: " .. helperPath)
        return false
    end
    state.path = helperPath
    state.sentinel = {}
    for index = 1, 15 do state.nibbleArgs[index] = {} end
    local names = {
        initialize = "pal_quick_stack_steam_vote_initialize",
        refresh = "pal_quick_stack_steam_vote_refresh",
        status = "pal_quick_stack_steam_vote_status",
        setUp = "pal_quick_stack_steam_vote_set_up",
        errorKind = "pal_quick_stack_steam_vote_error_kind",
        errorLow = "pal_quick_stack_steam_vote_error_result_low",
        errorHigh = "pal_quick_stack_steam_vote_error_result_high",
        clearError = "pal_quick_stack_steam_vote_clear_error",
    }
    for key, exportName in pairs(names) do
        state.exports[key] = loadExport(exportName)
        if type(state.exports[key]) ~= "function" then return false end
    end
    local called, value = pcall(state.exports.initialize, state.sentinel)
    if not called or value ~= state.sentinel then
        state.exports = {}
        return false
    end
    state.ready = true
    state.polling = true
    return true
end

function SteamVote.ready()
    return state.ready == true
end

function SteamVote.refresh()
    if state.ready ~= true then return false end
    local called, value = pcall(state.exports.refresh, state.sentinel)
    local started = called and value == state.sentinel
    if started then state.polling = true else logNativeError() end
    return started
end

function SteamVote.status()
    if state.ready ~= true then return nil end
    return readNibble(state.exports.status)
end

function SteamVote.polling()
    return state.polling == true
end

function SteamVote.poll()
    if state.ready ~= true or state.polling ~= true then return nil end
    local status = SteamVote.status()
    logNativeError()
    if status == SteamVote.statuses.noVote or status == SteamVote.statuses.down
        or status == SteamVote.statuses.up then state.polling = false end
    return status
end

function SteamVote.setUp()
    if state.ready ~= true then return false end
    local called, value = pcall(state.exports.setUp, state.sentinel)
    local started = called and value == state.sentinel
    if started then state.polling = true else logNativeError() end
    return started
end

function SteamVote.assetPath(fileName)
    local approved = {
        ["thumb-up-outline.png"] = true,
        ["thumb-up-filled.png"] = true,
        ["thumb-down-filled.png"] = true,
    }
    if approved[fileName] ~= true or type(package) ~= "table"
        or type(package.searchpath) ~= "function" then return nil end
    local searched, modulePath = pcall(package.searchpath, "steam_vote", package.path)
    if not searched or type(modulePath) ~= "string" then return nil end
    local scriptsDirectory = modulePath:match("^(.*)[/\\][^/\\]+$")
    local modDirectory = scriptsDirectory
        and scriptsDirectory:match("^(.*)[/\\][Ss]cripts$") or nil
    if type(modDirectory) ~= "string" or modDirectory == "" then return nil end
    return modDirectory .. "/assets/steam-workshop-feedback/" .. fileName
end

return SteamVote
