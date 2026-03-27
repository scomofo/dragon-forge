# Dragon Forge: Status Effects & Fusion Chamber Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 6 elemental status effects to combat (Burn, Freeze, Paralyze, Guard Break, Poison, Blind) and a Fusion Chamber where players breed two dragons into a stronger offspring with elemental alchemy and stability tiers.

**Architecture:** Status effects extend the existing battle engine with status state tracking, effect application, and turn-based tick/expiry. Fusion Chamber is a new pure-function engine (`fusionEngine.js`) + React screen (`FusionScreen.jsx`). Both follow established patterns: pure logic modules with TDD, React components for UI.

**Tech Stack:** React 18, Vitest, Web Audio API (new SFX), CSS, localStorage

---

## File Map

### Part A: Status Effects
| File | Responsibility |
|---|---|
| `src/gameData.js` | **Modify:** Add `canApplyStatus` to moves, add status effect config |
| `src/battleEngine.js` | **Modify:** Status processing in turn resolution |
| `src/battleEngine.test.js` | **Modify:** Status effect tests |
| `src/BattleScreen.jsx` | **Modify:** Status display below HP bars, status event animations |
| `src/soundEngine.js` | **Modify:** Add statusApply, statusTick, statusExpire SFX |
| `src/styles.css` | **Modify:** Status indicator styles |

### Part B: Fusion Chamber
| File | Responsibility |
|---|---|
| `src/fusionEngine.js` | **Create:** Alchemy table, stat calc, stability, fusion execution |
| `src/fusionEngine.test.js` | **Create:** Tests for fusion engine |
| `src/FusionScreen.jsx` | **Create:** Fusion UI with parent selection, preview, animation |
| `src/persistence.js` | **Modify:** Migration for fusedBaseStats, fusion save operations |
| `src/battleEngine.js` | **Modify:** Support fusedBaseStats in stat calculation |
| `src/NavBar.jsx` | **Modify:** Conditional FUSION tab |
| `src/App.jsx` | **Modify:** Add fusion screen routing |
| `src/soundEngine.js` | **Modify:** Add fusion SFX |
| `src/styles.css` | **Modify:** Fusion screen styles |

---

# Part A: Status Effects

## Task 1: Game Data — Status Config & Move Updates

**Files:**
- Modify: `src/gameData.js`

- [ ] **Step 1: Add status effect config and canApplyStatus to moves**

Read `src/gameData.js`. Make TWO changes:

**Change 1:** Add `canApplyStatus: true` to every elemental move and `canApplyStatus: false` to basic_attack. For each move entry, add the field after `vfxKey`. Example for magma_breath:
```js
  magma_breath: { name: 'Magma Breath', element: 'fire', power: 65, accuracy: 95, vfxKey: 'MAGMA_BREATH', canApplyStatus: true },
```
For basic_attack:
```js
  basic_attack: { name: 'Basic Attack', element: 'neutral', power: 40, accuracy: 100, vfxKey: 'BASIC_ATTACK', canApplyStatus: false },
```

**Change 2:** Add status effect config at the end of the file (after the rarity config):

```js
// === STATUS EFFECTS ===
export const STATUS_EFFECTS = {
  fire:   { name: 'Burn',       icon: '🔥', duration: 2, type: 'dot',    value: 0.08 },
  ice:    { name: 'Freeze',     icon: '❄️', duration: 1, type: 'skip',   value: 1.0 },
  storm:  { name: 'Paralyze',   icon: '⚡', duration: 2, type: 'maySkip', value: 0.5 },
  stone:  { name: 'Guard Break', icon: '🛡️', duration: 2, type: 'debuff', value: 0.4 },
  venom:  { name: 'Poison',     icon: '☠️', duration: 2, type: 'dot',    value: 0.06 },
  shadow: { name: 'Blind',      icon: '👁️', duration: 2, type: 'debuff', value: 0.3 },
};

export const STATUS_APPLY_CHANCE = 0.30;
```

- [ ] **Step 2: Commit**

```bash
git add src/gameData.js
git commit -m "feat: add canApplyStatus to moves and STATUS_EFFECTS config"
```

---

## Task 2: Battle Engine — Status Effect Processing

**Files:**
- Modify: `src/battleEngine.js`, `src/battleEngine.test.js`

- [ ] **Step 1: Write failing tests for status effects**

Add to `src/battleEngine.test.js`. Update imports to include `applyStatus, processStatusTick`:

