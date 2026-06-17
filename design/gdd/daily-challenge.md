# Daily Challenge

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: Daily Return Loop / Retention

## Summary

The Daily Challenge is a once-per-calendar-day special battle that presents a
deterministically-selected, stat-boosted NPC opponent drawn from the standard
campaign pool. Winning pays triple the base scrap reward and double the base XP
compared to the same opponent fought normally. A consecutive-day streak applies
an additional scrap multiplier of up to 1.5x on top of the 3x base reward. The
system exists to give returning players an immediately visible reason to open the
game each day and to provide a renewable DataScraps faucet that scales with
engagement without inflating the economy unboundedly.

> **Quick reference** — Layer: `Feature` · Priority: `Alpha` · Key deps: `Battle Engine, Persistence, NPC Data`

## Overview

Each calendar day the game derives an integer seed from the current date
(`YYYYMMDD` as an integer). That seed drives a deterministic pseudo-random
number generator which selects one NPC from the full campaign pool and computes
a stat-boost factor between 1.3 and 1.6. The selected NPC is presented in
Battle Select with a gold border and "DAILY CHALLENGE" label. The player may
battle it once; on victory, `persistence.completeDailyChallenge` is called,
recording the seed in `save.lastDailyCompleted` so subsequent checks block
re-entry for the rest of the day. Losing does not consume the attempt — the
daily card remains available until the player wins or midnight resets the seed.

## Player Fantasy

The player should feel the anticipation of a daily ritual: "What challenge is
waiting for me today?" followed by relief and satisfaction at the boosted
reward. The elevated difficulty (stats 30-60% higher than the same NPC in
campaign) frames this as the game's elite sparring match — something worth
planning a dragon build around. The streak counter provides a secondary
collector's thrill: maintaining a chain of consecutive victories feels like an
achievement worth protecting.

Primary MDA aesthetics served: **Challenge** (harder-than-normal opponent),
**Achievement** (streak accumulation, once-per-day gatekeeping makes wins feel
meaningful), **Submission** (the ritual of a daily check-in).

## Detailed Design

### Core Rules

1. **Seed generation** (`dailyChallenge.js:5-8`): The daily seed is computed
   as `year * 10000 + (month + 1) * 100 + day` using the local browser clock.
   This produces an integer such as `20260616` for 2026-06-16. The seed changes
   at local midnight.

2. **NPC selection** (`dailyChallenge.js:18-47`): A seeded LCG
   (`s = (s * 1664525 + 1013904223) & 0xffffffff`) consumes the seed, and
   `Math.floor(rng() * NPC_IDS.length)` picks one of the 9 NPCs currently in
   `gameData.npcs`. The same seed always produces the same NPC for all players.

3. **Stat inflation** (`dailyChallenge.js:27-32`): A `boostFactor` in range
   `[1.3, 1.6)` is drawn from the same RNG sequence (second call). Every
   numeric stat key (hp, atk, def, spd) is floored at `baseStat * boostFactor`.
   The NPC's level is also floored at `baseLevel * boostFactor`.

4. **Reward inflation** (`dailyChallenge.js:34-35`): Independent of the stat
   boost, `baseXP` is multiplied by exactly **2** and `scrapsReward` by exactly
   **3** before the opponent object is returned. These multipliers are
   intentional design choices documented in ADR-0006.

5. **Once-per-day gate** (`dailyChallenge.js:50-53`, `persistence.js:412-418`):
   A battle is gated if `save.lastDailyCompleted === getDailySeed()`. The player
   may attempt the daily as many times as needed until they win; the gate is
   written only on victory via `completeDailyChallenge(seed)`.

6. **Victory path** (`BattleScreen.jsx:963-964`): On win, `recordNpcDefeat`
   is NOT called for the daily (the NPC id is `'daily_challenge'`, not a real
   campaign id), so the daily opponent does not pollute the campaign defeat
   record. `completeDailyChallenge(battleConfig.dailyNpc.seed)` is called
   instead.

