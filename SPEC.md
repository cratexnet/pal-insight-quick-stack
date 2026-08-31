# Spec: Pal Insight: Quick Stack | 一键归箱

## Objective

Build an independent UE4SS Lua mod for Palworld 1.0 that moves eligible items
from the local player's common inventory into appropriate storage in the
current base when the player presses F5.

The mod must match the useful behavior of the installed `QuickStackHotkey`
configuration while replacing its global object scans, repeated full-database
lookups, nested item-by-chest routing, and burst RPC submission with bounded,
base-local work.

The mod is independently installable and does not require Pal Insight. When a
compatible Pal Insight is also installed, its F6 panel may expose this mod's
settings as an optional convenience and discovery path.

## Verified Inputs

- Reference runtime:
  `F:\SteamLibrary\steamapps\common\Palworld\Mods\NativeMods\UE4SS\Mods\QuickStackHotkey\Scripts\main.lua`
- Reference configuration has `AltEggSorting`, `IncubatorsFirst`, and
  `FillByChestFilter` enabled.
- Current Palworld 1.0 evidence is taken from Steam build `24575825`, its
  cooked UI assets, executable symbol table, and the compatible
  `Palworld_1_0_2FF94A03.usmap` mapping recorded in
  `docs/runtime-contract.md`.
- Legacy SDK architecture evidence:
  `D:\Workspace\pal-insight\research\palworld-dumped-header-gist\Pal.hpp`.
  This is a 2024-01-19 snapshot and is not authoritative for current
  signatures, fields, or offsets.
- UE4SS provides process keybind registration, game-thread dispatch, and scalar
  cross-mod shared variables through `ModRef`.
- A one-shot read-only runtime reflection probe on build `24575825` and
  Workshop UE4SS `3.0.1` verified
  `RequestMoveToContainer_ToServer(RequestID, ToContainerId, Froms)` with the
  exact reflected types recorded in `docs/runtime-contract.md`.

## Assumptions

1. The first release targets Palworld 1.0 on Steam with Workshop UE4SS.
2. This is a client-installed mod; inventory mutations still use Palworld's
   server-authoritative item RPCs.
3. Dedicated-server and co-op compatibility remain unverified until in-game
   acceptance is completed.
4. Only the local player's common inventory is in scope. Equipment, food,
   sphere, key-item, and unrelated containers must not be scanned as fallback.
5. The current base is the only destination scope.
6. Guild Chests are never automatic destinations; Quick Stack only writes to
   the player's ordinary current-base storage and optional incubators.
7. Runtime ambiguity fails closed: no move is attempted if local-player,
   current-base, common-inventory, exclusion-list, permission, or destination
   state cannot be read completely.
8. Pal Insight integration is a second-stage convenience, not a dependency of
   the core feature.

## User-Visible Behavior

### Default shortcut

- Default: `F5`.
- The shortcut is configurable in the writable Saved-directory config. The
  packaged `Scripts/config.lua` is only the first-run seed.
- A press is ignored while the player is outside a base or while required local
  state is unavailable. With the `Tab` bundle open, F5 is accepted only while
  its active content is the Inventory/Equipment page; Map, Technology, Paldex,
  and all other bundled pages remain blocked.
- One physical press starts at most one job. Repeated presses while a job is
  active do not create concurrent routing jobs.

### Exclusions

- Read `Local_ItemQuickMoveExceptionIDList` from the same local player record
  used for the inventory and base lookup.
- By default, respect every exclusion created by Inventory `Tab` -> `R`.
- `IncludeExcludedItems = true` makes those items eligible without
  modifying the game's exclusion list.
- An unreadable or partially decoded exclusion list aborts the whole job.

### Routing order

Eligibility and route restrictions use this fixed order for every common-
inventory item:

1. A `Tab` -> `R` ignored item stays in the player inventory unless
   `IncludeExcludedItems = true`.
2. An eligible Pal Egg uses available incubators first. `IncubatorOnly` leaves
   any remainder in the inventory; `IncubatorThenStorage` continues through
   ordinary-storage routing.
3. An eligible Ancient Civilization Relic uses all compatible Ancient Relic
   Recyclers in stable current-base discovery order. `RecyclerOnly` leaves any
   remainder in the inventory; `RecyclerThenStorage` continues through
   ordinary-storage routing.
