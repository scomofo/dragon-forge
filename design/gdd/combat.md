# Combat

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: P2 — Every Fight Is a Readable Type-Puzzle

## Summary

Combat is the turn-based battle system that resolves encounters between the player's dragon and enemy NPCs or bosses. Each turn the player selects a move; speed determines who acts first; damage is calculated from elemental type matchups, stats, and optional buffs or charged strikes. Status conditions, a two-dragon bench, and an adaptive NPC AI create tactical depth without requiring real-time skill. Combat is the primary source of XP, scraps, core drops, and relic drops.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `dragon-progression`, `economy`, `status-effects`

---

## Overview

The combat system is a single-file simulation (`src/battleEngine.js`) consumed by the React presentation layer (`src/BattleScreen.jsx`). Two combatants — the player dragon and an NPC — take alternating turns. At the start of each turn the player picks a move; the engine picks the NPC's move via `pickNpcMove`; `resolveTurn` executes both in speed order and returns an event log that `BattleScreen` animates sequentially. A match ends when either combatant's HP reaches zero. If the player equipped a reserve dragon (bench) it provides a second life. Bosses have multi-phase definitions that chain into new HP pools when the current phase is defeated. Victory grants XP (with optional level-up), scraps, a probabilistic core drop, and on first defeat only — a relic or fragment unlock.

---

## Player Fantasy

The player should feel like a tactical commander reading the enemy's patterns and making sharp decisions under pressure. Landing a type-advantage hit or a critical strike on a nearly-dead boss should feel decisive and earned. Watching the NPC charge up a powerful move creates genuine tension — the player has one turn to either finish the fight or brace for impact. The system should reward knowledge of the 8-element type chart and punish passive, single-move spam through the NPC's counter-element adaptation.

Primary MDA aesthetics served: **Challenge** (reading enemy patterns, choosing optimal moves), **Fantasy** (controlling a legendary dragon in elemental combat).

---

## Detailed Design

### Core Rules

**Turn structure**

1. At `PHASES.PLAYER_TURN`, the player selects one of their dragon's moves, `basic_attack`, or `defend`. On standard battles only, they may instead trigger a reserve swap (costs the turn).
2. The engine simultaneously selects an NPC move via `pickNpcMove` (or fires a charged move, signature move, or defend during charge wind-up — see Charge Moves below).
3. `resolveTurn` is called with both move selections.
4. Speed order: the combatant with the higher `spd` stat acts first. Ties go to the player (`playerFirst = player.spd >= npc.spd`).
5. After the first actor resolves, the target is checked. If `hp > 0`, the second actor resolves. If the first actor KO'd the target, the second actor's action is skipped entirely.
6. After both actions, status effects tick (DOT damage applied, turn counters decremented). Expired statuses are cleared. `reflecting` flags are cleared. Buff duration counters are decremented; buffs that reach 0 turns are removed.
7. The result object `{ player, npc, events }` is returned for animation.

**Move types**

| Type | Key indicator | Effect |
|---|---|---|
| Attack | default (no `actionType`) | Deals damage; may apply status |
| Defend | `moveKey === 'defend'` | Sets `defending: true`; halves damage received this turn |
| Reflect | `move.isReflect === true` | Sets `reflecting: true`; redirects the next hit back to the attacker |
| Buff | `move.actionType === 'buff'` | Sets `atkBuff` or `defBuff` on self for `buffDuration` turns |

**Speed tie-breaking** — the player wins all ties (`>=`), giving a minor structural advantage to speed investment.

**Freeze skip** — a combatant with status `ice` (Freeze) cannot act; their action is skipped entirely for 1 turn.

**Paralyze skip** — a combatant with status `storm` (Paralyze) has a 50% chance to skip their action each turn for 2 turns (probability defined as `STATUS_EFFECTS.storm.value = 0.5`).

**Void Glitch** — a combatant with status `void` (Glitch) has their selected move replaced with a random move from their available move list for 1 turn.

---

### Damage Formula

Source: `src/battleEngine.js`, function `calculateDamage`.

**Step 1 — Accuracy check**
```
accuracyRoll = Math.random() * 100
if accuracyRoll > move.accuracy → miss (damage = 0, hit = false)
```
The `shadow` (Blind) status reduces effective accuracy: `effectiveAccuracy = move.accuracy − STATUS_EFFECTS.shadow.value × 100 = move.accuracy − 30`.

**Step 2 — Base damage**
```
stageMult   = stageMultipliers[attacker.stage]   // {1:0.6, 2:0.8, 3:1.0, 4:1.2}
powerScale  = move.power / 65                     // normalised against the baseline power of 65
baseDamage  = (attacker.atk × stageMult × powerScale × 2) − (defender.def × 0.5)
```

**Step 3 — Type effectiveness**
```
typedDamage = baseDamage × typeChart[move.element][defender.element]
```
Possible multipliers: `0.5` (resisted), `1.0` (neutral), `2.0` (super-effective).

**Step 4 — Defend halving**
```
if defender.defending:
    typedDamage × 0.5
```

**Step 5 — Damage roll**
```
roll        = 0.85 + Math.random() × 0.15     // [0.85, 1.0)
finalDamage = max(1, floor(typedDamage × roll))
```

