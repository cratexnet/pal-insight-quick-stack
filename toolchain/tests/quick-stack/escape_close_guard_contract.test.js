'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '../../..');
const bridge = fs.readFileSync(
  path.join(root, 'Scripts', 'pal_insight_bridge.lua'), 'utf8');

function section(startMarker, endMarker) {
  const start = bridge.indexOf(startMarker);
  const end = bridge.indexOf(endMarker, start + startMarker.length);
  assert.ok(start >= 0 && end > start,
    `missing section ${startMarker} -> ${endMarker}`);
  return bridge.slice(start, end);
}

const guard = section('local function escapeCloseGuardBlocksNativeUI()',
  '\nend\n\nlocal function ownsUnderlyingInput');
const arm = section('function Bridge.armEscapeClose(source)',
  '\nfunction Bridge.releaseEscapeClose');
const closed = section('function Bridge.noteEscapeWindowClosed()',
  '\nfunction Bridge.cancelEscapeClose');

assert.match(guard,
  /record\.windowClosed == true and record\.released ~= true[\s\S]*record\.settleUntil/,
  'a closed transaction must fail open after settlement when KeyUp is lost');
assert.match(arm, /expiresAt = os\.clock\(\) \+ 0\.25/,
  'the entire Escape close transaction must fail open within 250 ms');
assert.doesNotMatch(arm, /expiresAt = os\.clock\(\) \+ 3\.0/,
  'a lost close callback must not suppress later game input for several seconds');
assert.match(closed,
  /record\.settleUntil = now \+ 0\.08[\s\S]*record\.expiresAt = now \+ 0\.25/,
  'confirmed close must retain only the short same-event settlement window');

console.log('Quick Stack Escape close guard contract: ok');
