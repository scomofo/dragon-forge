# Story 007: Cross-System XP Source Contracts

> **Epic**: Dragon Progression
> **Status**: Blocked
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**:

## Context

**GDD**: `design/gdd/dragon-progression.md`
**Requirement**: `TR-dragon-002`, `TR-dragon-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Dragon Data Model And Progression Services; ADR-0008: Campaign Map Content And Reward Pipeline
**ADR Decision Summary**: Battle, Hatchery, Campaign Map, and Journal interact with Dragon Progression through service helpers and semantic events; Battle does not directly mutate XP or Resonance.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Cross-system tests should use real helper APIs once Hatchery, Battle, Campaign Map, and Journal services exist.

**Control Manifest Rules (this layer)**:
- Required: CM-DRAGON-05, CM-BATTLE-04, CM-MAP-03
- Forbidden: Battle Engine or Campaign Map incrementing `dragon.battle_charges` directly
- Guardrail: Feature systems settle durable progression through SaveTransaction after Battle returns payloads.

---

## Acceptance Criteria

*From GDD `design/gdd/dragon-progression.md`, scoped to this story:*

- [ ] AC-DP46 through AC-DP52: Hatchery duplicate XP, Battle XP, XP ordering, and shared XP loop behavior match the GDD.
- [ ] AC-DP75: Journal receives invalid `stage_iv_reached` element defensively without crashing.
- [ ] AC-DP88 and AC-DP95: Stage IV Captain's Log delivery and late-connect recovery work through Journal.
- [ ] AC-DP92a: Battle-originated non-active dragon events do not increment charges; Campaign Map bench award path can increment charges.

## Implementation Notes

This story is blocked until at least Battle, Hatchery, Campaign Map, and Journal service scaffolds exist. The Dragon Progression helpers created in earlier stories should be sufficient; this story verifies integration ownership and catches direct-write regressions.

## Out of Scope

- Hatchery RNG/pity implementation.
- Battle damage and runtime implementation.
- Journal UI presentation.

## QA Test Cases

- **AC-1**: Hatchery duplicate XP uses shared loop
  - Given: Hatchery duplicate outcomes for Common, Uncommon, and Rare
  - When: duplicate XP is applied through Dragon Progression
  - Then: AC-DP46 through AC-DP50 pass exactly
  - Edge cases: missing element duplicate discard is covered by Story 004
- **AC-2**: Battle XP and active Resonance
  - Given: BattleEndedPayload values at equal and uneven levels
  - When: Campaign Map/Singularity settlement applies XP
  - Then: AC-DP51, AC-DP52, and active charge ownership pass
  - Edge cases: Battle never mutates `battle_charges` directly
- **AC-3**: Journal stage IV recovery
  - Given: stage IV event and late-connected Journal service
  - When: Journal receives or queries progression state
  - Then: correct Captain's Log entry is surfaced and invalid element logs safely
  - Edge cases: no connected listener at commit time

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/dragon/test_cross_system_xp_source_contracts.gd`

**Status**: [ ] Not yet created - blocked until dependent feature/core services exist

## Dependencies

- Depends on: Story 002, Story 003, Hatchery service stories, Battle runtime stories, Campaign Map settlement stories, Journal service stories
- Unlocks: End-to-end progression settlement validation