4. `IncludeNewItems = false` restricts only the ordinary-storage route to writable storage
   that already contains the exact item. Empty incubators and empty storage
   accepted only by filters are not ordinary-storage candidates; empty
   incubators and recycler slots remain eligible.
5. The ordinary route prefers writable storage containing the exact item, then
   writable storage whose filter accepts the item category.
6. Leave the item in the player inventory when no valid capacity remains.

The current-build `WorldTreeRelic_01` through `WorldTreeRelic_05` IDs identify
Ancient Civilization Relics even when no recycler exists in the base. Every
live recycler's dedicated-container permission list is still authoritative for
whether that recycler may receive a specific relic. A recycler whose
permission contract is unreadable is not used. A recycler
that exists but rejects the specific item is not treated as full. A partially
accepted stack is split at the plan boundary: the accepted quantity is sent to
the recycler and the remainder continues through ordinary-storage routing.

`WorldTreeHolyWater` uses each recycler's dedicated `BoostItemContainer` before
ordinary storage. Quick Stack tops up every Ancient Relic Recycler in stable
current-base order to `WorldTreeHolyWaterMinimum` (default `10`, integer range
`1..100`). If the backpack cannot satisfy every recycler, earlier recyclers are
filled first. Water above the configured minimum continues through the ordinary
storage route; ignored-item and ordinary-storage settings still apply.

Guild Chests are excluded before any generic storage-class match and cannot
become a destination under any setting combination.

Ancient Relic Recyclers preserve stable current-base discovery order. Within
the ordinary-storage route, when multiple destinations are otherwise
equivalent, prefer a destination already present in the current job's plan and
then preserve stable discovery order. This tie-breaker may reduce destination
RPC count, but it must never move a filter-only destination ahead of an
exact-item destination or change incubator-first behavior.

Every destination is rechecked before submission. Permissions, filters,
container identity, stack capacity, and world/base generation must still match
the snapshot. With `IncludeNewItems = false`, the destination must still
contain each requested item at recheck time.

### Feedback

- The standalone mod creates the same compact, centered, non-focusable status
  HUD presentation used by Pal Insight's F7 feedback. It does not depend on Pal
  Insight and does not use Palworld's persistent side-log feed. The compact
  frame grows from 360 to at most 520 logical units, is further clamped to the
  viewport safe width, and uses a deterministic content-width wrap budget.
  Text stays on one line while it fits; beyond the safe maximum it wraps and
  naturally increases the frame height while remaining horizontally and
  vertically centered.
- Starting a valid job shows a persistent quick-stacking message that asks the
  player not to manipulate inventory until the job finishes.
- `Quick stack complete` is shown only after the submitted source-slot changes
  are observed in the replicated common inventory. If replication is not
  observed within three seconds, the message says that requests were submitted
  instead of claiming completion.
- Without a compatible Pal Insight result-dialog bridge, every outcome uses the
  compact notification, including jobs started from Inventory/Equipment.
- `ResultDisplay = "TextOnly"` disables the detailed card for every trigger
  location. Persistent progress and compact result feedback remain enabled.
- `ResultDisplay = "ResultWindow"` requests the independently owned detailed
  card for every trigger location. If the compatible Pal Insight bridge is not
  available or cannot acquire input ownership, the result falls back to compact
  text without leaving an interactive widget behind.
- With a compatible bridge, a confirmed result with at least one successfully
  stored or unstored item uses a centered F6-style detailed card when selected
  by the trigger-time `ResultDisplay` policy. The card owns its cursor, modal
  hit-test shield, movement/look isolation, and keyboard/gamepad close events;
  later Inventory/Equipment lifecycle changes cannot strand it without input.
  Bridge acquisition failure falls back to the compact summary. The card uses a wide, viewport-safe
  layout. The current native localized item row has a verified `360 x 34`
  authored footprint, so four columns are used only when every item cell is at
  least 360 logical units wide; otherwise the card uses three columns, with a
  two-column emergency fallback on narrow viewports. Each non-empty result
  section shows up to twelve native localized icon/name rows, a plain
  right-aligned quantity, and an explicit overflow count. Quick Stack hides the
  native row's decorative background/corner marks and supplies the same flat
  row surface used by the result card. Each item is one common visual region:
  the native icon/name host is structurally clipped before a fixed 68-unit
  quantity column, and the quantity shares the cell background instead of
  becoming a separate badge. Horizontal cells use a 12-unit gutter while rows
  retain a 4-unit gap, so items are tighter within a cell than between cells.
