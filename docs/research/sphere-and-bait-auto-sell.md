# 帕鲁球与钓饵自动出售：Palworld 1.0 静态调查

## 结论

可以把“自动出售帕鲁球”和“自动出售钓饵”作为现有 F5 出售阶段的两个独立规则，
并分别提供“保留的帕鲁球”和“保留的钓饵”选择器。候选不能按名称包含
`Sphere` / `Bait` 猜测，而应使用当前物品主表的官方分类与合法性字段：

```text
帕鲁球：TypeA = SpecialWeapon
        TypeB = SPWeaponCaptureBall
        bLegalInGame = true

钓饵：  TypeA = Consume
        TypeB = ConsumeFishingBait
        bLegalInGame = true
```

当前数据中有 **10 个合法帕鲁球**和 **4 个合法钓饵**。另有 2 个禁用帕鲁球、
5 个禁用钓饵、8 个 `Essential` 密钥球和 5 个禁用钓饵蓝图，均不应进入选择器或出售
allowlist。

当前 F5 使用的 `RequestSellItems_ToServer(ShopID, SellItemSlotIDArray)` 服务端路径不按
物品类别或商店库存过滤出售项；它按 common-inventory 槽重新校验并在成功移除后按物品
`Price` 计价。因此这 14 项在同一真实、已注册 item-shop 上可沿现有 F5 出售 RPC 出售。
这个结论是静态代码路径结论，尚未逐项在运行中的游戏里实际卖出验证。

安全默认应与弹药一致：两个总开关默认关闭，两个内部显式出售 allowlist 默认空，
即首次使用时 10/10 帕鲁球和 4/4 钓饵全部保留。界面勾选表示“保留、不出售”；只有用户
明确取消保留的当前已知 ID 才进入出售集合。未来新增内容默认保留。

## 证据范围

本调查只使用当前安装游戏的一手 cooked/export 数据和项目已完成的当前 EXE/RPC 分析：

- 当前 PAK：
  `F:\SteamLibrary\steamapps\common\Palworld\Pal\Content\Paks\Pal-Windows.pak`
  （`40527155723` bytes，mtime `2026-08-12 12:38:35`）。
- 物品主表导出：
  `D:\Workspace\pal-insight\toolchain\work\auto-sell-research\DT_ItemDataTable_Common.json`
  （SHA-256 `D03E2C6EA1A8ABF65C0CE4048EE5F6C1A67D82E8F6C390DD4A96B304065FE423`）。
- 配方表导出：
  `D:\Workspace\pal-insight\toolchain\work\ammo-auto-sell-research\DT_ItemRecipeDataTable_Common.json`
  （SHA-256 `A8ADB199DA0BD4E20DAB6BBCC2E6CB22B6AF556A0F3589D12E48E516DADCD60B`）。
- 简中名称表导出：
  `D:\Workspace\pal-insight\toolchain\work\ammo-auto-sell-research\ItemNames-zh-Hans.json`
  （SHA-256 `9E79040F17DDCE9B4792C0E6FFE40C574D6BF53BD78CD0736E3BC74320F3A709`）。
- 繁中名称表导出：
  `D:\Workspace\pal-insight\toolchain\work\quick-stack-item-names-20260905\json\zh-Hant.json`
  （SHA-256 `A6A64C7B2ACE894B23AAE8630400F46508A002E82502C0CB9C61FC64737A47E7`）。
- 游戏设置导出：
  `D:\Workspace\pal-insight\toolchain\work\ammo-auto-sell-research\BP_PalGameSetting.json`
  （SHA-256 `115A29A2083E12B1357F833D8A14FC456BC16FF15B5F280EC1404A86E3045790`）。
- 当前 RPC 与服务端校验分析：本仓库
  `docs/research/f5-auto-sell.md`。

本文中的“已证实”表示上述当前版本一手数据或当前 EXE 路径直接支持；“建议”表示产品
或实现选择；“未确认”表示静态材料尚不足以声称实机成立。

## 当前合法帕鲁球（10 项，已证实）

以下顺序使用物品表 `SortId`。`Price` 是主表基础价格；当前
`BP_PalGameSetting.SellItemRate = 0.1`，所以“默认售出价”按 `Price × 0.1`
列出。最终金额仍由服务端和实际游戏设置决定。

