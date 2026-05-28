# Story 007: Animation Manifest Runtime Lookup

> **Epic**: Battle Engine
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 0.75 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/battle-engine.md`
**Requirement**: `TR-battle-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Battle Runtime State Machine
**ADR Decision Summary**: `BattleDefinition.animation_manifest_id` and `MoveDefinition` IDs resolve actor/action clips through `BattleAnimationManifest`; runtime code must not branch on move names for sprite/VFX paths.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Existing manifest Resource classes and validator coverage can be reused; runtime lookup should stay separate from asset playback.

**Control Manifest Rules (this layer)**:
- Required: CM-DATA-08, CM-BATTLE-07
- Forbidden: Move-specific sprite paths or VFX paths embedded in Battle runtime code
- Guardrail: Placeholder animation bindings are allowed only for explicit greybox scope, not production content lock.

---

## Acceptance Criteria

*From GDD `design/gdd/battle-engine.md` and `docs/architecture/battle-animation-manifest-schema.md`, scoped to this story:*

- [x] Battle runtime resolves required move, defend, hurt, defend-hit, KO, and status receive clips from `BattleAnimationManifest`.
- [x] Runtime lookup uses `BattleDefinition.animation_manifest_id`, actor animation set IDs, and `MoveDefinition` IDs.
- [x] Runtime code contains no hardcoded move-name branches for sprite or VFX path selection.
- [x] Missing required bindings produce actionable validation/runtime errors before production content lock.

## Implementation Notes

Use the existing `src/battle/animation/` Resource classes and validator. This story should wire runtime lookup keys and payloads; actual frame playback and final art assets belong to presentation/content stories.

Performance: runtime animation lookup must be phase/event-bound and use stable ID maps or equivalent O(1)/small bounded lookups; no per-frame asset scanning or playback work is in scope.

## Out of Scope

- Producing new art assets.
- Runtime animation player implementation.
- Full production content lock for every dragon/NPC.

## QA Test Cases

- **AC-1**: manifest lookup
  - Given: a valid battle definition, move definitions, and animation manifest
  - When: runtime asks for action clip data
  - Then: move/VFX/receive/base clips resolve through IDs
  - Edge cases: defend, hurt, defend-hit, KO, and status receive
- **AC-2**: missing binding failure
  - Given: a manifest missing a required binding
  - When: runtime validation runs
  - Then: result reports the missing binding with actor/move key
  - Edge cases: manifest ID mismatch
- **AC-3**: no hardcoded move paths
  - Given: battle runtime source is reviewed
  - When: move presentation selection is inspected
  - Then: no branches select sprite/VFX paths by move display name or hardcoded move ID
  - Edge cases: allowed generic lookup tables are authored content, not runtime branches

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/battle_engine/test_animation_manifest_runtime_lookup.gd`

**Status**: [x] Created - focused BATTLE-007 integration suite passed with 7/7 tests and 80 assertions; adjacent Battle animation/content suite passed with 11/11 tests and 65 assertions; Battle Engine integration slice passed with 14/14 tests and 909 assertions; full unit/integration suite passed with 139/139 tests and 7,129 assertions.

## Dependencies

- Depends on: Existing BattleAnimationManifest validator/content fixture, Battle Story 001
- Unlocks: Production battle presentation and content lock

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 4/4 passing.
**Deviations**: None. Advisory note: full-mode QA/lead sidecar gates were unavailable due agent thread limit, so closure uses local verification plus approved `/code-review`.
**Test Evidence**: Integration evidence at `tests/integration/battle_engine/test_animation_manifest_runtime_lookup.gd`; focused BATTLE-007 suite passed with 7/7 tests and 80 assertions; adjacent Battle animation/content suite passed with 11/11 tests and 65 assertions; Battle Engine integration slice passed with 14/14 tests and 909 assertions; full unit/integration suite passed with 139/139 tests and 7,129 assertions.
**Code Review**: Complete - `/code-review` returned APPROVED after review suggestions were implemented and re-reviewed.
