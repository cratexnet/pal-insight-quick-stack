local P = require("palworld")
local NativeSettingsInput = require("native_settings_input")

local Bridge = {}

local SHARED_PREFIX = "PalInsightQuickStack."
local CAPABILITY_NAME = "ResultDialogBridgeVersion"
local CAPABILITY_VERSION = 2
local BRIDGE_PRIORITY = 9999
local BRIDGE_ASSET_PATH =
    "/Game/Mods/PalInsightX/WBP_PalInsightX_Settings"
local BRIDGE_CLASS_PATH = BRIDGE_ASSET_PATH .. ".WBP_PalInsightX_Settings_C"
local BRIDGE_DEFAULT_PATH = BRIDGE_ASSET_PATH
    .. ".Default__WBP_PalInsightX_Settings_C"
local BRIDGE_PRESSED_FUNCTION = BRIDGE_CLASS_PATH
    .. ":PalInsightInputBridgePressed"
local BRIDGE_RELEASED_FUNCTION = BRIDGE_CLASS_PATH
    .. ":PalInsightInputBridgeReleased"
local BRIDGE_AXIS_X_FUNCTION = BRIDGE_CLASS_PATH
    .. ":PalInsightInputBridgeAxisX"
local BRIDGE_AXIS_Y_FUNCTION = BRIDGE_CLASS_PATH
    .. ":PalInsightInputBridgeAxisY"
local BRIDGE_CLICKED_FUNCTION = BRIDGE_CLASS_PATH
    .. ":PalInsightSearchClearClicked"
local BRIDGE_TOGGLE_CHANGED_FUNCTION = BRIDGE_CLASS_PATH
    .. ":PalInsightSettingsToggleChanged"
local RETURN_LISTENER_CLASS =
    "/Game/Pal/Blueprint/UI/WBP_PalHUD_InGame_InputListener.WBP_PalHUD_InGame_InputListener_C"
local RETURN_GATE_FUNCTION_CANDIDATES = {
    RETURN_LISTENER_CLASS .. ":CanOpenAnyUI",
    RETURN_LISTENER_CLASS .. ":Can_Open_Any_UI",
    RETURN_LISTENER_CLASS .. ":Can Open Any UI",
}
local NATIVE_ESCAPE_FUNCTION = RETURN_LISTENER_CLASS .. ":OnTriggerEscape"
local MENU_QUERY_FUNCTION =
    "/Game/Pal/Blueprint/UI/PlayerRadialMenu/WBP_PlayerRadialMenu.WBP_PlayerRadialMenu_C:IsAnyMenuOpened"
local KEYBOARD_QUEUE_LIMIT = 64
local INPUT_MODE_FUNCTIONS = {
    GameOnly = "/Script/UMG.WidgetBlueprintLibrary:SetInputMode_GameOnly",
    UIOnly = "/Script/UMG.WidgetBlueprintLibrary:SetInputMode_UIOnlyEx",
    GameAndUI = "/Script/UMG.WidgetBlueprintLibrary:SetInputMode_GameAndUIEx",
}

local state = {
    log = nil,
    keyboardBindingsReady = false,
    keyboardBindingCallbacks = {},
    keyboardWarningLogged = false,
    bridgeHooksReady = false,
    actionDelegateHookReady = false,
    toggleDelegateHookReady = false,
    inputModeHooksReady = false,
    escapePriorityHooksReady = false,
    returnGateReady = false,
    nativeEscapeHookReady = false,
    menuQueryHookReady = false,
    returnGatePath = nil,
    hookRecords = {},
    bridgeCache = nil,
    bridge = nil,
    bridgeAddress = nil,
    ownerWidget = nil,
    ownerWidgetAddress = nil,
    controller = nil,
    controllerAddress = nil,
    closeButton = nil,
    closeButtonAddress = nil,
    actionDelegateBridge = nil,
    actionDelegateBridgeAddress = nil,
    actionDelegateRecords = {},
    actionDelegateExpectedCount = 0,
    nativeActionLastEventAt = -10.0,
    nativeActionLastEventGeneration = 0,
    globalMouseFallbackAt = -10.0,
    globalMouseFallbackGeneration = 0,
    toggleDelegateBridge = nil,
    toggleDelegateBridgeAddress = nil,
    toggleDelegateRecords = {},
    handlers = nil,
    modalUIOnly = false,
    hostedParent = false,
    cookedInputActive = false,
    nativeInputActive = false,
    active = false,
    closePending = false,
    reclaimPending = false,
    applyingInputMode = false,
    inputContext = nil,
    hostedFallbackContext = nil,
    externalInputContext = nil,
    lastObservedInputContext = nil,
    inputIsolation = nil,
    generation = 0,
    keyboardQueue = {},
    keyboardWakePending = false,
    keyboardWakeCallback = nil,
    closeDispatchCallback = nil,
    reclaimCallback = nil,
    lastAcquireDiagnostics = nil,
    escapeCloseSequence = 0,
    escapeCloseGuard = nil,
}

local function log(message)
    if type(state.log) == "function" then
        state.log("Pal Insight modal input bridge: " .. tostring(message))
    end
end

local function sharedRead(name)
    if ModRef == nil then return nil, false end
    local ok, value = pcall(function()
        return ModRef:GetSharedVariable(SHARED_PREFIX .. name)
    end)
    return value, ok
end

local function sameObject(object, address)
    return address ~= nil and P.isValid(object)
        and P.objectAddress(object) == address
end

local function ownsBridge(context)
    if state.active ~= true or state.bridgeAddress == nil then return false end
    return sameObject(P.unwrap(context), state.bridgeAddress)
end

local function ownsDelegateBridge(context, bridge, address)
    return state.active == true and sameObject(bridge, address)
        and sameObject(P.unwrap(context), address)
end

local function ownsController(controller)
    return state.active == true
        and sameObject(controller, state.controllerAddress)
end

local function escapeCloseGuardBlocksNativeUI()
    local record = state.escapeCloseGuard
    if type(record) ~= "table" then return false end
    local now = os.clock()
    if now >= (tonumber(record.expiresAt) or 0.0) then
        state.escapeCloseGuard = nil
        return false
    end
    if record.windowClosed == true and record.released == true
        and now >= (tonumber(record.settleUntil) or math.huge) then
        state.escapeCloseGuard = nil
        return false
    end
    return true
end

local function ownsUnderlyingInput()
    return state.active == true or escapeCloseGuardBlocksNativeUI()
end

