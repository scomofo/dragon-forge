# Dragon Forge — Combat Animation Overhaul Design

**Date:** 2026-03-30
**Status:** Approved
**Style:** Snappy arcade — fast, punchy, strong feedback
**Library:** GSAP + @gsap/react

---

## 1. Animation Infrastructure

### New Dependencies
- `gsap` (~25KB) — timeline-based animation engine
- `@gsap/react` — React lifecycle integration via `useGSAP()` hook

### New File: `src/animationEngine.js`
Centralized module exporting reusable GSAP timeline factories:

```
screenShake(container, intensity)     → gsap tween
hitFlash(target, color?)              → white/element-colored overlay flash
hitFreeze(timeline, duration)         → pause insert
zoomPunch(container, target)          → scale toward target + snap back
shatterKO(spriteEl)                   → clip-path fragment timeline
shieldUp(target, element)             → shield bubble appear
shieldDeflect(shield, attackDir)      → bounce + spark
statusAura(target, statusType)        → tint + particle loop
criticalHit(container, target)        → composed: freeze + flash + zoom + shake
damageNumberPop(el, type)             → enhanced float animation
```

### Migration Path
- Existing CSS animations (`sprite-telegraph`, `sprite-recoil`, `sprite-ko`) remain for now
- New animations use GSAP exclusively
- `animateEvent()` in BattleScreen refactored to build a GSAP timeline per turn instead of chaining `await wait()` calls
- Old CSS anims can be migrated incrementally — no big-bang rewrite

---

## 2. Screen Shake & Hit Flash

### Screen Shake
Applied to the battle container element (not the whole page).

| Hit Type | Intensity | Duration | Oscillations |
|----------|-----------|----------|-------------|
| Normal | 4-6px | 200ms | 3-4 |
| Super effective | 6-8px | 250ms | 4 |
| Critical | 8-12px | 300ms | 5 (part of crit timeline) |
| Miss | None | — | — |

Intensity scales by `damage / maxHP` ratio within the range for that hit type.

Implementation: `gsap.to(container, { x: 'random(-i, i)', y: 'random(-i, i)', duration: 0.05, repeat: cycles, yoyo: true, ease: 'power2.inOut' })`

### Hit Flash
A persistent overlay div inside each sprite container. Normally invisible.

- Normal hit: white flash, opacity `0 → 0.7 → 0` over 120ms
- Super effective: element-colored flash (using `elementColors` from gameData) instead of white
- Implementation: `gsap.fromTo(overlay, { opacity: 0 }, { opacity: 0.7, duration: 0.06, yoyo: true, repeat: 1 })`

Both trigger after VFX impact phase completes, replacing the current bare `wait(300)` gap.

---

## 3. Defend — Shield + Deflect

### Shield Appearance
Triggered when a dragon uses a defend action.

- Translucent hexagonal shape via `clip-path: polygon(...)`
- Element-colored with matching `box-shadow` glow
- Entry: `scale(0.5) → scale(1.05) → scale(1.0)`, `opacity 0 → 0.8` over 250ms
- Idle pulse while active: `opacity 0.7 ↔ 0.85` looping
- Positioned over the defending dragon's sprite container

### Deflect on Hit
When enemy attack lands on a defending dragon:

- Shield brightens to full opacity for 80ms
- 2-3 spark particles spawn at contact point (side facing attacker), fly outward at random angles over 200ms
- Shield wobbles: `scaleX(0.95) → scaleX(1.05) → scaleX(1.0)` over 150ms
- Screen shake at half normal intensity (hit was blocked)
- Damage number uses `resisted` style

### Shield Dismiss
After attack resolves: `scale(1.0) → scale(0.8)`, `opacity → 0` over 200ms. DOM element removed.

### Sparks
2-3 small `<div>` elements, `border-radius: 50%`, element-colored, animated with GSAP for position + opacity + scale. No canvas needed.

---

## 4. Critical Hits — Hit-Freeze + Flash + Zoom Punch

