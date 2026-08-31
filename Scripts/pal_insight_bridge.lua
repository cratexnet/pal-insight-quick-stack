local P = require("palworld")

local Bridge = {}

local SHARED_PREFIX = "PalInsightQuickStack."
local CAPABILITY_NAME = "ResultDialogBridgeVersion"
local CAPABILITY_VERSION = 2
local BRIDGE_PRIORITY = 9999
local BRIDGE_ASSET_PATH =
    "/Game/Mods/PalInsightX/WBP_PalInsightX_Settings"
local BRIDGE_CLASS_PATH = BRIDGE_ASSET_PATH .. ".WBP_PalInsightX_Settings_C"
local BRIDGE_PRESSED_FUNCTION = BRIDGE_CLASS_PATH
    .. ":PalInsightInputBridgePressed"
local BRIDGE_RELEASED_FUNCTION = BRIDGE_CLASS_PATH
    .. ":PalInsightInputBridgeReleased"
local BRIDGE_CLICKED_FUNCTION = BRIDGE_CLASS_PATH
    .. ":PalInsightSearchClearClicked"
local INPUT_MODE_FUNCTIONS = {
    GameOnly = "/Script/UMG.WidgetBlueprintLibrary:SetInputMode_GameOnly",
    UIOnly = "/Script/UMG.WidgetBlueprintLibrary:SetInputMode_UIOnlyEx",
    GameAndUI = "/Script/UMG.WidgetBlueprintLibrary:SetInputMode_GameAndUIEx",
}

local state = {
    log = nil,
    keyboardBindingsReady = false,
    keyboardBindingsAttempted = false,
    keyboardWarningLogged = false,
    bridgeHooksReady = false,
    inputModeHooksReady = false,
    hookRecords = {},
    bridge = nil,
    bridgeAddress = nil,
    ownerWidget = nil,
    ownerWidgetAddress = nil,
    controller = nil,
    controllerAddress = nil,
    closeButton = nil,
    closeButtonAddress = nil,
    onClose = nil,
    active = false,
    closePending = false,
    reclaimPending = false,
    applyingInputMode = false,
    inputContext = nil,
    externalInputContext = nil,
    lastObservedInputContext = nil,
    inputIsolation = nil,
    generation = 0,
}

local function log(message)
    if type(state.log) == "function" then
        state.log("Pal Insight result-dialog bridge: " .. tostring(message))
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

local function ownsController(controller)
    return state.active == true
        and sameObject(controller, state.controllerAddress)
end

local function requestClose(source)
    if state.active ~= true or state.closePending
        or type(state.onClose) ~= "function" then return false end
    state.closePending = true
    local generation = state.generation
    local scheduled = pcall(ExecuteInGameThread, function()
        if state.active ~= true or state.generation ~= generation then return end
        state.closePending = false
        local callback = state.onClose
        if type(callback) == "function" then callback(source) end
    end)
    if not scheduled then state.closePending = false end
    return scheduled == true
end

local function bridgeKeyName(keyParam)
    local key = P.unwrap(keyParam)
    if key == nil then return nil end
    local ok, keyName = pcall(function() return key.KeyName end)
    if not ok then return nil end
    return P.nameString(keyName)
end

local function pressedHook(context, _keyParam)
    if not ownsBridge(context) then return end
end

local function releasedHook(context, keyParam)
    if not ownsBridge(context) then return end
    local keyName = bridgeKeyName(keyParam)
    if keyName == "Gamepad_FaceButton_Bottom"
        or keyName == "Gamepad_FaceButton_Right" then
        requestClose(keyName)
    end
end

