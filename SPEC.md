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
    PalEggRouting = "IncubatorOnly",
    RelicRouting = "RecyclerOnly",
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

`IncubatorOnly` and `RecyclerOnly` are the first displayed choices and the
defaults for a fresh writable configuration and for Restore Defaults. An
existing valid writable choice remains authoritative during an update; the
runtime must not reinterpret or silently migrate an explicit
`IncubatorThenStorage` or `RecyclerThenStorage` preference.

The shortcut selector rejects `F6`, `Escape`, and `LeftMouseButton`, because
those inputs are owned by the settings surface itself. A chord already owned by
another UE4SS callback remains selectable, but the settings surface shows the
same possible-conflict warning used by Pal Insight. A retained callback that
belongs to this Quick Stack runtime must not be reported as an external
conflict.

## Optional Pal Insight Integration

### Product contract

- Quick Stack works fully without Pal Insight.
- Quick Stack owns one canonical settings surface. Standalone `F6` opens that
  surface directly; Pal Insight never reimplements its controls, validation,
  defaults, persistence, reset behavior, or localized copy.
- Quick Stack's storage, settings, and result behavior remains Lua-owned and
  falls back to non-interactive compact results when the compatible Pal Insight
  result-dialog bridge is not present. The Workshop package may add only the
  isolated Steam-vote helper described below; it does not participate in item
  routing and non-Workshop packages omit it. Quick Stack does not ship a
  duplicate cooked UI PAK.
- When Pal Insight is live, Pal Insight is the sole physical `F6` action owner.
  Any earlier process-lifetime Quick Stack callback becomes inert instead of
  forwarding the same press. `F5` remains Quick Stack's gameplay action and is
  unaffected.
- Pal Insight's top-level `Extensions` page always contains one Quick Stack
  catalog row. A compatible runtime shows its version and opens the same Quick
  Stack-owned surface as a separate hosted panel. Missing or incompatible
  runtime states show the current distribution channel's install/update link.
  Game Pass remains explicitly unavailable until a real Quick Stack Game Pass
  package exists.
- Escape or controller Back closes only the hosted Quick Stack panel and
  restores Pal Insight plus focus to the originating row. `F6` closes the whole
  settings stack.
- Quick Stack is the sole Escape/Back action owner while its settings surface is
  open. Pal Insight keeps the underlying settings stack suspended and consumes
  its own retained routes without issuing a second close request.
- The settings surface has one authoritative interaction state shared by mouse,
  keyboard, and controller. `W/S`, arrows, and controller directions navigate;
  Enter/Space or controller Accept activates; Escape or controller Back cancels
  the active selector/choice first and otherwise closes the surface. Focused
  rows are scrolled into view.
- The fixed Header matches Pal Insight's settings chrome: the optional Steam
  Workshop vote control precedes About, Restore Defaults, and Close in that
  order, using the same native UMG Button brushes, dimensions, spacing, icon
  canvases, semantic hover/pressed colors, and focus treatment. A transparent
  compatibility input layer may sit above those buttons so standalone Quick
  Stack retains its existing mouse route; it must not replace or visually alter
  the Pal Insight presentation. The Footer is informational only. About opens a
  Quick Stack-owned modal and all three actions remain operable by mouse,
  keyboard, and controller. The About modal is not a placeholder: it identifies
  Quick Stack, recommends Pal Insight without implying that Quick Stack depends
  on it, and uses the same three-column creator hierarchy as Pal Insight. The
  CrateX.app action is on the left, the creator biography is in the center, and
  Special Thanks plus Supporters remain fixed on the right even when their
  rosters are empty. Each roster opens as a nested modal with an explicit empty
  state instead of changing the About layout. The modal also exposes Quick
  Stack's Nexus Mods, Steam Workshop, and CurseForge pages, X, Discord, and Buy
  Me a Coffee. Its copy is complete in all 17 supported locales; external
  destinations open outside the game, while the modal keeps input ownership and
  remains open.
