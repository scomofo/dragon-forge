# Hatchery — Gacha Pull System

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: P1 — Collection Is the Heartbeat

## Summary

The Hatchery is the primary dragon-acquisition mechanic: players spend DataScraps (the game's soft currency) to incubate eggs and receive random dragons drawn from a four-tier rarity pool. A pity counter guarantees a Rare-or-better result within every 10 consecutive pulls, and a 2% shiny variant chance adds a cosmetic + stat bonus on top of any roll. The system drives the collection loop and the early-game onboarding pull is free.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Persistence / Dragon XP Curve`, `Economy (DataScraps)`, `Dragon Codex (discovered flag)`

---

## Overview

Players visit the Quantum Incubation Lab (the Hatchery screen) to pull new dragons. Each pull costs 50 DataScraps (x10 bundle costs 500). The first pull ever is free, gating it behind no currency to eliminate new-player friction. A random dragon is drawn from a weighted rarity table; if the player already owns that dragon the pull converts to duplicate XP instead of a new unlock. A shiny variant has an independent 2% chance and applies a permanent +20% stat multiplier. The pity system resets after any Rare or Exotic result, guaranteeing one within every 10 pulls. All persistent state lives in the `save` object in `localStorage`.

---

## Player Fantasy

The player should feel the tension of instantiating an unknown guardian protocol — will this egg resolve as a Common spark or a rare Exotic presence? — combined with the satisfaction of building a personal bestiary. Every pull carries the possibility of something extraordinary — a gold-bordered Exotic, the rare shiny shimmer — even if most pulls land on Commons. Duplicate pulls should feel like progress, not waste, because XP immediately ticks up a level bar. The pity counter converts frustration into a countdown, turning a losing streak into mounting excitement rather than mounting disappointment.

Primary MDA aesthetics served: **Collection** (Discovery + Expression). Secondary: **Challenge** (resource pressure from pull cost).

---

## Detailed Design

### Core Rules

1. **Pull cost**: Each standard pull costs exactly 50 DataScraps (`PULL_COST = 50`, `src/gameData.js:360`). A x10 bundle costs 500 DataScraps and executes 10 independent pulls in sequence.
2. **Free first pull**: If every dragon in `save.dragons` has `owned: false`, the next x1 pull is free — no DataScraps are deducted (`src/HatcheryScreen.jsx:55-104`). The x10 button is hidden until the player has made at least one pull and owns a dragon.
3. **Rarity roll**: A weighted random draw selects one of four rarity tiers. Weights are cumulative: a `Math.random()` value in `[0, 1)` is reduced by each tier's `chance` in order (Common → Uncommon → Rare → Exotic) until the remainder reaches zero or below (`src/hatcheryEngine.js:16-21`).
4. **Element roll**: Within the selected rarity tier, one element is chosen uniformly at random from that tier's `elements` array (`src/hatcheryEngine.js:24-27`).
5. **Pity override**: If `pityCounter >= PITY_THRESHOLD - 1` (i.e., `>= 9`), the rarity roll is restricted to only Rare and Exotic, with their relative weights preserved. The draw cannot produce Common or Uncommon on a pity-trigger pull (`src/hatcheryEngine.js:5-13`).
6. **Pity counter management**: After each pull, if the result was Rare or Exotic, `pityCounter` resets to 0. Otherwise it increments by 1. The counter persists in `save.pityCounter` (`src/hatcheryEngine.js:39-47`).
7. **Shiny roll**: After rarity and element are decided, an independent roll checks `Math.random() < SHINY_CHANCE` (0.02). If the rarity tier carries `guaranteedShiny: true` (currently only Exotic), this check is bypassed and the result is always shiny (`src/hatcheryEngine.js:29-32`).
8. **New unlock**: If the drawn dragon is not yet owned (`dragon.owned === false`), it is set to `owned: true` and `discovered: true`. If the pull was shiny, `dragon.shiny` is set to `true` (`src/hatcheryEngine.js:57-62`).
9. **Duplicate handling**: If the drawn dragon is already owned, the player receives `50 * rarityMultiplier` XP applied to that dragon via the canonical `applyDragonXp()` curve — no second copy is created (`src/hatcheryEngine.js:63-64`).
10. **Shiny upgrade on duplicate**: If a duplicate pull is shiny and the owned dragon is not already shiny, `dragon.shiny` is upgraded to `true` even though the pull was a duplicate (`src/hatcheryEngine.js:65-67`).
11. **Discovered flag**: `discovered` is set to `true` on first unlock and never reverted, even if fusion later consumes the dragon (sets `owned: false`). Collection-count milestones count `discovered`, not `owned` (`src/persistence.js:6-8`).
12. **x10 pull sequencing**: All 10 pulls are resolved server-side (in JS) in a single loop before any animation begins. State is committed once. Only the first pull animates the full egg sequence; the remaining 9 appear immediately in a summary grid after a 500ms pause (`src/HatcheryScreen.jsx:128-152`).

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| `IDLE` | Initial load; after REVEAL or GRID dismissed | Player clicks PULL x1 or PULL x10 | Shows pull buttons and pity hint |
| `HATCHING` | Pull button clicked and cost deducted | Animation sequence completes, or player clicks to skip | Egg animation plays; pull result already committed to save |
| `REVEAL` | `HATCHING` completes | Player clicks anywhere | Single-result card shown: dragon sprite, rarity badge, NEW or +XP badge, shiny badge if applicable |
| `GRID` | 500ms after REVEAL when a x10 pull was performed | Player clicks anywhere | 10-card grid summary shown alongside the REVEAL result |

Clicking during `HATCHING` triggers skip: the animation jumps to burst frame 6 and fires the shell-shatter VFX immediately, then transitions to `REVEAL`.

### Interactions with Other Systems

- **Economy (DataScraps)**: Pulls debit `save.dataScraps`. The hatchery reads and writes this value directly through `loadSave()` / `writeSave()` in `persistence.js`.
- **Dragon Progression (XP/Level)**: Duplicate pulls call `applyDragonXp(dragon, xpGained)` from `persistence.js`. This is the canonical XP function shared by all XP sources (battle rewards, shop items). The hatchery does not define its own leveling logic.
- **Dragon Codex / Journal**: The `discovered` flag written by `applyPullResult` is read by the Journal screen and by milestone-check logic to count collection size.
- **Battle System**: The `shiny` flag stored on a dragon record is consumed by `calculateStatsForLevel()` in `battleEngine.js`, which applies a ×1.2 multiplier to all stats when `shiny === true`.
- **Fusion System**: `owned` can be reverted to `false` by fusion, but `discovered` is never reverted. Fusion does not interact with the hatchery pull flow.
- **Analytics / Stats**: Each pull (or batch of 10) calls `trackStat('totalPulls')` / `trackStat('totalPulls', 10)` for the lifetime stats screen.

---

## Formulas

### Rarity Roll (Normal Path)

```
roll = Math.random()            // uniform in [0, 1)
for each tier T in [Common, Uncommon, Rare, Exotic]:
    roll -= T.chance
    if roll <= 0: return T
return last tier                // fallback (floating-point safety)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| `T.chance` | float | see table | `src/gameData.js:353-358` | Probability weight for that tier |

**Rarity tier table** (`src/gameData.js:353-358`):

| Tier | `chance` | `elements` | `multiplier` | `guaranteedShiny` |
|------|----------|------------|-------------|-------------------|
| Common | 0.50 | fire, ice | 1 | — |
| Uncommon | 0.30 | storm, venom, stone | 2 | — |
| Rare | 0.15 | shadow | 3 | — |
| Exotic | 0.05 | void | 5 | true |

Total weight sums to 1.00.

### Rarity Roll (Pity Path — pityCounter >= 9)

```
rareAndAbove = [Rare, Exotic]
totalChance  = Rare.chance + Exotic.chance   // 0.15 + 0.05 = 0.20
roll = Math.random() * totalChance
for each tier T in rareAndAbove:
    roll -= T.chance
    if roll <= 0: return T
return Exotic                                // fallback
```

On the pity path: effective Rare probability = 0.15/0.20 = **75%**; effective Exotic probability = 0.05/0.20 = **25%**.

### Duplicate XP Award

```
xpGained = 50 * rarityMultiplier
```

| Rarity | `rarityMultiplier` | `xpGained` |
|--------|--------------------|------------|
| Common | 1 | 50 XP |
| Uncommon | 2 | 100 XP |
| Rare | 3 | 150 XP |
| Exotic | 5 | 250 XP |

Source: `src/hatcheryEngine.js:63`

### XP-to-Level Curve (shared, not hatchery-specific)

```
xpForLevel(L) = 50 + (L - 1) * 5
```

| Level | XP required to advance |
|-------|------------------------|
| 1 | 50 |
| 10 | 95 |
| 25 | 170 |
| 49 | 290 |
| 50 | cap — no further leveling |

Source: `src/persistence.js:188`. At level 50, `dragon.xp` is zeroed and no further XP accrues.

### Shiny Stat Multiplier (applied at battle time, not stored)

```
stat_value = floor((base + budget * (base / totalBase)) * mult)
mult = 1.2 if dragon.shiny else 1.0
```

Source: `src/battleEngine.js:74-81`. The 1.2 multiplier applies uniformly to hp, atk, def, and spd. It is calculated on each stat lookup, not baked into the stored dragon record.

---

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player owns all Rare/Exotic dragons before pity triggers | Pity pull still selects from the Rare/Exotic pool and awards duplicate XP | Pity guarantees a rarity tier, not a new unlock |
| Pull returns Exotic (guaranteedShiny: true) and dragon already owned + already shiny | Duplicate XP awarded at 5× multiplier; shiny flag unchanged | `dragon.shiny` is idempotent — setting true on already-true has no effect |
| Exotic drawn but player already owns the void dragon (the only Exotic element) | Always a duplicate result; awards 250 XP | Only one element maps to Exotic; 100% duplicate rate post-first-unlock |
| Light and Synthesis dragons never appear in pull pool | These dragons are not listed in any `rarityTier.elements` array. They are obtained only via Singularity completion (light) and Fusion (synthesis) | Intended; they are progression milestones, not gacha rewards |
| `pityCounter` reaches exactly `PITY_THRESHOLD - 1` (= 9) mid-x10 batch | The pity override fires for that specific pull within the batch; counter resets to 0 if Rare+ is drawn, and subsequent pulls in the same batch use the updated counter | Each pull in the x10 loop reads `currentSave.pityCounter` which has already been updated by `applyPullResult` |
| Player triggers x10 with exactly 500 DataScraps | Proceeds normally; balance reaches 0 | No floor check beyond the `canPull10` guard before button activation |
| `Math.random()` returns exactly 0.0 | First tier iterated (Common) triggers immediately (`0 - 0.50 <= 0`) | Correct behavior |
| `Math.random()` returns a value such that the loop exhausts all tiers without triggering | Fallback `return rarityTiers[rarityTiers.length - 1]` returns Exotic | Floating-point safety valve; in practice cannot occur when chances sum to 1.0 |
| Save data missing `pityCounter` key (legacy save) | `migrateSave()` sets `save.pityCounter = 0` (`src/persistence.js:81`) | Forward-compat handled in migration layer |

---

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| `persistence.js` — `applyDragonXp` | Hatchery depends on Persistence | Canonical XP curve; hatchery delegates all level-up math here |
| `persistence.js` — `loadSave / writeSave` | Hatchery depends on Persistence | All dragon state and currency reads/writes |
| `gameData.js` — `rarityTiers, SHINY_CHANCE, PITY_THRESHOLD, PULL_COST` | Hatchery depends on GameData | All tuning constants consumed by the roll logic |
| Dragon Codex / Journal | Codex depends on Hatchery | Reads `dragon.discovered` and `dragon.owned` flags written by `applyPullResult` |
| Battle System (`battleEngine.js`) | Battle depends on Hatchery (via save) | Reads `dragon.shiny` to apply ×1.2 stat multiplier in `calculateStatsForLevel` |
| Economy (DataScraps) | Bidirectional | Hatchery debits `dataScraps`; battles and milestones are the primary faucets |
| Fusion System | Hatchery produces inputs to Fusion | Fusion consumes owned dragons; `discovered` flag contract must be preserved |
| Animation Engine (`animationEngine.js`) | Hatchery depends on AnimationEngine | `eggBurst()` fires the shell-shatter particle effect on hatch frame 6 |
| Sound Engine (`soundEngine.js`) | Hatchery depends on SoundEngine | `playSound()` calls keyed to each animation phase (eggGlow, eggCrack, eggShake, hatchBurst, dragonReveal) |

---

## Tuning Knobs

All constants live in `src/gameData.js` unless noted. No values are hardcoded in the engine.

| Parameter | Current Value | File:Line | Category | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|-----------|----------|------------|-------------------|--------------------|
| `PULL_COST` | 50 DataScraps | `gameData.js:360` | Gate | 25–150 | Slower acquisition; more sessions needed | Faster acquisition; devalues currency |
| `PITY_THRESHOLD` | 10 | `gameData.js:362` | Gate | 5–20 | More frustration before guarantee | Rare+ feels almost always available; undermines tension |
| `SHINY_CHANCE` | 0.02 (2%) | `gameData.js:361` | Gate | 0.005–0.10 | Shiny feels common; loses prestige | Shiny becomes near-mythical |
| Common `chance` | 0.50 | `gameData.js:354` | Curve | — | Lowers average quality per pull | — |
| Uncommon `chance` | 0.30 | `gameData.js:355` | Curve | — | — | — |
| Rare `chance` | 0.15 | `gameData.js:356` | Curve | — | Raises baseline pull quality | — |
| Exotic `chance` | 0.05 | `gameData.js:357` | Curve | 0.01–0.10 | Exotic feels less special | Even longer expected wait for void dragon |
| Common duplicate XP (`50 * 1`) | 50 XP | `hatcheryEngine.js:63` | Curve | 25–200 | Duplicates level faster; reduces grind | Duplicates feel wasteful |
| Exotic duplicate XP (`50 * 5`) | 250 XP | `hatcheryEngine.js:63` | Curve | 100–500 | Significant; could trivially cap levels | Low; Exotic duplication feels punishing |
| Shiny stat multiplier | 1.2 (×1.2 all stats) | `battleEngine.js:78` | Curve | 1.05–1.5 | Shiny becomes balance-relevant (pay-to-win risk in PvP) | Shiny becomes purely cosmetic |

**Warning**: Adjusting `rarityTier.chance` values requires the four values to still sum to 1.0, or the fallback return path activates on high `Math.random()` values.

---

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Hatch initiated | Egg sprite switches from generic to element-specific sheet | — | Must-have |
| Egg glow (frame 1) | CSS class `egg-glow` on container | `eggGlow` sound | Must-have |
| Egg crack (frames 2–3) | Crack frames rendered from sprite sheet | `eggCrack` sound (×2) | Must-have |
| Egg shake (frames 4–5, repeated) | CSS class `egg-shake-anim` / `egg-shake-intense` | `eggShake` sound | Must-have |
| Burst (frame 6) | `eggBurst()` fires shell-shatter particle canvas effect; `egg-shake-intense` class | `hatchBurst` sound; `dragonReveal` sound after 200ms | Must-have |
| Dragon reveal | Dragon sprite with element-colored glow rays (`reveal-rays`), rarity badge, NEW or +XP badge | — | Must-have |
| Shiny reveal | Shiny sprite variant rendered; gold star `★` next to name; `+20% STATS` badge | — | High |
| Pity hint | Text "Rare+ guaranteed in N pulls" shown when `pityRemaining < 10` in IDLE state | — | High |
| x10 grid | 10-card summary grid after REVEAL | — | High |

---

## Game Feel

N/A — turn-based browser game. There is no frame-data, hitbox timing, input latency budget, controller rumble, or hit-stop applicable to the hatchery pull flow. The pull is initiated by a button click; the system responds with a CSS animation sequence. Subjective feel targets:

- The egg shake escalation (slow shake → fast shake → intense shake → burst) should feel like mounting anticipation resolving in a clean payoff.
- The skip interaction (click-to-skip during `HATCHING`) must jump immediately to the burst frame — no partial-animation limbo.
- The x10 grid should appear promptly after the single REVEAL to avoid the player feeling like they are waiting for a loading state.

---

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Pull cost | Pull x1 button label (`PULL x1 — 50◆`) | Static | Always (after first pull) |
| Bundle cost | Pull x10 button label (`PULL x10 — 500◆`) | Static | After first pull |
| Free pull label | Pull x1 button (`FREE PULL`) | One-time | Only when all dragons unowned |
| Pity countdown | Below egg container (`Rare+ guaranteed in N pulls`) | Per-pull | Only when `pityCounter > 0 AND < PITY_THRESHOLD` and phase is IDLE |
| Dragon name | REVEAL card | Per-pull | Always |
| Rarity badge | REVEAL card (CSS class matches tier name) | Per-pull | Always |
| NEW badge | REVEAL card | Per-pull | When `isNew === true` |
| +XP badge | REVEAL card (`+{xpGained} XP`) | Per-pull | When `isNew === false` |
| Shiny star ★ | Next to dragon name in REVEAL | Per-pull | When `pull.shiny === true` |
| +20% STATS badge | REVEAL card | Per-pull | When `pull.shiny === true` |
| Skip hint | Below egg | During HATCHING | Phase === HATCHING |
| Dismiss hint | Below egg | During REVEAL / GRID | Phase === REVEAL or GRID |
| Tutorial overlay | Full-screen modal | Once | Only on first visit (all dragons unowned) |

---

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| Duplicate XP feeds dragon level | `design/gdd/dragon-progression.md` | `applyDragonXp` XP curve and level cap (50) | Data dependency |
| DataScraps deducted on pull | `design/gdd/economy.md` | DataScraps faucet/sink balance | Rule dependency |
| `discovered` flag counts toward milestones | `design/gdd/journal-milestones.md` | Collection milestone count logic | State trigger |
| `shiny` flag enables ×1.2 stat multiplier | `design/gdd/combat.md` | `calculateStatsForLevel` shiny branch | Data dependency |
| Void dragon (Exotic) is only gachable void-element dragon | `design/gdd/dragon-progression.md` | Exotic pool composition | Rule dependency |
| Light and Synthesis dragons are excluded from pull pool | `design/gdd/dragon-progression.md` | Acquisition path definitions | Rule dependency |

> All referenced GDD files exist as of the 2026-06-16 reverse-documentation sprint.

---

## Acceptance Criteria

**Functional**

- [ ] A fresh save produces a free pull on first x1 click with no DataScraps deducted.
- [ ] After the free pull, all subsequent x1 pulls deduct exactly 50 DataScraps and x10 pulls deduct exactly 500.
- [ ] `pityCounter` increments by 1 after any Common or Uncommon result and resets to 0 after any Rare or Exotic result.
- [ ] When `pityCounter === 9`, the next pull draws only from Rare or Exotic; Common and Uncommon cannot be returned.
- [ ] Exotic pulls always produce a shiny dragon (`guaranteedShiny: true`); the 2% shiny roll is not consulted.
- [ ] Pulling a dragon the player already owns results in exactly `50 * rarityMultiplier` XP applied to that dragon's record, not a new `owned: true` entry.
- [ ] Pulling a non-shiny duplicate of an already-owned shiny dragon does NOT remove the shiny flag.
- [ ] Pulling a shiny duplicate of an already-owned non-shiny dragon upgrades `dragon.shiny` to `true`.
- [ ] `dragon.discovered` is set to `true` on first pull of any dragon and never reverted by subsequent operations.
- [ ] Light and Synthesis dragons cannot be obtained through any number of pulls.
- [ ] x10 pull button is hidden when player has zero owned dragons.
- [ ] After a x10 pull, all 10 results are committed to save before any UI animation begins.
- [ ] `trackStat('totalPulls', N)` is called with the correct count after each pull action.

**Experiential (playtest targets)**

- [ ] The egg animation escalation feels like genuine anticipation — at least 3/5 first-time players comment on the buildup unprompted.
- [ ] The skip-to-burst interaction feels instantaneous — no reviewer describes it as "laggy" or "stuck."
- [ ] Duplicate pulls with the XP badge feel like consolation progress rather than punishment — players with duplicates do not describe the system as "unfair" or "pay-to-win."
- [ ] The pity counter hint ("Rare+ in N pulls") is understood by players without explanation — at least 3/5 testers correctly explain what it means when asked.
- [ ] Exotic pulls are perceived as surprising and exciting even by players who have experienced multiple Exotics.

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should the x10 pull guarantee at least one Rare+ result as a separate mechanic (distinct from the pity counter)? | Game Designer | — | Not currently implemented; existing pity covers at most 10 pulls |
| Is Exotic's 100% post-first-unlock duplicate rate (only 1 element) intentional long-term? | Game Designer | — | Currently by design; may warrant a second Exotic element in a future expansion |
| Should shiny stat multiplier scale with rarity (e.g., Exotic shiny gets ×1.3 instead of ×1.2)? | Systems Designer | — | Currently flat ×1.2 for all rarities |
