-- UE4SS treats enabled.txt as an independent activation path, so an old
-- marker can start this script even when Palworld wrote
-- `PalInsightQuickStack : 0` to mods.txt. Respect that explicit user choice
-- before loading modules or initializing any recurring work.
do
    local function explicitlyDisabledByModsTxt()
        local inspected, info = pcall(function()
            return debug.getinfo(1, "S")
        end)
        local source = inspected and info ~= nil and info.source or nil
        if type(source) ~= "string" or source == ""
            or source:sub(1, 1) == "=" then
            return false
        end
        if source:sub(1, 1) == "@" then source = source:sub(2) end

        local scriptsDirectory = source:match("^(.*)[/\\][^/\\]+$")
        local modDirectory = scriptsDirectory ~= nil
            and scriptsDirectory:match("^(.*)[/\\][^/\\]+$") or nil
        local modsDirectory = modDirectory ~= nil
            and modDirectory:match("^(.*)[/\\][^/\\]+$") or nil
        if modsDirectory == nil or modsDirectory == "" then return false end

        local opened, file = pcall(function()
            return io.open(modsDirectory .. "/mods.txt", "r")
        end)
        if not opened or file == nil then return false end

        local read, content = pcall(function() return file:read("*a") end)
        pcall(function() file:close() end)
        if not read or type(content) ~= "string" then return false end

        local configured = nil
        for line in content:gmatch("[^\r\n]+") do
            line = line:gsub("^\239\187\191", "")
            line = line:gsub("%s*[;#].*$", "")
            local name, enabled = line:match(
                "^%s*([^:]+)%s*:%s*([01])%s*$")
            if name ~= nil then
                name = name:match("^%s*(.-)%s*$")
                if name:lower() == "palinsightquickstack" then
                    configured = enabled
                end
            end
        end
        return configured == "0"
    end

    if explicitlyDisabledByModsTxt() then
        print("[PalInsightQuickStack] runtime disabled by mods.txt; initialization skipped")
        return
    end
end

local Settings = require("settings")
local SettingsUI = require("settings_ui")
local QuickStack = require("quick_stack")
local Palworld = require("palworld")

local TAG = "[PalInsightQuickStack] "
local VERSION = "1.0.0"
local SHARED_API_VERSION = 3
local SHARED_PREFIX = "PalInsightQuickStack."
local SETTINGS_HOST_PROTOCOL_VERSION = 3
local SETTINGS_HOST_PREFIX = "PalInsightSettingsHost."
local SETTINGS_HOST_LEASE_SECONDS = 1.5
local SHARED_POLL_MS = 500
local HOST_ACTIVITY_POLL_MS = 80
local HOST_REQUEST_POLL_MS = 16
local INTEGRATION_PERFORMANCE_SAMPLES = 40
local SHARED_BOOLEAN_SETTINGS = {
    { shared = "IncludeExcludedItems", config = "IncludeExcludedItems" },
    { shared = "IncludeNewItems", config = "IncludeNewItems" },
    { shared = "IncludeGuildChest", config = "IncludeGuildChest" },
}
local SHARED_STRING_SETTINGS = {
    { shared = "ResultDisplay", config = "ResultDisplay",
        validate = Settings.validateResultDisplay },
    { shared = "PalEggRouting", config = "PalEggRouting",
        validate = Settings.validatePalEggRouting },
    { shared = "RelicRouting", config = "RelicRouting",
        validate = Settings.validateRelicRouting },
}
local SHARED_NUMBER_SETTINGS = {
    { shared = "WorldTreeHolyWaterMinimum",
        config = "WorldTreeHolyWaterMinimum",
        validate = Settings.validateWorldTreeHolyWaterMinimum },
}

local runtimeIsSuperseded

local state = {
    config = nil,
    configPath = nil,
    bindingSignature = nil,
    registeredShortcutBindings = {},
    shortcutConflictLoggedSignature = nil,
    inputDispatchPending = false,
    inputDispatchCallback = nil,
    settingsInputDispatchPending = false,
    settingsInputDispatchCallback = nil,
    sharedRevision = nil,
    sharedPolling = false,
    sharedPollHandle = nil,
    sharedPollCallback = nil,
    hostActivityPolling = false,
    hostActivityPollHandle = nil,
    hostActivityPollCallback = nil,
    hostActivityLastProbeAt = 0.0,
    hostActivityHostLive = false,
    hostActivityHostSettingsOpen = false,
    settingsShortcutRegistered = false,
    settingsShortcutCallback = nil,
    settingsHostOpenRevision = 0,
    settingsHostCloseRevision = 0,
    settingsSelfToggleRevision = 0,
    settingsHostRequestSignalRevision = 0,
    settingsHostGeneration = 0,
    settingsHostLivenessRevision = 0,
    settingsHostPanelRevision = nil,
    settingsHostPanelHostGeneration = nil,
    settingsHostPanelInputRoute = nil,
    pendingSettingsHostCloseAck = nil,
    settingsPrewarmPending = false,
    settingsPrewarmCallback = nil,
    performanceCaptureEnabled = false,
    integrationPerformance = nil,
    superseded = false,
    supersededLogged = false,
}

local function log(message)
    print(TAG .. tostring(message) .. "\n")
end

local function debugLog(message)
    if state.config == nil or state.config.Debug ~= true then return end
    if type(message) == "function" then message = message() end
    log("debug: " .. tostring(message))
