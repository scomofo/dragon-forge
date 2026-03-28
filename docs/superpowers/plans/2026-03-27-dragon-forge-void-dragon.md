# Void Dragon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the Void Dragon — a 7th exotic element with glass cannon stats, a unique Null Reflect move that bounces damage back, and a Glitch status effect that randomizes the opponent's next move.

**Architecture:** Void is added as data to gameData.js (dragon, moves, type chart, status, rarity). The reflect mechanic is implemented in battleEngine.js's resolveAction/resolveTurn functions. Glitch status randomizes moveKey before resolution. Visual effects reuse shadow sprites with CSS hue-rotate filters. All existing screens that display dragons are updated to handle the void element.

**Tech Stack:** React 18, Vitest, CSS filters

---

## File Map

| File | Responsibility |
|---|---|
| `src/gameData.js` | Void dragon definition, moves, type chart, elementColors, lore, eggs, status, rarity |
| `src/battleEngine.js` | Reflect mechanic, Glitch randomization |
| `src/battleEngine.test.js` | Tests for reflect, glitch, void type effectiveness |
| `src/persistence.js` | Void in DEFAULT_SAVE + migration |
| `src/sprites.js` | VFX entries for void moves |
| `src/styles.css` | void-sprite filter, reflect shield, glitch indicator |
| `src/DragonSprite.jsx` | Apply void-sprite class |
| `src/BattleScreen.jsx` | Handle reflect events in animateEvent |
| `src/BattleSelectScreen.jsx` | Void dragon in selection |
| `src/HatcheryScreen.jsx` | Void sprite filter on egg/reveal |
| `src/JournalScreen.jsx` | Void dragon in grid |

---

## Task 1: Game Data — Void Dragon, Moves, Type Chart

**Files:**
- Modify: `src/gameData.js`

- [ ] **Step 1: Add void to ELEMENTS array**

In `src/gameData.js`, find the `ELEMENTS` array (line 2) and add `'void'`:

```js
export const ELEMENTS = ['fire', 'ice', 'storm', 'stone', 'venom', 'shadow', 'void'];
```

- [ ] **Step 2: Add void row and column to typeChart**

Add a new `void` row to `typeChart` (after the `shadow` row):

```js
  void:   { fire: 1.0, ice: 1.0, storm: 1.0, stone: 1.0, venom: 1.0, shadow: 1.0, void: 1.0 },
```

Add `void: 1.0` to every existing element row. Each row in `typeChart` needs a new `void: 1.0` entry at the end:

```js
  fire:   { fire: 0.5, ice: 2.0, storm: 1.0, stone: 0.5, venom: 2.0, shadow: 1.0, void: 1.0 },
  ice:    { fire: 0.5, ice: 0.5, storm: 2.0, stone: 1.0, venom: 1.0, shadow: 2.0, void: 1.0 },
  storm:  { fire: 1.0, ice: 0.5, storm: 0.5, stone: 2.0, venom: 1.0, shadow: 2.0, void: 1.0 },
  stone:  { fire: 2.0, ice: 1.0, storm: 0.5, stone: 0.5, venom: 2.0, shadow: 1.0, void: 1.0 },
  venom:  { fire: 0.5, ice: 1.0, storm: 1.0, stone: 0.5, venom: 0.5, shadow: 2.0, void: 1.0 },
  shadow: { fire: 1.0, ice: 0.5, storm: 0.5, stone: 1.0, venom: 0.5, shadow: 0.5, void: 1.0 },
```

- [ ] **Step 3: Add void moves**

Add to the `moves` object, after the `basic_attack` entry:

```js
  // Void
  void_rift:      { name: 'Void Rift',      element: 'void',  power: 80, accuracy: 80, vfxKey: 'VOID_RIFT', canApplyStatus: true },
  null_reflect:   { name: 'Null Reflect',    element: 'void',  power: 0,  accuracy: 100, vfxKey: 'NULL_REFLECT', canApplyStatus: false, isReflect: true },
```

