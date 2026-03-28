# Dragon Forge: Attack VFX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add sprite-based attack visual effects (concept art impact overlays + CSS travel streaks) to the battle system, wired into the existing TELEGRAPH → IMPACT → RECOIL animation flow.

**Architecture:** A new `VfxOverlay` React component renders during attacks — first a CSS-animated travel streak (element-colored glow blob), then a concept art frame cropped from source sheets and screen-blended over the target. VFX config lives in `sprites.js`. BattleScreen orchestrates via a `vfxActive` state field that triggers VfxOverlay and awaits its completion callback.

**Tech Stack:** React 18, CSS @keyframes, mix-blend-mode: screen

---

## File Map

| File | Responsibility |
|---|---|
| `assets/vfx/*.png` (8 files) | Concept art sheets copied from Downloads |
| `src/sprites.js` | VFX_FRAMES config — maps each vfxKey to source image, crop rect, optional filter |
| `src/VfxOverlay.jsx` | New component: renders travel streak + impact frame with blend modes |
| `src/BattleScreen.jsx` | Wire VfxOverlay into animateEvent, manage vfxActive state |
| `src/styles.css` | VFX keyframes and classes — travel, impact, basic slash |

---

## Task 1: Copy VFX Assets

**Files:**
- Create: `assets/vfx/fire_effects.png`
- Create: `assets/vfx/stone_explosion.png`
- Create: `assets/vfx/storm_lightning.png`
- Create: `assets/vfx/ice_crystals.png`
- Create: `assets/vfx/venom_cloud.png`
- Create: `assets/vfx/shadow_flames.png`
- Create: `assets/vfx/stone_meteor.png`
- Create: `assets/vfx/venom_splash.png`

- [ ] **Step 1: Create assets/vfx directory and copy files**

```bash
mkdir -p assets/vfx
cp "/c/Users/Scott Morley/Downloads/ChatGPT Image Mar 27, 2026, 05_53_12 PM.png" assets/vfx/fire_effects.png
cp "/c/Users/Scott Morley/Downloads/ChatGPT Image Mar 27, 2026, 05_58_14 PM.png" assets/vfx/stone_explosion.png
cp "/c/Users/Scott Morley/Downloads/ChatGPT Image Mar 27, 2026, 06_00_14 PM.png" assets/vfx/storm_lightning.png
cp "/c/Users/Scott Morley/Downloads/ChatGPT Image Mar 27, 2026, 06_02_52 PM.png" assets/vfx/ice_crystals.png
cp "/c/Users/Scott Morley/Downloads/ChatGPT Image Mar 27, 2026, 06_04_48 PM.png" assets/vfx/venom_cloud.png
cp "/c/Users/Scott Morley/Downloads/ChatGPT Image Mar 27, 2026, 06_06_45 PM.png" assets/vfx/shadow_flames.png
cp "/c/Users/Scott Morley/Downloads/ChatGPT Image Mar 27, 2026, 06_08_37 PM.png" assets/vfx/stone_meteor.png
cp "/c/Users/Scott Morley/Downloads/ChatGPT Image Mar 27, 2026, 06_13_30 PM.png" assets/vfx/venom_splash.png
```

- [ ] **Step 2: Verify all 8 files are in place**

```bash
ls -la assets/vfx/
```

Expected: 8 PNG files listed.

- [ ] **Step 3: Commit**

```bash
git add assets/vfx/
git commit -m "feat: add VFX concept art sheets to assets/vfx"
```

---

## Task 2: VFX Frame Config in sprites.js

**Files:**
- Modify: `src/sprites.js`

- [ ] **Step 1: Add VFX_FRAMES config to sprites.js**

Add the following after the existing `DRAGON_DISPLAY` export at the bottom of `src/sprites.js`:

