local Settings = require("settings")
local QuickStack = require("quick_stack")
local Palworld = require("palworld")
local Notifications = require("notifications")

local TAG = "[PalInsightQuickStack] "
local VERSION = "0.1.0-beta.1"
local SHARED_API_VERSION = 1
local SHARED_PREFIX = "PalInsightQuickStack."
local SHARED_POLL_MS = 500

local state = {
    config = nil,
    configPath = nil,
    bindingSignature = nil,
    inputDispatchPending = false,
    resultCloseDispatchPending = false,
    sharedRevision = nil,
    sharedPolling = false,
}

local function log(message)
    print(TAG .. tostring(message) .. "\n")
end

local function debugLog(message)
    if state.config == nil or state.config.Debug ~= true then return end
    if type(message) == "function" then message = message() end
    log("debug: " .. tostring(message))
end

local function dispatchConfiguredPress()
    if state.inputDispatchPending then return end
    state.inputDispatchPending = true
    local scheduled = pcall(ExecuteInGameThread, function()
        state.inputDispatchPending = false
        local ok, errorMessage = pcall(QuickStack.begin)
        if not ok then log("input error: " .. tostring(errorMessage)) end
    end)
    if not scheduled then
        state.inputDispatchPending = false
        log("cannot dispatch shortcut to the game thread")
    end
end

local function dispatchResultClosePress()
    if state.resultCloseDispatchPending
        or not Notifications.hasInteractiveResult() then return end
    state.resultCloseDispatchPending = true
    local scheduled = pcall(ExecuteInGameThread, function()
        state.resultCloseDispatchPending = false
        local ok, errorMessage = pcall(Notifications.closeIfHovered)
        if not ok then log("result close input error: " .. tostring(errorMessage)) end
    end)
    if not scheduled then
        state.resultCloseDispatchPending = false
        log("cannot dispatch result close input to the game thread")
    end
end

local function registerResultCloseInput()
    if type(RegisterKeyBind) ~= "function" or type(Key) ~= "table"
        or Key.LEFT_MOUSE_BUTTON == nil then
        return false, "left-mouse keybind API is unavailable"
    end
    local ok, errorMessage = pcall(RegisterKeyBind,
        Key.LEFT_MOUSE_BUTTON, dispatchResultClosePress)
    if not ok then return false, errorMessage end
    return true, nil
end

local function registerConfiguredKey(config)
    config = config or state.config
    if type(RegisterKeyBind) ~= "function" or type(Key) ~= "table" then
        return false, "UE4SS keybind API is unavailable"
    end
    local keyValue = Settings.keyValue(config.Key)
    if keyValue == nil then return false, "configured key is unavailable" end
    local signature = Settings.chordSignature(config)
    if state.bindingSignature == signature then return true, nil end
    local callback = function()
        if state.bindingSignature ~= signature then return end
        dispatchConfiguredPress()
    end
    local modifiers = Settings.modifierValues(config)
    local ok, errorMessage = pcall(function()
        if #modifiers > 0 then
            RegisterKeyBind(keyValue, modifiers, callback)
        else
            RegisterKeyBind(keyValue, callback)
        end
    end)
    if not ok then return false, errorMessage end
    state.bindingSignature = signature
    return true, nil
end

local function sharedRead(name)
    if ModRef == nil then return nil, false end
    local ok, value = pcall(function()
        return ModRef:GetSharedVariable(SHARED_PREFIX .. name)
    end)
    return value, ok
end

local function sharedWrite(name, value)
    if ModRef == nil then return false end
    return pcall(function()
        ModRef:SetSharedVariable(SHARED_PREFIX .. name, value)
    end)
end

local function revisionValue(value)
    if type(value) ~= "number" or value < 0 or value % 1 ~= 0 then return nil end
    return value
end

local function publishCanonicalShortcut(revision)
    local values = {
        { "ApiVersion", SHARED_API_VERSION },
        { "RuntimeVersion", VERSION },
        { "Key", state.config.Key },
        { "Shift", state.config.Shift },
        { "Ctrl", state.config.Ctrl },
        { "Alt", state.config.Alt },
    }
    for _, entry in ipairs(values) do
        if not sharedWrite(entry[1], entry[2]) then return false end
    end
    if not sharedWrite("SettingsRevision", revision) then return false end
    state.sharedRevision = revision
    return true
