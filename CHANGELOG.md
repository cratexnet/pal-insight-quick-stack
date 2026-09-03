# Changelog

## Unreleased

- Added a default-off `IncludeGuildChest` setting. When enabled, Quick Stack
  can use an accessible Guild Chest in the current guild base, with guild-role
  checks, shared-container deduplication, bounded replication readiness, and
  submission-time revalidation.

## 1.0.0 - 2026-09-03

Quick Stack 1.0.0 is the first stable release, adding configurable storage
rules, a full settings panel, clearer results, and smoother storage runs.

### Storage rules

- Press `F5` inside the current base to store eligible backpack items. Items
  ignored through Inventory `Tab → R` stay in the backpack by default, and
  Guild Chests are never used.
- Choose whether `F5` also stores ignored items and item types not already
  present in storage.
- Pal Eggs use Incubators only by default, while Ancient Civilization Relics
  use Ancient Relic Recyclers only. Either route can fall back to regular
  storage or be set to manual placement so Quick Stack leaves that item type in
  the backpack. Each Recycler keeps `10` World Tree Holy Water by default
  (`1–100`).

### Results and settings

- Choose Automatic, Text only, or Result window. Detailed results show stored,
  ignored, and unstored items, and can be closed with mouse, keyboard, or
  controller.
- Press `F6` to open Quick Stack settings. With a compatible Pal Insight
  version, the same panel opens inside Pal Insight. All 17 Palworld interface
  languages are supported, and `0.1.0-beta.1` settings migrate automatically.

### Performance

- Shortened storage stutter and waiting time while keeping destination checks
  before every move. If a detailed result window cannot open safely, Quick
  Stack falls back to a text notification.

### Distribution

- Added separate Steam/Win64 and Xbox App / PC Game Pass / Microsoft Store
  WinGDK packages on Nexus Mods and CurseForge. WinGDK packaging passes static
  validation; representative Game Pass runtime acceptance remains unverified.

The core single-player storage flow has been tested. Multiplayer and
dedicated-server clients remain unverified.

## 0.1.0-beta.1 - 2026-08-30

### Initial beta

- Introduced standalone F5 quick storage for the normal backpack and current
  base.
- Added `Tab → R` ignored-item support, existing-stack priority, storage-filter
  checks, Incubator priority for Pal Eggs, and a permanent Guild Chest block.
- Added central progress notifications and a detailed result card for stored,
  ignored, and unstored items.
- Added Saved-directory shortcut configuration and an optional Pal Insight F6
  shortcut editor.
- Added all 17 Palworld interface languages.
- Split storage scans into bounded steps and serialized destination requests to
  reduce one-frame stalls and recheck state before each move.

Beta validation covered the core single-player ordinary-item flow. Full Pal Egg
coverage, narrow and tall result layouts, load-order combinations, multiplayer,
and dedicated-server clients remained unverified.
