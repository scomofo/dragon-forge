# Dragon Forge: Quantum Incubation (Hatchery) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a gacha hatchery system where players spend dataScraps (earned from battles) to pull dragons with rarity tiers, pity system, shiny protocol, duplicate merging, and animated egg-crack reveals.

**Architecture:** Pure-function hatchery engine (`hatcheryEngine.js`) handles all pull logic. New `HatcheryScreen.jsx` handles the UI/animation. Shared `NavBar.jsx` lets players switch between hatchery and battles. Persistence layer extended with owned/shiny/scraps/pity fields and migration for existing saves.

**Tech Stack:** React 18, Vite, Vitest, CSS animations, localStorage

---

## File Map

| File | Responsibility |
|---|---|
| `src/persistence.js` | **Modify:** Add owned, shiny, dataScraps, pityCounter fields + migration |
| `src/gameData.js` | **Modify:** Add rarity config, scrapsReward to NPCs |
| `src/hatcheryEngine.js` | **Create:** Pull logic — rarity roll, pity, shiny, duplicate merge |
| `src/hatcheryEngine.test.js` | **Create:** Tests for all hatchery engine logic |
| `src/battleEngine.js` | **Modify:** Update calculateStatsForLevel for shiny multiplier |
| `src/battleEngine.test.js` | **Modify:** Add shiny stat test |
| `src/NavBar.jsx` | **Create:** Shared nav bar with HATCHERY/BATTLES tabs + scraps display |
| `src/DragonSprite.jsx` | **Modify:** Add shiny prop with hue-rotate animation |
| `src/HatcheryScreen.jsx` | **Create:** Full hatchery UI with egg animation, pull buttons, results |
| `src/BattleScreen.jsx` | **Modify:** Award scraps on victory, show in overlay |
| `src/BattleSelectScreen.jsx` | **Modify:** Filter to owned dragons, locked silhouettes, add NavBar |
| `src/App.jsx` | **Modify:** Add HATCHERY screen, nav switching |
| `src/styles.css` | **Modify:** Add hatchery, nav bar, egg animation, shiny CSS |

---

## Task 1: Persistence Layer Updates

**Files:**
- Modify: `src/persistence.js`

- [ ] **Step 1: Read the current persistence.js and replace with updated version**

```js
const STORAGE_KEY = 'dragonforge_save';

const DEFAULT_SAVE = {
  dragons: {
    fire:   { level: 1, xp: 0, owned: false, shiny: false },
    ice:    { level: 1, xp: 0, owned: false, shiny: false },
    storm:  { level: 1, xp: 0, owned: false, shiny: false },
    stone:  { level: 1, xp: 0, owned: false, shiny: false },
    venom:  { level: 1, xp: 0, owned: false, shiny: false },
    shadow: { level: 1, xp: 0, owned: false, shiny: false },
  },
  dataScraps: 0,
  pityCounter: 0,
};

function migrateSave(save) {
  // Migrate dragon entries
  for (const id of Object.keys(save.dragons)) {
    const d = save.dragons[id];
    if (d.owned === undefined) {
      d.owned = d.level > 1 || d.xp > 0;
    }
    if (d.shiny === undefined) {
      d.shiny = false;
    }
  }
  if (save.dataScraps === undefined) save.dataScraps = 0;
  if (save.pityCounter === undefined) save.pityCounter = 0;
  return save;
}

export function loadSave() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return structuredClone(DEFAULT_SAVE);
    return migrateSave(JSON.parse(raw));
  } catch {
    return structuredClone(DEFAULT_SAVE);
  }
}

export function writeSave(save) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(save));
}

export function saveDragonProgress(dragonId, level, xp) {
  const save = loadSave();
  save.dragons[dragonId] = { ...save.dragons[dragonId], level, xp };
  writeSave(save);
}

export function addScraps(amount) {
  const save = loadSave();
  save.dataScraps += amount;
  writeSave(save);
}

export function spendScraps(amount) {
  const save = loadSave();
  if (save.dataScraps < amount) return false;
  save.dataScraps -= amount;
  writeSave(save);
  return true;
}

export function updatePityCounter(newValue) {
  const save = loadSave();
  save.pityCounter = newValue;
  writeSave(save);
}

export function unlockDragon(dragonId, shiny) {
  const save = loadSave();
  save.dragons[dragonId] = { ...save.dragons[dragonId], owned: true };
  if (shiny) save.dragons[dragonId].shiny = true;
  writeSave(save);
}

export function addDragonXp(dragonId, bonusXp) {
  const save = loadSave();
  const d = save.dragons[dragonId];
  d.xp += bonusXp;
  // Level up if threshold reached
  const xpPerLevel = 100;
  while (d.xp >= xpPerLevel) {
    d.xp -= xpPerLevel;
    d.level++;
  }
  writeSave(save);
}

export function upgradeDragonShiny(dragonId) {
  const save = loadSave();
  save.dragons[dragonId].shiny = true;
  writeSave(save);
}

export function resetSave() {
  localStorage.removeItem(STORAGE_KEY);
}
```

- [ ] **Step 2: Commit**

```bash
git add src/persistence.js
git commit -m "feat: extend persistence with owned, shiny, dataScraps, pityCounter + migration"
```

---

## Task 2: Game Data Updates

**Files:**
- Modify: `src/gameData.js`

- [ ] **Step 1: Read src/gameData.js and add rarity config + scrapsReward to NPCs**

Add after the `elementColors` export at the end of the file:

