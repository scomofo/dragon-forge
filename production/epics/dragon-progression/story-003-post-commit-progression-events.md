# Story 003: Post-Commit Progression Events

> **Epic**: Dragon Progression
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/dragon-progression.md`
**Requirement**: `TR-dragon-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Save Transaction Boundary; ADR-0002: Semantic Event Contracts; ADR-0006: Dragon Data Model And Progression Services
**ADR Decision Summary**: Progression events are accumulated during staged mutation but emitted only after Save / Persistence commit success. Event payloads carry both `dragon_id` and `element`.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Verify progression events do not publish when `SaveService.commit_transaction()` fails, especially with failure injection.

**Control Manifest Rules (this layer)**:
- Required: CM-GLOB-02, CM-DRAGON-02, CM-DRAGON-04
- Forbidden: Emitting `stats_updated`, `stage_advanced`, or `stage_iv_reached` from inside the XP loop before commit
- Guardrail: Missing listeners are no-ops and must not block gameplay.

---

## Acceptance Criteria

*From GDD `design/gdd/dragon-progression.md`, scoped to this story:*

- [x] AC-DP39 through AC-DP45: stage IV and stage advancement events fire exactly once, in order, with correct element parameters, and missing listeners do not error.
- [x] AC-DP40: `stage_iv_reached` is recorded at the exact level-50 crossing and publishes only after SaveTransaction commit success; injected save failure publishes no signal.
- [x] AC-DP31: multi-level XP gain records `stats_updated` exactly once after the entire XP loop completes.

## Implementation Notes

Connect Dragon Progression event publication to Save / Persistence commit success. Prefer pending event payloads on named XP results or transaction metadata rather than immediate signal emission. Do not open nested transactions from event listeners.

## Out of Scope

- Journal content unlock handling: Journal epic.
- Visual level-up playback: Presentation/UI story.
- Singularity Void grant trigger: Singularity epic.

## QA Test Cases

- **AC-1**: ordered stage events
  - Given: staged XP awards crossing 9->10, 24->25, and 49->50
  - When: the transaction commits successfully
  - Then: `stage_advanced` and `stage_iv_reached` emit exactly as AC-DP43a through AC-DP43d specify
  - Edge cases: crossing two stage boundaries in one award
- **AC-2**: commit-before-emit
  - Given: an XP award that crosses level 50
  - When: save commit succeeds, then when save failure is injected
  - Then: successful commit publishes events; failed commit publishes none
  - Edge cases: award continues beyond level 50 before loop completion
- **AC-3**: listener absence
  - Given: no listeners are connected
  - When: a stage IV crossing commits
  - Then: gameplay continues and no error is raised
  - Edge cases: invalid listener connection is absent, not mocked as a failure

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/dragon/test_post_commit_progression_events.gd`

**Status**: [x] Created - focused post-commit progression event integration suite passed with 4/4 tests and 36 assertions; full unit/integration suite passed with 88/88 tests and 5,737 assertions.

## Dependencies

- Depends on: Story 002, `production/epics/save-persistence/story-003-commit-signals-and-failure-hooks.md`
- Unlocks: Journal Stage IV lore integration, UI progression presentation

## Dev Notes

**Implemented**: 2026-05-27
**Deviations**: None
**Test Evidence**: Integration story evidence at `tests/integration/dragon/test_post_commit_progression_events.gd`; focused suite passes with 4/4 tests and 36 assertions; full unit/integration suite passes with 88/88 tests and 5,737 assertions.
**Code Review**: Complete - approved on 2026-05-27 with no blocking findings.

### Acceptance Criteria Verification

| Criterion | Evidence | Status |
|-----------|----------|--------|
| AC-DP39 through AC-DP45: stage IV and stage advancement events fire exactly once, in order, with correct element parameters, and missing listeners do not error. | `test_successful_commit_publishes_ordered_stage_events_with_dragon_payloads`, `test_stage_iv_reached_emits_once_when_award_continues_to_max_level`, `test_missing_progression_event_listeners_do_not_block_commit` | Covered |
| AC-DP40: `stage_iv_reached` is recorded at the exact level-50 crossing and publishes only after commit success; injected save failure publishes no signal. | `test_stage_iv_crossing_publishes_after_commit_and_failed_commit_publishes_none` | Covered |
| AC-DP31: multi-level XP gain records `stats_updated` exactly once after the entire XP loop completes. | `test_successful_commit_publishes_ordered_stage_events_with_dragon_payloads`, existing unit coverage in `tests/unit/dragon/test_xp_loop_and_resonance.gd` | Covered |

### Verification Commands

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/integration/dragon -gselect=test_post_commit_progression_events.gd -gexit
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit/dragon -gdir=res://tests/integration/dragon -gexit
godot --headless --import --path . && godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit
```

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 3/3 passing
**Deviations**: None
**Test Evidence**: Integration test at `tests/integration/dragon/test_post_commit_progression_events.gd`; focused suite passed with 4/4 tests and 36 assertions; full unit/integration suite passed with 88/88 tests and 5,737 assertions.
**Code Review**: Complete - approved with no required changes.
**Review Notes**: Full review mode is configured, but delegated sidecar review was not spawned in this closure pass because sub-agent spawning requires an explicit delegation request in the current tool policy. Local code review for DRAGON-003 was completed and approved before closure.