end

local function configureIntegrationPerformance()
    local enabled = state.config ~= nil
        and state.config.PerformanceCapture == true
    if enabled == state.performanceCaptureEnabled then return end
    state.performanceCaptureEnabled = enabled
    state.integrationPerformance = enabled and {
        startedAt = os.clock(),
        sharedSamples = 0,
        sharedTotalMs = 0,
        sharedMaxMs = 0,
        hostTotalMs = 0,
        hostMaxMs = 0,
        settingsTotalMs = 0,
        settingsMaxMs = 0,
        activitySamples = 0,
        activityTotalMs = 0,
        activityMaxMs = 0,
    } or nil
end

local function elapsedMs(startedAt)
    if startedAt == nil then return 0 end
    return math.max(0, (os.clock() - startedAt) * 1000)
end

local function recordHostActivityPerformance(capture, startedAt)
    if type(capture) ~= "table" or startedAt == nil then return end
    local duration = elapsedMs(startedAt)
    capture.activitySamples = capture.activitySamples + 1
    capture.activityTotalMs = capture.activityTotalMs + duration
    capture.activityMaxMs = math.max(capture.activityMaxMs, duration)
end

local function recordSharedPollPerformance(capture, sharedMs, hostMs, settingsMs)
    if type(capture) ~= "table" then return end
    capture.sharedSamples = capture.sharedSamples + 1
    capture.sharedTotalMs = capture.sharedTotalMs + sharedMs
    capture.sharedMaxMs = math.max(capture.sharedMaxMs, sharedMs)
    capture.hostTotalMs = capture.hostTotalMs + hostMs
    capture.hostMaxMs = math.max(capture.hostMaxMs, hostMs)
    capture.settingsTotalMs = capture.settingsTotalMs + settingsMs
    capture.settingsMaxMs = math.max(capture.settingsMaxMs, settingsMs)
    if capture.sharedSamples < INTEGRATION_PERFORMANCE_SAMPLES then return end
    log(table.concat({
        "perf_settings_heartbeat",
        "samples=" .. tostring(capture.sharedSamples),
        string.format("window_ms=%.3f", elapsedMs(capture.startedAt)),
        string.format("work_ms=%.3f", capture.sharedTotalMs),
        string.format("max_ms=%.3f", capture.sharedMaxMs),
        string.format("host_ms=%.3f", capture.hostTotalMs),
        string.format("host_max_ms=%.3f", capture.hostMaxMs),
        string.format("settings_ms=%.3f", capture.settingsTotalMs),
        string.format("settings_max_ms=%.3f", capture.settingsMaxMs),
        "activity_samples=" .. tostring(capture.activitySamples),
        string.format("activity_ms=%.3f", capture.activityTotalMs),
        string.format("activity_max_ms=%.3f", capture.activityMaxMs),
    }, "|"))
    state.integrationPerformance = nil
end

local function scheduleSettingsPrewarm()
    if state.settingsPrewarmPending
        or type(ExecuteInGameThreadWithDelay) ~= "function" then return false end
    state.settingsPrewarmPending = true
    state.settingsPrewarmCallback = function()
        state.settingsPrewarmPending = false
        state.settingsPrewarmCallback = nil
        local prepared, prepareError = pcall(SettingsUI.prepare)
        if not prepared then
            log("settings prewarm failed: " .. tostring(prepareError))
        end
    end
    local scheduled = pcall(ExecuteInGameThreadWithDelay,
        0, state.settingsPrewarmCallback)
    if not scheduled then
        state.settingsPrewarmPending = false
        state.settingsPrewarmCallback = nil
    end
    return scheduled
end

local function dispatchConfiguredPress()
    if state.inputDispatchPending or SettingsUI.mode() ~= nil then return end
    state.inputDispatchPending = true
    state.inputDispatchCallback = function()
        state.inputDispatchCallback = nil
        state.inputDispatchPending = false
        if runtimeIsSuperseded ~= nil and runtimeIsSuperseded() then return end
        if SettingsUI.mode() ~= nil then return end
        local ok, errorMessage = pcall(QuickStack.begin)
        if not ok then log("input error: " .. tostring(errorMessage)) end
    end
    local scheduled = pcall(ExecuteInGameThread, state.inputDispatchCallback)
    if not scheduled then
        state.inputDispatchPending = false
        state.inputDispatchCallback = nil
        log("cannot dispatch shortcut to the game thread")
    end
end

