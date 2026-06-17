# ADR-0007: Fixed-TTK Post-Game Boss Scaling Derived from Real Player Damage/HP

## Status

Accepted

## Date

2026-06-16

## Last Verified

2026-06-16

## Decision Makers

Reverse-documented from implementation

## Summary

Singularity-arc bosses (mini-bosses, the three-phase Singularity, the Mirror
Admin, and the Corruption Remnants) must stay a real challenge regardless of how
over-levelled the player's roster is at endgame, without authoring per-level stat
tables. The decision is to compute each boss's HP and ATK at engage time from the
player's *actual* simulated damage output and HP — targeting a fixed turns-to-kill
(TTK) — rather than from static authored stats, via the pure function
`scaleBossForPlayer` (`src/singularityProgress.js:61–108`).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React 18 + Vite (browser build) |
| **Domain** | Core (combat balance / simulation) |
| **Knowledge Risk** | LOW — plain ES modules, no engine-version-specific API |
| **References Consulted** | `src/singularityProgress.js`, `src/singularityBosses.js`, `src/battleEngine.js`, `src/App.jsx`, `src/BattleScreen.jsx`, `design/gdd/singularity-endgame.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None for the browser build. The Godot port (`dragon-forge-godot/scripts/screens/battle_screen.gd:164–`) re-implements this *without* the replay multiplier and must be kept in parity if replays are added there. |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | The battle engine's level-scaling and damage formulas (`calculateStatsForLevel`, `getStageForLevel`, `calculateDamage` in `src/battleEngine.js`) — the scaler inverts the damage formula's constants. |
| **Enables** | Endgame replay loop and rising replay difficulty (`getReplayReward` in `src/persistence.js`); New Game+ and Corruption Remnant post-game content reusing the same scaler. |
| **Blocks** | None |
| **Ordering Note** | The damage formula `(atk × stageMult × powerScale × 2) − (def × 0.5)` (`battleEngine.js:43`) is a hard dependency: the scaler hand-inverts the `× 2` and `× 0.5` constants. Any change to that formula silently breaks the TTK target and both must change together. |

## Context

### Problem Statement

The Singularity arc is post-game content reached after the player has typically
maxed or near-maxed several dragons. Authored boss stats (`singularityBosses.js`)
are tuned around the *expected* engage level (15–40). A player who grinds to
level 50+ before engaging — or who returns to replay a boss — would walk through
authored bosses, turning the climax of the game into a one-shot. Conversely,
authored stats tuned for a high-level player would wall an under-levelled one.
There is no monetization or matchmaking lever to lean on; the only knob is the
boss's stat block, and it must be decided once because the arc is already shipped
as the game's ending.

### Current State

All Singularity bosses, the Mirror Admin, and the Corruption Remnants route
through `App.jsx`'s `handleEngageBoss` / `handleEngageRemnant`
(`App.jsx:124–158`). Both call `scaleBossForPlayer(config.boss, save)` and pass
the **scaled** boss object into `battleConfig.boss`, never the raw data constant.
`BattleScreen.initBattle` reads `battleConfig.boss` directly for stats and uses
`battleConfig.phases` for multi-phase transitions (`BattleScreen.jsx:101–120,
862–897`). The raw constants in `singularityBosses.js` are therefore *shape and
ratio templates*, not the numbers the player fights.

The combat damage formula is fixed at
`(attacker.atk × stageMult × powerScale × 2) − (defender.def × 0.5)`
(`battleEngine.js:43`), and per-level stat growth is
`calculateStatsForLevel(base, level, shiny)` (`battleEngine.js:74–81`).

### Constraints

- **Determinism**: balance must be unit-testable, so the scaler must be a pure
  function with no RNG (the damage formula itself rolls accuracy/crit, but the
  scaler uses a neutral approximation).
- **No per-level authoring**: solo project; no budget to hand-tune a stat table
  per engage level per boss.
- **Formula coupling**: the scaler must agree with the live damage formula's
  multiplicative/subtractive constants or the TTK target drifts.
- **Single-dragon fights**: bench/team support is disabled for the entire
  Singularity arc (`BattleScreen.jsx:135, 283–289`) precisely so the fixed-TTK
  math has one well-defined player power baseline.
- **Phase preservation**: multi-phase bosses must keep their per-phase HP/ATK
  *ratios* and authored element/move/sprite identity after scaling.

### Requirements

- A boss fight at any player level should complete in a consistent turn band
  (GDD acceptance target: 6–20 player turns, `singularity-endgame.md:478`).
- The player should win with a comfort margin at first clear (player-favoured),
  not face a coin-flip.
- Replays must get progressively harder, capped, so the endgame replay loop stays
  meaningful but does not spiral to impossible.
- Defensive against a save with zero owned dragons (must not divide-by-zero or
  crash).

## Decision

Derive boss HP and ATK at engage time from the player's representative dragon's
*actual* simulated stats, targeting a fixed turns-to-kill, instead of using the
authored static stats. Authored stats are demoted to ratio templates: DEF and SPD
pass through unchanged, and per-phase HP/ATK *weights* are derived from the
authored phase stats so phase identity (a tankier phase stays relatively tankier)
survives scaling.

The player baseline is the **highest-level owned dragon** (the likely pick),
re-simulated through the live `calculateStatsForLevel`. From its ATK and a neutral
move (power 1.0, no type/crit/def), the scaler estimates representative player
damage per hit; from its HP it derives how hard the boss must hit to reach the
target TTK. Both sides are then multiplied by a replay multiplier that rises per
clear, capped.

### Architecture

```
singularityBosses.js (RAW templates: HP/ATK ratios, DEF/SPD, element, moves, art)
        │
        │  config.boss  (raw constant)
        ▼