| Static ID | 简中名称 | 繁中名称 | Price | 默认售出价 | IconName | 原生图标对象路径 |
|---|---|---|---:|---:|---|---|
| `PalSphere` | 帕鲁球 | 帕魯球 | 80 | 8 | `CapturePrism` | `/Game/Others/InventoryItemIcon/Texture/T_itemicon_PalSphere.T_itemicon_PalSphere` |
| `PalSphere_Mega` | 高级帕鲁球 | 高級帕魯球 | 460 | 46 | `PalSphere_Mega` | `/Game/Others/InventoryItemIcon/Texture/T_itemicon_PalSphere_Mega.T_itemicon_PalSphere_Mega` |
| `PalSphere_Giga` | 优质帕鲁球 | 優質帕魯球 | 890 | 89 | `PalSphere_Giga` | `/Game/Others/InventoryItemIcon/Texture/T_itemicon_PalSphere_Giga.T_itemicon_PalSphere_Giga` |
| `PalSphere_Tera` | 特级帕鲁球 | 特級帕魯球 | 1350 | 135 | `PalSphere_Tera` | `/Game/Others/InventoryItemIcon/Texture/T_itemicon_PalSphere_Tera.T_itemicon_PalSphere_Tera` |
| `PalSphere_Master` | 大师帕鲁球 | 大師帕魯球 | 3300 | 330 | `PalSphere_Master` | `/Game/Others/InventoryItemIcon/Texture/T_itemicon_PalSphere_Master.T_itemicon_PalSphere_Master` |
| `PalSphere_Legend` | 传奇帕鲁球 | 傳奇帕魯球 | 5570 | 557 | `PalSphere_Legend` | `/Game/Others/InventoryItemIcon/Texture/T_itemicon_PalSphere_Legend.T_itemicon_PalSphere_Legend` |
| `PalSphere_Ultimate` | 究极帕鲁球 | 究極帕魯球 | 12560 | 1256 | `PalSphere_Ultimate` | `/Game/Others/InventoryItemIcon/Texture/T_itemicon_PalSphere_Ultimate.T_itemicon_PalSphere_Ultimate` |
| `PalSphere_Exotic` | 超限帕鲁球 | 超限帕魯球 | 9080 | 908 | `PalSphere_Exotic` | `/Game/Others/InventoryItemIcon/Texture/T_itemicon_PalSphere_Exotic.T_itemicon_PalSphere_Exotic` |
| `PalSphere_Ancient_1` | 烈阳帕鲁球 | 烈陽帕魯球 | 21000 | 2100 | `PalSphere_Ancient_1` | `/Game/Others/InventoryItemIcon/Texture/T_itemicon_PalSphere_Ancient_1.T_itemicon_PalSphere_Ancient_1` |
| `PalSphere_Ancient_2` | 远古帕鲁球 | 遠古帕魯球 | 122760 | 12276 | `PalSphere_Ancient_2` | `/Game/Others/InventoryItemIcon/Texture/T_itemicon_PalSphere_Ancient_2.T_itemicon_PalSphere_Ancient_2` |

注意：基础 `PalSphere` 的 `IconName` 是 `CapturePrism`，但 PAK 中实际对象是
`T_itemicon_PalSphere`，不能对这一项机械地用 `IconName` 拼路径。对 10 个上表对象逐项
检查当前 PAK，每个 `.uasset` 和配套 `.uexp` 都恰好存在一份。

10 项每项都在当前配方表中有且仅有一个 `Product_Id == Static ID` 的产物行。
因此没有发现 `bLegalInGame=true` 但仅用于测试、无当前配方的帕鲁球。

## 当前合法钓饵（4 项，已证实）

游戏当前简中/繁中名称使用“钓饵/釣餌”，所以界面文案建议沿用官方术语，而不是写
“鱼饵/魚餌”。

