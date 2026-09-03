# Guild Chest 存入：其他模组与当前 Palworld 接口调查

调查日期：2026-09-03

## 结论

该功能可以实现，且已有同类 Quick Stack 模组证明单机、房主联机和 dedicated client 均可工作；但不能只删除 Quick Stack 现有的 Guild Chest 排除判断。

Guild Chest 不是普通基地箱。它是一个 **guild 级共享容器**，其地图实体使用独立的 `UPalMapObjectGuildChestModel` 和 `IPalMapObjectItemContainerAccessInterface`。正确实现需要单独完成以下步骤：

1. 验证玩家所属 guild 以及 guild role 是否允许访问 Guild Chest。
2. 验证候选 Guild Chest 实体属于本 guild。
3. 通过 Guild Chest 的专用 ItemContainer Access 接口请求复制并等待容器 ready。
4. 取得真实 `UPalItemContainer` 和 container GUID 后，继续复用现有过滤、容量规划和 `RequestMoveToContainer_ToServer`。
5. 按 container GUID 去重，并在提交前重新验证权限、实体和容器。

实现难点不是移动 RPC，而是远程客户端的 **权限、容器复制与 ready 时序**。

## 先区分三种行为

| 行为 | 是否等同于本需求 | 证据 |
| --- | --- | --- |
| 远程打开 Guild Chest UI | 否；只证明安全地发现/打开共享容器 | GuildChest Anywhere |
| 跨基地把材料计入制作/建筑 | 否；通常不把背包物品存入 Guild Chest | Integrated Storage / Storage+ |
| Quick Stack 自动从背包存入 Guild Chest | 是 | Stow And Behold |

因此，Integrated Storage 等模组支持“读取/消费 Guild Chest 材料”，不能单独证明 Quick Stack 的写入路径；真正直接对应本需求的是 Stow And Behold。

## 一手证据

### 1. Guild Chest 是 guild 级共享容器

Pocketpair 的 Feybreak 官方公告明确说明：放入一个 Guild Chest 的物品会在所有 Guild Chest 之间共享。这意味着同一 guild 的多个实体不能被当成多个独立库存累加或规划。

