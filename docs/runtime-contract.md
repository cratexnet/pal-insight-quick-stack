# Runtime Contract: Pal Insight: Quick Stack

## Decision

Production routing may use the current-build object paths recorded below. It
may call `RequestMoveToContainer_ToServer` only with the verified three-
argument layout below. The one-shot probe resolved reflection metadata only;
it did not invoke the function or read or mutate inventory state.

## Evidence Identity

- Steam app: Palworld `1623730`
- Installed Steam build ID: `24575825`
- Installed executable SHA-256:
  `FE3C15064524BAE1947852467C4F92BC22469ACC033A3D3C8031EAB4324E41E8`
- Installed executable timestamp: `2026-08-12T12:38:35+08:00`
- Compatible current-1.0 mapping:
  `D:\Workspace\pal-insight\toolchain\tools\UAssetGUI\Data\Mappings\Palworld_1_0_2FF94A03.usmap`
- Mapping SHA-256:
  `241C45DE9D5B55B246CD4B39D62B9209FAF7758CE0637E1F7A545AA0F75F71F0`
- Installed reference runtime SHA-256:
  `0B2A028E68ED6FC233970420A128E180A27FD28CE3EF9C798641542A099BF544`

The cooked assets used below were extracted read-only from the installed
`Pal-Windows.pak`. The two primary assets are byte-identical to the retained
evidence tree:

- `WBP_InventoryEquipment.uasset`:
  `1BDAFD8E35ED51599D27F8B2880AD168AA4A075C03A70D9FCCD6B85150459460`
- `WBP_IngameMenu_ChestManage.uasset`:
  `0A96B30CF72B6CAFFB7054312F2BBFEF6695A86B7E537FE9CB1D7539ECAD4767`

The repository's `research/palworld-dumped-header-gist/Pal.hpp` is explicitly
documented as a 2024-01-19 snapshot. It is used only to explain legacy
architecture and never as sole proof of a current signature or field.

## Current-Build Object Route