local function shortcutConflictFor(config)
    if type(config) ~= "table" or type(IsKeyBindRegistered) ~= "function" then
        return false
    end
    local signature = Settings.chordSignature(config)
    local owned = state.registeredShortcutBindings[signature]
    if type(owned) == "table" then return owned.externalConflict == true end
    if ModRef ~= nil then
        local sharedSignature, sharedConflict
        pcall(function()
            sharedSignature = ModRef:GetSharedVariable(
                SETTINGS_HOST_PREFIX .. "QuickStackShortcutSignature")
            sharedConflict = ModRef:GetSharedVariable(
                SETTINGS_HOST_PREFIX .. "QuickStackShortcutExternalConflict")
        end)
        if sharedSignature == signature then return sharedConflict == true end
    end
    local keyValue = Settings.keyValue(config.Key)
    if keyValue == nil then return false end
    local modifiers = Settings.modifierValues(config)
    local ok, registered = pcall(function()
        if #modifiers > 0 then
            return IsKeyBindRegistered(keyValue, modifiers)
        end
        return IsKeyBindRegistered(keyValue)
    end)
    return ok and registered == true
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
    local existing = state.registeredShortcutBindings[signature]
    if type(existing) == "table" and type(existing.callback) == "function" then
        state.bindingSignature = signature
        return true, nil
    end
    local externalConflict = shortcutConflictFor(config)
    local binding = {
        activeAfter = os.clock() + 0.35,
        externalConflict = externalConflict,
    }
    binding.callback = function()
        if state.bindingSignature ~= signature then return end
        -- A newly selected shortcut is registered while its capture press is
        -- still unwinding. Keep that press owned by the selector instead of
        -- immediately starting Quick Stack with the just-saved binding.
        if os.clock() < binding.activeAfter then return end
        dispatchConfiguredPress()
    end
    local modifiers = Settings.modifierValues(config)
    local ok, errorMessage = pcall(function()
        if #modifiers > 0 then
            RegisterKeyBind(keyValue, modifiers, binding.callback)
        else
            RegisterKeyBind(keyValue, binding.callback)
        end
    end)
    if not ok then return false, errorMessage end
    state.registeredShortcutBindings[signature] = binding
    state.bindingSignature = signature
    if ModRef ~= nil then
        pcall(function()
            ModRef:SetSharedVariable(
                SETTINGS_HOST_PREFIX .. "QuickStackShortcutSignature", signature)
            ModRef:SetSharedVariable(
                SETTINGS_HOST_PREFIX .. "QuickStackShortcutExternalConflict",
                externalConflict == true)
        end)
    end
    if externalConflict and state.shortcutConflictLoggedSignature ~= signature then
        state.shortcutConflictLoggedSignature = signature
        log("WARNING: possible UE4SS shortcut conflict for " .. signature
            .. "; both actions may run")
    end
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

local function settingsHostRead(name)
    if ModRef == nil then return nil, false end
    local ok, value = pcall(function()
        return ModRef:GetSharedVariable(SETTINGS_HOST_PREFIX .. name)
    end)
    return value, ok
end

local function settingsHostWrite(name, value)
    if ModRef == nil then return false end
    return pcall(function()
        ModRef:SetSharedVariable(SETTINGS_HOST_PREFIX .. name, value)
    end)
end

runtimeIsSuperseded = function()
    if state.superseded == true then return true end
    if state.settingsHostGeneration <= 0 then return false end
    local current = select(1, settingsHostRead("QuickStackGeneration"))
    if type(current) ~= "number" or current < 0 or current % 1 ~= 0 then
        current = nil
    end
    if current == nil or current <= state.settingsHostGeneration then return false end
    state.superseded = true
    if not state.supersededLogged then
        state.supersededLogged = true
        log("runtime superseded by Quick Stack generation " .. tostring(current))
    end
    return true
end

local function nonNegativeRevision(value)
    if type(value) ~= "number" or value < 0 or value % 1 ~= 0 then return nil end
    return value
end

local function initializeSettingsHostGeneration()
    if state.settingsHostGeneration > 0 then return end
    local previous = nonNegativeRevision(
        select(1, settingsHostRead("QuickStackGeneration"))) or 0
    state.settingsHostGeneration = previous + 1
    state.settingsHostOpenRevision = nonNegativeRevision(select(1,
        settingsHostRead("OpenExtensionSettingsRequestRevision"))) or 0
    state.settingsHostCloseRevision = nonNegativeRevision(select(1,
        settingsHostRead("CloseExtensionSettingsRequestRevision"))) or 0
    state.settingsSelfToggleRevision = nonNegativeRevision(select(1,
        settingsHostRead("QuickStackToggleRequestRevision"))) or 0
    state.settingsHostRequestSignalRevision = nonNegativeRevision(select(1,
        settingsHostRead("HostRequestSignalRevision"))) or 0
end

local function nextHostRevision(name)
    local current = nonNegativeRevision(select(1, settingsHostRead(name))) or 0
    return current + 1
end

local function signalSettingsHostRequest()
    local revision = nextHostRevision("HostRequestSignalRevision")
    return settingsHostWrite("HostRequestSignalRevision", revision)
end

local function livePalInsightRuntime()
    local protocol = select(1, settingsHostRead("ProtocolVersion"))
    local heartbeat = tonumber((select(1, settingsHostRead("HostHeartbeat"))))
    local generation = nonNegativeRevision(
        select(1, settingsHostRead("HostGeneration")))
    local runtimeVersion = select(1, settingsHostRead("HostRuntimeVersion"))
    local live = protocol == SETTINGS_HOST_PROTOCOL_VERSION
        and heartbeat ~= nil
        and os.clock() - heartbeat <= SETTINGS_HOST_LEASE_SECONDS
        and generation ~= nil and generation > 0
        and type(runtimeVersion) == "string" and runtimeVersion ~= ""
    return live, live and generation or nil
end

local function livePalInsightHost()
    local live, generation = livePalInsightRuntime()
    local ready = select(1, settingsHostRead("HostReady")) == true
    return live and ready, live and ready and generation or nil
end

