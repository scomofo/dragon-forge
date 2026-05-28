# Battle Engine

> **Status**: Approved
> **Author**: Scott + agents
> **Last Updated**: 2026-05-21
> **Implements Pillar**: Core Loop — Battle

## Overview

The Battle Engine is Dragon Forge's turn-based combat simulation. Each battle runs a five-phase turn loop — INIT → TELEGRAPH → IMPACT → RECOIL → RESOLUTION — in which the player and a CPU opponent simultaneously select moves, then the engine resolves damage, elemental effectiveness, critical hits, status effects, and XP gain. Damage is calculated from attacker attack stat, defender defense stat, evolution stage multiplier, elemental type matchup, and a per-hit variance factor, then floored to an integer. Six core dragon elements form an asymmetric type chart — Fire beats Ice and Venom; Stone beats Fire and Venom; Ice and Storm each beat two elements including Shadow; Venom beats Shadow only; Shadow beats only itself in mirror matches. Shadow as a defender is weak to Ice, Storm, Venom, and same-element Shadow attacks — the most vulnerable defender in the chart, compensated by its mirror-match offensive advantage. Void is an endgame story element added by Singularity and is neutral 1.0× both ways against all elements in MVP. From the player's perspective, combat is a moment of legible tension: they pick a move, see the opponent telegraph theirs, and watch the outcome land with clear visual and audio feedback — a system that rewards knowing your dragon's strengths and your opponent's weaknesses.

## Player Fantasy

The Battle Engine is the game's primary act of trust. You are not a general commanding units — you are a handler reading a failing system's tells and trusting your dragon to hold the line against whatever the system sends. The fantasy has two beats: the read, and the landing.

**The read** happens in the TELEGRAPH phase. The opponent's intent is visible — a Fire-aligned node winding up against your Stage III Ice dragon. The type chart is in your head. Your dragon's stage multiplier is in your gut. You commit. The move is out and there is nothing left to do but watch.

**The landing** is IMPACT. The effectiveHit presentation profile fires. Your dragon flinches, holds, and retaliates. The satisfaction is not "I won the math." It is "I knew them, and they held." The element chart is a read, not a lookup. The telegraph is the system showing you what it intends — and rewarding the players who listen.

The dread of the macro-arc sits at the edge of the combat frame, not inside it. Battles feel clean, legible, 16-bit-tactile. The warmth lives in the dragon. The urgency lives in knowing that the world outside keeps fraying while you fight.

> **Designer test:** A new feature serves this fantasy if it deepens the read-and-trust cycle. Animations that obscure the telegraph signal fail. RNG that punishes good reads fails. A status effect that rewards anticipating a multi-turn pattern passes. If a feature makes the player feel clever *about* their dragon rather than clever *with* their dragon, it is drifting.

## Detailed Design

### Core Rules

1. Each battle is 1v1: one player dragon vs. one NPC dragon.
2. A battle turn executes in five phases: **INIT → TELEGRAPH → IMPACT → RECOIL → RESOLUTION**.
3. **INIT**: Battle scene initializes. Player and NPC dragon stats are computed from current level, element, and shiny flag. Active status effects carry over from previous turns only if the same dragon is re-entering a multi-turn boss encounter.
4. **TELEGRAPH**: Player selects one action. NPC AI simultaneously selects one action. The NPC's **element signal** is revealed to the player (which element the NPC is using — not the specific move name). Player may select: an Attack move, Defend, a Status move, or Use Consumable.
5. **IMPACT**: Both actions resolve simultaneously.
   - **Attack**: Deals typed damage using the damage formula.
   - **Defend**: Reduces incoming damage for this hit by ×0.5, applied post-multiplier (after elemental and stage modifiers are applied). **Defend cooldown**: a dragon that selects Defend this turn cannot select Defend on the following turn — it must choose any other action (Attack, Status move, or Consumable) before Defend becomes available again. Defend is shown greyed out but visible during its cooldown turn. This cooldown applies equally to the player and NPC AI.
   - **Status move**: Applies the user's elemental status to the opponent on successful hit.
   - **Consumable**: Applies item effect to the player's dragon. MVP in-battle consumables include Defrag Patch only. Consumable effects take effect before damage resolution within the same IMPACT.
   - **Defrag Patch**: Available in TELEGRAPH when `expedition_defrag_patch = true`. Selecting it removes the player's currently active status effect, if any, before simultaneous damage/status resolution in IMPACT, then reports `expedition_defrag_patch` consumption in `BattleDurableDelta`. If no active status exists, the action is still legal and consumes the item with no effect. Campaign Map or Singularity settlement clears the flag through ExpeditionInventoryLedger; Battle Engine never writes the durable flag directly.
   - **Simultaneous KO**: If both dragons are reduced to 0 HP in the same IMPACT, the player wins.