local function dispatchEvent(kind, value, source)
    if state.active ~= true then return false end
    local handlers = state.handlers
    local callback = type(handlers) == "table" and handlers[kind] or nil
    if type(callback) ~= "function" then return true end
    local ok, errorMessage = pcall(callback, value, source)
    if not ok then log("input handler failed: " .. tostring(errorMessage)) end
    return ok
end

local wakeKeyboardQueue

local function drainKeyboardQueue()
    state.keyboardWakePending = false
    local queue = state.keyboardQueue
    state.keyboardQueue = {}
    for _, item in ipairs(queue) do
        if state.active == true and item.generation == state.generation then
            if item.keyName == "LeftMouseButton" then
                local now = os.clock()
                local nativeRecent = Bridge.nativeActionDelegatesReady()
                    and state.nativeActionLastEventGeneration == state.generation
                    and now - state.nativeActionLastEventAt <= 0.08
                if not nativeRecent then
                    state.globalMouseFallbackAt = now
                    state.globalMouseFallbackGeneration = state.generation
                    dispatchEvent("onClicked", "mouse", "global")
                end
            else
                dispatchEvent("onPressed", item.keyName, "global")
            end
        end
    end
    if #state.keyboardQueue > 0 then wakeKeyboardQueue() end
    return true
end

state.keyboardWakeCallback = drainKeyboardQueue

wakeKeyboardQueue = function()
    if #state.keyboardQueue == 0 or state.keyboardWakePending then return true end
    if type(ExecuteInGameThread) ~= "function" then return false end
    state.keyboardWakePending = true
    local scheduled = pcall(ExecuteInGameThread, state.keyboardWakeCallback)
    if not scheduled then state.keyboardWakePending = false end
    return scheduled == true
end

local function queueKeyboardPress(keyName)
    if state.active ~= true or type(keyName) ~= "string" then return false end
    if #state.keyboardQueue >= KEYBOARD_QUEUE_LIMIT then
        table.remove(state.keyboardQueue, 1)
    end
    state.keyboardQueue[#state.keyboardQueue + 1] = {
        keyName = keyName,
        generation = state.generation,
    }
    wakeKeyboardQueue()
    return true
end

local function requestClose(source)
    if state.active ~= true or state.closePending then return false end
    local handlers = state.handlers
    if type(handlers) ~= "table" or type(handlers.onClose) ~= "function" then
        return false
    end
    state.closePending = true
    local generation = state.generation
    state.closeDispatchCallback = function()
        state.closeDispatchCallback = nil
        if state.active ~= true or state.generation ~= generation then return end
        state.closePending = false
        dispatchEvent("onClose", source)
    end
    local scheduled = pcall(ExecuteInGameThread, state.closeDispatchCallback)
    if not scheduled then
        state.closePending = false
        state.closeDispatchCallback = nil
    end
    return scheduled == true
end

local function bridgeKeyName(keyParam)
    local key = P.unwrap(keyParam)
    if key == nil then return nil end
    if type(key) == "string" then return P.nameString(key) end
    local keyName
    pcall(function() keyName = key.KeyName end)
    local result = P.nameString(keyName)
    if result ~= nil then return result end

    local nestedKey
    pcall(function() nestedKey = P.unwrap(key.Key) end)
    if nestedKey ~= nil then
        keyName = nil
        pcall(function() keyName = nestedKey.KeyName end)
        result = P.nameString(keyName)
        if result ~= nil then return result end
    end
    -- FKey wrappers are not guaranteed to expose a safe UObject-style
    -- ToString call on every UE4SS build. Match Pal Insight and accept only a
    -- real KeyName (or its nested chord key) instead of stringifying the whole
    -- reflected parameter.
    return nil
end

local function pressedHook(context, keyParam)
    if not ownsBridge(context) then return end
    local keyName = bridgeKeyName(keyParam)
    if type(keyName) == "string" and keyName:find("Gamepad_", 1, true) == 1 then
        dispatchEvent("onPressed", keyName, "actor")
    end
end

local function releasedHook(context, keyParam)
    if not ownsBridge(context) then return end
    local keyName = bridgeKeyName(keyParam)
    if type(keyName) == "string" and keyName:find("Gamepad_", 1, true) == 1 then
        dispatchEvent("onReleased", keyName, "actor")
    end
end

local function clickedHook(context)
    if ownsDelegateBridge(context, state.actionDelegateBridge,
            state.actionDelegateBridgeAddress) or ownsBridge(context) then
        local now = os.clock()
        state.nativeActionLastEventAt = now
        state.nativeActionLastEventGeneration = state.generation
        if state.globalMouseFallbackGeneration == state.generation
            and now - state.globalMouseFallbackAt <= 0.08 then return true end
        dispatchEvent("onClicked", "mouse")
    end
end

local function toggleChangedHook(context, _checkedParam)
    if ownsDelegateBridge(context, state.toggleDelegateBridge,
            state.toggleDelegateBridgeAddress) then
        dispatchEvent("onToggleChanged", "mouse", "native")
    end
end

local function axisValue(valueParam)
    if valueParam == nil then return nil end
    local value
    local ok = pcall(function() value = valueParam:get() end)
    if not ok then value = valueParam end
    value = P.unwrap(value)
    return tonumber(value)
end

local function axisXHook(context, valueParam)
    if not ownsBridge(context) then return end
    local value = axisValue(valueParam)
    if type(value) == "number" then dispatchEvent("onAxisX", value) end
end

local function axisYHook(context, valueParam)
    if not ownsBridge(context) then return end
    local value = axisValue(valueParam)
    if type(value) == "number" then dispatchEvent("onAxisY", value) end
end

local function hookValue(param)
    if param == nil then return nil end
    local ok, value = pcall(function() return param:get() end)
    if ok then return P.unwrap(value) end
    return P.unwrap(param)
end

local function widgetLibrary()
    return P.staticObject("/Script/UMG.Default__WidgetBlueprintLibrary")
end

local function focusIfAlive(widget)
    return P.isValid(widget) and widget or nil
end

local function applyModalInput()
    local controller = state.controller
    local ownerWidget = state.ownerWidget
    local library = widgetLibrary()
    if not ownsController(controller)
        or not sameObject(ownerWidget, state.ownerWidgetAddress)
        or library == nil then return false end
    state.applyingInputMode = true
    local modeApplied = pcall(function()
        if state.modalUIOnly then
            library:SetInputMode_UIOnlyEx(controller, ownerWidget, 0, false)
        else
            library:SetInputMode_GameAndUIEx(
                controller, ownerWidget, 0, false, false)
        end
    end)
    state.applyingInputMode = false
    local cursorApplied, cursorVisible = pcall(function()
        controller.bShowMouseCursor = true
        return controller.bShowMouseCursor == true
    end)
    local focused = pcall(function() ownerWidget:SetKeyboardFocus() end)
    return modeApplied == true and cursorApplied == true
        and cursorVisible == true and focused == true
