# Dragon Progression

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: Mastery & Collection Growth

## Summary

Dragon Progression is the levelling system that tracks how individual dragons grow stronger through battle XP. Dragons gain levels from 1 to 50 along a smooth arithmetic XP curve, with every 12 XP-budget points per level distributed proportionally across that dragon's four stats. At three level thresholds the dragon advances to a new visual and combat Stage, applying a flat damage multiplier. Shiny dragons apply a flat 1.2x multiplier on top of all stats at every level.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `Combat (battleEngine)`, `Hatchery (hatcheryEngine)`, `Persistence (persistence.js)`

## Overview

Each owned dragon maintains a `level` (1–50) and an `xp` pool stored in the save file. When XP is added from any source — battle win, duplicate pull, shop item — it passes through a single canonical function (`applyDragonXp`) that walks the dragon up however many levels the XP covers and then stops at the cap of 50. Stats are not stored permanently; they are recomputed on demand from the dragon's base stats and current level via `calculateStatsForLevel`. Three stage thresholds (levels 8, 20, 38) determine which sprite tier is shown and which stage damage multiplier applies in combat.

## Player Fantasy

The player should feel their investment in a dragon accumulate over time. Winning battles with a fire dragon should make it visibly stronger — both numerically (higher ATK, HP) and aesthetically (new stage sprite). Shiny dragons should feel like a premium variant worth nurturing: the 1.2x stat bonus is always present, reinforcing that the player owns something special. The level cap at 50 provides a clear ceiling so players know exactly when a dragon is "done."

Target MDA aesthetics: **Challenge** (scaling difficulty and power), **Expression** (choosing which dragon to invest in), **Discovery** (unlocking stage sprites).

## Detailed Design

### Core Rules

1. **XP per level threshold**: The XP required to gain from level N to level N+1 is `50 + (N - 1) * 5`. At level 1 this is 50 XP; at level 49 (advancing to 50) this is 290 XP.
2. **Single canonical path**: All XP sources — battle wins, duplicate hatchery pulls, and shop items — call `applyDragonXp(dragon, amount)` in `src/persistence.js`. No XP source bypasses this function.
3. **Level cap**: A dragon cannot exceed level 50. When level 50 is reached, the XP pool is zeroed (`dragon.xp = 0`). XP granted beyond the cap is silently discarded.
4. **Stat computation**: Stats are never stored at runtime. They are recalculated from `baseStats` and `level` by `calculateStatsForLevel` every time they are needed (battle entry, stat display). The formula distributes a per-level budget of 12 points proportionally across the four stats based on each stat's share of the total base stat sum.
5. **Shiny multiplier**: If `dragon.shiny === true`, every computed stat (hp, atk, def, spd) is multiplied by 1.2 before floor. This is the last step in `calculateStatsForLevel`.
6. **Stage determination**: Stage is derived from level at call time via `getStageForLevel`. The stage is not stored; it is recomputed whenever needed.
7. **Stage combat multiplier**: In `calculateDamage`, the attacker's stage maps to a damage multiplier applied to the base damage calculation. Stage is a property of the combat state passed in — the battle engine reads it from `calculateStatsForLevel` output or from the NPC stat block.
8. **XP gain from battle**: The battle engine scales the NPC's `baseXP` by a ratio of `enemyLevel / playerLevel`, clamped to [0.25, 2.0], then floors the result. The minimum awarded is 1 XP.
9. **XP gain from duplicate pulls**: When a hatchery pull yields a dragon already owned, `applyPullResult` in `src/hatcheryEngine.js` awards `50 * rarityMultiplier` XP (Common=50, Uncommon=100, Rare=150, Exotic=250).

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Level 1–7 (Stage 1) | New dragon or level < 8 | Level reaches 8 | Stage 1 sprite; damage multiplier 0.6 |
| Level 8–19 (Stage 2) | Level >= 8 | Level reaches 20 | Stage 2 sprite; damage multiplier 0.8 |
| Level 20–37 (Stage 3) | Level >= 20 | Level reaches 38 | Stage 3 sprite; damage multiplier 1.0 |
| Level 38–50 (Stage 4) | Level >= 38 | Level cap (50) | Stage 4 sprite; damage multiplier 1.2 |
| Level cap | dragon.level == 50 | Never | dragon.xp fixed at 0; no further growth |

