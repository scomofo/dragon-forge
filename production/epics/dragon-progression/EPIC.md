# Epic: Dragon Progression

> **Layer**: Core
> **GDD**: `design/gdd/dragon-progression.md`
> **Architecture Module**: Dragon Progression
> **Status**: Ready
> **Stories**: Created

## Overview

Build the canonical dragon progression service for Dragon Forge. This epic owns the typed dragon record contract, stat and stage derivation, XP thresholds, XP application, Resonance charge mutation, source-specific dragon creation helpers, and post-commit progression events that downstream systems consume.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0001: Save Transaction Boundary | Dragon mutations happen through staged `SaveTransaction` copies and publish durable-state signals only after commit success. | HIGH |
| ADR-0002: Semantic Event Contracts | Progression and stage events use stable semantic payloads and missing listeners cannot block gameplay. | HIGH |
| ADR-0006: Dragon Data Model And Progression Services | Dragon Progression owns schema, stat calculation, XP application, derived stage, Resonance, named results, and creation helpers. | HIGH |
| ADR-0010: Singularity Boss And Ending Orchestration | Void story-dragon creation uses Dragon Progression helpers while Singularity owns the grant trigger and milestone state. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-dragon-001 | Own canonical dragon record schema, level progression, stat calculation, stage derivation, shiny, `battle_charges`, and `is_elder`. | ADR-0006 |
| TR-dragon-002 | Expose XP, stat calculation, stage, Resonance, and creation APIs for Battle, Hatchery, Campaign Map, Fusion, Singularity, and UI. | ADR-0006, ADR-0010 |
| TR-dragon-003 | Progression/stage events must be compatible with save transaction commit ordering. | ADR-0001, ADR-0002, ADR-0006 |

## Definition of Done

This epic is complete when:

- `DragonRecord`, `DragonStats`, progression event payloads, and named result types exist and are used by stories instead of anonymous dictionaries.
- `DragonProgressionService` calculates stats, stages, thresholds, XP application, Resonance charge consumption, and MAX_LEVEL cleanup deterministically.
- Hatchery, Fusion, Campaign Map, Singularity, Battle, and UI-facing callers can use service APIs without direct `DragonRecord` field mutation.
- Progression and stage events are queued during staged mutation and published only after save commit success.
- Unit/integration tests cover stat scaling, stage boundaries, XP loop boundaries, Resonance behavior, save repair, and event ordering.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Stats, Stage, And Record Contract](story-001-stats-stage-and-record-contract.md) | Logic | Ready | ADR-0006 |
| 002 | [XP Loop And Resonance](story-002-xp-loop-and-resonance.md) | Logic | Ready | ADR-0006 |
| 003 | [Post-Commit Progression Events](story-003-post-commit-progression-events.md) | Integration | Ready | ADR-0001, ADR-0002, ADR-0006 |
| 004 | [Dragon Creation And Source Helpers](story-004-dragon-creation-and-source-helpers.md) | Integration | Ready | ADR-0006, ADR-0010 |
| 005 | [Save Load Integrity And Repair](story-005-save-load-integrity-and-repair.md) | Integration | Ready | ADR-0001, ADR-0006 |
| 006 | [Progression Presentation Contract](story-006-progression-presentation-contract.md) | UI | Blocked | ADR-0006 |
| 007 | [Cross-System XP Source Contracts](story-007-cross-system-xp-source-contracts.md) | Integration | Blocked | ADR-0006, ADR-0008 |

## Next Step

Run `/story-readiness production/epics/dragon-progression/story-001-stats-stage-and-record-contract.md`, then `/dev-story` on the first ready story.
