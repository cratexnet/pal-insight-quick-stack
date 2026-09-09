# Palworld 1.0 同类 Quick Stack 模组的基地库存同步调查

调查日期：2026-09-09

## 结论

**有同类问题，而且现象高度一致。** Base Stash 作者明确记录：远离箱子时，物品会从玩家库存移入或移出，但箱子显示仍是旧状态；走近或打开箱子后立即恢复。作者把它归因于 dedicated server 上箱子的 network relevancy，并提供了一个服务端 companion mod 扩大箱子复制范围。

但当前 Quick Stack 报告的主要症状不是“远程查看箱子内容”，而是“工作台材料总量不刷新，同时 Item Retrieval Machine 显示正确”。因此，照搬 Base Stash 的服务端 relevancy 扩展不是合适的客户端修复；最可信的客户端方案是复用原版 Inventory Quick Stack 已使用的 **基地物品堆栈复制生命周期**：

1. `RequestStartReplicateLocalPlayerBaseCampItemStackInfo`
2. `CallOrRegisterOnReadyLocalPlayerBaseCampItemStackInfo`
3. `SubscribeLocalPlayerBaseCampItemStackInfoUpdated`
4. 执行现有精确目标移动 RPC
5. 收到最终 RPC 之后的基地堆栈更新
6. `UnsubscribeLocalPlayerBaseCampItemStackInfoUpdated`
7. `RequestEndReplicateLocalPlayerBaseCampItemStackInfo`

该方案保留当前按过滤器、Incubator、Recycler、Guild Chest 和容量规划的精确目标语义，只补上 dedicated client 缺失的基地聚合库存刷新订阅。

## 同类问题的一手证据

### Base Stash：物品实际已移动，但远处客户端状态不更新

Base Stash 的作者页面直接说明：

- dedicated client 必须处于箱子的正常网络范围内，才会看到 live contents；
- 如果距离过远，物品仍然会移动，但显示可能不变；
- 靠近或打开箱子会使显示恢复；
- 作者另发了 server-side-only 的 `Base Stash Server Relevancy`，把箱子可见范围扩大到基地建造边界。

来源：

