# 设置分组与弹药自动出售：Palworld 1.0 静态调查

## 结论

当前设置页的主体分组基本合理，唯一明显的分类问题是
`AutoSellValuables` 被放在“收纳规则”中。出售是有损操作，不属于收纳；加入弹药出售后，
最小且更清晰的调整是增加一个独立的“自动出售”分组，将贵重品出售移入其中，并新增
“自动出售弹药”和“保留的弹药”入口。其余选项不需要大改。

当前游戏物品主表中共有 38 行同时满足 `TypeA = Ammo`、
`TypeB = ConsumeBullet`。其中 32 行同时满足 `bLegalInGame = true`，每一行都具有：

- 当前简体中文名称；
- 当前简体中文用途描述；
- 唯一配方产物行；
- `IconName`；
- PAK 中与 `IconName` 一一对应的原生弹药图标纹理。

因此，面向用户的候选集应是这 32 项，而不是按名称包含 `Bullet` 猜测，也不应显示 6 个
隐藏/禁用条目。安全的配置模型应在内部保存“明确允许出售的 static item ID 集合”，
但在界面上以“保留这些弹药”呈现；未出现过的新弹药默认保留。这样既符合用户心智，
也不会在游戏更新新增弹药时自动出售未知物品。

## 证据范围与标记

调查对象：

- 当前 PAK：
  `F:\SteamLibrary\steamapps\common\Palworld\Pal\Content\Paks\Pal-Windows.pak`
  - size: `40527155723`
  - mtime: `2026-08-12 12:38:35`
- 当前物品主表导出：
  `D:\Workspace\pal-insight\toolchain\work\auto-sell-research\DT_ItemDataTable_Common.json`
