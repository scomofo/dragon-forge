# Story 004: Contextual Counter Routing

> **Epic**: Input Router
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 0.5 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/input-router.md`
**Requirement**: `TR-input-001`, `TR-input-002`
**ADR Governing Implementation**: ADR-0003: Input Router Semantic Actions
**ADR Decision Summary**: Singularity Counter is a contextual interpretation of `battle_defend`; no separate MVP Counter action exists.
**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Counter UI can relabel Defend, but routed action remains `battle_defend`.

**Control Manifest Rules**:
- Required: CM-IN-05
- Forbidden: Separate MVP Counter input action
- Guardrail: Battle legality remains owned by Battle/Singularity, not InputRouter.

## Acceptance Criteria

- [x] During `tritone_window`, selecting focused Defend/Counter emits `battle_defend`.
- [x] When the tritone window closes before confirm, the same focused option routes normal `battle_defend` if Defend is legal.
- [x] If Defend is disabled/cooling down, confirm emits a blocked/rejected state and no gameplay `semantic_action`.
- [x] No separate MVP `battle_counter` action exists; Counter remains presentation context for canonical `battle_defend`.

## Implementation Notes

This is an input routing contract/harness story. Mirror Admin battle behavior belongs to Singularity/Battle stories.

`tritone_window` state remains owned by Singularity/Battle presentation; InputRouter only tracks the focused semantic action and emits canonical `battle_defend`.

## Out of Scope

- Mirror Admin phase implementation.
- Counter damage/effect calculation.

## QA Test Cases

- **AC-1**: tritone counter route
  - Given: battle action context is open and `tritone_window = true`
  - When: focused Counter/Defend is confirmed
  - Then: InputRouter emits `battle_defend`
- **AC-2**: window closes before confirm
  - Given: focused Defend/Counter remains selected and `tritone_window` closes
  - When: confirm is pressed and Defend is legal
  - Then: InputRouter emits normal `battle_defend`
- **AC-3**: disabled Defend blocks gameplay action
  - Given: focused Defend is disabled by cooldown
  - When: confirm is pressed
  - Then: InputRouter emits `semantic_action_rejected` and does not emit `semantic_action`
- **AC-4**: no separate Counter action
  - Given: MVP action IDs and InputMap are initialized
  - When: the router is inspected
  - Then: `battle_counter` is absent and no payload exposes raw hardware details

## Test Evidence

**Required evidence**:
- `tests/integration/input/test_contextual_counter_routing.gd`

**Status**: [x] Passing — focused contextual counter integration suite and full unit/integration suite pass.

## Dependencies

- Depends on: Story 001
- Unlocks: Singularity Counter UI and battle stories

## Completion Notes

- Added focused semantic action routing for `ui_confirm` in Battle TELEGRAPH context.
- Verified Counter presentation remains canonical `battle_defend`; no `battle_counter` InputMap or MVP action ID is created.
- Verified disabled Defend emits `semantic_action_rejected` and suppresses gameplay `semantic_action`.
- Kept `tritone_window` timing out of InputRouter; Singularity/Battle owns that state and only presents/focuses Defend as Counter.
- Test evidence: `tests/integration/input/test_contextual_counter_routing.gd`.
