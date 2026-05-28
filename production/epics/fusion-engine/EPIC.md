# Epic: Fusion Engine

> **Layer**: Core
> **GDD**: `design/gdd/fusion-engine.md`
> **Architecture Module**: Fusion Engine
> **Status**: Ready
> **Stories**: Not yet created - run `/create-stories fusion-engine`

## Overview

Build the deterministic Fusion service for Dragon Forge. This epic owns parent eligibility, shared preview/commit formula paths, inherited base stat calculation, same-element stability bonus, cross-element HP penalty, Elder generation, and atomic roster mutation through Dragon Progression and Save / Persistence.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0001: Save Transaction Boundary | Fusion child creation and parent mutation must commit atomically or roll back together. | HIGH |
| ADR-0006: Dragon Data Model And Progression Services | Fusion writes canonical Dragon records through source-specific Dragon Progression helpers and sets `is_elder` through approved schema fields. | HIGH |
| ADR-0013: Fusion Anvil Transaction Boundaries | Fusion preview and commit share one formula path, return named result types, and avoid UI-owned record mutation. | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-fusion-001 | Fuse two dragons through inherited base stats, level bonus, same-element bonus, cross-element HP penalty, and Elder flag generation. | ADR-0006, ADR-0013 |
| TR-fusion-002 | Fusion child creation is atomic with parent removal or retention rules and Save / Persistence transaction support. | ADR-0001, ADR-0006, ADR-0013 |

## Definition of Done

This epic is complete when:

- `FusionService` exposes read-only preview and transactional commit APIs that use the same formula path.
- Formula tests cover canonical average, level bonus, same-element bonus, cross-element HP penalty, Elder boundary cases, shiny reset, and level-1 child state.
- Parent validation rejects missing parents, self-fusion, invalid records, and cancellation before commit without mutating save data.
- Successful fusion creates the child and applies parent retention/removal rules in one SaveTransaction.
- Battle can consume `is_elder` and Fusion's Elder multiplier constant without hardcoded duplicate literals in battle runtime code.

## Next Step

Run `/create-stories fusion-engine` to break this epic into implementable stories.
