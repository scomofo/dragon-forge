# Dragon Forge: Attack VFX Integration Design Spec

## Overview

Integrate attack visual effects into the battle system using existing concept art sheets as impact overlays, combined with CSS-generated travel effects. The goal is dramatic, element-colored attack animations that look great against the dark arena backgrounds.

**Approach:** Hybrid system — CSS travel streaks + concept art impact frames with `mix-blend-mode: screen`.

---

## 1. VFX Animation Phases

Each attack VFX plays across the existing TELEGRAPH → IMPACT → RECOIL flow:

| Phase | Duration | VFX Behavior |
|---|---|---|
| TELEGRAPH (existing) | 400ms | Attacker pulses (unchanged) |
| TRAVEL (new) | 350ms | Element-colored energy streak flies from attacker to target |
| IMPACT (new) | 400ms | Concept art frame flashes over target, screen-blended |
| RECOIL (existing) | 200ms | Target shakes (unchanged) |

Total VFX adds ~750ms to each attack. The TRAVEL phase starts after TELEGRAPH ends. The IMPACT phase overlaps with the existing damage number spawn.

---

## 2. Travel Streak (CSS-only)

A blurred, element-colored gradient blob that animates from attacker position to target position.

### 2.1 Visual

- 80x40px blurred ellipse (`border-radius: 50%`)
- Background: radial gradient using the move's element colors (primary center, glow edge)
- `filter: blur(8px)` for soft glow
- A small trailing tail via `box-shadow` with 20px spread in the trailing direction
- `mix-blend-mode: screen` so it glows against the dark arena

### 2.2 Animation

- CSS `@keyframes` from attacker position to target position
- Player attacks: left-to-right. NPC attacks: right-to-left
- Slight vertical arc (10-15px parabola via multi-step keyframes) for organic feel
- Scale up slightly at midpoint (1.0 → 1.3 → 1.0)
- Opacity: 0 → 1 (first 10%) → 1 (middle) → 0 (last 10%)
- Duration: 350ms, `ease-in-out`

### 2.3 Implementation

This is a `<div>` rendered in the `.arena-sprites` container with `position: absolute`. BattleScreen manages it via state: `{ showTravel: true, travelDirection: 'left-to-right', travelElement: 'fire' }`. Auto-removed after animation completes via `onAnimationEnd`.

---

## 3. Impact Frame (Concept Art Overlays)

### 3.1 Approach

Each attack maps to a single cropped region from one of the concept art sheets. At render time, the full sheet is loaded as a `background-image` and `background-position` + `background-size` crops to the chosen frame. Displayed as a 200x200px overlay centered on the target sprite.

### 3.2 Blending

- `mix-blend-mode: screen` — dark pixels become transparent, bright pixels glow
- For sheets with lighter backgrounds (fire, stone), apply `filter: brightness(0.8) contrast(1.3)` to darken non-effect areas before blending
- `opacity` animates: 0 → 1 (50ms ease-in) → 1 (200ms hold) → 0 (150ms ease-out)
- Slight scale pulse: 0.8 → 1.1 → 1.0 over the 400ms

### 3.3 Asset Mapping

Source images are copied from `~/Downloads/` to `assets/vfx/` with clean filenames.

| Source File (Downloads) | Destination | Content |
|---|---|---|
| `ChatGPT Image Mar 27, 2026, 05_53_12 PM.png` | `assets/vfx/fire_effects.png` | Fire streams, flame walls |
| `ChatGPT Image Mar 27, 2026, 05_58_14 PM.png` | `assets/vfx/stone_explosion.png` | Ground explosions, shockwaves |
| `ChatGPT Image Mar 27, 2026, 06_00_14 PM.png` | `assets/vfx/storm_lightning.png` | Lightning bolts, electric bursts |
| `ChatGPT Image Mar 27, 2026, 06_02_52 PM.png` | `assets/vfx/ice_crystals.png` | Ice shard eruptions, frost |
| `ChatGPT Image Mar 27, 2026, 06_04_48 PM.png` | `assets/vfx/venom_cloud.png` | Poison cloud billows |
| `ChatGPT Image Mar 27, 2026, 06_06_45 PM.png` | `assets/vfx/shadow_flames.png` | Purple void flames, vortex |
| `ChatGPT Image Mar 27, 2026, 06_08_37 PM.png` | `assets/vfx/stone_meteor.png` | Meteor impact, rock debris |
| `ChatGPT Image Mar 27, 2026, 06_13_30 PM.png` | `assets/vfx/venom_splash.png` | Green acid splash |

### 3.4 Frame Crop Definitions

Each vfxKey maps to: source image, crop region (x, y, width, height in source pixels), and optional CSS filter adjustments.

Coordinates reference the top-left corner of the desired frame within the source sheet. All crops are approximate rectangles around the best single effect in each sheet.

