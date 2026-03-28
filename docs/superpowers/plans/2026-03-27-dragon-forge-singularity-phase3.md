# Singularity Phase 3: Boss Rush Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the Singularity boss rush — 3 gatekeeper bosses, a multi-phase final boss that shifts elements mid-fight, a dedicated boss selection screen, and a victory epilogue with Felix dialogue.

**Architecture:** Boss data lives in a new `singularityBosses.js` module. A new `SingularityScreen.jsx` shows the linear boss progression. BattleScreen gains multi-phase support — when an NPC with phases is KO'd, the boss shifts to the next phase instead of triggering victory. An epilogue overlay shows Felix's closing dialogue after the final phase. Persistence tracks boss defeats and completion state.

**Tech Stack:** React 18, CSS, localStorage

---

## File Map

| File | Responsibility |
|---|---|
| `src/singularityBosses.js` | Create — boss definitions, phase configs, unlock logic, Felix quotes |
| `src/persistence.js` | Modify — singularityProgress in save, migration, defeat/complete functions |
| `src/singularityProgress.js` | Modify — return stage 3 when singularityComplete |
| `src/SingularityScreen.jsx` | Create — boss rush screen with boss list, detail, dragon picker |
| `src/BattleScreen.jsx` | Modify — multi-phase support, epilogue overlay |
| `src/NavBar.jsx` | Modify — SINGULARITY tab at stage 5 |
| `src/App.jsx` | Modify — singularity screen + routing, battle config for phases |
| `src/styles.css` | Modify — singularity screen, boss cards, phase shift, epilogue styles |

---

## Task 1: Singularity Boss Data Module

**Files:**
- Create: `src/singularityBosses.js`

- [ ] **Step 1: Create src/singularityBosses.js**

```js
export const SINGULARITY_BOSSES = [
  {
    id: 'data_corruption',
    name: 'Data Corruption',
    element: 'fire',
    level: 15,
    stats: { hp: 140, atk: 30, def: 18, spd: 16 },
    moveKeys: ['magma_breath', 'flame_wall'],
    difficulty: 'Singularity',
    baseXP: 100,
    scrapsReward: 200,
    idleSprite: '/assets/npc/firewall_sentinel_sprites.png',
    attackSprite: '/assets/npc/firewall_sentinel_attack.png',
    arena: '/assets/arenas/shadow.png',
    arenaFilter: 'grayscale(0.5) hue-rotate(330deg) contrast(1.3)',
    spriteFilter: 'saturate(1.5) hue-rotate(15deg) contrast(1.2)',
    felixQuote: "It's eating through our data layers. Fire with fire — you'll need a dragon that can take the heat.",
    unlockRequires: null, // First boss, always unlocked at stage 5
  },
  {
    id: 'memory_leak',
    name: 'Memory Leak',
    element: 'ice',
    level: 20,
    stats: { hp: 120, atk: 26, def: 24, spd: 22 },
    moveKeys: ['frost_bite', 'blizzard'],
    difficulty: 'Singularity',
    baseXP: 150,
    scrapsReward: 300,
    idleSprite: '/assets/npc/bit_wraith_sprites.png',
    attackSprite: '/assets/npc/bit_wraith_attack.png',
    arena: '/assets/arenas/shadow.png',
    arenaFilter: 'grayscale(0.5) hue-rotate(330deg) contrast(1.3)',
    spriteFilter: 'saturate(1.5) hue-rotate(-30deg) contrast(1.2)',
    felixQuote: "This thing absorbs and never releases. It'll freeze you solid if you let it accumulate.",
    unlockRequires: 'data_corruption',
  },
  {
    id: 'stack_overflow',
    name: 'Stack Overflow',
    element: 'storm',
    level: 25,
    stats: { hp: 100, atk: 34, def: 14, spd: 30 },
    moveKeys: ['lightning_strike', 'thunder_clap'],
    difficulty: 'Singularity',
    baseXP: 200,
    scrapsReward: 400,
    idleSprite: '/assets/npc/glitch_hydra_sprites.png',
    attackSprite: '/assets/npc/glitch_hydra_attack.png',
    arena: '/assets/arenas/shadow.png',
    arenaFilter: 'grayscale(0.5) hue-rotate(330deg) contrast(1.3)',
    spriteFilter: 'saturate(1.5) hue-rotate(30deg) contrast(1.2)',
    felixQuote: "Infinite recursion manifested as pure electricity. It's fast. Faster than anything we've faced.",
    unlockRequires: 'memory_leak',
  },
];

export const FINAL_BOSS = {
  id: 'the_singularity',
  name: 'The Singularity',
  difficulty: 'FINAL',
  baseXP: 500,
  scrapsReward: 1000,
  arena: '/assets/arenas/shadow.png',
  arenaFilter: 'grayscale(0.5) hue-rotate(330deg) contrast(1.3)',
  felixQuote: "This is it. The source of everything. It will adapt. It will learn. Do not let it win.",
  unlockRequires: 'stack_overflow',
  idleSprite: '/assets/npc/recursive_golem_sprites.png',
  attackSprite: '/assets/npc/recursive_golem_attack.png',
  phases: [
    {
      name: 'The Singularity — Ignition',
      element: 'fire',
      level: 30,
      stats: { hp: 150, atk: 32, def: 20, spd: 18 },
      moveKeys: ['magma_breath', 'flame_wall'],
      spriteFilter: 'saturate(2) hue-rotate(15deg) contrast(1.3)',
    },
    {
      name: 'The Singularity — Surge',
      element: 'storm',
      level: 30,
      stats: { hp: 130, atk: 36, def: 16, spd: 26 },
      moveKeys: ['lightning_strike', 'thunder_clap'],
      spriteFilter: 'saturate(2) hue-rotate(60deg) contrast(1.3)',
    },
    {
      name: 'The Singularity — Void Collapse',
      element: 'void',
      level: 30,
      stats: { hp: 100, atk: 40, def: 12, spd: 32 },
      moveKeys: ['void_rift', 'null_reflect'],
      spriteFilter: 'saturate(2) hue-rotate(180deg) contrast(1.5)',
    },
  ],
};

export function getBossStatus(boss, save) {
  const progress = save.singularityProgress || { defeated: [], finalBossPhase: 0 };
  const defeated = progress.defeated || [];

  if (boss.id === 'the_singularity') {
    const allGatekeepersDefeated = SINGULARITY_BOSSES.every(b => defeated.includes(b.id));
    if (save.singularityComplete) return 'defeated';
    if (allGatekeepersDefeated) return 'available';
    return 'locked';
  }

  if (defeated.includes(boss.id)) return 'defeated';
  if (!boss.unlockRequires) return 'available';
  if (defeated.includes(boss.unlockRequires)) return 'available';
  return 'locked';
}

export const EPILOGUE_LINES = [
  'You did it. The Singularity is contained.',
  'The Matrix is stabilizing. I can feel it.',
  "You've saved every dragon in the Forge.",
  "But between you and me... I don't think it's gone forever.",
  'Stay sharp, Dragon Forger.',
];
```