end

local function scheduleModalReclaim()
    if state.active ~= true or state.reclaimPending then return end
    state.reclaimPending = true
    local generation = state.generation
    state.reclaimCallback = function()
        state.reclaimCallback = nil
        if state.active ~= true or state.generation ~= generation then
            state.reclaimPending = false
            return
        end
        state.reclaimPending = false
        if not applyModalInput() then
            log("cannot reclaim modal input after an external mode change")
            requestClose("input-ownership-failed")
        end
    end
    -- The game often assigns bShowMouseCursor immediately after calling an
    -- input-mode helper. Defer one event turn so the modal reclaim wins after
    -- the complete external transition rather than racing its remaining code.
    local scheduled = type(ExecuteInGameThreadWithDelay) == "function"
        and pcall(ExecuteInGameThreadWithDelay, 0, state.reclaimCallback)
        or false
    if not scheduled then
        state.reclaimPending = false
        state.reclaimCallback = nil
        requestClose("input-ownership-dispatch-failed")
    end
end

local function observeInputMode(mode, controllerParam, focusParam,
        mouseLockParam, hideCursorParam)
    if state.applyingInputMode then return end
    local controller = hookValue(controllerParam)
    local controllerAddress = P.objectAddress(controller)
    if controllerAddress == nil then return end
    local context = {
        mode = mode,
        controllerAddress = controllerAddress,
        focusWidget = hookValue(focusParam),
        mouseLockMode = tonumber(hookValue(mouseLockParam)) or 0,
        hideCursorDuringCapture = hookValue(hideCursorParam) == true,
        showMouseCursor = mode ~= "GameOnly",
    }
    state.lastObservedInputContext = context
    if not ownsController(controller) then return end
    state.externalInputContext = context
    scheduleModalReclaim()
end

local function gameOnlyHook(_context, controllerParam, _flushParam)
    observeInputMode("GameOnly", controllerParam, nil, nil, nil)
end

local function uiOnlyHook(_context, controllerParam, focusParam,
        mouseLockParam, _flushParam)
    observeInputMode("UIOnly", controllerParam, focusParam, mouseLockParam, nil)
end

local function gameAndUiHook(_context, controllerParam, focusParam,
        mouseLockParam, hideCursorParam, _flushParam)
    observeInputMode("GameAndUI", controllerParam, focusParam,
        mouseLockParam, hideCursorParam)
end

local function canOpenAnyUiHook(_context, canOpenParam)
    if not ownsUnderlyingInput() then return end
    pcall(function() canOpenParam:set(false) end)
end

local function nativeEscapeHook()
    local record = state.escapeCloseGuard
    if type(record) ~= "table" then return end
    record.released = true
    if record.windowClosed == true then record.settleUntil = os.clock() + 0.08 end
end

local function menuQueryGuardHook(_context, valueParam)
    if not ownsUnderlyingInput() then return end
    pcall(function() valueParam:set(false) end)
end

local function installHook(path, callback)
    if state.hookRecords[path] ~= nil then return true end
    if type(RegisterHook) ~= "function" or P.staticObject(path) == nil then
        return false
    end
    local ok, preId, postId = pcall(RegisterHook, path, callback)
    if not ok or type(preId) ~= "number" then return false end
    state.hookRecords[path] = { preId = preId, postId = postId }
    return true
end

local function installInputModeHooks()
    if state.inputModeHooksReady then return true end
    if not installHook(INPUT_MODE_FUNCTIONS.GameOnly, gameOnlyHook)
        or not installHook(INPUT_MODE_FUNCTIONS.UIOnly, uiOnlyHook)
        or not installHook(INPUT_MODE_FUNCTIONS.GameAndUI, gameAndUiHook) then
        return false
    end
    state.inputModeHooksReady = true
    return true
end

local function installEscapePriorityHooks()
    if state.escapePriorityHooksReady then return true end
    if type(RegisterHook) ~= "function" then return false end

    if not state.returnGateReady then
        for _, path in ipairs(RETURN_GATE_FUNCTION_CANDIDATES) do
            if P.staticObject(path) ~= nil then
                local ok, preId, postId = pcall(
                    RegisterHook, path, canOpenAnyUiHook)
                if ok and type(preId) == "number" then
                    state.hookRecords[path] = {
                        preId = preId, postId = postId,
                        callback = canOpenAnyUiHook,
                    }
                    state.returnGatePath = path
                    state.returnGateReady = true
                    break
                end
            end
        end
    end
    if not state.returnGateReady then return false end

    if not state.nativeEscapeHookReady then
        if P.staticObject(NATIVE_ESCAPE_FUNCTION) == nil then return false end
        local escapeOk, escapePreId, escapePostId = pcall(
            RegisterHook, NATIVE_ESCAPE_FUNCTION, nativeEscapeHook)
        if not escapeOk or type(escapePreId) ~= "number" then return false end
        state.hookRecords[NATIVE_ESCAPE_FUNCTION] = {
            preId = escapePreId, postId = escapePostId,
            callback = nativeEscapeHook,
        }
        state.nativeEscapeHookReady = true
    end
    if not state.menuQueryHookReady then
        if P.staticObject(MENU_QUERY_FUNCTION) == nil then return false end
        local queryOk, queryPreId, queryPostId = pcall(RegisterHook,
            MENU_QUERY_FUNCTION, menuQueryGuardHook, menuQueryGuardHook)
        if not queryOk or type(queryPreId) ~= "number" then return false end
        state.hookRecords[MENU_QUERY_FUNCTION] = {
            preId = queryPreId, postId = queryPostId,
            callback = menuQueryGuardHook,
        }
        state.menuQueryHookReady = true
    end
    state.escapePriorityHooksReady = true
    return true
end

local function installBridgeHooks()
    if state.bridgeHooksReady then return true end
    if not installHook(BRIDGE_PRESSED_FUNCTION, pressedHook)
        or not installHook(BRIDGE_RELEASED_FUNCTION, releasedHook)
        or not installHook(BRIDGE_AXIS_X_FUNCTION, axisXHook)
        or not installHook(BRIDGE_AXIS_Y_FUNCTION, axisYHook) then
        return false
    end
    state.bridgeHooksReady = true
    return true
end

