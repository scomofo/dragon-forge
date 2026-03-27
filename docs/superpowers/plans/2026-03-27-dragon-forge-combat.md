# Dragon Forge: Combat-First Milestone Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable 1v1 turn-based dragon combat game with 6 player dragons, 4 NPC enemies, type effectiveness, XP/leveling, and full pixel-art visual polish.

**Architecture:** React 18 SPA via Vite. Pure-function battle engine (`battleEngine.js`) handles all combat math and state transitions. React components handle rendering and animation. State managed via `useReducer` in BattleScreen. Dragon progress persisted to localStorage.

**Tech Stack:** React 18, Vite, Vitest (for engine tests), CSS (no libraries), localStorage

---

## File Map

| File | Responsibility |
|---|---|
| `package.json` | Dependencies: react, react-dom, vite, @vitejs/plugin-react, vitest |
| `vite.config.js` | Vite config with React plugin and test config |
| `index.html` | Entry point, mounts React root |
| `src/main.jsx` | React DOM render entry |
| `src/App.jsx` | Root component, screen switching via state |
| `src/gameData.js` | All dragon stats, NPC stats, moves, type chart |
| `src/battleEngine.js` | Pure logic: damage calc, type effectiveness, turn resolution, XP, NPC AI |
| `src/sprites.js` | Sprite sheet frame configs, animation timing constants |
| `src/TitleScreen.jsx` | Felix intro with typewriter text |
| `src/BattleSelectScreen.jsx` | Dragon picker + NPC picker + matchup indicator |
| `src/BattleScreen.jsx` | Full battle: arena, sprites, HP bars, move panel, animations |
| `src/DragonSprite.jsx` | Animated sprite sheet component for player dragons |
| `src/NpcSprite.jsx` | NPC sprite with idle/attack swap |
| `src/DamageNumber.jsx` | Floating damage number with CSS animation |
| `src/persistence.js` | localStorage read/write for dragon progress |
| `src/styles.css` | Global styles: CRT, pixelated, UI chrome, animations |
| `src/battleEngine.test.js` | Tests for all battle engine logic |
| `assets/arenas/` | 6 arena backgrounds (copied from handoff/) |
| `assets/dragons/` | 6 dragon sprite sheets (copied from handoff/) |
| `assets/npc/` | NPC idle + attack sprites (copied from handoff/npc/) |
| `assets/felix_pixel.jpg` | Professor Felix portrait (copied from handoff/) |

---

## Task 1: Project Scaffolding

**Files:**
- Create: `package.json`, `vite.config.js`, `index.html`, `src/main.jsx`, `src/App.jsx`

- [ ] **Step 1: Initialize the project with package.json**

```json
{
  "name": "dragon-forge",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.3.4",
    "vite": "^6.0.0",
    "vitest": "^3.0.0"
  }
}
```

Write this to `package.json` in the project root (`df/`).

- [ ] **Step 2: Create vite.config.js**

```js
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'node',
  },
});
```

- [ ] **Step 3: Create index.html**

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Dragon Forge</title>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap" rel="stylesheet" />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
```

- [ ] **Step 4: Create src/main.jsx**

```jsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './styles.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

- [ ] **Step 5: Create src/App.jsx with placeholder screen switching**

```jsx
import { useState } from 'react';

const SCREENS = {
  TITLE: 'title',
  BATTLE_SELECT: 'battleSelect',
  BATTLE: 'battle',
};

export default function App() {
  const [screen, setScreen] = useState(SCREENS.TITLE);
  const [battleConfig, setBattleConfig] = useState(null);

  function handleStartGame() {
    setScreen(SCREENS.BATTLE_SELECT);
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
        <div className="placeholder-screen">
          <h1>DRAGON FORGE</h1>
          <button onClick={handleStartGame}>ENTER THE FORGE</button>
        </div>
      )}
      {screen === SCREENS.BATTLE_SELECT && (
        <div className="placeholder-screen">
          <h1>SELECT YOUR DRAGON</h1>
          <button onClick={() => handleBeginBattle({ dragonId: 'fire', npcId: 'firewall_sentinel' })}>
            BEGIN BATTLE (placeholder)
          </button>
        </div>
      )}
      {screen === SCREENS.BATTLE && (
        <div className="placeholder-screen">
          <h1>BATTLE (placeholder)</h1>
          <p>Config: {JSON.stringify(battleConfig)}</p>
          <button onClick={handleBattleEnd}>END BATTLE</button>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 6: Create minimal src/styles.css**

```css
@import url('https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap');

*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  background: #111118;
  color: #e0e0e0;
  font-family: 'Press Start 2P', monospace;
  font-size: 10px;
  overflow: hidden;
  height: 100vh;
  width: 100vw;
}

#root {
  height: 100vh;
  width: 100vw;
}

.app {
  height: 100%;
  width: 100%;
  position: relative;
}

.placeholder-screen {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  gap: 20px;
}

.placeholder-screen button {
  font-family: 'Press Start 2P', monospace;
  font-size: 10px;
  padding: 12px 24px;
  background: #1a1a2e;
  color: #e0e0e0;
  border: 1px solid #444;
  cursor: pointer;
}

.placeholder-screen button:hover {
  border-color: #ff6622;
  color: #ff8844;
}
```

- [ ] **Step 7: Install dependencies and verify dev server starts**

Run: `npm install`
Expected: `node_modules/` created, no errors.

Run: `npm run dev`
Expected: Vite dev server starts on http://localhost:5173. Browser shows "DRAGON FORGE" title with "ENTER THE FORGE" button. Clicking through screens works.

- [ ] **Step 8: Commit**

```bash
git init
echo "node_modules/" > .gitignore
echo ".superpowers/" >> .gitignore
echo "dist/" >> .gitignore
git add package.json vite.config.js index.html src/main.jsx src/App.jsx src/styles.css .gitignore
git commit -m "feat: scaffold Dragon Forge project with Vite + React 18"
```

---

## Task 2: Asset Setup

**Files:**
- Create: `assets/arenas/`, `assets/dragons/`, `assets/npc/`, `assets/felix_pixel.jpg`

- [ ] **Step 1: Create asset directories and copy files**

```bash
mkdir -p assets/arenas assets/dragons assets/npc

# Arenas — the 6 arena backgrounds
cp handoff/magma.png assets/arenas/magma.png
cp handoff/ice.png assets/arenas/ice.png
cp handoff/lightning.png assets/arenas/lightning.png
cp handoff/stone.png assets/arenas/stone.png
cp handoff/venom.png assets/arenas/venom.png
cp handoff/shadow.png assets/arenas/shadow.png

# Dragons — same source files, different destination
cp handoff/magma.png assets/dragons/magma.png
cp handoff/ice.png assets/dragons/ice.png
cp handoff/lightning.png assets/dragons/lightning.png
cp handoff/stone.png assets/dragons/stone.png
cp handoff/venom.png assets/dragons/venom.png
cp handoff/shadow.png assets/dragons/shadow.png

# NPCs
cp handoff/npc/firewall_sentinel_sprites.png assets/npc/
cp handoff/npc/firewall_sentinel_attack.png assets/npc/
cp handoff/npc/bit_wraith_sprites.png assets/npc/
cp handoff/npc/bit_wraith_attack.png assets/npc/
cp handoff/npc/glitch_hydra_sprites.png assets/npc/
cp handoff/npc/glitch_hydra_attack.png assets/npc/
cp handoff/npc/recursive_golem_sprites.png assets/npc/
cp handoff/npc/recursive_golem_attack.png assets/npc/

# Felix portrait
cp handoff/felix_pixel.jpg assets/felix_pixel.jpg
```

**Important note:** The handoff dragon sprite sheets (e.g., `magma.png`) serve double duty — they ARE both the dragon sprites AND have the same filenames as the arena concepts. The actual arena background images may be different assets if dedicated arena art exists. If the same file is truly both arena and dragon sheet, the arenas directory can use them as-is (the green-screen background will need CSS treatment) or placeholder solid-color gradients can stand in until dedicated arena art is provided. Verify by inspecting: the dragon sheets have green backgrounds with sprite frames — they are NOT arena backgrounds. The arena files listed in the spec (`magma.jpg` etc.) may be separate assets not yet provided. If so, create placeholder arena backgrounds.

- [ ] **Step 2: Verify assets are accessible from Vite**

Create a quick test — temporarily add an image to `App.jsx`:

```jsx
// Add at top of the placeholder title screen div, temporarily:
<img src="/assets/dragons/magma.png" alt="test" style={{ width: 200, imageRendering: 'pixelated' }} />
```

Run: `npm run dev`
Expected: Magma dragon sprite sheet visible in browser. Remove the test image after confirming.

- [ ] **Step 3: Commit**

```bash
git add assets/
git commit -m "feat: add game assets — arenas, dragon sprites, NPC sprites, Felix portrait"
```

---

## Task 3: Game Data

**Files:**
- Create: `src/gameData.js`

- [ ] **Step 1: Create src/gameData.js with complete game data**

```js
// === ELEMENTS ===
export const ELEMENTS = ['fire', 'ice', 'storm', 'stone', 'venom', 'shadow'];

