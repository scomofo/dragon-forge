# Singularity Endgame

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: Mastery through Collection — the arc converts every dragon-collection and campaign milestone into visible stakes, then caps the power fantasy with a permanent narrative consequence.

## Summary

The Singularity arc is the endgame content loop of Dragon Forge. As the player collects dragons and defeats campaign NPCs, a six-stage corruption meter rises and transforms the game's visual and audio presentation. Completing the arc — by defeating the four-boss Singularity gauntlet, then defeating the Mirror Admin true-final boss — unlocks the Light Dragon, surfaces New Game+ mode, and makes three Corruption Remnant post-game challenges available. The arc is designed so that earning the ending is inseparable from completing the rest of the game.

> **Quick reference** — Layer: `Feature` · Priority: `Full Vision` · Key deps: `battle-engine, persistence, campaign-map`

---

## Overview

The Singularity arc begins the moment a player owns at least two of the six base-element dragons and escalates through five corruption stages (1–5) before resolving at stage 0 on completion. Corruption stage is computed live from save state on every render: no separate timer or resource. The stage drives a CSS class (`corruption-stage-N`) on the root `<div class="app">` element, applying globally visible scan-line overlays, glitch animations, and chromatic-aberration effects that intensify as the player approaches the endgame.

When all four base-element campaign NPCs (`firewall_sentinel`, `bit_wraith`, `glitch_hydra`, `recursive_golem`) have been defeated, the Singularity screen becomes fully accessible and the player faces a linear gauntlet: three mini-bosses (Data Corruption, Memory Leak, Stack Overflow) followed by the three-phase final boss (The Singularity). Defeating The Singularity grants the Light Dragon and permanently flags `singularityComplete = true`. All seven boss battle log fragments must then be collected before the Mirror Admin (true-final) unlocks. Defeating the Mirror Admin routes to the Credits screen, enables New Game+, and opens the three Corruption Remnant post-game fights. All Singularity bosses, the Mirror Admin, and all Remnants use the fixed-TTK scaling system so fights last a consistent number of turns regardless of the player's current dragon level.

---

## Player Fantasy

The player should feel the weight of the world becoming more dangerous as a direct consequence of their own strength. Every dragon they hatch, every NPC they beat, visibly corrupts the screen — the world is reacting to them. When they finally face The Singularity, the UI should feel genuinely distressed. Defeating it should feel like pulling the plug on something that was going to kill everything. The Mirror Admin epilogue then reframes that victory: the player learns the thing they beat was a safety system gone wrong, and beating it was bittersweet mercy, not simple triumph.