7. **Scrap reward with streak multiplier** (`BattleScreen.jsx:933-935`):
   `scrapsGained = Math.floor(rawScraps * streakMultiplier)`, where `rawScraps`
   is already the 3x-inflated value from step 4 and `streakMultiplier` is the
   value returned by `getDailyStreakMultiplier(save)` captured before
   `completeDailyChallenge` mutates the streak.

8. **XP reward** (`BattleScreen.jsx:902`): `calculateXpGain` receives the 2x
   `baseXP` from the daily NPC object; no additional daily multiplier is applied
   to XP. The streak multiplier applies to scraps only.

9. **Loss behavior** (`BattleScreen.jsx:1643-1644`): On loss, the defeat screen
   shows "The daily card is still open — retry it from Battle Select." The
   `save.lastDailyCompleted` is not updated; the player may try again.

10. **New Game+ interaction** (`BattleScreen.jsx:940-943`): When `save.ngPlus > 0`,
    a post-calculation bonus of `+25% per NG+ tier` is applied to both XP and
    scraps after all daily multipliers, so NG+ stacks multiplicatively on top of
    all daily boosts.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Available | `save.lastDailyCompleted !== getDailySeed()` | Player wins the daily battle | Card shown in gold, selectable, reward tooltip visible |
| Completed | `save.lastDailyCompleted === getDailySeed()` | Midnight (seed changes) | Card shows "COMPLETED TODAY" with green check; click disabled |
| Attempted (loss) | Player loses while daily is Available | Player wins or midnight resets | Remains in Available state; retry is free |

### Interactions with Other Systems

**Battle Engine** (`battleEngine.js`): The daily NPC object is passed as
`battleConfig.dailyNpc`. The battle engine treats it as a normal NPC opponent;
no special battle rules apply beyond what the boosted stats provide. The
presence of `dailyNpc` in `battleConfig` is the flag that downstream scrap
and completion logic branches on.

**Persistence** (`persistence.js`): `completeDailyChallenge(seed)` is the only
write operation on victory. It reads the pre-victory save to determine whether
yesterday's seed matches `save.lastDailyCompleted`, then increments
`dailyStreak` if true or resets it to 1 if not, then writes `lastDailyCompleted
= seed`.

**Battle Select Screen** (`BattleSelectScreen.jsx`): Calls `getDailyChallenge()`
on every render (pure, deterministic — no side effects). Calls
`isDailyChallengeCompleted(save)` to set the completed state. Calls
`getEffectiveStreak(save)` to display the flame-streak indicator next to the
card title.

**New Game+** (`persistence.js:applyNewGamePlus`): NG+ does NOT reset
`lastDailyCompleted` or `dailyStreak`. Daily progress persists across NG+
transitions.

## Formulas

### Daily Seed

```
seed = year * 10000 + (month + 1) * 100 + day
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| year | int | 2024+ | `new Date().getFullYear()` | Four-digit year |
| month | int | 0-11 | `new Date().getMonth()` | Zero-indexed; +1 applied |
| day | int | 1-31 | `new Date().getDate()` | Day of month |

**Expected output range**: Integer, e.g. 20260616. Changes at local browser midnight.

### LCG Pseudo-Random Number Generator

```
s = (s * 1664525 + 1013904223) & 0xffffffff
value = (s >>> 0) / 0xffffffff
```

The first call selects the NPC index; the second call selects the boost factor.
Both calls use the same seeded generator instance, so both outputs are
deterministic given the daily seed.

### Stat Boost

```
boostFactor = 1.3 + rng() * 0.3          // range: [1.3, 1.6)
boostedStat = Math.floor(baseStat * boostFactor)
boostedLevel = Math.floor(baseLevel * boostFactor)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| boostFactor | float | [1.3, 1.6) | second LCG call | Stat inflation multiplier |
| baseStat | int | varies by NPC | `gameData.npcs[id].stats.*` | Base stat before inflation |
| baseLevel | int | 2-12 | `gameData.npcs[id].level` | Base level before inflation |