**Step 6 — Critical hit**
```
isCritical = Math.random() < CRIT_CHANCE   // 0.10 (10%)
if isCritical:
    finalDamage = floor(finalDamage × CRIT_MULTIPLIER)   // × 1.5
```
Critical hits apply AFTER the damage roll. Crits bypass the defend halving calculation because `defending` is applied in step 4 before the crit in step 6. (No crit-ignores-defense mechanic beyond ordering.)

**Minimum output**: `max(1, …)` in step 5 guarantees at least 1 damage on every hit.

---

### Effective Attack (Buff + Charge Cap)

Source: `src/battleEngine.js`, function `effectiveAttack`.

```
buffMult        = atkBuff?.multiplier ?? 1
combinedMult    = min(buffMult × chargeMultiplier, MAX_ATK_MULTIPLIER)   // cap = 1.5
effectiveAtk    = floor(atk × combinedMult)
```

`chargeMultiplier` is 1 by default; it is set to `CHARGE_ATK_MULTIPLIER` (1.4) when the NPC fires a charged move. The cap at `MAX_ATK_MULTIPLIER` (1.5) prevents the stacking of `npc_focus` (1.3×) and a charged strike (1.4×) from producing the otherwise-reachable 1.82× spike.

**NPC defense buff applied to effective DEF**:
```
effectiveDef = target.def
if target.status.effect === 'stone':   // Guard Break
    effectiveDef = floor(effectiveDef × (1 − STATUS_EFFECTS.stone.value))   // ×0.6
if target.defBuff:
    effectiveDef = floor(effectiveDef × target.defBuff.multiplier)
```

---

### The 8 × 8 Type Chart

Source: `src/gameData.js`, `typeChart`. Rows = attacker element; columns = defender element. Values are multipliers applied to `baseDamage`.

|           | fire | ice  | storm | stone | venom | shadow | void | light |
|-----------|------|------|-------|-------|-------|--------|------|-------|
| **fire**  | 0.5  | 2.0  | 1.0   | 0.5   | 2.0   | 1.0    | 1.0  | 1.0   |
| **ice**   | 0.5  | 0.5  | 2.0   | 1.0   | 1.0   | 2.0    | 1.0  | 1.0   |
| **storm** | 1.0  | 0.5  | 0.5   | 2.0   | 1.0   | 0.5    | 2.0  | 1.0   |
| **stone** | 2.0  | 1.0  | 0.5   | 0.5   | 2.0   | 1.0    | 1.0  | 1.0   |
| **venom** | 0.5  | 1.0  | 1.0   | 0.5   | 0.5   | 2.0    | 1.0  | 2.0   |
| **shadow**| 1.0  | 0.5  | 2.0   | 1.0   | 0.5   | 0.5    | 2.0  | 2.0   |
| **void**  | 1.0  | 1.0  | 1.0   | 2.0   | 1.0   | 0.5    | 1.0  | 2.0   |
| **light** | 1.0  | 1.0  | 1.0   | 1.0   | 2.0   | 2.0    | 0.5  | 1.0   |

Notable relationships:
- Fire/Ice are mutually resistant (0.5 each way).
- Storm and Stone form a simple advantage loop: storm beats stone, stone beats storm.
- Shadow is strong against Ice, Venom, Shadow, but weak against Storm, Void, Light — it punishes slow defensive play.
- Void is strong against Stone and Light, but weak to Shadow and itself — the endgame element is not universally dominant.
- Light defeats Venom and Shadow, resists Void — a late-unlock counter to shadow-heavy enemy rosters.

---

### Status Effects

Source: `src/gameData.js`, `STATUS_EFFECTS`. Applied on hit with `STATUS_APPLY_CHANCE = 0.30` (30%) when `move.canApplyStatus === true`.

| Status     | Key in map | Type       | Duration | Effect value | Mechanic                                                        |
|------------|------------|------------|----------|--------------|-----------------------------------------------------------------|
| Burn       | `fire`     | `dot`      | 2 turns  | 0.15         | Deals `floor(maxHp × 0.15)` damage at end of each turn        |
| Freeze     | `ice`      | `skip`     | 1 turn   | 1.0          | Skips the afflicted combatant's action entirely for 1 turn     |
| Paralyze   | `storm`    | `maySkip`  | 2 turns  | 0.5          | 50% chance to skip action each of 2 turns                      |
| Guard Break| `stone`    | `debuff`   | 2 turns  | 0.4          | Reduces target's effective DEF by 40% (`effectiveDef × 0.6`)  |
| Poison     | `venom`    | `dot`      | 2 turns  | 0.12         | Deals `floor(maxHp × 0.12)` damage at end of each turn        |
| Blind      | `shadow`   | `debuff`   | 2 turns  | 0.3          | Reduces attacker's move accuracy by 30 percentage points       |
| Glitch     | `void`     | `randomize`| 1 turn   | 1.0          | Replaces attacker's chosen move with a random move key         |
| Dazzle     | `light`    | `debuff`   | 2 turns  | 0.3          | Reduces attacker's move accuracy by 30 percentage points       |

**Status tick timing** — DOT damage fires at the end of the turn (after both actors have resolved), applied to `hp` with a minimum of 1. The tick decrements `turnsLeft`; when `turnsLeft` reaches 0 the status is cleared.

**Status stack rule** — only one status may be active on a combatant at a time. A newly applied status overwrites the existing one. The engine applies the new status by writing `{ effect: moveElement, turnsLeft: duration }` to the combatant's `status` field.

