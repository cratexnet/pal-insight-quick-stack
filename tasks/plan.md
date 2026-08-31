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

### Checkpoint: Ordinary items

- [x] Lua syntax check passes.
- [x] Static audit finds no warm-path `FindAllOf`.
- [x] No job can overlap or survive a world/base generation change.
- [x] In-game ordinary-item comparison is documented and ready for a separately
  approved prototype installation.

## Phase 3: Egg Parity and Acceptance

- [x] Add exclusion-aware alternate egg classification.
- [x] Add incubator-first routing and chest spillover.
- [x] Add representative manual acceptance and performance ledgers.
- [ ] Validate single-player, then co-op client, then dedicated-server client.

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
- [x] Prepare README, changelog, icon, Workshop metadata, and compatibility text.
- [x] Document both manual Saved-directory rebinding and the conditional
  `F6 -> Controls -> Pal Insight: Quick Stack` path.
- [ ] Obtain explicit approval before building, packaging, creating GitHub, or
  publishing Workshop content.

## Phase 6: Dedicated Facility Routing

- [x] Define two-value Pal Egg and Ancient Civilization Relic routing contracts.
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

## Risks and Mitigations

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