```js
import {
  getTypeEffectiveness, calculateDamage, calculateXpGain,
  calculateStatsForLevel, getStageForLevel, pickNpcMove, resolveTurn,
  applyStatus, processStatusTick
} from './battleEngine';

describe('applyStatus', () => {
  it('applies burn status from fire move', () => {
    const result = applyStatus('fire');
    expect(result).toEqual({ effect: 'fire', turnsLeft: 2 });
  });

  it('returns null for neutral element', () => {
    expect(applyStatus('neutral')).toBe(null);
  });

  it('applies freeze with 1 turn duration', () => {
    const result = applyStatus('ice');
    expect(result).toEqual({ effect: 'ice', turnsLeft: 1 });
  });
});

describe('processStatusTick', () => {
  it('deals DOT damage for burn', () => {
    const state = { hp: 100, maxHp: 100, status: { effect: 'fire', turnsLeft: 2 } };
    const result = processStatusTick(state);
    expect(result.hp).toBe(92); // 8% of 100
    expect(result.status.turnsLeft).toBe(1);
    expect(result.statusEvent).toEqual({ type: 'dot', damage: 8, effectName: 'Burn' });
  });

  it('deals DOT damage for poison', () => {
    const state = { hp: 100, maxHp: 100, status: { effect: 'venom', turnsLeft: 2 } };
    const result = processStatusTick(state);
    expect(result.hp).toBe(94); // 6% of 100
    expect(result.status.turnsLeft).toBe(1);
  });

  it('expires status when turnsLeft reaches 0', () => {
    const state = { hp: 100, maxHp: 100, status: { effect: 'fire', turnsLeft: 1 } };
    const result = processStatusTick(state);
    expect(result.hp).toBe(92);
    expect(result.status).toBe(null);
    expect(result.statusEvent.expired).toBe(true);
  });

  it('returns unchanged state when no status', () => {
    const state = { hp: 100, maxHp: 100, status: null };
    const result = processStatusTick(state);
    expect(result.hp).toBe(100);
    expect(result.statusEvent).toBe(null);
  });

  it('decrements non-DOT status without damage', () => {
    const state = { hp: 100, maxHp: 100, status: { effect: 'stone', turnsLeft: 2 } };
    const result = processStatusTick(state);
    expect(result.hp).toBe(100);
    expect(result.status.turnsLeft).toBe(1);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `npx vitest run src/battleEngine.test.js`
Expected: FAIL — `applyStatus` and `processStatusTick` not exported.

- [ ] **Step 3: Implement applyStatus and processStatusTick**

Add to `src/battleEngine.js`. Update import at top to include `STATUS_EFFECTS, STATUS_APPLY_CHANCE`:

```js
import { typeChart, stageMultipliers, stageThresholds, moves as allMoves, STATUS_EFFECTS, STATUS_APPLY_CHANCE } from './gameData';
```

Add these functions:

```js
export function applyStatus(moveElement) {
  const effect = STATUS_EFFECTS[moveElement];
  if (!effect) return null;
  return { effect: moveElement, turnsLeft: effect.duration };
}

export function processStatusTick(combatantState) {
  if (!combatantState.status) {
    return { ...combatantState, statusEvent: null };
  }

  const effect = STATUS_EFFECTS[combatantState.status.effect];
  let hp = combatantState.hp;
  let damage = 0;
  const turnsLeft = combatantState.status.turnsLeft - 1;
  const expired = turnsLeft <= 0;

  // DOT effects
  if (effect.type === 'dot') {
    damage = Math.max(1, Math.floor(combatantState.maxHp * effect.value));
    hp = Math.max(0, hp - damage);
  }

  return {
    ...combatantState,
    hp,
    status: expired ? null : { ...combatantState.status, turnsLeft },
    statusEvent: {
      type: effect.type,
      damage,
      effectName: effect.name,
      expired,
    },
  };
}
```

- [ ] **Step 4: Update resolveAction to apply statuses and respect status debuffs**

Replace the `resolveAction` function in `src/battleEngine.js`:

```js
function resolveAction(actor, events, getTarget, setTarget, setSelf) {
  // Check for Freeze — skip entirely
  if (actor.state.status?.effect === 'ice') {
    events.push({
      attacker: actor.label,
      action: 'statusSkip',
      statusName: 'Freeze',
    });
    return;
  }

  // Check for Paralyze — 50% chance to skip
  if (actor.state.status?.effect === 'storm') {
    if (Math.random() < STATUS_EFFECTS.storm.value) {
      events.push({
        attacker: actor.label,
        action: 'statusSkip',
        statusName: 'Paralyze',
      });
      return;
    }
  }

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

  // Apply Guard Break debuff to effective DEF
  let effectiveDef = target.def;
  if (target.status?.effect === 'stone') {
    effectiveDef = Math.floor(effectiveDef * (1 - STATUS_EFFECTS.stone.value));
  }

  // Apply Blind debuff to effective accuracy
  let effectiveAccuracy = move.accuracy;
  if (actor.state.status?.effect === 'shadow') {
    effectiveAccuracy = Math.max(0, effectiveAccuracy - STATUS_EFFECTS.shadow.value * 100);
  }

  const result = calculateDamage(
    { atk: actor.state.atk, element: actor.state.element, stage: actor.state.stage },
    { def: effectiveDef, element: target.element, defending: target.defending },
    { ...move, accuracy: effectiveAccuracy }
  );

  const newTargetHp = Math.max(0, target.hp - result.damage);
  setTarget({ ...target, hp: newTargetHp });

  // Status application roll
  let appliedStatus = null;
  if (result.hit && move.canApplyStatus && Math.random() < STATUS_APPLY_CHANCE) {
    appliedStatus = applyStatus(move.element);
    if (appliedStatus) {
      const updatedTarget = getTarget();
      setTarget({ ...updatedTarget, status: appliedStatus });
    }
  }

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
    appliedStatus: appliedStatus ? STATUS_EFFECTS[appliedStatus.effect].name : null,
  });
}
```

- [ ] **Step 5: Update resolveTurn to process status ticks at end of turn**

Replace the `resolveTurn` function:

```js
export function resolveTurn(playerState, npcState, playerMoveKey, npcMoveKey) {
  let player = { ...playerState, defending: false };
  let npc = { ...npcState, defending: false };
  const events = [];

  const playerFirst = player.spd >= npc.spd;

  const first = playerFirst
    ? { state: player, moveKey: playerMoveKey, label: 'player' }
    : { state: npc, moveKey: npcMoveKey, label: 'npc' };

  const second = playerFirst
    ? { state: npc, moveKey: npcMoveKey, label: 'npc' }
    : { state: player, moveKey: playerMoveKey, label: 'player' };

  // Resolve first attacker
  resolveAction(first, events,
    () => first.label === 'player' ? npc : player,
    (t) => { if (first.label === 'player') npc = t; else player = t; },
    (s) => { if (first.label === 'player') player = s; else npc = s; }
  );

  // Check if target is KO'd
  const firstTarget = first.label === 'player' ? npc : player;
  if (firstTarget.hp > 0) {
    second.state = second.label === 'player' ? player : npc;

    resolveAction(second, events,
      () => second.label === 'player' ? npc : player,
      (t) => { if (second.label === 'player') npc = t; else player = t; },
      (s) => { if (second.label === 'player') player = s; else npc = s; }
    );
  }

  // Process status ticks at end of turn (if both alive)
  if (player.hp > 0 && player.status) {
    const playerTick = processStatusTick({ ...player, maxHp: playerState.maxHp || player.maxHp });
    player = { ...player, hp: playerTick.hp, status: playerTick.status };
    if (playerTick.statusEvent) {
      events.push({ attacker: 'status', target: 'player', ...playerTick.statusEvent });
    }
  }
  if (npc.hp > 0 && npc.status) {
    const npcTick = processStatusTick({ ...npc, maxHp: npcState.maxHp || npc.maxHp });
    npc = { ...npc, hp: npcTick.hp, status: npcTick.status };
    if (npcTick.statusEvent) {
      events.push({ attacker: 'status', target: 'npc', ...npcTick.statusEvent });
    }
  }

  return { player, npc, events };
}
```

- [ ] **Step 6: Run all tests**

Run: `npx vitest run`
Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add src/battleEngine.js src/battleEngine.test.js
git commit -m "feat: status effects in battle engine — burn, freeze, paralyze, guard break, poison, blind"
```

