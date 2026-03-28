# Dragon Forge: Void Dragon Design Spec

## Overview

Add the Void Dragon — a 7th exotic element unlockable only through the Exotic rarity tier (5% hatchery chance). Glass cannon with the highest ATK in the game, a unique Null Reflect move that bounces damage back at attackers, and a Glitch status effect that randomizes the opponent's next move. Reuses shadow dragon/egg sprites with CSS hue-rotate filters.

---

## 1. Void Dragon Stats & Moves

### 1.1 Stats

| Dragon | Element | HP | ATK | DEF | SPD |
|---|---|---|---|---|---|
| Void Dragon | void | 75 | 34 | 12 | 30 |

Design identity: ultimate glass cannon. Highest ATK (34), tied second-fastest (30), lowest HP (75) and DEF (12) in the game.

### 1.2 Moves

| Move Key | Name | Element | Power | Accuracy | vfxKey | canApplyStatus | Notes |
|---|---|---|---|---|---|---|---|
| `void_rift` | Void Rift | void | 80 | 80% | `VOID_RIFT` | true | High damage, can apply Glitch |
| `null_reflect` | Null Reflect | void | 0 | 100% | `NULL_REFLECT` | false | Sets 1-turn reflect state |

### 1.3 Sprite

No dedicated void sprite sheet. Reuse `/assets/dragons/shadow.png` with CSS class `void-sprite` applying `filter: hue-rotate(180deg) saturate(1.5)` — turns purple shadow into teal/cyan void.

### 1.4 Lore

"It came from beyond the Elemental Matrix — a tear in the simulation itself. I don't think it belongs to any element. I don't think it belongs to this reality at all."

---

## 2. Type Effectiveness

Void is neutral (1.0x) against all elements. All elements are neutral (1.0x) against Void. No weaknesses, no resistances.

Add `void` row and column to `typeChart`:

```
void: { fire: 1.0, ice: 1.0, storm: 1.0, stone: 1.0, venom: 1.0, shadow: 1.0, void: 1.0 }
```

Add `void: 1.0` to every existing element's row.

Add `'void'` to the `ELEMENTS` array.

---

## 3. Status Effect — Glitch

| Effect | Element | Duration | Behavior |
|---|---|---|---|
| Glitch | void | 1 turn | Target's next action uses a random move from their moveset |

- 30% chance on Void Rift (standard `canApplyStatus: true` path)
- Only one status at a time (existing rule — Glitch replaces any current status)
- When a combatant with Glitch selects a move: their `moveKey` is replaced with a random key from their `moveKeys` array before resolution. The Glitch is consumed on use (not on end-of-turn tick).
- Icon: `🌀`

Add to `STATUS_EFFECTS`:
```js
void: { name: 'Glitch', icon: '🌀', duration: 1, type: 'randomize', value: 1.0 }
```

---

## 4. Null Reflect Mechanic

### 4.1 Setting Reflect

When a dragon uses Null Reflect:
- No damage calculation, no accuracy check
- Set `reflecting: true` on the user
- Push event: `{ attacker, action: 'reflect', moveName: 'Null Reflect', moveKey: 'null_reflect', vfxKey: 'NULL_REFLECT' }`

### 4.2 Attacking a Reflecting Target

When resolving an attack against a target with `reflecting: true`:
- If attack hits: apply the calculated damage to the **attacker** (not the target). The target takes 0 damage.
- If attack misses: no damage to anyone.
- In both cases: set `reflecting: false` on the target.
- Push `reflected: true` on the attack event so BattleScreen knows to animate it differently.

### 4.3 Reflect Cleanup

At the end of each turn (after both combatants act), clear `reflecting: false` on both combatants. This handles the case where the opponent defended instead of attacking.

### 4.4 NPC AI

NPCs never select `null_reflect`. If an NPC has void moves, the AI only considers `void_rift`. This avoids NPCs making poor reflect decisions.

---

## 5. Hatchery Integration

### 5.1 Rarity Tier Change

Update the Exotic tier from `elements: ['shadow']` to `elements: ['void']`:

```js
{ name: 'Exotic', chance: 0.05, elements: ['void'], multiplier: 5, guaranteedShiny: true }
```

### 5.2 Egg Sprite

Reuse shadow egg sheets with the `void-sprite` CSS filter. Add to `eggSheets`:

```js
void: '/assets/eggs/egg_shadow_sheet.png',
```

The hue-rotate filter is applied at render time via the element class, not baked into the image.

---

## 6. Element Colors & UI

```js
void: { primary: '#00cccc', glow: '#44eeee' }
```

Teal/cyan to visually distinguish from shadow's purple.

---

## 7. Arena

Void battles use the shadow arena with an inverted filter:

```js
arena: '/assets/arenas/shadow.jpg',
arenaFilter: 'grayscale(1) invert(1)',
```

The `arenaFilter` is a new optional field on NPC data. If present, BattleScreen applies it to the arena background element. Since Void dragons fight in the player slot (not NPC slot), this only matters if a future NPC uses void. For now, use the shadow arena unfiltered when a player void dragon fights an NPC — the NPC's arena is used, not the player's.

Actually, simpler: no arena change needed. The NPC determines the arena, not the player. Void dragons fight in whatever arena the NPC uses. No change required.

---

## 8. VFX

- `VOID_RIFT`: Reuse `VOID_PULSE` VFX config from sprites.js (same shadow flame source, similar visual)
- `NULL_REFLECT`: CSS-only effect — a brief cyan shield shimmer on the user (no concept art sprite needed). New CSS class `.vfx-reflect-shield` with a border glow + scale pulse.

---

## 9. Persistence

Add `void` to `DEFAULT_SAVE.dragons`:

```js
void: { level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null }
```

Add migration for existing saves missing the void key.

---

## 10. BattleScreen — Reflect Animation

When a `reflected: true` event is received:
- Play the attack VFX traveling toward the target as normal
- At impact, flash a cyan shield on the target
- Then play a reverse VFX (or damage numbers) on the attacker
- Show "REFLECTED!" text instead of damage number on the target

When a `reflect` action event is received (dragon using Null Reflect):
- Show the cyan shield shimmer on the user
- Play a sound effect (reuse `defend` sound)

---

## 11. File Changes

| File | Changes |
|---|---|
| `src/gameData.js` | Void dragon, void moves, typeChart void row/column, ELEMENTS, elementColors, dragonLore, eggSheets, STATUS_EFFECTS, rarityTiers |
| `src/battleEngine.js` | Reflect mechanic (set/check/clear), Glitch randomization, void type chart |
| `src/battleEngine.test.js` | Tests for reflect, glitch, void type effectiveness |
| `src/persistence.js` | Void in DEFAULT_SAVE, migration |
| `src/sprites.js` | VOID_RIFT and NULL_REFLECT VFX entries |
| `src/styles.css` | `.void-sprite` filter, `.vfx-reflect-shield`, glitch status indicator |
| `src/DragonSprite.jsx` | Apply void-sprite class when element is void |
| `src/BattleScreen.jsx` | Handle reflect/reflected events in animateEvent |
| `src/BattleSelectScreen.jsx` | Void dragon appears in selection when owned |
| `src/HatcheryScreen.jsx` | Apply void-sprite filter to void egg/reveal |
| `src/JournalScreen.jsx` | Void dragon in grid (no milestone change — stays 6) |

---

## 12. Out of Scope

- Void-specific NPC enemy (future milestone)
- Void arena as a selectable location
- Fusion involving void element (existing fusion works, void just follows normal rules)
- Void-specific egg art (reuse shadow with filter)
- Void-specific dragon sprite (reuse shadow with filter)
