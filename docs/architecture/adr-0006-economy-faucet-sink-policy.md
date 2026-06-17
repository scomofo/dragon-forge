# ADR-0006: Economy Faucet/Sink Policy — First-Clear-Full / Repeat ×0.25, Keep the Daily ×3 Reward

## Status

Accepted

## Date

2026-06-16

## Last Verified

2026-06-16

## Decision Makers

Reverse-documented from implementation

## Summary

Dragon Forge's only resource faucet is battle rewards (Data Scraps + dragon XP),
and without limits a player could farm a single beatable enemy forever to trivialize
the gacha/fusion/shop economy. This ADR records the shipped policy: every battle's
**first clear pays full reward, every repeat clear pays ×0.25**, while the
**Daily Challenge keeps its ×3 scrap multiplier** because it is gated to once per
calendar day and its compounding (streak ×1.5 cap, NG+ +25%/tier) is bounded — a
generous daily-return incentive in a non-monetized single-player game is legitimate,
not an exploit.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React 18 + Vite (browser build) |
| **Domain** | Core (economy / progression) |
| **Knowledge Risk** | LOW — plain JS, in training data; no engine-specific APIs |
| **References Consulted** | `src/BattleScreen.jsx`, `src/dailyChallenge.js`, `src/persistence.js` |
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
| **Ordering Note** | The repeat clamp depends on the save's defeat-tracking fields (`defeatedNpcs`, `singularityProgress.replayCounts`/`defeated`, `remnantDefeated`, `mirrorAdminDefeated`, `singularityComplete`) and on the daily-gating field (`lastDailyCompleted`) already existing in the save schema (`persistence.js DEFAULT_SAVE`). |

## Context

### Problem Statement

The economy has exactly one resource faucet — winning battles, which grant Data Scraps
(the universal currency for gacha pulls, fusion, the shop, and the Skye forge) and
dragon XP. Every sink (hatchery pulls, fusion at 100 scraps, shop items, wrench upgrades)
draws from that one pool. If a player can re-fight any single beatable enemy with no
diminishing return, the entire scarcity model collapses: scraps become free, the gacha
pity system and fusion cost become meaningless, and there is no reason to engage with the
campaign or endgame to progress. The decision of *how to dampen repeat farming without
punishing legitimate replay* had to be made because the game is deployed and feature-complete;
an unbounded faucet would be the single largest balance hole in a shipped product.

A second, narrower question rides alongside it: the Daily Challenge grants a deliberately
large **×3 scrap** payout. Is that a second uncapped faucet that should be softened, or a
legitimate retention reward that the rest of the policy already bounds?

### Current State

The reward path lives in the VICTORY branch of `BattleScreen.jsx` (the battle-resolution
effect, around lines 911-948). Reward amount is decided by a three-way branch over the
pre-battle `save` snapshot:

- **Repeat clear** (`isRepeatDefeat || isSingularityRepeat`): `scrapsGained = Math.floor(rawScraps * 0.25)`.
- **Daily Challenge** (`battleConfig?.dailyNpc`): `scrapsGained = Math.floor(rawScraps * getDailyStreakMultiplier(save))`.
- **First clear of anything else**: `scrapsGained = rawScraps` (full).

`isRepeatDefeat` covers normal/campaign NPCs and reads `save.defeatedNpcs`.
`isSingularityRepeat` covers the endgame arc and reads, per boss type,
`save.remnantDefeated`, `save.mirrorAdminDefeated`, `save.singularityComplete`, and
`save.singularityProgress.replayCounts` / `.defeated`. Both explicitly exclude the
Daily (`!battleConfig?.dailyNpc`), so the daily card never triggers the ×0.25 clamp even
though you re-fight a daily every day.

The Daily's generosity is set upstream in `dailyChallenge.js`: `getDailyChallenge()`
produces `boostedScraps = Math.floor(baseNpc.scrapsReward * 3)`. The Daily is gated to
once per calendar day: `isDailyChallengeCompleted(save)` compares `save.lastDailyCompleted`
against today's `getDailySeed()` (a `YYYYMMDD` integer), and `completeDailyChallenge(seed)`
stamps it on win. Daily streak compounding is bounded two ways: `getEffectiveStreak`
zeroes the streak unless *yesterday's* daily was completed, and `getDailyStreakMultiplier`
caps at **1.5×** (`Math.min(1.5, 1.0 + (currentStreak - 1) * 0.1)`).

