# ADR-0010: Progression/unlocks derive deterministically from save state (single source of truth)

## Status

Accepted

## Date

2026-06-16

## Last Verified

2026-06-16

## Decision Makers

Reverse-documented from implementation

## Summary

Dragon Forge needs to answer "is this content unlocked?", "what corruption stage
is the world in?", and "where should the player go next?" without those answers
ever drifting out of sync with what the player has actually done. The decision —
already shipped — is that the save object stores only primitive *facts* (which
dragons are `owned`, which NPC IDs are in `defeatedNpcs`, dragon `level`, the
`singularityComplete` boolean) and every derived progression/unlock/stage/guidance
value is computed as a pure function of that save on read, never persisted.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React 18 + Vite (browser build) |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — pure-JS derivation, no engine-version-specific APIs |
| **References Consulted** | `src/singularityProgress.js`, `src/playerGuidance.js`, `src/persistence.js`, `src/App.jsx` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Reliable cross-screen guidance (`getPlayerGuidance`), corruption-stage theming, save-version forward compat (derived values need no migration) |
| **Blocks** | None |
| **Ordering Note** | Foundational for any system that gates content on prior progress; new gated features should follow this pattern rather than introducing persisted derived flags. |

## Context

### Problem Statement

A collection/progression RPG must repeatedly decide what the player has unlocked
(can they enter the Singularity? has the forge opened?), what global state the
world is in (which of six corruption stages is active), and what the player
should do next (the on-screen guidance prompt). If any of these answers are
*stored* alongside the underlying facts, they can disagree with reality — a save
that says `singularityUnlocked: true` but whose `defeatedNpcs` list does not
contain the gate boss is a corrupt, hard-to-debug state. The cost of not deciding
is a class of bugs where unlock flags, stage counters, and the actual record of
player actions slowly diverge across patches and migrations.

### Current State

The save object is the single central data structure (loaded once from
`localStorage` key `dragonforge_save`, passed to every screen — see CLAUDE.md and
`persistence.js`). The shipped implementation persists only *primitive facts*:

- Per-dragon: `owned`, `discovered`, `level`, `xp`, `shiny`, `fusedBaseStats`
  (`persistence.js:10-18`).
- Event records: `defeatedNpcs: []`, `remnantDefeated: []`,
  `singularityProgress.defeated: []`, `singularityProgress.replayCounts: {}`
  (`persistence.js:23-27`).
- Terminal milestone booleans: `singularityComplete`, `mirrorAdminDefeated`
  (`persistence.js:25-26`), and `flags.fragmentsUnlocked: []` (`persistence.js:41`).

Crucially, the `DEFAULT_SAVE` schema contains **no** `singularityStage`,
`singularityUnlocked`, `forgeReady`, `fusionReady`, or `guidance` field. Every
such value is recomputed on demand:

- `getSingularityStage(save)` derives the 0–5 corruption stage purely from owned
  base-element count, whether any owned dragon is level ≥ 50, and whether the four
  base NPC IDs are all in `defeatedNpcs` (`singularityProgress.js:16-29`).
- `isSingularityUnlocked(save)` is a one-line predicate: `singularityComplete ||
  defeatedNpcs.includes('protocol_vulture')` (`singularityProgress.js:31-35`).
- `getRemnantProgress(save)` derives `{ available, defeated, allDefeated }` from
  `singularityComplete` and `remnantDefeated` (`singularityProgress.js:37-45`).
- `getPlayerGuidance(save)` derives the single next-step prompt via an ordered
  cascade of predicates over the same facts (`playerGuidance.js:9-106`).

Consumers read these on the fly. `App.jsx:48` calls `getSingularityStage(save)`
each render and applies the result directly as a CSS class:
`className={`app${stage >= 2 ? ` corruption-stage-${stage}` : ''}`}`
(`App.jsx:190`). There is no cached stage variable in the save.

There is nothing "wrong" with the current approach — this ADR documents it so the
pattern is explicit and future systems conform to it rather than re-introducing
persisted derived state.

