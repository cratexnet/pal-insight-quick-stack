'use strict';

const assert = require('node:assert/strict');
const childProcess = require('node:child_process');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const {
  assertArtifact,
  assertPrebuild,
  createChannelPlan,
  listFiles,
} = require('./toolchain/tools/release/pal_insight_quick_stack_release_inventory');
const {
  normalizeZipExtendedTimestamps,
} = require('./toolchain/tools/release/normalize_zip_timestamps');

const ROOT = __dirname;
const RELEASE_ROOT = path.join(ROOT, 'release');
const ASSEMBLY_ROOT = path.join(ROOT, 'release-assembly');
const ROUNDTRIP_ROOT = path.join(ROOT, 'release-roundtrip');
const FIXED_TIMESTAMP = new Date('2026-09-03T00:00:00.000Z');

function sha256(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

function removeOwnedDirectory(directory) {
  const relative = path.relative(ROOT, directory);
  assert(relative && !relative.startsWith(`..${path.sep}`)
    && !path.isAbsolute(relative),
  `refuse to delete outside the repository: ${directory}`);
  fs.rmSync(directory, { recursive: true, force: true, maxRetries: 2 });
}

function run(executable, args, label, cwd = ROOT) {
  const result = childProcess.spawnSync(executable, args, {
    cwd,
    windowsHide: true,
    encoding: 'utf8',
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${label} failed (${result.status}): ${String(
      result.stderr || result.stdout || '').trim()}`);
  }
  return String(result.stdout || '').trim();
}

function copyFile(source, target) {
  assert(fs.existsSync(source), `missing release input: ${source}`);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.copyFileSync(source, target);
  assert.equal(sha256(target), sha256(source),
    `release copy differs from source: ${target}`);
}

function assemble(channel, destination) {
  fs.mkdirSync(destination, { recursive: true });
  for (const entry of createChannelPlan(channel)) {
    copyFile(
      path.join(ROOT, ...entry.source.split('/')),
      path.join(destination, ...entry.target.split('/')),
    );
  }
  assertArtifact(ROOT, destination, channel);
  return destination;
}

function normalizeTreeTimestamps(root) {
  const visit = (directory) => {
    const directories = [];
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const full = path.join(directory, entry.name);
      if (entry.isDirectory()) {
        visit(full);
        directories.push(full);
      } else {
        fs.utimesSync(full, FIXED_TIMESTAMP, FIXED_TIMESTAMP);
      }
    }
    for (const child of directories) {
      fs.utimesSync(child, FIXED_TIMESTAMP, FIXED_TIMESTAMP);
    }
  };
  visit(root);
}

function assertSafeArchiveEntry(entry) {
  assert.equal(entry.includes('\\'), false,
    `archive entry uses a backslash: ${entry}`);
  assert.equal(entry.startsWith('/'), false,
    `archive entry is absolute: ${entry}`);
  assert.equal(/^[A-Za-z]:/.test(entry), false,
    `archive entry has a drive prefix: ${entry}`);
  const segments = entry.split('/').filter(Boolean);
  assert.equal(segments.includes('..'), false,
    `archive entry escapes its root: ${entry}`);
}

function compareTrees(expectedRoot, actualRoot) {
  const expected = listFiles(expectedRoot);
  const actual = listFiles(actualRoot);
  assert.deepEqual(actual, expected, 'round-trip archive file list differs');
  for (const relative of expected) {
    assert.equal(
      sha256(path.join(actualRoot, ...relative.split('/'))),
      sha256(path.join(expectedRoot, ...relative.split('/'))),
      `round-trip archive differs at ${relative}`,
    );
  }
}

function createZip(packageRoot, archive) {
  fs.mkdirSync(path.dirname(archive), { recursive: true });
  normalizeTreeTimestamps(packageRoot);
  const entries = fs.readdirSync(packageRoot).sort((left, right) =>
    left.localeCompare(right));
  run('tar.exe', ['-a', '-c', '-f', archive, ...entries],
    `create ${path.basename(archive)}`, packageRoot);
  assert(fs.existsSync(archive) && fs.statSync(archive).size > 0,
    `release archive was not created: ${archive}`);
  normalizeZipExtendedTimestamps(
    archive, Math.floor(FIXED_TIMESTAMP.getTime() / 1000));
}

function verifyZip(archive, expectedRoot, channel, key) {
  const entries = run('tar.exe', ['-tf', archive],
    `inspect ${path.basename(archive)}`).split(/\r?\n/).filter(Boolean);
  assert(entries.length > 0, `${path.basename(archive)} is empty`);
  for (const entry of entries) assertSafeArchiveEntry(entry);
  const destination = path.join(ROUNDTRIP_ROOT, key);
  fs.mkdirSync(destination, { recursive: true });
  run('tar.exe', ['-xf', archive, '-C', destination],
    `extract ${path.basename(archive)}`);
  compareTrees(expectedRoot, destination);
  assertArtifact(ROOT, destination, channel);
  return entries.length;
}

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
}

// The release gate must pass before any previous artifact is removed.
const version = assertPrebuild(ROOT);
const releaseMetadata = JSON.parse(fs.readFileSync(
  path.join(ROOT, 'packaging', 'release.json'), 'utf8'));

for (const directory of [RELEASE_ROOT, ASSEMBLY_ROOT, ROUNDTRIP_ROOT]) {
  removeOwnedDirectory(directory);
  fs.mkdirSync(directory, { recursive: true });
}

const assemblies = {
  nexus: assemble('nexus', path.join(ASSEMBLY_ROOT, 'nexus')),
  nexusGamePass: assemble(
    'nexus-gamepass', path.join(ASSEMBLY_ROOT, 'nexus-gamepass')),
  curseforge: assemble('curseforge', path.join(ASSEMBLY_ROOT, 'curseforge')),
  curseforgeGamePass: assemble(
    'curseforge-gamepass', path.join(ASSEMBLY_ROOT, 'curseforge-gamepass')),
  workshop: assemble('workshop',
    path.join(RELEASE_ROOT, 'workshop', 'PalInsightQuickStack')),
};

const fileNames = {
  standard: `Pal-Insight-Quick-Stack-${version}.zip`,
  gamePass: `Pal-Insight-Quick-Stack-${version}-Game-Pass.zip`,
};
const archives = {
  nexus: path.join(RELEASE_ROOT, 'nexus', fileNames.standard),
  nexusGamePass: path.join(RELEASE_ROOT, 'nexus', fileNames.gamePass),
  curseforge: path.join(RELEASE_ROOT, 'curseforge', fileNames.standard),
  curseforgeGamePass: path.join(
    RELEASE_ROOT, 'curseforge', fileNames.gamePass),
};

createZip(assemblies.nexus, archives.nexus);
createZip(assemblies.nexusGamePass, archives.nexusGamePass);
createZip(assemblies.curseforge, archives.curseforge);
createZip(assemblies.curseforgeGamePass, archives.curseforgeGamePass);

const archiveEntries = {
  nexus: verifyZip(archives.nexus, assemblies.nexus, 'nexus', 'nexus'),
  nexusGamePass: verifyZip(archives.nexusGamePass, assemblies.nexusGamePass,
    'nexus-gamepass', 'nexus-gamepass'),
  curseforge: verifyZip(archives.curseforge, assemblies.curseforge,
    'curseforge', 'curseforge'),
  curseforgeGamePass: verifyZip(
    archives.curseforgeGamePass, assemblies.curseforgeGamePass,
    'curseforge-gamepass', 'curseforge-gamepass'),
};

assert.equal(sha256(archives.nexus), sha256(archives.curseforge),
  'Nexus and CurseForge Steam/Win64 archives must be byte-identical');
assert.equal(sha256(archives.nexusGamePass), sha256(archives.curseforgeGamePass),
  'Nexus and CurseForge Game Pass/WinGDK archives must be byte-identical');

const packageRecord = (file, entries) => ({
  relative: path.relative(ROOT, file).split(path.sep).join('/'),
  bytes: fs.statSync(file).size,
  sha256: sha256(file),
  archiveEntries: entries,
  backslashEntries: 0,
  extractedTreeByteMatch: true,
});
const manifest = {
  release: `Pal Insight: Quick Stack ${version}`,
  status: 'passed',
  nexus: releaseMetadata.nexus,
  packages: {
    nexus: packageRecord(archives.nexus, archiveEntries.nexus),
    nexusGamePass: packageRecord(
      archives.nexusGamePass, archiveEntries.nexusGamePass),
    curseforge: packageRecord(archives.curseforge, archiveEntries.curseforge),
    curseforgeGamePass: packageRecord(
      archives.curseforgeGamePass, archiveEntries.curseforgeGamePass),
    workshop: {
      relative: path.relative(ROOT, assemblies.workshop).split(path.sep).join('/'),
      files: listFiles(assemblies.workshop).length,
      artifactGate: true,
    },
  },
  checks: {
    prebuildGate: true,
    diagnosticsDisabled: true,
    safeArchivePaths: true,
    extractedTreeByteMatch: true,
    gamePassRuntimeRoot: 'Pal/Binaries/WinGDK/ue4ss/Mods/PalInsightQuickStack',
    realGamePassRuntimeTest: false,
  },
};
writeJson(path.join(RELEASE_ROOT, 'release-manifest.json'), manifest);
fs.writeFileSync(path.join(RELEASE_ROOT, 'SHA256SUMS.txt'), [
  `${manifest.packages.nexus.sha256}  nexus/${fileNames.standard}`,
  `${manifest.packages.nexusGamePass.sha256}  nexus/${fileNames.gamePass}`,
  `${manifest.packages.curseforge.sha256}  curseforge/${fileNames.standard}`,
  `${manifest.packages.curseforgeGamePass.sha256}  curseforge/${fileNames.gamePass}`,
  '',
].join('\n'), 'utf8');

removeOwnedDirectory(ASSEMBLY_ROOT);
removeOwnedDirectory(ROUNDTRIP_ROOT);
process.stdout.write(`${JSON.stringify(manifest, null, 2)}\n`);