- If a compatible ordinary destination exists but its usable capacity is
  exhausted, the detailed card makes that result primary. A partial result is
  titled `Some items could not be stored`; a capacity-only result is titled
  `Items could not be stored`. The possible-cause explanation belongs to the
  fixed result Header as a secondary line, outside the scrolling item lists.
  The warning-colored `Not stored` section appears before successful and
  excluded sections and contains only its summary and affected item rows. It is
  shown even when zero items were successfully stored. This user-facing copy
  deliberately avoids claiming one exact cause; affected items remain in the
  backpack. Empty sections are omitted.
- The detailed card follows Pal Insight F6's flat hierarchy: one subtle window
  outline, separate Header/Content/Footer surfaces, full-width section heading
  bands, no decorative rails or nested section outlines, and no button-like
  quantity badges. Under height pressure, only Content may scroll; Header and
  Footer remain fixed. A card whose complete content fits does not show a
  scrollbar merely because of font or overflow-label desired-height rounding.
- Excluded items never count as success and never trigger the detailed card by
  themselves. Gameplay-triggered jobs, no eligible item, submitted-only, and
  aborted outcomes keep the compact two-second message.
- The detailed card does not auto-close. Its fixed Footer contains one centered,
  focusable `OK` button with a wider target. Mouse click, Enter, Space, Escape,
  controller Confirm, and controller Cancel close only the result card; they
  never start, cancel, or change an inventory job. Compact outcomes remain
  non-interactive.
- The compact unstored-item outcome is authored as two explicit lines: the
  result count first, followed by storage-space/settings guidance. It does not
  depend on incidental word wrapping.
- The runtime logs actionable failures and load errors.
- Optional verbose diagnostics default to `false` and must not be present or
  enabled in a release artifact.

### Localization

- Quick Stack is standalone and owns its localization; it must not read Pal
  Insight tables or require Pal Insight for translated runtime text.
- Every Quick Stack-authored notification, result title, section label, summary,
  helper, button, empty state, submitted state, and stopped state has
  an explicit translation for the same 17 interface locales supported by
  Palworld and Pal Insight: `en`, `zh-hans`, `zh-hant`, `ja`, `ko`, `de`, `fr`,
  `it`, `es`, `pt-br`, `ru`, `tr`, `pl`, `id`, `es-419`, `th`, and `vi`.
- The active language is read from
  `KismetInternationalizationLibrary.GetCurrentLanguage()`, with current culture
  as a fallback. Unknown, unavailable, or malformed tags fail safely to English.
- Native item icons and localized names continue to come from Palworld's item
  row; Quick Stack does not duplicate game-owned item translations.
- All locale rows contain exactly the same keys as English. The release gate
  rejects a missing locale, a missing key, inline Chinese result copy in the
  notification owner, or omission of the standalone localization module.
- Brand names remain proper names. The optional Pal Insight F6 bridge localizes
  its Quick Stack shortcut and detailed-result rows in all 17 locales while the
  section name remains `Pal Insight: Quick Stack`.

## Configuration

`Scripts/config.lua` is a package-owned default seed. On first run, Quick Stack
creates and thereafter uses this writable configuration as the sole source of
truth:

`%LOCALAPPDATA%\Pal\Saved\PalInsightQuickStackSettings.lua`

Workshop updates must not overwrite this file.

For compatibility with `0.1.x`, if the new file is absent and
`PalInsightQuickStack-config.lua` exists, Quick Stack imports the validated
legacy values into `PalInsightQuickStackSettings.lua`. The legacy file is not
deleted. All subsequent writes target the new file whenever it can be created.

```lua
return {
    Key = "F5",
    Shift = false,
    Ctrl = false,
    Alt = false,
    ResultDisplay = "Default",
    IncludeExcludedItems = false,
    IncludeNewItems = true,
    PalEggRouting = "IncubatorThenStorage",
    RelicRouting = "RecyclerThenStorage",
    WorldTreeHolyWaterMinimum = 10,
    Debug = false,
}
```