local function clickedHook(context)
    if ownsBridge(context) then requestClose("mouse") end
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
        library:SetInputMode_GameAndUIEx(
            controller, ownerWidget, 0, false, false)
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
    local function reclaim()
        if state.active ~= true or state.generation ~= generation then return end
        state.reclaimPending = false
        if not applyModalInput() then
            log("cannot reclaim modal input after an external mode change")
            requestClose("input-ownership-failed")
        end
    end
    local function dispatchReclaim()
        local dispatched = pcall(ExecuteInGameThread, reclaim)
        if not dispatched and state.active and state.generation == generation then
            state.reclaimPending = false
            requestClose("input-ownership-dispatch-failed")
        end
    end
    -- The game often assigns bShowMouseCursor immediately after calling an
    -- input-mode helper. Defer one event turn so the modal reclaim wins after
    -- the complete external transition rather than racing its remaining code.
    local scheduled = type(ExecuteWithDelay) == "function"
        and pcall(ExecuteWithDelay, 0, dispatchReclaim)
        or pcall(ExecuteInGameThread, reclaim)
    if not scheduled then
        state.reclaimPending = false
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

local function installBridgeHooks()
    if state.bridgeHooksReady then return true end
    if not installHook(BRIDGE_PRESSED_FUNCTION, pressedHook)
        or not installHook(BRIDGE_RELEASED_FUNCTION, releasedHook)
        or not installHook(BRIDGE_CLICKED_FUNCTION, clickedHook) then
        return false
    end
    state.bridgeHooksReady = true
    return true
end

local function registerKeyboardBindings()
    if state.keyboardBindingsAttempted then return state.keyboardBindingsReady end
    state.keyboardBindingsAttempted = true
    if type(RegisterKeyBind) ~= "function" or type(Key) ~= "table" then
        return false
    end
    for _, spec in ipairs({
        { name = "Enter", value = Key.RETURN },
        { name = "SpaceBar", value = Key.SPACE },
        { name = "Escape", value = Key.ESCAPE },
    }) do
        if spec.value == nil then return false end
        local name = spec.name
        local ok = pcall(RegisterKeyBind, spec.value, function()
            requestClose(name)
        end)
        if not ok then return false end
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
    state.inputIsolation = nil
    if type(isolation) ~= "table"
        or not sameObject(isolation.controller, isolation.controllerAddress) then
        return true
    end
    local ok = true
    if isolation.look then
        ok = pcall(function() isolation.controller:SetIgnoreLookInput(false) end)
            and ok
    end
    if isolation.move then
        ok = pcall(function() isolation.controller:SetIgnoreMoveInput(false) end)
            and ok
    end
    return ok
end

local function captureInputContext(controller)
    local ok, cursorVisible = pcall(function()
        return controller.bShowMouseCursor == true
    end)
    if not ok then return nil end
    local controllerAddress = P.objectAddress(controller)
    local observed = state.lastObservedInputContext
    if controllerAddress ~= nil and type(observed) == "table"
        and observed.controllerAddress == controllerAddress then
        local mode = observed.mode
        if cursorVisible and mode == "GameOnly" then mode = "GameAndUI" end
        return {
            mode = mode,
            focusWidget = observed.focusWidget,
            mouseLockMode = observed.mouseLockMode,
            hideCursorDuringCapture = observed.hideCursorDuringCapture,
            showMouseCursor = cursorVisible == true,
        }
    end
    return {
        mode = cursorVisible and "GameAndUI" or "GameOnly",
        focusWidget = nil,
        mouseLockMode = 0,
        hideCursorDuringCapture = false,
        showMouseCursor = cursorVisible == true,
    }
end

function Bridge.configure(logger)
    state.log = logger
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