6. **RECOIL**: Active status effects tick on both dragons. **DoT declaration order: player dragon's DoT ticks first, then NPC dragon's DoT ticks.** Non-DoT statuses update their timers in the same order.
   - Burn and Poison: deal DoT damage (player dragon first, then NPC dragon).
   - Freeze: registers a guaranteed turn-skip for next TELEGRAPH.
   - Paralyze: registers a random chance to skip action next TELEGRAPH.
   - Guard Break: decrements the DEF reduction timer; effectiveDef remains reduced until the timer reaches 0.
   - Blind: reduces attacker's effective accuracy by 30 points for 2 turns.
   - Status effects registered in this turn's IMPACT are active starting next RECOIL. A newly applied status **overwrites** any existing status (no stacking). **A dragon may hold at most one status effect at a time** — all six elemental statuses (Burn, Freeze, Paralyze, Guard Break, Poison, Blind) compete in a single slot.
7. **RESOLUTION**: KO check. Player dragon HP ≤ 0 → defeat. NPC dragon HP ≤ 0 → victory + XP award. Neither ≤ 0 → loop to next TELEGRAPH.
8. **NPC AI** selects moves using elemental heuristics with this priority order: (1) **Super-effective** — if any available attack move is 2.0× effective against the player's element, the NPC prefers it at 70%; (2) **Status** — if no SE move is available and the player has no active status, the NPC prefers a status move at 40%; (3) **High-power fallback** — otherwise the NPC picks the highest-power move at 60%, falling back to random selection among themed moves. Weight conflicts resolve by this priority: super-effective beats power, which beats status. The NPC also respects its own Defend cooldown and cannot Defend two consecutive turns.

### States and Transitions

| State | Entry Condition | Player Can Act | NPC Can Act | Exit Condition |
|-------|-----------------|----------------|-------------|----------------|
| INIT | Battle begins | No | No | Stats initialized |
| TELEGRAPH | INIT complete; or RESOLUTION with no KO | Yes | Yes (AI) | Both sides selected |
| IMPACT | Both sides selected | No | No | All effects resolved |
| RECOIL | IMPACT complete | No | No | Status ticks complete |
| RESOLUTION | RECOIL complete | No | No | KO check: end or loop |

**Frozen/Paralyzed dragons in TELEGRAPH**: If a dragon has a registered turn-skip from Freeze, it does not select an action — no telegraph signal is shown for that side. If a dragon has Paralysis and its skip check fires, same behavior: no action, no signal.

### Interactions with Other Systems

| System | Direction | Data In | Data Out |
|--------|-----------|---------|----------|
| Dragon Progression | Upstream | Base stats (HP, ATK, DEF, SPD) at current level, element, shiny status, standard stage thresholds | — |
| Fusion Engine | Upstream | `is_elder` flag and `ELDER_STAGE_MULT` constant for Elder Stage IV multiplier branch | — |
| Save / Persistence | Upstream | Current HP, level, shiny flag, active status, `is_elder` at battle entry | HP/status delta and raw reward payload at RESOLUTION |
| Dragon Forge Hub | Downstream | — | `turn_resolved`, `battle_ended` signals for UI updates |
| Campaign Map | Downstream | — | Battle result (victory/defeat) at RESOLUTION |
| Singularity | Downstream | — | Battle result; boss combatants use same NPC state structure with scripted moves in KERNEL_PANIC phase |
| Shop | Upstream | Consumable item definitions (effect type, magnitude) | — |
| Audio Director | Downstream | — | Presentation profile signals: `miss`, `resisted_hit`, `normal_hit`, `effective_hit`, `critical_hit`, `status_apply`, `reflect`, `ko` |

## Formulas

### Move Accuracy

Each move has an accuracy rating (85–100). A miss check runs before any damage:

```
accuracyRoll = random(0, 100)
if accuracyRoll > effectiveAccuracy → MISS (damage = 0, hit = false)
```

With Blind status active on the attacker: `effectiveAccuracy = max(0, move.accuracy - 30)`

*Move accuracy values: 100% (Flame Wall, Frost Bite, Thunder Clap, Acid Spit), 95% (Magma Breath, Rock Slide, Shadow Strike, Radiant Beam), 90% (Lightning Strike), 85% (Blizzard, Earthquake, Toxic Cloud, Void Pulse).*

---

### Damage Formula

**Variables:**
- `ATK` — attacker's attack stat (after level scaling)
- `DEF` — defender's defense stat (after level scaling, before status modifiers)
- `stageMult` — stage multiplier (see Stage Multipliers table)
- `typeEff` — elemental type effectiveness (see Type Chart)
- `defending` — true if defender selected Defend this turn
- `roll` — random variance drawn from `[0.85, 1.0]`
- `CRIT_CHANCE` = 0.10 (10%)
- `CRIT_MULTIPLIER` = 1.5×

