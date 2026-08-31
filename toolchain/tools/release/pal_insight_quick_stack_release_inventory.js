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
const RUNTIME_FILES = Object.freeze([
  'Scripts/config.lua',
  'Scripts/localization.lua',
  'Scripts/main.lua',
  'Scripts/notifications.lua',
  'Scripts/pal_insight_bridge.lua',
  'Scripts/palworld.lua',
  'Scripts/quick_stack.lua',
  'Scripts/settings.lua',
  'enabled.txt',
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
      /^\s*PalEggRouting\s*=\s*["']IncubatorThenStorage["']/m,
      `${relative} must default PalEggRouting to IncubatorThenStorage`);
    assert.match(source,
      /^\s*RelicRouting\s*=\s*["']RecyclerThenStorage["']/m,
      `${relative} must default RelicRouting to RecyclerThenStorage`);
  }
  const main = fs.readFileSync(absolute(root, 'Scripts/main.lua'), 'utf8');
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

function localeRows(source) {
  const table = balancedTable(source, 'local STRINGS =');
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
  assert.deepEqual(info.InstallRule, [{ Type: 'Lua', Targets: ['./Scripts'] }],
    'Quick Stack is a client-only Lua mod installed from ./Scripts');
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
  PACKAGE_NAME,
  PORTABLE_RUNTIME_ROOT,
  PUBLIC_DOCUMENTS,
  RELEASE_CHANNELS,
  RUNTIME_FILES,
  SUPPORTED_LOCALES,
  assertArtifact,
  assertLocalizationCoverage,
  assertPrebuild,
  createChannelPlan,
  listFiles,
  readRuntimeVersion,
};
