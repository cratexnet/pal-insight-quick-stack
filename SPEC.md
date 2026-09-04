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

1. The first release targets Palworld 1.0 on Steam and the Xbox App / PC Game
   Pass / Microsoft Store WinGDK build. Each platform requires its matching
   UE4SS runtime path; WinGDK compatibility remains runtime-unverified until a
   representative Game Pass acceptance run is completed.
2. This is a client-installed mod; inventory mutations still use Palworld's
   server-authoritative item RPCs.
3. A community tester reported on 2026-09-05 that the mod worked without issue
   on a dedicated server with the mod installed client-side only. This is valid
   compatibility evidence for release descriptions, but the exact game build,
   distribution platform, scenario matrix, and logs were not provided. Co-op
   compatibility remains unverified until in-game acceptance is completed.
4. Only the local player's common inventory is in scope. Equipment, food,
   sphere, key-item, and unrelated containers must not be scanned as fallback.
5. The current base is the only destination scope.
6. Guild Chests are automatic destinations only when the default-off
   `IncludeGuildChest` setting is enabled, the current base contains a live
   Guild Chest for the local player's guild, and the player's guild role is
   allowed to access it.
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
- A queued shortcut press belongs to its binding and settings-window generation.
  Before starting a job, discard it if the binding changed or settings opened
  or closed after the press. An old press must never start a new routing job
  after a settings transaction, even if the window is closed again.

### Exclusions

- Read `Local_ItemQuickMoveExceptionIDList` from the same local player record
  used for the inventory and base lookup.
- By default, respect every exclusion created by Inventory `Tab` -> `R`.
- `IncludeExcludedItems = true` makes those items eligible without
  modifying the game's exclusion list.
- An unreadable or partially decoded exclusion list aborts the whole job.

### Optional automatic sale

- `AutoSellValuables` is one default-off toggle. When disabled, F5 performs no
  valuable-item sale. `ValuableSellItems` is the canonical comma-separated
  sell allowlist for the same fixed catalog; it defaults to all nine current
  high-value merchant items so enabling the toggle preserves the existing
  sell-all behavior. Its settings picker presents the inverse, safer wording:
  a checked item is kept and is not sold.
- When enabled, F5 may sell only complete stacks from the local common inventory
  whose exact static item ID is in this fixed whitelist: `Ruby`, `Sapphire`,
  `Eemerald`, `Diamond`, and `PalItem_ToSell_01` through
  `PalItem_ToSell_05`. The whitelist represents the current items whose game
  description says merchants buy them for a high price; localized display text
  is never used as a runtime classifier.
- The Inventory `Tab` -> `R` exclusion list has higher priority than automatic
  sale, regardless of `IncludeExcludedItems`. An excluded whitelisted item is
  neither sold nor removed from the existing excluded-result accounting.
- Sale uses only a current, server-registered item shop ID obtained through a
  proved game-owned route. Missing, zero, stale, or unverifiable shop context
  skips the sale phase without blocking the existing Quick Stack routes. The mod
  must not invent a shop ID, create a synthetic shop, or delete items directly.
- Every sale candidate is revalidated against the same local common container,
  slot index, item ID, stack count, player, world, and job generation immediately
  before submission. Sell requests are paced to at most one per frame and run
  before storage routing so a sold stack cannot also be moved.
- After a sell request is submitted, any unconfirmed remainder stays in the
  backpack for that F5 job and is reported as pending. It is not routed to
  storage, because a late server sale must never race a move of the same stack.
- `AutoSellAmmo` is a separate default-off toggle. When enabled, complete
  common-inventory stacks may join the same pre-storage sale batch only when
  their exact static item ID is present in `AmmoSellItems`. The persisted value
  is a comma-separated, canonical sell allowlist; it defaults to empty, ignores
  unknown IDs, and therefore protects ammunition added by a later game update.
- `AutoSellPalSpheres` and `AutoSellFishingBait` are independent default-off
  toggles. Their canonical `PalSphereSellItems` and `FishingBaitSellItems`
  allowlists both default to empty. A common-inventory stack may join the same
  pre-storage sale batch only when its toggle is enabled and its exact current,
  legal static item ID is explicitly present in the corresponding allowlist.