**Steps (in order):**
```
1. Accuracy check (see above) — if miss, stop.
2. baseDamage = (ATK × stageMult × 1.5) − (DEF × 0.5)
3. typedDamage = baseDamage × typeEff
4. If defending: typedDamage = typedDamage × 0.5   [applied post-multiplier]
5. roll = random(0.85, 1.0)
6. preCritDamage = max(1, floor(typedDamage × roll))
7. If random(0, 1) < 0.10: finalDamage = floor(preCritDamage × 1.5)
   Else: finalDamage = preCritDamage
```

Minimum 1 damage guaranteed. Note: `move.power` values in game data are used by NPC AI for move selection heuristics only — they do not modify the damage calculation.

**Example** (Stage III Fire dragon, ATK=70, vs Stage II Ice dragon, DEF=44, no defend, no crit, roll=0.90):
```
baseDamage = (70 × 1.0 × 1.5) − (44 × 0.5) = 105 − 22 = 83
typeEff = 2.0  (Fire beats Ice)
typedDamage = 83 × 2.0 = 166
preCritDamage = max(1, floor(166 × 0.90)) = 149
finalDamage = 149
```

---

### Stage Multipliers

| Stage | Level Range | stageMult |
|-------|-------------|-----------|
| I | 1–9 | 0.5× |
| II | 10–24 | 0.75× |
| III | 25–49 | 1.0× |
| IV | 50+ | 1.4× |
| Elder IV | 50+ and `is_elder = true` | 1.75× |

`ELDER_STAGE_MULT = 1.75` is defined by Fusion Engine. Battle Engine reads the
dragon record's `is_elder` flag and applies the Elder IV branch only when the dragon
is both Stage IV and Elder. Elder dragons below Stage IV use the normal stage row for
their current level.

---

### Type Effectiveness Chart

`typeChart[attacker][defender]` — values shown as multiplier applied to `typedDamage`.

| Attacker ↓ / Defender → | Fire | Ice | Storm | Stone | Venom | Shadow | Void |
|-------------------------|------|-----|-------|-------|-------|--------|------|
| **Fire** | 0.5× | 2.0× | 1.0× | 0.5× | 2.0× | 1.0× | 1.0× |
| **Ice** | 0.5× | 0.5× | 2.0× | 1.0× | 1.0× | 2.0× | 1.0× |
| **Storm** | 1.0× | 0.5× | 0.5× | 2.0× | 1.0× | 2.0× | 1.0× |
| **Stone** | 2.0× | 1.0× | 0.5× | 0.5× | 2.0× | 1.0× | 1.0× |
| **Venom** | 0.5× | 1.0× | 1.0× | 0.5× | 0.5× | 2.0× | 1.0× |
| **Shadow** | 1.0× | 0.5× | 0.5× | 1.0× | 0.5× | 2.0× | 1.0× |
| **Void** | 1.0× | 1.0× | 1.0× | 1.0× | 1.0× | 1.0× | 1.0× |

*Shadow as attacker: 2.0× vs Shadow (mirror match only); 1.0× vs Fire and Stone; 0.5× vs Ice, Storm, and Venom. Shadow is the only element with a single super-effective matchup, and it is exclusively in the mirror. Shadow as defender: 2.0× from Ice, Storm, Venom, and Shadow; 1.0× from Fire and Stone.*

---

### Stat Scaling Formula

Applied to HP, ATK, DEF, SPD at battle INIT:

```
stat_at_level(baseStat, level, shiny) = floor((baseStat + (level − 1) × 3) × shinyMult)
where shinyMult = 1.2 if shiny, else 1.0
```

*Example: Fire dragon, base ATK=28, level 20, not shiny:*
`floor((28 + 19 × 3) × 1.0) = floor(85) = 85`

---

### Status Effect Formulas

| Status | Element | Formula | Duration | Apply Chance |
|--------|---------|---------|----------|--------------|
| Burn | Fire | `damage = max(1, floor(maxHp × 0.08))` per RECOIL | 2 turns | 30% |
| Freeze | Ice | Target skips next turn (guaranteed) | 1 turn | 30% |
| Paralyze | Storm | 50% chance to skip turn each RECOIL | 2 turns | 30% |
| Guard Break | Stone | `effectiveDef = floor(DEF × 0.6)` for duration | 2 turns | 30% |
| Poison | Venom | `damage = max(1, floor(maxHp × 0.06))` per RECOIL | 2 turns | 30% |
| Blind | Shadow | `effectiveAccuracy = max(0, move.accuracy − 30)` | 2 turns | 30% |

