# ADR-0008: Combined attack-up multiplier cap (MAX_ATK_MULTIPLIER) over charge + buff

## Status

Accepted

## Date

2026-06-16

## Last Verified

2026-06-16

## Decision Makers

Reverse-documented from implementation

## Summary

Multiple attack-up sources in combat (the NPC `npc_focus` timed `atkBuff` at 1.3×
and a charged-move boost at `CHARGE_ATK_MULTIPLIER` 1.4×) would, if applied
independently, multiply into a 1.82× damage spike. The decision is to funnel every
attack-up source through a single pure function, `effectiveAttack`, that combines
them and clamps the product to a shared ceiling `MAX_ATK_MULTIPLIER` (1.5×), so no
combination of buffs and charges can produce a runaway one-shot.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Browser build — React 18 + Vite (pure JS engine module) |
| **Domain** | Core (combat damage resolution) |
| **Knowledge Risk** | LOW — plain JavaScript arithmetic, no engine-version-specific APIs |
| **References Consulted** | `src/battleEngine.js`, `src/BattleScreen.jsx`, `src/gameData.js`, `src/battleEngine.test.js`, `design/gdd/combat.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | None |
| **Blocks** | None |
| **Ordering Note** | The charged-move system and the `npc_focus` buff move both predate this cap; the cap exists specifically to bound their interaction, so it must remain in place whenever either feature does. |

## Context

### Problem Statement

Combat depth in Dragon Forge is built from independently-designed attack-up
mechanics: a timed attack buff (`npc_focus`, 1.3× for one turn) and charged moves
that fire at an elevated attack multiplier (1.4×). Each was tuned in isolation. When
an NPC buffs itself with Focus and then lands a charged strike on the same outgoing
attack, the two multipliers compose multiplicatively (1.3 × 1.4 = 1.82×). On the
NPCs that carry both a buff move and a chargeable move — `phishing_siren` and
`protocol_vulture` — that spike is reachable in normal play and can effectively
one-shot a player dragon, breaking the "tactical depth without twitch skill"
pillar of combat. The decision of how to bound stacked attack-up sources had to be
made because both features ship together (see commit `5c05dfc`, "Combat depth:
charge-up moves + NPC buff & signature moves").

### Current State

As implemented, every attack-up source passes through one funnel:
`src/battleEngine.js`, `effectiveAttack(atk, atkBuff, chargeMultiplier = 1)`:

```js
export const CHARGE_ATK_MULTIPLIER = 1.4;
export const MAX_ATK_MULTIPLIER = 1.5;

export function effectiveAttack(atk, atkBuff, chargeMultiplier = 1) {
  const buffMult = atkBuff?.multiplier ?? 1;
  const mult = Math.min(buffMult * chargeMultiplier, MAX_ATK_MULTIPLIER);
  return Math.floor(atk * mult);
}
```

`resolveAction` (`src/battleEngine.js:389`) is the single caller in the damage path:

```js
const effectiveAtk = effectiveAttack(actor.state.atk, actor.state.atkBuff, actor.state.chargeMultiplier);
```

The charge multiplier is supplied as data, not pre-baked into `atk`.
`src/BattleScreen.jsx` (around line 726), when an NPC fires a stored charged move,
passes the multiplier through on the state object rather than multiplying `atk` itself:

```js
const chargedNpcState = previouslyCharged
  ? { ...npcState, chargeMultiplier: CHARGE_ATK_MULTIPLIER }
  : npcState;
