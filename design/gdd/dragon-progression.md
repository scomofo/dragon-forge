# Dragon Progression

> **Status**: Approved
> **Author**: Scott + agents
> **Last Updated**: 2026-05-22
> **Implements Pillar**: Core Loop — Attachment (Wonder → Attachment emotional arc)

## Overview

Dragon Progression is the stat-growth and stage-evolution system governing all six core elemental dragons from hatch through level cap, plus the Singularity-granted Void story dragon after endgame unlock. Each dragon has four base stats (HP, ATK, DEF, SPD) that scale at +3 per level above 1; accumulated XP — earned through battle victories and hatchery duplicate pulls — drives level advancement at escalating per-stage rates (50 / 80 / 120 / 200 XP per level across Stages I through IV). Battle XP is awarded via the scaling formula in `battle-engine.md`: `max(1, floor(base_xp × enemyLevel / playerLevel))`. Reaching four level thresholds transitions a dragon through Stage I (1–9, Hatchling form) → Stage II (10–24) → Stage III (25–49) → Stage IV (50+), each stage applying an increasing damage multiplier in combat (0.5× → 0.75× → 1.0× → 1.4×). Shiny dragons carry a 1.2× bonus across all four base stats at every level, except Void, which is never shiny. Resonance charges reduce effective XP thresholds on level-up, providing a catch-up mechanism without enabling pure grinding. From the player's perspective, watching a dragon cross a stage threshold — visually changing form and measurably improving in battle — is the game's primary moment of attachment. The dragon the player hatched at Stage I that reaches Stage IV is the same guardian protocol, now running at its full allocated power. Mechanically, this GDD is the single source of truth for all core elements' base stat tables, the Void story-dragon stat row, the canonical stat scaling formula, MAX_LEVEL (the level cap that bounds Hatchery XP accumulation and is referenced by Battle Engine stage calculations), and the per-stage XP threshold constants referenced by the Hatchery XP loop.

## Player Fantasy

The Rendered World hatches its dragons from throttled seeds. A Stage I dragon is not young — it has been running, somewhere, for as long as the Astraeus has needed it to. What it cannot do, yet, is show its full allocation. The protocols that make a Fire dragon *burn dead data*, or a Shadow dragon *hide critical processes*, are initialized at hatch. They are not granted by leveling. They are *uncapped* by it.

**The fantasy of Dragon Progression is not making a dragon powerful. It is earning its trust until the throttle lifts.**

Every XP point is a shared record — a battle weathered together, a duplicate pull that thickens the dragon's instance data. The dragon tracks this. Astraeus systems are patient with entities that demonstrate consistent registration. When enough of that record accumulates, the next stage allocation opens — not because the dragon grew, but because the dragon decided the world was stable enough to let you see what it already was.

This creates a distinct emotional beat at each stage threshold:

**Stage I** is the Hatchling form. Every element presents young — visually small, unguarded, carrying a 0.5× combat multiplier because the full protocol isn't trusted to the world yet. This is not a flaw. The player does not experience Stage I as "my dragon is bad." They experience it as "my dragon is young." The art direction makes this legible: the Hatchling sprite is the distinct, almost-fragile version of the dragon's adult self. Players who know what comes protect their Hatchling. That protective instinct is the beginning of the bond.

**Stage I → II** is the first signal. The sprite changes — small, but there. Stats climb. The player may not yet articulate what shifted; they only sense the dragon settling into itself.

**Stage II → III** is the moment of recognition. The dragon stops feeling like a companion-in-progress and begins feeling like a peer. In combat, this is the stage where it carries encounters rather than survives them. Felix marks this crossing: *"She's not new, Skye. She's just allowed now."*

**Stage III → IV** is the one the player will remember. The XP bar fills. A Captain's Log entry surfaces — a fragment of documentation about what this element was originally written to do in the Astraeus. The sprite change is unmistakable. The player realizes they did not make the dragon stronger. They made themselves trusted enough — the world stable enough — for it to run at full allocation. Then, beneath the quiet awe, a faint second thought: *Has the Admin noticed yet?*

> **Designer test:** A Dragon Progression feature serves this fantasy if it makes a stage threshold feel like a *reveal* rather than a *reward*. XP bars should convey momentum, not scarcity. Stage transition animations should feel like recognition — the dragon acknowledging what just happened — not celebration. If a feature makes the player feel like they *upgraded* their dragon rather than *accompanied* it to a threshold it was always approaching, the framing has drifted.

## Detailed Design

### Core Rules

**Dragon Stats**

Each dragon has four base stats defined by element. These values apply at level 1, before any shiny multiplier:

| Element | Base HP | Base ATK | Base DEF | Base SPD |
|---------|---------|----------|----------|----------|
| Fire    | 110     | 28       | 16       | 22       |
| Ice     | 100     | 24       | 17       | 14       |
| Storm   | 90      | 30       | 13       | 32       |
| Stone   | 120     | 22       | 24       | 8        |
| Venom   | 95      | 26       | 19       | 12       |
| Shadow  | 85      | 32       | 11       | 28       |
| Void    | 80      | 40       | 20       | 36       |

Void is a story-only element granted by Singularity as `dragon_id = "void_dragon"`. It is not hatchable, pullable, fuseable, or duplicate-convertible. Void uses the normal stat scaling, stage thresholds, XP loop, and Battle Engine neutral type chart treatment after acquisition. It must be granted through a reserved story-roster slot outside normal roster capacity and must always have `dragon.shiny = false`.

**SPD is an internal stat only.** It is tracked in the dragon's data record but is not displayed to the player and has no effect in combat under the current ruleset. It is reserved for future mechanics.

**Level Advancement**

1. A dragon begins at level 1 and has a maximum level of MAX_LEVEL (60).
2. A dragon accumulates XP from two sources: battle victories and Hatchery duplicate pulls.
3. The XP cost to gain one level escalates with the dragon's current stage:

   | Current Stage | Current Level Range | XP to Next Level |
   |--------------|---------------------|-----------------|
   | I (Hatchling) | 1 – 9 | 50 XP |
   | II | 10 – 24 | 80 XP |
   | III | 25 – 49 | 120 XP |
   | IV | 50 – 59 | 200 XP |

4. XP in excess of the current threshold carries forward to the next level (e.g., 70 XP at level 5 advances to level 6 with 20 XP remaining, since Stage I threshold is 50).
5. At MAX_LEVEL (60), XP accumulation stops. Any XP earned at MAX_LEVEL is discarded.
6. HP, ATK, DEF, and SPD each increase by +3 per level above 1. Stats recalculate automatically on level-up.

**Battle XP**

Battle XP is determined by the formula in `battle-engine.md`, with Dragon Progression as the consumer:

```
xpAwarded = max(1, floor(base_xp × enemyLevel / playerLevel))
```

where `base_xp` is a tuning knob in `battle-engine.md` (~25 for standard NPC battles). Dragon Progression does not own this formula — it is authoritative in `battle-engine.md`. Any update to the XP formula requires revising that document, not this one.

**Battle Resonance Bonus**

Every battle a dragon actively fights adds to its resonance — a growing alignment between the dragon's threat-parsing and the player's tactical patterns. Felix calls this "running in parallel." The dragon is not merely following commands; it is anticipating them. This shared record of combat experience is what stage progression actually measures, and after enough fights together, it starts to matter mechanically: each battle the dragon has personally weathered makes the next threshold a little less costly to reach.

The Astraeus registration that tracks this is local — bounded to battles the dragon personally participates in as the active combatant. **Active Resonance** accrues only from battles this dragon fights directly. **Passive (Bench) Resonance** is a second accumulation path owned by the Campaign Map: a benched dragon that witnesses expedition battles alongside its handler is changed by proximity, even without striking a blow.

**Active Resonance (this GDD owns):**
- Each battle won by this dragon (as the active combatant) adds 1 resonance charge (stored as `dragon.battle_charges`), up to BATTLE_MAX_CHARGES (10).

**Passive Bench Resonance (Campaign Map contract):**
- When a dragon is benched on a campaign expedition (occupying slots 2–3), Campaign Map awards +1 `dragon.battle_charges` after each expedition battle (win or loss by the slot-1 dragon), subject to the same BATTLE_MAX_CHARGES (10) cap.
- This award is initiated by Campaign Map (see campaign-map.md Rule 9), not by Battle Engine. It represents proximity and witness: a benched dragon that walks with you and observes every battle accumulates resonance differently from one left in the roster at home.
- AC-DP92a's prohibition on out-of-scope charge increments applies to **Battle Engine events** only — it does not apply to Campaign Map's bench award, which is an explicit contracted accumulation path. See AC-DP92a (amended below).

**Both paths share the same field and cap:**
- When a dragon with resonance charges gains a level (from battle or Hatchery duplicate), the effective XP threshold for that level is reduced to `max(1, floor(threshold / RESONANCE_XP_MULT))` — making each level-up cheaper — and 1 resonance charge is consumed per level gained.
- Resonance charges accumulate across sessions (persisted in save data as `dragon.battle_charges`).
- Resonance charges do not accumulate once `dragon.level == MAX_LEVEL`.

