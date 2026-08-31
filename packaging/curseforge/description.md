# Pal Insight: Quick Stack

**One key, one clean backpack.**

Press **F5** while standing inside your current base. Quick Stack moves matching items from your normal inventory into compatible **private storage** in that base.

It is a standalone, client-side UE4SS Lua mod. [Pal Insight](https://www.curseforge.com/palworld/blueprint-code-mods/pal-insight) is optional.

## What it does

- Uses only storage objects from the base you are currently inside.
- Respects Quick Move exclusions added through Inventory **Tab > R** by default, with optional rules to include ignored items or always keep Pal Eggs.
- Never selects Guild Chests as automatic destinations.
- Prefers incubators for eligible Pal Eggs, then existing matching stacks, then compatible private storage whose filters accept the item.
- Shows a native-style result card for items stored, items excluded by you, and items that could not be stored because of storage space or settings.
- Follows Palworld's current interface language across all 17 languages included with the game.
- Splits work into bounded slices and serializes destination requests to keep frame-time work bounded.

## Requirements

- Palworld 1.0 on Steam.
- **[The experimental Palworld build of RE-UE4SS](https://github.com/Okaetsu/RE-UE4SS/releases/tag/experimental-palworld) — required.** A [Steam Workshop package](https://steamcommunity.com/sharedfiles/filedetails/?id=3625223587) is also available.

The correct Palworld UE4SS runtime is not currently available as a CurseForge Related Project, so install it from one of the official pages linked above.

The current Beta has been tested in single-player. Multiplayer and dedicated-server client behavior have not yet been verified and are not claimed as supported by this release.

## Installation

1. Install the [experimental Palworld build of RE-UE4SS](https://github.com/Okaetsu/RE-UE4SS/releases/tag/experimental-palworld), or subscribe to its [Steam Workshop package](https://steamcommunity.com/sharedfiles/filedetails/?id=3625223587).
2. Install Quick Stack with the CurseForge App, or extract the ZIP into the Palworld game folder that directly contains the **Pal** directory.
3. Start Palworld, enter one of your bases, and press **F5**.

**Do not install CurseForge, Nexus, and Steam Workshop copies at the same time.**

## Shortcut settings

The default shortcut is **F5**.

For standalone use, close the game and open:

```text
%LOCALAPPDATA%\Pal\Saved\PalInsightQuickStackSettings.lua
```

Change **Key**, **Shift**, **Ctrl**, **Alt**, **ResultDisplay**, **IncludeExcludedItems**, **IncludeNewItems**, **PalEggRouting**, **RelicRouting**, or **WorldTreeHolyWaterMinimum**, save the file, then restart the game. `ResultDisplay` accepts `Default` (automatic), `TextOnly`, or `ResultWindow`. The result window requires a compatible Pal Insight and otherwise falls back safely to center-screen text. Mod updates do not overwrite this Saved-directory configuration.
Existing `PalInsightQuickStack-config.lua` settings from 0.1.x are imported automatically and the old file is left unchanged.

With a compatible [Pal Insight](https://www.curseforge.com/palworld/blueprint-code-mods/pal-insight) version installed, press **F6** and open:

**[Controls > Pal Insight: Quick Stack](https://www.curseforge.com/palworld/blueprint-code-mods/pal-insight)**

[Pal Insight](https://www.curseforge.com/palworld/blueprint-code-mods/pal-insight) lets you change the shortcut and all six Quick Stack settings in game. Quick Stack remains fully functional without it.

**Storage routing**

- Inventory **Tab > R** ignored items are respected unless `IncludeExcludedItems` is enabled.
- Pal Eggs use incubators first; `PalEggRouting` chooses whether any remainder stays in the inventory or falls back to ordinary storage.
- Ancient Civilization Relics use Ancient Relic Recyclers first; `RelicRouting` chooses whether any remainder stays in the inventory or falls back to ordinary storage.
- Each Ancient Relic Recycler is topped up to `WorldTreeHolyWaterMinimum` World Tree Holy Water (default 10, range 1-100); the remainder follows ordinary-storage rules.
- `IncludeNewItems = false` restricts ordinary storage to containers that already hold the same item; it does not disable empty incubators or recycler slots.

These rules affect only the current Quick Stack job. `IncludeExcludedItems` never modifies Palworld's ignored-item list.

## Safety and behavior

- Only the normal player inventory and the current base are considered.
- Capacity, filters, permissions, exclusions, and destination identity are rechecked before each request.
- Quick Stack stops instead of guessing when the local player, base, permission, filter, capacity, or destination state cannot be verified.
- Avoid other inventory operations while the progress message is visible.
