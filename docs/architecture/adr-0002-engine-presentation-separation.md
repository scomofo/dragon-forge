# ADR-0002: Pure engine modules (`*Engine.js`) separated from React shells (`*Screen.jsx`)

## Status

Accepted

## Date

2026-06-16

## Last Verified

2026-06-16

## Decision Makers

Reverse-documented from implementation.

## Summary

Game simulation logic (combat resolution, fusion alchemy, gacha rolls) lives in
pure, framework-free `*Engine.js` modules that take plain data in and return plain
data out, while React `*Screen.jsx` components are thin shells that own all UI
state, DOM refs, animation, sound, and persistence side effects. The contract
between the two layers is a serializable result object — most importantly the
`events` array returned by `battleEngine.resolveTurn()` — which a third pure layer
(`battlePresentation.js`) classifies into display profiles, keeping balance/rules
testable in isolation and presentation swappable without touching simulation.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Browser build — React 18 + Vite |
| **Domain** | Core / Scripting (with UI and Animation as consumers) |
| **Knowledge Risk** | LOW — React 18, ES modules, and Vitest are all well within training data |
| **References Consulted** | `CLAUDE.md` (Engine vs. presentation separation), `vite.config.js` (test environment), `src/battleEngine.js`, `src/battlePresentation.js`, `src/BattleScreen.jsx` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — pattern is shipped and covered by Vitest suites |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | The GDScript port (`dragon-forge-godot/scripts/sim/`), which re-implements the same stateless-simulation boundary so two runtimes can share one balance model |
| **Blocks** | None |
| **Ordering Note** | This is a foundational pattern decision; new gameplay systems are expected to conform to it from inception rather than refactor into it later |

## Context

### Problem Statement

Dragon Forge is a turn-based dragon-collecting game whose value lives in its
*systems*: combat damage formulas, type effectiveness, status effects, NPC AI,
fusion alchemy, and gacha pull odds. These rules must be balanced precisely and
must not regress as content and VFX grow. At the same time, the game is a
heavily animated React app — every attack is a multi-phase choreography of
sprite telegraphs, GSAP timelines, hit-stop, screen shake, sound, and floating
damage numbers. If rules and rendering are interleaved in the same component, the
rules become impossible to unit-test (they only run inside an animating React
tree), and the rendering becomes impossible to change without risking a balance
regression. The decision of where to draw the line between "what the battle
*does*" and "what the battle *looks like*" had to be made up front because it
shapes every gameplay system that follows.

### Current State

The shipped codebase consistently splits each system into layers:

- **Pure logic** — `battleEngine.js`, `fusionEngine.js`, `hatcheryEngine.js`,
  plus `soundEngine.js`, `animationEngine.js`, `gamepadInput.js`. These export
  plain functions, hold no React state, and (for the rules engines) perform no
  DOM access. `battleEngine.resolveTurn(...)` returns
  `{ player, npc, events }` — new combatant state plus an ordered array of
  describing-what-happened event objects. `fusionEngine.executeFusion(...)`
  returns a plain fusion-result object. `hatcheryEngine.executePull(...)` returns
  a plain pull-result object.
- **Presentation mapping** — `battlePresentation.js` is a *pure* module that sits
  between the engine and the view. `classifyBattleEvent(event)` maps an engine
  event to a display kind (`miss`, `criticalHit`, `effectiveHit`, `ko`, `buff`,
  `charge`, ...); `getBattlePresentationProfile(event, move)` returns timing,
  shake intensity, flash colour, sprite CSS classes, and sound key for that kind.
  It has its own `battlePresentation.test.js`.
- **React shells** — `BattleScreen.jsx`, `FusionScreen.jsx`, `HatcheryScreen.jsx`,
  etc. These import the engines, own all `useState`/`useReducer` state, hold DOM
  `useRef`s, drive GSAP animations from `animationEngine.js`, call `playSound`/
  `playMusic`, and perform persistence side effects (`addDragonXp`, `addScraps`,
  `recordNpcDefeat`, ...). In `BattleScreen.jsx`, `handleMoveSelect` calls
  `resolveTurn(...)`, then iterates `result.events`, mapping each through
  `getBattlePresentationProfile` inside `animateEvent` to produce the on-screen
  choreography.