> **Design intent (party rotation):** The Resonance system intentionally rewards deploying under-leveled dragons in battle. A player who rotates their roster and fields every dragon will advance all of them more efficiently than one who runs a single favourite through every fight. The catch-up effect is modest in magnitude — but each fight with a neglected dragon directly applies toward their progression. The mechanic represents the attachment fantasy mechanically: the dragon you fight with levels faster because you are building the shared record together.

**Shiny Dragons**

A dragon's shiny status is determined at hatch and never changes. A shiny dragon's stats are multiplied by 1.2× at every level, applied after level scaling and then floored (see Formulas).

**Stage Thresholds**

A dragon's stage is determined entirely by its current level:

| Stage | Level Range | Combat Damage Multiplier | Narrative Role |
|-------|-------------|--------------------------|---------------|
| I     | 1 – 9       | 0.5×                     | Hatchling — protocol not yet trusted to the world |
| II    | 10 – 24     | 0.75×                    | Growing — first allocation granted |
| III   | 25 – 49     | 1.0×                     | Peer — carries encounters rather than survives them |
| IV    | 50 – 60     | 1.4×                     | Full allocation — the throttle lifts |

Stage transitions happen automatically when a dragon's level crosses a threshold. No player action is required. A stage can never decrease.

At the Stage III → Stage IV transition, the Journal system surfaces a Captain's Log entry — a lore fragment about what this dragon's element was originally written to do in the Astraeus.

**XP from Hatchery Duplicates**

When a player pulls a duplicate dragon (same element), the Hatchery converts the duplicate into XP for the player's existing dragon of that element:

| Duplicate Rarity | XP Awarded |
|------------------|------------|
| Common           | 50         |
| Uncommon         | 100        |
| Rare (Shadow)    | 150        |

**XP from Battle**

A battle victory awards XP to the player's active dragon via the scaling formula in `battle-engine.md`. The formula and its `base_xp` tuning knob are authoritative in that document — see Section F (Dependencies) and `battle-engine.md` Tuning Knobs.

---

### States and Transitions

Dragon Progression has no discrete player-driven states. It is a passive accumulation system — level and XP increment as the player plays, and the only meaningful transitions are stage crossings.

**Stage Crossing Protocol**

When a dragon's level advances to a threshold value (10, 25, or 50):

1. The dragon's stage updates.
2. The new stage multiplier takes effect for all subsequent combat.
3. A pending `stage_advanced(element, from_stage, to_stage)` event is recorded for post-commit publication — allowing Felix dialogue, campaign map gates, and any stage-responsive system to hook in.
4. The stage sprite updates in all UI contexts (party view, battle screen, Hatchery Ring detail).
5. If the new stage is IV (threshold: level 50), a pending `stage_iv_reached(element)` event is recorded for Journal delivery after the SaveTransaction commits. (Both `stage_advanced` and `stage_iv_reached` publish on this crossing after commit success.)

The stage crossing resolves at the moment the level-up formula completes. Visual acknowledgment is handled by the Visual/Audio requirements — the system itself does not gate on any player confirmation.

---

### Interactions with Other Systems

| System | What This System Provides | What This System Receives |
|--------|--------------------------|---------------------------|
| Battle Engine | HP, ATK, DEF at current level; current stageMult; post-commit `stats_updated` / `stage_advanced` events | XP per battle victory via scaling formula in `battle-engine.md`. Active Resonance charge is awarded through Dragon Progression helpers by Campaign Map or Singularity settlement when the active dragon earns battle XP. |
| Hatchery | Dragon's current level; MAX_LEVEL constant (to discard XP at cap) | XP on duplicate pull (50 / 100 / 150) |
| Fusion Engine | Base stats at level 1 (pre-scaling, pre-shiny) for inheritance input; dragon record fields `base_hp`, `base_atk`, `base_def`, `base_spd`, and `is_elder` for fused outputs | New fused dragon records with inherited base stats and `is_elder` set by Fusion Engine |
| Save / Persistence | dragon.base_hp, dragon.base_atk, dragon.base_def, dragon.base_spd, dragon.level, dragon.xp, dragon.shiny, dragon.element, dragon.battle_charges, dragon.is_elder | Same fields on load; dragon.battle_charges and dragon.is_elder default to 0/false if absent in older saves |
| Journal / Console | Post-commit `stage_advanced(element, from, to)` event at all stage crossings; post-commit `stage_iv_reached(element)` event at Stage III → IV | Nothing |

**Dragon data contract** (fields owned by this system):

| Field | Type | Range | Notes |
|-------|------|-------|-------|
| `dragon.element` | String | Fire / Ice / Storm / Stone / Venom / Shadow / Void | Core elements are set at hatch; Void is set only by Singularity story grant |
| `dragon.base_hp` | int | ≥1 | Per-dragon level-1 HP allocation. Hatchery uses the canonical element table; Fusion writes inherited values; Singularity writes authored Void values. |
| `dragon.base_atk` | int | ≥1 | Per-dragon level-1 ATK allocation. |
| `dragon.base_def` | int | ≥1 | Per-dragon level-1 DEF allocation. |
| `dragon.base_spd` | int | ≥1 | Per-dragon level-1 SPD allocation. |
| `dragon.level` | int | 1 – 60 | |
| `dragon.xp` | int | 0 – (stage_threshold − 1) | 0–49 in Stage I, 0–79 in Stage II, 0–119 in Stage III, 0–199 in Stage IV. Always 0 when level == MAX_LEVEL. |
| `dragon.shiny` | bool | — | Set at hatch for core elements; forced false for Void; never changes |
| `dragon.battle_charges` | int | 0 – BATTLE_MAX_CHARGES (10) | Accumulated while this dragon is the active combatant in battle. Consumed on level-up when charges are present. |
| `dragon.is_elder` | bool | true / false | Set only by Fusion Engine when both parents were Stage IV at fusion time. Defaults false for Hatchery dragons, Void, and legacy records. Battle Engine reads this flag for the Elder Stage IV multiplier. |

**Signals emitted by this system:**

| Signal | When | Parameters |
|--------|------|-----------|
| `stats_updated(element)` | Published after SaveTransaction commit success, only if at least one level was gained | element: String |
| `stage_advanced(element, from_stage, to_stage)` | Recorded when `dragon.level` crosses any stage threshold (9→10, 24→25, 49→50) during staged XP application; published after commit success | element: String; from_stage: int (1–3); to_stage: int (2–4) |
| `stage_iv_reached(element)` | Recorded when `dragon.level` crosses to 50 during staged XP application; published after commit success for Journal integration | element: String |

## Formulas

All formulas in this section use integer arithmetic unless otherwise noted. `floor()` truncates toward zero. All stats are non-negative integers.

---

### Formula 1 — Stat at Level N

**Expression**

```
stat(level) = floor((baseStat + (level − 1) × 3) × shinyMult)
```

| Symbol | Type | Range | Description |
|--------|------|-------|-------------|
| `baseStat` | int | 8–120 | Element's base stat value at level 1 (see Detailed Design table) |
| `level` | int | 1–60 | Dragon's current level |
| `shinyMult` | float | {1.0, 1.2} | 1.0 for standard; 1.2 for shiny |
| `stat(level)` | int | baseStat–unbounded | Final computed stat value |

Minimum output: `baseStat` (level 1, non-shiny). Maximum output: `floor((baseStat + 177) × 1.2)`. Monotonically increasing; no clamp required.

**Boundary Check — Extremes (non-shiny)**

| Element / Stat | baseStat | Level 1 | Level 60 | Level 60 (shiny) |
|----------------|----------|---------|----------|------------------|
| Stone ATK (lowest) | 22 | 22 | 199 | 238 |
| Shadow ATK (highest) | 32 | 32 | 209 | 250 |
| Stone HP (highest) | 120 | 120 | 297 | 356 |
| Shadow DEF (lowest) | 11 | 11 | 188 | 225 |

No outputs go negative. Floor loses at most 0.999 — never a full point.

**Worked Example — Shadow ATK**

| Scenario | Calculation | Result |
|----------|-------------|--------|
| Level 1, non-shiny | floor((32 + 0) × 1.0) | 32 |
| Level 60, non-shiny | floor((32 + 177) × 1.0) | 209 |
| Level 60, shiny | floor(209 × 1.2) = floor(250.8) | 250 |

---

### Formula 2 — Stage from Level

```
stage(level) =
    Stage I   if  1 ≤ level ≤  9
    Stage II  if 10 ≤ level ≤ 24
    Stage III if 25 ≤ level ≤ 49
    Stage IV  if 50 ≤ level ≤ 60
```

| Stage | Level Range | stageMult |
|-------|-------------|-----------|
| I | 1–9 | 0.5× |
| II | 10–24 | 0.75× |
| III | 25–49 | 1.0× |
| IV | 50–60 | 1.4× |

**Boundary Verification**

| Level | Expected Stage | Passes? |
|-------|---------------|---------|
| 9 | Stage I | Yes |
| 10 | Stage II | Yes |
| 24 | Stage II | Yes |
| 25 | Stage III | Yes |
| 49 | Stage III | Yes |
| 50 | Stage IV | Yes |
| 60 | Stage IV | Yes |

No gaps or overlaps. Implementation must use inclusive comparisons on both bounds.

---

### Formula 3 — XP Threshold per Level and Stage Milestones

**Per-level XP threshold:**

