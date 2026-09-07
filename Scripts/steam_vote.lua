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
    presenceChecked = false,
    present = false,
    ready = false,
    polling = false,
    resolvedStatus = nil,
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

function SteamVote.present()
    if state.presenceChecked then return state.present == true end
    state.presenceChecked = true
    -- 只加载本模块 Scripts 旁的专属依赖，不依赖安装目录名称或全局 cpath。
    local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
    local directory = source:match("^(.*)/[^/]+$")
    if directory == nil then return false end
    local helperPath = directory .. "/PalInsightQuickStackSteamVote.dll"
    local file = io.open(helperPath, "rb")
    if file == nil then
        log("Steam Workshop vote helper is not installed")
        return false
    end
    file:close()
    state.path = helperPath
    state.present = true
    return true
end

function SteamVote.initialize()
    if state.loadAttempted then
        return state.ready
    end
    state.loadAttempted = true
    if type(package) ~= "table" or type(package.loadlib) ~= "function"
        or not SteamVote.present() then return false end
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
    local failed = logNativeError()
    if status == SteamVote.statuses.noVote or status == SteamVote.statuses.down
        or status == SteamVote.statuses.up then
        state.resolvedStatus = status
        state.polling = false
    elseif failed and state.resolvedStatus ~= SteamVote.statuses.noVote
        and state.resolvedStatus ~= SteamVote.statuses.down
        and state.resolvedStatus ~= SteamVote.statuses.up then
        state.resolvedStatus = SteamVote.statuses.unavailable
        state.polling = false
    elseif failed then
        state.polling = false
    end
    return status
end

function SteamVote.resolvedStatus()
    return state.resolvedStatus
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
