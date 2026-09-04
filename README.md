# Pal Insight: Quick Stack | 一键归箱

面向 Palworld 1.0 的独立 UE4SS Lua 模组。默认在基地内按 `F5`，把玩家普通背包中符合条件的物品归入当前基地的对应容器。

> 当前版本：`1.1.0`。独立核心已完成单人实机迭代，普通物品移动、
> 中央状态通知和宽屏结果卡已验证；多人、专服、完整帕鲁蛋矩阵、满箱失败卡、
> 窄屏/超高滚动及 Pal Insight 双加载顺序仍待验收。

Nexus Mods 与 CurseForge 分别提供 Steam/Win64 和 Xbox App / PC Game Pass /
Microsoft Store WinGDK 两种压缩包。必须选择与游戏版本匹配的文件；WinGDK 包已
通过静态结构验证，但尚未完成代表性 Game Pass 实机验收。

## 核心规则

- 只处理本地玩家的 Common 普通背包，不扫描装备、食物栏、重要物品栏等其他容器。
- 只枚举玩家当前所在基地的复制对象，不扫描全世界对象。
- 默认遵循背包 `Tab` → `R` 添加的快速移动排除项，包括帕鲁蛋；可选规则允许本次
  收纳包含这些物品，但不会修改游戏中的忽略列表。
- 工会箱永远不会成为自动收纳目标；只使用当前基地的普通储存容器、孵化器和
  古代遗物转换器。
- 打开 `Tab` 后，只有当前位于“背包/装备”页时允许按 `F5`；地图、科技、
  帕鲁图鉴等同一套菜单中的其他页面仍会拦截快捷键。
- 帕鲁蛋始终先进入空闲孵化器；可选择在孵化器不存在或已满时留在背包，或继续
  使用兼容的普通仓库。
- 古代文明的遗物始终先进入当前基地的古代遗物转换器；可选择在转换器不存在或
  已满时留在背包，或继续使用兼容的普通仓库。多个转换器会依次利用。
- 关闭“收纳不在仓库中的物品”后，普通仓库只接收已经存有同种物品的物品；
  这不会阻止帕鲁蛋进入空孵化器或遗物进入空转换器。
- 每个目标容器提交前重新检查玩家、基地、容器身份、筛选、权限、容量和来源物品。
- 每次只向一个目标容器发送请求；目标请求之间至少间隔 34 ms。
- 开始时显示“收纳中”，提交后只在背包复制状态确认物品确已减少时显示
  “收纳完成”；3 秒内未确认则显示“收纳请求已发送”，不误报完成。
- 独立使用 Quick Stack 时，所有结果都显示为非交互式中央提示。与兼容版
  Pal Insight 配合后，可选择“自动 / 仅文字 / 仅结果窗”：自动模式在背包页
  触发时显示逐项结果窗，场景中触发时显示文字；仅结果窗则在两处都显示结果窗。
  结果窗自行接管光标和输入，即使收纳期间关闭背包也仍可正常操作；它以游戏
  原生图标和本地化名称列出“已收纳”及 `Tab` → `R` 的“已排除”物品，并标注数量。
  结果卡采用 Pal Insight
  F6 的宽幅扁平布局；每个物品单元足够容纳原生行时显示四列，否则显示三列，
  窄窗口安全降为两列，长名称不会再穿入数量区域。
- 兼容普通箱容量耗尽时，结果卡会改用醒目的失败标题，并把“未能收纳”放在
  首位，明确这些物品仍留在背包中；随后才显示已收纳和已排除。只有排除项时
  仍使用短提示。
- 详细结果卡不会自动关闭。底部使用居中的宽“确定”按钮；鼠标点击、回车、
  空格、ESC、手柄确认键和取消键均可关闭。关闭只影响结果卡，不影响收纳任务。
- 未能收纳的中央短提示固定分为两行：第一行显示未收纳数量，第二行提示检查
  仓库空间和设置；不依赖窗口宽度碰巧折行。
- “收纳中”、无可收纳物品及其他短提示在状态框内水平、垂直居中。
- 状态不完整或发生切图、离开基地、角色切换时停止本次任务，不猜测备用对象。

## 语言

Quick Stack 的状态提示、结果标题、分区、统计、说明和按钮会自动
跟随 Palworld 当前界面语言，完整覆盖游戏现有的 17 种界面语言。未知语言或
语言读取失败时安全回退英文。物品图标和名称直接使用 Palworld 的原生本地化
资源，不维护一份可能过期的重复翻译。

## 快捷键设置

默认快捷键为 `F5`。

首次运行后，可写配置位于：

```text
%LOCALAPPDATA%\Pal\Saved\PalInsightQuickStackSettings.lua
```

关闭游戏后编辑该文件并重新启动。Steam 创意工坊更新不会覆盖 Saved 目录中的配置。
从 `0.1.x` 升级时，旧的 `PalInsightQuickStack-config.lua` 会在首次启动时自动
导入；旧文件会保留，不会删除或覆盖。

单键示例：

```lua
Key = "F5",
Shift = false,
Ctrl = false,
Alt = false,
```

`Ctrl+S` 示例：

```lua
Key = "S",
Shift = false,
Ctrl = true,
Alt = false,
```

`Key` 使用 UE4SS 的按键名称，例如 `F5`、`S`、`HOME`。手动改完后需要重启游戏，首版不要求热重载。

## 与 Pal Insight 配合

Quick Stack 本身不依赖 Pal Insight。安装兼容版 Pal Insight 后，可通过：

```text
F6 → Controls → Pal Insight: Quick Stack
```

