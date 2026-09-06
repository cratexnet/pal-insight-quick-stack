# Changelog

## 1.4.0 - 2026-09-07

### Changed

- Quick Stack continues to work independently with F5. With Pal Insight
  installed, its settings are available under F6 → Extensions. Without Pal
  Insight, saved or default settings still apply, but cannot be changed in game.
- Quick Stack now uses Pal Insight's shared settings host and on-screen control
  guide while retaining its own settings page. Keeping common settings
  infrastructure in one place provides a consistent keyboard, mouse, and
  controller experience across companion mods, while reducing duplicated work
  and making future fixes easier to maintain.
- Opening Quick Stack settings now hides the underlying Pal Insight window,
  keeping the interface clear and focused. Returning from Quick Stack restores
  the previous Pal Insight page.
- Removed the separate About page while keeping release notes, restore defaults,
  and close controls. On Steam, a compact Like action appears in the settings
  header and disappears after a successful recommendation.
- Standardized result colors: green for success, yellow for warnings, red for
  errors, blue for processing, and neutral white when no action is needed.

### Fixed

- Fixed a handshake failure that could prevent the Quick Stack settings panel
  from opening through Pal Insight.

## 1.3.1 - 2026-09-05

### Added

- Added a default-on option to keep sale items in the backpack when no merchant
  is found. Disable it to send those items through normal storage rules instead.

### Changed

- Improved F5 result feedback with status-specific titles, one line per
  processing category, and clear reporting for unsold items. Automatic mode now
  opens detailed results when F5 is used from the inventory and shows a text
  notification elsewhere.

### Fixed

- Fixed automatic selling of configured high-value items, ammunition, Pal
  Spheres, and fishing bait. F5 now finds an available merchant automatically,
  reads Noble and Fine Furs passives from party Pals, and applies them to sale
  prices.
- Fixed dedicated food routing so the 5 cake types use Breeding Farms and other
  food uses Pal Food Boxes before cold and ordinary storage.
- Fixed a crash that could occur when closing Quick Stack settings with Esc or
  controller Back, including when the panel was opened from Pal Insight.

## 1.3.0 - 2026-09-05

### Added

- Added optional Medicine Rack priority for the 3 current medical supplies.
  When no usable Medicine Rack is available or all racks are full, items
  continue to ordinary storage. The option is disabled by default.
- Added dedicated food routing, enabled by default. The 5 cakes use Breeding
  Farms first, while other food uses Pal Food Boxes first; both routes continue
  through cold storage and then ordinary storage. Cakes never enter Pal Food
  Boxes, and Inventory `Tab → R` exclusions remain protected.

### Changed

- Reorganized settings into General, Automatic Sale, and Special Items tabs.
  Tabs support mouse, keyboard, and controller navigation, with visible arrow
  controls on both sides. Small-incubator usage and Holy Water quantity are
  displayed as child options of their corresponding routing settings.

## 1.2.0 - 2026-09-05

### Added

- Added automatic selling for four independently configurable item categories:
  9 high-value merchant items, 32 ammunition types, 10 Pal Sphere types, and
  4 fishing baits. Every category is disabled by default.
- Added icon-assisted keep lists for every sale category. Checked items are not
  sold, and item names follow all 17 supported game languages. The selectors
  support mouse, keyboard, and controller input.
- Automatic selling runs before Quick Stack storage. Items excluded through
  Inventory `Tab → R` are always protected, and sales use the selected result-
  display mode.
- Added localized release history, opened by selecting the version number in
  the settings header.

## 1.1.0 - 2026-09-05

### Added

- Added a default-off `IncludeSmallIncubators` setting to standalone and hosted
  settings. Large incubators are planned first; small incubators are used only
  after a bounded recheck finds no empty slots in the discovered large ones.
  Unreadable large-incubator state or a failed large request blocks this fallback.
  Small incubators with an egg or an unclaimed Pal are skipped. Manual egg
  placement and item exclusions remain respected.
- Added a default-off `IncludeGuildChest` setting to the standalone and Pal
  Insight-hosted settings panels. When enabled, Quick Stack can use an accessible
  Guild Chest in the current guild base after validating permissions and capacity.

### Changed

- Added bounded rereads for already-discovered ordinary storage and supported
  incubators when their container or slot data cannot be read. Unresolved
  targets are logged separately from capacity failures. This does not establish
  dedicated-server or co-op compatibility.

### Fixed

- Fixed the small-incubator option being omitted from each Quick Stack job's
  settings snapshot. Replaced the failing hatched-Pal utility call with the
  current native-equivalent character-ID check and preserved read-failure details.

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
  languages are supported, and `0.1.0` settings migrate automatically.

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

## 0.1.0 - 2026-08-30

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