New Game+ applies a further `+25%` scraps/XP per NG+ tier (`BattleScreen.jsx` ~939-942),
but NG+ is itself gated behind a true-final clear (`startNewGamePlus` requires
`save.mirrorAdminDefeated`), so it is not a farmable loop.

The DECISION (2026-06-16) confirms this shipped policy is correct and the Daily ×3 is
**kept as-is** rather than softened.

### Constraints

- **Single-player, no monetization** — there is no real-money store, no leaderboard, and
  no PvP. "Exploiting" the faucet only affects the player's own pacing; the only thing at
  stake is the designed sense of progression, not revenue or fairness to other players.
- **Client-authoritative save** — the save lives in `localStorage` (`dragonforge_save`).
  A determined player can edit it. Reward gating is a *pacing* mechanism for normal play,
  not an anti-cheat boundary, and should not be over-engineered as one.
- **Deployed and feature-complete** — the browser build is live (`base: '/dragon-forge/'`).
  Changes to faucet values directly change the felt economy for existing saves.
- **Compatibility** — the policy must read only fields already present in `DEFAULT_SAVE` and
  survive `migrateSave` for older saves (older saves default `lastDailyCompleted`/`dailyStreak`
  to 0, which reads as "daily never completed" — safe).

### Requirements

- A beatable enemy must not be a renewable, full-value scrap fountain.
- First-time content completion must still feel rewarding (full payout).
- Replaying content (campaign re-fights, endgame boss replays) must remain *worth doing*
  for non-scrap rewards (core/relic drops, XP) without re-flooding the scrap economy.
- The Daily Challenge must remain a meaningful daily-return incentive.
- All compounding multipliers (daily streak, NG+) must have hard caps or hard gates so no
  combination produces an unbounded payout.
- Logic must be deterministic and unit-testable where it is pure (it lives in `persistence.js`
  helpers and `dailyChallenge.js`).

## Decision

Adopt a **first-clear-full / repeat ×0.25** reward clamp as the universal sink on the
battle faucet, and **keep the Daily Challenge ×3 multiplier**, treating the Daily as a
deliberately-exempt, separately-bounded faucet.

Concretely:

1. **First clear pays full.** The first time a given NPC/boss/remnant is defeated (judged
   against the pre-battle save snapshot, so a genuine first clear reads as not-yet-defeated),
   `scrapsGained = rawScraps`.
2. **Repeat clear pays ×0.25.** Any subsequent clear of the same content pays
   `Math.floor(rawScraps * 0.25)`. This applies uniformly to normal NPCs and to every
   endgame boss type (Singularity bosses, the final boss, Corruption Remnants, the Mirror
   Admin), each judged against its own defeat-tracking field.
3. **Daily Challenge is exempt from the clamp and keeps ×3.** The daily NPC's base
   `scrapsReward` is already `×3` (set in `dailyChallenge.js`). The Daily never enters the
   repeat branch; instead it multiplies by the streak multiplier (1.0–1.5×). Its faucet is
   bounded by being **once per calendar day** (`lastDailyCompleted === getDailySeed()`).
4. **Compounding is bounded.** The daily streak multiplier hard-caps at 1.5×, decays to 0
   if a day is missed, and NG+ (+25%/tier) sits behind a true-final-clear gate. The maximum
   single daily payout is therefore `3 × baseReward × 1.5 × (1 + 0.25·ngPlus)`, paid at most
   once per day — a known, bounded ceiling, not an open loop.

### Architecture

```
                 ┌──────────────────────────────────────────────┐
                 │  Battle won (BattleScreen.jsx VICTORY branch)  │
                 └──────────────────────────────────────────────┘
                                      │
                 rawScraps = state.npc.scrapsReward
                 (daily NPC's rawScraps is already ×3 from dailyChallenge.js)
                                      │
              ┌───────────────────────┴────────────────────────┐
              │  Which reward branch? (decided on PRE-battle    │
              │  `save` snapshot)                               │
              └───────────────────────┬────────────────────────┘
        repeat clear            daily challenge            first clear
   (isRepeatDefeat ||           (battleConfig                (else)
    isSingularityRepeat)         .dailyNpc)
              │                       │                          │
   floor(raw * 0.25)      floor(raw * streakMult)            raw (full)
                            streakMult = min(1.5, …)
              └───────────────────────┴──────────────────────────┘
                                      │
                    NG+ bonus: floor(scraps * (1 + 0.25·ngPlus))   (NG+ gated by final clear)
                                      │
                              addScraps(scrapsGained)
                                      │
            Defeat tracking stamped so NEXT clear reads as repeat:
            recordNpcDefeat / recordSingularityDefeat / markMirrorAdminDefeated /
            recordRemnantDefeat / markSingularityComplete  — OR —
            completeDailyChallenge(seed)  (daily: stamps lastDailyCompleted = today)
```

