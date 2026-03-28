# Traveler's Journal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a bestiary/collection screen with a split-view layout (dragon grid + detail dossier), 7 milestones with DataScraps rewards, and Felix lore quotes for each dragon.

**Architecture:** New JournalScreen component with split layout — left panel renders a 2x3 clickable dragon grid, right panel shows selected dragon's detail. Milestone logic lives in a separate `journalMilestones.js` module. Milestones are checked on screen load and auto-claimed if met. Persistence tracks claimed milestone IDs.

**Tech Stack:** React 18, CSS, localStorage persistence

---

## File Map

| File | Responsibility |
|---|---|
| `src/journalMilestones.js` | Milestone definitions array, `checkMilestones(save)` function |
| `src/gameData.js` | Add `dragonLore` export |
| `src/persistence.js` | Add `milestones: []` to save, migration, `claimMilestone()` |
| `src/JournalScreen.jsx` | Main journal screen — grid + detail split layout, milestone display |
| `src/NavBar.jsx` | Add JOURNAL tab |
| `src/App.jsx` | Add journal screen routing |
| `src/styles.css` | Journal layout, grid cards, detail panel, milestone badge styles |

---

## Task 1: Dragon Lore Data

**Files:**
- Modify: `src/gameData.js`

- [ ] **Step 1: Add dragonLore export to gameData.js**

Add the following after the `elementColors` export (around line 169) in `src/gameData.js`:

```js
// === DRAGON LORE ===
export const dragonLore = {
  fire:   "Forged from the planet's molten core. Its breath can melt through starship bulkheads — handle with extreme caution.",
  ice:    "Crystallized from subzero atmospheric anomalies. The temperature drops 30 degrees in its presence alone.",
  storm:  "Born from a feedback loop in the planet's electromagnetic field. Faster than anything I've ever recorded.",
  stone:  "Its hide is denser than compressed titanium. I once watched it walk through a collapsing mine without flinching.",
  venom:  "Secretes a neurotoxin that can dissolve organic matter in seconds. Keep it away from the lab samples.",
  shadow: "This one... shouldn't exist. It reads as a gap in the data — a hole where reality should be. Fascinating.",
};
```

- [ ] **Step 2: Commit**

```bash
git add src/gameData.js
git commit -m "feat: add dragonLore data for journal detail panel

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Persistence — Milestones Support

**Files:**
- Modify: `src/persistence.js`

- [ ] **Step 1: Add milestones to DEFAULT_SAVE**

In `src/persistence.js`, update the `DEFAULT_SAVE` object. Add after `pityCounter: 0,`:

```js
  milestones: [],
```

- [ ] **Step 2: Add migration for milestones**

In the `migrateSave` function, add after the `if (save.pityCounter === undefined)` line:

```js
  if (save.milestones === undefined) save.milestones = [];
```

- [ ] **Step 3: Add claimMilestone function**

Add the following function after the `upgradeDragonShiny` function (around line 97):

```js
export function claimMilestone(milestoneId, reward) {
  const save = loadSave();
  if (save.milestones.includes(milestoneId)) return false;
  save.milestones.push(milestoneId);
  save.dataScraps += reward;
  writeSave(save);
  return true;
}
```

- [ ] **Step 4: Commit**

```bash
git add src/persistence.js
git commit -m "feat: milestones persistence — save array, migration, claimMilestone

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Milestone Definitions & Check Logic

**Files:**
- Create: `src/journalMilestones.js`

- [ ] **Step 1: Create src/journalMilestones.js**

