# Story 005: Turn Resolution And Presentation Events

> **Epic**: Battle Engine
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/battle-engine.md`
**Requirement**: `TR-battle-001`, `TR-battle-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Semantic Event Contracts; ADR-0007: Battle Runtime State Machine
**ADR Decision Summary**: Battle emits typed turn and presentation payloads for UI/audio/VFX, and emits final `battle_completed(payload, delta)` once on KO without committing durable rewards.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Gameplay progression must not block on audible playback or missing presentation listeners.

**Control Manifest Rules (this layer)**:
- Required: CM-GLOB-04, CM-BATTLE-03, CM-EVT-04
- Forbidden: Requiring audio playback or presentation listener completion for turn progression
- Guardrail: Presentation payloads are runtime telemetry, not durable authority.

---

## Acceptance Criteria

*From GDD `design/gdd/battle-engine.md`, scoped to this story:*

- [x] Simultaneous KO in IMPACT results in player victory; simultaneous KO via RECOIL DoT is not possible because DoT resolves in declaration order.
- [x] Consumable timing applies in IMPACT before opponent simultaneous damage.
- [x] A 50-turn loop including at least one Freeze turn and one Paralysis skip completes without state errors or illegal transitions.
- [x] Presentation profile signals `miss`, `resisted_hit`, `normal_hit`, `effective_hit`, `critical_hit`, `status_apply`, and `ko` each fire exactly once when triggered.
- [x] `battle_completed(payload, delta)` fires with correct payload/delta on KO and no further turn phases execute afterward.

## Implementation Notes

Build on the runtime session and formula/status stories. Presentation events should use typed payloads and tolerate no listeners. This story can use test doubles for UI/audio/VFX.

## Out of Scope

- Sprite animation playback and manifest evidence: Story 007.
- Campaign Map or Singularity settlement commits.
- Full battle screen visuals.

## QA Test Cases

- **AC-1**: KO and consumable ordering
  - Given: fixtures for simultaneous damage, DoT, and consumable healing
  - When: IMPACT/RECOIL/RESOLUTION run
  - Then: KO and net HP match the GDD ordering
  - Edge cases: both combatants at lethal thresholds
- **AC-2**: long loop stability
  - Given: deterministic actions across 50 turns with Freeze and Paralysis
  - When: the session runs
  - Then: no illegal state transitions occur
  - Edge cases: status skip followed by normal turn
- **AC-3**: presentation event emission
  - Given: fixtures for each presentation profile
  - When: triggering turns resolve
  - Then: each typed event fires exactly once
  - Edge cases: no listener attached
- **AC-4**: final battle completion
  - Given: a KO fixture
  - When: RESOLUTION completes
  - Then: `battle_completed(payload, delta)` fires once and no more phases execute
  - Edge cases: repeated calls after COMPLETE are rejected/no-op

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/battle_engine/test_turn_resolution_and_presentation_events.gd`

**Status**: [x] Created - focused BATTLE-005 integration suite passed with 5/5 tests and 357 assertions; adjacent Battle Engine slice passed with 42/42 tests and 1,590 assertions; full unit/integration suite passed with 157/157 tests and 7,682 assertions.

## Dependencies

- Depends on: Battle Stories 001-004
- Unlocks: Battle screen presentation and settlement owner stories

## Completion Notes

**Completed**: 2026-05-28
**Criteria**: 5/5 passing.
**Deviations**: None.
**Test Evidence**: Integration coverage in `tests/integration/battle_engine/test_turn_resolution_and_presentation_events.gd`; focused BATTLE-005 suite passed with 5/5 tests and 357 assertions; combined BATTLE-005/BATTLE-006 focused suite passed with 11/11 tests and 387 assertions; adjacent Battle Engine slice passed with 42/42 tests and 1,590 assertions; full unit/integration suite passed with 157/157 tests and 7,682 assertions.
**Code Review**: Complete - `/code-review` approved after required presentation-event, consumable-ordering, completion-payload, and `battle_completed(payload, delta)` contract fixes.