### Key Interfaces

```js
// dailyChallenge.js — the ×3 faucet and its bounds
getDailyChallenge()              -> { ..., scrapsReward: floor(baseNpc.scrapsReward * 3), seed }
isDailyChallengeCompleted(save)  -> save.lastDailyCompleted === getDailySeed()   // once/day gate
getEffectiveStreak(save)         -> save.lastDailyCompleted === yesterdaySeed ? save.dailyStreak : 0
getDailyStreakMultiplier(save)   -> min(1.5, 1.0 + (effectiveStreak + 1 - 1) * 0.1) // hard cap 1.5×

// persistence.js — defeat tracking (what flips a clear from "first" to "repeat")
completeDailyChallenge(seed)     // stamps lastDailyCompleted, increments/decays dailyStreak
recordNpcDefeat(npcId)           // adds to defeatedNpcs
recordSingularityDefeat(bossId)  // adds to singularityProgress.defeated + replayCounts
markMirrorAdminDefeated()        // sets mirrorAdminDefeated + replayCounts
startNewGamePlus()               // returns false unless save.mirrorAdminDefeated (gates NG+ faucet bonus)

// BattleScreen.jsx — the clamp itself (VICTORY branch)
isRepeatDefeat = !isSingularity && !dailyNpc && save.defeatedNpcs.includes(npcId)
isSingularityRepeat = isSingularity && (<per-boss-type defeat lookup>)
scrapsGained =
    (isRepeatDefeat || isSingularityRepeat) ? floor(rawScraps * 0.25)
  : dailyNpc                                 ? floor(rawScraps * getDailyStreakMultiplier(save))
  :                                            rawScraps
if (save.ngPlus) scrapsGained = floor(scrapsGained * (1 + save.ngPlus * 0.25))
```

### Implementation Guidelines

- **Judge repeat status against the pre-battle snapshot.** `save` in the VICTORY branch is
  read before the defeat is recorded, so a true first clear correctly reads as
  not-yet-defeated. Do not move the `recordNpcDefeat` / `recordSingularityDefeat` calls
  ahead of the `isRepeatDefeat` computation.
- **Keep the Daily out of both repeat predicates.** Both `isRepeatDefeat` and
  `isSingularityRepeat` must retain their `!battleConfig?.dailyNpc` guard, or the daily would
  collapse to ×0.25 on day two.
- **Capture `streakMultiplier` before `completeDailyChallenge`.** The victory overlay shows
  the multiplier that was actually applied; `completeDailyChallenge` mutates the streak, so
  it must be read first (it is — `getDailyStreakMultiplier(save)` runs on the pre-mutation snapshot).
- **New faucet sources must respect the same clamp.** Any future repeatable content that
  grants scraps must add a defeat-tracking field and route through the same first/repeat
  branch rather than paying full on every clear.
- **Do not treat the clamp as anti-cheat.** It is a pacing tool over a client-authoritative
  save; resist the urge to add server validation or obfuscation for a single-player game.

## Alternatives Considered

### Alternative 1: Soften the Daily ×3 down to ×2

- **Description**: Lower `boostedScraps` in `dailyChallenge.js` from `* 3` to `* 2`, on the
  theory that ×3 is "too much" of a faucet.
- **Pros**: Smaller daily injection; marginally tighter scrap economy.
- **Cons**: Solves a non-problem. The Daily is already capped at once per calendar day and is
  *excluded by design* from the repeat clamp, so it is not the unbounded faucet — repeat-boss
  farming was. Cutting it reduces the daily-return incentive (the single best retention hook in
  a no-monetization game) to fix a leak that does not exist. It also re-tunes the felt value of
  a deployed reward for every existing save.
- **Estimated Effort**: Trivial (one constant).
- **Rejection Reason**: Misidentifies where the exploit is. The genuinely exploitable faucet
  (unlimited repeat farming) is already closed by the ×0.25 clamp; softening the once-per-day
  reward trades away retention value for no economic benefit.

### Alternative 2: Cap the daily compounding (remove or shrink the streak/NG+ multipliers)

- **Description**: Remove the streak multiplier (or shrink its 1.5× cap), and/or strip the
  NG+ +25%/tier bonus from the daily, to "prevent stacking."