Every rules engine has a `.test.js` sibling (`battleEngine.test.js`,
`fusionEngine.test.js`, `hatcheryEngine.test.js`, `battlePresentation.test.js`)
that imports the module and asserts on its return values directly. The Vitest
environment is `node` (no jsdom — see `vite.config.js`), which is only possible
*because* the rules modules never touch the DOM.

### Constraints

- **No jsdom in the test harness** — the test environment is `node`; any module
  that is to be unit-tested must be pure JS with no `window`/DOM dependency.
- **Heavy animation coupling in the view** — battle choreography depends on GSAP,
  DOM refs, sprite canvases, and precise `await wait(...)` timing; this complexity
  is irreducible and must be quarantined away from rules.
- **Single-developer / indie velocity** — the boundary must be cheap to maintain
  by one person, not require a heavyweight architecture (no ECS, no event bus,
  no DI container).
- **Two-runtime future** — the Godot 4.6 build re-implements the same simulation
  in GDScript; a clean stateless-rules boundary is what makes that port a
  re-implementation of named functions rather than a rewrite of tangled UI logic.

### Requirements

- Combat math (damage, type chart, crit, status ticks, buff caps) must be unit
  tested without rendering anything.
- Adding or restyling VFX, sound, or animation timing must not require editing
  rules code, and must not be able to change combat outcomes.
- The same engine must be drivable by more than one caller (player input,
  AUTO-battle, and the mid-fight reserve-swap path all call `resolveTurn`/
  `pickNpcMove` in `BattleScreen.jsx`).
- Engine output must be serializable plain data so it can cross the
  logic→presentation boundary and, eventually, a second runtime.

## Decision

Adopt a three-layer separation for every gameplay system, enforced by file naming
and import direction:

1. **`*Engine.js` (pure rules)** — stateless functions that accept plain data and
   return plain data. No React, no DOM, no GSAP, no `localStorage`. RNG via
   `Math.random()` is permitted inside the engine (it is the system of record for
   outcomes), but the *result* is always returned as data, never rendered. For
   turn-based combat the canonical output is a `{ player, npc, events }` object
   where `events` is an ordered, fully-described log of what happened.

2. **`*Presentation.js` (pure mapping)** — stateless functions that translate
   engine output into view-ready descriptors (timing, colours, CSS classes, sound
   keys, callout text). This layer reads engine events but produces no side
   effects and holds no state, so it too is unit-testable in `node`.

3. **`*Screen.jsx` (React shell)** — owns *all* of: React state
   (`useReducer`/`useState`), DOM refs, the animation loop, sound playback, and
   persistence writes. It calls the engine for outcomes, walks the returned
   `events`, asks the presentation layer how each should look, and performs the
   actual DOM/GSAP/audio side effects. Persistence side effects (XP, scraps,
   defeats, relic drops) live here, *after* the engine has decided the outcome.

Import direction is one-way: shells import engines and presentation; engines and
presentation import neither React nor each other's shells. Data modules
(`gameData`, `forgeData`, ...) are shared leaf tables imported by engines.

### Architecture

```
                          plain data in / plain data out
   ┌─────────────────────────────────────────────────────────────────┐
   │  RULES LAYER (pure, node-testable)                                │
   │                                                                   │
   │   battleEngine.js      fusionEngine.js     hatcheryEngine.js      │
   │   resolveTurn()  ──┐   executeFusion()     executePull()          │
   │   pickNpcMove()    │   getFusionElement()  rollRarity()           │
   │   calculateDamage()│   calculateFusionStats rollShiny()           │
   │        ▲           │                                              │
   │        │ imports   │ returns { player, npc, events }              │
   │   gameData (tables)│                                              │
   └────────┼───────────┼──────────────────────────────────────────────┘
            │           │ events[]
            │           ▼
   ┌────────┼───────────────────────────────────────────────────────┐
   │  PRESENTATION-MAPPING LAYER (pure, node-testable)                │
   │   battlePresentation.js                                          │
   │     classifyBattleEvent(event) -> kind                          │
   │     getBattlePresentationProfile(event, move) -> {timing,shake,  │
   │       flashColor, attackerClass, defenderClass, sound, ...}      │
   │     getBattleResultCallout(event) -> {text, variant}            │
   └────────────────────────────┬────────────────────────────────────┘
                                 │ display profiles
                                 ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │  REACT SHELL (impure: state, DOM, side effects)                  │
   │   BattleScreen.jsx / FusionScreen.jsx / HatcheryScreen.jsx       │
   │     useReducer(battleReducer)   ← UI state only                  │
   │     for (event of result.events) animateEvent(event)            │
   │       → GSAP (animationEngine.js), playSound (soundEngine.js),   │
   │         DamageNumber / VfxOverlay, DOM refs                      │
   │     on victory → addDragonXp / addScraps / recordNpcDefeat       │
   │                  (persistence.js side effects)                   │
   └─────────────────────────────────────────────────────────────────┘
```