- Workshop voting is owned by a Quick Stack-specific native helper and targets
  Quick Stack Workshop item `3792968111`; it must never read or change Pal
  Insight item `3778493118`. The visual states and interaction rules match Pal
  Insight: an outline thumb for no vote, an inverted Chillet with a black down
  thumb for a down vote, and a normal Chillet with a gold up thumb for an up
  vote. Only no-vote/down-vote states can submit an up vote. Non-Workshop
  packages omit the helper and therefore omit the control.
- Opening and closing are transactional. An open acknowledgement is published
  only after the widget and modal input lease are both live. A closed
  acknowledgement is published only after input isolation and the prior input
  context are restored; a failed restore leaves a visible recovery surface
  instead of silently acknowledging success.
- The settings widget is reused only while its world, local controller, locale,
  viewport size, and widget identity still match. Closing hides the valid
  cached tree after releasing input; a mismatch discards it before rebuilding,
  so repeated opens do not synchronously reconstruct the complete UMG tree.
- Process-lifetime preview/input hooks and the optional Pal Insight bridge asset
  are prepared once during startup. Standalone-only native Escape gates are
  installed once on the first standalone acquisition. Idle host reconciliation must not rebuild,
  validate, or prewarm the settings tree. If startup preparation was too early,
  the actual open transaction may retry only the missing preparation work. The
  Workshop vote Pal portrait follows the same bounded retry rule; a warm open
  never calls `LoadAsset` to repair it.
- Numeric fields retain direct integer entry, but the focused root owns
  keyboard/controller editing and rejects composition-triggering text.
  Left/Right and A/D adjust the value without reaching a native text editor or
  desktop IME. Digits, numpad digits, Backspace, and Delete update an
  integer-only buffer while focus remains on the settings root. Pointer
  activation enters the same buffer instead of opening a separate Slate text
  session, so all input families share one deterministic path.
- Focus-scoped UMG preview input is the primary keyboard owner. Global keybinds
  remain only as a compatibility fallback: their scalar events are bounded and
  marshalled to the game thread, while the existing open-panel pump can drain a
  lost wake without blocking later input. Cooked controller axis events dispatch
  directly through a type-checked handler. Preview/cooked ownership suppresses
  the corresponding delayed global event for the same physical press.
- The settings surface is a true modal owner. It applies `UIOnly`, keeps a
  visible full-viewport hit-test shield below the card, and returns `Handled`
  for every keyboard/controller press and release owned by the panel. While the
  surface is open, movement, look, gameplay actions, and underlying menu clicks
  receive no input. Close restores the exact captured mode, focus, cursor,
  movement, and look state before publishing its acknowledgement.
- Warm-open acceptance is measured, not inferred. After one cold construction
  in an unchanged world/controller/locale/viewport, ten close/open cycles must
  reuse both the settings tree and cooked input bridge, perform no `LoadAsset`,
  `RegisterHook`, `CreateWidget`, `AddToViewport`, or full-tree construction in
  the open transaction, and keep warm-open synchronous time at or below
  16.7 ms for every sample.
- Pal Insight never scans for storage, moves items, or becomes responsible for
  a Quick Stack job.
- A compatible Pal Insight may additionally lend its cooked input bridge to a
  Quick Stack result card. This is used only for an Inventory/Equipment-triggered
  result, uses a separate capability, and does not transfer item movement or
  settings ownership to Pal Insight.

### Runtime contract

Settings hosting uses private, versioned scalar shared variables under
`PalInsightSettingsHost.*`. Both runtimes publish a monotonically increasing
load generation and a short heartbeat lease. Open, close, failure, and
acknowledgement revisions carry both the Pal Insight host generation and the
Quick Stack target generation; the revision is written last as the transaction
commit marker. The Quick Stack F6 owner also publishes a cooperative behavior
version so Pal Insight never mistakes an older or external callback for an
inert peer. Stale generations and expired leases are ignored.

