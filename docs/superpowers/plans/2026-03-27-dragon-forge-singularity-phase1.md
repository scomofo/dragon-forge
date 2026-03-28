# Singularity Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lift save state into App.jsx for shared data across screens, add a Singularity progression tracker that computes narrative stage from player achievements, and wire Felix dialogue + nav bar ticker messages that evolve as the Singularity approaches.

**Architecture:** Save state is lifted to App.jsx via `useState` and passed as `save`/`refreshSave` props to all screens. A new `singularityProgress.js` module computes the current stage (0-5) from save data. A new `felixDialogue.js` module provides stage-specific terminal dialogue and ticker messages. TitleScreen uses stage-aware Felix dialogue. NavBar shows a ticker message.

**Tech Stack:** React 18, localStorage persistence, CSS

---

## File Map

| File | Responsibility |
|---|---|
| `src/singularityProgress.js` | Create — stage definitions, `getSingularityStage(save)` |
| `src/felixDialogue.js` | Create — terminal dialogue and ticker messages per stage |
| `src/persistence.js` | Modify — add `defeatedNpcs`, migration, `recordNpcDefeat()` |
| `src/App.jsx` | Modify — lift save state, pass `save`/`refreshSave` to all screens |
| `src/NavBar.jsx` | Modify — accept `save` prop, display ticker |
| `src/TitleScreen.jsx` | Modify — accept `save` prop, use stage-aware Felix dialogue |
| `src/HatcheryScreen.jsx` | Modify — use `save`/`refreshSave` props |
| `src/BattleSelectScreen.jsx` | Modify — use `save` prop |
| `src/BattleScreen.jsx` | Modify — use `save`/`refreshSave` props, record NPC defeat |
| `src/FusionScreen.jsx` | Modify — use `save`/`refreshSave` props |
| `src/JournalScreen.jsx` | Modify — use `save`/`refreshSave` props |
| `src/styles.css` | Modify — ticker styles |

---

## Task 1: Singularity Progress Module

**Files:**
- Create: `src/singularityProgress.js`

- [ ] **Step 1: Create src/singularityProgress.js**

```js
const BASE_ELEMENTS = ['fire', 'ice', 'storm', 'stone', 'venom', 'shadow'];
const BASE_NPC_IDS = ['firewall_sentinel', 'bit_wraith', 'glitch_hydra', 'recursive_golem'];

export const STAGES = [
  { stage: 0, name: 'Dormant', description: 'The Elemental Matrix is stable.' },
  { stage: 1, name: 'Anomaly Detected', description: 'Strange readings in the Matrix.' },
  { stage: 2, name: 'Signal Growing', description: 'Something is feeding on elemental energy.' },
  { stage: 3, name: 'Matrix Unstable', description: 'The Matrix is destabilizing.' },
  { stage: 4, name: 'Breach Imminent', description: 'Defenses are failing.' },
  { stage: 5, name: 'The Singularity', description: 'The Singularity has breached the Matrix.' },
];

export function getSingularityStage(save) {
  const ownedCount = BASE_ELEMENTS.filter(el => save.dragons[el]?.owned).length;
  const hasElder = Object.values(save.dragons).some(d => d.owned && d.level >= 50);
  const defeatedNpcs = save.defeatedNpcs || [];
  const allNpcsDefeated = BASE_NPC_IDS.every(id => defeatedNpcs.includes(id));

  if (allNpcsDefeated) return 5;
  if (hasElder) return 4;
  if (ownedCount >= 6) return 3;
  if (ownedCount >= 4) return 2;
  if (ownedCount >= 2) return 1;
  return 0;
}
```

- [ ] **Step 2: Commit**

