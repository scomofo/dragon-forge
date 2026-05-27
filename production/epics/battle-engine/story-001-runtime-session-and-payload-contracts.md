# Story 001: Runtime Session And Payload Contracts

> **Epic**: Battle Engine
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.5 days
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/battle-engine.md`
**Requirement**: `TR-battle-001`, `TR-battle-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*
**Scope Note**: This story fully covers the runtime session/payload foundation for `TR-battle-001` and partial coverage of `TR-battle-003`: `BattleEndedPayload`/`BattleDurableDelta` settlement contracts only. `turn_resolved` and presentation payload emission are deferred to later Battle presentation/turn-resolution stories.

**ADR Governing Implementation**: ADR-0007: Battle Runtime State Machine
**ADR Decision Summary**: Battle Engine is scene-local/runtime-only; a Battle screen/host owns a controller Node, which owns one RefCounted BattleSession and emits typed payloads without committing durable rewards.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Runtime state must live in RefCounted/controller objects, not shared `.tres` Resources.
**Performance**: No per-frame simulation in this story; fixture sessions advance deterministically without timers, rendering, audio, or Save I/O.

**Control Manifest Rules (this layer)**:
- Required: CM-BATTLE-01, CM-BATTLE-02, CM-BATTLE-03, CM-DATA-06
- Forbidden: Battle Engine as an Autoload, persisted BattleSession, or mutable runtime state in authored Resources
- Guardrail: Battle completion remains a pre-commit settlement request.

---

## Acceptance Criteria

*From GDD `design/gdd/battle-engine.md`, scoped to this story:*

- [x] BattleSession advances only `INIT -> TELEGRAPH -> IMPACT -> RECOIL -> RESOLUTION`, then either loops to `TELEGRAPH` on no KO or enters `COMPLETE` on battle end; illegal phase transitions return a named failure result and do not mutate state.
- [x] Gameplay actions are accepted only during TELEGRAPH and rejected in other phases.
- [x] Battle runtime emits `battle_completed(payload: BattleEndedPayload, delta: BattleDurableDelta)` exactly once on battle completion.
- [x] `BattleEndedPayload` contains at minimum the six mandatory GDD fields: `victory`, `raw_xp_awarded`, `scraps_earned`, `player_hp_remaining`, `player_level_start`, and `enemy_level`; any additional fields must be stable typed IDs allowed by ADR-0007 and must not be anonymous Dictionary data.
- [x] Battle completion returns a typed `BattleDurableDelta` settlement request alongside `BattleEndedPayload`; it contains only ADR-0007 allowed settlement fields.
- [x] Battle runtime opens no SaveTransaction, holds no SaveData reference, and mutates no durable SaveData fields; integration tests must prove this with a fake/spying SaveService or immutable SaveData fixture and assert that only payload/delta output is produced.

## Implementation Notes

Add minimal runtime types: `BattleRuntimeState`, `BattleSession`, `BattleEndedPayload`, `TurnResolvedPayload`, `BattleDurableDelta`, and action submit results. The first story can use test fixtures instead of a production Battle screen, but the ownership shape must match ADR-0007.

## Out of Scope

- Damage/status formulas: Stories 002 and 003.
- Defrag Patch and consumable timing: Story 004.
- Presentation animation playback: Story 007.

## QA Test Cases

- **AC-1**: state ownership
  - Given: a battle controller test harness starts a battle
  - When: the session is inspected
  - Then: runtime state is held by one RefCounted `BattleSession`, not by authored Resources
  - Edge cases: starting a second battle invalidates or rejects overlapping sessions
- **AC-2**: legal phase transition graph
  - Given: a deterministic fixture with no KO and a deterministic fixture with KO
  - When: the session is advanced
  - Then: the observed transition order is `INIT -> TELEGRAPH -> IMPACT -> RECOIL -> RESOLUTION`, then either loops to `TELEGRAPH` or enters `COMPLETE`
  - Edge cases: illegal manual transition attempts return named failures and leave state unchanged
- **AC-3**: TELEGRAPH-only action acceptance
  - Given: a session in INIT, IMPACT, RECOIL, RESOLUTION, and TELEGRAPH
  - When: `submit_action()` is called
  - Then: only TELEGRAPH accepts gameplay actions
  - Edge cases: disabled/unknown action IDs return named rejection results