Status is applied at IMPACT if the attack hits and `random(0, 1) < 0.30`. DoT damage uses the **defender's max HP** (not current HP) — Burn and Poison are not affected by damage already taken this battle.

---

### Raw XP Gain Formula

Awarded at RESOLUTION on victory:

```
raw_xp_awarded = max(1, floor(base_xp × float(enemyLevel) / float(playerLevel)))
```

`base_xp` is per-NPC (range: 25–90). Higher-level enemies award more XP; lower-level enemies award less.
Campaign Map may apply over-leveling decay to this raw value before calling Dragon
Progression `apply_xp()`. Battle Engine owns the raw formula only; Campaign Map owns
final expedition XP and Scrap application.

**Precondition:** `playerLevel >= 1` — enforced at battle entry. Division by zero is not possible. GDScript requires explicit float conversion: `float(enemy_level) / float(player_level)` to prevent integer truncation (e.g. `5 / 10 = 0` in GDScript without conversion).

## Edge Cases

**Negative base damage (high DEF vs. low ATK):**
`baseDamage = (ATK × stageMult × 1.5) − (DEF × 0.5)` can produce a negative value if DEF is very high relative to ATK. The `max(1, ...)` floor in the damage formula guarantees a minimum of 1 damage regardless — a zero-damage outcome is not possible on a hit.

**Critical hit on a Defending target:**
Crit is applied after Defend. The full chain: `typedDamage × 0.5 × roll × 1.5`. A critical hit on a Defending target deals 75% of what a non-defended crit would deal. Crit does not negate Defend.

**Simultaneous KO (both dragons reach 0 HP in same IMPACT):**
Player wins. This is the declared tiebreaker. Applies only to IMPACT-phase damage; status DoT in RECOIL is resolved sequentially (player dragon's DoT fires first, then NPC dragon's DoT), so a true simultaneous KO from DoT is not possible — the first dragon to KO from DoT ends the battle at RESOLUTION before the second DoT has any effect.

**Consumable targeting a KO'd dragon:**
Consumables apply in IMPACT before damage resolution. If both a Consumable and an incoming attack are applied in the same IMPACT and the net result would KO the dragon, RESOLUTION evaluates final HP after all IMPACT effects are applied. A Consumable cannot revive an already-KO'd dragon (HP already at 0 from a prior turn's RESOLUTION).

**Status applied to a dragon that already has a status:**
New status overwrites. The previous status (including any remaining turns) is discarded entirely. A 2-turn Poison followed immediately by a Freeze does not preserve the Poison.

**Blind on a 100% accuracy move:**
`max(0, 100 − 30) = 70%`. Blind still reduces accuracy; no move is immune to the accuracy reduction regardless of its base accuracy rating.

**Burn/Poison damage when HP is very low:**
Both DoT formulas use `max(1, floor(maxHp × value))`. DoT uses max HP — it is not affected by the dragon's current HP. A dragon at 1 HP still takes full DoT and is KO'd. HP cannot go below 0 (clamped at `max(0, hp − damage)`).

**Guard Break while target is already Guard Broken:**
New application overwrites — the DEF reduction resets to its full 2-turn duration and recalculates `effectiveDef = floor(DEF × 0.6)` from the current base DEF (not the already-reduced effective DEF). Guard Break does not stack multiplicatively.

**Paralyze and Freeze registered in same turn (status overwrite case):**
Not possible in a single turn — only one status can be applied per IMPACT (one attacking move per turn per side). However, if Freeze expires and Paralyze is applied in the same RECOIL resolution cycle, Paralyze is applied fresh with no interaction.

**Dragon entering battle with HP below max:**
HP at battle INIT is read from Save/Persistence. The dragon's battle maxHp is calculated at INIT from its stats; if current HP < maxHp at entry, it begins damaged. Status DoT is still calculated from maxHp, not entry HP. There is no in-battle HP recovery to full before battle begins.

**XP floor at 1 (player far outlevels enemy):**
`max(1, floor(25 × (1 / 60)))` → `max(1, 0)` → 1. Battles against very low-level enemies always award at least 1 XP. There is no XP penalty for over-leveling beyond the floor.

**Continuous multi-phase boss profile swap (Singularity / Mirror Admin):**
Mirror Admin is one continuous boss encounter owned by Singularity. Battle Engine must allow Singularity to swap combat profiles at phase thresholds without emitting `battle_ended`, awarding XP, returning to Campaign Map, or opening a new INIT cycle. Statuses, pending skips, and Defend cooldowns are cleared on phase transition by Singularity. Rewards and `battle_ended` are emitted only on final KO or player defeat.

## Dependencies

### Upstream Dependencies (Battle Engine reads from)

