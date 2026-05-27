# Story 001: Stats, Stage, And Record Contract

> **Epic**: Dragon Progression
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/dragon-progression.md`
**Requirement**: `TR-dragon-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Dragon Data Model And Progression Services
**ADR Decision Summary**: Dragon Progression owns typed dragon schema, stat calculation, derived stage, shiny handling, and named snapshot/result contracts. `stage` is derived from level and is not persisted.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Dragon records are mutable Resources in save data; runtime readers must use copied records or derived snapshots, not live mutable SaveData nested Resources.

**Control Manifest Rules (this layer)**:
- Required: CM-DATA-05, CM-DRAGON-01, CM-DRAGON-03
- Forbidden: Persisted `stage`, element-only identity, or anonymous Dictionary progression contracts
- Guardrail: `dragon_id: StringName` is canonical identity; `element` is carried for gameplay, Journal, and UI.

---

## Acceptance Criteria

*From GDD `design/gdd/dragon-progression.md`, scoped to this story:*

- [x] AC-DP01 through AC-DP06: non-shiny Fire, Ice, Storm, Stone, Venom, and Shadow level-1 stats return their canonical HP/ATK/DEF/SPD values.
- [x] AC-DP06a: Void level-1 stats return HP=80, ATK=40, DEF=20, SPD=36, and Void cannot be shiny.
- [x] AC-DP07 through AC-DP16: representative level-30, MAX_LEVEL, and shiny stat calculations match the GDD formulas exactly.
- [x] AC-DP17 through AC-DP19: shiny stats are strictly greater for core elements, stat values are monotonic, and `floor()` is applied once after the full expression.
- [x] AC-DP32 through AC-DP37: stage and standard stage multiplier boundaries match levels 1, 9, 10, 24, 25, 49, 50, and 60.
- [x] AC-DP53: SPD is computed internally as a valid positive integer for all six core elements at levels 1, 30, and 60.
- [x] AC-DP67 through AC-DP71: defensive formula calls handle invalid levels, unknown elements, and invalid shiny multipliers without crashing.

## Implementation Notes

Add or extend typed progression data classes as needed: `DragonStats`, named result shells, and a `DragonProgressionService` stat/stage API. Reuse the existing `DragonRecord` schema; do not persist stage. Keep UI visibility rules out of this story.

## Out of Scope

- XP application and Resonance: Story 002.
- Save transaction event ordering: Story 003.
- Save/load repair: Story 005.
- UI display and stage art evidence: Story 006.

## QA Test Cases

- **AC-1**: canonical base stats
  - Given: one non-shiny `DragonRecord` per core element at level 1
  - When: `calculate_stats()` is called
  - Then: HP/ATK/DEF/SPD match AC-DP01 through AC-DP06 exactly
  - Edge cases: Void level-1 stats; Void shiny forced/rejected
- **AC-2**: level and shiny formula
  - Given: representative Shadow, Fire, and Stone records at levels 1, 30, and 60
  - When: stats are calculated
  - Then: outputs match AC-DP07 through AC-DP16, with one floor after multiplication
  - Edge cases: shiny Stone ATK at level 1, shiny Shadow ATK/DEF at level 60
- **AC-3**: stage boundaries
  - Given: dragons at levels 1, 9, 10, 24, 25, 49, 50, and 60
  - When: stage and stage multiplier are derived
  - Then: stages and standard multipliers match AC-DP32 through AC-DP37
  - Edge cases: no persisted stage field is read or written
- **AC-4**: defensive formula calls
  - Given: invalid levels, unknown element `Wind`, and invalid shiny multiplier
  - When: the stat API is called
  - Then: results and logs match AC-DP67 through AC-DP71 without crashing
  - Edge cases: level <= 0, level 61, Void remains valid

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/dragon/test_stats_stage_and_record_contract.gd`

**Status**: [x] Created - focused Dragon Progression unit suite passed with 7/7 tests and 4,627 assertions; full unit/integration suite passed with 77/77 tests and 5,396 assertions.

## Dependencies

- Depends on: Sprint 01 SaveData Resource complete
- Unlocks: Story 002, Battle formula stories, Hatchery/Fusion creation stories

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 7/7 passing
**Deviations**: None
**Test Evidence**: Logic story evidence at `tests/unit/dragon/test_stats_stage_and_record_contract.gd`; focused Dragon Progression suite passes with 7/7 tests and 4,627 assertions; full unit/integration suite passes with 77/77 tests and 5,396 assertions.
**Code Review**: Complete - APPROVED; no required changes.

### Acceptance Criteria Verification

| Criterion | Evidence | Status |
|-----------|----------|--------|
| AC-DP01 through AC-DP06: core level-1 stats match canonical HP/ATK/DEF/SPD values. | `test_canonical_level_one_stats_for_core_elements_and_void` | Covered |
| AC-DP06a: Void level-1 stats match authored row and Void cannot be shiny. | `test_canonical_level_one_stats_for_core_elements_and_void`, `test_defensive_formula_calls_return_safe_stats_without_crashing` | Covered |
| AC-DP07 through AC-DP16: representative level-30, MAX_LEVEL, and shiny calculations match formulas. | `test_representative_level_and_shiny_formula_outputs_match_gdd` | Covered |
| AC-DP17 through AC-DP19: shiny stats greater, monotonic stats, and single final floor. | `test_shiny_stats_are_greater_floor_once_and_stats_are_monotonic` | Covered |
| AC-DP32 through AC-DP37: stage and multiplier boundaries match required levels. | `test_stage_boundaries_and_standard_stage_multipliers_are_derived_from_level` | Covered |
| AC-DP53: SPD is computed internally as positive int for all core elements at levels 1, 30, and 60. | `test_spd_is_computed_internally_for_core_elements` | Covered |
| AC-DP67 through AC-DP71: invalid levels, unknown elements, and invalid shiny multipliers return safe results without crashing. | `test_defensive_formula_calls_return_safe_stats_without_crashing` | Covered |

### Verification Commands

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit/dragon -gselect=test_stats_stage_and_record_contract.gd -gexit
godot --headless --import --path . && godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit
```
