# Pal Insight: Quick Stack task list

## Task 1: Prove current-build runtime contracts

**Acceptance criteria:**

- [x] Exact local player, common inventory, exclusion list, base collection,
  storage model, transmitter, and item move RPC routes are recorded.
- [x] Every unverified boundary is explicit and has no fallback implementation.

**Verification:**

- [x] Compare local SDK headers, cooked asset evidence, and the installed
  reference mod.
- [x] Obtain separate approval and capture the three-argument RPC ABI with a
  one-shot read-only probe.

**Dependencies:** Human approval of `SPEC.md` and `tasks/plan.md`.

**Files likely touched:** `docs/runtime-contract.md`

**Estimated scope:** Small

## Task 2: Add standalone input and job ownership

**Acceptance criteria:**

- [x] The packaged config seed defaults to F5 and creates a writable
  `%LOCALAPPDATA%\Pal\Saved\PalInsightQuickStackSettings.lua` that Workshop
  updates cannot overwrite.
- [x] Manual shortcut configuration supports `Key`, `Shift`, `Ctrl`, and `Alt`.
- [x] One press creates at most one generation-scoped job.
- [x] Blocking UI, invalid local context, and an active job fail closed.

**Verification:**

- [x] Lua syntax parse.
- [x] Static review of keybind dispatch and generation guards.

**Dependencies:** Task 1.

**Files likely touched:** `Scripts/config.lua`, `Scripts/main.lua`

**Estimated scope:** Small

## Task 3: Build the current-base destination snapshot

**Acceptance criteria:**

- [x] Only current-base map-object instance IDs are enumerated.
- [x] Supported writable storage and incubators are classified in bounded
  slices.
- [x] Permissions, filters, capacity, and container IDs are captured.

**Verification:**

- [x] Lua syntax parse.
- [x] Static audit finds no `FindAllOf` in the job route.

**Dependencies:** Tasks 1-2.

**Files likely touched:** `Scripts/main.lua`, `docs/runtime-contract.md`

**Estimated scope:** Medium

## Task 4: Plan ordinary-item moves with indexes

**Acceptance criteria:**

- [x] Exclusions and common-inventory scope are strict.
- [x] Exact-item containers are preferred before filter-compatible containers.
- [x] Routing uses item/category indexes instead of an unfiltered
  inventory-slot-by-container pass.

**Verification:**

- [x] Lua syntax parse.
- [x] Source audit of item/category caches and lookup complexity.

**Dependencies:** Task 3.

**Files likely touched:** `Scripts/main.lua`

**Estimated scope:** Medium

## Task 5: Submit paced server moves

**Acceptance criteria:**

- [x] A single serialized submission chain sends only one destination RPC per
  callback and waits 34 ms before the next target.
- [x] Destination and job generation are revalidated before every submission.
- [x] Repeated F5 presses cannot duplicate or overlap work.

**Verification:**

- [x] Lua syntax parse.
- [x] Static audit of the submission queue and stale-job cancellation.
- [ ] User-approved in-game comparison for ordinary items.

**Dependencies:** Task 4.

**Files likely touched:** `Scripts/main.lua`, `docs/acceptance.md`

**Estimated scope:** Medium

## Task 6: Add egg and incubator parity

**Acceptance criteria:**

- [x] Excluded eggs are removed from the source plan before egg routing.
- [x] Eligible eggs prefer available incubators when configured.
- [x] Remaining eggs follow agreed chest routing without global scans.

**Verification:**

- [x] Lua syntax parse.
- [ ] User-approved in-game comparison for egg scenarios.

**Dependencies:** Task 5.

**Files likely touched:** `Scripts/main.lua`, `docs/acceptance.md`

**Estimated scope:** Medium

## Task 7: Measure the standalone candidate

**Acceptance criteria:**

- [ ] Baseline and candidate use the same inventory/base scenario.
- [ ] Per-slice timings, total job time, and request pacing are recorded.
- [ ] Any result inside noise is not claimed as an improvement.

**Verification:**

- [ ] User-approved opt-in development capture.
- [ ] Single-player, co-op, and dedicated-server-client matrix.

**Dependencies:** Task 6 and separate diagnostic/install approval.

**Files likely touched:** `docs/performance.md`, `docs/acceptance.md`

**Estimated scope:** Small

## Task 8: Add the optional Pal Insight settings bridge

**Acceptance criteria:**

- [ ] Quick Stack publishes its versioned scalar settings contract.
- [ ] Valid setting revisions apply and persist; invalid revisions fail closed.
- [ ] Old UE4SS keybind callbacks become inert after rebind.
- [ ] Shortcut modifiers round-trip between F6, shared variables, and the
  writable Quick Stack config.
- [ ] Pal Insight conditionally appends an independent
  `Pal Insight: Quick Stack` class to the bottom of the existing final
  `Controls` tab, containing only the Quick Stack shortcut setting.

**Verification:**

- [ ] Both mod load orders and Quick Stack standalone behavior.
- [ ] Pal Insight absent and incompatible-version behavior.

**Dependencies:** Accepted standalone candidate and explicit approval to modify
Pal Insight.

**Files likely touched:** `Scripts/main.lua`, `Scripts/config.lua`, Pal Insight
runtime/settings files in its separate repository change.

**Estimated scope:** Medium per repository

## Task 9: Prepare distribution

**Acceptance criteria:**

- [x] All Quick Stack-authored runtime text covers the same 17 locales as
  Palworld and fails safely to English.
- [x] Native item names and icons continue to use Palworld localization.
- [x] Pal Insight's optional Quick Stack shortcut row covers all 17 locales.
- [ ] English, Simplified Chinese, and one long-text locale are observed in game.
- [x] Independent release diagnostics gate exists and passes.
- [x] All developer diagnostics are false or excluded.
- [x] Workshop copy states dependencies and multiplayer evidence accurately.
- [x] Workshop copy explains both manual Saved-directory rebinding and the
  `F6 -> Controls -> Pal Insight: Quick Stack` path.

**Verification:**

- [ ] Release inventory audit.
- [ ] Explicit user approval before build, GitHub creation, or Workshop publish.

**Dependencies:** Tasks 7-8 as selected for the release scope.

**Files likely touched:** release tooling and public documentation

**Estimated scope:** Medium
