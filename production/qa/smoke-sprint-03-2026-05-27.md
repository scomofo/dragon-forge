## Smoke Check Report: Sprint 03

**Date**: 2026-05-27
**Sprint**: Sprint 03
**Stage**: Pre-Production
**Engine**: Godot 4.6.3
**QA Plan**: `production/qa/qa-plan-sprint-03-2026-05-27.md`
**Argument**: sprint

---

### Environment

| Check | Result |
|-------|--------|
| Test directory | PASS - `tests/` exists |
| CI workflow | PASS - `.github/workflows/tests.yml` runs the GUT unit/integration suite |
| Smoke checklist | PASS - `tests/smoke/critical-paths.md` and Sprint 03 QA plan smoke scope exist |
| Current stage | Pre-Production |

Project import command:

```bash
godot --headless --editor --quit --path .
```

Result: PASS - root project imports and registers scripts under Godot 4.6.3.

Notes:
- Godot reports the nested vertical-slice `project.godot` folder at `res://prototypes/dragon-forge-vertical-slice` is ignored during root import. This matches the existing repository layout.
- Godot reports an ObjectDB leak warning at editor quit. No parser errors, import blockers, or test-run blockers were observed.

---

### Automated Tests

**Status**: PASS - 146 tests, 146 passing, 7,243 assertions.

Command:

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit
```

Result summary:

| Metric | Count |
|--------|-------|
| Scripts | 29 |
| Tests | 146 |
| Passing Tests | 146 |
| Assertions | 7,243 |

Expected defensive `push_error` / `push_warning` output appears in tests that explicitly assert guard behavior. GUT reports those errors as expected and the suite passes.

---

### Production Shell / Main-Menu Smoke

Command:

```bash
godot --headless --path . --quit
```

Result: PASS - root project launch exits 0 using the configured production main scene.

| Check | Result | Evidence |
|-------|--------|----------|
| Godot project imports headlessly without blocking errors | PASS | Fresh headless editor import completed |
| Production shell/main-menu launch | PASS | `project.godot` runs `scenes/bootstrap/BootstrapRoot.tscn`; headless launch exits 0 |
| Initial Hub shell reaches SceneFlow active screen | PASS | `test_project_defines_production_main_scene_that_boots_shell` |
| Keyboard/gamepad focus restoration through InputRouter | PASS | `test_initial_shell_focus_restoration_emits_through_input_router` |
| Manual frame-rate/performance smoke | DEFERRED | Minimal greybox shell has no meaningful playable runtime performance path yet; this is explicitly allowed by the Sprint 03 QA plan |

---

### Sprint 03 Coverage Snapshot

| Story | Priority | Sprint Status | Coverage Status |
|-------|----------|---------------|-----------------|
| SCENE-003 - Production Shell Main Scene Smoke Path | Must Have | Complete | COVERED - `tests/integration/scene_flow/test_production_shell_main_scene_smoke_path.gd` |
| DRAGON-005 - Save Load Integrity And Repair | Must Have | Complete | COVERED - `tests/integration/dragon/test_save_load_integrity_and_repair.gd` |
| BATTLE-003 - Status And Recoil Effects | Must Have | Complete | COVERED - `tests/unit/battle_engine/test_status_and_recoil_effects.gd` |
| BATTLE-004 - Telegraph, Defend, And Defrag Delta | Must Have | Complete | COVERED - `tests/integration/battle_engine/test_telegraph_defend_and_defrag_delta.gd` |
| BATTLE-007 - Animation Manifest Runtime Lookup | Should Have | Complete | COVERED - `tests/integration/battle_engine/test_animation_manifest_runtime_lookup.gd` |
| BATTLE-005 - Turn Resolution And Presentation Events | Nice-to-have | Backlog | NOT PULLED - no Sprint 03 close-out requirement |
| BATTLE-006 - NPC Action Selection Heuristics | Nice-to-have | Backlog | NOT PULLED - no Sprint 03 close-out requirement |

Coverage summary for delivered Sprint 03 scope: 5 covered, 0 missing.

---

### Focused Story Evidence

| Story | Evidence |
|-------|----------|
| SCENE-003 | Focused production shell suite passed with 4/4 tests and 37 assertions; included in full suite |
| DRAGON-005 | Focused save/load integrity suite passed with 4/4 tests and 62 assertions; included in full suite |
| BATTLE-003 | Focused status/recoil suite passed with 5/5 tests and 38 assertions; included in full suite |
| BATTLE-004 | Focused Telegraph/Defend/Defrag suite passed with 7/7 tests and 86 assertions; included in full suite |
| BATTLE-007 | Focused animation manifest runtime lookup suite passed with 7/7 tests and 80 assertions; included in full suite |

---

### Manual Smoke Checks

| Check | Result | Notes |
|-------|--------|-------|
| Game launches without crash | PASS | Headless production launch exits 0 |
| New session / shell start path | PASS | Bootstrap and Hub shell path covered by integration tests |
| Main input focus path responds | PASS | Focus restoration emits through InputRouter integration coverage |
| Dragon save/load integrity | PASS | Automated integration coverage in full suite |
| Battle status/recoil contracts | PASS | Automated unit coverage in full suite |
| Battle Defend/Defrag TELEGRAPH contracts | PASS | Automated integration coverage in full suite |
| Animation manifest runtime lookup | PASS | Automated integration/content coverage in full suite |
| Frame-rate/performance smoke | DEFERRED | Minimal greybox shell has no meaningful playable runtime performance path yet |

---

### Missing Test Evidence

All delivered Logic and Integration stories have automated test coverage.

Nice-to-have stories not pulled this sprint still need their planned tests before future closure:
- BATTLE-005 - `tests/integration/battle_engine/test_turn_resolution_and_presentation_events.gd`
- BATTLE-006 - `tests/unit/battle_engine/test_npc_action_selection_heuristics.gd`

---

### Verdict: PASS WITH WARNINGS

Sprint 03 is ready for QA hand-off.

Warnings:
- Manual frame-rate/performance smoke remains deferred because the current production shell is a minimal greybox path, not a meaningful player-facing runtime performance scenario.
- Godot reports an ObjectDB leak warning when the editor import process exits, but the import, production launch, and GUT suite all exit successfully.