```js
// === VFX IMPACT FRAMES ===
// Each vfxKey maps to a source image and crop region for the impact overlay.
// Crop coordinates (x, y, w, h) define the rectangle in the source sheet.
// The crop is displayed at 200x200px on screen with mix-blend-mode: screen.
export const VFX_FRAMES = {
  MAGMA_BREATH: {
    src: '/assets/vfx/fire_effects.png',
    crop: { x: 0, y: 512, w: 512, h: 256 },
    filter: 'brightness(0.8) contrast(1.3)',
  },
  FLAME_WALL: {
    src: '/assets/vfx/fire_effects.png',
    crop: { x: 0, y: 768, w: 1024, h: 256 },
    filter: 'brightness(0.8) contrast(1.3)',
  },
  FROST_BITE: {
    src: '/assets/vfx/ice_crystals.png',
    crop: { x: 0, y: 768, w: 512, h: 384 },
    filter: null,
  },
  BLIZZARD: {
    src: '/assets/vfx/ice_crystals.png',
    crop: { x: 0, y: 1152, w: 1024, h: 384 },
    filter: null,
  },
  LIGHTNING_STRIKE: {
    src: '/assets/vfx/storm_lightning.png',
    crop: { x: 512, y: 512, w: 512, h: 256 },
    filter: null,
  },
  THUNDER_CLAP: {
    src: '/assets/vfx/storm_lightning.png',
    crop: { x: 1024, y: 0, w: 512, h: 256 },
    filter: null,
  },
  ROCK_SLIDE: {
    src: '/assets/vfx/stone_meteor.png',
    crop: { x: 0, y: 384, w: 512, h: 384 },
    filter: 'brightness(0.7) contrast(1.4)',
  },
  EARTHQUAKE: {
    src: '/assets/vfx/stone_explosion.png',
    crop: { x: 0, y: 640, w: 512, h: 256 },
    filter: 'brightness(0.7) contrast(1.4)',
  },
  ACID_SPIT: {
    src: '/assets/vfx/venom_splash.png',
    crop: { x: 256, y: 256, w: 512, h: 256 },
    filter: null,
  },
  TOXIC_CLOUD: {
    src: '/assets/vfx/venom_cloud.png',
    crop: { x: 384, y: 256, w: 512, h: 384 },
    filter: null,
  },
  SHADOW_STRIKE: {
    src: '/assets/vfx/shadow_flames.png',
    crop: { x: 0, y: 384, w: 512, h: 256 },
    filter: null,
  },
  VOID_PULSE: {
    src: '/assets/vfx/shadow_flames.png',
    crop: { x: 512, y: 384, w: 512, h: 256 },
    filter: null,
  },
  BASIC_ATTACK: null, // CSS-only, no sprite
};
```

- [ ] **Step 2: Commit**

```bash
git add src/sprites.js
git commit -m "feat: VFX_FRAMES config — crop regions for 13 attack effects"
```

---

## Task 3: VFX CSS — Travel Streak, Impact Flash, Basic Slash

**Files:**
- Modify: `src/styles.css`

- [ ] **Step 1: Add VFX CSS to styles.css**

Add the following at the end of `src/styles.css`, before the final closing comment (if any):