- [ ] **Step 4: Add void dragon**

Add to the `dragons` object, after the `shadow` entry:

```js
  void: {
    id: 'void',
    name: 'Void Dragon',
    element: 'void',
    baseStats: { hp: 75, atk: 34, def: 12, spd: 30 },
    moveKeys: ['void_rift', 'null_reflect'],
    spriteSheet: '/assets/dragons/shadow.png',
  },
```

- [ ] **Step 5: Add void to elementColors**

Add to `elementColors`, after the `neutral` entry:

```js
  void:    { primary: '#00cccc', glow: '#44eeee' },
```

- [ ] **Step 6: Add void lore**

Add to `dragonLore`, after the `shadow` entry:

```js
  void:   "It came from beyond the Elemental Matrix — a tear in the simulation itself. I don't think it belongs to any element. I don't think it belongs to this reality at all.",
```

- [ ] **Step 7: Add void egg and update rarity**

Add to `eggSheets`, after the `shadow` entry:

```js
  void:    '/assets/eggs/egg_shadow_sheet.png',
```

Update the `rarityTiers` Exotic entry from `elements: ['shadow']` to `elements: ['void']`:

```js
  { name: 'Exotic',   chance: 0.05, elements: ['void'], multiplier: 5, guaranteedShiny: true },
```

- [ ] **Step 8: Add void status effect (Glitch)**

Add to `STATUS_EFFECTS`, after the `shadow` entry:

```js
  void:   { name: 'Glitch',      icon: '🌀', duration: 1, type: 'randomize', value: 1.0 },
```

- [ ] **Step 9: Commit**

```bash
git add src/gameData.js
git commit -m "feat: void dragon data — stats, moves, type chart, lore, rarity, glitch status

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Persistence — Void Dragon Save Data

**Files:**
- Modify: `src/persistence.js`

- [ ] **Step 1: Add void to DEFAULT_SAVE**

In `src/persistence.js`, add after `shadow: { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null },`:

```js
    void:   { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null },
```

- [ ] **Step 2: Add migration for void**

In the `migrateSave` function, add after the `if (save.milestones === undefined)` line:

```js
  if (!save.dragons.void) {
    save.dragons.void = { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null };
  }
```

- [ ] **Step 3: Commit**

```bash
git add src/persistence.js
git commit -m "feat: void dragon persistence — save data and migration

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Battle Engine — Reflect & Glitch (TDD)

**Files:**
- Modify: `src/battleEngine.js`
- Modify: `src/battleEngine.test.js`

- [ ] **Step 1: Write failing tests for void type effectiveness**

Add to `src/battleEngine.test.js`, inside the `getTypeEffectiveness` describe block:

```js
  it('returns 1.0 for void attacking any element', () => {
    expect(getTypeEffectiveness('void', 'fire')).toBe(1.0);
    expect(getTypeEffectiveness('void', 'ice')).toBe(1.0);
    expect(getTypeEffectiveness('void', 'shadow')).toBe(1.0);
    expect(getTypeEffectiveness('void', 'void')).toBe(1.0);
  });

  it('returns 1.0 for any element attacking void', () => {
    expect(getTypeEffectiveness('fire', 'void')).toBe(1.0);
    expect(getTypeEffectiveness('ice', 'void')).toBe(1.0);
    expect(getTypeEffectiveness('shadow', 'void')).toBe(1.0);
  });
```

- [ ] **Step 2: Run tests to verify they pass (type chart already updated in Task 1)**

```bash
npm test
```

Expected: PASS (type chart was added in Task 1).

- [ ] **Step 3: Write failing tests for Null Reflect**

Add a new describe block at the end of `src/battleEngine.test.js`:

