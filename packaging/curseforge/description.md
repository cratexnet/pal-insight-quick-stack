<h1 style="text-align: center;">Pal Insight: Quick Stack</h1>
<p style="text-align: center;"><strong>One key, one clean backpack.</strong></p>
<p style="text-align: center;">Press <strong>F5</strong> while standing inside your current base. Quick Stack can sell selected items, then move eligible items from your normal backpack into compatible storage in that base.</p>
<p style="text-align: center;">It is a standalone, client-side UE4SS Lua mod. <a href="https://www.curseforge.com/palworld/blueprint-code-mods/pal-insight" rel="nofollow">Pal Insight</a> is optional.</p>
<p><img src="https://media.forgecdn.net/attachments/1917/542/pal-insight-quick-stack-promo-final-png.png" alt="Pal Insight: Quick Stack"></p>
<h2>What's New in 1.4.0</h2>
<ul>
<li><strong>Automatic selling fixed:</strong> F5 now finds an available merchant in the current base automatically and applies Noble and Fine Furs passives from party Pals to sale prices for configured valuables, ammunition, Pal Spheres, and fishing bait.</li>
<li><strong>Safe merchant fallback:</strong> A new default-on option keeps sale items in the backpack when no merchant is found. Disable it to send those items through normal storage rules instead.</li>
<li><strong>Clearer results:</strong> Results now use status-specific titles and one line per processing category. Automatic mode opens detailed results when F5 is used from the inventory and shows a text notification elsewhere.</li>
<li><strong>Routing and stability fixes:</strong> Corrected dedicated food routing so the 5 cake types use Breeding Farms and other food uses Pal Food Boxes before cold and ordinary storage, and fixed a crash when closing Quick Stack settings with Esc or controller Back.</li>
</ul>
<p>Version 1.3.0 added Medicine Rack priority, dedicated food routing, and General, Automatic Sale, and Special Items settings tabs.</p>
<p>Version 1.2.0 added automatic selling for 9 high-value items, 32 ammunition types, 10 Pal Sphere types, and 4 fishing baits; icon-assisted keep lists; safe sale-before-storage ordering; and localized release history.</p>
<p>Version 1.1.0 added optional Guild Chest and small-Incubator support. Both are off by default.</p>
<h2>Quick Start</h2>
<ol>
<li>Install the <a href="https://github.com/Okaetsu/RE-UE4SS/releases/tag/experimental-palworld" rel="nofollow">experimental Palworld build of RE-UE4SS</a>.</li>
<li>Download the package matching your game: <strong>Steam/Win64</strong> or <strong>Game Pass/WinGDK</strong>.</li>
<li>Extract it into the Palworld game folder that directly contains the <strong>Pal</strong> directory.</li>
<li>Enter one of your bases and press <strong>F5</strong>.</li>
</ol>
<p>Press <strong>F6</strong> to open Quick Stack Settings.</p>
<p><strong>Use one installation channel only.</strong> Do not combine CurseForge, Nexus Mods, or Steam Workshop copies, and do not mix Win64 and WinGDK packages. Close Palworld completely before installing or updating.</p>
<h2>Automatic Selling</h2>
<p>Quick Stack can sell the following categories before storage:</p>
<ul>
<li>9 high-value merchant items</li>
<li>32 ammunition types</li>
<li>10 Pal Sphere types</li>
<li>4 fishing baits</li>
</ul>
<p>Each category is configured independently and disabled by default. Icon-assisted keep lists support all 17 Palworld interface languages and mouse, keyboard, and controller input.</p>
<p>Checked items are kept. Items excluded through Inventory <strong>Tab &gt; R</strong> are always protected from selling.</p>
<p>Review each keep list before enabling it. The high-value category initially allows all 9 supported items to be sold; the other categories initially keep all supported items.</p>
<p>F5 searches the current base for an available merchant. Sale prices include Noble and Fine Furs passives from party Pals. If no merchant is found, sale items stay in the backpack by default; disable <strong>Keep sale items when no merchant is found</strong> to let them continue through normal storage rules.</p>
<h2>What Quick Stack Moves</h2>
<p>Quick Stack handles the normal backpack inventory only. It does not move equipped items, food-slot items, Key Items, or items outside the supported inventory area.</p>
<p>It uses storage facilities from <strong>your current base only</strong>. By default:</p>
<ul>
<li>Items ignored through Inventory <strong>Tab &gt; R</strong> stay in your backpack.</li>
<li>Compatible ordinary storage may receive eligible item types even when it does not already contain the same item.</li>
<li>Pal Eggs use available Incubators only.</li>
<li>Ancient Civilization Relics use Ancient Relic Recyclers only.</li>
<li>Each Recycler keeps 10 World Tree Holy Water.</li>
<li>Food uses dedicated routing: the 5 cakes prefer Breeding Farms, while other food prefers Pal Food Boxes; both continue through cold storage and ordinary storage.</li>
<li>Medicine Rack priority, Guild Chests, and small Incubators are disabled.</li>
</ul>
<p>Quick Stack never changes Palworld's ignored-item list.</p>
<h2>Configurable Storage Rules</h2>
<p>From F6 Settings, choose whether Quick Stack may also store:</p>
<ul>
<li>Items currently marked as ignored</li>
<li>Item types not already present in ordinary storage</li>
<li>Items in an accessible Guild Chest belonging to the current guild base</li>
</ul>
<h3>Medical Supplies</h3>
<p>Enable Medicine Rack priority to route the 3 current medical supplies to a usable Medicine Rack first. If no rack is available or all racks are full, the items continue to ordinary storage. This option is disabled by default.</p>
<h3>Food</h3>
<p>Dedicated food routing is enabled by default:</p>
<ul>
<li>The 5 cakes use Breeding Farms first, then cold storage, then ordinary storage.</li>
<li>Other food uses Pal Food Boxes first, then cold storage, then ordinary storage.</li>
<li>Cakes never enter Pal Food Boxes.</li>
</ul>
<p>Inventory <strong>Tab &gt; R</strong> exclusions remain protected, so use them for food or dishes you want to keep in your backpack.</p>
<h3>Pal Eggs</h3>
<ul>
<li><strong>Incubator only</strong> &mdash; default</li>
<li><strong>Incubator, then regular storage</strong></li>
<li><strong>Manual placement</strong> &mdash; leave Pal Eggs in the backpack</li>
</ul>
<p>Large Incubators are used first. When enabled, empty small Incubators are used after the large ones are full. Incubators containing an egg or an unclaimed Pal are skipped.</p>
<h3>Ancient Civilization Relics</h3>
<ul>
<li><strong>Recycler only</strong> &mdash; default</li>
<li><strong>Recycler, then regular storage</strong></li>
<li><strong>Manual placement</strong> &mdash; leave Relics in the backpack</li>
</ul>
<p>The World Tree Holy Water reserve for each Recycler can be set from <strong>1 to 100</strong>. The default is <strong>10</strong>; any remainder follows ordinary-storage rules.</p>
<p>Disabling storage of new item types affects ordinary storage only. It does not prevent dedicated routes from using an empty compatible destination.</p>
<h2>Result Display</h2>
<ul>
<li><strong>Automatic</strong></li>
<li><strong>Text Only</strong></li>
<li><strong>Result Window</strong></li>
</ul>
<p>Automatic mode opens the detailed result window when F5 is triggered from the Inventory screen and shows a text notification elsewhere. Text Only always uses text, while Result Window requests the detailed panel everywhere.</p>
<p>Results show sold, stored, excluded, and unstored items. The detailed window uses Palworld's native icons and localized names and supports mouse, keyboard, and controller input.</p>
<p>If the detailed window cannot open safely, Quick Stack falls back to a text notification. An item is reported as sold or stored only after the backpack confirms that its quantity decreased.</p>
<p><img src="https://media.forgecdn.net/attachments/1917/550/01-quick-stack-results-png.png" alt="Quick Stack result window"></p>
<h2>Settings and Pal Insight</h2>
<p>Quick Stack owns one complete settings panel and remains fully functional without Pal Insight.</p>
<ul>
<li><strong>Quick Stack alone:</strong> Press F6 to open Quick Stack Settings.</li>
<li><strong>Pal Insight installed but disabled:</strong> F6 still opens the standalone Quick Stack panel.</li>
<li><strong>Both mods active:</strong> Open <strong>F6 &gt; Extensions &gt; Pal Insight: Quick Stack</strong>.</li>
<li><strong>F5:</strong> Runs Quick Stack's selling and storage action.</li>
</ul>
<p>Settings are organized into <strong>General</strong>, <strong>Automatic Sale</strong>, and <strong>Special Items</strong> tabs. Use the mouse, keyboard, controller, or the visible arrows on both sides to change tabs. Small-Incubator usage and World Tree Holy Water quantity are shown as child options of their corresponding routing settings.</p>
<p>Configure the shortcut, result style, automatic selling, keep lists, ordinary-storage rules, Medicine Rack priority, food routing, Guild Chest, small Incubators, Pal Egg routing, Relic routing, and World Tree Holy Water reserve in game.</p>
<p>Pal Insight opens Quick Stack's own panel; it does not copy the controls, move items, or own Quick Stack's settings. Use <a href="https://www.curseforge.com/palworld/blueprint-code-mods/pal-insight" rel="nofollow">Pal Insight 2.0.0 or later</a> for current integration.</p>
<p><a href="https://www.curseforge.com/palworld/blueprint-code-mods/pal-insight" rel="nofollow"><img src="https://staticdelivery.nexusmods.com/mods/6063/images/4638/4638-1786447166-1320978993.jpg" alt="Pal Insight feature overview"></a></p>
<p>Settings are stored at <code>%LOCALAPPDATA%\Pal\Saved\PalInsightQuickStackSettings.lua</code>. Mod updates do not overwrite them. Existing 0.1.x settings are imported automatically, and the old configuration file is left unchanged.</p>
<p><img src="https://media.forgecdn.net/attachments/1917/548/02-quick-stack-settings-png.png" alt="Quick Stack settings"></p>
<h2>Requirements and Packages</h2>
<h3>Steam / Win64</h3>
<ul>
<li>Palworld 1.0 or later</li>
<li><a href="https://github.com/Okaetsu/RE-UE4SS/releases/tag/experimental-palworld" rel="nofollow">Experimental Palworld build of RE-UE4SS</a></li>
</ul>
<p>Steam users may alternatively install the <a href="https://steamcommunity.com/sharedfiles/filedetails/?id=3625223587" rel="nofollow">UE4SS Steam Workshop package</a>.</p>
<p>The correct Palworld UE4SS runtime is not currently available as a CurseForge Related Project, so install it from one of the official pages above.</p>
<h3>Xbox App / PC Game Pass / Microsoft Store &mdash; WinGDK</h3>
<p>Use the additional archive explicitly marked <strong>Game Pass/WinGDK</strong> and install it manually. The CurseForge App's Palworld support targets Steam.</p>
<p>The WinGDK package has passed static package validation, but representative Game Pass runtime acceptance remains unverified. The standard Win64 archive is not a Game Pass package.</p>
<h2>Safety and Performance</h2>
<p>Before every sale or item move, Quick Stack rechecks the local player, current base, source item, destination, storage filters, permissions, exclusions, and capacity.</p>
<p>Work is split into bounded steps, and destination requests are sent one at a time. Quick Stack stops when required state can no longer be verified&mdash;for example after leaving the base, changing worlds, or changing characters.</p>
<p>Avoid other inventory operations while the progress notification is visible.</p>
<h2>Compatibility Status</h2>
<ul>
<li><strong>Core single-player flow on Steam:</strong> Tested</li>
<li><strong>All 17 Palworld interface languages:</strong> Supported</li>
<li><strong>Pal Insight 2.0.0 integration:</strong> Supported</li>
<li><strong>Dedicated-server client:</strong> One community tester reported successful client-side-only use; their game build and distribution platform were not recorded</li>
<li><strong>Co-op:</strong> Not verified</li>
<li><strong>Game Pass runtime:</strong> Not verified in game</li>
</ul>
<h2>Troubleshooting</h2>
<h3>F5 Does Nothing</h3>
<ul>
<li>Confirm that your character is inside a base.</li>
<li>Open F6 Settings and verify the shortcut.</li>
<li>Check that the package matches Win64 or WinGDK.</li>
<li>Confirm that only one Quick Stack installation is present.</li>
<li>Check <code>UE4SS.log</code> to confirm that Quick Stack loaded.</li>
</ul>
<h3>Items Were Not Sold or Stored</h3>
<ul>
<li>Check the sale category and keep list.</li>
<li>Check Inventory <strong>Tab &gt; R</strong>.</li>
<li>Check Medicine Rack, food, Pal Egg, Relic, and ordinary-storage routing settings.</li>
<li>Check storage filters, permissions, and capacity.</li>
<li>Confirm that the item belongs to the supported normal backpack.</li>
<li>Make sure an available merchant is present in the current base. The F5 result reports when none is found.</li>
</ul>
<h3>Reporting a Problem</h3>
<p>Include your platform, installation channel, game mode, relevant versions and settings, exact reproduction steps, expected and actual results, the complete <code>UE4SS.log</code>, and original crash files when available.</p>
<h2>Palworld Breeding Calculator</h2>
<p>Use the <a href="https://cratex.app/games/palworld/breeding" rel="nofollow">CrateX.app Palworld Breeding Calculator</a> to import a save, compare routes using Pals you already own, or search general breeding combinations. Save processing runs locally in your browser and remains on your device.</p>
<p><a href="https://cratex.app/games/palworld/breeding" rel="nofollow"><img src="https://staticdelivery.nexusmods.com/mods/6063/images/4638/4638-1787096480-407403883.jpg" alt="Plan a Palworld breeding route"></a></p>
<p><a href="https://cratex.app/games/palworld/breeding" rel="nofollow"><img src="https://staticdelivery.nexusmods.com/mods/6063/images/4638/4638-1787598334-1162571780.png" alt="Compare Palworld breeding routes"></a></p>
<h2>Other Download Channels</h2>
<ul>
<li><a href="https://www.nexusmods.com/palworld/mods/5474" rel="nofollow">Nexus Mods</a></li>
<li><a href="https://steamcommunity.com/sharedfiles/filedetails/?id=3792968111" rel="nofollow">Steam Workshop</a></li>
</ul>
<h2>Acknowledgements</h2>
<p>For acknowledgements and supporters, open <strong>F6 &gt; About</strong> in game.</p>
