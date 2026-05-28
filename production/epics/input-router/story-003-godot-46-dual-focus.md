# Story 003: Godot 4.6 Dual Focus

> **Epic**: Input Router
> **Status**: Complete
> **Layer**: Foundation
> **Type**: UI
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/input-router.md`
**Requirement**: `TR-input-003`
**ADR Governing Implementation**: ADR-0003: Input Router Semantic Actions; ADR-0005: Godot Scene Flow And Autoload Boundaries
**ADR Decision Summary**: Godot 4.6 keyboard/gamepad focus must remain explicit and separate from mouse/touch hover; scene transitions restore focus through InputRouter.
**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Must test `Control.grab_focus()` focus restoration and hover separation.

**Control Manifest Rules**:
- Required: CM-IN-04, CM-IN-06
- Forbidden: Treating mouse hover as controller focus
- Guardrail: Focus restoration happens after every top-level screen transition.

## Acceptance Criteria

- [x] Mouse hover does not steal keyboard/gamepad focus in controller tests.
- [x] Disabled actions visibly reject confirm and emit no gameplay action.
- [x] InputRouter can restore focus to a requested Control after top-level scene transition.

## Implementation Notes

Add focused test harnesses for hover/focus separation; avoid relying on final feature screens.

## Out of Scope

- Final theme styling for focus rings.
- Full accessibility remapping.

## QA Test Cases

- **Manual check**: hover/focus separation
  - Setup: focus a button with keyboard/gamepad, then hover another with mouse
  - Verify: hover state changes visually but keyboard/gamepad confirm still targets focused control
  - Pass condition: no focus theft
- **Manual check**: disabled action rejection
  - Setup: focus a disabled action
  - Verify: confirm produces rejection feedback and no semantic gameplay action
  - Pass condition: action is not emitted

## Test Evidence

**Required evidence**:
- `production/qa/evidence/input-dual-focus-evidence.md`

**Status**: [x] Created - automated dual-focus evidence approved; full unit/integration suite passing with 38 tests / 435 assertions

## Dependencies

- Depends on: Story 001
- Unlocks: Scene Flow focus restoration stories

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 3/3 passing
**Deviations**: None
**Test Evidence**: UI evidence at `production/qa/evidence/input-dual-focus-evidence.md`; automated harness at `tests/unit/input/test_dual_focus_input_router.gd` passes with 3/3 tests and 25 assertions; full unit/integration suite passes with 38/38 tests and 435 assertions.
**Code Review**: Complete; no required changes. InputRouter now tracks hover without taking keyboard/gamepad focus, emits `semantic_action_rejected(payload)` for presentation feedback while suppressing gameplay actions, and exposes focus restoration result signals for scene transitions.
