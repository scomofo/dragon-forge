# Story 003: Status And Recoil Effects

> **Epic**: Battle Engine
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/battle-engine.md`
**Requirement**: `TR-battle-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Battle Runtime State Machine
**ADR Decision Summary**: BattleSession owns runtime HP/status state, status effects, RECOIL ticks, skip effects, and KO determination within battle only.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Runtime status state must not be stored in shared authored Resources.

**Control Manifest Rules (this layer)**:
- Required: CM-BATTLE-01, CM-DATA-06
- Forbidden: Mutable combat/session state in shared `.tres` Resources
- Guardrail: Durable HP/status deltas are returned for owner settlement; Battle does not commit them.

---

## Acceptance Criteria

*From GDD `design/gdd/battle-engine.md`, scoped to this story:*

- [x] Status applies at 30% +/- 5% over 1,000 fixed-seed trials.
- [x] Applying Status B to a dragon with Status A overwrites the old status and fresh duration.
- [x] Burn and Poison DoT use defender max HP, tick for 2 turns, and can KO at low HP.
- [x] Freeze skips next TELEGRAPH action; Paralysis skips at 50% +/- 5% over fixed-seed trials.
- [x] Guard Break uses `floor(DEF * 0.6)` and does not multiplicatively stack.
- [x] Status duration, single-slot behavior, DoT expiry, and DoT declaration order match the GDD.

## Implementation Notes

Keep status formulas deterministic with injectable RNG. Store status runtime state on combatant battle state. Do not implement status icon/UI rendering here.

Performance: no per-frame work is expected; status application and RECOIL resolution must remain deterministic O(1) per combatant per phase and covered by unit tests.

## Out of Scope

- Presentation profile signals: Story 005.
- Defrag Patch status clearing: Story 004.
- Status receive animation binding: Story 007.

## QA Test Cases

- **AC-1**: status apply/overwrite
  - Given: fixed-seed status fixtures and a combatant with an existing status
  - When: status application resolves
  - Then: statistical rate is within tolerance and only the new status remains
  - Edge cases: reapplying same status resets duration
- **AC-2**: Burn/Poison DoT
  - Given: combatants with max HP and current HP values
  - When: RECOIL ticks run
  - Then: DoT uses max HP, lasts two turns, expires on turn three, and can KO
  - Edge cases: current HP = 1
- **AC-3**: Freeze, Paralysis, Guard Break
  - Given: status fixtures for each effect
  - When: TELEGRAPH/RECOIL resolution runs
  - Then: skips, duration, and DEF reduction match the GDD
  - Edge cases: Guard Break reapply resets instead of stacking
- **AC-4**: declaration order
  - Given: both combatants have active DoT
  - When: RECOIL runs
  - Then: player DoT ticks first, NPC DoT still fires if player hits 0, and KO is determined at RESOLUTION
  - Edge cases: both combatants reach 0 during RECOIL

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/battle_engine/test_status_and_recoil_effects.gd`

**Status**: [x] Created - focused BATTLE-003 status/recoil unit suite passed with 5/5 tests and 38 assertions; Battle Engine unit/integration slice passed with 17/17 tests and 921 assertions; full unit/integration suite passed with 132/132 tests and 7,013 assertions.

## Dependencies

- Depends on: Battle Story 001, Battle Story 002
- Unlocks: Defrag Patch and long-loop resolution stories

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 6/6 passing.
**Deviations**: None.
**Test Evidence**: Logic unit evidence at `tests/unit/battle_engine/test_status_and_recoil_effects.gd`; focused suite passed with 5/5 tests and 38 assertions; Battle Engine unit/integration slice passed with 17/17 tests and 921 assertions; full unit/integration suite passed with 132/132 tests and 7,013 assertions.
**Code Review**: Complete — `/code-review` verdict APPROVED. Full-mode `qa-lead` and `lead-programmer` sidecar gate spawns were unavailable due thread limit; local QA coverage and ADR checks passed.