| Boundary | Current evidence | Production contract |
|---|---|---|
| Local controller | UE4SS exposes `FindFirstOf`; installed `UEHelpers.GetPlayerController()` globally enumerates controllers; current `PalPlayerController` mapping contains `Transmitter` | Reuse a validated cached local controller. On cache miss, try `FindFirstOf("PlayerController")` and require `IsLocalPlayerController()`; use UEHelpers only as a cold compatibility fallback when the direct result is absent or non-local |
| Local pawn and base | Current `WBP_InventoryEquipment` calls `PalInsideBaseCampCheckComponent.GetInsideBaseCampModel()` with zero arguments; current mapping contains `NowInsideBaseCampID` | Resolve the pawn from the verified controller, then resolve the base from its inside-base component; require a non-zero matching base identity |
| Job identity guard | UE4SS exposes the underlying UObject address through `GetAddress()`. The installed `UEHelpers.GetPlayerController()` performs a global `FindAllOf("PlayerController")`; measured repeated calls cost roughly 35–40 ms each, while rebuilding and comparing the remaining identity snapshot costs about 1 ms | Resolve and locally validate the controller once at job start, then reuse that controller only for the job lifetime. Before each slice, re-read and validate controller, player state, pawn, inside-base component, base, and world; compare all native addresses plus the base GUID. Abort when any value is unavailable or differs |
| Base object IDs | Current mapping has `PalBaseCampModel.MapObjectCollection`; current collection has `MapObjectInstanceIdRepInfoArray`; `PalFastBaseCampMapObjectRepInfoArray.Items` contains `PalBaseCampMapObjectRepInfo.InstanceId` | Enumerate only `base.MapObjectCollection.MapObjectInstanceIdRepInfoArray.Items[*].InstanceId`; the old `MapObjectInstanceIds` field is invalid for 1.0 |
| Map-object model | Current `WBP_IngameMenu_ChestSetting` calls `PalUtility.GetMapObjectManager(context)` and then `PalMapObjectManager.FindModel(instanceId)` | Resolve the manager once per job and call `FindModel` only for IDs in the current base snapshot |
| Concrete model and container | Current mapping exposes `PalMapObjectModel.ConcreteModel`; current `WBP_Ingame_Incubator` calls `PalMapObjectConcreteModelBase.GetItemContainerModule()` with zero arguments; current module mapping exposes `TargetContainer` | Require a valid concrete model, a valid item-container module, and a valid target container; unsupported models are recorded and skipped without global fallback |
| Common inventory | Current mapping exposes `PalPlayerState.InventoryData`, `PalPlayerInventoryData.MyInventoryInfo.CommonContainerId`, and `InventoryMultiHelper`; current enum maps `EPalPlayerInventoryType.Common` to `0` | From the verified local player state, match the common container ID against its small owned container set; missing, duplicate, or unreadable matches abort the whole job |
| Exclusions | Current `WBP_InventoryEquipment.AddExceptItem` resolves the local player state, calls `GetLocalRecordData()`, and calls `AddQuickStackExceptId`; its grey-out path reads `Local_ItemQuickMoveExceptionIDList`. Current mapping records that field as `Array<NameProperty>` | Read only the same verified local player's record array. Any read/decode failure aborts the whole job. Empty is valid only after a successful array read |
| Tab input ownership | Current `WBP_InGameMainMenu_C` exposes `IsActivated()` and `CurrentContentWidget`; its cooked asset imports `WBP_InventoryEquipment_ForDisplay_C` as the Inventory/Equipment content class | Track the naturally created main-menu instance through `NotifyOnNewObject`. With the UI cursor visible, allow F5 only when that exact menu is valid and activated and its current content `IsA(WBP_InventoryEquipment_ForDisplay_C)`; otherwise fail closed without `FindAllOf` |
| Item metadata | Current `WBP_PalItemListBlock` calls `PalUtility.GetItemIDManager(context)` and `PalItemIDManager.GetStaticItemData(staticId)`; current static-item mapping exposes `TypeA`, `TypeB`, and `MaxStackCount` | Cache metadata only for unique IDs present in the job snapshot |
| Chest category filters | Current mapping exposes `PalGameSetting.ItemFilterPreference.PreferenceMap`, category `TypeA`, `TypeB`, and `TypeB_Except`, plus `PalItemContainer.FilterPreference.FilterOffList` | Build the category table once per job from `PalUtility.GetGameSetting(context)`; map each unique item ID once, then index accepting containers by category |
| Permission and capacity | Current mapping exposes container and slot `Permission`, `ItemSlotArray`, `StackCount`, and static `MaxStackCount` | A destination is eligible only when its permission admits the item and it has matching-stack room or an empty slot. Recheck before submission |
| Incubators | Current mapping includes `PalMapObjectHatchingEggModelBase`; current incubator UI uses the same concrete-model item-container module route | Classify a current-base concrete model with `IsA("/Script/Pal.PalMapObjectHatchingEggModelBase")`; incubators are indexed separately and never discovered globally |
| Guild Chest exclusion | Current `BP_BuildObject_GuildChest` asset binds its concrete model to the native `/Script/Pal.PalMapObjectGuildChestModel` class | Resolve this class before destination discovery and reject matching models before all generic storage-family checks. If the class is unavailable, fail closed instead of risking a Guild Chest move |
| Network component | Current mapping exposes `PalPlayerController.Transmitter` and `PalNetworkTransmitter.Item` | Use `localController.Transmitter.Item`; no ownership guess and no `FindAllOf("PalNetworkItemComponent")` |

## Local Notification Contract

The standalone candidate uses runtime-created UMG feedback matching Pal
Insight's F7 palette and placement. The running and short terminal states use a
non-focusable compact panel. `ResultDisplay` selects automatic, text-only, or
result-window-only feedback at the accepted F5 trigger. A compatible Pal Insight
bridge is required for the detailed card; absent or incompatible versions fall
back to compact text without mounting an interactive widget. It does not use
Palworld's side-log feed.