- 当前简中物品名称表、配方表和游戏设置导出：
  `D:\Workspace\pal-insight\toolchain\work\ammo-auto-sell-research\`
- 当前简中物品描述表：
  `D:\Workspace\pal-insight\toolchain\work\auto-sell-research\ItemDescriptions-zh-Hans.json`
- 当前仓库设置实现：`Scripts/settings_ui.lua`、`Scripts/settings.lua`、
  `Scripts/config.lua`、`Scripts/localization.lua`、`SPEC.md`。

本文标记：

- **已证实**：当前仓库源代码或当前 PAK/cooked asset 直接支持。
- **推断**：多项一手证据一致，但未在运行中的游戏里验证。
- **建议**：产品或实现选择，不是游戏事实。

## 现有设置项与分组评估

`Scripts/settings_ui.lua:6349-6379` 当前实际渲染 10 行用户设置：

| 当前分组 | 设置 | 默认值 | 评估 | 最小建议 |
|---|---|---:|---|---|
| 基础 | 一键归箱快捷键（`Key` + 修饰键） | `F5` | 合适 | 保持 |
| 基础 | 收纳提示（`ResultDisplay`） | `Default` | 可以接受；它是显示偏好而不是按键，但只有两项时无需再拆“界面”分组 | 保持 |
| 收纳规则 | 收纳已忽略的物品（`IncludeExcludedItems`） | `false` | 合适 | 保持；帮助文案需继续强调它只授权收纳，不授权出售 |
| 收纳规则 | 收纳仓库中尚未存在的物品（`IncludeNewItems`） | `true` | 合适 | 保持 |
| 收纳规则 | 使用公会箱（`IncludeGuildChest`） | `false` | 合适；属于目的地范围 | 保持 |
| 收纳规则 | 出售商人高价收购品（`AutoSellValuables`） | `false` | **不合适**；出售不是收纳，且是有损操作 | 移到独立“自动出售”分组 |
| 特殊物品 | 帕鲁蛋收纳（`PalEggRouting`） | `IncubatorOnly` | 合适 | 保持 |
| 特殊物品 | 使用小型孵化器（`IncludeSmallIncubators`） | `false` | 分组和顺序合适，是上一行的子选项 | `PalEggRouting=ManualPlacement` 时禁用或弱化显示 |
| 特殊物品 | 古代文明遗物收纳（`RelicRouting`） | `RecyclerOnly` | 合适 | 保持 |
| 特殊物品 | 每台转换器保留的世界树圣水（`WorldTreeHolyWaterMinimum`） | `10` | 分组和顺序合适，是上一行的子选项 | 不使用转换器时禁用或弱化显示 |

**建议的最小分组顺序：**

1. 基础：快捷键、结果显示。
2. 收纳规则：已忽略物品、新物品、公会箱。
3. 自动出售：商人高价收购品、自动出售弹药、保留的弹药。
4. 特殊物品收纳：帕鲁蛋、小型孵化器、古代遗物、世界树圣水。

“特殊物品”本身没有错误；中文改成“特殊物品收纳”会更精确，但这不是必须项。相比之下，
把出售从“收纳规则”移出是应优先做的调整。

## “哪些算弹药”的判定与完整性

### 判定字段（已证实）

当前 `DT_ItemDataTable_Common` 有 2466 个 static item row。完整遍历后：

```text
TypeA == Ammo && TypeB == ConsumeBullet                  38 行
TypeA == Ammo && TypeB == ConsumeBullet && bLegalInGame 32 行
```

所有 `TypeA == Ammo` 行的 `TypeB` 都是 `ConsumeBullet`，没有第二种 Ammo 子类。
用于用户选择的严格条件应为：

```text
TypeA == Ammo
TypeB == ConsumeBullet
bLegalInGame == true
```

这比名称规则完整：`Arrow`、`InkBullet`、`FlamethrowerBullet` 等都属于同一官方类别；
手雷本身则是 `TypeA = Weapon / TypeB = WeaponThrowObject`，不应算作弹药。

### 6 个不应展示的隐藏/禁用条目（已证实）

以下 6 行虽属于 Ammo，但 `bLegalInGame != true`，且当前配方/排序状态不适合作为用户候选：

```text
LargeBullet
SmallBullet
MachingunBullet
MagnumBullet
SkyLightBullet
SkyHeavyBullet
```

其中 `MachingunBullet` 是游戏内部现有拼写。实现不应修正 ID，也不应因其存在图标而把它加入
候选集。

### 32 个当前用户可用弹药（已证实）

“用途”列来自当前简中 `ITEM_DESC_<StaticItemID>`；描述中写“等”的项目只表示游戏描述明确
举出的武器族，不把该列冒充完整武器兼容矩阵。`Price` 是物品主表基础价格。
当前 `BP_PalGameSetting` 的 `SellItemRate = 0.1`，所以“默认售出价”列按
`Price × 0.1` 列出；服务端最终金额仍以运行时游戏设置和服务端计算为准。

| Static Item ID | 当前简中名称 | 游戏描述注明的用途 | Price | 默认售出价 | IconName |
|---|---|---|---:|---:|---|
| `Arrow` | 箭 | 弓 | 10 | 1 | `Arrow` |
| `Arrow_Poison` | 毒箭 | 弓（附毒） | 40 | 4 | `Arrow_Poison` |
| `Arrow_Fire` | 火箭 | 弓（火属性） | 40 | 4 | `Arrow_Fire` |
| `ReinforcedArrow` | 强化箭矢 | 复合弓专用 | 370 | 37 | `ReinforcedArrow` |
| `SFArrow` | 卓越箭矢 | 卓越弓专用 | 1110 | 111 | `SFArrow` |
| `RoughBullet` | 劣质弹药 | 鸟枪、劣质手枪等 | 40 | 4 | `RoughBullet` |
| `HandgunBullet` | 手枪子弹 | 手枪等 | 40 | 4 | `HandgunBullet` |
| `RifleBullet` | 步枪子弹 | 步枪等 | 280 | 28 | `RifleBullet` |
| `ShotgunBullet` | 霰弹枪子弹 | 霰弹枪等 | 330 | 33 | `ShotgunBullet` |
| `AssaultRifleBullet` | 突击步枪子弹 | 突击步枪等 | 90 | 9 | `AssaultRifleBullet` |
| `ExplosiveBullet` | 火箭弹 | 火箭发射器等 | 2550 | 255 | `ExplosiveBullet` |
| `InkBullet` | 印花墨水 | 印花枪 | 70 | 7 | `InkBullet` |
| `FlamethrowerBullet` | 火焰喷射器燃料 | 火焰喷射器等 | 280 | 28 | `FlamethrowerBullet` |
| `MissileBullet` | 导弹 | 追踪导弹发射器等 | 3240 | 324 | `MissileBullet` |
| `GrenadeBullet` | 榴弹 | 榴弹发射器等 | 470 | 47 | `GrenadeBullet` |
| `GatlingBullet` | 加特林子弹 | 加特林机枪等 | 60 | 6 | `GatlingBullet` |
| `MeteorBullet` | 陨石弹 | 陨石发射器等 | 360 | 36 | `MeteorBullet` |
| `LaserBullet` | 能量盒 | 激光步枪等 | 280 | 28 | `LaserBullet` |
| `EnergyLauncherBullet` | 电浆能量盒 | 等离子炮等 | 2190 | 219 | `EnergyLauncherBullet` |
| `LaserGatlingBullet` | 加特林激光能量盒 | 激光加特林等 | 110 | 11 | `LaserGatlingBullet` |
| `ChargeLaserRifleBullet` | 充能步枪子弹 | 充能步枪等 | 1740 | 174 | `ChargeLaserRifleBullet` |
| `OverheatRifleBullet` | 过热步枪子弹 | 过热步枪等 | 920 | 92 | `OverheatRifleBullet` |
| `EnergyShotgunBullet` | 能量霰弹枪子弹 | 能量霰弹枪等 | 990 | 99 | `EnergyShotgunBullet` |
| `PalDopingShotBullet` | 强化枪子弹 | 强化枪等 | 90 | 9 | `PalDopingShotBullet` |
| `WidePenetrateShotgunBullet` | 散射光束枪弹药 | 散射光束枪 | 7830 | 783 | `WidePenetrateShotgunBullet` |
| `ElectricArcAssaultRifleBullet` | 等离子步枪弹药 | 等离子步枪 | 3910 | 391 | `ElectricArcAssaultRifleBullet` |
| `BeamLauncherBullet` | 光束炮发射器弹药 | 光束炮发射器 | 13660 | 1366 | `BeamLauncherBullet` |
| `SkyBowArrow` | 机械弓箭矢 | 机械弓专用 | 1730 | 173 | `SkyBowArrow` |
| `SkySubmachineGunBullet` | 战斗冲锋枪子弹 | 战斗冲锋枪 | 1020 | 102 | `SkySubmachineGunBullet` |
| `SkyShotgunBullet` | 原型霰弹枪子弹 | 原型霰弹枪 | 3870 | 387 | `SkyShotgunBullet` |
| `SkyAssaultRifleBullet` | 重型突击步枪子弹 | 重型突击步枪 | 1120 | 112 | `SkyAssaultRifleBullet` |
| `SkyGrenadeLauncherBullet` | 战术榴弹发射器子弹 | 战术榴弹发射器 | 3970 | 397 | `SkyGrenadeLauncherBullet` |

### 可获得性核对（已证实）

32 项中的每一项在 `DT_ItemRecipeDataTable_Common` 中都恰好有一个
`Product_Id == StaticItemID` 的配方行；其当前简中描述也都说明了制作设施。
因此没有发现 `bLegalInGame = true` 但仅供测试、没有当前配方的特殊弹药，现阶段不需要从
32 项中再排除候选。

这只能证明当前 cooked 数据定义了合法配方，不能证明某个特定存档已经解锁该配方；
对自动出售候选而言不需要按存档解锁状态过滤，因为背包中实际存在该 static ID 才会参与。

## 原生图标路径与可实现 UI

### 图标资源（已证实）

32 项的 `IconName` 都与 PAK 中一个纹理一一匹配，零缺失。精确对象路径规则为：

```text
/Game/Others/InventoryItemIcon/Texture/
  T_itemicon_Ammo_<IconName>.T_itemicon_Ammo_<IconName>