```

The inline comment there states the intent directly: "Pass the multiplier through
(rather than pre-multiplying atk) so the engine combines it with any active atkBuff
under one ceiling — otherwise charge × focus would stack multiplicatively." This is
the architecture the ADR documents — there is no prior "broken" state to migrate
from; the cap was present at feature introduction.

### Constraints

- **Pure-function testability**: the browser build separates pure `*Engine.js`
  logic from `*Screen.jsx` presentation; the damage cap must be unit-testable
  without standing up React or RNG.
- **No double-application**: the multiplier must be applied in exactly one place;
  applying charge both at the call site (pre-multiplied `atk`) and inside the engine
  would silently exceed the ceiling.
- **Compatibility with existing buff system**: `atkBuff` is a `{ multiplier, turnsLeft }`
  object set by `npc_focus`/buff moves and ticked by `decrementBuff`; the cap must
  consume that shape unchanged.
- **Balance-tuning constraint**: designers tune `CHARGE_ATK_MULTIPLIER`, the buff
  multiplier (`buffMultiplier: 1.3` in `gameData.js`), and `MAX_ATK_MULTIPLIER`
  independently, so the ceiling must be a single named constant, not a magic number.

### Requirements

- Combined attack-up output must never exceed `MAX_ATK_MULTIPLIER` (1.5×) for any
  reachable combination of timed buff and charged-move boost.
- A lone buff (1.3×) and a lone charge (1.4×) must each apply at full value when
  under the ceiling.
- The cap path must be exercisable by a direct unit test with no battle simulation.
- The mechanic must add negligible cost to per-turn resolution (it is a single
  `Math.min` / `Math.floor` per attacking action).

## Decision

Route all attack-up multipliers through one pure, exported function,
`effectiveAttack`, that (1) reads the timed buff multiplier from `atkBuff`, (2)
multiplies it by the supplied `chargeMultiplier` (default 1), (3) clamps the product
to `MAX_ATK_MULTIPLIER` with `Math.min`, and (4) floors the scaled attack stat. The
charged-move boost is passed as a data field (`state.chargeMultiplier`) from the
presentation layer rather than being pre-multiplied into the attacker's `atk`, so
the engine — and only the engine — owns the combination and the ceiling.

### Architecture

```
 gameData.js                BattleScreen.jsx                 battleEngine.js
 ┌─────────────┐            ┌────────────────────┐          ┌────────────────────────┐
 │ npc_focus   │  atkBuff   │ on charged fire:   │ state    │ resolveAction          │
 │ buffMult    │──set on────│  chargeMultiplier =│──passes──│   effectiveAttack(     │
 │  = 1.3      │  actor     │  CHARGE_ATK_MULT   │  through │     atk, atkBuff,       │
 │ canCharge   │  state     │  (1.4) on npcState │          │     chargeMultiplier)  │
 │ chargeChance│            └────────────────────┘          │     ▼                  │
 └─────────────┘                                            │   min(buffMult ×       │
                                                            │       chargeMult,      │
                                                            │       MAX_ATK_MULT 1.5)│
                                                            │     ▼  floor(atk×mult) │
                                                            │   → calculateDamage    │
                                                            └────────────────────────┘
        single combination point, single ceiling ───────────────────┘
```

### Key Interfaces

```js
// src/battleEngine.js — the contract every attack-up source must respect
export const CHARGE_ATK_MULTIPLIER = 1.4; // charged-move boost
export const MAX_ATK_MULTIPLIER   = 1.5; // shared ceiling on combined atk-up