---

## Task 3: Status SFX + CSS

**Files:**
- Modify: `src/soundEngine.js`, `src/styles.css`

- [ ] **Step 1: Add status SFX to soundEngine.js**

Read `src/soundEngine.js`. Find the SFX catalog object and add these entries (after the `scrapsEarned` entry):

```js
  // Status
  statusApply: () => { playNoise(60, 2000, 0.4); playTone(350, 80, 'sawtooth', 0.3); },
  statusTick: () => playNoise(40, 1500, 0.25),
  statusExpire: () => playArpeggio([400, 500, 600], 'sine', 60),
```

- [ ] **Step 2: Add status CSS to styles.css**

Read `src/styles.css` and append:

```css
/* === STATUS EFFECTS === */
.status-indicator {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 8px;
  margin-top: 4px;
  padding: 2px 6px;
  border-radius: 3px;
  background: rgba(0, 0, 0, 0.5);
  border: 1px solid #444;
}

.status-indicator.burn { border-color: #ff6622; color: #ff8844; }
.status-indicator.freeze { border-color: #44aaff; color: #66ccff; }
.status-indicator.paralyze { border-color: #aa66ff; color: #cc88ff; }
.status-indicator.guardbreak { border-color: #aa8844; color: #ccaa66; }
.status-indicator.poison { border-color: #44cc44; color: #66ee66; }
.status-indicator.blind { border-color: #8844aa; color: #aa66cc; }

.status-flash {
  position: absolute;
  font-size: 9px;
  pointer-events: none;
  animation: damageFloat 1s ease-out forwards;
  text-shadow: 2px 2px 0px #000;
  z-index: 20;
}
```

- [ ] **Step 3: Commit**

```bash
git add src/soundEngine.js src/styles.css
git commit -m "feat: status effect SFX and CSS indicators"
```

---

## Task 4: BattleScreen — Status Display & Animation

**Files:**
- Modify: `src/BattleScreen.jsx`

- [ ] **Step 1: Update BattleScreen for status effects**

Read `src/BattleScreen.jsx`. Make these changes:

**1.** Add import at top:
```js
import { STATUS_EFFECTS } from './gameData';
```

**2.** Add `status: null` to the `initBattle` return object for both player and NPC state. Add these fields:
```js
    playerStatus: null,
    npcStatus: null,
```

**3.** Add reducer cases for status updates. In `battleReducer`, add:
```js
    case 'SET_PLAYER_STATUS':
      return { ...state, playerStatus: action.value };
    case 'SET_NPC_STATUS':
      return { ...state, npcStatus: action.value };
```

**4.** In the `animateEvent` callback, after the existing event handling, add status event processing. At the end of the callback (before the final `await wait(200)`), add a check for `appliedStatus`:
```js
    // Status application
    if (event.appliedStatus) {
      playSound('statusApply');
    }
```

**5.** In `handleMoveSelect`, after the `for (const event of result.events)` loop, add status sync and status event animation:
```js
    // Sync status state from engine result
    dispatch({ type: 'SET_PLAYER_STATUS', value: result.player.status || null });
    dispatch({ type: 'SET_NPC_STATUS', value: result.npc.status || null });

    // Animate status tick events
    for (const event of result.events) {
      if (event.attacker === 'status') {
        if (event.damage > 0) {
          playSound('statusTick');
          const dmgId = ++damageIdCounter;
          dispatch({
            type: 'ADD_DAMAGE_NUMBER',
            entry: {
              id: dmgId,
              damage: event.damage,
              effectiveness: 1.0,
              hit: true,
              target: event.target,
            },
          });
          if (event.target === 'player') {
            dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
          } else {
            dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
          }
          await wait(400);
        }
        if (event.expired) {
          playSound('statusExpire');
        }
      }
      if (event.action === 'statusSkip') {
        const dmgId = ++damageIdCounter;
        dispatch({
          type: 'ADD_DAMAGE_NUMBER',
          entry: {
            id: dmgId,
            damage: 0,
            effectiveness: 1.0,
            hit: false,
            target: event.attacker === 'player' ? 'player' : 'npc',
          },
        });
        await wait(300);
      }
    }
```

**6.** Update the `handleMoveSelect` player/NPC state construction to include status:
```js
    const playerState = {
      ...existing fields...,
      status: state.playerStatus,
      maxHp: state.playerMaxHp,
    };

    const npcState = {
      ...existing fields...,
      status: state.npcStatus,
      maxHp: state.npcMaxHp,
    };
```

**7.** In the JSX, add status indicators below each HP bar. After the player HP bar's closing `</div>`, add:
```jsx
        {state.playerStatus && (
          <div className={`status-indicator ${STATUS_EFFECTS[state.playerStatus.effect]?.name.toLowerCase().replace(' ', '')}`}>
            {STATUS_EFFECTS[state.playerStatus.effect]?.icon} {STATUS_EFFECTS[state.playerStatus.effect]?.name} {state.playerStatus.turnsLeft}t
          </div>
        )}
```