**Relic extension** — the `coolant_core` relic adds `relicMods.statusDurationBonus` to `turnsLeft` whenever the player applies a new status to the NPC (BattleScreen.jsx, post-resolution hook).

---

### Buff System

Source: `src/gameData.js` (move data), `src/battleEngine.js` (`resolveAction`, `decrementBuff`).

Two NPC-only buff moves exist:

| Move key    | Name    | Stat | Multiplier | Duration |
|-------------|---------|------|------------|----------|
| `npc_focus` | Focus   | atk  | 1.3×       | 1 turn   |
| `npc_harden`| Harden  | def  | 1.4×       | 2 turns  |

**Application** — on a buff action, `actor.state[buffKey]` is set to `{ multiplier, turnsLeft: buffDuration + 1 }`. The `+1` ensures that the end-of-turn `decrementBuff` leaves `turnsLeft > 0` on the application turn, making the buff active for the full intended number of subsequent attack turns.

**Anti-stack rule** — `pickNpcMove` filters out `npc_focus` if `npcAtkBuff` is already active, and `npc_harden` if `npcDefBuff` is already active. Buffs cannot be stacked on top of themselves.

**Player-side buff system** — the player has no access to buff moves in the base implementation. The framework exists (the buff multiplier path in `effectiveAttack` consults `actor.state.atkBuff`), so future player buff moves could be added without engine changes.

---

### Charged Moves

Source: `src/BattleScreen.jsx` (`handleMoveSelect`), `src/battleEngine.js` (`effectiveAttack`).

**Charge-eligible moves** (flagged `canCharge: true` in `moves`):

| Move              | Element | Power | chargeChance |
|-------------------|---------|-------|--------------|
| `blizzard`        | ice     | 70    | 0.45         |
| `lightning_strike`| storm   | 70    | 0.40         |
| `earthquake`      | stone   | 75    | 0.50         |
| `toxic_cloud`     | venom   | 70    | 0.40         |
| `void_pulse`      | shadow  | 75    | 0.45         |
| `void_rift`       | void    | 80    | 0.55         |
| `solar_flare`     | light   | 70    | 0.40         |
| `golem_rupture`   | stone   | 95    | 0.70 (sig)   |

**Charge sequence**:
1. The NPC selects a charge-eligible move and a random roll passes below `chargeChance`.
2. The NPC's selected move is stored in `npcChargedMove` state; the NPC executes `defend` this turn (absorbs the player's attack at half damage while winding up).
3. The player is shown a warning log line: `"[NPC] is winding up [move name]!"`.
4. Next turn: `npcChargedMove` is set — the engine fires the stored move with `chargeMultiplier = CHARGE_ATK_MULTIPLIER` (1.4×) passed to `effectiveAttack`, capped at `MAX_ATK_MULTIPLIER` (1.5×) when combined with any active `atkBuff`.
5. Desperation mode (NPC HP < 30%) suppresses charging — the NPC attacks immediately rather than winding up.

**Player-side charging** — players do not have a charge mechanic. The charge system is NPC-only.

---

### NPC Signature Moves

Source: `src/gameData.js` (`npcs[id].signatureMoveKey`, `signatureCondition`), `src/BattleScreen.jsx`.

Each NPC with a signature move fires it exactly once per battle when their HP falls to or below the `hpThreshold`. The move is prioritised over the normal `pickNpcMove` path and over charge initiation. After firing, `signatureMoveUsed` is set to `true` and the move will not fire again.

| NPC                  | Signature Move      | Element | Power | Threshold |
|----------------------|---------------------|---------|-------|-----------|
| `bit_wraith`         | Void Unravel        | void    | 85    | ≤ 50% HP  |
| `glitch_hydra`       | Arc Overload        | storm   | 85    | ≤ 40% HP  |
| `recursive_golem`    | Tectonic Rupture    | stone   | 95    | ≤ 45% HP  |
| `logic_bomb`         | Final Detonation    | fire    | 90    | ≤ 35% HP  |
| `protocol_vulture`   | Soul Drain          | shadow  | 90    | ≤ 50% HP  |

Signature moves are distinct from charged moves — they fire unconditionally and instantly (no two-turn wind-up) when the HP threshold is crossed.

---

### Adaptive NPC AI (`pickNpcMove`)

Source: `src/battleEngine.js`, function `pickNpcMove`.

The NPC AI evaluates the current battle state each turn and applies a priority stack to select a move:

**Priority 1 — Desperation mode** (`enemyHpRatio < 0.30`)
- Filters to offensive moves only (drops buffs and status targets).
- Sorts by descending power and returns the highest-power move.
- Prevents buffing or charging when about to lose.

**Priority 2 — Anti-stack** (always active when not in desperation)
- `npc_focus` is removed from the candidate pool if `npcAtkBuff` is already active.
- `npc_harden` is removed if `npcDefBuff` is already active.

**Priority 3 — Early buff preference** (`turnCount <= 2`)
- 45% chance to pick a buff move if buff moves are available and it is turns 0–2.
- Simulates an NPC that opens by fortifying before attacking.

**Priority 4 — Counter-element adaptation**
- Inspects the last 3 player moves (rolling window via `playerMoveHistory`).
- If all three share the same element (player is spamming one type), finds moves that are super-effective against that element.
- 75% chance to pick a counter move if one exists.
- Punishes predictable single-element player strategies.

