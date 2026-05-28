# Epic: Economy Ledger

> **Layer**: Core
> **GDD**: `design/gdd/shop.md`, `design/gdd/campaign-map.md`
> **Architecture Module**: Economy Ledger
> **Status**: Ready
> **Stories**: Created

## Overview

Build the shared Scrap mutation boundary for Dragon Forge. This epic owns `player_scraps` add/spend rules, affordability checks, named economy results, source/sink IDs, and the transaction helper APIs that Shop and Campaign Map must use instead of directly editing save data.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0001: Save Transaction Boundary | Scrap mutations occur only on staged save data and commit or roll back atomically. | HIGH |
| ADR-0008: Campaign Map Content And Reward Pipeline | Campaign Map owns final reward settlement and validates battle reward data before applying economy changes. | HIGH |
| ADR-0009: Economy And Shop Transaction Boundaries | Economy is split so `EconomyLedger` owns `player_scraps` mutation while Shop and Campaign Map call it through transactions. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-shop-002 | Every Scrap mutation uses EconomyLedger in a SaveTransaction and cannot make `player_scraps` negative. | ADR-0009 |
| TR-shop-004 | Keep OQ-SH01 boss and hazard Scrap bonus tuning provisional until Campaign Map node and playtest or simulation data exists. | ADR-0004, ADR-0008, ADR-0009 |
| TR-map-001 | Own expedition party, current node, cleared nodes, act gates, map traversal, final XP decay, and Campaign Map reward settlement. | ADR-0008, ADR-0009 |

## Definition of Done

This epic is complete when:

- `EconomyLedger` exposes `get_scraps()`, `can_afford()`, `add_scraps()`, and `spend_scraps()` without writing save files directly.
- All Scrap changes require a `SaveTransaction`, stable source/sink IDs, and named `EconomyResult` values.
- Spend attempts fail without mutating staged data when the player cannot afford the cost or the amount is invalid.
- Campaign Map reward and Shop purchase stories can depend on the ledger without direct `player_scraps` writes.
- OQ-SH01 remains marked provisional until `docs/balance/economy-content-lock.md` exists with authored node and economy simulation/playtest evidence.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Scrap Read, Affordability, And Results](story-001-scrap-read-affordability-and-results.md) | Logic | Ready | ADR-0009 |
| 002 | [Scrap Spend Transaction Boundary](story-002-scrap-spend-transaction-boundary.md) | Integration | Ready | ADR-0001, ADR-0009 |
| 003 | [Scrap Reward Addition Boundary](story-003-scrap-reward-addition-boundary.md) | Integration | Ready | ADR-0008, ADR-0009 |
| 004 | [Economy Content Lock Evidence](story-004-economy-content-lock-evidence.md) | Config/Data | Blocked | ADR-0004, ADR-0008, ADR-0009 |

## Next Step

Run `/story-readiness production/epics/economy-ledger/story-001-scrap-read-affordability-and-results.md`, then `/dev-story` on the first ready story.