### Constraints

- **Single save object**: all screens share one `save` loaded from `localStorage`;
  mutations go through persistence helpers followed by `refreshSave()` (CLAUDE.md).
  Derived values must therefore be cheap enough to recompute after every refresh.
- **Forward compatibility**: `migrateSave` must keep old saves loadable
  (`persistence.js:90-132`). Persisted derived fields would each need their own
  migration and back-fill logic; derived-on-read values need none.
- **No server**: this is a client-only browser game; there is no authoritative
  backend to reconcile against, so the local fact set must *be* the authority.
- **Two builds**: the Godot runtime re-implements the same simulation; keeping the
  rules as pure predicates over a plain data object makes them portable to GDScript
  (`scripts/sim/`).

### Requirements

- Unlock/stage/guidance answers must never contradict the recorded facts.
- Adding a new gated feature must not require a save-schema field or a migration.
- Derivation must be unit-testable without React, DOM, or `localStorage` (the
  test env is `node`, no jsdom — CLAUDE.md).
- Recompute cost must be negligible at render frequency (it runs on every
  `App` render).

## Decision

Persist only the minimal set of primitive facts that record what the player has
done; derive every progression, unlock, world-stage, and guidance value as a
**pure function of the save object**, computed on read and never written back.

The save is the single source of truth. Derived state is a *view* over it.

### Architecture

```
                 localStorage: "dragonforge_save"
                              |
                    load once (persistence.js)
                              v
        +----------------------------------------------+
        |              save object (FACTS)             |
        |  dragons[].owned / .level                    |
        |  defeatedNpcs[]  remnantDefeated[]           |
        |  singularityComplete  mirrorAdminDefeated    |
        |  singularityProgress.{defeated,replayCounts} |
        |  flags.fragmentsUnlocked[]                   |
        +----------------------------------------------+
              |            |            |            |
   pure fns   v            v            v            v
   (no writes) getSingularityStage   isSingularityUnlocked
               getRemnantProgress    getPlayerGuidance
               scaleBossForPlayer
              |            |            |            |
              v            v            v            v
        corruption-   gate access   post-game     next-step
        stage CSS     to screen     remnant arc   prompt
        (App.jsx)     (NavBar/      (Singularity  (NavBar/
                       App)          Screen)       guidance UI)

   Mutation path:  screen -> persistence helper -> refreshSave()
                   (writes FACTS only; derived fns re-run on next read)
```

### Key Interfaces

```js
// All take the whole save (a plain data object) and return a fresh value.
// None mutate the save; none read or write localStorage; none are memoized.

getSingularityStage(save) -> number        // 0..5, derived from facts
isSingularityUnlocked(save) -> boolean      // single predicate over facts
getRemnantProgress(save) -> { available: boolean,
                              defeated: string[],
                              allDefeated: boolean }
getPlayerGuidance(save) -> { target: string,   // screen enum
                             action: string,    // CTA label
                             title: string } | null
scaleBossForPlayer(boss, save) -> Boss         // derives encounter from player facts
```

Contract for all derivation functions:

1. **Pure**: output depends only on the passed `save` (and any imported static
   data tables); no `Date.now()`, no RNG, no global mutable read.
2. **Read-only**: never mutate `save` and never call a persistence/storage helper.
3. **Total**: defensively default missing fields (e.g.
   `save.defeatedNpcs || []`, `Array.isArray(save.remnantDefeated) ? ... : []`)
   so an older or partial save still derives a sane value.

### Implementation Guidelines

- When adding a gated feature, ask "what *fact* records that the gate is passed?"
  Store that fact (a boolean, or push an ID into an existing list); write a
  predicate that reads it. Do **not** add an `xUnlocked` field to the save.
- Keep derivation in the `*Progress.js` / guidance modules, not inside React
  components, so it stays testable in the `node` env and portable to the Godot
  `scripts/sim/` layer.