App.jsx  handleEngageBoss / handleEngageRemnant
        │
        │  scaleBossForPlayer(boss, save)  ── reads ──▶ save.dragons (player power)
        │                                  ── reads ──▶ save.singularityProgress.replayCounts
        │                                  ── uses  ──▶ battleEngine.calculateStatsForLevel
        │                                  ── uses  ──▶ battleEngine.getStageForLevel + stageMultipliers
        │                                  ── inverts ─▶ battleEngine.calculateDamage constants (×2, def×0.5)
        ▼
   scaledBoss  (HP/ATK rewritten to hit target TTK; DEF/SPD/identity preserved)
        │
        │  battleConfig.boss / battleConfig.phases
        ▼
BattleScreen.initBattle → uses scaledBoss stats verbatim; phase shifts read battleConfig.phases
```

### Key Interfaces

```js
// src/singularityProgress.js
// Pure, deterministic. Same (boss, save) → same scaled boss. No RNG.
export function scaleBossForPlayer(boss, save) -> ScaledBoss

// Tuning constants (module-private):
//   phasePlayerTtk(phaseCount) -> 3 (>=3 phases) | 4 (2 phases) | 6 (1 phase)
//   BOSS_SURVIVAL_MARGIN = 1.8   // >1 = player-favoured
//   REPLAY_STEP = 0.1            // +10% HP & ATK per prior clear
//   REPLAY_CAP  = 1.0            // capped at +100% (replayMult ≤ 2.0)

// Player baseline (singularityProgress.js:62–73):
//   pick highest-level OWNED dragon; pStats = calculateStatsForLevel(base, level, shiny)
//   fallback (no owned dragons): pLevel = boss.level || 30,
//                                base = { hp:100, atk:30, def:20, spd:20 }

// Anchors (singularityProgress.js:74–87):
//   estPlayerDmg = max(1, pStats.atk × stageMult × 2)        // neutral hit estimate
//   bossTtk      = perPhaseTtk × phaseCount × BOSS_SURVIVAL_MARGIN
//   targetBossDmg = pStats.hp / bossTtk
//   targetBossAtk = max(1, (targetBossDmg + pStats.def × 0.5) / 2)  // inverts damage formula