```

例如：

```text
Arrow
  /Game/Others/InventoryItemIcon/Texture/
    T_itemicon_Ammo_Arrow.T_itemicon_Ammo_Arrow

BeamLauncherBullet
  /Game/Others/InventoryItemIcon/Texture/
    T_itemicon_Ammo_BeamLauncherBullet.T_itemicon_Ammo_BeamLauncherBullet
```

每一项的纹理标识就是上表 `IconName`；代入同一规则即可得到其完整对象路径。

### 推荐的选择界面（建议）

不要在主设置页平铺 32 个文字开关。建议在“自动出售”分组中使用两行：

```text
自动出售弹药                         [关 / 开]
保留的弹药                         [32 / 32  选择…]
```

点击第二行进入一个有滚动区域的子面板：

- 两列原生物品卡片；每张卡片显示游戏图标和当前语言名称；
- 卡片右侧使用明确的“保留”勾选状态，而不是用颜色暗示；
- 顶部写清楚“勾选的弹药不会出售”；
- 提供“全部保留”和“全部出售”操作，其中“全部出售”使用警告色；
- 键鼠和手柄共用现有 modal/focus/navigation 基础设施；
- 构建 32 个条目时按帧分片并缓存，避免一次冷开创建整棵 UMG 子树。

当前仓库已经有可复用的一手实现路径：

- `PalItemIDManager.GetStaticItemData(staticId)` 返回的
  `UPalStaticItemDataBase` 本身带有 `IconTexture`；已落地当前类型头中的字段为
  `UPalStaticItemDataBase::IconTexture`，因此运行时也可直接沿物品元数据取得图标；
- `Scripts/notifications.lua:44-46` 使用游戏自带
  `/Game/Pal/Blueprint/UI/UserInterface/MainMenu/Paldex/WBP_Paldex_DropItem`；
- `Scripts/notifications.lua:534-544` 创建
  `WBP_Paldex_DropItem_C` 并调用 `itemWidget:Setup(item.staticId)`；
- 该原生 row 会根据 static ID 显示游戏自己的图标和当前本地化名称；
- `Scripts/settings_ui.lua` 已有 `CheckBox`、嵌套 modal、滚动容器、
  `UniformGridPanel` 和手柄导航基础设施。

2026-09-05 的游戏内验证否定了上述原生 row 方案：打开弹药选择器后，游戏线程在
UE4SS 内以 `EXCEPTION_ACCESS_VIOLATION` 读取 `0x70` 崩溃。该签名与当前 UE4SS
反射参数封送缺陷一致，Lua `pcall` 无法拦截。因此实际实现不得从 Lua 构造或调用
`WBP_Paldex_DropItem_C:Setup`。

修订后的方案直接按上面的纹理对象路径加载游戏图标，并通过经过类型检查的 `FName`
调用游戏物品名称接口；若名称接口不可用则显示 stable static ID。这样保留图标和游戏
本地化名称，同时移除会创建整棵原生 item-row Blueprint 的崩溃路径。

如果原生 item-row class 或某一项的图标无法解析，选择器应保持旧配置并显示失败状态，
不能把该项默认为可出售。自动出售本身也应继续 fail closed。

## 安全的“自动出售，但选定弹药不出售”模型

### 用户语义与内部存储要分开（建议）

用户界面采用“保留名单”最容易理解，但持久化时保存显式的“允许出售名单”更安全：

```text
UI：勾选 = 保留，不出售
内部：AmmoSellItems = 用户明确取消“保留”的已知 static IDs
```

推荐配置：

```lua
AutoSellAmmo = false
AmmoSellItems = ""
```

`AmmoSellItems` 可使用按固定候选顺序规范化的逗号分隔 static ID 字符串，从而保持当前
Pal Insight bridge 的 versioned scalar contract；解析时只接受 32 项固定 allowlist 中的
完整 ID，去重、按规范顺序重写，未知值忽略并记录普通日志。

这一设计的安全性质：

- 默认 `AutoSellAmmo = false`；
- 默认 `AmmoSellItems` 为空，即 32/32 全部保留；
- 用户只有明确取消某张卡片的“保留”后，该 ID 才进入可出售集合；
- 游戏更新新增弹药时，它不在旧的 `AmmoSellItems` 中，因此默认保留；
- 配置损坏、缺字段、未知 ID、候选元数据缺失时均不会扩大出售范围。

虽然 UI 看起来是保留名单，这在安全边界上仍然是“出售白名单”，不会出现“新弹药默认
被黑名单漏掉后自动卖出”的问题。

### 运行时优先级（建议）

一个背包槽只有同时满足以下条件才可进入出售 batch：

```text
AutoSellAmmo == true
staticId 在固定的当前版本 32 项弹药候选中
staticId 在 AmmoSellItems 中
staticId 不在玩家 Tab -> R 排除名单中
槽位属于同一 local player 的 common inventory
提交前重读得到相同 container / slot index / staticId / count
存在当前基地真实且已注册的 ShopID
```

保护优先级应为：

```text
Tab -> R 排除 > 弹药“保留”选择 > 自动出售弹药 > 普通收纳
```

即使 `IncludeExcludedItems = true`，它也只代表“允许收纳已忽略物品”，不能授权出售。
已装入武器弹匣的弹药不属于 common inventory 槽，本路径不应扫描或影响它。

弹药出售可以复用已经研究确定的当前基地 vendor/ShopID、server-side slot revalidation 和
一次 batch RPC 路径。若出售 RPC 已提交但结果未确认，该槽本次仍留在背包，不再与归箱
RPC 竞争。

## 提取与复核

关键提取命令：

```powershell
repak.exe unpack -f -o <work> `
  -i Pal/Content/L10N/zh-Hans/Pal/DataTable/Text/DT_ItemNameText_Common.uasset `
  -i Pal/Content/L10N/zh-Hans/Pal/DataTable/Text/DT_ItemNameText_Common.uexp `
  Pal-Windows.pak

repak.exe unpack -f -o <work> `
  -i Pal/Content/Pal/DataTable/Item/DT_ItemRecipeDataTable_Common.uasset `
  -i Pal/Content/Pal/DataTable/Item/DT_ItemRecipeDataTable_Common.uexp `
  Pal-Windows.pak

