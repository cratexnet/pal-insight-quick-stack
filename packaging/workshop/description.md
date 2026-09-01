[h1]Pal Insight: Quick Stack | 一键归箱[/h1]

[b]One key, one clean backpack.[/b]

Press [b]F5[/b] while standing inside your current base. Quick Stack moves matching items from your normal inventory into compatible [b]private storage[/b] in that base.

在当前基地内按 [b]F5[/b]，即可把普通背包中符合条件的物品收纳到该基地兼容的[b]私人储存容器[/b]。

[h2]What it does | 功能[/h2]

[list]
[*]Uses only storage objects from the base you are currently inside.
[*]Respects Quick Move exclusions added through Inventory [b]Tab > R[/b] by default, with optional storage rules.
[*]Never selects Guild Chests as automatic destinations.
[*]Prefers incubators for eligible Pal Eggs, then existing matching stacks, then compatible private storage whose filters accept the item.
[*]Shows a native-style result card for stored, excluded, and not-stored items.
[*]Follows all 17 interface languages currently included with Palworld.
[*]Splits work into bounded slices and serializes destination requests to keep frame-time work bounded.
[/list]

[list]
[*]仅使用角色当前所在基地的储存设施。
[*]默认遵循背包 [b]Tab > R[/b] 添加的快速移动排除项，并提供可选收纳规则。
[*]永远不会把工会箱作为自动收纳目标。
[*]符合条件的帕鲁蛋优先进入孵化器；其他物品依次优先匹配已有堆叠和允许该物品的私人储存容器。
[*]用原生风格结果卡区分已收纳、用户排除和因空间或仓库设置限制而未能收纳的物品。
[*]自动跟随 Palworld 当前界面语言，覆盖游戏现有的全部 17 种界面语言。
[*]分帧处理并串行提交储存请求，避免持续掉帧。
[/list]

[h2]Requirements | 依赖[/h2]

[list]
[*][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3625223587][b]UE4SS Experimental (Palworld)[/b][/url] — required and declared as this item's Workshop dependency.
[*][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3778493118]Pal Insight[/url] is optional.
[/list]

[list]
[*]本条目已声明 [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3625223587][b]UE4SS Experimental (Palworld)[/b][/url] 为必需依赖。
[*][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3778493118]Pal Insight[/url] 是可选模组，不安装也可以正常使用 Quick Stack。
[/list]

The current Beta has been tested in single-player. Multiplayer and dedicated-server client behavior have not yet been verified.

当前 Beta 已完成单人测试；多人及专用服务器客户端行为尚未验证。

[b]Do not combine Steam Workshop, Nexus, and CurseForge copies.[/b]

[b]请勿同时安装 Steam Workshop、Nexus 和 CurseForge 版本。[/b]

[h2]Shortcut settings | 快捷键设置[/h2]

The default shortcut is [b]F5[/b]. / 默认快捷键为 [b]F5[/b]。

[b]Standalone | 独立使用[/b]

Close the game and open the following file. / 关闭游戏后打开：

[code]%LOCALAPPDATA%\Pal\Saved\PalInsightQuickStackSettings.lua[/code]

Change [b]Key[/b], [b]Shift[/b], [b]Ctrl[/b], [b]Alt[/b], [b]ResultDisplay[/b], [b]IncludeExcludedItems[/b], [b]IncludeNewItems[/b], [b]PalEggRouting[/b], [b]RelicRouting[/b], or [b]WorldTreeHolyWaterMinimum[/b], save the file, then restart the game. [code]ResultDisplay[/code] accepts [code]Default[/code] (automatic), [code]TextOnly[/code], or [code]ResultWindow[/code]. The result window requires a compatible Pal Insight and otherwise falls back safely to center-screen text. Workshop updates do not overwrite it.