| vfxKey | Source File | Crop (x, y, w, h) | Filter Adjust | Description |
|---|---|---|---|---|
| MAGMA_BREATH | `fire_effects.png` | (0, 512, 512, 256) | `brightness(0.8) contrast(1.3)` | Wide horizontal flame stream, row 3 left |
| FLAME_WALL | `fire_effects.png` | (0, 768, 1024, 256) | `brightness(0.8) contrast(1.3)` | Bottom row wide fire spread |
| FROST_BITE | `ice_crystals.png` | (0, 768, 512, 384) | none | Row 3, large spiky crystal eruption |
| BLIZZARD | `ice_crystals.png` | (0, 1152, 1024, 384) | none | Bottom row, massive crystal field |
| LIGHTNING_STRIKE | `storm_lightning.png` | (512, 512, 512, 256) | none | Center bolt striking ground, row 3 |
| THUNDER_CLAP | `storm_lightning.png` | (1024, 0, 512, 256) | none | Shockwave ring, row 1 right |
| ROCK_SLIDE | `stone_meteor.png` | (0, 384, 512, 384) | `brightness(0.7) contrast(1.4)` | Meteor impact with rock debris, row 2 |
| EARTHQUAKE | `stone_explosion.png` | (0, 640, 512, 256) | `brightness(0.7) contrast(1.4)` | Ground-level shockwave + debris, row 3 |
| ACID_SPIT | `venom_splash.png` | (256, 256, 512, 256) | none | Large green splash impact, row 2 |
| TOXIC_CLOUD | `venom_cloud.png` | (384, 256, 512, 384) | none | Center large billowing cloud |
| SHADOW_STRIKE | `shadow_flames.png` | (0, 384, 512, 256) | none | Dark energy slash, row 2 left |
| VOID_PULSE | `shadow_flames.png` | (512, 384, 512, 256) | none | Expanding void vortex, row 2 right |
| BASIC_ATTACK | none | n/a | n/a | CSS-only white slash arc (no sprite) |

**Note:** These crop coordinates are best-effort estimates from visual inspection. They will be fine-tuned during implementation by viewing each crop in the browser and adjusting pixel offsets.

---

## 4. Basic Attack VFX (CSS-only)

Since Basic Attack has no concept art, use a pure CSS effect:

- White arc slash: a thin rotated `<div>` with white-to-transparent gradient
- `clip-path: polygon(...)` for crescent shape
- Animate rotation 0° → 45° with fade-out over 200ms
- Positioned over the target, same timing as other impact frames

---

## 5. Component Architecture

### 5.1 New: `src/VfxOverlay.jsx`

Single component handling both travel streak and impact frame.

**Props:**
- `vfxKey` — which attack effect (e.g., `'MAGMA_BREATH'`)
- `element` — for travel streak color (e.g., `'fire'`)
- `direction` — `'left-to-right'` (player attacks) or `'right-to-left'` (NPC attacks)
- `onComplete` — callback when full VFX sequence finishes

**Behavior:**
1. On mount, renders travel streak and starts travel animation
2. On travel `onAnimationEnd`, hides travel streak, shows impact frame
3. On impact animation end, calls `onComplete`

### 5.2 Update: `src/sprites.js`

Add a `VFX_FRAMES` config object mapping each `vfxKey` to:
```js
{
  src: '/assets/vfx/fire_effects.png',
  crop: { x: 0, y: 512, w: 512, h: 256 },
  filter: 'brightness(0.8) contrast(1.3)',
}
```

### 5.3 Update: `src/BattleScreen.jsx`

- Add `vfxActive` state: `{ vfxKey, element, direction }` or `null`
- In `animateEvent`, after TELEGRAPH and before damage:
  1. Set `vfxActive` with the event's vfxKey and element
  2. `await` a promise that resolves when `VfxOverlay` calls `onComplete`
  3. Clear `vfxActive`
- Render `<VfxOverlay>` in the arena-sprites container when `vfxActive` is set

### 5.4 Update: `src/styles.css`

New CSS classes and keyframes:
- `.vfx-travel` — travel streak base styles + blend mode
- `.vfx-travel-ltr` / `.vfx-travel-rtl` — directional travel keyframes
- `.vfx-impact` — impact overlay base styles + blend mode
- `.vfx-impact-flash` — scale + opacity keyframes
- `.vfx-basic-slash` — CSS-only basic attack arc

---

## 6. File Changes Summary

| File | Action |
|---|---|
| `assets/vfx/*.png` (8 files) | Create — copy from Downloads |
| `src/VfxOverlay.jsx` | Create — new VFX component |
| `src/sprites.js` | Update — add VFX_FRAMES config |
| `src/BattleScreen.jsx` | Update — add vfxActive state, render VfxOverlay, await in animateEvent |
| `src/styles.css` | Update — add VFX keyframes and classes |

---

## 7. Out of Scope

- Multi-frame sprite sheet animation (concept sheets aren't formatted for it)
- VFX for defend action (stays CSS-only pulse)
- Gene Scrambler effect (saved for fusion VFX later)
- Status effect VFX (burn/freeze/etc. already have CSS indicators)
- Sound — attack SFX already exists and plays independently