- [ ] **Step 2: Commit**

```bash
git add src/singularityBosses.js
git commit -m "feat: Singularity boss definitions — 3 gatekeepers, final boss phases, unlock logic

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Persistence — Singularity Progress

**Files:**
- Modify: `src/persistence.js`

- [ ] **Step 1: Add singularityProgress and singularityComplete to DEFAULT_SAVE**

In `src/persistence.js`, add after `defeatedNpcs: [],` in DEFAULT_SAVE:

```js
  singularityProgress: { defeated: [], finalBossPhase: 0 },
  singularityComplete: false,
```

- [ ] **Step 2: Add migration**

In `migrateSave`, add after the defeatedNpcs migration:

```js
  if (save.singularityProgress === undefined) {
    save.singularityProgress = { defeated: [], finalBossPhase: 0 };
  }
  if (save.singularityComplete === undefined) save.singularityComplete = false;
```

- [ ] **Step 3: Add singularity persistence functions**

Add after `recordNpcDefeat`:

```js
export function recordSingularityDefeat(bossId) {
  const save = loadSave();
  if (!save.singularityProgress.defeated.includes(bossId)) {
    save.singularityProgress.defeated.push(bossId);
    writeSave(save);
  }
}

export function updateFinalBossPhase(phase) {
  const save = loadSave();
  save.singularityProgress.finalBossPhase = phase;
  writeSave(save);
}

export function markSingularityComplete() {
  const save = loadSave();
  save.singularityComplete = true;
  save.singularityProgress.finalBossPhase = 4;
  writeSave(save);
}
```

- [ ] **Step 4: Commit**

```bash
git add src/persistence.js
git commit -m "feat: singularity progress persistence — defeat tracking, phase, completion

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Singularity Progress — Post-Completion Stage Reduction

**Files:**
- Modify: `src/singularityProgress.js`

