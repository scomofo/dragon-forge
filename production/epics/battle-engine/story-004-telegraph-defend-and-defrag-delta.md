# Story 004: Telegraph, Defend, And Defrag Delta

> **Epic**: Battle Engine
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/battle-engine.md`, `design/gdd/shop.md`
**Requirement**: `TR-battle-001`, `TR-battle-003`, `TR-shop-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Battle Runtime State Machine; ADR-0009: Economy And Shop Transaction Boundaries
**ADR Decision Summary**: Battle accepts semantic actions in TELEGRAPH only, handles runtime Defrag Patch use, and returns consumed item flags in `BattleDurableDelta` for the owner to commit.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Use callable signal connections from Input Router; Battle legality stays in Battle runtime, not InputRouter.

**Control Manifest Rules (this layer)**:
- Required: CM-BATTLE-02, CM-BATTLE-03, CM-ECO-02
- Forbidden: Raw input constants in Battle logic or Battle directly mutating expedition flags
- Guardrail: Counter remains contextual `battle_defend`; no separate MVP Counter action.

---

## Acceptance Criteria

*From GDD `design/gdd/battle-engine.md` and `design/gdd/shop.md`, scoped to this story:*

- [x] Defend reduces incoming damage by 50% as covered by formula story and cannot be selected on the next turn after defending.
- [x] NPC-submitted Defend actions use the same runtime cooldown legality as player Defend actions; weighted NPC action-selection heuristics remain out of scope.
- [x] Defrag Patch with `expedition_defrag_patch = true` clears active player status before IMPACT and returns `expedition_defrag_patch` in `BattleDurableDelta.consumed_item_flags`.
- [x] Defrag Patch with no active status still consumes the item, returns the consumed flag, and changes no status state.
- [x] Emergency Patch is not available as an in-battle TELEGRAPH action.

## Implementation Notes

Wire TELEGRAPH semantic actions to the runtime action contract. The Battle runtime may mark an action as consumed/effective, but Campaign Map or Singularity commits the durable flag clear.

Performance: TELEGRAPH legality, Defend cooldown, and Defrag Patch consumption must stay as phase-bound O(1) runtime checks. Do not add per-frame polling, save I/O, or direct durable flag mutation in Battle runtime.

## Out of Scope

- ExpeditionInventoryLedger implementation.
- Shop purchase flow.
- Weighted NPC action-selection heuristics.
- Counter tritone damage/effects.

## QA Test Cases

- **AC-1**: Defend cooldown
  - Given: player and NPC combatants who defend on turn N
  - When: turn N+1 TELEGRAPH starts
  - Then: Defend is unavailable for each defender and available again after another action
  - Edge cases: cooldown survives status skip rules where applicable
- **AC-2**: Defrag clears status
  - Given: player has Burn and `expedition_defrag_patch = true`
  - When: Use Defrag Patch is selected in TELEGRAPH
  - Then: Burn clears before IMPACT and durable delta reports `expedition_defrag_patch`
  - Edge cases: no direct SaveData flag mutation
- **AC-3**: Defrag no-status case
  - Given: no active status and `expedition_defrag_patch = true`
  - When: Use Defrag Patch is selected
  - Then: no status changes, but durable delta still reports consumption
  - Edge cases: item absent rejects action
- **AC-4**: Emergency Patch absent in battle
  - Given: `expedition_emergency_patch = true`
  - When: TELEGRAPH action list is built
  - Then: no Emergency Patch action is available
  - Edge cases: Field Kit and Cache Shard MAP_EXPLORE actions remain out of Battle

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/battle_engine/test_telegraph_defend_and_defrag_delta.gd`

**Status**: [x] Created - focused BATTLE-004 integration suite passed with 7/7 tests and 86 assertions; adjacent Battle runtime/status/formula suites passed with 24/24 tests and 1,071 assertions; full unit/integration suite passed with 146/146 tests and 7,243 assertions.

## Dependencies

- Depends on: Battle Story 001, Battle Story 002, Battle Story 003, Input Router contextual counter story complete
- Unlocks: Shop/Campaign Defrag settlement stories

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 5/5 passing.
**Deviations**: None.
**Test Evidence**: Integration coverage in `tests/integration/battle_engine/test_telegraph_defend_and_defrag_delta.gd`; focused BATTLE-004 suite passed with 7/7 tests and 86 assertions; adjacent Battle runtime/status/formula suite passed with 24/24 tests and 1,071 assertions; full unit/integration suite passed with 146/146 tests and 7,243 assertions.
**Code Review**: Complete - `/code-review` approved after required changes; QA coverage gate returned ADEQUATE; lead-programmer gate returned APPROVED after doc-comment follow-up.