### Key Interfaces

```js
// RULES — battleEngine.js (pure)
// Resolves one full turn for both combatants. Returns next state + an ordered
// event log. No DOM, no React. RNG happens here; the result is data.
resolveTurn(playerState, npcState, playerMoveKey, npcMoveKey,
            playerMoveKeys, npcMoveKeys)
  -> { player: CombatantState, npc: CombatantState, events: BattleEvent[] }

// A BattleEvent is plain, serializable, presentation-agnostic:
//   { attacker, action, moveName, moveKey, vfxKey,
//     damage, effectiveness, hit, isCritical, targetHp, appliedStatus }

pickNpcMove(npcMoveKeys, npcElement, playerElement, playerStatus, battleContext)
  -> moveKey            // AI decision, pure given its inputs + Math.random()

// PRESENTATION — battlePresentation.js (pure)
classifyBattleEvent(event)               -> kind            // 'criticalHit' | 'miss' | ...
getBattlePresentationProfile(event, move) -> DisplayProfile  // timing/shake/class/sound
getBattleResultCallout(event)            -> { text, variant } | null
shouldAnimateBattleEvent(event)          -> boolean

// SHELL — BattleScreen.jsx (impure)
const result = resolveTurn(playerState, chargedNpcState, moveKey, npcMoveKey, ...);
for (const event of result.events) {
  if (shouldAnimateBattleEvent(event)) await animateEvent(event, dispatch);
}
// animateEvent reads getBattlePresentationProfile(event, move) and performs
// the GSAP / sound / DOM side effects. Persistence writes happen on resolution.
```

### Implementation Guidelines

- A `*Engine.js` module must import **nothing** from React, the DOM, GSAP, or
  `persistence.js`. If it needs to write a save, it returns data and lets the
  shell write. (`hatcheryEngine` is the deliberate edge case — it returns a new
  save via `structuredClone` in `applyPullResult` rather than mutating; it still
  performs no I/O.)
- Engine outputs must be plain serializable objects. Prefer an explicit `events`
  array over callbacks so the shell controls timing and the data can be asserted
  in tests.
- All presentation decisions (timing, colour, shake, CSS class, callout text,
  sound key) belong in `*Presentation.js` or the shell — never in the rules
  engine. The engine may *tag* an event (e.g. `isCritical`, `effectiveness`,
  `vfxKey`) but must not decide how it is drawn.
- Side effects (persistence, sound, music, animation) live only in the shell, and
  only *after* the engine has returned the authoritative outcome.
- Every new `*Engine.js` and `*Presentation.js` module ships with a `.test.js`
  sibling that imports it and asserts on return values, runnable under the
  `node` Vitest environment.

## Alternatives Considered

### Alternative 1: Logic inline in the React components

- **Description**: Compute damage, type effectiveness, status, and AI directly
  inside `BattleScreen.jsx` event handlers, interleaved with the animation and
  sound calls.
- **Pros**: Fewer files; no need to design a result-object contract; "see
  everything in one place" for a single small feature.
- **Cons**: Rules can only run inside an animating React tree, so they are
  effectively untestable without jsdom and a full render harness; any VFX edit
  risks changing balance; the same logic cannot be reused by AUTO-battle or the
  reserve-swap path without duplication.