```
xpThreshold(level) =
     50  if  1 ≤ level ≤  9   (Stage I — Hatchling)
     80  if 10 ≤ level ≤ 24   (Stage II)
    120  if 25 ≤ level ≤ 49   (Stage III)
    200  if 50 ≤ level ≤ 59   (Stage IV)
```

`xpThreshold(level)` is the XP needed while at `level` to advance to `level + 1`.

**Cumulative XP to reach a target level from level 1:**

```
totalXP(targetLevel) =
    (min(targetLevel−1, 9)) × 50
  + (max(0, min(targetLevel−1, 24) − 9)) × 80
  + (max(0, min(targetLevel−1, 49) − 24)) × 120
  + (max(0, (targetLevel−1) − 49)) × 200
```

| Symbol | Range | Description |
|--------|-------|-------------|
| `targetLevel` | 2–60 | The level being reached |

| Milestone | targetLevel | Segment XP | Cumulative XP | Approx. battles (base_xp=25) |
|-----------|-------------|-----------|---------------|------------------------------|
| Enter Stage II | 10 | 450 XP (9 × 50) | 450 XP | ~18 |
| Enter Stage III | 25 | 1,200 XP (15 × 80) | 1,650 XP | ~66 |
| Enter Stage IV | 50 | 3,000 XP (25 × 120) | 4,650 XP | ~186 |
| MAX_LEVEL | 60 | 2,000 XP (10 × 200) | 6,650 XP | ~266 |

> **Design note:** Stage III is the longest segment (3,000 XP, ~120 battles). Stage IV requires meaningful commitment (2,000 XP, ~80 battles) — the climax earns its moment. Stage I passes quickly (~18 battles) so the Hatchling-to-Stage-II reveal comes early in the player relationship.

---

### Formula 4 — XP Level-Up Loop

Canonical copy in `dragon_progression.gd` (this GDD is authoritative; `hatchery.md` references this):

```
# Pre-conditions
assert(xpGained >= 0)                     # negative: reject upstream
xpGained = min(xpGained, XP_MAX_AWARD)   # overflow guard (XP_MAX_AWARD = 10000)

# Level-up loop
var levels_gained: int = 0
dragon.xp += xpGained
var threshold: int = xp_threshold_for(dragon.level)
var effective_threshold: int = max(1, int(threshold / RESONANCE_XP_MULT)) if dragon.battle_charges > 0 else threshold
while dragon.xp >= effective_threshold and dragon.level < MAX_LEVEL:
    dragon.xp              -= effective_threshold
    var prev_stage: int     = stage(dragon.level)
    dragon.level           += 1
    levels_gained          += 1
    if dragon.battle_charges > 0:
        dragon.battle_charges -= 1
    var new_stage: int      = stage(dragon.level)
    if new_stage > prev_stage:
        pending_events.append(StageAdvancedPayload.new(dragon.dragon_id, dragon.element, prev_stage, new_stage))
    if dragon.level == 50:
        pending_events.append(StageIVReachedPayload.new(dragon.dragon_id, dragon.element))
    threshold           = xp_threshold_for(dragon.level)
    effective_threshold = max(1, int(threshold / RESONANCE_XP_MULT)) if dragon.battle_charges > 0 else threshold

# Post-loop cleanup
if dragon.level == MAX_LEVEL:
    dragon.xp = 0
    dragon.battle_charges = 0

if levels_gained > 0:
    pending_events.append(StatsUpdatedPayload.new(dragon.dragon_id, dragon.element))
```

Where `xp_threshold_for(level)` returns `xpThreshold(level)` from Formula 3. For `level == MAX_LEVEL`, `xp_threshold_for` returns `INT_MAX` (or equivalent sentinel) so the loop guard `dragon.xp >= effective_threshold` is always false at cap.

- Handles multi-level gains from a single XP award.
- The `dragon.level < MAX_LEVEL` guard prevents overshoot past level 60.
- The post-loop block clears remainder XP and battle charges at MAX_LEVEL.
- `xpGained` must be a non-negative integer; negative values must be rejected upstream.
- `xpGained` is clamped to `XP_MAX_AWARD` (10,000) before the loop to prevent integer overflow.
- Resonance bonus reduces `effective_threshold` per level — each resonance level costs `max(1, floor(threshold / RESONANCE_XP_MULT))` XP instead of the full threshold. Exactly 1 battle charge is consumed per level gained; no charge is consumed on XP awards that produce no level-up.
- `stage_advanced` is recorded inside the staged loop immediately after `dragon.level` increments, whenever the new level crosses a stage boundary. `stage_iv_reached` is recorded additionally when `dragon.level` reaches 50 — both events publish after commit success, with `stage_advanced` first.
- `stats_updated` is recorded at most once per call, only if at least one level was gained, and publishes after commit success.
- Loop terminates in at most 59 iterations.

---

### Formula 5 — Worked Combat Example Across Stages

Scenario: Shadow (base ATK 32) attacks Ice (base DEF 17). Same level, same stage, non-shiny. Damage formula from `battle-engine.md`:

```
baseDamage = (ATK × stageMult × 1.5) − (DEF × 0.5),  minimum 1
```

| Stage | Level | Shadow ATK | Ice DEF | stageMult | baseDamage |
|-------|-------|-----------|---------|-----------|-----------|
| I | 5 | 44 | 29 | 0.5 | floor(33.0 − 14.5) = **18** |
| II | 17 | 80 | 65 | 0.75 | floor(90.0 − 32.5) = **57** |
| III | 37 | 140 | 125 | 1.0 | floor(210.0 − 62.5) = **147** |
| IV | 55 | 194 | 179 | 1.4 | floor(407.4 − 89.5) = **317** |

> **Design note (Stage IV OHKO policy):** Ice HP at level 55 = 262. Shadow deals 317 — a confirmed one-shot. This is intentional design policy: Stage IV is decisive territory against element-disadvantaged opponents. A Shadow dragon running at full allocation is supposed to be terrifying to Ice — the emotional design is "the Mirror Admin has reason to be afraid." Same-element matchups (e.g., Shadow vs. Shadow) and high-DEF elements (Stone) remain competitive at Stage IV. Players who field element-disadvantaged dragons in Stage IV are making a deliberate risk. DEF reduction (`DEF × 0.5`) does not scale with stageMult — high-stageMult stages systematically favour attackers, and this asymmetry is load-bearing for the Stage IV reveal.
>
> **This policy applies in both directions.** An NPC Shadow dragon at Stage IV will OHKO an element-disadvantaged player dragon by the same math. Stage IV matchups are consequential in both directions — the system does not soften outcomes for player protection. A player who fields a Stage II Ice dragon against a Stage IV Mirror Admin Shadow accepts the same risk the Mirror Admin accepts against a player's Shadow. Stage indicators and element badges surface this information before the fight; the consequence is the warning.

**No degenerate outputs.** Minimum baseDamage in all tested scenarios: 18 (well above the floor of 1). No formula produces negative, zero, or non-integer outputs at valid inputs.

## Edge Cases

### 1. XP Award Edge Cases

**Situation:** `xpGained` is 0.
**Behaviour:** `dragon.xp += 0` is a no-op. Level and XP are unchanged. No level-up fires. Silently accepted — not an error.

**Situation:** `xpGained` is negative.
**Behaviour:** Rejected before touching `dragon.xp`. Log error: `"XP award rejected: xpGained must be >= 0, got [value]"`. Level and XP unchanged. Calling system investigates.

**Situation:** `xpGained` spans multiple levels in a single award (e.g., 150 XP at level 1 with 0 XP remaining).
**Behaviour:** The XP loop runs to completion. All level-up events — stat recalculations, stage transitions, signals — fire in ascending level order before control returns to the caller. At most 59 loop iterations.

**Situation:** `xpGained` is awarded to a dragon already at MAX_LEVEL (60).
**Behaviour:** The loop guard `dragon.level < MAX_LEVEL` is immediately false. Post-loop `if` sets `dragon.xp = 0`. Final state: level 60, xp 0. Surplus discarded silently. The Hatchery and Battle Engine may check `dragon.level == MAX_LEVEL` before calling to avoid the empty call — the progression system does not refuse it.

**Situation:** `xpGained` is a non-integer float.
**Behaviour:** Truncated to int via `int(xpGained)` before applying. No error raised. This is a defensive measure — callers should pass integers.

---

### 2. Level-Up Sequence Edge Cases

**Situation:** A single XP award produces exactly 0 XP remainder at the new level.
**Behaviour:** Valid state. `dragon.xp = 0` at a non-MAX level is indistinguishable from a fresh level. No special handling required.

**Situation:** `xpGained` brings the dragon to exactly MAX_LEVEL with 0 remainder.
**Behaviour:** Loop runs once. Post-loop `if dragon.level == MAX_LEVEL` sets `dragon.xp = 0` (idempotent). Stats recalculate to level 60. Stage IV signal fires if the dragon was below level 50 before the award.

**Situation:** `xpGained` exceeds what is needed to reach MAX_LEVEL.
**Behaviour:** Loop exits when `dragon.level == MAX_LEVEL`. Post-loop `if` sets `dragon.xp = 0`. Surplus XP is permanently discarded — by design.

