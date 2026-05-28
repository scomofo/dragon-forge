# Story 003: Element Soft Pity Resolution

> **Epic**: Hatchery
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/hatchery.md`
**Requirement**: `TR-hatch-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: Hatchery Pull Transaction And RNG Boundaries
**ADR Decision Summary**: Hatchery owns element drought counters, deterministic RNG seams, and captured roll results. For AC-H30-H38, the current Hatchery GDD Rule 4b is the source of truth for priority order: guaranteed element threshold first, Rare+ pity with Rule 4's natural-Rare check second, ramp draw third.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Ordinary GDScript service logic; no engine-specific APIs beyond typed data classes and injected RNG.

**Control Manifest Rules (this layer)**:
- Required: CM-HATCH-02, CM-HATCH-03
- Forbidden: UI-owned pity mutation or hidden global RNG state
- Guardrail: Soft-pity resolution must stay O(standard element count) and deterministic for tests.

---

## Acceptance Criteria

*From GDD `design/gdd/hatchery.md`, scoped to this story:*

- [x] AC-H30: With `drought[Stone] = 39`, a pull is not forced to Stone; the ramp draw executes.
- [x] AC-H31: With `drought[Stone] = 40`, the next pull is forced to Stone regardless of natural draw.
- [x] AC-H32: After any Stone pull, `drought[Stone] = 0` and each other standard element drought counter increments by 1.
- [x] AC-H33: With `drought[Storm] = 42` and `drought[Venom] = 40`, Storm is forced; Venom increments to 41, remains above the guaranteed threshold, and can trigger next pull.
- [x] AC-H34: Soft-pity-forced Shadow resets Rare+ pity to 0; soft-pity-forced Stone increments Rare+ pity by 1.
- [x] AC-H35: With `drought[Stone] = 40` and `pityCounter = 9`, the guaranteed element threshold forces Stone first, increments pity to 10, and the next pull fires Rare+ pity unless another element guarantee takes priority.
- [x] AC-H36: Over 10,000 independent simulated pulls with `drought[Stone]` held/reset to 30 for each trial and other counters below onset, Stone appears in 35%-45% of pulls.
- [x] AC-H37: Every successful resolver result returns a complete `next_drought_counters` set for all six standard elements so Story 004 can stage them atomically.
- [x] AC-H38: Over 10,000 simulated pulls from `pityCounter = 0`, Shadow drought never reaches soft-pity onset 20.

## Implementation Notes

Build on Story 002's pure resolver. Add a drought-counter projection and element soft-pity layer that follows Hatchery GDD Rule 4b exactly: first resolve any guaranteed element threshold, then run Rule 4's natural-Rare check before applying Rare+ pity if no element guarantee fired, then apply ramp-adjusted element weights only if neither guarantee nor Rare+ pity fired. Use the GDD tie-break priority order for simultaneous element guarantees: Fire, Ice, Shadow, Stone, Storm, Venom. Return complete next drought counters as values for Story 004 to stage atomically.

Performance: no per-frame work. Simulation tests may run 10,000 pulls but production resolution is one bounded pass over six elements.

## Out of Scope

- Save/load persistence of drought counters: Story 004.
- Dragon creation and duplicate outcomes after an element is selected: Story 005.
- UI display of counters: forbidden by GDD fantasy/optimization note.

## QA Test Cases

- **AC-1**: Below guarantee uses ramp
  - Given: `drought[Stone] = 39` and scripted rolls
  - When: a pull resolves
  - Then: Stone is not guaranteed; the ramp-adjusted draw determines the result
  - Edge cases: scripted draw can still naturally/ramp select Stone
- **AC-2**: Guarantee threshold
  - Given: `drought[Stone] = 40`
  - When: a pull resolves
  - Then: final element is Stone regardless of natural roll
  - Edge cases: natural Shadow does not override element guarantee
- **AC-3**: Drought update
  - Given: a final Stone result
  - When: next drought counters are calculated
  - Then: Stone is 0 and Fire/Ice/Storm/Venom/Shadow each increment by 1
  - Edge cases: natural, ramp, and guaranteed Stone all update the same way
- **AC-4**: Highest counter and tie priority
  - Given: Storm at 42 and Venom at 40
  - When: guarantee resolution runs
  - Then: Storm is forced and Venom remains eligible for the next pull
  - Edge cases: equal counters use Fire, Ice, Shadow, Stone, Storm, Venom priority
- **AC-5**: Soft-pity affects Rare+ pity
  - Given: forced Shadow and forced Stone scenarios
  - When: next pity counter is calculated
  - Then: Shadow resets Rare+ pity to 0; Stone increments it by 1
  - Edge cases: forced Fire/Ice/Storm/Venom also increment
- **AC-6**: Soft-pity outranks Rare+ pity
  - Given: `drought[Stone] = 40` and `pityCounter = 9`
  - When: current and next pull resolve
  - Then: current pull forces Stone and increments pity; next pull forces Shadow if no element guarantee outranks it
  - Edge cases: another element at guarantee can still outrank Rare+ pity on the next pull
- **AC-7**: Ramp expected value
  - Given: `drought[Stone] = 30` held/reset for each independent trial, other counters below onset, and 10,000 fixed-seed pulls
  - When: ramp probabilities are applied
  - Then: Stone appears in 35%-45% of pulls
  - Edge cases: total probabilities renormalize to 1.0
- **AC-8**: Counter staging surface
  - Given: next drought counters are returned by the resolver
  - When: a pull result is successful
  - Then: all six standard element counters are present as one complete result set for Story 004 to stage atomically
  - Edge cases: missing counters return a named resolver failure before Story 004 attempts commit
- **AC-9**: Shadow drought unreachable
  - Given: a 10,000-pull simulation from `pityCounter = 0`
  - When: Rare+ pity is active
  - Then: max observed Shadow drought is <= 9
  - Edge cases: soft-pity onset remains 20

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/hatchery/test_element_soft_pity_resolution.gd`

**Status**: [x] Created - focused HATCHERY-003 unit suite passed with 11/11 tests and 10,236 assertions; Story 002 compatibility suite passed with 7/7 tests and 141 assertions; Hatchery unit slice passed with 26/26 tests and 10,486 assertions; full unit/integration suite passed with 183/183 tests and 18,168 assertions.

## Dependencies

- Depends on: Story 001, Story 002
- Unlocks: Story 004

## Completion Notes

**Completed**: 2026-05-28
**Criteria**: 9/9 passing.
**Deviations**: None blocking. Scope note: GDD AC-H37's full save/load persistence wording remains owned by Story 004; this story completes the resolver-side `next_drought_counters` result surface for atomic staging.
**Test Evidence**: Logic unit test at `tests/unit/hatchery/test_element_soft_pity_resolution.gd`; focused HATCHERY-003 suite passed with 11/11 tests and 10,236 assertions; Story 002 compatibility suite passed with 7/7 tests and 141 assertions; Hatchery unit slice passed with 26/26 tests and 10,486 assertions; full unit/integration suite passed with 183/183 tests and 18,168 assertions.
**Code Review**: Complete - `/code-review` rerun approved; QL-TEST-COVERAGE verdict ADEQUATE; LP-CODE-REVIEW verdict PASS.