`ResultDisplay` accepts `Default`, `TextOnly`, or `ResultWindow`. A writable configuration using
the former `ShowDetailedResults`, `OnlyExistingItems`, `IncludePalEggs`,
`ExcludePalEggs`, `AltEggSorting`, `IncubatorsFirst`, or `FillByChestFilter`
fields is migrated or removed and rewritten canonically. Experimental
`RelicRouting` values are migrated to `RecyclerOnly` or
`RecyclerThenStorage`.

Manual edits made while the game is running are not required to hot-reload.
Users should close the game, edit the writable file, and restart. Modifier
examples must be documented; `Ctrl+S` is represented by `Key = "S"` and
`Ctrl = true`.

## Optional Pal Insight Integration

### Product contract

- Quick Stack works fully without Pal Insight.
- Standalone Quick Stack remains pure Lua and falls back to non-interactive
  compact results when the compatible Pal Insight result-dialog bridge is not
  present. It does not ship a duplicate cooked UI PAK.
- The optional in-game settings editor requires a compatible Pal Insight.
- Pal Insight shows the integration only when a compatible Quick Stack runtime
  announces itself.
- The integration does not add a new tab. It appends one independent settings
  class to the bottom of Pal Insight's existing final F6 tab, `Controls`.
- The class title is `Pal Insight: Quick Stack`.
- The class contains the Quick Stack keyboard shortcut, a three-value
  `Quick Stack notifications` choice (`Auto`, `Text only`, or `Result window only`), two independent
  toggles (`Store ignored items` and `Store items not already in storage`), a
  Pal Egg route (`Incubators only` or `Incubators > storage`), and an Ancient
  Civilization Relic route (`Ancient Relic Recyclers only` or
  `Ancient Relic Recyclers > storage`). The notification, egg route, and relic
  route each have localized explanatory text; the two toggles do not.
- When Quick Stack is absent or incompatible, the entire class is omitted;
  Pal Insight does not show an empty class or placeholder in `Controls`.
- Pal Insight never scans for storage, moves items, or becomes responsible for
  a Quick Stack job.
- Incompatible or missing integration silently falls back to `config.lua`.
- A compatible Pal Insight may additionally lend its cooked input bridge to a
  Quick Stack result card. This is used only for an Inventory/Equipment-triggered
  result and does not transfer item movement ownership to Pal Insight.

### Runtime contract

Use globally unique scalar shared-variable names through UE4SS `ModRef`:

- `PalInsightQuickStack.ApiVersion`
- `PalInsightQuickStack.RuntimeVersion`
- `PalInsightQuickStack.SettingsRevision`
- `PalInsightQuickStack.Key`
- `PalInsightQuickStack.Shift`
- `PalInsightQuickStack.Ctrl`
- `PalInsightQuickStack.Alt`
- `PalInsightQuickStack.IncludeExcludedItems`
- `PalInsightQuickStack.IncludeNewItems`
- `PalInsightQuickStack.ResultDisplay`
- `PalInsightQuickStack.PalEggRouting`
- `PalInsightQuickStack.RelicRouting`
- `PalInsightQuickStack.WorldTreeHolyWaterMinimum`
- `PalInsightQuickStack.ResultDialogBridgeVersion`

Quick Stack owns validation, runtime application, and persistence. Pal Insight
only publishes requested values and advances `SettingsRevision`. Quick Stack
reconciles that revision at a low fixed frequency, applies valid changes, makes
old process-lifetime keybind callbacks inert when necessary, and rewrites its
own canonical Saved configuration. It republishes the accepted or restored
canonical settings with a newer acknowledgement revision. Invalid values are
rejected without changing the last valid runtime configuration.

The first integration is deliberately specific to this sibling mod. A generic
third-party F6 extension API is out of scope.

`ResultDialogBridgeVersion` is written by Pal Insight. Version `1` identifies
the fixed `WBP_PalInsightX_Settings` pressed/released/click callback contract.
Quick Stack validates the version and reflected functions before creating its
own bridge instance. Missing or incompatible capability data fails closed to
the compact notification. The borrowed bridge lifetime is identical to the
detailed card lifetime and is always released when that card closes.

## Architecture and Performance Contract

### Required object route

- Resolve the current local controller and its player-owned state without a
  global fallback scan.
- Resolve the current base through `InsideBaseCampCheckComponent` and
  `GetInsideBaseCampModel()`.
