# Handoff - 2026-05-28 - HATCHERY-005

## Current State

The active lane is Sprint 04 Hatchery implementation.

Current story:

- `production/epics/hatchery/story-005-dragon-unlock-duplicate-xp-and-shiny-upgrade.md`
- Status: `In Progress`
- Implementation: complete locally
- Review: not yet run after implementation
- Story closure: not yet run

The immediate next action for the next chat is:

```text
/code-review src/hatchery/hatchery_service.gd src/hatchery/hatchery_pull_result.gd src/dragon/dragon_progression_service.gd src/dragon/xp_apply_result.gd tests/integration/hatchery/test_dragon_unlock_duplicate_xp_and_shiny_upgrade.gd tests/integration/hatchery/test_pull_transaction_boundary_and_scrap_spend.gd production/epics/hatchery/story-005-dragon-unlock-duplicate-xp-and-shiny-upgrade.md
```

If review requests changes, make them, rerun the same `/code-review`, then run:

```text
/story-done production/epics/hatchery/story-005-dragon-unlock-duplicate-xp-and-shiny-upgrade.md
```

## What Was Done In This Chat

### 1. HATCHERY-005 Readiness Gate

Initial `/story-readiness` found HATCHERY-005 nearly ready but with two cleanup gaps:

- Dependency wording was ambiguous: `Story 004, Dragon Progression Story 004`.
- Required Control Manifest list omitted `CM-DRAGON-01`; `CM-DRAGON-03` was also relevant for named result contracts.

Repairs made in `production/epics/hatchery/story-005-dragon-unlock-duplicate-xp-and-shiny-upgrade.md`:

- Added required manifest rules:
  - `CM-HATCH-03`
  - `CM-DRAGON-01`
  - `CM-DRAGON-03`
  - `CM-DRAGON-06`
  - `CM-GLOB-07`
- Replaced ambiguous dependencies with stable IDs and paths:
  - `HATCHERY-004` -> `production/epics/hatchery/story-004-pull-transaction-boundary-and-scrap-spend.md`
  - `DRAGON-004` -> `production/epics/dragon-progression/story-004-dragon-creation-and-source-helpers.md`
- Replaced vague unlocks with:
  - `HATCHERY-006` -> `production/epics/hatchery/story-006-post-commit-events-and-preview-contract.md`
  - `HATCHERY-007` -> `production/epics/hatchery/story-007-hatchery-ring-ui-and-reveal-evidence-contract.md`

Reran `/story-readiness`:

- Local verdict: `READY`
- Full-mode QA lead gate: `PASS / ADEQUATE`
- Advisory from QA: implementation tests should separately prove shiny upgrade behavior and combined XP-plus-shiny behavior.

### 2. HATCHERY-005 Dev Story

Ran `/dev-story production/epics/hatchery/story-005-dragon-unlock-duplicate-xp-and-shiny-upgrade.md`.

Per the dev-story flow:

- Story status was changed from `Ready` to `In Progress`.
- `Last Updated` was set to `2026-05-28`.
- `production/sprint-status.yaml` was checked, but it has no HATCHERY-005 row, so there was no matching sprint-status entry to update.

TDD notes:

- Added the HATCHERY-005 integration test first.
- First focused run failed because the test exposed that `HatcheryService.configure()` did not yet accept/use `DragonProgressionService`.
- After implementation, focused and full suites passed.

### 3. Production Implementation

Main implementation files:

- `src/hatchery/hatchery_service.gd`
- `src/hatchery/hatchery_pull_result.gd`
- `src/dragon/dragon_progression_service.gd`
- `src/dragon/xp_apply_result.gd`

Key behavior added:

- `HatcheryService.configure()` now receives `DragonProgressionService`.
- `HatcheryService.execute_pull()` still owns the one SaveTransaction pull boundary, but now stages the dragon outcome before commit:
  - Scrap spend through `EconomyLedger`
  - rarity/element/shiny resolution through `HatcheryPullResolver`
  - pity and drought counter updates
  - new dragon creation or duplicate XP/shiny update through `DragonProgressionService`
  - SaveService commit
- New dragon outcomes call `DragonProgressionService.create_from_hatchery()`.
- Duplicate outcomes compute XP as `50 * rarity_xp_multiplier` from the runtime table snapshot:
  - Common: 50
  - Uncommon: 100
  - Rare/Shadow: 150
- Duplicate outcomes call `DragonProgressionService.apply_hatchery_duplicate_outcome()`.
- Shiny duplicate on an owned non-shiny dragon upgrades `dragon.shiny` in the same staged transaction as XP.
- Non-shiny duplicate on an owned shiny dragon does not downgrade.
- MAX_LEVEL duplicate XP still goes through Dragon Progression and leaves level 60 / XP 0.
- Save commit failure clears public outcome fields on `HatcheryPullResult` and leaves canonical save unchanged.

Dragon Progression additions:

- Added `apply_hatchery_duplicate_outcome(tx, element, xp_amount, shiny, source_id)`.
- Kept existing `apply_hatchery_duplicate_xp()` as a wrapper for compatibility.
- Added `XPApplyResult` fields:
  - `shiny_requested`
  - `shiny_upgraded`
  - `shiny`
- Refactored shared XP validation/application into helper methods so normal XP and Hatchery duplicate XP use the same level loop and pending-event logic.
- Preserved old missing-target behavior: `xp_requested` is still recorded and the required discard log still fires.

Hatchery result additions:

- `dragon_id`
- `shiny_upgraded`
- `creation_result`
- `xp_result`