修改 [b]Key[/b]、[b]Shift[/b]、[b]Ctrl[/b]、[b]Alt[/b]、[b]ResultDisplay[/b]、[b]IncludeExcludedItems[/b]、[b]IncludeNewItems[/b]、[b]PalEggRouting[/b]、[b]RelicRouting[/b] 或 [b]WorldTreeHolyWaterMinimum[/b]，保存后重新启动游戏。[code]ResultDisplay[/code] 可设为 [code]Default[/code]（自动）、[code]TextOnly[/code]（仅文字）或 [code]ResultWindow[/code]（仅结果窗）；结果窗需要兼容版本的 Pal Insight，否则会安全降级为中央短提示。创意工坊更新不会覆盖此文件。

Existing [code]PalInsightQuickStack-config.lua[/code] settings from 0.1.x are imported automatically and the old file is left unchanged.

从 0.1.x 升级时会自动导入旧的 [code]PalInsightQuickStack-config.lua[/code]，旧文件保持不变。

[b]With a compatible [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3778493118]Pal Insight[/url] version | 与兼容版 [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3778493118]Pal Insight[/url] 配合[/b]

[url=https://steamcommunity.com/sharedfiles/filedetails/?id=3778493118][b]F6 > Controls > Pal Insight: Quick Stack[/b][/url]

[url=https://steamcommunity.com/sharedfiles/filedetails/?id=3778493118]Pal Insight[/url] lets you change the shortcut and all six Quick Stack settings in game. Quick Stack remains fully functional without it.

[url=https://steamcommunity.com/sharedfiles/filedetails/?id=3778493118]Pal Insight[/url] 可在游戏内修改快捷键和六项 Quick Stack 设置；未安装时，Quick Stack 仍可独立使用。

[b]Storage routing | 收纳路由[/b]

[list]
[*]Inventory [b]Tab > R[/b] ignored items unless [code]IncludeExcludedItems[/code] is enabled / [b]Tab > R[/b] 忽略项（除非启用包含已忽略物品）
[*][code]PalEggRouting[/code] can keep Pal Eggs in inventory, fall back from incubators to storage, or leave every egg for manual placement / [code]PalEggRouting[/code] 可让帕鲁蛋留在背包、从孵蛋器回退普通仓库，或全部交由玩家手动放置
[*][code]RelicRouting[/code] can keep relics in inventory, fall back from Recyclers to storage, or leave every relic for manual placement / [code]RelicRouting[/code] 可让古代文明遗物留在背包、从转换器回退普通仓库，或全部交由玩家手动放置
[*]Each recycler is topped up to [code]WorldTreeHolyWaterMinimum[/code] World Tree Holy Water (default 10, range 1-100); the remainder follows ordinary-storage rules / 每台转换器的世界树圣水补到 [code]WorldTreeHolyWaterMinimum[/code]（默认 10，范围 1-100），剩余圣水按普通仓库规则收纳
[*][code]IncludeNewItems = false[/code] only restricts ordinary storage / 关闭 [code]IncludeNewItems[/code] 只限制普通仓库，不影响空孵蛋器或转换器槽位
[/list]

[code]IncludeExcludedItems[/code] only affects Quick Stack and never changes Palworld's ignored-item list. / [code]IncludeExcludedItems[/code] 只影响本次收纳，不会修改游戏中的忽略列表。

[h2]Safety and behavior | 安全与行为[/h2]

[list]
[*]Only the normal player inventory and the current base are considered.
[*]Capacity, filters, permissions, exclusions, and destination identity are rechecked before each request.
[*]Quick Stack stops instead of guessing when required state cannot be verified.
[*]Avoid other inventory operations while the progress message is visible.
[/list]

[list]
[*]仅处理普通玩家背包与当前基地。
[*]每次请求前都会重新检查容量、筛选设置、权限、排除项和目标身份。
[*]无法确认必要状态时会停止，不会猜测或强行移动。
[*]进度提示显示期间，请勿执行其他背包操作。
[/list]
