# Story 002: Scrap Spend Transaction Boundary

> **Epic**: Economy Ledger
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/shop.md`
**Requirement**: `TR-shop-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Save Transaction Boundary; ADR-0009: Economy And Shop Transaction Boundaries
**ADR Decision Summary**: Scrap spends are staged inside a `SaveTransaction`; insufficient funds or invalid amounts fail without mutating staged or canonical save data.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Verify staged transaction mutation remains isolated until SaveService commit.

**Control Manifest Rules (this layer)**:
- Required: CM-SAVE-02, CM-ECO-01
- Forbidden: Partial purchase states or direct save file writes from EconomyLedger
- Guardrail: Spend results include source/sink IDs for audit and QA.

---

## Acceptance Criteria

*From GDD `design/gdd/shop.md`, scoped to this story:*

- [x] AC-SH11: after a successful purchase spend, Scrap balance equals pre-purchase balance minus item price.
- [x] AC-SH12: a purchase attempted with `player_scraps < item_price` is refused and `player_scraps` is unchanged.
- [x] AC-SH14: `player_scraps` never goes below 0 by any transaction.
- [x] AC-SH15: exact-price spend succeeds and leaves `player_scraps = 0`.
- [x] AC-SH16: save write failure during purchase rollback preserves pre-purchase `player_scraps`.

## Implementation Notes

Implement `spend_scraps(tx, amount, sink_id)`. It may mutate only `tx.staged_save.player_scraps`; SaveService remains responsible for commit/rollback. Do not set item/relic/expedition flags here.

## Out of Scope

- Shop purchase flag mutation.
- Campaign reward addition.
- Unit 01 responses and Shop UI states.

## QA Test Cases

- **AC-1**: successful staged spend
  - Given: a transaction with `player_scraps = 50`
  - When: `spend_scraps(tx, 50, sink_id)` is called and committed
  - Then: reload shows `player_scraps = 0`
  - Edge cases: spend 35 from 50 leaves 15
- **AC-2**: refused insufficient spend
  - Given: a transaction with `player_scraps = 10`
  - When: `spend_scraps(tx, 35, sink_id)` is called
  - Then: result fails and staged/canonical `player_scraps` remain 10
  - Edge cases: amount < 0, amount = 0
- **AC-3**: rollback on commit failure
  - Given: a successful staged spend and injected SaveService failure
  - When: commit fails
  - Then: reload preserves the pre-spend canonical balance
  - Edge cases: temp file exists after failure

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/economy/test_scrap_spend_transaction_boundary.gd`

**Status**: [x] Created and passing

**Evidence**:
- Focused: `tests/integration/economy/test_scrap_spend_transaction_boundary.gd` passed with 5/5 tests and 45 assertions.
- Full: unit + integration suite passed with 99/99 tests and 5,847 assertions.

## Dependencies

- Depends on: ECO-001 (`production/epics/economy-ledger/story-001-scrap-read-affordability-and-results.md`), Save Transaction Commit And Rollback (`production/epics/save-persistence/story-002-save-transaction-commit-rollback.md`)
- Unlocks: Shop purchase transaction stories, Hatchery pull spend

## Dev Notes

**Implemented**: 2026-05-27
**Deviations**: None.
**Code Review**: Complete - approved on 2026-05-27 with no blocking findings.

**Implementation Summary**:
- Added `EconomyLedger.spend_scraps(tx, amount, sink_id)` to stage Scrap spends only on `tx.staged_save.player_scraps`.
- Invalid transactions, negative amounts, and insufficient balances return named failed `EconomyResult` data without mutating staged or canonical save data.
- Successful spends populate balance-before/balance-after and `sink_id` audit fields; SaveService remains the only commit/rollback owner.

**Acceptance Criteria Verification**:

| AC | Coverage |
| --- | --- |
| AC-SH11 | `test_exact_price_spend_commits_zero_balance`, `test_partial_spend_mutates_only_staged_save_before_commit` |
| AC-SH12 | `test_insufficient_negative_and_zero_spends_do_not_mutate` |
| AC-SH14 | `test_insufficient_negative_and_zero_spends_do_not_mutate`, exact-price zero-balance coverage |
| AC-SH15 | `test_exact_price_spend_commits_zero_balance` |
| AC-SH16 | `test_failed_commit_rolls_back_successful_staged_spend` |

**Verification Commands**:

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/integration/economy -ginclude_subdirs -gexit
godot --headless --import
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit
```

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 5/5 passing
**Deviations**: None
**Test Evidence**: Integration test at `tests/integration/economy/test_scrap_spend_transaction_boundary.gd`; focused suite passed with 5/5 tests and 45 assertions; full unit/integration suite passed with 99/99 tests and 5,847 assertions.
**Code Review**: Complete - approved with no required changes.
**Review Notes**: Full review mode is configured, but delegated sidecar review was not spawned in this closure pass because sub-agent spawning requires an explicit delegation request in the current tool policy. Local code review for ECO-002 was completed and approved before closure.