Same for NPC HP bar:
```jsx
        {state.npcStatus && (
          <div className={`status-indicator ${STATUS_EFFECTS[state.npcStatus.effect]?.name.toLowerCase().replace(' ', '')}`}>
            {STATUS_EFFECTS[state.npcStatus.effect]?.icon} {STATUS_EFFECTS[state.npcStatus.effect]?.name} {state.npcStatus.turnsLeft}t
          </div>
        )}
```

- [ ] **Step 2: Verify build**

Run: `npx vite build`
Expected: Clean build.

- [ ] **Step 3: Commit**

```bash
git add src/BattleScreen.jsx
git commit -m "feat: status effect display in battle — indicators, DOT animation, skip events"
```

---

# Part B: Fusion Chamber

## Task 5: Persistence — fusedBaseStats Migration

**Files:**
- Modify: `src/persistence.js`

- [ ] **Step 1: Update persistence for fusedBaseStats**

Read `src/persistence.js`. Make these changes:

**1.** Update `DEFAULT_SAVE` dragon entries to include `fusedBaseStats: null`:
```js
    fire:   { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null },
```
(Same for all 6 dragons.)

**2.** In `migrateSave`, add:
```js
    if (d.fusedBaseStats === undefined) {
      d.fusedBaseStats = null;
    }
```

**3.** Add a `fuseDragons` function:

```js
export function fuseDragons(parentAId, parentBId, offspringElement, offspringLevel, offspringXp, offspringShiny, fusedBaseStats) {
  const save = loadSave();

  // Consume parents
  save.dragons[parentAId] = { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null };
  save.dragons[parentBId] = { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null };

  // Create offspring
  save.dragons[offspringElement] = {
    level: offspringLevel,
    xp: offspringXp,
    owned: true,
    shiny: offspringShiny,
    fusedBaseStats,
  };

  // Deduct cost
  save.dataScraps -= 100;

  writeSave(save);
  return save;
}
```

- [ ] **Step 2: Commit**

```bash
git add src/persistence.js
git commit -m "feat: persistence — fusedBaseStats migration + fuseDragons operation"
```

---

## Task 6: Battle Engine — Support fusedBaseStats

**Files:**
- Modify: `src/battleEngine.js`

- [ ] **Step 1: No engine changes needed**

The `calculateStatsForLevel` function already accepts `baseStats` as a parameter. The caller (BattleScreen, BattleSelectScreen) passes `dragon.baseStats` from gameData. To support fusedBaseStats, the callers just need to check `save.dragons[id].fusedBaseStats || dragon.baseStats` — no engine change required.

This is handled in Task 10 (FusionScreen) and already works in BattleSelectScreen since it reads from save.

Skip this task — mark complete immediately.

- [ ] **Step 2: Commit** (no-op, nothing to commit)

---

## Task 7: Fusion Engine — Alchemy Table & Stats

**Files:**
- Create: `src/fusionEngine.js`, `src/fusionEngine.test.js`

- [ ] **Step 1: Write failing tests for fusion alchemy and stats**

```js
// src/fusionEngine.test.js
import { describe, it, expect } from 'vitest';
import { getFusionElement, calculateFusionStats, getStabilityTier } from './fusionEngine';

describe('getFusionElement', () => {
  it('returns same element for same-element fusion', () => {
    expect(getFusionElement('fire', 'fire')).toBe('fire');
    expect(getFusionElement('shadow', 'shadow')).toBe('shadow');
  });

  it('returns storm for fire+ice', () => {
    expect(getFusionElement('fire', 'ice')).toBe('storm');
    expect(getFusionElement('ice', 'fire')).toBe('storm');
  });

  it('returns shadow for fire+venom', () => {
    expect(getFusionElement('fire', 'venom')).toBe('shadow');
    expect(getFusionElement('venom', 'fire')).toBe('shadow');
  });

  it('is commutative — order doesnt matter', () => {
    expect(getFusionElement('ice', 'storm')).toBe(getFusionElement('storm', 'ice'));
    expect(getFusionElement('stone', 'shadow')).toBe(getFusionElement('shadow', 'stone'));
  });
});

describe('getStabilityTier', () => {
  it('returns stable for same element', () => {
    expect(getStabilityTier('fire', 'fire')).toBe('stable');
  });

  it('returns unstable for opposing elements', () => {
    expect(getStabilityTier('fire', 'ice')).toBe('unstable');
    expect(getStabilityTier('storm', 'stone')).toBe('unstable');
    expect(getStabilityTier('venom', 'shadow')).toBe('unstable');
  });

  it('returns normal for neutral combos', () => {
    expect(getStabilityTier('fire', 'storm')).toBe('normal');
    expect(getStabilityTier('ice', 'venom')).toBe('normal');
  });
});

describe('calculateFusionStats', () => {
  const parentA = { hp: 100, atk: 30, def: 20, spd: 20 };
  const parentB = { hp: 80, atk: 20, def: 30, spd: 10 };

  it('averages stats with 10% fusion bonus', () => {
    const result = calculateFusionStats(parentA, parentB, 'normal');
    // avg: hp=90 atk=25 def=25 spd=15 => *1.1 = 99, 27, 27, 16
    expect(result).toEqual({ hp: 99, atk: 27, def: 27, spd: 16 });
  });

  it('applies 25% bonus for stable fusion', () => {
    const result = calculateFusionStats(parentA, parentB, 'stable');
    // avg*1.1: hp=99 atk=27 def=27 spd=16 => *1.25 = 123, 33, 33, 20
    expect(result).toEqual({ hp: 123, atk: 33, def: 33, spd: 20 });
  });

  it('applies unstable modifiers — HP*0.8, ATK*1.1', () => {
    const result = calculateFusionStats(parentA, parentB, 'unstable');
    // avg*1.1: hp=99 atk=27 def=27 spd=16 => hp*0.8=79, atk*1.1=29
    expect(result).toEqual({ hp: 79, atk: 29, def: 27, spd: 16 });
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `npx vitest run src/fusionEngine.test.js`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement fusion engine**

```js
// src/fusionEngine.js