```bash
git add src/singularityProgress.js
git commit -m "feat: singularity progression module — stage 0-5 from save state

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Felix Dialogue Module

**Files:**
- Create: `src/felixDialogue.js`

- [ ] **Step 1: Create src/felixDialogue.js**

```js
const TERMINAL_DIALOGUE = {
  0: [
    '"Welcome to the Dragon Forge.',
    ' I\'m Professor Felix.',
    ' We have work to do — the Elemental',
    ' Matrix needs new guardians."',
  ],
  1: [
    '"Interesting... I\'m picking up anomalous',
    ' readings in the Matrix.',
    ' Probably nothing. Keep forging."',
  ],
  2: [
    '"The anomalies are getting stronger.',
    ' Something is feeding on the elemental',
    ' energy. We need more dragons, fast."',
  ],
  3: [
    '"All six elements are online, but the',
    ' Matrix is destabilizing. I\'m detecting',
    ' a pattern in the noise — it\'s not',
    ' random. It\'s intelligent."',
  ],
  4: [
    '"An Elder dragon... magnificent.',
    ' But its power is attracting something.',
    ' The readings are off the charts.',
    ' Brace yourself."',
  ],
  5: [
    '"It\'s here. The Singularity has breached',
    ' the Matrix. Everything I\'ve built,',
    ' everything we\'ve forged — it all',
    ' comes down to this."',
  ],
};

const TICKER_MESSAGES = {
  0: 'SYSTEM STATUS: NOMINAL',
  1: 'ANOMALY DETECTED \u2014 SECTOR 7',
  2: 'WARNING: ELEMENTAL FLUX RISING',
  3: 'ALERT: MATRIX INTEGRITY 62%',
  4: 'CRITICAL: MATRIX INTEGRITY 23%',
  5: '[BREACH DETECTED] \u2014 ALL SECTORS COMPROMISED',
};

export function getTerminalDialogue(stage) {
  return TERMINAL_DIALOGUE[stage] || TERMINAL_DIALOGUE[0];
}

export function getTickerMessage(stage) {
  return TICKER_MESSAGES[stage] || TICKER_MESSAGES[0];
}
```

- [ ] **Step 2: Commit**

```bash
git add src/felixDialogue.js
git commit -m "feat: Felix dialogue module — terminal broadcasts and ticker per stage

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Persistence — defeatedNpcs

**Files:**
- Modify: `src/persistence.js`

- [ ] **Step 1: Add defeatedNpcs to DEFAULT_SAVE**

In `src/persistence.js`, add after `milestones: [],` in DEFAULT_SAVE:

```js
  defeatedNpcs: [],
```

- [ ] **Step 2: Add migration**

In `migrateSave`, add after the void dragon migration:

```js
  if (save.defeatedNpcs === undefined) save.defeatedNpcs = [];
```

- [ ] **Step 3: Add recordNpcDefeat function**

Add after the `claimMilestone` function:

```js
export function recordNpcDefeat(npcId) {
  const save = loadSave();
  if (!save.defeatedNpcs.includes(npcId)) {
    save.defeatedNpcs.push(npcId);
    writeSave(save);
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add src/persistence.js
git commit -m "feat: defeatedNpcs persistence — track beaten NPCs for Singularity progression

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Ticker CSS

**Files:**
- Modify: `src/styles.css`

- [ ] **Step 1: Add ticker styles to styles.css**

Append at the end of `src/styles.css`:

```css
/* === SINGULARITY TICKER === */

.nav-ticker {
  font-size: 7px;
  line-height: 1.6;
  letter-spacing: 1px;
  padding: 0 8px;
  white-space: nowrap;
  font-family: 'Press Start 2P', monospace;
}

.nav-ticker.stage-0,
.nav-ticker.stage-1 {
  color: #44cc44;
}

.nav-ticker.stage-2,
.nav-ticker.stage-3 {
  color: #cccc44;
}

.nav-ticker.stage-4,
.nav-ticker.stage-5 {
  color: #cc4444;
}

.nav-ticker.stage-4,
.nav-ticker.stage-5 {
  animation: tickerBlink 1.5s ease-in-out infinite;
}

@keyframes tickerBlink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.4; }
}
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

- [ ] **Step 3: Commit**

```bash
git add src/styles.css
git commit -m "feat: Singularity ticker CSS — stage-colored with blink at high stages

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: App.jsx — Lift Save State + Pass Props

**Files:**
- Modify: `src/App.jsx`

This is the core refactor. App.jsx needs to manage save state and pass it to all screens.

- [ ] **Step 1: Add imports**

At the top of `src/App.jsx`, add:

```js
import { loadSave } from './persistence';
import JournalScreen from './JournalScreen';
```

Note: `JournalScreen` is already imported. Just add the `loadSave` import if not already present.

- [ ] **Step 2: Add save state to App**

Inside the `App` function, after the existing `useState` calls, add:

```js
  const [save, setSave] = useState(() => loadSave());
  const refreshSave = () => setSave(loadSave());
