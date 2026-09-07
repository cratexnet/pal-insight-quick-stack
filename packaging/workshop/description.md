[h1]Pal Insight: Quick Stack - Move Backpack Items to Storage with One Key[/h1]

[b]Come home, press one key, and get back to the adventure.[/b]

Press [b]F5[/b] inside your current base. Quick Stack can sell selected items, then move eligible normal-backpack items into suitable storage in that base.

[img]https://staticdelivery.nexusmods.com/mods/6063/images/5474/5474-1788114023-1813187159.jpg[/img]

[h2]What's New in 1.4.0[/h2]

[list]
[*][b]Automatic selling fixed:[/b] F5 finds an available current-base merchant, sells configured valuables, ammunition, Pal Spheres, and bait, and applies Noble and Fine Furs from party Pals.
[*][b]Safe fallback:[/b] A new default-on option keeps sale items in the backpack when no merchant is found. Disable it to use normal storage rules.
[*][b]Clearer results:[/b] Status titles and one line per category. Automatic opens details from Inventory and shows text elsewhere.
[*][b]Routing and stability:[/b] Corrected cake and food priorities and a crash when closing Settings with Esc or controller Back, including from Pal Insight.
[/list]

Version 1.3.0 added Medicine Rack priority, dedicated food routing, and three-tab Settings.

[h2]All Features[/h2]

[b]Automatic selling[/b]

[list]
[*]Enable valuables, ammunition, Pal Spheres, and fishing bait separately
[*]Use icon-assisted keep lists with mouse, keyboard, or controller
[*]Keep all [b]Tab > R[/b] excluded items safe from selling
[*]Find a current-base merchant and apply party Noble and Fine Furs to sale prices
[*]Keep sale items in the backpack when no merchant is found by default, or use normal storage rules
[/list]

All categories are off by default. High-value items initially allow all 9 items; other categories keep everything.

[b]Quick storage[/b]

[list]
[*]Processes only the normal backpack and current base; leaves equipment, food slots, and Key Items untouched
[*]Respects [b]Tab > R[/b] exclusions by default
[*]Can include excluded items without changing Palworld's exclusion list
[*]Can allow new item types in compatible ordinary-storage slots
[*]Can use an accessible current-base Guild Chest when enabled
[*]Always checks capacity, permissions, and item filters
[/list]

[b]Dedicated storage routing[/b]

[list]
[*]Optionally send the 3 medical supplies to Medicine Racks first, then ordinary storage
[*]Send the 5 cakes to Breeding Farms first, then cold storage and ordinary storage
[*]Send other food to Pal Food Boxes first, then cold and ordinary storage; cakes never enter Pal Food Boxes
[*]Send Pal Eggs to Incubators only, Incubators then ordinary storage, or keep them for manual placement
[*]Optionally use small Incubators after large ones are full; Incubators with an egg or unclaimed Pal are skipped
[*]Send Ancient Civilization Relics to Recyclers only, Recyclers then ordinary storage, or keep them for manual placement
[*]Keep 1–100 World Tree Holy Water in each Recycler; default 10
[/list]

Medicine Rack priority is off by default; food routing is on. [b]Tab > R[/b] exclusions stay protected, so use them for food or dishes you want to keep.

[b]Results[/b]

[list]
[*]Automatic opens details from Inventory and text elsewhere; Text Only and Result Window force those modes
[*]Status titles and category lines show sold, stored, excluded, and unstored items
[*]Detailed results use native icons and localized names
[*]Fall back to text when the detailed window is unavailable
[/list]

Items count as sold or stored only after the backpack confirms the quantity decrease.

[h2]Settings and Pal Insight[/h2]

[list]
[*][b]F5[/b] — run selling and storage
[*][b]F6[/b] — open Quick Stack Settings when running standalone
[/list]

The [b]General[/b], [b]Automatic Sale[/b], and [b]Special Items[/b] tabs support mouse, keyboard, controller, and side arrows. Child options include small Incubators and Holy Water quantity. Settings survive Workshop updates and import existing 0.1.x data.

With [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3778493118][b]Pal Insight 2.0.0 or newer[/b][/url], open the same settings from:

[b]F6 > Extensions > Pal Insight: Quick Stack[/b]

Quick Stack still owns selling, movement, and settings. If Pal Insight is disabled, its standalone F6 panel remains available.

[url=https://steamcommunity.com/sharedfiles/filedetails/?id=3778493118][img]https://staticdelivery.nexusmods.com/mods/6063/images/4638/4638-1786447166-1320978993.jpg[/img][/url]

[h2]Language, Safety, and Performance[/h2]

[list]
[*]Supports all 17 interface languages with Palworld's native icons and names
[*]Searches only the current base and runs entirely on the client
[*]Uses bounded game-thread work and sends one destination request at a time
[*]Rechecks player, base, items, destination, filters, permissions, and capacity; stops if state changes
[/list]

Avoid other inventory actions while the in-progress message is visible.

[h2]Installation[/h2]

[url=https://steamcommunity.com/sharedfiles/filedetails/?id=3625223587][b]Required: UE4SS Experimental (Palworld)[/b][/url]

[olist]
[*]Subscribe to UE4SS Experimental and Pal Insight: Quick Stack.
[*]Enable both in [b]Palworld > Options > Mod Management[/b].
[*]Save, allow Palworld to restart, enter a base, and press F5.
[/olist]

[b]Use one Quick Stack installation channel only.[/b] Do not combine Workshop, Nexus, CurseForge, or Game Pass copies.

[h2]Compatibility[/h2]

[list]
[*]Steam single-player: Tested
[*]Pal Insight 2.0.0 integration: Supported
[*]Dedicated server: One tester reported successful client-side-only use; build and platform were not recorded
[*]Co-op: Not verified
[*]Game Pass/WinGDK: Package verified statically; in-game acceptance not verified
[/list]

[h2]Troubleshooting and Support[/h2]

[b]F5 does nothing:[/b] Confirm that you are inside a base, UE4SS and Quick Stack are enabled, the shortcut is correct, and only one Quick Stack copy is installed.

[b]Items were not sold or stored:[/b] Check the sale toggle, keep list, [b]Tab > R[/b], current-base merchant, routing, filters, permissions, and capacity.

Bug reports should include platform, versions, settings, reproduction steps, expected and actual results, the complete UE4SS log, and crash files.

[h2]Palworld Breeding Calculator[/h2]

Use the [url=https://cratex.app/games/palworld/breeding][b]CrateX.app Palworld Breeding Calculator[/b][/url] to import a save, compare routes using Pals you already own, or search general breeding combinations. Save processing runs locally in your browser and remains on your device.

[url=https://cratex.app/games/palworld/breeding][img]https://staticdelivery.nexusmods.com/mods/6063/images/4638/4638-1787096480-407403883.jpg[/img][/url]

[url=https://cratex.app/games/palworld/breeding][img]https://staticdelivery.nexusmods.com/mods/6063/images/4638/4638-1787598334-1162571780.png[/img][/url]

[url=https://www.nexusmods.com/palworld/mods/5474][b]Nexus Mods / Game Pass[/b][/url] | [url=https://www.curseforge.com/palworld/lua-code-mods/pal-insight-quick-stack][b]CurseForge[/b][/url] | [url=https://www.nexusmods.com/palworld/mods/5474?tab=logs][b]Complete Changelog[/b][/url]

For credits, open [b]F6 > About > Special Thanks[/b] in game.