local function installActionDelegateHook()
    if state.actionDelegateHookReady then return true end
    if not installHook(BRIDGE_CLICKED_FUNCTION, clickedHook) then return false end
    state.actionDelegateHookReady = true
    return true
end

local function installToggleDelegateHook()
    if state.toggleDelegateHookReady then return true end
    if not installHook(BRIDGE_TOGGLE_CHANGED_FUNCTION,
            toggleChangedHook) then return false end
    state.toggleDelegateHookReady = true
    return true
end

local function registerKeyboardBindings()
    if state.keyboardBindingsReady then return true end
    if type(RegisterKeyBind) ~= "function" or type(Key) ~= "table" then
        return false
    end
    for _, spec in ipairs({
        { name = "W", value = Key.W },
        { name = "S", value = Key.S },
        { name = "A", value = Key.A },
        { name = "D", value = Key.D },
        { name = "Up", value = Key.UP_ARROW },
        { name = "Down", value = Key.DOWN_ARROW },
        { name = "Left", value = Key.LEFT_ARROW },
        { name = "Right", value = Key.RIGHT_ARROW },
        { name = "Enter", value = Key.RETURN },
        { name = "SpaceBar", value = Key.SPACE },
        { name = "Escape", value = Key.ESCAPE },
        { name = "Tab", value = Key.TAB },
        { name = "LeftMouseButton", value = Key.LEFT_MOUSE_BUTTON },
    }) do
        if spec.value ~= nil and state.keyboardBindingCallbacks[spec.name] == nil then
            local name = spec.name
            local callback = function()
                queueKeyboardPress(name)
            end
            local ok = pcall(RegisterKeyBind, spec.value, callback)
            if not ok then return false end
            -- UE4SS does not own a Lua callback strongly enough for us to rely
            -- on it surviving collection. Keep every process-lifetime binding
            -- reachable; losing one here makes navigation appear to die later.
            state.keyboardBindingCallbacks[name] = callback
        end
    end
    state.keyboardBindingsReady = true
    return true
end

local function acquireInputIsolation(controller)
    local isolation = {
        controller = controller,
        controllerAddress = state.controllerAddress,
        move = false,
        look = false,
    }
    state.inputIsolation = isolation
    local move = pcall(function() controller:SetIgnoreMoveInput(true) end)
    if not move then return false end
    isolation.move = true
    local look = pcall(function() controller:SetIgnoreLookInput(true) end)
    if not look then return false end
    isolation.look = true
    return true
end

local function releaseInputIsolation()
    local isolation = state.inputIsolation
    if type(isolation) ~= "table"
        or not sameObject(isolation.controller, isolation.controllerAddress) then
        state.inputIsolation = nil
        return true
    end
    local ok = true
    if isolation.look then
        local released = pcall(function()
            isolation.controller:SetIgnoreLookInput(false)
        end)
        if released then isolation.look = false else ok = false end
    end
    if isolation.move then
        local released = pcall(function()
            isolation.controller:SetIgnoreMoveInput(false)
        end)
        if released then isolation.move = false else ok = false end
    end
    if isolation.look ~= true and isolation.move ~= true then
        state.inputIsolation = nil
    end
    return ok
end

local function reclaimInputIsolation(isolation)
    if type(isolation) ~= "table"
        or not sameObject(isolation.controller, isolation.controllerAddress) then
        return false
    end
    state.inputIsolation = isolation
    local ok = true
    if isolation.move ~= true then
        local acquired = pcall(function()
            isolation.controller:SetIgnoreMoveInput(true)
        end)
        if acquired then isolation.move = true else ok = false end
    end
    if isolation.look ~= true then
        local acquired = pcall(function()
            isolation.controller:SetIgnoreLookInput(true)
        end)
        if acquired then isolation.look = true else ok = false end
    end
    return ok and isolation.move == true and isolation.look == true
end

local function setCookedBridgeActive(bridge, active)
    if not P.isValid(bridge) then return active ~= true end
    return pcall(function()
        bridge:UnregisterInputComponent()
        bridge:SetInputActionPriority(BRIDGE_PRIORITY)
        bridge:SetInputActionBlocking(active == true)
        if active == true then bridge:RegisterInputComponent() end
    end) == true
end

local function restoreInputContext(controller, controllerAddress, context)
    if not sameObject(controller, controllerAddress) then return true end
    if type(context) ~= "table" then return false end
    local library = widgetLibrary()
    local focusWidget = focusIfAlive(context.focusWidget)
    if library == nil then return false end
    if context.mode == "UIOnly" and focusWidget == nil
        and context.allowMissingFocus ~= true then return false end
    state.applyingInputMode = true
    local restored, cursorMatches = pcall(function()
        if context.mode == "UIOnly" then
            library:SetInputMode_UIOnlyEx(controller, focusWidget,
                tonumber(context.mouseLockMode) or 0, false)
        elseif context.mode == "GameAndUI" then
            library:SetInputMode_GameAndUIEx(controller, focusWidget,
                tonumber(context.mouseLockMode) or 0,
                context.hideCursorDuringCapture == true, false)
        else
            library:SetInputMode_GameOnly(controller, true)
        end
        controller.bShowMouseCursor = context.showMouseCursor == true
        return controller.bShowMouseCursor == (context.showMouseCursor == true)
    end)
    state.applyingInputMode = false
    return restored == true and cursorMatches == true
end

local function captureInputContext(controller, hostedParent)
    hostedParent = hostedParent == true
    local ok, cursorVisible = pcall(function()
        return controller.bShowMouseCursor == true
    end)
    if not ok then return nil end
    local controllerAddress = P.objectAddress(controller)
    local observed = state.lastObservedInputContext
    if controllerAddress ~= nil and type(observed) == "table"
        and observed.controllerAddress == controllerAddress then
        local mode = observed.mode
        if cursorVisible and mode == "GameOnly" then
            if not hostedParent then return nil end
            mode = "GameAndUI"
        end
        local focusWidget = focusIfAlive(observed.focusWidget)
        if mode == "UIOnly" and focusWidget == nil
            and not hostedParent then return nil end
        return {
            mode = mode,
            focusWidget = focusWidget,
            mouseLockMode = observed.mouseLockMode,
            hideCursorDuringCapture = observed.hideCursorDuringCapture,
            showMouseCursor = cursorVisible == true,
            allowMissingFocus = hostedParent and mode == "UIOnly",
        }
    end
    if cursorVisible and not hostedParent then return nil end
    return {
        mode = cursorVisible and "GameAndUI" or "GameOnly",
        focusWidget = nil,
        mouseLockMode = 0,
        hideCursorDuringCapture = false,
        showMouseCursor = cursorVisible == true,
        allowMissingFocus = hostedParent and cursorVisible,
    }
