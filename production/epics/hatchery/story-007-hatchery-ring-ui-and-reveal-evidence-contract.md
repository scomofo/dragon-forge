# Story 007: Hatchery Ring UI And Reveal Evidence Contract

> **Epic**: Hatchery
> **Status**: Blocked
> **Layer**: Core
> **Type**: UI
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**:

## Context

**GDD**: `design/gdd/hatchery.md`
**Requirement**: `TR-hatch-001`, `TR-hatch-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: Hatchery Pull Transaction And RNG Boundaries
**ADR Decision Summary**: UI may request previews and execute pulls through HatcheryService, but must not own Scrap spend, RNG, pity mutation, or dragon mutation. Presentation evidence must prove reveal/readability behavior without becoming durable authority.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Blocked until production Hatchery UI/screen work is scheduled with Hub/Scene Flow and presentation assets.

**Control Manifest Rules (this layer)**:
- Required: CM-HATCH-01, CM-RENDER-06
- Forbidden: UI code spending Scraps, rolling RNG, mutating pity counters, or using audio/animation completion as durable authority
- Guardrail: Reduced-motion and non-color element cues are required for reveal evidence.

---

## Acceptance Criteria

*From GDD `design/gdd/hatchery.md`, scoped to this story:*

- [ ] Hatchery Ring screen shows Scrap balance at all times and updates after committed pulls.
- [ ] Pull button has AVAILABLE, DISABLED, and CONFIRMING states; balance <50 Scraps disables pulls without executing an outcome.
- [ ] Pity counters are not displayed to the player.
- [ ] Result screen distinguishes new dragon, duplicate XP, level-up, and shiny upgrade outcomes from typed Hatchery result payloads.
- [ ] Pull animation phases IDLE, ANIMATING, RESOLVING, RESULT_SHOWN, and RETURNING have visual/audio evidence or documented placeholders.
- [ ] Element reveal uses color plus distinct shape/pattern cues, not color alone.
- [ ] Shiny reveal includes a visible burst and persistent shimmer marker in result presentation.
- [ ] Reduced-motion mode can skip directly to result without changing pull outcome or durable state.

## Implementation Notes

This is a future presentation contract story and is blocked until the service stories exist and production Hatchery UI/screen work is scheduled. The UI calls `preview_pull()` and `execute_pull()` only; it never reproduces pull math or durable mutation. Evidence should be captured in `production/qa/evidence/hatchery-ui-reveal-evidence.md`.

## Out of Scope

- Core Hatchery service contracts and RNG math: Stories 001-003.
- Transactional pull settlement: Stories 004-006.
- Final production dragon art and audio library authoring beyond evidence placeholders.
- Post-collection narrative framing for OQ-H03.

## QA Test Cases

- **Manual check AC-1**: Ring screen state
  - Setup: open Hatchery with balances 49, 50, and 100 Scraps
  - Verify: balance is visible; button states match DISABLED/AVAILABLE/CONFIRMING rules
  - Pass condition: insufficient balance cannot execute `execute_pull()`
- **Manual check AC-2**: Pity hidden
  - Setup: inspect Hatchery UI with varied pity/drought counter fixture values
  - Verify: no pity counter, drought counter, or optimization-facing hidden probability is shown
  - Pass condition: UI preserves the GDD "who is coming" fantasy and does not expose counters
- **Manual check AC-3**: Result types
  - Setup: force new dragon, duplicate XP, level-up, shiny upgrade, and all-owned duplicate outcomes
  - Verify: result screen displays the correct outcome from typed payloads
  - Pass condition: no UI-side outcome inference duplicates service logic
- **Manual check AC-4**: Reveal phases and accessibility
  - Setup: run a pull in default and reduced-motion modes for each standard element
  - Verify: animation phases, non-color element cues, shiny marker, and instant-resolve behavior are evident
  - Pass condition: evidence includes screenshots or clips plus sign-off notes

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/hatchery-ui-reveal-evidence.md`

**Status**: [ ] Not yet created - blocked until Hatchery service stories and production Hatchery UI/screen work exist

## Dependencies

- Depends on: Stories 001-006, production Hatchery screen, Hub/Scene Flow entry path, Audio/Art placeholder assets
- Unlocks: Hatchery presentation acceptance and player-facing pull flow