| System | What Battle Engine needs | Interface |
|--------|--------------------------|-----------|
| **Dragon Progression** | Base stats (HP, ATK, DEF, SPD) per element; stat scaling formula; standard stage thresholds | `calculateStatsForLevel(baseStat, level, shiny)` |
| **Fusion Engine** | `is_elder` semantics and `ELDER_STAGE_MULT = 1.75` for Elder Stage IV dragons | Dragon record flag + exported constant |
| **Save / Persistence** | Player dragon's current HP, level, shiny flag, active status, and `is_elder` at battle entry | Read from `SaveSnapshot` at INIT; return HP/status delta at RESOLUTION. Campaign Map or Singularity commits final HP/status, XP, Scrap, item, and milestone outcomes after `battle_completed`. |
| **Shop** | Consumable item definitions: effect type (heal, cure status, etc.) and magnitude | Item definition table read at battle start |

### Downstream Dependents (systems that read Battle Engine output)

| System | What it needs from Battle Engine | Interface |
|--------|----------------------------------|-----------|
| **Dragon Forge Hub** | Turn results for UI display; battle end signal | `turn_resolved` and `battle_ended` signals |
| **Campaign Map** | Victory/defeat outcome to advance or hold map state | `battle_ended` result payload |
| **Singularity** | Full battle execution for gatekeeper and final boss encounters | Passes boss combatants and scripted/weighted AI profiles; receives `battle_ended` only for gatekeeper completion and final Mirror Admin KO/defeat |
| **Mirror Admin** | Continuous 3-phase final boss (sub-system of Singularity) | Singularity drives phase profile swaps, threshold clamps, tritone counter resolution, and `battle_ended` suppression between phases |
| **Audio Director** | Presentation profile events to trigger SFX and music | Signals: `miss`, `resisted_hit`, `normal_hit`, `effective_hit`, `critical_hit`, `status_apply`, `reflect`, `ko` |

### Signal Schemas

**`battle_ended` payload** (emitted at RESOLUTION on KO):
```
{
  victory:              bool    # true if NPC dragon KO'd, false if player dragon KO'd
  raw_xp_awarded:      int     # raw Battle Engine XP before Campaign Map decay (0 on defeat)
  scraps_earned:       int     # Data Scraps awarded by this combatant/reward profile (0 on defeat)
  player_hp_remaining: int     # player dragon HP after battle (≥ 0)
  player_level_start:  int     # player dragon level at battle start
  enemy_level:         int     # enemy level used for raw_xp_awarded
}
```

**`turn_resolved` payload** (emitted at end of RESOLUTION when no KO):
```
{
  player_hp:  int   # current player dragon HP
  npc_hp:     int   # current NPC dragon HP
  turn_count: int   # total turns completed so far this battle
}
```

> **Bidirectional note:** Dragon Progression GDD must list Battle Engine as a downstream dependent. Save/Persistence GDD must list Battle Engine as a read/write consumer. Shop GDD must list Battle Engine as a data consumer for consumable definitions. These cross-references must be validated when those GDDs are authored.

## Tuning Knobs

| Knob | Current Value | Safe Range | Gameplay Effect |
|------|--------------|------------|-----------------|
| `CRIT_CHANCE` | 10% | 5–20% | Frequency of crit surges. Below 5% feels unnoticeable; above 20% undermines the read-and-trust fantasy by adding too much variance. |
| `CRIT_MULTIPLIER` | 1.5× | 1.25–2.0× | Magnitude of crit impact. Below 1.25× crits feel trivial; above 2.0× crits become comeback mechanic killers. |
| `STATUS_APPLY_CHANCE` | 30% | 15–45% | How often status effects land on hit. Below 15% makes status moves feel unreliable; above 45% makes battles feel status-dominated rather than type-read-dominated. |
| Variance roll range | [0.85, 1.0] | [0.80, 1.0] – [0.90, 1.0] | Per-hit unpredictability. Narrowing to [0.90, 1.0] makes damage more predictable (favors skilled play); widening to [0.80, 1.0] adds tension (favors comeback moments). |
| Stage I multiplier | 0.5× | 0.4–0.6× | Damage output of lowest-stage dragons. Raising reduces early-game challenge; lowering makes early battles feel anemic. |
| Stage IV multiplier | 1.4× | 1.2–1.6× | Power ceiling of fully-evolved dragons. Too high creates a runaway snowball; too low makes stage evolution feel unrewarding. |
| Elder Stage IV multiplier | 1.75× | 1.5–2.0× | Imported from Fusion Engine as `ELDER_STAGE_MULT`; used only for dragons with `is_elder = true` at Stage IV. |
| Stage II threshold (level) | 10 | 7–13 | How quickly a dragon evolves out of Stage I. Lower = earlier power bump. |
| Stage III threshold (level) | 25 | 20–30 | Controls mid-game power plateau. |
| Stage IV threshold (level) | 50 | 45–55 | Controls endgame power ceiling. |
| Burn DoT per tick | 8% maxHp | 5–12% | Burn's pressure per turn. Above 12% becomes oppressive in a 2-turn window. |
| Poison DoT per tick | 6% maxHp | 4–10% | Poison's attrition. Intentionally lower than Burn — Venom is the patience element. |
| Guard Break DEF reduction | 40% | 25–50% | Stagger's impact. Above 50% with a 2-turn window can trivialize tank dragons. |
| Blind accuracy reduction | 30 pts | 15–40 pts | Shadow's evasion impact. Below 15 pts is barely felt; above 40 pts makes high-accuracy moves irrelevant. |
| Paralysis skip chance | 50% | 35–65% | Storm's RNG pressure. Widening range increases frustration at high values. |
| NPC super-effective preference | 70% | 55–85% | How aggressively the NPC chases advantageous matchups. High values make NPC feel reactive to telegraphs. |
| NPC status-move preference | 40% | 25–55% | How often the NPC applies statuses when target is clean. |
| NPC high-power move preference | 60% | 40–75% | How often the NPC picks highest-power move vs. a random themed move. |

