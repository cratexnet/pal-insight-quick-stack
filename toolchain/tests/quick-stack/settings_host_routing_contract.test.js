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
assert.match(main, /local SETTINGS_HOST_PROTOCOL_VERSION = 2\b/,
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
  /OpenExtensionSettingsRequestRevision[\s\S]*SettingsUI\.open\("hosted"[\s\S]*ExtensionSettingsOpenedRevision/,
  'a hosted request must acknowledge only after the canonical panel opens');
assert.match(main,
  /OpenExtensionSettingsInputDevice[\s\S]*initialInputDevice\s*=\s*requestInputDevice/,
  'a hosted request must preserve the input device that opened the extension');
assert.match(main,
  /OpenExtensionSettingsHostGeneration[\s\S]*OpenExtensionSettingsTargetGeneration[\s\S]*requestTargetGeneration ~= state\.settingsHostGeneration/,
  'hosted requests must be scoped to both live runtime generations');
assert.match(main,
  /ExtensionSettingsAckHostGeneration[\s\S]*ExtensionSettingsAckQuickStackGeneration/,
  'hosted acknowledgements must identify both live runtime generations');
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
assert.doesNotMatch(settingsUi,
  /construct\(tree, "\/Script\/UMG\.EditableTextBox"\)/,
  'integer settings must never transfer focus to Slate text input or the desktop IME');
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
  /beginNumberEditor = function\(control, mode\)[\s\S]*buffer = tostring\(control\.value\)[\s\S]*focusNavigationRoot\(\)[\s\S]*handleNumberPreview = function/,
  'mouse activation and keyboard/controller editing must share one root-owned bounded buffer');
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