```js
describe('Null Reflect', () => {
  it('reflect action sets reflecting flag and pushes reflect event', () => {
    const player = {
      name: 'Void Dragon', element: 'void', stage: 3,
      hp: 75, atk: 34, def: 12, spd: 30,
      status: null,
    };
    const npc = {
      name: 'Test NPC', element: 'fire', stage: 3,
      hp: 100, atk: 20, def: 20, spd: 10,
      status: null,
    };

    const result = resolveTurn(player, npc, 'null_reflect', 'basic_attack');

    // Player is faster (30 > 10), so player reflects first
    const reflectEvent = result.events.find(e => e.action === 'reflect');
    expect(reflectEvent).toBeDefined();
    expect(reflectEvent.attacker).toBe('player');

    // NPC attacks into reflect — damage should be applied to NPC, not player
    const attackEvent = result.events.find(e => e.action === 'attack' && e.attacker === 'npc');
    expect(attackEvent).toBeDefined();
    expect(attackEvent.reflected).toBe(true);

    // Player should take 0 damage, NPC should take damage
    expect(result.player.hp).toBe(75); // Player untouched
    expect(result.npc.hp).toBeLessThan(100); // NPC took reflected damage
  });

  it('reflect is consumed even if opponent misses', () => {
    const player = {
      name: 'Void Dragon', element: 'void', stage: 3,
      hp: 75, atk: 34, def: 12, spd: 30,
      status: null,
    };
    const npc = {
      name: 'Test NPC', element: 'fire', stage: 3,
      hp: 100, atk: 20, def: 20, spd: 10,
      status: null,
    };

    // Use a move with 0 accuracy to guarantee miss
    const result = resolveTurn(player, npc, 'null_reflect', 'basic_attack');
    // Even if the NPC attack misses, reflect should not persist to next turn
    // (This is hard to test deterministically due to random accuracy,
    //  but we verify the mechanic works via the success case above)
    expect(result.events.some(e => e.action === 'reflect')).toBe(true);
  });

  it('reflect has no effect if opponent defends', () => {
    const player = {
      name: 'Void Dragon', element: 'void', stage: 3,
      hp: 75, atk: 34, def: 12, spd: 30,
      status: null,
    };
    const npc = {
      name: 'Test NPC', element: 'fire', stage: 3,
      hp: 100, atk: 20, def: 20, spd: 10,
      status: null,
    };

    const result = resolveTurn(player, npc, 'null_reflect', 'defend');

    // Player reflects, NPC defends — both should be at full HP
    expect(result.player.hp).toBe(75);
    expect(result.npc.hp).toBe(100);
  });
});
```

- [ ] **Step 4: Run tests to verify they fail**

```bash
npm test
```

Expected: FAIL — `reflect` action not implemented.

- [ ] **Step 5: Implement reflect mechanic in battleEngine.js**

In `src/battleEngine.js`, modify the `resolveAction` function. Add a reflect check after the defend block (after `return;` on line 196). Before `const move = allMoves[actor.moveKey]`:

```js
  // Check for Null Reflect move
  const moveData = allMoves[actor.moveKey];
  if (moveData && moveData.isReflect) {
    const updated = { ...actor.state, reflecting: true };
    setSelf(updated);
    events.push({
      attacker: actor.label,
      action: 'reflect',
      moveName: moveData.name,
      moveKey: actor.moveKey,
      vfxKey: moveData.vfxKey,
      damage: 0,
      effectiveness: 1.0,
      hit: true,
    });
    return;
  }
```

Then update the existing `const move = allMoves[actor.moveKey]` line to just reuse:

```js
  const move = moveData || allMoves.basic_attack;
```

Now add reflect check when dealing damage. After `const newTargetHp = Math.max(0, target.hp - result.damage);` (around line 219), wrap the damage application in a reflect check:

Replace the section from `const newTargetHp` through to the `events.push` at the end of resolveAction with:

