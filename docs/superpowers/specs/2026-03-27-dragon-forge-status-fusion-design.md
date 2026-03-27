# Dragon Forge: Status Effects & Fusion Chamber Design Spec

## Overview

Two features: (1) elemental status effects in combat — 6 element-specific debuffs applied by elemental moves, and (2) the Fusion Chamber — breed two dragons to create a stronger offspring with elemental alchemy, stability tiers, and Stage IV Elder evolution.

---

## 1. Status Effects — Combat Logic

### 1.1 Effect Table

| Effect | Element | Duration | Behavior |
|---|---|---|---|
| Burn | Fire | 2 turns | Deals 8% max HP damage at end of turn |
| Freeze | Ice | 1 turn | Target skips their next action entirely |
| Paralyze | Storm | 2 turns | 50% chance to skip action each turn |
| Guard Break | Stone | 2 turns | Target DEF reduced by 40% |
| Poison | Venom | 2 turns | Deals 6% max HP damage at end of turn |
| Blind | Shadow | 2 turns | Target accuracy reduced by 30% |

### 1.2 Apply Rules

- 30% chance on any elemental move (not basic attack, not defend)
- Only one status at a time — new replaces old
- Status applied after damage, at the end of the attacker's action
- Duration ticks down at the end of each full turn (after both combatants have acted)
- Frozen targets skip their action entirely
- Paralyzed targets have 50% chance to skip each turn they're paralyzed
- Guard Break reduces DEF by 40% for damage calculation while active
- Blind reduces accuracy by 30 percentage points (e.g., 95% becomes 65%)

### 1.3 Move Data Change

Add `canApplyStatus: true` to all elemental moves in `gameData.js`. Basic attack has `canApplyStatus: false`. The status effect applied matches the move's element.

### 1.4 Engine Changes

`battleEngine.js` changes:
- Add `status` field to combatant state: `{ effect: 'burn', turnsLeft: 2 }` or `null`
- `resolveTurn` checks for Freeze/Paralyze before action — may skip
- After each attack action, 30% roll to apply status matching move element
- After both combatants act, tick DOT effects (Burn/Poison) and decrement `turnsLeft`
- Guard Break modifies effective DEF during damage calculation
- Blind modifies effective accuracy during accuracy check

---

## 2. Status Effects — Visual & Sound

### 2.1 In-Battle Display

- Status icon + name below HP bar: e.g., "🔥 BURN 2t"
- Color matches element that applied it
- When DOT triggers: floating text "Burned! -12 HP" or "Poisoned! -8 HP"
- When skip triggers: floating text "Frozen!" or "Paralyzed!"
- When status expires: brief "Status cleared" flash

### 2.2 SFX

- `statusApply` — short buzzing/crackling tone
- `statusTick` — quiet sizzle when DOT triggers
- `statusExpire` — soft ascending chime

---

## 3. Fusion Chamber — Mechanics

### 3.1 Access

FUSION nav tab appears only when:
- Player owns 2+ dragons
- At least one owned dragon is Stage II+ (level 10+)

### 3.2 Eligibility

- Only Stage II+ dragons (level 10+) can be fused
- Both parents are consumed — destroyed after fusion
- Costs 100 dataScraps

### 3.3 Elemental Alchemy

Same-element fusions keep that element. Cross-element combinations:

| Parent A | Parent B | Offspring |
|---|---|---|
| Fire + Fire | | Fire |
| Ice + Ice | | Ice |
| Storm + Storm | | Storm |
| Stone + Stone | | Stone |
| Venom + Venom | | Venom |
| Shadow + Shadow | | Shadow |
| Fire + Ice | | Storm |
| Fire + Storm | | Fire |
| Fire + Stone | | Stone |
| Fire + Venom | | Shadow |
| Fire + Shadow | | Fire |
| Ice + Storm | | Ice |
| Ice + Stone | | Stone |
| Ice + Venom | | Venom |
| Ice + Shadow | | Shadow |
| Storm + Stone | | Storm |
| Storm + Venom | | Venom |
| Storm + Shadow | | Shadow |
| Stone + Venom | | Venom |
| Stone + Shadow | | Stone |
| Venom + Shadow | | Shadow |

### 3.4 Stat Formula

```
resultStat = floor(((parentA_stat + parentB_stat) / 2) * 1.1)
```

Where `parentA_stat` and `parentB_stat` are the parents' current calculated stats (including level scaling and shiny bonuses).

### 3.5 Stability Tiers

| Tier | Condition | Modifier |
|---|---|---|
| Stable | Same element | All stats * 1.25 |
| Normal | Neutral combo | No modifier (just the 1.1x fusion bonus) |
| Unstable | Opposing elements | HP * 0.8, ATK * 1.1 |