- **Pros**: Flatter, more predictable daily payout.
- **Cons**: The compounding is already bounded: the streak multiplier hard-caps at 1.5× and
  resets to 0 on any missed day (`getEffectiveStreak`), and the NG+ bonus is gated behind a
  true-final clear (`startNewGamePlus` requires `mirrorAdminDefeated`), so neither is an open
  loop. The combined ceiling is a closed-form maximum paid at most once per day. Removing the
  streak bonus also removes the *consecutive-day* habit incentive, which is the entire point of
  a streak system.
- **Estimated Effort**: Low.
- **Rejection Reason**: There is nothing unbounded to cap — the caps and gates already exist.
  The compounding is a deliberate, bounded retention reward, not a runaway multiplier.

### Alternative 3: Per-day scrap cap across all sources (global faucet limiter)

- **Description**: Track scraps earned today and hard-stop the faucet at a daily ceiling
  regardless of source.
- **Pros**: Absolute guarantee against farming; one knob governs the whole economy.
- **Cons**: Punishes legitimate first-clear progress (a player completing a chunk of new
  campaign content in one sitting would hit the wall), adds a new save field and reset logic,
  and imposes a session-length limit that feels hostile in a single-player game with no
  competitive stakes. It is a heavier mechanism than the targeted repeat clamp needs to be.
- **Estimated Effort**: Medium (new state, daily reset, UI to explain the cap).
- **Rejection Reason**: Over-engineered for a single-player, non-monetized game. The
  first-clear/repeat clamp already removes the only renewable exploit while leaving genuine
  progress uncapped.

### Alternative 4: Zero reward on repeat (×0 instead of ×0.25)

- **Description**: Pay nothing for repeat clears.
- **Pros**: Hardest possible sink; eliminates any farming incentive entirely.
- **Cons**: Kills the reason to replay content at all. Endgame boss replays scale harder
  (rising replay cap) and drop cores/relics on a schedule; paying ×0 scraps makes the scrap
  half of those runs feel like a punishment and conflicts with the every-5th-clear core cache.
- **Estimated Effort**: Trivial.
- **Rejection Reason**: Too punitive. ×0.25 keeps replays mildly worthwhile (and lets the
  non-scrap drop systems carry the replay loop) without re-flooding the economy.

## Consequences

### Positive

- The one renewable faucet exploit (full-value repeat farming) is closed, so scarcity-driven
  systems (gacha pity, 100-scrap fusion, shop, wrench upgrades) retain their intended pacing.
- First-time completion stays maximally rewarding, reinforcing forward progression.
- Replays remain worth doing (×0.25 scraps + full XP + core/relic drops), so the endgame
  replay loop is intact without being a money printer.
- The Daily keeps its full retention pull: a single, generous, once-a-day reason to return,
  appropriate for a no-monetization single-player game.
- All multipliers have explicit, testable bounds (1.5× streak cap, NG+ gated by final clear),
  so the maximum payout is a known closed-form value, not an emergent surprise.

### Negative

- Reward logic is centralized in one VICTORY branch with several predicates (`isRepeatDefeat`,
  `isSingularityRepeat` with per-boss-type lookups). It is correct but dense; adding new
  repeatable content requires touching this branch and adding a matching defeat-tracking field.
- The clamp is client-side over an editable `localStorage` save — it shapes normal play but is
  not an anti-cheat boundary. (Accepted: irrelevant in single-player.)
- Two reward concepts (the repeat clamp and the daily exemption) must be kept in sync; a future
  edit that forgets the `!dailyNpc` guard would silently collapse the daily to ×0.25.

### Neutral

- The Daily's generosity is split across two files: the ×3 base lives in `dailyChallenge.js`,
  the streak multiplier application lives in `BattleScreen.jsx`. Intentional (faucet value vs.
  per-battle application), but anyone tuning the daily must look in both.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| A new repeatable scrap source is added without routing through the first/repeat branch, reopening the faucet | Medium | High | Implementation guideline mandates a defeat-tracking field + the shared branch for any new repeatable content; covered by economy GDD. |
| A refactor drops the `!dailyNpc` guard, collapsing the daily to ×0.25 | Low | Medium | Guard is documented here and asserted by the daily reward branch; add/keep a unit test that the daily pays ×3×streak, not ×0.25, on a repeat day. |
| Player edits `localStorage` to reset `defeatedNpcs` / `lastDailyCompleted` and re-farms full rewards | Medium | Low | Out of scope — single-player, no monetization; the clamp is pacing, not security. Accepted. |
| Daily streak/NG+ math drifts and exceeds intended ceiling | Low | Medium | Both are pure functions (`getDailyStreakMultiplier`, `applyNewGamePlus`) with hard caps/gates; unit-test the 1.5× cap and the NG+ final-clear gate. |

