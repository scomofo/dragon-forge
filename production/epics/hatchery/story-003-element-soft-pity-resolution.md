# Story 003: Element Soft Pity Resolution

> **Epic**: Hatchery
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**:

## Context

**GDD**: `design/gdd/hatchery.md`
**Requirement**: `TR-hatch-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: Hatchery Pull Transaction And RNG Boundaries
**ADR Decision Summary**: Hatchery owns element drought counters and resolves soft-pity before Rare+ pity, using deterministic tests and captured roll results.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Ordinary GDScript service logic; no engine-specific APIs beyond typed data classes and injected RNG.

**Control Manifest Rules (this layer)**:
- Required: CM-HATCH-02, CM-HATCH-03
- Forbidden: UI-owned pity mutation or hidden global RNG state
- Guardrail: Soft-pity resolution must stay O(standard element count) and deterministic for tests.

---

## Acceptance Criteria

*From GDD `design/gdd/hatchery.md`, scoped to this story:*

- [ ] AC-H30: With `drought[Stone] = 39`, a pull is not forced to Stone; the ramp draw executes.
- [ ] AC-H31: With `drought[Stone] = 40`, the next pull is forced to Stone regardless of natural draw.
- [ ] AC-H32: After any Stone pull, `drought[Stone] = 0` and each other standard element drought counter increments by 1.
- [ ] AC-H33: With `drought[Storm] = 42` and `drought[Venom] = 40`, Storm is forced; Venom remains at 40 and can trigger next pull.
- [ ] AC-H34: Soft-pity-forced Shadow resets Rare+ pity to 0; soft-pity-forced Stone increments Rare+ pity by 1.
- [ ] AC-H35: With `drought[Stone] = 40` and `pityCounter = 9`, soft-pity forces Stone first, increments pity to 10, and the next pull fires Rare+ pity unless another element guarantee takes priority.
- [ ] AC-H36: Over 10,000 simulated pulls with `drought[Stone] = 30` and other counters below onset, Stone appears in 35%-45% of pulls.
- [ ] AC-H37: All six element drought counters are staged for atomic save with each pull.
- [ ] AC-H38: Over 10,000 simulated pulls from `pityCounter = 0`, Shadow drought never reaches soft-pity onset 20.

## Implementation Notes

Build on Story 002's pure resolver. Add a drought-counter projection and soft-pity resolution layer that runs before Rare+ pity. Use the GDD tie-break priority order: Fire, Ice, Shadow, Stone, Storm, Venom. Return next drought counters as values for Story 004 to stage atomically.

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
  - Given: `drought[Stone] = 30`, other counters below onset, and 10,000 fixed-seed pulls
  - When: ramp probabilities are applied
  - Then: Stone appears in 35%-45% of pulls
  - Edge cases: total probabilities renormalize to 1.0
- **AC-8**: Counter staging surface
  - Given: next drought counters are returned by the resolver
  - When: Story 004 stages a pull
  - Then: all six counters can be written atomically as one result set
  - Edge cases: missing counters reject before commit
- **AC-9**: Shadow drought unreachable
  - Given: a 10,000-pull simulation from `pityCounter = 0`
  - When: Rare+ pity is active
  - Then: max observed Shadow drought is <= 9
  - Edge cases: soft-pity onset remains 20

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/hatchery/test_element_soft_pity_resolution.gd`

**Status**: [ ] Not yet created

## Dependencies

- Depends on: Story 001, Story 002
- Unlocks: Story 004