**Expected output range for boostFactor**: 1.3 to ~1.599 (never exactly 1.6).
**Effect on NPC pool**: At maximum boost (1.6), the easiest NPC
(firewall_sentinel, lv2 hp:80 atk:14) becomes approximately lv3 hp:128 atk:22;
the hardest (protocol_vulture, lv12 hp:100 atk:28) becomes approximately lv19
hp:160 atk:44.

### XP Reward

```
baseXP_daily = Math.floor(baseNpc.baseXP * 2)
xpGained = calculateXpGain(baseXP_daily, playerLevel, npcLevel)
```

The 2x multiplier is baked into the NPC object returned by `getDailyChallenge`.
The XP gain function applies its own level-differential scaling on top of that.
No streak multiplier is applied to XP.

**NPC baseXP range (pre-boost)**: 25 (firewall_sentinel) to 130 (protocol_vulture).
**Daily baseXP range (post 2x)**: 50 to 260.

### Scrap Reward

```
scrapsReward_daily = Math.floor(baseNpc.scrapsReward * 3)
scrapsGained = Math.floor(scrapsReward_daily * streakMultiplier)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| scrapsReward_daily | int | 90-390 | 3x base NPC reward | Pre-streak scrap value |
| streakMultiplier | float | 1.0-1.5 | `getDailyStreakMultiplier(save)` | Consecutive-day bonus |

**NPC scrapsReward range (pre-boost)**: 30 (firewall_sentinel) to 130 (protocol_vulture).
**Daily scraps range (3x, no streak)**: 90 to 390.
**Daily scraps range (3x, max streak 1.5x)**: 135 to 585.

### Streak Multiplier

```
effectiveStreak = (save.lastDailyCompleted === yesterdaySeed) ? save.dailyStreak : 0
currentStreak   = effectiveStreak + 1
streakMultiplier = (currentStreak <= 1) ? 1.0 : Math.min(1.5, 1.0 + (currentStreak - 1) * 0.1)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| effectiveStreak | int | 0+ | `getEffectiveStreak(save)` | 0 if yesterday not completed |
| currentStreak | int | 1+ | effectiveStreak + 1 | Includes today's completion |
| streakMultiplier | float | 1.0-1.5 | clamped formula | Applied to scrap reward only |

**Example outputs**:
- Day 1 (no prior streak): effectiveStreak=0, currentStreak=1, multiplier=1.0
- Day 2 (yesterday completed, dailyStreak=1): currentStreak=2, multiplier=1.1
- Day 3 (dailyStreak=2): currentStreak=3, multiplier=1.2
- Day 6+ (dailyStreak>=5): currentStreak>=6, multiplier capped at 1.5

The cap of 1.5 is reached when `currentStreak >= 6` (effectiveStreak >= 5,
meaning at least 5 prior consecutive days completed).

### Streak Update on Completion

```
// in persistence.completeDailyChallenge:
save.dailyStreak = (save.lastDailyCompleted === yesterdaySeed)
  ? (save.dailyStreak || 0) + 1
  : 1
save.lastDailyCompleted = seed
```