## Performance Implications

Negligible. The reward decision is a handful of array `.includes` / object lookups and integer
math executed once per battle resolution (a user-paced, non-frame-critical event). No
allocation in the hot path, no impact on frame time, memory, or load time.

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | n/a (per-battle, not per-frame) | < 0.1ms one-shot | 16.6ms/frame |
| Memory | negligible | negligible | n/a |
| Load Time | n/a | n/a | n/a |
| Network (if applicable) | n/a | n/a | n/a |

## Migration Plan

No migration required. The policy reads only fields already in `DEFAULT_SAVE`
(`defeatedNpcs`, `singularityProgress`, `remnantDefeated`, `mirrorAdminDefeated`,
`singularityComplete`, `lastDailyCompleted`, `dailyStreak`, `ngPlus`), all of which
`migrateSave` backfills for older saves. Older saves with `lastDailyCompleted: 0` /
`dailyStreak: 0` read as "daily never completed," which is the correct safe default.

This ADR is reverse-documentation of an already-shipped behavior; the DECISION (2026-06-16)
is to **keep** the current implementation, so there is no code change to migrate to.

**Rollback plan**: This documents existing behavior, so "rollback" means changing the policy
itself. To soften the daily (Alternative 1), edit the `* 3` constant in
`dailyChallenge.js getDailyChallenge`. To change the repeat clamp, edit the `* 0.25` factor in
the `BattleScreen.jsx` VICTORY branch. Both are single-constant changes that take effect on the
next battle resolution with no save migration.

## Validation Criteria

- [x] First clear of any NPC/boss pays full `scrapsReward`; the immediate next clear pays
      `floor(rawScraps * 0.25)`.
- [x] The Daily Challenge pays `~3×` the base NPC reward and is never reduced to ×0.25 on
      repeat days.
- [x] The Daily can be completed for full reward at most once per calendar day
      (`lastDailyCompleted === getDailySeed()`).
- [x] The daily streak multiplier never exceeds 1.5× and resets to 0 after a missed day.
- [x] The NG+ scrap/XP bonus is only reachable after a true-final clear
      (`startNewGamePlus` returns false otherwise).
- [ ] A regression test asserts the daily pays `×3×streak` (not `×0.25`) when re-fought on a
      subsequent eligible day, guarding the `!dailyNpc` exemption.

## GDD Requirements Addressed

<!-- This section is MANDATORY. Every ADR must trace back to at least one GDD
     requirement, or explicitly state it is a foundational decision with no GDD
     dependency. Traceability is audited by /architecture-review. -->

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/economy.md` | Economy (faucets & sinks) | The battle-reward faucet must not be a renewable, full-value source that trivializes scrap-driven sinks (gacha, fusion, shop, forge) | First-clear-full / repeat ×0.25 clamp in `BattleScreen.jsx` caps repeat farming while keeping first-completion rewarding; all compounding has hard caps/gates |
| `design/gdd/economy.md` | Economy (replay value) | Replaying content should stay worthwhile without re-flooding the currency | Repeats still pay ×0.25 scraps + full XP + core/relic drops, so the replay loop survives without being an exploit |
| `design/gdd/daily-challenge.md` | Daily Challenge | A generous once-per-day reward should drive daily return without becoming an exploit | Daily keeps ×3 base, is gated to once per calendar day (`lastDailyCompleted`/`getDailySeed`), and is exempted from the repeat clamp by design |
| `design/gdd/daily-challenge.md` | Daily Challenge (streaks) | Consecutive-day play should be incentivized but bounded | Streak multiplier caps at 1.5× and decays to 0 on a missed day (`getEffectiveStreak` / `getDailyStreakMultiplier`) |

## Related

- `src/BattleScreen.jsx` — VICTORY reward branch (the first-clear/repeat clamp, daily exemption, NG+ bonus)
- `src/dailyChallenge.js` — daily ×3 faucet, once-per-day gate, streak multiplier cap
- `src/persistence.js` — defeat-tracking fields and `completeDailyChallenge` / `startNewGamePlus` gates that drive the clamp
- ADR (TBD) on the Singularity endgame replay-reward / scaling loop — overlaps with the ×0.25 endgame repeat clamp documented here
