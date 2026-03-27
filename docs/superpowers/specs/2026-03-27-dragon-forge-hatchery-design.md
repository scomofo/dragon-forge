# Dragon Forge: Quantum Incubation (Hatchery) Design Spec

## Overview

The Quantum Incubation system is the gacha/collection mechanic for Dragon Forge. Players spend dataScraps (earned from battles) to pull dragons from an incubator. Features rarity tiers, a pity system, shiny protocol, duplicate merging, and an animated egg-crack reveal sequence.

---

## 1. Navigation & Screen Flow

Current: Title > Battle Select > Battle

New flow adds a nav bar and hatchery screen:

```
Title > Battle Select (with nav bar)
              |
         [HATCHERY]  [BATTLES]
              |            |
        Hatchery Screen   Battle Select (existing)
                                |
                           Battle Screen
```

- Both Hatchery and Battle Select share a top nav bar with **HATCHERY** and **BATTLES** buttons
- Nav bar displays the player's **dataScraps balance** (right-aligned)
- Player can switch freely between screens
- Battle Select and Battle Screen work exactly as they do now, with the nav bar added to Battle Select

---

## 2. Gacha Engine Logic (`hatcheryEngine.js`)

Pure-function module, no React dependencies.

### 2.1 Rarity Tiers

| Rarity | Chance | Elements |
|---|---|---|
| Common | 50% | Fire, Ice |
| Uncommon | 30% | Storm, Venom, Stone |
| Rare | 15% | Shadow |
| Exotic | 5% | Shadow (guaranteed Shiny) |

Within a rarity tier, each element has equal probability (e.g., Uncommon: 1/3 chance each for Storm, Venom, Stone).

### 2.2 Pity System

- Track `pityCounter` (0-9) — increments on each pull that is NOT Rare+
- At `pityCounter === 9` (10th pull), force the next pull to be Rare or Exotic
- Reset `pityCounter` to 0 on any Rare or Exotic pull
- Pity is tracked across 1x and 10x pulls (shared counter)

### 2.3 Shiny Protocol

- 2% flat chance per pull, independent of rarity
- Exotic pulls are always Shiny
- Shiny dragons get +20% to all base stats (multiplicative, applied during stat calculation)
- Shiny is permanent — once a dragon is shiny, it stays shiny
- If a duplicate pull is shiny and the existing dragon is not, upgrade it to shiny

### 2.4 Duplicate Merge

- If player already owns the pulled element: grant bonus XP to the existing dragon
  - XP bonus: `50 * rarityMultiplier` where Common=1, Uncommon=2, Rare=3, Exotic=5
- If player doesn't own the element: add it to roster at level 1

### 2.5 Currency

- 1x pull cost: 50 dataScraps
- 10x pull cost: 500 dataScraps (no discount, pure convenience)
- Battle rewards: Easy 30, Medium 50, Hard 80, Boss 120 dataScraps

---

## 3. Hatchery UI (`HatcheryScreen.jsx`)

### 3.1 Layout

```
┌─────────────────────────────────────────────┐
│  [HATCHERY]  [BATTLES]     ◆ 230 dataScraps │
├─────────────────────────────────────────────┤
│                                              │
│          QUANTUM INCUBATION LAB              │
│                                              │
│              ┌─────────┐                     │
│              │         │                     │
│              │  EGG /  │                     │
│              │ DRAGON  │                     │
│              │         │                     │
│              └─────────┘                     │
│                                              │
│     "Rare+ in 4 pulls" (pity hint)           │
│                                              │
│    [PULL x1 - 50◆]    [PULL x10 - 500◆]     │
│                                              │
└─────────────────────────────────────────────┘
```

### 3.2 Egg Reveal Animation (click-to-skip at any point)

1. **Egg appears** (300ms) — generic dark egg with subtle pulse glow
2. **Egg shakes** (800ms) — increasing intensity CSS animation
3. **Crack + burst** (400ms) — element-colored flash fills the screen
4. **Dragon revealed** — sprite fades in with element name, rarity label, and "NEW!" or "+XP" badge
5. **Shiny bonus** — if shiny, rainbow border pulse and "+20% STATS" callout

Clicking at any point during steps 1-3 skips directly to step 4.

### 3.3 10x Pull Display

- First pull plays the full animation
- Subsequent results auto-advance as cards in a grid (~500ms each)
- Click to skip all remaining and show final grid
- Grid shows all 10 results: dragon sprite, element, rarity, NEW/+XP badge

### 3.4 Button States

- Disabled + grayed when insufficient dataScraps
- Button text shows cost: "PULL x1 — 50◆"
- Pity hint below egg area: "Rare+ guaranteed in X pulls" (hidden when counter is 0)

