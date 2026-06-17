# Economy & Rewards

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: P5 — Earned Mastery, Never Trivialized

## Summary

Dragon Forge runs a dual-currency economy: **DataScraps** (the general-purpose soft currency) and **Element Cores** (six element-typed hard resources used for forge crafting). Both are earned primarily through battle wins and have explicit sinks in the hatchery, shop, fusion system, wrench upgrades, and forge crafting. The system ensures first-time content rewards full value while repeat farming is capped at 25% to prevent trivial accumulation, with New Game+ and the Daily Challenge providing sanctioned, multiplier-gated replay paths.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `battle-combat`, `hatchery`, `shop`, `fusion`, `singularity-progression`

---

## Overview

Players earn DataScraps by winning battles, claiming Journal Milestones, and completing the Daily Challenge. They spend scraps on hatchery pulls (50 ◆ each), shop items (50–500 ◆), forge recipes (0–500 ◆ material cost), and fusion (100 ◆ per fusion). Element Cores drop from battle wins with a 60% chance per victory and are consumed by forge crafting recipes. Both currencies persist across sessions via `localStorage`. The economy is closed: no real-money purchases exist and no infinite-generation loops are present.

---

## Player Fantasy

The player should feel like a resourceful engineer who converts hard-won battle victories into meaningful upgrades. Scraps should feel abundant enough that spending them on pulls and fusions is not stressful, but scarce enough that multi-pull binges feel like a real commitment. Cores should feel like a tangible trophy from each win — a physical record of what you fought — and their elemental identity should make crafting feel thematic rather than arbitrary.

Primary MDA aesthetics served: **Achievement** (accumulating scraps toward the next unlock), **Discovery** (not knowing exactly what the next pull yields), **Challenge** (earning higher rewards from harder fights).

---

## Detailed Design

### Core Rules

**DataScraps (◆)**

1. DataScraps are a non-negative integer stored in `save.dataScraps` (`persistence.js` line 20).
2. `addScraps(amount)` adds unconditionally; no ceiling exists on the balance (`persistence.js` line 161–165).
3. `spendScraps(amount)` returns `false` and makes no change if the balance would go negative (`persistence.js` line 167–173).
4. Fusion calls `spendScraps` implicitly via `fuseDragons`, which gates on `save.dataScraps < 100` directly (`persistence.js` line 360).

**Element Cores**

5. Six core elements exist: `fire`, `ice`, `storm`, `stone`, `venom`, `shadow` (`shopItems.js` line 1; `persistence.js` line 253).
6. Each element's count is stored in `save.inventory.cores[element]` as a non-negative integer.
7. Core counts are capped at 99 per element. `addCore` enforces: `Math.min(99, current + count)` (`persistence.js` line 325). Replay rewards use the same cap (`persistence.js` line 264).
8. `spendCores(coreMap)` subtracts amounts by element; if the result is ≤ 0 the key is deleted from the map (`persistence.js` line 329–336).

**Battle Reward Formula**

9. On victory, raw scraps = `npc.scrapsReward` (a static value per NPC defined in `gameData.js`).
10. A **repeat penalty** of ×0.25 applies if the NPC is already in `save.defeatedNpcs` (campaign NPCs) or already in `singularityProgress.defeated` / `replayCounts` (Singularity bosses), checked against the pre-battle save snapshot (`BattleScreen.jsx` lines 911–925).
11. The **Daily Challenge** is exempt from the repeat penalty; instead a **streak multiplier** is applied (see Formulas section). A Daily NPC that was previously completed cannot be re-fought today — `isDailyChallengeCompleted` gates entry.
12. **New Game+ bonus**: after the base/reduced scraps are determined, `scrapsGained = Math.floor(scrapsGained * (1 + save.ngPlus * 0.25))` is applied (`BattleScreen.jsx` line 942).
13. XP follows the same order: base XP → optional ×3 XP Booster → optional `xpMultiplier` relic mod → repeat/NG+ scaling (`BattleScreen.jsx` lines 902–943).
14. Reserve (bench) dragon always earns half the active dragon's final XP, minimum 1: `Math.max(1, Math.floor(xpGained / 2))` (`BattleScreen.jsx` line 945).