```

- [ ] **Step 3: Update all screen renders to pass save/refreshSave**

Replace the JSX return in `App.jsx` with:

```jsx
  return (
    <div className="app">
      {screen === SCREENS.TITLE && (
        <TitleScreen onStart={handleStartGame} save={save} />
      )}
      {screen === SCREENS.HATCHERY && (
        <HatcheryScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
      )}
      {screen === SCREENS.FUSION && (
        <FusionScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
      )}
      {screen === SCREENS.JOURNAL && (
        <JournalScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
      )}
      {screen === SCREENS.BATTLE_SELECT && (
        <BattleSelectScreen onBeginBattle={handleBeginBattle} onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
      )}
      {screen === SCREENS.BATTLE && battleConfig && (
        <BattleScreen
          dragonId={battleConfig.dragonId}
          npcId={battleConfig.npcId}
          onBattleEnd={handleBattleEnd}
          save={save}
          refreshSave={refreshSave}
        />
      )}
    </div>
  );
```

- [ ] **Step 4: Update handleNavigate to refresh save on screen switch**

Add `refreshSave()` at the start of `handleNavigate` so screens always get fresh data on navigation:

```js
  function handleNavigate(target) {
    refreshSave();
    playSound('navSwitch');
```

Also add it to `handleBattleEnd`:

```js
  function handleBattleEnd() {
    refreshSave();
    playMusic('select');
```

- [ ] **Step 5: Pass save to NavBar in all screens that render it**

This is handled by updating each screen in subsequent tasks — NavBar will receive `save` as a prop through the screens that render it.

- [ ] **Step 6: Verify build**

```bash
npm run build
```

Expected: Build succeeds. Screens still work because they accept but don't yet use the new props (existing `loadSave()` calls remain until later tasks remove them).

- [ ] **Step 7: Commit**

```bash
git add src/App.jsx
git commit -m "feat: lift save state into App.jsx — pass save/refreshSave to all screens

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: NavBar — Accept Save Prop + Ticker

**Files:**
- Modify: `src/NavBar.jsx`

- [ ] **Step 1: Update NavBar to accept save prop and show ticker**

Replace the entire `src/NavBar.jsx` with:

```jsx
import { getStageForLevel } from './battleEngine';
import { getSingularityStage } from './singularityProgress';
import { getTickerMessage } from './felixDialogue';
import SoundToggle from './SoundToggle';

export default function NavBar({ activeScreen, onNavigate, save }) {
  const ownedDragons = Object.values(save.dragons).filter(d => d.owned);
  const hasEligible = ownedDragons.some(d => d.level >= 10);
  const showFusion = ownedDragons.length >= 2 && hasEligible;

  const stage = getSingularityStage(save);
  const ticker = getTickerMessage(stage);

  return (
    <div className="nav-bar">
      <div className="nav-tabs">
        <button
          className={`nav-tab ${activeScreen === 'hatchery' ? 'active' : ''}`}
          onClick={() => onNavigate('hatchery')}
        >
          HATCHERY
        </button>
        {showFusion && (
          <button
            className={`nav-tab ${activeScreen === 'fusion' ? 'active' : ''}`}
            onClick={() => onNavigate('fusion')}
          >
            FUSION
          </button>
        )}
        <button
          className={`nav-tab ${activeScreen === 'journal' ? 'active' : ''}`}
          onClick={() => onNavigate('journal')}
        >
          JOURNAL
        </button>
        <button
          className={`nav-tab ${activeScreen === 'battleSelect' ? 'active' : ''}`}
          onClick={() => onNavigate('battleSelect')}
        >
          BATTLES
        </button>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <div className={`nav-ticker stage-${stage}`}>{ticker}</div>
        <div className="nav-scraps">◆ {save.dataScraps}</div>
        <SoundToggle />
      </div>
    </div>
  );
}
```

Key changes: removed `loadSave` import, accept `save` prop, added singularity stage + ticker display.

- [ ] **Step 2: Verify build**

```bash
npm run build
```

- [ ] **Step 3: Commit**

```bash
git add src/NavBar.jsx
git commit -m "feat: NavBar accepts save prop + Singularity ticker message

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: TitleScreen — Stage-Aware Felix Dialogue

**Files:**
- Modify: `src/TitleScreen.jsx`

- [ ] **Step 1: Update TitleScreen to use stage-based dialogue**

Add imports at the top of `src/TitleScreen.jsx`:

```js
import { getSingularityStage } from './singularityProgress';
import { getTerminalDialogue } from './felixDialogue';
```

Update the component signature to accept `save`:

```js
export default function TitleScreen({ onStart, save }) {
```

Replace the hardcoded `FELIX_LINES` constant (lines 14-23) with a dynamic version. Change the constant to be computed inside the component, after the `save` prop is available. Remove the `const FELIX_LINES = [...]` constant at the top of the file.

Inside the component function, after the useState declarations, add:

```js
  const stage = getSingularityStage(save);
  const felixDialogue = getTerminalDialogue(stage);
```

Then in `runBootSequence`, replace the loop that iterates over `FELIX_LINES` (around line 105):

```js
    for (const line of felixDialogue) {
```

And replace the skip fallback (around line 118):

```js
    if (skippedRef.current) {
      setFelixLines([...felixDialogue]);
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

- [ ] **Step 3: Commit**

```bash
git add src/TitleScreen.jsx
git commit -m "feat: TitleScreen uses stage-aware Felix dialogue from Singularity system

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Screen Migration — HatcheryScreen

**Files:**
- Modify: `src/HatcheryScreen.jsx`

- [ ] **Step 1: Update HatcheryScreen to use save/refreshSave props**

Update the component signature:

```js
export default function HatcheryScreen({ onNavigate, save, refreshSave }) {
```

Remove the internal `loadSave` import — keep `writeSave` since it's used directly for pull operations. Remove these lines:

```js
const [save, setSave] = useState(() => loadSave());
```
```js
const refreshSave = () => setSave(loadSave());
```

Replace any internal `loadSave()` calls with reading from the `save` prop. However, HatcheryScreen mutates save during pulls (lines 79, 102) — these need fresh reads. Keep `loadSave()` for mutation operations but use props for rendering.

Actually, the simplest approach: keep the internal `loadSave` import for mutation reads, but replace the state initialization and refresh:

- Change `useState(() => loadSave())` to use the prop: remove the local save useState entirely and use `save` from props
- Replace internal `refreshSave()` calls with `props.refreshSave()`
- Keep `loadSave()` calls inside pull handlers (lines 79, 102) since they need the very latest save for mutation

Update NavBar render to pass save:

```jsx
<NavBar activeScreen="hatchery" onNavigate={onNavigate} save={save} />
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

- [ ] **Step 3: Commit**

```bash
git add src/HatcheryScreen.jsx
git commit -m "refactor: HatcheryScreen uses save/refreshSave props + passes save to NavBar

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: Screen Migration — BattleSelectScreen

**Files:**
- Modify: `src/BattleSelectScreen.jsx`

- [ ] **Step 1: Update BattleSelectScreen to use save prop**

Update the component signature:

```js
export default function BattleSelectScreen({ onBeginBattle, onNavigate, save, refreshSave }) {
```

Remove the `loadSave` import from persistence.js. Remove the internal `const save = loadSave();` call. Use the `save` prop directly.

Update NavBar render:

```jsx
<NavBar activeScreen="battleSelect" onNavigate={onNavigate} save={save} />
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

- [ ] **Step 3: Commit**

```bash
git add src/BattleSelectScreen.jsx
git commit -m "refactor: BattleSelectScreen uses save prop + passes save to NavBar

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 10: Screen Migration — BattleScreen + NPC Defeat Tracking

**Files:**
- Modify: `src/BattleScreen.jsx`

- [ ] **Step 1: Update BattleScreen to accept save/refreshSave and record NPC defeats**

Add `recordNpcDefeat` to the persistence imports:

```js
import { loadSave, saveDragonProgress, addScraps, recordNpcDefeat } from './persistence';
```

Update the component signature:

```js
export default function BattleScreen({ dragonId, npcId, onBattleEnd, save, refreshSave }) {
```

In the `initBattle` function, replace `const save = loadSave();` with using the prop. Since `initBattle` is called from `useReducer` init, and it needs save data, pass it through:

Change `useReducer(battleReducer, null, () => initBattle(dragonId, npcId))` — the `initBattle` function currently calls `loadSave()` internally. Update it to accept save as a parameter:

```js
function initBattle(dragonId, npcId, save) {
```

Remove the `const save = loadSave();` line inside initBattle. Then update the useReducer call:

```js
const [state, dispatch] = useReducer(battleReducer, null, () => initBattle(dragonId, npcId, save));
```

In the victory handler (inside `handleMoveSelect`, after dispatching SET_VICTORY), add NPC defeat recording:

Find where `saveDragonProgress` is called after victory. After that block, add:

```js
        recordNpcDefeat(npcId);
        refreshSave();
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

- [ ] **Step 3: Commit**

```bash
git add src/BattleScreen.jsx
git commit -m "refactor: BattleScreen uses save prop + records NPC defeats on victory

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 11: Screen Migration — FusionScreen + JournalScreen

**Files:**
- Modify: `src/FusionScreen.jsx`
- Modify: `src/JournalScreen.jsx`

- [ ] **Step 1: Update FusionScreen**

Update signature:

```js
export default function FusionScreen({ onNavigate, save, refreshSave }) {
```

Remove the internal `loadSave` import (keep `fuseDragons`). Remove:

```js
const [save, setSave] = useState(() => loadSave());
```
```js
const refreshSave = () => setSave(loadSave());
```

Use `save` from props for rendering. Keep `fuseDragons` calls for mutations, call `refreshSave()` from props after mutations.

Update NavBar:

```jsx
<NavBar activeScreen="fusion" onNavigate={onNavigate} save={save} />
```

- [ ] **Step 2: Update JournalScreen**

Update signature:

```js
export default function JournalScreen({ onNavigate, save, refreshSave }) {
```

Remove the internal `loadSave` import (keep `claimMilestone`). Remove:

```js
const [save, setSave] = useState(() => loadSave());
```

Use `save` from props. In the milestone check effect, replace internal `loadSave()` calls with `save` prop for the initial check. After claiming milestones, call `refreshSave()` from props.

Update the `selectedId` init to use `save` prop:

```js
const [selectedId, setSelectedId] = useState(() => {
  const firstOwned = ELEMENTS.find(el => save.dragons[el]?.owned);
  return firstOwned || 'fire';
});
```

Update NavBar:

```jsx
<NavBar activeScreen="journal" onNavigate={onNavigate} save={save} />
```

- [ ] **Step 3: Verify build and tests**

```bash
npm run build
npm test
```

- [ ] **Step 4: Commit**

```bash
git add src/FusionScreen.jsx src/JournalScreen.jsx
git commit -m "refactor: FusionScreen + JournalScreen use save/refreshSave props

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 12: Final Verification

- [ ] **Step 1: Run all tests**

```bash
npm test
```

Expected: All 70 tests pass.

- [ ] **Step 2: Run production build**

```bash
npm run build
```

Expected: Build succeeds.

- [ ] **Step 3: Manual playthrough**

```bash
npm run dev
```

Verify:
- Terminal screen shows Felix dialogue (stage 0 if fresh save)
- NavBar shows ticker "SYSTEM STATUS: NOMINAL" in green
- Hatch 2 dragons → ticker changes to "ANOMALY DETECTED — SECTOR 7"
- All screens show current data (no stale state on nav switch)
- DataScraps updates immediately when switching screens after earning
- Win a battle → NPC defeat recorded (check via console: `JSON.parse(localStorage.getItem('dragonforge_save')).defeatedNpcs`)
- Journal milestones still work
- Fusion still works
- Title screen dialogue changes if you restart at a higher stage

- [ ] **Step 4: Commit any tweaks**

```bash
git add -A
git commit -m "fix: Singularity Phase 1 polish after manual testing

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

Skip if no adjustments needed.