- **Estimated Effort**: Lower up front, much higher over time.
- **Rejection Reason**: Directly defeats the testability and balance-stability
  requirements; the `node` test environment in `vite.config.js` would be
  impossible.

### Alternative 2: Engine emits ready-to-render view models (skip the mapping layer)

- **Description**: Keep a pure engine, but have it return objects that already
  contain timing, colours, CSS classes, and sound keys, so the shell just plays
  them.
- **Pros**: One fewer module; the shell becomes a trivial player.
- **Cons**: Couples balance code to presentation concepts; a restyle now means
  editing the engine and re-running balance tests; the engine becomes
  view-specific and harder to share with a second runtime (Godot has different
  animation primitives entirely).
- **Estimated Effort**: Comparable.
- **Rejection Reason**: Re-tangles the two concerns the whole pattern exists to
  separate. The chosen design keeps the engine emitting *semantic* events
  (`isCritical`, `effectiveness`) and isolates the semantic→visual mapping in
  `battlePresentation.js`, which is itself pure and testable.

### Alternative 3: Full state-management / event-bus architecture (Redux, ECS, observer bus)

- **Description**: Route all gameplay through a central store or event bus with
  middleware, systems, and subscriptions.
- **Pros**: Scales to very large teams and very large state graphs; decouples
  producers from consumers globally.
- **Cons**: Heavy ceremony for a single-developer indie project; indirection
  makes the turn flow harder to follow; `useReducer` per screen already covers
  the actual state needs.
- **Estimated Effort**: Significantly higher.
- **Rejection Reason**: Over-engineered for the project's scale. The local
  `useReducer` in `BattleScreen.jsx` plus pure engines achieves the same
  testability without the framework tax.

## Consequences

### Positive

- Combat, fusion, and gacha math are unit-tested directly in `node` with no
  render harness (`battleEngine.test.js` asserts the atk-up cap, type chart,
  status ticks, etc.).
- Presentation can be retuned freely — timing, shake, colours, sounds all live in
  `battlePresentation.js`/`animationEngine.js` and cannot alter outcomes.
- One engine, many callers: player input, AUTO-battle, and reserve-swap all reuse
  `resolveTurn`/`pickNpcMove`.
- The boundary is portable: the GDScript build mirrors the same stateless-`sim`
  vs. screen-controller split, so the two runtimes can share one balance model.
- The `events` array makes the turn auditable and gives the shell full control
  over animation sequencing and timing.

### Negative

- More files per system (engine + presentation + shell + two test files) than an
  inline approach.
- A result-object/event contract must be designed and kept stable; adding a new
  combat mechanic often means touching the engine, the event shape, the
  presentation mapping, *and* the shell (e.g. the charge-up and signature-move
  work threaded through all layers).
- The shell still carries real complexity (the `BattleScreen.jsx` `animateEvent`
  choreography is large); the pattern quarantines that complexity but does not
  remove it.

### Neutral

- RNG lives inside the engine, so engine tests assert on ranges/invariants or
  stub `Math.random`, rather than on fixed outputs.
- Persistence side effects are concentrated in the shell rather than the engine,
  which is intentional but means "what happens on victory" is read in
  `BattleScreen.jsx`, not `battleEngine.js`.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Rules logic leaks into a shell for expedience, eroding testability | Medium | High | Code review against the "no rules in `.jsx`" rule; engines stay import-free of React/DOM so leakage is visible |
| Presentation concepts leak into an engine (colours/timing) | Low | Medium | Keep engines emitting semantic flags only; route visuals through `*Presentation.js` |
| Engine ↔ Godot balance drift (two implementations of one ruleset) | Medium | Medium | Treat the JS engine as source of truth per `CLAUDE.md`; mirror function names; headless `sim_smoke.gd` parity check |
| Event-shape changes silently break the shell's animation switch | Low | Medium | `battlePresentation.test.js` pins event classification; shell guards unknown actions |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | n/a (pattern, not a feature) | Negligible — turn resolution is synchronous arithmetic over two combatants, far under one frame | 16.6ms/frame (60fps) |
| Memory | n/a | Negligible — small plain result objects + a per-turn events array, GC'd each turn | No specific budget |
| Load Time | n/a | Neutral — modules are small and tree-shaken by Vite | No regression |
| Network (if applicable) | n/a | n/a — fully client-side | n/a |

