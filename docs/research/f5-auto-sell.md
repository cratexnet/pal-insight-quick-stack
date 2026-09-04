# F5 自动出售：Palworld 1.0 静态调查

## 结论

当前版本可以将自动出售作为 F5 Quick Stack 存储路由前的一个独立阶段，但必须从当前基地的工作 Pal 中获取一个真实商人的 `UPalVenderDataComponent` 和已注册的 item shop。不应构造伪 ShopID，也不应全世界搜索商人。出售后先等待并重读源槽；一旦出售 RPC 已提交，任何未确认的剩余物品都应留在背包而不再进入本次存储路由，避免迟到的出售与同槽位移动请求并发。

已证实当前 RPC ABI 为：

```text
UPalNetworkShopComponent::RequestSellItems_ToServer(
    ShopID: FGuid,
    SellItemSlotIDArray: TArray<FPalItemSlotIdAndNum>
)
```

这与旧 dumped header 中含 `RequestPlayerUId` 的三参数签名不同。当前 server handler 会从 RPC 调用方自行解析玩家，先对 `ShopID` 做 server-side item-shop map 精确查找，再对每个 slot/count 做容器、索引、数量及移除检查。查不到 shop 时直接返回；无效条目不计价。

商店 UI 不需要保持打开。当前 cooked blueprint 的顺序是先 `SetupShopData` / 等待 registered delegate / `TryGetItemShop`，最后才打开 UI；server 出售路径也不检查 UI、距离或 vendor actor。UI 是 shop 的消费者，不是 shop 的生命周期所有者。

## 调查对象

- 当前 EXE：`F:\SteamLibrary\steamapps\common\Palworld\Pal\Binaries\Win64\Palworld-Win64-Shipping.exe`
  - size: `161397248`
  - mtime: `2026-08-12`
  - SHA-256: `FE3C15064524BAE1947852467C4F92BC22469ACC033A3D3C8031EAB4324E41E8`
- 当前 PAK：`F:\SteamLibrary\steamapps\common\Palworld\Pal\Content\Paks\Pal-Windows.pak`
  - size: `40527155723`
  - mtime: `2026-08-12`
- 已落地 header：`D:\Workspace\pal-insight\research\palworld-dumped-header-gist\Pal.hpp`

证据标记：

- **已证实**：当前 EXE 控制流/反射元数据或当前 cooked asset 直接支持。
- **推断**：多项一手证据一致，但未运行游戏验证。
- **未知**：静态证据不足以给出保证。

## RPC 与服务端校验

### 当前两参数 ABI（已证实）

- `RequestSellItems_ToServer` ASCII 名称位于 EXE file offset `0x7613ED8`。
- native registration pair 位于 file offset `0x7617AC0`，指向 exec thunk `0x142A30C50`。
- thunk 只解析两个参数：一个 16-byte `FGuid` 和一个 `TArray`，然后调用 native handler `0x142C83620`。
- 参数元数据包含 `ShopID` 和 `SellItemSlotIDArray`，不存在该函数的第三个 `RequestPlayerUId` 解析步骤。

旧 header 仍有用于确认类型形状，但不能直接用于当前 RPC 调用：

```cpp
// 旧签名，当前版本已过时
void RequestSellItems_ToServer(
    const FGuid& RequestPlayerUId,
    const FGuid& ShopID,
    const TArray<FPalItemSlotIdAndNum>& SellItemSlotIDArray);
```

`FPalItemSlotIdAndNum` 的已落地布局是 `SlotID` + `Num`，总大小 `0x18`；`SlotID` 是 `ContainerId(FGuid)` + `SlotIndex(int32)`。

### ShopID 校验（已证实）

native handler `0x142C83620` 的关键路径：

1. 从 network component owner 解析请求玩家，并获取该玩家的物品容器/通用背包上下文。
2. 获取 `UPalShopManager`。
3. 在 `0x142C83772` 调用 `0x14323D060(manager, ShopID, &OutShop)`。
4. `0x14323D060` 对 manager `+0xF8` 的 item-shop map 做 `FGuid` 精确查找；未命中返回 `false`。
5. handler 未命中时立即返回。