local function livePalInsightF6Owner()
    local live, generation = livePalInsightRuntime()
    if not live then return false end
    local owner = select(1, settingsHostRead("F6Owner"))
    local ownerGeneration = nonNegativeRevision(select(1,
        settingsHostRead("F6OwnerGeneration")))
    return owner == "PalInsight" and ownerGeneration == generation
end

local function requestCurrentQuickStackToggle()
    local generation = nonNegativeRevision(select(1,
        settingsHostRead("QuickStackGeneration")))
    if generation == nil or generation <= 0 then return false end
    local revision = nextHostRevision("QuickStackToggleRequestRevision")
    local committed = settingsHostWrite(
            "QuickStackToggleRequestTargetGeneration", generation)
        and settingsHostWrite("QuickStackToggleRequestRevision", revision)
    if committed then signalSettingsHostRequest() end
    return committed
end

local function toggleSettingsForCurrentRuntime()
    if livePalInsightF6Owner() then
        if SettingsUI.mode() == "standalone"
            and not SettingsUI.close("host-takeover") then
            return false, "standalone settings could not yield to Pal Insight"
        end
        -- Pal Insight owns the physical F6 binding while its host lease is
        -- live. UE4SS cannot unregister this earlier Quick Stack callback, so
        -- it must become inert instead of forwarding the same press and
        -- toggling the host a second time.
        return true, nil
    end
    local toggled, toggleError = SettingsUI.toggle("standalone")
    return toggled == true, toggleError
end

local function dispatchSettingsShortcut()
    if state.settingsInputDispatchPending then return end
    state.settingsInputDispatchPending = true
    state.settingsInputDispatchCallback = function()
        state.settingsInputDispatchCallback = nil
        state.settingsInputDispatchPending = false
        local ok, errorMessage = pcall(function()
            if runtimeIsSuperseded() then
                if not requestCurrentQuickStackToggle() then
                    error("current Quick Stack runtime request is unavailable")
                end
                return
            end
            local toggled, toggleError = toggleSettingsForCurrentRuntime()
            if not toggled then error(toggleError or "settings toggle failed") end
        end)
        if not ok then log("settings input error: " .. tostring(errorMessage)) end
    end
    local scheduled = pcall(ExecuteInGameThread, state.settingsInputDispatchCallback)
    if not scheduled then
        state.settingsInputDispatchPending = false
        state.settingsInputDispatchCallback = nil
        log("cannot dispatch settings shortcut to the game thread")
    end
end

local function registerSettingsShortcut()
    if state.settingsShortcutRegistered then return true, nil end
    initializeSettingsHostGeneration()
    if type(RegisterKeyBind) ~= "function" or type(IsKeyBindRegistered) ~= "function"
        or type(Key) ~= "table" then
        return false, "UE4SS settings-key API is unavailable"
    end
    local keyValue = Settings.keyValue("F6")
    if keyValue == nil then return false, "F6 is unavailable" end
    local queried, registered = pcall(IsKeyBindRegistered, keyValue)
    if not queried then return false, "F6 ownership cannot be queried" end
    if registered == true then
        local owner = select(1, settingsHostRead("F6Owner"))
        if type(owner) ~= "string" or owner == "" then owner = "External" end
        settingsHostWrite("F6Owner", owner)
        return true, nil
    end
    state.settingsShortcutCallback = function()
        dispatchSettingsShortcut()
    end
    local ok, errorMessage = pcall(
        RegisterKeyBind, keyValue, state.settingsShortcutCallback)
    if not ok then
        state.settingsShortcutCallback = nil
        return false, errorMessage
    end
    state.settingsShortcutRegistered = true
    settingsHostWrite("F6BehaviorVersion", 2)
    if not livePalInsightF6Owner() then
        settingsHostWrite("F6OwnerGeneration", state.settingsHostGeneration)
        settingsHostWrite("F6Owner", "QuickStack")
    end
    return true, nil
end

local function revisionValue(value)
    if type(value) ~= "number" or value < 0 or value % 1 ~= 0 then return nil end
    return value
end

local function publishCanonicalSettings(revision)
    local values = {
        { "ApiVersion", SHARED_API_VERSION },
        { "RuntimeVersion", VERSION },
        { "Key", state.config.Key },
        { "Shift", state.config.Shift },
        { "Ctrl", state.config.Ctrl },
        { "Alt", state.config.Alt },
    }
    for _, setting in ipairs(SHARED_BOOLEAN_SETTINGS) do
        values[#values + 1] = {
            setting.shared,
            state.config[setting.config],
        }
    end
    for _, setting in ipairs(SHARED_STRING_SETTINGS) do
        values[#values + 1] = {
            setting.shared,
            state.config[setting.config],
        }
    end
    for _, setting in ipairs(SHARED_NUMBER_SETTINGS) do
        values[#values + 1] = {
            setting.shared,
            state.config[setting.config],
        }
    end
    for _, entry in ipairs(values) do
        if not sharedWrite(entry[1], entry[2]) then return false end
    end
    if not sharedWrite("SettingsRevision", revision) then return false end
    state.sharedRevision = revision
    return true
end