| Static ID | 简中名称 | 繁中名称 | Price | 默认售出价 | IconName | 原生图标对象路径 |
|---|---|---|---:|---:|---|---|
| `FishingBait_1` | 简陋钓饵 | 簡陋釣餌 | 160 | 16 | `FishingBait_1` | `/Game/Others/InventoryItemIcon/Texture/T_itemicon_Consume_FishingBait_1.T_itemicon_Consume_FishingBait_1` |
| `FishingBait_2` | 优质钓饵 | 優質釣餌 | 240 | 24 | `FishingBait_2` | `/Game/Others/InventoryItemIcon/Texture/T_itemicon_Consume_FishingBait_2.T_itemicon_Consume_FishingBait_2` |
| `FishingBait_3` | 奢华钓饵 | 奢華釣餌 | 350 | 35 | `FishingBait_3` | `/Game/Others/InventoryItemIcon/Texture/T_itemicon_Consume_FishingBait_3.T_itemicon_Consume_FishingBait_3` |
| `FishingBait_3_A` | 魅惑钓饵 | 魅惑釣餌 | 2020 | 202 | `FishingBait_3_A` | `/Game/Others/InventoryItemIcon/Texture/T_itemicon_Consume_FishingBait_3_A.T_itemicon_Consume_FishingBait_3_A` |

4 项每项都在当前配方表中有且仅有一个对应产物行，且上表 4 个图标在当前 PAK 中均
唯一存在。因此 `FishingBait_3_A` 虽然 ID 带后缀 `_A`，但它与另外几个禁用原型不同：
它明确为合法内容、有正式本地化名称、有配方、有图标，应纳入候选。

## 必须排除的隐藏、测试和关键物品

### 官方类别内但禁用的条目

以下行虽然命中同一 `TypeB`，但 `bLegalInGame=false`，不得显示，也不得被配置文本手工
注入出售 allowlist：

| 类别 | Static ID | 简中 / 繁中名称 | Price | 原因 |
|---|---|---|---:|---|
| 帕鲁球 | `PalSphere_Robbery` | 雷达帕鲁球 / 雷達帕魯球 | 1 | 禁用，`SortId=9999` |
| 帕鲁球 | `PalSphere_Debug` | `zh-hans text` / `zh-hant text` | 1 | Debug，禁用且名称仍为占位文本 |
| 钓饵 | `FishingBait_1_A` | 新手钓饵 / 新手釣餌 | 30 | 禁用 |
| 钓饵 | `FishingBait_1_B` | 甜味钓饵 / 甜釣餌 | 30 | 禁用 |
| 钓饵 | `FishingBait_2_A` | 幸运钓饵 / 幸運釣餌 | 40 | 禁用 |
| 钓饵 | `FishingBait_2_B` | 快钩钓饵 / 快鉤釣餌 | 40 | 禁用 |
| 钓饵 | `FishingBait_3_B` | 高风险钓饵 / 高風險釣餌 | 120 | 禁用 |

### 名称相似但不属于候选的条目

- `KeySphere_01` 至 `KeySphere_08` 是七宗罪/原罪“密钥球”。主表为
  `TypeA=Essential / TypeB=Essential`、`bLegalInGame=false`、`Price=0`。
  它们属于关键物品语义，不是捕捉用帕鲁球；严格分类会自然排除它们。
- `Blueprint_Salvage_FishingBait_1_A`、`1_B`、`2_A`、`2_B`、`3_B` 是
  `TypeA=Blueprint / TypeB=Blueprint` 且 `bLegalInGame=false` 的蓝图行，不是可消耗
  钓饵。
- `SphereLauncher*`、`HomingSphereLauncher` 是武器，`SphereModule_*` 是捕捉模块；
  名称含 `Sphere` 不改变其官方类别。
- `FishingRod*` 是钓竿武器；名称含 `Fishing` 不等于钓饵。

在 14 个合法候选中没有发现 `Essential`、任务物品、Debug、占位本地化或无配方条目。

## 与当前 F5 出售 RPC 的兼容性

已完成的当前 EXE 静态分析证明，F5 使用的服务端入口为：

```text
UPalNetworkShopComponent::RequestSellItems_ToServer(
    ShopID: FGuid,
    SellItemSlotIDArray: TArray<FPalItemSlotIdAndNum>
)
```

handler 对每项执行 common-inventory container GUID、slot index、数量和当前 stack 的重读
与移除校验；成功移除后再从 static item data 计算售价。它不把待售 static ID 与商店
销售目录比对，也未发现针对 `SpecialWeapon`、`Consume` 或上述两个 `TypeB` 的拒绝分支。
14 项均有正 `Price`，按当前 `SellItemRate=0.1` 均得到正售出价。因此：

- **已证实（静态）**：这 14 类 slot 可进入当前 F5 的同一出售 batch，服务端 ABI 和
  校验模型无需为帕鲁球或钓饵另开 RPC。