- [ ] **Step 1: Update getSingularityStage to handle completion**

In `src/singularityProgress.js`, update the `getSingularityStage` function. At the very start of the function, add:

```js
  // After completing the Singularity, corruption reduces to stage 3
  if (save.singularityComplete) return 3;
```

The full function becomes:

```js
export function getSingularityStage(save) {
  // After completing the Singularity, corruption reduces to stage 3
  if (save.singularityComplete) return 3;

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

Also add a new export for checking if the singularity tab should show (stage 5 OR completed):

```js
export function showSingularityTab(save) {
  if (save.singularityComplete) return true;
  return getSingularityStage(save) >= 5 || save.singularityComplete;
}
```

Wait — that's redundant. Simpler: the NavBar should show the tab when the raw stage (ignoring completion) would be 5, or when singularityComplete is true. Add a helper:

```js
export function isSingularityUnlocked(save) {
  if (save.singularityComplete) return true;
  const ownedCount = BASE_ELEMENTS.filter(el => save.dragons[el]?.owned).length;
  const hasElder = Object.values(save.dragons).some(d => d.owned && d.level >= 50);
  const defeatedNpcs = save.defeatedNpcs || [];
  const allNpcsDefeated = BASE_NPC_IDS.every(id => defeatedNpcs.includes(id));
  return allNpcsDefeated;
}
```

- [ ] **Step 2: Commit**

```bash
git add src/singularityProgress.js
git commit -m "feat: post-completion stage reduction + isSingularityUnlocked helper

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Singularity Screen CSS

**Files:**
- Modify: `src/styles.css`

- [ ] **Step 1: Add singularity screen CSS**

Append at the end of `src/styles.css`:

