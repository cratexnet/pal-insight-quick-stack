'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '../../..');
const read = (relative) => fs.readFileSync(path.join(root, relative), 'utf8');
const main = read('Scripts/main.lua');
const settingsUi = read('Scripts/settings_ui.lua');
const bridge = read('Scripts/pal_insight_bridge.lua');
const source = `${main}\n${settingsUi}\n${bridge}`;
const shortcutWarning = settingsUi.slice(
  settingsUi.indexOf('refreshShortcutConflictWarning = function()'),
  settingsUi.indexOf('local function resetControlsToConfig'));
const bridgeRelease = bridge.slice(
  bridge.indexOf('function Bridge.release(options)'),
  bridge.indexOf('\nreturn Bridge'));
const bridgeAcquire = bridge.slice(
  bridge.indexOf('function Bridge.acquire(controller, ownerWidget, options)'),
  bridge.indexOf('\nfunction Bridge.cookedInputActive()'));
const bridgeEmergencyRelease = bridge.slice(
  bridge.indexOf('function Bridge.emergencyRelease(options)'),
  bridge.indexOf('\nreturn Bridge'));
const palInsightRuntimePresence = main.slice(
  main.indexOf('local function livePalInsightRuntime()'),
  main.indexOf('\nlocal function livePalInsightHost()'));

assert.match(main, /local SettingsUI = require\("settings_ui"\)/,
  'Quick Stack must ship one settings surface owned by its own runtime');
assert.match(main, /local SETTINGS_HOST_PROTOCOL_VERSION = 3\b/,
  'settings hosting must be versioned independently from the legacy value bridge');
assert.match(main,
  /local SETTINGS_HOST_PREFIX = "PalInsightSettingsHost\."/,
  'host coordination must use its private shared-variable namespace');
for (const field of [
  'QuickStackGeneration', 'QuickStackHeartbeat', 'QuickStackLivenessRevision',
]) {
  assert.ok(main.includes(`"${field}"`),
    `Quick Stack capability must publish ${field}`);
}

