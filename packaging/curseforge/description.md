# Pal Insight: Quick Stack

**One key, one clean backpack.**

Press **F5** while standing inside your current base. Quick Stack moves matching items from your normal inventory into compatible storage in that base.

It is a standalone, client-side UE4SS Lua mod. [Pal Insight](https://www.curseforge.com/palworld/blueprint-code-mods/pal-insight) is optional.

## What it does

- Uses only storage objects from the base you are currently inside.
- Respects Quick Move exclusions added through Inventory **Tab > R** by default, with optional rules to include ignored items or always keep Pal Eggs.
- Can optionally use an accessible Guild Chest in the current guild base. This setting is off by default.
- Can optionally use empty small incubators after large incubators are full. Skips incubators with an egg or an unclaimed Pal. This setting is off by default.
- Prefers incubators for eligible Pal Eggs, then existing matching stacks, then compatible private storage whose filters accept the item.
- Shows a native-style result card for items stored, items excluded by you, and items that could not be stored because of storage space or settings.
- Follows Palworld's current interface language across all 17 languages included with the game.
- Splits work into bounded slices and serializes destination requests to keep frame-time work bounded.

## Requirements

- Palworld 1.0 on Steam, or the Xbox App / PC Game Pass / Microsoft Store WinGDK build.
- **[The experimental Palworld build of RE-UE4SS](https://github.com/Okaetsu/RE-UE4SS/releases/tag/experimental-palworld) — required.** Steam users may alternatively use its [Steam Workshop package](https://steamcommunity.com/sharedfiles/filedetails/?id=3625223587); Game Pass users must install the WinGDK runtime manually.

The correct Palworld UE4SS runtime is not currently available as a CurseForge Related Project, so install it from one of the official pages linked above.

The current release has been tested in single-player on Steam. A community tester also confirmed that it worked without issue on a dedicated server with the mod installed client-side only. The tester's game build and distribution platform were not recorded; Game Pass and co-op behavior have not yet been verified in game.

## Installation

Choose the file that matches your game: the standard **Steam/Win64** ZIP or the
separately named **Game Pass/WinGDK** ZIP. The WinGDK package has passed static
package validation, but representative Game Pass runtime acceptance is still
unverified.

1. Install the [experimental Palworld build of RE-UE4SS](https://github.com/Okaetsu/RE-UE4SS/releases/tag/experimental-palworld) under **Win64** for Steam or **WinGDK** for Game Pass. Steam users may alternatively subscribe to its [Workshop package](https://steamcommunity.com/sharedfiles/filedetails/?id=3625223587).
2. On Steam, use the CurseForge App or extract the standard ZIP. On Game Pass, manually extract the separately named Game Pass ZIP. In both cases, use the Palworld game folder that directly contains the **Pal** directory.
3. Start Palworld, enter one of your bases, and press **F5**.

**Do not install CurseForge, Nexus, and Steam Workshop copies at the same time.**

## Shortcut settings

The default shortcut is **F5**.

Press **F6** to open Quick Stack's own settings panel. You can change the
shortcut, notification style, storage rules, special-item routing, and World
Tree Holy Water minimum without editing files.

With **[Pal Insight 2.0.0 or later](https://www.curseforge.com/palworld/blueprint-code-mods/pal-insight)**
active, open the same panel from:

**F6 > Extensions > Pal Insight: Quick Stack**

Quick Stack remains fully functional without Pal Insight. If Pal Insight is
installed but disabled, **F6** correctly opens the standalone Quick Stack
panel. Settings are stored in
`%LOCALAPPDATA%\Pal\Saved\PalInsightQuickStackSettings.lua`, so mod updates do
not overwrite them. Existing `PalInsightQuickStack-config.lua` settings from
0.1.x are imported automatically and the old file is left unchanged.

**Storage routing**

- Inventory **Tab > R** ignored items are respected unless `IncludeExcludedItems` is enabled.
- Pal Eggs use incubators first; `PalEggRouting` can keep any remainder in the inventory, fall back to ordinary storage, or leave all Pal Eggs for manual placement.
- Ancient Civilization Relics use Ancient Relic Recyclers first; `RelicRouting` can keep any remainder in the inventory, fall back to ordinary storage, or leave all relics for manual placement.
- Each Ancient Relic Recycler is topped up to `WorldTreeHolyWaterMinimum` World Tree Holy Water (default 10, range 1-100); the remainder follows ordinary-storage rules.
- `IncludeNewItems = false` restricts ordinary storage to containers that already hold the same item; it does not disable empty incubators or recycler slots.
- `IncludeGuildChest = true` allows an accessible Guild Chest in the current guild base; it is disabled by default.

These rules affect only the current Quick Stack job. `IncludeExcludedItems` never modifies Palworld's ignored-item list.

## Safety and behavior

- Only the normal player inventory and the current base are considered.
- Capacity, filters, permissions, exclusions, and destination identity are rechecked before each request.
- Quick Stack stops instead of guessing when the local player, base, permission, filter, capacity, or destination state cannot be verified.
- Avoid other inventory operations while the progress message is visible.