```css
/* === SINGULARITY SCREEN === */

.singularity-layout {
  display: flex;
  gap: 12px;
  height: calc(100vh - 48px);
  padding: 12px;
  padding-top: 52px;
}

.singularity-boss-list {
  width: 40%;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.singularity-boss-card {
  background: #1a1a24;
  border: 1px solid #333;
  border-left: 3px solid #cc2222;
  border-radius: 3px;
  padding: 10px 12px;
  cursor: pointer;
  transition: all 0.15s;
  display: flex;
  align-items: center;
  gap: 10px;
}

.singularity-boss-card:hover {
  border-color: #555;
}

.singularity-boss-card.selected {
  border-color: #cc2222;
  box-shadow: 0 0 10px rgba(204, 34, 34, 0.3);
}

.singularity-boss-card.locked {
  opacity: 0.4;
  cursor: default;
}

.singularity-boss-card.defeated {
  border-left-color: #44cc44;
}

.singularity-boss-name {
  font-size: 9px;
  line-height: 1.6;
  color: #cc4444;
}

.singularity-boss-card.defeated .singularity-boss-name {
  color: #44cc44;
}

.singularity-boss-sub {
  font-size: 7px;
  color: #666;
  line-height: 1.6;
}

.singularity-boss-status {
  font-size: 7px;
  margin-left: auto;
  line-height: 1.6;
}

.singularity-boss-status.locked { color: #444; }
.singularity-boss-status.available { color: #cc4444; }
.singularity-boss-status.defeated { color: #44cc44; }

/* Detail panel */
.singularity-detail {
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

.singularity-detail-name {
  font-size: 14px;
  line-height: 1.6;
  color: #cc4444;
}

.singularity-detail-meta {
  font-size: 8px;
  color: #888;
  line-height: 1.8;
}

.singularity-detail-stats {
  display: flex;
  gap: 16px;
  font-size: 8px;
  color: #aaa;
  line-height: 1.8;
}

.singularity-detail-stats span {
  color: #e0e0e0;
}

.singularity-detail-quote {
  font-size: 8px;
  color: #cc6666;
  font-style: italic;
  line-height: 2;
  text-align: center;
  max-width: 400px;
  margin-top: 8px;
}

.singularity-phases-indicator {
  font-size: 7px;
  color: #cc4444;
  border: 1px solid #cc4444;
  padding: 2px 8px;
  border-radius: 2px;
}

.singularity-engage-btn {
  margin-top: 12px;
  padding: 8px 24px;
  font-family: 'Press Start 2P', monospace;
  font-size: 10px;
  background: #cc2222;
  color: #fff;
  border: none;
  border-radius: 3px;
  cursor: pointer;
  transition: all 0.15s;
}

.singularity-engage-btn:hover {
  background: #ee3333;
  box-shadow: 0 0 12px rgba(204, 34, 34, 0.5);
}

.singularity-engage-btn:disabled {
  background: #333;
  color: #555;
  cursor: default;
  box-shadow: none;
}

/* Dragon picker for singularity */
.singularity-dragon-picker {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  justify-content: center;
  margin-top: 8px;
}

.singularity-dragon-option {
  background: #111118;
  border: 1px solid #333;
  border-radius: 3px;
  padding: 4px 8px;
  cursor: pointer;
  font-size: 7px;
  color: #888;
  transition: all 0.15s;
}

.singularity-dragon-option.selected {
  border-color: #ff6622;
  color: #ff8844;
}

/* Nav tab singularity style */
.nav-tab.singularity-tab {
  color: #cc4444;
  animation: corruptionBorderPulse 3s ease-in-out infinite;
}

/* Phase shift animation */
.phase-shift-flash {
  position: fixed;
  inset: 0;
  background: rgba(204, 34, 34, 0.3);
  z-index: 9999;
  pointer-events: none;
  animation: phaseShiftFlash 1s ease-out forwards;
}

@keyframes phaseShiftFlash {
  0% { opacity: 1; }
  30% { opacity: 0.8; }
  100% { opacity: 0; }
}

/* Phase indicator in battle */
.phase-indicator {
  font-size: 7px;
  color: #cc4444;
  border: 1px solid #cc4444;
  padding: 1px 6px;
  border-radius: 2px;
  margin-left: 6px;
}

/* Epilogue overlay */
.epilogue-overlay {
  position: fixed;
  inset: 0;
  background: rgba(17, 17, 24, 0.95);
  z-index: 100;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding: 40px;
}

.epilogue-portrait {
  width: 80px;
  height: 80px;
  border: 3px solid #44cc44;
  box-shadow: inset -3px -3px 0px #228822;
  overflow: hidden;
}

.epilogue-portrait img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  image-rendering: pixelated;
}

.epilogue-text {
  font-size: 9px;
  color: #44cc44;
  line-height: 2.2;
  text-align: center;
  max-width: 500px;
}

.epilogue-rewards {
  display: flex;
  gap: 16px;
  font-size: 10px;
  margin-top: 8px;
}

.epilogue-btn {
  margin-top: 16px;
  padding: 8px 24px;
  font-family: 'Press Start 2P', monospace;
  font-size: 10px;
  background: #44cc44;
  color: #111118;
  border: none;
  border-radius: 3px;
  cursor: pointer;
}

.epilogue-btn:hover {
  background: #66ee66;
  box-shadow: 0 0 12px rgba(68, 204, 68, 0.5);
}

/* Corrupted NPC sprite */
.singularity-npc-sprite {
  image-rendering: pixelated;
}
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

- [ ] **Step 3: Commit**

```bash
git add src/styles.css
git commit -m "feat: Singularity screen CSS — boss cards, detail, phase shift, epilogue

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: SingularityScreen Component

**Files:**
- Create: `src/SingularityScreen.jsx`

- [ ] **Step 1: Create src/SingularityScreen.jsx**