```js
export const MILESTONES = [
  {
    id: 'first_discovery',
    name: 'First Discovery',
    description: 'Discover any dragon',
    reward: 100,
    check: (save) => {
      const owned = Object.values(save.dragons).filter(d => d.owned).length;
      return { met: owned >= 1, progress: `${owned}/1` };
    },
  },
  {
    id: 'elemental_trio',
    name: 'Elemental Trio',
    description: 'Own 3 different dragons',
    reward: 200,
    check: (save) => {
      const owned = Object.values(save.dragons).filter(d => d.owned).length;
      return { met: owned >= 3, progress: `${owned}/3` };
    },
  },
  {
    id: 'full_roster',
    name: 'Full Roster',
    description: 'Own all 6 dragons',
    reward: 500,
    check: (save) => {
      const owned = Object.values(save.dragons).filter(d => d.owned).length;
      return { met: owned >= 6, progress: `${owned}/6` };
    },
  },
  {
    id: 'shiny_hunter',
    name: 'Shiny Hunter',
    description: 'Own a shiny dragon',
    reward: 300,
    check: (save) => {
      const shinies = Object.values(save.dragons).filter(d => d.owned && d.shiny).length;
      return { met: shinies >= 1, progress: `${shinies}/1` };
    },
  },
  {
    id: 'shiny_collector',
    name: 'Shiny Collector',
    description: 'Own 3 shiny dragons',
    reward: 1000,
    check: (save) => {
      const shinies = Object.values(save.dragons).filter(d => d.owned && d.shiny).length;
      return { met: shinies >= 3, progress: `${shinies}/3` };
    },
  },
  {
    id: 'elder_forged',
    name: 'Elder Forged',
    description: 'Reach Stage IV (Lv.50+)',
    reward: 250,
    check: (save) => {
      const hasElder = Object.values(save.dragons).some(d => d.owned && d.level >= 50);
      return { met: hasElder, progress: hasElder ? '1/1' : '0/1' };
    },
  },
  {
    id: 'fusion_master',
    name: 'Fusion Master',
    description: 'Complete a fusion',
    reward: 200,
    check: (save) => {
      const hasFused = Object.values(save.dragons).some(d => d.owned && d.fusedBaseStats);
      return { met: hasFused, progress: hasFused ? '1/1' : '0/1' };
    },
  },
];

export function checkMilestones(save) {
  return MILESTONES.map((milestone) => {
    const claimed = save.milestones.includes(milestone.id);
    const { met, progress } = milestone.check(save);
    return {
      ...milestone,
      claimed,
      newlyClaimed: !claimed && met,
      progress,
    };
  });
}
```

- [ ] **Step 2: Commit**

```bash
git add src/journalMilestones.js
git commit -m "feat: milestone definitions and checkMilestones logic

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Journal CSS

**Files:**
- Modify: `src/styles.css`

- [ ] **Step 1: Add journal CSS to styles.css**

Add the following at the end of `src/styles.css`:

```css
/* === JOURNAL SCREEN === */

.journal-layout {
  display: flex;
  gap: 12px;
  height: calc(100vh - 48px);
  padding: 12px;
  padding-top: 52px;
}

.journal-grid-panel {
  width: 40%;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.journal-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px;
  flex: 1;
}

.journal-card {
  background: #1a1a24;
  border: 1px solid #333;
  border-left: 3px solid #333;
  border-radius: 3px;
  padding: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s;
  gap: 4px;
}

.journal-card:hover {
  border-color: #555;
}

.journal-card.owned {
  cursor: pointer;
}

.journal-card.selected {
  box-shadow: 0 0 10px rgba(255, 102, 34, 0.3);
}

.journal-card-name {
  font-size: 8px;
  line-height: 1.6;
  text-align: center;
}

.journal-card-sub {
  font-size: 7px;
  color: #666;
  line-height: 1.6;
}

.journal-discovery-count {
  font-size: 8px;
  color: #666;
  text-align: center;
  padding: 4px 0;
}

/* Detail panel */
.journal-detail {
  width: 60%;
  background: #1a1a24;
  border: 1px solid #333;
  border-radius: 3px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  overflow-y: auto;
}

.journal-detail-name {
  font-size: 14px;
  line-height: 1.6;
}

.journal-detail-meta {
  font-size: 8px;
  color: #888;
  line-height: 1.8;
}

.journal-detail-stats {
  display: flex;
  gap: 16px;
  font-size: 8px;
  color: #aaa;
  line-height: 1.8;
}

.journal-detail-stats span {
  color: #e0e0e0;
}