// === TYPE EFFECTIVENESS ===
// typeChart[attacker][defender] = multiplier
export const typeChart = {
  fire:   { fire: 0.5, ice: 2.0, storm: 1.0, stone: 0.5, venom: 2.0, shadow: 1.0 },
  ice:    { fire: 0.5, ice: 0.5, storm: 2.0, stone: 1.0, venom: 1.0, shadow: 2.0 },
  storm:  { fire: 1.0, ice: 0.5, storm: 0.5, stone: 2.0, venom: 1.0, shadow: 2.0 },
  stone:  { fire: 2.0, ice: 1.0, storm: 0.5, stone: 0.5, venom: 2.0, shadow: 1.0 },
  venom:  { fire: 0.5, ice: 1.0, storm: 1.0, stone: 0.5, venom: 0.5, shadow: 2.0 },
  shadow: { fire: 1.0, ice: 0.5, storm: 0.5, stone: 1.0, venom: 0.5, shadow: 0.5 },
};

// === STAGE MULTIPLIERS ===
export const stageMultipliers = { 1: 0.5, 2: 0.75, 3: 1.0, 4: 1.4 };

// === STAGE THRESHOLDS ===
export const stageThresholds = { 2: 10, 3: 25, 4: 50 };

// === MOVES ===
export const moves = {
  // Fire
  magma_breath:     { name: 'Magma Breath',     element: 'fire',   power: 65, accuracy: 95, vfxKey: 'MAGMA_BREATH' },
  flame_wall:       { name: 'Flame Wall',        element: 'fire',   power: 55, accuracy: 100, vfxKey: 'FLAME_WALL' },
  // Ice
  frost_bite:       { name: 'Frost Bite',        element: 'ice',    power: 60, accuracy: 100, vfxKey: 'FROST_BITE' },
  blizzard:         { name: 'Blizzard',          element: 'ice',    power: 70, accuracy: 85, vfxKey: 'BLIZZARD' },
  // Storm
  lightning_strike: { name: 'Lightning Strike',  element: 'storm',  power: 70, accuracy: 90, vfxKey: 'LIGHTNING_STRIKE' },
  thunder_clap:     { name: 'Thunder Clap',      element: 'storm',  power: 55, accuracy: 100, vfxKey: 'THUNDER_CLAP' },
  // Stone
  rock_slide:       { name: 'Rock Slide',        element: 'stone',  power: 60, accuracy: 95, vfxKey: 'ROCK_SLIDE' },
  earthquake:       { name: 'Earthquake',        element: 'stone',  power: 75, accuracy: 85, vfxKey: 'EARTHQUAKE' },
  // Venom
  acid_spit:        { name: 'Acid Spit',         element: 'venom',  power: 60, accuracy: 100, vfxKey: 'ACID_SPIT' },
  toxic_cloud:      { name: 'Toxic Cloud',       element: 'venom',  power: 70, accuracy: 85, vfxKey: 'TOXIC_CLOUD' },
  // Shadow
  shadow_strike:    { name: 'Shadow Strike',     element: 'shadow', power: 65, accuracy: 95, vfxKey: 'SHADOW_STRIKE' },
  void_pulse:       { name: 'Void Pulse',        element: 'shadow', power: 75, accuracy: 85, vfxKey: 'VOID_PULSE' },
  // Neutral
  basic_attack:     { name: 'Basic Attack',      element: 'neutral', power: 40, accuracy: 100, vfxKey: 'BASIC_ATTACK' },
};

// === PLAYER DRAGONS ===
export const dragons = {
  fire: {
    id: 'fire',
    name: 'Magma Dragon',
    element: 'fire',
    baseStats: { hp: 110, atk: 28, def: 20, spd: 18 },
    moveKeys: ['magma_breath', 'flame_wall'],
    spriteSheet: '/assets/dragons/magma.png',
  },
  ice: {
    id: 'ice',
    name: 'Ice Dragon',
    element: 'ice',
    baseStats: { hp: 100, atk: 24, def: 26, spd: 20 },
    moveKeys: ['frost_bite', 'blizzard'],
    spriteSheet: '/assets/dragons/ice.png',
  },
  storm: {
    id: 'storm',
    name: 'Storm Dragon',
    element: 'storm',
    baseStats: { hp: 90, atk: 30, def: 16, spd: 28 },
    moveKeys: ['lightning_strike', 'thunder_clap'],
    spriteSheet: '/assets/dragons/lightning.png',
  },
  stone: {
    id: 'stone',
    name: 'Stone Dragon',
    element: 'stone',
    baseStats: { hp: 120, atk: 22, def: 30, spd: 12 },
    moveKeys: ['rock_slide', 'earthquake'],
    spriteSheet: '/assets/dragons/stone.png',
  },
  venom: {
    id: 'venom',
    name: 'Venom Dragon',
    element: 'venom',
    baseStats: { hp: 95, atk: 26, def: 18, spd: 24 },
    moveKeys: ['acid_spit', 'toxic_cloud'],
    spriteSheet: '/assets/dragons/venom.png',
  },
  shadow: {
    id: 'shadow',
    name: 'Shadow Dragon',
    element: 'shadow',
    baseStats: { hp: 85, atk: 32, def: 14, spd: 26 },
    moveKeys: ['shadow_strike', 'void_pulse'],
    spriteSheet: '/assets/dragons/shadow.png',
  },
};

// === NPC ENEMIES ===
export const npcs = {
  firewall_sentinel: {
    id: 'firewall_sentinel',
    name: 'Firewall Sentinel',
    element: 'stone',
    level: 5,
    stats: { hp: 130, atk: 18, def: 32, spd: 8 },
    moveKeys: ['rock_slide', 'earthquake'],
    difficulty: 'Easy',
    baseXP: 30,
    idleSprite: '/assets/npc/firewall_sentinel_sprites.png',
    attackSprite: '/assets/npc/firewall_sentinel_attack.png',
    arena: '/assets/arenas/stone.png',
  },
  bit_wraith: {
    id: 'bit_wraith',
    name: 'Bit Wraith',
    element: 'shadow',
    level: 10,
    stats: { hp: 75, atk: 34, def: 12, spd: 30 },
    moveKeys: ['shadow_strike', 'void_pulse'],
    difficulty: 'Medium',
    baseXP: 50,
    idleSprite: '/assets/npc/bit_wraith_sprites.png',
    attackSprite: '/assets/npc/bit_wraith_attack.png',
    arena: '/assets/arenas/shadow.png',
  },
  glitch_hydra: {
    id: 'glitch_hydra',
    name: 'Glitch Hydra',
    element: 'storm',
    level: 18,
    stats: { hp: 110, atk: 30, def: 20, spd: 22 },
    moveKeys: ['lightning_strike', 'thunder_clap'],
    difficulty: 'Hard',
    baseXP: 80,
    idleSprite: '/assets/npc/glitch_hydra_sprites.png',
    attackSprite: '/assets/npc/glitch_hydra_attack.png',
    arena: '/assets/arenas/lightning.png',
  },
  recursive_golem: {
    id: 'recursive_golem',
    name: 'Recursive Golem',
    element: 'stone',
    level: 25,
    stats: { hp: 180, atk: 28, def: 38, spd: 6 },
    moveKeys: ['rock_slide', 'earthquake'],
    difficulty: 'Boss',
    baseXP: 120,
    idleSprite: '/assets/npc/recursive_golem_sprites.png',
    attackSprite: '/assets/npc/recursive_golem_attack.png',
    arena: '/assets/arenas/stone.png',
  },
};

// === ELEMENT COLORS (for UI) ===
export const elementColors = {
  fire:    { primary: '#ff6622', glow: '#ff8844' },
  ice:     { primary: '#44aaff', glow: '#66ccff' },
  storm:   { primary: '#aa66ff', glow: '#cc88ff' },
  stone:   { primary: '#aa8844', glow: '#ccaa66' },
  venom:   { primary: '#44cc44', glow: '#66ee66' },
  shadow:  { primary: '#8844aa', glow: '#aa66cc' },
  neutral: { primary: '#888888', glow: '#aaaaaa' },
};
```

- [ ] **Step 2: Commit**

```bash
git add src/gameData.js
git commit -m "feat: add complete game data — dragons, NPCs, moves, type chart"
```

---

## Task 4: Battle Engine — Type Effectiveness & Damage

**Files:**
- Create: `src/battleEngine.js`, `src/battleEngine.test.js`

- [ ] **Step 1: Write failing tests for type effectiveness lookup**

```js
// src/battleEngine.test.js
import { describe, it, expect } from 'vitest';
import { getTypeEffectiveness, calculateDamage } from './battleEngine';