function Bridge.acquire(controller, ownerWidget, onClose)
    if state.active then return false, "bridge is already active" end
    if not Bridge.available() then return false, "compatible Pal Insight is absent" end
    if not P.isValid(controller) or not P.isValid(ownerWidget)
        or type(onClose) ~= "function" then
        return false, "result-dialog owner is unavailable"
    end

    local bridgeClass = P.staticObject(BRIDGE_CLASS_PATH)
    if bridgeClass == nil and type(LoadAsset) == "function" then
        pcall(LoadAsset, BRIDGE_ASSET_PATH)
        bridgeClass = P.staticObject(BRIDGE_CLASS_PATH)
    end
    if bridgeClass == nil or not installBridgeHooks() then
        return false, "cooked bridge contract is unavailable"
    end

    local world
    local ok = pcall(function() world = controller:GetWorld() end)
    local library = widgetLibrary()
    if not ok or not P.isValid(world) or library == nil then
        return false, "bridge creation roots are unavailable"
    end
    local bridge
    ok = pcall(function() bridge = library:Create(world, bridgeClass, controller) end)
    if not ok or not P.isValid(bridge) then
        return false, "bridge widget cannot be created"
    end

    local prepared = pcall(function()
        bridge.bIsFocusable = false
        bridge:SetRenderOpacity(0.0)
        bridge:SetVisibility(3)
        bridge:UnregisterInputComponent()
        bridge:SetInputActionPriority(BRIDGE_PRIORITY)
        bridge:SetInputActionBlocking(true)
        bridge:RegisterInputComponent()
        bridge:AddToViewport(99)
    end)
    local bridgeAddress = prepared and P.objectAddress(bridge) or nil
    local controllerAddress = P.objectAddress(controller)
    local ownerWidgetAddress = P.objectAddress(ownerWidget)
    local inputContext = captureInputContext(controller)
    if bridgeAddress == nil or controllerAddress == nil
        or ownerWidgetAddress == nil or inputContext == nil then
        pcall(function() bridge:UnregisterInputComponent() end)
        pcall(function() bridge:SetInputActionBlocking(false) end)
        pcall(function() bridge:RemoveFromParent() end)
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
    state.externalInputContext = nil
    state.onClose = onClose
    state.active = true
    state.closePending = false
    state.reclaimPending = false

    if not acquireInputIsolation(controller) or not applyModalInput() then
        Bridge.release()
        return false, "independent result-dialog input ownership cannot be acquired"
    end
    return true, nil
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

function Bridge.release()
    local bridge = state.bridge
    local button = state.closeButton
    local buttonAddress = state.closeButtonAddress
    local restoreContext = state.externalInputContext or state.inputContext
    local controller = state.controller
    local controllerAddress = state.controllerAddress

    state.active = false
    state.generation = state.generation + 1
    state.closePending = false
    state.reclaimPending = false
    state.onClose = nil
    state.closeButton = nil
    state.closeButtonAddress = nil

    if P.isValid(bridge) and P.isValid(button)
        and P.objectAddress(button) == buttonAddress then
        pcall(function()
            button.OnClicked:Remove(bridge, "PalInsightSearchClearClicked")
        end)
    end
    if P.isValid(bridge) then
        pcall(function() bridge:UnregisterInputComponent() end)
        pcall(function() bridge:SetInputActionBlocking(false) end)
        pcall(function() bridge:RemoveFromParent() end)
    end

    local isolationReleased = releaseInputIsolation()
    local inputRestored = true
    if sameObject(controller, controllerAddress) and type(restoreContext) == "table" then
        local library = widgetLibrary()
        local focusWidget = focusIfAlive(restoreContext.focusWidget)
        state.applyingInputMode = true
        inputRestored = library ~= nil and pcall(function()
            if restoreContext.mode == "UIOnly" then
                library:SetInputMode_UIOnlyEx(controller, focusWidget,
                    tonumber(restoreContext.mouseLockMode) or 0, false)
            elseif restoreContext.mode == "GameAndUI" then
                library:SetInputMode_GameAndUIEx(controller, focusWidget,
                    tonumber(restoreContext.mouseLockMode) or 0,
                    restoreContext.hideCursorDuringCapture == true, false)
            else
                library:SetInputMode_GameOnly(controller, true)
            end
            controller.bShowMouseCursor = restoreContext.showMouseCursor == true
        end)
        state.applyingInputMode = false
    end

    state.bridge = nil
    state.bridgeAddress = nil
    state.ownerWidget = nil
    state.ownerWidgetAddress = nil
    state.controller = nil
    state.controllerAddress = nil
    state.inputContext = nil
    state.externalInputContext = nil
    if not isolationReleased or not inputRestored then
        log("input ownership was released with an incomplete restore")
    end
    return isolationReleased == true and inputRestored == true
end

return Bridge