- The Pal Sphere catalog contains the ten current legal
  `SpecialWeapon` / `SPWeaponCaptureBall` items: `PalSphere`,
  `PalSphere_Mega`, `PalSphere_Giga`, `PalSphere_Tera`, `PalSphere_Master`,
  `PalSphere_Legend`, `PalSphere_Ultimate`, `PalSphere_Exotic`,
  `PalSphere_Ancient_1`, and `PalSphere_Ancient_2`. The fishing-bait catalog
  contains the four current legal `Consume` / `ConsumeFishingBait` items:
  `FishingBait_1`, `FishingBait_2`, `FishingBait_3`, and `FishingBait_3_A`.
  Hidden, disabled, debug, Blueprint, Essential, launcher, module, and fishing-
  rod rows are never exposed or accepted.
- The ammunition picker presents all 32 current, legal `ConsumeBullet` items
  with each item's game-owned icon texture and localized name. The valuable
  picker presents all nine fixed high-value merchant items in the same form;
  the Pal Sphere and fishing-bait pickers present their fixed legal catalogs.
  All four pickers reserve fixed checkmark, icon, and scrollbar geometry before
  textures load, so toggling, deferred population, scrolling, and scrollbar
  appearance cannot move a row horizontally. An icon image remains hidden
  until a valid texture is assigned, rather than exposing UMG's white default
  brush. Display names come
  from the current-build game localization tables for all 17 supported
  interface locales, with the stable item ID only as a missing-data fallback.
  They must not
  instantiate or call `WBP_Paldex_DropItem_C:Setup` from Lua: the installed
  UE4SS build can terminate the process while marshalling that reflected
  `FName` route. A checked item means **keep it; do not sell it**. The current
  catalog is: `Arrow`, `Arrow_Fire`,
  `Arrow_Poison`, `AssaultRifleBullet`, `BeamLauncherBullet`,
  `ChargeLaserRifleBullet`, `ElectricArcAssaultRifleBullet`,
  `EnergyLauncherBullet`, `EnergyShotgunBullet`, `ExplosiveBullet`,
  `FlamethrowerBullet`, `GatlingBullet`, `GrenadeBullet`, `HandgunBullet`,
  `InkBullet`, `LaserBullet`, `LaserGatlingBullet`, `MeteorBullet`,
  `MissileBullet`, `OverheatRifleBullet`, `PalDopingShotBullet`,
  `ReinforcedArrow`, `RifleBullet`, `RoughBullet`, `SFArrow`,
  `ShotgunBullet`, `SkyAssaultRifleBullet`, `SkyBowArrow`,
  `SkyGrenadeLauncherBullet`, `SkyShotgunBullet`,
  `SkySubmachineGunBullet`, and `WidePenetrateShotgunBullet`. Hidden or disabled
  ammunition is never exposed or accepted.
- The Inventory `Tab` -> `R` exclusion remains stronger than every automatic
  sale rule. Valuables, selected ammunition, selected Pal Spheres, and selected
  fishing bait share one vendor lookup and one sale request, and the complete
  sale phase finishes or safely degrades before metadata discovery or any
  storage request begins.

### Routing order

Eligibility and route restrictions use this fixed order for every common-
inventory item:

1. The automatic-sale phase first removes eligible, non-excluded valuables,
   explicitly selected ammunition, Pal Spheres, and fishing bait from storage
   consideration. A submitted but unconfirmed sale also remains in the backpack
   for the current job.
2. A `Tab` -> `R` ignored item stays in the player inventory unless
   `IncludeExcludedItems = true`.
3. `PalEggRouting = "ManualPlacement"` leaves every eligible Pal Egg in the
   inventory without scanning metadata or planning a destination. Otherwise an
   eligible Pal Egg uses available incubators first. `IncubatorOnly` leaves any
   remainder in the inventory; `IncubatorThenStorage` continues through
   ordinary-storage routing.
4. `RelicRouting = "ManualPlacement"` leaves every eligible Ancient
   Civilization Relic in the inventory without scanning metadata or planning a
   destination. Otherwise an eligible relic uses all compatible Ancient Relic
   Recyclers in stable current-base discovery order. `RecyclerOnly` leaves any
   remainder in the inventory; `RecyclerThenStorage` continues through
   ordinary-storage routing.
