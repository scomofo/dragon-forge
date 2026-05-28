# Story 006: NPC Action Selection Heuristics

> **Epic**: Battle Engine
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 0.75 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/battle-engine.md`
**Requirement**: `TR-battle-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Battle Runtime State Machine
**ADR Decision Summary**: Battle runtime owns NPC action selection as deterministic testable logic using authored move/status options and runtime cooldown/status state.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: NPC choice tests need injectable RNG to avoid flaky statistical assertions.

**Control Manifest Rules (this layer)**:
- Required: CM-BATTLE-01, CM-DATA-06
- Forbidden: NPC AI mutating authored move Resources or bypassing Defend cooldown
- Guardrail: Move power is a design signal for AI only unless the Battle GDD changes damage formulas.

---

## Acceptance Criteria

*From GDD `design/gdd/battle-engine.md`, scoped to this story:*

- [x] NPC prefers super-effective available attack moves at 70% when available.
- [x] If no super-effective move is available and player has no active status, NPC prefers status at 40%.
- [x] Otherwise NPC prefers highest-power fallback at 60%, falling back to random themed moves.
- [x] Priority resolves super-effective over power over status.
- [x] NPC respects Defend cooldown and cannot defend two consecutive turns.
- [x] Advisory manual check: when a super-effective move is available, NPC selects it in the majority of observed turns during playtest.

## Implementation Notes

Implement NPC action selection as a pure/testable helper or BattleSession method with seeded RNG. Keep authored move definitions immutable. Do not wire move power into damage unless the GDD changes.

## Out of Scope

- Full enemy/boss behavior trees.
- Mirror Admin phase AI.
- Player-facing telegraph visuals.

## QA Test Cases

- **AC-1**: weighted priority order
  - Given: seeded move pools with super-effective, status, and high-power options
  - When: NPC selection runs over deterministic trials
  - Then: priority and weights match the GDD within chosen tolerances
  - Edge cases: no super-effective move, player already has status
- **AC-2**: Defend cooldown
  - Given: NPC defended on turn N
  - When: turn N+1 selection runs
  - Then: Defend is excluded
  - Edge cases: Defend available again after another action
- **Manual check AC-3**: majority super-effective behavior
  - Setup: run a playtest encounter where the NPC has a super-effective move
  - Verify: NPC chooses it in the majority of observed turns
  - Pass condition: manual evidence records observed turns and selection count

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/battle_engine/test_npc_action_selection_heuristics.gd`
- Optional manual evidence: `production/qa/evidence/npc-action-selection-evidence.md`

**Status**: [x] Created - focused BATTLE-006 unit suite passed with 6/6 tests and 30 assertions; adjacent Battle Engine slice passed with 42/42 tests and 1,590 assertions; full unit/integration suite passed with 157/157 tests and 7,682 assertions.

## Dependencies

- Depends on: Battle Story 002, Battle Story 004
- Unlocks: Authored encounter difficulty tuning

## Completion Notes

**Completed**: 2026-05-28
**Criteria**: 6/6 covered. The majority-selection behavior is covered by deterministic seeded unit tests; optional manual playtest evidence remains a Sprint 04 QA-delta advisory.
**Deviations**: None.
**Test Evidence**: Logic coverage in `tests/unit/battle_engine/test_npc_action_selection_heuristics.gd`; focused BATTLE-006 suite passed with 6/6 tests and 30 assertions; combined BATTLE-005/BATTLE-006 focused suite passed with 11/11 tests and 387 assertions; adjacent Battle Engine slice passed with 42/42 tests and 1,590 assertions; full unit/integration suite passed with 157/157 tests and 7,682 assertions.
**Code Review**: Complete - `/code-review` approved after required runtime typing and enemy-consumable rejection fixes.