Primary MDA aesthetics served: **Challenge** (the gauntlet structure with no shortcuts) and **Narrative** (the Mirror Admin's phaseLines arc from menace to tragedy). Secondary: **Discovery** (the Light Dragon reward is not telegraphed; the Remnants and NG+ are hidden post-game layers).

---

## Detailed Design

### Core Rules

#### Corruption Stage Gate (`singularityProgress.js:16–29`)

The corruption stage is a pure function of the live save state. It is re-evaluated on every app render via `getSingularityStage(save)` in `App.jsx:48`.

1. If `save.singularityComplete === true`, return stage **0** (arc resolved, corruption gone).
2. Count base-element dragons currently owned (`fire`, `ice`, `storm`, `stone`, `venom`, `shadow`). Call this `ownedCount`.
3. Check whether any dragon in the roster has `level >= 50`. Call this `hasElder`.
4. Check whether all four base NPC IDs (`firewall_sentinel`, `bit_wraith`, `glitch_hydra`, `recursive_golem`) are in `save.defeatedNpcs`. Call this `allNpcsDefeated`.
5. Apply thresholds in descending priority:
   - `allNpcsDefeated` → stage **5**
   - `hasElder` → stage **4**
   - `ownedCount >= 6` → stage **3**
   - `ownedCount >= 4` → stage **2**
   - `ownedCount >= 2` → stage **1**
   - else → stage **0**

Stage 0 applies no CSS class. Stages 1 applies no class either (the class is only added for `stage >= 2`, `App.jsx:190`). Stages 2–5 add `.corruption-stage-N` to the root element.

#### Singularity Screen Unlock (`singularityProgress.js:31–35`)

`isSingularityUnlocked(save)` returns `true` if:
- `save.singularityComplete === true`, OR
- `'protocol_vulture'` is in `save.defeatedNpcs`.

The Singularity screen navigation route (`App.jsx:96–98`) is gated by this function at the NavBar level; the screen itself is always rendered but the nav link is hidden/disabled when locked.

#### Boss Unlock Chain (linear sequential)

Within the Singularity screen, `getBossStatus(boss, save)` (`singularityBosses.js:163–186`) evaluates per-boss state:

| Boss | Unlock Condition |
|------|-----------------|
| Data Corruption | Always available once Singularity screen is unlocked |
| Memory Leak | `data_corruption` in `singularityProgress.defeated` |
| Stack Overflow | `memory_leak` in `singularityProgress.defeated` |
| The Singularity (final) | All three mini-bosses in `singularityProgress.defeated` |
| Mirror Admin | `save.singularityComplete === true` AND all 7 fragment IDs (`001`–`007`) in `save.flags.fragmentsUnlocked` |

A boss that is neither `available` nor `defeated` renders as `locked` (greyed card, `???` name, lock icon). A `defeated` boss can still be re-engaged for replay rewards.

#### Mini-Boss Data (`singularityBosses.js:3–63`)

Pre-scaling base stats (actual values used in scaling formula as weights only):

| Boss | Element | Base Level | HP | ATK | DEF | SPD | Base XP | Scraps Reward |
|------|---------|-----------|-----|-----|-----|-----|---------|---------------|
| Data Corruption | fire | 15 | 140 | 30 | 18 | 16 | 100 | 200 |
| Memory Leak | ice | 20 | 120 | 26 | 24 | 22 | 150 | 300 |
| Stack Overflow | storm | 25 | 100 | 34 | 14 | 30 | 200 | 400 |

All three mini-bosses use `difficulty: 'Singularity'`, arena `shadow.png` with filter `grayscale(0.5) hue-rotate(330deg) contrast(1.3)`, and bespoke portrait art.

Move assignments:
- Data Corruption: `magma_breath`, `flame_wall`
- Memory Leak: `frost_bite`, `blizzard`
- Stack Overflow: `lightning_strike`, `thunder_clap`

Each mini-boss drops one lore fragment (IDs `001`, `002`, `003` respectively).

#### Final Boss — The Singularity (`singularityBosses.js:65–111`)

Three-phase fight. Player HP carries across phases. Phase changes trigger new sprite and element.

Pre-scaling base stats (actual values used as hp/atk weight ratios):

| Phase | Name | Element | Base Level | HP | ATK | DEF | SPD |
|-------|------|---------|-----------|-----|-----|-----|-----|
| 1 | Ignition | fire | 30 | 130 | 32 | 18 | 18 |
| 2 | Surge | storm | 30 | 150 | 36 | 20 | 26 |
| 3 | Void Collapse | void | 30 | 180 | 40 | 22 | 32 |

Moves: Phase 1 uses `magma_breath`, `flame_wall`; Phase 2 uses `lightning_strike`, `thunder_clap`; Phase 3 uses `void_rift`, `null_reflect`.

Drops fragments `004`–`007` (four fragments, IDs `004`, `005`, `006`, `007`). `baseXP: 500`, `scrapsReward: 1000`.

On defeat, `markSingularityComplete()` (`persistence.js:309–320`) sets:
- `save.singularityComplete = true`
- `save.singularityProgress.finalBossPhase = 4`
- Increments `replayCounts['the_singularity']`
- Grants `save.dragons.light.owned = true` and `discovered = true`

#### Mirror Admin — TRUE FINAL (`singularityBosses.js:113–159`)

Three-phase fight. `difficulty: 'TRUE FINAL'`. Requires `singularityComplete` AND all 7 fragments.

Pre-scaling base stats:

| Phase | Name | Element | Base Level | HP | ATK | DEF | SPD |
|-------|------|---------|-----------|-----|-----|-----|-----|
| 1 | Protocol | shadow | 35 | 150 | 38 | 18 | 20 |
| 2 | Warden | void | 38 | 165 | 42 | 20 | 28 |
| 3 | Great Reset | light | 40 | 190 | 48 | 24 | 34 |

Moves: Phase 1 uses `shadow_strike`, `void_pulse`; Phase 2 uses `void_rift`, `null_reflect`; Phase 3 uses `radiant_beam`, `solar_flare`.

Each phase has a `phaseLines` entry voiced in the battle log at phase-start. The three lines progressively reveal the Mirror Admin as a safety system that lost sight of what it was protecting (review finding #8). `baseXP: 1000`, `scrapsReward: 2000`.

On defeat, `markMirrorAdminDefeated()` (`persistence.js:291–298`) sets `save.mirrorAdminDefeated = true` and increments `replayCounts['mirror_admin']`. Winning the Mirror Admin battle routes to the Credits screen (`App.jsx:186`). Any other outcome (defeat, or re-engage while already defeated) routes back to the Singularity screen.

#### Corruption Remnants — Post-Game (`singularityBosses.js:188–309`)

Available only when `save.singularityComplete === true` (`getRemnantProgress`, `singularityProgress.js:37–45`). Three three-phase fights, unlocked sequentially. Each Remnant is a harder version of the corresponding mini-boss.

| Remnant | Unlock | Base XP | Scraps |
|---------|--------|---------|--------|
| Data Corruption — Remnant | Immediately on singularityComplete | 300 | 600 |
| Memory Leak — Remnant | `data_corruption_remnant` in `remnantDefeated` | 420 | 840 |
| Stack Overflow — Remnant | `memory_leak_remnant` in `remnantDefeated` | 560 | 1120 |

Remnant phase stats (pre-scaling):

**Data Corruption — Remnant:**
- Phase I (fire, L22): HP 140, ATK 42, DEF 25, SPD 22
- Phase II (venom, L24): HP 168, ATK 48, DEF 21, SPD 26
- Phase III (shadow, L26): HP 196, ATK 56, DEF 17, SPD 31

**Memory Leak — Remnant:**
- Phase I (ice, L28): HP 120, ATK 36, DEF 34, SPD 31
- Phase II (storm, L30): HP 148, ATK 42, DEF 30, SPD 37
- Phase III (void, L32): HP 168, ATK 52, DEF 24, SPD 44

**Stack Overflow — Remnant:**
- Phase I (storm, L35): HP 100, ATK 48, DEF 20, SPD 42
- Phase II (shadow, L37): HP 120, ATK 55, DEF 16, SPD 49
- Phase III (void, L40): HP 140, ATK 65, DEF 12, SPD 56

Remnants shift element between phases, preventing any single element from trivializing the entire fight. On defeat, `recordRemnantDefeat(remnantId)` (`persistence.js:300–307`) appends the ID to `save.remnantDefeated` and routes back to the Singularity screen.

#### Light Dragon Reward

Granted automatically inside `markSingularityComplete()`. Retroactively granted to saves that completed the arc before the field existed (via `migrateSave`, `persistence.js:112–116`). The Light Dragon's element has the following type effectiveness (`gameData.js:16`):

- Deals 2.0× to venom and shadow; 0.5× to void; 1.0× to all others.

#### New Game+ (`persistence.js:424–441`)

Offered in the Singularity screen left panel once `save.mirrorAdminDefeated === true`. Requires an explicit two-step confirmation in the UI (`confirmingNg` state, `SingularityScreen.jsx:88–99`).

`startNewGamePlus()` guards on `save.mirrorAdminDefeated` being `true` before proceeding. It calls `applyNewGamePlus(save)` which:
- Increments `save.ngPlus` by 1
- Resets `save.defeatedNpcs = []`
- Resets `save.singularityProgress` to `{ defeated: [], finalBossPhase: 0, replayCounts: {} }`
- Resets `save.singularityComplete = false`
- Resets `save.mirrorAdminDefeated = false`
- Resets `save.remnantDefeated = []`
- Resets `save.flags.currentAct = 1` and `save.flags.fragmentsUnlocked = []`

**Kept across NG+**: all dragons (owned, levels, shiny), `dataScraps`, `inventory.cores`, `milestones`, `records`, `stats`, `skye` progression.

The UI description in `SingularityScreen.jsx:86–87` states "Enemies +25% / rewards +25% per tier." The `save.ngPlus` counter is available to scaling logic; confirming the actual enemy-scaling wiring requires reading the campaign map and battle screen entry paths, which is outside the scope of this document.

---

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Stage 0 (Dormant) | New save, or `singularityComplete = true` | Own 2+ base dragons | No visual effect; Singularity nav potentially hidden |
| Stage 1 (Anomaly) | 2+ base dragons owned | 4+ base dragons owned OR `hasElder` OR `allNpcsDefeated` | No CSS class applied (class only from stage 2) |
| Stage 2 (Signal) | 4+ base dragons owned | 6+ owned OR `hasElder` OR `allNpcsDefeated` | `.corruption-stage-2`: scan-line overlay, nav ticker jitter |
| Stage 3 (Unstable) | 6 base dragons owned | `hasElder` OR `allNpcsDefeated` | `.corruption-stage-3`: stronger scan-lines, chromatic fringe, nav flicker, card glitch |
| Stage 4 (Breach Imminent) | Any dragon at level 50 | `allNpcsDefeated` | `.corruption-stage-4`: heavy scan-lines, static flash, Felix portrait skew, ticker jitter |
| Stage 5 (The Singularity) | All 4 base NPCs defeated | `singularityComplete = true` | `.corruption-stage-5`: all stage-4 effects plus screen micro-shake, heavy border pulse, fast static |
| Post-completion | `singularityComplete = true` | — | Stage resets to 0. Remnants and Mirror Admin unlock paths open. |

The transition from stage 5 → 0 on `singularityComplete` is abrupt (no animation), which reinforces the "plug pulled" narrative beat.

---

### Interactions with Other Systems

**Battle Engine**: All Singularity bosses, the Mirror Admin, and all Remnants are routed through the standard battle engine via `handleEngageBoss` / `handleEngageRemnant` (`App.jsx:124–157`). The boss object passed to the battle engine is the scaled output of `scaleBossForPlayer`, not the raw data constant. Phase progression is handled by the battle screen using the `phases` array on the boss config.

**Persistence**: Every boss defeat writes to `localStorage` via the named persistence helpers. No battle state is held in React component state; it is always re-read from storage on screen return via `refreshSave()`.

**Campaign Map**: Defeating the four base NPCs (`firewall_sentinel`, `bit_wraith`, `glitch_hydra`, `recursive_golem`) on the Campaign Map is the primary gate for stage 5 and Singularity screen access. The campaign map writes to `save.defeatedNpcs` via `recordNpcDefeat`.

**Sound Engine**: Navigating to the Singularity screen plays `'singularity'` music (looped). Engaging the Mirror Admin plays `'mirrorAdminSpawn'` sound effect before music. Winning the Mirror Admin plays `'victoryFanfare'` then switches music to `'title'`. NG+ start plays `'newGamePlusStart'`.

**Credits Screen**: The Mirror Admin victory is the only path that routes to `SCREENS.CREDITS` (`App.jsx:186`).

**Journal / Lore Fragments**: Fragments are written to `save.flags.fragmentsUnlocked` by `unlockFragment(fragmentId)`. The Mirror Admin unlock check reads this array and requires all 7 IDs (`001`–`007`).

---

## Formulas

### Fixed-TTK Boss Scaling (`singularityProgress.js:61–108`)

This scaling system (referenced in ADR-0007) ensures every Singularity-tier fight lasts approximately the same number of player turns regardless of the player's dragon level, preventing both one-shots and damage-sponge scenarios.

**Step 1: Player baseline**

```
pLevel  = highest owned dragon's current level (fallback: boss.level or 30)
pBase   = that dragon's fusedBaseStats || gameData.dragons[id].baseStats || { hp:100, atk:30, def:20, spd:20 }
pStats  = calculateStatsForLevel(pBase, pLevel, shiny)
pStageMult = stageMultipliers[getStageForLevel(pLevel)]   // {1:0.6, 2:0.8, 3:1.0, 4:1.2}
```

**Step 2: Estimated player damage per hit**

```
estPlayerDmg = max(1, pStats.atk × pStageMult × 2)
```

This is a neutral approximation (move power 1.0, no type modifier, no crit, no def subtraction) used as the TTK anchor.

**Step 3: Replay multiplier**

```
replays    = save.singularityProgress.replayCounts[boss.id] || 0
replayMult = 1 + min(REPLAY_CAP, replays × REPLAY_STEP)
           = 1 + min(1.0, replays × 0.1)
```

The replay multiplier caps at 2.0× (100% increase after 10 clears).

**Step 4: Per-phase TTK target**

```
phaseCount   = boss.phases.length    // 1 for mini-bosses; 3 for multi-phase
perPhaseTtk  = 3   (if phaseCount >= 3)
             = 4   (if phaseCount == 2)
             = 6   (if phaseCount == 1)
bossTtk      = perPhaseTtk × phaseCount × BOSS_SURVIVAL_MARGIN
             = perPhaseTtk × phaseCount × 1.8
```

For a 3-phase boss: `bossTtk = 3 × 3 × 1.8 = 16.2 total player turns`.
For a 1-phase mini-boss: `bossTtk = 6 × 1 × 1.8 = 10.8 total player turns`.

**Step 5: Target boss damage per turn**

```
targetBossDmg = pStats.hp / bossTtk
```

The boss should KO the player in `bossTtk` turns if the player never defends. Player wins with a margin of `BOSS_SURVIVAL_MARGIN` (1.8×).

**Step 6: Target boss ATK stat**

Inverting the damage formula (`dmg = atk×1.0×1.0×2 − playerDef×0.5`):

```
targetBossAtk = max(1, (targetBossDmg + pStats.def × 0.5) / 2)
```

**Step 7: Build scaled stats per phase**

```
bossHp[phase]  = max(1, round(perPhaseTtk × estPlayerDmg × hpWeight × replayMult))
bossAtk[phase] = max(1, round(targetBossAtk × atkWeight × replayMult))
bossDef[phase] = phase.stats.def   (unchanged)
bossSpd[phase] = phase.stats.spd   (unchanged)
```

Where `hpWeight` and `atkWeight` for multi-phase bosses are each phase's raw HP/ATK divided by the average HP/ATK across all phases, preserving the relative difficulty curve across phases while anchoring absolute numbers to the player.

For single-phase bosses both weights are `1`.

**Step 8: Level floor**

```
scaledLevel = max(boss.level, pLevel)
```

Boss level is floored at the player's highest dragon level, preventing level-based type advantages from breaking in the player's favor.

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `pStats.hp` | int | 1–∞ | `calculateStatsForLevel` (battleEngine) |
| `pStats.atk` | int | 1–∞ | `calculateStatsForLevel` (battleEngine) |
| `pStats.def` | int | 1–∞ | `calculateStatsForLevel` (battleEngine) |
| `pStageMult` | float | 0.6–1.2 | `stageMultipliers` (gameData) |
| `replayMult` | float | 1.0–2.0 | replay count × 0.1, capped at +1.0 |
| `perPhaseTtk` | int | 3–6 | phase count lookup |
| `BOSS_SURVIVAL_MARGIN` | float | 1.8 | constant |

**Expected output**: Boss HP and ATK are always proportional to the player's current power. At minimum player power (level 1, no shiny, stage 1), a mini-boss has approximately `6 × max(1, 100×0.6×2) = 6 × 120 = 720 HP` before replay scaling, but DEF and SPD are always the raw data values and the damage formula's subtraction term (`def × 0.5`) means actual turns-to-kill is slightly above `perPhaseTtk`.

### Replay Reward (`persistence.js:252–265`)

Every 5th cumulative clear of any Singularity-tier boss yields a core cache:

```
clearCount = replayCounts[bossId]   (incremented each engagement, win or loss? — only on win; see recordSingularityDefeat)
reward     = 5 cores of element[((clearCount / 5) - 1) % 6]
```

Elements cycle through `['fire', 'ice', 'storm', 'stone', 'venom', 'shadow']` in order. Core counts cap at 99.

### XP Gain

```
xpGain = max(1, floor(boss.baseXP × min(2, max(0.25, enemyLevel / playerLevel))))
```

Standard `calculateXpGain` (`battleEngine.js:69–72`). Singularity bosses have `baseXP` ranging from 100 (Data Corruption) to 1000 (Mirror Admin).

---

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player has no owned dragons when Singularity screen opens | `selectedDragonId` defaults to `'fire'`; the engage button is disabled because `ownedDragons` is empty | Prevents crash; player cannot engage a boss without a dragon |
| `scaleBossForPlayer` called with zero owned dragons | Falls back to `pLevel = boss.level || 30`, base stats `{ hp:100, atk:30, def:20, spd:20 }` | Defensive; should not occur in normal flow since the engage button requires an owned dragon |
| Mirror Admin engaged after `mirrorAdminDefeated = true` | `getBossStatus` returns `'defeated'`; status `'defeated'` still allows engagement (canEngage = true); replay increments via `markMirrorAdminDefeated` again | Allows replays; credits only shown when `won === true` in `handleSingularityBattleEnd` |
| Player loses to Mirror Admin | `wonMirrorAdmin = false`; routes back to Singularity screen, not Credits | Defeat overlay's "TRY AGAIN" calls `handleSingularityBattleEnd(false)` explicitly |
| `save.singularityComplete` set while player is viewing a boss's detail | Stage recalculates on next `refreshSave()` (next battle end or navigation); CSS class updates on re-render | Eventual consistency; no mid-session re-render |
| Replay count reaches 10 (`REPLAY_CAP` hit at +100% scaling) | `replayMult` clamps at 2.0×; further replays do not increase difficulty | Prevents unbounded power spiral; confirmed by `min(REPLAY_CAP, replays × REPLAY_STEP)` |
| All 7 fragments needed for Mirror Admin — fragment 007 belongs to the final boss | Player must defeat The Singularity before Mirror Admin unlocks, which grants fragment 007 as part of `FINAL_BOSS.fragmentIds` | Structural dependency; Mirror Admin cannot be skipped to |
| NG+ started, then player loses to a Singularity boss | Treat as normal loss; `defeatedNpcs` was reset so stage returns to 0 and the full arc must be re-run | Intended; NG+ is a fresh run |
| `migrateSave` on a pre-light-dragon save with `singularityComplete = true` | `dragons.light` is granted retroactively (`persistence.js:112–116`) | Forward-compatibility migration |

---

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| `battleEngine.js` | Singularity depends on Battle Engine | `calculateStatsForLevel`, `getStageForLevel`, `calculateXpGain` used directly in `scaleBossForPlayer` and XP award |
| `gameData.js` | Singularity depends on Game Data | `stageMultipliers`, `typeChart`, `dragons` (base stats), `moves` (boss move pools) |
| `persistence.js` | Bidirectional | Singularity reads/writes all arc state; persistence exports the save schema and helpers |
| `singularityBosses.js` | `singularityProgress.js` depends on boss data | `scaleBossForPlayer` takes a boss object from `singularityBosses.js` |
| Campaign Map (NPC battles) | Singularity depends on Campaign Map | Defeating `firewall_sentinel`, `bit_wraith`, `glitch_hydra`, `recursive_golem` via `recordNpcDefeat` is required for stage 5 and screen access |
| Journal / Fragments | Singularity depends on Journal | `save.flags.fragmentsUnlocked` array (written by `unlockFragment`) is the Mirror Admin gate |
| `App.jsx` | Singularity depends on App router | `handleEngageBoss`, `handleEngageRemnant`, `handleSingularityBattleEnd` live in App; the Singularity screen receives them as props |
| Sound Engine | Singularity depends on Sound | Music track `'singularity'` plays on screen entry; `'mirrorAdminSpawn'` and `'victoryFanfare'` on specific events |
| Credits Screen | Credits depends on Singularity | Mirror Admin victory is the only path to `SCREENS.CREDITS` |

---

## Tuning Knobs

All tuning constants live in `src/singularityProgress.js:50–55` unless noted.

| Parameter | Current Value | Safe Range | Category | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|----------|-------------------|-------------------|
| `BOSS_SURVIVAL_MARGIN` | 1.8 | 1.2–2.5 | Feel | Boss hits less hard relative to player HP; fights feel safer | Boss becomes more lethal; higher failure rate |
| `REPLAY_STEP` | 0.1 | 0.05–0.2 | Curve | Harder scaling per replay; power wall reached in fewer clears | Gentler slope; more replays before cap |
| `REPLAY_CAP` | 1.0 | 0.5–2.0 | Gate | Higher cap; final difficulty plateau is more extreme | Fights plateau at a lower difficulty ceiling |
| `perPhaseTtk` (3-phase) | 3 | 2–5 | Feel | Longer per-phase fights; less sense of urgency | Faster phase transitions; more chaotic pace |
| `perPhaseTtk` (2-phase) | 4 | 3–6 | Feel | Same as above | Same as above |
| `perPhaseTtk` (1-phase) | 6 | 4–10 | Feel | Single-phase fights drag; pacing feels loose | Mini-bosses feel too easy / fast |
| Boss `scrapsReward` (mini) | 200/300/400 | 100–600 | Curve | More economy injection per fight | Less incentive to re-engage |
| Boss `scrapsReward` (final) | 1000 | 500–2000 | Curve | Larger economy spike at arc completion | Reduced completion payoff |
| Boss `scrapsReward` (Mirror Admin) | 2000 | 1000–4000 | Curve | Largest economy spike; NG+ feels more rewarded | Reduced true-final payoff |
| Boss `scrapsReward` (Remnants) | 600/840/1120 | 300–1500 | Curve | More post-game incentive | Less reason to pursue post-game content |
| Replay core reward frequency | Every 5 clears | Every 3–10 clears | Gate | Core cache granted more often | Longer grind between core rewards |
| Core cache size | 5 cores | 1–10 | Curve | More cores per cache; element-specific resource more abundant | Slower core accumulation from replays |

---

## Visual/Audio Requirements

N/A for frame-data, hitbox timing, and controller rumble — this is a turn-based browser game. Visual and audio requirements are implemented via CSS class application and `soundEngine.js` calls.

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Corruption stage 2 | `.corruption-stage-2`: scan-line overlay on root, nav ticker jitter | No dedicated audio trigger | Medium |
| Corruption stage 3 | Adds chromatic fringe inset shadow, nav bar flicker, card glitch animation | No dedicated audio trigger | Medium |
| Corruption stage 4 | Heavier scan-lines, static flash animation, Felix portrait skew, ticker jitter at 0.3s | No dedicated audio trigger | High |
| Corruption stage 5 | All stage-4 effects + constant 0.5s micro-shake loop, fast static flash, heavy border pulse | Music already on `'singularity'` track | High |
| Singularity screen open | Left panel boss list, right panel detail with bespoke portrait art | `'singularity'` music (looped) | High |
| Mirror Admin selected | Bespoke `mirror_admin_sprites.png` with `hue-rotate(220deg) saturate(1.5) contrast(1.4)` filter | `'mirrorAdminSpawn'` sfx on engage | High |
| Singularity complete | Corruption stage drops to 0 (CSS class removed on next render) | No dedicated audio (handled in battle) | High |
| Mirror Admin defeated | Routes to Credits screen | `'victoryFanfare'` then `'title'` music | High |
| New Game+ confirmed | Navigates to hatchery (re-locks arc) | `'newGamePlusStart'` sfx | Medium |
| Remnant section visible | Purple-accented section header, progress counter `N/3 CLEARED` | Same as Singularity screen music | Medium |

---

## Game Feel

N/A — turn-based browser game. Frame data, hitbox timing, input latency targets, hit-stop, and controller rumble do not apply. The "feel" of the arc is delivered through the escalating CSS corruption effects (passive, persistent, cannot be dismissed) rather than moment-to-moment input feedback.

The intended sensation is environmental dread: the UI itself is corrupting, not a pop-up warning. The screen micro-shake at stage 5 is deliberately subtle (0.5px amplitude) so it reads as system instability rather than deliberate game feedback.

---

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Boss unlock status (locked / available / defeated) | Singularity screen left panel, per-card | On screen enter / after each battle | Always visible |
| Boss name (or "???") | Boss card header | Static per card | Locked bosses show `???` |
| Replay count badge `×N` | Boss card sub-text | On screen enter | Only when `replayCounts[id] > 1` |
| Mirror Admin lock hint | Card sub-text: `'UNLOCK ALL LOG FRAGMENTS'` | Static | When `singularityComplete` but not all fragments |
| Corruption Remnants section | Below main boss list | On screen enter | Only when `singularityComplete = true` |
| Remnants cleared counter | `N/3 CLEARED` | On screen enter | Remnant section visible |
| New Game+ panel | Top of left panel | On screen enter | Only when `mirrorAdminDefeated = true` |
| NG+ tier display | `New Game+ · Tier N` | Static | When `ngPlus > 0` |
| Selected boss stats (HP/ATK/DEF/SPD) | Right panel detail | On boss select | Phase-1 stats shown for multi-phase bosses |
| Felix quote | Right panel detail, italic | On boss select | Unlocked bosses only |
| Dragon picker | Right panel below quote | On screen enter | All currently owned dragons |
| ENGAGE button disabled state | Right panel | On boss select | `bossStatus === 'locked'` |

---

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| Boss HP/ATK scaled from `calculateStatsForLevel` | `design/gdd/combat.md` | `calculateStatsForLevel` formula, `stageMultipliers` | Data dependency |
| Damage formula inversion in `targetBossAtk` | `design/gdd/combat.md` | `calculateDamage` formula | Rule dependency |
| `getStageForLevel` thresholds | `design/gdd/combat.md` | `stageThresholds: {2:8, 3:20, 4:38}` | Data dependency |
| Type chart values (Light Dragon) | `design/gdd/combat.md` | `typeChart` matrix | Data dependency |
| `recordNpcDefeat` writes `defeatedNpcs` | `design/gdd/campaign-map.md` | NPC defeat persistence | State trigger |
| Fragment unlock via `unlockFragment` | `design/gdd/narrative-and-lore.md` | `flags.fragmentsUnlocked` array | State trigger |
| Dragon base stats for scaling | `design/gdd/journal-milestones.md` | `dragons[id].baseStats`, `fusedBaseStats` | Data dependency |
| `ngPlus` counter for enemy scaling | `design/gdd/campaign-map.md` | NG+ difficulty multiplier wiring | Rule dependency |

> Note: as of 2026-06-16 no files exist under `design/gdd/` — all cross-reference GDDs are declared but not yet written.

---

## Acceptance Criteria

**Functional**

- [ ] `getSingularityStage` returns stage 0 when `singularityComplete = true`, regardless of collection state
- [ ] Corruption CSS class is applied to the root `div.app` at stage 2 and above; not applied at stage 0 or 1
- [ ] Data Corruption mini-boss is available immediately on Singularity screen entry; Memory Leak and Stack Overflow are locked until their predecessor is defeated
- [ ] The Singularity (final boss) is locked until all three mini-bosses appear in `singularityProgress.defeated`
- [ ] Mirror Admin status returns `'locked'` when `singularityComplete = false` or when any of the 7 fragment IDs are missing from `flags.fragmentsUnlocked`
- [ ] Defeating The Singularity sets `singularityComplete = true`, grants `dragons.light.owned = true`, and fragments `004`–`007` are recorded
- [ ] Defeating Mirror Admin sets `mirrorAdminDefeated = true` and routes to the Credits screen; a loss routes to the Singularity screen
- [ ] `startNewGamePlus()` returns `false` when `mirrorAdminDefeated = false`
- [ ] NG+ reset clears `defeatedNpcs`, `singularityProgress`, `singularityComplete`, `mirrorAdminDefeated`, `remnantDefeated`, and `flags.fragmentsUnlocked`; dragons, scraps, cores, milestones, and records are retained
- [ ] Replay reward of 5 cores is granted at every 5th clear of any Singularity-tier boss; core count caps at 99
- [ ] `scaleBossForPlayer` returns deterministic output for the same save state (pure function, no RNG)
- [ ] Corruption Remnants section is hidden when `singularityComplete = false`; visible and sequentially unlocked when `true`
- [ ] `migrateSave` retroactively grants `dragons.light` to saves where `singularityComplete = true` but `dragons.light.owned = false`

**Experiential**

- [ ] Playtester at stage 5 comments unprompted that the UI "looks broken" or "unstable" without being told corruption exists
- [ ] A player who defeats The Singularity and receives the Light Dragon can identify it as the reward without reading external documentation
- [ ] Mirror Admin phase-line dialogue reads as tragic rather than merely threatening to a blind playtester
- [ ] A boss fight at any player level takes between 6 and 20 player turns to complete (validates fixed-TTK targets)
- [ ] The NG+ confirmation double-step prevents accidental reset in all observed playtests

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Does `save.ngPlus` currently wire into any enemy scaling code in the campaign map or battle engine? The UI description promises "+25% per tier" but no scaling code reading `ngPlus` was found during this audit. | Lead Programmer | Before NG+ is advertised as functional | Unresolved — verify `ngPlus` consumer |
| Should Mirror Admin replays (after `mirrorAdminDefeated = true`) also route to Credits, or only to the Singularity screen? Current code only routes to Credits when `won === true` per the `battleConfig.isMirrorAdmin` check, which means first win always goes to Credits regardless. | Game Designer | — | Implemented: all Mirror Admin wins route to Credits |
| Corruption stage 1 (`ownedCount >= 2`) applies no CSS class. Should it have a subtle visual tell, or is stage 1 intentionally silent? | Game Designer | — | Unresolved — design intent unclear from code |