**Core Drop**

15. Every battle victory rolls `Math.random() < CORE_DROP_CHANCE` (0.60); on success, a further roll `Math.random() < CORE_DOUBLE_CHANCE` (0.20) determines 2 cores instead of 1 (`BattleScreen.jsx` lines 972–976; `shopItems.js` lines 3–4).
16. The dropped core's element equals the defeated NPC's element (`BattleScreen.jsx` line 971).
17. Cores are added immediately before the victory overlay is shown; the overlay displays the drop.

**Hatchery Pull Cost (Sink)**

18. Single pull costs 50 ◆ (`PULL_COST`, `gameData.js` line 360). Ten-pull costs 500 ◆ (10 × `PULL_COST`, `HatcheryScreen.jsx` lines 125–126); no bulk discount applies.
19. Cost is deducted in `HatcheryScreen` before `executePull` is called; the engine is stateless.
20. First game of a new save: `isFirstGame` flag allows a free single pull even with 0 scraps (`HatcheryScreen.jsx` line 56).

**Hatchery Pity (Gate)**

21. `pityCounter` increments by 1 on every pull that does not yield Rare or Exotic.
22. At `pityCounter >= PITY_THRESHOLD - 1` (i.e., ≥ 9, making the 10th pull guaranteed), the pull is forced to a Rare-or-above result (`hatcheryEngine.js` lines 5–13; `gameData.js` line 362: `PITY_THRESHOLD = 10`).
23. On a Rare or Exotic result the pity counter resets to 0 (`hatcheryEngine.js` line 40–41).

**Duplicate Pull XP**

24. Pulling a dragon already owned grants XP instead of a second copy: `50 * rarityMultiplier` XP (`hatcheryEngine.js` line 64). Multipliers: Common ×1 = 50 XP; Uncommon ×2 = 100 XP; Rare ×3 = 150 XP; Exotic ×5 = 250 XP (`gameData.js` lines 353–357).

**Journal Milestones (one-time Scraps faucets)**

25. `claimMilestone(milestoneId, reward)` adds scraps and adds the milestone ID to `save.milestones`; subsequent calls are no-ops (`persistence.js` lines 218–225).
26. Milestone rewards range from 100 ◆ to 2,000 ◆ (see Tuning Knobs).

**Fusion Cost (Sink)**

27. Fusing two parent dragons costs 100 ◆, deducted atomically in `fuseDragons` (`persistence.js` line 360 and 375).

**Shop BUY Items (Sinks)**

28. Items have fixed scrap costs: XP Booster 100 ◆, Shiny Charm 500 ◆, Pity Reset 100 ◆, Element Reroll 200 ◆, Data Fragment 50 ◆ (`shopItems.js` lines 6–57).

**Forge Recipes (Sinks)**

29. Forge recipes consume Cores (not scraps, except as an additional cost): Dragon Essence costs 3 same-element cores (0 ◆); Stability Matrix costs 3 different-element cores + 100 ◆; Elder Shard costs any 5 cores + 300 ◆; Void Fragment costs 1 of each of 6 elements + 500 ◆ (`shopItems.js` lines 59–98).

**Wrench Upgrade (Sink)**

30. Wrench Tier 1 is the default (free). Tier 2 costs 400 ◆ and unlocks 2 relic slots. Tier 3 costs 900 ◆ and unlocks 4 relic slots (`forgeData.js` lines 255–258; `persistence.js` function `upgradeWrench` line 471).

**Singularity Replay Core Cache**

