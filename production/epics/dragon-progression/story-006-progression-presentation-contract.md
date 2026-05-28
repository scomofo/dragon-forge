# Story 006: Progression Presentation Contract

> **Epic**: Dragon Progression
> **Status**: Blocked
> **Layer**: Core
> **Type**: UI
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**:

## Context

**GDD**: `design/gdd/dragon-progression.md`
**Requirement**: `TR-dragon-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Dragon Data Model And Progression Services
**ADR Decision Summary**: Dragon Progression exposes derived level, stage, XP threshold, shiny, and stat data for UI, while presentation systems own rendering and timing.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: UI evidence must be captured in actual Godot screens once Hub, Battle, Hatchery, and roster screens exist.

**Control Manifest Rules (this layer)**:
- Required: CM-DRAGON-04 and presentation systems read derived snapshots, not live mutable SaveData
- Forbidden: UI mutating DragonRecord fields or exposing SPD
- Guardrail: Stage IV art evidence requires art-director/tester sign-off.

---

## Acceptance Criteria

*From GDD `design/gdd/dragon-progression.md`, scoped to this story:*

- [ ] AC-DP54 through AC-DP58: SPD is not displayed in dragon detail, party cards, battle panels, Hatchery detail, tooltips, hover states, or gamepad context panels.
- [ ] AC-DP77 through AC-DP83: XP bar, level display, stage badge, MAX badge, and shiny indicator behave as specified.
- [ ] AC-DP84 through AC-DP89: Stage IV treatment, level-up animation timing, Captain's Log surfacing, and Stage IV sprite distinction receive required evidence/sign-off.
- [ ] AC-DP93 and AC-DP96: stage badge and stage-appropriate art remain correct after save-load and across presentation contexts.

## Implementation Notes

This is a presentation contract story and is blocked until production Hub/roster, Battle, and Hatchery screens exist. The Core service should expose enough read-only data for those screens, but this story should not be scheduled in Sprint 02.

## Out of Scope

- Core stat/stage calculation: Story 001.
- Journal content implementation: Journal epic.
- Art asset production for all stage sprites: Art/Presentation epics.

## QA Test Cases

- **Manual check AC-1**: SPD hidden
  - Setup: open all dragon presentation contexts for all six core elements
  - Verify: no "SPD", "Speed", or variant is visible in labels, tooltips, hover, or gamepad panels
  - Pass condition: SPD is completely absent from player-facing UI
- **Manual check AC-2**: XP, level, stage, shiny display
  - Setup: inspect nontrivial level, threshold-minus-one XP, MAX_LEVEL, and shiny records
  - Verify: XP fill/MAX badge, `Lv. N`, Roman numeral stage, and shiny indicator match AC-DP77 through AC-DP83
  - Pass condition: all displays update from derived Dragon Progression snapshots
- **Manual check AC-3**: stage visuals and timing
  - Setup: trigger a multi-level gain including at least one stage crossing
  - Verify: level ticks, stage animation order, input restoration under 2 seconds, and Stage IV art distinction
  - Pass condition: evidence docs include signed screenshots/timing notes

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/dragon-progression-presentation-contract-evidence.md`

**Status**: [ ] Not yet created - blocked until production presentation screens exist

## Dependencies

- Depends on: Story 001, Story 003, production Hub/roster screen, Battle screen, Hatchery screen, Journal integration
- Unlocks: Dragon progression presentation acceptance