Composed GSAP timeline firing when `event.isCritical` is true. Total duration ~500ms.

```
0ms    → Hit-freeze: timeline pauses for 100ms
         Screen desaturates (filter: saturate(0.3))

100ms  → White flash: full-opacity overlay, 0 → 1.0 → 0 over 100ms
         Screen shake: heavy (10-12px), 4 oscillations

200ms  → Zoom punch: container scales 1.0 → 1.06
         translateX shifts slightly toward target side

350ms  → Snap back: scale 1.06 → 1.0, translate resets
         ease: 'back.out(2)'
         Desaturation filter removed

400ms  → Critical damage number appears (see enhanced damage numbers)

500ms  → Timeline complete, resume normal flow
```

### Critical Damage Number
- New CSS class `.critical` — font-size +30%, bold, gold color (`#ffcc00`)
- Entry: `scale(1.5) → scale(1.0)` with `back.out` ease (bouncy pop-in)
- Pulsing `text-shadow` glow in element color, 2 cycles over float duration
- Floats higher than normal (-80px instead of -60px)

Crits use this composed timeline instead of the normal shake + flash path.

### Battle Engine Change Required
`battleEngine.js` does not currently have a critical hit system. Implementation must add:
- Critical hit chance (e.g., base 10%, modified by move/dragon properties)
- `isCritical: true` flag on attack events returned by `resolveTurn()`
- Critical damage multiplier (e.g., 1.5x)

This is the only game logic change in this spec — everything else is purely visual.

---

## 5. KO — Flash + Shatter

Replaces current simple opacity fade when a dragon's HP hits 0. Total duration ~800ms.

```
0ms    → White flash: full-opacity overlay on sprite, 100ms
         Screen shake: medium (6px)

100ms  → Sprite freezes on current frame
         Create 9-12 shatter fragments as cloned <div> elements
         Each shows a clip-path portion of sprite (3x3 or 3x4 grid)
         Hide original sprite instantly

100ms  → Fragments fly outward (staggered 30ms apart):
         - translateX: ±60-120px (random per fragment)
         - translateY: -40 to +80px (random)
         - rotation: ±90-180deg (random)
         - scale: 1.0 → 0.3
         - opacity: 1 → 0
         - duration: 500ms per fragment
         - ease: 'power2.out'

350ms  → Element-colored burst particles (4-6 small dots) from center
         Scatter outward, fade over 300ms

650ms  → All fragments fully faded, clean up DOM

800ms  → Timeline complete, proceed to victory/next turn
```

### Fragment Creation
- For canvas-based DragonSprite: `canvas.toDataURL()` captures current frame as static image
- Image used as `background-image` for each fragment div
- Each fragment uses `clip-path: inset(...)` to show only its grid cell
- GSAP `.stagger()` for the sequential launch

### Sound
Existing KO sound at 0ms. Glass/shatter SFX if available in sound engine.

---

## 6. Status Effect Visuals — Tint + Particle Aura

Two visual layers persist while a status is active on a dragon.

### Layer 1 — Sprite Tint (CSS filter)

| Status | Filter | Pulse |
|--------|--------|-------|
| Burn | `sepia(0.4) saturate(1.8) hue-rotate(-10deg)` | Brightness 1.0 ↔ 1.3, 1s cycle |
| Freeze | `saturate(0.5) brightness(1.2) hue-rotate(180deg)` | None — static cold |
| Paralyze | `saturate(1.5) brightness(1.1) hue-rotate(240deg)` | Random opacity flicker (electrical) |
| Poison | `hue-rotate(90deg) saturate(1.3)` | Brightness 1.0 ↔ 0.85, 1.5s cycle |
| Guard Break | `saturate(0.4) brightness(0.9)` | None — dull/weakened |
| Blind | `brightness(0.6) contrast(0.8)` | None — dark/obscured |

Applied via `gsap.to(spriteEl, { filter, duration: 0.3 })`. Reversed on expire.

### Layer 2 — Particle Aura (4-6 looping particles)