31. Every 5th total clear of any Singularity boss (tracked per-boss in `replayCounts`) yields a core cache of 5 cores of a cycling element (`persistence.js` line 255–257; `getReplayReward` function lines 254–258).
32. The cycling order is: `['fire', 'ice', 'storm', 'stone', 'venom', 'shadow']`. The element index = `((clearCount / 5) - 1) % 6`.
33. `grantReplayReward` applies the same 99-cap as `addCore` (`persistence.js` line 264).

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| First-clear rate | NPC not yet in `defeatedNpcs` / Singularity not yet in `defeated`/`replayCounts` | NPC recorded as defeated | Full `scrapsReward` granted |
| Repeat rate | NPC in `defeatedNpcs` or already cleared Singularity entry | — (persistent) | `Math.floor(rawScraps * 0.25)` granted |
| Daily Challenge rate | `battleConfig.dailyNpc` is set | Streak multiplier applied | `Math.floor(rawScraps * streakMultiplier)` granted; no repeat clamp |
| NG+ overlay | `save.ngPlus > 0` | — (persistent per cycle) | Additional `×(1 + ngPlus × 0.25)` on top of first-clear/repeat/daily scraps and XP |

### Interactions with Other Systems

**Battle System → Economy**: On NPC defeat, BattleScreen calculates final scraps and XP, calls `addScraps`, `addDragonXp`, `addCore`, then `dispatch SET_VICTORY` with all reward values for the overlay.

**Hatchery → Economy**: HatcheryScreen deducts `PULL_COST` (50 ◆) per pull from `save.dataScraps` before calling `executePull`. Duplicate pulls feed XP back into the progression system via `applyDragonXp`.

**Fusion → Economy**: FusionScreen gates on `save.dataScraps >= 100` and calls `fuseDragons`, which deducts 100 ◆ atomically.

**Shop → Economy**: ShopScreen calls `spendScraps` for BUY items. ForgeShop calls `spendScraps(recipe.scrapsCost)` and `spendCores(...)` for forge recipes.

**Milestones → Economy**: `claimMilestone` is called by JournalScreen (and retroactively during `migrateSave`); it adds scraps as a one-time grant.

**Daily Challenge → Economy**: `getDailyStreakMultiplier(save)` is called before `scrapsGained` is finalized; it reads `save.lastDailyCompleted` and `save.dailyStreak`.

---

## Formulas

### Battle Scraps Reward