```jsx
import { useState } from 'react';
import { playSound } from './soundEngine';
import { dragons, elementColors, ELEMENTS } from './gameData';
import { getStageForLevel, calculateStatsForLevel } from './battleEngine';
import { SINGULARITY_BOSSES, FINAL_BOSS, getBossStatus } from './singularityBosses';
import NavBar from './NavBar';
import NpcSprite from './NpcSprite';

const ALL_BOSSES = [...SINGULARITY_BOSSES, FINAL_BOSS];

export default function SingularityScreen({ onNavigate, onEngageBoss, save }) {
  const [selectedBossId, setSelectedBossId] = useState(ALL_BOSSES[0].id);
  const [selectedDragonId, setSelectedDragonId] = useState(() => {
    const firstOwned = ELEMENTS.find(el => save.dragons[el]?.owned);
    return firstOwned || 'fire';
  });

  const selectedBoss = ALL_BOSSES.find(b => b.id === selectedBossId);
  const bossStatus = getBossStatus(selectedBoss, save);
  const canEngage = bossStatus === 'available' || bossStatus === 'defeated';
  const ownedDragons = ELEMENTS.filter(el => save.dragons[el]?.owned);

  const handleSelectBoss = (bossId) => {
    const boss = ALL_BOSSES.find(b => b.id === bossId);
    const status = getBossStatus(boss, save);
    if (status === 'locked') return;
    playSound('buttonClick');
    setSelectedBossId(bossId);
  };

  const handleEngage = () => {
    if (!canEngage) return;
    playSound('buttonClick');
    onEngageBoss({
      dragonId: selectedDragonId,
      boss: selectedBoss,
      isSingularity: true,
    });
  };

  // Display stats — for final boss show phase 1
  const displayStats = selectedBoss.phases ? selectedBoss.phases[0].stats : selectedBoss.stats;
  const displayElement = selectedBoss.phases ? selectedBoss.phases[0].element : selectedBoss.element;
  const displayLevel = selectedBoss.phases ? selectedBoss.phases[0].level : selectedBoss.level;

  return (
    <div>
      <NavBar activeScreen="singularity" onNavigate={onNavigate} save={save} />

      <div className="singularity-layout">
        {/* Left panel — boss list */}
        <div className="singularity-boss-list">
          {ALL_BOSSES.map((boss) => {
            const status = getBossStatus(boss, save);
            const isSelected = boss.id === selectedBossId;
            const color = boss.phases
              ? elementColors[boss.phases[0].element]
              : elementColors[boss.element];

            return (
              <div
                key={boss.id}
                className={`singularity-boss-card ${status} ${isSelected ? 'selected' : ''}`}
                onClick={() => handleSelectBoss(boss.id)}
              >
                <div>
                  <div className="singularity-boss-name">
                    {status === 'locked' ? '???' : boss.name.toUpperCase()}
                  </div>
                  <div className="singularity-boss-sub">
                    {status === 'locked' ? 'LOCKED' : `${boss.difficulty} · ${(boss.phases ? boss.phases[0].element : boss.element).toUpperCase()}`}
                    {boss.phases && status !== 'locked' && ' · 3 PHASES'}
                  </div>
                </div>
                <div className={`singularity-boss-status ${status}`}>
                  {status === 'locked' ? '🔒' : status === 'defeated' ? '✓' : '⚔'}
                </div>
              </div>
            );
          })}
        </div>

        {/* Right panel — detail */}
        <div className="singularity-detail">
          {bossStatus !== 'locked' ? (
            <>
              <NpcSprite
                idleSprite={selectedBoss.idleSprite}
                attackSprite={selectedBoss.attackSprite || selectedBoss.idleSprite}
                isAttacking={false}
                style={{ filter: selectedBoss.spriteFilter || (selectedBoss.phases ? selectedBoss.phases[0].spriteFilter : '') }}
              />

              <div className="singularity-detail-name">
                {selectedBoss.name.toUpperCase()}
              </div>

              <div className="singularity-detail-meta">
                {displayElement.toUpperCase()} · Lv.{displayLevel} · {selectedBoss.difficulty}
                {selectedBoss.phases && (
                  <span className="singularity-phases-indicator" style={{ marginLeft: 8 }}>3 PHASES</span>
                )}
              </div>

              <div className="singularity-detail-stats">
                <div>HP <span>{displayStats.hp}</span></div>
                <div>ATK <span>{displayStats.atk}</span></div>
                <div>DEF <span>{displayStats.def}</span></div>
                <div>SPD <span>{displayStats.spd}</span></div>
              </div>

              <div className="singularity-detail-quote">
                "{selectedBoss.felixQuote}"
                <br />
                <span style={{ color: '#555' }}>— Professor Felix</span>
              </div>

              {/* Dragon picker */}
              <div className="singularity-dragon-picker">
                {ownedDragons.map((el) => {
                  const d = dragons[el];
                  const color = elementColors[el];
                  return (
                    <div
                      key={el}
                      className={`singularity-dragon-option ${el === selectedDragonId ? 'selected' : ''}`}
                      style={{ borderColor: el === selectedDragonId ? color.primary : undefined }}
                      onClick={() => { playSound('buttonClick'); setSelectedDragonId(el); }}
                    >
                      {d.name}
                    </div>
                  );
                })}
              </div>

              <button
                className="singularity-engage-btn"
                disabled={!canEngage}
                onClick={handleEngage}
              >
                ENGAGE
              </button>
            </>
          ) : (
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', flex: 1 }}>
              <div style={{ fontSize: 10, color: '#444', textAlign: 'center', lineHeight: 2 }}>
                LOCKED<br />
                <span style={{ fontSize: 7, color: '#333' }}>Defeat the previous boss to unlock</span>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

- [ ] **Step 3: Commit**

```bash
git add src/SingularityScreen.jsx
git commit -m "feat: SingularityScreen — boss rush selection with linear progression

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: NavBar — SINGULARITY Tab