这里可以直接改键，并调整“收纳提示”、“收纳已忽略的物品”、
“收纳不在仓库中的物品”、“收纳帕鲁蛋”、“收纳古代文明的遗物”，以及
“每台转换器保留的世界树圣水”；
所有设置都由 Quick Stack 保存。
“收纳提示”设为“仅文字”后，所有触发方式都只显示中央短提示。兼容版 Pal Insight
还会为背包页触发的逐项结果卡提供输入桥；Quick
Stack 不附带第二份 PAK。未安装或版本不兼容时，快捷键及该开关仍从 Saved
配置读取，收纳结果自动降级为中央短提示。

## 配置项

```lua
return {
    Key = "F5",
    Shift = false,
    Ctrl = false,
    Alt = false,
    ResultDisplay = "Default",
    IncludeExcludedItems = false,
    IncludeNewItems = true,
    IncludeGuildChest = false,
    IncludeSmallIncubators = false,
    PalEggRouting = "IncubatorOnly",
    RelicRouting = "RecyclerOnly",
    WorldTreeHolyWaterMinimum = 10,
    Debug = false,
}
```

- `ResultDisplay`：`Default`（界面显示为“自动”）在场景中显示文字提示、从背包页
  触发时显示逐项结果窗；`TextOnly` 始终只显示文字；`ResultWindow` 始终请求可独立
  关闭的结果窗。结果窗需要兼容版本的 Pal Insight，缺失或接管失败时安全降级为文字。
- `IncludeExcludedItems`：也收纳通过 `Tab → R` 忽略的物品，但不修改忽略列表。
- `IncludeNewItems`：也使用尚未存有同种物品、但筛选允许的普通仓库空位。
- `IncludeGuildChest`：也使用当前基地中有权限访问的公会箱；默认关闭。
- `IncludeSmallIncubators`：也使用小型孵化器；默认关闭。先投大型，再确认已发现的
  大型均无空位，才向无蛋、无待领取帕鲁的小型投放。大型状态不明、请求失败或仍有
  空位时，本次跳过小型；`ManualPlacement` 仍完全跳过帕鲁蛋。
- `PalEggRouting`：`IncubatorOnly` 只使用孵化器；`IncubatorThenStorage` 在孵化器
  不存在或已满时继续使用兼容的普通仓库；`ManualPlacement` 完全跳过帕鲁蛋，留给
  玩家手动放置。
- `RelicRouting`：`RecyclerOnly` 只使用古代遗物转换器；
  `RecyclerThenStorage` 在转换器不存在或已满时继续使用兼容的普通仓库；
  `ManualPlacement` 完全跳过古代文明遗物，留给玩家手动放置。
- `WorldTreeHolyWaterMinimum`：把当前基地每台古代遗物转换器中的世界树圣水补到
  指定数量，范围 `1–100`、默认 `10`；剩余圣水继续按普通仓库规则收纳。
- `Debug`：开发日志；公开发布版本必须保持 `false`。

旧配置中的 `ShowDetailedResults`、`OnlyExistingItems`、`IncludePalEggs`、
`ExcludePalEggs`、`AltEggSorting`、`IncubatorsFirst` 和 `FillByChestFilter` 会自动
迁移或移除。短期测试版的旧 `RelicRouting` 值也会迁移为当前路由。迁移后
Saved 配置会改写为新格式，旧版独立配置文件仍保持不变。

## 性能设计

预热后的 F5 热路径不使用 `FindAllOf`。首次或缓存失效时先使用
`FindFirstOf` 并验证本地 Controller，只在兼容性回退时调用 UEHelpers。
Tab 页面判定也不扫描 Widget：模组在主菜单实例创建时保存一个指针，按键时
只检查该菜单是否激活以及当前内容是否为原生背包页。
库存、基地对象、容器槽位和提交前复核都分成有上限的游戏线程切片；
物品路由使用“已有物品”和“接受类别”索引，不执行全世界扫描或瞬间
RPC 连发。提交后的确认只按 120 ms 间隔复核本次实际提交涉及的背包槽位，
最多 3 秒，不存在常驻 UObject Tick 或全局对象轮询。可选 F6 集成继续以 500 ms
低频处理能力发布、预热和兼容设置；检测到 Pal Insight 设置已打开后，16 ms
快速路径每次只读一个请求信号，只有信号变化才接收完整打开／关闭事务，
不执行仓库扫描或界面重建。
遗物转换器及其世界树圣水专用槽只复用本轮当前基地对象枚举，不增加全世界扫描；
遗物资格继续以实时容器权限为准。
结果统计复用同一次任务快照与确认数据，不为通知重新扫描背包或箱子；结果卡
最多创建有限数量的原生物品行，超出的种类只显示汇总。详细结果卡只在兼容
能力存在时创建一份卡片生命周期内的输入桥实例；关闭时解除按钮 delegate、
输入组件和 Widget，不再以 16 ms 轮询按钮状态。

设计目标是代表性基地上单切片不超过 2 ms。这个数字必须通过同场景 A/B 实机采集验证，在获得数据前不宣称已经达到。

## 开发边界

- `diagnostics/` 只保存获批的一次性只读证据工具，不属于发布载荷。
- `Scripts/palworld.lua` 隔离当前版本反射字段，`Scripts/quick_stack.lua`
  独立拥有任务状态；入口文件只负责配置和快捷键调度。
- 未经单独批准，不构建、安装、打包、创建 GitHub 仓库或发布创意工坊条目。
- 当前运行时契约、已知风险和验收矩阵见 `docs/`。
- 三平台发布源、元数据和门禁见 `packaging/` 与
  `toolchain/tools/release/pal_insight_quick_stack_release_inventory.js`。