```
rawScraps       = npc.scrapsReward                             // static per NPC
clampedScraps   = isRepeat  ? Math.floor(rawScraps * 0.25)
                : isDaily   ? Math.floor(rawScraps * streakMultiplier)
                :             rawScraps
scrapsGained    = save.ngPlus > 0
                    ? Math.floor(clampedScraps * (1 + save.ngPlus * 0.25))
                    : clampedScraps
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| `npc.scrapsReward` | int | 30–1,000 | `gameData.js`, `singularityBosses.js` | Static reward per enemy |
| `isRepeat` | bool | true/false | `BattleScreen.jsx` line 911 | NPC already in defeat log |
| `isDaily` | bool | true/false | `battleConfig.dailyNpc` set | Daily Challenge battle type |
| `streakMultiplier` | float | 1.0–1.5 | `dailyChallenge.js` | Daily streak bonus (see below) |
| `save.ngPlus` | int | 0–N | `persistence.js` | New Game+ cycle count |

**Expected output ranges:**
- Cheapest NPC first-clear: 30 ◆ (firewall_sentinel)
- Cheapest NPC repeat: 7 ◆ (Math.floor(30 × 0.25))
- Most expensive first-clear: 1,000 ◆ (The Singularity final boss)
- Most expensive repeat: 250 ◆ (Singularity, Math.floor(1000 × 0.25))
- NG+1 first-clear multiplier: ×1.25
- NG+2 first-clear multiplier: ×1.50

### Daily Challenge NPC Stats & Rewards

```
boostFactor     = 1.3 + rng() * 0.3              // range: [1.30, 1.60]
boostedStats[k] = Math.floor(baseNpc.stats[k] * boostFactor)
boostedXP       = Math.floor(baseNpc.baseXP * 2)
boostedScraps   = Math.floor(baseNpc.scrapsReward * 3)
```

Daily stats are seeded deterministically from `YYYYMMDD` integer so all players face the same opponent each day (`dailyChallenge.js` lines 5–8).

### Daily Streak Multiplier

```
effectiveStreak   = (lastDailyCompleted === yesterdaySeed) ? dailyStreak : 0
currentStreak     = effectiveStreak + 1          // includes today's win
streakMultiplier  = currentStreak <= 1 ? 1.0 : Math.min(1.5, 1.0 + (currentStreak - 1) * 0.1)
```

| `currentStreak` | Multiplier |
|-----------------|------------|
| 1 | ×1.0 |
| 2 | ×1.1 |
| 3 | ×1.2 |
| 4 | ×1.3 |
| 5 | ×1.4 |
| 6+ | ×1.5 (cap) |

**Source**: `dailyChallenge.js` lines 64–73.

### Core Drop Probability

```
drops1core  = CORE_DROP_CHANCE * (1 - CORE_DOUBLE_CHANCE) = 0.60 * 0.80 = 0.48
drops2cores = CORE_DROP_CHANCE * CORE_DOUBLE_CHANCE        = 0.60 * 0.20 = 0.12
dropsNone   = 1 - CORE_DROP_CHANCE                         = 0.40
expectedCores_per_win = 0.48 * 1 + 0.12 * 2              = 0.72 cores/battle
```

**Source**: `shopItems.js` lines 3–4.

### Hatchery Pity Guarantee

```
// At pityCounter >= 9 (10th consecutive non-Rare pull):
guaranteedRarePlus = true   // pool restricted to Rare (0.15) + Exotic (0.05)
```

Expected pulls to guaranteed Rare+ without luck: at most 10.
Expected pulls with natural luck: ~5 (1/0.20 = 5 average pulls to a Rare/Exotic result).

### XP from Battle Victory

```
xpGained = calculateXpGain(npc.baseXP, playerLevel, npc.level)
// XP Booster active:  xpGained *= 3
// astraeus_engine relic: xpGained = Math.floor(xpGained * relicMods.xpMultiplier)
// NG+ overlay: xpGained = Math.floor(xpGained * (1 + save.ngPlus * 0.25))
benchXp  = Math.max(1, Math.floor(xpGained / 2))
```

`calculateXpGain` lives in `battleEngine.js`. XP Booster consumption is tracked in `save.inventory.xpBoostBattles`; `decrementXpBoost()` runs on every boosted win.

### Replay Core Cache (Singularity)

```
if (clearCount % 5 === 0):
  element = ['fire','ice','storm','stone','venom','shadow'][(clearCount/5 - 1) % 6]
  grant 5 cores of that element (capped at 99)
