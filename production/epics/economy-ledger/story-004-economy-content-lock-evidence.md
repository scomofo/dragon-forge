# Story 004: Economy Content Lock Evidence

> **Epic**: Economy Ledger
> **Status**: Blocked
> **Layer**: Core
> **Type**: Config/Data
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**:

## Context

**GDD**: `design/gdd/shop.md`, `design/gdd/campaign-map.md`
**Requirement**: `TR-shop-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Authored Content Resources; ADR-0008: Campaign Map Content And Reward Pipeline; ADR-0009: Economy And Shop Transaction Boundaries
**ADR Decision Summary**: Boss and hazard Scrap bonuses remain provisional until authored Campaign Map node distribution and economy simulation or playtest evidence prove the Act 3 critical path surplus target.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: This is data/evidence work, not runtime logic.

**Control Manifest Rules (this layer)**:
- Required: CM-DATA-04, CM-MAP-07
- Forbidden: Finalizing `BOSS_SCRAP_BONUS` or `HAZARD_SCRAP_BONUS` from estimates alone
- Guardrail: Keep OQ-SH01 open until `docs/balance/economy-content-lock.md` validates the target.

---

## Acceptance Criteria

*From GDD `design/gdd/shop.md`, scoped to this story:*

- [ ] OQ-SH01 is resolved only after Campaign Map Act 3 mandatory encounter distribution and average Scrap earn data exist.
- [ ] The Act 3 mandatory-node critical path yields at least 200 Scraps surplus above normal consumable expenditure.
- [ ] `BOSS_SCRAP_BONUS` and `HAZARD_SCRAP_BONUS` are calibrated jointly against Hatchery pull cost and the cheapest relic price.
- [ ] The evidence artifact records whether Hatchery spending crowds out relic acquisition.

## Implementation Notes

Create `docs/balance/economy-content-lock.md` from authored Campaign Map node data and simulation/playtest evidence. This story is blocked until Campaign Map content exists.

## Out of Scope

- EconomyLedger runtime helpers.
- Campaign Map node authoring.
- Shop purchase UI.

## QA Test Cases

- **Config check AC-1**: economy content lock artifact
  - Given: authored Act 3/4 Campaign Map node data and Scrap reward tables
  - When: the economy simulation/playtest is run
  - Then: `docs/balance/economy-content-lock.md` reports whether surplus is >= 200 Scraps
  - Edge cases: normal consumable spend, moderate Hatchery pull cadence
- **Config check AC-2**: tuning remains provisional until evidence
  - Given: no content-lock artifact
  - When: bonus constants are reviewed
  - Then: they remain marked provisional
  - Edge cases: placeholder estimates must not be treated as final

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `docs/balance/economy-content-lock.md`

**Status**: [ ] Not yet created - blocked on authored Campaign Map node distribution and economy simulation/playtest data

## Dependencies

- Depends on: Campaign Map authored content stories, Economy Ledger Stories 001-003
- Unlocks: Shop OQ-SH01 closure and production balance lock