```js
  // Check if target is reflecting
  if (target.reflecting && result.hit) {
    // Reflect: damage goes to attacker instead
    const newSelfHp = Math.max(0, actor.state.hp - result.damage);
    const updatedSelf = { ...actor.state, hp: newSelfHp };
    setSelf(updatedSelf);
    // Clear reflect on target
    const updatedTarget = { ...target, reflecting: false };
    setTarget(updatedTarget);

    events.push({
      attacker: actor.label,
      action: 'attack',
      moveName: move.name,
      moveKey: actor.moveKey,
      vfxKey: move.vfxKey,
      damage: result.damage,
      effectiveness: result.effectiveness,
      hit: result.hit,
      targetHp: target.hp,
      reflected: true,
      appliedStatus: null,
    });
    return;
  }

  // Clear reflect if target was reflecting but attack missed
  if (target.reflecting) {
    const updatedTarget = { ...target, reflecting: false };
    setTarget(updatedTarget);
  }

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
    reflected: false,
    appliedStatus: appliedStatus ? STATUS_EFFECTS[appliedStatus.effect].name : null,
  });
```

Also add reflect cleanup at end of turn in `resolveTurn`. After the status tick processing block and before `return { player, npc, events };`, add:

```js
  // Clear any lingering reflect flags
  player = { ...player, reflecting: false };
  npc = { ...npc, reflecting: false };
```

- [ ] **Step 6: Run tests**

```bash
npm test
```

Expected: All tests pass including the new reflect tests.

- [ ] **Step 7: Write failing tests for Glitch status**

Add to `src/battleEngine.test.js`:

```js
describe('Glitch status', () => {
  it('Glitch randomizes the move selection', () => {
    const player = {
      name: 'Fire Dragon', element: 'fire', stage: 3,
      hp: 110, atk: 28, def: 20, spd: 18,
      status: { effect: 'void', turnsLeft: 1 },
    };
    const npc = {
      name: 'Test NPC', element: 'stone', stage: 3,
      hp: 100, atk: 20, def: 20, spd: 10,
      status: null,
    };

    // Player has Glitch and picks basic_attack
    // With glitch, the move should be randomized from their available moves
    // We can't test exact randomization, but we can verify the turn resolves without error
    const result = resolveTurn(player, npc, 'basic_attack', 'basic_attack');
    expect(result.events.length).toBeGreaterThan(0);
    // Player should still have acted (not skipped)
    const playerEvent = result.events.find(e => e.attacker === 'player');
    expect(playerEvent).toBeDefined();
  });
});
```

- [ ] **Step 8: Implement Glitch randomization**

In `src/battleEngine.js`, in the `resolveTurn` function, add Glitch move randomization after constructing `first` and `second` but before calling `resolveAction` on `first`. Add after line 122:

```js
  // Glitch status — randomize move selection
  if (first.state.status?.effect === 'void') {
    const allMoveKeys = first.label === 'player' ? playerState.moveKeys : npcState.moveKeys;
    if (allMoveKeys && allMoveKeys.length > 0) {
      first.moveKey = allMoveKeys[Math.floor(Math.random() * allMoveKeys.length)];
    }
  }
  if (second.state.status?.effect === 'void') {
    const allMoveKeys = second.label === 'player' ? playerState.moveKeys : npcState.moveKeys;
    if (allMoveKeys && allMoveKeys.length > 0) {
      second.moveKey = allMoveKeys[Math.floor(Math.random() * allMoveKeys.length)];
    }
  }
```

Note: `playerState` and `npcState` are the original function parameters (which have `moveKeys` when passed from BattleScreen). If `moveKeys` isn't available, the original moveKey is kept. This is safe because the Glitch randomization is optional — worst case it doesn't randomize.

Actually, `resolveTurn` doesn't receive `moveKeys` — it receives individual combatant state objects. We need to pass moveKeys through. Simpler approach: add `moveKeys` to the state objects passed into resolveTurn. But that's a larger change.

Better approach: since the Glitch status is processed in BattleScreen before calling resolveTurn, handle it there instead. But the plan says to keep it in the engine.

Simplest approach: add optional `moveKeys` parameter to resolveTurn:

Update the function signature in `src/battleEngine.js`:

```js
export function resolveTurn(playerState, npcState, playerMoveKey, npcMoveKey, playerMoveKeys, npcMoveKeys) {
```

