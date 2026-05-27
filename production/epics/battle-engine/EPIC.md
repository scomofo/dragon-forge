# Epic: Battle Engine

> **Layer**: Core
> **GDD**: `design/gdd/battle-engine.md`
> **Architecture Module**: Battle Engine
> **Status**: Ready
> **Stories**: Created

## Overview

Build the scene-local 1v1 battle runtime for Dragon Forge. This epic owns the INIT, TELEGRAPH, IMPACT, RECOIL, and RESOLUTION state machine; deterministic battle formulas; NPC action selection; typed battle payloads; and battle animation manifest lookup while leaving durable settlement to Campaign Map or Singularity.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0002: Semantic Event Contracts | Battle emits typed runtime/presentation events while durable-state events remain post-commit in owner systems. | HIGH |
| ADR-0006: Dragon Data Model And Progression Services | Battle consumes immutable `DragonStats` snapshots and reads `is_elder` for the Stage IV branch without mutating Dragon records. | HIGH |
| ADR-0007: Battle Runtime State Machine | Battle is scene-local/runtime-only, accepts actions only in TELEGRAPH, and returns typed settlement payloads instead of committing rewards. | HIGH |
| ADR-0008: Campaign Map Content And Reward Pipeline | Campaign Map validates and settles Battle payload rewards for map encounters. | HIGH |
| ADR-0009: Economy And Shop Transaction Boundaries | Battle reports Defrag Patch consumption and reward payloads but does not mutate Scraps or expedition flags directly. | HIGH |
| ADR-0010: Singularity Boss And Ending Orchestration | Mirror Admin uses continuous BattleSession profile swaps with final-only battle completion. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-battle-001 | Implement five-phase 1v1 battle loop: INIT, TELEGRAPH, IMPACT, RECOIL, RESOLUTION. | ADR-0007 |
| TR-battle-002 | Implement canonical damage, type effectiveness, status, crit, defend cooldown, simultaneous KO, and Elder Stage IV multiplier formulas. | ADR-0006, ADR-0007 |
| TR-battle-003 | Emit typed runtime battle result and presentation payloads, including `raw_xp_awarded` and `scraps_earned`, without committing durable rewards. | ADR-0002, ADR-0007, ADR-0008, ADR-0009, ADR-0010 |

## Definition of Done

This epic is complete when:

- A Battle screen/host owns a controller Node that owns one `BattleSession` runtime object; Battle is not an Autoload or persisted Resource.
- TELEGRAPH is the only phase that accepts gameplay actions from Input Router semantic actions.
- Damage, accuracy, crit, status, Defend, cooldown, DoT, KO, and Elder Stage IV rules are covered by unit/integration tests.
- Battle emits `TurnResolvedPayload`, `BattleEndedPayload`, `BattleDurableDelta`, and presentation payloads without opening save transactions.
- `BattleDefinition.animation_manifest_id` and `MoveDefinition` IDs resolve through `BattleAnimationManifest`; runtime code does not branch on move names to choose sprite/VFX paths.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Runtime Session And Payload Contracts](story-001-runtime-session-and-payload-contracts.md) | Integration | Complete | ADR-0007 |
| 002 | [Damage, Type, Crit, And Stage Formulas](story-002-damage-type-crit-and-stage-formulas.md) | Logic | Ready | ADR-0006, ADR-0007 |
| 003 | [Status And Recoil Effects](story-003-status-and-recoil-effects.md) | Logic | Ready | ADR-0007 |
| 004 | [Telegraph, Defend, And Defrag Delta](story-004-telegraph-defend-and-defrag-delta.md) | Integration | Ready | ADR-0007, ADR-0009 |
| 005 | [Turn Resolution And Presentation Events](story-005-turn-resolution-and-presentation-events.md) | Integration | Ready | ADR-0002, ADR-0007 |
| 006 | [NPC Action Selection Heuristics](story-006-npc-action-selection-heuristics.md) | Logic | Ready | ADR-0007 |
| 007 | [Animation Manifest Runtime Lookup](story-007-animation-manifest-runtime-lookup.md) | Integration | Ready | ADR-0007 |

## Next Step

Run `/story-readiness production/epics/battle-engine/story-001-runtime-session-and-payload-contracts.md`, then `/dev-story` on the first ready story.