```css
/* === VFX ATTACK EFFECTS === */

/* Travel streak — element-colored glow blob that flies across the arena */
.vfx-travel {
  position: absolute;
  width: 80px;
  height: 40px;
  border-radius: 50%;
  filter: blur(8px);
  mix-blend-mode: screen;
  pointer-events: none;
  z-index: 20;
  top: 50%;
  transform: translateY(-50%);
  opacity: 0;
}

.vfx-travel-ltr {
  animation: vfxTravelLTR 350ms ease-in-out forwards;
}

.vfx-travel-rtl {
  animation: vfxTravelRTL 350ms ease-in-out forwards;
}

@keyframes vfxTravelLTR {
  0%   { left: 10%; opacity: 0; transform: translateY(-50%) scale(1.0); }
  10%  { opacity: 1; }
  50%  { transform: translateY(calc(-50% - 15px)) scale(1.3); }
  90%  { opacity: 1; }
  100% { left: 80%; opacity: 0; transform: translateY(-50%) scale(1.0); }
}

@keyframes vfxTravelRTL {
  0%   { left: 80%; opacity: 0; transform: translateY(-50%) scale(1.0); }
  10%  { opacity: 1; }
  50%  { transform: translateY(calc(-50% - 15px)) scale(1.3); }
  90%  { opacity: 1; }
  100% { left: 10%; opacity: 0; transform: translateY(-50%) scale(1.0); }
}

/* Impact frame — concept art overlay, screen-blended */
.vfx-impact {
  position: absolute;
  width: 200px;
  height: 200px;
  mix-blend-mode: screen;
  pointer-events: none;
  z-index: 21;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%) scale(0.8);
  opacity: 0;
  background-repeat: no-repeat;
  image-rendering: auto;
}

.vfx-impact-flash {
  animation: vfxImpactFlash 400ms ease-out forwards;
}

@keyframes vfxImpactFlash {
  0%   { opacity: 0; transform: translate(-50%, -50%) scale(0.8); }
  12%  { opacity: 1; transform: translate(-50%, -50%) scale(1.1); }
  50%  { opacity: 1; transform: translate(-50%, -50%) scale(1.0); }
  100% { opacity: 0; transform: translate(-50%, -50%) scale(1.0); }
}

/* Basic Attack — CSS-only white slash arc */
.vfx-basic-slash {
  position: absolute;
  width: 120px;
  height: 120px;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%) rotate(-30deg);
  pointer-events: none;
  z-index: 21;
  opacity: 0;
  mix-blend-mode: screen;
}

.vfx-basic-slash::before {
  content: '';
  position: absolute;
  width: 100%;
  height: 100%;
  border-radius: 50%;
  border: 3px solid transparent;
  border-top-color: rgba(255, 255, 255, 0.9);
  border-right-color: rgba(255, 255, 255, 0.4);
  box-shadow: 0 0 15px rgba(255, 255, 255, 0.5);
}

.vfx-basic-slash-anim {
  animation: vfxBasicSlash 250ms ease-out forwards;
}

@keyframes vfxBasicSlash {
  0%   { opacity: 0; transform: translate(-50%, -50%) rotate(-30deg) scale(0.5); }
  20%  { opacity: 1; }
  100% { opacity: 0; transform: translate(-50%, -50%) rotate(15deg) scale(1.2); }
}
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

Expected: Build succeeds — these are just CSS additions with no references yet.

- [ ] **Step 3: Commit**

```bash
git add src/styles.css
git commit -m "feat: VFX CSS — travel streak, impact flash, basic slash keyframes"
```

---

## Task 4: VfxOverlay Component

**Files:**
- Create: `src/VfxOverlay.jsx`

- [ ] **Step 1: Create src/VfxOverlay.jsx**

```jsx
import { useState, useCallback } from 'react';
import { elementColors } from './gameData';
import { VFX_FRAMES } from './sprites';

export default function VfxOverlay({ vfxKey, element, direction, onComplete }) {
  const [phase, setPhase] = useState('travel'); // 'travel' | 'impact' | 'done'
  const isLTR = direction === 'left-to-right';
  const colors = elementColors[element] || elementColors.neutral;

  const handleTravelEnd = useCallback(() => {
    const frameConfig = VFX_FRAMES[vfxKey];
    if (frameConfig || vfxKey === 'BASIC_ATTACK') {
      setPhase('impact');
    } else {
      // No impact frame defined, finish immediately
      onComplete();
    }
  }, [vfxKey, onComplete]);

  const handleImpactEnd = useCallback(() => {
    onComplete();
  }, [onComplete]);

  if (phase === 'done') return null;

  return (
    <>
      {/* Travel streak */}
      {phase === 'travel' && (
        <div
          className={`vfx-travel ${isLTR ? 'vfx-travel-ltr' : 'vfx-travel-rtl'}`}
          style={{
            background: `radial-gradient(ellipse, ${colors.glow}, ${colors.primary} 60%, transparent 80%)`,
            boxShadow: `${isLTR ? '-20px' : '20px'} 0 20px ${colors.primary}`,
          }}
          onAnimationEnd={handleTravelEnd}
        />
      )}

      {/* Impact frame — concept art or basic slash */}
      {phase === 'impact' && vfxKey === 'BASIC_ATTACK' && (
        <div
          className="vfx-basic-slash vfx-basic-slash-anim"
          onAnimationEnd={handleImpactEnd}
        />
      )}

      {phase === 'impact' && vfxKey !== 'BASIC_ATTACK' && VFX_FRAMES[vfxKey] && (
        <ImpactFrame config={VFX_FRAMES[vfxKey]} onAnimationEnd={handleImpactEnd} />
      )}
    </>
  );
}