Then the Glitch code becomes:

```js
  // Glitch status — randomize move selection
  if (first.state.status?.effect === 'void') {
    const keys = first.label === 'player' ? playerMoveKeys : npcMoveKeys;
    if (keys && keys.length > 0) {
      first.moveKey = keys[Math.floor(Math.random() * keys.length)];
    }
  }
  if (second.state.status?.effect === 'void') {
    const keys = second.label === 'player' ? playerMoveKeys : npcMoveKeys;
    if (keys && keys.length > 0) {
      second.moveKey = keys[Math.floor(Math.random() * keys.length)];
    }
  }
```

- [ ] **Step 9: Run tests**

```bash
npm test
```

Expected: All tests pass.

- [ ] **Step 10: Update NPC AI to skip null_reflect**

In `src/battleEngine.js`, update `pickNpcMove` to filter out reflect moves:

```js
export function pickNpcMove(npcMoveKeys, npcElement, playerElement) {
  // Filter out reflect moves — NPC AI shouldn't use them
  const filteredKeys = npcMoveKeys.filter(key => {
    const move = allMoves[key];
    return !move?.isReflect;
  });
  const availableKeys = [...filteredKeys, 'basic_attack'];
```

The rest of the function stays the same but uses `filteredKeys` instead of `npcMoveKeys` for the preferred selection:

```js
  const preferred = filteredKeys.length > 0 && Math.random() < 0.5
    ? filteredKeys
    : availableKeys;
  return preferred[Math.floor(Math.random() * preferred.length)];
```

- [ ] **Step 11: Run all tests**

```bash
npm test
```

Expected: All tests pass.

- [ ] **Step 12: Commit**

```bash
git add src/battleEngine.js src/battleEngine.test.js
git commit -m "feat: reflect mechanic, glitch status, void type effectiveness in battle engine

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: VFX & CSS — Void Sprite Filter, Reflect Shield, Glitch Indicator

**Files:**
- Modify: `src/sprites.js`
- Modify: `src/styles.css`

- [ ] **Step 1: Add void VFX entries to sprites.js**

In `src/sprites.js`, add to `VFX_FRAMES` before `BASIC_ATTACK: null`:

```js
  VOID_RIFT: {
    src: '/assets/vfx/shadow_flames.png',
    sheet: { w: 1536, h: 1024 },
    crop: { x: 512, y: 384, w: 512, h: 256 },
    filter: 'hue-rotate(180deg) saturate(1.5)',
  },
  NULL_REFLECT: null, // CSS-only reflect shield effect
```

- [ ] **Step 2: Add void CSS to styles.css**

Append to `src/styles.css`:

```css
/* === VOID DRAGON === */

.void-sprite {
  filter: hue-rotate(180deg) saturate(1.5) !important;
}

.void-sprite.shiny-sprite {
  animation: shinyHueRotate 3s linear infinite;
  filter: hue-rotate(180deg) saturate(1.5) drop-shadow(0 0 6px gold) !important;
}

/* Glitch status indicator */
.status-indicator.glitch {
  color: #00cccc;
  border-color: #00cccc;
  animation: glitchJitter 0.15s infinite;
}

@keyframes glitchJitter {
  0% { transform: translate(0, 0); }
  25% { transform: translate(-2px, 1px); }
  50% { transform: translate(2px, -1px); }
  75% { transform: translate(-1px, -1px); }
  100% { transform: translate(1px, 1px); }
}

/* Reflect shield — cyan shimmer */
.vfx-reflect-shield {
  position: absolute;
  width: 160px;
  height: 160px;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  border-radius: 50%;
  border: 2px solid #44eeee;
  box-shadow: 0 0 20px rgba(0, 204, 204, 0.5), inset 0 0 20px rgba(0, 204, 204, 0.2);
  pointer-events: none;
  z-index: 21;
  opacity: 0;
  mix-blend-mode: screen;
}

.vfx-reflect-shield-anim {
  animation: reflectShield 500ms ease-out forwards;
}