### Interactions with Other Systems

**Battle Engine**: On battle victory, the engine calls `calculateXpGain(npc.baseXP, playerDragon.level, npc.level)` to determine raw XP, then passes it to `addDragonXp`. The combat stat block passed to `resolveTurn` must include `stage` (derived from `getStageForLevel`) because `calculateDamage` reads `attacker.stage` to apply the multiplier.

**Hatchery Engine**: `applyPullResult` in `hatcheryEngine.js` calls `applyDragonXp` for duplicate pulls. The XP amount is `50 * rarityTier.multiplier`.

**Fusion Engine**: `fuseDragons` in `persistence.js` consumes two parent dragons (resetting level, xp, owned, shiny, fusedBaseStats back to defaults while preserving `discovered: true`) and writes the offspring at a calculated level. The offspring level must not exceed 50 (enforced by `offspringLevel = Math.min(offspringLevel, 50)`).

**Persistence**: All dragon state lives in `localStorage` under `dragonforge_save`. `applyDragonXp` mutates the dragon object in place; callers are responsible for writing back via `writeSave`. `addDragonXp` does this automatically as a full load-mutate-write cycle.

**UI / Sprite system**: `getDragonSprite(dragonId, stage)` in `gameData.js` maps the computed stage to a sprite path. Each dragon has four `stageSprites` entries keyed 1–4.

## Formulas

### XP Required Per Level (Threshold)

```
xpForLevel(N) = 50 + (N - 1) * 5
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| N | integer | 1–49 | current dragon level | Level being left (advancing from N to N+1) |

**Expected output range**: 50 (at N=1) to 290 (at N=49)

**Total XP to reach level 50 from level 1**: 8,330 XP

Example table (selected levels):

| Level N | XP to advance | Cumulative XP from L1 |
|---------|--------------|----------------------|
| 1 | 50 | 0 |
| 5 | 70 | 260 |
| 10 | 95 | 635 |
| 20 | 145 | 1,835 |
| 30 | 195 | 3,535 |
| 38 | 235 | 5,635 |
| 49 | 290 | 8,330 |

### Stat Growth at Level

```
budget   = (level - 1) * 12
totalBase = baseStats.hp + baseStats.atk + baseStats.def + baseStats.spd
statShare(base) = base / totalBase
grown(base) = floor((base + budget * statShare(base)) * mult)

where mult = 1.2 if dragon.shiny else 1.0
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| level | integer | 1–50 | dragon save | Current dragon level |
| budget | integer | 0–588 | computed | Total extra stat points from levelling |
| totalBase | integer | archetype sum | `gameData.js` dragon entry | Sum of all four base stats |
| base | integer | 8–112 | `gameData.js` | One of hp/atk/def/spd base values |
| mult | float | 1.0 or 1.2 | dragon.shiny | Shiny multiplier applied last |

**Implementation reference**: `src/battleEngine.js` `calculateStatsForLevel`, lines 74–81

**Example — Fire Dragon (base hp:110, atk:28, def:20, spd:18; totalBase=176) at level 5**:
- budget = 4 * 12 = 48
- hp:  floor((110 + 48*(110/176)) * 1.0) = floor(110 + 30) = 140
- atk: floor((28  + 48*(28/176))  * 1.0) = floor(28 + 7.6) = 35
- def: floor((20  + 48*(20/176))  * 1.0) = floor(20 + 5.4) = 25
- spd: floor((18  + 48*(18/176))  * 1.0) = floor(18 + 4.9) = 22

