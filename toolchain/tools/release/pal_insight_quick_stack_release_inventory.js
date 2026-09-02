'use strict';

const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const PACKAGE_NAME = 'PalInsightQuickStack';
const PORTABLE_RUNTIME_ROOT =
  `Pal/Binaries/Win64/ue4ss/Mods/${PACKAGE_NAME}`;
const RELEASE_CHANNELS = Object.freeze(['nexus', 'curseforge', 'workshop']);
const SUPPORTED_LOCALES = Object.freeze([
  'en', 'zh-hans', 'zh-hant', 'ja', 'ko', 'de', 'fr', 'it', 'es',
  'pt-br', 'ru', 'tr', 'pl', 'id', 'es-419', 'th', 'vi',
]);
const ABOUT_FILES = Object.freeze([
  'assets/about/breeding-calculator-preview.png',
  'assets/about/buy-me-a-coffee.png',
  'assets/about/cratex.png',
  'assets/about/curseforge.png',
  'assets/about/discord.png',
  'assets/about/fluentui-emoji-LICENSE.txt',
  'assets/about/nexus.png',
  'assets/about/pal-insight-preview.jpg',
  'assets/about/quick-stack-preview.png',
  'assets/about/red-heart.png',
  'assets/about/sports-medal.png',
  'assets/about/steam.png',
  'assets/about/unicorn.png',
  'assets/about/x.png',
]);
const RUNTIME_FILES = Object.freeze([
  'Scripts/config.lua',
  'Scripts/localization.lua',
  'Scripts/main.lua',
  'Scripts/native_settings_input.lua',
  'Scripts/notifications.lua',
  'Scripts/pal_insight_bridge.lua',
  'Scripts/palworld.lua',
  'Scripts/quick_stack.lua',
  'Scripts/settings.lua',
  'Scripts/settings_ui.lua',
  'Scripts/steam_vote.lua',
  ...ABOUT_FILES,
  'enabled.txt',
]);
const COMMON_NATIVE_FILES = Object.freeze([
  {
    source: 'native/settings_input/bin/PalInsightQuickStackSettingsInput.dll',
    target: 'Scripts/PalInsightQuickStackSettingsInput.dll',
  },
]);
const WORKSHOP_ONLY_FILES = Object.freeze([
  {
    source: 'native/steam_vote/bin/PalInsightQuickStackSteamVote.dll',
    target: 'Scripts/PalInsightQuickStackSteamVote.dll',
  },
  ...[
    'thumb-up-outline.png', 'thumb-up-filled.png', 'thumb-down-filled.png',
  ].map((name) => ({
    source: `assets/steam-workshop-feedback/${name}`,
    target: `assets/steam-workshop-feedback/${name}`,
  })),
]);
const WORKSHOP_FEEDBACK_SHA256 = Object.freeze({
  'thumb-down-filled.png':
    '3a44ad63f1ab98ff0644e72052338620a9e3688fadf8d2922613b23c69f7bd48',
  'thumb-up-filled.png':
    '4f23ca4dd9fcc0008370219656599a573fa76979572be686517bc512d6d1297e',
  'thumb-up-outline.png':
    'fcf5a99286067eb2c9fee797e21c09c9ea783a403998e713a480a4c60b41a932',
});
const PUBLIC_DOCUMENTS = Object.freeze([
  'CHANGELOG.md',
  'CREDITS.md',
  'LICENSE.md',
  'README.md',
]);
const RELEASE_METADATA = 'packaging/release.json';
const WORKSHOP_INFO = 'packaging/workshop/Info.json';
const WORKSHOP_THUMBNAIL = 'packaging/workshop/thumbnail.png';