// Alchemy table — key is sorted pair "elementA_elementB"
const ALCHEMY = {
  'fire_fire': 'fire',
  'ice_ice': 'ice',
  'storm_storm': 'storm',
  'stone_stone': 'stone',
  'venom_venom': 'venom',
  'shadow_shadow': 'shadow',
  'fire_ice': 'storm',
  'fire_storm': 'fire',
  'fire_stone': 'stone',
  'fire_venom': 'shadow',
  'fire_shadow': 'fire',
  'ice_storm': 'ice',
  'ice_stone': 'stone',
  'ice_venom': 'venom',
  'ice_shadow': 'shadow',
  'stone_storm': 'storm',
  'storm_venom': 'venom',
  'shadow_storm': 'shadow',
  'stone_venom': 'venom',
  'shadow_stone': 'stone',
  'shadow_venom': 'shadow',
};

const OPPOSING_PAIRS = [
  ['fire', 'ice'],
  ['storm', 'stone'],
  ['venom', 'shadow'],
];

function sortedKey(a, b) {
  return [a, b].sort().join('_');
}

export function getFusionElement(elementA, elementB) {
  return ALCHEMY[sortedKey(elementA, elementB)] || elementA;
}

export function getStabilityTier(elementA, elementB) {
  if (elementA === elementB) return 'stable';
  for (const [a, b] of OPPOSING_PAIRS) {
    if ((elementA === a && elementB === b) || (elementA === b && elementB === a)) {
      return 'unstable';
    }
  }
  return 'normal';
}

export function calculateFusionStats(statsA, statsB, stabilityTier) {
  const avg = {
    hp:  (statsA.hp + statsB.hp) / 2,
    atk: (statsA.atk + statsB.atk) / 2,
    def: (statsA.def + statsB.def) / 2,
    spd: (statsA.spd + statsB.spd) / 2,
  };

  // 10% fusion bonus
  let fused = {
    hp:  Math.floor(avg.hp * 1.1),
    atk: Math.floor(avg.atk * 1.1),
    def: Math.floor(avg.def * 1.1),
    spd: Math.floor(avg.spd * 1.1),
  };

  if (stabilityTier === 'stable') {
    fused = {
      hp:  Math.floor(fused.hp * 1.25),
      atk: Math.floor(fused.atk * 1.25),
      def: Math.floor(fused.def * 1.25),
      spd: Math.floor(fused.spd * 1.25),
    };
  } else if (stabilityTier === 'unstable') {
    fused.hp = Math.floor(fused.hp * 0.8);
    fused.atk = Math.floor(fused.atk * 1.1);
  }

  return fused;
}
```

- [ ] **Step 4: Run tests**

Run: `npx vitest run src/fusionEngine.test.js`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/fusionEngine.js src/fusionEngine.test.js
git commit -m "feat: fusion engine — alchemy table, stability tiers, stat calculation"
```

---

## Task 8: Fusion Engine — Full Fusion Execution

**Files:**
- Modify: `src/fusionEngine.js`, `src/fusionEngine.test.js`

- [ ] **Step 1: Write failing tests for executeFusion**

Add to `src/fusionEngine.test.js`:

```js
import { getFusionElement, calculateFusionStats, getStabilityTier, executeFusion } from './fusionEngine';

describe('executeFusion', () => {
  it('produces offspring with correct element and stats', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 110, atk: 28, def: 20, spd: 18 }, level: 12, shiny: false };
    const parentB = { id: 'ice', element: 'ice', stats: { hp: 100, atk: 24, def: 26, spd: 20 }, level: 10, shiny: false };
    const result = executeFusion(parentA, parentB);
    expect(result.element).toBe('storm'); // fire+ice=storm
    expect(result.stabilityTier).toBe('unstable'); // fire↔ice opposing
    expect(result.fusedBaseStats).toHaveProperty('hp');
    expect(result.level).toBe(1);
    expect(result.shiny).toBe(false);
  });

  it('inherits shiny from either parent', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 12, shiny: true };
    const parentB = { id: 'storm', element: 'storm', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 12, shiny: false };
    const result = executeFusion(parentA, parentB);
    expect(result.shiny).toBe(true);
  });

  it('creates Stage IV Elder when both parents are Stage III', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 200, atk: 50, def: 40, spd: 40 }, level: 30, shiny: false };
    const parentB = { id: 'fire', element: 'fire', stats: { hp: 200, atk: 50, def: 40, spd: 40 }, level: 25, shiny: false };
    const result = executeFusion(parentA, parentB);
    expect(result.level).toBe(50); // Stage IV
  });

  it('stays level 1 when parents are not both Stage III', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 24, shiny: false };
    const parentB = { id: 'fire', element: 'fire', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 25, shiny: false };
    const result = executeFusion(parentA, parentB);
    expect(result.level).toBe(1);
  });
});
```

- [ ] **Step 2: Implement executeFusion**

Add to `src/fusionEngine.js`:

```js
export function executeFusion(parentA, parentB) {
  const element = getFusionElement(parentA.element, parentB.element);
  const stabilityTier = getStabilityTier(parentA.element, parentB.element);
  const fusedBaseStats = calculateFusionStats(parentA.stats, parentB.stats, stabilityTier);
  const shiny = parentA.shiny || parentB.shiny;

  // Stage IV Elder: both parents must be Stage III (level 25+)
  const bothStageIII = parentA.level >= 25 && parentB.level >= 25;
  const level = bothStageIII ? 50 : 1;

  return {
    element,
    stabilityTier,
    fusedBaseStats,
    shiny,
    level,
    xp: 0,
    parentAId: parentA.id,
    parentBId: parentB.id,
  };
}
```