// atkBuff: { multiplier: number, turnsLeft: number } | null
// chargeMultiplier: number (1 = no charge)
function effectiveAttack(atk, atkBuff, chargeMultiplier = 1): number
//   → floor(atk × min(atkBuff.multiplier × chargeMultiplier, MAX_ATK_MULTIPLIER))
```

### Implementation Guidelines

- Any new attack-up source (e.g. a relic that boosts ATK, a new buff move, a player
  charge mechanic) MUST be expressed either as an `atkBuff.multiplier` or as an
  additional factor folded into the `chargeMultiplier` argument — never as a separate
  multiplication outside `effectiveAttack`. Adding a new factor without routing it
  through this function reintroduces the runaway-stack bug the cap exists to prevent.
- Pass charge as data on the combatant state (`chargeMultiplier`), not by mutating
  `atk`. Pre-multiplying `atk` would bypass the ceiling and double-count.
- Keep `MAX_ATK_MULTIPLIER` >= the largest single source so a lone buff or charge is
  never silently clipped; today the largest single source is the 1.4× charge, under
  the 1.5× ceiling.
- Defensive/accuracy modifiers (`defBuff`, Guard Break, Blind) are deliberately NOT
  part of this funnel — they have their own caps and ordering in `resolveAction`.
  This cap is scoped to attack-up only.

## Alternatives Considered

### Alternative 1: Additive stacking (sum the bonuses instead of multiplying)

- **Description**: Treat each source as a +0.3 / +0.4 bonus and sum them: effective
  multiplier = 1 + 0.3 + 0.4 = 1.7×, then clamp or leave uncapped.
- **Pros**: Bonuses grow linearly and are intuitive for designers; less prone to
  exponential blow-up as more sources are added.
- **Cons**: Diverges from the multiplicative model the rest of the damage formula
  already uses (`stageMult × powerScale × typeChart × roll`), creating two mental
  models for stat scaling; still needs a ceiling to be safe; would require reworking
  the existing `atkBuff.multiplier` data shape.
- **Estimated Effort**: Medium — touches data shape and several formula sites.
- **Rejection Reason**: The codebase is consistently multiplicative; introducing an
  additive special-case for attack-up only would hurt maintainability for no balance
  benefit a simple cap doesn't already provide.

### Alternative 2: Pre-multiply ATK at the call site, no shared cap

- **Description**: Where the charged move fires, set `npcState.atk = atk × 1.4`
  directly; let `atkBuff` apply on top inside the engine; accept the 1.82× result.
- **Pros**: Trivially simple; no new function or constant.
- **Cons**: Reintroduces the exact one-shot spike on `phishing_siren` /
  `protocol_vulture`; splits the multiplier across two layers so no single place
  knows the total; impossible to unit-test the combined value in isolation. The
  inline comment in `BattleScreen.jsx` explicitly rejects this approach.
- **Estimated Effort**: Low.
- **Rejection Reason**: Breaks combat balance and testability — the very problem
  this decision exists to solve.

### Alternative 3: Mutual exclusion (a charged move cannot benefit from an active buff)

- **Description**: When firing a charged move, ignore `atkBuff` entirely; apply only
  the charge multiplier (and vice versa).
- **Pros**: Hard guarantee against any stacking; no ceiling constant needed.
- **Cons**: Throws away the player's/NPC's earned buff turn, which feels punitive and
  arbitrary; requires branching logic at the resolution site; loses the design
  intent that buffs and charges are both "attack-up" tools the AI can combine for a
  meaningful-but-bounded payoff.
- **Estimated Effort**: Low–medium.
- **Rejection Reason**: The cap preserves the reward of combining sources (output
  still reaches the 1.5× ceiling) while bounding it; exclusion is a blunter, less
  satisfying rule.

## Consequences

### Positive

- A single, named, unit-tested ceiling makes the worst-case damage spike a known,
  bounded quantity — `floor(atk × 1.5)` — which directly supports combat balance.
- One combination point means future attack-up sources inherit the cap for free as
  long as they route through `effectiveAttack`.
- The pure function is directly testable; `src/battleEngine.test.js` asserts the lone
  cases, the combined cap, and that no reachable combo exceeds the ceiling, without
  simulating a battle or stubbing RNG.
- Designers can retune `CHARGE_ATK_MULTIPLIER`, buff multipliers, and the ceiling
  independently via named constants.

### Negative

- The cap is invisible in the UI: a player who buffs then charges does not see "1.82×
  clamped to 1.5×" — the lost headroom is silent, which can make tuning feel opaque.
- Adds a discipline requirement: any contributor adding an attack-up effect must know
  to route it through `effectiveAttack`, or the cap is silently bypassed. There is no
  compile-time enforcement of this contract.
- The ceiling is a global flat cap, not per-source, so a future high-value single
  buff (> 1.5×) would be clipped on its own; the ceiling would need to rise with it.

### Neutral

- Charge state is carried as a data field on the combatant state object rather than
  baked into `atk`; this is a structural choice that other charge-related logic must
  also respect.
- The cap is scoped strictly to attack-up; defense and accuracy modifiers remain
  governed by their own logic in `resolveAction`.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| A new attack-up source is added outside `effectiveAttack`, bypassing the cap | Medium | High (reintroduces one-shot spike) | Implementation guideline + inline comment in `BattleScreen.jsx`; cap path covered by `battleEngine.test.js`; code review of any combat-damage change |
| Designer raises a single buff above `MAX_ATK_MULTIPLIER`, silently clipping it | Low | Medium | Guideline to keep ceiling >= largest single source; constants are co-located and commented |
| Charge multiplier accidentally pre-multiplied into `atk` AND passed as `chargeMultiplier` (double count) | Low | Medium | Single documented call site passes it as data only; comment warns against pre-multiplying |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | n/a (turn-based) | +1 `Math.min`/`Math.floor` per attacking action (negligible) | < 16ms/frame; combat is event-driven, not per-frame |
| Memory | n/a | +2 module-level constants | n/a |
| Load Time | n/a | none | n/a |
| Network (if applicable) | n/a | none | n/a |

This is a turn-based engine; the cap runs once per attacking action, not per frame,
and costs two arithmetic operations. There is no measurable performance impact.

## Migration Plan

Not applicable — the cap was present when the charge + buff features were introduced
(commit `5c05dfc`). There is no prior uncapped state in the shipped codebase to
migrate from. This ADR documents the decision retroactively.

**Rollback plan**: To remove the cap, delete the `Math.min(..., MAX_ATK_MULTIPLIER)`
clamp in `effectiveAttack`; the multiplicative combination would then be uncapped.
This would re-expose the 1.82× spike and is not recommended.

## Validation Criteria

- [x] `effectiveAttack(100, { multiplier: 1.3 }, CHARGE_ATK_MULTIPLIER)` returns
      `floor(100 × 1.5)`, not `182` (covered by `battleEngine.test.js`).
- [x] A lone buff (1.3×) and a lone charge (1.4×) each apply at full value under the
      ceiling (covered by `battleEngine.test.js`).
- [x] No reachable buff/charge combination exceeds `MAX_ATK_MULTIPLIER` (covered by
      `battleEngine.test.js`).
- [x] The charge boost is the only attack-up factor passed as data from
      `BattleScreen.jsx`; `atk` is never pre-multiplied there.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/combat.md` | Combat — Effective Attack (Buff + Charge Cap) | "The cap at `MAX_ATK_MULTIPLIER` (1.5) prevents the stacking of `npc_focus` (1.3×) and a charged strike (1.4×) from producing the otherwise-reachable 1.82× spike." | `effectiveAttack` combines `atkBuff.multiplier × chargeMultiplier` and clamps via `Math.min(..., MAX_ATK_MULTIPLIER)` at the single damage-resolution call site. |