**Priority 5 — Super-effective targeting**
- Checks all offensive moves for type advantage (`typeChart[move.element][playerElement] > 1.0`).
- 70% chance to pick a super-effective move if one is available.

**Priority 6 — Exploit wounded player** (`exploitMode`: NPC HP > 70%, player HP < 40%, no player status)
- Status move chance raised from 40% to 70%.
- Attempts to apply a status to a weakened but not-yet-debuffed player.

**Priority 7 — Power preference**
- 60% chance to pick the highest-power offensive move.

**Priority 8 — Random fallback**
- 70% chance to pick from offensive moves; 30% chance to include `basic_attack`.

Reflect moves (`isReflect: true`) are filtered out of NPC candidates entirely — only the player's Void Dragon has access to `null_reflect`.

---

### Reserve Dragon (Bench)

Source: `src/benchLogic.js`, `src/BattleScreen.jsx`.

**Setup** — a reserve dragon is available only in standard battles (not bosses, Singularity arc, daily challenges). The player selects a bench dragon in `BattleSelectScreen` via `battleConfig.benchDragonId`. Both active and bench dragons are initialised with full, independently-calculated stats.

**Manual swap** — at the player's turn, if the bench dragon has `hp > 0`, the player may swap instead of attacking. This costs the player's turn: the engine resolves a free NPC attack against the incoming dragon (who enters defending, taking half damage). The outgoing dragon retains its current HP and status in the bench slot.

**Faint swap (second life)** — when the active dragon's HP reaches 0 and the bench has `hp > 0`, the bench dragon automatically steps in at its current HP. The fallen dragon is removed (bench is cleared). This is a free action — the player takes their next turn normally.

**Bench XP** — the reserve dragon earns half XP on victory: `floor(xpGained / 2)`.

**Boss restriction** — bosses, the Singularity arc, the Mirror Admin, Corruption Remnants, and daily challenges all lock the bench out (`initBattle` skips bench initialisation). The comment explains this is deliberate to preserve fixed time-to-kill balance for high-stakes fights.

---

### NPC Scaling

Source: `src/BattleScreen.jsx`, function `getScaledNpcStats`.

Standard NPC stats scale if the player's dragon level exceeds the NPC's base level:

```
levelScale = 1 + max(0, playerLevel − npcBaseLevel) × 0.04   // +4% per over-level
ngScale    = 1 + ngPlus × 0.25                                // +25% per New Game+ tier
scale      = levelScale × ngScale
scaledStat = floor(baseStat × scale)
scaledLevel = max(npcBaseLevel, floor(npcBaseLevel + max(0, playerLevel − npcBaseLevel) × 0.5))
```

When `scale === 1` (player is not over-levelled and NG+ is 0), base stats are used unchanged.

---

### Stat Growth (Dragon Level-Up)

Source: `src/battleEngine.js`, function `calculateStatsForLevel`.

```
levels    = level − 1
totalBase = hp + atk + def + spd         // sum of base stats
budget    = levels × 12                  // total stat points earned
mult      = shiny ? 1.2 : 1.0
grow(base) = floor((base + budget × (base / totalBase)) × mult)
```

Each stat grows proportionally to its share of `totalBase`, keeping the dragon's archetype shape constant across levels. Shiny dragons gain a flat 20% stat bonus.

Stage thresholds gate a separate `stageMult` applied inside `calculateDamage`:

| Level | Stage | stageMult |
|-------|-------|-----------|
| 1–7   | 1     | 0.6       |
| 8–19  | 2     | 0.8       |
| 20–37 | 3     | 1.0       |
| 38+   | 4     | 1.2       |

---

### XP and Reward System

Source: `src/battleEngine.js` (`calculateXpGain`), `src/BattleScreen.jsx` (victory handler).

**XP formula**:
```
ratio   = min(2, max(0.25, enemyLevel / playerLevel))
xpGained = max(1, floor(baseXP × ratio))
```
XP is clamped between 25% and 200% of `baseXP` based on the level delta. Enemy outscaling the player doubles XP; player heavily outscaling halves it.

**Repeat penalty** — a previously defeated NPC pays 25% scraps. Singularity/boss/remnant repeat clears also pay 25% scraps.

**New Game+ bonus** — each NG+ tier adds 25% to both XP and scraps earned.

**Core drop** — `CORE_DROP_CHANCE` roll on every victory. Success drops 1 core (or 2 on a secondary `CORE_DOUBLE_CHANCE` roll) of the defeated NPC's element.

**Relic drop** — first defeat of select NPCs only (defined in `RELIC_DROPS` in `forgeData.js`).

---

### Battle Rank

Source: `src/BattleScreen.jsx`, function `getBattleRank`. Displayed on the victory screen.

| Criterion | Points |
|-----------|--------|
| Win in ≤ 3 turns | 2 |
| Win in 4–5 turns | 1 |
| Max damage dealt ≥ 24 | 2 |
| Max damage dealt 14–23 | 1 |
| Player HP ≥ 70% on victory | 2 |
| Player HP 40–69% on victory | 1 |

| Total | Rank |
|-------|------|
| 6     | S    |
| 4–5   | A    |
| 2–3   | B    |
| 0–1   | C    |

---

### Multi-Phase Bosses

Source: `src/BattleScreen.jsx` (`PHASES.PHASE_SHIFT` reducer case, phase-shift block in `handleMoveSelect`).