describe('getTypeEffectiveness', () => {
  it('returns 2.0 for fire attacking ice', () => {
    expect(getTypeEffectiveness('fire', 'ice')).toBe(2.0);
  });

  it('returns 0.5 for fire attacking stone', () => {
    expect(getTypeEffectiveness('fire', 'stone')).toBe(0.5);
  });

  it('returns 1.0 for neutral element', () => {
    expect(getTypeEffectiveness('neutral', 'fire')).toBe(1.0);
  });

  it('returns 1.0 for unknown elements', () => {
    expect(getTypeEffectiveness('fire', 'neutral')).toBe(1.0);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `npx vitest run src/battleEngine.test.js`
Expected: FAIL — module `./battleEngine` not found.

- [ ] **Step 3: Implement getTypeEffectiveness**

```js
// src/battleEngine.js
import { typeChart, stageMultipliers } from './gameData';

export function getTypeEffectiveness(attackerElement, defenderElement) {
  if (!typeChart[attackerElement]) return 1.0;
  return typeChart[attackerElement][defenderElement] ?? 1.0;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `npx vitest run src/battleEngine.test.js`
Expected: All 4 tests PASS.

- [ ] **Step 5: Write failing tests for damage calculation**

Add to `src/battleEngine.test.js`:

```js
describe('calculateDamage', () => {
  const attacker = { atk: 28, element: 'fire', stage: 3 };
  const defender = { def: 20, element: 'ice', defending: false };
  const move = { element: 'fire', power: 65, accuracy: 100 };

  it('calculates super-effective damage correctly', () => {
    // baseDamage = (28 * 1.0 * 2) - (20 * 0.5) = 56 - 10 = 46
    // typedDamage = 46 * 2.0 = 92
    // finalDamage = floor(92 * rand(0.85..1.0)) => 78..92
    const result = calculateDamage(attacker, defender, move);
    expect(result.damage).toBeGreaterThanOrEqual(78);
    expect(result.damage).toBeLessThanOrEqual(92);
    expect(result.effectiveness).toBe(2.0);
    expect(result.hit).toBe(true);
  });

  it('halves damage when defender is defending', () => {
    const defendingTarget = { ...defender, defending: true };
    const result = calculateDamage(attacker, defendingTarget, move);
    expect(result.damage).toBeGreaterThanOrEqual(39);
    expect(result.damage).toBeLessThanOrEqual(46);
  });

  it('applies stage multiplier', () => {
    const stage1Attacker = { ...attacker, stage: 1 };
    // baseDamage = (28 * 0.5 * 2) - (20 * 0.5) = 28 - 10 = 18
    // typedDamage = 18 * 2.0 = 36
    const result = calculateDamage(stage1Attacker, defender, move);
    expect(result.damage).toBeGreaterThanOrEqual(30);
    expect(result.damage).toBeLessThanOrEqual(36);
  });

  it('returns minimum 1 damage', () => {
    const weakAttacker = { atk: 1, element: 'fire', stage: 1 };
    const tankDefender = { def: 100, element: 'fire', defending: true };
    const result = calculateDamage(weakAttacker, tankDefender, move);
    expect(result.damage).toBe(1);
  });

  it('can miss based on accuracy', () => {
    const lowAccMove = { element: 'fire', power: 65, accuracy: 0 };
    const result = calculateDamage(attacker, defender, lowAccMove);
    expect(result.hit).toBe(false);
    expect(result.damage).toBe(0);
  });
});
```

- [ ] **Step 6: Run tests to verify new tests fail**

Run: `npx vitest run src/battleEngine.test.js`
Expected: `calculateDamage` tests FAIL — function not exported.

- [ ] **Step 7: Implement calculateDamage**

Add to `src/battleEngine.js`:

```js
export function calculateDamage(attacker, defender, move) {
  // Accuracy check
  const accuracyRoll = Math.random() * 100;
  if (accuracyRoll > move.accuracy) {
    return { damage: 0, effectiveness: 1.0, hit: false };
  }

  const stageMult = stageMultipliers[attacker.stage] ?? 1.0;
  const baseDamage = (attacker.atk * stageMult * 2) - (defender.def * 0.5);
  const effectiveness = getTypeEffectiveness(move.element, defender.element);
  let typedDamage = baseDamage * effectiveness;

  if (defender.defending) {
    typedDamage *= 0.5;
  }

  const roll = 0.85 + Math.random() * 0.15;
  const finalDamage = Math.max(1, Math.floor(typedDamage * roll));

  return { damage: finalDamage, effectiveness, hit: true };
}
```

- [ ] **Step 8: Run tests to verify they pass**

Run: `npx vitest run src/battleEngine.test.js`
Expected: All tests PASS.

- [ ] **Step 9: Commit**

```bash
git add src/battleEngine.js src/battleEngine.test.js
git commit -m "feat: battle engine — type effectiveness and damage calculation"
```

---

## Task 5: Battle Engine — XP, Leveling, Stats

**Files:**
- Modify: `src/battleEngine.js`, `src/battleEngine.test.js`

- [ ] **Step 1: Write failing tests for XP and leveling**

Add to `src/battleEngine.test.js`:

```js
import { getTypeEffectiveness, calculateDamage, calculateXpGain, calculateStatsForLevel, getStageForLevel } from './battleEngine';

describe('getStageForLevel', () => {
  it('returns stage 1 for levels below 10', () => {
    expect(getStageForLevel(1)).toBe(1);
    expect(getStageForLevel(9)).toBe(1);
  });

  it('returns stage 2 for levels 10-24', () => {
    expect(getStageForLevel(10)).toBe(2);
    expect(getStageForLevel(24)).toBe(2);
  });

  it('returns stage 3 for levels 25-49', () => {
    expect(getStageForLevel(25)).toBe(3);
    expect(getStageForLevel(49)).toBe(3);
  });

  it('returns stage 4 for level 50+', () => {
    expect(getStageForLevel(50)).toBe(4);
    expect(getStageForLevel(99)).toBe(4);
  });
});

describe('calculateXpGain', () => {
  it('gives base XP when levels are equal', () => {
    expect(calculateXpGain(50, 10, 10)).toBe(50);
  });

  it('gives more XP for fighting higher level enemies', () => {
    const xp = calculateXpGain(50, 5, 10);
    expect(xp).toBe(100);
  });

  it('gives less XP for fighting lower level enemies', () => {
    const xp = calculateXpGain(50, 10, 5);
    expect(xp).toBe(25);
  });

  it('gives minimum 1 XP', () => {
    const xp = calculateXpGain(50, 99, 1);
    expect(xp).toBeGreaterThanOrEqual(1);
  });
});

describe('calculateStatsForLevel', () => {
  it('returns base stats at level 1', () => {
    const base = { hp: 110, atk: 28, def: 20, spd: 18 };
    const result = calculateStatsForLevel(base, 1);
    expect(result).toEqual({ hp: 110, atk: 28, def: 20, spd: 18 });
  });

  it('adds 3 per stat per level above 1', () => {
    const base = { hp: 110, atk: 28, def: 20, spd: 18 };
    const result = calculateStatsForLevel(base, 5);
    // 4 levels above 1 => +12 to each stat
    expect(result).toEqual({ hp: 122, atk: 40, def: 32, spd: 30 });
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `npx vitest run src/battleEngine.test.js`
Expected: FAIL — functions not exported.

- [ ] **Step 3: Implement XP and leveling functions**

Add to `src/battleEngine.js`:

```js
import { typeChart, stageMultipliers, stageThresholds } from './gameData';

export function getStageForLevel(level) {
  if (level >= stageThresholds[4]) return 4;
  if (level >= stageThresholds[3]) return 3;
  if (level >= stageThresholds[2]) return 2;
  return 1;
}

export function calculateXpGain(baseXP, playerLevel, enemyLevel) {
  const ratio = enemyLevel / playerLevel;
  return Math.max(1, Math.floor(baseXP * ratio));
}

export function calculateStatsForLevel(baseStats, level) {
  const bonus = (level - 1) * 3;
  return {
    hp:  baseStats.hp + bonus,
    atk: baseStats.atk + bonus,
    def: baseStats.def + bonus,
    spd: baseStats.spd + bonus,
  };
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `npx vitest run src/battleEngine.test.js`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/battleEngine.js src/battleEngine.test.js
git commit -m "feat: battle engine — XP gain, leveling, stage evolution, stat scaling"
```

---

## Task 6: Battle Engine — Turn Resolution & NPC AI

**Files:**
- Modify: `src/battleEngine.js`, `src/battleEngine.test.js`

- [ ] **Step 1: Write failing tests for NPC AI move selection**

Add to `src/battleEngine.test.js`:

```js
import {
  getTypeEffectiveness, calculateDamage, calculateXpGain,
  calculateStatsForLevel, getStageForLevel, pickNpcMove, resolveTurn
} from './battleEngine';
import { moves } from './gameData';

describe('pickNpcMove', () => {
  it('returns a valid move key from the NPC move list', () => {
    const npcMoveKeys = ['rock_slide', 'earthquake'];
    const result = pickNpcMove(npcMoveKeys, 'stone', 'fire');
    expect(['rock_slide', 'earthquake', 'basic_attack']).toContain(result);
  });

  it('favors super-effective moves', () => {
    // Stone vs Storm => rock_slide and earthquake are both stone (2x vs storm)
    // Run 50 times — super-effective should appear majority
    const npcMoveKeys = ['rock_slide', 'earthquake'];
    let superEffectiveCount = 0;
    for (let i = 0; i < 50; i++) {
      const result = pickNpcMove(npcMoveKeys, 'stone', 'storm');
      const move = moves[result] || moves.basic_attack;
      const eff = getTypeEffectiveness(move.element, 'storm');
      if (eff > 1.0) superEffectiveCount++;
    }
    expect(superEffectiveCount).toBeGreaterThan(25);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `npx vitest run src/battleEngine.test.js`
Expected: FAIL — `pickNpcMove` not exported.

- [ ] **Step 3: Implement pickNpcMove**

Add to `src/battleEngine.js`:

```js
import { typeChart, stageMultipliers, stageThresholds, moves as allMoves } from './gameData';

export function pickNpcMove(npcMoveKeys, npcElement, playerElement) {
  const availableKeys = [...npcMoveKeys, 'basic_attack'];

  // Find super-effective moves
  const superEffective = availableKeys.filter((key) => {
    const move = allMoves[key];
    return move && getTypeEffectiveness(move.element, playerElement) > 1.0;
  });

  // 70% chance to pick super-effective if available
  if (superEffective.length > 0 && Math.random() < 0.7) {
    return superEffective[Math.floor(Math.random() * superEffective.length)];
  }

  // Otherwise random from all available (excluding basic_attack 50% of the time)
  const preferred = npcMoveKeys.length > 0 && Math.random() < 0.5
    ? npcMoveKeys
    : availableKeys;
  return preferred[Math.floor(Math.random() * preferred.length)];
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `npx vitest run src/battleEngine.test.js`
Expected: All tests PASS.

- [ ] **Step 5: Write failing tests for turn resolution**

Add to `src/battleEngine.test.js`:

```js
describe('resolveTurn', () => {
  const playerState = {
    name: 'Magma Dragon', element: 'fire', stage: 3,
    hp: 100, maxHp: 110, atk: 28, def: 20, spd: 18, defending: false,
  };
  const npcState = {
    name: 'Firewall Sentinel', element: 'stone', stage: 3,
    hp: 130, maxHp: 130, atk: 18, def: 32, spd: 8, defending: false,
  };

  it('returns updated player and npc state', () => {
    const result = resolveTurn(playerState, npcState, 'magma_breath', 'rock_slide');
    expect(result.player).toHaveProperty('hp');
    expect(result.npc).toHaveProperty('hp');
    expect(result.events).toBeInstanceOf(Array);
    expect(result.events.length).toBeGreaterThanOrEqual(2);
  });

  it('faster combatant attacks first', () => {
    // Player spd 18 > NPC spd 8, so player goes first
    const result = resolveTurn(playerState, npcState, 'magma_breath', 'rock_slide');
    expect(result.events[0].attacker).toBe('player');
    expect(result.events[1].attacker).toBe('npc');
  });

  it('sets defending flag when defend is chosen', () => {
    const result = resolveTurn(playerState, npcState, 'defend', 'rock_slide');
    // Player chose defend — the defend event should be first (player is faster)
    const defendEvent = result.events.find(e => e.action === 'defend');
    expect(defendEvent).toBeDefined();
  });

  it('stops turn if first attacker KOs the target', () => {
    const weakNpc = { ...npcState, hp: 1 };
    const result = resolveTurn(playerState, weakNpc, 'magma_breath', 'rock_slide');
    // NPC should be KO'd, only player attack event + KO event
    expect(result.npc.hp).toBe(0);
    const npcAttackEvents = result.events.filter(e => e.attacker === 'npc' && e.action === 'attack');
    expect(npcAttackEvents.length).toBe(0);
  });
});
```

- [ ] **Step 6: Run tests to verify they fail**

Run: `npx vitest run src/battleEngine.test.js`
Expected: FAIL — `resolveTurn` not exported.

- [ ] **Step 7: Implement resolveTurn**

Add to `src/battleEngine.js`:

```js
export function resolveTurn(playerState, npcState, playerMoveKey, npcMoveKey) {
  let player = { ...playerState, defending: false };
  let npc = { ...npcState, defending: false };
  const events = [];

  // Determine order by speed
  const playerFirst = player.spd >= npc.spd;

  const first = playerFirst
    ? { state: player, moveKey: playerMoveKey, label: 'player', target: () => npc }
    : { state: npc, moveKey: npcMoveKey, label: 'npc', target: () => player };

  const second = playerFirst
    ? { state: npc, moveKey: npcMoveKey, label: 'npc', target: () => player }
    : { state: player, moveKey: playerMoveKey, label: 'player', target: () => npc };

  // Resolve first attacker
  resolveAction(first, events, () => {
    if (first.label === 'player') return npc;
    return player;
  }, (updatedTarget) => {
    if (first.label === 'player') npc = updatedTarget;
    else player = updatedTarget;
  }, (updatedSelf) => {
    if (first.label === 'player') player = updatedSelf;
    else npc = updatedSelf;
  });

  // Check if target is KO'd
  const firstTarget = first.label === 'player' ? npc : player;
  if (firstTarget.hp > 0) {
    // Resolve second attacker
    resolveAction(second, events, () => {
      if (second.label === 'player') return npc;
      return player;
    }, (updatedTarget) => {
      if (second.label === 'player') npc = updatedTarget;
      else player = updatedTarget;
    }, (updatedSelf) => {
      if (second.label === 'player') player = updatedSelf;
      else npc = updatedSelf;
    });
  }

  return { player, npc, events };
}

function resolveAction(actor, events, getTarget, setTarget, setSelf) {
  if (actor.moveKey === 'defend') {
    const updated = { ...actor.state, defending: true };
    setSelf(updated);
    events.push({
      attacker: actor.label,
      action: 'defend',
      damage: 0,
      effectiveness: 1.0,
      hit: true,
    });
    return;
  }

  const move = allMoves[actor.moveKey] || allMoves.basic_attack;
  const target = getTarget();
  const result = calculateDamage(
    { atk: actor.state.atk, element: actor.state.element, stage: actor.state.stage },
    { def: target.def, element: target.element, defending: target.defending },
    move
  );

  const newTargetHp = Math.max(0, target.hp - result.damage);
  setTarget({ ...target, hp: newTargetHp });

  events.push({
    attacker: actor.label,
    action: 'attack',
    moveName: move.name,
    moveKey: actor.moveKey,
    vfxKey: move.vfxKey,
    damage: result.damage,
    effectiveness: result.effectiveness,
    hit: result.hit,
    targetHp: newTargetHp,
  });
}
```

- [ ] **Step 8: Run tests to verify they pass**

Run: `npx vitest run src/battleEngine.test.js`
Expected: All tests PASS.

- [ ] **Step 9: Commit**

```bash
git add src/battleEngine.js src/battleEngine.test.js
git commit -m "feat: battle engine — NPC AI move selection and full turn resolution"
```

---

## Task 7: Persistence

**Files:**
- Create: `src/persistence.js`

- [ ] **Step 1: Create src/persistence.js**

```js
const STORAGE_KEY = 'dragonforge_save';

const DEFAULT_SAVE = {
  dragons: {
    fire:   { level: 1, xp: 0 },
    ice:    { level: 1, xp: 0 },
    storm:  { level: 1, xp: 0 },
    stone:  { level: 1, xp: 0 },
    venom:  { level: 1, xp: 0 },
    shadow: { level: 1, xp: 0 },
  },
};

export function loadSave() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_SAVE };
    return JSON.parse(raw);
  } catch {
    return { ...DEFAULT_SAVE };
  }
}

export function saveDragonProgress(dragonId, level, xp) {
  const save = loadSave();
  save.dragons[dragonId] = { level, xp };
  localStorage.setItem(STORAGE_KEY, JSON.stringify(save));
}

export function resetSave() {
  localStorage.removeItem(STORAGE_KEY);
}
```

- [ ] **Step 2: Commit**

```bash
git add src/persistence.js
git commit -m "feat: localStorage persistence for dragon level/XP progress"
```

---

## Task 8: Sprite Components

**Files:**
- Create: `src/sprites.js`, `src/DragonSprite.jsx`, `src/NpcSprite.jsx`

- [ ] **Step 1: Create src/sprites.js**

```js
// Dragon sprite sheets are 2x4 grids on 1024x1024 images
// Each frame is 512x256 (but we'll render them scaled)
export const DRAGON_SHEET = {
  cols: 2,
  rows: 4,
  frameWidth: 512,
  frameHeight: 256,
  totalFrames: 8,
  idleFrames: [0, 1, 2, 3, 4, 5, 6, 7],
  lungeFrame: 3,
  frameDuration: 150, // ms per frame
};

// Scale factors for each evolution stage
export const STAGE_SCALES = {
  1: 0.6,
  2: 0.8,
  3: 1.0,
  4: 1.4,
};

// Display size for a dragon at scale 1.0
export const DRAGON_DISPLAY = {
  width: 200,
  height: 100,
};
```

- [ ] **Step 2: Create src/DragonSprite.jsx**

```jsx
import { useState, useEffect, useRef } from 'react';
import { DRAGON_SHEET, STAGE_SCALES, DRAGON_DISPLAY } from './sprites';

export default function DragonSprite({ spriteSheet, stage = 3, flipX = false, forcedFrame = null, className = '' }) {
  const [frame, setFrame] = useState(0);
  const intervalRef = useRef(null);

  useEffect(() => {
    if (forcedFrame !== null) {
      setFrame(forcedFrame);
      return;
    }

    intervalRef.current = setInterval(() => {
      setFrame((prev) => (prev + 1) % DRAGON_SHEET.totalFrames);
    }, DRAGON_SHEET.frameDuration);

    return () => clearInterval(intervalRef.current);
  }, [forcedFrame]);

  const col = frame % DRAGON_SHEET.cols;
  const row = Math.floor(frame / DRAGON_SHEET.cols);
  const bgX = -(col * DRAGON_SHEET.frameWidth);
  const bgY = -(row * DRAGON_SHEET.frameHeight);

  const scale = STAGE_SCALES[stage] ?? 1.0;
  const width = DRAGON_DISPLAY.width * scale;
  const height = DRAGON_DISPLAY.height * scale;

  const style = {
    width: `${width}px`,
    height: `${height}px`,
    backgroundImage: `url(${spriteSheet})`,
    backgroundPosition: `${bgX * (width / DRAGON_SHEET.frameWidth)}px ${bgY * (height / DRAGON_SHEET.frameHeight)}px`,
    backgroundSize: `${DRAGON_SHEET.cols * width}px ${DRAGON_SHEET.rows * height}px`,
    imageRendering: 'pixelated',
    transform: flipX ? 'scaleX(-1)' : 'none',
    filter: stage === 4 ? 'drop-shadow(0 0 8px gold)' : 'none',
  };

  return <div className={`dragon-sprite ${className}`} style={style} />;
}
```

- [ ] **Step 3: Create src/NpcSprite.jsx**

```jsx
export default function NpcSprite({ idleSprite, attackSprite, isAttacking = false, className = '' }) {
  const src = isAttacking ? attackSprite : idleSprite;

  return (
    <img
      className={`npc-sprite pixelated ${className}`}
      src={src}
      alt="NPC"
      style={{
        imageRendering: 'pixelated',
        height: '160px',
        objectFit: 'contain',
      }}
    />
  );
}
```

- [ ] **Step 4: Verify sprites render**

Temporarily update `App.jsx` title screen to show a dragon and NPC:

```jsx
import DragonSprite from './DragonSprite';
import NpcSprite from './NpcSprite';

// Inside the title placeholder:
<DragonSprite spriteSheet="/assets/dragons/magma.png" stage={3} />
<NpcSprite idleSprite="/assets/npc/firewall_sentinel_sprites.png" />
```

Run: `npm run dev`
Expected: Magma dragon animates through 8 frames. Firewall Sentinel shows static idle sprite. Remove the test sprites after verifying.

- [ ] **Step 5: Commit**

```bash
git add src/sprites.js src/DragonSprite.jsx src/NpcSprite.jsx
git commit -m "feat: DragonSprite (animated sheet) and NpcSprite components"
```

---

## Task 9: Global CSS & CRT Effects

**Files:**
- Modify: `src/styles.css`

- [ ] **Step 1: Replace styles.css with full game styles**

Replace the contents of `src/styles.css` with:

```css
@import url('https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap');

/* === RESET === */
*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

/* === BASE === */
body {
  background: #111118;
  color: #e0e0e0;
  font-family: 'Press Start 2P', monospace;
  font-size: 10px;
  overflow: hidden;
  height: 100vh;
  width: 100vw;
}

#root {
  height: 100vh;
  width: 100vw;
}

.app {
  height: 100%;
  width: 100%;
  position: relative;
}

/* === CRT SCANLINE OVERLAY === */
.app::after {
  content: '';
  position: fixed;
  inset: 0;
  pointer-events: none;
  z-index: 9999;
  background: repeating-linear-gradient(
    0deg,
    rgba(0, 0, 0, 0.15) 0px,
    rgba(0, 0, 0, 0.15) 1px,
    transparent 1px,
    transparent 3px
  );
}

/* === PIXELATED RENDERING === */
.pixelated {
  image-rendering: pixelated;
  image-rendering: -moz-crisp-edges;
  image-rendering: crisp-edges;
}

/* === PROFESSOR FELIX FRAME === */
.felix-frame {
  border: 4px solid #ffffff;
  box-shadow: inset -4px -4px 0px #888888;
  background: #111118;
}

/* === UI PANELS === */
.panel {
  background: rgba(0, 0, 0, 0.85);
  border: 1px solid #333;
}

.panel-top {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  padding: 12px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  z-index: 10;
  border-bottom: 2px solid #333;
}

.panel-bottom {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 14px 20px;
  z-index: 10;
  border-top: 2px solid #ff6622;
}

/* === HP BAR === */
.hp-bar-container {
  min-width: 180px;
}

.hp-bar-label {
  font-size: 9px;
  margin-bottom: 4px;
}

.hp-bar-track {
  height: 8px;
  background: #333;
  border-radius: 4px;
  overflow: hidden;
}

.hp-bar-fill {
  height: 100%;
  border-radius: 4px;
  transition: width 0.5s ease-out;
}

/* === MOVE BUTTONS === */
.move-panel {
  display: flex;
  gap: 8px;
  justify-content: center;
}

.move-btn {
  font-family: 'Press Start 2P', monospace;
  font-size: 9px;
  padding: 10px 16px;
  background: #1a1a2e;
  color: #e0e0e0;
  border: 1px solid #444;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.15s;
  position: relative;
}

.move-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
}

.move-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.move-btn .tooltip {
  display: none;
  position: absolute;
  bottom: 100%;
  left: 50%;
  transform: translateX(-50%);
  background: #000;
  border: 1px solid #555;
  padding: 4px 8px;
  font-size: 8px;
  white-space: nowrap;
  margin-bottom: 4px;
  border-radius: 2px;
}

.move-btn:hover .tooltip {
  display: block;
}

/* === ARENA === */
.arena {
  position: absolute;
  inset: 0;
  background-size: cover;
  background-position: center;
  image-rendering: pixelated;
}

.arena-sprites {
  position: absolute;
  inset: 0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 10%;
  padding-top: 40px;
  padding-bottom: 60px;
}

/* === FLOATING DAMAGE NUMBERS === */
@keyframes damageFloat {
  0% {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
  50% {
    opacity: 1;
    transform: translateY(-30px) scale(1.2);
  }
  100% {
    opacity: 0;
    transform: translateY(-60px) scale(0.8);
  }
}

.damage-number {
  position: absolute;
  font-size: 18px;
  font-weight: bold;
  pointer-events: none;
  animation: damageFloat 0.8s ease-out forwards;
  text-shadow: 2px 2px 0px #000, -1px -1px 0px #000;
  z-index: 20;
}

.damage-number.normal { color: #ffffff; }
.damage-number.super-effective { color: #ff4444; font-size: 22px; }
.damage-number.resisted { color: #888888; font-size: 14px; }
.damage-number.miss { color: #666666; font-style: italic; }

/* === ATTACK ANIMATIONS === */
@keyframes telegraph {
  0%, 100% { filter: brightness(1); }
  50% { filter: brightness(2) saturate(1.5); }
}

@keyframes recoil {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-8px); }
  75% { transform: translateX(8px); }
}

@keyframes fadeOut {
  from { opacity: 1; }
  to { opacity: 0; }
}

.sprite-telegraph {
  animation: telegraph 0.4s ease-in-out;
}

.sprite-recoil {
  animation: recoil 0.2s ease-in-out;
}

.sprite-ko {
  animation: fadeOut 0.6s ease-out forwards;
}

/* === TITLE SCREEN === */
.title-screen {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  gap: 24px;
}

.title-screen h1 {
  font-size: 24px;
  color: #ff6622;
  text-shadow: 0 0 20px rgba(255, 102, 34, 0.5);
}

@keyframes typewriter {
  from { width: 0; }
  to { width: 100%; }
}

.typewriter-text {
  overflow: hidden;
  white-space: nowrap;
  border-right: 2px solid #ff6622;
  animation: typewriter 2s steps(40) forwards, blink 0.7s step-end infinite;
  max-width: 600px;
}

@keyframes blink {
  50% { border-color: transparent; }
}

.enter-btn {
  font-family: 'Press Start 2P', monospace;
  font-size: 12px;
  padding: 16px 32px;
  background: #1a1a2e;
  color: #ff6622;
  border: 2px solid #ff6622;
  cursor: pointer;
  transition: all 0.2s;
}

.enter-btn:hover {
  background: #ff6622;
  color: #111118;
  box-shadow: 0 0 20px rgba(255, 102, 34, 0.4);
}

/* === BATTLE SELECT === */
.battle-select {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.battle-select-header {
  text-align: center;
  padding: 16px;
  font-size: 14px;
  color: #ff6622;
}

.battle-select-panels {
  display: flex;
  flex: 1;
  gap: 16px;
  padding: 0 16px;
  overflow: hidden;
}

.select-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
  overflow-y: auto;
}

.select-panel h2 {
  font-size: 11px;
  color: #888;
  margin-bottom: 4px;
}

.select-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  background: #1a1a2e;
  border: 1px solid #333;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.15s;
}

.select-card:hover {
  border-color: #666;
}

.select-card.selected {
  border-color: #ff6622;
  box-shadow: 0 0 10px rgba(255, 102, 34, 0.2);
}

.select-card-info {
  flex: 1;
}

.select-card-name {
  font-size: 10px;
  margin-bottom: 4px;
}

.select-card-stats {
  font-size: 8px;
  color: #888;
}

.matchup-indicator {
  text-align: center;
  padding: 12px;
  font-size: 11px;
}

.matchup-indicator.super-effective { color: #ff4444; }
.matchup-indicator.resisted { color: #888888; }
.matchup-indicator.neutral { color: #e0e0e0; }

.battle-select-footer {
  padding: 16px;
  text-align: center;
}

.begin-battle-btn {
  font-family: 'Press Start 2P', monospace;
  font-size: 11px;
  padding: 14px 28px;
  background: #1a1a2e;
  color: #ff6622;
  border: 2px solid #ff6622;
  cursor: pointer;
  transition: all 0.2s;
}

.begin-battle-btn:hover:not(:disabled) {
  background: #ff6622;
  color: #111118;
}

.begin-battle-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

/* === RESULT SCREENS === */
.result-overlay {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.85);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 20px;
  z-index: 50;
}

.result-overlay h2 {
  font-size: 20px;
}

.result-overlay.victory h2 { color: #ffcc00; }
.result-overlay.defeat h2 { color: #ff4444; }

.xp-display {
  font-size: 10px;
  color: #44aaff;
}

.level-up-display {
  font-size: 12px;
  color: #ffcc00;
  text-shadow: 0 0 10px rgba(255, 204, 0, 0.5);
}

.result-btn {
  font-family: 'Press Start 2P', monospace;
  font-size: 10px;
  padding: 12px 24px;
  background: #1a1a2e;
  color: #e0e0e0;
  border: 1px solid #444;
  cursor: pointer;
}

.result-btn:hover {
  border-color: #ff6622;
  color: #ff8844;
}

/* === STABILITY GLITCH (from spec) === */
.stability-glitch {
  animation: jitter 0.1s infinite;
  filter: hue-rotate(90deg) contrast(150%);
}

@keyframes jitter {
  0% { transform: translate(0, 0); }
  25% { transform: translate(-2px, 1px); }
  50% { transform: translate(1px, -2px); }
  75% { transform: translate(-1px, 2px); }
  100% { transform: translate(2px, -1px); }
}
```

- [ ] **Step 2: Verify styles apply**

Run: `npm run dev`
Expected: Dark background (#111118), CRT scanlines visible as faint horizontal lines, pixel font on buttons, orange hover effects.

- [ ] **Step 3: Commit**

```bash
git add src/styles.css
git commit -m "feat: full game CSS — CRT scanlines, pixel aesthetic, battle UI, animations"
```

---

## Task 10: Title Screen

**Files:**
- Create: `src/TitleScreen.jsx`
- Modify: `src/App.jsx`

- [ ] **Step 1: Create src/TitleScreen.jsx**

```jsx
import { useState, useEffect } from 'react';

const INTRO_LINES = [
  '> EMERGENCY BROADCAST FROM DR. FELIX',
  '> The Elemental Matrix is destabilizing...',
  '> We need Dragon Forgers. We need YOU.',
];

export default function TitleScreen({ onStart }) {
  const [visibleLines, setVisibleLines] = useState(0);
  const [showButton, setShowButton] = useState(false);

  useEffect(() => {
    if (visibleLines < INTRO_LINES.length) {
      const timer = setTimeout(() => setVisibleLines((v) => v + 1), 1200);
      return () => clearTimeout(timer);
    } else {
      const timer = setTimeout(() => setShowButton(true), 600);
      return () => clearTimeout(timer);
    }
  }, [visibleLines]);

  return (
    <div className="title-screen">
      <div className="felix-frame" style={{ width: 96, height: 96, overflow: 'hidden', marginBottom: 16 }}>
        <img
          src="/assets/felix_pixel.jpg"
          alt="Professor Felix"
          className="pixelated"
          style={{ width: '100%', height: '100%', objectFit: 'cover' }}
        />
      </div>

      <h1>DRAGON FORGE</h1>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 8, minHeight: 80, alignItems: 'center' }}>
        {INTRO_LINES.slice(0, visibleLines).map((line, i) => (
          <p key={i} style={{ color: '#44ff44', fontSize: 9 }}>{line}</p>
        ))}
      </div>

      {showButton && (
        <button className="enter-btn" onClick={onStart}>
          ENTER THE FORGE
        </button>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Update App.jsx to use TitleScreen**

Replace the title screen placeholder in `App.jsx`:

```jsx
import { useState } from 'react';
import TitleScreen from './TitleScreen';

const SCREENS = {
  TITLE: 'title',
  BATTLE_SELECT: 'battleSelect',
  BATTLE: 'battle',
};

export default function App() {
  const [screen, setScreen] = useState(SCREENS.TITLE);
  const [battleConfig, setBattleConfig] = useState(null);

  function handleStartGame() {
    setScreen(SCREENS.BATTLE_SELECT);
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
      {screen === SCREENS.BATTLE_SELECT && (
        <div className="placeholder-screen">
          <h1>SELECT YOUR DRAGON</h1>
          <button onClick={() => handleBeginBattle({ dragonId: 'fire', npcId: 'firewall_sentinel' })}>
            BEGIN BATTLE (placeholder)
          </button>
        </div>
      )}
      {screen === SCREENS.BATTLE && (
        <div className="placeholder-screen">
          <h1>BATTLE (placeholder)</h1>
          <button onClick={handleBattleEnd}>END BATTLE</button>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 3: Verify title screen**

Run: `npm run dev`
Expected: Felix portrait in framed box, "DRAGON FORGE" title, three lines of green text appearing one by one, then "ENTER THE FORGE" button fades in. Clicking button transitions to battle select placeholder.

- [ ] **Step 4: Commit**

```bash
git add src/TitleScreen.jsx src/App.jsx
git commit -m "feat: title screen with Felix portrait and typewriter intro"
```

---

## Task 11: Battle Select Screen

**Files:**
- Create: `src/BattleSelectScreen.jsx`
- Modify: `src/App.jsx`

- [ ] **Step 1: Create src/BattleSelectScreen.jsx**

```jsx
import { useState } from 'react';
import { dragons, npcs, elementColors, moves } from './gameData';
import { getTypeEffectiveness, calculateStatsForLevel, getStageForLevel } from './battleEngine';
import { loadSave } from './persistence';
import DragonSprite from './DragonSprite';
import NpcSprite from './NpcSprite';

const dragonList = Object.values(dragons);
const npcList = Object.values(npcs);

export default function BattleSelectScreen({ onBeginBattle }) {
  const [selectedDragon, setSelectedDragon] = useState(null);
  const [selectedNpc, setSelectedNpc] = useState(null);
  const save = loadSave();

  function getMatchup() {
    if (!selectedDragon || !selectedNpc) return null;
    const eff = getTypeEffectiveness(selectedDragon.element, selectedNpc.element);
    if (eff > 1.0) return { label: 'SUPER EFFECTIVE!', className: 'super-effective' };
    if (eff < 1.0) return { label: 'RESISTED...', className: 'resisted' };
    return { label: 'NEUTRAL', className: 'neutral' };
  }

  const matchup = getMatchup();

  function handleBegin() {
    if (!selectedDragon || !selectedNpc) return;
    onBeginBattle({ dragonId: selectedDragon.id, npcId: selectedNpc.id });
  }

  return (
    <div className="battle-select">
      <div className="battle-select-header">SELECT YOUR BATTLE</div>

      <div className="battle-select-panels">
        <div className="select-panel">
          <h2>YOUR DRAGONS</h2>
          {dragonList.map((dragon) => {
            const progress = save.dragons[dragon.id] || { level: 1, xp: 0 };
            const stage = getStageForLevel(progress.level);
            const stats = calculateStatsForLevel(dragon.baseStats, progress.level);
            const color = elementColors[dragon.element];
            return (
              <div
                key={dragon.id}
                className={`select-card ${selectedDragon?.id === dragon.id ? 'selected' : ''}`}
                style={{ borderColor: selectedDragon?.id === dragon.id ? color.primary : undefined }}
                onClick={() => setSelectedDragon(dragon)}
              >
                <div style={{ width: 80, height: 40, overflow: 'hidden', flexShrink: 0 }}>
                  <DragonSprite spriteSheet={dragon.spriteSheet} stage={stage} />
                </div>
                <div className="select-card-info">
                  <div className="select-card-name" style={{ color: color.primary }}>{dragon.name}</div>
                  <div className="select-card-stats">
                    Lv.{progress.level} | HP:{stats.hp} ATK:{stats.atk} DEF:{stats.def} SPD:{stats.spd}
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        <div className="select-panel">
          <h2>OPPONENTS</h2>
          {npcList.map((npc) => {
            const color = elementColors[npc.element];
            return (
              <div
                key={npc.id}
                className={`select-card ${selectedNpc?.id === npc.id ? 'selected' : ''}`}
                style={{ borderColor: selectedNpc?.id === npc.id ? color.primary : undefined }}
                onClick={() => setSelectedNpc(npc)}
              >
                <div style={{ width: 60, height: 60, overflow: 'hidden', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <NpcSprite idleSprite={npc.idleSprite} attackSprite={npc.attackSprite} />
                </div>
                <div className="select-card-info">
                  <div className="select-card-name" style={{ color: color.primary }}>{npc.name}</div>
                  <div className="select-card-stats">
                    Lv.{npc.level} | {npc.difficulty} | {npc.element.toUpperCase()}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {matchup && (
        <div className={`matchup-indicator ${matchup.className}`}>
          {selectedDragon.element.toUpperCase()} vs {selectedNpc.element.toUpperCase()} — {matchup.label}
        </div>
      )}

      <div className="battle-select-footer">
        <button
          className="begin-battle-btn"
          disabled={!selectedDragon || !selectedNpc}
          onClick={handleBegin}
        >
          BEGIN BATTLE
        </button>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Update App.jsx to use BattleSelectScreen**

Replace the battle select placeholder in `App.jsx`:

```jsx
import { useState } from 'react';
import TitleScreen from './TitleScreen';
import BattleSelectScreen from './BattleSelectScreen';

const SCREENS = {
  TITLE: 'title',
  BATTLE_SELECT: 'battleSelect',
  BATTLE: 'battle',
};

export default function App() {
  const [screen, setScreen] = useState(SCREENS.TITLE);
  const [battleConfig, setBattleConfig] = useState(null);

  function handleStartGame() {
    setScreen(SCREENS.BATTLE_SELECT);
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
      {screen === SCREENS.BATTLE_SELECT && (
        <BattleSelectScreen onBeginBattle={handleBeginBattle} />
      )}
      {screen === SCREENS.BATTLE && (
        <div className="placeholder-screen">
          <h1>BATTLE (placeholder)</h1>
          <p style={{ fontSize: 9 }}>Dragon: {battleConfig?.dragonId} vs NPC: {battleConfig?.npcId}</p>
          <button onClick={handleBattleEnd}>END BATTLE</button>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 3: Verify battle select**

Run: `npm run dev`
Expected: Two-panel layout. Left shows 6 dragons with animated sprites, levels, and stats. Right shows 4 NPCs with difficulty labels. Selecting both shows matchup indicator. "BEGIN BATTLE" enables when both selected.

- [ ] **Step 4: Commit**

```bash
git add src/BattleSelectScreen.jsx src/App.jsx
git commit -m "feat: battle select screen with dragon/NPC picker and matchup indicator"
```

---

## Task 12: Floating Damage Number Component

**Files:**
- Create: `src/DamageNumber.jsx`

- [ ] **Step 1: Create src/DamageNumber.jsx**

```jsx
import { useEffect, useState } from 'react';

export default function DamageNumber({ damage, effectiveness, hit, position, onComplete }) {
  const [visible, setVisible] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => {
      setVisible(false);
      onComplete?.();
    }, 800);
    return () => clearTimeout(timer);
  }, [onComplete]);

  if (!visible) return null;

  let className = 'damage-number normal';
  let text = String(damage);

  if (!hit) {
    className = 'damage-number miss';
    text = 'MISS';
  } else if (effectiveness > 1.0) {
    className = 'damage-number super-effective';
    text = `${damage}`;
  } else if (effectiveness < 1.0) {
    className = 'damage-number resisted';
    text = `${damage}`;
  }

  return (
    <div
      className={className}
      style={{
        left: `${position.x}px`,
        top: `${position.y}px`,
      }}
    >
      {text}
    </div>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add src/DamageNumber.jsx
git commit -m "feat: floating damage number component with CSS animation"
```

---

## Task 13: Battle Screen

**Files:**
- Create: `src/BattleScreen.jsx`
- Modify: `src/App.jsx`

This is the largest task. It wires together the battle engine, sprites, damage numbers, and animations into the full combat experience.

- [ ] **Step 1: Create src/BattleScreen.jsx**

```jsx
import { useReducer, useCallback, useEffect, useRef } from 'react';
import { dragons, npcs, moves, elementColors } from './gameData';
import {
  resolveTurn, pickNpcMove, calculateStatsForLevel,
  getStageForLevel, calculateXpGain,
} from './battleEngine';
import { loadSave, saveDragonProgress } from './persistence';
import DragonSprite from './DragonSprite';
import NpcSprite from './NpcSprite';
import DamageNumber from './DamageNumber';

const PHASES = {
  PLAYER_TURN: 'playerTurn',
  ANIMATING: 'animating',
  VICTORY: 'victory',
  DEFEAT: 'defeat',
};

function initBattle(dragonId, npcId) {
  const dragon = dragons[dragonId];
  const npc = npcs[npcId];
  const save = loadSave();
  const progress = save.dragons[dragonId] || { level: 1, xp: 0 };
  const stage = getStageForLevel(progress.level);
  const stats = calculateStatsForLevel(dragon.baseStats, progress.level);

  return {
    phase: PHASES.PLAYER_TURN,
    dragon,
    npc,
    dragonId,
    playerLevel: progress.level,
    playerXp: progress.xp,
    playerStage: stage,
    playerStats: stats,
    playerHp: stats.hp,
    playerMaxHp: stats.hp,
    playerDefending: false,
    npcHp: npc.stats.hp,
    npcMaxHp: npc.stats.hp,
    npcDefending: false,
    damageNumbers: [],
    playerSpriteClass: '',
    npcSpriteClass: '',
    npcAttacking: false,
    playerForcedFrame: null,
    xpGained: 0,
    leveledUp: false,
    newLevel: progress.level,
  };
}

function battleReducer(state, action) {
  switch (action.type) {
    case 'START_ANIMATION':
      return { ...state, phase: PHASES.ANIMATING };
    case 'SET_PLAYER_SPRITE_CLASS':
      return { ...state, playerSpriteClass: action.value };
    case 'SET_NPC_SPRITE_CLASS':
      return { ...state, npcSpriteClass: action.value };
    case 'SET_NPC_ATTACKING':
      return { ...state, npcAttacking: action.value };
    case 'SET_PLAYER_FORCED_FRAME':
      return { ...state, playerForcedFrame: action.value };
    case 'APPLY_DAMAGE_TO_NPC':
      return { ...state, npcHp: Math.max(0, state.npcHp - action.damage) };
    case 'APPLY_DAMAGE_TO_PLAYER':
      return { ...state, playerHp: Math.max(0, state.playerHp - action.damage) };
    case 'ADD_DAMAGE_NUMBER':
      return { ...state, damageNumbers: [...state.damageNumbers, action.entry] };
    case 'REMOVE_DAMAGE_NUMBER':
      return { ...state, damageNumbers: state.damageNumbers.filter((d) => d.id !== action.id) };
    case 'SET_PHASE':
      return { ...state, phase: action.phase };
    case 'SET_VICTORY':
      return { ...state, phase: PHASES.VICTORY, xpGained: action.xpGained, leveledUp: action.leveledUp, newLevel: action.newLevel };
    case 'SET_DEFEAT':
      return { ...state, phase: PHASES.DEFEAT };
    case 'RESET_TURN':
      return { ...state, phase: PHASES.PLAYER_TURN, playerSpriteClass: '', npcSpriteClass: '', npcAttacking: false, playerForcedFrame: null };
    default:
      return state;
  }
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

let damageIdCounter = 0;

export default function BattleScreen({ dragonId, npcId, onBattleEnd }) {
  const [state, dispatch] = useReducer(battleReducer, null, () => initBattle(dragonId, npcId));
  const animatingRef = useRef(false);

  const animateEvent = useCallback(async (event, dispatch) => {
    const isPlayer = event.attacker === 'player';

    if (event.action === 'defend') {
      // Brief flash to indicate defending
      if (isPlayer) {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
        await wait(400);
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      }
      return;
    }

    // TELEGRAPH phase
    if (isPlayer) {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
      dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: null });
    } else {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-telegraph' });
    }
    await wait(400);

    // IMPACT phase
    if (isPlayer) {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: 3 }); // lunge frame
    } else {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
      dispatch({ type: 'SET_NPC_ATTACKING', value: true });
    }

    // Apply damage + show number
    if (event.hit) {
      if (isPlayer) {
        dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
      } else {
        dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
      }
    }

    const dmgId = ++damageIdCounter;
    dispatch({
      type: 'ADD_DAMAGE_NUMBER',
      entry: {
        id: dmgId,
        damage: event.damage,
        effectiveness: event.effectiveness,
        hit: event.hit,
        target: isPlayer ? 'npc' : 'player',
      },
    });
    await wait(300);

    // RECOIL phase
    if (isPlayer) {
      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-recoil' });
    } else {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-recoil' });
    }
    await wait(200);

    // RESOLUTION
    dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
    dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
    dispatch({ type: 'SET_NPC_ATTACKING', value: false });
    dispatch({ type: 'SET_PLAYER_FORCED_FRAME', value: null });
    await wait(200);
  }, []);

  const handleMoveSelect = useCallback(async (moveKey) => {
    if (animatingRef.current) return;
    animatingRef.current = true;
    dispatch({ type: 'START_ANIMATION' });

    // Build combatant states for engine
    const playerState = {
      name: state.dragon.name,
      element: state.dragon.element,
      stage: state.playerStage,
      hp: state.playerHp,
      maxHp: state.playerMaxHp,
      atk: state.playerStats.atk,
      def: state.playerStats.def,
      spd: state.playerStats.spd,
      defending: false,
    };

    const npcState = {
      name: state.npc.name,
      element: state.npc.element,
      stage: 3,
      hp: state.npcHp,
      maxHp: state.npcMaxHp,
      atk: state.npc.stats.atk,
      def: state.npc.stats.def,
      spd: state.npc.stats.spd,
      defending: false,
    };

    const npcMoveKey = pickNpcMove(state.npc.moveKeys, state.npc.element, state.dragon.element);
    const result = resolveTurn(playerState, npcState, moveKey, npcMoveKey);

    // Animate each event sequentially
    for (const event of result.events) {
      await animateEvent(event, dispatch);
    }

    // Check outcomes
    if (result.npc.hp <= 0) {
      // Victory
      const xpGained = calculateXpGain(state.npc.baseXP, state.playerLevel, state.npc.level);
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

      dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-ko' });
      await wait(600);
      dispatch({ type: 'SET_VICTORY', xpGained, leveledUp, newLevel });
    } else if (result.player.hp <= 0) {
      dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-ko' });
      await wait(600);
      dispatch({ type: 'SET_DEFEAT' });
    } else {
      dispatch({ type: 'RESET_TURN' });
    }

    animatingRef.current = false;
  }, [state, animateEvent]);

  const dragon = state.dragon;
  const npc = state.npc;
  const playerMoves = [...dragon.moveKeys.map((k) => ({ key: k, ...moves[k] })), { key: 'basic_attack', ...moves.basic_attack }];
  const playerColor = elementColors[dragon.element];
  const npcColor = elementColors[npc.element];

  return (
    <div style={{ position: 'relative', width: '100%', height: '100%' }}>
      {/* Arena background */}
      <div className="arena pixelated" style={{ backgroundImage: `url(${npc.arena})` }} />

      {/* Top bar — HP */}
      <div className="panel panel-top">
        <div className="hp-bar-container">
          <div className="hp-bar-label" style={{ color: npcColor.glow }}>
            {npc.name} <span style={{ color: '#888' }}>Lv.{npc.level}</span>
          </div>
          <div className="hp-bar-track">
            <div
              className="hp-bar-fill"
              style={{
                width: `${(state.npcHp / state.npcMaxHp) * 100}%`,
                background: `linear-gradient(90deg, ${npcColor.primary}, ${npcColor.glow})`,
              }}
            />
          </div>
          <div style={{ fontSize: 8, color: '#888', marginTop: 2 }}>
            HP {state.npcHp}/{state.npcMaxHp}
          </div>
        </div>

        <div style={{ color: '#555', fontSize: 14 }}>VS</div>

        <div className="hp-bar-container" style={{ textAlign: 'right' }}>
          <div className="hp-bar-label" style={{ color: playerColor.glow }}>
            <span style={{ color: '#888' }}>Lv.{state.playerLevel}</span> {dragon.name}
          </div>
          <div className="hp-bar-track">
            <div
              className="hp-bar-fill"
              style={{
                width: `${(state.playerHp / state.playerMaxHp) * 100}%`,
                background: `linear-gradient(90deg, ${playerColor.primary}, ${playerColor.glow})`,
                marginLeft: 'auto',
              }}
            />
          </div>
          <div style={{ fontSize: 8, color: '#888', marginTop: 2, textAlign: 'right' }}>
            HP {state.playerHp}/{state.playerMaxHp}
          </div>
        </div>
      </div>

      {/* Arena sprites */}
      <div className="arena-sprites">
        <div style={{ position: 'relative' }}>
          <NpcSprite
            idleSprite={npc.idleSprite}
            attackSprite={npc.attackSprite}
            isAttacking={state.npcAttacking}
            className={state.npcSpriteClass}
          />
          {/* NPC damage numbers */}
          {state.damageNumbers
            .filter((d) => d.target === 'npc')
            .map((d) => (
              <DamageNumber
                key={d.id}
                damage={d.damage}
                effectiveness={d.effectiveness}
                hit={d.hit}
                position={{ x: 40, y: -20 }}
                onComplete={() => dispatch({ type: 'REMOVE_DAMAGE_NUMBER', id: d.id })}
              />
            ))}
        </div>

        <div style={{ position: 'relative' }}>
          <DragonSprite
            spriteSheet={dragon.spriteSheet}
            stage={state.playerStage}
            flipX={false}
            forcedFrame={state.playerForcedFrame}
            className={state.playerSpriteClass}
          />
          {/* Player damage numbers */}
          {state.damageNumbers
            .filter((d) => d.target === 'player')
            .map((d) => (
              <DamageNumber
                key={d.id}
                damage={d.damage}
                effectiveness={d.effectiveness}
                hit={d.hit}
                position={{ x: 40, y: -20 }}
                onComplete={() => dispatch({ type: 'REMOVE_DAMAGE_NUMBER', id: d.id })}
              />
            ))}
        </div>
      </div>

      {/* Bottom panel — moves */}
      <div className="panel panel-bottom">
        <div className="move-panel">
          {playerMoves.map((move) => {
            const moveColor = elementColors[move.element] || elementColors.neutral;
            return (
              <button
                key={move.key}
                className="move-btn"
                style={{ borderColor: moveColor.primary, color: moveColor.glow }}
                disabled={state.phase !== PHASES.PLAYER_TURN}
                onClick={() => handleMoveSelect(move.key)}
              >
                <span className="tooltip">PWR:{move.power} ACC:{move.accuracy}%</span>
                {move.name.toUpperCase()}
              </button>
            );
          })}
          <button
            className="move-btn"
            style={{ borderColor: '#44aa44', color: '#66cc66' }}
            disabled={state.phase !== PHASES.PLAYER_TURN}
            onClick={() => handleMoveSelect('defend')}
          >
            <span className="tooltip">Halves damage this turn</span>
            DEFEND
          </button>
        </div>
      </div>

      {/* Victory overlay */}
      {state.phase === PHASES.VICTORY && (
        <div className="result-overlay victory">
          <h2>VICTORY!</h2>
          <div className="xp-display">+{state.xpGained} XP</div>
          {state.leveledUp && (
            <div className="level-up-display">LEVEL UP! Now Lv.{state.newLevel}</div>
          )}
          <button className="result-btn" onClick={onBattleEnd}>CONTINUE</button>
        </div>
      )}

      {/* Defeat overlay */}
      {state.phase === PHASES.DEFEAT && (
        <div className="result-overlay defeat">
          <h2>DEFEATED</h2>
          <p style={{ fontSize: 9, color: '#44ff44', maxWidth: 400, textAlign: 'center', lineHeight: 1.8 }}>
            "Hmm, a setback! But every great Dragon Forger learns from defeat. Recalibrate and try again!"
            <br />— Professor Felix
          </p>
          <button className="result-btn" onClick={onBattleEnd}>TRY AGAIN</button>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Update App.jsx to use BattleScreen**

Final version of `App.jsx`:

```jsx
import { useState } from 'react';
import TitleScreen from './TitleScreen';
import BattleSelectScreen from './BattleSelectScreen';
import BattleScreen from './BattleScreen';

const SCREENS = {
  TITLE: 'title',
  BATTLE_SELECT: 'battleSelect',
  BATTLE: 'battle',
};

export default function App() {
  const [screen, setScreen] = useState(SCREENS.TITLE);
  const [battleConfig, setBattleConfig] = useState(null);

  function handleStartGame() {
    setScreen(SCREENS.BATTLE_SELECT);
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
      {screen === SCREENS.BATTLE_SELECT && (
        <BattleSelectScreen onBeginBattle={handleBeginBattle} />
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

- [ ] **Step 3: Verify full battle flow**

Run: `npm run dev`
Expected:
1. Title screen shows, click "ENTER THE FORGE"
2. Battle select — pick a dragon and NPC, see matchup, click "BEGIN BATTLE"
3. Battle screen — arena background, sprites visible, HP bars in top panel, move buttons in bottom panel
4. Click a move — animation plays (telegraph flash, damage number floats up, recoil shake, HP bar animates)
5. NPC attacks back — same animation sequence
6. Battle continues until one side's HP reaches 0
7. Victory: XP screen with continue button → back to battle select
8. Defeat: Felix encouragement with try again button → back to battle select

- [ ] **Step 4: Commit**

```bash
git add src/BattleScreen.jsx src/App.jsx
git commit -m "feat: full battle screen with turn-based combat, animations, and results"
```

---

## Task 14: Run All Tests & Final Verification

**Files:** None (verification only)

- [ ] **Step 1: Run the full test suite**

Run: `npx vitest run`
Expected: All battle engine tests PASS.

- [ ] **Step 2: Run the build**

Run: `npm run build`
Expected: Vite builds to `dist/` with no errors. Output should show asset sizes.

- [ ] **Step 3: Preview the production build**

Run: `npm run preview`
Expected: Production build serves on http://localhost:4173. Full game flow works identically to dev mode.

- [ ] **Step 4: Play through a full session**

Manual verification:
1. Title screen → intro text → "ENTER THE FORGE"
2. Select Magma Dragon vs Firewall Sentinel (SUPER EFFECTIVE)
3. Win the battle, verify XP awarded and level saved
4. Return to battle select, verify level persisted on the dragon card
5. Select Ice Dragon vs Bit Wraith (SUPER EFFECTIVE)
6. Test defeat scenario — pick a weak matchup and let the NPC win
7. Verify "TRY AGAIN" returns to select screen

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "feat: Dragon Forge combat milestone complete — battle system fully playable"
```