**Opposing pairs:** Fire↔Ice, Storm↔Stone, Venom↔Shadow

### 3.6 Offspring

- Element determined by alchemy table
- Level 1 with `fusedBaseStats` (the calculated fused stats become the new base)
- If either parent was shiny, offspring is shiny
- **Stage IV exception:** If both parents are Stage III (level 25+), offspring starts at level 50 (Stage IV) with gold drop-shadow and 1.4x stage multiplier

### 3.7 Fusion Cost

100 dataScraps deducted on fusion.

---

## 4. Fusion Chamber — UI

### 4.1 Layout

```
┌─────────────────────────────────────────────────┐
│ [HATCHERY] [FUSION] [BATTLES]    ◆ 230 dataScraps│
├─────────────────────────────────────────────────┤
│              FUSION CHAMBER                       │
│                                                   │
│   ┌─────────┐          ┌─────────┐               │
│   │ Parent A │   ───►   │ Parent B │              │
│   │ [dragon] │          │ [dragon] │              │
│   │ Lv.12   │          │ Lv.8    │              │
│   └─────────┘          └─────────┘               │
│                                                   │
│          ┌──────────────────┐                     │
│          │ RESULT PREVIEW   │                     │
│          │ Element: Storm   │                     │
│          │ Stability: Stable│                     │
│          │ Stats: HP 124... │                     │
│          └──────────────────┘                     │
│                                                   │
│   ⚠ Both parents will be consumed                │
│                                                   │
│        [FUSE — costs 100◆]                        │
└─────────────────────────────────────────────────┘
```

### 4.2 Flow

1. Player picks Parent A from owned Stage II+ dragons
2. Player picks Parent B from remaining eligible dragons
3. Preview shows: resulting element, stability tier, stat preview, consumption warning
4. FUSE button (disabled if insufficient scraps or fewer than 2 eligible dragons selected)
5. On fuse: animation plays, parents consumed, offspring added to save

### 4.3 Fusion Animation (~2 seconds)

1. Both parent sprites slide toward center (400ms)
2. Bright white flash at merge point (200ms)
3. Element-colored burst matching offspring element (300ms)
4. New dragon fades in at center with element glow (400ms)
5. Result card: name, element, stats, stability tier badge

Click to skip — same pattern as egg hatch.

---

## 5. Persistence Changes

### 5.1 Updated Dragon Save Entry

```json
{
  "fire": {
    "level": 1, "xp": 0, "owned": true, "shiny": false,
    "fusedBaseStats": null
  }
}
```

When `fusedBaseStats` is not null, `calculateStatsForLevel` uses those instead of default base stats from gameData.

### 5.2 Migration

Existing saves without `fusedBaseStats`: default to `null`.

### 5.3 Fusion Save Operations

- Deduct 100 dataScraps
- Set both parent dragons to: `owned: false`, `level: 1`, `xp: 0`, `shiny: false`, `fusedBaseStats: null`
- Set offspring dragon to: `owned: true`, `level: 1` (or 50 for Stage IV), `xp: 0`, `shiny: (parentA.shiny || parentB.shiny)`, `fusedBaseStats: { hp, atk, def, spd }`

---

## 6. SFX Additions

| Sound | Description |
|---|---|
| `statusApply` | Short buzzing/crackling tone |
| `statusTick` | Quiet sizzle for DOT damage |
| `statusExpire` | Soft ascending chime |
| `fusionMerge` | Two ascending tones converging |
| `fusionBurst` | Heavy impact + sparkle |
| `fusionReveal` | Triumphant chord |

---

## 7. New Files

| File | Responsibility |
|---|---|
| `src/fusionEngine.js` | Fusion logic: alchemy table, stat calc, stability |
| `src/fusionEngine.test.js` | Tests for fusion engine |
| `src/FusionScreen.jsx` | Fusion UI: parent selection, preview, animation |

## Modified Files

| File | Changes |
|---|---|
| `src/battleEngine.js` | Status effect processing in turn resolution |
| `src/battleEngine.test.js` | Status effect tests |
| `src/gameData.js` | Add canApplyStatus to moves, status config, fusion alchemy table, fusion cost |
| `src/BattleScreen.jsx` | Status display below HP bars, status text flashes |
| `src/NavBar.jsx` | Conditional FUSION tab |
| `src/App.jsx` | Add fusion screen routing |
| `src/persistence.js` | Migration for fusedBaseStats, fusion save operations |
| `src/soundEngine.js` | Add status and fusion SFX |
| `src/styles.css` | Status indicator styles, fusion screen styles |

---

## Out of Scope

- Traveler's Journal / Bestiary
- Attack VFX projectile sprites
- More NPCs
- Status effect immunity by element