repak.exe unpack -f -o <work> `
  -i Pal/Content/Pal/Blueprint/System/BP_PalGameSetting.uasset `
  -i Pal/Content/Pal/Blueprint/System/BP_PalGameSetting.uexp `
  Pal-Windows.pak

Invoke-UAssetGuiToJson.ps1 `
  -EngineVersion VER_UE5_1 `
  -MappingName Palworld_1_0_2FF94A03 `
  -InputPath <uasset> -OutputPath <json> -LogDirectory <logs>
```

映射：

```text
Palworld_1_0_2FF94A03.usmap
SHA-256 241C45DE9D5B55B246CD4B39D62B9209FAF7758CE0637E1F7A545AA0F75F71F0
```

新增调查产物及 SHA-256：

| 产物 | bytes | SHA-256 |
|---|---:|---|
| `DT_ItemNameText_Common.uasset` | 58147 | `0FD31CE8183B32D8CE88432C097B30E53D3966EE67B83D29E26DFF23CCAC13E2` |
| `DT_ItemNameText_Common.uexp` | 212668 | `53E3C7EC7C09053B80431C18FB2FA9785FC2B883036D53849EC96D5D086A50BF` |
| `ItemNames-zh-Hans.json` | 3309204 | `9E79040F17DDCE9B4792C0E6FFE40C574D6BF53BD78CD0736E3BC74320F3A709` |
| `DT_ItemRecipeDataTable_Common.uasset` | 27738 | `0EDE709D0E06EF99D55D5D68A2A727B4A5AAE0CB9BA06EA49E46962525C544AB` |
| `DT_ItemRecipeDataTable_Common.uexp` | 108918 | `710ADB95802D87D10156B078CB26A159BFA0D33E1A42653E7277BEFA4EB773BE` |
| `DT_ItemRecipeDataTable_Common.json` | 14136244 | `A8ADB199DA0BD4E20DAB6BBCC2E6CB22B6AF556A0F3589D12E48E516DADCD60B` |
| `BP_PalGameSetting.uasset` | 24408 | `7C868C5B5E507ADA81977016E951D359260D4445ADF83FF9CC59075BC3AA638A` |
| `BP_PalGameSetting.uexp` | 24493 | `A7D8F8752E64AAE4623EECEA9ADCB7F110AC619023DCDC074071B3AC7D6904BA` |
| `BP_PalGameSetting.json` | 1485725 | `115A29A2083E12B1357F833D8A14FC456BC16FF15B5F280EC1404A86E3045790` |

复核断言：

```text
合法弹药候选                  32
有简中 ITEM_NAME 行           32 / 32
有简中 ITEM_DESC 行           32 / 32
有唯一 Product_Id 配方        32 / 32
IconName 对应 PAK 原生纹理     32 / 32
缺失                           0
```

## 尚未证明的部分

- 本调查没有运行游戏，因此不声称已验证 32 项选择器的 UMG 冷开耗时、手柄滚动体验或
  多人出售时序。
- “用途”按当前官方物品描述列出；描述带“等”的项目没有在本文扩展成完整武器兼容矩阵。
- 默认售出价按当前 cooked `SellItemRate` 给出；自定义服务器或未来版本若改变该设置，
  最终金额以服务端为准。

这些未知项不影响候选集和安全模型：出售集合保持显式 allowlist，缺失或新增内容默认保留。

## 选择器运行时修正（2026-09-05）

首次实机验证发现两项问题：图标槽在异步贴图成功前使用 `Collapsed`，导致槽位从
0px 变为 38px，用户在取消并重新勾选时会看到同一行横向位移；同时直接调用
`PalUIUtility.GetItemName` 没有得到可用的输出参数，界面回退成了内部 ID。

修正后的约束是：图标 `SizeBox` 从首帧起始终保留固定宽度，只更新 Brush；物品名称
由当前可执行文件配套 PAK 中的 `DT_ItemNameText_Common` 提取。17 个界面 locale、32 个
弹药和 9 个高价收购物品均为 `41/41` 命中。西语拉美使用游戏的 `es-MX` 资源，日语
使用非 L10N 的源表，其余 locale 使用同名 L10N 表。运行时只按当前 locale 查这个小型
只读目录，不再调用原生物品行或带输出参数的反射函数。

高价收购物品新增与弹药一致的保留选择器。底层仍存显式 `ValuableSellItems` 出售
allowlist；旧配置缺少该字段时迁移为当前 9 项全选出售，从而保持原有开关语义。界面
反向显示为“勾选即保留”，用户可逐项保护，未知或未来新增 ID 仍不会自动进入出售集合。
中文主设置行使用与弹药平行的短文案：“自动出售高价品”和“保留的高价品”，避免同一
类别混用“商人高价收购品”与“高价物品”。

后续截图进一步证明，固定图标槽只解决了贴图成功前的文字位移，尚有三个独立问题：

- 弹窗条目宽度没有预留垂直滚动条的 gutter；`ScrollWidgetIntoView` 为显示条目右边缘而
  产生横向滚动，使滚动后的行整体左移约一个滚动条宽度。
- `UImage` 在贴图分片加载前已经可见，空 Brush 会显示为白色方块；`LoadAsset` 成功后的
  纹理也没有进入现有强引用缓存。图标槽应始终占位，但内部图片必须在成功设置 Brush 后
  才显示。通过 `ImportFileAsTexture2D` 创建的点赞/About 纹理绑定创建时的 `UWorld`，窗口
  因世界变化重建时必须清空对应缓存。
- 弹窗原先把键盘也纳入 retained repeat；Preview 路由返回 Handled 后，
  `APlayerController::IsInputKeyDown` 对键盘键可能为 false，导致第一次轮询即取消，同时
  held transaction 又会吞掉 Slate 后续的重复 key-down。键盘应直接接受同一 Preview 来源
  的系统 repeat，并只去重跨路由的同一按压；手柄 D-pad 和摇杆继续使用现有
  native/cooked 物理状态与 retained repeat。