Load order is symmetric. If Pal Insight registers `F6` first, Quick Stack sees
the occupied chord and does not add a duplicate callback. If Quick Stack
registers first, Pal Insight later becomes the sole live action owner and the
retained Quick Stack callback becomes inert while the host lease is live. After
a Quick Stack hot reload, a retained callback targets only the newest Quick
Stack generation while no Pal Insight host is live. Quick Stack publishes a
versioned cooperative-F6 capability so Pal Insight can distinguish this behavior
from an older or external callback. Quick Stack publishes capability and
reconciles legacy settings from its existing 500 ms cadence. This idle heartbeat
reads and writes only scalar shared state; it never prepares widgets, walks
viewport-owned objects, or validates the settings window cache. While Pal
Insight reports that its settings stack is open, Quick Stack
additionally runs a lightweight 16 ms request-signal loop. That loop reads only
`HostRequestSignalRevision` and consumes the full open/close/toggle transaction
after that scalar advances; it does not prepare widgets, publish capability,
reconcile legacy settings, or perform storage work, and it stops when the host
settings stack closes or its lease expires. This bounds the
hosted click-to-request pickup to one frame without adding a permanent
high-frequency idle task. The 500 ms heartbeat starts the fast watcher only
while `HostSettingsOpen` is true or Quick Stack already owns a hosted settings
surface; no 80 ms watcher remains active while both settings surfaces are
closed. The 500 ms heartbeat, 16 ms hosted watcher, and 80 ms open-only control
pump each use one retained repeating game-thread action rather than registering
a new delayed callback every interval. The hosted watcher and control pump are
cancelled when their owner closes. Each control-pump phase is exception-isolated,
so a failed reflected read cannot disable Close, Reset, or navigation.

The legacy `PalInsightQuickStack.*` value bridge remains temporarily readable
for older Pal Insight versions, but the new Pal Insight UI neither displays nor
writes those individual settings. Quick Stack alone applies, validates, saves,
and resets its configuration.

The first integration is deliberately specific to this sibling mod. A generic
third-party F6 extension API is out of scope.

`ResultDialogBridgeVersion` remains under `PalInsightQuickStack.*` and is
independent from settings hosting. Version `2` identifies
the fixed `WBP_PalInsightX_Settings` pressed/released/click callback contract.
Quick Stack validates the version and reflected functions before creating its
own bridge instance. Missing or incompatible capability data fails closed to
the compact notification. The borrowed bridge lifetime is identical to the
detailed card lifetime and is always released when that card closes.

## Architecture and Performance Contract

### Startup activation

- An explicit final `PalInsightQuickStack : 0` entry in the active UE4SS
  `Mods/mods.txt` takes precedence over a packaged or leftover `enabled.txt`.
- The entry script exits before loading modules, registering shortcuts/hooks,
  initializing native helpers, or scheduling recurring work when that disable
  entry is present. Missing or unreadable `mods.txt` remains fail-open so a
  portable installation may intentionally use `enabled.txt`.

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
assets/
  about/           Shared About-panel logos and Pal Insight preview
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
- Standalone `F6` opens Quick Stack's own settings surface and can change and
  persist the shortcut, result-display choice, two storage-rule toggles, Pal
  Egg route, Ancient Civilization Relic route, and World Tree Holy Water
  threshold without Pal Insight.
- When both mods are present and compatible, Pal Insight's `Extensions` page
  opens that same Quick Stack-owned surface as a separate hosted panel; when
  either mod is absent, the other continues normally.

## Open Questions Requiring Runtime Evidence

1. Whether nested confirmation or item-use overlays keep the parent Inventory
   page activated; if they do, a separate modal predicate may be required.
2. Whether every supported storage exposes filter, permission, and capacity
   through one concrete-model family or needs a small explicit adapter list.
3. Whether a native per-request acknowledgement is available for stronger
   multiplayer diagnostics than the current replicated-source confirmation.

## Workshop Documentation Contract

Every release description must document the standalone and Pal Insight-hosted
settings paths near the feature list, not only in troubleshooting text.

### Simplified Chinese draft

```text
快捷键设置

默认快捷键为 F5。

独立使用 Quick Stack：
按 F6 打开 Quick Stack 设置面板，修改后自动保存。

与 Pal Insight 配合使用：
按 F6 打开 Pal Insight，进入“扩展（Extensions）”→“Quick Stack”打开同一套
Quick Stack 设置面板。按 Escape 或手柄 Back 只返回 Pal Insight；按 F6 关闭整个设置栈。

高级或恢复用途仍可直接编辑：
%LOCALAPPDATA%\Pal\Saved\PalInsightQuickStackSettings.lua
```