Detailed item rows instantiate the current native
`WBP_Paldex_DropItem_C` and call its verified one-argument `Setup(ItemId)`
function, so Palworld supplies the current icon and localized item name. Quick
Stack respects the native row's verified `360 x 34` authored footprint when
choosing the responsive column count, hides its decorative background and
corner marks, and supplies a flat result-row surface with an opaque trailing
`x quantity` region. It caps visible rows and reports omitted item types without
an unbounded widget tree. A missing native row class degrades to a static-ID
text row and logs one actionable warning; notification failure can never alter
the inventory job.

Only the detailed card exposes pointer interaction. A transparent full-viewport
Border prevents pointer events from reaching Palworld menus underneath it, and
the centered `OK` UButton is the sole pointer action. The card mounts at viewport
Z-order 100 and acquires a generation-scoped modal transaction through the
compatible Pal Insight cooked bridge: Game-and-UI input mode, visible cursor,
keyboard focus, a blocking InputComponent, and paired movement/look isolation.
Reflected input-mode events capture any later game-owned transition (including
closing Inventory), then reassert the card after that event completes; the most
recent external mode is restored when the card closes. Mouse click, Enter,
Space, Escape, gamepad confirm, and gamepad cancel are event-driven. The card has
no countdown and no button-state polling; acquisition failure removes the
candidate and falls back to compact text.

The running state remains visible until the job reaches a terminal outcome. The
terminal state replaces its text in the same widget and removes it after two
seconds. UMG creation, update, and removal are guarded; a notification failure
is logged once and cannot abort or alter the inventory job.

“收纳完成” is not tied to the return of
`RequestMoveToContainer_ToServer`, because that only proves local submission.
After all successful submissions, the job remains active and re-reads only the
source slots involved in those requests every 120 ms. Completion requires every
source stack to reflect at least the submitted reduction. After three seconds,
the candidate reports “请求已发送” rather than claiming completion. This is a
bounded replication observation, not a native server acknowledgement.

The result data is captured during the existing bounded inventory, destination,
planning, and confirmation passes. `Tab` -> `R` exclusions are counted from the
initial common-inventory snapshot but never count toward success. Capacity-full
items are reported only when at least one permission/filter-compatible ordinary
storage destination existed; absence of any matching destination is not
misreported as full storage.

## Optional Pal Insight Settings Host Contract

Quick Stack owns one settings implementation in `Scripts/settings_ui.lua`.
Standalone `F6` and Pal Insight's hosted Extensions action both open that same
surface. Pal Insight does not copy Quick Stack controls or write its Saved
configuration.

The private `PalInsightSettingsHost.*` scalar protocol publishes protocol
version, runtime version, generation, readiness, and heartbeat for both sides.
Every open/close transaction is scoped to both live generations, and its
revision is written last. Stale requests, stale acknowledgements, expired
heartbeats, and incompatible protocol versions fail closed. The existing 500 ms
Quick Stack reconciliation cadence carries capability and legacy settings using
only scalar shared state. It performs no widget preparation, viewport walk, or
window-cache validation. Once that heartbeat observes an open Pal Insight
settings stack, a 16 ms loop reads only
`HostRequestSignalRevision` and consumes the full open/close/toggle transaction
after that scalar advances. The fast path performs no widget preparation,
capability publication, legacy reconciliation, or storage work and stops when
the settings stack closes or the host lease expires. Host liveness and the open
flag are refreshed every 80 ms only while this fast path is active; there is no
80 ms watcher while both settings surfaces are closed.