| `design/gdd/combat.md` | Combat — Charge Moves | Charged moves fire at an elevated attack multiplier (`CHARGE_ATK_MULTIPLIER` 1.4×) without enabling a one-shot when combined with a timed buff. | Charge is passed as `state.chargeMultiplier` data into `effectiveAttack` rather than pre-multiplied, so it composes with `atkBuff` under one shared ceiling. |
| `design/gdd/combat.md` | Combat — Buff System | `npc_focus` sets `atkBuff { multiplier: 1.3, turnsLeft }`; tactical depth must not become a twitch/one-shot mechanic. | The buff multiplier is consumed unchanged by `effectiveAttack` and bounded by the cap, preserving the buff's value (output still reaches 1.5×) while preventing a runaway spike. |

## Related

- `src/battleEngine.js` — `effectiveAttack`, `CHARGE_ATK_MULTIPLIER`,
  `MAX_ATK_MULTIPLIER`, and the single call site in `resolveAction`.
- `src/BattleScreen.jsx` — passes `chargeMultiplier: CHARGE_ATK_MULTIPLIER` as data
  on the charged NPC state (around line 726).
- `src/gameData.js` — `npc_focus` (`buffMultiplier: 1.3`) and `canCharge` /
  `chargeChance` move flags that define the stacking sources.
- `src/battleEngine.test.js` — `describe('effectiveAttack (atk-up cap)')` unit tests.
- `design/gdd/combat.md` — "Effective Attack (Buff + Charge Cap)", "Charge Moves",
  and "Buff System" sections.