Bosses defined with a `phases` array cycle through each phase sequentially. When the current phase's HP reaches 0, instead of triggering victory:
1. A `shatterKO` animation plays on the current phase sprite.
2. The reducer dispatches `PHASE_SHIFT`, replacing `npc` stat block, name, element, move set, and sprite with the next phase's data; HP is reset to the next phase's `stats.hp`.
3. The player's HP, status, and all buffs carry over unmodified.
4. A phase dialogue line is logged from `boss.phaseLines[nextPhaseIndex]`.
5. The fight continues at `PHASES.PLAYER_TURN`.

Victory fires only when the final phase's HP reaches 0.

---

### Auto-Battle

Source: `src/BattleScreen.jsx`. Available only in standard (non-boss, non-Singularity, non-daily-challenge) battles. When enabled, the player dragon's moves are selected by `pickNpcMove` with the same adaptive logic as the NPC, on a 500ms delay per turn.

---

## Formulas

### Damage

```
effectiveAtk = floor(atk × min(buffMult × chargeMultiplier, 1.5))
stageMult    = stageMultipliers[attacker.stage]      // {1:0.6, 2:0.8, 3:1.0, 4:1.2}
powerScale   = move.power / 65
baseDamage   = (effectiveAtk × stageMult × powerScale × 2) − (effectiveDef × 0.5)
typedDamage  = baseDamage × typeChart[move.element][defender.element]
if defender.defending: typedDamage × 0.5
roll         = 0.85 + rand() × 0.15
finalDamage  = max(1, floor(typedDamage × roll))
if crit (10%): finalDamage = floor(finalDamage × 1.5)
```

| Variable | Source | Range |
|---|---|---|
| `atk` | `calculateStatsForLevel` | Dragon-dependent; grows with level |
| `buffMult` | `npcAtkBuff?.multiplier` or 1 | 1.0–1.3 |
| `chargeMultiplier` | `CHARGE_ATK_MULTIPLIER` or 1 | 1.0 or 1.4 |
| `effectiveAtk` cap | `MAX_ATK_MULTIPLIER` | 1.5× maximum combined |
| `stageMult` | `stageMultipliers` | 0.6–1.2 |
| `powerScale` | `move.power / 65` | 0.615 (`basic_attack` 40) to 1.46 (`golem_rupture` 95) |
| `effectiveDef` | `calculateStatsForLevel` ± status/buff | Dragon-dependent |
| `typeChart value` | `typeChart` | 0.5, 1.0, or 2.0 |
| `roll` | `Math.random()` | [0.85, 1.0) |
| `CRIT_CHANCE` | constant | 0.10 |
| `CRIT_MULTIPLIER` | constant | 1.5 |

**Minimum output**: 1 (enforced by `max(1, …)` before the crit check — crits on near-zero base still produce at least 1 damage).

### XP Gain

```
ratio    = clamp(enemyLevel / playerLevel, 0.25, 2.0)
xpGained = max(1, floor(baseXP × ratio))
```

### Stat Growth (per level)

```
budget    = (level − 1) × 12
grow(base) = floor((base + budget × (base / totalBase)) × (shiny ? 1.2 : 1.0))
```

### NPC Level Scaling

```
scale      = (1 + max(0, playerLevel − npcBase) × 0.04) × (1 + ngPlus × 0.25)
scaledStat = floor(baseStat × scale)
```

---

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|---|---|---|
| `baseDamage` goes negative (very high defender DEF) | `max(1, ...)` clamp ensures at least 1 damage | Prevents healing-via-damage edge case; no move ever heals the target |
| Both combatants faint simultaneously | Only the player faint path executes because the NPC HP check comes first in `resolveTurn`; if `firstTarget.hp <= 0`, second actor is skipped | Maintains "who acts first wins" consistency |
| Reflected move misses | Reflect clears (`target.reflecting = false`); attacker receives a normal miss event | Avoids a silent no-op; the reflect is consumed by the miss |
| Void Glitch selects a reflect move from the NPC | `pickNpcMove` already filters `isReflect` moves; Glitch's random replacement draws from `npcMoveKeys`, which do not include reflect | NPC cannot accidentally self-reflect |
| Player applies status to a target that already has a status | New status overwrites. `status` is a single field; no stacking | Keeps status economy simple; prevents double-poison + double-blind chains |
| Charge move queued, then NPC hits desperation (< 30% HP) next turn | Desperation check fires BEFORE the charge-fire path in `handleMoveSelect`. When `npcChargedMove` is already set, it fires regardless of desperation. Desperation only suppresses NEW charge initiations. | NPC always fires an already-queued charge rather than abandoning it |
| Bench dragon KO'd on the entry strike during a manual swap | If the bench dragon is KO'd on entry and the outgoing (now reserve) dragon still has HP, `FAINT_SWAP` is dispatched again to bring it back. If both dragons are now at 0 HP, defeat triggers. | No soft-lock; the fight always resolves |
| Boss has only one phase (no `phases` array) | Victory fires immediately when `npcHp <= 0`. Phase-shift logic is guarded by `phases && currentPhaseIndex < phases.length - 1`. | Single-phase bosses behave identically to regular NPCs |
| Guard Break + Harden buff both active on defender | `effectiveDef` is first reduced by Guard Break (×0.6), then multiplied by `defBuff.multiplier`. Order: Guard Break then def buff. Both can be active simultaneously with no conflict. | Defence penalty applies to the raw stat; the buff then scales the result |
| `STATUS_APPLY_CHANCE` roll succeeds but `applyStatus` returns null | `applyStatus` checks `STATUS_EFFECTS[moveElement]`; `basic_attack` has element `neutral`, which has no status effect entry — returns null. Null result is checked before writing to the target. | Prevents null status writes from moves that cannot logically inflict a status |
| Player uses Null Reflect and the NPC charges that turn | NPC charges: it defends this turn and stores the move for next turn. Reflect is set on player. Next turn the NPC fires the charged move — reflect triggers, damage returns to NPC. | Reflects charged strikes; intended high-skill interaction |