## Visual/Audio Requirements

### Presentation Profiles

The Battle Engine emits one presentation profile signal per attack outcome. The Audio Director and VFX systems subscribe to these signals:

| Profile | Trigger | Expected Visual | Expected Audio |
|---------|---------|-----------------|----------------|
| `miss` | Accuracy check fails | Dragon silhouette flicker; no hit flash | Soft "whoosh" — no impact sound |
| `resisted_hit` | typeEff = 0.5× | Muted hit flash; small damage number | Dampened impact thud |
| `normal_hit` | typeEff = 1.0× | Standard hit flash; damage number | Standard impact |
| `effective_hit` | typeEff = 2.0× | Bright element-colored hit flash; larger number | Enhanced impact with element sound layer |
| `critical_hit` | Crit flag = true | Screen shake; gold number highlight | Crit chime on top of impact |
| `status_apply` | Status applied to target | Status icon appears; brief element particle | Element-specific status sound |
| `reflect` | Null Reflect / Mirror Admin reflect mechanic | Reflect animation; damage returns to attacker | Reflect SFX |
| `ko` | Dragon HP reaches 0 | Dragon sprite fade; 16-bit KO animation | 16-bit defeat chord |

### Corruption Stage Overlays

As the Singularity arc advances, the battle screen applies corruption visual filters (governed by Singularity GDD). The Battle Engine passes the current corruption stage to the presentation layer at INIT but does not own the filter logic.

## UI Requirements

- **HP bars**: Both player dragon and NPC dragon HP bars visible at all times. Current/max HP displayed numerically. HP bar color shifts as HP falls (green → yellow → red).
- **Status indicator**: Active status icon + remaining turns displayed on the afflicted combatant's portrait. No indicator when no status active.
- **Turn phase label**: Current phase displayed (TELEGRAPH / IMPACT / RECOIL) so the player understands where they are in the loop. INIT and RESOLUTION phases are instantaneous and may show a brief transition state.
- **TELEGRAPH — move selection menu**: Player's dragon's move list displayed; Defend always shown as a dedicated option. Consumable items shown if any are in inventory. Each move displays its element icon.
- **TELEGRAPH — Defrag Patch**: If `expedition_defrag_patch = true`, show "Use Defrag Patch" in the consumable list. The action remains selectable even when no active status is present because Shop specifies that no-status use consumes the item with no effect.
- **TELEGRAPH — NPC intent signal**: NPC's element signal displayed prominently on the NPC's side of the screen before IMPACT. If NPC is Frozen/Paralyzed and skipping, this side remains blank.
- **Damage numbers**: Floating combat text per hit. Presentation profile determines size, color, and animation.
- **XP award display**: XP gained shown at RESOLUTION on victory before returning to the map.
- **All UI navigation must support d-pad input**: No hover-only interactions. Face button confirms move selection. (See Input Router GDD.)

## Acceptance Criteria

All unit tests live in `tests/unit/battle_engine/`. All integration tests live in `tests/integration/battle_engine/`.