Small `<div>` circles (6-10px), absolutely positioned around sprite, looping GSAP timelines:

| Status | Color | Behavior |
|--------|-------|----------|
| Burn | `#ff6622` | Rise upward like embers, fade at top, respawn at bottom |
| Freeze | `#88ccff` | Drift downward like snowflakes, slight horizontal wobble |
| Paralyze | `#aa66ff` | Quick erratic jumps, static sparks |
| Poison | `#44cc44` | Slow orbit, bubble-like scale up then pop |
| Guard Break | `#aa8844` | Small chips fall downward from edges |
| Blind | `#8844aa` | Slow wisps drift across sprite |

Each particle: `border-radius: 50%`, colored background + `box-shadow` glow, ~3s loop with staggered starts.

### On Status Expire
- Particles scatter outward and fade (200ms)
- Tint transitions back to normal (300ms)
- Status indicator icon fades as it already does

### Multiple Statuses
Tint filters combine via CSS. Particle sets coexist in the same container.

---

## 7. NPC Sprite Animation & Damage Numbers

### NPC Attack Animation
Upgrade from static image swap to animated lunge:

- **Lunge out:** `translateX(±30px)` toward player over 150ms, `ease: 'power2.in'`
- **Hold pose:** Swap to attack sprite at peak, hold 200ms
- **Return:** Translate back to origin over 150ms, swap to idle, `ease: 'power2.out'`
- **Hit reaction:** When NPC takes damage: brief `scale(0.95)` squash + 2-3px shake

### Player Dragon Attack Enhancement
- Add lunge: `translateX(±20px)` toward enemy during telegraph phase
- `forcedFrame: 3` activates at peak of lunge (not after VFX)
- Return to neutral synced with recoil clear

### Damage Number Enhancements

| Type | Animation |
|------|-----------|
| Normal | Float up, slight random X spread (±15px) |
| Super effective | Red, `scale(1.0 → 1.3 → 1.0)` bounce entry |
| Resisted | Gray, slower float, `scale(0.9)` — feels weak |
| Miss | Drifts sideways instead of up, faster fade |
| Critical | Gold, 30% larger, bounce pop-in, pulsing glow (Section 4) |
| Status tick | Element-colored, no float — pulse-in/pulse-out at position |

Staggered positioning: each new number offsets ±15px horizontally to avoid overlap on multi-hits.

---

## Files Modified

| File | Changes |
|------|---------|
| `src/animationEngine.js` | **New** — all GSAP timeline factories |
| `src/BattleScreen.jsx` | Refactor `animateEvent()` to use GSAP timelines, add overlay/shield/particle DOM elements, integrate `useGSAP()` |
| `src/DragonSprite.jsx` | Expose canvas ref for `toDataURL()` (shatter), add hit flash overlay div |
| `src/NpcSprite.jsx` | Add lunge animation, hit reaction squash |
| `src/DamageNumber.jsx` | New types (critical, status tick), staggered positioning, GSAP entry animations |
| `src/VfxOverlay.jsx` | Minor — ensure compatibility with new GSAP timing |
| `src/styles/battle.css` | New classes: `.shield-hex`, `.spark`, `.status-particle`, `.critical`, `.damage-miss`, `.damage-status-tick`, flash overlay styles |
| `package.json` | Add `gsap`, `@gsap/react` dependencies |

---

## Animation Timing Budget

Target: keep total attack animation under 2s for normal hits, 2.5s for crits. Current is ~1.8s.

| Phase | Normal | Critical |
|-------|--------|----------|
| Telegraph + lunge | 400ms | 400ms |
| VFX travel + impact | 750ms | 750ms |
| Shake + flash | 200ms | — |
| Crit timeline (freeze+flash+zoom) | — | 500ms |
| Recoil | 200ms | 200ms |
| Reset | 200ms | 200ms |
| **Total** | **~1750ms** | **~2050ms** |

KO shatter adds 800ms after final hit. Status ticks remain 400ms each.