local function requestedSharedSettings()
    local key, keyOk = sharedRead("Key")
    local shift, shiftOk = sharedRead("Shift")
    local ctrl, ctrlOk = sharedRead("Ctrl")
    local alt, altOk = sharedRead("Alt")
    if not keyOk or not shiftOk or not ctrlOk or not altOk then
        return nil, "shared values are unavailable"
    end
    local requested, validationError = Settings.validateShortcut({
        Key = key,
        Shift = shift,
        Ctrl = ctrl,
        Alt = alt,
    })
    if requested == nil then return nil, validationError end
    for _, setting in ipairs(SHARED_BOOLEAN_SETTINGS) do
        local value, ok = sharedRead(setting.shared)
        if not ok then return nil, "shared values are unavailable" end
        if type(value) ~= "boolean" then
            return nil, setting.shared .. " must be a boolean"
        end
        requested[setting.config] = value
    end
    for _, setting in ipairs(SHARED_STRING_SETTINGS) do
        local value, ok = sharedRead(setting.shared)
        if not ok then return nil, "shared values are unavailable" end
        local validated, valueError = setting.validate(value)
        if validated == nil then return nil, valueError end
        requested[setting.config] = validated
    end
    for _, setting in ipairs(SHARED_NUMBER_SETTINGS) do
        local value, ok = sharedRead(setting.shared)
        if not ok then return nil, "shared values are unavailable" end
        local validated, valueError = setting.validate(value)
        if validated == nil then return nil, valueError end
        requested[setting.config] = validated
    end
    return requested, nil
end

local function reconcileSharedSettings()
    local incoming = revisionValue(select(1, sharedRead("SettingsRevision")))
    if incoming == nil or incoming == state.sharedRevision then return end
    local acknowledgement = math.max(incoming, state.sharedRevision or 0) + 1
    local requested, validationError = requestedSharedSettings()
    if requested == nil then
        log("Pal Insight settings request rejected: " .. tostring(validationError))
        publishCanonicalSettings(acknowledgement)
        return
    end

    local shortcutChanged =
        Settings.chordSignature(requested) ~= state.bindingSignature
    local settingsChanged = shortcutChanged
    for _, setting in ipairs(SHARED_BOOLEAN_SETTINGS) do
        if requested[setting.config] ~= state.config[setting.config] then
            settingsChanged = true
            break
        end
    end
    for _, setting in ipairs(SHARED_STRING_SETTINGS) do
        if requested[setting.config] ~= state.config[setting.config] then
            settingsChanged = true
            break
        end
    end
    for _, setting in ipairs(SHARED_NUMBER_SETTINGS) do
        if requested[setting.config] ~= state.config[setting.config] then
            settingsChanged = true
            break
        end
    end
    if not settingsChanged then
        publishCanonicalSettings(acknowledgement)
        return
    end

    local applied, applyError = SettingsUI.apply(requested, "legacy-bridge")
    if not applied then
        log("Pal Insight settings request rejected: "
            .. tostring(applyError or "cannot apply settings"))
        publishCanonicalSettings(acknowledgement)
        return
    end

    log("settings updated by Pal Insight: " .. Settings.chordSignature(state.config)
        .. ", result display=" .. tostring(state.config.ResultDisplay)
        .. ", include ignored=" .. tostring(state.config.IncludeExcludedItems)
        .. ", include new=" .. tostring(state.config.IncludeNewItems)
        .. ", include guild chest=" .. tostring(state.config.IncludeGuildChest)
        .. ", egg routing=" .. tostring(state.config.PalEggRouting)
        .. ", relic routing=" .. tostring(state.config.RelicRouting)
        .. ", holy water minimum="
        .. tostring(state.config.WorldTreeHolyWaterMinimum))
    publishCanonicalSettings(acknowledgement)
end

local function publishSettingsSurfaceCapability()
    initializeSettingsHostGeneration()
    if runtimeIsSuperseded() then return false, "superseded" end
    state.settingsHostLivenessRevision = state.settingsHostLivenessRevision + 1
    local values = {
        { "ProtocolVersion", SETTINGS_HOST_PROTOCOL_VERSION },
        { "QuickStackReady", true },
        { "QuickStackRuntimeVersion", VERSION },
        { "QuickStackGeneration", state.settingsHostGeneration },
        { "QuickStackHeartbeat", os.clock() },
        { "QuickStackLivenessRevision", state.settingsHostLivenessRevision },
    }
    for _, entry in ipairs(values) do
        if not settingsHostWrite(entry[1], entry[2]) then return false, "write-failed" end
    end
    return true, nil
end

local function publishHostedAcknowledgementContext(hostGeneration, inputRoute)
    return settingsHostWrite(
            "ExtensionSettingsAckHostGeneration", hostGeneration)
        and settingsHostWrite(
            "ExtensionSettingsAckQuickStackGeneration",
            state.settingsHostGeneration)
        and settingsHostWrite("ExtensionSettingsAckInputRoute", inputRoute)
end

local function publishHostedOpenAcknowledgement(
        revision, hostGeneration, inputRoute)
    return publishHostedAcknowledgementContext(hostGeneration, inputRoute)
        and settingsHostWrite("ExtensionSettingsFailureCode", "")
        and settingsHostWrite("ExtensionSettingsOpenedRevision", revision)
end

local function acknowledgeHostedFailure(revision, code, hostGeneration, inputRoute)
    return publishHostedAcknowledgementContext(hostGeneration, inputRoute)
        and settingsHostWrite(
            "ExtensionSettingsFailureCode", tostring(code or "open-failed"))
        and settingsHostWrite("ExtensionSettingsFailureRevision", revision)
end