assert.match(main,
  /local function livePalInsightRuntime\([\s\S]*HostHeartbeat[\s\S]*local function livePalInsightF6Owner\([\s\S]*F6Owner[\s\S]*F6OwnerGeneration/,
  'F6 ownership must use the Pal Insight runtime lease rather than transient host UI readiness');
assert.match(main,
  /local function toggleSettingsForCurrentRuntime\([\s\S]*livePalInsightF6Owner\([\s\S]*SettingsUI\.mode\(\) == "standalone"[\s\S]*SettingsUI\.close\("host-takeover"\)[\s\S]*return true, nil[\s\S]*SettingsUI\.toggle\("standalone"/,
  'F6 must yield to a live Pal Insight F6 owner or toggle the same standalone panel');
assert.doesNotMatch(palInsightRuntimePresence, /HostReady/,
  'Pal Insight runtime presence must not depend on an actor-backed HostReady value');
assert.match(main,
  /runtimeIsSuperseded\(\)[\s\S]*requestCurrentQuickStackToggle\([\s\S]*QuickStackToggleRequestTargetGeneration[\s\S]*targetGeneration == state\.settingsHostGeneration[\s\S]*toggleSettingsForCurrentRuntime\(/,
  'a retained process-level F6 owner must forward to the newest hot-reloaded runtime');
assert.match(main,
  /local function registerSettingsShortcut\([\s\S]*IsKeyBindRegistered[\s\S]*RegisterKeyBind[\s\S]*F6Owner/,
  'Quick Stack must claim F6 only when the physical chord is free');
assert.match(main,
  /settingsHostWrite\("F6BehaviorVersion", 2\)[\s\S]*if not livePalInsightF6Owner\(\) then[\s\S]*settingsHostWrite\("F6Owner", "QuickStack"\)/,
  'the cooperative callback must advertise itself without overwriting a live Pal Insight owner');
assert.match(main,
  /publishHostedOpenAcknowledgement[\s\S]*ExtensionSettingsOpenedRevision[\s\S]*OpenExtensionSettingsRequestRevision[\s\S]*SettingsUI\.open\("hosted"[\s\S]*publishHostedOpenAcknowledgement/,
  'a hosted request must acknowledge only after the canonical panel opens');
assert.match(main,
  /OpenExtensionSettingsInputDevice[\s\S]*initialInputDevice\s*=\s*requestInputDevice/,
  'a hosted request must preserve the input device that opened the extension');
assert.match(main,
  /OpenExtensionSettingsInputRoute[\s\S]*requestInputRoute[\s\S]*host-native[\s\S]*extension-cooked[\s\S]*hostedInputRoute\s*=\s*requestInputRoute/,
  'a hosted request must select one explicit controller route and pass it to the child surface');
assert.match(main,
  /OpenExtensionSettingsHostGeneration[\s\S]*OpenExtensionSettingsTargetGeneration[\s\S]*requestTargetGeneration ~= state\.settingsHostGeneration/,
  'hosted requests must be scoped to both live runtime generations');
assert.match(main,
  /ExtensionSettingsAckHostGeneration[\s\S]*ExtensionSettingsAckQuickStackGeneration[\s\S]*ExtensionSettingsAckInputRoute/,
  'hosted acknowledgements must identify both live runtime generations and the accepted input route');
assert.match(main,
  /publishHostedOpenAcknowledgement[\s\S]*if not acknowledged then[\s\S]*SettingsUI\.close\("host-open-ack-failed"\)/,
  'a failed hosted-open acknowledgement must roll the child surface back instead of leaving split ownership');
assert.match(main,
  /pendingSettingsHostCloseAck[\s\S]*publishPendingHostedCloseAcknowledgement[\s\S]*reconcileSettingsHostRequests/,
  'a locally closed hosted surface must retain and retry its close acknowledgement');
assert.match(main,
  /CloseExtensionSettingsRequestRevision[\s\S]*SettingsUI\.close\("host-request"/,
  'the host must be able to close the extension-owned panel');
assert.match(main,
  /SettingsUI\.mode\(\) == "hosted"[\s\S]*hostGeneration ~= state\.settingsHostPanelHostGeneration[\s\S]*SettingsUI\.close\("host-unavailable"\)/,
  'a hosted panel must release itself when its Pal Insight generation disappears');
for (const field of [
  'ExtensionSettingsClosedRevision',
  'ExtensionSettingsFailureRevision',
  'ExtensionSettingsFailureCode',
]) {
  assert.ok(main.includes(`"${field}"`),
    `hosted close and failure outcomes must publish ${field}`);
}

assert.match(settingsUi,
  /function SettingsUI\.open\(mode,[\s\S]*mode == "hosted"[\s\S]*buildSettingsWindow/,
  'standalone and hosted entry points must build one canonical surface');
assert.match(settingsUi,
  /hostedInputRoute[\s\S]*useCookedBridge = mode ~= "hosted"\s*or hostedInputRoute == "extension-cooked"/,
  'hosted input acquisition must mount a cooked bridge only for the transferred cooked route');
assert.match(bridgeAcquire,
  /useCookedBridge[\s\S]*cookedAvailable = useCookedBridge and Bridge\.prepare\(\)[\s\S]*if cookedAvailable then[\s\S]*setCookedBridgeActive\(bridge, true\)/,
  'the modal bridge must not register a second cooked blocker for a host-native route');
assert.match(bridge,
  /nativeActionLastEventAt[\s\S]*globalMouseFallbackAt/,
  'the mouse arbitration state must retain native and fallback liveness');
assert.match(bridge,
  /drainKeyboardQueue[\s\S]*nativeRecent[\s\S]*globalMouseFallbackAt/,
  'the global mouse path must fall back when no live native event arrived');
assert.match(bridge,
  /clickedHook[\s\S]*nativeActionLastEventAt[\s\S]*globalMouseFallbackGeneration/,
  'native mouse delegates and the global fallback must use event liveness plus bounded deduplication');
assert.match(settingsUi,
  /pollLastTickAt[\s\S]*function SettingsUI\.ensurePollAlive\(\)[\s\S]*schedulePoll\(\)/,
  'the settings control loop must expose an independent liveness recovery entry point');
assert.match(main,
  /SettingsUI\.mode\(\) ~= nil[\s\S]*SettingsUI\.ensurePollAlive\(\)/,
  'the independent integration loop must recover a dead open-settings poll');
assert.match(settingsUi,
  /mode == "hosted"[\s\S]*strings\.footerHosted[\s\S]*strings\.footer/,
  'the hosted surface must explain its distinct Escape\/Back and F6 behavior');
assert.match(settingsUi,
  /ResultDisplay[\s\S]*IncludeExcludedItems[\s\S]*IncludeNewItems[\s\S]*PalEggRouting[\s\S]*RelicRouting[\s\S]*WorldTreeHolyWaterMinimum/,
  'the canonical surface must expose every Quick Stack setting');
assert.match(settingsUi,
  /local function styleToggle\(toggle\)[\s\S]*UncheckedImage[\s\S]*CheckedImage[\s\S]*local function addToggleRow[\s\S]*styleToggle\(toggle\)/,
  'standalone toggles must remain visible against the dark settings surface');
assert.match(settingsUi,
  /Settings\.validateShortcut[\s\S]*Settings\.save/,
  'Quick Stack must retain validation and persistence ownership');
assert.doesNotMatch(settingsUi, /SetIsSelectingKey/,
  'shortcut cancellation must not call an unavailable reflected setter');
assert.match(bridge,
  /BRIDGE_DEFAULT_PATH[\s\S]*function Bridge\.bindActionButtons\(buttons\)[\s\S]*delegateBridge\(\)[\s\S]*OnClicked:Add\([\s\S]*bridge, "PalInsightSearchClearClicked"\)[\s\S]*function Bridge\.nativeActionDelegatesReady\(\)/,
  'every direct settings Button must bind to the stable cooked default object');
assert.match(bridge,
  /local function actionDelegatesReady\(\)[\s\S]*actionDelegateBridgeAddress[\s\S]*actionDelegateExpectedCount[\s\S]*function Bridge\.nativeActionDelegatesReady\(\)[\s\S]*state\.active == true and actionDelegatesReady\(\)/,
  'native click ownership must validate the stable owner and every cached Button');
assert.match(bridge,
  /name = "LeftMouseButton", value = Key\.LEFT_MOUSE_BUTTON/,
  'the modal input owner must register the standalone mouse fallback');
assert.match(bridge,
  /item\.keyName == "LeftMouseButton"[\s\S]*nativeActionDelegatesReady\(\)[\s\S]*dispatchEvent\("onClicked", "mouse", "global"\)/,
  'standalone settings must retain one mouse fallback that is disabled by native delegates');
assert.match(bridge,
  /BRIDGE_TOGGLE_CHANGED_FUNCTION[\s\S]*toggleChangedHook[\s\S]*toggleDelegateBridgeAddress[\s\S]*function Bridge\.bindToggleControls\(controls\)[\s\S]*delegateBridge\(\)[\s\S]*OnCheckStateChanged:Add\([\s\S]*bridge, "PalInsightSettingsToggleChanged"\)/,
  'native CheckBox changes must use the stable cooked typed delegate used by Pal Insight');
assert.match(settingsUi,
  /local function activateHoveredDirectAction\(\)[\s\S]*onClicked = function\(\) activateHoveredDirectAction\(\) end[\s\S]*InputOwner\.bindActionButtons\(state\.directActionButtons\)/,
  'the settings surface must route both native and fallback clicks through one hovered action owner');
assert.match(settingsUi,
  /local function hoveredRootPointerControl\(\)[\s\S]*isRootSettingControl\(control\)[\s\S]*pointerControlHovered\(control\)[\s\S]*return control[\s\S]*hoveredWidget\(control\.rowFrame\)[\s\S]*return control/,
  'a root settings click must prefer the exact control and then fall back to its row surface');
assert.match(settingsUi,
  /local function promoteHoveredRootSelection\(\)[\s\S]*state\.focusIndex = control\.focusIndex[\s\S]*local function activateHoveredDirectAction\(\)[\s\S]*local selectionHandled = promoteHoveredRootSelection\(\)[\s\S]*if not pointerActionIsCurrent\(action\) then[\s\S]*return selectionHandled/,
  'a row-only click must update the shared navigation origin without requiring a control action');
assert.match(settingsUi,
  /action\.scope == "root"[\s\S]*local control = action\.owner[\s\S]*state\.focusIndex = control\.focusIndex[\s\S]*local returnFocusIndex = state\.focusIndex/,
  'a direct pointer action must promote its root setting before activation');
assert.match(settingsUi,
  /local function commitNativeToggleChanges\(source\)[\s\S]*FooterGuide\.markInputDevice\("mouse"\)[\s\S]*state\.focusIndex = control\.focusIndex[\s\S]*commitToggle\(control/,
  'a native pointer Toggle change must become the next keyboard/controller navigation origin');
assert.match(settingsUi,
  /if selecting and not wasSelecting then[\s\S]*state\.lastInputDevice == "mouse"[\s\S]*state\.focusIndex = control\.focusIndex[\s\S]*control\.pointerReturnFocusIndex = control\.focusIndex/,
  'a mouse-opened Shortcut capture must restore and continue from the clicked row');
assert.match(settingsUi,
  /local function commitNativeToggleChanges\(source\)[\s\S]*control\.kind == "toggle"[\s\S]*commitToggle\(control, source[\s\S]*onToggleChanged = function\(\)[\s\S]*commitNativeToggleChanges\("toggle-native"\)[\s\S]*InputOwner\.bindToggleControls\(state\.controls\)/,
  'native CheckBox changes must commit immediately with polling retained as an idempotent fallback');
assert.match(settingsUi,
  /local function commitToggle\(control, source\)[\s\S]*value == control\.last[\s\S]*applyControlPatch\([\s\S]*SetIsChecked\(previous\)[\s\S]*local function activateToggle\(control, source\)[\s\S]*SetIsChecked\(target\)[\s\S]*commitToggle\(control/,
  'toggle observation and explicit keyboard/controller activation must remain separate');
assert.doesNotMatch(bridgeRelease,
  /unbindActionButtons\(\)|unbindToggleControls\(\)/,
  'closing a cached panel must preserve stable native delegates');
assert.match(settingsUi,
  /local function clearWindowReferences\(\)[\s\S]*InputOwner\.unbindActionButtons\(\)[\s\S]*InputOwner\.unbindToggleControls\(\)/,
  'destroying the cached settings tree must unbind its stable native delegates');
assert.match(settingsUi,
  /local function activateHoveredDirectAction\(\)[\s\S]*control\.kind == "choice"[\s\S]*openChoiceModal\(control\)/,
  'choice Buttons must open their selector through an explicit mouse action route');
assert.match(settingsUi,
  /state\.activeChoice ~= nil[\s\S]*hoveredWidget\(option\.widget\)[\s\S]*commitNestedModalSelection\("mouse"\)/,
  'choice options must commit through their own hovered Button instead of virtual focus');
assert.equal((settingsUi.match(
  /^\s*registerDirectActionButton\((?:surface|button|displayButton)\)/gm) || []).length, 6,
  'every direct Button constructor must publish its native action surface');
assert.match(settingsUi,
  /addNumberRow\([\s\S]*construct\(tree, "\/Script\/UMG\.EditableTextBox"\)[\s\S]*displayButton\.bIsFocusable = false[\s\S]*input:SetIsReadOnly\(false\)[\s\S]*input\.SelectAllTextWhenFocused = true/,
  'Quick Stack must use the same layered writable number editor as Pal Insight 1.8.0');
assert.match(settingsUi,
  /ensureChoiceModal = function\(\)[\s\S]*buildChoiceModal[\s\S]*InputOwner\.bindActionButtons\(state\.directActionButtons\)/,
  'lazily built choice and reset buttons must join the active native delegate owner');
assert.match(settingsUi,
  /ensureAboutModal = function\(\)[\s\S]*buildAboutModal[\s\S]*InputOwner\.bindActionButtons\(state\.directActionButtons\)/,
  'lazily built About buttons must join the active native delegate owner');
assert.doesNotMatch(settingsUi, /OnPreviewMouseButtonDown/,
  'the failed root Preview mouse adapter must not compete with Button OnClicked');
assert.match(settingsUi,
  /refreshShortcutConflictWarning = function\(\)[\s\S]*Key = state\.config\.Key[\s\S]*Shift = state\.config\.Shift[\s\S]*Ctrl = state\.config\.Ctrl[\s\S]*Alt = state\.config\.Alt/,
  'shortcut conflict warnings must describe only the committed configuration');
assert.doesNotMatch(shortcutWarning, /selectedChord\(control\.widget\)/,
  'a transient InputKeySelector mouse capture must never drive the conflict warning');
assert.match(settingsUi,
  /local function focusNumberEditorInput\(control\)[\s\S]*control\.input:SetUserFocus[\s\S]*control\.input:SetKeyboardFocus\(\)[\s\S]*beginNumberEditor = function\(control, mode\)[\s\S]*replaceOnType = mode == "keyboard"[\s\S]*if mode == "mouse" then[\s\S]*focusNumberEditorInput\(control\)[\s\S]*focusNavigationRoot\(\)/,
  'mouse editing must own the native text focus while keyboard and controller retain root focus');
const navigationRootFocus = settingsUi.match(
  /local function focusNavigationRoot\(\)[\s\S]*?\nend\n\ndo/);
assert.ok(navigationRootFocus,
  'navigation-root focus helper must remain independently auditable');
assert.doesNotMatch(navigationRootFocus[0], /:HasKeyboardFocus\(/,
  'root focus acquisition must not reject a request before Slate applies it');
const numberEditorFocus = settingsUi.match(
  /local function focusNumberEditorInput\(control\)[\s\S]*?\nend\n\nlocal function focusEntry/);
assert.ok(numberEditorFocus,
  'mouse number editor focus helper must remain independently auditable');
assert.doesNotMatch(numberEditorFocus[0], /:HasKeyboardFocus\(/,
  'mouse editing must not reject Slate focus before the pointer event has returned');
assert.match(settingsUi,
  /local function nativeNumberEditKeyAllowed\(control, keyName, controlDown, shiftDown\)[\s\S]*NUMBER_NATIVE_EDIT_KEYS\[keyName\][\s\S]*handleNumberPreview = function[\s\S]*edit\.mode == "mouse"[\s\S]*source ~= "preview"/,
  'mouse input must let only the 1.8.0 numeric key allowlist reach Slate');
assert.match(settingsUi,
  /edit\.mode == "controller"[\s\S]*commitNumberEditor\(edit\.control, "number-pointer"/,
  'switching from controller editing to pointer ownership must finish the controller transaction');
assert.match(settingsUi,
  /local function applyControlPatch\(patch, source\)[\s\S]*candidate\[key\] = value[\s\S]*local function commitChoice[\s\S]*\[control\.key\] = control\.values\[index\][\s\S]*local function commitToggle[\s\S]*\[control\.key\] = value/,
  'each settings primitive must commit only its own persisted field');
assert.doesNotMatch(settingsUi, /applyFromControls/,
  'one control must never validate transient state from every other control');
assert.match(settingsUi,
  /local reserved = chord\.Key == "F6"[\s\S]*chord\.Key == "LeftMouseButton"[\s\S]*setSelectorChord\(control\.widget, persisted\)[\s\S]*scheduleShortcutFocusRestore\(control\)/,
  'reserved shortcut captures must restore persisted state before releasing focus');
assert.match(settingsUi,
  /local function installSelectorSelectedKeyHook\(\)[\s\S]*InputKeySelector:SetSelectedKey[\s\S]*local function pollControls\(\)[\s\S]*control\.kind == "shortcut"[\s\S]*selectedChord\(control\.widget\)/,
  'the shortcut selector must retain its native capture hook and idempotent poll fallback');
for (const kind of ['choice', 'toggle', 'number', 'shortcut', 'steamVote', 'about', 'reset', 'close']) {
  assert.ok(settingsUi.includes(`control.kind == "${kind}"`),
    `the shared activation owner is missing ${kind}`);
}
assert.match(settingsUi,
  /shield:SetVisibility\(VIS_VISIBLE\)[\s\S]*shield:SetIsEnabled\(true\)[\s\S]*root:AddChild\(shield\)[\s\S]*Minimum = \{ X = 0\.0, Y = 0\.0 \}[\s\S]*Maximum = \{ X = 1\.0, Y = 1\.0 \}[\s\S]*shieldSlot:SetZOrder\(0\)/,
  'the settings surface must keep a full-viewport pointer shield below the card');
assert.match(bridge,
  /modalUIOnly[\s\S]*SetInputMode_UIOnlyEx\(controller, ownerWidget/,
  'settings acquisition must use UIOnly instead of allowing gameplay input');
assert.match(bridge,
  /keyboardBindingCallbacks = \{\}[\s\S]*state\.keyboardBindingCallbacks\[name\] = callback/,
  'process-lifetime navigation fallbacks must keep their Lua callbacks strongly reachable');
assert.match(bridge,
  /function Bridge\.release\(options\)[\s\S]*setCookedBridgeActive\(bridge, false\)[\s\S]*releaseInputIsolation\(\)[\s\S]*restoreInputContext[\s\S]*modal rollback/,
  'close must retain and roll back the visible modal transaction when restoration fails');
assert.match(bridgeAcquire,
  /if exclusiveController and not hostedParent then[\s\S]*NativeSettingsInput\.acquire\(\)/,
  'standalone exclusive-controller mode must acquire the native process filter even when the cooked bridge exists');
assert.doesNotMatch(bridgeAcquire,
  /exclusiveController and not hostedParent and not cookedAvailable/,
  'cooked bridge availability must not disable standalone process-level controller isolation');
assert.match(bridgeEmergencyRelease,
  /local cookedReleased[\s\S]*local isolationReleased[\s\S]*if not cookedReleased or not isolationReleased then[\s\S]*return false[\s\S]*local restored[\s\S]*if not restored then[\s\S]*return false[\s\S]*local nativeReleased[\s\S]*if not nativeReleased then[\s\S]*return false[\s\S]*clearModalOwnership\(\)/,
  'the watchdog may clear ownership only after every release stage is verified');
assert.doesNotMatch(bridgeEmergencyRelease,
  /SetIgnoreMoveInput\(false\)|SetIgnoreLookInput\(false\)/,
  'the watchdog must not decrement the counted movement/look lease a second time');
assert.match(settingsUi,
  /InputOwner\.emergencyRelease[\s\S]*else[\s\S]*closeRecoveryDeadline = now \+ 0\.5[\s\S]*closeRecoveryRetryAt = now \+ 0\.25/,
  'a failed watchdog release must back off and retain the visible recovery transaction');
assert.match(settingsUi,
  /function SettingsUI\.prepare\(\)[\s\S]*prepareForController[\s\S]*buildSettingsWindow/,
  'the existing reconciliation cadence must prewarm both the tree and cooked bridge');
assert.match(settingsUi,
  /function SettingsUI\.open\(mode,[\s\S]*windowCacheMatches[\s\S]*reuseWindow[\s\S]*prepareWindowForOpen/,
  'warm opens must reuse the already-mounted settings tree');
assert.match(settingsUi,
  /Gamepad_FaceButton_Right[\s\S]*SettingsUI\.close\("gamepad-back"\)/,
  'the open-only settings poll must map controller Back to one panel close');
assert.match(main,
  /ExtensionControllerEdgeRevision[\s\S]*ExtensionControllerPressedEdges[\s\S]*ExtensionControllerReleasedEdges[\s\S]*ExtensionControllerRevision[\s\S]*ackHostedControllerSnapshot/,
  'the hosted snapshot boundary must read committed edge latches and expose acknowledgement');
assert.match(settingsUi,
  /lastHostedControllerEdgeRevision[\s\S]*pressedEdges[\s\S]*releasedEdges[\s\S]*ackHostedControllerSnapshot/,
  'the settings owner must consume each latched button edge exactly once before acknowledging it');
assert.match(settingsUi,
  /state\.navigationDirection = function\(keyName\)[\s\S]*Gamepad_DPad_Left[\s\S]*return "x", -1[\s\S]*local function startNavigationRepeat[\s\S]*axis = axis[\s\S]*record\.axis[\s\S]*pollNavigationRepeat/,
  'D-pad horizontal navigation must share the same retained repeat transaction as vertical navigation');
assert.match(settingsUi,
  /initialInputDevice[\s\S]*focusEntry\(1, initialInputDevice, true\)/,
  'the first visible selection and footer must use the opening input device without a keyboard flash');
assert.match(settingsUi,
  /control\.kind == "shortcut"[\s\S]*sourceName:find\("\^gamepad"\)[\s\S]*shortcutKeyboardMouseOnly/,
  'controller activation of the keyboard-only shortcut row must remain explicit and recoverable');
assert.match(main, /registerConfiguredKey\([\s\S]*dispatchConfiguredPress\(/,
  'the existing F5 gameplay action must remain independent of F6 settings');
assert.doesNotMatch(source,
  /LoopInGameThreadWithDelay\([^\n]*settingsHost|ExecuteWithDelay\([^\n]*settingsHost/,
  'host routing must reuse the existing shared reconciliation cadence');

console.log('Quick Stack settings host routing contract: ok');