- Order guidance predicates from most-terminal to least (the shipped cascade
  checks `mirrorAdminDefeated` and `singularityComplete` first, then onboarding
  states) so the single returned prompt is always the highest-priority next step
  (`playerGuidance.js:12-104`).
- If a derivation becomes expensive, memoize at the *call site* (e.g. `useMemo`
  keyed on the save) rather than persisting the result.

## Alternatives Considered

### Alternative 1: Persist derived flags alongside facts

- **Description**: Store `singularityUnlocked`, `singularityStage`,
  `forgeReady`, etc. directly in the save, written at the moment the triggering
  event occurs.
- **Pros**: Reads are a single field lookup; no recompute cost; the unlock moment
  is an explicit event you can hook (e.g. to fire a "new content!" toast).
- **Cons**: Two representations of the same truth that can diverge; every flag
  needs a `migrateSave` back-fill for existing saves; a missed write or a reorder
  during refactor silently corrupts unlock state; balance/tuning changes to the
  *rule* (e.g. moving the elder threshold off level 50) don't retroactively apply
  to saves that already cached the old answer.
- **Estimated Effort**: Higher (each flag = write site + migration + back-fill).
- **Rejection Reason**: Reintroduces exactly the drift this decision exists to
  prevent; the save schema deliberately contains none of these fields
  (`persistence.js` `DEFAULT_SAVE`).

### Alternative 2: Derive into a cached/observable progression store at load time

- **Description**: On load, compute all derived state once into a separate
  in-memory store (or React context/reducer) and invalidate it on mutation.
- **Pros**: Single computation per change; ergonomic selectors; can centralize
  unlock-transition side effects.
- **Cons**: Adds a cache-invalidation surface — the store must be re-derived on
  *every* mutation path, and the existing `refreshSave()` model already re-reads
  the whole save, so a parallel cache is redundant complexity; harder to unit-test
  than free functions; couples logic to a React-specific store, hurting Godot
  portability.
- **Estimated Effort**: Comparable to higher.
- **Rejection Reason**: The pure-function-over-save model already gives correctness
  for free at trivial cost; a cache buys nothing measurable here and adds an
  invalidation failure mode.

### Alternative 3: Server-authoritative progression

- **Description**: A backend owns progression state and the client asks it what is
  unlocked.
- **Pros**: Tamper-resistant; cross-device sync.
- **Cons**: Requires infrastructure the project does not have; adds latency and an
  offline-failure mode to what is a single-player, client-only browser game.
- **Estimated Effort**: Far higher (new service, auth, hosting).
- **Rejection Reason**: Out of scope for a client-only indie title; no requirement
  for anti-cheat or sync.

## Consequences

### Positive

- **No drift possible**: unlock/stage/guidance answers are always consistent with
  the recorded facts because they are computed from them every time.
- **Migration-light**: new gated content rarely touches the schema; derived values
  need no `migrateSave` entry. Existing migrations only ever add *facts*
  (`persistence.js:90-132`).
- **Cheap, isolated testing**: derivation functions are tested as plain
  input/output with hand-built save objects, no mocks, no DOM
  (`playerGuidance.test.js` builds plain saves and asserts the returned prompt).
- **Tuning is retroactive**: changing a rule (e.g. the elder threshold or the gate
  boss ID) instantly applies to all existing saves, since nothing cached the old
  result.
- **Portable**: the rules are pure data predicates, mirroring cleanly into the
  Godot `scripts/sim/` modules.

### Negative

- **Recompute on every read**: e.g. `getSingularityStage` runs each `App` render.
  Cost is tiny (a few array filters over ≤9 dragons / ≤4 IDs) but non-zero, and a
  future heavyweight derivation would need call-site memoization.
- **No built-in "unlock moment" hook**: because nothing is written when a gate
  opens, anything that should fire *at the transition* (a fanfare, an analytics
  event) must detect the edge separately rather than reading a freshly-set flag.

### Neutral

