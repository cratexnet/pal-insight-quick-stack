# Implementation Plan: Pal Insight: Quick Stack

## Overview

Deliver an independent, fail-closed Quick Stack mod in risk-first slices. Prove
the current Palworld item-move contract and base-local discovery route before
building routing breadth or optional Pal Insight integration.

## Architecture Decisions

- Keep Quick Stack in its own repository and Workshop item.
- Treat one F5 operation as a generation-scoped job with a single owner.
- Freeze the three-state result-display policy at the accepted F5 press. When a
  detailed card is selected, own its modal input independently of the later
  Inventory/Equipment lifecycle and restore the latest external mode on close.
- Enumerate only the current base's map-object IDs; never scan all live objects.
- Build one destination snapshot and item/category indexes per valid job/base
  generation.
- Pace server requests to at most one destination per frame.
- Keep writable Saved-directory `PalInsightQuickStackSettings.lua` as the
  standalone source of truth; packaged configuration is only a first-run seed.
- Add Pal Insight F6 integration only after the standalone route is accepted.

## Dependency Graph

```text
Runtime contract proof
  -> strict local context and input gate
    -> current-base destination snapshot
      -> indexed routing plan
        -> paced server submission
          -> egg/incubator parity
            -> standalone acceptance
              -> optional Pal Insight F6 bridge
                -> release tooling and packaging
```

## Phase 0: Specification

- [x] Record product, behavior, performance, integration, and safety contracts.
- [x] Human review and approval of `SPEC.md` and this plan.

## Phase 1: Risk Proof

- [x] Confirm the reflected current-build item move RPC argument contract.
- [x] Confirm a strict route to the local common inventory and exclusion list.
- [x] Confirm a current-base-only route to supported storage and incubators.
- [x] Record unknown or unsupported container families instead of adding global
  fallbacks.

### Checkpoint: Runtime contract

- [x] Static evidence is recorded with exact SDK/runtime source locations.
- [x] The required opt-in runtime probe had separate approval and was removed
  from the active UE4SS mod directory after capture.
- [x] No production routing code depends on an unverified signature.

## Phase 2: Standalone Core

- [x] Add the minimal UE4SS project skeleton and F5 configuration.
- [x] Add one coalesced, game-thread, generation-scoped job owner.
- [x] Resolve local context and exclusions with fail-closed guards.
- [x] Snapshot the current base and build destination indexes in bounded slices.
- [x] Plan ordinary-item moves using existing-item then filter routing.
- [x] Submit at most one destination request per frame with stale-state checks.

## Phase 2A: Optional Valuables Sale

- [x] Freeze one default-off `AutoSellValuables` toggle and an exact nine-ID
  whitelist derived from current game item-description data.
- [x] Prove the current-build sell RPC ABI, server-registered `ShopID` source,
  and shop lifetime without relying on an empty or synthetic shop ID.
- [x] Add the setting to writable config, standalone F6, and the Pal Insight
  shared-settings bridge.
- [x] Add a generation-scoped sale phase that revalidates source slots, respects
  `Tab` -> `R` exclusions, and never submits more than one sell request per frame.
- [x] Run the narrow Lua/static checks and record any runtime behavior that static
  evidence cannot verify.

## Phase 2B: Optional Ammunition Sale

- [x] Freeze the current 32-item legal ammunition catalog and native icon/name
  presentation contract from current game data.
- [x] Add default-off `AutoSellAmmo` and a fail-closed explicit ammunition sell
  allowlist to writable config and the shared-settings bridge.
- [x] Add ammunition to the existing exclusion-aware pre-storage sale batch.
- [x] Reorganize settings into runtime order, add the icon-assisted keep picker,
  and explain the automatic result-display behavior beneath its row.
- [x] Run the narrow Lua/static checks and record remaining runtime-only risk.

## Phase 2C: Optional Pal Sphere and Fishing Bait Sale

- [x] Freeze the current 10-item legal Pal Sphere catalog and 4-item legal
  fishing-bait catalog from current game data, including native icon exceptions.
- [x] Add two default-off toggles and two fail-closed explicit sell allowlists
  to writable config and the shared-settings bridge.