.journal-detail-lore {
  font-size: 8px;
  color: #777;
  font-style: italic;
  line-height: 2;
  text-align: center;
  max-width: 400px;
  margin-top: 8px;
}

.journal-detail-fused {
  font-size: 7px;
  color: #aa66ff;
  border: 1px solid #aa66ff;
  padding: 2px 6px;
  border-radius: 2px;
}

/* Milestone badges */
.journal-milestones {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  justify-content: center;
  margin-top: 12px;
  width: 100%;
}

.milestone-badge {
  font-size: 7px;
  line-height: 1.6;
  padding: 3px 8px;
  border-radius: 3px;
  border: 1px solid #333;
  color: #555;
  background: #111118;
  text-align: center;
}

.milestone-badge.claimed {
  border-color: #44cc44;
  color: #44cc44;
}

.milestone-badge.newly-claimed {
  border-color: #ffcc00;
  color: #ffcc00;
  animation: milestonePulse 1s ease-out;
}

@keyframes milestonePulse {
  0% { box-shadow: 0 0 0px rgba(255, 204, 0, 0); transform: scale(1); }
  50% { box-shadow: 0 0 12px rgba(255, 204, 0, 0.6); transform: scale(1.1); }
  100% { box-shadow: 0 0 0px rgba(255, 204, 0, 0); transform: scale(1); }
}

.milestone-reward-flash {
  font-size: 9px;
  color: #ffcc00;
  animation: milestoneRewardFloat 1.5s ease-out forwards;
  position: absolute;
  pointer-events: none;
}

@keyframes milestoneRewardFloat {
  0% { opacity: 1; transform: translateY(0); }
  100% { opacity: 0; transform: translateY(-20px); }
}
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add src/styles.css
git commit -m "feat: journal CSS — grid, detail panel, milestone badge styles

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: JournalScreen Component

**Files:**
- Create: `src/JournalScreen.jsx`

- [ ] **Step 1: Create src/JournalScreen.jsx**