### 4. Test Work

New required test file:

- `tests/integration/hatchery/test_dragon_unlock_duplicate_xp_and_shiny_upgrade.gd`

The file has 7 test functions covering:

- AC-H15, AC-H16, AC-H17: unowned pulls create core dragons with shiny true/false from the roll.
- AC-H18, AC-H19, AC-H20: duplicate XP amounts for Common, Uncommon, and Rare Shadow.
- AC-H22: Dragon Progression XP loop, level 5 XP 30 plus Common duplicate -> level 6 XP 30.
- AC-H23: MAX_LEVEL duplicate remains level 60 XP 0.
- AC-H24, AC-H25: shiny upgrade and no downgrade.
- AC-H26: shiny duplicate on MAX_LEVEL upgrades shiny and retains level 60 XP 0.
- AC-H28: all six standard dragons owned makes every standard pull a duplicate XP outcome.
- AC-H29: shiny duplicate below MAX_LEVEL applies XP and shiny upgrade in one committed pull.
- Rollback: save failure rolls back Scrap spend, XP, and shiny upgrade together.

Updated adjacent HATCHERY-004 regression test:

- `tests/integration/hatchery/test_pull_transaction_boundary_and_scrap_spend.gd`
- The successful transaction test now expects the completed outcome application to persist one created dragon.
- The test helper now configures `HatcheryService` with `DragonProgressionService`.

### 5. Verification Completed

Commands run and passing:

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gtest=res://tests/integration/hatchery/test_dragon_unlock_duplicate_xp_and_shiny_upgrade.gd -gexit
```

Result:

- 7/7 tests
- 113 assertions

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gtest=res://tests/integration/hatchery/test_pull_transaction_boundary_and_scrap_spend.gd -gexit
```

Result:

- 8/8 tests
- 155 assertions

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit/hatchery -gdir=res://tests/integration/hatchery -ginclude_subdirs -gexit
```

Result:

- 41/41 tests
- 10,754 assertions

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gtest=res://tests/integration/dragon/test_dragon_creation_and_source_helpers.gd -gtest=res://tests/unit/dragon/test_xp_loop_and_resonance.gd -gexit
```

Result:

- 11/11 tests
- 387 assertions

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit
```

Result:

- 198/198 tests
- 18,436 assertions

Expected defensive `push_error` / `push_warning` output appears in Dragon save/progression tests and is reported by GUT as `ExpectedError`. This is normal and the suite passes.

## Files Touched For HATCHERY-005

Primary story implementation files:

- `src/hatchery/hatchery_service.gd`
- `src/hatchery/hatchery_pull_result.gd`
- `src/dragon/dragon_progression_service.gd`
- `src/dragon/xp_apply_result.gd`
- `tests/integration/hatchery/test_dragon_unlock_duplicate_xp_and_shiny_upgrade.gd`
- `tests/integration/hatchery/test_pull_transaction_boundary_and_scrap_spend.gd`
- `production/epics/hatchery/story-005-dragon-unlock-duplicate-xp-and-shiny-upgrade.md`

Session handoff files updated by wrap-up:

- `production/session-state/handoff-2026-05-28-hatchery-005.md`
- `production/session-state/active.md`

Important workspace note:

- The worktree is very dirty and includes many pre-existing modified/untracked files from earlier project setup and sprint work.
- Do not revert broad changes.
- Only treat the files listed above as the HATCHERY-005 implementation surface unless the next task explicitly expands scope.

## Review Watch-Outs

The code review should pay special attention to:

- `HatcheryService.configure()` signature change. Current tests were updated; check for any production/bootstrap callsites before future UI wiring.
- Whether `HatcheryPullResult` should expose both `creation_result` and `xp_result` now or wait for HATCHERY-006 result/presentation contract refinements.
- Whether clearing outcome fields on save failure is the desired public contract, matching HATCHERY-004 failure behavior.
- Whether `_find_staged_dragon_by_element()` in `HatcheryService` is acceptable as a bounded six-element lookup, or whether all duplicate detection should move into Dragon Progression. It currently only decides route; mutation remains in Dragon Progression.
- Whether `apply_hatchery_duplicate_outcome()` should emit a distinct post-commit shiny-upgrade event later in HATCHERY-006. It currently mutates shiny and returns named result facts; post-commit hatch/progression event publication is explicitly out of scope for HATCHERY-005.

## Remaining Work

Immediate:

1. Run the HATCHERY-005 `/code-review` command shown at the top.
2. Make any required review changes.
3. Rerun `/code-review` with the same file list.
4. Run `/story-done production/epics/hatchery/story-005-dragon-unlock-duplicate-xp-and-shiny-upgrade.md`.

Likely next story after HATCHERY-005 closes:

```text
/story-readiness production/epics/hatchery/story-006-post-commit-events-and-preview-contract.md
```

Then, if ready:

```text
/dev-story production/epics/hatchery/story-006-post-commit-events-and-preview-contract.md
```

Sprint 04 close-out still needs, based on the current sprint notes:

- SCENE-003 manual launch evidence or explicit carry-forward.
- BATTLE-007 source/content review evidence or explicit carry-forward.
- `/smoke-check sprint`.
- `/team-qa sprint` or Sprint 04 QA sign-off after pulled scope is settled.

## Do Not Forget

- HATCHERY-005 is not closed yet.
- No commit was made.
- No files were staged.
- No background agents remain open from this handoff work.
- Continue from `/code-review`, not from `/dev-story`.
