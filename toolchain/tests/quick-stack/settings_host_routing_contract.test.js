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

assert.match(main, /local SettingsUI = require\("settings_ui"\)/,
  'Quick Stack must ship one settings surface owned by its own runtime');
assert.match(main, /local SETTINGS_HOST_PROTOCOL_VERSION = 1\b/,
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
  /local function toggleSettingsForCurrentRuntime\([\s\S]*livePalInsightHost\([\s\S]*SettingsUI\.mode\(\) == "standalone"[\s\S]*SettingsUI\.close\("host-takeover"\)[\s\S]*return true, nil[\s\S]*SettingsUI\.toggle\("standalone"/,
  'F6 must yield to a live Pal Insight owner or toggle the same standalone panel');
assert.match(main,
  /runtimeIsSuperseded\(\)[\s\S]*requestCurrentQuickStackToggle\([\s\S]*QuickStackToggleRequestTargetGeneration[\s\S]*targetGeneration == state\.settingsHostGeneration[\s\S]*toggleSettingsForCurrentRuntime\(/,
  'a retained process-level F6 owner must forward to the newest hot-reloaded runtime');
assert.match(main,
  /local function registerSettingsShortcut\([\s\S]*IsKeyBindRegistered[\s\S]*RegisterKeyBind[\s\S]*F6Owner/,
  'Quick Stack must claim F6 only when the physical chord is free');
assert.match(main,
  /OpenExtensionSettingsRequestRevision[\s\S]*SettingsUI\.open\("hosted"[\s\S]*ExtensionSettingsOpenedRevision/,
  'a hosted request must acknowledge only after the canonical panel opens');
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
assert.doesNotMatch(settingsUi, /EditableTextBox/,
  'integer settings must never transfer focus to Slate text input or the desktop IME');
assert.match(settingsUi,
  /state\.numberEdit\s*=\s*\{[\s\S]*buffer = tostring\(control\.value\)[\s\S]*handleNumberPreview/,
  'integer editing must remain a root-owned bounded buffer');
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
assert.match(settingsUi,
  /function SettingsUI\.prepare\(\)[\s\S]*prepareForController[\s\S]*buildSettingsWindow/,
  'the existing reconciliation cadence must prewarm both the tree and cooked bridge');
assert.match(settingsUi,
  /function SettingsUI\.open\(mode,[\s\S]*windowCacheMatches[\s\S]*reuseWindow[\s\S]*prepareWindowForOpen/,
  'warm opens must reuse the already-mounted settings tree');
assert.match(settingsUi,
  /Gamepad_FaceButton_Right[\s\S]*SettingsUI\.close\("gamepad-back"\)/,
  'the open-only settings poll must map controller Back to one panel close');
assert.match(main, /registerConfiguredKey\([\s\S]*dispatchConfiguredPress\(/,
  'the existing F5 gameplay action must remain independent of F6 settings');
assert.doesNotMatch(source,
  /LoopInGameThreadWithDelay\([^\n]*settingsHost|ExecuteWithDelay\([^\n]*settingsHost/,
  'host routing must reuse the existing shared reconciliation cadence');

console.log('Quick Stack settings host routing contract: ok');