- [x] Add both categories to the existing exclusion-aware pre-storage sale batch.
- [x] Reuse the icon-assisted keep picker and localized item-name catalog for
  both categories without adding a second modal implementation.
- [x] Run the narrow Lua/static checks and record remaining runtime-only risk.

### Checkpoint: Ordinary items

- [x] Lua syntax check passes.
- [x] Static audit finds no warm-path `FindAllOf`.
- [x] No job can overlap or survive a world/base generation change.
- [x] In-game ordinary-item comparison is documented and ready for a separately
  approved prototype installation.

### Bounded destination rereads (2026-09-04)

- [x] Limit rereads to already-classified ordinary storage and supported
  incubators, before planning; retain stable discovery order and fresh snapshots.
- [x] Bound rereads per target and per job; preserve GameThread generation guards.
- [x] Record unreadable targets separately from known capacity failures; do not
  add ordinary-container Start/Stop calls, base rescans, or idle hooks.
- [ ] Validate transient unreadability, exhausted retries, and world/base changes
  in game. Multiplayer compatibility is still unverified.

## Phase 3: Egg Parity and Acceptance

- [x] Add exclusion-aware alternate egg classification.
- [x] Add incubator-first routing and chest spillover.
- [x] Add representative manual acceptance and performance ledgers.
- [ ] Validate single-player, then co-op client, then dedicated-server client.
  Community evidence recorded on 2026-09-05 confirms dedicated-server use with
  a client-side-only install. Future release descriptions must cite that bounded
  report instead of saying dedicated servers are untested; co-op, the exact
  game build, and the distribution platform remain unverified.

### Checkpoint: Standalone candidate

- [ ] Reference and candidate final placement match for the agreed matrix.
- [ ] Excluded ordinary items and eggs never move.
- [ ] Performance capture meets the recorded budget on the representative base.
- [ ] Developer-only diagnostics are false and excluded from candidate artifacts.

## Phase 4: Optional Pal Insight Integration

- [ ] Publish Quick Stack presence, versions, settings, and revision through
  scalar UE4SS shared variables.
- [ ] Add low-frequency revision reconciliation and safe keybind replacement.
- [ ] With separate approval, append a conditional `Pal Insight: Quick Stack`
  class to the bottom of Pal Insight's existing final F6 tab, `Controls`, with
  only the shortcut setting.
- [ ] Verify both load orders, missing/incompatible versions, config persistence,
  and independent uninstall behavior.

### Checkpoint: Integration

- [ ] Standalone Quick Stack remains fully functional without Pal Insight.
- [ ] Pal Insight remains fully functional without Quick Stack.
- [ ] No incompatible or absent integration produces an empty F6 section.
- [ ] No Quick Stack setting appears outside its own `Controls` class.

## Phase 5: Distribution

- [x] Add standalone runtime localization for all 17 Palworld interface locales
  with English fallback and native localized item rows.
- [x] Localize the optional Pal Insight Quick Stack shortcut row in the same 17
  locales without changing the fixed product section name.
- [ ] Observe English, Simplified Chinese, and one long-text locale in game.
- [x] Add independent release inventory and diagnostics gate.
- [x] Add separate Win64 and WinGDK portable layouts for Nexus and CurseForge.
- [x] Prepare README, changelog, icon, Workshop metadata, and compatibility text.
- [x] Document both manual Saved-directory rebinding and the conditional
  `F6 -> Controls -> Pal Insight: Quick Stack` path.
- [ ] Obtain explicit approval before building, packaging, creating GitHub, or
  publishing Workshop content.

## Phase 6: Dedicated Facility Routing

- [x] Define Pal Egg and Ancient Civilization Relic routing contracts, including
  an explicit third `ManualPlacement` choice that performs no automatic move.
- [x] Prove the current-build recycler container and item-eligibility contracts;
  destination movement remains part of the representative in-game matrix.
- [x] Add current-base recycler discovery without `FindAllOf` or a second base
  scan.
- [x] Add `IncubatorOnly` / `IncubatorThenStorage` and `RecyclerOnly` /
  `RecyclerThenStorage` planning and recheck behavior.
- [x] Publish both shared string settings and add localized Pal Insight F6 choices.
- [x] Route `WorldTreeHolyWater` through each recycler's dedicated boost
  container up to a configurable `1–100` minimum without a second base scan.