查找成功后得到的 `OutShop` 指针在后续出售控制流中没有再被解引。后续路径不接收 vendor actor，也没有 UI 状态或玩家与商人距离判定。因此：

- server 端的商店门槛是 **ShopID 当前存在于 item-shop map**。
- 打开商店 UI 不是 server handler 的先决条件。
- 不能使用 zero/random/cached-across-world ShopID；这些值将查找失败。

### slot/count 校验与移除（已证实）

对数组中的每个 `FPalItemSlotIdAndNum`，server 会：

- 根据 container GUID + slot index 重新解析 slot（`0x142FB81D0`）。
- 拒绝空 GUID、`SlotIndex == -1` 和 `Num <= 0`。
- 校验当前 stack 数不小于请求数。
- 通过容器的 server-side removal 路径（`0x142FACF40`）移除成功后，才读取 static item ID/count 计算价格。
- 使用 `CalcItemSellPrice` 路径（`0x14321E470`）与 game setting `SellItemRate`，最后把成功条目价格累加到玩家货币容器。

客户端仍必须在发送前重新读取 slot 并限定白名单；server 校验是安全网，不是放宽客户端选择的理由。

## ShopID 的合法来源与生命周期

### 反射路径（已证实/旧 header 交叉验证）

```text
/Script/Pal.PalVenderDataComponent
  SetupShopData() -> void
  TryGetItemShop(OutShop: UPalShopBase&) -> bool
  IsValidItemShop() -> bool
  MyItemShop: UPalShopBase* (replicated; OnRep_MyItemShop)

/Script/Pal.PalShopBase
  GetId(OutID: FGuid&) -> void
```

实现应从 `TryGetItemShop` 成功返回的 shop 调用 `GetId`，不应直接猜测组件字段偏移。旧 header 同时显示 `UPalShopBase::MyShopID`，但使用公开反射 getter 更稳定。

### Setup 与 UI 的关系（已证实）

当前 EXE 中 `UPalVenderDataComponent::SetupShopData()` 的 native 路径会：

1. 获取拥有该组件的 actor/network shop component。
2. 生成/设置 shop GUID 上下文。
3. 向 server 发送 `SetupShopDataForActor_ToServer(VenderActor)`。

server setup handler `0x142C87700` 要求 actor 上恰好一个 vendor data component，然后用 actor/vendor 的 GUID：

- item-shop map 已有该 key：复用既有 shop，回填 vendor component。
- 无该 key：server 创建并注册 shop，再回填 vendor component。

当前 cooked asset
`Pal/Content/Pal/Blueprint/FlowGraph/NPCTalkFlow/CommonNode/FNBP_OpenItemShop`
包含清晰的 `SetupShopData` -> `OnRegisteredItemShopDelegate` -> `TryGetItemShop` -> `OpenItemShop_*` 路径。所以 shop 注册是打开 UI 之前的异步先决步骤，而不是 UI 打开后才存在的临时对象。

### UI 关闭后是否仍有效

- **已证实**：出售 server handler 不查 UI，也不查距离。
- **已证实**：当前 EXE 中已无旧版 `RemoveShopData_ToServer` 反射名/字符串；cooked `WBP_ItemShop` 关闭路径也没有该调用名。
- **推断（高置信）**：UI 关闭不会从 server map 删除 shop，因此同一 world/vendor 生命周期内的 `MyItemShop:GetId()` 仍可用。
- **未知**：shop 在 vendor unload/destroy、world travel 或 server 内部清理时的精确回收点。因此不得跨 world/base generation 缓存 ShopID。

## 当前基地商人发现

安全发现路径：

1. 沿 F5 已有 fail-closed context 解析同一 local player、controller、current base 和 generation。
2. 只枚举 **current-base object IDs / worker handles**，解析其当前 actor。
3. 对每个 actor 查找 `/Script/Pal.PalVenderDataComponent`；没有该组件就不是候选商人。
4. 对候选组件调用 `SetupShopData()`，在有界 frame/time budget 内等待 `TryGetItemShop` 成功。
5. 从 `UPalShopBase::GetId(OutID)` 取 ShopID。
6. 在发送 sell RPC 前重新验证 actor 仍属于同一 current base、component/shop 仍有效。