---

## Dependencies

| System | Direction | Nature of Dependency |
|---|---|---|
| `design/gdd/dragon-progression.md` | Combat depends on progression | Reads `level`, `xp`, `stage`, `fusedBaseStats`, `shiny` from `save.dragons[id]` to initialise combat stats |
| `design/gdd/economy.md` | Combat provides to economy | Victory handler calls `addScraps`, `addCore`, `grantRelic`, `addDragonXp` — combat is the primary economy faucet |
| `design/gdd/combat.md` | Combat implements status effects | `STATUS_EFFECTS`, `STATUS_APPLY_CHANCE` consumed from `gameData.js`; tick logic lives in `battleEngine.js` |
| `design/gdd/fusion.md` | Fusion depends on combat | XP earned in combat enables level-ups; minimum level gates are required to access fusion |
| `design/gdd/forge-skye.md` | Combat reads relic modifiers | `getRelicBattleModifiers` applied to ATK, DEF, SPD, XP multiplier, status duration, chain hit chance |
| `design/gdd/singularity-endgame.md` | Combat writes singularity state | Victory calls `recordSingularityDefeat`, `markSingularityComplete`, `unlockFragment` |
| `design/gdd/daily-challenge.md` | Combat reads daily config | `battleConfig.dailyNpc` drives streak multiplier, scraps reward, and completion flag |
| `design/gdd/audio.md` | audio.md depends on combat | Combat provides element strings, HP/maxHP ratio for music threshold, and turn-event sequence to audio system |
| `design/gdd/campaign-map.md` | Bidirectional | Campaign provides `campaignNodeId` + NPC defs into `battleConfig`; combat calls `recordNpcDefeat` on win |
| `design/gdd/vfx-animation-accessibility.md` | Combat provides to vfx-animation-accessibility | Combat provides the `resolveTurn {events}` object shape as the animation contract consumed by the presentation layer |
| `design/gdd/hatchery-gacha.md` | Data dependency: hatchery writes, combat reads | Hatchery writes `dragon.shiny`; combat reads it in `calculateStatsForLevel` for the ×1.2 stat multiplier |

---

## Tuning Knobs

All live in source files, not external data files (existing implementation — ideal future state would move these to `assets/data/`).

| Parameter | Current Value | File:identifier | Category | Safe Range | Effect of Increase | Effect of Decrease |
|---|---|---|---|---|---|---|
| `CRIT_CHANCE` | 0.10 | `battleEngine.js:3` | feel | 0.05–0.20 | More crits; higher burst variance; less predictable pacing | Fewer crits; fights feel more deterministic |
| `CRIT_MULTIPLIER` | 1.5× | `battleEngine.js:4` | feel | 1.25–2.0 | Higher crit spikes; more one-shot potential | Crits feel less rewarding |
| `CHARGE_ATK_MULTIPLIER` | 1.4× | `battleEngine.js:7` | feel | 1.2–1.6 | Charged strikes hit harder; more dangerous charge turns | Charging feels less threatening; less incentive to block |
| `MAX_ATK_MULTIPLIER` | 1.5× | `battleEngine.js:11` | gate | 1.4–1.8 | Buff + charge can combine for higher peaks | Cap too low makes Focus + charge underperform independently |
| `STATUS_APPLY_CHANCE` | 0.30 | `gameData.js:376` | feel | 0.15–0.50 | Status procs more often; status-move strategies more viable | Status becomes unreliable; status moves lose value |
| Damage roll lower bound | 0.85 | `battleEngine.js:51` | feel | 0.75–0.90 | Higher variance; a bad roll hurts more | Lower variance; fights more consistent |
| `stageMultipliers` | {1:0.6, 2:0.8, 3:1.0, 4:1.2} | `gameData.js:20` | curve | — | Wider stage spread amplifies early weakness and late power | Flatter curve; stage gates matter less |
| `stageThresholds` | {2:8, 3:20, 4:38} | `gameData.js:23` | gate | — | Later thresholds slow progression | Earlier thresholds compress the power curve |
| NPC over-level scale rate | 0.04 per level | `BattleScreen.jsx:43` | curve | 0.02–0.07 | NPCs become more dangerous as players level past them | Over-levelled players face weaker resistance |
| NG+ scale bonus | 0.25 per tier | `BattleScreen.jsx:43` | curve | 0.15–0.40 | Harder NG+ runs; more reward incentive | NG+ barely changes difficulty |
| `npc_focus` multiplier | 1.3× | `gameData.js:54` | curve | 1.1–1.5 | Focused NPC attacks hit harder | Focus feels negligible; anti-stack rule becomes moot |
| `npc_harden` multiplier | 1.4× | `gameData.js:55` | curve | 1.2–1.6 | Hardened NPC is much tankier | Harden feels cosmetic |
| `npc_harden` duration | 2 turns | `gameData.js:55` | gate | 1–3 | Extended defence window; harder to burst through | Harden expires quickly; less impact on pacing |
| Counter-element AI chance | 0.75 | `battleEngine.js:169` | feel | 0.5–0.9 | AI counters spam more reliably | Spam strategies less consistently punished |
| Super-effective AI chance | 0.70 | `battleEngine.js:183` | feel | 0.5–0.9 | AI exploits type weaknesses more often | NPC feels less tactically aware |
| Exploit (status) base chance | 0.40 | `battleEngine.js:188` | feel | 0.2–0.6 | NPC applies status more aggressively against healthy players | Less status pressure |
| Exploit mode status chance | 0.70 | `battleEngine.js:188` | feel | 0.5–0.9 | NPC piles on wounded players hard | Exploit mode less punishing |
| Early buff turn window | 2 | `battleEngine.js:155` | gate | 1–4 | NPC buffs later into the fight | NPC opens faster but misses early fortification |
| Early buff probability | 0.45 | `battleEngine.js:155` | feel | 0.2–0.7 | NPC buffs on nearly every early turn | NPC buffs less consistently |
| Desperation threshold | 0.30 | `battleEngine.js:134` | gate | 0.20–0.40 | NPC goes all-out earlier | More turns before NPC panics |
| Exploit mode min player HP | 0.40 | `battleEngine.js:135` | gate | 0.25–0.55 | NPC exploits even less-wounded players | Exploit only triggers when player is very low |
| Repeat clear scraps ratio | 0.25× | `BattleScreen.jsx:~932` | gate | 0.1–0.5 | Repeat grinding pays more | Less incentive to farm previously-defeated NPCs |