**Situation:** A multi-level gain requires stat recalculation multiple times in one frame.
**Behaviour:** Stat recalculation runs once per loop iteration, immediately after each `dragon.level` increment. The formula is deterministic and cheap — repeated calls are correct. The Battle Engine reads stats after the loop completes, not during. One `stats_updated` signal fires after the entire loop, not per level.

---

### 3. Stage Transition Edge Cases

**Situation:** A dragon crosses Stage I → II or II → III as part of a level-up.
**Behaviour:** `stageMult` updates, the stage sprite update is queued, and `stage_advanced(element, from_stage, to_stage)` fires inside the loop with the correct from/to stage values.

**Situation:** A single XP award crosses two stage boundaries in one call (e.g., from Stage I to Stage III).
**Behaviour:** The loop evaluates stage at each iteration. Each boundary triggers its sprite update in level order. Both transitions complete before any UI animation plays — animations queue and play sequentially after the loop.

**Situation:** `stage_iv_reached(element)` is published after commit but the Journal listener is not yet connected.
**Behaviour:** Godot 4 emits the signal unconditionally — no connected receivers is a no-op, not an error. The Journal system is responsible for connecting before any dragon can plausibly reach level 50. If loaded lazily, it must query committed dragon level/state on initialisation to surface any missed entries. Dragon Progression does not re-emit retroactively.

**Situation:** A single XP award crosses Stage III → IV and also overshoots to MAX_LEVEL.
**Behaviour:** `stage_advanced(element, 3, 4)` and `stage_iv_reached(element)` are both recorded exactly once when staged `dragon.level` hits 50. The loop continues to 60. Post-loop clears XP. Both events publish once after commit success, in the correct order.

**Situation:** A listener connected to `stage_advanced` or `stage_iv_reached` calls Dragon Progression APIs synchronously during the post-commit callback.
**Behaviour:** Direct nested mutation is not supported. Listeners that need to award XP or mutate dragon state in response to a stage crossing must schedule a new guarded command after the current commit/event dispatch completes.

---

### 4. Shiny Edge Cases

**Situation:** Shiny dragon evaluated at level 1 (minimum case for shinyMult).
**Behaviour:** `stat(1) = floor(baseStat × 1.2)`. For Shadow DEF (11): `floor(13.2) = 13`. A level 1 shiny dragon always exceeds a level 1 non-shiny dragon of the same element — no level or baseStat causes the floor to collapse to parity.

**Situation:** The shiny multiplier produces a fractional result.
**Behaviour:** `floor()` truncates once, after multiplying the fully level-scaled stat by `shinyMult`. Maximum fractional loss: 0.999 per stat — never a full point.

**Situation:** Any in-game path attempts to modify `dragon.shiny` after hatch.
**Behaviour:** `dragon.shiny` is read-only after hatch. No setter is exposed by the progression system. If a future mechanic requires toggling shiny status, this GDD must be revised before implementation.

---

### 5. Save / Load Edge Cases

**Situation:** `dragon.level` outside valid range (0, negative, or > 60) on load.
**Behaviour:** Record discarded. Log: `"Save integrity violation: dragon.level out of range [value] for element [element]. Dragon record discarded."` Other dragons unaffected. No clamping or recovery — the data is gone.

**Situation:** `dragon.xp > 0` when `dragon.level == 60` on load.
**Behaviour:** Record repaired silently. `dragon.xp` set to 0. Log warning: `"Save correction: dragon.xp [value] cleared for MAX_LEVEL dragon [element]."` Dragon loaded normally. Level is trusted; only XP is corrected.

**Situation:** `dragon.xp < 0` on load.
**Behaviour:** Record discarded (same as out-of-range level). Log: `"Save integrity violation: dragon.xp negative [value] for element [element]. Dragon record discarded."` Negative XP cannot be safely corrected to 0 without risk of hiding deeper corruption.

**Situation:** `dragon.xp >= xp_threshold_for(dragon.level)` while `dragon.level < 60` on load. (Uses the same function as Formula 4; returns INT_MAX for level 60, ensuring this guard is always false at cap.)
**Behaviour:** Inconsistency detected. `dragon.battle_charges` is reset to 0. Log warning and run the canonical XP loop on the loaded values before completing the load: `"Save correction: dragon.xp [value] at level [level] — running XP loop to resolve."` Dragon loaded in the corrected state.

> **General save-repair rule:** Whenever XP inconsistency is detected on load (any repair case in §5), `dragon.battle_charges` is reset to 0 before the repair loop. Resonance charges cannot be trusted alongside corrupted XP state; resetting ensures the repair loop uses standard (non-discounted) thresholds, preventing a corrupted save from inadvertently inflating the resonance bonus.

**Situation:** Cloud and local saves present conflicting `dragon.level` and `dragon.xp` values for the same element.
**Behaviour:** Take the higher `dragon.level` as authoritative. If levels are equal, take the higher `dragon.xp`. Never average or merge. If the higher-level source is flagged as potentially corrupted, surface an explicit conflict resolution prompt showing both records' levels and XP before committing. Dragon Progression specifies the rule; Save / Persistence enforces it.

**Situation:** `dragon.element` on load is not in the valid set.
**Behaviour:** Record discarded unless the value is the supported story element `Void`. Log: `"Save integrity violation: unknown element '[value]'. Dragon record discarded."` Element is identity — an unknown element cannot be safely mapped to a known one.

---

### 6. Data Integrity Edge Cases

**Situation:** Stat formula called with `level <= 0` or `level > 60`.
**Behaviour:** Log error and return the element's level-1 baseStat (level ≤ 0) or clamp to level 60 (level > 60) before computing. Does not crash. These are defensive fallbacks — callers must not pass out-of-range values.

**Situation:** Stat formula called with an element string not in the base stat table.
**Behaviour:** Log error: `"Stat formula: unknown element '[value]' — no base stat found"`. Return 0 for all four stats. Does not crash. The resulting dragon (0 HP, 0 ATK, 0 DEF) fails visibly in combat, making the corruption immediately detectable. Does not substitute a default element's stats — substitution masks the corruption.

**Situation:** Stat formula called with `shinyMult` outside `{1.0, 1.2}`.
**Behaviour:** Log error and substitute `1.0` before computing. Does not crash. Dragon functions in combat while the error is visible in logs.

**Situation:** `stage_iv_reached(element)` emitted with an invalid element string.
**Behaviour:** Journal system validates the parameter. If unknown, logs: `"stage_iv_reached: unknown element '[value]' — no Captain's Log entry to surface"` and takes no action. Does not crash. The corrupt upstream record is the issue; Journal does not repair it.

**Situation:** Fusion Engine requests base stats using `stat(level > 1)` instead of reading the level-1 table directly.
**Behaviour:** The stat formula returns a valid result for any valid level — but the Fusion Engine's output will be wrong. This is a Fusion Engine integration error. The correct contract is documented in the Interactions table: Fusion reads level-1 base stats from the Detailed Design table, not via the stat formula.

## Dependencies

| System | Relationship | Interface |
|--------|-------------|-----------|
| Battle Engine | Downstream consumer + XP formula owner | Reads `dragon.level`, `dragon.element`, `dragon.shiny` to compute stats via Formula 1; reads `stageMult` via Formula 2. **Provides raw XP per battle victory via its canonical scaling formula** (`max(1, floor(base_xp × enemyLevel / playerLevel))`); Dragon Progression does not define this formula. Campaign Map or Singularity settlement calls Dragon Progression helpers to apply final XP and add active Resonance charges. Battle UI consumes post-commit `stats_updated` events to sync post-level-up stats before next battle. |
| Hatchery | Downstream consumer + XP source | Reads `dragon.level` and `MAX_LEVEL` constant to discard XP at cap. Provides 50 / 100 / 150 XP on duplicate pull. |
| Fusion Engine | Downstream consumer + dragon record writer | Reads level-1 base stats from the Detailed Design table (pre-scaling, pre-shiny) as inheritance inputs for core elements only. Writes inherited `base_hp`, `base_atk`, `base_def`, `base_spd`, and `is_elder` on fused dragon records. Fusion must not produce Void. |
| Singularity | Upstream story grant | Grants `dragon_id = "void_dragon"` with `element = Void`, `level = 30`, base stats from this table, `dragon.shiny = false`, and reserved story-roster capacity. |
| Save / Persistence | Bidirectional | Serialises and deserialises `dragon.base_hp`, `dragon.base_atk`, `dragon.base_def`, `dragon.base_spd`, `dragon.level`, `dragon.xp`, `dragon.shiny`, `dragon.element`, **`dragon.battle_charges`**, `dragon.is_elder`, and story-roster slot metadata for Void. Load path applies save-integrity rules (see Edge Cases §5). `dragon.battle_charges` and `dragon.is_elder` are optional in older save formats — default to 0/false if absent. |
| Journal / Console | Signal recipient | Receives `stage_iv_reached(element)` signal at Stage III → IV crossing. Surfaces the appropriate Captain's Log entry. Must connect its listener before any dragon can plausibly reach level 50. |
| Campaign Map | Downstream consumer | Zone gates require dragons at Stage II or Stage III minimum. Reads `dragon.level` to evaluate gate conditions. This GDD does not define the gate values — Campaign Map GDD owns those thresholds. |

**Constants exported by this GDD** (referenced by other systems):