local function publishPendingHostedCloseAcknowledgement()
    local pending = state.pendingSettingsHostCloseAck
    if type(pending) ~= "table" then return true end
    local published = publishHostedAcknowledgementContext(
            pending.hostGeneration, pending.inputRoute)
        and settingsHostWrite(
            "ExtensionSettingsClosedRevision", pending.revision)
    if not published then return false end
    if state.pendingSettingsHostCloseAck == pending then
        state.pendingSettingsHostCloseAck = nil
        state.settingsHostPanelRevision = nil
        state.settingsHostPanelHostGeneration = nil
        state.settingsHostPanelInputRoute = nil
    end
    return true
end

local function reconcileSettingsHostRequests()
    if not publishPendingHostedCloseAcknowledgement() then return true end
    if runtimeIsSuperseded() then
        if SettingsUI.mode() ~= nil
            and not SettingsUI.close("runtime-superseded") then return true end
        return false
    end
    local selfToggleRevision = nonNegativeRevision(select(1,
        settingsHostRead("QuickStackToggleRequestRevision"))) or 0
    if selfToggleRevision > state.settingsSelfToggleRevision then
        state.settingsSelfToggleRevision = selfToggleRevision
        local targetGeneration = nonNegativeRevision(select(1,
            settingsHostRead("QuickStackToggleRequestTargetGeneration")))
        if targetGeneration == state.settingsHostGeneration then
            local toggled, toggleError = toggleSettingsForCurrentRuntime()
            if not toggled then
                log("forwarded settings input error: "
                    .. tostring(toggleError or "settings toggle failed"))
            end
        end
    end

    if SettingsUI.mode() == "hosted" then
        local hostLive, hostGeneration = livePalInsightHost()
        local hostSettingsOpen = select(1,
            settingsHostRead("HostSettingsOpen")) == true
        if not hostLive
            or hostGeneration ~= state.settingsHostPanelHostGeneration
            or not hostSettingsOpen then
            SettingsUI.close("host-unavailable")
        end
    end

    local closeRevision = nonNegativeRevision(select(1,
        settingsHostRead("CloseExtensionSettingsRequestRevision"))) or 0
    if closeRevision > state.settingsHostCloseRevision then
        local closeHostGeneration = nonNegativeRevision(select(1,
            settingsHostRead("CloseExtensionSettingsHostGeneration")))
        local closeTargetGeneration = nonNegativeRevision(select(1,
            settingsHostRead("CloseExtensionSettingsTargetGeneration")))
        if closeHostGeneration == state.settingsHostPanelHostGeneration
            and closeTargetGeneration == state.settingsHostGeneration
            and SettingsUI.mode() == "hosted" then
            if SettingsUI.close("host-request") then
                state.settingsHostCloseRevision = closeRevision
            end
        else
            state.settingsHostCloseRevision = closeRevision
        end
    end

    local openRevision = nonNegativeRevision(select(1,
        settingsHostRead("OpenExtensionSettingsRequestRevision"))) or 0
    if openRevision <= state.settingsHostOpenRevision then return true end
    state.settingsHostOpenRevision = openRevision
    local requestId = select(1,
        settingsHostRead("OpenExtensionSettingsRequestId"))
    local requestHostGeneration = nonNegativeRevision(select(1,
        settingsHostRead("OpenExtensionSettingsHostGeneration")))
    local requestTargetGeneration = nonNegativeRevision(select(1,
        settingsHostRead("OpenExtensionSettingsTargetGeneration")))
    local requestInputDevice = select(1,
        settingsHostRead("OpenExtensionSettingsInputDevice"))
    local requestInputRoute = select(1,
        settingsHostRead("OpenExtensionSettingsInputRoute"))
    local hostLive, liveHostGeneration = livePalInsightHost()
    if select(1, settingsHostRead("ProtocolVersion"))
            ~= SETTINGS_HOST_PROTOCOL_VERSION
        or requestId ~= "quickStack"
        or requestTargetGeneration ~= state.settingsHostGeneration
        or requestHostGeneration ~= liveHostGeneration
        or (requestInputDevice ~= "keyboard" and requestInputDevice ~= "mouse"
            and requestInputDevice ~= "gamepad")
        or (requestInputRoute ~= "host-native"
            and requestInputRoute ~= "extension-cooked")
        or not hostLive then
        acknowledgeHostedFailure(
            openRevision, "host-unavailable", requestHostGeneration,
            requestInputRoute)
        return true
    end
    state.settingsHostPanelRevision = openRevision
    state.settingsHostPanelHostGeneration = requestHostGeneration
    state.settingsHostPanelInputRoute = requestInputRoute
    local opened, openError = SettingsUI.open("hosted", {
        requestRevision = openRevision,
        initialInputDevice = requestInputDevice,
        hostedInputRoute = requestInputRoute,
    })
    if opened then
        local acknowledged = publishHostedOpenAcknowledgement(
            openRevision, requestHostGeneration, requestInputRoute)
        if not acknowledged then
            log("hosted settings open acknowledgement failed; rolling back")
            if not SettingsUI.close("host-open-ack-failed") then
                log("hosted settings rollback retained its visible recovery surface")
            end
        end
    else
        state.settingsHostPanelRevision = nil
        state.settingsHostPanelHostGeneration = nil
        state.settingsHostPanelInputRoute = nil
        acknowledgeHostedFailure(openRevision,
            openError or "open-failed", requestHostGeneration,
            requestInputRoute)
    end
    return true