- The save schema is intentionally "thin" — readers must call the derivation
  helpers rather than reading a field, so onboarding a contributor means pointing
  them at `singularityProgress.js` / `playerGuidance.js` as the canonical answers.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| A contributor persists a derived flag for convenience, reintroducing drift | Medium | Medium | This ADR + code review; keep `DEFAULT_SAVE` as the audited schema with no derived fields |
| A derivation reads a field a stale save lacks and throws | Low | Medium | All shipped fns defensively default missing fields; keep that convention; `migrateSave` back-fills fact arrays |
| Derivation cost grows as more rules are added to the render path | Low | Low | Memoize at call site (`useMemo` keyed on save) before persisting anything |
| Rule change silently alters many players' unlock state (because derivation is retroactive) | Low | Medium | Treat threshold/ID changes in derivation fns as balance changes; verify against representative saves before shipping |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | n/a (as-built) | < 0.05 ms per derivation call (array filters over ≤9 dragons / ≤4 NPC IDs) | < 16 ms total frame |
| Memory | n/a | No persisted derived state; transient objects only | No measurable save-size growth |
| Load Time | n/a | No effect — derivation is on read, not load | No regression |
| Network (if applicable) | n/a | None (client-only) | n/a |

## Migration Plan

Not applicable — this ADR documents the as-shipped design; nothing changes. For
*future* gated features that follow this pattern:

1. Identify the primitive fact that records the gate being passed (a boolean or an
   ID pushed into an existing list); add it to `DEFAULT_SAVE` and `migrateSave`
   if it is genuinely new.
2. Write a pure predicate over the save in the appropriate `*Progress.js` /
   guidance module; do not add a derived field to the schema.
3. Verify with a unit test that builds plain save objects and asserts the derived
   output (mirror `playerGuidance.test.js`).

**Rollback plan**: There is nothing to roll back. If a specific derivation proves
too costly, memoize it at the call site; do not persist its result.

## Validation Criteria

- [x] `DEFAULT_SAVE` contains no `singularityStage` / `*Unlocked` / `guidance`
      field — only primitive facts (`persistence.js:9-41`).
- [x] World stage is computed and applied on read, not stored
      (`App.jsx:48`, `App.jsx:190`).
- [x] Unlock and guidance logic are pure functions of the save, tested with
      hand-built saves and no mocks (`playerGuidance.test.js`).
- [x] All derivation functions defensively default missing save fields, so older
      saves derive sane values (`singularityProgress.js:18,20,33,39`;
      `playerGuidance.js:5-6,40,55-56`).
- [ ] New gated features added after this ADR introduce no persisted derived
      flags (audited at code review).

## GDD Requirements Addressed

<!-- This section is MANDATORY. Every ADR must trace back to at least one GDD
     requirement, or explicitly state it is a foundational decision with no GDD
     dependency. Traceability is audited by /architecture-review. -->

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/singularity-endgame.md` | Singularity endgame | The endgame must advance through escalating corruption stages and gate access to the Singularity behind specific prior progress | `getSingularityStage` derives the 0–5 stage and `isSingularityUnlocked` gates entry, both as pure functions of owned dragons / `defeatedNpcs` / `singularityComplete` — stage and gate can never disagree with recorded progress (`singularityProgress.js:16-35`) |
| `design/gdd/player-guidance-and-onboarding.md` | Player guidance & onboarding | The game must always surface a single, correct "what to do next" prompt appropriate to the player's exact progress | `getPlayerGuidance` returns one prioritized next-step prompt derived entirely from the current save via an ordered predicate cascade (`playerGuidance.js:9-106`) |

## Related

- ADR (this) documents the data-flow contract that `getPlayerGuidance`,
  `getSingularityStage`, `isSingularityUnlocked`, and `getRemnantProgress` all
  obey.
- Code: `src/singularityProgress.js`, `src/playerGuidance.js`,
  `src/persistence.js` (`DEFAULT_SAVE` / `migrateSave`), `src/App.jsx`
  (stage consumption), `src/playerGuidance.test.js`.
- Builds on the single-save-object architecture described in `CLAUDE.md`
  (load-once, mutate-via-helpers, `refreshSave()`).
