'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'Scripts', 'settings_ui.lua'), 'utf8');

const start = source.indexOf('local function refreshItemPickerNameMarquee(record, active)');
const end = source.indexOf('\nend\n\nlocal function refreshTriggerSurfaces', start);
assert.ok(start >= 0 && end > start, 'missing shared item-picker marquee');
const marquee = source.slice(start, end);

assert.match(source, /local ITEM_PICKER_MARQUEE_START_DELAY = 0\.0/,
  'hover or navigation focus must start an overflowing name immediately');
assert.match(source, /local ITEM_PICKER_MARQUEE_END_DELAY = 0\.80/,
  'the end position must remain readable before the marquee restarts');
assert.match(marquee,
  /elapsed > ITEM_PICKER_MARQUEE_START_DELAY[\s\S]*ITEM_PICKER_MARQUEE_SPEED/,
  'the shared animation must derive movement directly from its start delay');

console.log('Quick Stack item-picker marquee contract: ok');