| Constant | Value | Referenced by |
|----------|-------|--------------|
| `MAX_LEVEL` | 60 | Hatchery (XP accumulation cap), Battle Engine (stage calculation bound) |
| `XP_STAGE_I / II / III / IV` | 50 / 80 / 120 / 200 | Hatchery (XP loop), replaces the former flat XP_PER_LEVEL=100 |

## Tuning Knobs

| Knob | Current Value | Safe Range | What It Affects |
|------|--------------|------------|-----------------|
| `MAX_LEVEL` | 60 | 30–99 | Total progression depth; total XP required to cap; Stage IV level count. |
| `XP_STAGE_I` | 50 per level | 30–100 | Stage I pacing. Lower = faster hatch-to-Stage-II reveal (~18 battles at 50). Raising beyond 100 delays the first reveal into frustration territory. |
| `XP_STAGE_II` | 80 per level | 50–150 | Stage II pacing. |
| `XP_STAGE_III` | 120 per level | 80–200 | Stage III pacing. This is the game's longest segment (~120 battles at 120 XP). Raising beyond ~180 risks dropout before Stage IV. Consider mid-segment rewards if raising. |
| `XP_STAGE_IV` | 200 per level | 100–400 | Stage IV pacing. Current value produces ~80 battles — the climax feels earned without becoming a wall. Values below 100 trivialise the final stage. |
| `STAT_INCREMENT` | 3 per level | 1–5 | Stat power growth rate per level. Affects the ATK/DEF gap between stages. Raising steepens the power curve; lowering flattens combat power across levels. |
| `SHINY_MULT` | 1.2× | 1.05–1.5 | Shiny stat advantage. Values above ~1.4 risk making shiny vs. non-shiny matchups effectively non-competitive at high stage. |
| `STAGE_I_MULT` | 0.5× | 0.3–0.7 | Stage I combat power. This is the Hatchling multiplier — art direction frames the weakness as youth, not damage. Raising reduces the Stage I → II reveal impact; lowering makes the Hatchling feel defeated rather than precious. |
| `STAGE_II_MULT` | 0.75× | 0.6–0.9 | Stage II combat power. |
| `STAGE_III_MULT` | 1.0× | 0.85–1.1 | Stage III combat power. Treat as the baseline multiplier — other stages are defined relative to it. |
| `STAGE_IV_MULT` | 1.4× | 1.2–1.8 | Stage IV combat power. At 1.4×, element-disadvantaged matchups result in OHKOs — this is deliberate design policy (see Formula 5 note). Same-element matchups remain competitive at 1.4×. Values above ~1.6 risk OHKOs even in same-element matchups. |
| `BATTLE_MAX_CHARGES` | 10 | 3–20 | Maximum resonance charges a dragon can accumulate from active combat. 10 = up to 10 levels at the resonance discount. Higher values widen the momentum window; values below 3 make the bonus negligible. Note: at RESONANCE_XP_MULT=1.5×, Stage III effective threshold (80) equals the full Stage II threshold — an incidental coincidence, not a design constraint. |
| `RESONANCE_XP_MULT` | 1.5× | 1.1–2.5 | Effective threshold divisor per level when a dragon has resonance charges. At 1.5×: Stage I costs 33 XP/level instead of 50; Stage III costs 80 XP/level instead of 120. Values above 2.0 risk making heavily-used dragons level too fast to meaningfully reveal their stage. |
| `XP_MAX_AWARD` | 10,000 | 1,000–50,000 | Maximum single XP award (overflow guard). No gameplay scenario awards near this value. |
| `XP_DUPE_COMMON` | 50 | 25–100 | XP from a Common duplicate Hatchery pull. Equivalent to ~2 standard battles at base_xp=25. |
| `XP_DUPE_UNCOMMON` | 100 | 50–200 | XP from an Uncommon duplicate Hatchery pull. |
| `XP_DUPE_RARE` | 150 | 75–300 | XP from a Rare (Shadow) duplicate Hatchery pull. |

> **Battle XP tuning** (`base_xp` and the level-scaling formula) is owned by `battle-engine.md`. Dragon Progression consumes it — do not define battle XP here.

**Constraint:** `XP_DUPE_COMMON < XP_DUPE_UNCOMMON < XP_DUPE_RARE` must hold. The relative ordering signals rarity value to the player.

**Constraint:** `STAGE_I_MULT < STAGE_II_MULT < STAGE_III_MULT < STAGE_IV_MULT` must hold. Any tuning that collapses or inverts adjacent multipliers breaks the stage-reveal emotional arc.

**Constraint:** `XP_STAGE_I ≤ XP_STAGE_II ≤ XP_STAGE_III ≤ XP_STAGE_IV` is recommended. Reversing the ordering is not strictly broken but creates confusing pacing (later stages easier) and is not design-intentional.

## Visual/Audio Requirements

### Visual

| Event | Requirement |
|-------|-------------|
| Stage I → II crossing | Sprite updates to Stage II variant. Update applies in all UI contexts simultaneously: party view, battle screen, Hatchery Ring detail. |
| Stage II → III crossing | Sprite updates to Stage III variant. Same UI contexts. The transition should feel like recognition — the dragon settling into a peer, not a celebration. |
| Stage III → IV crossing | Sprite updates to Stage IV variant. This is the primary moment of visual impact — the sprite change must be unmistakable. Accompanied by a Captain's Log Journal entry surfacing. |
| XP bar fill | The XP bar should convey momentum, not scarcity. It should never feel like it is emptying — always filling. Visual direction: a progress fill that accelerates slightly at the end of each level before resetting, not a countdown. |
| Level-up tick | Each individual level-up within a multi-level XP award should produce a brief visual tick (flash or increment). The stage-crossing animation is separate and plays after all ticks complete. |
| Shiny indicator | Shiny dragons require a persistent visual marker at all stages — a consistent visual cue that is present in party view, battle, and Hatchery detail. |

### Audio

| Event | Requirement |
|-------|-------------|
| Level-up (non-stage-crossing) | Short, satisfying tick or chime. Should feel incremental, not climactic. |
| Stage I → II crossing | Distinct audio cue — different from a level-up tick, but not a fanfare. Quiet acknowledgement. |
| Stage II → III crossing | Slightly more prominent than Stage II crossing. The player should sense something shifted. |
| Stage III → IV crossing | The primary audio moment of Dragon Progression. Should feel like recognition — the dragon completing a long sequence, not a reward being given. Coordinate with audio-director for the specific cue. |
| XP award (Hatchery duplicate) | Brief audio acknowledgement tied to the duplicate pull reveal, not to the subsequent level-up. The Hatchery system owns this cue; Dragon Progression does not play additional audio for the XP portion. |

> **Direction:** Stage transitions should feel like reveals, not celebrations. The audio and visual design for each crossing should reinforce the "throttle lifting" framing from the Player Fantasy — the dragon acknowledging what just happened, not the player receiving a prize.

## UI Requirements

| Element | Requirement |
|---------|-------------|
| XP bar | Displayed on the dragon's detail view. Fill level is normalized: `min(1.0, float(dragon.xp) / float(xp_threshold_for(dragon.level) − 1))` — empty at xp=0, saturated at 1.0 when xp=threshold−1. Must not display raw XP numbers — show as a fill bar only. Never shows a total XP counter. **At MAX_LEVEL (level 60):** the XP bar is hidden entirely and replaced by a "MAX" badge in the same display position. The fill formula is not evaluated at level 60; no empty or full bar is shown. |
| Level display | Current level shown as a numeral (e.g., "Lv. 37"). Displayed in: party view card, battle screen dragon panel, Hatchery Ring detail. |
| Stage display | Current stage shown as a Roman numeral chip or badge (e.g., "III"). Displayed adjacent to the level wherever level is shown. Stage badge updates immediately on crossing — no delay. |
| Shiny indicator | Persistent visual marker on all dragon displays. Must be visible at a glance — not a tooltip or hover-only state. Works with gamepad navigation (no hover state assumed). |
| Stage IV indicator | Stage IV should have a distinct visual treatment from Stages I–III — not just the badge label, but a visual quality that conveys the dragon is at full allocation. Specific treatment: coordinate with art-director. |
| SPD stat | **Not displayed.** SPD is tracked internally. No UI element should expose this value to the player under any circumstance in the current design. If a future mechanic requires displaying SPD, this GDD must be revised before that UI is built. |
| Level-up animation | Plays after XP is applied and before control returns to player. During multi-level gains, individual level ticks animate at speed; the stage-crossing animation plays after all ticks complete. Animation must not block player input for more than 2 seconds total. |
| Stage transition screen | Stage III → IV crossing surfaces a full Captain's Log entry (owned by Journal / Console GDD). The stage sprite update is part of this beat. The exact presentation is specified in the Journal GDD — Dragon Progression only owns the trigger. |

## Acceptance Criteria

### 1. Stat Scaling

**AC-DP01:** [Unit] Given a non-shiny Fire dragon at level 1, `stat(1)` returns HP=110, ATK=28, DEF=16, SPD=22. Any deviation is a failure.

**AC-DP02:** [Unit] Given a non-shiny Ice dragon at level 1, `stat(1)` returns HP=100, ATK=24, DEF=17, SPD=14. Any deviation is a failure.

