# Story 002: D-Pad Confirm Cancel Flows

> **Epic**: Input Router
> **Status**: Complete
> **Layer**: Foundation
> **Type**: UI
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/input-router.md`
**Requirement**: `TR-input-002`
**ADR Governing Implementation**: ADR-0003: Input Router Semantic Actions
**ADR Decision Summary**: Required player-facing flows must be completable with d-pad plus confirm/cancel, not hover-only interaction.
**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: UI evidence must verify controller and keyboard paths separately from mouse hover.

**Control Manifest Rules**:
- Required: CM-IN-02, CM-IN-06
- Forbidden: Hover-only interaction
- Guardrail: D-pad row navigation stops at edges unless a GDD explicitly allows wrapping.

## Acceptance Criteria

- [x] Hub, Shop, Campaign Map, Battle TELEGRAPH, Crown, and terminals have d-pad plus confirm/cancel paths in the navigation contract.
- [x] Row navigation stops at row ends for Shop and multi-relic Crown selection.
- [x] Keyboard fallback can complete every required flow.

## Implementation Notes

This story may implement shared focus-map helpers and evidence scenes; it does not need to implement final feature screens.

## Out of Scope

- Final Hub, Shop, Campaign Map, or Crown UI composition.

## QA Test Cases

- **Manual check**: d-pad flow evidence
  - Setup: open each available test harness/screen stub
  - Verify: d-pad moves focus, confirm activates, cancel backs out
  - Pass condition: no required path needs mouse hover
- **Manual check**: row edges
  - Setup: focus first and last row items in Shop/Crown harnesses
  - Verify: d-pad does not wrap unless explicitly configured
  - Pass condition: edge behavior matches GDD

## Test Evidence

**Required evidence**:
- `production/qa/evidence/input-dpad-confirm-cancel-evidence.md`

**Status**: [x] Created - navigation-contract evidence approved; full unit/integration suite passing with 61 tests / 694 assertions

## Dependencies

- Depends on: Story 001
- Unlocks: Feature UI stories

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 3/3 passing
**Deviations**: None
**Test Evidence**: Evidence doc at `production/qa/evidence/input-dpad-confirm-cancel-evidence.md`; automated harness at `tests/unit/input/test_dpad_confirm_cancel_contract.gd` passes with 4/4 tests and 58 assertions; full unit/integration suite passes with 61/61 tests and 694 assertions.
**Code Review**: Complete; no required changes. FocusNavigationContract defines required d-pad/confirm/cancel paths for Hub, Shop, Campaign Map, Battle TELEGRAPH, Crown, and terminals, marks hover as non-required, clamps Shop/Crown rows at edges, and documents the Hub wrap exception from the Hub GDD.