```jsx
import { useState, useEffect, useRef } from 'react';
import { playSound } from './soundEngine';
import { dragons, elementColors, dragonLore, ELEMENTS } from './gameData';
import { calculateStatsForLevel, getStageForLevel } from './battleEngine';
import { loadSave, claimMilestone } from './persistence';
import { checkMilestones } from './journalMilestones';
import NavBar from './NavBar';
import DragonSprite from './DragonSprite';

export default function JournalScreen({ onNavigate }) {
  const [save, setSave] = useState(() => loadSave());
  const [selectedId, setSelectedId] = useState(() => {
    const s = loadSave();
    const firstOwned = ELEMENTS.find(el => s.dragons[el]?.owned);
    return firstOwned || 'fire';
  });
  const [milestoneResults, setMilestoneResults] = useState([]);
  const [newlyClaimed, setNewlyClaimed] = useState([]);
  const hasCheckedRef = useRef(false);

  // Check and claim milestones on first render
  useEffect(() => {
    if (hasCheckedRef.current) return;
    hasCheckedRef.current = true;

    const currentSave = loadSave();
    const results = checkMilestones(currentSave);
    const toClaim = results.filter(m => m.newlyClaimed);

    if (toClaim.length > 0) {
      for (const m of toClaim) {
        claimMilestone(m.id, m.reward);
      }
      playSound('superEffective');
      const updatedSave = loadSave();
      setSave(updatedSave);
      setMilestoneResults(checkMilestones(updatedSave));
      setNewlyClaimed(toClaim.map(m => m.id));
    } else {
      setMilestoneResults(results);
    }
  }, []);

  const handleSelectDragon = (elementId) => {
    playSound('buttonClick');
    setSelectedId(elementId);
  };

  const dragon = dragons[selectedId];
  const progress = save.dragons[selectedId];
  const owned = progress?.owned;
  const stage = owned ? getStageForLevel(progress.level) : 1;
  const stats = owned
    ? calculateStatsForLevel(progress.fusedBaseStats || dragon.baseStats, progress.level, progress.shiny)
    : null;
  const discoveredCount = Object.values(save.dragons).filter(d => d.owned).length;

  return (
    <div>
      <NavBar activeScreen="journal" onNavigate={onNavigate} />

      <div className="journal-layout">
        {/* Left panel — dragon grid */}
        <div className="journal-grid-panel">
          <div className="journal-grid">
            {ELEMENTS.map((el) => {
              const d = dragons[el];
              const p = save.dragons[el];
              const isOwned = p?.owned;
              const color = elementColors[el];
              const isSelected = el === selectedId;

              return (
                <div
                  key={el}
                  className={`journal-card ${isOwned ? 'owned' : ''} ${isSelected ? 'selected' : ''}`}
                  style={{
                    borderLeftColor: isOwned ? color.primary : '#333',
                    borderColor: isSelected ? color.primary : undefined,
                  }}
                  onClick={() => handleSelectDragon(el)}
                >
                  <DragonSprite
                    spriteSheet={d.spriteSheet}
                    stage={isOwned ? getStageForLevel(p.level) : 1}
                    size={{ width: 80, height: 60 }}
                    shiny={p?.shiny}
                    className={isOwned ? '' : 'undiscovered-silhouette'}
                  />
                  <div
                    className="journal-card-name"
                    style={{ color: isOwned ? color.glow : '#444' }}
                  >
                    {isOwned ? d.name.toUpperCase() : '???'}
                    {p?.shiny && isOwned && <span className="shiny-star"> ★</span>}
                  </div>
                  <div className="journal-card-sub">
                    {isOwned ? `Lv.${p.level} Stage ${getStageForLevel(p.level) === 4 ? 'IV' : getStageForLevel(p.level) === 3 ? 'III' : getStageForLevel(p.level) === 2 ? 'II' : 'I'}` : 'UNDISCOVERED'}
                  </div>
                </div>
              );
            })}
          </div>
          <div className="journal-discovery-count">
            {discoveredCount}/6 DISCOVERED
          </div>
        </div>

        {/* Right panel — detail */}
        <div className="journal-detail">
          <DragonSprite
            spriteSheet={dragon.spriteSheet}
            stage={stage}
            shiny={progress?.shiny && owned}
            className={owned ? '' : 'undiscovered-silhouette'}
          />

          <div
            className="journal-detail-name"
            style={{ color: owned ? elementColors[dragon.element].glow : '#444' }}
          >
            {owned ? dragon.name.toUpperCase() : '???'}
            {owned && progress?.shiny && <span className="shiny-star"> ★</span>}
          </div>

          <div className="journal-detail-meta">
            {owned ? (
              <>
                {dragon.element.toUpperCase()} · Lv.{progress.level} · Stage {stage === 4 ? 'IV' : stage === 3 ? 'III' : stage === 2 ? 'II' : 'I'}
                {progress.fusedBaseStats && <span className="journal-detail-fused" style={{ marginLeft: 8 }}>FUSED</span>}
              </>
            ) : (
              'ELEMENT UNKNOWN'
            )}
          </div>

          {owned && stats && (
            <div className="journal-detail-stats">
              <div>HP <span>{stats.hp}</span></div>
              <div>ATK <span>{stats.atk}</span></div>
              <div>DEF <span>{stats.def}</span></div>
              <div>SPD <span>{stats.spd}</span></div>
            </div>
          )}

          <div className="journal-detail-lore">
            "{owned ? dragonLore[dragon.element] : 'No data available. Discover this dragon in the Hatchery.'}"
            <br />
            <span style={{ color: '#555' }}>— Professor Felix</span>
          </div>

          {/* Milestones */}
          <div className="journal-milestones">
            {milestoneResults.map((m) => {
              const isClaimed = m.claimed || newlyClaimed.includes(m.id);
              const isNew = newlyClaimed.includes(m.id);

              return (
                <div
                  key={m.id}
                  className={`milestone-badge ${isClaimed ? 'claimed' : ''} ${isNew ? 'newly-claimed' : ''}`}
                  title={`${m.description} — ${m.reward} DataScraps`}
                >
                  {isClaimed ? '✓ ' : ''}{m.name}
                  {!isClaimed && <span style={{ display: 'block', fontSize: 6, color: '#444' }}>{m.progress}</span>}
                  {isNew && <span style={{ display: 'block', fontSize: 6, color: '#ffcc00' }}>+{m.reward} ◆</span>}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Add undiscovered silhouette CSS**

Add the following to `src/styles.css` in the journal section:

```css
.undiscovered-silhouette {
  filter: brightness(0) !important;
  animation: none !important;
}
```

- [ ] **Step 3: Verify build**

```bash
npm run build
```

Expected: Build succeeds (component created but not routed yet).

- [ ] **Step 4: Commit**

```bash
git add src/JournalScreen.jsx src/styles.css
git commit -m "feat: JournalScreen — split view bestiary with milestones and lore

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: NavBar + App Routing