- Enumerate only
  `base.MapObjectCollection.MapObjectInstanceIdRepInfoArray.Items[*].InstanceId`.
  The pre-1.0 `MapObjectInstanceIds` field must not be used.
- Resolve each base object through `PalMapObjectManager.FindModel`, then use
  its replicated `ConcreteModel` and
  `PalMapObjectConcreteModelBase.GetItemContainerModule()` route.
- Resolve the local common inventory from the verified local player state,
  match `MyInventoryInfo.CommonContainerId` against the small
  `InventoryMultiHelper.Containers` set, and abort if the match is missing or
  ambiguous. Do not enumerate unrelated live containers.
- Resolve exclusions only from that same local player state's
  `GetLocalRecordData().Local_ItemQuickMoveExceptionIDList`.
- Resolve item metadata lazily through `PalItemIDManager.GetStaticItemData` for
  unique relevant item IDs only.
- Resolve the item network component through `localController.Transmitter.Item`,
  not `FindAllOf("PalNetworkItemComponent")`.

### Job snapshot and indexes

Build one generation-scoped snapshot shared by egg and normal-item routing:

- `containersByContainedItem[itemId]`
- `containersByAcceptedCategory[category]`
- available incubators
- per-container permissions, filter state, stack capacity, and container ID
- cached category metadata for relevant unique inventory item IDs
- compatibility indexes that distinguish `no matching ordinary storage` from
  `matching ordinary storage has no remaining capacity`, without adding an
  item-by-container routing loop

The warm F5 path must not call `FindAllOf`. Routing must not iterate every item
against every base container.

The input gate tracks newly created `WBP_InGameMainMenu_C` instances through
UE4SS lifecycle notification. When the cursor is owned by UI, it performs only
bounded pointer checks: the tracked menu must still be valid and activated, and
its `CurrentContentWidget` must be an instance of
`WBP_InventoryEquipment_ForDisplay_C`. Missing or unreadable lifecycle/content
state fails closed; the gate never scans all live widgets.

### Scheduling budget

- Heavy discovery and classification work is divided into bounded game-thread
  slices.
- Stable notification class objects may be warmed before the first F5 in
  bounded one-object slices. Warm-up must not create or retain a world-owned
  widget and must remain safe if it has not completed when F5 is pressed.
- Target: no controllable Lua scan, planning, recheck, or result-UI slice over
  4 ms on the representative acceptance base after warm-up. The indivisible
  synchronous target RPC boundary is measured and reported separately; actual
  results must be measured in game before release.
- Submit at most one destination move RPC per frame.
- After submission, poll only the source slots involved in successful requests
  every 120 ms for at most three seconds; do not add a permanent tick or scan
  unrelated inventory/container state.
- Cancel stale work on world change, base change, controller change, player
  change, or a newer accepted job generation.
- No unbounded cache: metadata and container indexes are scoped to a job or a
  validated world/base generation.

## Tech Stack

- UE4SS Lua mod
- Palworld 1.0 reflected SDK contracts
- No Pal Insight runtime dependency
- No third-party Lua dependencies

## Project Structure

```text
Scripts/
  main.lua        Runtime entry point and keybind dispatch
  config.lua      Package-owned default configuration seed
  localization.lua Standalone 17-language runtime text and locale resolution
  settings.lua    Writable Saved-config parser and shortcut helpers
  notifications.lua Native local progress and completion feedback
  palworld.lua    Current-build reflected object boundary
  quick_stack.lua Generation-scoped snapshot, routing, and RPC owner
docs/
  acceptance.md  Manual single-player/co-op/dedicated-server matrix
  performance.md Baseline and before/after measurements
tasks/
  plan.md        Ordered implementation plan
  todo.md        Executable task checklist
SPEC.md          Product and runtime contract
README.md        Installation, behavior, and compatibility
CHANGELOG.md     User-facing release history
```

## Code Style

- Keep each owning module's runtime state in one explicit table; input dispatch
  state and Quick Stack job state must not be shared implicitly through globals.
- Use small local functions with fail-closed return values.
- Use English identifiers and concise Simplified Chinese only where comments
  materially help maintainers.
- Do not create generic frameworks for one integration.

