local NativeInput = {}

local state = {
    log = nil,
    loadAttempted = false,
    ready = false,
    active = false,
    faulted = false,
    path = nil,
    sentinel = {},
    nibbleArgs = {},
    exports = {},
    lastHeartbeatAt = 0.0,
}

for index = 1, 15 do state.nibbleArgs[index] = {} end

local function log(message)
    if type(state.log) == "function" then
        state.log("Quick Stack native settings input: " .. tostring(message))
    end
end

local function queryBoolean(fn)
    if type(fn) ~= "function" then return false end
    local called, value = pcall(fn, state.sentinel)
    return called and value == state.sentinel
end

local function queryNibble(fn)
    if type(fn) ~= "function" then return nil, "export-not-function" end
    local called, value = pcall(function()
        return select("#", fn(table.unpack(state.nibbleArgs)))
    end)
    if not called then return nil, "call-failed:" .. tostring(value) end
    if type(value) ~= "number" or value < 0 or value > 15 then
        return nil, "invalid-return:" .. tostring(value)
    end
    return value, nil
end

local function loadExport(exportName)
    if type(package) ~= "table" or type(package.loadlib) ~= "function"
        or type(state.path) ~= "string" then return nil end
    local loaded, functionOrError, loadError = pcall(
        package.loadlib, state.path, exportName)
    if not loaded or type(functionOrError) ~= "function" then
        log("export failed: " .. tostring(exportName) .. " -- "
            .. tostring(loadError or functionOrError))
        return nil
    end
    return functionOrError
end

local function initialize()
    if state.loadAttempted then return state.ready == true end
    state.loadAttempted = true
    if type(package) ~= "table" or type(package.searchpath) ~= "function"
        or type(package.loadlib) ~= "function" then
        log("Lua native-module loading is unavailable")
        return false
    end
    local searched, helperPath, searchError = pcall(package.searchpath,
        "PalInsightQuickStackSettingsInput", package.cpath)
    if not searched or type(helperPath) ~= "string" then
        log(tostring(searchError or helperPath or "DLL not found"))
        return false
    end
    local normalized = helperPath:gsub("/", "\\"):lower()
    local expected = "\\palinsightquickstack\\scripts"
        .. "\\palinsightquickstacksettingsinput.dll"
    if normalized:sub(-#expected) ~= expected then
        log("helper rejected outside this mod: " .. helperPath)
        return false
    end
    state.path = helperPath
    local names = {
        initialize = "pal_quick_stack_input_initialize",
        isHooked = "pal_quick_stack_input_is_hooked",
        isConnected = "pal_quick_stack_input_is_connected",
        modalOn = "pal_quick_stack_input_modal_on",
        modalOff = "pal_quick_stack_input_modal_off",
        heartbeat = "pal_quick_stack_input_heartbeat",
        takeWatchdogRelease = "pal_quick_stack_input_take_watchdog_release",
        shutdown = "pal_quick_stack_input_shutdown",
    }
    local exports = {}
    for key, exportName in pairs(names) do
        exports[key] = loadExport(exportName)
        if type(exports[key]) ~= "function" then return false end
    end
    exports.state = {}
    for index = 0, 5 do
        exports.state[index] = loadExport(
            "pal_quick_stack_input_state_" .. tostring(index))
        if type(exports.state[index]) ~= "function" then return false end
    end
    if not queryBoolean(exports.initialize)
        or not queryBoolean(exports.isHooked)
        or not queryBoolean(exports.modalOff) then
        queryBoolean(exports.shutdown)
        log("XInput hook initialization failed")
        return false
    end
    state.exports = exports
    state.ready = true
    state.faulted = false
    log("ready")
    return true
end

local function readSnapshot()
    if state.ready ~= true then return nil, "helper-not-ready" end
    local values = {}
    for index = 0, 5 do
        local value, failure = queryNibble(state.exports.state[index])
        if value == nil then
            return nil, "state_" .. tostring(index) .. ":" .. tostring(failure)
        end
        values[index] = value
    end
    local buttons = values[0] | (values[1] << 4)
        | (values[2] << 8) | (values[3] << 12)
    local left = values[5]
    return {
        connected = queryBoolean(state.exports.isConnected),
        buttons = buttons,
        leftX = (left & 0x4) ~= 0 and -1.0
            or (left & 0x8) ~= 0 and 1.0 or 0.0,
        leftY = (left & 0x2) ~= 0 and -1.0
            or (left & 0x1) ~= 0 and 1.0 or 0.0,
    }
end

function NativeInput.configure(logger)
    state.log = logger
end

function NativeInput.acquire()
    if state.active == true then return true, nil end
    if not initialize() then return false, "native helper is unavailable" end
    if not queryBoolean(state.exports.modalOn) then
        return false, "native modal filter could not be enabled"
    end
    state.active = true
    state.faulted = false
    state.lastHeartbeatAt = os.clock()
    if not queryBoolean(state.exports.heartbeat) then
        state.faulted = true
        NativeInput.release()
        return false, "native modal lease could not be started"
    end
    local snapshot, failure = readSnapshot()
    if type(snapshot) ~= "table" then
        state.faulted = true
        NativeInput.release()
        return false, "native controller state is unavailable: "
            .. tostring(failure)
    end
    return true, nil
end

function NativeInput.readSnapshot()
    if state.active ~= true then return nil, "native modal filter is inactive" end
    if queryBoolean(state.exports.takeWatchdogRelease) then
        state.active = false
        state.faulted = true
        return nil, "native modal lease expired"
    end
    local now = os.clock()
    if now - (state.lastHeartbeatAt or 0.0) >= 0.5 then
        if not queryBoolean(state.exports.heartbeat) then
            state.faulted = true
            return nil, "native modal heartbeat failed"
        end
        state.lastHeartbeatAt = now
    end
    local snapshot, failure = readSnapshot()
    if type(snapshot) ~= "table" then state.faulted = true end
    return snapshot, failure
end

function NativeInput.active()
    return state.active == true
end

function NativeInput.release()
    if state.active ~= true then return true end
    local released = queryBoolean(state.exports.modalOff)
    if not released then
        released = queryBoolean(loadExport("pal_quick_stack_input_modal_off"))
    end
    if not released then
        released = queryBoolean(state.exports.shutdown)
            or queryBoolean(loadExport("pal_quick_stack_input_shutdown"))
    end
    if not released then return false end
    state.active = false
    state.faulted = false
    state.lastHeartbeatAt = 0.0
    return true
end

function NativeInput.emergencyRelease()
    return NativeInput.release()
end

return NativeInput