> Stat budget per level (12) is a tuning knob owned by design/gdd/dragon-progression.md.

---

## Visual/Audio Requirements

N/A — detailed visual and audio implementation lives in `src/battlePresentation.js` and `src/animationEngine.js`. Summary:

| Event | Visual Feedback | Audio Feedback |
|---|---|---|
| Attack lands (normal) | `hitFlash`, `hitFlicker`, `targetKnockback`, `pixelShake` | `attackHit` |
| Attack lands (super-effective) | Same + element-tinted flash, heavier shake | `superEffective` |
| Attack lands (critical) | `criticalHit` GSAP timeline, `hitFlicker` | `criticalHit` |
| Attack misses | `sprite-whiff` class on target | `miss` |
| Attack resisted | Soft recoil, muted flash | `resisted` |
| Status applied | `statusAuraApply` persistent aura, status label damage number | `statusApply` |
| Status tick | Damage number with status element tint | `statusTick` |
| Status expires | Aura removed | `statusExpire` |
| KO | `shatterKO` GSAP timeline on defeated sprite | `ko` |
| Phase shift | `shatterKO` then replace sprite + stats | `terminalGlitch` |
| Defend | `shieldUp` element-tinted shield overlay | `defend` |
| Buff | `sprite-telegraph`, "ATTACK/DEFENSE UP" damage number label | `statusApply` |
| Charge wind-up | NPC defends; log warning | `attackLaunch` |
| Signature move | "SIGNATURE" callout banner | (inherits move sound) |
| Victory | `sprite-celebrate`, XP/scraps overlay | `victoryFanfare`, `xpGain` |
| Defeat | `sprite-defeated` | `defeatDrone` |

---

## Game Feel

N/A — this is a turn-based browser game. Frame-data, hitbox timing, input latency, controller rumble, and hit-stop in the real-time sense do not apply. The closest analogue to "feel" parameters in this system are the presentation timing values in `battlePresentation.js`:

| Profile | `anticipationMs` | `impactPauseMs` | `recoveryMs` |
|---|---|---|---|
| Normal hit | 260 ms | 60 ms | 200 ms |
| Super-effective | 300 ms (+ 60 if power ≥ 70) | 90 ms | 220 ms |
| Critical hit | 340 ms | 120 ms | 260 ms |
| KO | 320 ms | 140 ms | 320 ms |
| Defend | 240 ms | 0 ms | 180 ms |
| Buff | 200 ms | 60 ms | 300 ms |

These are feel knobs, not balance knobs. Adjusting them changes the rhythm of combat without affecting outcomes.

---

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|---|---|---|---|
| Player HP bar | Left side of battle screen | After each damage event | Always |
| NPC HP bar | Right side of battle screen | After each damage event | Always |
| Player status icon | Below player HP | On status apply/expire | When status is active |
| NPC status icon | Below NPC HP | On status apply/expire | When status is active |
| Active buff indicators | Beside NPC HP | On buff apply/expire | When NPC has atkBuff or defBuff |
| Move buttons (2 dragon moves + basic_attack + defend) | Player action panel | On turn start | `PHASES.PLAYER_TURN` |
| Move type effectiveness preview | Move button tooltip/label | On hover/focus | `PHASES.PLAYER_TURN` |
| Status summary (Blind/Paralyze etc.) | Move button sub-label | On hover/focus | When move has `canApplyStatus` |
| NPC charge warning | Battle log | Turn after charge initiation | When `isCharging` |
| Battle callout banner | Centre of screen | 620–900 ms after trigger | On MISS / RESIST / SUPER HIT / CRITICAL / REFLECT / SIGNATURE / FORTIFY |
| Damage numbers | Floating above target | Immediately on hit | On every damage event |
| Battle log text | Scrolling log area | Per event | After each animated event |
| Edge indicator | HUD | Each turn | Always |
| Battle rank | Victory screen | Once | After NPC KO, before next turn |
| Swap button | Player action panel | On turn start | When bench dragon alive |
| Bench dragon HP mini-bar | Below swap button | After bench takes entry damage | When bench exists |

