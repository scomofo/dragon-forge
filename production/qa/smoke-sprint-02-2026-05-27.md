## Smoke Check Report: Sprint 02
**Date**: 2026-05-27
**Sprint**: Sprint 02
**Stage**: Pre-Production
**Engine**: Godot 4.6.3
**QA Plan**: `production/qa/qa-plan-sprint-02-2026-05-27.md`
**Argument**: sprint

---

### Environment

| Check | Result |
|-------|--------|
| Test directory | PASS - `tests/` exists |
| CI workflow | PASS - `.github/workflows/tests.yml` exists |
| Smoke checklist | PASS - `tests/smoke/critical-paths.md` exists |
| Review mode | full |
| Current stage | Pre-Production |

Project import command:

```bash
godot --headless --editor --quit --path .
```

Result: PASS - root project imports and registers scripts under Godot 4.6.3.

Notes:
- Godot reports the nested vertical-slice `project.godot` folder at `res://prototypes/dragon-forge-vertical-slice` is ignored during the root import. This matches the existing repository layout.
- Godot reports an ObjectDB leak warning at editor quit. No parser errors, import blockers, or test-run blockers were observed.

---

### Automated Tests

**Status**: PASS - 119 tests, 119 passing, 6,854 assertions.

Command:

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit,res://tests/integration -ginclude_subdirs -gexit
```

Result summary:

| Metric | Count |
|--------|-------|
| Scripts | 24 |
| Tests | 119 |
| Passing Tests | 119 |
| Assertions | 6,854 |

Expected defensive `push_error` output appears in tests that explicitly assert guard behavior. GUT reports those errors as expected and the suite passes.

---

### Completed Sprint 02 Coverage

| Story | Priority | Type | Test File / Evidence | Coverage Status |
|-------|----------|------|----------------------|----------------|
| DRAGON-001 - Stats, Stage, And Record Contract | Must Have | Logic | `tests/unit/dragon/test_stats_stage_and_record_contract.gd` | COVERED |
| DRAGON-002 - XP Loop And Resonance | Must Have | Logic | `tests/unit/dragon/test_xp_loop_and_resonance.gd` | COVERED |
| DRAGON-003 - Post-Commit Progression Events | Must Have | Integration | `tests/integration/dragon/test_post_commit_progression_events.gd` | COVERED |
| ECO-001 - Scrap Read, Affordability, And Results | Must Have | Logic | `tests/unit/economy/test_scrap_read_affordability_and_results.gd` | COVERED |
| ECO-002 - Scrap Spend Transaction Boundary | Must Have | Integration | `tests/integration/economy/test_scrap_spend_transaction_boundary.gd` | COVERED |
| BATTLE-001 - Runtime Session And Payload Contracts | Must Have | Integration | `tests/integration/battle_engine/test_runtime_session_and_payload_contracts.gd` | COVERED |
| DRAGON-004 - Dragon Creation And Source Helpers | Should Have | Integration | `tests/integration/dragon/test_dragon_creation_and_source_helpers.gd` | COVERED |
| ECO-003 - Scrap Reward Addition Boundary | Should Have | Integration | `tests/integration/economy/test_scrap_reward_addition_boundary.gd` | COVERED |
| BATTLE-002 - Damage, Type, Crit, And Stage Formulas | Should Have | Logic | `tests/unit/battle_engine/test_damage_type_crit_and_stage_formulas.gd` | COVERED |

**Completed-scope summary**: 9 completed Must/Should stories, 9 covered, 0 missing.

---

### Deferred Nice-to-Have Stories

| Story | Sprint Status | Close-Out Status |
|-------|---------------|------------------|
| DRAGON-005 - Save Load Integrity And Repair | backlog | DEFERRED - not part of completed Sprint 02 close-out evidence |
| BATTLE-003 - Status And Recoil Effects | backlog | DEFERRED - not part of completed Sprint 02 close-out evidence |
| BATTLE-007 - Animation Manifest Runtime Lookup | backlog | DEFERRED - not part of completed Sprint 02 close-out evidence |

These stories remain in the sprint file as Nice-to-have backlog items. Their missing test files are not blockers for closing the completed Sprint 02 Must/Should scope.

---

### Manual Smoke Checks

| Check | Result | Evidence |
|-------|--------|----------|
| Godot project imports headlessly without blocking errors | PASS | Fresh headless editor import completed |
| Full unit/integration GUT suite runs | PASS | 119/119 tests, 6,854 assertions |
| Dragon stat and XP fixtures execute without stale save mutations | PASS | Dragon unit/integration tests pass |
| EconomyLedger spend/add fixtures survive SaveService rollback checks | PASS | Economy unit/integration tests pass |
| Battle runtime fixture starts and ends a session without touching SaveData | PASS | Battle runtime integration tests pass |
| Sprint 01 Foundation regression tests still pass | PASS | Save, input, content, scene flow, bootstrap, and event suites included in full run |
| Root/Admin animation manifest content test still passes | PASS | `tests/integration/battle/test_root_admin_animation_content.gd` included in full run |
| Production shell/main-menu smoke | DEFERRED | No production main scene is configured in `project.godot`; Sprint 02 delivered service contracts, not a player-facing shell |
| Manual frame-rate/performance smoke | DEFERRED | No player-facing runtime scene is in scope for this sprint |

---

### Missing Test Evidence

None for the completed Sprint 02 Must/Should close-out scope.

Deferred Nice-to-have backlog stories still need implementation and test evidence before they can be closed:
- DRAGON-005 - `tests/integration/dragon/test_save_load_integrity_and_repair.gd`
- BATTLE-003 - `tests/unit/battle_engine/test_status_and_recoil_effects.gd`
- BATTLE-007 - `tests/integration/battle_engine/test_animation_manifest_runtime_lookup.gd`

---

### Verdict: PASS WITH WARNINGS

Sprint 02 is ready for QA sign-off for the completed Must/Should scope.

Warnings:
- Production shell/main-menu smoke is deferred because no production main scene is configured yet.
- Manual frame-rate/performance smoke is deferred because Sprint 02 changed core service contracts rather than a playable runtime scene.
- Nice-to-have stories DRAGON-005, BATTLE-003, and BATTLE-007 remain backlog and are excluded from this close-out verdict.