`UPalBaseCampManager::GetInRangedBaseCamp(Location, Margin) -> UPalBaseCampModel*` 在已落地 header 中有签名，当前 EXE 仍有该反射名。因此可用：

```text
vendorData.GetOwner().GetActorLocation()
  -> BaseCampManager.GetInRangedBaseCamp(location, 0)
  -> 与 job.currentBase 做对象/ID 相等比较
```

这只应作为提交前的二次空间验证，不应替代 current-base object ID 发现路径。禁止用 `FindAllOf(PalVenderDataComponent)` 扫全世界后再按距离过滤。

## 推荐的 fail-closed 实现

1. `AutoSellValuables = false` 时完全不进入 shop 发现/出售阶段。
2. 出售阶段在存储 move 规划前执行；确认或超时并重读源槽后才继续。RPC 已提交但仍未确认的物品留在背包，不再参与本次容器 move，因此两个 RPC 不会争用同一槽位。
3. 仅使用已解析的 current-base worker actors 查找 vendor component。
4. 如果没有 current-base merchant、setup 超时、`TryGetItemShop` 失败或 ShopID 为空：取消 sell phase，让物品继续走原有 Quick Stack 路由。若 generation/world/base/player 变化，则取消整个过期 job。
5. 重新扫描玩家通用背包，只收集精确 static ID 白名单中的 slot；Tab -> R 排除列表的优先级更高。
6. 在组装 RPC 数组前再次读取 slot 的 container ID、slot index、static ID 和 stack count。任意一项无法验证就跳过该 slot。
7. 只发送一个有界 sell batch RPC；空数组不发送。
8. Shop 对象和 ShopID 只存活于当前 generation，不持久化、不跨 world/base 复用。

## “商人高价收购”白名单的当前游戏数据证据

### 提取路径与完整性（已证实）

本机当前安装的 `Pal\Content\Paks` 目录只有一个游戏 PAK：
`F:\SteamLibrary\steamapps\common\Palworld\Pal\Content\Paks\Pal-Windows.pak`
（`40527155723` bytes，mtime `2026-08-12 12:38:35`）。对该 PAK 的完整文件清单筛选后，物品描述 DataTable 只有以下基础表及其简体中文本地化覆盖，没有第二个 `DT_ItemDescriptionText_*` 表：

```text
Pal/Content/Pal/DataTable/Text/DT_ItemDescriptionText_Common.uasset/.uexp
Pal/Content/L10N/zh-Hans/Pal/DataTable/Text/DT_ItemDescriptionText_Common.uasset/.uexp
```

使用 `repak` 从当前 PAK 逐文件提取，再以 `UAssetGUI`、`VER_UE5_1` 和当前
`Palworld_1_0_2FF94A03.usmap` 映射导出 JSON。映射 SHA-256 为
`241C45DE9D5B55B246CD4B39D62B9209FAF7758CE0637E1F7A545AA0F75F71F0`。
可复核产物位于：

```text
D:/Workspace/pal-insight/toolchain/work/auto-sell-research/
  Pal_Content_L10N_zh-Hans_Pal_DataTable_Text_DT_ItemDescriptionText_Common.uasset
  Pal_Content_L10N_zh-Hans_Pal_DataTable_Text_DT_ItemDescriptionText_Common.uexp
  ItemDescriptions-zh-Hans.json
  DT_ItemDataTable_Common.json
```

关键 SHA-256：

```text
zh-Hans uasset  96EB394DD07D9EAE25FC8C7B192B5A86BC853A490CA32B4472FF5DF1549D08AE
zh-Hans uexp    E64885D219F26665A5FDC10DCF30F0FEEB130C74DCF3CC0A313E3BB6C3A85154
description JSON D9F9058207309478E4A89467218C329B23CD5187B21AA339A632F0E5EE93CE1E
item-data JSON   D03E2C6EA1A8ABF65C0CE4048EE5F6C1A67D82E8F6C390DD4A96B304065FE423
```