The streak only increments if the previous day's seed matches. Any gap resets
to 1 (not 0, because completing today's daily always establishes a streak of 1).

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player loses the daily | `lastDailyCompleted` unchanged; card remains available | Retry is free — gates on WIN, not on ATTEMPT |
| Player wins, then page refreshes | `save.lastDailyCompleted === seed` returns true; card shows "COMPLETED TODAY" | Written before UI update |
| Streak lapsed (>1 day gap) | `getEffectiveStreak` returns 0; multiplier is 1.0 | Only yesterday's completion counts |
| Daily NPC happens to be a campaign Boss-tier NPC | Boosted further by 30-60%; no unlock lock or prerequisite check — daily bypasses campaign gate | The daily pool is all of `gameData.npcs`; Boss NPCs are included |
| Midnight crosses during battle | Seed used is the one captured at battle start (`battleConfig.dailyNpc.seed`); completion writes that seed | Avoids off-by-one if game tab stays open overnight |
| NG+ active | NG+ bonus applied after all daily multipliers, stacking multiplicatively | Designed reward for NG+ persistence |
| `dailyStreak` undefined in older save | `migrateSave` sets `dailyStreak = 0`; `getEffectiveStreak` guards with `(save.dailyStreak || 0)` | Safe fallback to 0 |
| NPC pool changes (NPC added/removed) | LCG index wraps with `Math.floor(rng() * NPC_IDS.length)` so adding/removing NPCs redistributes the distribution; any given day's NPC may shift | Accept as a non-issue — daily is not a contract |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| `src/gameData.js` — `npcs` object | This depends on gameData | Source NPC pool; all NPCs are eligible daily opponents |
| `src/battleEngine.js` — `calculateXpGain` | This depends on battleEngine | XP scaling formula applied to boosted baseXP |
| `src/persistence.js` — `completeDailyChallenge`, `save.lastDailyCompleted`, `save.dailyStreak` | Bidirectional | Persistence owns the state; dailyChallenge reads and writes via persistence helpers |
| `src/BattleScreen.jsx` | BattleScreen depends on this | Reads `getDailyStreakMultiplier` to compute scraps on victory |
| `src/BattleSelectScreen.jsx` | BattleSelectScreen depends on this | Reads `getDailyChallenge`, `isDailyChallengeCompleted`, `getEffectiveStreak`, `getDateString` |

## Tuning Knobs

| Parameter | Current Value | File:Line | Safe Range | Category | Effect of Increase | Effect of Decrease |
|-----------|--------------|-----------|------------|----------|-------------------|-------------------|
| Stat boost floor | 1.3 | `dailyChallenge.js:27` | 1.0-1.5 | Feel | Harder minimum; reduces variance | Easier minimum; could make daily too close to normal |
| Stat boost ceiling (addend) | 0.3 | `dailyChallenge.js:27` | 0.1-0.5 | Feel | Higher variance; some days brutally hard | Lower variance; more predictable daily |
| XP multiplier | 2 (×baseXP) | `dailyChallenge.js:34` | 1.5-4 | Curve | Faster dragon leveling from dailies | Reduces XP incentive |
| Scrap multiplier | 3 (×scrapsReward) | `dailyChallenge.js:35` | 2-5 | Curve | Richer faucet; economy inflates faster | Weakens daily incentive |
| Streak multiplier step | 0.1 per day | `dailyChallenge.js:72` | 0.05-0.2 | Curve | Streak feels more rewarding faster | Streak bonus less felt |
| Streak multiplier cap | 1.5 | `dailyChallenge.js:72` | 1.2-2.0 | Gate | Stronger long-term retention hook | Weaker; cap reached quickly and feels same |
| Streak decay window | 1 day (yesterday only) | `dailyChallenge.js:55-66` | N/A (binary) | Gate | N/A | N/A — currently binary: yesterday or 0 |

**Economy note on the 3x scrap multiplier**: This is an intentional design
choice (ADR-0006). The daily challenge is the primary renewable scrap faucet for
players who have completed the campaign (where all NPCs pay 0.25x on repeat).
Without a 3x floor the daily would not provide meaningful economic momentum for
post-campaign players. The cap of 1.5x on the streak prevents compound
exponential growth from destabilizing the economy.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Daily card in lobby | Gold (#ffcc00) border; "DAILY CHALLENGE" header; "3x DataScraps · 2x XP" tooltip | N/A — no sound on display | High |
| Streak active (not completed) | Flame emoji + streak count next to header | N/A | Medium |
| Daily completed (today) | Card grayed-out, "COMPLETED TODAY" text + green check, click disabled | N/A | High |
| Win with streak bonus | Post-battle overlay shows "Streak bonus ×N.N applied" in orange | N/A (battle win sound plays normally) | Medium |

## Game Feel

N/A — turn-based browser game. Frame data, hitbox timing, input latency,
controller rumble, and hit-stop do not apply. The "feel" of the daily challenge
is defined by the presentation (gold card, tooltip, streak flame) and the
reward payoff at victory, not by moment-to-moment input response.

**Interaction feel target**: The daily card should feel like a special event
entry point — visually distinct from the campaign list, immediately readable as
"this is the premium fight today." The completed state must be unambiguous so
returning players do not think the feature is broken.

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Daily NPC name and date | Battle Select card | Once per session (deterministic) | Always when not completed |
| "COMPLETED TODAY" status | Battle Select card | On save load / refreshSave | When `lastDailyCompleted === seed` |
| Streak count (flame indicator) | Battle Select card header | On save load | When `effectiveStreak > 0` and not completed |
| "3x DataScraps · 2x XP" tooltip | Battle Select card | Always (static) | When not completed |
| Streak bonus applied message | Post-battle victory overlay | Once on victory | When `streakMultiplier > 1.0` |

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| NPC stat and reward values | `design/gdd/combat.md` (not yet authored) | `scrapsReward`, `baseXP`, `stats`, `level` per NPC | Data dependency |
| Battle reward calculation | `design/gdd/economy.md` (not yet authored) | `calculateXpGain` formula, scrap accumulation path | Rule dependency |
| Persistence save schema | `design/gdd/save-and-persistence.md` (not yet authored) | `save.lastDailyCompleted`, `save.dailyStreak` fields | Data dependency |
| Economy balance: ADR-0006 | ADR-0006 (not yet authored as standalone file) | Decision to use 3x scrap multiplier as renewable faucet | Rule dependency |

## Acceptance Criteria

**Functional:**
- [ ] On any given calendar day, `getDailyChallenge()` returns the same NPC
      for all calls within that day (deterministic by seed).
- [ ] After winning the daily, `save.lastDailyCompleted` equals `getDailySeed()`
      and the Battle Select card shows "COMPLETED TODAY" with click disabled.
- [ ] Losing the daily battle does not write `lastDailyCompleted`; the card
      remains selectable.
- [ ] The scrap reward equals `Math.floor(baseNpc.scrapsReward * 3 * streakMultiplier)`
      where `streakMultiplier` is captured before `completeDailyChallenge` runs.
- [ ] The XP reward uses `baseNpc.baseXP * 2` as the input to `calculateXpGain`.
- [ ] A streak of 0 prior days yields multiplier 1.0; a streak of 5 prior days
      yields multiplier 1.5; a streak of 20 prior days also yields 1.5 (capped).
- [ ] A gap of 2+ days resets the displayed streak to 0 and applies multiplier 1.0.
- [ ] The daily NPC does NOT appear in `save.defeatedNpcs` after completion.
- [ ] NG+ bonus is applied after the daily multipliers, not before.
- [ ] `migrateSave` sets `dailyStreak = 0` for saves that lack the field.

**Experiential (playtester validation):**
- [ ] A playtester opening Battle Select immediately identifies the daily card as
      distinct from the campaign NPC list without reading instructions.
- [ ] After completing the daily, a playtester does not attempt to click the
      completed card expecting it to work — the disabled state reads clearly.
- [ ] A playtester who has a 5-day streak notices and mentions the streak
      indicator without being prompted.
- [ ] Post-battle overlay streak message is readable and understood by a
      playtester who did not know the streak system existed.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should the daily seed be server-side to guarantee identical opponent across timezones? | game-designer | Post-MVP | Currently uses local clock; all players in the same timezone see the same daily |
| Should losing cost a streak charge or remain free to retry? | game-designer | Alpha | Currently free retry; no cost on loss |
| Should Boss-tier NPCs (recursive_golem, protocol_vulture) be excluded from the daily pool? | game-designer | Alpha | Currently included — can produce very hard dailies |
