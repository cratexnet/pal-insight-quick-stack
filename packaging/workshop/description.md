[h1]Pal Insight: Quick Stack | 一键归箱[/h1]

[b]One key, one clean backpack.[/b]

Press [b]F5[/b] while standing inside your current base. Quick Stack moves matching items from your normal inventory into compatible storage in that base.

在当前基地内按 [b]F5[/b]，即可把普通背包中符合条件的物品收纳到该基地兼容的储存容器。

[h2]What it does | 功能[/h2]

[list]
[*]Uses only storage objects from the base you are currently inside.
[*]Respects Quick Move exclusions added through Inventory [b]Tab > R[/b] by default, with optional storage rules.
[*]Can optionally use an accessible Guild Chest in the current guild base. This setting is off by default.
[*]Can optionally use empty small incubators after large incubators are full. Skips incubators with an egg or an unclaimed Pal. This setting is off by default.
[*]Prefers incubators for eligible Pal Eggs, then existing matching stacks, then compatible private storage whose filters accept the item.
[*]Shows a native-style result card for stored, excluded, and not-stored items.
[*]Follows all 17 interface languages currently included with Palworld.
[*]Splits work into bounded slices and serializes destination requests to keep frame-time work bounded.
[/list]

[list]
[*]仅使用角色当前所在基地的储存设施。
[*]默认遵循背包 [b]Tab > R[/b] 添加的快速移动排除项，并提供可选收纳规则。
[*]可选择使用当前公会基地中有权限访问的公会箱；此设置默认关闭。
[*]可选择在大型孵化器已满后使用空的小型孵化器；跳过已有蛋或有待领取帕鲁的孵化器，此设置默认关闭。
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

Quick Stack 1.2.0 has been tested in single-player. A community tester also confirmed that it worked without issue on a dedicated server with the mod installed client-side only. The tester's game build and distribution platform were not recorded; co-op behavior has not yet been verified.

Quick Stack 1.2.0 已完成单人测试。一名社区玩家另行确认：在专用服务器上仅客户端安装本模组即可正常使用。该玩家使用的游戏构建及发行平台未记录；co-op 行为尚未完成实机验证。

[b]Do not combine Steam Workshop, Nexus, and CurseForge copies.[/b]

[b]请勿同时安装 Steam Workshop、Nexus 和 CurseForge 版本。[/b]

[h2]Shortcut settings | 快捷键设置[/h2]

The default shortcut is [b]F5[/b]. / 默认快捷键为 [b]F5[/b]。

Press [b]F6[/b] to open Quick Stack's own settings panel. Change the shortcut,
notification style, storage rules, special-item routing, and World Tree Holy
Water minimum without editing files.

按 [b]F6[/b] 打开 Quick Stack 自己的设置面板，无需手动修改文件即可调整快捷键、提示方式、收纳规则、特殊物品路由及每台转换器保留的世界树圣水数量。

[b]With [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3778493118]Pal Insight 2.0.0 or later[/url] | 与 [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3778493118]Pal Insight 2.0.0 或更高版本[/url] 配合[/b]

[b]F6 > Extensions > Pal Insight: Quick Stack[/b]

The same Quick Stack panel opens from Pal Insight's Extensions page. Quick
Stack remains fully functional without Pal Insight; if Pal Insight is installed
but disabled, [b]F6[/b] opens the standalone panel.

可从 Pal Insight 的“扩展”页面打开同一套 Quick Stack 设置。未安装 Pal Insight 时 Quick Stack 仍可独立使用；即使已经安装但没有启用 Pal Insight，[b]F6[/b] 也会打开独立设置面板。

Settings are stored in [code]%LOCALAPPDATA%\Pal\Saved\PalInsightQuickStackSettings.lua[/code], so Workshop updates do not overwrite them. Existing [code]PalInsightQuickStack-config.lua[/code] settings from 0.1.x are imported automatically and the old file is left unchanged.

设置保存在 [code]%LOCALAPPDATA%\Pal\Saved\PalInsightQuickStackSettings.lua[/code]，创意工坊更新不会覆盖。升级时会自动导入 0.1.x 的 [code]PalInsightQuickStack-config.lua[/code]，旧文件保持不变。

[b]Storage routing | 收纳路由[/b]

[list]
[*]Inventory [b]Tab > R[/b] ignored items unless [code]IncludeExcludedItems[/code] is enabled / [b]Tab > R[/b] 忽略项（除非启用包含已忽略物品）
[*][code]PalEggRouting[/code] can keep Pal Eggs in inventory, fall back from incubators to storage, or leave every egg for manual placement / [code]PalEggRouting[/code] 可让帕鲁蛋留在背包、从孵蛋器回退普通仓库，或全部交由玩家手动放置
[*][code]RelicRouting[/code] can keep relics in inventory, fall back from Recyclers to storage, or leave every relic for manual placement / [code]RelicRouting[/code] 可让古代文明遗物留在背包、从转换器回退普通仓库，或全部交由玩家手动放置
[*]Each recycler is topped up to [code]WorldTreeHolyWaterMinimum[/code] World Tree Holy Water (default 10, range 1-100); the remainder follows ordinary-storage rules / 每台转换器的世界树圣水补到 [code]WorldTreeHolyWaterMinimum[/code]（默认 10，范围 1-100），剩余圣水按普通仓库规则收纳
[*][code]IncludeNewItems = false[/code] only restricts ordinary storage / 关闭 [code]IncludeNewItems[/code] 只限制普通仓库，不影响空孵蛋器或转换器槽位
[*][code]IncludeGuildChest = true[/code] allows an accessible Guild Chest in the current guild base and is off by default / 开启 [code]IncludeGuildChest[/code] 后可使用当前公会基地中有权限访问的公会箱；默认关闭
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