end

local scheduleHostActivityPoll
local stopHostActivityPoll

local function reconcileSettingsHost()
    if runtimeIsSuperseded() then return reconcileSettingsHostRequests() end
    local published, publishReason = publishSettingsSurfaceCapability()
    if not published and publishReason == "superseded" then return false end
    local hostLive = livePalInsightHost()
    local hostSettingsOpen = hostLive == true and select(1,
        settingsHostRead("HostSettingsOpen")) == true
    state.hostActivityHostLive = hostLive == true
    state.hostActivityHostSettingsOpen = hostSettingsOpen
    state.hostActivityLastProbeAt = os.clock()
    if SettingsUI.mode() ~= nil then SettingsUI.ensurePollAlive() end
    if hostLive and (hostSettingsOpen or SettingsUI.mode() == "hosted")
        and scheduleHostActivityPoll ~= nil then
        scheduleHostActivityPoll(HOST_REQUEST_POLL_MS)
    end
    return reconcileSettingsHostRequests()
end

scheduleHostActivityPoll = function(delayMs)
    if state.hostActivityPolling
        or type(LoopInGameThreadWithDelay) ~= "function"
        or state.superseded == true then return false end
    state.hostActivityPolling = true
    state.hostActivityPollCallback = state.hostActivityPollCallback or function()
        local capture = state.integrationPerformance
        local startedAt = type(capture) == "table" and os.clock() or nil
        local keepPolling = false
        local ok, errorMessage = pcall(function()
            local now = os.clock()
            if state.hostActivityLastProbeAt <= 0.0
                or now - state.hostActivityLastProbeAt
                    >= HOST_ACTIVITY_POLL_MS / 1000.0 then
                state.hostActivityHostLive = livePalInsightHost() == true
                state.hostActivityHostSettingsOpen = select(1,
                    settingsHostRead("HostSettingsOpen")) == true
                state.hostActivityLastProbeAt = now
            end
            keepPolling = state.hostActivityHostLive == true
                and (state.hostActivityHostSettingsOpen
                    or SettingsUI.mode() == "hosted")
            if keepPolling then
                local signalRevision = nonNegativeRevision(select(1,
                    settingsHostRead("HostRequestSignalRevision"))) or 0
                if signalRevision > state.settingsHostRequestSignalRevision then
                    state.settingsHostRequestSignalRevision = signalRevision
                    keepPolling = reconcileSettingsHostRequests() ~= false
                end
            end
        end)
        if not ok then
            log("settings host request error: " .. tostring(errorMessage))
        end
        recordHostActivityPerformance(capture, startedAt)
        if not keepPolling then stopHostActivityPoll() end
    end
    local started, handleOrError = pcall(LoopInGameThreadWithDelay,
        tonumber(delayMs) or HOST_ACTIVITY_POLL_MS,
        state.hostActivityPollCallback)
    if not started or type(handleOrError) ~= "number" then
        state.hostActivityPolling = false
        state.hostActivityPollHandle = nil
        return false
    end
    state.hostActivityPollHandle = handleOrError
    return true
end

stopHostActivityPoll = function()
    local handle = state.hostActivityPollHandle
    local stopped = handle == nil
    if not stopped and type(CancelDelayedAction) == "function" then
        local cancelled, result = pcall(CancelDelayedAction, handle)
        stopped = cancelled and result == true
    end
    if not stopped and type(IsValidDelayedActionHandle) == "function" then
        local checked, valid = pcall(IsValidDelayedActionHandle, handle)
        stopped = checked and valid == false
    end
    if stopped then
        state.hostActivityPollHandle = nil
        state.hostActivityPolling = false
    end
    return stopped
end

local stopSharedPoll

local function scheduleSharedPoll()
    if state.sharedPolling
        or type(LoopInGameThreadWithDelay) ~= "function" then return false end
    state.sharedPolling = true
    state.sharedPollCallback = state.sharedPollCallback or function()
        local capture = state.integrationPerformance
        local sharedStarted = type(capture) == "table" and os.clock() or nil
        local hostMs = 0
        local settingsMs = 0
        local keepPolling = true
        local ok, errorMessage = pcall(function()
            local hostStarted = type(capture) == "table" and os.clock() or nil
            keepPolling = reconcileSettingsHost() ~= false
            hostMs = elapsedMs(hostStarted)
            if keepPolling then
                local settingsStarted = type(capture) == "table"
                    and os.clock() or nil
                reconcileSharedSettings()
                settingsMs = elapsedMs(settingsStarted)
            end
        end)
        if not ok then log("settings integration error: " .. tostring(errorMessage)) end
        recordSharedPollPerformance(
            capture, elapsedMs(sharedStarted), hostMs, settingsMs)
        if not keepPolling or (state.superseded == true
                and SettingsUI.mode() == nil) then stopSharedPoll() end
    end
    local started, handleOrError = pcall(LoopInGameThreadWithDelay,
        SHARED_POLL_MS, state.sharedPollCallback)
    if not started or type(handleOrError) ~= "number" then
        state.sharedPolling = false
        state.sharedPollHandle = nil
        return false
    end
    state.sharedPollHandle = handleOrError
    return true
end