The separation is a structural decision with no measurable runtime cost; the
animation cost lives entirely in the shell/GSAP layer and is unaffected by the
boundary.

## Migration Plan

Not applicable — this pattern is already embodied throughout the shipped browser
build. This ADR documents the existing decision rather than introducing a change.
For *new* systems, the migration is forward-looking:

1. New gameplay system starts as a pure `*Engine.js` with a `.test.js` sibling.
2. If it has rich visual variety, add a pure `*Presentation.js` mapping layer with
   its own tests.
3. Add the `*Screen.jsx` shell last; it owns state, animation, sound, and
   persistence and consumes the engine's data output.

**Rollback plan**: None required — reverting would mean re-inlining logic into
components, which the project explicitly rejects. If a single system ever needs
to merge layers, that would be a localized exception documented in its own ADR,
not a reversal of this pattern.

## Validation Criteria

- [x] Each rules engine has a `.test.js` sibling that runs under the `node`
      Vitest environment with no jsdom (`battleEngine.test.js`,
      `fusionEngine.test.js`, `hatcheryEngine.test.js`, `battlePresentation.test.js`).
- [x] `battleEngine.js` imports nothing from React, the DOM, GSAP, or
      `persistence.js`.
- [x] `battlePresentation.js` is pure (no React/DOM) and independently tested.
- [x] `resolveTurn` returns a serializable `{ player, npc, events }` object that
      the shell consumes without re-deriving outcomes.
- [x] More than one caller drives the same engine (player, AUTO-battle, swap).
- [ ] Restyling battle VFX/sound requires edits only to
      `battlePresentation.js`/`animationEngine.js`/the shell, never to
      `battleEngine.js` (ongoing — enforced at review time).

## GDD Requirements Addressed

<!-- This section is MANDATORY. Every ADR must trace back to at least one GDD
     requirement, or explicitly state it is a foundational decision with no GDD
     dependency. Traceability is audited by /architecture-review. -->

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/combat.md` (authored in parallel) | Combat | Damage, type effectiveness, crit, status effects, and NPC AI must be precisely balanced and protected from regression | Combat rules live in pure `battleEngine.js` with a `battleEngine.test.js` suite (atk-up cap, type chart, status ticks) that runs without rendering, so balance is locked by tests independent of VFX |
| `design/gdd/combat.md` (authored in parallel) | Combat — presentation | Hits must read clearly (crit / super-effective / resist / miss / KO have distinct feedback) without affecting outcomes | `battlePresentation.js` maps semantic engine events to display profiles in a pure, tested layer, so feedback can be tuned without touching combat math |
| `design/gdd/fusion.md` | Fusion | Fusion element/stability/stat outcomes follow fixed alchemy rules | `fusionEngine.js` (`getFusionElement`, `getStabilityTier`, `calculateFusionStats`) is pure and tested; `FusionScreen.jsx` only presents the result |
| `design/gdd/hatchery-gacha.md` | Hatchery / Gacha | Pull rarity, element, shiny, and pity must be reproducible and verifiable | `hatcheryEngine.js` (`rollRarity`, `rollElement`, `rollShiny`, `executePull`) is pure with a `.test.js` sibling; `HatcheryScreen.jsx` handles only the reveal animation and save write |

## Related

- ADR-0001 (single-`save`-object + `localStorage` persistence) — this ADR depends
  on persistence side effects living in the shell, not the engine.
- `CLAUDE.md` — "Engine vs. presentation separation" describes this pattern as the
  project convention; this ADR records the decision and rationale behind it.
- Code: `src/battleEngine.js`, `src/battlePresentation.js`, `src/BattleScreen.jsx`,
  `src/fusionEngine.js`, `src/hatcheryEngine.js`, `src/animationEngine.js`,
  and their `.test.js` siblings.
- Godot mirror: `dragon-forge-godot/scripts/sim/` (stateless rules) vs.
  `dragon-forge-godot/scripts/screens/` (controllers) re-implements the same
  boundary in the production runtime.