5. `IncludeNewItems = false` restricts only the ordinary-storage route to writable storage
   that already contains the exact item. Empty incubators and empty storage
   accepted only by filters are not ordinary-storage candidates; empty
   incubators and recycler slots remain eligible.
6. The ordinary route prefers writable storage containing the exact item, then
   writable storage whose filter accepts the item category.
7. Leave the item in the player inventory when no valid capacity remains.

The current-build `WorldTreeRelic_01` through `WorldTreeRelic_05` IDs identify
Ancient Civilization Relics even when no recycler exists in the base. Every
live recycler's dedicated-container permission list is still authoritative for
whether that recycler may receive a specific relic. A recycler whose
permission contract is unreadable is not used. A recycler
that exists but rejects the specific item is not treated as full. A partially
accepted stack is split at the plan boundary: the accepted quantity is sent to
the recycler and the remainder continues through ordinary-storage routing.

`WorldTreeHolyWater` uses each recycler's dedicated `BoostItemContainer` before
ordinary storage. This independent boost-item rule is unchanged by
`RelicRouting = "ManualPlacement"`. Quick Stack tops up every Ancient Relic
Recycler in stable current-base order to `WorldTreeHolyWaterMinimum` (default
`10`, integer range `1..100`). If the backpack cannot satisfy every recycler,
earlier recyclers are filled first. Water above the configured minimum
continues through the ordinary storage route; ignored-item and ordinary-storage
settings still apply.

Guild Chests are excluded before any generic storage-class match while
`IncludeGuildChest = false`. When enabled, they remain a distinct
`guild_storage` destination: Quick Stack verifies the local guild, Guild Chest
role access and current-base ownership, obtains the shared container through
`IPalMapObjectItemContainerAccessInterface`, waits for bounded replication
readiness when necessary, and deduplicates all matching entities by the shared
container GUID. The same guild/access/container identity checks repeat before
submission. Missing or ambiguous state skips Guild Chest routing without
weakening ordinary-storage routing.

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

Already-classified ordinary storage and supported incubators may reread an
unavailable container, container GUID, slot array, or slot before planning.
Each destination gets at most three rereads, separated by 100 ms, with at most
15 rereads across the job. Each reread discards the partial destination snapshot
and resolves the container again. Successful destinations retain discovery
order; fully readable jobs incur no retry delay. Unknown models are not added
to this path, and the base object list is not rescanned. Empty arrays, rejected
permissions, and insufficient capacity do not trigger rereads.

An exhausted unreadable destination is recorded as unresolved in the normal
log, not as full. Planning may use other readable destinations, but does not
classify an item's remainder as a capacity failure when an unresolved
destination kind could receive that item. Existing submission rechecks remain
authoritative. This is bounded read-failure tolerance, not verified multiplayer
compatibility. It adds no ordinary-container replication requests or idle hooks.

### Optional small incubators

`IncludeSmallIncubators = false` is the default, including existing configs.
Disabled jobs do not resolve the small-incubator class or read its containers.
When enabled, eggs are planned into large incubators first, small incubators
second, and ordinary storage only under `IncubatorThenStorage`. Exclusions and
`ManualPlacement` still apply. A small incubator must have exactly one readable
empty slot and no valid `HatchedCharacterSaveParameter`. The reflected
`CharacterID == NAME_None` check matches the current native
`PalIndividualCharacterSaveParameterUtility.IsValid` predicate without passing
the whole save struct through UE4SS.

Before the first small-incubator submission, one bounded, game-thread sweep
re-resolves the already-discovered large incubators and verifies they have no
empty slots. Unreadable state, a failed large request, or remaining large space
blocks all small-incubator requests in that job; there is no automatic retry of
the move RPC. The sweep may wait for local replication at most three times at
100 ms intervals when large slots are still empty. Each small target is checked
again immediately before its own submission. This is a client-side phase
boundary check, not an atomic guarantee against concurrent server/player edits.

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
- The settings row explains `Default` in-place with secondary text equivalent
  to: `Automatic: show the result window when triggered from the inventory;
  otherwise show text.` This describes the existing trigger-time behavior and
  does not change it.
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