- **AC-4**: battle completed payload and delta contract
  - Given: a KO fixture
  - When: battle completion is reached
  - Then: `battle_completed(payload, delta)` fires once; `payload` contains the mandatory GDD fields and any ADR-0007 ID fields as typed properties; `delta` is a typed settlement request
  - Edge cases: no anonymous Dictionary payloads and no durable writes occur
- **AC-5**: save mutation boundary
  - Given: a fake/spying SaveService or immutable SaveData fixture
  - When: battle completion is reached
  - Then: no SaveTransaction opens, no SaveData field mutates, and the only settlement output is typed payload/delta data

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/battle_engine/test_runtime_session_and_payload_contracts.gd`

**Status**: [x] Created and passing

**Evidence**:
- Focused: `tests/integration/battle_engine/test_runtime_session_and_payload_contracts.gd` passed with 7/7 tests and 771 assertions.
- Full: unit + integration suite passed with 106/106 tests and 6,618 assertions.

## Dependencies

- Depends on: Input Router semantic action routing complete (`production/epics/input-router/story-001-semantic-action-router.md`), Input Router d-pad confirm/cancel flows complete (`production/epics/input-router/story-002-dpad-confirm-cancel-flows.md`), Input Router dual focus complete (`production/epics/input-router/story-003-godot-46-dual-focus.md`), Input Router contextual counter routing complete (`production/epics/input-router/story-004-contextual-counter-routing.md`), and Semantic Event Contract Harness complete (`production/epics/semantic-events/story-001-semantic-event-contract-harness.md`)
- Unlocks: Stories 002-005, Campaign Map settlement stories

## Dev Notes

**Implemented**: 2026-05-27
**Deviations**: None.
**Code Review**: Approved after required changes and setup snapshot follow-up.

**Implementation Summary**:
- Added minimal Battle runtime contracts under `src/battle/runtime/`.
- `BattleRuntimeController` is the scene-owned Node and owns one RefCounted `BattleSession`.
- `BattleSession` advances the explicit phase graph, rejects illegal transitions with named results, and accepts gameplay actions only during TELEGRAPH.
- `BattleSession.configure()` snapshots scalar setup values so later caller mutations cannot alter runtime completion output.
- Battle completion emits `battle_completed(payload: BattleEndedPayload, delta: BattleDurableDelta)` exactly once and produces typed pre-commit settlement data.
- Public settlement and presentation shell fields use typed `BattlePhaseCheckpointDelta` and `PresentationEventPayload` contracts.
- Runtime code has no `SaveService`, `SaveTransaction`, or `SaveData` dependency.

**Acceptance Criteria Verification**:

| AC | Coverage |
| --- | --- |
| Legal phase graph and illegal transition failures | `test_session_advances_legal_phase_graph_and_rejects_illegal_transitions` |
| TELEGRAPH-only gameplay action acceptance | `test_actions_are_accepted_only_during_telegraph` |
| `battle_completed(payload, delta)` exactly once | `test_battle_completed_emits_typed_payload_and_delta_once` |
| Setup values snapshot on configure | `test_session_snapshots_setup_values_on_configure` |
| Mandatory `BattleEndedPayload` fields | `test_battle_completed_emits_typed_payload_and_delta_once` |
| Typed `BattleDurableDelta` settlement request | `test_battle_completed_emits_typed_payload_and_delta_once` |
| Typed public checkpoint and presentation payload shells | `test_public_payload_shells_reject_loose_dictionary_contracts` |
| No SaveTransaction/SaveData mutation or dependency | `test_runtime_exposes_no_save_facing_api_or_mutation_boundary` |
| Controller owns one RefCounted session | `test_controller_owns_one_refcounted_session_and_rejects_overlap` |

**Verification Commands**:

```bash
godot --headless --import --path .
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/integration/battle_engine -ginclude_subdirs -gexit
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit
```

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 6/6 passing
**Deviations**: None.
**Test Evidence**: Integration evidence at `tests/integration/battle_engine/test_runtime_session_and_payload_contracts.gd`; focused suite passed with 7/7 tests and 771 assertions; full unit + integration suite passed with 106/106 tests and 6,618 assertions.
**Code Review**: Complete. Full-mode QA coverage gate returned ADEQUATE; lead-programmer gate returned APPROVED.