end

local function requestedSharedShortcut()
    local key, keyOk = sharedRead("Key")
    local shift, shiftOk = sharedRead("Shift")
    local ctrl, ctrlOk = sharedRead("Ctrl")
    local alt, altOk = sharedRead("Alt")
    if not keyOk or not shiftOk or not ctrlOk or not altOk then
        return nil, "shared values are unavailable"
    end
    return Settings.validateShortcut({
        Key = key,
        Shift = shift,
        Ctrl = ctrl,
        Alt = alt,
    })
end

local function reconcileSharedShortcut()
    local incoming = revisionValue(select(1, sharedRead("SettingsRevision")))
    if incoming == nil or incoming == state.sharedRevision then return end
    local acknowledgement = math.max(incoming, state.sharedRevision or 0) + 1
    local requested, validationError = requestedSharedShortcut()
    if requested == nil then
        log("Pal Insight shortcut request rejected: " .. tostring(validationError))
        publishCanonicalShortcut(acknowledgement)
        return
    end

    if Settings.chordSignature(requested) == state.bindingSignature then
        publishCanonicalShortcut(acknowledgement)
        return
    end

    local previous = {
        Key = state.config.Key,
        Shift = state.config.Shift,
        Ctrl = state.config.Ctrl,
        Alt = state.config.Alt,
    }
    local previousSignature = state.bindingSignature
    state.config.Key = requested.Key
    state.config.Shift = requested.Shift
    state.config.Ctrl = requested.Ctrl
    state.config.Alt = requested.Alt

    local registered, registerError = registerConfiguredKey(state.config)
    local saved, saveError = false, nil
    if registered then saved, saveError = Settings.save(state.configPath, state.config) end
    if not registered or not saved then
        state.config.Key = previous.Key
        state.config.Shift = previous.Shift
        state.config.Ctrl = previous.Ctrl
        state.config.Alt = previous.Alt
        state.bindingSignature = previousSignature
        log("Pal Insight shortcut request rejected: "
            .. tostring(registerError or saveError or "cannot apply shortcut"))
        publishCanonicalShortcut(acknowledgement)
        return
    end

    log("shortcut updated by Pal Insight: " .. Settings.chordSignature(state.config))
    publishCanonicalShortcut(acknowledgement)
end

local function scheduleSharedPoll()
    if state.sharedPolling or type(ExecuteWithDelay) ~= "function" then return false end
    state.sharedPolling = true
    local function poll()
        state.sharedPolling = false
        local ok, errorMessage = pcall(reconcileSharedShortcut)
        if not ok then log("shortcut integration error: " .. tostring(errorMessage)) end
        scheduleSharedPoll()
    end
    local scheduled = pcall(ExecuteWithDelay, SHARED_POLL_MS, poll)
    if not scheduled then state.sharedPolling = false end
    return scheduled
end

state.config, state.configPath = Settings.load(log)
QuickStack.configure(state.config, log, debugLog)

local resultCloseReady, resultCloseError = registerResultCloseInput()
Notifications.setCloseInputAvailable(resultCloseReady)
if not resultCloseReady then
    log("result close button unavailable: " .. tostring(resultCloseError))
end

local inputTrackingReady, inputTrackingError = Palworld.installInputUiTracking()
if not inputTrackingReady then
    log("inventory-page shortcut unavailable: " .. tostring(inputTrackingError))
end

local registered, registerError = registerConfiguredKey()
if not registered then
    log("load failed: " .. tostring(registerError))
else
    log("loaded " .. VERSION .. " -- " .. Settings.chordSignature(state.config)
        .. " quick-stacks inside the current base")
end

if registered then
    local existingRevision = revisionValue(
        select(1, sharedRead("SettingsRevision"))) or 0
    if publishCanonicalShortcut(existingRevision + 1) then
        scheduleSharedPoll()
    end
end
