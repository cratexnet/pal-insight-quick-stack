[center][size=6][b]Pal Insight: Quick Stack[/b][/size][/center]
[center][/center]
[center][b]One key, one clean backpack.[/b][/center]
[center][/center]
[center]Press [b]F5[/b] while inside your current base. Quick Stack can automatically sell configured items, then moves eligible items from your normal backpack into compatible private storage, Incubators, Ancient Relic Recyclers, and optionally an accessible Guild Chest in that base.[/center]
[center][/center]
[center]Quick Stack is a standalone, client-side UE4SS Lua mod. [url=https://www.nexusmods.com/palworld/mods/4638][b]Pal Insight[/b][/url] is optional.[/center]

[center][img]https://staticdelivery.nexusmods.com/mods/6063/images/5474/5474-1788399721-964224582.png[/img][/center]

[size=5][b]WHAT'S NEW IN 1.4.0[/b][/size]

[list]
[*][b]Automatic selling fixed:[/b] F5 now finds an available merchant in the current base automatically and applies Noble and Fine Furs passives from party Pals to sale prices for configured valuables, ammunition, Pal Spheres, and fishing bait.[/*]
[*][b]Safe merchant fallback:[/b] A new default-on option keeps sale items in the backpack when no merchant is found. Disable it to send those items through normal storage rules instead.[/*]
[*][b]Clearer results:[/b] Results now use status-specific titles and one line per processing category. Automatic mode opens detailed results when F5 is used from the inventory and shows a text notification elsewhere.[/*]
[*][b]Routing and stability fixes:[/b] Corrected dedicated food routing so the 5 cake types use Breeding Farms and other food uses Pal Food Boxes before cold and ordinary storage, and fixed a crash when closing Quick Stack settings with Esc or controller Back.[/*]
[/list]

Version 1.3.0 added Medicine Rack priority, dedicated food routing, and General, Automatic Sale, and Special Items settings tabs.

Version 1.2.0 added optional automatic selling for 9 high-value merchant items, 32 ammunition types, 10 Pal Sphere types, and 4 fishing baits, with icon-assisted keep lists and localized release history.

Version 1.1.0 added optional, default-off support for accessible Guild Chests and small Incubators. Large Incubators are used first, and small Incubators containing an egg or an unclaimed Pal are skipped.

Settings from [b]0.1.x[/b] are migrated automatically.

[size=5][b]QUICK START[/b][/size]

[list=1]
[*]Install the [url=https://github.com/Okaetsu/RE-UE4SS/releases/tag/experimental-palworld][b]experimental Palworld build of RE-UE4SS[/b][/url].[/*]
[*]Download the package matching your game: [b]Steam/Win64[/b] or [b]Game Pass/WinGDK[/b].[/*]
[*]Extract it into the Palworld game folder that directly contains the [b]Pal[/b] directory.[/*]
[*]Enter one of your bases and press [b]F5[/b].[/*]
[/list]

Press [b]F6[/b] to open Quick Stack Settings.

[b]Use one installation channel only.[/b] Do not combine Nexus Mods, CurseForge, or Steam Workshop copies, and do not mix Win64 and WinGDK packages.

Close Palworld completely before installing or updating.

[size=5][b]WHAT QUICK STACK MOVES[/b][/size]

Quick Stack handles the normal backpack inventory only. It does not move equipped items, food-slot items, key items, or items outside the supported inventory area.

It uses storage facilities from [b]your current base only[/b]. Guild Chests are not selected by default; when the optional setting is enabled, Quick Stack may use an accessible Guild Chest in the current guild base.

By default:

[list]
[*]Items ignored through Inventory [b]Tab > R[/b] stay in your backpack.[/*]
[*]Compatible private storage may receive eligible item types even when it does not already contain the same item.[/*]
[*]Guild Chests are not used.[/*]
[*]Large Incubators may receive eligible Pal Eggs.[/*]
[*]Small Incubators are not used.[/*]
[*]Pal Eggs use available Incubators only.[/*]
[*]Ancient Civilization Relics use Ancient Relic Recyclers only.[/*]
[*]Each Recycler keeps 10 World Tree Holy Water.[/*]
[*]Medicine Rack priority is disabled.[/*]
[*]The 5 cakes use Breeding Farms first, then cold storage and ordinary storage; cakes never enter Pal Food Boxes.[/*]
[*]Other food uses Pal Food Boxes first, then cold storage and ordinary storage.[/*]
[*]All four automatic-sale categories are disabled.[/*]
[/list]

Quick Stack never changes Palworld's ignored-item list.

[size=5][b]AUTOMATIC SELLING[/b][/size]

Automatic selling is optional and runs before Quick Stack storage.

The four independently configurable categories are:

[list]
[*]9 high-value merchant items[/*]
[*]32 ammunition types[/*]
[*]10 Pal Sphere types[/*]
[*]4 fishing baits[/*]
[/list]

Every category is disabled by default.

Each category has an icon-assisted keep list. Checked items stay in your backpack and are not sold. Items excluded through Inventory [b]Tab > R[/b] are always protected from selling.

The selectors use Palworld's native item icons and localized names. They support mouse, keyboard, and controller input.

The high-value category initially allows all 9 supported items to be sold when enabled. Ammunition, Pal Sphere, and fishing-bait categories initially keep all supported items until their sale selections are changed.

Review the keep list before enabling a category.

Enabling storage of ignored items does not make those items eligible for automatic selling.

F5 searches the current base for an available merchant. Sale prices include Noble and Fine Furs passives from party Pals. If no merchant is found, sale items stay in the backpack by default; disable [b]Keep sale items when no merchant is found[/b] to let them continue through normal storage rules.

[size=5][b]CONFIGURABLE STORAGE RULES[/b][/size]

From F6 Settings, configure whether Quick Stack may also store or prioritize:

[list]
[*]Items currently marked as ignored[/*]
[*]Item types not already present in ordinary storage[/*]
[*]Items in an accessible Guild Chest in the current guild base[/*]
[*]Pal Eggs in supported small Incubators after large Incubators are full[/*]
[*]The 3 current medical supplies in Medicine Racks before ordinary storage[/*]
[*]The 5 cakes in Breeding Farms before cold and ordinary storage[/*]
[*]Other food in Pal Food Boxes before cold and ordinary storage[/*]
[/list]

[b]Guild Chests[/b]

Guild Chest support is disabled by default. When enabled, Quick Stack may use an accessible Guild Chest in the current guild base after validating access permission and capacity.

[b]Medical supplies[/b]

Medicine Rack priority is disabled by default. When enabled, the 3 current medical supplies use Medicine Racks first. If no usable Medicine Rack is available or all racks are full, those items continue to ordinary storage.

[b]Food and cakes[/b]

Dedicated food routing is enabled by default.

The 5 cakes use Breeding Farms first, then cold storage and ordinary storage when no usable Breeding Farm has room. Cakes never enter Pal Food Boxes.

Other food uses Pal Food Boxes first, then cold storage and ordinary storage when no usable Pal Food Box has room.

Use Inventory [b]Tab > R[/b] to keep a food type in your backpack. Excluded food and cakes remain protected from every storage route.

[b]Pal Eggs[/b]

[list]
[*][b]Incubator only[/b] — default[/*]
[*][b]Incubator, then regular storage[/b][/*]
[*][b]Manual placement[/b] — leave Pal Eggs in the backpack[/*]
[/list]

Small-Incubator support is disabled by default.

When enabled, large Incubators take priority. Small Incubators are considered only after a bounded recheck finds no empty slots in the discovered large Incubators.

Small Incubators containing an egg or an unclaimed Pal are skipped. Unreadable large-Incubator state or a failed large-Incubator request blocks the small-Incubator fallback.

[b]Ancient Civilization Relics[/b]

[list]
[*][b]Recycler only[/b] — default[/*]
[*][b]Recycler, then regular storage[/b][/*]
[*][b]Manual placement[/b] — leave Relics in the backpack[/*]
[/list]

The World Tree Holy Water reserve for each Recycler can be set from [b]1 to 100[/b]. The default is [b]10[/b]; any remainder follows the ordinary-storage rules.

Disabling storage of new item types affects ordinary storage only. It does not prevent Pal Eggs from entering empty Incubators or Relics from entering empty Recycler slots.

[size=5][b]RESULT DISPLAY[/b][/size]

Choose one of three result modes:

[list]
[*][b]Automatic[/b][/*]
[*][b]Text only[/b][/*]
[*][b]Result window[/b][/*]
[/list]

Automatic mode opens the detailed result window when F5 is triggered from the Inventory screen and shows a text notification elsewhere. Text only always uses text, while Result window requests the detailed panel everywhere.

Automatic selling uses the same selected result-display mode as storage.

The detailed panel lists sold, stored, excluded, and unstored items with Palworld's native icons and localized names. It supports mouse, keyboard, and controller input. If the panel cannot open safely, Quick Stack falls back to a text notification.

An item is reported as sold or stored only after the backpack confirms that its quantity decreased.

[size=5][b]SETTINGS AND PAL INSIGHT[/b][/size]

Quick Stack owns one complete settings panel and remains fully functional without Pal Insight.

[list]
[*][b]Quick Stack alone:[/b] Press F6 to open Quick Stack Settings.[/*]
[*][b]Pal Insight installed but disabled:[/b] F6 still opens the standalone Quick Stack panel.[/*]
[*][b]Both mods active:[/b] Pal Insight owns F6. Open [b]F6 > Extensions > Pal Insight: Quick Stack[/b].[/*]
[/list]

Settings are organized into General, Automatic Sale, and Special Items tabs. Use the mouse, keyboard, controller, or the arrow controls on both sides of the tab row to navigate.

Pal Insight opens Quick Stack's own panel; it does not copy the controls, sell or move items, or own Quick Stack's settings.

Use [url=https://www.nexusmods.com/palworld/mods/4638][b]Pal Insight 2.0.0 or later[/b][/url] for current integration.

[center][url=https://www.nexusmods.com/palworld/mods/4638][img]https://staticdelivery.nexusmods.com/mods/6063/images/4638/4638-1786447166-1320978993.jpg[/img][/url][/center]

Select the version number in the Quick Stack settings header to open the localized release history.

Settings are stored at:

[code]%LOCALAPPDATA%\Pal\Saved\PalInsightQuickStackSettings.lua[/code]

This keeps them safe from normal mod updates. Existing [b]0.1.x[/b] settings are imported automatically, and the old configuration file is left unchanged.

[size=5][b]REQUIREMENTS AND PACKAGES[/b][/size]

[b]Steam / Win64[/b]

[list]
[*]Palworld 1.0 or later[/*]
[*][url=https://github.com/Okaetsu/RE-UE4SS/releases/tag/experimental-palworld]Experimental Palworld build of RE-UE4SS[/url][/*]
[/list]

Steam users may alternatively install the [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3625223587]UE4SS Steam Workshop package[/url].

[b]Xbox App / PC Game Pass / Microsoft Store — WinGDK[/b]

[list]
[*]Use the archive explicitly marked [b]Game Pass/WinGDK[/b].[/*]
[*]Install the matching Palworld UE4SS runtime under WinGDK.[/*]
[*]The package has passed static packaging validation, but representative Game Pass runtime acceptance remains unverified.[/*]
[/list]

The standard Win64 archive is not a Game Pass package.

[size=5][b]SAFETY AND PERFORMANCE[/b][/size]

Before every sale or item move, Quick Stack rechecks the applicable local player, current base, source item, destination identity, filters, permissions, exclusions, and capacity.

Storage work is split into bounded steps, and destination requests are serialized instead of being sent all at once. A run stops when required state can no longer be verified—for example after leaving the base, changing worlds, or changing characters.

Avoid other inventory operations while the progress notification is visible.

[size=5][b]COMPATIBILITY STATUS[/b][/size]

[list]
[*][b]Core single-player storage flow on Steam:[/b] Tested[/*]
[*][b]All 17 Palworld interface languages:[/b] Supported[/*]
[*][b]Pal Insight 2.0.0 integration:[/b] Supported[/*]
[*][b]Multiplayer clients:[/b] Not fully verified[/*]
[*][b]Dedicated-server client:[/b] One community tester reported successful use with Quick Stack installed client-side only. The tester's game build and distribution platform were not recorded, so this does not establish comprehensive dedicated-server compatibility.[/*]
[*][b]Representative Game Pass runtime acceptance:[/b] Not yet verified[/*]
[/list]

[size=5][b]TROUBLESHOOTING[/b][/size]

[b]F5 does nothing[/b]

[list]
[*]Confirm that your character is inside a base.[/*]
[*]Open F6 Settings and verify the current Quick Stack shortcut.[/*]
[*]Make sure the package matches Win64 or WinGDK.[/*]
[*]Confirm that only one Quick Stack installation channel is present.[/*]
[*]Check that UE4SS loaded Quick Stack successfully.[/*]
[/list]

[b]An item was not sold[/b]

[list]
[*]Confirm that its automatic-sale category is enabled.[/*]
[*]Check whether the item is selected in the category's keep list.[/*]
[*]Check whether the item is excluded through Inventory [b]Tab > R[/b].[/*]
[*]Confirm that the item belongs to one of the supported automatic-sale categories.[/*]
[*]Make sure an available merchant is present in the current base. The F5 result reports when none is found.[/*]
[/list]

[b]Some items remain in the backpack[/b]

Check the Inventory [b]Tab > R[/b] ignore state, Quick Stack's ignored-item and new-item settings, Guild Chest, Medicine Rack, food-routing and small-Incubator settings, Pal Egg and Relic routing, storage filters, permissions, and available capacity.

Items outside the normal backpack are intentionally not handled.

[b]Reporting a problem[/b]

Include your platform, installation channel, single-player/multiplayer status, Quick Stack and Pal Insight versions, relevant automatic-sale and storage settings, expected result, actual result, and the complete [b]UE4SS.log[/b] when available.

For a crash, also attach the original [b].dmp[/b] and runtime/crash XML when available.

Upload original files rather than an AI summary or selected lines.

[size=5][b]PALWORLD BREEDING CALCULATOR[/b][/size]

Planning a breeding project? Try the [url=https://cratex.app/games/palworld/breeding][b]Palworld Breeding Calculator[/b][/url] from CrateX.app. Use an imported save to plan routes from your party, Palbox, and base workers, or search general breeding combinations without importing a save. Imported data is processed locally on your device.

[center][url=https://cratex.app/games/palworld/breeding][img]https://staticdelivery.nexusmods.com/mods/6063/images/4638/4638-1787096480-407403883.jpg[/img][/url][/center]

[center][url=https://cratex.app/games/palworld/breeding][img]https://staticdelivery.nexusmods.com/mods/6063/images/4638/4638-1787598334-1162571780.png[/img][/url][/center]

[size=5][b]DOWNLOADS[/b][/size]

[url=https://www.nexusmods.com/palworld/mods/5474][b]Nexus Mods[/b][/url] | [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3792968111][b]Steam Workshop[/b][/url] | [url=https://www.curseforge.com/palworld/lua-code-mods/pal-insight-quick-stack][b]CurseForge[/b][/url]

[size=5][b]ACKNOWLEDGEMENTS[/b][/size]

For the complete and up-to-date credits list, open [b]F6 > About > Special Thanks[/b] in game.