**AC-DP03:** [Unit] Given a non-shiny Storm dragon at level 1, `stat(1)` returns HP=90, ATK=30, DEF=13, SPD=32. Any deviation is a failure.

**AC-DP04:** [Unit] Given a non-shiny Stone dragon at level 1, `stat(1)` returns HP=120, ATK=22, DEF=24, SPD=8. Any deviation is a failure.

**AC-DP05:** [Unit] Given a non-shiny Venom dragon at level 1, `stat(1)` returns HP=95, ATK=26, DEF=19, SPD=12. Any deviation is a failure.

**AC-DP06:** [Unit] Given a non-shiny Shadow dragon at level 1, `stat(1)` returns HP=85, ATK=32, DEF=11, SPD=28. Any deviation is a failure.

**AC-DP06a:** [Unit] Given the Singularity-granted Void dragon at level 1, `stat(1)` returns HP=80, ATK=40, DEF=20, SPD=36. Void cannot be shiny; any `dragon.shiny = true` Void record is rejected or corrected to false by the grant/load path.

**AC-DP07:** [Unit] Given a non-shiny Shadow dragon at level 30, `stat(30)` returns ATK = floor((32 + 29 × 3) × 1.0) = 119. Any deviation is a failure.

**AC-DP08:** [Unit] Given a non-shiny Fire dragon at level 30, `stat(30)` returns HP = floor((110 + 29 × 3) × 1.0) = 197. Any deviation is a failure.

**AC-DP09:** [Unit] Given a non-shiny Stone dragon at MAX_LEVEL (60), `stat(60)` returns ATK = floor((22 + 59 × 3) × 1.0) = 199. Any deviation is a failure.

**AC-DP10:** [Unit] Given a non-shiny Shadow dragon at MAX_LEVEL (60), `stat(60)` returns ATK=209, HP=262, DEF=188. All three values must match exactly.

**AC-DP11:** [Unit] Given a non-shiny Stone dragon at MAX_LEVEL (60), `stat(60)` returns HP = floor((120 + 59 × 3) × 1.0) = 297. Any deviation is a failure.

**AC-DP12:** [Unit] Given a shiny Shadow dragon at level 1, `stat(1)` returns ATK = floor(32 × 1.2) = floor(38.4) = 38. Returning 32 (non-shiny) is a failure.

**AC-DP13:** [Unit] Given a shiny Stone dragon at level 1, `stat(1)` returns ATK = floor(22 × 1.2) = floor(26.4) = 26. Returning 27 (ceiling) or 22 (non-shiny) is a failure.

**AC-DP14:** [Unit] Given a shiny Shadow dragon at MAX_LEVEL (60), `stat(60)` returns ATK = floor(209 × 1.2) = floor(250.8) = 250. Returning 251 (ceiling) or 209 (missing shiny) is a failure.

**AC-DP15:** [Unit] Given a shiny Stone dragon at MAX_LEVEL (60), `stat(60)` returns HP = floor(297 × 1.2) = floor(356.4) = 356. Any deviation is a failure.

**AC-DP16:** [Unit] Given a shiny Shadow dragon at MAX_LEVEL (60), `stat(60)` returns DEF = floor(188 × 1.2) = floor(225.6) = 225. Any deviation is a failure.

**AC-DP17:** [Unit] For every core element, a shiny dragon's stat at any level is strictly greater than the same element's non-shiny stat at the same level. Must hold for all four stats across all six core elements at levels 1, 30, and 60 (54 checks minimum). Void is excluded because it is never shiny. Any tie is a failure.

**AC-DP18:** [Unit] The stat formula is monotonically non-decreasing: `stat(N+1) >= stat(N)` for every element, every stat, both shiny and non-shiny, across all valid levels 1–59. No stat value decreases from one level to the next.

**AC-DP19:** [Unit] `floor()` is applied once, after the full expression `(baseStat + (level − 1) × 3) × shinyMult` is evaluated. Verified by: shiny Stone ATK at level 1 must return 26 (`floor(22 × 1.2) = floor(26.4) = 26`), not 26.4 (`floor(22) × 1.2`) — the latter is wrong order of operations.

---

### 2. Level Advancement

**AC-DP20:** [Unit] A dragon at level 1, XP 0 that receives 50 XP (Stage I threshold) advances to level 2, XP 0.

**AC-DP21:** [Unit] A dragon at level 1, XP 0 that receives 49 XP stays at level 1, XP 49. No level-up fires.

**AC-DP22:** [Unit] A dragon at level 1, XP 30 that receives 25 XP advances to level 2, XP 5. (30 + 25 = 55; 55 − 50 = 5.)

**AC-DP23:** [Unit] A dragon at level 1, XP 0 that receives 100 XP reaches level 3, XP 0. (100 = 50 + 50 — both Stage I level-ups.) Both increments occur within the same call.

**AC-DP24:** [Unit] A dragon at level 1, XP 0 that receives 130 XP reaches level 3, XP 30. (50 + 50 = 100 for two levels; remainder = 30.)

**AC-DP25:** [Unit] A dragon at level 10 (Stage II), XP 0 that receives 80 XP advances to level 11, XP 0. (Stage II threshold = 80.)

**AC-DP26:** [Unit] A dragon at level 9, XP 40 that receives 50 XP advances from Stage I to Stage II: reaches level 10, XP 40. (40 + 50 = 90; 90 − 50 = 40 remainder at level 10, which uses Stage II threshold = 80. 40 < 80 — no further advance.)

**AC-DP27:** [Unit] A dragon at level 59 (Stage IV), XP 199 that receives 1 XP reaches level 60, XP 0. (199 + 1 = 200 = Stage IV threshold. Post-loop XP clear fires.)

**AC-DP28:** [Unit] A dragon at MAX_LEVEL (60), XP 0 that receives any XP amount remains at level 60, XP 0. XP is discarded silently.

**AC-DP29:** [Unit] A dragon at level 59, XP 0 that receives 10,000 XP reaches level 60, XP 0. Level must not exceed 60, XP must be 0.

**AC-DP30:** [Unit] After a level-up from level 1 to level 2, a non-shiny Fire dragon's stats are HP=113, ATK=31, DEF=19, SPD=25. All four stats must reflect the new level immediately after level-up.

**AC-DP31:** [Unit] During a multi-level gain (e.g., 100 XP from level 1, yielding 2 levels), `stats_updated` fires exactly once after the entire XP loop completes. Not once per level. Verified by connecting a counter to the signal and confirming count == 1 after the call.

**AC-DP98:** [Unit] `dragon.xp` is always in the range 0–(stage_threshold − 1) at any stable post-load state: 0–49 in Stage I, 0–79 in Stage II, 0–119 in Stage III, 0–199 in Stage IV. (This invariant excludes the in-flight save-repair window — AC-DP63 and AC-DP63a deliberately load out-of-range XP values and verify they are repaired before the dragon is accessible.) A value equal to or greater than the current threshold in a fully loaded, non-repair-path dragon is a failure.

**AC-DP99:** [Unit] `dragon.xp` is always exactly 0 when `dragon.level == 60`. Any non-zero XP at MAX_LEVEL is a failure.

---

### 3. Stage Determination

**AC-DP32:** [Unit] Level 9 returns Stage I. Level 10 returns Stage II. Both checks must pass.

**AC-DP33:** [Unit] Level 24 returns Stage II. Level 25 returns Stage III. Both checks must pass.

**AC-DP34:** [Unit] Level 49 returns Stage III. Level 50 returns Stage IV. Both checks must pass.

**AC-DP35:** [Unit] Level 60 (MAX_LEVEL) returns Stage IV. No error or out-of-range value.

**AC-DP36:** [Unit] Level 1 returns Stage I. Minimum valid level handled correctly.

**AC-DP37:** [Unit] Standard non-Elder `stageMult` values are within ±0.001 of: Stage I = 0.5, Stage II = 0.75, Stage III = 1.0, Stage IV = 1.4. (Note: 1.4 is not exactly representable in IEEE 754 float; the tolerance accommodates this without allowing meaningful drift. A result of 1.3989... or 1.4011... at standard Stage IV is a failure. Elder Stage IV branch is owned by Fusion Engine + Battle Engine.)

**AC-DP38:** [Integration] Stage never decreases. Runtime verification: set a dragon to Stage II (level 12), call any public progression API with valid or invalid XP values, then confirm `stage(dragon.level)` still returns Stage II or higher after each call. A return of Stage I is a failure. This test must be executed against the running system, not inferred from code inspection.

---

### 4. Stage Signals

**AC-DP39:** [Integration] A dragon advancing from any level below 50 to exactly level 50 in a single XP award emits `stage_iv_reached(element)` exactly once. 0 or 2+ emissions is a failure.

**AC-DP40:** [Integration] The staged XP application records `stage_iv_reached` at the exact level-50 crossing and publishes it only after SaveTransaction commit success. Verified by: apply an XP award that crosses level 50 and reaches at least level 51 before loop completion; inspect the committed event payload and assert its crossing level is exactly 50, then inject a save failure and assert no `stage_iv_reached` signal publishes. A pre-commit signal, missing event, or payload recorded at level 51+ is a failure.

**AC-DP41:** [Integration] A single XP award crossing multiple stage boundaries (e.g., Stage I → Stage IV) emits `stage_iv_reached(element)` exactly once.

