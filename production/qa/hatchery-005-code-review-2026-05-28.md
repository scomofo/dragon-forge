# HATCHERY-005 Code Review — 2026-05-28

## Verdict

CHANGES REQUIRED.

The happy-path acceptance criteria and primary integration coverage are adequate, but two failure-path contract issues must be fixed before `/story-done`.

## Required Findings

### 1. Post-spend, pre-commit failures can return a misleading spent result

**Files/functions**:
- `src/hatchery/hatchery_service.gd` — `execute_pull()`
- `src/hatchery/hatchery_service.gd` — `_stage_dragon_outcome()`
- `src/hatchery/hatchery_service.gd` — `_duplicate_xp_for_rarity()`

After affordability and `spend_scraps()` succeed, the result stores the staged spent balance. If a later pre-commit failure occurs, such as `unknown_rarity`, the transaction is marked inactive and no save is committed, but the public `HatcheryPullResult` can still report the staged spent balance.

Required fix direction: reuse rollback/cleanup normalization for all post-spend failures, or delay publishing spent balances on the result until commit succeeds.

Recommended regression test: force the `unknown_rarity` path and assert the durable Scrap balance, pity counters, XP, shiny state, and result balance/outcome fields all reflect rollback.

### 2. Shiny mutation happens before XP validation in duplicate outcome helper

**File/function**:
- `src/dragon/dragon_progression_service.gd` — `apply_hatchery_duplicate_outcome()`

The helper can set `dragon.shiny = true` and `result.shiny_upgraded = true` before XP request validation. Current Hatchery callers pass positive table-derived XP, but the source-specific helper should preserve same-helper atomicity for invalid direct/future calls too.

Required fix direction: validate XP before mutating shiny, or snapshot/revert shiny on validation failure.

Recommended regression test: call `apply_hatchery_duplicate_outcome()` with invalid XP for a non-shiny owned dragon and assert the result fails while the staged dragon remains non-shiny.

## QA Coverage Notes

The HATCHERY-005 integration test suite is adequate for the listed happy-path acceptance criteria:
- AC-H15, AC-H16, AC-H17: unowned creation and shiny/non-shiny state.
- AC-H18, AC-H19, AC-H20: Common/Uncommon/Rare duplicate XP amounts.
- AC-H22: Dragon Progression XP loop.
- AC-H23: MAX_LEVEL XP cleanup.
- AC-H24, AC-H25, AC-H26, AC-H29: shiny upgrade/no downgrade and XP-plus-shiny behavior.
- AC-H28: all-owned standard duplicate routing.
- Save-failure rollback: canonical Scrap, XP, level, and shiny state remain rolled back.

Suggested non-blocking additions:
- Assert nested `creation_result` and `xp_result` named contract fields.
- Add explicit `unknown_rarity` rejection coverage.
- Add temp/backup artifact cleanup assertions if test utilities expose them.

## Local Environment Note

This closure pass ran in a local checkout that is not synced to the GitHub `main` Godot 4.6 production tree, so source fixes and Godot/GUT reruns must happen in a synced production workspace.
