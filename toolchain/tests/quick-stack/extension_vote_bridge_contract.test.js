const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const root = path.resolve(__dirname, "..", "..", "..");
const runtime = fs.readFileSync(path.join(root, "Scripts", "main.lua"), "utf8");
const settingsUi = fs.readFileSync(
  path.join(root, "Scripts", "settings_ui.lua"),
  "utf8",
);

test("Quick Stack publishes and handles the Pal Insight vote bridge", () => {
  assert.match(runtime, /SteamVoteAvailable/);
  assert.match(runtime, /SteamVoteStatus/);
  assert.match(runtime, /SteamVoteRequestRevision/);
  assert.match(runtime, /SteamVoteAppliedRevision/);
  assert.match(runtime, /SteamVoteRejectedRevision/);
});

test("Quick Stack keeps a successful thumb action as a passive thank-you state", () => {
  assert.match(settingsUi, /local voteBox = makeSteamVoteControl/);
  assert.match(settingsUi, /state\.steamVoteBox:SetVisibility\(VIS_VISIBLE\)/);
  assert.match(settingsUi, /status == statuses\.up and VIS_VISIBLE or VIS_COLLAPSED/);
  assert.match(settingsUi, /makeSteamVoteContent\(tree, "thumb-up-filled.png", true\)/);
  assert.match(settingsUi, /control\.passive = status == statuses\.up/);
  assert.doesNotMatch(settingsUi, /openDownvoteAcknowledgement\(\) == true/);
  assert.doesNotMatch(settingsUi, /openSteamVoteChecking\(\) == true/);
});