- [ ] **[UNIT]** Damage formula: given known ATK, DEF, stageMult, typeEff, and roll=1.0 (no crit), output equals `max(1, floor(((ATK × stageMult × 1.5) − (DEF × 0.5)) × typeEff × roll))`
- [ ] **[UNIT]** Damage formula: when `(ATK × stageMult × 1.5) − (DEF × 0.5)` is negative, final damage = 1 (negative base damage floor)
- [ ] **[UNIT]** Crit multiplier: `finalDamage = floor(preCritDamage × 1.5)` where `preCritDamage` already has `max(1, floor(...))` applied
- [ ] **[UNIT]** Crit after Defend: crit on a defending target equals `floor(typedDamage × 0.5 × roll × 1.5)` — order confirmed; Defend does not negate crit
- [ ] **[UNIT]** Crit rate: over 10,000 trials, crit fires at 10% ± 2% (statistical)
- [ ] **[UNIT]** Defend: reduces incoming `typedDamage` by 50%, applied post-multiplier (after elemental and stage), before variance roll
- [ ] **[UNIT]** Type effectiveness: full core 6×6 matrix (36 matchups) plus Void row/column verified against the type chart — each cell returns the correct multiplier
- [ ] **[UNIT]** Stage multipliers: I = 0.5×, II = 0.75×, III = 1.0×, IV = 1.4× applied correctly in the damage formula
- [ ] **[UNIT]** Elder Stage IV multiplier: a dragon with `is_elder = true` and level 50+ uses `ELDER_STAGE_MULT = 1.75`; the same dragon below level 50 uses the normal Stage I/II/III multiplier for its level.
- [ ] **[UNIT]** Stage thresholds: levels 1–9 → Stage I; 10–24 → Stage II; 25–49 → Stage III; 50+ → Stage IV
- [ ] **[UNIT]** Accuracy miss: a move with accuracy 85 misses when `accuracyRoll > 85`; damage = 0 on miss
- [ ] **[UNIT]** Blind accuracy: `effectiveAccuracy = max(0, move.accuracy − 30)`; a 100%-accuracy move under Blind resolves at 70% effective accuracy
- [ ] **[UNIT]** Stat scaling: `floor((baseStat + (level − 1) × 3) × shinyMult)` verified for shiny (1.2×) and non-shiny (1.0×) at representative levels
- [ ] **[UNIT]** Stat scaling boundary: shiny stat at level 1 equals `floor(baseStat × 1.2)`; non-shiny equals `baseStat` (no rounding error)
- [ ] **[UNIT]** Status apply rate: over 1,000 trials, status applies at 30% ± 5% (statistical)
- [ ] **[UNIT]** Status overwrite: applying Status B to a dragon with Status A results in only Status B remaining with a fresh duration; Status A is fully discarded
- [ ] **[UNIT]** Burn: deals `max(1, floor(maxHp × 0.08))` per RECOIL tick for 2 turns; DoT calculated from maxHp, not current HP
- [ ] **[UNIT]** Poison: deals `max(1, floor(maxHp × 0.06))` per RECOIL tick for 2 turns; DoT calculated from maxHp, not current HP
- [ ] **[UNIT]** Burn/Poison at low HP: a dragon at 1 current HP still takes full DoT from maxHp and is KO'd
- [ ] **[UNIT]** Freeze: frozen dragon does not select an action in the next TELEGRAPH phase; duration = 1 turn
- [ ] **[UNIT]** Paralysis skip: over 1,000 trials, action is skipped at 50% ± 5%; duration = 2 turns (statistical)
- [ ] **[UNIT]** Guard Break: `effectiveDef = floor(DEF × 0.6)` during its 2-turn duration; re-applying Guard Break resets timer and recalculates from base DEF (no multiplicative stacking)
- [ ] **[UNIT]** XP formula: `max(1, floor(base_xp × float(enemyLevel) / float(playerLevel)))` verified for representative pairs including extreme level gap (floor case = 1); GDScript integer division must NOT be used (e.g. `5 / 10 = 0`, not `0.5`)
- [ ] **[INTEGRATION]** Simultaneous KO: both dragons reaching 0 HP in the same IMPACT → player victory; simultaneous KO via RECOIL DoT is not possible (DoT resolves in declaration order)
- [ ] **[INTEGRATION]** Consumable timing: consumable applied in IMPACT takes effect before opponent's simultaneous damage; net HP reflects heal + damage in the correct order
- [ ] **[INTEGRATION]** Defrag Patch: with `expedition_defrag_patch = true` and player status Burn active, selecting Use Defrag Patch in TELEGRAPH clears Burn before IMPACT damage/status resolution and returns `expedition_defrag_patch` in `BattleDurableDelta.consumed_item_flags`
- [ ] **[INTEGRATION]** Defrag Patch no-status case: with `expedition_defrag_patch = true` and no active player status, selecting Use Defrag Patch consumes the item, returns `expedition_defrag_patch` in `BattleDurableDelta.consumed_item_flags`, and changes no status state
- [ ] **[INTEGRATION]** Five-phase turn loop: 50 consecutive turns including at least one Freeze turn and one Paralysis skip complete without state errors or illegal transitions
- [ ] **[INTEGRATION]** Presentation profile signals: `miss`, `resisted_hit`, `normal_hit`, `effective_hit`, `critical_hit`, `status_apply`, and `ko` each fire exactly once on the turn triggering the corresponding outcome (`reflect` signal is out of scope — defined in Mirror Admin GDD)
- [ ] **[INTEGRATION]** Battle end: `battle_ended` signal fires with correct victory/defeat payload on KO; no further turn phases execute after signal fires
- [ ] **[UNIT]** Defend cooldown: a dragon that Defended on turn N cannot select Defend on turn N+1; Defend becomes available again on turn N+2 or later (after any other action)
- [ ] **[UNIT]** Defend cooldown — NPC: NPC AI cannot Defend two consecutive turns; Defend is excluded from NPC selection on the turn after NPC Defended
- [ ] **[UNIT]** Type chart — Shadow mirror match: Shadow→Shadow effectiveness = 2.0× (included in full 6×6 matrix test above)
- [ ] **[UNIT]** Status single-slot: applying any status to a dragon that already has a different status results in exactly one active status (the new one); the previous status and its remaining duration are fully discarded
- [ ] **[UNIT]** Status duration tick: a 2-turn status decrements its counter by 1 each RECOIL; after 2 turns, the status is cleared and no longer active
- [ ] **[UNIT]** DoT expiry: Burn/Poison deal damage on turns 1 and 2; on turn 3 (after expiry), no DoT damage is dealt and the status is absent from the dragon's state
- [ ] **[UNIT]** DoT declaration order: when both dragons have active DoT in the same RECOIL, player dragon's DoT ticks first, then NPC dragon's DoT ticks; if player dragon reaches 0 HP from DoT, NPC's DoT still fires but KO is determined at RESOLUTION
- [ ] **[UNIT]** Stage boundary — level 9 → 10: dragon at level 9 is Stage I (stageMult = 0.5×); dragon at level 10 is Stage II (stageMult = 0.75×)
- [ ] **[UNIT]** Stage boundary — level 24 → 25 and 49 → 50: verified same way as above for Stage II→III and III→IV transitions
- [ ] **[UNIT]** `battle_ended` signal payload: contains `victory` (bool), `raw_xp_awarded` (int), `scraps_earned` (int), `player_hp_remaining` (int), `player_level_start` (int), and `enemy_level` (int); no extra fields; fires exactly once per battle.
- [ ] **[ADVISORY — MANUAL]** TELEGRAPH phase: NPC element signal visible to player before IMPACT; frozen dragon shows no telegraph signal on its side
- [ ] **[ADVISORY — MANUAL]** NPC AI: when super-effective move is available, NPC selects it in the majority of observed turns during a playtest session