end

local function releaseRestoreContext(context, ownerUnavailable)
    if type(context) ~= "table" or context.mode ~= "UIOnly" then return context end
    local focusWidget = focusIfAlive(context.focusWidget)
    if not ownerUnavailable and (focusWidget ~= nil
        or context.allowMissingFocus == true) then return context end
    if not ownerUnavailable and context.focusWidget == nil then return context end
    log("UI-only input owner is unavailable; restoring an interactive fallback")
    return {
        mode = "GameAndUI",
        focusWidget = nil,
        mouseLockMode = context.mouseLockMode,
        hideCursorDuringCapture = false,
        showMouseCursor = true,
    }
end

function Bridge.configure(logger)
    state.log = logger
    NativeSettingsInput.configure(logger)
    installInputModeHooks()
end

function Bridge.available()
    local version, readable = sharedRead(CAPABILITY_NAME)
    if not readable or version ~= CAPABILITY_VERSION
        or type(ExecuteInGameThread) ~= "function" then return false end
    if not installInputModeHooks() then return false end
    if registerKeyboardBindings() then return true end
    if not state.keyboardWarningLogged then
        state.keyboardWarningLogged = true
        log("keyboard close bindings are unavailable")
    end
    return false
end

function Bridge.prepare()
    if type(ExecuteInGameThread) ~= "function"
        or not installInputModeHooks() or not registerKeyboardBindings() then
        return false
    end
    local version, readable = sharedRead(CAPABILITY_NAME)
    if not readable or version ~= CAPABILITY_VERSION then return false end
    if state.bridgeHooksReady then return true end
    local bridgeClass = P.staticObject(BRIDGE_CLASS_PATH)
    if bridgeClass == nil and type(LoadAsset) == "function" then
        pcall(LoadAsset, BRIDGE_ASSET_PATH)
        bridgeClass = P.staticObject(BRIDGE_CLASS_PATH)
    end
    return bridgeClass ~= nil and installBridgeHooks()
end

local function discardBridgeCache()
    local cache = state.bridgeCache
    local bridge = type(cache) == "table" and cache.bridge or nil
    if not P.isValid(bridge) then
        state.bridgeCache = nil
        return true
    end
    if not setCookedBridgeActive(bridge, false) then return false end
    if pcall(function() bridge:RemoveFromParent() end) ~= true then return false end
    state.bridgeCache = nil
    return true
end

local function prepareBridgeCache(controller)
    if not Bridge.prepare() or not P.isValid(controller) then return nil, false end
    local world
    local ok = pcall(function() world = controller:GetWorld() end)
    local worldAddress = ok and P.objectAddress(world) or nil
    local controllerAddress = P.objectAddress(controller)
    local cache = state.bridgeCache
    if type(cache) == "table" and P.isValid(cache.bridge)
        and cache.worldAddress == worldAddress
        and cache.controllerAddress == controllerAddress
        and P.objectAddress(cache.bridge) == cache.bridgeAddress then
        return cache.bridge, true
    end
    if state.active then return nil, false end
    if cache ~= nil and not discardBridgeCache() then return nil, false end
    if worldAddress == nil or controllerAddress == nil then return nil, false end
    local library = widgetLibrary()
    local bridgeClass = P.staticObject(BRIDGE_CLASS_PATH)
    if library == nil or bridgeClass == nil then return nil, false end
    local bridge
    ok = pcall(function() bridge = library:Create(world, bridgeClass, controller) end)
    if not ok or not P.isValid(bridge) then return nil, false end
    local prepared = pcall(function()
        -- Mount once. Open/close only registers its already-created input
        -- component; the hot path never reconstructs the cooked widget.
        bridge.bIsFocusable = false
        bridge:SetRenderOpacity(0.0)
        bridge:SetVisibility(3)
        bridge:UnregisterInputComponent()
        bridge:SetInputActionPriority(BRIDGE_PRIORITY)
        bridge:SetInputActionBlocking(false)
        bridge:AddToViewport(99)
    end)
    local bridgeAddress = prepared and P.objectAddress(bridge) or nil
    if bridgeAddress == nil then
        pcall(function() bridge:UnregisterInputComponent() end)
        pcall(function() bridge:SetInputActionBlocking(false) end)
        pcall(function() bridge:RemoveFromParent() end)
        return nil, false
    end
    state.bridgeCache = {
        bridge = bridge,
        bridgeAddress = bridgeAddress,
        worldAddress = worldAddress,
        controllerAddress = controllerAddress,
    }
    return bridge, false
end

function Bridge.prepareForController(controller)
    local bridge, cacheHit = prepareBridgeCache(controller)
    return P.isValid(bridge), cacheHit == true
end

local function handlersFor(options)
    if type(options) == "function" then
        local close = options
        return {
            onPressed = function(keyName)
                if keyName == "Enter" or keyName == "SpaceBar"
                    or keyName == "Escape" then close(keyName) end
            end,
            onReleased = function(keyName)
                if keyName == "Gamepad_FaceButton_Bottom"
                    or keyName == "Gamepad_FaceButton_Right" then close(keyName) end
            end,
            onClicked = function() close("mouse") end,
            onClose = close,
        }, false
    end
    options = type(options) == "table" and options or {}
    return options, options.allowWithoutBridge == true
end

