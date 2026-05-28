# Epic: Hatchery

> **Layer**: Core
> **GDD**: `design/gdd/hatchery.md`
> **Architecture Module**: Hatchery
> **Status**: Ready
> **Stories**: Created

## Overview

Build the deterministic Hatchery pull service for Dragon Forge. This epic owns egg pull orchestration, authored pull tables, rarity pity, element soft-pity, shiny rolls, duplicate XP routing, and atomic pull settlement through Economy Ledger, Dragon Progression, and Save / Persistence.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0001: Save Transaction Boundary | Pull spend, pity updates, dragon creation, duplicate XP, and result events commit or roll back together. | HIGH |
| ADR-0004: Authored Content Resources | Pull tables and required IDs use typed Resources or approved generated tables with validation. | HIGH |
| ADR-0006: Dragon Data Model And Progression Services | Hatchery creates dragons and applies duplicate XP only through Dragon Progression helpers. | HIGH |
| ADR-0009: Economy And Shop Transaction Boundaries | Pull Scrap spend uses EconomyLedger in a SaveTransaction and cannot make balance negative. | HIGH |
| ADR-0012: Hatchery Pull Transaction And RNG Boundaries | HatcheryService uses immutable pull tables, injected or transaction-scoped RNG, stable roll order, and post-commit events. | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-hatch-001 | Implement egg pulls, pity counters, rarity probabilities, element soft-pity, shiny protocol, and duplicate-dragon XP grants. | ADR-0004, ADR-0006, ADR-0009, ADR-0012 |
| TR-hatch-002 | Hatchery pull results, Scrap spend, dragon creation, pity updates, and duplicate XP are committed atomically. | ADR-0001, ADR-0006, ADR-0009, ADR-0012 |

## Definition of Done

This epic is complete when:

- `HatcheryService` executes pulls through one SaveTransaction and never uses UI-owned mutation or global RNG calls.
- Pull tables, rarity weights, element weights, pity rules, shiny rate, and stable IDs are authored and validated.
- Rarity pity, element soft-pity, shiny rolls, duplicate XP, and all six element drought counters are covered by deterministic tests.
- Pull success, insufficient Scraps, save failure rollback, duplicate XP, shiny upgrade, and all-owned duplicate paths have acceptance coverage.
- Result events and progression events publish only after save commit success.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Pull Table And Result Contracts](story-001-pull-table-and-result-contracts.md) | Logic | Ready | ADR-0004, ADR-0012 |
| 002 | [Rarity Pity And Shiny Roll Resolution](story-002-rarity-pity-and-shiny-roll-resolution.md) | Logic | Ready | ADR-0012 |
| 003 | [Element Soft Pity Resolution](story-003-element-soft-pity-resolution.md) | Logic | Ready | ADR-0012 |
| 004 | [Pull Transaction Boundary And Scrap Spend](story-004-pull-transaction-boundary-and-scrap-spend.md) | Integration | Ready | ADR-0001, ADR-0009, ADR-0012 |
| 005 | [Dragon Unlock Duplicate XP And Shiny Upgrade](story-005-dragon-unlock-duplicate-xp-and-shiny-upgrade.md) | Integration | Ready | ADR-0006, ADR-0012 |
| 006 | [Post Commit Events And Preview Contract](story-006-post-commit-events-and-preview-contract.md) | Integration | Ready | ADR-0001, ADR-0012 |
| 007 | [Hatchery Ring UI And Reveal Evidence Contract](story-007-hatchery-ring-ui-and-reveal-evidence-contract.md) | UI | Blocked | ADR-0012 |

## Next Step

Run `/story-readiness production/epics/hatchery/story-001-pull-table-and-result-contracts.md` before starting implementation.
