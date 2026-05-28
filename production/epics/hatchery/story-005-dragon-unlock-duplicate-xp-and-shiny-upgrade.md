# Story 005: Dragon Unlock Duplicate XP And Shiny Upgrade

> **Epic**: Hatchery
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/hatchery.md`
**Requirement**: `TR-hatch-001`, `TR-hatch-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Dragon Data Model And Progression Services; ADR-0012: Hatchery Pull Transaction And RNG Boundaries
**ADR Decision Summary**: Hatchery applies outcomes through Dragon Progression source-specific helpers inside the same pull transaction; Hatchery never creates Void and never mutates DragonRecord fields directly from UI code.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Verify staged dragon mutations do not leak before commit and duplicate XP uses Dragon Progression helpers.

**Control Manifest Rules (this layer)**:
- Required: CM-HATCH-03, CM-DRAGON-01, CM-DRAGON-03, CM-DRAGON-06, CM-GLOB-07
- Forbidden: Hatchery constructing or mutating DragonRecord instances directly in UI code, creating Void, or bypassing DragonProgressionService for duplicate XP
- Guardrail: XP and shiny upgrade must settle in the same transaction as Scrap spend and pity counters.

---

## Acceptance Criteria

*From GDD `design/gdd/hatchery.md`, scoped to this story:*

- [x] AC-H15: A pull for an unowned element sets that dragon owned through the approved creation helper.
- [x] AC-H16: A shiny pull for an unowned element sets `dragon.shiny = true`.
- [x] AC-H17: A non-shiny pull for an unowned element sets `dragon.shiny = false`.
- [x] AC-H18: A Common duplicate awards exactly 50 XP.
- [x] AC-H19: An Uncommon duplicate awards exactly 100 XP.
- [x] AC-H20: A Rare Shadow duplicate awards exactly 150 XP.
- [x] AC-H22: Stage I level 5 XP 30 plus a Common duplicate resolves to level 6 XP 30 via Dragon Progression Formula 4.
- [x] AC-H23: A MAX_LEVEL dragon receiving duplicate XP remains level 60 and XP 0.
- [x] AC-H24: A shiny duplicate on an owned non-shiny dragon sets shiny true without changing level or XP except duplicate XP if applicable.
- [x] AC-H25: A non-shiny duplicate on an owned shiny dragon does not downgrade shiny.
- [x] AC-H26: A shiny duplicate on a MAX_LEVEL non-shiny dragon upgrades shiny and keeps level 60 XP 0.
- [x] AC-H28: With all six standard dragons owned, every Hatchery pull produces a duplicate XP outcome.
- [x] AC-H29: A shiny duplicate on an owned non-shiny dragon not at MAX_LEVEL awards XP and upgrades shiny in the same pull resolution.

## Implementation Notes

Complete outcome application inside the transaction boundary from Story 004. New dragon creation should call Dragon Progression's Hatchery creation helper. Duplicate XP should call Dragon Progression duplicate XP/application helpers so level thresholds, MAX_LEVEL cleanup, and progression events remain owned by Dragon Progression.

Performance: duplicate/new lookup should be bounded by the six standard elements and not scan unrelated save data every frame.

## Out of Scope

- Rare/soft-pity RNG selection: Stories 002-003.
- Event publication after commit: Story 006.
- UI result cards and animations: Story 007.
- Void duplicate handling: Singularity GDD/story scope.

## QA Test Cases

- **AC-1**: New dragon creation
  - Given: an unowned Fire outcome
  - When: `execute_pull()` commits
  - Then: Fire is owned with level 1, XP 0, battle charges 0, non-Elder state, and no Void creation path
  - Edge cases: shiny true sets shiny true; shiny false sets shiny false
- **AC-2**: Duplicate XP amounts
  - Given: owned Fire, Stone, and Shadow dragons
  - When: Common, Uncommon, and Rare duplicate outcomes apply
  - Then: XP awards are 50, 100, and 150 respectively
  - Edge cases: unknown rarity rejects with named failure
- **AC-3**: Dragon Progression XP loop
  - Given: a level 5 dragon with XP 30
  - When: a Common duplicate grants 50 XP
  - Then: Dragon Progression resolves final level 6 XP 30
  - Edge cases: progression events are pending until commit
- **AC-4**: MAX_LEVEL cleanup
  - Given: a level 60 dragon with XP 0
  - When: any duplicate XP award applies
  - Then: level remains 60 and XP remains 0
  - Edge cases: shiny upgrade can still apply
- **AC-5**: Shiny upgrade and no downgrade
  - Given: owned shiny and non-shiny dragons
  - When: shiny and non-shiny duplicates apply
  - Then: shiny duplicate upgrades false->true, non-shiny duplicate does not downgrade true->false
  - Edge cases: level and XP are preserved except duplicate XP progression