stopSharedPoll = function()
    local handle = state.sharedPollHandle
    local stopped = handle == nil
    if not stopped and type(CancelDelayedAction) == "function" then
        local cancelled, result = pcall(CancelDelayedAction, handle)
        stopped = cancelled and result == true
    end
    if not stopped and type(IsValidDelayedActionHandle) == "function" then
        local checked, valid = pcall(IsValidDelayedActionHandle, handle)
        stopped = checked and valid == false
    end
    if stopped then
        state.sharedPollHandle = nil
        state.sharedPolling = false
    end
    return stopped
end

state.config, state.configPath = Settings.load(log)
configureIntegrationPerformance()
SettingsUI.configure({
    version = VERSION,
    config = state.config,
    configPath = state.configPath,
    registerShortcut = registerConfiguredKey,
    shortcutConflict = shortcutConflictFor,
    readHostedControllerSnapshot = function()
        if state.settingsHostPanelRevision == nil
            or state.settingsHostPanelHostGeneration == nil then return nil end
        local revision = nonNegativeRevision(select(1,
            settingsHostRead("ExtensionControllerRevision")))
        if revision == nil then return nil end
        local hostGeneration = nonNegativeRevision(select(1,
            settingsHostRead("ExtensionControllerHostGeneration")))
        local quickStackGeneration = nonNegativeRevision(select(1,
            settingsHostRead("ExtensionControllerQuickStackGeneration")))
        local openRevision = nonNegativeRevision(select(1,
            settingsHostRead("ExtensionControllerOpenRevision")))
        local connected = select(1,
            settingsHostRead("ExtensionControllerConnected")) == true
        local buttons = tonumber((select(1,
            settingsHostRead("ExtensionControllerButtons"))))
        local leftX = tonumber((select(1,
            settingsHostRead("ExtensionControllerLeftX"))))
        local leftY = tonumber((select(1,
            settingsHostRead("ExtensionControllerLeftY"))))
        local edgeRevision = nonNegativeRevision(select(1,
            settingsHostRead("ExtensionControllerEdgeRevision")))
        local pressedEdges = tonumber((select(1,
            settingsHostRead("ExtensionControllerPressedEdges"))))
        local releasedEdges = tonumber((select(1,
            settingsHostRead("ExtensionControllerReleasedEdges"))))
        local committedRevision = nonNegativeRevision(select(1,
            settingsHostRead("ExtensionControllerRevision")))
        if revision ~= committedRevision
            or hostGeneration ~= state.settingsHostPanelHostGeneration
            or quickStackGeneration ~= state.settingsHostGeneration
            or openRevision ~= state.settingsHostPanelRevision
            or type(buttons) ~= "number" or buttons < 0 or buttons > 0xFFFF
            or buttons % 1 ~= 0
            or edgeRevision == nil
            or type(pressedEdges) ~= "number" or pressedEdges < 0
            or pressedEdges > 0xFFFF or pressedEdges % 1 ~= 0
            or type(releasedEdges) ~= "number" or releasedEdges < 0
            or releasedEdges > 0xFFFF or releasedEdges % 1 ~= 0
            or (leftX ~= -1 and leftX ~= 0 and leftX ~= 1)
            or (leftY ~= -1 and leftY ~= 0 and leftY ~= 1) then
            return nil
        end
        return {
            revision = revision,
            connected = connected,
            buttons = buttons,
            leftX = leftX,
            leftY = leftY,
            edgeRevision = edgeRevision,
            pressedEdges = pressedEdges,
            releasedEdges = releasedEdges,
        }
    end,
    ackHostedControllerSnapshot = function(edgeRevision)
        edgeRevision = nonNegativeRevision(edgeRevision)
        if edgeRevision == nil or state.settingsHostPanelRevision == nil
            or state.settingsHostPanelHostGeneration == nil then return false end
        return settingsHostWrite("ExtensionControllerEdgeAckHostGeneration",
                state.settingsHostPanelHostGeneration)
            and settingsHostWrite(
                "ExtensionControllerEdgeAckQuickStackGeneration",
                state.settingsHostGeneration)
            and settingsHostWrite("ExtensionControllerEdgeAckOpenRevision",
                state.settingsHostPanelRevision)
            and settingsHostWrite("ExtensionControllerEdgeAckRevision",
                edgeRevision)
    end,
    log = log,
    onApplied = function()
        QuickStack.configure(state.config, log, debugLog)
        configureIntegrationPerformance()
        local revision = (state.sharedRevision or 0) + 1
        publishCanonicalSettings(revision)
    end,
    onClosed = function(mode)
        if mode == "hosted" and state.settingsHostPanelRevision ~= nil then
            state.pendingSettingsHostCloseAck = {
                revision = state.settingsHostPanelRevision,
                hostGeneration = state.settingsHostPanelHostGeneration,
                inputRoute = state.settingsHostPanelInputRoute,
            }
            publishPendingHostedCloseAcknowledgement()
        end
    end,
})
QuickStack.configure(state.config, log, debugLog)
if not scheduleSettingsPrewarm() then
    log("settings prewarm could not reach the game thread")
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

local settingsRegistered, settingsRegisterError = registerSettingsShortcut()
if not settingsRegistered then
    log("settings shortcut unavailable: " .. tostring(settingsRegisterError))
end

if registered then
    local existingRevision = revisionValue(
        select(1, sharedRead("SettingsRevision"))) or 0
    if publishCanonicalSettings(existingRevision + 1)
        and publishSettingsSurfaceCapability() then
        scheduleSharedPoll()
    end
end