While Pal Insight is live, its callback is the sole physical `F6` action owner.
If Quick Stack registered first, that unavoidable process-lifetime callback
publishes its cooperative behavior version and becomes inert after observing a
live Pal Insight lease; it does not forward the same press. Without a live host,
it opens standalone Quick Stack or forwards only to the newest Quick Stack
generation after a hot reload. If Pal Insight registered first, Quick Stack does
not add another callback. Thus two retained callbacks may exist after the
Quick-Stack-first load order, but only one may perform an action for a press.
Quick Stack is the only Escape/controller-Back action owner while its hosted
surface is open. Pal Insight keeps its underlying routes consumed but does not
dispatch another close. Escape/Back first cancels an active selector or choice;
otherwise it closes only Quick Stack. `F6` asks the host to close the complete
settings stack. Open/closed acknowledgements are transactional with the Quick
Stack input lease: no success is published before acquisition or restoration.

The surface uses one ordered focus model for pointer, keyboard, and controller
input. The recurring open-only pump is only an idempotent pointer and standalone
controller fallback; reflected failures are isolated per phase and cannot stop
subsequent Close, Reset, selection, focus, or visual updates.

The complete UMG tree is retained across close/open only for the same live
world, local controller, locale, and logical viewport size. The cooked input
bridge is retained for the same live world and local controller. Close collapses
a valid cached tree after restoring input; any relevant identity or geometry
mismatch while open first closes the old input transaction, then removes and
rebuilds that cache for the new context. Keyboard navigation is owned by the focused
`UUserWidget:OnPreviewKeyDown` route. Integer editing never transfers focus to
an `EditableTextBox`: the root consumes digits and editing keys into a bounded
integer buffer, so Slate and the desktop IME never own that session. The cooked
bridge dispatches normalized axis values synchronously and contains handler failures.
Off-thread global keybind fallbacks use a bounded game-thread queue whose wake is
also drained by the existing open-panel pump, so a lost wake cannot permanently
block later keys; a short ownership window removes Preview/cooked duplicates.
Process-lifetime input hooks and the optional cooked bridge class are prepared
once through the game-thread delayed-action queue during startup. If the world
is not ready, the actual open transaction retries only the missing work; idle
host reconciliation never retries the full preparation path.

The active panel applies `SetInputMode_UIOnlyEx`, owns a full-viewport hit-test
shield, and holds composable move/look ignore leases. Preview key-down and
key-up handlers consume every panel-owned keyboard/controller event. In
standalone mode a single Escape transaction also guards Palworld's native
`CanOpenAnyUI`, `OnTriggerEscape`, and radial-menu query routes until the same
physical release settles, so closing Quick Stack cannot open the system Escape
menu underneath it. Release is
transactional: the previously observed input mode, focus, cursor, and only the
move/look layers acquired by this session are restored before close succeeds.

With an unchanged world/controller/locale/viewport, a warm open performs no
asset load, hook registration, widget creation, viewport mount, or full-tree
construction. The existing developer-only `PerformanceCapture` switch may emit
phase timings and cache-hit identities for local acceptance; every one of ten
warm-open samples must complete its synchronous transaction within 16.7 ms.
The switch remains `false` in source, Saved defaults, and release artifacts.

The older `PalInsightQuickStack.*` value bridge remains as a compatibility path
for earlier Pal Insight builds. It is not the new settings surface contract.

## Native UI Semantics

The current inventory UI does not immediately move items when its Quick Stack
panel opens. It first uses these current native calls:

1. `PalBaseCampUtility.RequestStartReplicateLocalPlayerBaseCampItemStackInfo`
2. `CallOrRegisterOnReadyLocalPlayerBaseCampItemStackInfo`
3. `PalItemUtility.CollectLocalPlayerQuickStackTargetItemInfos`
4. `PalBaseCampUtility.RequestEndReplicateLocalPlayerBaseCampItemStackInfo`

This proves the native UI computes against replicated current-base stack
information. It does not by itself provide the filter-fill and incubator-first
placement contract required by this mod, so Quick Stack still needs a bounded
client-side destination plan and server-authoritative move requests.