**AC-DP42:** [Integration] A single XP award that crosses Stage IV and also reaches MAX_LEVEL simultaneously emits `stage_iv_reached(element)` exactly once — not a second time from the post-loop XP clear.

**AC-DP43:** [Integration] `stage_advanced(element, from_stage, to_stage)` IS emitted on Stage I → II (level 10) and Stage II → III (level 25) crossings with correct parameter values. `stage_iv_reached(element)` is NOT emitted on Stage I → II or Stage II → III crossings — only `stage_advanced` fires for those.

**AC-DP43a:** [Integration] A dragon advancing from level 9 to level 10 emits `stage_advanced(element, 1, 2)` exactly once. Parameters must match: element = `dragon.element`, from_stage = 1, to_stage = 2. Incorrect parameter values are a failure.

**AC-DP43b:** [Integration] A dragon advancing from level 24 to level 25 emits `stage_advanced(element, 2, 3)` exactly once. Parameters: from_stage = 2, to_stage = 3.

**AC-DP43c:** [Integration] A dragon advancing from level 49 to level 50 emits both `stage_advanced(element, 3, 4)` and `stage_iv_reached(element)`. `stage_advanced` fires first. Both emit exactly once. Verified by connecting listeners to both signals and confirming emission order and count.

**AC-DP43d:** [Integration] A single XP award crossing two stage boundaries (e.g., Stage I → Stage III in one call) emits `stage_advanced` twice: `stage_advanced(element, 1, 2)` then `stage_advanced(element, 2, 3)`, in ascending stage order. Each fires exactly once.

**AC-DP44:** [Integration] `stage_iv_reached(element)` is emitted with the dragon's `dragon.element` string exactly as stored (case-sensitive, e.g., `"Fire"`). An incorrect case or wrong element is a failure.

**AC-DP45:** [Integration] Emitting `stage_iv_reached(element)` with no connected listener produces no error and Dragon Progression continues normally. (Godot 4 signal emission with no receivers is a no-op.)

---

### 5. XP Sources

**AC-DP46:** [Integration] Hatchery conversion of a Common duplicate awards exactly 50 XP to the owning dragon. 49 or 51 is a failure.

**AC-DP47:** [Integration] Hatchery conversion of an Uncommon duplicate awards exactly 100 XP. 99 or 101 is a failure.

**AC-DP48:** [Integration] Hatchery conversion of a Rare (Shadow) duplicate awards exactly 150 XP. 149 or 151 is a failure.

**AC-DP49:** [Unit] XP ordering holds: Common (50) < Uncommon (100) < Rare (150). Any tuning change that inverts or collapses this ordering fails this check.

**AC-DP50:** [Integration] Hatchery XP processes through the same canonical XP loop as battle XP. A dragon at level 1, XP 30 receiving a 50 XP Common duplicate award advances: 30 + 50 = 80; 80 − 50 = 30 remainder. Final: level 2, XP 30.

**AC-DP51:** [Integration] A battle victory at equal player/enemy levels with `base_xp = 25` awards exactly 25 XP to the active dragon (formula: `max(1, floor(25 × level / level)) = 25`). A battle at player level 20 vs enemy level 10 with `base_xp = 25` awards `max(1, floor(25 × 10 / 20)) = 12` XP. Both values must match exactly. Formula sourced from `battle-engine.md`.

**AC-DP52:** [Integration] A dragon receiving battle XP then Hatchery XP in sequence produces the same final level and XP as a single award of their sum (verifies shared XP loop, no source-specific divergence).

---

### 6. SPD Visibility

**AC-DP53:** [Unit] The stat formula computes a valid, non-zero positive integer SPD for all six elements at levels 1, 30, and 60. The internal value is correct.

**AC-DP54:** [UI] The dragon detail view displays no element labelled "SPD", "Speed", "Spd", or any variant. Tester must inspect all six element detail screens. Any SPD label is a failure.

**AC-DP55:** [UI] The party view dragon card displays no SPD value for any element. All six element cards must be checked.

**AC-DP56:** [UI] The battle screen dragon panel displays no SPD for player's or opponent's dragon. Must be verified for all six elements in combat.

**AC-DP57:** [UI] The Hatchery Ring detail screen displays no SPD for any element. All six elements must be checked.

**AC-DP58:** [UI] No tooltip, hover state, or secondary panel anywhere in the game reveals SPD. Verified by gamepad navigation only — SPD must not appear in any activated panel or context menu.

---

### 7. Save / Load Integrity

**AC-DP59:** [Integration] Loading a save with `dragon.level = 0` for any element discards that dragon record. Remaining dragons load normally. No crash. Log contains `"Save integrity violation: dragon.level out of range 0 for element [element]. Dragon record discarded."`

**AC-DP60:** [Integration] Loading a save with `dragon.level = 61` for any element discards that dragon record. No clamping to 60 — the record is discarded, not repaired.

**AC-DP61:** [Integration] Loading a save with `dragon.level = 60, dragon.xp = 45` repairs XP to 0 silently. Dragon loads at level 60, XP 0. Log contains: `"Save correction: dragon.xp 45 cleared for MAX_LEVEL dragon [element]."` Dragon is not discarded.

**AC-DP62:** [Integration] Loading a save with `dragon.xp = -1` discards that dragon record. No repair or clamping. Log contains: `"Save integrity violation: dragon.xp negative -1 for element [element]. Dragon record discarded."`

**AC-DP63:** [Integration] Loading a save with `dragon.level = 5, dragon.xp = 150, dragon.battle_charges = 0` runs the canonical XP loop on loaded values (`battle_charges = 0` ensures standard thresholds apply during repair — no resonance discount). Dragon loads at level 8, XP 0 (Stage I threshold 50: 150 ÷ 50 = 3 level-ups from level 5, no remainder). A warning is logged. The dragon is not discarded.

**AC-DP63a:** [Integration] Loading a save with `dragon.level = 5, dragon.xp = 150, dragon.battle_charges = 5` resets `battle_charges` to 0 before running the repair loop, then repairs using standard thresholds (not discounted). Dragon loads at level 8, XP 0, `battle_charges` 0. A result of `battle_charges > 0` after load is a failure. The general save-repair rule requires charges to be cleared before any XP-inconsistency repair loop.

**AC-DP64:** [Integration] Cloud `dragon.level = 10, dragon.xp = 40` vs. local `dragon.level = 12, dragon.xp = 20`: system selects local (higher level). Final state: level 12, XP 20. No averaging or merging.

**AC-DP65:** [Integration] Cloud `dragon.level = 10, dragon.xp = 80` vs. local `dragon.level = 10, dragon.xp = 30`: system selects cloud (same level, higher XP). Final state: level 10, XP 80.

**AC-DP66:** [Integration] Loading a save with `dragon.element = "Wind"` discards that dragon record. Log contains: `"Save integrity violation: unknown element 'Wind'. Dragon record discarded."` No element mapping attempted.

**AC-DP66a:** [Integration] Loading a valid Singularity-granted `dragon_id = "void_dragon"` with `dragon.element = "Void"` preserves the record, places it in the reserved story-roster slot even when normal roster capacity is full, and forces `dragon.shiny = false`.

---

### 8. Data Integrity

**AC-DP67:** [Unit] Stat formula called with `level = 0` logs an error and returns level-1 baseStats for that element. For Fire: HP=110, ATK=28, DEF=16, SPD=22. No crash.

**AC-DP68:** [Unit] Stat formula called with `level = -5` logs an error and returns level-1 baseStats. Behaviour identical to `level = 0`. No crash.

**AC-DP69:** [Unit] Stat formula called with `level = 61` logs an error, clamps to level 60, returns `stat(60)` for that element. For non-shiny Fire, HP=287. No crash.

**AC-DP70:** [Unit] Stat formula called with `element = "Wind"` logs `"Stat formula: unknown element 'Wind' — no base stat found"` and returns HP=0, ATK=0, DEF=0, SPD=0. Does not substitute another element's stats. No crash. `element = "Void"` is valid and must use the Void stat row.

**AC-DP71:** [Unit] Stat formula called with `shinyMult = 1.5` logs an error, substitutes `1.0`, and returns the non-shiny result. No crash.

**AC-DP72:** [Unit] XP loop called with `xpGained = -10` logs `"XP award rejected: xpGained must be >= 0, got -10"`. `dragon.xp` and `dragon.level` unchanged. No crash.

**AC-DP73:** [Unit] XP loop called with `xpGained = 75.9` (float) truncates to 75 before processing. Dragon receives exactly 75 XP. Not 76 (rounded), not a type error. No error logged.

**AC-DP74:** [Unit] XP loop called with `xpGained = 0` leaves `dragon.xp` and `dragon.level` unchanged. No level-up fires. No error logged. Valid no-op.

**AC-DP75:** [Integration] `stage_iv_reached("Wind")` received by Journal system logs `"stage_iv_reached: unknown element 'Wind' — no Captain's Log entry to surface"` and takes no action. No crash.

**AC-DP76:** [Integration] `dragon.shiny` cannot be modified after hatch. Runtime verification: hatch a non-shiny dragon, then attempt to set `dragon.shiny = true` via any method available through the running game's public API or debug console. Confirm that after the attempt, `dragon.shiny` remains `false`. A successfully applied write is a failure. Code inspection alone is insufficient — this must be verified in a running build.