- [x] Publish the numeric minimum and add its localized Pal Insight F6 editor.
- [x] Run the static release gates.
- [ ] Complete one representative in-game matrix.

## Phase 7: Pal Insight Settings Primitive Parity

- [x] Revalidate the shortcut binding and settings-window generation before a
  queued press starts a job; Lua syntax and the existing host-routing contract pass.
- [ ] Verify in game that opening/closing settings discards a queued old press
  and that the next normal shortcut press still starts Quick Stack.
- [x] Freeze shared settings controls to Pal Insight's direct native control
  trees; native `OnClicked` owns direct Buttons and the process-lifetime mouse
  binding remains a mutually exclusive standalone fallback.
- [x] Replace transparent action proxies in Header, Steam voting, choices,
  nested modals, and About with direct focusable Buttons.
- [x] Match focusable toggle and shortcut-selector geometry.
- [x] Keep the three Header glyphs and version-button text at the primary color
  across normal, hovered, and pressed states while retaining semantic backgrounds.
- [x] Match Pal Insight 1.8.0 numeric editing: pointer input uses the layered
  writable native editor, while keyboard/controller input retains the bounded
  root-owned integer buffer.
- [x] Update the release diagnostics gate for the direct-control contract.
- [x] Keep integer routing inside the root preview owner so only the 1.8.0
  native numeric allowlist reaches pointer-owned Slate editing; keyboard and
  controller input continue through the bounded root-owned buffer.
- [x] Separate explicit toggle activation from native change observation and
  keep the existing poll only as an idempotent fallback.
- [x] Keep pointer hover transient, but promote an explicitly clicked root
  setting control into the shared keyboard/controller selection before action.
- [x] Commit each settings primitive independently so transient shortcut
  capture state cannot veto checkbox, choice, or number persistence.
- [x] Reject and restore the shortcut activation key before releasing native
  capture focus; warnings must continue to describe only the persisted chord.
- [x] Update the existing static regression contract from the rejected live
  bridge/all-device root buffer to stable default-object delegates, layered
  number editing, and persisted-only shortcut conflict warnings.
- [x] Match Pal Insight's interaction refinements: reverse `Shift+Tab`, bounded
  keyboard/D-pad/stick repeat, real pointer-family detection, and cursor repair.
- [x] Scope delayed settings actions to the current window/world/controller
  session and add stale-context close plus bounded close-recovery watchdog.
- [x] Normalize cooked controller keys from either reflected `FName` values or
  direct strings, while retaining the standalone controller polling fallback.
- [x] Keep the prepared window transparent until modal ownership and the
  authoritative first-row selection are both established.
- [x] Trigger settings prewarm from the local controller `ClientRestart`
  lifecycle with an independently latched Pal Insight settings-stack fallback.
  Require an explicit ready window, and stop its retained retry action on
  success, timeout, or runtime supersession.
- [x] Verify in game that the first hosted open reuses the prepared settings
  tree (`window_cache=hit`, 19 ms observed) on the Insight-to-Quick-Stack click.
- [x] Reserve the main one-page settings scrollbar before its first Slate
  layout pass so the cold open cannot shift right-aligned controls.
- [ ] Verify mouse, keyboard, and controller behavior in game before syncing or
  packaging.

## Phase 8: About Product Hierarchy

- [x] Keep the product shelf in one three-column row at every supported About
  width.
- [x] Reorder every product card to title nameplate, framed media, then actions.
- [x] Make each Mod platform action fill one third of the row and share the
  calculator text action's visual component without adding platform labels.
- [x] Preserve existing mouse, keyboard, controller, tooltip, and preview
  behavior while changing only layout and presentation.

## Phase 9: Optional Guild Chest Routing

- [x] Add a default-off `IncludeGuildChest` setting to the writable config and
  standalone/hosted settings surface.
- [x] Resolve only a current-base Guild Chest owned by the local player's guild
  after `CheckGuildChestAccess` succeeds.
- [x] Use the Guild Chest item-container access interface and bounded
  replication-ready lifecycle instead of the ordinary storage module path.
- [x] Deduplicate the guild-wide shared container by GUID and revalidate guild,
  role, ownership, container identity, filters, permissions, and capacity before
  submission.