- **已证实（静态）**：仍必须使用当前基地真实商人的已注册 ShopID；不能构造虚假
  ShopID，也不能绕过现有 slot 重校验。
- **未确认（实机）**：本调查没有逐个物品在单人、联机或专用服务器实际成交，所以
  不声称已验证 14 项最终到账金额。

运行时保护优先级建议沿用现状：

```text
Tab -> R 排除
  > 各类别“保留”选择
  > 各类别自动出售开关
  > 普通归箱
```

`IncludeExcludedItems=true` 只能授权归箱，不能授权出售。所有类别应合并进同一个商人
发现、一个有界出售 batch 和同一套提交前重校验；出售仍先于存箱。已提交但未确认的槽
本次留在背包，不能再进入 move RPC。

## 安全默认与配置建议

建议增加四个 scalar 设置：

```lua
AutoSellPalSpheres = false
PalSphereSellItems = ""
AutoSellFishingBait = false
FishingBaitSellItems = ""
```

用户界面显示保留状态，底层仍存显式出售 allowlist：

```text
界面：勾选 = 保留，不出售
内部：SellItems = 用户明确取消“保留”的当前合法 static IDs
```

这样有三层明确授权：用户开启总开关、用户取消某个条目的保留、运行时 exact-ID
allowlist 命中。未知 ID、损坏值、未来新增 ID 和本版本非法 ID全部忽略并默认保护。

不要像已有高价品的兼容迁移那样为这两个全新功能默认填满 allowlist；它们没有旧功能
语义需要维持。否则用户只打开总开关就会出售所有帕鲁球或钓饵，与显式授权原则冲突。

## UI 文案建议

主设置页使用与弹药、高价品平行的短文案：

| 用途 | 简体中文 | 繁体中文 |
|---|---|---|
| 总开关 | 自动出售帕鲁球 | 自動出售帕魯球 |
| 选择入口 | 保留的帕鲁球 | 保留的帕魯球 |
| 弹窗标题 | 选择要保留的帕鲁球 | 選擇要保留的帕魯球 |
| 弹窗说明 | 勾选的帕鲁球不会出售 | 勾選的帕魯球不會出售 |
| 总开关 | 自动出售钓饵 | 自動出售釣餌 |
| 选择入口 | 保留的钓饵 | 保留的釣餌 |
| 弹窗标题 | 选择要保留的钓饵 | 選擇要保留的釣餌 |
| 弹窗说明 | 勾选的钓饵不会出售 | 勾選的釣餌不會出售 |

摘要继续使用现有模式：`保留 10/10`、`保留 4/4`。选择器复用当前固定 checkmark、图标
和滚动条槽位；内部图片只有在有效纹理设置成功后才显示，避免白色默认 Brush。

设置顺序建议保持同一种信息结构：

```text
自动出售高价品
保留的高价品
自动出售弹药
保留的弹药
自动出售帕鲁球
保留的帕鲁球
自动出售钓饵
保留的钓饵
```

## 完整性复核

对物品主表 2466 行做完整遍历，得到：

```text
TypeB = SPWeaponCaptureBall                         12
... 且 TypeA = SpecialWeapon、bLegalInGame = true   10

TypeB = ConsumeFishingBait                           9
... 且 TypeA = Consume、bLegalInGame = true          4

合法候选有简中名称                                 14 / 14
合法候选有繁中名称                                 14 / 14
合法候选有唯一 Product_Id 配方                     14 / 14
合法候选有唯一 PAK 原生图标                        14 / 14
合法候选 Price > 0                                 14 / 14
```

该完整性检查同时验证了 `FishingBait_3_A` 应纳入、`PalSphere_Debug` 等不应纳入。

## 尚未确认的部分

- 没有运行游戏逐项卖出 14 种物品，不声称已验证实际到账、多人与专用服务器时序。
- `Price × SellItemRate` 是当前 cooked 设置与当前已分析的服务端计价模型；自定义服务器
  或未来版本可能改变最终金额。
- 当前数据没有为物品行提供一个独立“任务物品”布尔字段；本调查通过官方
  `TypeA/TypeB`、`bLegalInGame`、配方、本地化和图标做交叉验证，并明确排除了
  `Essential` 密钥球。若未来合法候选被赋予剧情用途，固定 catalog 仍需随版本人工复核。
- 尚未验证 10 项帕鲁球选择器在手柄下的完整滚动体验；这不影响候选集与安全默认。