```

**Source**: `persistence.js` lines 254–265.

---

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Scraps balance would go negative from `spendScraps` | Returns `false`; no mutation | Guard in `persistence.js` line 169 |
| Core count at 99, gain more cores | Clamped to 99 by `Math.min(99, ...)` | `persistence.js` lines 264, 325 |
| Replay reward at clearCount not divisible by 5 | Returns `null`; no grant | `getReplayReward` line 255 |
| Daily streak gap (yesterday not completed) | `effectiveStreak = 0`; today counts as streak 1 | `dailyChallenge.js` line 66 |
| Singularity repeat penalty applied when `replayCounts[npcId] > 0` | Uses `|| (sp.replayCounts?.[npcId] || 0) > 0` check; even first-entry-list check is OR'd with replay count | `BattleScreen.jsx` lines 917–924 — prevents exploit of clearing cache before defeat list updates |
| `save.ngPlus = 0` (fresh save) | NG+ multiplier branch not entered; base rewards returned | `BattleScreen.jsx` line 939 guards with `if (save.ngPlus)` |
| Fusion called with < 100 ◆ | `fuseDragons` returns `null` and makes no state changes | `persistence.js` line 360 |
| Player defeats same NPC in same session twice (no page reload) | Second defeat detected via `save.defeatedNpcs` loaded from `localStorage` at reward time; `refreshSave()` called between battles | `BattleScreen.jsx` line 967 calls `refreshSave()` before `coreDropped` and reward checks |
| Pity counter reaches exactly 9 | Next pull is guaranteed Rare+; the check is `>= PITY_THRESHOLD - 1` (i.e., ≥ 9) | `hatcheryEngine.js` line 5 |
| `migrateSave` retroactive `full_roster` grant | If discovered ≥ 8 and milestone not yet claimed, 500 ◆ added | `persistence.js` lines 83–88 — one-time migration safety |
| NG+ reset: `defeatedNpcs` cleared | All campaign NPCs become first-clear again; Singularity bosses also reset via `singularityProgress` wipe | `applyNewGamePlus` in `persistence.js` lines 424–433 |

---

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Battle Combat | Economy depends on Battle | Battle provides `scrapsReward`, `baseXP`, `npcId`, defeat state; Economy reads these to calculate rewards |
| Hatchery | Economy depends on Hatchery | Hatchery deducts 50 ◆ per pull; duplicate pulls consume XP budget from the progression system |
| Shop / Forge | Economy depends on Shop | Shop and forge consume scraps and cores; their costs are the primary discretionary sinks |
| Fusion | Economy depends on Fusion | Fusion deducts 100 ◆ per use |
| Singularity Progression | Bidirectional | Economy provides replay core caches; Singularity progress state determines whether repeat penalty applies |
| Daily Challenge | Economy depends on Daily Challenge | Daily Challenge provides streak multiplier; economy applies it to reward calculation |
| Journal Milestones | Economy depends on Milestones | Milestones are one-time scraps faucets; `claimMilestone` is the sole writer for milestone-driven grants |
| Relic System (Skye) | Economy depends on Relics | `astraeus_engine` relic applies XP multiplier; `hydra_cog` grants chain hit chance (indirect economy via faster clears) |
| New Game+ | Economy depends on NG+ | `save.ngPlus` scales both scraps and XP rewards by ×(1 + 0.25 per tier) |
| Persistence / Save | Economy depends on Persistence | All currency state lives in `localStorage` via `persistence.js`; all mutations go through `addScraps`/`spendScraps`/`addCore`/`spendCores` |

---

## Tuning Knobs

| Parameter | Current Value | Location | Safe Range | Category | Effect of Increase | Effect of Decrease |
|-----------|--------------|----------|------------|----------|-------------------|-------------------|
| `PULL_COST` | 50 ◆ | `gameData.js` line 360 | 25–100 | Gate | Pulls feel more premium; scraps accumulate longer | Pulls become trivial; hatchery loses tension |
| `PITY_THRESHOLD` | 10 | `gameData.js` line 362 | 5–20 | Gate | More pulls before guarantee; more frustration risk | Rare+ comes sooner; pity less meaningful as mechanic |
| `CORE_DROP_CHANCE` (owner) | 0.60 | `shopItems.js` line 3 | 0.40–0.80 | Feel | Cores flow faster; forge recipes become cheaper time-wise | Cores feel scarcer; recipe grind extends |
| `CORE_DOUBLE_CHANCE` (owner) | 0.20 | `shopItems.js` line 4 | 0.10–0.35 | Feel | Expected cores/win increases; inventory fills faster | Rarely get windfalls; steadier accumulation |
| Repeat penalty multiplier | ×0.25 | `BattleScreen.jsx` line 932 | ×0.10–×0.50 | Curve | Repeat farming more rewarding; less pressure for fresh content | Near-zero reward for repeated fights; forces new content |
| NG+ scraps bonus per tier | +25% | `BattleScreen.jsx` line 942 | +10%–+50% | Curve | NG+ loop more rewarding; may trivialize economy in later cycles | NG+ loop less rewarding; less incentive to restart |
| Daily streak cap | ×1.5 | `dailyChallenge.js` line 72 | ×1.2–×2.0 | Gate | Veteran daily players earn significantly more; may widen wealth gap | Less incentive to maintain daily habit |
| Daily streak step | +0.1 per day | `dailyChallenge.js` line 72 | +0.05–+0.2 | Curve | Multiplier ramps faster; streak payoff arrives sooner | Slower payoff for consistent players |
| Fusion cost | 100 ◆ | `persistence.js` line 360 | 50–300 | Gate | Fusion is a heavier decision; slows progression | Fusion becomes low-stakes; reduces meaningful choice |
| Wrench Tier 2 cost | 400 ◆ | `forgeData.js` line 257 | 200–800 | Gate | Relic slot unlock is a longer milestone | More accessible relic system; reduces progression depth |
| Wrench Tier 3 cost | 900 ◆ | `forgeData.js` line 258 | 500–2,000 | Gate | Endgame relic build locked behind significant spend | Endgame relic load-out accessible earlier |
| Replay core cache count | 5 cores per cache | `persistence.js` line 257 | 2–10 | Feel | Faster core accumulation from endgame replay | Smaller core windfalls from high-effort endgame content |
| Replay cache interval | every 5 clears | `persistence.js` line 255 | 3–10 | Gate | Caches arrive more often; more frequent endgame reward beats | Caches are rarer; replay feels drier between payoffs |
| Core cap per element | 99 | `persistence.js` lines 264, 325 | 50–999 | Gate | Overflow protection triggers sooner; harder to stockpile | Less pressure to spend; crafting hoarding risk |
| Milestone rewards | 100–2,000 ◆ | `journalMilestones.js` | — | Curve | More scraps from one-time grants; accelerates early access to hatchery | Fewer free pulls from milestone completion |

> **Note**: `CORE_DROP_CHANCE` and `CORE_DOUBLE_CHANCE` are owned here; other GDDs cross-reference.

---

## Visual / Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Scraps earned on victory | `+N ◆` in result overlay summary grid | `scrapsEarned` sound (~200ms delay after fanfare) | High |
| Core dropped on victory | Element-colored core display below XP line | None (covered by victory fanfare) | High |
| Repeat penalty active | `REPEAT ×0.25` label under scraps value | None | Medium |
| Streak bonus applied | Streak bonus line shown in Daily overlay | None | Medium |
| Level up on victory | "LEVEL UP! Now Lv.N" display | `levelUp` sound (~400ms delay) | High |
| Relic dropped on victory | Relic icon + name displayed in result card | None | High |
| Milestone claimed | Toast / Journal UI | `uiConfirm` (existing) | Medium |
| Hatchery pull cost deducted | Scraps counter in NavBar updates | None (pull animation covers it) | Low |

---

## Game Feel

N/A — turn-based browser game. No frame-data, hitbox timing, hit-stop, or controller rumble applies. Economy feedback is purely visual (number displays, overlay labels) and audio (scrapsEarned, levelUp sounds). Latency between a battle win and seeing the reward overlay is driven by the KO animation (~1,200ms) rather than input handling.

---

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| DataScraps balance | NavBar (`◆ N`) | After every save mutation | Always visible |
| Scraps earned this battle | Victory overlay result grid | Once on victory | Victory state |
| Repeat penalty indicator | Victory overlay below scraps | Once on victory | `wasRepeat === true` |
| Core dropped | Victory overlay core-drop line | Once on victory | `coreDropped !== null` |
| Streak multiplier | Victory overlay | Once on victory | `battleConfig.dailyNpc && streakMultiplier > 1` |
| Core inventory | Shop / Forge screens | On screen open | Always when shop open |
| Pity counter | Not shown to player | — | Hidden; pity operates silently |

---

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| NPC `scrapsReward` values | `design/gdd/combat.md` | NPC stat tables | Data dependency |
| `PULL_COST`, `PITY_THRESHOLD`, rarity tiers | `design/gdd/hatchery-gacha.md` | Pull cost and pity gate | Rule dependency |
| Fusion 100 ◆ cost | `design/gdd/fusion.md` | Fusion gate rule | Rule dependency |
| Shop item costs (50–500 ◆) | `design/gdd/shop-and-crafting.md` | BUY item price table | Data dependency |
| Forge recipe core/scrap costs | `design/gdd/shop-and-crafting.md` | Forge recipe cost table | Data dependency |
| Daily Challenge streak multiplier | `design/gdd/daily-challenge.md` | `getDailyStreakMultiplier` formula | Rule dependency |
| Singularity `replayCounts` repeat detection | `design/gdd/singularity-endgame.md` | Repeat detection logic | State trigger |
| NG+ `save.ngPlus` scaling | `design/gdd/singularity-endgame.md` | NG+ reward multiplier | Rule dependency |
| `astraeus_engine` relic XP multiplier | `design/gdd/forge-skye.md` | `xpMultiplier` relic modifier | Data dependency |

---

## Acceptance Criteria

**Functional**

- [ ] Defeating any NPC for the first time grants exactly `npc.scrapsReward` DataScraps (no multiplier applied for fresh save, `ngPlus = 0`).
- [ ] Defeating a previously defeated campaign NPC grants `Math.floor(scrapsReward * 0.25)`, confirmed via the "REPEAT ×0.25" label in the victory overlay.
- [ ] Defeating a Singularity boss for the first time (not in `defeated` list or `replayCounts`) grants full reward; second defeat yields ×0.25.
- [ ] Daily Challenge reward equals `Math.floor(npc.scrapsReward * 3 * streakMultiplier)` where `npc.scrapsReward` is the base NPC value before Daily boost — i.e., `Math.floor(baseNpc.scrapsReward * 3 * streakMultiplier)`.
- [ ] Core drops occur at 60% frequency across a sample of ≥ 20 battles (within ±10pp statistical tolerance).
- [ ] Core counts cannot exceed 99 per element regardless of any combination of battle drops, replay caches, or forge grants.
- [ ] The pity counter guarantees a Rare-or-above result no later than pull 10, measured from the last Rare/Exotic result or the start of a fresh save.
- [ ] Fusing two dragons deducts exactly 100 ◆ and fails (returns null) if balance is below 100 ◆.
- [ ] NG+1 rewards equal NG+0 rewards ×1.25 (rounded down) for both scraps and XP.
- [ ] `getReplayReward(5)` returns `{ element: 'fire', count: 5 }`; `getReplayReward(10)` returns `{ element: 'ice', count: 5 }`; `getReplayReward(4)` returns `null`.
- [ ] Wrench Tier 2 upgrade deducts 400 ◆ and fails without mutation if scraps < 400.
- [ ] Milestone `claimMilestone('full_roster', 500)` adds 500 ◆ exactly once; second call returns `false` and does not add scraps.

**Experiential**

- [ ] A new player can afford their first hatchery pull (50 ◆) after winning 1–2 campaign battles without grinding (first-clear rewards of 30–50 ◆ confirmed against early NPC table).
- [ ] A player who replays the same NPC five times in a row comments that rewards feel clearly reduced compared to first-time wins — the ×0.25 label is noticed.
- [ ] The Daily Challenge feels meaningfully harder and more rewarding than campaign NPCs — stat boost and ×3 scraps base are both perceptible.
- [ ] Core accumulation feels like a natural side-effect of playing, not a grind target, through the endgame (≥5 of each element accrued without deliberate farming by the time of first Singularity attempt).

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should the core cap of 99 be raised or removed post-NG+? High-tier NG+ players may hit cap frequently on 6 elements. | economy-designer | — | Not yet decided; monitor via analytics if instrumented |
| Should the 10-pull have a discount (e.g., 450 ◆ instead of 500 ◆) to reward commitment? | game-designer | — | Current behavior: no discount. Open for future consideration. |