- [ ] Pass the narrow existing static checks and complete single-player,
  listen-client, and dedicated-client in-game acceptance before claiming
  multiplayer support.

## Optional small incubators (2026-09-04)

- [x] Add the default-off setting, persistence, shared settings, and all 17 locales.
- [x] Keep the small-class lookup and container reads disabled by default.
- [x] Plan large first, then gate small submission on a bounded large-capacity
  sweep; skip small for unreadable state, failed large requests, or remaining room.
- [x] Check the single egg slot and native hatched-character validity before
  indexing and immediately before submitting a small-incubator request.
- [x] User confirmed the reported small-only setup works after the job-config
  snapshot and reflected CharacterID fixes (2026-09-04).
- [ ] Complete in-game acceptance: setting save/reset, normal/electric small
  incubators, unclaimed Pal, large-first fallback, delayed replication, travel,
  exclusions, and ManualPlacement in single-player and multiplayer.

## Risks and Mitigations

### In-game version updates (2026-09-05)

- [x] Use the Header version number itself as the Version Updates action and
  keep the right action row limited to About, Restore Defaults, and Close.
- [x] Show static, newest-first Quick Stack release history with a running-
  version marker, verified historical public timestamps at source precision,
  and the current version's UTC timestamp captured when publication begins.
- [x] Mark the running version only with a green five-point star; do not append
  a localized Current label. Match Pal Insight's index-row geometry, typography,
  state colors, and fixed trailing marker cell.
- [x] Reproduce the finalized 1.2.0 changelog bullets in the panel and audit
  older summaries against their official release records.
- [x] Include the public 0.1.0 Beta in history; retain the default-off details
  from 1.1.0 and the Holy Water and package details from 1.0.0.
- [x] Localize the modal chrome, category headings, and release copy for all 17
  supported interface languages.
- [x] Preserve mouse, keyboard, controller, held-navigation, modal close, and
  exact Header-focus restoration behavior.
- [x] Match Pal Insight's version-number button presentation without a separate
  Version Updates glyph.
- [x] Defer pointer selection outside the native Button callback, scope queued
  actions to the Version Updates revision, and reset selection plus scroll state
  when reopening so a prior modal cannot leak state.
- [x] Pass the narrow existing release static checks.
- [ ] Verify mouse, keyboard, controller, held navigation, scrolling, close,
  and Header-focus restoration in game after an explicitly approved build and
  installation.

### Automatic-sale picker follow-up (2026-09-05)

- [x] Keep picker row geometry stable while icons populate and selections toggle.
- [x] Source ammunition and high-value-item names from the current game tables
  for every supported interface locale without calling the unsafe native item-row route.
- [x] Add a high-value-item keep picker backed by a canonical sell allowlist;
  preserve the existing sell-all behavior when the feature is first enabled.
- [ ] Reserve scrollbar width, hide unresolved icon brushes, invalidate
  world-bound image caches, and restore held keyboard/controller navigation in
  both item pickers.
- [ ] Verify both pickers in game: localized names, repeated off/on toggles,
  held navigation, scrolling, close/reopen persistence, and no new crash record.

- 2026-09-05：维护者确认当前候选版“都测过了，可以发”，授权发布 1.1.0。
  上述历史矩阵保留为环境级证据清单；本次确认没有细分多人、专服或 WinGDK 环境。

| Risk | Impact | Mitigation |
|---|---|---|
| Reflected RPC signature differs from reference Lua call | High | Prove current-build contract first; no guessed production call |
| Partial exclusion decode moves protected items | High | Abort entire job on any read/decode failure |
| UI or lifecycle change lets a stale F5 job continue | High | Single job owner plus world/base/controller generation tokens |
| Many containers cause a game-thread hitch | High | Base-local enumeration, indexed routing, bounded slices |
| Server rejects or delays request bursts | High | One destination request per frame and capacity recheck |
| Optional integration couples release cycles | Medium | Versioned scalar bridge; standalone config remains authoritative |
| UE4SS keybind cannot be unregistered | Medium | Old callbacks compare active signature and become inert |

## Open Questions

- See `SPEC.md` section `Open Questions Requiring Runtime Evidence`.
