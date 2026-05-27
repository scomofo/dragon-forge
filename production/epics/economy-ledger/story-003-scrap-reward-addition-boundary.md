# Story 003: Scrap Reward Addition Boundary

> **Epic**: Economy Ledger
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 0.75 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/campaign-map.md`, `design/gdd/shop.md`
**Requirement**: `TR-map-001`, `TR-shop-002`, `TR-shop-004`
**Requirement Text**:
- `TR-map-001`: Own expedition party, current node, cleared nodes, act gates, map traversal, final XP decay, and Campaign Map reward settlement.
- `TR-shop-002`: Every Scrap mutation uses EconomyLedger in a SaveTransaction and cannot make `player_scraps` negative.
- `TR-shop-004`: Keep OQ-SH01 boss and hazard Scrap bonus tuning provisional until Campaign Map node and playtest or simulation data exists.
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0008: Campaign Map Content And Reward Pipeline; ADR-0009: Economy And Shop Transaction Boundaries
**ADR Decision Summary**: Campaign Map owns final reward settlement and applies Scrap rewards through EconomyLedger; Battle payload values are not final durable authority.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Reward helpers should be deterministic integer operations staged in SaveTransaction.
**Performance**: No per-frame work expected. Reward addition is an O(1) integer mutation during settlement only.

**Control Manifest Rules (this layer)**:
- Required: CM-GLOB-09, CM-DATA-04, CM-ECO-01, CM-MAP-04, CM-MAP-07
- Forbidden: Accepting arbitrary Battle `scraps_earned` as final authority, directly mutating `player_scraps`, or finalizing `BOSS_SCRAP_BONUS` / `HAZARD_SCRAP_BONUS` from provisional estimates.
- Guardrail: Authored Campaign Map reward data remains the source of final reward amounts; OQ-SH01 remains open until `docs/balance/economy-content-lock.md` validates the Act 3 surplus target.

---

## Acceptance Criteria

*From GDD `design/gdd/campaign-map.md` and `design/gdd/shop.md`, scoped to this story:*

- [x] Campaign Map battle-end settlement applies authored Scrap rewards through EconomyLedger.
- [x] AC-CM11 and AC-CM13: losing a battle results in no loss of Data Scraps.
- [x] AC-SH54: underlying `player_scraps` can exceed 999 and remains exact after transactions.
- [x] Shop OQ-SH01 remains provisional; reward helper implementation does not finalize `BOSS_SCRAP_BONUS` / `HAZARD_SCRAP_BONUS` values or create the economy content-lock verdict.

## Implementation Notes

Implement `add_scraps(tx, amount, source_id)` and validation for non-negative authored reward amounts. This story may include a small settlement harness that takes an authored reward amount and rejects mismatched arbitrary Battle payload values, but it must not create Campaign Map node content, tune Act 3 bonuses, define `BOSS_SCRAP_BONUS` / `HAZARD_SCRAP_BONUS`, or produce `docs/balance/economy-content-lock.md`.

## Out of Scope

- Campaign Map node graph authoring.
- Boss/hazard bonus calibration.
- HUD display.

## QA Test Cases

- **AC-1**: successful reward addition
  - Given: a transaction with `player_scraps = 90`
  - When: `add_scraps(tx, 15, source_id)` is called and committed
  - Then: reload shows `player_scraps = 105`
  - Edge cases: crossing 999 preserves exact underlying value
- **AC-2**: invalid reward amount
  - Given: a transaction with valid Scraps
  - When: `add_scraps(tx, -1, source_id)` is called
  - Then: result fails and no mutation occurs
  - Edge cases: amount 0 returns a named no-op/success result per implementation choice
- **AC-3**: defeat does not deduct Scraps
  - Given: a settlement harness for a lost battle
  - When: defeat settlement runs
  - Then: `player_scraps` is unchanged
  - Edge cases: prior reward balance above 999
- **AC-4**: OQ-SH01 provisional tuning boundary
  - Given: the reward helper implementation and settlement harness source
  - When: the boundary is inspected by tests
  - Then: it does not define or finalize `BOSS_SCRAP_BONUS`, `HAZARD_SCRAP_BONUS`, or `docs/balance/economy-content-lock.md`
  - Edge cases: helper may accept authored reward amounts but must not invent or lock Act 3/4 bonus tuning

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/economy/test_scrap_reward_addition_boundary.gd`

**Status**: [x] Created and passing

**Evidence**:
- Red: focused Economy integration suite failed because `EconomyLedger.add_scraps()` did not exist.
- Focused: `tests/integration/economy/test_scrap_reward_addition_boundary.gd` and existing Economy spend integration tests passed with 9/9 tests and 109 assertions.
- Full: unit + integration suite passed with 115/115 tests and 6,772 assertions.

## Dependencies

- Depends on: Story 001, Save Transaction Commit And Rollback
- Unlocks: Campaign Map reward settlement stories

## Dev Notes

**Implemented**: 2026-05-27
**Deviations**: None.
**Code Review**: Complete. Lead programmer gate APPROVED.

**Implementation Summary**:
- Added `EconomyLedger.add_scraps(tx, amount, source_id)` for staged, transaction-bound Scrap reward additions.
- Reused `EconomyResult` for named reward outcomes with `source_id`, `amount`, `balance_before`, `balance_after`, `success`, and `reason`.
- Added an integration settlement harness proving authored rewards are applied through `add_scraps()`, Battle echo mismatches do not mutate Scraps, defeats do not deduct or add Scraps, and balances above 999 remain exact.
- Verified the Economy reward helper does not define `BOSS_SCRAP_BONUS`, `HAZARD_SCRAP_BONUS`, or an economy content-lock artifact.
- Addressed code review coverage gaps for inactive/missing-staged invalid transactions and full OQ-SH01 helper/harness/file-existence boundaries.
- Addressed code review API typing gap by returning `EconomyResult` from result-producing EconomyLedger methods.

**Acceptance Criteria Verification**:

| AC | Coverage |
| --- | --- |
| Authored Scrap rewards apply through EconomyLedger | `test_authored_reward_addition_commits_and_preserves_exact_balance_above_display_cap`, `test_defeat_settlement_and_mismatched_battle_echo_do_not_deduct_or_add_scraps` |
| Defeat causes no Data Scrap loss | `test_defeat_settlement_and_mismatched_battle_echo_do_not_deduct_or_add_scraps` |
| `player_scraps` can exceed 999 and remains exact | `test_authored_reward_addition_commits_and_preserves_exact_balance_above_display_cap` |
| OQ-SH01 remains provisional | `test_oq_sh01_bonus_tuning_remains_provisional_and_out_of_scope` |

**Verification Commands**:

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/integration/economy -ginclude_subdirs -gexit
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit
```

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 4/4 passing.
**Deviations**: None.
**Test Evidence**: Integration test at `tests/integration/economy/test_scrap_reward_addition_boundary.gd`; focused Economy integration suite passed with 9/9 tests and 109 assertions; full unit + integration suite passed with 115/115 tests and 6,772 assertions.
**Code Review**: Complete. `/code-review` verdict APPROVED; full-mode lead programmer gate APPROVED.
**QA Coverage Gate**: ADEQUATE.
**Scope Notes**: No Campaign Map node graph authoring, boss/hazard bonus calibration, HUD display, `BOSS_SCRAP_BONUS`/`HAZARD_SCRAP_BONUS` finalization, or economy content-lock artifact implemented.