function ImpactFrame({ config, onAnimationEnd }) {
  const { src, crop, filter } = config;

  // Calculate background-size and background-position to show only the crop region.
  // We want the crop region to fill a 200x200 display area.
  // Scale factor: display / crop. We use the largest dimension to contain the crop.
  const displaySize = 200;
  const scaleX = displaySize / crop.w;
  const scaleY = displaySize / crop.h;
  const scale = Math.min(scaleX, scaleY);

  // For the source image, we need to know its natural dimensions.
  // Since sheets are either 1024x1024, 1536x1024, or 1024x1536,
  // we infer from src path. But simpler: use background-size as percentage.
  // background-position in px, background-size to scale the full sheet.

  // Alternative simpler approach: use object-fit with a clip-path? No — background-image
  // approach is more reliable for cropping sprite sheets.

  // We'll use a known-size approach: render the sheet scaled so that 1 source px = scale screen px,
  // then offset to show the crop region.
  // We don't know the full sheet size here, so we hardcode a lookup.
  const sheetSizes = {
    '/assets/vfx/fire_effects.png': { w: 1024, h: 1024 },
    '/assets/vfx/stone_explosion.png': { w: 1536, h: 1024 },
    '/assets/vfx/storm_lightning.png': { w: 1536, h: 1024 },
    '/assets/vfx/ice_crystals.png': { w: 1024, h: 1536 },
    '/assets/vfx/venom_cloud.png': { w: 1536, h: 1024 },
    '/assets/vfx/shadow_flames.png': { w: 1536, h: 1024 },
    '/assets/vfx/stone_meteor.png': { w: 1024, h: 1536 },
    '/assets/vfx/venom_splash.png': { w: 1536, h: 1024 },
  };

  const sheet = sheetSizes[src] || { w: 1024, h: 1024 };
  const bgW = sheet.w * scale;
  const bgH = sheet.h * scale;
  const bgX = -(crop.x * scale);
  const bgY = -(crop.y * scale);

  return (
    <div
      className="vfx-impact vfx-impact-flash"
      style={{
        backgroundImage: `url(${src})`,
        backgroundSize: `${bgW}px ${bgH}px`,
        backgroundPosition: `${bgX}px ${bgY}px`,
        filter: filter || 'none',
      }}
      onAnimationEnd={onAnimationEnd}
    />
  );
}
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