- [ ] **Step 3: Run all tests**

Run: `npx vitest run`
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add src/fusionEngine.js src/fusionEngine.test.js
git commit -m "feat: fusion engine — full fusion execution with Stage IV Elder creation"
```

---

## Task 9: Fusion SFX + CSS

**Files:**
- Modify: `src/soundEngine.js`, `src/styles.css`

- [ ] **Step 1: Add fusion SFX**

Read `src/soundEngine.js`. Add after the status SFX entries:

```js
  // Fusion
  fusionMerge: () => { playTone(300, 300, 'sine', 0.4); playTone(500, 300, 'sine', 0.4); },
  fusionBurst: () => { playNoise(200, 4000, 0.6); playTone(600, 200, 'sine', 0.5); },
  fusionReveal: () => playArpeggio([523, 659, 784, 1047], 'square', 100),
```

- [ ] **Step 2: Add fusion CSS**

Read `src/styles.css` and append:

```css
/* === FUSION SCREEN === */
.fusion-screen {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.fusion-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding: 20px;
}

.fusion-title {
  font-size: 14px;
  color: #ff6622;
  text-shadow: 0 0 10px rgba(255, 102, 34, 0.3);
}

.fusion-parents {
  display: flex;
  gap: 40px;
  align-items: center;
}

.fusion-slot {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 12px;
  background: #1a1a2e;
  border: 2px dashed #444;
  border-radius: 8px;
  min-width: 160px;
  min-height: 180px;
  cursor: pointer;
  transition: all 0.15s;
}

.fusion-slot:hover {
  border-color: #666;
}

.fusion-slot.filled {
  border-style: solid;
  border-color: #ff6622;
}

.fusion-slot-label {
  font-size: 8px;
  color: #888;
}

.fusion-arrow {
  font-size: 20px;
  color: #ff6622;
}

.fusion-preview {
  text-align: center;
  padding: 12px 20px;
  background: #1a1a2e;
  border: 1px solid #444;
  border-radius: 6px;
  min-width: 250px;
}

.fusion-preview h3 {
  font-size: 10px;
  color: #888;
  margin-bottom: 8px;
}

.fusion-preview-element {
  font-size: 11px;
  margin-bottom: 4px;
}

.fusion-preview-stability {
  font-size: 9px;
  margin-bottom: 4px;
}