---

### 9. Visual / UI

**AC-DP77:** [UI] XP bar fills using a normalized scale: empty at `dragon.xp = 0`, visually 100% full at `dragon.xp = xp_threshold_for(dragon.level) − 1`. The display implementation clamps the fill ratio to `1.0` when `dragon.xp == threshold − 1`, so the bar reaches full width exactly one XP before leveling. Verified at both empty (xp=0) and full (xp=threshold−1) boundary values for at least one element per stage.

**AC-DP78:** [UI] XP bar displays no raw numeric XP label (e.g., "47/100" or "47 XP"). Any numeric XP value visible on the detail view is a failure.

**AC-DP79:** [UI] XP bar displays no total cumulative XP counter. Only the within-level fill is shown.

**AC-DP79a:** [UI] When `dragon.level == 60` (MAX_LEVEL), the XP bar is hidden entirely and replaced by a "MAX" badge in the same display position. No fill bar is rendered — neither empty nor full. Verified for at least one dragon at level 60 in: dragon detail view, party view card, and Hatchery Ring detail. A visible fill bar at level 60 is a failure regardless of fill amount.

**AC-DP80:** [UI] Level display reads "Lv. [N]" in party view card, battle screen dragon panel, and Hatchery Ring detail. Verified for at least one dragon at a non-trivial level (e.g., level 37) in all three locations.

**AC-DP81:** [UI] Stage badge displays correct Roman numeral adjacent to level display in all contexts. A Stage III dragon shows "III" in party view, battle screen, and Hatchery detail simultaneously.

**AC-DP82:** [UI] Stage badge updates immediately on crossing — before any transition animation completes. Verified by triggering level 9 → 10 and confirming badge shows "II" before the animation finishes.

**AC-DP83:** [UI] Shiny indicator is persistently visible in party view, battle screen, and Hatchery detail via gamepad navigation only. Visible without any button activation. Any hover-required state is a failure.

**AC-DP84:** [UI] Stage IV dragons have a visually distinct treatment from Stages I–III beyond the badge label. Art-director sign-off required to pass. Evidence: signed screenshot per element in `production/qa/evidence/`.

**AC-DP85:** [UI] A single level-up at a non-stage-crossing level (e.g., level 5 → 6) produces a brief level number increment flash lasting 100–500ms on the level display, followed by the XP bar resetting to empty. The flash animation must be distinct from the stage-crossing particle/glow effect — tester must be able to identify which event occurred (level-up tick vs. stage crossing) from visual output alone, without checking the level number. Any animation that appears identical to a stage crossing is a failure.

**AC-DP86:** [UI] During a multi-level gain including at least one stage crossing: (a) level ticks play first, (b) stage animation plays after the final tick, (c) stage animation does not play mid-sequence.

**AC-DP87:** [UI] Total time from `stats_updated` signal emission to player input restored does not exceed 2 seconds for any multi-level gain including at least one stage crossing. Tester triggers the XP gain, starts timing when the XP bar begins animating (coincides with `stats_updated`), and stops timing when button presses are registered by the game. A result of 2.1 seconds or more is a failure. Measured with a stopwatch on the target device.

**AC-DP88:** [Integration] Stage III → IV crossing surfaces the correct Captain's Log entry for the dragon's element via the Journal system. A Fire dragon shows the Fire entry, not another element's. Requires Journal integration to verify.

**AC-DP89:** [UI] Stage IV sprite is unmistakably distinct from Stage III sprite for the same element. Art-director and tester sign-off required. Screenshot evidence per element in `production/qa/evidence/`.

---

---

### 10. Rest-XP and Overflow

**AC-DP90:** [Unit] `xpGained` values above `XP_MAX_AWARD` (10,000) are clamped to 10,000 before any XP is added to `dragon.xp`. A dragon receiving `xpGained = 999,999` produces the same result as `xpGained = 10,000`. No crash, no integer overflow.

**AC-DP91:** [Unit] Battle resonance charge mechanics — two scenarios at Stage I (level 5, XP 0, threshold 50):
- **1-level case** (battle_charges = 3, receives 40 XP): effective_threshold = max(1, int(50 / 1.5)) = 33. dragon.xp = 40. 40 ≥ 33 → level 6, XP = 40 − 33 = 7, battle_charges = 2. 7 < 33 — loop exits. Final: level 6, XP 7, battle_charges 2. One charge consumed.
- **0-level case** (battle_charges = 3, receives 20 XP): effective_threshold = 33. dragon.xp = 20. 20 < 33 — loop never fires. Final: level 5, XP 20, battle_charges 3. No charges consumed without a level gain.

**AC-DP92:** [Unit] A dragon with `battle_charges = 0` receiving XP earns no bonus. `xpGained` is applied at 1.0× (unmodified). Any bonus XP applied when charges are 0 is a failure.

**AC-DP92a:** [Integration] A battle event originating outside the player's current active party (simulated via test harness) does not increment `dragon.battle_charges` via Battle Engine. Only battles where the dragon is the active combatant contribute Active Resonance charges through Battle Engine. **Exception:** Campaign Map's bench award (see campaign-map.md Rule 9) is an explicitly contracted Passive Resonance path — +1 `dragon.battle_charges` per expedition battle for benched dragons is correct behavior, not a failure. Any Battle Engine charge increment for a non-active dragon (i.e., arriving through the Battle Engine code path rather than the Campaign Map code path) remains a failure. Unit test: trigger a battle event through the Battle Engine for a non-active dragon → assert no charge increment. Trigger a bench award through the Campaign Map award function → assert +1 charge increment.

**AC-DP93:** [Integration] Stage badge (Roman numeral chip) displays the correct stage after a save-load cycle. Procedure: advance a dragon to Stage II (level 12), save, reload, confirm the badge shows "II" in party view, battle screen, and Hatchery detail. A badge of "I" on reload is a failure.

**AC-DP94:** [Integration] When a player's Hatchery pulls a duplicate of an element they do not yet own (dragon not in party), the XP award is discarded and a log message is emitted: `"Hatchery XP discarded: element [X] not in party."` A null-reference crash is a failure. Silently discarding without logging is a failure. Storing the XP in any pending queue is a failure — the committed behavior is discard-with-log (decision made 2026-05-22).

**AC-DP95:** [Integration] Journal late-connect recovery: manually set a test dragon to level 50 via debug tools, then connect the Journal listener after the fact. Confirm the Journal queries `dragon.level >= 50` on connect and surfaces the appropriate Captain's Log entry. A Journal that fails to surface the entry because the signal was missed is a failure.

**AC-DP96:** [UI] Dragon sprite displays the correct stage-appropriate art in all three contexts simultaneously: party view, battle screen, and Hatchery Ring detail. Tester sets a dragon to Stage III, then visits all three screens in sequence without any game events in between. Any context showing Stage II or Stage I art is a failure.

**AC-DP97:** [Integration] After a save-load cycle, `stageMult` for a non-Elder dragon at Stage IV is within ±0.001 of 1.4. Procedure: advance a non-Elder dragon to level 55, save, reload, trigger a battle, and confirm the damage calculation uses 1.4× stageMult (not 1.0 from a default-initialised state). A result outside ±0.001 of 1.4 is a failure. Elder save/load multiplier coverage is verified by Battle Engine/Fusion integration ACs.

---

*Notes: AC-DP84 and AC-DP89 require art-director sign-off (advisory gate). AC-DP88 requires Journal integration (blocking for Stage IV crossing story). AC-DP94: committed behavior is discard-with-log (decision made 2026-05-22).*

## Open Questions

**OQ-DP01 — `XP_BATTLE_AWARD` value [RESOLVED]**
~~Resolved in design review 2026-05-22.~~ Battle XP is no longer a tuning knob in this GDD. The formula `max(1, floor(base_xp × enemyLevel / playerLevel))` in `battle-engine.md` is canonical. Dragon Progression is a consumer. Tuning the battle XP rate is done via `base_xp` in `battle-engine.md` Tuning Knobs. This GDD no longer blocks on this value — see AC-DP51 (unblocked).

**OQ-DP02 — SPD mechanic design [Advisory]**
SPD is tracked internally with no current combat effect. A future mechanic using SPD (e.g., initiative order, evasion, turn skip) will require: (1) this GDD to be revised with the mechanic defined, (2) the Battle Engine GDD to be updated, and (3) the UI Requirements section to be expanded to display SPD. No action required now — carry this question to the Campaign Map or a future mechanic GDD when initiative/turn-order design begins.

**OQ-DP03 — Stage IV visual treatment [Advisory]**
The art-director has not yet specified the Stage IV visual treatment beyond "unmistakably distinct from Stage III." This blocks AC-DP84 and AC-DP89. Requires art-director sign-off before Stage IV implementation stories can be marked Done.

**OQ-DP04 — Stage I → II and II → III audio/visual direction [Advisory]**
The audio-director has not yet specified the exact cues for Stage I → II and II → III crossings. The direction ("quiet acknowledgement", "slightly more prominent") is in the Visual/Audio Requirements section, but specific sound design has not been committed. Carry to the Audio Director GDD for formal assignment.
