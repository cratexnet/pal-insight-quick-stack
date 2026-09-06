'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..', '..', '..');
const lua = fs.readFileSync(path.join(root, 'Scripts', 'settings_ui.lua'), 'utf8');
const bridgeLua = fs.readFileSync(
  path.join(root, 'Scripts', 'pal_insight_bridge.lua'), 'utf8');
const notificationsLua = fs.readFileSync(
  path.join(root, 'Scripts', 'notifications.lua'), 'utf8');

function section(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start + startMarker.length);
  assert.ok(start >= 0 && end > start,
    `missing section ${startMarker} -> ${endMarker}`);
  return source.slice(start, end);
}

const buildWindow = section(lua, 'local function buildSettingsWindow(controller, mode)',
  '\nlocal function acquireInput');
const openWindow = section(lua, 'function SettingsUI.open(mode, options)',
  '\ncompleteClose = function');
const acquireFailure = section(lua, '    if not acquired then',
  '    for _, keyName in ipairs(state.controllerKeys) do');
const completeClose = section(lua, 'completeClose = function(closedMode, reason, widget, controller, escapeClose)',
  '\nfunction SettingsUI.close(reason)');
const bridgeMountHelpers = section(bridgeLua, 'local function mountCookedBridge(bridge)',
  '\nlocal function discardBridgeCache()');
const prepareBridge = section(bridgeLua, 'local function prepareBridgeCache(controller)',
  '\nfunction Bridge.prepareForController(controller)');
const acquireBridge = section(bridgeLua, 'function Bridge.acquire(controller, ownerWidget, options)',
  '\nfunction Bridge.cookedInputActive()');
const releaseBridge = section(bridgeLua, 'function Bridge.release(options)',
  '\nfunction Bridge.emergencyRelease(options)');
const emergencyReleaseBridge = section(bridgeLua, 'function Bridge.emergencyRelease(options)',
  '\nreturn Bridge');
const compactNotification = section(notificationsLua,
  'local function mountCompactFrame(widget, tree, content, textWidgets,',
  '\nlocal function detailedMetrics(controller)');

assert.doesNotMatch(buildWindow, /AddToViewport/,
  'prewarm construction must not mount a closed settings tree');
assert.match(openWindow,
  /prepareWindowForOpen\(mode\)[\s\S]*widget:AddToViewport\(120\)[\s\S]*acquireInput\(/,
  'the real open transaction must attach the prepared cached tree before acquiring input');
assert.match(acquireFailure, /widget:RemoveFromParent\(\)/,
  'a failed open must detach the cached tree after rolling back input ownership');
assert.match(completeClose, /widget:RemoveFromParent\(\)/,
  'a successful close must detach a cache-preserved settings tree');
assert.match(completeClose,
  /if preserveWindow and P\.isValid\(widget\)[\s\S]*SetVisibility\(VIS_COLLAPSED\)[\s\S]*widget:RemoveFromParent\(\)/,
  'a cache-preserved settings tree must be detached after it is hidden');
assert.doesNotMatch(prepareBridge, /AddToViewport/,
  'prewarming the cooked input bridge must leave its transparent widget detached');
assert.match(bridgeMountHelpers, /bridge:AddToViewport\(99\)/,
  'the cooked input bridge must have an explicit active-lifetime mount operation');
assert.match(bridgeMountHelpers, /bridge:RemoveFromParent\(\)/,
  'the cooked input bridge must have an explicit inactive-lifetime detach operation');
assert.match(acquireBridge,
  /mountCookedBridge\(bridge\)[\s\S]*setCookedBridgeActive\(bridge, true\)/,
  'acquiring modal input must attach the cached bridge before activating it');
assert.match(releaseBridge, /detachCookedBridge\(bridge\)/,
  'normal modal release must detach the transparent bridge');
assert.match(emergencyReleaseBridge, /detachCookedBridge\(bridge\)/,
  'emergency modal release must detach the transparent bridge');
assert.match(compactNotification,
  /root:SetVisibility\(VIS_HIT_TEST_INVISIBLE\)[\s\S]*widget:SetVisibility\(VIS_HIT_TEST_INVISIBLE\)/,
  'compact notifications must retain a non-hit-testable child root if owner visibility is restored');

console.log('Quick Stack settings detached window cache contract: ok');
