'use strict';

const assert = require('node:assert/strict');
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
  'assets/about/buy-me-a-coffee.png',
  'assets/about/cratex.png',
  'assets/about/discord.png',
  'assets/about/fluentui-emoji-LICENSE.txt',
  'assets/about/nexus.png',
  'assets/about/pal-insight-preview.jpg',
  'assets/about/steam.png',
  'assets/about/x.png',
]);
const RUNTIME_FILES = Object.freeze([
  'Scripts/config.lua',
  'Scripts/localization.lua',
  'Scripts/main.lua',
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
  assert.match(main, /local SETTINGS_HOST_PROTOCOL_VERSION = 1\b/,
    'settings hosting must use the accepted private protocol version');
  for (const field of [
    'QuickStackGeneration', 'QuickStackHeartbeat',
    'OpenExtensionSettingsHostGeneration',
    'OpenExtensionSettingsTargetGeneration',
    'CloseExtensionSettingsHostGeneration',
    'CloseExtensionSettingsTargetGeneration',
    'ExtensionSettingsAckHostGeneration',
    'ExtensionSettingsAckQuickStackGeneration',
    'HostSettingsOpen',
    'HostRequestSignalRevision',
  ]) {
    assert.ok(main.includes(`"${field}"`),
      `settings host contract is missing ${field}`);
  }
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
  assert.match(settings, /RecyclerOnly or RecyclerThenStorage/,
    'writable configuration must document relic routing values');
  assert.match(settings,
    /WorldTreeHolyWaterMinimum must be an integer from 1 to 100/,
    'writable configuration must validate the Holy Water minimum range');
  const settingsUi = fs.readFileSync(
    absolute(root, 'Scripts/settings_ui.lua'), 'utf8');
  assert.match(settingsUi,
    /function SettingsUI\.open\(mode,[\s\S]*buildSettingsWindow/,
    'standalone and hosted entry points must use one settings surface');
  assert.match(settingsUi,
    /Settings\.validateShortcut[\s\S]*Settings\.save/,
    'Quick Stack must retain validation and persistence ownership');
  assert.doesNotMatch(settingsUi, /SetIsSelectingKey/,
    'settings UI must not call an unavailable selector-state setter');
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
    /local function makeIconTrigger[\s\S]*?\/Script\/UMG\.Button[\s\S]*?\/Script\/UMG\.CheckBox[\s\S]*?VIS_HIT_TEST_INVISIBLE[\s\S]*?styleHeaderButton/,
    'settings Header actions must retain Pal Insight Button visuals over the compatibility input layer');
  assert.match(settingsUi,
    /local function makeSteamVoteAction[\s\S]*?\/Script\/UMG\.Button[\s\S]*?\/Script\/UMG\.CheckBox[\s\S]*?VIS_HIT_TEST_INVISIBLE[\s\S]*?styleHeaderButton/,
    'Steam voting must retain Pal Insight Button visuals over the compatibility input layer');
  assert.match(settingsUi,
    /voteBlack\s*=\s*\{\s*R\s*=\s*0\.0,[\s\S]*?voteGold\s*=\s*\{\s*R\s*=\s*1\.0,\s*G\s*=\s*0\.7379109859,\s*B\s*=\s*0\.0051819999/,
    'Steam voting must use the same black and gold colors as Pal Insight');
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
    'website', 'palInsight', 'quickStackNexus', 'quickStackWorkshop',
    'quickStackCurseForge', 'x', 'discord', 'bmc',
  ]) {
    assert.match(settingsUi, new RegExp(`\\b${urlKey}\\s*=`),
      `Quick Stack About is missing the ${urlKey} destination`);
  }
  assert.match(settingsUi,
    /buildAboutModal\s*=\s*function[\s\S]*?\/Script\/UMG\.ScrollBox[\s\S]*?strings\.aboutSummary[\s\S]*?strings\.aboutCreatorDescription[\s\S]*?strings\.aboutDownloads[\s\S]*?strings\.aboutCommunity[\s\S]*?strings\.aboutSupport/,
    'Quick Stack About must contain product, creator, download, community, and support content');
  assert.match(settingsUi,
    /local function makeAboutAction[\s\S]*?\/Script\/UMG\.Button[\s\S]*?\/Script\/UMG\.CheckBox[\s\S]*?state\.aboutActions/,
    'Quick Stack About actions must share the native visual and compatibility input layers');
  assert.match(settingsUi,
    /local function aboutAssetPath[\s\S]*?assets\/about\/[\s\S]*?local function aboutTexture[\s\S]*?ImportFileAsTexture2D/,
    'Quick Stack About must load its packaged visual assets');
  assert.match(settingsUi,
    /local function makeAboutLogoButton[\s\S]*?\/Script\/UMG\.Image[\s\S]*?SetBrushFromTexture[\s\S]*?\/Script\/UMG\.Button[\s\S]*?\/Script\/UMG\.CheckBox/,
    'Quick Stack About logo actions must retain image visuals and compatibility input');
  for (const asset of [
    'pal-insight-preview.jpg', 'cratex.png', 'nexus.png', 'steam.png',
    'curseforge.png',
    'x.png', 'discord.png', 'buy-me-a-coffee.png',
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
    /aboutRosterOpen[\s\S]*?openAboutRoster\s*=\s*function[\s\S]*?aboutSpecialThanksEmpty[\s\S]*?aboutSupportersEmpty[\s\S]*?closeAboutRoster/,
    'Quick Stack About rosters must remain fixed nested modals with empty states');
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
    'returnToPalInsight', 'closeAllSettings',
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
  const version = readRuntimeVersion(root);
  assertReleaseVersion(version);
  assertReleaseDiagnosticsDisabled(root);
  assertQuickStackSettings(root);
  assertLocalizationCoverage(root);
  assertFilesExist(root,
    [...PUBLIC_DOCUMENTS, RELEASE_METADATA, WORKSHOP_INFO, WORKSHOP_THUMBNAIL],
    'release source');
  assertFilesExist(root, [
    'native/steam_vote/pal_insight_quick_stack_steam_vote.cpp',
    'native/steam_vote/PalInsightQuickStackSteamVote.def',
    'native/steam_vote/build.ps1',
    'assets/steam-workshop-feedback/thumb-up-outline.png',
    'assets/steam-workshop-feedback/thumb-up-filled.png',
    'assets/steam-workshop-feedback/thumb-down-filled.png',
  ], 'Steam Workshop vote source');
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
