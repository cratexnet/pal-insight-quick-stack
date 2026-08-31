# Pal Insight: Quick Stack

Independent UE4SS Lua mod for Palworld 1.0.

## Working contract

- Respond in Simplified Chinese by default; use English identifiers in code.
- Read the relevant section of `SPEC.md` and `tasks/plan.md` before changing
  behavior. Update the spec first when an accepted decision changes.
- Treat diagnosis and audit as read-only. Implement only after explicit user
  approval.
- Use `apply_patch` for file edits. Preserve unrelated and uncommitted work.
- Create or change tests only when the user explicitly requests tests or
  test-first development. Use the narrowest existing static check otherwise.
- Do not commit, push, build, install, package, publish, or modify the installed
  reference mod without separate explicit approval. Commit messages are Chinese.

## UE runtime evidence

Before changing input, lifecycle, item movement, or recurring performance, read:

- `D:\Workspace\pal-insight\docs\agent-guides\ue-runtime-diagnosis.md`
- `D:\Workspace\pal-insight\docs\UE-DIAGNOSTIC-PLAYBOOK.md`

Follow the evidence order: bound the behavior, trace the local route, establish
the current engine/runtime contract, build a falsifiable model, then implement
the smallest owning route. Mark SDK facts, runtime facts, and inference
separately. Request approval before adding an in-game diagnostic probe.

## Runtime invariants

- Resolve the same local player, common inventory, exclusion list, and current
  base as one fail-closed context.
- Enumerate only current-base object IDs. The warm shortcut route contains no
  `FindAllOf` fallback.
- Build bounded, generation-scoped work. Cancel stale jobs on world, base,
  controller, or player change.
- Submit at most one destination move RPC per frame and revalidate the
  destination before submission.
- Keep Quick Stack fully functional without Pal Insight. Pal Insight integration
  owns only in-game shortcut editing.
- Keep reflected Palworld access in `Scripts/palworld.lua`, job orchestration in
  `Scripts/quick_stack.lua`, and startup/input dispatch in `Scripts/main.lua`.
- Package configuration is a seed. Writable settings belong under
  `%LOCALAPPDATA%\Pal\Saved` so Workshop updates cannot overwrite them.
- Optional diagnostics default to `false` and are excluded from release; normal
  error and load-failure logging remains enabled.

## Completion reporting

Report changed files, checks actually run, unverified runtime behavior, and the
next approval boundary. Never claim multiplayer or performance results without
representative in-game evidence.