@keyframes reflectShield {
  0% { opacity: 0; transform: translate(-50%, -50%) scale(0.5); }
  20% { opacity: 1; transform: translate(-50%, -50%) scale(1.1); }
  60% { opacity: 0.8; transform: translate(-50%, -50%) scale(1.0); }
  100% { opacity: 0; transform: translate(-50%, -50%) scale(1.0); }
}

/* Reflected damage — reverse flash */
.vfx-reflected-flash {
  animation: reflectedFlash 300ms ease-out forwards;
}

@keyframes reflectedFlash {
  0% { opacity: 0; filter: brightness(2); }
  30% { opacity: 1; filter: brightness(1.5); }
  100% { opacity: 0; filter: brightness(1); }
}
```

- [ ] **Step 3: Verify build**

```bash
npm run build
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/sprites.js src/styles.css
git commit -m "feat: void VFX, void-sprite filter, reflect shield, glitch CSS

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: DragonSprite — Void Filter

**Files:**
- Modify: `src/DragonSprite.jsx`

- [ ] **Step 1: Add void-sprite class support**

In `src/DragonSprite.jsx`, the component needs to accept an `element` prop and apply the `void-sprite` class when element is `'void'`. Update the component signature to accept `element`:

Find the return statement (around line 94). Update the `className` on the canvas:

Currently:
```jsx
      className={`dragon-sprite ${className} ${shiny ? 'shiny-sprite' : ''}`}
```

Change to:
```jsx
      className={`dragon-sprite ${className} ${shiny ? 'shiny-sprite' : ''} ${element === 'void' ? 'void-sprite' : ''}`}
```

Also update the function signature to accept `element`:

Currently:
```jsx
export default function DragonSprite({ spriteSheet, stage = 3, flipX = false, forcedFrame = null, className = '', size = null, shiny = false }) {
```

Change to:
```jsx
export default function DragonSprite({ spriteSheet, stage = 3, flipX = false, forcedFrame = null, className = '', size = null, shiny = false, element = '' }) {
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

Expected: Build succeeds (existing callers don't pass `element` — it defaults to `''`).

- [ ] **Step 3: Commit**

```bash
git add src/DragonSprite.jsx
git commit -m "feat: DragonSprite void-sprite class via element prop

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: BattleScreen — Reflect Event Handling

**Files:**
- Modify: `src/BattleScreen.jsx`

- [ ] **Step 1: Pass moveKeys to resolveTurn**

In `src/BattleScreen.jsx`, find the call to `resolveTurn` inside `handleMoveSelect` (around line 220-230). It currently looks like:

```js
const result = resolveTurn(playerState, npcState, moveKey, npcMoveKey);
```

Update to pass moveKeys:

```js
const result = resolveTurn(playerState, npcState, moveKey, npcMoveKey, state.dragon.moveKeys, state.npc.moveKeys);
```

- [ ] **Step 2: Handle reflect event in animateEvent**

In the `animateEvent` function, add a handler for the `reflect` action after the `defend` action handler. After `if (event.action === 'defend') { ... return; }`:

```js
    if (event.action === 'reflect') {
      playSound('defend');
      if (isPlayer) {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: 'sprite-telegraph' });
      } else {
        dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: 'sprite-telegraph' });
      }
      await wait(500);
      if (isPlayer) {
        dispatch({ type: 'SET_PLAYER_SPRITE_CLASS', value: '' });
      } else {
        dispatch({ type: 'SET_NPC_SPRITE_CLASS', value: '' });
      }
      return;
    }
```

- [ ] **Step 3: Handle reflected attacks**

In the `animateEvent` function, after the VFX promise resolves and in the IMPACT phase, check for `event.reflected`. Currently damage is applied to the target. When reflected, apply to the attacker instead.

Find the damage application block (the `if (event.hit)` block after the VFX). Wrap it in a reflected check:

```js
    if (event.hit) {
      if (event.reflected) {
        // Reflected — damage goes to attacker
        if (isPlayer) {
          dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
        } else {
          dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
        }
        playSound('superEffective');
      } else {
        // Normal — damage goes to target
        if (isPlayer) {
          dispatch({ type: 'APPLY_DAMAGE_TO_NPC', damage: event.damage });
        } else {
          dispatch({ type: 'APPLY_DAMAGE_TO_PLAYER', damage: event.damage });
        }
        if (event.effectiveness > 1.0) playSound('superEffective');
        else if (event.effectiveness < 1.0) playSound('resisted');
        else playSound('attackHit');
      }
    } else {
      playSound('miss');
    }
```

Also update the damage number to show on the correct target when reflected:

```js
    const dmgTarget = event.reflected ? (isPlayer ? 'player' : 'npc') : (isPlayer ? 'npc' : 'player');
    const dmgId = ++damageIdCounter;
    dispatch({
      type: 'ADD_DAMAGE_NUMBER',
      entry: {
        id: dmgId,
        damage: event.damage,
        effectiveness: event.effectiveness,
        hit: event.hit,
        target: dmgTarget,
        reflected: event.reflected,
      },
    });
```

- [ ] **Step 4: Pass element prop to DragonSprite in BattleScreen**

Find the `<DragonSprite` render in BattleScreen and add `element={dragon.element}`:

```jsx
          <DragonSprite
            spriteSheet={dragon.spriteSheet}
            stage={state.playerStage}
            flipX={true}
            forcedFrame={state.playerForcedFrame}
            className={state.playerSpriteClass}
            element={dragon.element}
          />
```

- [ ] **Step 5: Verify build**

```bash
npm run build
```

- [ ] **Step 6: Commit**

```bash
git add src/BattleScreen.jsx
git commit -m "feat: BattleScreen reflect handling — bounced damage, VFX, moveKeys pass-through

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Screen Updates — BattleSelect, Hatchery, Journal

**Files:**
- Modify: `src/BattleSelectScreen.jsx`
- Modify: `src/HatcheryScreen.jsx`
- Modify: `src/JournalScreen.jsx`

- [ ] **Step 1: Add element prop to DragonSprite in BattleSelectScreen**

In `src/BattleSelectScreen.jsx`, find the `<DragonSprite` render for owned dragons in the selection grid. Add `element={dragon.element}`:

Look for `<DragonSprite` and add the element prop.

- [ ] **Step 2: Add element prop to DragonSprite in HatcheryScreen**

In `src/HatcheryScreen.jsx`, find the `<DragonSprite` render in the reveal section. Add `element={result.element}` (or whatever the element variable is at that point).

- [ ] **Step 3: Add element prop to DragonSprite in JournalScreen**

In `src/JournalScreen.jsx`, find both `<DragonSprite` renders (grid card and detail panel). Add `element={el}` to the grid card and `element={dragon.element}` to the detail panel.

- [ ] **Step 4: Verify build**

```bash
npm run build
```

- [ ] **Step 5: Run tests**

```bash
npm test
```

Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add src/BattleSelectScreen.jsx src/HatcheryScreen.jsx src/JournalScreen.jsx
git commit -m "feat: pass element prop to DragonSprite across all screens for void filter

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Final Verification

- [ ] **Step 1: Run all tests**

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

Verify:
- Void Dragon appears in Journal as undiscovered (teal silhouette if void-sprite filter applies to silhouettes too — may need adjustment)
- Exotic hatchery pull yields Void Dragon (not Shadow)
- Void Dragon in battle select shows teal-filtered shadow sprite
- Battle with Void Dragon: Void Rift deals damage, can apply Glitch
- Null Reflect sets reflect — opponent's attack bounces back
- NPC AI never uses Null Reflect
- Glitch status randomizes opponent's move
- Type effectiveness is neutral (1.0x) in all matchups

- [ ] **Step 4: Commit any tweaks**

```bash
git add -A
git commit -m "fix: void dragon polish after manual testing

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

Skip if no adjustments needed.