function portable(relative) {
  return String(relative).split(path.sep).join('/').replace(/^\.\//, '');
}

function absolute(root, relative) {
  return path.join(root, ...portable(relative).split('/'));
}

function assertFilesExist(root, files, label) {
  const missing = files.filter((relative) => !fs.existsSync(absolute(root, relative)));
  assert.deepEqual(missing, [], `${label} is missing: ${missing.join(', ')}`);
}

function readJson(root, relative) {
  return JSON.parse(fs.readFileSync(absolute(root, relative), 'utf8'));
}

function readRuntimeVersion(root) {
  const source = fs.readFileSync(absolute(root, 'Scripts/main.lua'), 'utf8');
  const match = source.match(/\blocal\s+VERSION\s*=\s*["']([^"']+)["']/);
  assert.ok(match, 'Scripts/main.lua has no local VERSION declaration');
  return match[1];
}

function assertReleaseVersion(version) {
  assert.match(version, /^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/,
    `runtime version is not SemVer-compatible: ${version}`);
  assert.ok(!/(?:^|[.-])dev(?:$|[.-])/i.test(version),
    `development version cannot be released: ${version}`);
}

function assertFalseAssignment(source, name, relative) {
  const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const assignment = new RegExp(`^[ \\t]*(?:${escaped})\\s*=\\s*(true|false)\\b`, 'gm');
  const values = [...source.matchAll(assignment)].map((match) => match[1]);
  assert.ok(values.includes('false'),
    `${relative} must explicitly set ${name} = false`);
  assert.ok(!values.includes('true'),
    `${relative} must not enable ${name} in a release`);
}

function assertReleaseDiagnosticsDisabled(root) {
  for (const relative of ['Scripts/config.lua', 'Scripts/settings.lua']) {
    const source = fs.readFileSync(absolute(root, relative), 'utf8');
    assertFalseAssignment(source, 'PerformanceCapture', relative);
    assertFalseAssignment(source, 'Debug', relative);
  }
}

function assertQuickStackSettings(root) {
  for (const relative of ['Scripts/config.lua', 'Scripts/settings.lua']) {
    const source = fs.readFileSync(absolute(root, relative), 'utf8');
    assert.match(source, /^\s*ResultDisplay\s*=\s*["']Default["']/m,
      `${relative} must default ResultDisplay to Default`);
    assert.match(source, /^\s*IncludeExcludedItems\s*=\s*false\b/m,
      `${relative} must default IncludeExcludedItems to false`);
    assert.match(source, /^\s*IncludeNewItems\s*=\s*true\b/m,
      `${relative} must default IncludeNewItems to true`);
    assert.match(source,
      /^\s*PalEggRouting\s*=\s*["']IncubatorOnly["']/m,
      `${relative} must default PalEggRouting to IncubatorOnly`);
    assert.match(source,
      /^\s*RelicRouting\s*=\s*["']RecyclerOnly["']/m,
      `${relative} must default RelicRouting to RecyclerOnly`);
  }
  const main = fs.readFileSync(absolute(root, 'Scripts/main.lua'), 'utf8');
  assert.match(main, /local SettingsUI = require\("settings_ui"\)/,
    'Quick Stack must ship its canonical settings surface');
  assert.match(main, /local SETTINGS_HOST_PROTOCOL_VERSION = 2\b/,
    'settings hosting must use the accepted private protocol version');
  for (const field of [
    'QuickStackGeneration', 'QuickStackHeartbeat',
    'OpenExtensionSettingsHostGeneration',
    'OpenExtensionSettingsTargetGeneration',
    'OpenExtensionSettingsInputDevice',
    'CloseExtensionSettingsHostGeneration',
    'CloseExtensionSettingsTargetGeneration',
    'ExtensionSettingsAckHostGeneration',
    'ExtensionSettingsAckQuickStackGeneration',
    'ExtensionControllerEdgeRevision',
    'ExtensionControllerPressedEdges',
    'ExtensionControllerReleasedEdges',
    'ExtensionControllerEdgeAckRevision',
    'HostSettingsOpen',
    'HostRequestSignalRevision',
  ]) {
    assert.ok(main.includes(`"${field}"`),
      `settings host contract is missing ${field}`);
  }
  assert.match(main,
    /local function livePalInsightRuntime\([\s\S]*HostHeartbeat[\s\S]*local function livePalInsightF6Owner\([\s\S]*F6OwnerGeneration/,
    'F6 ownership must follow the Pal Insight runtime lease, not transient UI readiness');
  assert.match(main,
    /settingsHostWrite\("F6BehaviorVersion", 2\)[\s\S]*if not livePalInsightF6Owner\(\) then[\s\S]*settingsHostWrite\("F6Owner", "QuickStack"\)/,
    'Quick Stack must not overwrite a live Pal Insight F6 owner');
  assert.match(main, /local\s+SHARED_API_VERSION\s*=\s*3\b/,
    'shared settings contract must use API version 3');
  for (const setting of ['IncludeExcludedItems', 'IncludeNewItems']) {
    assert.match(main, new RegExp(
      `\\{ shared = "${setting}", config = "${setting}" \\}`),
    `shared settings must publish and reconcile ${setting}`);
  }
  assert.match(main,
    /\{ shared = "ResultDisplay", config = "ResultDisplay",\s*validate = Settings\.validateResultDisplay \}/,
    'shared settings must publish and reconcile validated ResultDisplay');
  assert.match(main,
    /\{ shared = "PalEggRouting", config = "PalEggRouting",\s*validate = Settings\.validatePalEggRouting \}/,
    'shared settings must publish and reconcile validated PalEggRouting');
  assert.match(main,
    /\{ shared = "RelicRouting", config = "RelicRouting",\s*validate = Settings\.validateRelicRouting \}/,
    'shared settings must publish and reconcile validated RelicRouting');
  assert.match(main,
    /shared = "WorldTreeHolyWaterMinimum",\s*config = "WorldTreeHolyWaterMinimum",\s*validate = Settings\.validateWorldTreeHolyWaterMinimum/,
    'shared settings must publish and reconcile the validated Holy Water minimum');
  const quickStack = fs.readFileSync(absolute(root, 'Scripts/quick_stack.lua'), 'utf8');
  assert.match(quickStack, /identity\.config\.ResultDisplay\s*==\s*"Default"/,
    'detailed result display must honor ResultDisplay');
  assert.match(quickStack, /identity\.config\.ResultDisplay\s*==\s*"ResultWindow"/,
    'detailed result display must support ResultWindow');
  assert.match(quickStack, /not\s+job\.config\.IncludeExcludedItems/,
    'ignored-item routing must honor IncludeExcludedItems');
  assert.match(quickStack, /if\s+item\.isEgg\s+then\s+incubators\s*=\s*job\.incubators/,
    'Pal Egg routing must always consider incubators before ordinary storage');
  assert.match(quickStack,
    /job\.config\.PalEggRouting\s*==\s*"IncubatorThenStorage"/,
    'Pal Egg ordinary-storage fallback must honor PalEggRouting');
  assert.match(quickStack,
    /job\.config\.RelicRouting\s*==\s*"RecyclerThenStorage"/,
    'relic ordinary-storage fallback must honor RelicRouting');
  assert.match(quickStack,
    /isEgg\s+and\s+job\.config\.PalEggRouting\s*==\s*"ManualPlacement"/,
    'manual Pal Egg routing must skip automatic placement');
  assert.match(quickStack,
    /isRelic[\s\S]*?job\.config\.RelicRouting\s*==\s*"ManualPlacement"/,
    'manual relic routing must skip automatic placement');
  assert.match(quickStack,
    /not\s+job\.config\.IncludeNewItems\s+and\s+not\s+recheck\.entry\.isRecycler\s+and\s+not\s+recheck\.entry\.isRecyclerBoost\s+and\s+not\s+recheck\.containsNeeded/,
    'IncludeNewItems must be rechecked before submission');
  assert.match(quickStack,
    /local\s+recyclers\s*=\s*item\.isRelic\s+and\s+job\.recyclers\s+or\s+\{\}/,
    'compatible relics must always consider current-base recyclers');
  for (let tier = 1; tier <= 5; tier += 1) {
    assert.match(quickStack, new RegExp(
      `WorldTreeRelic_0${tier}\\s*=\\s*true`),
    `current-build relic tier ${tier} must be classified without requiring a live recycler`);
  }
  assert.match(quickStack,
    /kind = "recycler", entries = recyclers[\s\S]*?kind = "normal"/,
    'recycler routing must precede ordinary-storage fallback');
  assert.match(quickStack,
    /local\s+function\s+allocateRecycler[\s\S]*?return\s+allocateNormal/,
    'relic routing must use bounded destination capacity planning');
  const palworld = fs.readFileSync(absolute(root, 'Scripts/palworld.lua'), 'utf8');
  assert.match(palworld, /\/Script\/Pal\.PalMapObjectRecyclerModel/,
    'runtime must identify the Ancient Relic Recycler model');
  assert.match(palworld,
    /entry\.isRecycler[\s\S]*entry\.permission\.itemIds\[item\.id\]\s*==\s*true/,
    'runtime must use each live recycler permission contract instead of guessing by color');
  assert.match(quickStack,
    /candidate\.kind\s*==\s*"storage"\s+or\s+candidate\.kind\s*==\s*"recycler"[\s\S]*P\.readPermission\(candidate\.container\)/,
    'recycler permissions must be decoded from the live dedicated container');
  assert.match(quickStack, /GetRelicItemContainer\(\)/,
    'recycler routing must target its dedicated relic container');
  assert.match(quickStack,
    /WORLD_TREE_HOLY_WATER_ID\s*=\s*"WorldTreeHolyWater"/,
    'Holy Water routing must use the current-build item ID');
  assert.match(quickStack,
    /kind\s*==\s*"recycler_boost"[\s\S]*?concrete\.BoostItemContainer/,
    'Holy Water routing must target the recycler boost container');
  assert.match(quickStack,
    /WorldTreeHolyWaterMinimum\s+-\s+current/,
    'Holy Water allocation must stop at the configured per-recycler minimum');
  assert.match(quickStack,
    /kind\s*=\s*"recycler_boost"[\s\S]*?kind\s*=\s*"normal"/,
    'Holy Water top-up must precede ordinary-storage routing');
  const settings = fs.readFileSync(absolute(root, 'Scripts/settings.lua'), 'utf8');
  assert.match(settings,
    /parsed\.IncludeNewItems\s*=\s*legacyFillByChestFilter/,
  'legacy FillByChestFilter must migrate to IncludeNewItems');
  assert.match(settings,
    /parsed\.PalEggRouting\s*=\s*legacyExcludePalEggs[\s\S]*?"IncubatorOnly"\s+or\s+"IncubatorThenStorage"/,
  'legacy ExcludePalEggs must migrate to PalEggRouting');
  assert.match(settings,
    /RecyclerOnly, RecyclerThenStorage, or ManualPlacement/,
    'writable configuration must document all relic routing values');
  assert.match(settings,
    /WorldTreeHolyWaterMinimum must be an integer from 1 to 100/,
    'writable configuration must validate the Holy Water minimum range');
  const settingsUi = fs.readFileSync(
    absolute(root, 'Scripts/settings_ui.lua'), 'utf8');
  const settingsBridge = fs.readFileSync(
    absolute(root, 'Scripts/pal_insight_bridge.lua'), 'utf8');
  const bridgeRelease = settingsBridge.slice(
    settingsBridge.indexOf('function Bridge.release(options)'),
    settingsBridge.indexOf('\nreturn Bridge'));
  assert.match(settingsUi,
    /function SettingsUI\.open\(mode,[\s\S]*buildSettingsWindow/,
    'standalone and hosted entry points must use one settings surface');
  assert.match(settingsUi,
    /Settings\.validateShortcut[\s\S]*Settings\.save/,
    'Quick Stack must retain validation and persistence ownership');
  assert.doesNotMatch(settingsUi, /SetIsSelectingKey/,
    'settings UI must not call an unavailable selector-state setter');
  assert.match(settingsUi,
    /\{ "IncubatorOnly", "IncubatorThenStorage", "ManualPlacement" \}/,
    'settings UI must expose manual Pal Egg placement as the third choice');
  assert.match(settingsUi,
    /\{ "RecyclerOnly", "RecyclerThenStorage", "ManualPlacement" \}/,
    'settings UI must expose manual relic placement as the third choice');
  const topLevelLocalCount = settingsUi.split(/\r?\n/)
    .filter((line) => /^local\s+/.test(line)).reduce((count, line) => {
      if (/^local\s+function\s+/.test(line)) return count + 1;
      const declaration = line.replace(/^local\s+/, '').split('=')[0];
      return count + declaration.split(',').filter((name) => name.trim()).length;
    }, 0);
  assert.ok(topLevelLocalCount < 190,
    `settings UI has ${topLevelLocalCount} top-level locals; keep headroom below Lua's 200-local limit`);
  for (const action of ['steamVote', 'about', 'reset', 'close']) {
    assert.ok(settingsUi.includes(`kind = "${action}"`),
      `settings Header is missing the ${action} action`);
  }
  assert.match(settingsUi,
    /makeSteamVoteControl[\s\S]*makeIconTrigger\(tree, "ⓘ"[\s\S]*makeIconTrigger\(tree, "↻"[\s\S]*makeIconTrigger\(tree, "×"/,
    'settings Header action order must match Pal Insight');
  assert.match(settingsUi,
    /local function makeIconTrigger[\s\S]*?\/Script\/UMG\.Button[\s\S]*?button\.bIsFocusable = true[\s\S]*?styleHeaderButton[\s\S]*?box:AddChild\(button\)/,
    'settings Header actions must use Pal Insight direct Button controls');
  assert.match(settingsUi,
    /local function makeSteamVoteAction[\s\S]*?\/Script\/UMG\.Button[\s\S]*?button\.bIsFocusable = true[\s\S]*?styleHeaderButton/,
    'Steam voting must use Pal Insight direct Button controls');
  assert.equal((settingsUi.match(/\/Script\/UMG\.CheckBox/g) || []).length, 1,
    'only native toggle rows may construct CheckBox controls');
  assert.equal((settingsUi.match(
    /^\s*registerDirectActionButton\((?:surface|button|displayButton)\)/gm) || []).length, 6,
    'every direct Button constructor must publish its native action surface');
  assert.match(settingsBridge,
    /BRIDGE_DEFAULT_PATH[\s\S]*function Bridge\.bindActionButtons\(buttons\)[\s\S]*delegateBridge\(\)[\s\S]*OnClicked:Add\([\s\S]*bridge, "PalInsightSearchClearClicked"\)[\s\S]*function Bridge\.nativeActionDelegatesReady/,
    'direct Buttons must use the stable Pal Insight native default object');
  assert.match(settingsBridge,
    /local function actionDelegatesReady\(\)[\s\S]*actionDelegateBridgeAddress[\s\S]*actionDelegateExpectedCount[\s\S]*function Bridge\.nativeActionDelegatesReady\(\)[\s\S]*state\.active == true and actionDelegatesReady\(\)/,
    'native click ownership must validate the stable owner and cached Buttons');
  assert.match(settingsBridge,
    /name = "LeftMouseButton", value = Key\.LEFT_MOUSE_BUTTON/,
    'standalone settings must register the process-lifetime mouse fallback');
  assert.match(settingsBridge,
    /item\.keyName == "LeftMouseButton"[\s\S]*nativeActionDelegatesReady\(\)[\s\S]*dispatchEvent\("onClicked", "mouse", "global"\)/,
    'standalone mouse fallback must be disabled whenever native delegates own clicks');
  assert.match(settingsUi,
    /local function activateHoveredDirectAction\(\)[\s\S]*onClicked = function\(\) activateHoveredDirectAction\(\) end[\s\S]*InputOwner\.bindActionButtons\(state\.directActionButtons\)/,
    'native and fallback clicks must share one hovered action executor');
  assert.match(settingsUi,
    /local function activateHoveredDirectAction\(\)[\s\S]*control\.kind == "choice"[\s\S]*openChoiceModal\(control\)/,
    'choice Buttons must open their selector through an explicit mouse action route');
  assert.match(settingsBridge,
    /BRIDGE_TOGGLE_CHANGED_FUNCTION[\s\S]*toggleChangedHook[\s\S]*toggleDelegateBridgeAddress[\s\S]*function Bridge\.bindToggleControls\(controls\)[\s\S]*delegateBridge\(\)[\s\S]*OnCheckStateChanged:Add\([\s\S]*bridge, "PalInsightSettingsToggleChanged"\)/,
    'native CheckBox changes must use the stable Pal Insight typed delegate');
  assert.match(settingsUi,
    /local function commitNativeToggleChanges\(source\)[\s\S]*control\.kind == "toggle"[\s\S]*commitToggle\(control, source[\s\S]*onToggleChanged = function\(\)[\s\S]*commitNativeToggleChanges\("toggle-native"\)[\s\S]*InputOwner\.bindToggleControls\(state\.controls\)/,
    'CheckBox events must commit immediately with an idempotent poll fallback');
  assert.match(settingsUi,
    /local function commitToggle\(control, source\)[\s\S]*value == control\.last[\s\S]*applyControlPatch\([\s\S]*SetIsChecked\(previous\)[\s\S]*local function activateToggle\(control, source\)[\s\S]*SetIsChecked\(target\)[\s\S]*commitToggle\(control/,
    'toggle observation and explicit activation must remain separate');
  assert.doesNotMatch(bridgeRelease,
    /unbindActionButtons\(\)|unbindToggleControls\(\)/,
    'release must preserve stable delegates for the cached settings tree');
  assert.match(settingsUi,
    /local function clearWindowReferences\(\)[\s\S]*InputOwner\.unbindActionButtons\(\)[\s\S]*InputOwner\.unbindToggleControls\(\)/,
    'discarding the cached settings tree must unbind its stable delegates');
  assert.match(settingsUi,
    /ensureChoiceModal = function\(\)[\s\S]*buildChoiceModal[\s\S]*InputOwner\.bindActionButtons\(state\.directActionButtons\)/,
    'lazy choice and reset actions must join the active native click owner');
  assert.match(settingsUi,
    /ensureAboutModal = function\(\)[\s\S]*buildAboutModal[\s\S]*InputOwner\.bindActionButtons\(state\.directActionButtons\)/,
    'lazy About actions must join the active native click owner');
  assert.doesNotMatch(settingsUi, /OnPreviewMouseButtonDown/,
    'the failed root Preview mouse adapter must not compete with Button OnClicked');
  const shortcutWarning = settingsUi.slice(
    settingsUi.indexOf('refreshShortcutConflictWarning = function()'),
    settingsUi.indexOf('local function resetControlsToConfig'));
  assert.match(shortcutWarning, /Key = state\.config\.Key[\s\S]*Alt = state\.config\.Alt/,
    'shortcut warnings must describe the committed configuration');
  assert.doesNotMatch(shortcutWarning, /selectedChord\(/,
    'transient selector captures must not create shortcut conflict warnings');
  assert.doesNotMatch(settingsUi, /thumb:SetColorAndOpacity\(thumbColor\)/,
    'Steam voting must preserve the alpha silhouette of its pre-colored icons');
  for (const [asset, expected] of Object.entries(WORKSHOP_FEEDBACK_SHA256)) {
    const bytes = fs.readFileSync(absolute(root,
      `assets/steam-workshop-feedback/${asset}`));
    const actual = crypto.createHash('sha256').update(bytes).digest('hex');
    assert.equal(actual, expected,
      `Steam voting must use the approved pre-colored ${asset}`);
  }
  assert.match(settingsUi,
    /local function refreshSteamVotePalVisuals[\s\S]*?SetBrushFromTexture[\s\S]*?SetVisibility\(VIS_VISIBLE\)[\s\S]*?function SettingsUI\.prepare\(\)[\s\S]*?refreshSteamVotePalVisuals\(\)/,
    'the Chillet portrait must retry during low-frequency settings preparation');
  assert.match(settingsUi,
    /\/Script\/UMG\.GridPanel[\s\S]*?footerSize:SetHeightOverride\(SIZE\.footer\)[\s\S]*?FooterGuide\.footerHelpSpecs[\s\S]*?FooterGuide\.addGroup/,
    'settings footer must retain Pal Insight fixed-height native input-guide layout');
  for (const keyGuideContract of [
    'KEYBOARD_KEY_GUIDE', 'XINPUT_KEY_GUIDE', 'DUALSENSE_KEY_GUIDE',
    'keyGuideTexturePath', 'makeFooterKeycap', 'refreshFooterHelp',
  ]) {
    assert.ok(settingsUi.includes(keyGuideContract),
      `settings footer is missing ${keyGuideContract}`);
  }
  assert.match(settingsUi,
    /keyGuideTexturePath[\s\S]*?LoadAsset[\s\S]*?SetBrushFromTexture/,
    'settings footer must load Palworld native key-guide textures');
  assert.match(settingsUi,
    /function FooterGuide\.markInputDevice[\s\S]*?FooterGuide\.refreshFooterHelp\(device == "gamepad"\)/,
    'settings footer must refresh when the active input device changes');
  assert.match(settingsUi,
    /if applied then[\s\S]*?FooterGuide\.refreshFooterHelp\((?:true|false)\)/,
    'settings footer must refresh after the Quick Stack shortcut changes');
  for (const urlKey of [
    'website', 'calculator', 'palInsight', 'palInsightWorkshop',
    'palInsightCurseForge', 'quickStackNexus', 'quickStackWorkshop',
    'quickStackCurseForge', 'x', 'discord', 'bmc',
  ]) {
    assert.match(settingsUi, new RegExp(`\\b${urlKey}\\s*=`),
      `Quick Stack About is missing the ${urlKey} destination`);
  }
  assert.match(settingsUi,
    /buildAboutModal\s*=\s*function[\s\S]*?\/Script\/UMG\.ScrollBox[\s\S]*?strings\.aboutSummary[\s\S]*?strings\.aboutProducts[\s\S]*?Pal Insight: Quick Stack[\s\S]*?strings\.aboutCreatorDescription[\s\S]*?strings\.aboutCommunity[\s\S]*?strings\.aboutSupport[\s\S]*?strings\.aboutSupportDescription/,
    'Quick Stack About must contain the product shelf, creator, Community, and Support content');
  assert.match(settingsUi,
    /local function makeAboutAction[\s\S]*?\/Script\/UMG\.Button[\s\S]*?button\.bIsFocusable = true[\s\S]*?box:AddChild\(button\)[\s\S]*?state\.aboutActions/,
    'Quick Stack About actions must use Pal Insight direct Button controls');
  assert.match(settingsUi,
    /local function aboutAssetPath[\s\S]*?assets\/about\/[\s\S]*?local function aboutTexture[\s\S]*?ImportFileAsTexture2D/,
    'Quick Stack About must load its packaged visual assets');
  assert.match(settingsUi,
    /local function makeAboutLogoButton[\s\S]*?\/Script\/UMG\.Button[\s\S]*?\/Script\/UMG\.Image[\s\S]*?SetBrushFromTexture[\s\S]*?button\.bIsFocusable = true[\s\S]*?box:AddChild\(button\)/,
    'Quick Stack About logo actions must retain images inside direct Buttons');
  assert.doesNotMatch(settingsUi,
    /construct\(tree, "\/Script\/UMG\.EditableTextBox"\)/,
    'integer settings must not create a writable Slate or IME text client');
  assert.match(settingsUi,
    /local function addNumberRow\([\s\S]*\/Script\/UMG\.Button[\s\S]*widget = displayButton/,
    'number rows must expose one direct Button as their controlled presentation');
  assert.match(settingsUi,
    /beginNumberEditor = function\(control, mode\)[\s\S]*buffer = tostring\(control\.value\)[\s\S]*focusNavigationRoot\(\)[\s\S]*handleNumberPreview = function[\s\S]*edit\.buffer[\s\S]*controlDown == true[\s\S]*keyName == "A"/,
    'mouse activation and keyboard/controller editing must share one root-owned integer buffer');
  assert.match(settingsUi,
    /local function applyControlPatch\(patch, source\)[\s\S]*candidate\[key\] = value[\s\S]*local function commitChoice[\s\S]*\[control\.key\] = control\.values\[index\][\s\S]*local function commitToggle[\s\S]*\[control\.key\] = value/,
    'each settings primitive must commit only its own persisted field');
  assert.doesNotMatch(settingsUi, /applyFromControls/,
    'one control must not validate transient state from unrelated controls');
  assert.match(settingsUi,
    /local reserved = chord\.Key == "F6"[\s\S]*chord\.Key == "LeftMouseButton"[\s\S]*setSelectorChord\(control\.widget, persisted\)[\s\S]*scheduleShortcutFocusRestore\(control\)/,
    'reserved shortcut captures must restore persisted state before focus');
  for (const asset of [
    'pal-insight-preview.jpg', 'quick-stack-preview.png',
    'breeding-calculator-preview.png',
    'cratex.png', 'nexus.png', 'steam.png', 'curseforge.png',
    'x.png', 'discord.png', 'unicorn.png', 'buy-me-a-coffee.png',
    'sports-medal.png', 'red-heart.png',
  ]) {
    assert.ok(settingsUi.includes(`\"${asset}\"`),
      `Quick Stack About does not render ${asset}`);
  }
  assert.match(settingsUi,
    /state\.aboutOpen\s*==\s*true[\s\S]*?moveAboutFocus[\s\S]*?activateAboutAction/,
    'Quick Stack About must retain keyboard and controller navigation');
  assert.match(settingsUi,
    /strings\.aboutProducts[\s\S]*?title = "Pal Insight"[\s\S]*?strings\.aboutCreatorDescription[\s\S]*?strings\.aboutSpecialThanks[\s\S]*?strings\.aboutSupporters/,
    'Quick Stack About must retain the product shelf and fixed creator actions');
  assert.match(settingsUi,
    /aboutRosterOverlays\s*=\s*\{\}[\s\S]*?aboutRosterCloseActions\s*=\s*\{\}[\s\S]*?local function buildRosterOverlay\(mode\)[\s\S]*?aboutSpecialThanksEmpty[\s\S]*?aboutSupportersEmpty[\s\S]*?buildRosterOverlay\("thanks"\)[\s\S]*?buildRosterOverlay\("supporters"\)/,
    'Quick Stack About rosters must remain separate fixed modals with empty states');
  assert.match(settingsUi,
    /closeAboutRoster\s*=\s*function[\s\S]*?aboutRosterMode[\s\S]*?aboutRosterOverlays[\s\S]*?openAboutRoster\s*=\s*function\(mode\)[\s\S]*?aboutRosterOverlays/,
    'Quick Stack About rosters must open and close through their mode-owned surfaces');
  assert.match(main, /local HOST_REQUEST_POLL_MS = 16\b/,
    'hosted settings requests must use the one-frame request path');
  assert.match(main,
    /settingsHostRead\("HostSettingsOpen"\)[\s\S]*settingsHostRead\("HostRequestSignalRevision"\)[\s\S]*signalRevision > state\.settingsHostRequestSignalRevision[\s\S]*reconcileSettingsHostRequests/,
    'fast hosted handoff must reconcile only after its request signal advances');
  assert.match(settings,
    /canonicalKey == "F6"[\s\S]*canonicalKey == "Escape"[\s\S]*canonicalKey == "LeftMouseButton"/,
    'the shortcut selector must retain its settings-surface protection keys');
  const steamVote = fs.readFileSync(absolute(root, 'Scripts/steam_vote.lua'), 'utf8');
  assert.match(steamVote, /PalInsightQuickStackSteamVote/,
    'Quick Stack must load its own Steam vote helper');
  assert.ok(steamVote.includes(
    '"\\\\palinsightquickstack\\\\scripts\\\\palinsightquickstacksteamvote.dll"'),
    'Quick Stack must reject a Steam vote helper outside its own mod directory');
  const nativeVote = fs.readFileSync(absolute(root,
    'native/steam_vote/pal_insight_quick_stack_steam_vote.cpp'), 'utf8');
  const nativeVoteExports = fs.readFileSync(absolute(root,
    'native/steam_vote/PalInsightQuickStackSteamVote.def'), 'utf8');
  assert.match(nativeVote, /kQuickStackWorkshopItemId\s*=\s*3792968111ULL/,
    'Quick Stack Steam vote helper must target its own Workshop item');
  assert.doesNotMatch(nativeVote, /3778493118/,
    'Quick Stack Steam vote helper must not target Pal Insight');
  for (const suffix of [
    'initialize', 'refresh', 'status', 'set_up',
    'error_kind', 'error_result_low', 'error_result_high', 'clear_error',
  ]) {
    const name = `pal_quick_stack_steam_vote_${suffix}`;
    assert.ok(steamVote.includes(name) && nativeVote.includes(name)
      && nativeVoteExports.includes(name),
    `Quick Stack Steam vote ABI is missing ${name}`);
  }
}

function balancedTable(source, marker) {
  const markerAt = source.indexOf(marker);
  assert.notEqual(markerAt, -1, `missing localization table: ${marker}`);
  const start = source.indexOf('{', markerAt + marker.length);
  assert.notEqual(start, -1, `missing opening brace: ${marker}`);
  let depth = 0;
  let quote = null;
  let escaped = false;
  for (let index = start; index < source.length; index += 1) {
    const character = source[index];
    if (quote !== null) {
      if (escaped) escaped = false;
      else if (character === '\\') escaped = true;
      else if (character === quote) quote = null;
      continue;
    }
    if (character === '"' || character === "'") quote = character;
    else if (character === '{') depth += 1;
    else if (character === '}') {
      depth -= 1;
      if (depth === 0) return source.slice(start, index + 1);
    }
  }
  assert.fail(`unterminated localization table: ${marker}`);
}

function localeRows(source, marker = 'local STRINGS =') {
  const table = balancedTable(source, marker);
  const localePattern = SUPPORTED_LOCALES
    .map((locale) => locale.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
    .join('|');
  const rowPattern = new RegExp(
    `^\\s*(?:([a-z]+)|\\["(${localePattern})"\\])\\s*=\\s*\\{`, 'gm');
  const rows = new Map();
  for (const match of table.matchAll(rowPattern)) {
    const locale = match[1] || match[2];
    if (!SUPPORTED_LOCALES.includes(locale)) continue;
    const row = balancedTable(table.slice(match.index), match[0].slice(0, -1));
    const values = new Map();
    for (const valueMatch of row.matchAll(
      /\b([A-Za-z][A-Za-z0-9_]*)\s*=\s*"((?:\\.|[^"\\])*)"/g)) {
      values.set(valueMatch[1], valueMatch[2]);
    }
    rows.set(locale, values);
  }
  return rows;
}

function assertLocalizationCoverage(root) {
  const source = fs.readFileSync(absolute(root, 'Scripts/localization.lua'), 'utf8');
  const supported = balancedTable(source, 'local SUPPORTED_LOCALES =');
  const declared = [...supported.matchAll(/"([a-z0-9-]+)"/g)]
    .map((match) => match[1]);
  assert.deepEqual(declared, SUPPORTED_LOCALES,
    'localization locale list must match Palworld exactly');
  const rows = localeRows(source);
  assert.deepEqual([...rows.keys()].sort(), [...SUPPORTED_LOCALES].sort(),
    'localization must define every supported Palworld locale');
  const englishKeys = [...rows.get('en').keys()].sort();
  assert.ok(englishKeys.length > 0, 'English localization has no fields');
  for (const locale of SUPPORTED_LOCALES) {
    assert.deepEqual([...rows.get(locale).keys()].sort(), englishKeys,
      `localization ${locale} fields differ from English`);
    for (const key of englishKeys) {
      const expectedFormats = rows.get('en').get(key).match(/%[dfs]/g) || [];
      const actualFormats = rows.get(locale).get(key).match(/%[dfs]/g) || [];
      assert.deepEqual(actualFormats, expectedFormats,
      `localization ${locale}.${key} format fields differ from English`);
    }
  }
  const settingsRows = localeRows(source, 'local SETTINGS_STRINGS =');
  assert.deepEqual([...settingsRows.keys()].sort(), [...SUPPORTED_LOCALES].sort(),
    'settings localization must define every supported Palworld locale');
  const englishSettingsKeys = [...settingsRows.get('en').keys()].sort();
  assert.ok(englishSettingsKeys.includes('manualPlacement'),
    'settings localization must include the manual-placement choice');
  for (const locale of SUPPORTED_LOCALES) {
    assert.deepEqual([...settingsRows.get(locale).keys()].sort(),
      englishSettingsKeys,
      `settings localization ${locale} fields differ from English`);
  }
  const aboutRosterRows = localeRows(source,
    'local ABOUT_ROSTER_STRINGS =');
  const aboutRosterKeys = [
    'aboutRecommended', 'aboutSpecialThanks',
    'aboutSpecialThanksDescription', 'aboutSpecialThanksEmpty',
    'aboutSupporters', 'aboutSupportersDescription', 'aboutSupportersEmpty',
  ];
  assert.deepEqual([...aboutRosterRows.keys()].sort(),
    [...SUPPORTED_LOCALES].sort(),
    'About roster copy must define every supported Palworld locale');
  for (const locale of SUPPORTED_LOCALES) {
    assert.deepEqual([...aboutRosterRows.get(locale).keys()].sort(),
      [...aboutRosterKeys].sort(),
      `About roster ${locale} fields differ from the accepted contract`);
  }
  const settingsExtraRows = localeRows(source,
    'local SETTINGS_EXTRA_STRINGS =');
  const settingsExtraKeys = [
    'about', 'creator', 'externalShortcutConflict',
    'voteLike', 'voteReconsider', 'voteThanks',
  ];
  assert.deepEqual([...settingsExtraRows.keys()].sort(),
    [...SUPPORTED_LOCALES].sort(),
    'settings extras must define every supported Palworld locale');
  for (const locale of SUPPORTED_LOCALES) {
    assert.deepEqual([...settingsExtraRows.get(locale).keys()].sort(),
      [...settingsExtraKeys].sort(),
      `settings extras ${locale} fields differ from the accepted contract`);
    const expectedFormats = settingsExtraRows.get('en')
      .get('externalShortcutConflict').match(/%[dfs]/g) || [];
    const actualFormats = settingsExtraRows.get(locale)
      .get('externalShortcutConflict').match(/%[dfs]/g) || [];
    assert.deepEqual(actualFormats, expectedFormats,
      `settings extras ${locale} conflict format fields differ from English`);
  }
  const aboutContentRows = localeRows(source,
    'local ABOUT_CONTENT_STRINGS =');
  const aboutContentKeys = [
    'aboutSummary', 'aboutIntegration', 'aboutProducts', 'aboutCalculator',
    'aboutVisitCalculator',
    'aboutCurrent', 'aboutOpen', 'aboutCreator',
    'aboutCreatorDescription',
    'aboutDownloads', 'aboutCommunity', 'aboutSupport',
    'aboutSupportDescription',
  ];
  assert.deepEqual([...aboutContentRows.keys()].sort(),
    [...SUPPORTED_LOCALES].sort(),
    'About content must define every supported Palworld locale');
  for (const locale of SUPPORTED_LOCALES) {
    assert.deepEqual([...aboutContentRows.get(locale).keys()].sort(),
      [...aboutContentKeys].sort(),
      `About content ${locale} fields differ from the accepted contract`);
  }
  const inputHelpRows = localeRows(source,
    'local SETTINGS_INPUT_HELP_STRINGS =');
  const inputHelpKeys = [
    'inputHelpTitle', 'inputDeviceKeyboardMouse', 'inputDeviceGamepad',
    'navigate', 'adjust', 'confirm', 'toggleSettings',
    'returnToPalInsight', 'closeAllSettings', 'shortcutKeyboardMouseOnly',
  ];
  assert.deepEqual([...inputHelpRows.keys()].sort(),
    [...SUPPORTED_LOCALES].sort(),
    'settings input help must define every supported Palworld locale');
  for (const locale of SUPPORTED_LOCALES) {
    assert.deepEqual([...inputHelpRows.get(locale).keys()].sort(),
      [...inputHelpKeys].sort(),
      `settings input help ${locale} fields differ from the accepted contract`);
  }
  const notifications = fs.readFileSync(
    absolute(root, 'Scripts/notifications.lua'), 'utf8');
  assert.doesNotMatch(notifications, /[\u3400-\u9fff]/,
    'notifications.lua contains inline Chinese UI text');
  assert.match(notifications,
    /ResultDialogBridge\.acquire\(\s*build\.controller, build\.widget/,
    'detailed results must give the bridge the mounted modal owner');
  assert.match(notifications,
    /inputShield:SetVisibility\(VIS_VISIBLE\)[\s\S]*?Maximum = \{ X = 1\.0, Y = 1\.0 \}/,
    'detailed results must block pointer input across the full viewport');
  const bridge = fs.readFileSync(
    absolute(root, 'Scripts/pal_insight_bridge.lua'), 'utf8');
  assert.match(bridge,
    /if exclusiveController and not hostedParent then[\s\S]*NativeSettingsInput\.acquire\(\)/,
    'standalone settings must always acquire process-level controller isolation');
  const emergencyRelease = bridge.slice(
    bridge.indexOf('function Bridge.emergencyRelease(options)'),
    bridge.indexOf('\nreturn Bridge'));
  assert.doesNotMatch(emergencyRelease,
    /SetIgnoreMoveInput\(false\)|SetIgnoreLookInput\(false\)/,
    'emergency release must not decrement the counted input-isolation lease twice');
  assert.match(emergencyRelease,
    /local cookedReleased[\s\S]*local isolationReleased[\s\S]*local restored[\s\S]*local nativeReleased[\s\S]*clearModalOwnership\(\)/,
    'emergency release must verify every modal ownership stage before clearing state');
  assert.match(bridge, /local\s+CAPABILITY_VERSION\s*=\s*2\b/,
    'result-dialog bridge must require independent modal capability version 2');
  for (const mode of [
    'SetInputMode_GameOnly',
    'SetInputMode_UIOnlyEx',
    'SetInputMode_GameAndUIEx',
  ]) {
    assert.match(bridge, new RegExp(mode),
      `result-dialog bridge must observe and restore ${mode}`);
  }
  assert.match(bridge,
    /controller\.bShowMouseCursor\s*=\s*true/,
    'result-dialog bridge must own a visible cursor');
  assert.match(bridge,
    /scheduleModalReclaim\(\)/,
    'result-dialog bridge must reclaim ownership after external mode changes');
}

function assertPng(root, relative) {
  const file = absolute(root, relative);
  const data = fs.readFileSync(file);
  assert.ok(data.length <= 1024 * 1024,
    `${relative} exceeds the Workshop uploader 1 MB limit`);
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  assert.ok(data.length >= 33 && data.subarray(0, 8).equals(signature),
    `${relative} must be a valid PNG`);
  assert.equal(data.subarray(12, 16).toString('ascii'), 'IHDR',
    `${relative} has no leading IHDR chunk`);
  assert.ok(data.readUInt32BE(16) >= 256 && data.readUInt32BE(20) >= 256,
    `${relative} must be at least 256 x 256`);
}

function assertReleaseMetadata(root, version) {
  const metadata = readJson(root, RELEASE_METADATA);
  assert.equal(metadata.packageName, PACKAGE_NAME,
    `release packageName must be ${PACKAGE_NAME}`);
  assert.equal(metadata.version, version,
    'release metadata and runtime versions differ');
  assert.equal(metadata.author, 'cratexnet',
    'release author must be cratexnet');
  assert.equal(metadata.license, 'All Rights Reserved',
    'release license must match Pal Insight');
  assert.equal(metadata.releaseType, 'release',
    '0.x releases use normal version labels without an additional beta suffix');
  assert.deepEqual(metadata.languages, SUPPORTED_LOCALES,
    'release metadata must list every supported Palworld locale in runtime order');
  assert.equal(metadata.multiplayer, 'unverified',
    'multiplayer must remain unverified until representative runtime evidence exists');
}

function assertWorkshopMetadata(root, version) {
  const info = readJson(root, WORKSHOP_INFO);
  assert.equal(info.ModName, 'Pal Insight: Quick Stack');
  assert.equal(info.PackageName, PACKAGE_NAME);
  assert.equal(info.Thumbnail, 'thumbnail.png');
  assert.equal(info.Version, version);
  assert.equal(info.DebugMode, false);
  assert.equal(info.MinRevision, 82182);
  assert.equal(info.Author, 'cratexnet');
  assert.deepEqual(info.Dependencies, ['UE4SSExperimentalPW']);
  assert.ok(Array.isArray(info.Tags) && info.Tags.includes('UE4SS')
    && info.Tags.includes('Utilities'),
  'Workshop tags must identify UE4SS and Utilities');
  assert.deepEqual(info.InstallRule,
    [{ Type: 'Lua', Targets: ['./Scripts', './assets'] }],
    'Quick Stack must install its client runtime and Workshop-only UI assets');
  assertPng(root, WORKSHOP_THUMBNAIL);
}

function assertPrebuild(root) {
  assertFilesExist(root, RUNTIME_FILES, 'release runtime');
  assertFilesExist(root, COMMON_NATIVE_FILES.map((entry) => entry.source),
    'common native runtime');
  const version = readRuntimeVersion(root);
  assertReleaseVersion(version);
  assertReleaseDiagnosticsDisabled(root);
  assertQuickStackSettings(root);
  assertLocalizationCoverage(root);
  assertFilesExist(root,
    [...PUBLIC_DOCUMENTS, RELEASE_METADATA, WORKSHOP_INFO, WORKSHOP_THUMBNAIL],
    'release source');
  assertFilesExist(root, [
    'native/settings_input/pal_insight_quick_stack_settings_input.cpp',
    'native/settings_input/PalInsightQuickStackSettingsInput.def',
    'native/settings_input/build.ps1',
    'native/steam_vote/pal_insight_quick_stack_steam_vote.cpp',
    'native/steam_vote/PalInsightQuickStackSteamVote.def',
    'native/steam_vote/build.ps1',
    'assets/steam-workshop-feedback/thumb-up-outline.png',
    'assets/steam-workshop-feedback/thumb-up-filled.png',
    'assets/steam-workshop-feedback/thumb-down-filled.png',
  ], 'native helper source');
  assertReleaseMetadata(root, version);
  assertWorkshopMetadata(root, version);
  return version;
}

function createChannelPlan(channel) {
  assert.ok(RELEASE_CHANNELS.includes(channel),
    `unsupported release channel: ${channel}`);
  const entries = [];
  if (channel === 'workshop') {
    entries.push(
      { source: WORKSHOP_INFO, target: 'Info.json' },
      { source: WORKSHOP_THUMBNAIL, target: 'thumbnail.png' },
      ...RUNTIME_FILES
        .filter((relative) => relative !== 'enabled.txt')
        .map((relative) => ({ source: relative, target: relative })),
      ...COMMON_NATIVE_FILES,
      ...WORKSHOP_ONLY_FILES,
    );
    return entries;
  }
  entries.push(...PUBLIC_DOCUMENTS.map((relative) => ({
    source: relative,
    target: relative,
  })));
  entries.push(...RUNTIME_FILES.map((relative) => ({
    source: relative,
    target: `${PORTABLE_RUNTIME_ROOT}/${relative}`,
  })));
  entries.push(...COMMON_NATIVE_FILES.map((entry) => ({
    source: entry.source,
    target: `${PORTABLE_RUNTIME_ROOT}/${entry.target}`,
  })));
  return entries;
}

function listFiles(root) {
  assert.ok(fs.existsSync(root), `artifact root does not exist: ${root}`);
  const files = [];
  const visit = (directory) => {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })
      .sort((left, right) => left.name.localeCompare(right.name))) {
      const full = path.join(directory, entry.name);
      if (entry.isDirectory()) visit(full);
      else files.push(portable(path.relative(root, full)));
    }
  };
  visit(root);
  return files.sort();
}

function assertArtifact(sourceRoot, artifactRoot, channel) {
  assertPrebuild(sourceRoot);
  const plan = createChannelPlan(channel);
  const expected = plan.map((entry) => entry.target).sort();
  const actual = listFiles(artifactRoot);
  assert.deepEqual(actual, expected,
    `${channel} artifact contains missing or unexpected files`);
}

function parseArguments(argv) {
  const [phase, ...rest] = argv;
  const values = { phase, root: process.cwd(), channel: null, artifact: null };
  for (let index = 0; index < rest.length; index += 1) {
    const argument = rest[index];
    if (argument === '--root') values.root = path.resolve(rest[++index]);
    else if (argument === '--channel') values.channel = rest[++index];
    else if (argument === '--artifact') values.artifact = path.resolve(rest[++index]);
    else throw new Error(`unknown argument: ${argument}`);
  }
  return values;
}

function runCli(argv) {
  const options = parseArguments(argv);
  assert.ok(['prebuild', 'artifact'].includes(options.phase),
    'usage: node pal_insight_quick_stack_release_inventory.js '
      + '<prebuild|artifact> [--root PATH] '
      + '[--channel nexus|curseforge|workshop --artifact PATH]');
  const version = assertPrebuild(options.root);
  if (options.phase === 'artifact') {
    assert.ok(RELEASE_CHANNELS.includes(options.channel),
      'artifact phase requires a supported --channel');
    assert.ok(options.artifact, 'artifact phase requires --artifact PATH');
    const expected = createChannelPlan(options.channel)
      .map((entry) => entry.target).sort();
    assert.deepEqual(listFiles(options.artifact), expected,
      `${options.channel} artifact contains missing or unexpected files`);
  }
  process.stdout.write(
    `Quick Stack ${options.phase} gate passed (${version}`
      + `${options.channel ? `, ${options.channel}` : ''})\n`,
  );
}

if (require.main === module) {
  try {
    runCli(process.argv.slice(2));
  } catch (error) {
    process.stderr.write(`Quick Stack release gate failed: ${error.message}\n`);
    process.exitCode = 1;
  }
}

module.exports = {
  ABOUT_FILES,
  COMMON_NATIVE_FILES,
  PACKAGE_NAME,
  PORTABLE_RUNTIME_ROOT,
  PUBLIC_DOCUMENTS,
  RELEASE_CHANNELS,
  RUNTIME_FILES,
  WORKSHOP_ONLY_FILES,
  SUPPORTED_LOCALES,
  assertArtifact,
  assertLocalizationCoverage,
  assertPrebuild,
  createChannelPlan,
  listFiles,
  readRuntimeVersion,
};