Each configuration write first completes and closes a sibling `.tmp` file.
When an authoritative file already exists, Quick Stack preserves it as `.bak`
before promoting the temporary file and attempts to restore that backup if
promotion fails. If the authoritative file is absent on startup, a
structurally valid `.bak` file is loaded and restoration is attempted before
legacy import or package defaults. A `.tmp` file is never authoritative.

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
    IncludeGuildChest = false,
    AutoSellValuables = false,
    ValuableSellItems = "Ruby,Sapphire,Eemerald,Diamond,PalItem_ToSell_01,PalItem_ToSell_02,PalItem_ToSell_03,PalItem_ToSell_04,PalItem_ToSell_05",
    AutoSellAmmo = false,
    AmmoSellItems = "",
    AutoSellPalSpheres = false,
    PalSphereSellItems = "",
    AutoSellFishingBait = false,
    FishingBaitSellItems = "",
    PalEggRouting = "IncubatorOnly",
    RelicRouting = "RecyclerOnly",
    WorldTreeHolyWaterMinimum = 10,
    Debug = false,
}
```

`ResultDisplay` accepts `Default`, `TextOnly`, or `ResultWindow`.
`ValuableSellItems`, `AmmoSellItems`, `PalSphereSellItems`, and
`FishingBaitSellItems` accept only canonical comma-separated IDs from their
current fixed catalogs; normalization removes duplicates and unknown IDs.
A writable configuration using
the former `ShowDetailedResults`, `OnlyExistingItems`, `IncludePalEggs`,
`ExcludePalEggs`, `AltEggSorting`, `IncubatorsFirst`, or `FillByChestFilter`
fields is migrated or removed and rewritten canonically. Experimental
`RelicRouting` values are migrated to `RecyclerOnly` or
`RecyclerThenStorage`.

`PalEggRouting` accepts `IncubatorOnly`, `IncubatorThenStorage`, or
`ManualPlacement`. `RelicRouting` accepts `RecyclerOnly`,
`RecyclerThenStorage`, or `ManualPlacement`.

Manual edits made while the game is running are not required to hot-reload.
Users should close the game, edit the writable file, and restart. Modifier
examples must be documented; `Ctrl+S` is represented by `Key = "S"` and
`Ctrl = true`.

`IncubatorOnly` and `RecyclerOnly` are the first displayed choices and the
defaults for a fresh writable configuration and for Restore Defaults. An
existing valid writable choice remains authoritative during an update; the
runtime must not reinterpret or silently migrate an explicit
`IncubatorThenStorage`, `RecyclerThenStorage`, or `ManualPlacement` preference.
`ManualPlacement` is the third displayed choice for both routes. It takes
priority over dedicated-facility and ordinary-storage routing, but does not
change `Tab` -> `R` exclusion reporting or the independent World Tree Holy Water
top-up rule.

The shortcut selector rejects `F6`, `Escape`, and `LeftMouseButton`, because
those inputs are owned by the settings surface itself. Rejection is silent in
the visible settings UI: the selector restores the last persisted valid chord
without showing a save-failure status. Validation still rejects the candidate
internally. Conflict presentation is refreshed only after that rollback and
must describe the persisted valid chord, never the rejected transient input.
A chord already owned by another UE4SS callback remains selectable, but the
settings surface shows the same possible-conflict warning used by Pal Insight.
A retained callback that belongs to this Quick Stack runtime must not be
reported as an external conflict.

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
  Ownership follows Pal Insight's generation and heartbeat rather than its
  transient actor-backed UI readiness. Any earlier process-lifetime Quick Stack
  callback becomes inert instead of forwarding the same press. `F5` remains
  Quick Stack's gameplay action and is unaffected.
- Pal Insight's top-level `Extensions` page always contains one Quick Stack
  catalog row. A compatible runtime shows its version and opens the same Quick
  Stack-owned surface as a separate hosted panel. Missing or incompatible
  runtime states show the current distribution channel's install/update link.
  Nexus Mods and CurseForge each publish a separate WinGDK/Game Pass archive;
  the Steam/Win64 archive must not be installed into a WinGDK game directory.
- The settings body follows runtime order: Basics, Automatic Sale, Storage
  Rules, then Special Item Storage. Automatic Sale contains the valuables and
  toggles plus dedicated valuable-item, ammunition, Pal Sphere, and fishing-
  bait pickers. Each picker is
  one modal transaction, loads game-owned item icon textures directly and uses
  the extracted current-build localized item-name catalog without constructing
  native item-row widgets, clearly states that checked means kept, and persists
  changes through the same validated settings path as the other controls.
- Simplified and Traditional Chinese use concise parallel labels for both sale
  categories: `自动出售高价品` / `保留的高价品` and
  `自動出售高價品` / `保留的高價品`, matching the ammunition wording.
- The two new Chinese setting pairs use the same wording structure:
  `自动出售帕鲁球` / `保留的帕鲁球`, `自动出售钓饵` / `保留的钓饵`,
  and their Traditional Chinese equivalents. The fishing-bait wording follows
  the game's official `钓饵` / `釣餌` item names.
- Both automatic-sale pickers use the same navigation contract as the root
  settings page. `W`/`S` and Up/Down accept Slate's keyboard-repeat events;
  controller D-pad and left stick use the retained physical-state repeat path.
  A light press moves exactly once, while a held input continues moving.
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
  rows are scrolled into view. `Shift+Tab` navigates backward. Holding vertical
  keyboard directions, the controller D-pad, or the left stick repeats after a
  bounded initial delay and stops immediately on release, direction change,
  modal transition, or settings-session invalidation.
- Real pointer movement changes the active input family without requiring a
  click. While the settings surface owns modal input, cursor visibility is an
  invariant: pointer events repair it immediately and the open-only control pump
  provides a bounded fallback when Slate does not deliver a movement event.
  Pointer hover targets only the native control under the cursor and does not
  promote that control into the persistent keyboard/controller selection. An
  actual pointer activation of a root settings control promotes that control
  before running its Toggle, Choice, Number, Shortcut, or other setting action,
  so the next keyboard/controller direction continues from the clicked control.
  Choice close, shortcut capture completion, and mouse number-edit completion
  restore that clicked control. Header actions retain the existing content
  selection across their modal transaction.
- The fixed Header matches Pal Insight's settings chrome: the optional Steam
  Workshop vote control precedes About, Restore Defaults, and Close in that
  order, using the same native UMG Button brushes, dimensions, spacing, icon
  canvases, semantic hover/pressed colors, and focus treatment. While focus is
  in this Header action row, keyboard/controller Left and Right move through
  the currently interactive actions in display order and wrap at both ends;
  Up and Down retain the existing vertical settings navigation. Every shared
  action surface uses Pal Insight's direct `SizeBox -> Button` tree; choice
  buttons, nested-modal options, the Steam vote action, About actions, and
  modal close actions must not add a transparent `CheckBox` proxy. When the
  cooked bridge is available, each direct Button's native `OnClicked` delegate
  is the sole mouse action owner. The process-lifetime `LeftMouseButton`
  binding is only a standalone compatibility fallback and is suppressed while
  native delegates are live; both routes share one hovered-action executor and
  must never run for the same click. Toggle rows use the focusable
  native `CheckBox`; keyboard/controller activation performs an explicit state
  change, while native mouse changes are observed through an idempotent typed
  `OnCheckStateChanged` bridge and the open-panel pump remains only a fallback.
  Shortcut rows preserve Pal Insight's selector geometry and capture
  transaction: the activating click/key is rejected as a candidate, invalid
  values restore the persisted chord, and capture releases focus before any
  unrelated setting can commit. Number rows use Pal Insight 1.8.0's layered
  resting Button and writable `EditableTextBox`. Pointer activation gives the
  native editor focus for caret, selection, deletion, and direct integer entry;
  keyboard and controller activation keep focus on the settings root and use
  the bounded settings-owned integer buffer. Only the integer operations
  required by the active mode are accepted, while unsupported letters, paste,
  and composition triggers are consumed. The
  text beneath Header actions is a virtual
  focus hint for keyboard and controller only; mouse hover keeps the button
  Tooltip and hover styling but leaves that hint empty. Restore Defaults opens
  a nested confirmation
  modal instead of applying immediately. Cancel is selected by default; only
  the explicit confirmation restores all Quick Stack settings, including the
  shortcut. Escape or controller Back cancels and returns focus to Restore
  Defaults. The Footer is informational only. About opens a
  Quick Stack-owned modal and all three actions remain operable by mouse,
  keyboard, and controller. The About modal is not a placeholder: it identifies
  Quick Stack, recommends Pal Insight without implying that Quick Stack depends
  on it, and uses the same three-column creator hierarchy as Pal Insight. The
  CrateX.app action is on the left, the creator biography is in the center, and
  Special Thanks plus Supporters remain fixed on the right even when their
  rosters are empty. Those two roster actions use the same shared direct-Button
  contract, construction order, content fill, padding, focusability, semantic
  style, and action registration as Pal Insight. Their leading symbols use the
  shared medal and heart image assets so meaning and alignment do not depend on
  the active font.
  Each roster opens as a nested modal with the same geometry,
  typography, grouping, empty state, close action, focus treatment, and static
  per-mode content structure as Pal Insight; it must not substitute a shared
  dynamic approximation. Credit symbols and their image fallbacks use the same
  credit-entry representation as Pal Insight. The modal also exposes Quick
  Stack's Nexus Mods, Steam Workshop, and CurseForge pages, X, Discord, and Buy
  Me a Coffee. Community occupies a compact fixed `160`-unit left card and is
  split internally into two equal columns, each centering one `52x52`
  icon-only X or Discord action; tooltips, accessible names, and focus hints
  retain the action semantics without permanent labels. Support fills the
  remaining width so the wrapped Buy Me a Coffee copy has priority over unused
  Community whitespace. Its copy uses the same warm, adventure-oriented
  sentence pattern as Pal Insight, with Quick Stack named as the product. Copy
  is complete in all 17 supported locales; external destinations open outside
  the game, while the modal keeps input ownership and remains open.
- The three product columns always remain one equal-width row and use identical
  `title nameplate -> framed media -> action row` geometry. Each column has one
  neutral card surface and the current product receives no persistent outline,
  tint, badge, or geometry change. Every cover and screenshot is wrapped by the
  same one-unit low-contrast media frame with three units of safe inset. Each
  Mod platform row is split into three equal cells; every icon-only button fills
  its cell and shares the Breeding Calculator text action's height, default
  surface, low-contrast boundary, and interaction states. The calculator action
  remains localized and text-only. Visible labels must always use their
  localized or brand text and must never expose font-size metadata.
- Every settings primitive shared with Pal Insight follows the same current F6
  design system: window and scrollbar geometry, typography, section rhythm,
  whole-row hover and virtual focus, checkbox states, fixed-column Choice
  arrows, number and shortcut capture states, conflict-note spacing, modal
  selection, Header actions, Footer key guides, and About surfaces. Product
  structure remains intentionally different: Quick Stack has one settings page
  instead of Pal Insight's tab deck, and its Footer exposes only operations that
  the Quick Stack panel can actually perform.
- Closing About restores the exact parent settings selection captured before
  opening it. That virtual selection remains visible for mouse, keyboard, and
  controller alike; pointer hover is transient and must not erase it.
- Workshop voting is owned by a Quick Stack-specific native helper and targets
  Quick Stack Workshop item `3792968111`; it must never read or change Pal
  Insight item `3778493118`. The visual states and interaction rules match Pal
  Insight: an outline thumb for no vote, an inverted Chillet with a black down
  thumb for a down vote, and a normal Chillet with a gold up thumb for an up
  vote. Every state must preserve the thumb silhouette; a solid color rectangle
  is not an acceptable fallback. The Chillet portrait keeps its fixed canvas
  but receives angle-aware optical vertical compensation for the asymmetric
  source art and an angle-aware horizontal mirror so both the upright and
  inverted portrait face the adjacent thumb; the thumb remains geometrically
  centered. Only no-vote/down-vote states can submit an up vote. Non-Workshop
  packages omit the helper and therefore omit the control.
- Opening and closing are transactional. An open acknowledgement is published
  only after the widget and modal input lease are both live. A closed
  acknowledgement is published only after input isolation and the prior input
  context are restored; a failed restore leaves a visible recovery surface
  instead of silently acknowledging success. Every delayed input/edit action is
  scoped to the current settings session, widget, world, and controller. The
  opening widget remains fully transparent while modal ownership and the
  authoritative first-row selection are established, ignores opening-phase
  synthetic pointer-family changes, and becomes opaque only after that first
  selection has been styled. The
  open-only pump closes a stale surface when any of those owners changes. A
  bounded close-recovery watchdog retries transient restoration failures, then
  releases the modal lease through a fail-open emergency path rather than
  leaving an unrecoverable input lock.
- The settings widget is reused only while its world, local controller, locale,
  viewport size, and widget identity still match. Closing hides the valid
  cached tree after releasing input; a mismatch discards it before rebuilding,
  so repeated opens do not synchronously reconstruct the complete UMG tree.
- Process-lifetime preview/input hooks and the optional Pal Insight bridge asset
  are prepared once. Standalone-only native Escape gates are installed once on
  the first standalone acquisition. The settings tree is prewarmed on the game
  thread after the local player controller's `ClientRestart` establishes a
  usable world and controller. Opening the Pal Insight settings stack may request
  the same preparation as a fallback; an already prepared or pending window
  makes that request a no-op. One retained, cancellable action may retry the work
  for at most five seconds; only an explicit `windowReady = true` result is
  success, and success, exhaustion, or runtime supersession stops the action.
  Idle host reconciliation must not rebuild, validate, or prewarm the settings
  tree. If lifecycle and active-host preparation were unavailable or exhausted,
  the actual open transaction may retry only the missing preparation work. The
  Workshop vote Pal portrait follows the same bounded retry rule; a warm open
  never calls `LoadAsset` to repair it.
- Numeric fields retain Pal Insight 1.8.0's direct integer-entry split. Pointer
  activation swaps the resting Button for a writable native editor and focuses
  it; repeated pointer clicks preserve the caret, selection, and edit
  transaction. Root `OnPreviewKeyDown` lets only digits, numpad digits,
  Backspace, Delete, Home, End, bounded minus, and unmodified `Ctrl+A` reach the
  pointer-owned editor while consuming unsupported keys. Keyboard/controller
  activation keeps focus on the settings root and uses the bounded integer
  buffer. Commit, cancel, navigation, close, and focus restoration all
  terminate exactly one edit transaction.
- Focus-scoped UMG preview input is the primary keyboard owner. Global keybinds
  remain only as a compatibility fallback: their scalar events are bounded and
  marshalled to the game thread, while the existing open-panel pump can drain a
  lost wake without blocking later input. Cooked controller axis events dispatch
  directly through a type-checked handler. Cooked controller key parameters
  accept both reflected `FName` wrappers and direct Lua strings; standalone
  polling remains the fallback, and both routes feed the same D-pad, stick,
  Accept, and Back handlers. Preview/cooked ownership suppresses
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

Protocol version 3 assigns every hosted open exactly one controller route:
`host-native` retains Pal Insight's native filter and delivers scoped controller
snapshots, while `extension-cooked` suspends the parent cooked bridge and lets
Quick Stack mount the child route. Open, failure, and close acknowledgements
echo the selected route. Quick Stack rolls back when it cannot publish the open
acknowledgement and retains a failed close acknowledgement for retry, so the
parent never restores a competing input route from a partial transaction.

Load order is symmetric. `IsKeyBindRegistered(F6)` proves only that the chord is
occupied; it does not identify the callback owner. Quick Stack skips a new
registration only when the shared generation and cooperative behavior version
identify a retained Quick Stack callback, or when a live Pal Insight lease owns
`F6`. For any other occupied `F6`, Quick Stack logs a possible external conflict
and still registers its standalone settings callback, so an unrelated callback
cannot make Quick Stack settings unreachable; both external actions may run for
the same press. If Quick Stack registers first, Pal Insight later becomes the
sole live action owner within the cooperative pair and the retained Quick Stack
callback becomes inert while the runtime ownership lease is live, even during a
temporary actor/UI readiness gap. After a Quick Stack hot reload, a retained
callback targets only the newest Quick Stack generation while no Pal Insight
host is live. Quick Stack publishes a versioned cooperative-F6 capability so Pal
Insight can distinguish this behavior from an older or external callback. Quick
Stack publishes capability and reconciles legacy settings from its existing
500 ms cadence. This idle heartbeat reads and writes only scalar shared state;
it never prepares widgets, walks
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
- Guild Chests receive zero automatic move requests by default. When
  `IncludeGuildChest = true`, only a role-accessible current-base Guild Chest
  belonging to the local player's guild may receive requests, and its shared
  container GUID is planned only once.
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
  persist the shortcut, result-display choice, three storage-rule toggles, Pal
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
