# Dragon Forge: Singularity Phase 3 — Boss Rush & Epilogue

## Overview

The climax of the Singularity narrative arc. At stage 5, a "SINGULARITY" tab appears in the NavBar leading to a dedicated boss rush screen. Three gatekeeper bosses are fought in sequence, each unlocking the next. After all three, the player faces The Singularity itself — a multi-phase final boss that shifts elements mid-fight. Beating it triggers an epilogue with Felix and marks the game as completed.

---

## 1. Singularity Bosses

### 1.1 Gatekeepers

Three bosses fought in linear order. Each uses existing elemental moves with corrupted stats.

| ID | Name | Element | Level | HP | ATK | DEF | SPD | Moves | Difficulty |
|---|---|---|---|---|---|---|---|---|---|
| `data_corruption` | Data Corruption | fire | 15 | 140 | 30 | 18 | 16 | `magma_breath`, `flame_wall` | Singularity |
| `memory_leak` | Memory Leak | ice | 20 | 120 | 26 | 24 | 22 | `frost_bite`, `blizzard` | Singularity |
| `stack_overflow` | Stack Overflow | storm | 25 | 100 | 34 | 14 | 30 | `lightning_strike`, `thunder_clap` | Singularity |

- Data Corruption: high HP tank, slow. Tests endurance.
- Memory Leak: balanced, good defense. Tests sustained damage.
- Stack Overflow: glass cannon speedster. Tests burst survival.

### 1.2 The Singularity (Final Boss — 3 Phases)

One continuous fight. When a phase's HP reaches 0, the boss shifts to the next phase. Player dragon keeps current HP between phases (no healing).

| Phase | Element | HP | ATK | DEF | SPD | Moves |
|---|---|---|---|---|---|---|
| 1 — Ignition | fire | 150 | 32 | 20 | 18 | `magma_breath`, `flame_wall` |
| 2 — Surge | storm | 130 | 36 | 16 | 26 | `lightning_strike`, `thunder_clap` |
| 3 — Void Collapse | void | 100 | 40 | 12 | 32 | `void_rift`, `null_reflect` |

Phase 3 is the hardest — highest ATK and SPD with the reflect mechanic. If the player dies at any phase, the entire fight restarts from Phase 1.

### 1.3 Sprites

No new sprite assets. Reuse existing NPC sprites with corruption CSS filters:

| Boss | Base Sprite | CSS Filter |
|---|---|---|
| Data Corruption | `firewall_sentinel_sprites.png` | `saturate(1.5) hue-rotate(15deg) contrast(1.2)` |
| Memory Leak | `bit_wraith_sprites.png` | `saturate(1.5) hue-rotate(-30deg) contrast(1.2)` |
| Stack Overflow | `glitch_hydra_sprites.png` | `saturate(1.5) hue-rotate(30deg) contrast(1.2)` |
| The Singularity | `recursive_golem_sprites.png` | Phase 1: `saturate(2) hue-rotate(15deg) contrast(1.3)`, Phase 2: `saturate(2) hue-rotate(60deg) contrast(1.3)`, Phase 3: `saturate(2) hue-rotate(180deg) contrast(1.5)` |

Attack sprites use the corresponding base NPC's attack sprite with the same filter.

### 1.4 Arena

All Singularity fights use the shadow arena with: `filter: grayscale(0.5) hue-rotate(330deg) contrast(1.3)` — red-tinted corrupted void.

### 1.5 Felix Quotes

| Boss | Quote |
|---|---|
| Data Corruption | "It's eating through our data layers. Fire with fire — you'll need a dragon that can take the heat." |
| Memory Leak | "This thing absorbs and never releases. It'll freeze you solid if you let it accumulate." |
| Stack Overflow | "Infinite recursion manifested as pure electricity. It's fast. Faster than anything we've faced." |
| The Singularity | "This is it. The source of everything. It will adapt. It will learn. Do not let it win." |

### 1.6 Rewards

| Boss | XP | DataScraps |
|---|---|---|
| Data Corruption | 100 | 200 |
| Memory Leak | 150 | 300 |
| Stack Overflow | 200 | 400 |
| The Singularity | 500 | 1000 |

---

## 2. Singularity Screen

### 2.1 Layout

Split view similar to BattleSelect:

**Left panel (40%):** Vertical list of 4 boss cards in order:
- Each card shows: boss name, element icon, difficulty tag, status (LOCKED / AVAILABLE / DEFEATED)
- Locked bosses: dimmed with "LOCKED" text overlay
- Defeated bosses: green checkmark, still clickable for re-fight
- Available (next in sequence): highlighted border, pulsing glow
- Click to select

**Right panel (60%):** Selected boss detail:
- NPC sprite with corruption filter (animated idle)
- Boss name, element, level
- Stats: HP, ATK, DEF, SPD
- Felix warning quote in italic
- For The Singularity: show "3 PHASES" indicator

**Bottom:** "ENGAGE" button — only enabled when an available/defeated boss is selected.

### 2.2 Navigation

- "SINGULARITY" tab in NavBar, visible only at stage 5
- Styled with red text color and corruption border pulse
- Positioned after JOURNAL and before BATTLES

---

## 3. Multi-Phase Final Boss

### 3.1 Battle Config

