# Story 006: Post Commit Events And Preview Contract

> **Epic**: Hatchery
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 0.75 day
> **Manifest Version**: 2026-05-26
> **Last Updated**:

## Context

**GDD**: `design/gdd/hatchery.md`
**Requirement**: `TR-hatch-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Save Transaction Boundary; ADR-0012: Hatchery Pull Transaction And RNG Boundaries
**ADR Decision Summary**: Hatchery captures pull results for QA and presentation, while hatch and progression events publish only after Save / Persistence commit succeeds.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Use callable signal connections and typed payload classes; missing listeners must not block commit or gameplay progression.

**Control Manifest Rules (this layer)**:
- Required: CM-GLOB-02, CM-GLOB-04, CM-HATCH-01, CM-HATCH-03
- Forbidden: Emitting committed hatch/dragon/progression events before save commit success
- Guardrail: Preview is read-only and must not consume RNG, spend Scraps, or mutate pity counters.

---

## Acceptance Criteria

*From GDD `design/gdd/hatchery.md` and ADR-0012, scoped to this story:*

- [ ] `preview_pull(snapshot, pull_id)` reports cost/eligibility from a save snapshot without mutating Scraps, pity counters, drought counters, dragons, or RNG state.
- [ ] `HatcheryPullResult` captures final element, rarity, shiny result, duplicate/new outcome type, XP grant, pity force state, soft-pity force state, and next pity/drought values for QA evidence.
- [ ] Hatch/new-dragon, duplicate-XP, shiny-upgrade, and collection-progress events are queued during transaction mutation and publish only after commit success.
- [ ] Failed commit publishes no hatch result or dragon progression events.
- [ ] Missing event listeners do not block a successful pull.
- [ ] Pull result payloads carry stable IDs and never use display text as logic keys.

## Implementation Notes

This story wires the read-only preview and post-commit publication surface after Stories 004-005 establish the transaction and outcome application. Keep presentation events semantic and typed. Do not implement UI animation, audio playback, or player-facing result screens here.

Performance: preview must be O(1) or bounded by validated pull table size and must not allocate or mutate transaction state.

## Out of Scope

- Pull UI, result screen, animations, and sound playback: Story 007.
- Final collection narrative beat: open GDD question OQ-H03.
- External Audio Director implementation: Audio epic.

## QA Test Cases

- **AC-1**: Preview read-only
  - Given: a save snapshot with Scraps, pity counters, drought counters, and dragons
  - When: `preview_pull()` is called
  - Then: it reports cost/eligibility without changing snapshot data or RNG state
  - Edge cases: insufficient Scraps preview returns unavailable without mutation
- **AC-2**: Result payload completeness
  - Given: new, duplicate, shiny, pity-forced, and soft-pity-forced outcomes
  - When: pull results are inspected
  - Then: typed fields expose final element, rarity, shiny, outcome type, XP grant, pity force, soft-pity force, and next counters
  - Edge cases: failure results still carry named reasons
- **AC-3**: Commit-before-emit
  - Given: a successful pull transaction
  - When: commit succeeds
  - Then: hatch and progression events publish after commit and include stable IDs
  - Edge cases: duplicate XP progression events preserve Dragon Progression ordering
- **AC-4**: Failed commit suppresses events
  - Given: save failure injection during pull commit
  - When: commit fails
  - Then: no hatch, shiny, duplicate, or dragon progression event publishes
  - Edge cases: result reports rollback/failure reason
- **AC-5**: Missing listeners
  - Given: no listeners connected to hatch events
  - When: a pull commits
  - Then: the pull still succeeds and returns the same result
  - Edge cases: one failing optional presentation listener cannot mutate durable state
- **AC-6**: Stable IDs
  - Given: a result payload
  - When: fields are inspected
  - Then: element, rarity, pull, and event keys are `StringName`/stable IDs, not localized display text
  - Edge cases: display names belong in later UI/content layers

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/hatchery/test_post_commit_events_and_preview_contract.gd`

**Status**: [ ] Not yet created

## Dependencies

- Depends on: Story 004, Story 005, Semantic Events foundation story
- Unlocks: Story 007 and Hatchery UI integration