Expected: Build succeeds (component isn't rendered yet, just created).

- [ ] **Step 3: Commit**

```bash
git add src/VfxOverlay.jsx
git commit -m "feat: VfxOverlay component — travel streak + impact frame rendering"
```

---

## Task 5: Wire VfxOverlay into BattleScreen

**Files:**
- Modify: `src/BattleScreen.jsx`

- [ ] **Step 1: Add VfxOverlay import**

At the top of `src/BattleScreen.jsx`, after the `DamageNumber` import (line 11), add:

```js
import VfxOverlay from './VfxOverlay';
```

- [ ] **Step 2: Add vfxActive state to battleReducer**

In the `initBattle` function's return object (around line 28-54), add a new field after `npcStatus: null,`:

```js
    vfxActive: null,
```

In the `battleReducer` switch statement, add two new cases before the `default:` case (around line 89):

```js
    case 'SET_VFX':
      return { ...state, vfxActive: action.value };
    case 'CLEAR_VFX':
      return { ...state, vfxActive: null };
```

- [ ] **Step 3: Add VFX to animateEvent**

In the `animateEvent` function, add the VFX sequence between the TELEGRAPH and IMPACT phases. Find the comment `// IMPACT phase` (around line 127). Insert the following **before** that comment:

```js
    // VFX TRAVEL + IMPACT phase
    const move = moves[event.moveKey] || moves.basic_attack;
    const vfxElement = move.element === 'neutral' ? 'neutral' : move.element;
    const vfxDirection = isPlayer ? 'left-to-right' : 'right-to-left';

    // Create a promise that resolves when VfxOverlay calls onComplete
    let vfxResolve;
    const vfxPromise = new Promise((resolve) => { vfxResolve = resolve; });
    dispatch({
      type: 'SET_VFX',
      value: {
        vfxKey: event.vfxKey,
        element: vfxElement,
        direction: vfxDirection,
        onComplete: () => {
          dispatch({ type: 'CLEAR_VFX' });
          vfxResolve();
        },
      },
    });
    await vfxPromise;

```

- [ ] **Step 4: Add `moves` import**

The `animateEvent` function now references `moves` from gameData. Check the existing import at the top of the file (line 3):

```js
import { dragons, npcs, moves, elementColors, STATUS_EFFECTS } from './gameData';
```

`moves` is already imported — no change needed.

- [ ] **Step 5: Render VfxOverlay in the JSX**

In the JSX return, inside the `.arena-sprites` div (around line 364-408), add the VfxOverlay render **after** the closing `</div>` of the player sprite container and **before** the closing `</div>` of `.arena-sprites`. Find the player sprite block that ends around line 407 with `</div>`. Insert the following just before the closing `</div>` of `.arena-sprites`:

```jsx
        {/* VFX overlay */}
        {state.vfxActive && (
          <VfxOverlay
            vfxKey={state.vfxActive.vfxKey}
            element={state.vfxActive.element}
            direction={state.vfxActive.direction}
            onComplete={state.vfxActive.onComplete}
          />
        )}
```

- [ ] **Step 6: Verify build**

```bash
npm run build
```

Expected: Build succeeds with no errors.

- [ ] **Step 7: Commit**

```bash
git add src/BattleScreen.jsx
git commit -m "feat: wire VfxOverlay into battle — travel streak + impact on every attack"
```

---

## Task 6: Run Tests & Manual Verification

**Files:** None — testing only.

- [ ] **Step 1: Run the test suite**

```bash
npm test
```

Expected: All existing tests pass. No new tests needed — VFX is purely visual rendering with no testable logic.

- [ ] **Step 2: Run production build**

```bash
npm run build
```

Expected: Build succeeds.

- [ ] **Step 3: Manual playthrough**

```bash
npm run dev
```

Open browser at localhost. Play through a battle and verify:
- Each attack shows an element-colored travel streak flying from attacker to target
- After the streak, an impact frame flashes over the target (screen-blended)
- NPC attacks show the streak flying right-to-left
- Basic Attack shows a white slash arc instead of a concept art frame
- Damage numbers still appear on top of the VFX
- Victory/defeat still works correctly
- No VFX lingers after the animation completes

- [ ] **Step 4: Fine-tune crop coordinates if needed**

If any impact frames show the wrong region of the concept art, update the crop coordinates in `src/sprites.js` `VFX_FRAMES`. Adjust `x`, `y`, `w`, `h` values based on what looks best in-game.

- [ ] **Step 5: Commit any tweaks**

```bash
git add src/sprites.js
git commit -m "fix: fine-tune VFX crop coordinates after visual testing"
```

Skip this step if no adjustments were needed.

---

## Task 7: Final Commit

- [ ] **Step 1: Verify clean state**

```bash
git status
npm test
npm run build
```

Expected: Clean working tree (or only unrelated files), all tests pass, build succeeds.

- [ ] **Step 2: Final commit if any remaining changes**

```bash
git add -A
git commit -m "feat: attack VFX system — concept art impacts + CSS travel streaks"
```

Skip if nothing to commit.