function Bridge.acquire(controller, ownerWidget, options)
    if state.active then return false, "bridge is already active" end
    local handlers, allowWithoutBridge = handlersFor(options)
    local modalUIOnly = type(options) == "table" and options.modalUIOnly == true
    local hostedParent = type(options) == "table" and options.hostedParent == true
    local useCookedBridge = type(options) ~= "table"
        or options.useCookedBridge ~= false
    local exclusiveController = type(options) == "table"
        and options.exclusiveController == true
    if not hostedParent and not installEscapePriorityHooks() then
        log("native Escape priority hooks are unavailable")
    end
    local cookedAvailable = useCookedBridge and Bridge.prepare() or false
    if useCookedBridge and not cookedAvailable and not allowWithoutBridge then
        return false, "compatible Pal Insight is absent"
    end
    if type(ExecuteInGameThread) ~= "function"
        or not installInputModeHooks() or not registerKeyboardBindings() then
        return false, "modal input callbacks are unavailable"
    end
    if not P.isValid(controller) or not P.isValid(ownerWidget)
        or type(handlers) ~= "table" then
        return false, "modal input owner is unavailable"
    end

    local world
    local ok = pcall(function() world = controller:GetWorld() end)
    local library = widgetLibrary()
    if not ok or not P.isValid(world) or library == nil then
        return false, "bridge creation roots are unavailable"
    end
    local bridge, bridgeAddress, bridgeCacheHit
    if cookedAvailable then
        bridge, bridgeCacheHit = prepareBridgeCache(controller)
        if not P.isValid(bridge) then return false, "bridge widget cannot be prepared" end
        bridgeAddress = P.objectAddress(bridge)
    end
    local controllerAddress = P.objectAddress(controller)
    local ownerWidgetAddress = P.objectAddress(ownerWidget)
    local inputContext = captureInputContext(controller, hostedParent)
    local hostedFallbackContext
    if hostedParent and type(inputContext) == "table" then
        hostedFallbackContext = {
            mode = inputContext.mode,
            focusWidget = inputContext.focusWidget,
            mouseLockMode = inputContext.mouseLockMode,
            hideCursorDuringCapture = inputContext.hideCursorDuringCapture,
            showMouseCursor = inputContext.showMouseCursor,
            allowMissingFocus = inputContext.allowMissingFocus,
        }
        -- Pal Insight is a UIOnly modal owner. A late-loaded extension may have
        -- missed the parent's original reflected transition and otherwise infer
        -- GameAndUI from the visible cursor. Preserve UI isolation throughout
        -- the close acknowledgement; the host restores its exact root focus.
        inputContext.mode = "UIOnly"
        inputContext.hideCursorDuringCapture = false
        inputContext.showMouseCursor = true
        inputContext.allowMissingFocus = true
    end
    if (cookedAvailable and bridgeAddress == nil) or controllerAddress == nil
        or ownerWidgetAddress == nil or inputContext == nil then
        if cookedAvailable then discardBridgeCache() end
        return false, "bridge input ownership cannot be prepared"
    end

    state.generation = state.generation + 1
    state.bridge = bridge
    state.bridgeAddress = bridgeAddress
    state.ownerWidget = ownerWidget
    state.ownerWidgetAddress = ownerWidgetAddress
    state.controller = controller
    state.controllerAddress = controllerAddress
    state.inputContext = inputContext
    state.hostedFallbackContext = hostedFallbackContext
    state.externalInputContext = nil
    state.handlers = handlers
    state.modalUIOnly = modalUIOnly
    state.hostedParent = hostedParent
    state.cookedInputActive = false
    state.nativeInputActive = false
    state.active = true
    state.nativeActionLastEventAt = -10.0
    state.nativeActionLastEventGeneration = state.generation
    state.globalMouseFallbackAt = -10.0
    state.globalMouseFallbackGeneration = state.generation
    state.closePending = false
    state.reclaimPending = false

    if cookedAvailable then
        -- Record the conservative lease before the first fallible mutation. A
        -- partial activation must remain visible to the normal/watchdog release
        -- transaction instead of becoming an ownerless blocking component.
        state.cookedInputActive = true
        if not setCookedBridgeActive(bridge, true) then
            local released = Bridge.release()
            return false, "cooked input bridge cannot be activated",
                released ~= true and state.active == true
        end
    end

    if exclusiveController and not hostedParent then
        local nativeAcquired, nativeError = NativeSettingsInput.acquire()
        state.nativeInputActive = nativeAcquired == true
            or NativeSettingsInput.active()
        if not nativeAcquired then
            local released = Bridge.release()
            return false, nativeError or "native controller isolation is unavailable",
                released ~= true and state.active == true
        end
    end

    state.lastAcquireDiagnostics = {
        bridgeAvailable = cookedAvailable == true,
        bridgeCacheHit = bridgeCacheHit == true,
        bridgeCreated = cookedAvailable == true and bridgeCacheHit ~= true,
        bridgeMounted = cookedAvailable == true and bridgeCacheHit ~= true,
        nativeInputActive = state.nativeInputActive == true,
    }

    local isolationAcquired = hostedParent or acquireInputIsolation(controller)
    if not isolationAcquired or not applyModalInput() then
        local released = Bridge.release()
        return false, "settings input ownership cannot be acquired",
            released ~= true and state.active == true
    end
    return true, nil
end

function Bridge.cookedInputActive()
    return state.active == true and state.cookedInputActive == true
end

function Bridge.nativeControllerActive()
    return state.active == true and state.nativeInputActive == true
        and NativeSettingsInput.active()
end

function Bridge.readNativeControllerSnapshot()
    if not Bridge.nativeControllerActive() then
        return nil, "native controller isolation is inactive"
    end
    return NativeSettingsInput.readSnapshot()
end

function Bridge.lastAcquireDiagnostics()
    return state.lastAcquireDiagnostics
end

function Bridge.drainPendingInput()
    return drainKeyboardQueue()
end

function Bridge.armEscapeClose(source)
    if state.active ~= true then return false end
    escapeCloseGuardBlocksNativeUI()
    local existing = state.escapeCloseGuard
    if type(existing) == "table" then return true end
    state.escapeCloseSequence = state.escapeCloseSequence + 1
    state.escapeCloseGuard = {
        id = state.escapeCloseSequence,
        generation = state.generation,
        source = tostring(source or "escape"),
        released = false,
        windowClosed = false,
        settleUntil = nil,
        expiresAt = os.clock() + 3.0,
    }
    return true
end

function Bridge.releaseEscapeClose(source)
    local record = state.escapeCloseGuard
    if type(record) ~= "table" then return false end
    record.releaseSource = tostring(source or "release")
    record.released = true
    if record.windowClosed == true then record.settleUntil = os.clock() + 0.08 end
    return true
end

function Bridge.noteEscapeWindowClosed()
    local record = state.escapeCloseGuard
    if type(record) ~= "table" then return false end
    record.windowClosed = true
    record.expiresAt = os.clock() + 3.0
    if record.released == true then record.settleUntil = os.clock() + 0.08 end
    return true
end

function Bridge.cancelEscapeClose()
    state.escapeCloseGuard = nil
    return true
end