**Files:**
- Modify: `src/NavBar.jsx`
- Modify: `src/App.jsx`

- [ ] **Step 1: Add JOURNAL tab to NavBar**

In `src/NavBar.jsx`, add a JOURNAL button between the FUSION button and the BATTLES button. Find the `<button` for BATTLES (the one with `activeScreen === 'battleSelect'`). Insert the following **before** it:

```jsx
        <button
          className={`nav-tab ${activeScreen === 'journal' ? 'active' : ''}`}
          onClick={() => onNavigate('journal')}
        >
          JOURNAL
        </button>
```

- [ ] **Step 2: Add journal screen to App.jsx**

In `src/App.jsx`, add the import at the top after the FusionScreen import:

```js
import JournalScreen from './JournalScreen';
```

Add `JOURNAL: 'journal'` to the `SCREENS` object:

```js
const SCREENS = {
  TITLE: 'title',
  HATCHERY: 'hatchery',
  BATTLE_SELECT: 'battleSelect',
  BATTLE: 'battle',
  FUSION: 'fusion',
  JOURNAL: 'journal',
};
```

Add a journal case in `handleNavigate`, after the fusion case:

```js
    } else if (target === 'journal') {
      playMusic('hatchery');
      setScreen(SCREENS.JOURNAL);
    }
```

Add the journal screen render in the JSX return, after the FusionScreen block and before the BattleSelectScreen block:

```jsx
      {screen === SCREENS.JOURNAL && (
        <JournalScreen onNavigate={handleNavigate} />
      )}
```

- [ ] **Step 3: Verify build**

```bash
npm run build
```

Expected: Build succeeds.

- [ ] **Step 4: Run tests**

```bash
npm test
```

Expected: All existing tests pass (no journal tests — it's purely UI).

- [ ] **Step 5: Commit**

```bash
git add src/NavBar.jsx src/App.jsx
git commit -m "feat: JOURNAL tab in NavBar + App routing for journal screen

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Final Verification

- [ ] **Step 1: Run tests**

```bash
npm test
```

Expected: All tests pass.

- [ ] **Step 2: Run production build**

```bash
npm run build
```

Expected: Build succeeds.

- [ ] **Step 3: Manual playthrough**

```bash
npm run dev
```

Open browser. Verify:
- JOURNAL tab visible in NavBar on all screens
- Journal screen shows 2x3 grid of dragons
- Owned dragons show animated sprite, name, level, stage
- Undiscovered dragons show black silhouette, "???"
- Clicking a card selects it and updates the right panel
- Right panel shows: sprite, name, element, level, stage, stats, lore, milestones
- Shiny dragons show star icon and gold glow
- Fused dragons show "FUSED" badge
- Undiscovered detail shows silhouette, "???", and Felix placeholder quote
- Discovery counter ("X/6 DISCOVERED") is accurate
- Milestones display with correct claimed/unclaimed state
- If any milestones are newly claimable, they animate and show reward

- [ ] **Step 4: Commit any tweaks**

```bash
git add -A
git commit -m "fix: journal polish after manual testing

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

Skip if no adjustments needed.
