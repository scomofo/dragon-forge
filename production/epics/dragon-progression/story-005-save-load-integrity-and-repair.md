# Story 005: Save Load Integrity And Repair

> **Epic**: Dragon Progression
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/dragon-progression.md`
**Requirement**: `TR-dragon-001`, `TR-dragon-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Save Transaction Boundary; ADR-0006: Dragon Data Model And Progression Services
**ADR Decision Summary**: Save / Persistence owns loading durable state, while Dragon Progression owns validation and repair rules for dragon records, XP, stage derivation, Resonance, and invalid elements.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Resource load/duplicate behavior must be tested with nested `DragonRecord` Resources.

**Control Manifest Rules (this layer)**:
- Required: CM-GLOB-05, CM-GLOB-07, CM-DATA-05
- Forbidden: Clamping invalid levels to hide corrupted records, or deriving persistent stage from loaded data
- Guardrail: Repair paths must be deterministic and logged.

---

## Acceptance Criteria

*From GDD `design/gdd/dragon-progression.md`, scoped to this story:*

- [x] AC-DP59 / AC-DP60: loading a dragon with `level = 0` or `level = 61` discards only that dragon record, does not clamp it, does not crash, keeps remaining valid dragons, and logs `Save integrity violation: dragon.level out of range [value] for element [element]. Dragon record discarded.`
- [x] AC-DP61: loading a MAX_LEVEL dragon with nonzero XP, such as `level = 60, xp = 45`, repairs XP to 0, keeps the dragon at level 60, and logs `Save correction: dragon.xp 45 cleared for MAX_LEVEL dragon [element].`
- [x] AC-DP62: loading a dragon with negative XP, such as `xp = -1`, discards only that dragon record, does not clamp or repair it, and logs `Save integrity violation: dragon.xp negative -1 for element [element]. Dragon record discarded.`
- [x] AC-DP63 / AC-DP63a: loading `level = 5, xp = 150` runs the canonical non-Resonance XP loop before the dragon is accessible; with either `battle_charges = 0` or `battle_charges = 5`, the final loaded state is `level = 8`, `xp = 0`, `battle_charges = 0`, and the warning contains `Save correction: dragon.xp 150 at level 5 — running XP loop to resolve.`
- [x] AC-DP64 / AC-DP65: local/cloud conflict projection selects the higher `level`; when levels match, it selects the higher `xp`. Example: cloud `level = 10, xp = 40` vs local `level = 12, xp = 20` selects local; cloud `level = 10, xp = 80` vs local `level = 10, xp = 30` selects cloud. The story does not implement a cloud sync UI prompt.
- [x] AC-DP66 / AC-DP66a: loading `element = "Wind"` discards the record and logs `Save integrity violation: unknown element 'Wind'. Dragon record discarded.`; loading reserved `dragon_id = "void_dragon"` with `element = "Void"` preserves the record, treats Void as a valid story element, places it in the reserved story-roster slot, and forces `shiny = false`.
- [x] AC-DP93: after save-load, derived progression snapshots report the correct stage from level, including `level = 12 -> Stage II`, without reading or trusting any persisted `stage` field. Actual stage badge UI verification remains out of scope.
- [x] AC-DP97: after save-load, a non-Elder Stage IV dragon at `level = 55` derives `stageMult` within +/-0.001 of `1.4`. Battle runtime damage verification remains out of scope.

## Implementation Notes

Add Dragon Progression validation/repair helpers that Save / Persistence can call during load or migration. Avoid presentation work; tests can inspect derived stage/stage multiplier snapshots instead of real UI badges until presentation stories exist.

## Out of Scope

- Cloud sync UI conflict prompt.
- Battle runtime damage verification beyond derived stage multiplier.
- Actual stage badge presentation.

## QA Test Cases

- **AC-1**: invalid record discard
  - Given: saves with level 0, level 61, XP -1, or element `Wind`
  - When: load validation runs
  - Then: offending records are discarded and logs match AC-DP59, AC-DP60, AC-DP62, and AC-DP66 text in this story
  - Edge cases: remaining valid dragons load normally
- **AC-2**: XP repair
  - Given: saves with MAX_LEVEL XP and out-of-range XP at level 5
  - When: load validation runs
  - Then: XP clears or runs the canonical loop per AC-DP61, AC-DP63, and AC-DP63a, ending at the exact final states listed above
  - Edge cases: `battle_charges` reset before repair
- **AC-3**: conflict and Void preservation
  - Given: local/cloud dragon state pairs and a valid Void story record
  - When: merge/load projection is requested
  - Then: higher level/higher XP wins per AC-DP64 and AC-DP65; Void is preserved in the reserved story roster slot per AC-DP66a
  - Edge cases: same level, different XP
- **AC-4**: derived post-load stage
  - Given: a level 12 and level 55 dragon loaded from disk
  - When: progression snapshots are derived
  - Then: stage and Stage IV multiplier match the snapshot-only scope for AC-DP93 and AC-DP97
  - Edge cases: no persisted stage field is used

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/dragon/test_save_load_integrity_and_repair.gd`

**Status**: [x] Created - focused Dragon save/load integrity suite passed with 4/4 tests and 62 assertions; full unit/integration suite passed with 127/127 tests and 6,953 assertions.

## Dependencies

- Depends on: Story 001, Story 002, `production/epics/save-persistence/story-004-ending-id-load-projection.md`
- Unlocks: Production save migration and robust roster loading

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 8/8 passing.
**Deviations**: None. Advisory notes: QA coverage accepts snapshot-only stage verification without injecting a corrupted persisted `stage` field; code review noted a few loosely typed test locals as non-blocking.
**Test Evidence**: Integration evidence at `tests/integration/dragon/test_save_load_integrity_and_repair.gd`; focused suite passed with 4/4 tests and 62 assertions; full unit/integration suite passed with 127/127 tests and 6,953 assertions.
**QA Coverage Gate**: ADEQUATE.
**Code Review**: Complete - `/code-review` returned APPROVED WITH SUGGESTIONS after required fixes; full-mode lead-programmer sidecar retry was unavailable due thread limit, so closure uses the approved review result plus local gate check.