---

## 4. Persistence Changes (`persistence.js`)

### 4.1 Updated Save Structure

```json
{
  "dragons": {
    "fire": { "level": 1, "xp": 0, "owned": true, "shiny": false },
    "ice": { "level": 1, "xp": 0, "owned": false, "shiny": false },
    "storm": { "level": 1, "xp": 0, "owned": false, "shiny": false },
    "stone": { "level": 1, "xp": 0, "owned": false, "shiny": false },
    "venom": { "level": 1, "xp": 0, "owned": false, "shiny": false },
    "shadow": { "level": 1, "xp": 0, "owned": false, "shiny": false }
  },
  "dataScraps": 0,
  "pityCounter": 0
}
```

### 4.2 New Fields

- `owned` (boolean) — dragons start unowned. Only owned dragons appear in Battle Select.
- `shiny` (boolean) — permanent flag, once true stays true.
- `dataScraps` (integer) — player currency, earned from battles, spent on pulls.
- `pityCounter` (integer, 0-9) — pulls since last Rare+.

### 4.3 Migration

Existing saves without the new fields get defaults applied on load:
- Missing `owned`: set to `true` for any dragon with `level > 1` or `xp > 0`, otherwise `false`
- Missing `shiny`: set to `false`
- Missing `dataScraps`: set to `0`
- Missing `pityCounter`: set to `0`

### 4.4 Starter Dragon

On first game (all dragons unowned), player gets one free pull (no dataScraps cost). This guarantees at least one dragon for battles.

---

## 5. Battle Select Changes

- Only show **owned** dragons in the left panel
- Unowned dragon slots render as locked silhouettes: dark card with "???" name, no stats, no sprite
- If player has no owned dragons (shouldn't happen with starter pull), show a message directing them to the hatchery

---

## 6. Shiny Visual Treatment

### 6.1 DragonSprite Changes

- New `shiny` prop on DragonSprite component
- When `shiny === true`: apply CSS animation `hue-rotate(0deg)` to `hue-rotate(360deg)` over 3 seconds, looping
- Gold sparkle drop-shadow always present (not just Stage IV)

### 6.2 In Battle

- Shiny sprites use the hue-rotate animation during combat
- Stat boost is invisible in UI — just reflected in the numbers

### 6.3 In Selection/Hatchery

- Rainbow border pulse on the dragon card
- Small star icon (★) next to the dragon name

### 6.4 Stat Calculation

- In `calculateStatsForLevel`: if shiny, multiply each stat by 1.2 after level scaling
- Formula: `stat = floor((baseStat + (level - 1) * 3) * (shiny ? 1.2 : 1.0))`

---

## 7. Battle Reward Integration

After a victory in BattleScreen:
- Award dataScraps based on NPC's `baseXP` value (reuse the same field, rename conceptually)
- Display scraps earned on the victory overlay alongside XP: "+25 ◆"
- Update localStorage immediately

NPC reward values (same as baseXP): Easy 25, Medium 40, Hard 60, Boss 80.

Wait — these don't match Section 2.5. Let me align: the battle rewards should be separate from XP. Add a `scrapsReward` field to NPCs:
- Firewall Sentinel: 30
- Bit Wraith: 50
- Glitch Hydra: 80
- Recursive Golem: 120

---

## 8. New Files

| File | Responsibility |
|---|---|
| `src/hatcheryEngine.js` | Pull logic: rarity roll, pity, shiny, duplicate merge |
| `src/hatcheryEngine.test.js` | Tests for all hatchery engine logic |
| `src/HatcheryScreen.jsx` | Hatchery UI: egg animation, pull buttons, results |
| `src/NavBar.jsx` | Shared nav bar: HATCHERY / BATTLES tabs + scraps display |

## Modified Files

| File | Changes |
|---|---|
| `src/App.jsx` | Add hatchery screen, integrate NavBar |
| `src/persistence.js` | Add dataScraps, pityCounter, owned, shiny fields + migration |
| `src/gameData.js` | Add scrapsReward to NPCs, add rarity config |
| `src/battleEngine.js` | No changes |
| `src/BattleScreen.jsx` | Award scraps on victory, show in victory overlay |
| `src/BattleSelectScreen.jsx` | Filter to owned dragons, show locked silhouettes, add NavBar |
| `src/DragonSprite.jsx` | Add shiny prop with hue-rotate animation |
| `src/styles.css` | Add hatchery styles, nav bar, egg animation, shiny effects |

---

## Out of Scope

- Fusion Chamber (next milestone)
- Traveler's Journal / Bestiary
- Void as a separate element
- Pull banners or limited-time pools
- Sound effects