**Files:**
- Modify: `src/NavBar.jsx`

- [ ] **Step 1: Add SINGULARITY tab**

Add import at top:

```js
import { isSingularityUnlocked } from './singularityProgress';
```

In the JSX, after the JOURNAL button and before the BATTLES button, add:

```jsx
        {isSingularityUnlocked(save) && (
          <button
            className={`nav-tab singularity-tab ${activeScreen === 'singularity' ? 'active' : ''}`}
            onClick={() => onNavigate('singularity')}
          >
            SINGULARITY
          </button>
        )}
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

- [ ] **Step 3: Commit**

```bash
git add src/NavBar.jsx
git commit -m "feat: SINGULARITY tab in NavBar — visible at stage 5

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: App.jsx — Singularity Routing

**Files:**
- Modify: `src/App.jsx`

- [ ] **Step 1: Add SingularityScreen import and SINGULARITY screen**

Add import:

```js
import SingularityScreen from './SingularityScreen';
```

Add to SCREENS:

```js
  SINGULARITY: 'singularity',
```

Add singularity case in `handleNavigate`, after the journal case:

```js
    } else if (target === 'singularity') {
      playMusic('battle', true);
      setScreen(SCREENS.SINGULARITY);
    }
```

- [ ] **Step 2: Add handleEngageBoss function**

After `handleBeginBattle`:

```js
  function handleEngageBoss(config) {
    playSound('buttonClick');
    playMusic('battle', true);
    setBattleConfig({
      dragonId: config.dragonId,
      npcId: config.boss.id,
      boss: config.boss,
      isSingularity: true,
      phases: config.boss.phases || null,
    });
    setScreen(SCREENS.BATTLE);
  }
```

- [ ] **Step 3: Add handleSingularityBattleEnd**

After `handleBattleEnd`:

```js
  function handleSingularityBattleEnd() {
    refreshSave();
    playMusic('battle', true);
    setBattleConfig(null);
    setScreen(SCREENS.SINGULARITY);
  }
```

- [ ] **Step 4: Add SingularityScreen render and update BattleScreen for singularity**

In the JSX, after the JournalScreen block:

```jsx
      {screen === SCREENS.SINGULARITY && (
        <SingularityScreen
          onNavigate={handleNavigate}
          onEngageBoss={handleEngageBoss}
          save={save}
        />
      )}
```

Update the BattleScreen render to pass the full battleConfig and use the right onBattleEnd:

```jsx
      {screen === SCREENS.BATTLE && battleConfig && (
        <BattleScreen
          dragonId={battleConfig.dragonId}
          npcId={battleConfig.npcId}
          onBattleEnd={battleConfig.isSingularity ? handleSingularityBattleEnd : handleBattleEnd}
          save={save}
          refreshSave={refreshSave}
          battleConfig={battleConfig}
        />
      )}
```

- [ ] **Step 5: Verify build**

```bash
npm run build
```

- [ ] **Step 6: Commit**

