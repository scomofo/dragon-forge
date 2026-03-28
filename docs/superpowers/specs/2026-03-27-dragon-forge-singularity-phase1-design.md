# Dragon Forge: Singularity Phase 1 — Global State, Progression & Felix Dialogue

## Overview

Three interconnected changes: (1) lift save state into App.jsx so all screens share fresh data, (2) add a Singularity progression system that computes narrative stage from player achievements, and (3) a Felix dialogue system that updates terminal broadcasts and nav bar ticker messages as the Singularity approaches. This is the narrative backbone for Phases 2 (corruption effects) and 3 (boss rush).

---

## 1. Global State Refactor

### 1.1 Problem

Every screen calls `loadSave()` independently. When one screen mutates state (hatch a dragon, win a battle), other screens may show stale data until they remount.

### 1.2 Solution

Lift save state into `App.jsx` via `useState`:

```js
const [save, setSave] = useState(() => loadSave());
function refreshSave() { setSave(loadSave()); }
```

Pass `save` and `refreshSave` as props to all screens. Screens read from `save` prop instead of calling `loadSave()`. After any persistence mutation (unlockDragon, saveDragonProgress, claimMilestone, etc.), the screen calls `refreshSave()` to sync the App-level state.

### 1.3 Screen Prop Changes

Every screen that currently calls `loadSave()` switches to using the `save` prop:

| Screen | Current | New Props |
|---|---|---|
| HatcheryScreen | `loadSave()` internally | `save`, `refreshSave` |
| BattleSelectScreen | `loadSave()` internally | `save`, `refreshSave` |
| BattleScreen | `loadSave()` in initBattle | `save`, `refreshSave` |
| FusionScreen | `loadSave()` internally | `save`, `refreshSave` |
| JournalScreen | `loadSave()` internally | `save`, `refreshSave` |
| NavBar | `loadSave()` internally | `save` |
| TitleScreen | No save access | `save` (for Felix dialogue stage) |

Screens keep their own local UI state (animation phases, selections, etc.). Only the save data is lifted.

### 1.4 What Doesn't Change

- `persistence.js` functions remain the mutation layer — they still write to localStorage
- BattleScreen's `useReducer` for battle state stays (that's combat state, not save state)
- No new state library or reducer pattern for the save

---

## 2. Singularity Progression

### 2.1 Stage Definitions

The Singularity stage is **computed dynamically** from the current save state — no separate progress field stored. Highest matching stage wins.

| Stage | Name | Trigger | Check |
|---|---|---|---|
| 0 | Dormant | Always | Default |
| 1 | Anomaly Detected | Own 2+ dragons | `ownedCount >= 2` |
| 2 | Signal Growing | Own 4+ dragons | `ownedCount >= 4` |
| 3 | Matrix Unstable | Own all 6+ dragons | `ownedCount >= 6` |
| 4 | Breach Imminent | Any dragon level 50+ | `anyDragon.level >= 50` |
| 5 | The Singularity | All 4 base NPCs defeated | `defeatedNpcs` includes all 4 NPC ids |

Owned count uses base 6 elements (fire, ice, storm, stone, venom, shadow). Void is exotic/bonus and not required for progression.

### 2.2 Module: `src/singularityProgress.js`

```js
export const STAGES = [
  { stage: 0, name: 'Dormant', description: 'The Elemental Matrix is stable.' },
  { stage: 1, name: 'Anomaly Detected', description: 'Strange readings in the Matrix.' },
  { stage: 2, name: 'Signal Growing', description: 'Something is feeding on elemental energy.' },
  { stage: 3, name: 'Matrix Unstable', description: 'The Matrix is destabilizing.' },
  { stage: 4, name: 'Breach Imminent', description: 'Defenses are failing.' },
  { stage: 5, name: 'The Singularity', description: 'The Singularity has breached the Matrix.' },
];

export function getSingularityStage(save) → number (0-5)
```

The function checks conditions in reverse order (5 down to 0) and returns the first match.

### 2.3 Persistence: defeatedNpcs

Add `defeatedNpcs: []` to save structure. Array of NPC ids that the player has beaten at least once.

New function `recordNpcDefeat(npcId)`:
- Loads save, adds npcId to `defeatedNpcs` if not already present, writes save.