SingularityScreen passes a `phases` array when starting The Singularity fight:

```js
{
  dragonId: selectedDragon,
  npcId: 'the_singularity',
  phases: [
    { name: 'The Singularity — Ignition', element: 'fire', stats: { hp: 150, atk: 32, def: 20, spd: 18 }, moveKeys: ['magma_breath', 'flame_wall'], spriteFilter: '...' },
    { name: 'The Singularity — Surge', element: 'storm', stats: { hp: 130, atk: 36, def: 16, spd: 26 }, moveKeys: ['lightning_strike', 'thunder_clap'], spriteFilter: '...' },
    { name: 'The Singularity — Void Collapse', element: 'void', stats: { hp: 100, atk: 40, def: 12, spd: 32 }, moveKeys: ['void_rift', 'null_reflect'], spriteFilter: '...' },
  ],
  isSingularity: true,
}
```

For gatekeeper fights, no `phases` array — standard single-phase battle.

### 3.2 Phase Shift in BattleScreen

When NPC HP reaches 0 in `handleMoveSelect`:
1. Check if `phases` exist and there are remaining phases
2. If yes: dispatch `PHASE_SHIFT` action to reducer
   - Brief animation: 1s screen flash + glitch (reuse corruption effects)
   - Update NPC: name, element, stats, HP (refill), moves
   - Increment phase counter
   - Resume battle — player keeps current HP
3. If no more phases: normal victory flow

New reducer action `PHASE_SHIFT`:
```js
case 'PHASE_SHIFT':
  return {
    ...state,
    npc: { ...state.npc, ...action.phaseData },
    npcHp: action.phaseData.stats.hp,
    npcMaxHp: action.phaseData.stats.hp,
    npcStatus: null,
    phase: PHASES.PLAYER_TURN,
    currentPhase: (state.currentPhase || 0) + 1,
  };
```

### 3.3 Phase Indicator

During multi-phase fight, show a small "PHASE 1/3" indicator in the top bar next to the NPC name. Updates on each shift.

---

## 4. Victory & Epilogue

### 4.1 Gatekeeper Victory

Normal victory flow — XP award, DataScraps, "CONTINUE" button returns to SingularityScreen. Save progress via `recordSingularityDefeat(bossId)`.

### 4.2 Final Boss Victory (Epilogue)

Special overlay replacing the normal victory screen:

- Dark background with CRT effect
- Felix portrait (clean — no corruption filter)
- Typewriter dialogue sequence:
  - "You did it. The Singularity is contained."
  - "The Matrix is stabilizing. I can feel it."
  - "You've saved every dragon in the Forge."
  - "But between you and me... I don't think it's gone forever."
  - "Stay sharp, Dragon Forger."
- XP + DataScraps award shown
- "RETURN TO THE FORGE" button → returns to Hatchery

### 4.3 Post-Completion State

- Save `singularityComplete: true` to persistence
- Corruption effects reduce: `singularityProgress.js` returns stage 3 instead of 5 when `singularityComplete` is true (Matrix stabilized but scarred)
- Singularity tab stays visible — all bosses show as DEFEATED with option to re-fight
- Re-fighting still awards XP/DataScraps (farmable)
- Re-beating The Singularity doesn't replay the epilogue (just normal victory)

---

## 5. Persistence

Add to save structure:

```js
singularityProgress: {
  defeated: [],        // array of gatekeeper IDs beaten
  finalBossPhase: 0,   // 0=not started, 1-3=died at phase, 4=completed
},
singularityComplete: false,
```

New functions:
- `recordSingularityDefeat(bossId)` — adds to defeated array
- `updateFinalBossPhase(phase)` — updates phase tracker
- `markSingularityComplete()` — sets singularityComplete to true, finalBossPhase to 4

Migration: add both fields if missing.

---

## 6. Singularity Progress Update

Update `getSingularityStage` in `singularityProgress.js`:
- If `save.singularityComplete` is true, return 3 instead of 5 (reduced corruption)
- All other stage checks remain the same

---

## 7. File Changes

| File | Action | Changes |
|---|---|---|
| `src/singularityBosses.js` | Create | Boss definitions, phase configs, Felix quotes, unlock logic |
| `src/SingularityScreen.jsx` | Create | Boss rush screen — boss list, detail, dragon picker, engage |
| `src/persistence.js` | Modify | singularityProgress in save, migration, defeat/phase/complete functions |
| `src/singularityProgress.js` | Modify | Return stage 3 when singularityComplete |
| `src/BattleScreen.jsx` | Modify | Multi-phase support (PHASE_SHIFT reducer), epilogue overlay |
| `src/NavBar.jsx` | Modify | SINGULARITY tab at stage 5 |
| `src/App.jsx` | Modify | Singularity screen routing, pass phase config to BattleScreen |
| `src/styles.css` | Modify | Singularity screen styles, boss cards, corruption NPC filters, phase shift animation, epilogue overlay |

---

## 8. Out of Scope

- New boss sprite art (reuse existing with CSS filters)
- New arena art (reuse shadow arena with filter)
- New music tracks (reuse existing battle music)
- Difficulty scaling based on player level
- Boss-specific VFX (reuse existing elemental VFX)
- New Game+ or prestige system