## Open Questions

- **HP recovery between map encounters**: Does the player dragon fully heal between battles, or does HP carry over? This affects battle difficulty balancing and consumable economy. Decision deferred to Campaign Map GDD.
- **Consumable HP cap**: When a consumable heals HP, is it capped at maxHp? The battle engine should receive a capped value from the consumable system, not enforce it internally — confirm interface contract with Shop GDD.
- **NPC move power as a design signal**: NPC AI uses `move.power` values for heuristic move selection (prefer highest-power move 60% of the time). These values currently have no effect on damage. If move.power is ever wired into the damage formula in a future pass, all existing balance data will shift — flag this before any such change.
- **Void dragon reflect move**: The Void dragon (Mirror Admin endgame unlock) uses the neutral Void type chart row/column above. Its optional `null_reflect` move has `isReflect: true` and `power: 0` and is excluded from NPC AI normal move selection. The reflect mechanic is listed as a presentation profile (`reflect`) but its exact combat resolution logic is post-MVP unless Singularity explicitly scopes it for implementation.
- **XP exploit gate (Campaign Map hard dependency)**: The XP formula is uncapped. A level-1 player reaching a level-50 enemy zone earns up to 4,500 XP per battle, potentially crossing multiple stage thresholds in a single encounter. Campaign Map GDD MUST specify either: (a) minimum player level or stage requirement per zone, or (b) hard access gates that prevent low-level entry into high-level zones. This GDD does not enforce an XP cap — zone gating is the safeguard. If Campaign Map does not provide this guarantee, a per-battle XP cap must be added to this formula.
- **Per-battle consumable limits**: If healing consumables are unlimited per battle, a player with a stocked inventory can trivialize boss encounters through attrition. This GDD does not specify per-battle consumable limits. Shop GDD must either define a per-battle use cap or explicitly state that consumables are unlimited and the boss encounter pacing accounts for this.
- **Missing upstream GDDs**: Dragon Progression (stat base values, level-XP curve), Campaign Map (zone structure, enemy levels, zone gating), and Shop (consumable definitions and limits) are upstream dependencies whose GDD files do not yet exist on disk. All balance claims in this document that depend on those systems — including XP balance, consumable economy, and stat scaling at level boundaries — are provisional until those GDDs are authored and cross-referenced.
