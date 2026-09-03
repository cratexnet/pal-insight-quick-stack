[size=6][b]Pal Insight: Quick Stack[/b][/size]

[b]One key, one clean backpack.[/b]

Press [b]F5[/b] while standing inside your current base. Quick Stack moves matching items from your normal inventory into compatible storage in that base.

It is a standalone, client-side UE4SS Lua mod. [url=https://www.nexusmods.com/palworld/mods/4638]Pal Insight[/url] is optional.

[size=5][b]WHAT IT DOES[/b][/size]

[list]
[*]Uses only storage objects from the base you are currently inside.
[*]Respects Quick Move exclusions added through Inventory [b]Tab > R[/b] by default, with optional rules to include ignored items or always keep Pal Eggs.
[*]Can optionally use an accessible Guild Chest in the current guild base. This setting is off by default.
[*]Prefers incubators for eligible Pal Eggs, then existing matching stacks, then compatible private storage whose filters accept the item.
[*]Shows a native-style result card for items stored, items excluded by you, and items that could not be stored because of storage space or settings.
[*]Follows Palworld's current interface language across all 17 languages included with the game.
[*]Splits work into bounded slices and serializes destination requests to keep frame-time work bounded.
[/list]

[size=5][b]REQUIREMENTS[/b][/size]

[list]
[*]Palworld 1.0 on Steam, or the Xbox App / PC Game Pass / Microsoft Store WinGDK build.
[*][url=https://github.com/Okaetsu/RE-UE4SS/releases/tag/experimental-palworld][b]The experimental Palworld build of RE-UE4SS[/b][/url] — required. Steam users may alternatively use its [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3625223587]Steam Workshop package[/url]; Game Pass users must install the WinGDK runtime manually.
[/list]

The current release has been tested in single-player on Steam. Game Pass, multiplayer, and dedicated-server client behavior have not yet been verified in game and are not claimed as supported by this release.

[size=5][b]INSTALLATION[/b][/size]

Choose the file that matches your game: the standard [b]Steam/Win64[/b] ZIP or
the separately named [b]Game Pass/WinGDK[/b] ZIP. The WinGDK package has passed
static package validation, but representative Game Pass runtime acceptance is
still unverified.

[list=1]
[*]Install the [url=https://github.com/Okaetsu/RE-UE4SS/releases/tag/experimental-palworld]experimental Palworld build of RE-UE4SS[/url] under [b]Win64[/b] for Steam or [b]WinGDK[/b] for Game Pass. Steam users may alternatively subscribe to its [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3625223587]Workshop package[/url].
[*]Extract the Quick Stack ZIP into the Palworld game folder that directly contains the [b]Pal[/b] directory.
[*]Start Palworld, enter one of your bases, and press [b]F5[/b].
[/list]

[b]Do not install Nexus, CurseForge, and Steam Workshop copies at the same time.[/b]

[size=5][b]SHORTCUT SETTINGS[/b][/size]

The default shortcut is [b]F5[/b].

Press [b]F6[/b] to open Quick Stack's own settings panel. You can change the
shortcut, notification style, storage rules, special-item routing, and World
Tree Holy Water minimum without editing files.

With [url=https://www.nexusmods.com/palworld/mods/4638][b]Pal Insight 2.0.0 or later[/b][/url]
active, open the same panel from:

[b]F6 > Extensions > Pal Insight: Quick Stack[/b]

Quick Stack remains fully functional without Pal Insight. If Pal Insight is
installed but disabled, [b]F6[/b] correctly opens the standalone Quick Stack
panel. Settings are stored in
[code]%LOCALAPPDATA%\Pal\Saved\PalInsightQuickStackSettings.lua[/code], so mod
updates do not overwrite them. Existing [code]PalInsightQuickStack-config.lua[/code]
settings from 0.1.x are imported automatically and the old file is left
unchanged.

[b]Storage routing[/b]

[list]
[*]Inventory [b]Tab > R[/b] ignored items, unless [code]IncludeExcludedItems[/code] is enabled
[*]Pal Eggs use incubators first; [code]PalEggRouting[/code] can keep any remainder in the inventory, fall back to ordinary storage, or leave all Pal Eggs for manual placement
[*]Ancient Civilization Relics use Ancient Relic Recyclers first; [code]RelicRouting[/code] can keep any remainder in the inventory, fall back to ordinary storage, or leave all relics for manual placement
[*]Each Ancient Relic Recycler is topped up to [code]WorldTreeHolyWaterMinimum[/code] World Tree Holy Water (default 10, range 1-100); the remainder follows ordinary-storage rules
[*][code]IncludeNewItems = false[/code] restricts ordinary storage to containers that already hold the same item; it does not disable empty incubators or recycler slots
[*][code]IncludeGuildChest = true[/code] allows an accessible Guild Chest in the current guild base; it is disabled by default
[/list]

These rules affect only the current Quick Stack job. [code]IncludeExcludedItems[/code] never modifies Palworld's ignored-item list.

[size=5][b]SAFETY AND BEHAVIOR[/b][/size]

[list]
[*]Only the normal player inventory and the current base are considered.
[*]Capacity, filters, permissions, exclusions, and destination identity are rechecked before each request.
[*]Quick Stack stops instead of guessing when the local player, base, permission, filter, capacity, or destination state cannot be verified.
[*]Avoid other inventory operations while the progress message is visible.
[/list]