- [Palworld 官方 Feybreak v0.4.11 公告（Guild Chest 条目）](https://store.steampowered.com/news/posts/?enddate=1734919898&feed=steam_community_announcements)

存档结构也支持这一点：`worldSaveData.GuildExtraSaveDataMap[guild].GuildItemStorage.RawData` 保存一个 container id，该 id 指向 `ItemContainerSaveData` 中唯一的容器记录。

- [palworld-guild-chest-resizer：Guild Chest 存档结构说明](https://github.com/Leo927/palworld-guild-chest-resizer#how-it-works)

### 2. Guild Chest 有独立的容器访问和复制接口

当前公开 PalworldModdingKit 头文件显示：

- `UPalMapObjectGuildChestModel` 继承 `UPalMapObjectConcreteModelBase`；
- 它实现 `IPalMapObjectItemContainerAccessInterface`，不是普通箱子的 `GetItemContainerModule().TargetContainer` 模式；
- 它公开 `GetItemContainer_ItemContainerAccessInterface()`；
- 它公开 `RequestStartItemContainerReplication()` / `RequestStopItemContainerReplication()`；
- 它提供 ready callback 注册接口。

来源：

- [`UPalMapObjectGuildChestModel` 声明](https://github.com/localcc/PalworldModdingKit/blob/main/Source/Pal/Public/PalMapObjectGuildChestModel.h#L8-L53)
- [`IPalMapObjectItemContainerAccessInterface` 声明](https://github.com/localcc/PalworldModdingKit/blob/main/Source/Pal/Public/PalMapObjectItemContainerAccessInterface.h#L6-L37)

`UPalGuildItemStorage` 本身只有一个 replicated `UPalItemContainer* ItemContainer`，进一步说明远程客户端必须考虑该指针尚未复制完成的情况。

- [`UPalGuildItemStorage` 声明](https://github.com/localcc/PalworldModdingKit/blob/main/Source/Pal/Public/PalGuildItemStorage.h#L5-L26)

### 3. Guild role 权限独立于物品过滤权限

`UPalGroupGuildBase` 持有 replicated `GuildChestAllowedRoles`，并公开：

- `GetPlayerRole(PlayerUId)`；
- `IsGuildChestRoleAllowed(Role)`；
- `CheckGuildChestAccess(PlayerUId)`。

- [`UPalGroupGuildBase` 权限接口](https://github.com/localcc/PalworldModdingKit/blob/main/Source/Pal/Public/PalGroupGuildBase.h#L78-L174)

这与普通容器的物品类别/过滤权限不是一回事。即使共享容器的 `FilterPreference` 和 `Permission` 可读，也不能用它们替代 guild role 授权。

### 4. 现有移动 RPC 可以继续使用

`UPalNetworkItemComponent.RequestMoveToContainer_ToServer(RequestID, ToContainerId, Froms)` 是 `Reliable, Server` RPC；Quick Stack 当前已经使用相同三参数调用。

- [`UPalNetworkItemComponent` 声明](https://github.com/localcc/PalworldModdingKit/blob/main/Source/Pal/Public/PalNetworkItemComponent.h#L31-L44)
- [当前 Quick Stack 的提交路径](../../Scripts/quick_stack.lua#L1217-L1247)

头文件只证明 RPC 形状与网络方向，不证明服务端一定替模组完成 Guild Chest role 校验。因此客户端仍应显式调用 `CheckGuildChestAccess`，服务端拒绝行为也必须实测。

## 其他模组具体怎么做

### Stow And Behold：直接对应的 Quick Stack 实现

[Stow And Behold](https://www.nexusmods.com/palworld/mods/5336) 明确支持：

- 从玩家背包按过滤规则存入 Guild Chest；
- Guild Chest 可独立开关并参与候选优先级；
- 客户端安装即可，调用与玩家 drag-and-drop 相同的原生请求；
- 让 Palworld 的原生服务端规则继续控制是否允许移动到别的 guild；
- 单机、hosted co-op 和 dedicated server 均宣称支持。

其 1.0.1 changelog 还专门记录了 “Guild Chest did nothing on dedicated servers” 的修复。作者在修复前建议测试“先手动打开一次 Guild Chest 再按 F1”，这是很强的时序证据：普通扫描可能已经找到实体，但 dedicated client 上共享 `ItemContainer` 尚未复制/ready。

该模组未公开 C++ 源码，因此无法从一手源码确认它最终如何等待 ready；能确认的是产品行为、客户端原生移动请求路线、独立 Guild Chest 配置以及 dedicated 修复历史。

### GuildChest Anywhere：安全发现、权限与实体重解析模板

[GuildChest Anywhere 的作者发布包](https://www.curseforge.com/palworld/lua-code-mods/guildchest-anywhere/files/8541595) 是“远程打开原生 Guild Chest UI”，不是 Quick Stack，但其包内 Lua 源码和技术说明公开了适合复用的安全模式：

- 通过本地 UID 取得 guild；
- 调用 `CheckGuildChestAccess`；
- 只接受 `UPalMapObjectGuildChestModel`；
- 验证 map object/base camp 的 group id 与本地 guild id 一致；
- 缓存 GUID，不长期缓存 UObject；
- 每次操作通过 `UPalMapObjectManager.FindConcreteModel` 重新解析 live concrete model；
- 任何 guild、权限、所属关系或对象有效性无法证明时 fail closed。

这只证明“如何安全找到可访问的本 guild 实体”，不证明其 UI 打开链路等同于存入链路。

### Hotkey Quick stack to base chests：普通箱路线不含 Guild Chest

[Hotkey Quick stack to base chests](https://www.nexusmods.com/palworld/mods/3800) 使用客户端原生服务端调用，证明普通箱 Quick Stack 可在不安装服务端模组的情况下运行。Stow And Behold 作者在公开对比中指出，它扫描 item chests、supply boxes 和 feed boxes，但没有加入游戏单独管理的 Guild Chest class。

因此它只能证明现有普通箱 RPC 路线，不提供 Guild Chest 容器解析方案。

### Integrated Storage 系列：读取/消费共享库存，不是 Quick Stack

[Integrated Storage Reworked](https://www.nexusmods.com/palworld/mods/5290) 支持把 Guild Chest 纳入跨基地制作、建筑和 Item Retrieval Machine；其说明提到 direct container resolution、内部 GUID/container 索引、duplicate-registration protection，以及 dedicated server 要求服务端和客户端安装。

但作者在[公开回复](https://www.nexusmods.com/palworld/mods/5290?tab=posts)中明确说该模组不修改 bulk storage 逻辑。因此不能把它的 Guild Chest 支持等同于“可从背包 Quick Stack 存入”。

[Sarfflow 的原始 Integrated Storage 源码](https://github.com/Sarfflow/palworld-integrated-storage)仍可提供两点架构参考：按 guild GUID 隔离容器，以及按真实容器身份去重；它的目标仍是制作/建筑材料池，而不是 Quick Stack 写入。

### AutoSort Item Base：默认关闭是已有设计先例

[AutoSort Item Base](https://steamcommunity.com/sharedfiles/filedetails/?id=3776873388) 提供 `IncludeGuildChest`，默认关闭。它处理的是 authority-side 地面物品自动入库，不是玩家背包 Quick Stack；只能作为“把 Guild Chest 做成 opt-in”的产品设计参考，不能作为实现参考。

## 当前 Quick Stack 与正确改法的差异

当前代码已经解析 `PalMapObjectGuildChestModel`，但在分类阶段明确排除它：

- [Guild Chest class 与排除逻辑](../../Scripts/palworld.lua#L7-L15)
- [`destinationKind` 的 Guild Chest 排除](../../Scripts/palworld.lua#L533-L540)

普通候选统一通过 `concrete:GetItemContainerModule().TargetContainer` 取容器：

- [当前普通候选的容器解析](../../Scripts/quick_stack.lua#L752-L783)

这正是不能直接复用于 Guild Chest 的部分。其余流程已经具备大量可复用能力：

- container GUID 去重：`job.candidateKeys[key]`；
- 容器过滤、物品权限、容量和 stack room 读取；
- 按目标 container 合并请求；
- 提交前重解析和容量/来源复核；
- `RequestMoveToContainer_ToServer` 串行提交。

## 建议的最小正确实现

### 1. 独立配置与类型

- 新增 `IncludeGuildChest`（建议默认 `false`）。
- `destinationKind` 命中 Guild Chest 时返回独立的 `"guild_storage"`，不要伪装成普通 `"storage"`。
- 默认关闭可避免在没有完成联机验证前改变现有用户的目标集合。

### 2. 开始任务时建立 guild 安全上下文

仅当配置开启时：

1. 取得 local player UID。
2. 取得 local guild 与 guild GUID。
3. 调用 `CheckGuildChestAccess(playerUid)`。
4. 任一步骤不可读或返回 false，跳过 Guild Chest，而不是猜测允许。

### 3. 只接受当前基地、本 guild 的 Guild Chest 实体

- 保持 Quick Stack 的“当前基地”边界；当前基地没有 live Guild Chest 实体时，不因为其他基地存在 Guild Chest 就隐式开放远程存入。
- 验证 concrete class 为 `UPalMapObjectGuildChestModel`。
- 验证 map object 或 base camp 的 group id 等于 local guild GUID。
- 缓存 map object instance GUID；需要操作时用 manager 重新解析 live model/concrete，不长期持有 UObject。

虽然所有实体访问同一个 guild 级容器，仍建议要求当前基地有实体，这样功能语义保持“存入当前基地可访问的储物设施”，不会悄悄扩大为全局远程仓库。

### 4. 使用专用访问接口并等待 ready

Guild Chest 候选不要调用 `GetItemContainerModule()`。建议状态机：

1. 调用 `RequestStartItemContainerReplication()`；不能只因容器指针已经存在就
   假定其槽位内容已在 dedicated client 上完成复制。
2. 使用 ready callback，或采用有上限的延迟重试；只有容器指针与槽位数组均
   ready 后才继续，超时则安全跳过并记录原因。
3. 任务完成/取消/世界切换时，按确认过的原生生命周期配对清理复制请求。

是否可以无条件调用 `RequestStopItemContainerReplication()`、是否存在内部引用计数，目前没有源码证据，不能假定。实施前应先观察原生 Guild Chest UI 的 start/stop 调用时序，避免 Quick Stack 关闭了仍被其他 UI 使用的复制。

### 5. 把共享容器接入现有规划器

取得有效 `UPalItemContainer` 后：

- 读取 container GUID，继续使用 `candidateKeys` 去重；
- 读取 `ItemSlotArray`、`FilterPreference`、item `Permission` 与容量；
- Guild Chest filters 可沿用普通存储的物品筛选逻辑；
- guild role 权限仍单独处理；
- 同一 guild 的多个地图实体若解析为同一 container GUID，只加入一次；
- 不跨实体重复累计 `free`、`stackRoom` 或已有物品。

### 6. 提交前重新验证

现有普通箱 recheck 会重新取得 current concrete/module/container。Guild Chest 分支应改为：

1. 重新解析 current-base map object 与 concrete。
2. 再次验证 class、guild ownership 和 `CheckGuildChestAccess`。
3. 通过专用 accessor 重新取得容器。
4. 要求 container GUID 与规划时一致。
5. 重新读取 filters、slots 与容量。
6. 调用现有 `RequestMoveToContainer_ToServer`。

角色权限、共享库存和剩余容量都可能在规划后被其他 guild 成员改变，不能只在扫描阶段验证一次。

## 必须完成的游戏内验证

- 单人。
- listen host。
- listen client。
- dedicated client；尤其验证刚进基地、从未手动打开 Guild Chest 的情况。
- 允许角色与拒绝角色。
- 当前基地有 Guild Chest / 没有 Guild Chest。
- 同一 guild 的两个基地都放置 Guild Chest，确认只规划一次共享容器。
- 满箱、部分 stack room、空槽、filters、物品类别限制。
- 规划和提交之间，另一成员移动物品或改变角色权限。
- 世界切换、重连、Guild Chest 被拆除或新建。
- Quick Stack 操作时原生 Guild Chest UI 同时打开，确认 replication start/stop 不互相破坏。

## 未知点

1. Stow And Behold 未公开源码，无法确认其 dedicated 修复究竟采用 ready callback、延迟重试还是另一条容器解析路径。
2. `RequestMoveToContainer_ToServer` 的服务端实现未公开；必须实测它对无权限角色、外国 guild container id 和过期 container id 的拒绝行为。
3. ItemContainer Access replication 是否引用计数、何时安全调用 stop，公开头文件没有说明。
4. Guild Chest 的 filters/物品权限在所有客户端上的复制 ready 时序需要实测。
5. “当前基地没有实体但 guild 在其他基地已有 Guild Chest”是否应允许存入属于产品语义决策；本调查建议不允许，以保持 Quick Stack 当前的 current-base 范围。

## 置信度

- 功能可实现：**高（90%）**。已有直接竞品在 dedicated client 上发布并修复。
- 现有移动 RPC 可复用：**高（90%）**。公开头文件与当前实现一致，竞品也说明使用原生 drag-and-drop 请求。
- 只删除排除判断即可可靠工作：**低（20%）**。公开接口和竞品 dedicated 修复均反证这一点。
- 不做游戏内联机验证即可发布：**很低（10%）**。最大风险明确集中在远程客户端的 replication readiness 和 guild role 权限。