```bash
git add src/App.jsx
git commit -m "feat: Singularity screen routing + boss battle config in App.jsx

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: BattleScreen — Multi-Phase + Epilogue

**Files:**
- Modify: `src/BattleScreen.jsx`

This is the most complex task. Read the current file carefully before making changes.

- [ ] **Step 1: Add imports**

Add to the persistence imports:

```js
import { loadSave, saveDragonProgress, addScraps, recordNpcDefeat, recordSingularityDefeat, markSingularityComplete } from './persistence';
```

Add new imports:

```js
import { EPILOGUE_LINES } from './singularityBosses';
```

- [ ] **Step 2: Accept battleConfig prop and update initBattle**

Update component signature to accept `battleConfig`:

```js
export default function BattleScreen({ dragonId, npcId, onBattleEnd, save, refreshSave, battleConfig }) {
```

Update `initBattle` to handle singularity bosses. The function currently reads from `npcs[npcId]`. For singularity bosses, the NPC data comes from `battleConfig.boss` instead. Add at the start of initBattle:

```js
function initBattle(dragonId, npcId, save, battleConfig) {
  const dragon = dragons[dragonId];

  // Build NPC from either standard npcs or singularity boss config
  let npc;
  if (battleConfig?.boss) {
    const boss = battleConfig.boss;
    const phase = boss.phases ? boss.phases[0] : null;
    npc = {
      id: boss.id,
      name: phase ? phase.name : boss.name,
      element: phase ? phase.element : boss.element,
      level: phase ? phase.level : boss.level,
      stats: phase ? phase.stats : boss.stats,
      moveKeys: phase ? phase.moveKeys : boss.moveKeys,
      difficulty: boss.difficulty,
      baseXP: boss.baseXP,
      scrapsReward: boss.scrapsReward,
      idleSprite: boss.idleSprite,
      attackSprite: boss.attackSprite,
      arena: boss.arena,
      arenaFilter: boss.arenaFilter || null,
      spriteFilter: phase ? phase.spriteFilter : (boss.spriteFilter || null),
    };
  } else {
    npc = npcs[npcId];
  }
```

Remove the old `const npc = npcs[npcId];` line.

Update the useReducer call:

```js
const [state, dispatch] = useReducer(battleReducer, null, () => initBattle(dragonId, npcId, save, battleConfig));
```

- [ ] **Step 3: Add PHASE_SHIFT and EPILOGUE to reducer**

Add to PHASES:

```js
  PHASE_SHIFT: 'phaseShift',
  EPILOGUE: 'epilogue',
```

Add to battleReducer:

```js
    case 'PHASE_SHIFT':
      return {
        ...state,
        npc: { ...state.npc, ...action.npcUpdate },
        npcHp: action.npcUpdate.stats.hp,
        npcMaxHp: action.npcUpdate.stats.hp,
        npcStatus: null,
        npcSpriteClass: '',
        npcAttacking: false,
        phase: PHASES.PLAYER_TURN,
        currentPhase: (state.currentPhase || 0) + 1,
      };
    case 'SET_EPILOGUE':
      return { ...state, phase: PHASES.EPILOGUE, xpGained: action.xpGained, scrapsGained: action.scrapsGained };
```

Also add `currentPhase: 0` to the initBattle return object.

- [ ] **Step 4: Update victory handling for multi-phase and singularity**

In `handleMoveSelect`, replace the NPC KO block (`if (result.npc.hp <= 0) { ... }`) with:

```js
    if (result.npc.hp <= 0) {
      // Check for multi-phase boss
      const phases = battleConfig?.phases;
      const currentPhaseIndex = state.currentPhase || 0;

      if (phases && currentPhaseIndex < phases.length - 1) {
        // Phase shift — boss transforms
        const nextPhase = phases[currentPhaseIndex + 1];
        dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
        playSound('ko');
        await wait(600);

        playSound('terminalGlitch');
        dispatch({
          type: 'PHASE_SHIFT',
          npcUpdate: {
            name: nextPhase.name,
            element: nextPhase.element,
            level: nextPhase.level,
            stats: nextPhase.stats,
            moveKeys: nextPhase.moveKeys,
            spriteFilter: nextPhase.spriteFilter,
          },
        });
        await wait(1000);
      } else {
        // True victory
        const xpGained = calculateXpGain(state.npc.baseXP || 50, state.playerLevel, state.npc.level);
        const scrapsGained = state.npc.scrapsReward || 0;
        const newXp = state.playerXp + xpGained;
        const xpPerLevel = 100;
        let newLevel = state.playerLevel;
        let remainingXp = newXp;
        while (remainingXp >= xpPerLevel) {
          remainingXp -= xpPerLevel;
          newLevel++;
        }
        const leveledUp = newLevel > state.playerLevel;
        saveDragonProgress(state.dragonId, newLevel, remainingXp);
        if (scrapsGained > 0) addScraps(scrapsGained);

        if (battleConfig?.isSingularity) {
          if (phases) {
            // Beaten the final boss
            markSingularityComplete();
          } else {
            recordSingularityDefeat(npcId);
          }
        } else {
          recordNpcDefeat(npcId);
        }
        refreshSave();

        dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
        playSound('ko');
        await wait(600);

        // Check if this is the final boss epilogue
        if (battleConfig?.isSingularity && phases && !save.singularityComplete) {
          dispatch({ type: 'SET_EPILOGUE', xpGained, scrapsGained });
          stopMusic();
          playSound('victoryFanfare');
        } else {
          dispatch({ type: 'SET_VICTORY', xpGained, leveledUp, newLevel, scrapsGained });
          stopMusic();
          playSound('victoryFanfare');
          playSound('xpGain');
          if (scrapsGained > 0) setTimeout(() => playSound('scrapsEarned'), 200);
          if (leveledUp) setTimeout(() => playSound('levelUp'), 400);
        }
      }
    } else if (result.player.hp <= 0) {
```

(Keep the existing defeat block and the else block unchanged.)

- [ ] **Step 5: Add arena filter support in JSX**

Find the arena background div. Add the arenaFilter style:

```jsx
      <div
        className="arena pixelated"
        style={{
          backgroundImage: `url(${npc.arena})`,
          filter: state.npc.arenaFilter || 'none',
        }}
      />
```

- [ ] **Step 6: Add NPC sprite filter support**

Find the NpcSprite render. Add a style prop for the corruption filter:

```jsx
          <NpcSprite
            idleSprite={npc.idleSprite}
            attackSprite={npc.attackSprite}
            isAttacking={state.npcAttacking}
            className={state.npcSpriteClass}
            flipX={npc.flipSprite}
            style={{ filter: state.npc.spriteFilter || 'none' }}
          />
```

Note: NpcSprite may need to accept and apply a `style` prop. Check its implementation — if it doesn't support it, add `style` to its props and apply to the outer element.

- [ ] **Step 7: Add phase indicator in top bar**

In the HP bar area, after the NPC name/level, add:

```jsx
            {state.currentPhase > 0 && battleConfig?.phases && (
              <span className="phase-indicator">
                PHASE {state.currentPhase + 1}/{battleConfig.phases.length}
              </span>
            )}
```

- [ ] **Step 8: Add epilogue overlay in JSX**

After the defeat overlay, add:

```jsx
      {/* Epilogue overlay */}
      {state.phase === PHASES.EPILOGUE && (
        <div className="epilogue-overlay">
          <div className="epilogue-portrait">
            <img src="/assets/felix_pixel.jpg" alt="Professor Felix" className="pixelated" />
          </div>
          <div className="epilogue-text">
            {EPILOGUE_LINES.map((line, i) => (
              <div key={i}>"{line}"</div>
            ))}
          </div>
          <div className="epilogue-rewards">
            <div style={{ color: '#44aaff' }}>+{state.xpGained} XP</div>
            {state.scrapsGained > 0 && <div style={{ color: '#ffcc00' }}>+{state.scrapsGained} ◆</div>}
          </div>
          <button className="epilogue-btn" onClick={onBattleEnd}>
            RETURN TO THE FORGE
          </button>
        </div>
      )}
```

- [ ] **Step 9: Verify build**

```bash
npm run build
```

- [ ] **Step 10: Commit**

```bash
git add src/BattleScreen.jsx
git commit -m "feat: multi-phase boss support, singularity victory, epilogue overlay

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: NpcSprite — Style Prop Support

**Files:**
- Modify: `src/NpcSprite.jsx`

- [ ] **Step 1: Add style prop to NpcSprite**

Read `src/NpcSprite.jsx`. Add `style = {}` to the props and apply it to the outer container element. This allows corruption filters to be passed through.

- [ ] **Step 2: Verify build**

```bash
npm run build
```

- [ ] **Step 3: Commit**

```bash
git add src/NpcSprite.jsx
git commit -m "feat: NpcSprite accepts style prop for corruption filters

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 10: Final Verification

- [ ] **Step 1: Run all tests**

```bash
npm test
```

Expected: All 70 tests pass.

- [ ] **Step 2: Run build**

```bash
npm run build
```

- [ ] **Step 3: Manual playthrough**

```bash
npm run dev
```

To test, set save to stage 5 via console:

```js
let s = JSON.parse(localStorage.getItem('dragonforge_save'));
s.dragons.fire.owned = true; s.dragons.fire.level = 50;
s.dragons.ice.owned = true; s.dragons.storm.owned = true;
s.dragons.stone.owned = true; s.dragons.venom.owned = true;
s.dragons.shadow.owned = true;
s.defeatedNpcs = ['firewall_sentinel','bit_wraith','glitch_hydra','recursive_golem'];
localStorage.setItem('dragonforge_save', JSON.stringify(s));
```

Verify:
- SINGULARITY tab appears in NavBar (red, pulsing)
- Singularity screen shows 4 bosses (first available, rest locked)
- Dragon picker works
- ENGAGE starts battle with corrupted arena + filtered NPC sprite
- Beating gatekeeper returns to singularity screen, next boss unlocks
- Final boss: phase 1 → KO → phase shift animation → phase 2 → phase 3
- Beating phase 3: epilogue overlay with Felix dialogue
- After epilogue: corruption reduces to stage 3
- Re-fighting bosses works (no epilogue repeat)

- [ ] **Step 4: Commit any tweaks**

```bash
git add -A
git commit -m "fix: Singularity Phase 3 polish after manual testing

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```