```js
// === RARITY CONFIG ===
export const rarityTiers = [
  { name: 'Common',   chance: 0.50, elements: ['fire', 'ice'], multiplier: 1 },
  { name: 'Uncommon', chance: 0.30, elements: ['storm', 'venom', 'stone'], multiplier: 2 },
  { name: 'Rare',     chance: 0.15, elements: ['shadow'], multiplier: 3 },
  { name: 'Exotic',   chance: 0.05, elements: ['shadow'], multiplier: 5, guaranteedShiny: true },
];

export const PULL_COST = 50;
export const SHINY_CHANCE = 0.02;
export const PITY_THRESHOLD = 10;
```

Also add `scrapsReward` to each NPC entry. Read the NPCs section first, then add the field to each:
- `firewall_sentinel`: `scrapsReward: 30,`
- `bit_wraith`: `scrapsReward: 50,`
- `glitch_hydra`: `scrapsReward: 80,`
- `recursive_golem`: `scrapsReward: 120,`

Add the field after `baseXP` in each NPC object.

- [ ] **Step 2: Commit**

```bash
git add src/gameData.js
git commit -m "feat: add rarity config, pull cost constants, and scrapsReward to NPCs"
```

---

## Task 3: Hatchery Engine — Rarity Roll

**Files:**
- Create: `src/hatcheryEngine.js`, `src/hatcheryEngine.test.js`

- [ ] **Step 1: Write failing tests for rarity roll**

```js
// src/hatcheryEngine.test.js
import { describe, it, expect } from 'vitest';
import { rollRarity, rollElement } from './hatcheryEngine';

describe('rollRarity', () => {
  it('returns a rarity tier object', () => {
    const result = rollRarity(0);
    expect(result).toHaveProperty('name');
    expect(result).toHaveProperty('elements');
    expect(result).toHaveProperty('multiplier');
  });

  it('forces Rare+ when pity counter reaches threshold', () => {
    // pityCounter of 9 means next pull is guaranteed Rare+
    let rareOrExoticCount = 0;
    for (let i = 0; i < 50; i++) {
      const result = rollRarity(9);
      if (result.name === 'Rare' || result.name === 'Exotic') rareOrExoticCount++;
    }
    expect(rareOrExoticCount).toBe(50);
  });

  it('returns valid rarity at normal pity', () => {
    const validNames = ['Common', 'Uncommon', 'Rare', 'Exotic'];
    for (let i = 0; i < 20; i++) {
      const result = rollRarity(0);
      expect(validNames).toContain(result.name);
    }
  });
});

describe('rollElement', () => {
  it('returns an element from the rarity tier', () => {
    const tier = { name: 'Uncommon', elements: ['storm', 'venom', 'stone'], multiplier: 2 };
    for (let i = 0; i < 20; i++) {
      const el = rollElement(tier);
      expect(['storm', 'venom', 'stone']).toContain(el);
    }
  });

  it('returns the only element for single-element tiers', () => {
    const tier = { name: 'Rare', elements: ['shadow'], multiplier: 3 };
    expect(rollElement(tier)).toBe('shadow');
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `npx vitest run src/hatcheryEngine.test.js`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement rollRarity and rollElement**

```js
// src/hatcheryEngine.js
import { rarityTiers, SHINY_CHANCE, PITY_THRESHOLD } from './gameData';

export function rollRarity(pityCounter) {
  // Force Rare+ at pity threshold
  if (pityCounter >= PITY_THRESHOLD - 1) {
    const rareAndAbove = rarityTiers.filter(t => t.name === 'Rare' || t.name === 'Exotic');
    const totalChance = rareAndAbove.reduce((sum, t) => sum + t.chance, 0);
    let roll = Math.random() * totalChance;
    for (const tier of rareAndAbove) {
      roll -= tier.chance;
      if (roll <= 0) return tier;
    }
    return rareAndAbove[rareAndAbove.length - 1];
  }

  // Normal roll
  let roll = Math.random();
  for (const tier of rarityTiers) {
    roll -= tier.chance;
    if (roll <= 0) return tier;
  }
  return rarityTiers[rarityTiers.length - 1];
}