Migration: `if (save.defeatedNpcs === undefined) save.defeatedNpcs = [];`

The 4 base NPC ids for Stage 5 check: `firewall_sentinel`, `bit_wraith`, `glitch_hydra`, `recursive_golem`.

---

## 3. Felix Dialogue System

### 3.1 Module: `src/felixDialogue.js`

Two exports: `getTerminalDialogue(stage)` and `getTickerMessage(stage)`.

### 3.2 Terminal Dialogue (TitleScreen)

Felix's "Emergency Broadcast" changes per stage:

| Stage | Dialogue |
|---|---|
| 0 | "Welcome to the Dragon Forge. I'm Professor Felix. We have work to do — the Elemental Matrix needs new guardians." |
| 1 | "Interesting... I'm picking up anomalous readings in the Matrix. Probably nothing. Keep forging." |
| 2 | "The anomalies are getting stronger. Something is feeding on the elemental energy. We need more dragons, fast." |
| 3 | "All six elements are online, but the Matrix is destabilizing. I'm detecting a pattern in the noise — it's not random. It's intelligent." |
| 4 | "An Elder dragon... magnificent. But its power is attracting something. The readings are off the charts. Brace yourself." |
| 5 | "It's here. The Singularity has breached the Matrix. Everything I've built, everything we've forged — it all comes down to this." |

### 3.3 Nav Bar Ticker

A single-line status message displayed in the NavBar, styled as a dim monospace label. Updates per stage:

| Stage | Ticker |
|---|---|
| 0 | `SYSTEM STATUS: NOMINAL` |
| 1 | `ANOMALY DETECTED — SECTOR 7` |
| 2 | `WARNING: ELEMENTAL FLUX RISING` |
| 3 | `ALERT: MATRIX INTEGRITY 62%` |
| 4 | `CRITICAL: MATRIX INTEGRITY 23%` |
| 5 | `[BREACH DETECTED] — ALL SECTORS COMPROMISED` |

### 3.4 Ticker Styling

- Font-size: 7px, color varies by stage (green at 0-1, yellow at 2-3, red at 4-5)
- Positioned in the NavBar between the tabs and the scraps/sound controls
- At stages 4-5, add a subtle CSS blink animation for urgency

---

## 4. TitleScreen Update

Replace the hardcoded Felix typewriter text with `getTerminalDialogue(stage)`. The TitleScreen receives `save` as a prop, computes the stage via `getSingularityStage(save)`, and passes the dialogue to the typewriter.

The rest of the TitleScreen stays the same — Felix portrait, CRT overlay, "ENTER THE FORGE" button.

---

## 5. BattleScreen — Record NPC Defeats

On victory, call `recordNpcDefeat(npcId)` then `refreshSave()`. This is a one-line addition to the existing victory handler.

---

## 6. File Changes

| File | Action | Changes |
|---|---|---|
| `src/singularityProgress.js` | Create | Stage definitions, `getSingularityStage(save)` |
| `src/felixDialogue.js` | Create | Terminal dialogue, ticker messages per stage |
| `src/persistence.js` | Modify | Add `defeatedNpcs: []`, migration, `recordNpcDefeat()` |
| `src/App.jsx` | Modify | Lift save state, pass `save` + `refreshSave` to all screens |
| `src/TitleScreen.jsx` | Modify | Accept `save` prop, use Felix dialogue based on stage |
| `src/NavBar.jsx` | Modify | Accept `save` prop, display ticker message |
| `src/HatcheryScreen.jsx` | Modify | Use `save` prop, call `refreshSave` after mutations |
| `src/BattleScreen.jsx` | Modify | Accept `save`/`refreshSave`, record NPC defeat on win |
| `src/BattleSelectScreen.jsx` | Modify | Use `save` prop |
| `src/FusionScreen.jsx` | Modify | Use `save` prop, call `refreshSave` after fusion |
| `src/JournalScreen.jsx` | Modify | Use `save` prop, call `refreshSave` after milestone claims |
| `src/styles.css` | Modify | Ticker message styles, stage-colored ticker |

---

## 7. Out of Scope (Phase 2 & 3)

- Visual corruption/glitch effects on screens
- Sound distortion
- Felix portrait glitching
- Singularity NPC bosses
- Corrupted arena
- Multi-phase final boss
- Victory/epilogue screen
- Campaign mode gating
