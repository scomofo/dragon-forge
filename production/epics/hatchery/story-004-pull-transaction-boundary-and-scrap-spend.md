# Story 004: Pull Transaction Boundary And Scrap Spend

> **Epic**: Hatchery
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/hatchery.md`
**Requirement**: `TR-hatch-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Save Transaction Boundary; ADR-0009: Economy And Shop Transaction Boundaries; ADR-0012: Hatchery Pull Transaction And RNG Boundaries
**ADR Decision Summary**: `HatcheryService.execute_pull()` opens one SaveTransaction, spends Scraps through EconomyLedger, stages resolver output plus pity/drought data, and commits or rolls back as one unit. This story implements the transaction-shell slice of `TR-hatch-002`: its observable outcome is a returned pending `HatcheryPullResolutionResult`, while dragon creation, duplicate XP, and post-commit events are completed by Stories 005-006 before the full pull settlement requirement is closed.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Verify transaction staging, rollback under save failure injection, and no direct file or SaveData mutation from Hatchery.

**Control Manifest Rules (this layer)**:
- Required: CM-HATCH-01, CM-HATCH-02, CM-HATCH-03, CM-GLOB-01, CM-GLOB-10
- Forbidden: UI code spending Scraps, rolling RNG, mutating pity counters, or writing save files directly
- Guardrail: Pull execution is transaction-bound and must not leave partial spend/resolver/counter state. Story 004 verifies the spend, deterministic RNG seam, resolver output, pity/drought staging, and rollback behavior; Stories 005-006 extend the same boundary to apply dragon/XP results and publish post-commit events.

---

## Acceptance Criteria

*From GDD `design/gdd/hatchery.md`, scoped to this story:*

- [x] AC-H01: A pull with balance >=50 Scraps deducts exactly 50 Scraps, resolves one deterministic pending `HatcheryPullResolutionResult` with final element, rarity, shiny, and next counter data, and returns a named success result. Dragon ownership and duplicate XP remain unchanged in this story.
- [x] AC-H02: A pull with balance <50 Scraps neither deducts Scraps, consumes RNG/resolver rolls, stages pity/drought changes, nor produces a pending outcome result.
- [x] AC-H03: Post-pull balance equals pre-pull balance minus 50.
- [x] AC-H11: The Rare+ pity counter is written to save data after each pull and reloads with the exact saved value.
- [x] AC-H27: If save commit fails after Scrap spend, resolver output, and counter mutations are staged but before the canonical save swap, the player's balance and counters reload at their pre-pull values and the failure result exposes no committed outcome.
- [x] AC-H37: All six element drought counters are written to save data atomically with each pull and reload exactly.
- [x] Hatchery never mutates `player_scraps` directly; it uses EconomyLedger inside a SaveTransaction.

## Implementation Notes

Implement `HatcheryService.execute_pull()` as the transaction boundary for pull settlement. This story can stage the selected resolver output and pity/drought counters but does not create or update dragons yet; Story 005 completes outcome application inside the same boundary, and Story 006 adds post-commit events. Keep failed affordability checks outside transaction mutation, return named result failures, and do not consume RNG on insufficient funds.

Integration observation surface for this story:
- Success returns a typed pending `HatcheryPullResolutionResult` carrying `final_element`, `final_rarity`, `shiny`, pity/soft-pity flags, and next counter values.
- Canonical save after Story 004 success contains the Scrap spend plus persisted pity/drought counters only; dragon ownership, duplicate XP, and hatch/progression events remain unchanged until Stories 005-006.
- Rollback tests inspect canonical save reload and the returned failure result; no durable pending-outcome save field is created by this story.

Performance: no repeated save I/O during simulation; production execution opens exactly one transaction per confirmed pull.

## Out of Scope

- Dragon creation and duplicate XP application: Story 005.
- Post-commit event publication: Story 006.
- UI button state and confirmation flow: Story 007.

## QA Test Cases

- **AC-1**: Successful exact spend
  - Given: a save with 50 Scraps and deterministic pull outcome
  - When: `execute_pull()` runs
  - Then: committed balance is 0, persisted pity/drought counters match the returned next values, and one pending resolver outcome result is returned
  - Edge cases: balance above 50 preserves exact remainder
- **AC-2**: Insufficient Scraps
  - Given: a save with 49 Scraps
  - When: `execute_pull()` runs
  - Then: no Scrap deduction, no RNG/resolver consumption, no pity/drought mutation, no pending outcome result, and a named insufficient-funds result returns
  - Edge cases: balance 0 behaves the same way
- **AC-3**: Balance arithmetic
  - Given: balances 50, 51, and 999+
  - When: pulls succeed
  - Then: post-pull balance is exactly pre-pull minus 50
  - Edge cases: no display cap changes underlying balance
- **AC-4**: Pity counter persistence
  - Given: a pull that sets pity counter to 7
  - When: save commits and reloads
  - Then: loaded pity counter is exactly 7
  - Edge cases: Rare result reloads counter at 0
- **AC-5**: Save failure rollback
  - Given: failure injection after staged Scrap spend, resolver output, and pity/drought mutation but before canonical save swap
  - When: commit fails
  - Then: canonical save reloads with pre-pull balance and pre-pull pity/drought counters, while the failure result exposes no committed outcome
  - Edge cases: temp/backup artifacts do not become canonical state
- **AC-6**: Drought counter persistence
  - Given: staged counters such as Fire 7 and Stone 19
  - When: save commits and reloads
  - Then: all six counters match exactly
  - Edge cases: missing one counter rejects or repairs before commit, according to Save contract
- **AC-7**: Economy boundary
  - Given: Hatchery executes a pull
  - When: code path is inspected in tests/review
  - Then: `player_scraps` mutation happens through EconomyLedger in the staged transaction only
  - Edge cases: preview does not mutate Scraps

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/hatchery/test_pull_transaction_boundary_and_scrap_spend.gd`

**Status**: [x] Created - focused HATCHERY-004 integration suite passed with 8/8 tests and 154 assertions after code-review fixes; Hatchery unit/integration slice passed with 34/34 tests and 10,640 assertions; full unit/integration suite passed with 191/191 tests and 18,322 assertions.

## Dependencies

- Depends on: Story 001, Story 002, Story 003, Economy Ledger Story 002, Save / Persistence transaction foundation
- Unlocks: Story 005, Story 006

## Completion Notes

**Completed**: 2026-05-28
**Criteria**: 7/7 passing.
**Deviations**: None blocking. QA coverage gate returned GAPS as advisory: rollback proves canonical state and returned result, but does not directly inspect the temp/staged save to prove every staged intermediate value; EconomyLedger-in-SaveTransaction is inferred from rollback behavior plus source guard; duplicate XP unchanged is covered by no dragon roster mutation in this story's current save surface.
**Test Evidence**: Integration test at `tests/integration/hatchery/test_pull_transaction_boundary_and_scrap_spend.gd`; focused HATCHERY-004 suite passed with 8/8 tests and 154 assertions; Hatchery unit/integration slice passed with 34/34 tests and 10,640 assertions; full unit/integration suite passed with 191/191 tests and 18,322 assertions.
**Code Review**: Complete - `/code-review` approved with suggestions; LP-CODE-REVIEW PASS; QL-TEST-COVERAGE GAPS accepted as advisory.