.fusion-preview-stability.stable { color: #44ff44; }
.fusion-preview-stability.normal { color: #e0e0e0; }
.fusion-preview-stability.unstable { color: #ff4444; }

.fusion-preview-stats {
  font-size: 8px;
  color: #888;
}

.fusion-warning {
  font-size: 8px;
  color: #ff4444;
  margin-top: 4px;
}

.fusion-btn {
  font-family: 'Press Start 2P', monospace;
  font-size: 10px;
  padding: 12px 24px;
  background: #1a1a2e;
  color: #ff6622;
  border: 2px solid #ff6622;
  cursor: pointer;
  transition: all 0.2s;
}

.fusion-btn:hover:not(:disabled) {
  background: #ff6622;
  color: #111118;
}

.fusion-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
  border-color: #444;
  color: #444;
}

.fusion-dragon-picker {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
  max-width: 500px;
}

.fusion-picker-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px;
  background: #1a1a2e;
  border: 1px solid #333;
  border-radius: 4px;
  cursor: pointer;
  font-size: 8px;
  transition: all 0.15s;
}

.fusion-picker-card:hover {
  border-color: #666;
}

.fusion-picker-card.selected {
  border-color: #ff6622;
  box-shadow: 0 0 8px rgba(255, 102, 34, 0.2);
}

.fusion-picker-card.disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

@keyframes fusionSlide {
  from { transform: translateX(0); }
  to { transform: translateX(var(--slide-x)); }
}

@keyframes fusionFlash {
  0% { opacity: 0; }
  50% { opacity: 1; }
  100% { opacity: 0; }
}

.fusion-animation-overlay {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 50;
}

.fusion-flash {
  width: 200px;
  height: 200px;
  border-radius: 50%;
  animation: fusionFlash 0.3s ease-out;
}

.fusion-result-card {
  animation: revealFadeIn 0.4s ease-out;
  text-align: center;
}
```

- [ ] **Step 3: Commit**

```bash
git add src/soundEngine.js src/styles.css
git commit -m "feat: fusion SFX and CSS styles"
```

---

## Task 10: Fusion Screen

**Files:**
- Create: `src/FusionScreen.jsx`

- [ ] **Step 1: Create src/FusionScreen.jsx**

```jsx
import { useState, useCallback } from 'react';
import { dragons, elementColors } from './gameData';
import { getFusionElement, getStabilityTier, calculateFusionStats, executeFusion } from './fusionEngine';
import { calculateStatsForLevel, getStageForLevel } from './battleEngine';
import { loadSave, fuseDragons } from './persistence';
import { playSound } from './soundEngine';
import NavBar from './NavBar';
import DragonSprite from './DragonSprite';

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export default function FusionScreen({ onNavigate }) {
  const [save, setSave] = useState(() => loadSave());
  const [parentA, setParentA] = useState(null);
  const [parentB, setParentB] = useState(null);
  const [phase, setPhase] = useState('select'); // select, animating, result
  const [fusionResult, setFusionResult] = useState(null);

  const refreshSave = () => setSave(loadSave());

  const ownedDragons = Object.entries(save.dragons)
    .filter(([, d]) => d.owned && d.level >= 10)
    .map(([id, d]) => {
      const dragon = dragons[id];
      const stage = getStageForLevel(d.level);
      const baseStats = d.fusedBaseStats || dragon.baseStats;
      const stats = calculateStatsForLevel(baseStats, d.level, d.shiny);
      return { id, ...dragon, ...d, stage, stats, baseStats };
    });

  const canFuse = parentA && parentB && save.dataScraps >= 100;

  function getPreview() {
    if (!parentA || !parentB) return null;
    const element = getFusionElement(parentA.element, parentB.element);
    const stability = getStabilityTier(parentA.element, parentB.element);
    const fusedStats = calculateFusionStats(parentA.stats, parentB.stats, stability);
    const color = elementColors[element];
    return { element, stability, fusedStats, color, dragonName: dragons[element].name };
  }

  const preview = getPreview();

  const handleFuse = useCallback(async () => {
    if (!canFuse || phase !== 'select') return;

    playSound('buttonClick');
    setPhase('animating');

    // Animation
    playSound('fusionMerge');
    await wait(600);
    playSound('fusionBurst');
    await wait(400);

    // Execute fusion
    const result = executeFusion(
      { id: parentA.id, element: parentA.element, stats: parentA.stats, level: parentA.level, shiny: parentA.shiny },
      { id: parentB.id, element: parentB.element, stats: parentB.stats, level: parentB.level, shiny: parentB.shiny }
    );

    fuseDragons(
      parentA.id, parentB.id,
      result.element, result.level, result.xp,
      result.shiny, result.fusedBaseStats
    );

    playSound('fusionReveal');
    setFusionResult(result);
    setPhase('result');
    refreshSave();
  }, [canFuse, phase, parentA, parentB]);

  const handleDismiss = () => {
    setPhase('select');
    setParentA(null);
    setParentB(null);
    setFusionResult(null);
    refreshSave();
  };

  const selectDragon = (dragon, slot) => {
    playSound('buttonClick');
    if (slot === 'A') {
      setParentA(dragon);
      if (parentB?.id === dragon.id) setParentB(null);
    } else {
      setParentB(dragon);
      if (parentA?.id === dragon.id) setParentA(null);
    }
  };

  return (
    <div className="fusion-screen">
      <NavBar activeScreen="fusion" onNavigate={onNavigate} />

      <div className="fusion-content">
        <div className="fusion-title">FUSION CHAMBER</div>

        {phase === 'select' && (
          <>
            <div className="fusion-parents">
              <div className={`fusion-slot ${parentA ? 'filled' : ''}`} onClick={() => parentA && setParentA(null)}>
                <div className="fusion-slot-label">PARENT A</div>
                {parentA ? (
                  <>
                    <DragonSprite spriteSheet={parentA.spriteSheet} stage={parentA.stage} size={{ width: 100, height: 75 }} shiny={parentA.shiny} />
                    <div style={{ fontSize: 9, color: elementColors[parentA.element]?.glow }}>{parentA.name}</div>
                    <div style={{ fontSize: 8, color: '#888' }}>Lv.{parentA.level}</div>
                  </>
                ) : (
                  <div style={{ fontSize: 20, color: '#333' }}>+</div>
                )}
              </div>

              <div className="fusion-arrow">+</div>

              <div className={`fusion-slot ${parentB ? 'filled' : ''}`} onClick={() => parentB && setParentB(null)}>
                <div className="fusion-slot-label">PARENT B</div>
                {parentB ? (
                  <>
                    <DragonSprite spriteSheet={parentB.spriteSheet} stage={parentB.stage} size={{ width: 100, height: 75 }} shiny={parentB.shiny} />
                    <div style={{ fontSize: 9, color: elementColors[parentB.element]?.glow }}>{parentB.name}</div>
                    <div style={{ fontSize: 8, color: '#888' }}>Lv.{parentB.level}</div>
                  </>
                ) : (
                  <div style={{ fontSize: 20, color: '#333' }}>+</div>
                )}
              </div>
            </div>

            {preview && (
              <div className="fusion-preview">
                <h3>RESULT PREVIEW</h3>
                <div className="fusion-preview-element" style={{ color: preview.color?.glow }}>
                  {preview.dragonName}
                </div>
                <div className={`fusion-preview-stability ${preview.stability}`}>
                  {preview.stability.toUpperCase()}
                </div>
                <div className="fusion-preview-stats">
                  HP:{preview.fusedStats.hp} ATK:{preview.fusedStats.atk} DEF:{preview.fusedStats.def} SPD:{preview.fusedStats.spd}
                </div>
                <div className="fusion-warning">⚠ Both parents will be consumed</div>
              </div>
            )}

            <div className="fusion-dragon-picker">
              {ownedDragons.map((d) => {
                const isSelectedA = parentA?.id === d.id;
                const isSelectedB = parentB?.id === d.id;
                const isSelected = isSelectedA || isSelectedB;
                return (
                  <div
                    key={d.id}
                    className={`fusion-picker-card ${isSelected ? 'selected' : ''}`}
                    onClick={() => {
                      if (isSelected) return;
                      if (!parentA) selectDragon(d, 'A');
                      else if (!parentB) selectDragon(d, 'B');
                    }}
                  >
                    <DragonSprite spriteSheet={d.spriteSheet} stage={d.stage} size={{ width: 60, height: 45 }} shiny={d.shiny} />
                    <div style={{ color: elementColors[d.element]?.glow, marginTop: 4 }}>{d.name.split(' ')[0]}</div>
                    <div style={{ color: '#888' }}>Lv.{d.level}</div>
                  </div>
                );
              })}
            </div>

            <button className="fusion-btn" disabled={!canFuse} onClick={handleFuse}>
              FUSE — 100◆
            </button>

            {ownedDragons.length < 2 && (
              <div style={{ fontSize: 8, color: '#666' }}>Need 2+ Stage II dragons to fuse</div>
            )}
          </>
        )}

        {phase === 'animating' && (
          <div className="fusion-animation-overlay">
            <div className="fusion-flash" style={{ background: 'radial-gradient(circle, #fff, transparent)' }} />
          </div>
        )}

        {phase === 'result' && fusionResult && (
          <div className="fusion-result-card" onClick={handleDismiss}>
            <DragonSprite
              spriteSheet={dragons[fusionResult.element].spriteSheet}
              stage={getStageForLevel(fusionResult.level)}
              size={{ width: 180, height: 140 }}
              shiny={fusionResult.shiny}
            />
            <div style={{ color: elementColors[fusionResult.element]?.glow, fontSize: 12, marginTop: 8 }}>
              {dragons[fusionResult.element].name}
              {fusionResult.shiny && <span className="shiny-star">★</span>}
            </div>
            <div className={`fusion-preview-stability ${fusionResult.stabilityTier}`} style={{ marginTop: 4 }}>
              {fusionResult.stabilityTier.toUpperCase()} FUSION
            </div>
            <div style={{ fontSize: 9, color: '#888', marginTop: 4 }}>
              HP:{fusionResult.fusedBaseStats.hp} ATK:{fusionResult.fusedBaseStats.atk} DEF:{fusionResult.fusedBaseStats.def} SPD:{fusionResult.fusedBaseStats.spd}
            </div>
            {fusionResult.level === 50 && (
              <div style={{ fontSize: 10, color: '#ffcc00', marginTop: 8 }}>STAGE IV ELDER!</div>
            )}
            <div style={{ fontSize: 8, color: '#555', marginTop: 12 }}>Click to continue</div>
          </div>
        )}
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add src/FusionScreen.jsx
git commit -m "feat: fusion screen with parent selection, preview, animation, and result"
```

---

## Task 11: NavBar — Conditional Fusion Tab + App Routing

**Files:**
- Modify: `src/NavBar.jsx`, `src/App.jsx`

- [ ] **Step 1: Update NavBar with conditional FUSION tab**

Read `src/NavBar.jsx`. Replace with:

```jsx
import { loadSave } from './persistence';
import { getStageForLevel } from './battleEngine';
import SoundToggle from './SoundToggle';

export default function NavBar({ activeScreen, onNavigate }) {
  const save = loadSave();

  const ownedDragons = Object.values(save.dragons).filter(d => d.owned);
  const hasEligible = ownedDragons.some(d => d.level >= 10);
  const showFusion = ownedDragons.length >= 2 && hasEligible;

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
          className={`nav-tab ${activeScreen === 'battleSelect' ? 'active' : ''}`}
          onClick={() => onNavigate('battleSelect')}
        >
          BATTLES
        </button>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <div className="nav-scraps">◆ {save.dataScraps}</div>
        <SoundToggle />
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Update App.jsx with fusion screen**

Read `src/App.jsx`. Add import:
```jsx
import FusionScreen from './FusionScreen';
```

Add `FUSION: 'fusion'` to SCREENS object.

In `handleNavigate`, add:
```jsx
    else if (target === 'fusion') {
      playMusic('hatchery');
      setScreen(SCREENS.FUSION);
    }
```

Add fusion screen rendering in the return JSX (after HatcheryScreen):
```jsx
      {screen === SCREENS.FUSION && (
        <FusionScreen onNavigate={handleNavigate} />
      )}
```

- [ ] **Step 3: Verify build**

Run: `npx vite build`
Expected: Clean build.

- [ ] **Step 4: Commit**

```bash
git add src/NavBar.jsx src/App.jsx
git commit -m "feat: conditional FUSION tab in NavBar + App routing"
```

---

## Task 12: BattleSelectScreen — Support fusedBaseStats

**Files:**
- Modify: `src/BattleSelectScreen.jsx`

- [ ] **Step 1: Update stat calculation to use fusedBaseStats**

Read `src/BattleSelectScreen.jsx`. Find the line that calculates stats for owned dragons:
```jsx
            const stats = calculateStatsForLevel(dragon.baseStats, progress.level, progress.shiny);
```

Replace with:
```jsx
            const baseStats = progress.fusedBaseStats || dragon.baseStats;
            const stats = calculateStatsForLevel(baseStats, progress.level, progress.shiny);
```

Also do the same in `BattleScreen.jsx`. Read it and find where `initBattle` calculates stats:
```jsx
  const stats = calculateStatsForLevel(dragon.baseStats, progress.level);
```

Replace with:
```jsx
  const stats = calculateStatsForLevel(progress.fusedBaseStats || dragon.baseStats, progress.level, progress.shiny);
```

- [ ] **Step 2: Verify build**

Run: `npx vite build`
Expected: Clean build.

- [ ] **Step 3: Commit**

```bash
git add src/BattleSelectScreen.jsx src/BattleScreen.jsx
git commit -m "feat: support fusedBaseStats in battle select and battle screen stat calculations"
```

---

## Task 13: Final Verification

**Files:** None (verification only)

- [ ] **Step 1: Run all tests**

Run: `npx vitest run`
Expected: All tests PASS (battle engine + hatchery engine + fusion engine).

- [ ] **Step 2: Run production build**

Run: `npm run build`
Expected: Clean build, no errors.

- [ ] **Step 3: Manual playthrough**

Run: `npm run dev`
Verify:
1. **Status effects:** Fight an NPC. Elemental moves have 30% chance to apply status. Burn/Poison show DOT damage at end of turn. Freeze skips turn. Guard Break makes you take more damage. Blind reduces accuracy. Status indicator shows below HP bar with icon and turns remaining.
2. **Fusion:** Level two dragons to 10+. FUSION tab appears in nav. Select two parents. Preview shows resulting element, stability tier, stats. "Both parents will be consumed" warning. Fuse — animation plays, parents removed, offspring appears with fused stats. Stage IV works when both parents are 25+.
3. **fusedBaseStats:** Fused dragon's enhanced stats show correctly in battle select and combat.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: status effects and fusion chamber complete"
```