- [Base Stash 作者说明、兼容性与已知限制](https://www.nexusmods.com/palworld/mods/4563)
- [Base Stash Server Relevancy 作者发布文件](https://www.nexusmods.com/palworld/mods/4563?show_file=20227&tab=files)

这与 Lefayae 报告的“靠近 storage area 一次后就正常”是同一类网络可见性/复制触发现象。区别在于 Base Stash 讨论的是单个箱子的 live contents，而本次报告进一步暴露了工作台使用的基地聚合材料缓存。

### Stow And Behold：打开一次 Guild Chest 是作者采用过的 replication 诊断

Stow And Behold 作者在 dedicated-server Guild Chest 问题上要求用户先打开一次 Guild Chest，再运行自动存放。这同样表明“实体已经能被扫描到”不等于客户端已经取得可用的容器复制状态。

- [Stow And Behold 作者在 Posts 中的 dedicated/Guild Chest 排查建议](https://www.nexusmods.com/palworld/mods/5336?tab=posts)

该模组未公开 C++ 源码，因此这个来源只能证明作者观察到相同的 ready/relevancy 边界，不能证明其最终修复实现。

### Hotkey Quick Stack：客户端原生 server calls 可行，但没有公开刷新实现

Hotkey Quick Stack 作者说明该模组只需安装在客户端，因为它使用服务器原本接受的标准游戏调用；1.12 文件说明还记录了一个 co-op server 修复。其页面没有公开可审查源码，也没有说明是否管理基地物品堆栈复制，因此不能把它当成刷新方案的实现证据。

- [Hotkey Quick Stack 作者 Posts：client-only、standard game calls 与 co-op 修复确认](https://www.nexusmods.com/palworld/mods/3800?tab=posts)
- [Hotkey Quick Stack 1.12 文件说明](https://www.nexusmods.com/palworld/mods/3800?show_file=17990&tab=files)

## 原版接口为什么支持这个修复方向

当前 PalworldModdingKit 的公开 1.0 SDK 头文件暴露了完整的基地聚合库存复制 API：

- start/end replication；
- ready callback；
- updated subscribe/unsubscribe；
- 原版 `RequestMoveInventoryItemToBaseCamp`。

- [`UPalBaseCampUtility`，固定到调查时 commit](https://github.com/localcc/PalworldModdingKit/blob/e6632458b97af0083eb81715775651b08104ef6a/Source/Pal/Public/PalBaseCampUtility.h#L17-L42)

`UPalBaseCampModuleItemStackInfo` 自身包含 replicated `ItemStackRepInfoArray`、`OnRep_ItemStackRepInfoArray` 和更新 delegate；它还监听 item container 的更新与 concrete model 的 available/not-available 状态。这说明工作台/原版 UI 使用的是独立于单个箱子 live UI 的基地聚合堆栈模块。

- [`UPalBaseCampModuleItemStackInfo` replicated array 与更新 delegate](https://github.com/localcc/PalworldModdingKit/blob/e6632458b97af0083eb81715775651b08104ef6a/Source/Pal/Public/PalBaseCampModuleItemStackInfo.h#L15-L53)

两个回调类型也在公开 SDK 中有精确签名：

- ready：`(UPalBaseCampModel* Model, UPalBaseCampFunctionModuleBase* Module)`；
- updated：`(UPalBaseCampModuleItemStackInfo* ItemStackInfoModule)`。

- [`FPalBaseCampModuleDelegate`](https://github.com/localcc/PalworldModdingKit/blob/e6632458b97af0083eb81715775651b08104ef6a/Source/Pal/Public/PalBaseCampModuleDelegateDelegate.h#L5-L8)
- [`FPalBaseCampItemStackInfoUpdatedDynamicDelegate`](https://github.com/localcc/PalworldModdingKit/blob/e6632458b97af0083eb81715775651b08104ef6a/Source/Pal/Public/PalBaseCampItemStackInfoUpdatedDynamicDelegateDelegate.h#L5-L7)

本仓库对当前 Steam build 的只读反射/资产调查进一步确认，原版 `WBP_InventoryEquipment` 的 Quick Stack 流程确实按 start → ready → subscribe updated → update → finish/end 的顺序运行；参见[现有 runtime contract](../runtime-contract.md#native-ui-semantics)。这比任何第三方模组的猜测更接近原版行为。

## UE4SS 实现边界

UE4SS 官方文档确认：

- single-cast delegate 的值是 `{ Object, FunctionName }` 表；
- multicast delegate 可用 `Add` / `Remove` 管理绑定；
- `RegisterHook` 明确不支持 delegate functions。

来源：

- [UE4SS DelegateProperty](https://docs.ue4ss.com/dev/lua-api/classes/delegateproperty.html)
- [UE4SS MulticastDelegateProperty](https://docs.ue4ss.com/dev/lua-api/classes/multicastdelegateproperty.html)
- [UE4SS RegisterHook 限制](https://docs.ue4ss.com/dev/lua-api/global-functions/registerhook.html)

因此，不应尝试直接 hook delegate signature。稳妥实现需要一个真实 UObject 上、签名匹配的 reflected UFunction 作为回调目标；然后把它组成 dynamic delegate 传给 ready/subscribe API。若现有 runtime bridge 已有匹配 UFunction，优先复用；否则应增加最小 cooked bridge，而不是使用固定延时猜测同步完成。

官方文档证明了 delegate 的表达和绑定机制，但没有单独保证当前 Okaetsu experimental Palworld build 对“把 Lua table 直接作为 native UFunction delegate 参数”的 marshalling 行为。这个 ABI 点必须做一次窄范围游戏内验证。

## 推荐实现

### 客户端网络连接

在一次 F5 generation 内持有一份基地堆栈 replication lease：

1. 解析并冻结当前 world、controller、player、base identity。
2. 调用 start，并注册 ready callback；ready 前不提交移动。
3. ready 后立即订阅 updated，再运行现有扫描、规划和直达目标 RPC。
4. 记录 final destination RPC 的提交序号/时间点。
5. 现有 source-slot replication 确认完成后，还必须观察到至少一次 final RPC 之后的基地堆栈 updated callback，才把本次联机任务判为同步完成。
6. success、error、timeout、取消、世界切换、base/controller identity 改变、新 generation 覆盖旧 generation 时，都必须 exactly-once unsubscribe/end。

### 单机/authority

继续使用当前路径，不额外开启客户端 replication lease。原版 UI 的 Blueprint 流程同样先检查 client connection；没有证据支持在 authority 路径上无条件 start/end。

### 不建议的替代方案

- **固定延时后结束**：不能证明跨 ping、server load 和远距离 relevancy 时已收到聚合更新。
- **自动打开目标箱子**：改变 UI/焦点状态，只刷新单个容器，并不能证明工作台聚合材料缓存已更新。
- **要求服务器安装 relevancy mod**：能解决远程箱子 live contents，但违背当前 client-only 产品边界，也不是工作台聚合缓存的最小修复。
- **改用原版自动 Quick Stack RPC**：无法保留当前 caller-selected destination、filters、Incubator/Recycler 和 Guild Chest 路由语义。

## 置信度变化

| 判断 | 调查后置信度 | 原因 |
| --- | ---: | --- |
| 存在同类问题 | 95% | Base Stash 作者直接记录“实际移动、显示不变、靠近/打开后恢复”。 |
| 根因属于 dedicated-client replication/relevancy，而非移动失败 | 90% | 同类报告、Item Retrieval Machine 正确、靠近后恢复三点相互支持。 |
| 最可信修复是原版基地堆栈 start/ready/subscribe/end 生命周期 | 90% | 当前 SDK 暴露完整 API，且原版 Inventory Quick Stack 资产采用同一流程。 |
| 第一次代码修改无需联机验证即可发布 | 25% | dynamic delegate marshalling、updated 事件时序和 cleanup 必须在 dedicated client 验证。 |
| 完成 targeted dedicated-client 验证后可形成可靠修复 | 85% | 主要未知点集中在回调桥接和最终更新判定，不在移动/路由逻辑本身。 |

## 最小验收场景

1. dedicated client TP 到基地后，不靠近、不打开目标箱子，直接 F5。
2. 目标箱位于正常 relevancy 范围外；至少移动一种工作台配方材料。
3. F5 完成后直接打开工作台，数量立即正确。
4. Item Retrieval Machine、目标箱和玩家源槽数量一致。
5. 连续 F5、任务超时、TP/离开基地、world/controller 切换后，下一次 F5 仍能正常工作，且没有遗留 replication subscription。
6. 单机路径没有行为退化。
