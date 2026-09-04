# Changelog

## Unreleased

### Added

- Added a default-off `IncludeSmallIncubators` setting to standalone and hosted
  settings. Large incubators are planned first; small incubators are used only
  after a bounded recheck finds no empty slots in the discovered large ones.
  Unreadable large-incubator state or a failed large request blocks this fallback.
  Small incubators with an egg or an unclaimed Pal are skipped. Manual egg
  placement and item exclusions remain respected. The reported small-only setup
  was confirmed working in game; the broader acceptance matrix remains pending.

### Changed

- Added bounded rereads for already-discovered ordinary storage and supported
  incubators when their container or slot data cannot be read. Unresolved
  targets are logged separately from capacity failures. This does not establish
  dedicated-server or co-op compatibility.

### Fixed

- Fixed the small-incubator option being omitted from each Quick Stack job's
  settings snapshot. Replaced the failing hatched-Pal utility call with the
  current native-equivalent character-ID check and preserved read-failure details.

## 1.1.0 - 2026-09-03

### Added

- Added a default-off `IncludeGuildChest` setting to the standalone and Pal
  Insight-hosted settings panels.
- When enabled, Quick Stack can use an accessible Guild Chest in the current
  guild base. Guild-role access, current-base ownership, shared-container
  identity, filters, permissions, capacity, and replication readiness are
  validated before moving items.

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
