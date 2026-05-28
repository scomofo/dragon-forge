# Story 002: XP Loop And Resonance

> **Epic**: Dragon Progression
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1.5 days
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/dragon-progression.md`
**Requirement**: `TR-dragon-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Dragon Data Model And Progression Services
**ADR Decision Summary**: Dragon Progression owns XP threshold lookup, XP application, Resonance charge consumption, MAX_LEVEL cleanup, and named `XPApplyResult` output.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Mutating XP on staged records must not leak into read snapshots before commit; nested Resource copies require verification.

**Control Manifest Rules (this layer)**:
- Required: CM-DRAGON-01, CM-DRAGON-03, CM-DRAGON-05
- Forbidden: Battle, Campaign Map, Hatchery, Fusion, or UI code directly incrementing `dragon.xp`, `dragon.level`, or `dragon.battle_charges`
- Guardrail: XP loop outputs named results and pending progression events; publication is handled by Story 003.

---

## Acceptance Criteria

*From GDD `design/gdd/dragon-progression.md`, scoped to this story:*

- [x] AC-DP20 through AC-DP31: XP awards advance levels, preserve remainders, update stats, stop at MAX_LEVEL, and record `stats_updated` once per multi-level call.
- [x] AC-DP98 and AC-DP99: stable XP remains in the valid per-stage range and is always 0 at level 60.
- [x] AC-DP72 through AC-DP74: negative XP is rejected, float XP truncates to int, and zero XP is a valid no-op.
- [x] AC-DP90: XP awards above `XP_MAX_AWARD` clamp to 10,000.
- [x] AC-DP91 and AC-DP92: Resonance reduces effective threshold only when charges are present and consumes exactly one charge per level gained.

## Implementation Notes

Implement `xp_threshold_for(level)` and staged `apply_xp(tx, dragon_id, amount)` using the GDD Formula 4 loop. Return a named result that includes levels gained, XP remainder, charges consumed, and pending events. Keep signal emission out of the loop.

## Out of Scope

- Post-commit event publication: Story 003.
- Cross-system XP sources from Hatchery/Battle/Campaign: Story 007.
- Save/load repair of invalid XP: Story 005.

## QA Test Cases

- **AC-1**: XP threshold boundaries
  - Given: staged dragons at levels 1, 9, 10, 59, and 60
  - When: XP amounts from AC-DP20 through AC-DP29 are applied
  - Then: final level and XP match each AC exactly
  - Edge cases: MAX_LEVEL clears XP, 10,000 XP cannot pass level 60
- **AC-2**: stable XP invariants
  - Given: valid post-application dragons across all stages
  - When: XP state is inspected after `apply_xp()`
  - Then: XP is below the current threshold and 0 at MAX_LEVEL
  - Edge cases: exact threshold, one below threshold, Stage IV cap
- **AC-3**: invalid and defensive XP values
  - Given: staged dragons with valid starting state
  - When: XP is negative, zero, float, or above `XP_MAX_AWARD`
  - Then: behavior matches AC-DP72 through AC-DP74 and AC-DP90
  - Edge cases: no mutation on rejected negative XP
- **AC-4**: Resonance threshold discount
  - Given: Stage I dragons with `battle_charges = 3` and `battle_charges = 0`
  - When: XP awards from AC-DP91 and AC-DP92 are applied
  - Then: charge consumption and final XP/level match the GDD examples exactly
  - Edge cases: no charge consumed when no level is gained

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/dragon/test_xp_loop_and_resonance.gd`

**Status**: [x] Created - focused XP/resonance unit suite passed with 7/7 tests and 305 assertions; full unit/integration suite passed with 84/84 tests and 5,701 assertions.

## Dependencies

- Depends on: Story 001
- Unlocks: Story 003, Story 005, Hatchery duplicate XP, Campaign reward settlement

## Dev Notes

**Implemented**: 2026-05-27
**Deviations**: None
**Test Evidence**: Logic story evidence at `tests/unit/dragon/test_xp_loop_and_resonance.gd`; focused XP/resonance suite passes with 7/7 tests and 305 assertions; full unit/integration suite passes with 84/84 tests and 5,701 assertions.
**Code Review**: Complete - APPROVED; no required changes.

### Acceptance Criteria Verification

| Criterion | Evidence | Status |
|-----------|----------|--------|
| AC-DP20 through AC-DP31: XP awards advance levels, preserve remainders, update stats, stop at MAX_LEVEL, and record one `stats_updated` per multi-level call. | `test_xp_awards_advance_levels_preserve_remainders_and_stop_at_max_level`, `test_level_up_result_updates_stats_and_records_stats_updated_once` | Covered |
| AC-DP98 and AC-DP99: stable XP remains below the current threshold and is always 0 at level 60. | `test_stable_xp_invariants_hold_after_application` | Covered |
| AC-DP72 through AC-DP74: negative XP rejects without mutation, float XP truncates, and zero XP is a valid no-op. | `test_negative_float_zero_and_clamped_xp_inputs_follow_gdd_rules` | Covered |
| AC-DP90: XP awards above `XP_MAX_AWARD` clamp to 10,000. | `test_negative_float_zero_and_clamped_xp_inputs_follow_gdd_rules` | Covered |
| AC-DP91 and AC-DP92: Resonance reduces thresholds only with charges and consumes one charge per level gained. | `test_resonance_reduces_effective_threshold_and_consumes_one_charge_per_level` | Covered |

### Verification Commands

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit/dragon -gselect=test_xp_loop_and_resonance.gd -gexit
godot --headless --import --path . && godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit
```

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 5/5 passing
**Deviations**: None
**Test Evidence**: Logic story evidence at `tests/unit/dragon/test_xp_loop_and_resonance.gd`; focused XP/resonance suite passes with 7/7 tests and 305 assertions; full unit/integration suite passes with 84/84 tests and 5,701 assertions.
**Code Review**: Complete - APPROVED. Local lead-programmer/Godot/GDScript/QA review found no blockers; the `apply_xp()` implementation was split into smaller helpers before closure to satisfy the method-size guideline. Sidecar Task review was not available in this thread, so the review was completed locally.