function Bridge.discardPendingKey(keyName)
    if type(keyName) ~= "string" then return false end
    local retained = {}
    for _, item in ipairs(state.keyboardQueue) do
        if item.keyName ~= keyName then retained[#retained + 1] = item end
    end
    state.keyboardQueue = retained
    return true
end

local function unbindActionButtons()
    local bridge = state.actionDelegateBridge
    local bridgeAddress = state.actionDelegateBridgeAddress
    for _, record in ipairs(state.actionDelegateRecords or {}) do
        if sameObject(bridge, bridgeAddress)
            and sameObject(record.button, record.address) then
            pcall(function()
                record.button.OnClicked:Remove(
                    bridge, "PalInsightSearchClearClicked")
            end)
        end
    end
    state.actionDelegateBridge = nil
    state.actionDelegateBridgeAddress = nil
    state.actionDelegateRecords = {}
    state.actionDelegateExpectedCount = 0
    return true
end

local function unbindToggleControls()
    local bridge = state.toggleDelegateBridge
    local bridgeAddress = state.toggleDelegateBridgeAddress
    for _, record in ipairs(state.toggleDelegateRecords or {}) do
        if sameObject(bridge, bridgeAddress)
            and sameObject(record.widget, record.address) then
            pcall(function()
                record.widget.OnCheckStateChanged:Remove(
                    bridge, "PalInsightSettingsToggleChanged")
            end)
        end
    end
    state.toggleDelegateBridge = nil
    state.toggleDelegateBridgeAddress = nil
    state.toggleDelegateRecords = {}
    return true
end

local function delegateBridge()
    local bridge = P.staticObject(BRIDGE_DEFAULT_PATH)
    if not P.isValid(bridge) and type(LoadAsset) == "function" then
        pcall(LoadAsset, BRIDGE_ASSET_PATH)
        bridge = P.staticObject(BRIDGE_DEFAULT_PATH)
    end
    local address = P.objectAddress(bridge)
    return address ~= nil and bridge or nil, address
end

local function actionDelegatesReady()
    local records = state.actionDelegateRecords or {}
    if not sameObject(state.actionDelegateBridge,
            state.actionDelegateBridgeAddress)
        or state.actionDelegateExpectedCount < 1
        or #records ~= state.actionDelegateExpectedCount then return false end
    for _, record in ipairs(records) do
        if not sameObject(record.button, record.address) then return false end
    end
    return true
end

function Bridge.bindActionButtons(buttons)
    if state.active ~= true or type(buttons) ~= "table"
        or not installActionDelegateHook() then return false end
    local bridge, bridgeAddress = delegateBridge()
    if bridge == nil then return false end
    if state.actionDelegateBridgeAddress ~= nil
        and (not sameObject(state.actionDelegateBridge,
                state.actionDelegateBridgeAddress)
            or state.actionDelegateBridgeAddress ~= bridgeAddress) then
        unbindActionButtons()
    end
    if state.actionDelegateBridgeAddress == nil then
        state.actionDelegateBridge = bridge
        state.actionDelegateBridgeAddress = bridgeAddress
    end
    local seen = {}
    for _, record in ipairs(state.actionDelegateRecords or {}) do
        if not sameObject(record.button, record.address) then
            unbindActionButtons()
            state.actionDelegateBridge = bridge
            state.actionDelegateBridgeAddress = bridgeAddress
            seen = {}
            break
        end
        seen[record.address] = true
    end
    local pending = {}
    local expected = {}
    for _, button in ipairs(buttons) do
        if P.isValid(button) then
            local address = P.objectAddress(button)
            if address == nil then
                unbindActionButtons()
                return false
            end
            expected[address] = true
            if not seen[address] then
                seen[address] = true
                pending[#pending + 1] = { button = button, address = address }
            end
        end
    end
    local added = {}
    for _, record in ipairs(pending) do
        local ok = pcall(function()
            record.button.OnClicked:Add(
                bridge, "PalInsightSearchClearClicked")
        end)
        if not ok then
            for _, rollback in ipairs(added) do
                pcall(function()
                    rollback.button.OnClicked:Remove(
                        bridge, "PalInsightSearchClearClicked")
                end)
            end
            unbindActionButtons()
            return false
        end
        added[#added + 1] = record
    end
    for _, record in ipairs(added) do
        state.actionDelegateRecords[#state.actionDelegateRecords + 1] = record
    end
    local expectedCount = 0
    for _ in pairs(expected) do expectedCount = expectedCount + 1 end
    state.actionDelegateExpectedCount = expectedCount
    return actionDelegatesReady()
end

function Bridge.nativeActionDelegatesReady()
    return state.active == true and actionDelegatesReady()
end

function Bridge.unbindActionButtons()
    return unbindActionButtons()
end

function Bridge.bindToggleControls(controls)
    if state.active ~= true or type(controls) ~= "table"
        or not installToggleDelegateHook() then return false end
    local pending = {}
    local seen = {}
    for _, control in ipairs(controls) do
        local widget = type(control) == "table"
            and control.kind == "toggle" and control.widget or nil
        if P.isValid(widget) then
            local address = P.objectAddress(widget)
            if address == nil then return false end
            if not seen[address] then
                seen[address] = true
                pending[#pending + 1] = {
                    widget = widget,
                    address = address,
                }
            end
        end
    end
    if #pending == 0 then return false end
    local bridge, bridgeAddress = delegateBridge()
    if bridge == nil then return false end
    local current = state.toggleDelegateRecords or {}
    local same = sameObject(state.toggleDelegateBridge,
            state.toggleDelegateBridgeAddress)
        and state.toggleDelegateBridgeAddress == bridgeAddress
        and #current == #pending
    if same then
        local currentAddresses = {}
        for _, record in ipairs(current) do
            if not sameObject(record.widget, record.address) then
                same = false
                break
            end
            currentAddresses[record.address] = true
        end
        if same then
            for _, record in ipairs(pending) do
                if currentAddresses[record.address] ~= true then
                    same = false
                    break
                end
            end
        end
    end
    if same then return true end
    unbindToggleControls()
    state.toggleDelegateBridge = bridge
    state.toggleDelegateBridgeAddress = bridgeAddress
    local added = {}
    for _, record in ipairs(pending) do
        local ok = pcall(function()
            record.widget.OnCheckStateChanged:Add(
                bridge, "PalInsightSettingsToggleChanged")
        end)
        if not ok then
            for _, rollback in ipairs(added) do
                pcall(function()
                    rollback.widget.OnCheckStateChanged:Remove(
                        bridge, "PalInsightSettingsToggleChanged")
                end)
            end
            unbindToggleControls()
            return false
        end
        added[#added + 1] = record
    end
    state.toggleDelegateRecords = added
    return true
end

function Bridge.unbindToggleControls()
    return unbindToggleControls()
end

function Bridge.bindCloseButton(button)
    if state.active ~= true or not P.isValid(state.bridge)
        or not P.isValid(button) then return false end
    local address = P.objectAddress(button)
    if address == nil then return false end
    local ok = pcall(function()
        button.OnClicked:Add(state.bridge, "PalInsightSearchClearClicked")
        button.bIsFocusable = true
    end)
    if not ok then return false end
    state.closeButton = button
    state.closeButtonAddress = address
    return true
end

function Bridge.focusCloseButton()
    if state.active ~= true or not P.isValid(state.closeButton) then return false end
    local ok = pcall(function() state.closeButton:SetKeyboardFocus() end)
    return ok
end

local function clearModalOwnership()
    state.active = false
    state.generation = state.generation + 1
    state.closePending = false
    state.reclaimPending = false
    state.closeDispatchCallback = nil
    state.reclaimCallback = nil
    state.handlers = nil
    state.modalUIOnly = false
    state.hostedParent = false
    state.cookedInputActive = false
    state.nativeInputActive = false
    state.keyboardQueue = {}
    state.keyboardWakePending = false
    state.closeButton = nil
    state.closeButtonAddress = nil
    state.bridge = nil
    state.bridgeAddress = nil
    state.ownerWidget = nil
    state.ownerWidgetAddress = nil
    state.controller = nil
    state.controllerAddress = nil
    state.inputContext = nil
    state.hostedFallbackContext = nil
    state.externalInputContext = nil
    state.inputIsolation = nil
end

function Bridge.release(options)
    if state.active ~= true then return true end
    local bridge = state.bridge
    local button = state.closeButton
    local buttonAddress = state.closeButtonAddress
    local hostUnavailable = type(options) == "table"
        and options.hostUnavailable == true
    local restoreContext = state.hostedParent == true and not hostUnavailable
        and state.inputContext
        or state.externalInputContext or state.hostedFallbackContext
        or state.inputContext
    restoreContext = releaseRestoreContext(restoreContext, hostUnavailable)
    local controller = state.controller
    local controllerAddress = state.controllerAddress
    local isolation = state.inputIsolation
    local cookedWasActive = state.cookedInputActive == true
    local nativeWasActive = state.nativeInputActive == true

    -- Closing is a transaction. Do not discard ownership records until the
    -- blocking component, movement/look lease, and prior input context have all
    -- been released. A failed stage rolls the same visible panel back to modal.
    if cookedWasActive and not setCookedBridgeActive(bridge, false) then
        setCookedBridgeActive(bridge, true)
        log("cooked input bridge could not be detached")
        return false
    end
    local isolationReleased = releaseInputIsolation()
    local inputRestored = isolationReleased
        and restoreInputContext(controller, controllerAddress, restoreContext)

    if not isolationReleased or not inputRestored then
        local isolationReclaimed = reclaimInputIsolation(isolation)
        local bridgeReclaimed = not cookedWasActive
            or setCookedBridgeActive(bridge, true)
        local modalReclaimed = applyModalInput()
        log("input restore failed; modal rollback isolation="
            .. tostring(isolationReclaimed) .. " bridge="
            .. tostring(bridgeReclaimed) .. " mode="
            .. tostring(modalReclaimed))
        return false
    end

    if nativeWasActive and not NativeSettingsInput.release() then
        local isolationReclaimed = reclaimInputIsolation(isolation)
        local bridgeReclaimed = not cookedWasActive
            or setCookedBridgeActive(bridge, true)
        local modalReclaimed = applyModalInput()
        log("native controller filter could not be released; modal rollback isolation="
            .. tostring(isolationReclaimed) .. " bridge="
            .. tostring(bridgeReclaimed) .. " mode="
            .. tostring(modalReclaimed))
        return false
    end

    if P.isValid(bridge) and P.isValid(button)
        and P.objectAddress(button) == buttonAddress then
        pcall(function()
            button.OnClicked:Remove(bridge, "PalInsightSearchClearClicked")
        end)
    end
    clearModalOwnership()
    return true
end

function Bridge.emergencyRelease(options)
    if state.active ~= true then return true end
    local bridge = state.bridge
    local button = state.closeButton
    local buttonAddress = state.closeButtonAddress
    local controller = state.controller
    local controllerAddress = state.controllerAddress
    local hostUnavailable = type(options) == "table"
        and options.hostUnavailable == true

    -- This path runs only after bounded normal retries. It is still a verified
    -- transaction: never hide the panel or discard an ownership record merely
    -- because a best-effort call was attempted.
    local isolation = state.inputIsolation
    local cookedWasActive = state.cookedInputActive == true
    local cookedReleased = not cookedWasActive
        or setCookedBridgeActive(bridge, false)
    if not cookedReleased and P.isValid(bridge) then
        cookedReleased = pcall(function()
            bridge:SetInputActionBlocking(false)
            bridge:UnregisterInputComponent()
        end) == true
    end
    local isolationReleased = releaseInputIsolation()
    if not cookedReleased or not isolationReleased then
        local isolationReclaimed = reclaimInputIsolation(isolation)
        local bridgeReclaimed = not cookedWasActive
            or setCookedBridgeActive(bridge, true)
        applyModalInput()
        log("modal watchdog retained recovery transaction: cooked="
            .. tostring(cookedReleased) .. " isolation="
            .. tostring(isolationReleased) .. " rollbackIsolation="
            .. tostring(isolationReclaimed) .. " rollbackBridge="
            .. tostring(bridgeReclaimed))
        return false
    end

    local restoreContext = state.hostedParent == true and not hostUnavailable
        and state.inputContext
        or state.externalInputContext or state.hostedFallbackContext
        or state.inputContext
    restoreContext = releaseRestoreContext(restoreContext, hostUnavailable)
    local restored = restoreInputContext(
        controller, controllerAddress, restoreContext)
    if not restored then
        reclaimInputIsolation(isolation)
        if cookedWasActive then setCookedBridgeActive(bridge, true) end
        applyModalInput()
        log("modal watchdog could not restore input; recovery transaction retained")
        return false
    end

    local nativeReleased = state.nativeInputActive ~= true
        or NativeSettingsInput.emergencyRelease() == true
    if not nativeReleased then
        reclaimInputIsolation(isolation)
        if cookedWasActive then setCookedBridgeActive(bridge, true) end
        applyModalInput()
        log("modal watchdog could not release native controller filter; recovery transaction retained")
        return false
    end
    if P.isValid(bridge) and P.isValid(button)
        and P.objectAddress(button) == buttonAddress then
        pcall(function()
            button.OnClicked:Remove(bridge, "PalInsightSearchClearClicked")
        end)
    end
    clearModalOwnership()
    log("modal watchdog completed a verified emergency release")
    return true
end

return Bridge