```lua
local function resolveCurrentBase(context)
    if context == nil or context.insideBaseComponent == nil then
        return nil, "current base is unavailable"
    end
    return context.insideBaseComponent:GetInsideBaseCampModel()
end
```

## Commands

Commands are provisional until the project skeleton verifies which Lua parser
is available on the development host.

```powershell
# Syntax check, if luac is available
luac -p .\Scripts\main.lua
luac -p .\Scripts\config.lua

# Inspect the complete local change
git status --short
git diff --check
git diff
```

No build, packaging, installation, or release command may run until its release
diagnostics gate exists and passes.

## Testing and Validation Strategy

No automated test files are added unless explicitly requested. Verification for
the prototype uses:

1. Lua syntax parsing when an installed parser is available.
2. Static source audit proving the F5 route has no `FindAllOf`, uses the current
   base collection, and limits move submission.
3. In-game A/B acceptance against the reference mod with only one quick-stack
   mod enabled at a time.
4. Single-player, co-op client, and dedicated-server client checks before any
   compatibility claim.
5. Opt-in development timing capture only after explicit approval; all optional
   diagnostics must be false or excluded from release.

## Boundaries

### Always

- Preserve exclusions, permissions, filters, capacity, and current-base scope.
- Keep server-authoritative mutation and fail closed on incomplete state.
- Keep standalone operation independent of Pal Insight.
- Report verified facts separately from runtime assumptions.

### Ask first

- Install or enable the prototype in the game.
- Disable or modify the existing QuickStackHotkey installation.
- Add persistent diagnostic probes or performance capture.
- Modify Pal Insight for the optional F6 integration.
- Build, package, publish, create a GitHub repository, or create a Workshop item.

### Never

- Move items from non-common player containers as a fallback.
- Use global object enumeration in the warm shortcut path.
- Send an unbounded burst of destination RPCs.
- Ship developer diagnostics enabled.
- Make Pal Insight a mandatory dependency.

## Success Criteria

- F5 produces the same final placement as the reference configuration for
  ordinary items, filtered empty containers, and incubator-first eggs.
- Inventory `Tab` -> `R` exclusions remain untouched, including excluded eggs.
- Guild Chests receive zero automatic move requests.
- The job aborts rather than guessing when required local state is incomplete.
- Static audit finds no `FindAllOf` in the warm F5 route.
- Runtime capture on the representative base meets the per-slice budget or the
  budget is revised with recorded evidence before release.
- At most one destination move request is submitted per frame.
- Standalone configuration works through the writable
  `%LOCALAPPDATA%\Pal\Saved\PalInsightQuickStackSettings.lua` and survives
  Workshop updates.
- Existing `0.1.x` values in `PalInsightQuickStack-config.lua` migrate without
  deleting or modifying the legacy file.
- When both mods are present and compatible, the final F6 `Controls` tab shows
  an independent `Pal Insight: Quick Stack` class that can change and persist
  the shortcut, result-display choice, two storage-rule toggles, Pal Egg route,
  and Ancient Civilization Relic route; when
  either mod is absent, the other continues normally.

## Open Questions Requiring Runtime Evidence

1. Whether nested confirmation or item-use overlays keep the parent Inventory
   page activated; if they do, a separate modal predicate may be required.
2. Whether every supported storage exposes filter, permission, and capacity
   through one concrete-model family or needs a small explicit adapter list.
3. Whether a native per-request acknowledgement is available for stronger
   multiplayer diagnostics than the current replicated-source confirmation.

## Workshop Documentation Contract

Every release description must document both settings paths near the feature
list, not only in troubleshooting text.

### Simplified Chinese draft

```text
快捷键设置

默认快捷键为 F5。

独立使用 Quick Stack：
关闭游戏，打开
%LOCALAPPDATA%\Pal\Saved\PalInsightQuickStackSettings.lua，修改 Key、Shift、
Ctrl、Alt、ResultDisplay、IncludeExcludedItems、IncludeNewItems、
PalEggRouting、RelicRouting 和 WorldTreeHolyWaterMinimum，保存后重新启动游戏。此文件位于用户存档
目录，不会被 Steam 创意工坊自动更新覆盖。

与 Pal Insight 配合使用：
按 F6 打开设置，进入“控制（Controls）”→“Pal Insight: Quick Stack”→
“Quick Stack 快捷键/收纳提示/收纳内容”，即可直接修改并自动保存。
```