**Example — same dragon at level 1, shiny**:
- budget = 0, mult = 1.2
- hp: floor(110 * 1.2) = 132; atk: floor(28 * 1.2) = 33; def: floor(20 * 1.2) = 24; spd: floor(18 * 1.2) = 21

### Stage from Level

```
stage = 4  if level >= 38
stage = 3  if level >= 20
stage = 2  if level >= 8
stage = 1  otherwise
```

| Threshold key | Level | Stage entered |
|---------------|-------|---------------|
| stageThresholds[2] | 8 | 2 |
| stageThresholds[3] | 20 | 3 |
| stageThresholds[4] | 38 | 4 |

**Implementation reference**: `src/battleEngine.js` `getStageForLevel`, lines 62–67; `src/gameData.js` `stageThresholds`, line 23.

### Stage Damage Multiplier

```
damage contribution = attacker.atk * stageMultipliers[attacker.stage]
```

| Stage | Multiplier |
|-------|-----------|
| 1 | 0.6 |
| 2 | 0.8 |
| 3 | 1.0 |
| 4 | 1.2 |

**Implementation reference**: `src/gameData.js` `stageMultipliers`, line 20; applied in `src/battleEngine.js` `calculateDamage`, line 42.

### Battle XP Gain

```
ratio  = clamp(enemyLevel / playerLevel, 0.25, 2.0)
xpGain = max(1, floor(baseXP * ratio))
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| baseXP | integer | 25–90 (NPC table) | `gameData.js` npc entry | Fixed XP value on the NPC |
| playerLevel | integer | 1–50 | dragon save | Active dragon's current level |
| enemyLevel | integer | 2–12 (NPC table) | `gameData.js` npc entry | NPC's defined level |
| ratio | float | 0.25–2.0 | computed | Scales reward by relative difficulty |

**Expected output range**: 1 to 180 XP per battle (2× at most when outlevelled 2:1)

**Implementation reference**: `src/battleEngine.js` `calculateXpGain`, lines 69–72.

### Duplicate Pull XP

```
xpGained = 50 * rarityMultiplier
```

| Rarity | Multiplier | XP awarded |
|--------|-----------|-----------|
| Common | 1 | 50 |
| Uncommon | 2 | 100 |
| Rare | 3 | 150 |
| Exotic | 5 | 250 |

**Implementation reference**: `src/hatcheryEngine.js` `applyPullResult`, line 63.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| XP added when dragon is at level 50 | `applyDragonXp` exits the while loop immediately because `dragon.level < 50` is false; XP is zeroed (`dragon.xp = 0`) | Cap is hard; excess XP is not banked |
| XP formula called at N=50 | `xpForLevel(50) = 295` — this value is computed but the while-loop condition `dragon.level < 50` prevents it from being consumed | No behavioral impact but the formula technically extends |
| XP gain when playerLevel = 0 | Division by zero — this cannot occur in practice because dragons start at level 1 and `applyDragonXp` enforces the cap | Caller must never pass playerLevel = 0 |
| enemyLevel >> playerLevel | ratio is clamped at 2.0 so maximum award is `floor(baseXP * 2)` | Prevents runaway XP from extremely overlevelled enemies |
| enemyLevel << playerLevel | ratio is clamped at 0.25 so minimum award is `max(1, floor(baseXP * 0.25))` | Low-level grinding still awards some XP |
| Shiny flag set on duplicate pull | `dragon.shiny = true` applied by `applyPullResult`; next stat recalculation picks up the 1.2x | Upgrade is permanent; duplicate pulls can upgrade a non-shiny dragon |
| Offspring from fusion exceeds level 50 | `fuseDragons` clamps: `offspringLevel = Math.min(offspringLevel, 50)` | Fusion cannot circumvent the level cap |
| baseStats all equal (totalBase = 4*N) | Each stat's share is 0.25; budget distributed evenly | Formula remains valid; no division by zero |
| Dragon with fusedBaseStats | `calculateStatsForLevel` receives whatever `baseStats` the caller passes; if the caller passes `fusedBaseStats` this works identically | Fusion offspring with blended stats use the same growth formula |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| `src/persistence.js` | This system lives here | Owns `xpForLevel`, `applyDragonXp`, `addDragonXp`, `fuseDragons` — single source of truth |
| `src/battleEngine.js` | Depends on persistence XP curve | Calls `calculateXpGain`; calls `calculateStatsForLevel` to build combat state; calls `getStageForLevel` for stage sprite and multiplier |
| `src/hatcheryEngine.js` | Depends on persistence XP curve | Calls `applyDragonXp` for duplicate pull XP |
| `src/gameData.js` | Data dependency | Provides `stageThresholds`, `stageMultipliers`, per-archetype `baseStats` |
| `src/App.jsx` / battle entry points | Depends on this | Reads `dragon.level` and `dragon.xp` from save; passes computed stats into battle |
| Combat System (design/gdd/combat.md) | Rule dependency | Stage multiplier feeds directly into `calculateDamage`; XP gain feeds back into this system |
| Fusion System (design/gdd/fusion.md) | State trigger | Fusion resets parents and writes offspring at a capped level; offspring then participates in this system normally |
| Hatchery System (design/gdd/hatchery-gacha.md) | Data dependency | Duplicate pull XP values are defined by rarity multipliers in `gameData.js` |

## Tuning Knobs

All numeric constants live in source files — there are no external data files for this system currently. The values below are the current live values with their source locations.

| Parameter | Current Value | Safe Range | Category | Effect of Increase | Effect of Decrease | Source |
|-----------|--------------|------------|----------|-------------------|-------------------|--------|
| XP base (level 1) | 50 | 30–80 | Curve | Slower early levels | Faster early levels | `persistence.js` line 188 |
| XP ramp per level | 5 | 3–10 | Curve | Slower late-game grind | Flatter curve | `persistence.js` line 188 |
| Level cap | 50 | 30–99 | Gate | More content runway | Faster ceiling | `persistence.js` `applyDragonXp` |
| Stat budget per level | 12 | 8–18 | Curve | Larger power differential between levels | Flatter growth | `battleEngine.js` line 77 |
| Shiny multiplier | 1.2 | 1.05–1.5 | Curve | Shinies feel more premium; widens power gap | Shiny feels cosmetic only | `battleEngine.js` line 79 |
| Stage 2 threshold | Level 8 | 5–12 | Gate | Longer Stage 1; later sprite reveal | Earlier first evolution | `gameData.js` line 23 |
| Stage 3 threshold | Level 20 | 15–25 | Gate | Longer mid-game | Faster progression | `gameData.js` line 23 |
| Stage 4 threshold | Level 38 | 30–45 | Gate | Longer endgame grind | Stage 4 reached earlier | `gameData.js` line 23 |
| Stage 1 damage mult | 0.6 | 0.4–0.8 | Curve | Stage 1 dragons weaker in combat | Stage 1 dragons stronger | `gameData.js` line 20 |
| Stage 4 damage mult | 1.2 | 1.1–1.5 | Curve | Wider power spread across stages | Smaller reward for max stage | `gameData.js` line 20 |
| XP ratio min clamp | 0.25 | 0.1–0.5 | Curve | Less XP from trivial fights | Trivial fights remain more rewarding | `battleEngine.js` line 70 |
| XP ratio max clamp | 2.0 | 1.5–3.0 | Curve | More XP for punching up | Less benefit from difficult fights | `battleEngine.js` line 70 |

## Visual/Audio Requirements

N/A — turn-based browser game. Stage transitions (new sprite becoming available) are displayed when the battle results screen shows the new level. No animation frame budget applies. Audio cues for level-up and stage-advance are handled by `soundEngine.js` at the presentation layer and are not specified here.

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Level-up | Level number increments in dragon summary UI; XP bar fills and wraps | Level-up chime (soundEngine) | Must Have |
| Stage advance | Dragon sprite swaps to new stage art on next battle entry | Stage-up fanfare (soundEngine) | Must Have |
| Shiny flag set | Shiny indicator shown on dragon card | — | Should Have |

## Game Feel

N/A — turn-based browser game. Frame data, hit-stop, input latency, controller rumble, and animation startup/active/recovery frames do not apply. Progression feedback is communicated through number display and sprite changes between turns, not through real-time kinesthetics.

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Current level (1–50) | Dragon card / party screen | On any XP change | Always visible for owned dragons |
| XP bar (current / threshold) | Dragon card detail view | On any XP change | Always visible for owned dragons |
| Stage indicator | Dragon card and battle sprite | On stage change | Derived from level |
| Shiny indicator | Dragon card badge | On dragon.shiny set | When dragon.shiny === true |
| XP gained notification | Post-battle results screen | Per battle | After a won battle |

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| Stage multiplier feeds calculateDamage | `design/gdd/combat.md` | `stageMultipliers` applied in `calculateDamage` | Data dependency |
| Battle XP gain triggers applyDragonXp | `design/gdd/combat.md` | Battle win reward flow | State trigger |
| Fusion resets parents / writes offspring | `design/gdd/fusion.md` | `fuseDragons` parent reset and offspring level | State trigger |
| Duplicate pull XP uses rarity multipliers | `design/gdd/hatchery-gacha.md` | `rarityTier.multiplier` used to scale XP | Data dependency |

## Acceptance Criteria

**Functional**

- [ ] A dragon at level 1 with `baseXP=50` after a same-level fight receives exactly 50 XP.
- [ ] A dragon receiving enough XP to span multiple levels in one call levels up correctly (e.g., adding 200 XP to a level-1 dragon with 0 XP results in level 3 with 75 XP remaining: 50+55=105 consumed for L1→3, 200−105=95 remaining, then 95−60=35 remaining after L3 threshold of 60 — verify exact output via `calculateStatsForLevel` trace).
- [ ] A level 50 dragon receiving any amount of XP remains at level 50 with xp=0.
- [ ] `getStageForLevel(7)` returns 1; `getStageForLevel(8)` returns 2; `getStageForLevel(20)` returns 3; `getStageForLevel(38)` returns 4.
- [ ] `calculateStatsForLevel(fireBase, 5, false)` returns `{hp:140, atk:35, def:25, spd:22}`.
- [ ] `calculateStatsForLevel(anyBase, 1, true)` returns each stat floored at `floor(base * 1.2)`.
- [ ] `calculateXpGain(50, 10, 10)` returns 50; `calculateXpGain(50, 5, 10)` returns 100; `calculateXpGain(50, 10, 5)` returns 25.
- [ ] XP from all three sources (battle win, duplicate pull, fusion offspring) passes through `applyDragonXp` — no source writes `dragon.level` or `dragon.xp` directly.
- [ ] Fusion offspring level is capped at 50 regardless of parent levels.

**Experiential (playtesting)**

- [ ] A new player can observe their first dragon gain at least 2 levels within a single 5-minute play session.
- [ ] Players can predict their dragon's next stage advance by reading the displayed level and comparing to the known thresholds — no hidden timing.
- [ ] Shiny dragons visibly outperform their non-shiny counterparts in battles at the same level — the difference is noticeable without needing to read stat numbers.
- [ ] Stage 4 (level 38+) should feel like a meaningful power upgrade over Stage 3 — at least one playtester comments on the stat or sprite change unprompted.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should `fusedBaseStats` be used in `calculateStatsForLevel` for fusion offspring (to blend parent stats), or should the offspring use the archetype's default base stats? | game-designer | — | Currently `fusedBaseStats` is stored but the caller controls which stats are passed to `calculateStatsForLevel`; the fusion GDD should document the intended behavior explicitly. |
| Are tuning knobs intended to move to an external `assets/data/` file per the stated design standard? | lead-programmer | — | All progression constants are currently hardcoded in JS source files. Migration would make live tuning possible without a rebuild. |