---

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|---|---|---|---|
| Dragon base stats, level, stage, shiny flag | `design/gdd/dragon-progression.md` | `calculateStatsForLevel` output, `stageThresholds` | Data dependency |
| XP curve, `addDragonXp` | `design/gdd/dragon-progression.md` | `addDragonXp` persistence call, XP-to-level formula | Data dependency |
| Scraps, cores, relics earned on victory | `design/gdd/economy.md` | `addScraps`, `addCore`, `grantRelic` faucet calls | Ownership handoff |
| `STATUS_EFFECTS`, `STATUS_APPLY_CHANCE` | `design/gdd/combat.md` | Status effect table, application probability | Rule dependency |
| `getRelicBattleModifiers` | `design/gdd/forge-skye.md` | ATK/DEF/SPD bonus, XP multiplier, statusDurationBonus, chainHitChance | Data dependency |
| `recordSingularityDefeat`, `markSingularityComplete`, `unlockFragment` | `design/gdd/singularity-endgame.md` | Singularity progression flags | Ownership handoff |
| `completeDailyChallenge`, daily streak multiplier | `design/gdd/daily-challenge.md` | Streak multiplier, completion flag | Rule dependency |
| Bench dragon swap state | `design/gdd/combat.md` | `swapActiveAndBench`, `faintSwap` state transitions | Rule dependency |

---

## Acceptance Criteria

**Functional**

- [ ] Speed order: when player SPD equals NPC SPD, player always acts first.
- [ ] Minimum damage: no attack dealing a hit (accuracy check passed) can produce 0 or negative damage — floor is always 1.
- [ ] Type chart: a super-effective hit (`typeChart` = 2.0) deals exactly double the damage of a neutral hit (same stats, same roll) within float rounding.
- [ ] Defend: a defending combatant takes exactly half the damage they would take undefended — `typedDamage × 0.5` — before the roll and crit checks.
- [ ] Crit: a critical hit deals exactly `floor(finalDamage × 1.5)` damage; crits cannot occur on a miss.
- [ ] Status application: on a successful attack with `canApplyStatus: true`, the `STATUS_APPLY_CHANCE` roll (30%) is the only gate. A status is applied if and only if `Math.random() < 0.30`.
- [ ] Buff anti-stack: `npc_focus` is never selected when `npcAtkBuff` is active; `npc_harden` is never selected when `npcDefBuff` is active.
- [ ] `MAX_ATK_MULTIPLIER` cap: `effectiveAttack(atk=100, atkBuff={multiplier:1.3}, chargeMultiplier=1.4)` returns `floor(100 × 1.5) = 150`, not `floor(100 × 1.82) = 182`.
- [ ] Charge sequence: when `isCharging`, the NPC executes `defend` this turn and the stored move fires next turn at `CHARGE_ATK_MULTIPLIER`.
- [ ] Desperation suppresses charge: when `enemyHpRatio < 0.30`, `isCharging` is never set.
- [ ] Signature fires once: `signatureMoveUsed` prevents the signature from triggering again after the first use.
- [ ] Bench second life: when the active dragon faints and the bench has HP > 0, `FAINT_SWAP` is dispatched and the fight continues without a defeat screen.
- [ ] Boss phase shift: when phase N's HP reaches 0 and phase N+1 exists, NPC stats, name, element, and move set update to phase N+1; player HP is unchanged.
- [ ] Reflect: a move that hits a reflecting combatant damages the attacker, not the reflector; the reflect flag clears after use.
- [ ] Repeat clear penalty: a second defeat of the same NPC pays `floor(scrapsReward × 0.25)` scraps.
- [ ] No hardcoded values in presentation: presentation timing (anticipationMs, etc.) reads from `battlePresentation.js` profile objects, not inlined.

**Experiential (playtest validation)**

- [ ] A player who spams the same move repeatedly observes the NPC adapting within 3 turns — either countering the type or applying a status.
- [ ] A player who defends on the NPC's charge turn takes visibly less damage when the charged strike lands.
- [ ] Critical hits feel distinctly heavier than normal hits without feeling unfair — playtester comments on the moment without calling it "random luck."
- [ ] Players without any knowledge of the type chart lose to obvious type disadvantages, but feel they could have done better with more information.
- [ ] A session where the bench dragon saves the player creates a "close call" feeling rather than confusion about why the fight continued.

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| Should player dragons have access to buff moves in a future balance pass? | game-designer | — | Deferred — framework exists in engine, no design doc decision yet |
| The global damage formula (`atk×2 / def×0.5`) was flagged in the 2026-06-16 balance audit as over-powering ATK relative to DEF at high levels. A full reweight was deferred pending more playtest data. | game-designer + systems-designer | — | Addressed indirectly via fixed-TTK boss scaling; revisit after player analytics |
| Should the NPC AI have distinct behaviour profiles per enemy archetype (aggressive, defensive, status-first)? | game-designer | — | Currently all NPCs share the same `pickNpcMove` with their move pool as the only differentiator |