简体中文描述表共有 `1924` 行。对所有行的 `TextData.CultureInvariantString` 做完整匹配，包含“商人”且包含“高价”的行恰好 `9` 行；不存在第 10 行。基础日文表的同义句“商人が高値で買い取ってくれる”也恰好命中相同 9 个 row key。因此，这 9 项对当前已安装游戏数据中的该语义是**完整覆盖**，不是从名称或售价猜出的候选集合。

### 精确命中结果（已证实）

| Static Item ID | 简体中文当前描述 | `DT_ItemDataTable_Common` 的 `Price` |
|---|---|---:|
| `Ruby` | 闪耀着红光的宝石。可被商人高价收购。 | 20000 |
| `Sapphire` | 闪耀着蓝光的宝石。可被商人高价收购。 | 30000 |
| `Eemerald` | 闪耀着绿光的宝石。可被商人高价收购。 | 40000 |
| `Diamond` | 闪耀着璀璨光芒的稀有宝石。可被商人高价收购。 | 50000 |
| `PalItem_ToSell_01` | 可从帕鲁身上获得的珠子，像宝石一样。可被商人高价收购。 | 15000 |
| `PalItem_ToSell_02` | 可从帕鲁身上获得的羽毛，闪闪发光。可被商人高价收购。 | 10000 |
| `PalItem_ToSell_03` | 可从帕鲁身上获得的心脏，在不停跳动。可被商人高价收购。 | 12500 |
| `PalItem_ToSell_04` | 可从帕鲁身上获得的爪子，十分尖锐。可被商人高价收购。 | 7500 |
| `PalItem_ToSell_05` | 可从帕鲁身上获得的毛，十分松软。可被商人高价收购。 | 5000 |

`DT_ItemDataTable_Common` 共有 `2466` 个 static item rows，并且以上 9 个 row name 均精确存在。它们的 `OverrideDescription` 都未设置；描述表使用对应的 `ITEM_DESC_<StaticItemID>` row key。由此可确认 RPC 白名单应使用表中的 static row name（上表第一列），不能用本地化名称或描述文本进行运行时匹配。

需要区分两种结论：

- **已证实**：当前简中描述表中，“可被商人高价收购”语义完整且仅对应这 9 个 row key；当前 item data 中也存在同名的 9 个 static item rows。
- **推断（高置信）**：`OverrideDescription` 为空时，游戏按既有 `ITEM_DESC_<StaticItemID>` 约定取描述。基础表、简中覆盖表和 item row 的 9 个后缀一一相同，且游戏数据没有冲突项。
- **不采用的推断**：不能仅按 `Price` 阈值扩展白名单；其他高售价物品没有该描述语义，用户要求的是描述白名单而不是价格白名单。

据此，当前版本的 9 个精确 ID 白名单为：

```text
Ruby
Sapphire
Eemerald
Diamond
PalItem_ToSell_01
PalItem_ToSell_02
PalItem_ToSell_03
PalItem_ToSell_04
PalItem_ToSell_05
```

`Eemerald` 是游戏内部的现有拼写，不应修正为 `Emerald`。

## 仍未静态证实的项目

- UE4SS Lua 对当前 `TArray<FPalItemSlotIdAndNum>` 的具体构造语法与 out-parameter 绑定细节；ABI 已确定，但 Lua bridge 仍需按本项目现有 struct/array 模式落地。
- current-base worker ID 到活 actor 的现有 resolver 是否能在所有 dedicated/listen/single-player 路径下得到 vendor component。
- 商人被 unload/destroy 时 server map 的精确清理点。因为实现必须每次在当前 generation 重新获取 ShopID，该未知项不需要通过跨生命周期缓存来冒险。
- 静态调查未实际运行游戏。因此不声称已验证多人时序或 UE4SS bridge 运行结果。

## 最终安全边界

可以实现的产品行为是：用户明确开启开关后，F5 在存储路由前，若当前基地存在可注册的商人，则向该商人的真实 ShopID 提交一个白名单出售 batch；确认源槽结果后再继续归箱，未确认的贵重物品留在背包并明确报告。没有合法商店上下文时跳过出售，仍走原有归箱。静态证据不支持“无当前基地商人也能构造虚拟 ShopID 出售”，该路径应明确禁止。
