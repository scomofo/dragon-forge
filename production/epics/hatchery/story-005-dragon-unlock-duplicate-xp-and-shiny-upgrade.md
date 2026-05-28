# Story 005: Dragon Unlock Duplicate XP And Shiny Upgrade

> **Epic**: Hatchery
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**:

## Context

**GDD**: `design/gdd/hatchery.md`
**Requirement**: `TR-hatch-001`, `TR-hatch-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Dragon Data Model And Progression Services; ADR-0012: Hatchery Pull Transaction And RNG Boundaries
**ADR Decision Summary**: Hatchery applies outcomes through Dragon Progression source-specific helpers inside the same pull transaction; Hatchery never creates Void and never mutates DragonRecord fields directly from UI code.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Verify staged dragon mutations do not leak before commit and duplicate XP uses Dragon Progression helpers.

**Control Manifest Rules (this layer)**:
- Required: CM-HATCH-03, CM-DRAGON-06, CM-GLOB-07
- Forbidden: Hatchery constructing or mutating DragonRecord instances directly in UI code, creating Void, or bypassing DragonProgressionService for duplicate XP
- Guardrail: XP and shiny upgrade must settle in the same transaction as Scrap spend and pity counters.

---

## Acceptance Criteria

*From GDD `design/gdd/hatchery.md`, scoped to this story:*

- [ ] AC-H15: A pull for an unowned element sets that dragon owned through the approved creation helper.
- [ ] AC-H16: A shiny pull for an unowned element sets `dragon.shiny = true`.
- [ ] AC-H17: A non-shiny pull for an unowned element sets `dragon.shiny = false`.
- [ ] AC-H18: A Common duplicate awards exactly 50 XP.
- [ ] AC-H19: An Uncommon duplicate awards exactly 100 XP.
- [ ] AC-H20: A Rare Shadow duplicate awards exactly 150 XP.
- [ ] AC-H22: Stage I level 5 XP 30 plus a Common duplicate resolves to level 6 XP 30 via Dragon Progression Formula 4.
- [ ] AC-H23: A MAX_LEVEL dragon receiving duplicate XP remains level 60 and XP 0.
- [ ] AC-H24: A shiny duplicate on an owned non-shiny dragon sets shiny true without changing level or XP except duplicate XP if applicable.
- [ ] AC-H25: A non-shiny duplicate on an owned shiny dragon does not downgrade shiny.
- [ ] AC-H26: A shiny duplicate on a MAX_LEVEL non-shiny dragon upgrades shiny and keeps level 60 XP 0.
- [ ] AC-H28: With all six standard dragons owned, every Hatchery pull produces a duplicate XP outcome.
- [ ] AC-H29: A shiny duplicate on an owned non-shiny dragon not at MAX_LEVEL awards XP and upgrades shiny in the same pull resolution.

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

**Status**: [ ] Not yet created

## Dependencies

- Depends on: Story 004, Dragon Progression Story 004
- Unlocks: Story 006, Story 007
