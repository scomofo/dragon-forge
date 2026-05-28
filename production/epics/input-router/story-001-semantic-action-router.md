# Story 001: Semantic Action Router

> **Epic**: Input Router
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/input-router.md`
**Requirement**: `TR-input-001`
**ADR Governing Implementation**: ADR-0003: Input Router Semantic Actions
**ADR Decision Summary**: InputRouter owns hardware-to-action translation; feature systems consume semantic actions only.
**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Verify Godot 4.6 InputMap and Control focus behavior against local engine reference.

**Control Manifest Rules**:
- Required: CM-IN-01, CM-IN-03
- Forbidden: Feature systems branching on raw gamepad button constants
- Guardrail: Semantic actions are stable `StringName` IDs.

## Acceptance Criteria

- [x] MVP InputMap actions are defined as distinct `StringName` action IDs.
- [x] InputRouter emits semantic actions for confirm, cancel, d-pad, battle, and map contexts.
- [x] Feature consumers can subscribe to semantic actions without raw hardware input details.

## Implementation Notes

Canonical actions include `ui_up`, `ui_down`, `ui_left`, `ui_right`, `ui_confirm`, `ui_cancel`, `battle_attack`, `battle_defend`, `battle_status`, `battle_consumable`, and `map_pan`.

## Out of Scope

- Screen-specific navigation grids.
- Singularity Counter interpretation.

## QA Test Cases

- **AC-1**: semantic dispatch
  - Given: InputRouter receives a Godot input event mapped to `ui_confirm`
  - When: the active context allows confirm
  - Then: InputRouter emits semantic `ui_confirm`
  - Edge cases: unmapped input, inactive context
- **AC-2**: raw input isolation
  - Given: a feature test consumer
  - When: it receives input through InputRouter
  - Then: it only sees semantic IDs, not raw device constants
  - Edge cases: keyboard and controller produce same semantic action

## Test Evidence

**Required evidence**:
- `tests/unit/input/test_semantic_action_router.gd`

**Status**: [x] Created - 6 semantic action router unit tests passing; full unit/integration suite passing with 35 tests / 410 assertions

## Dependencies

- Depends on: None
- Unlocks: Story 002, Story 004

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 3/3 passing
**Deviations**: None
**Test Evidence**: Unit test at `tests/unit/input/test_semantic_action_router.gd`; focused suite passes with 6/6 tests and 72 assertions; full unit/integration suite passes with 35/35 tests and 410 assertions.
**Code Review**: Complete; required review follow-up resolved by adding default keyboard/gamepad bindings for MVP UI actions and typing `semantic_action(payload)` as `SemanticActionPayload`.