- **AC-6**: XP plus shiny same pull
  - Given: owned non-shiny dragon below MAX_LEVEL
  - When: a shiny duplicate outcome applies
  - Then: XP is awarded and shiny becomes true in the same committed pull
  - Edge cases: save failure rolls back both effects through Story 004 transaction behavior
- **AC-7**: All-owned duplicate path
  - Given: all six standard dragons are owned
  - When: pulls resolve
  - Then: every standard outcome is duplicate XP and no new-dragon intro/outcome type is produced
  - Edge cases: Shadow remains duplicate, Void remains absent

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/hatchery/test_dragon_unlock_duplicate_xp_and_shiny_upgrade.gd`

**Status**: [x] Created and passing locally; focused HATCHERY-005 integration suite passed with 7/7 tests and 113 assertions; Hatchery unit/integration slice passed with 41/41 tests and 10,754 assertions; full unit/integration suite passed with 198/198 tests and 18,436 assertions.

## Dependencies

- Depends on: HATCHERY-004 (`production/epics/hatchery/story-004-pull-transaction-boundary-and-scrap-spend.md`), DRAGON-004 (`production/epics/dragon-progression/story-004-dragon-creation-and-source-helpers.md`)
- Unlocks: HATCHERY-006 (`production/epics/hatchery/story-006-post-commit-events-and-preview-contract.md`), HATCHERY-007 (`production/epics/hatchery/story-007-hatchery-ring-ui-and-reveal-evidence-contract.md`)

## Completion Notes

**Completed**: 2026-05-28
**Verdict**: COMPLETE WITH NOTES
**Criteria**: 13/13 passing.
**Deviations**: None blocking. Advisory notes: full-mode director gates were not spawned in this non-interactive run; prior `/code-review` verdict was APPROVED WITH SUGGESTIONS; Godot/GUT could not be rerun in this environment because `godot` is not available on `PATH`.
**Test Evidence**: Integration: `tests/integration/hatchery/test_dragon_unlock_duplicate_xp_and_shiny_upgrade.gd`. Recorded local evidence: focused HATCHERY-005 suite 7/7 tests and 113 assertions; adjacent HATCHERY-004 transaction suite 8/8 tests and 155 assertions; Hatchery unit/integration slice 41/41 tests and 10,754 assertions; full unit/integration suite 198/198 tests and 18,436 assertions.
**Code Review**: Complete — `/code-review` approved with suggestions; no required changes.

### Test-Criterion Traceability

| Criterion | Evidence | Status |
|---|---|---|
| AC-H15 | `test_unowned_pulls_create_core_dragons_with_shiny_state_from_roll` verifies unowned pulls create owned core dragons through the service path. | COVERED |
| AC-H16 | `test_unowned_pulls_create_core_dragons_with_shiny_state_from_roll` verifies shiny unowned pulls persist `dragon.shiny = true`. | COVERED |
| AC-H17 | `test_unowned_pulls_create_core_dragons_with_shiny_state_from_roll` verifies non-shiny unowned pulls persist `dragon.shiny = false`. | COVERED |
| AC-H18 | `test_duplicate_xp_amounts_follow_rarity_multipliers` verifies Common duplicate XP is exactly 50. | COVERED |
| AC-H19 | `test_duplicate_xp_amounts_follow_rarity_multipliers` verifies Uncommon duplicate XP is exactly 100. | COVERED |
| AC-H20 | `test_duplicate_xp_amounts_follow_rarity_multipliers` verifies Rare Shadow duplicate XP is exactly 150. | COVERED |
| AC-H22 | `test_duplicate_xp_uses_dragon_progression_loop_and_max_level_cleanup` verifies level 5 XP 30 plus Common duplicate resolves to level 6 XP 30. | COVERED |
| AC-H23 | `test_duplicate_xp_uses_dragon_progression_loop_and_max_level_cleanup` verifies MAX_LEVEL duplicate XP leaves level 60 XP 0. | COVERED |
| AC-H24 | `test_duplicate_shiny_upgrade_and_non_shiny_duplicate_no_downgrade` verifies shiny duplicate upgrades an owned non-shiny dragon while preserving progression except duplicate XP. | COVERED |
| AC-H25 | `test_duplicate_shiny_upgrade_and_non_shiny_duplicate_no_downgrade` verifies non-shiny duplicate does not downgrade an owned shiny dragon. | COVERED |
| AC-H26 | `test_max_level_shiny_duplicate_upgrades_shiny_without_retaining_xp` verifies shiny duplicate upgrades a MAX_LEVEL non-shiny dragon and keeps level 60 XP 0. | COVERED |
| AC-H28 | `test_all_owned_standard_dragons_route_every_standard_outcome_to_duplicate_xp` verifies all six owned standard dragons route every standard outcome to duplicate XP. | COVERED |
| AC-H29 | `test_duplicate_shiny_upgrade_and_non_shiny_duplicate_no_downgrade` verifies a below-MAX owned non-shiny dragon receives XP and shiny upgrade in the same pull. | COVERED |
