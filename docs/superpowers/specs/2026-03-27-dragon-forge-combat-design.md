# Dragon Forge: Combat-First Milestone Design Spec

## Overview

A 16-bit cyber-retro dragon breeding and combat simulator. This spec covers the **combat-first milestone**: a playable 1v1 turn-based battle system with 6 elemental player dragons, 3-4 NPC enemies, XP progression, and full visual polish (sprite animations, VFX, floating damage numbers).

**Platform:** Web-only React SPA (Vite + React 18)
**Aesthetic:** High-contrast pixel art, charcoal/navy UI (#111118), CRT scanline effects, 1px black outlines

---

## 1. Project Structure

```
df/
  index.html
  vite.config.js
  package.json
  src/
    App.jsx                 # Root — state-driven screen switching
    BattleScreen.jsx        # Full battle UI
    BattleSelectScreen.jsx  # Dragon + opponent picker
    TitleScreen.jsx         # Felix intro + enter button
    battleEngine.js         # Pure logic — damage, type chart, turns, XP
    gameData.js             # Dragon stats, NPC stats, moves, type chart
    sprites.js              # Sprite sheet configs — frames, dimensions, timing
  assets/
    arenas/                 # magma.png, ice.png, lightning.png, stone.png, venom.png, shadow.png
    dragons/                # 6 elemental dragon sprite sheets (1024x1024, 2x4 grid)
    npc/                    # NPC idle + attack sprites
    vfx/                    # Attack effect sprites
    felix_pixel.jpg         # Professor Felix portrait
  styles.css                # Global — CRT effects, pixelated rendering, UI chrome
```

### Tech Stack

- **React 18** via Vite
- **No state library** — `useReducer` in BattleScreen for battle state
- **No routing library** — simple state-driven screen switching in App.jsx
- **CSS only** — no Tailwind, no styled-components
- **localStorage** for dragon level/XP persistence

---

## 2. Battle Engine (`battleEngine.js`)

A pure-function module with no React dependencies. Takes state in, returns new state out.

### 2.1 Type Effectiveness Chart

Six elements with circular advantage plus Shadow as a defensive outlier:

| Attacker \ Target | Fire | Ice | Storm | Stone | Venom | Shadow |
|---|---|---|---|---|---|---|
| **Fire** | 0.5x | 2x | 1x | 0.5x | 2x | 1x |
| **Ice** | 0.5x | 0.5x | 2x | 1x | 1x | 2x |
| **Storm** | 1x | 0.5x | 0.5x | 2x | 1x | 2x |
| **Stone** | 2x | 1x | 0.5x | 0.5x | 2x | 1x |
| **Venom** | 0.5x | 1x | 1x | 0.5x | 0.5x | 2x |
| **Shadow** | 1x | 0.5x | 0.5x | 1x | 0.5x | 0.5x |

Circular chain: Fire > Ice > Storm > Stone > Venom > Fire. Shadow is weak offensively but resists many types.

### 2.2 Damage Formula

```
baseDamage = (attacker.atk * stageMult * 2) - (target.def * 0.5)
typedDamage = baseDamage * typeEffectiveness
finalDamage = max(1, floor(typedDamage * random(0.85, 1.0)))
```

Stage multipliers: I (0.5x), II (0.75x), III (1.0x), IV (1.4x)

If the target is defending, `finalDamage` is halved.

### 2.3 Turn Resolution

1. Player picks a move
2. NPC picks a move (AI: favor super-effective moves, random otherwise)
3. Speed stat determines who goes first
4. Attacker's move resolves — accuracy check, damage applied, check for KO
5. If target survives, defender's move resolves
6. End of turn — check win/loss, award XP if battle ends

### 2.4 XP & Leveling

- XP gained on win: `baseXP * (enemyLevel / playerLevel)`
- Level up: flat +2-4 per stat per level
- Stage evolution at levels 10 (Stage II), 25 (Stage III), 50 (Stage IV)

---

## 3. Game Data (`gameData.js`)

### 3.1 Player Dragons

| Dragon | Element | HP | ATK | DEF | SPD | Moves |
|---|---|---|---|---|---|---|
| Magma Dragon | Fire | 110 | 28 | 20 | 18 | Magma Breath, Flame Wall |
| Ice Dragon | Ice | 100 | 24 | 26 | 20 | Frost Bite, Blizzard |
| Storm Dragon | Storm | 90 | 30 | 16 | 28 | Lightning Strike, Thunder Clap |
| Stone Dragon | Stone | 120 | 22 | 30 | 12 | Rock Slide, Earthquake |
| Venom Dragon | Venom | 95 | 26 | 18 | 24 | Acid Spit, Toxic Cloud |
| Shadow Dragon | Shadow | 85 | 32 | 14 | 26 | Shadow Strike, Void Pulse |

Design identities: Stone = tank, Storm = glass speedster, Shadow = glass cannon, Magma = balanced bruiser, Ice = balanced defender, Venom = balanced attacker.

### 3.2 NPC Enemies

| NPC | Element | Role | Difficulty |
|---|---|---|---|
| Firewall Sentinel | Stone | Tanky defender, hits slow | Easy |
| Bit Wraith | Shadow | Fast, hits hard, low HP | Medium |
| Glitch Hydra | Storm | Multi-hit, unpredictable | Hard |
| Recursive Golem | Stone | Boss-tier HP/DEF | Boss |

NPC stats scale with difficulty tier. Arena background matches the NPC's element.

### 3.3 Move Structure

```js
{
  name: "Magma Breath",
  element: "fire",
  power: 65,
  accuracy: 95,
  effect: null,       // optional: "burn", "slow", "poison" (future)
  vfxKey: "MAGMA_BREATH"
}
```

Basic Attack: element-neutral, power 40, 100% accuracy.
Defend: sets `defending` flag, halves incoming damage for the turn.

---

## 4. Battle UI & Rendering (`BattleScreen.jsx`)

### 4.1 Layout (Top Bar + Bottom Panel)

```
┌──────────────────────────────────────────────────┐
│ [NPC NAME  ████░░ HP]    VS    [HP ██████ PLAYER] │
├──────────────────────────────────────────────────┤
│                                                    │
│      [NPC Sprite]              [Player Sprite]     │
│        animated                   animated         │
│                                                    │
│              * floating dmg numbers *              │
│              * VFX attack sprites *                │
│                                                    │
├──────────────────────────────────────────────────┤
│   [Move 1]  [Move 2]  [Basic Attack]  [Defend]    │
└──────────────────────────────────────────────────┘
```

### 4.2 Sprite Animation

- Dragon sprite sheets: 2x4 grid (8 frames, 512x256 each). CSS `background-position` cycles at ~150ms/frame for idle.
- NPC sprites: single-frame idle + separate attack image. Swap on attack.
- Player dragons face right, NPCs face left (CSS `scaleX(-1)` if needed).
- Stage scaling: I (0.6x), II (0.8x), III (1.0x), IV (1.4x + gold drop-shadow).

### 4.3 Attack Animation Sequence (5 phases)

1. **INIT** (300ms) — move buttons disable, brief pause
2. **TELEGRAPH** (400ms) — attacker sprite flashes/pulses via CSS animation
3. **IMPACT** — jump to lunge frame (frame 3), VFX sprite plays over target, floating damage number spawns
4. **RECOIL** (200ms) — target shakes via CSS `translateX` jitter, HP bar animates down
5. **RESOLUTION** — return to idle. KO: target fades out. Otherwise: next turn.

### 4.4 Floating Damage Numbers

- Spawn at target position, drift upward with fade-out over ~800ms
- Color-coded: white = normal, red = super-effective ("2x!"), gray = resisted ("0.5x")
- Pure CSS `@keyframes` — no animation library

### 4.5 Move Panel

- Buttons color-coded by move element (fire = orange border, ice = blue, etc.)
- Disabled + grayed out during NPC turn and animation phases
- Hover shows power/accuracy tooltip

---

## 5. Game Flow & Screens

### 5.1 Title Screen (`TitleScreen.jsx`)

- Professor Felix portrait in `.felix-frame` border (4px white, inset shadow)
- Typewriter text: short "Emergency Broadcast" intro (2-3 lines)
- "ENTER THE FORGE" button transitions to battle select
- CRT scanline overlay on the whole screen

### 5.2 Battle Select (`BattleSelectScreen.jsx`)

- **Left panel:** pick your dragon from 6. Shows idle animation, name, element, level, stats.
- **Right panel:** pick NPC opponent from 3-4. Shows sprite, name, element, difficulty.
- **Matchup indicator:** when both selected, shows "SUPER EFFECTIVE" / "RESISTED" / "NEUTRAL"
- "BEGIN BATTLE" button at bottom

### 5.3 Battle Screen (`BattleScreen.jsx`)

Full combat as described in Section 4.

**Win:** XP award screen — XP gained, level up notification, stat increases. "CONTINUE" returns to battle select.
**Loss:** "DEFEATED" screen with Felix encouragement. "TRY AGAIN" returns to battle select.

### 5.4 Persistence

Dragon levels/XP saved to `localStorage`:
```json
{ "dragons": { "fire": { "level": 12, "xp": 340, "stage": 2 } } }
```

---

## 6. Global CSS (`styles.css`)

- Background: `#111118` everywhere
- CRT scanline overlay: `repeating-linear-gradient` with semi-transparent lines over the viewport
- `image-rendering: pixelated` on all sprite and arena elements
- 1px black outlines on UI panels
- Font: "Press Start 2P" (Google Fonts) or system monospace fallback
- `.pixelated`, `.felix-frame`, `.stability-glitch` utility classes from spec

---

## 7. Asset Mapping

### Arenas (matched to NPC element)

| NPC | Arena Key | File |
|---|---|---|
| Firewall Sentinel | ARENA_STONE | stone.png |
| Bit Wraith | ARENA_SHADOW | shadow.png |
| Glitch Hydra | ARENA_STORM | lightning.png |
| Recursive Golem | ARENA_STONE | stone.png |

### Dragon Sprite Sheets

Source files in `handoff/` share names with arena files (e.g., `stone.png`). During asset setup, dragon sheets go into `assets/dragons/` and arenas into `assets/arenas/` to avoid collision.

| Element | Source File | Destination | Grid | Frame Size |
|---|---|---|---|---|
| Fire | handoff/magma.png | assets/dragons/magma.png | 2x4 | 512x256 |
| Ice | handoff/ice.png | assets/dragons/ice.png | 2x4 | 512x256 |
| Storm | handoff/lightning.png | assets/dragons/lightning.png | 2x4 | 512x256 |
| Stone | handoff/stone.png | assets/dragons/stone.png | 2x4 | 512x256 |
| Venom | handoff/venom.png | assets/dragons/venom.png | 2x4 | 512x256 |
| Shadow | handoff/shadow.png | assets/dragons/shadow.png | 2x4 | 512x256 |

### NPC Sprites

| NPC | Idle Sprite | Attack Sprite |
|---|---|---|
| Firewall Sentinel | firewall_sentinel_sprites.png | firewall_sentinel_attack.png |
| Bit Wraith | bit_wraith_sprites.png | bit_wraith_attack.png |
| Glitch Hydra | glitch_hydra_sprites.png | glitch_hydra_attack.png |
| Recursive Golem | recursive_golem_sprites.png | recursive_golem_attack.png |

---

## Out of Scope (Future Milestones)

- Terminal Intro (full typewriter sequence)
- Quantum Incubation (gacha/hatchery)
- Fusion Chamber (breeding/inheritance)
- Traveler's Journal (bestiary)
- Shiny Protocol
- Status effects (burn, poison, slow)
- The Singularity narrative arc
- Sound/music