The current chest UI also proves
`PalUIBaseCampItemDispenserModel.RequestMoveInventoryItemToBaseCamp` accepts an
array of player slot IDs. That is a useful native fallback reference, but it
does not expose a caller-selected destination and therefore cannot implement
the requested exact-item/filter/incubator order by itself.

### Verified native helper signatures

A read-only reflection capture on Steam build `24575825` with Workshop UE4SS
`3.0.1` verified these current parameter layouts:

- `PalBaseCampUtility.RequestMoveInventoryItemToBaseCamp(WorldObjectContext,
  TargetBaseCampID<Guid>, InventoryItemSlotIds<Array<PalItemSlotId>>,
  bQuickStackMode<bool>)`.
- `PalUIBaseCampItemDispenserModel.RequestMoveInventoryItemToBaseCamp(
  InventoryItemSlotIds<Array<PalItemSlotId>>)`.
- `PalBaseCampUtility.RequestStartReplicateLocalPlayerBaseCampItemStackInfo(
  WorldContextObject)` and the matching one-argument end call.
- `PalBaseCampUtility.CallOrRegisterOnReadyLocalPlayerBaseCampItemStackInfo(
  WorldContextObject, Delegate)`.
- `PalItemUtility.CollectLocalPlayerQuickStackTargetItemInfos(
  WorldContextObject, StaticItemIds<Array<Name>>, OutItemInfos<
  Array<PalStaticItemIdAndNum>>)`.

This proves ABI only. It does not prove what `bQuickStackMode` selects, which
container wins, whether filters are applied, or when the asynchronous move is
accepted or rejected. `CollectLocalPlayerQuickStackTargetItemInfos` exposes
item IDs and aggregate quantities, not destination container IDs. Production
must not mix this automatic route with direct destination RPCs until completion
and ordering semantics are separately proven.

## Verified RPC Contract

The current runtime contract was captured on 2026-08-30 from Steam build
`24575825` with Workshop UE4SS `3.0.1`:

```log
PATH|/Script/Pal.PalNetworkItemComponent:RequestMoveToContainer_ToServer
FUNCTION|RequestMoveToContainer_ToServer|flags=0xA40CC1
PARAM|1|RequestID|StructProperty<Guid>
PARAM|2|ToContainerId|StructProperty<PalContainerId>
PARAM|3|Froms|ArrayProperty<StructProperty<PalItemSlotIdAndNum>>
END|success|count=3
```

The installed reference's three-argument call therefore matches the current
reflected ABI. The five-argument declaration in the 2024-01-19 legacy header is
superseded and must not be used. Production submission must pass arguments in
the reflected order above. Any future build with a different count, name,
order, or type requires a contract revision before release.

The probe source remains under `diagnostics/rpc-contract` and is excluded from
release payloads. Its active mod directory was removed from `UE4SS/Mods` after
capture and moved to UE4SS's `_disabled_diagnostics` isolation directory
because local safety policy rejected permanent recursive deletion.

The native helper probe source remains under
`diagnostics/native-quick-stack-contract` and must likewise be excluded from
release payloads and removed from the active UE4SS mod directory after capture.

## Remaining Runtime Questions

- Whether nested confirmation or item-use overlays deactivate the parent
  Inventory content. The current gate authoritatively distinguishes the Tab
  bundle's active page, but nested modal behavior still requires runtime
  acceptance.
- Whether every supported base storage family exposes a valid target container
  through the shared concrete-model module route. Unsupported families are
  skipped and logged only with opt-in diagnostics.
- Whether one request per rendered frame is sufficient on co-op and dedicated
  servers or should be paced by a native completion/failure notification.
- Whether the standalone F7-style HUD has identical DPI placement in all
  supported resolutions and whether world travel can invalidate it before the
  terminal update; both paths fail safely and still require runtime acceptance.

These questions do not authorize a global scan or a guessed fallback.
