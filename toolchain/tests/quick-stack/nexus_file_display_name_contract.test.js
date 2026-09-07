'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '../../..');
const metadata = JSON.parse(fs.readFileSync(
  path.join(root, 'packaging/release.json'), 'utf8'));
const buildRelease = fs.readFileSync(path.join(root, 'build_release.js'), 'utf8');
const releaseGuide = fs.readFileSync(
  path.join(root, 'docs/RELEASE-PROCESS.md'), 'utf8');

assert.deepEqual(metadata.nexus, {
  mainFileDisplayName: 'Pal Insight: Quick Stack',
  gamePassFileDisplayName: 'Game Pass Experimental (WinGDK)',
});
assert.doesNotMatch(metadata.nexus.mainFileDisplayName, /\d+\.\d+\.\d+/);
assert.doesNotMatch(metadata.nexus.gamePassFileDisplayName, /\d+\.\d+\.\d+/);
assert.match(buildRelease,
  /nexus:\s*releaseMetadata\.nexus/,
  'release manifest must carry the validated Nexus display names');
assert.match(releaseGuide,
  /Nexus Version field/,
  'release guide must keep the version in the Nexus Version field');
assert.match(releaseGuide,
  /versioned ZIP filename/,
  'release guide must distinguish archive filenames from Nexus display names');

process.stdout.write('Quick Stack Nexus display-name contract passed\n');