// Stat build (singularityProgress.js:89–94):
//   hp  = round(perPhaseTtk × estPlayerDmg × hpWeight × replayMult)
//   atk = round(targetBossAtk × atkWeight × replayMult)
//   def, spd = passed through from the raw template

// Multi-phase (singularityProgress.js:96–105):
//   hpWeight/atkWeight = phase.stats.hp / avgPhaseHp, phase.stats.atk / avgPhaseAtk
//   level = max(phase.level, pLevel)
//   returns { ...boss, phases: scaledPhases }
// Single-phase (107):
//   returns { ...boss, level: max(boss.level, pLevel), stats: buildStats(boss.stats,1,1) }
```

### Implementation Guidelines

- **Keep the scaler pure.** No `Math.random`, no `Date`, no reads outside the
  passed `boss` and `save`. This is what makes the balance unit-testable
  (GDD criterion `singularity-endgame.md:469`).
- **The two magic constants `× 2` and `def × 0.5` are not free parameters** —
  they mirror `battleEngine.calculateDamage` (`battleEngine.js:43`). If that
  formula changes, update `estPlayerDmg` and `targetBossAtk` in the same commit
  and re-run the TTK acceptance test.
- **DEF/SPD pass through unchanged on purpose.** The TTK target is HP/ATK driven;
  raw DEF means actual turns-to-kill lands slightly *above* `perPhaseTtk` (the
  damage formula subtracts `def × 0.5`), which is the intended safety buffer.
- **Always engage via the App handlers**, which apply the scaler. Never feed a raw
  `singularityBosses.js` constant into `battleConfig.boss`; the raw stats are
  templates, not battle values.
- **Tune via the named constants**, not inline numbers — see the Tuning section in
  `design/gdd/singularity-endgame.md:374–382` for safe ranges.

## Alternatives Considered

### Alternative 1: Static authored boss stats (no runtime scaling)

- **Description**: Ship the `singularityBosses.js` stat blocks as-is; the player
  fights exactly the authored numbers.
- **Pros**: Simplest possible; fully deterministic; trivially testable; balance is
  visible in one file.
- **Cons**: Endgame players are routinely 10–20+ levels above the authored boss
  level, so bosses become one-shot damage piñatas; the climax and replay loop
  collapse. Tuning for high-level players would wall under-levelled ones.
- **Estimated Effort**: Lowest (it is the pre-decision state of the data file).
- **Rejection Reason**: Fails the core requirement — fights do not stay a
  challenge across the player-power range, and there is no second knob to fix it.

### Alternative 2: Flat level-delta multiplier on authored stats

- **Description**: Scale authored HP/ATK by a function of `(playerLevel −
  bossLevel)`, e.g. `stats × (1 + 0.05 × levelDelta)`.
- **Description detail**: Cheap, intuitive, common in many RPGs.
- **Pros**: Simple; preserves authored stat *shape*; one multiplier to reason
  about.
- **Cons**: Level is a poor proxy for real power here — `calculateStatsForLevel`
  distributes a level budget across base stats, and `shiny` adds 1.2×, and stage
  multipliers compound, so two same-level dragons can differ substantially in
  effective damage. A level-delta scaler still produces HP sponges (it inflates
  HP without anchoring to how fast the player actually kills), which the code
  comment explicitly rejects (`singularityProgress.js:57–60`).
- **Estimated Effort**: Comparable to chosen approach.
- **Rejection Reason**: Targets the wrong variable. The audit goal was an explicit
  *fixed TTK decoupled from level*; a level-delta multiplier is still
  level-coupled and still produces damage sponges.

### Alternative 3: Difficulty selector (player-chosen scaling)

- **Description**: Let the player pick Easy/Normal/Hard, applying a global boss
  multiplier.
- **Pros**: Player agency; sidesteps the auto-balance problem.
- **Cons**: Adds UI, save fields, and balance surface for a solo project; pushes
  the tuning burden onto the player; does not solve the underlying "my numbers
  are meaningless relative to the player's" problem — it just exposes it as a
  slider. Conflicts with the arc's authored, narrative-driven difficulty curve.
- **Estimated Effort**: Higher (new UI + persistence + per-tier tuning).
- **Rejection Reason**: Out of scope and contrary to the arc's single-canonical
  difficulty design; creative/design call, not a technical balance fix.

## Consequences

### Positive

- Fights land in a consistent turn band at any player level (GDD target 6–20
  turns), preserving the climax for both grinders and minimalists.
- No per-level stat authoring: the data file holds *shape* (ratios, identity,
  art), the scaler supplies *magnitude*. Adding a new boss means authoring ratios
  only.
- Replays scale up smoothly (`+10%/clear`, capped at `+100%`), keeping the endgame
  replay loop meaningful and paired with the per-5-clear core reward
  (`persistence.js:250–`).
- Pure and deterministic → unit-testable balance.
- Phase identity is preserved through scaling (a tanky phase stays relatively
  tanky via per-phase weights).

### Negative

- **Hidden coupling to the damage formula.** The `× 2` and `def × 0.5` constants
  are duplicated from `battleEngine.calculateDamage`. A change there silently
  drifts the TTK target. This is the single biggest maintenance hazard.
- **The data file's HP/ATK numbers lie.** A reader of `singularityBosses.js` sees
  stats the player never actually fights, which is surprising without this ADR /
  the GDD note.
- **Cross-build divergence risk.** The Godot port re-implements the scaler minus
  the replay multiplier (`battle_screen.gd:164–`); parity must be maintained
  manually.
- DEF/SPD pass-through means the *exact* TTK is approximate (slightly above
  `perPhaseTtk`), so the turn count is a band, not a precise number.

### Neutral

- Boss `level` is bumped to `max(authored, playerLevel)` so XP rewards
  (`calculateXpGain`, `battleEngine.js:69`) stay proportionate; this changes the
  authored level but only upward.
- The single-dragon constraint for the whole arc (`BattleScreen.jsx:135`) is
  partly *because* of this decision — it keeps the player-power baseline
  well-defined.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Damage-formula change in `battleEngine.js` drifts TTK | Medium | High | Co-locate the constant dependency in this ADR + code comment (`singularityProgress.js:85–87`); add a TTK-band assertion to the scaler's unit tests so formula drift fails CI. |
| Zero owned dragons → divide-by-zero / NaN stats | Low | Medium | Explicit fallback baseline `{hp:100,atk:30,def:20,spd:20}` and `Math.max(1, …)` guards (`singularityProgress.js:71–72, 76, 87, 90–91`); engage button is also disabled with no owned dragon (GDD edge case `:343`). |
| Replay multiplier spirals out of reach | Low | Medium | `REPLAY_CAP = 1.0` clamps replayMult at 2.0× (`singularityProgress.js:55, 79`). |
| Godot port diverges from web balance | Medium | Low | Parity comment in `battle_screen.gd:164–165`; treat the web scaler as source of truth (per CLAUDE.md). |
| Shiny / fused-base / stage edge combos produce extreme baseline | Low | Medium | Baseline runs through the same `calculateStatsForLevel` + `stageMultipliers` the player uses, so it tracks real power; ratios + `Math.round`/`Math.max(1,…)` keep outputs sane. |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | n/a | One pure function call per boss engage (a few array reduces + arithmetic, O(phases)); not in a render/frame loop | < 1 ms (one-shot at engage, off the frame budget) |
| Memory | n/a | One shallow-cloned boss object (`{ ...boss }` + scaled phases array) per engage | Negligible |
| Load Time | n/a | No effect (runs at engage, not at load) | No change |
| Network (if applicable) | n/a | n/a (client-only) | n/a |

## Migration Plan

This is a reverse-documentation of an already-shipped decision; no migration is
pending. The historical transition from static stats to fixed-TTK scaling was:

1. Demote `singularityBosses.js` stat blocks from battle values to ratio
   templates (keep DEF/SPD meaningful, HP/ATK as relative weights).
2. Add `scaleBossForPlayer` as a pure function reading player power + replay
   counts; invert the live damage formula constants for ATK.
3. Route every Singularity/Remnant/Mirror-Admin engage through the scaler in
   `App.jsx` so `battleConfig.boss` is always scaled, never raw.
4. Verify TTK falls in the 6–20 turn band across the player-level range.

**Rollback plan**: Bypass the scaler by passing `config.boss` directly into
`battleConfig` in `handleEngageBoss` / `handleEngageRemnant`; the authored stats
in `singularityBosses.js` are still complete static blocks and would once again be
the fought values. (Not recommended — see Alternative 1.)

## Validation Criteria

- [ ] A boss fight at any player level completes in 6–20 player turns
  (GDD `singularity-endgame.md:478`).
- [ ] `scaleBossForPlayer` returns identical output for identical save state — no
  RNG (GDD `:469`).
- [ ] Zero-owned-dragons input does not throw and produces finite, ≥1 stats.
- [ ] Replay multiplier clamps at 2.0× once `replays × 0.1 ≥ 1.0`.
- [ ] Multi-phase bosses retain per-phase HP/ATK ratio ordering after scaling.
- [ ] DEF and SPD of the scaled boss equal the authored template values.

## GDD Requirements Addressed

<!-- This section is MANDATORY. Every ADR must trace back to at least one GDD
     requirement, or explicitly state it is a foundational decision with no GDD
     dependency. Traceability is audited by /architecture-review. -->

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/singularity-endgame.md` | Singularity Endgame — Fixed-TTK Boss Scaling (§ `:224–316`) | "All Singularity bosses, the Mirror Admin, and all Remnants use the fixed-TTK scaling system so fights last a consistent number of turns regardless of the player's current dragon level." (`:21`) | `scaleBossForPlayer` derives HP/ATK from the player's real simulated stats targeting `perPhaseTtk × phaseCount × BOSS_SURVIVAL_MARGIN` turns; applied at every engage via `App.jsx:124–158`. |
| `design/gdd/singularity-endgame.md` | Singularity Endgame — Acceptance Criteria | "A boss fight at any player level takes between 6 and 20 player turns to complete." (`:478`) | TTK anchor uses `pStats.hp / bossTtk` for boss ATK and `perPhaseTtk × estPlayerDmg` for boss HP; DEF pass-through keeps actual TTK slightly above target inside the band. |
| `design/gdd/singularity-endgame.md` | Singularity Endgame — Acceptance Criteria | "`scaleBossForPlayer` returns deterministic output for the same save state (pure function, no RNG)." (`:469`) | The function reads only `boss` and `save`, uses no RNG, and clones rather than mutating. |
| `design/gdd/singularity-endgame.md` | Singularity Endgame — Tuning Knobs (`:374–382`) & Edge Cases (`:343–348`) | Replay difficulty must rise but plateau; zero-dragon case must not crash. | `REPLAY_STEP`/`REPLAY_CAP` (`+10%/clear`, capped `+100%`) and the `{hp:100,atk:30,def:20,spd:20}` fallback with `Math.max(1,…)` guards. |

## Related

- `design/gdd/singularity-endgame.md` — the system GDD this ADR implements
  (Fixed-TTK Boss Scaling section, `:224–316`).
- Code: `src/singularityProgress.js:47–108` (`scaleBossForPlayer` + tuning
  constants), `src/singularityBosses.js` (boss ratio templates),
  `src/App.jsx:124–158` (engage handlers that apply the scaler),
  `src/BattleScreen.jsx:97–120, 862–897` (consumption of scaled stats and phase
  transitions), `src/battleEngine.js:43, 62–81` (the damage and level-scaling
  formulas this scaler depends on and inverts), `src/persistence.js:250–`
  (`getReplayReward`, paired with the rising replay multiplier).
- Cross-build: `dragon-forge-godot/scripts/screens/battle_screen.gd:164–`
  (Godot parity port, minus the replay multiplier — keep in sync).