export function rollElement(rarityTier) {
  const elements = rarityTier.elements;
  return elements[Math.floor(Math.random() * elements.length)];
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `npx vitest run src/hatcheryEngine.test.js`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/hatcheryEngine.js src/hatcheryEngine.test.js
git commit -m "feat: hatchery engine — rarity roll with pity system"
```

---

## Task 4: Hatchery Engine — Shiny & Pull Resolution

**Files:**
- Modify: `src/hatcheryEngine.js`, `src/hatcheryEngine.test.js`

- [ ] **Step 1: Write failing tests for shiny roll and full pull**

Add to `src/hatcheryEngine.test.js`:

```js
import { rollRarity, rollElement, rollShiny, executePull } from './hatcheryEngine';

describe('rollShiny', () => {
  it('returns boolean', () => {
    expect(typeof rollShiny(false)).toBe('boolean');
  });

  it('always returns true for exotic (guaranteedShiny)', () => {
    for (let i = 0; i < 20; i++) {
      expect(rollShiny(true)).toBe(true);
    }
  });
});

describe('executePull', () => {
  it('returns a pull result with element, rarity, and shiny', () => {
    const result = executePull(0);
    expect(result).toHaveProperty('element');
    expect(result).toHaveProperty('rarityName');
    expect(result).toHaveProperty('rarityMultiplier');
    expect(result).toHaveProperty('shiny');
    expect(result).toHaveProperty('newPityCounter');
    expect(typeof result.element).toBe('string');
    expect(typeof result.shiny).toBe('boolean');
  });

  it('resets pity counter on Rare+ pull', () => {
    // Force pity to 9 — guaranteed Rare+
    const result = executePull(9);
    expect(result.newPityCounter).toBe(0);
  });

  it('increments pity counter on Common/Uncommon pull', () => {
    // Run many pulls at pity 0 — at least some should be Common/Uncommon
    let foundNonRare = false;
    for (let i = 0; i < 100; i++) {
      const result = executePull(0);
      if (result.rarityName === 'Common' || result.rarityName === 'Uncommon') {
        expect(result.newPityCounter).toBe(1);
        foundNonRare = true;
        break;
      }
    }
    expect(foundNonRare).toBe(true);
  });
});
```

- [ ] **Step 2: Run tests to verify new tests fail**

Run: `npx vitest run src/hatcheryEngine.test.js`
Expected: FAIL — `rollShiny` and `executePull` not exported.

- [ ] **Step 3: Implement rollShiny and executePull**

Add to `src/hatcheryEngine.js`:

```js
export function rollShiny(guaranteedShiny) {
  if (guaranteedShiny) return true;
  return Math.random() < SHINY_CHANCE;
}

export function executePull(pityCounter) {
  const rarityTier = rollRarity(pityCounter);
  const element = rollElement(rarityTier);
  const shiny = rollShiny(!!rarityTier.guaranteedShiny);

  const isRarePlus = rarityTier.name === 'Rare' || rarityTier.name === 'Exotic';
  const newPityCounter = isRarePlus ? 0 : pityCounter + 1;

  return {
    element,
    rarityName: rarityTier.name,
    rarityMultiplier: rarityTier.multiplier,
    shiny,
    newPityCounter,
  };
}
```

- [ ] **Step 4: Run tests to verify all pass**

Run: `npx vitest run src/hatcheryEngine.test.js`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/hatcheryEngine.js src/hatcheryEngine.test.js
git commit -m "feat: hatchery engine — shiny roll and full pull resolution"
```

---

## Task 5: Hatchery Engine — Apply Pull to Save

**Files:**
- Modify: `src/hatcheryEngine.js`, `src/hatcheryEngine.test.js`

- [ ] **Step 1: Write failing tests for applyPullResult**

Add to `src/hatcheryEngine.test.js`:

```js
import { rollRarity, rollElement, rollShiny, executePull, applyPullResult } from './hatcheryEngine';

describe('applyPullResult', () => {
  it('unlocks a new dragon', () => {
    const save = {
      dragons: { fire: { level: 1, xp: 0, owned: false, shiny: false } },
      dataScraps: 100,
      pityCounter: 0,
    };
    const pull = { element: 'fire', rarityName: 'Common', rarityMultiplier: 1, shiny: false, newPityCounter: 1 };
    const result = applyPullResult(save, pull);
    expect(result.save.dragons.fire.owned).toBe(true);
    expect(result.isNew).toBe(true);
    expect(result.xpGained).toBe(0);
  });

  it('merges duplicate with XP bonus', () => {
    const save = {
      dragons: { fire: { level: 1, xp: 0, owned: true, shiny: false } },
      dataScraps: 100,
      pityCounter: 0,
    };
    const pull = { element: 'fire', rarityName: 'Uncommon', rarityMultiplier: 2, shiny: false, newPityCounter: 1 };
    const result = applyPullResult(save, pull);
    expect(result.isNew).toBe(false);
    expect(result.xpGained).toBe(100); // 50 * 2
    expect(result.save.dragons.fire.xp).toBe(100);
  });

  it('upgrades to shiny on duplicate shiny pull', () => {
    const save = {
      dragons: { shadow: { level: 5, xp: 20, owned: true, shiny: false } },
      dataScraps: 100,
      pityCounter: 0,
    };
    const pull = { element: 'shadow', rarityName: 'Rare', rarityMultiplier: 3, shiny: true, newPityCounter: 0 };
    const result = applyPullResult(save, pull);
    expect(result.save.dragons.shadow.shiny).toBe(true);
  });

  it('updates pity counter', () => {
    const save = {
      dragons: { fire: { level: 1, xp: 0, owned: false, shiny: false } },
      dataScraps: 100,
      pityCounter: 3,
    };
    const pull = { element: 'fire', rarityName: 'Common', rarityMultiplier: 1, shiny: false, newPityCounter: 4 };
    const result = applyPullResult(save, pull);
    expect(result.save.pityCounter).toBe(4);
  });

  it('levels up dragon when XP exceeds threshold', () => {
    const save = {
      dragons: { fire: { level: 1, xp: 80, owned: true, shiny: false } },
      dataScraps: 100,
      pityCounter: 0,
    };
    const pull = { element: 'fire', rarityName: 'Exotic', rarityMultiplier: 5, shiny: false, newPityCounter: 0 };
    const result = applyPullResult(save, pull);
    // 80 + 250 = 330 => 3 level ups, 30 remaining
    expect(result.save.dragons.fire.level).toBe(4);
    expect(result.save.dragons.fire.xp).toBe(30);
    expect(result.xpGained).toBe(250);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `npx vitest run src/hatcheryEngine.test.js`
Expected: FAIL — `applyPullResult` not exported.

- [ ] **Step 3: Implement applyPullResult**

Add to `src/hatcheryEngine.js`:

```js
export function applyPullResult(save, pull) {
  const newSave = structuredClone(save);
  const dragon = newSave.dragons[pull.element];
  let isNew = false;
  let xpGained = 0;

  if (!dragon.owned) {
    // New dragon
    dragon.owned = true;
    if (pull.shiny) dragon.shiny = true;
    isNew = true;
  } else {
    // Duplicate — merge XP
    xpGained = 50 * pull.rarityMultiplier;
    dragon.xp += xpGained;
    // Level up
    const xpPerLevel = 100;
    while (dragon.xp >= xpPerLevel) {
      dragon.xp -= xpPerLevel;
      dragon.level++;
    }
    // Upgrade to shiny
    if (pull.shiny && !dragon.shiny) {
      dragon.shiny = true;
    }
  }

  newSave.pityCounter = pull.newPityCounter;

  return { save: newSave, isNew, xpGained };
}
```

- [ ] **Step 4: Run tests to verify all pass**

Run: `npx vitest run src/hatcheryEngine.test.js`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/hatcheryEngine.js src/hatcheryEngine.test.js
git commit -m "feat: hatchery engine — apply pull result with duplicate merge and XP"
```

---

## Task 6: Shiny Stat Calculation

**Files:**
- Modify: `src/battleEngine.js`, `src/battleEngine.test.js`

- [ ] **Step 1: Write failing test for shiny stat boost**

Add to `src/battleEngine.test.js`:

```js
describe('calculateStatsForLevel (shiny)', () => {
  it('applies 1.2x multiplier when shiny', () => {
    const base = { hp: 100, atk: 20, def: 20, spd: 20 };
    const result = calculateStatsForLevel(base, 1, true);
    // floor(100 * 1.2) = 120, floor(20 * 1.2) = 24
    expect(result).toEqual({ hp: 120, atk: 24, def: 24, spd: 24 });
  });

  it('applies shiny after level scaling', () => {
    const base = { hp: 100, atk: 20, def: 20, spd: 20 };
    const result = calculateStatsForLevel(base, 5, true);
    // base + 12 = 112, 32, 32, 32 => * 1.2 = 134, 38, 38, 38
    expect(result).toEqual({ hp: 134, atk: 38, def: 38, spd: 38 });
  });

  it('no change when shiny is false', () => {
    const base = { hp: 100, atk: 20, def: 20, spd: 20 };
    const result = calculateStatsForLevel(base, 1, false);
    expect(result).toEqual({ hp: 100, atk: 20, def: 20, spd: 20 });
  });
});
```

- [ ] **Step 2: Run tests to verify new tests fail**

Run: `npx vitest run src/battleEngine.test.js`
Expected: FAIL — `calculateStatsForLevel` called with 3 args but only accepts 2.

- [ ] **Step 3: Update calculateStatsForLevel to accept shiny parameter**

Read `src/battleEngine.js` first. Find `calculateStatsForLevel` and replace:

```js
export function calculateStatsForLevel(baseStats, level, shiny = false) {
  const bonus = (level - 1) * 3;
  const mult = shiny ? 1.2 : 1.0;
  return {
    hp:  Math.floor((baseStats.hp + bonus) * mult),
    atk: Math.floor((baseStats.atk + bonus) * mult),
    def: Math.floor((baseStats.def + bonus) * mult),
    spd: Math.floor((baseStats.spd + bonus) * mult),
  };
}
```

- [ ] **Step 4: Run ALL tests**

Run: `npx vitest run`
Expected: All battle engine tests PASS (old tests unaffected since shiny defaults to false). All hatchery tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/battleEngine.js src/battleEngine.test.js
git commit -m "feat: shiny stat calculation — 1.2x multiplier on calculateStatsForLevel"
```

---

## Task 7: NavBar Component

**Files:**
- Create: `src/NavBar.jsx`

- [ ] **Step 1: Create src/NavBar.jsx**

```jsx
import { loadSave } from './persistence';

export default function NavBar({ activeScreen, onNavigate }) {
  const save = loadSave();

  return (
    <div className="nav-bar">
      <div className="nav-tabs">
        <button
          className={`nav-tab ${activeScreen === 'hatchery' ? 'active' : ''}`}
          onClick={() => onNavigate('hatchery')}
        >
          HATCHERY
        </button>
        <button
          className={`nav-tab ${activeScreen === 'battleSelect' ? 'active' : ''}`}
          onClick={() => onNavigate('battleSelect')}
        >
          BATTLES
        </button>
      </div>
      <div className="nav-scraps">
        ◆ {save.dataScraps}
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add src/NavBar.jsx
git commit -m "feat: NavBar component with hatchery/battles tabs and scraps display"
```

---

## Task 8: DragonSprite Shiny Effect

**Files:**
- Modify: `src/DragonSprite.jsx`, `src/styles.css`

- [ ] **Step 1: Add shiny prop to DragonSprite**

Read `src/DragonSprite.jsx`. Find the function signature and add `shiny = false` prop:

```jsx
export default function DragonSprite({ spriteSheet, stage = 3, flipX = false, forcedFrame = null, className = '', size = null, shiny = false }) {
```

Find the canvas return element and update the style to add shiny effects:

```jsx
  const shinyFilter = shiny
    ? 'drop-shadow(0 0 6px gold) drop-shadow(0 0 12px rgba(255,215,0,0.4))'
    : (stage === 4 ? 'drop-shadow(0 0 8px gold)' : 'none');

  return (
    <canvas
      ref={canvasRef}
      width={width}
      height={height}
      className={`dragon-sprite ${className} ${shiny ? 'shiny-sprite' : ''}`}
      style={{
        imageRendering: 'pixelated',
        filter: shinyFilter,
        width: `${width}px`,
        height: `${height}px`,
      }}
    />
  );
```

- [ ] **Step 2: Add shiny CSS to styles.css**

Read `src/styles.css` and append these styles at the end (before the closing jitter keyframes):

```css
/* === SHINY EFFECTS === */
@keyframes shinyHueRotate {
  from { filter: hue-rotate(0deg) drop-shadow(0 0 6px gold); }
  to { filter: hue-rotate(360deg) drop-shadow(0 0 6px gold); }
}

.shiny-sprite {
  animation: shinyHueRotate 3s linear infinite;
}

.shiny-card {
  border-color: #ffcc00 !important;
  box-shadow: 0 0 12px rgba(255, 204, 0, 0.3);
  animation: shinyCardPulse 2s ease-in-out infinite;
}

@keyframes shinyCardPulse {
  0%, 100% { box-shadow: 0 0 12px rgba(255, 204, 0, 0.3); }
  50% { box-shadow: 0 0 20px rgba(255, 204, 0, 0.6); }
}

.shiny-star {
  color: #ffcc00;
  margin-left: 4px;
}
```

- [ ] **Step 3: Commit**

```bash
git add src/DragonSprite.jsx src/styles.css
git commit -m "feat: shiny dragon visual — hue-rotate animation and gold glow"
```

---

## Task 9: Hatchery CSS & Nav Bar Styles

**Files:**
- Modify: `src/styles.css`

- [ ] **Step 1: Add nav bar and hatchery styles to styles.css**

Read `src/styles.css` and append:

```css
/* === NAV BAR === */
.nav-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 16px;
  background: rgba(0, 0, 0, 0.9);
  border-bottom: 2px solid #333;
}

.nav-tabs {
  display: flex;
  gap: 4px;
}

.nav-tab {
  font-family: 'Press Start 2P', monospace;
  font-size: 9px;
  padding: 8px 16px;
  background: #1a1a2e;
  color: #888;
  border: 1px solid #333;
  border-radius: 4px 4px 0 0;
  cursor: pointer;
  transition: all 0.15s;
}

.nav-tab:hover {
  color: #ccc;
  border-color: #555;
}

.nav-tab.active {
  color: #ff6622;
  border-color: #ff6622;
  border-bottom-color: transparent;
  background: #111118;
}

.nav-scraps {
  font-size: 10px;
  color: #ffcc00;
}

/* === HATCHERY SCREEN === */
.hatchery-screen {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.hatchery-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 20px;
  padding: 20px;
}

.hatchery-title {
  font-size: 14px;
  color: #ff6622;
  text-shadow: 0 0 10px rgba(255, 102, 34, 0.3);
}

.egg-container {
  width: 160px;
  height: 200px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

/* === EGG ANIMATIONS === */
@keyframes eggPulse {
  0%, 100% { transform: scale(1); filter: brightness(1); }
  50% { transform: scale(1.05); filter: brightness(1.3); }
}

@keyframes eggShake {
  0%, 100% { transform: rotate(0deg); }
  10% { transform: rotate(-3deg); }
  20% { transform: rotate(3deg); }
  30% { transform: rotate(-5deg); }
  40% { transform: rotate(5deg); }
  50% { transform: rotate(-8deg); }
  60% { transform: rotate(8deg); }
  70% { transform: rotate(-5deg); }
  80% { transform: rotate(5deg); }
  90% { transform: rotate(-3deg); }
}

@keyframes eggBurst {
  0% { transform: scale(1); opacity: 1; }
  50% { transform: scale(2); opacity: 0.8; }
  100% { transform: scale(3); opacity: 0; }
}

@keyframes revealFadeIn {
  from { opacity: 0; transform: scale(0.5); }
  to { opacity: 1; transform: scale(1); }
}

.egg-sprite {
  width: 120px;
  height: 150px;
  background: radial-gradient(ellipse at 50% 40%, #2a2a3e, #111118);
  border-radius: 50% 50% 50% 50% / 60% 60% 40% 40%;
  border: 2px solid #444;
  position: relative;
}

.egg-pulse {
  animation: eggPulse 1s ease-in-out infinite;
}

.egg-shake {
  animation: eggShake 0.8s ease-in-out;
}

.egg-burst {
  position: absolute;
  inset: -50px;
  border-radius: 50%;
  animation: eggBurst 0.4s ease-out forwards;
  pointer-events: none;
}

.reveal-result {
  animation: revealFadeIn 0.3s ease-out;
  text-align: center;
}

.reveal-rarity {
  font-size: 8px;
  margin-top: 6px;
  text-transform: uppercase;
}

.reveal-rarity.Common { color: #888; }
.reveal-rarity.Uncommon { color: #44aaff; }
.reveal-rarity.Rare { color: #aa66ff; }
.reveal-rarity.Exotic { color: #ffcc00; }

.reveal-badge {
  font-size: 10px;
  margin-top: 8px;
  padding: 4px 12px;
  border-radius: 4px;
}

.reveal-badge.new-badge {
  color: #44ff44;
  border: 1px solid #44ff44;
}

.reveal-badge.xp-badge {
  color: #44aaff;
  border: 1px solid #44aaff;
}

.reveal-badge.shiny-badge {
  color: #ffcc00;
  border: 1px solid #ffcc00;
  animation: shinyCardPulse 1.5s ease-in-out infinite;
}

.pity-hint {
  font-size: 8px;
  color: #666;
}

.pull-buttons {
  display: flex;
  gap: 12px;
}

.pull-btn {
  font-family: 'Press Start 2P', monospace;
  font-size: 10px;
  padding: 12px 20px;
  background: #1a1a2e;
  color: #ff6622;
  border: 2px solid #ff6622;
  cursor: pointer;
  transition: all 0.2s;
}

.pull-btn:hover:not(:disabled) {
  background: #ff6622;
  color: #111118;
}

.pull-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
  border-color: #444;
  color: #444;
}

/* === 10x PULL GRID === */
.pull-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 8px;
  max-width: 600px;
}

.pull-grid-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px;
  background: #1a1a2e;
  border: 1px solid #333;
  border-radius: 4px;
  font-size: 7px;
}

.pull-grid-card .card-element {
  margin-top: 4px;
}

.pull-grid-card .card-badge {
  font-size: 6px;
  margin-top: 2px;
}
```

- [ ] **Step 2: Commit**

```bash
git add src/styles.css
git commit -m "feat: hatchery CSS — nav bar, egg animations, reveal effects, pull grid"
```

---

## Task 10: Battle Reward Integration

**Files:**
- Modify: `src/BattleScreen.jsx`

- [ ] **Step 1: Update BattleScreen to award scraps on victory**

Read `src/BattleScreen.jsx`. Make these changes:

Add import at top:
```jsx
import { loadSave, saveDragonProgress, addScraps } from './persistence';
```

In the victory handler section (inside `handleMoveSelect`, after the XP calculation), add scraps award. Find the block that starts with `if (result.npc.hp <= 0)` and update it:

```jsx
    if (result.npc.hp <= 0) {
      const xpGained = calculateXpGain(state.npc.baseXP, state.playerLevel, state.npc.level);
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

      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
      await wait(600);
      dispatch({ type: 'SET_VICTORY', xpGained, leveledUp, newLevel, scrapsGained });
```

Update the `SET_VICTORY` reducer case to include scrapsGained:
```jsx
    case 'SET_VICTORY':
      return { ...state, phase: PHASES.VICTORY, xpGained: action.xpGained, leveledUp: action.leveledUp, newLevel: action.newLevel, scrapsGained: action.scrapsGained || 0 };
```

Add `scrapsGained: 0` to `initBattle` return object.

Update the victory overlay JSX to show scraps:
```jsx
      {state.phase === PHASES.VICTORY && (
        <div className="result-overlay victory">
          <h2>VICTORY!</h2>
          <div className="xp-display">+{state.xpGained} XP</div>
          {state.scrapsGained > 0 && (
            <div className="xp-display" style={{ color: '#ffcc00' }}>+{state.scrapsGained} ◆</div>
          )}
          {state.leveledUp && (
            <div className="level-up-display">LEVEL UP! Now Lv.{state.newLevel}</div>
          )}
          <button className="result-btn" onClick={onBattleEnd}>CONTINUE</button>
        </div>
      )}
```

- [ ] **Step 2: Verify build**

Run: `npx vite build`
Expected: Clean build.

- [ ] **Step 3: Commit**

```bash
git add src/BattleScreen.jsx
git commit -m "feat: award dataScraps on battle victory, show in victory overlay"
```

---

## Task 11: Battle Select — Owned Filter & Locked Silhouettes

**Files:**
- Modify: `src/BattleSelectScreen.jsx`

- [ ] **Step 1: Update BattleSelectScreen**

Read `src/BattleSelectScreen.jsx`. Make these changes:

Add NavBar import:
```jsx
import NavBar from './NavBar';
```

Add `onNavigate` prop to the component:
```jsx
export default function BattleSelectScreen({ onBeginBattle, onNavigate }) {
```

Add the NavBar at the top of the returned JSX (inside the `battle-select` div, before the header):
```jsx
      <NavBar activeScreen="battleSelect" onNavigate={onNavigate} />
```

Update the dragon list rendering to show owned vs locked:
```jsx
          {dragonList.map((dragon) => {
            const progress = save.dragons[dragon.id] || { level: 1, xp: 0, owned: false, shiny: false };
            const isOwned = progress.owned;
            const stage = getStageForLevel(progress.level);
            const stats = calculateStatsForLevel(dragon.baseStats, progress.level, progress.shiny);
            const color = elementColors[dragon.element];

            if (!isOwned) {
              return (
                <div key={dragon.id} className="select-card" style={{ opacity: 0.4, cursor: 'default' }}>
                  <div style={{ width: 130, height: 90, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <div style={{ fontSize: 24, color: '#333' }}>?</div>
                  </div>
                  <div className="select-card-info">
                    <div className="select-card-name" style={{ color: '#444' }}>???</div>
                    <div className="select-card-stats">LOCKED — Pull from Hatchery</div>
                  </div>
                </div>
              );
            }

            return (
              <div
                key={dragon.id}
                className={`select-card ${selectedDragon?.id === dragon.id ? 'selected' : ''} ${progress.shiny ? 'shiny-card' : ''}`}
                style={{ borderColor: selectedDragon?.id === dragon.id ? color.primary : undefined }}
                onClick={() => setSelectedDragon(dragon)}
              >
                <div style={{ width: 130, height: 90, overflow: 'hidden', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <DragonSprite spriteSheet={dragon.spriteSheet} stage={stage} size={{ width: 130, height: 90 }} shiny={progress.shiny} />
                </div>
                <div className="select-card-info">
                  <div className="select-card-name" style={{ color: color.primary }}>
                    {dragon.name}{progress.shiny && <span className="shiny-star">★</span>}
                  </div>
                  <div className="select-card-stats">
                    Lv.{progress.level} | HP:{stats.hp} ATK:{stats.atk} DEF:{stats.def} SPD:{stats.spd}
                  </div>
                </div>
              </div>
            );
          })}
```

- [ ] **Step 2: Commit**

```bash
git add src/BattleSelectScreen.jsx
git commit -m "feat: battle select shows owned dragons only, locked silhouettes, shiny stars"
```

---

## Task 12: Hatchery Screen

**Files:**
- Create: `src/HatcheryScreen.jsx`

- [ ] **Step 1: Create src/HatcheryScreen.jsx**

```jsx
import { useState, useCallback } from 'react';
import { dragons, elementColors, PULL_COST } from './gameData';
import { executePull, applyPullResult } from './hatcheryEngine';
import { loadSave, writeSave } from './persistence';
import NavBar from './NavBar';
import DragonSprite from './DragonSprite';

const ANIM_PHASES = {
  IDLE: 'idle',
  EGG_APPEAR: 'eggAppear',
  EGG_SHAKE: 'eggShake',
  BURST: 'burst',
  REVEAL: 'reveal',
  GRID: 'grid',
};

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export default function HatcheryScreen({ onNavigate }) {
  const [phase, setPhase] = useState(ANIM_PHASES.IDLE);
  const [currentResult, setCurrentResult] = useState(null);
  const [gridResults, setGridResults] = useState([]);
  const [burstColor, setBurstColor] = useState('#fff');
  const [save, setSave] = useState(() => loadSave());
  const [skipped, setSkipped] = useState(false);

  const refreshSave = () => setSave(loadSave());

  const isFirstGame = Object.values(save.dragons).every(d => !d.owned);
  const canPull1 = isFirstGame || save.dataScraps >= PULL_COST;
  const canPull10 = save.dataScraps >= PULL_COST * 10;
  const pityRemaining = 10 - save.pityCounter;

  const animateSinglePull = useCallback(async (pullResult, applyResult, skipAnim = false) => {
    const color = elementColors[pullResult.element]?.glow || '#fff';
    setBurstColor(color);

    if (!skipAnim) {
      setPhase(ANIM_PHASES.EGG_APPEAR);
      await wait(300);

      setPhase(ANIM_PHASES.EGG_SHAKE);
      await wait(800);

      setPhase(ANIM_PHASES.BURST);
      await wait(400);
    }

    setCurrentResult({ pull: pullResult, apply: applyResult });
    setPhase(ANIM_PHASES.REVEAL);
  }, []);

  const handleSkip = () => {
    if (phase === ANIM_PHASES.EGG_APPEAR || phase === ANIM_PHASES.EGG_SHAKE || phase === ANIM_PHASES.BURST) {
      setSkipped(true);
    }
  };

  const handlePull1 = async () => {
    if (phase !== ANIM_PHASES.IDLE && phase !== ANIM_PHASES.REVEAL && phase !== ANIM_PHASES.GRID) return;

    let currentSave = loadSave();

    // Deduct cost (free for first game)
    if (!isFirstGame) {
      if (currentSave.dataScraps < PULL_COST) return;
      currentSave.dataScraps -= PULL_COST;
    }

    const pull = executePull(currentSave.pityCounter);
    const result = applyPullResult(currentSave, pull);
    writeSave(result.save);
    refreshSave();
    setGridResults([]);
    setSkipped(false);

    await animateSinglePull(pull, result);
  };

  const handlePull10 = async () => {
    if (phase !== ANIM_PHASES.IDLE && phase !== ANIM_PHASES.REVEAL && phase !== ANIM_PHASES.GRID) return;

    let currentSave = loadSave();
    if (currentSave.dataScraps < PULL_COST * 10) return;
    currentSave.dataScraps -= PULL_COST * 10;

    const results = [];
    for (let i = 0; i < 10; i++) {
      const pull = executePull(currentSave.pityCounter);
      const result = applyPullResult(currentSave, pull);
      currentSave = result.save;
      results.push({ pull, apply: result });
    }

    writeSave(currentSave);
    refreshSave();
    setSkipped(false);

    // Animate first pull
    const first = results[0];
    setGridResults([]);
    await animateSinglePull(first.pull, first.apply);

    // Show remaining as grid
    await wait(300);
    setGridResults(results);
    setPhase(ANIM_PHASES.GRID);
  };

  const handleDismiss = () => {
    setPhase(ANIM_PHASES.IDLE);
    setCurrentResult(null);
    setGridResults([]);
    refreshSave();
  };

  return (
    <div className="hatchery-screen">
      <NavBar activeScreen="hatchery" onNavigate={onNavigate} />

      <div className="hatchery-content" onClick={phase === ANIM_PHASES.REVEAL || phase === ANIM_PHASES.GRID ? handleDismiss : handleSkip}>
        <div className="hatchery-title">QUANTUM INCUBATION LAB</div>

        <div className="egg-container">
          {phase === ANIM_PHASES.IDLE && (
            <div className="egg-sprite egg-pulse" />
          )}
          {phase === ANIM_PHASES.EGG_APPEAR && (
            <div className="egg-sprite egg-pulse" />
          )}
          {phase === ANIM_PHASES.EGG_SHAKE && (
            <div className="egg-sprite egg-shake" />
          )}
          {phase === ANIM_PHASES.BURST && (
            <div style={{ position: 'relative', width: 120, height: 150 }}>
              <div className="egg-burst" style={{ background: `radial-gradient(circle, ${burstColor}, transparent)` }} />
            </div>
          )}
          {phase === ANIM_PHASES.REVEAL && currentResult && (
            <div className="reveal-result">
              <DragonSprite
                spriteSheet={dragons[currentResult.pull.element].spriteSheet}
                stage={1}
                size={{ width: 160, height: 120 }}
                shiny={currentResult.pull.shiny}
              />
              <div style={{ color: elementColors[currentResult.pull.element]?.glow, fontSize: 11, marginTop: 8 }}>
                {dragons[currentResult.pull.element].name}
                {currentResult.pull.shiny && <span className="shiny-star">★</span>}
              </div>
              <div className={`reveal-rarity ${currentResult.pull.rarityName}`}>
                {currentResult.pull.rarityName}
              </div>
              {currentResult.apply.isNew ? (
                <div className="reveal-badge new-badge">NEW!</div>
              ) : (
                <div className="reveal-badge xp-badge">+{currentResult.apply.xpGained} XP</div>
              )}
              {currentResult.pull.shiny && (
                <div className="reveal-badge shiny-badge">+20% STATS</div>
              )}
            </div>
          )}
          {phase === ANIM_PHASES.GRID && (
            <div className="reveal-result">
              <div style={{ fontSize: 9, color: '#888', marginBottom: 8 }}>10x PULL RESULTS</div>
              <div className="pull-grid">
                {gridResults.map((r, i) => {
                  const dragon = dragons[r.pull.element];
                  const color = elementColors[r.pull.element];
                  return (
                    <div key={i} className={`pull-grid-card ${r.pull.shiny ? 'shiny-card' : ''}`}>
                      <DragonSprite
                        spriteSheet={dragon.spriteSheet}
                        stage={1}
                        size={{ width: 60, height: 45 }}
                        shiny={r.pull.shiny}
                      />
                      <div className="card-element" style={{ color: color?.glow }}>{dragon.name.split(' ')[0]}</div>
                      <div className={`card-badge ${r.apply.isNew ? 'new-badge' : 'xp-badge'}`}>
                        {r.apply.isNew ? 'NEW' : `+${r.apply.xpGained}XP`}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        {pityRemaining < 10 && pityRemaining > 0 && phase === ANIM_PHASES.IDLE && (
          <div className="pity-hint">Rare+ guaranteed in {pityRemaining} pulls</div>
        )}

        {(phase === ANIM_PHASES.IDLE || phase === ANIM_PHASES.REVEAL || phase === ANIM_PHASES.GRID) && (
          <div className="pull-buttons">
            <button className="pull-btn" disabled={!canPull1} onClick={handlePull1}>
              {isFirstGame ? 'FREE PULL' : `PULL x1 — ${PULL_COST}◆`}
            </button>
            {!isFirstGame && (
              <button className="pull-btn" disabled={!canPull10} onClick={handlePull10}>
                PULL x10 — {PULL_COST * 10}◆
              </button>
            )}
          </div>
        )}

        {(phase === ANIM_PHASES.REVEAL || phase === ANIM_PHASES.GRID) && (
          <div style={{ fontSize: 8, color: '#555', marginTop: 8 }}>Click anywhere to dismiss</div>
        )}
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add src/HatcheryScreen.jsx
git commit -m "feat: hatchery screen with egg animation, pull UI, reveal sequence, 10x grid"
```

---

## Task 13: App.jsx — Wire Up Navigation

**Files:**
- Modify: `src/App.jsx`

- [ ] **Step 1: Update App.jsx with hatchery screen and navigation**

Read `src/App.jsx` first, then replace with:

```jsx
import { useState } from 'react';
import TitleScreen from './TitleScreen';
import BattleSelectScreen from './BattleSelectScreen';
import BattleScreen from './BattleScreen';
import HatcheryScreen from './HatcheryScreen';

const SCREENS = {
  TITLE: 'title',
  HATCHERY: 'hatchery',
  BATTLE_SELECT: 'battleSelect',
  BATTLE: 'battle',
};

export default function App() {
  const [screen, setScreen] = useState(SCREENS.TITLE);
  const [battleConfig, setBattleConfig] = useState(null);

  function handleStartGame() {
    setScreen(SCREENS.HATCHERY);
  }

  function handleNavigate(target) {
    if (target === 'hatchery') setScreen(SCREENS.HATCHERY);
    else if (target === 'battleSelect') setScreen(SCREENS.BATTLE_SELECT);
  }

  function handleBeginBattle(config) {
    setBattleConfig(config);
    setScreen(SCREENS.BATTLE);
  }

  function handleBattleEnd() {
    setBattleConfig(null);
    setScreen(SCREENS.BATTLE_SELECT);
  }

  return (
    <div className="app">
      {screen === SCREENS.TITLE && (
        <TitleScreen onStart={handleStartGame} />
      )}
      {screen === SCREENS.HATCHERY && (
        <HatcheryScreen onNavigate={handleNavigate} />
      )}
      {screen === SCREENS.BATTLE_SELECT && (
        <BattleSelectScreen onBeginBattle={handleBeginBattle} onNavigate={handleNavigate} />
      )}
      {screen === SCREENS.BATTLE && battleConfig && (
        <BattleScreen
          dragonId={battleConfig.dragonId}
          npcId={battleConfig.npcId}
          onBattleEnd={handleBattleEnd}
        />
      )}
    </div>
  );
}
```

- [ ] **Step 2: Verify build**

Run: `npx vite build`
Expected: Clean build.

- [ ] **Step 3: Commit**

```bash
git add src/App.jsx
git commit -m "feat: wire up hatchery screen and nav bar navigation in App"
```

---

## Task 14: Final Verification

**Files:** None (verification only)

- [ ] **Step 1: Run all tests**

Run: `npx vitest run`
Expected: All battle engine tests PASS. All hatchery engine tests PASS.

- [ ] **Step 2: Run production build**

Run: `npm run build`
Expected: Clean build, no errors.

- [ ] **Step 3: Full playthrough verification**

Run: `npm run dev`
Manual verification:
1. Title screen → "ENTER THE FORGE" → lands on Hatchery
2. First visit: "FREE PULL" button available. Click it.
3. Egg animation plays (pulse → shake → burst → reveal)
4. Dragon revealed with "NEW!" badge. Scraps show 0.
5. Navigate to BATTLES tab. The pulled dragon appears in the roster. Others show as locked "???"
6. Fight Firewall Sentinel and win. Verify scraps awarded ("+30 ◆" in victory overlay)
7. Navigate back to HATCHERY. Verify scraps balance updated.
8. Buy another pull. If same element, verify "+XP" badge and level progress.
9. If different element, verify "NEW!" badge and it appears in battle select.
10. Verify pity counter hint: "Rare+ guaranteed in X pulls"
11. Test 10x pull (need 500 scraps — may need several battles)
12. Verify shiny dragon gets ★ icon and rainbow animation

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: Dragon Forge hatchery milestone complete — gacha system fully playable"
```
