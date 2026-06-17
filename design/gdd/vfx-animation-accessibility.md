# VFX, Animation & Accessibility

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: Arcade Spectacle / Accessible by Default

## Summary

This system governs all visual animation and VFX that play during battle and
hatching sequences: GSAP-driven sprite motion (lunge, shake, squash, flicker,
knockback), animated projectile strips flying across the battle arena, CSS
sprite-class state animations, the Singularity corruption overlay ramp, and
the two-layer accessibility contract (CSS `prefers-reduced-motion` global
reset plus a JS `matchMedia` guard on every GSAP camera motion).

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps:
> `battle-engine`, `hatchery`

---

## Overview

Dragon Forge is a turn-based browser game styled after 16-bit arcade fighters.
Every combat event — hit, miss, critical, reflect, KO, status apply, buff,
charge — triggers a choreographed sequence of sprite animations, projectile
VFX, and camera/shake effects that make turn resolution feel physically weighty
despite having no real-time input. Animations are produced by two independent
layers working together: GSAP timelines attached directly to DOM elements
(`animationEngine.js`), and a CSS class-swap system on the combatant sprite
containers (`battlePresentation.js` + `battle.css`). A separate `VfxOverlay`
component renders projectile sprites across the arena. The Singularity endgame
arc adds a fifth system: a CSS `corruption-stage-N` class applied at the root
that escalates ambient glitch/flicker effects as the narrative threat increases.
All motion-intensive paths — GSAP camera shakes and the CSS glitch animations —
are neutralized when the OS accessibility setting `prefers-reduced-motion:
reduce` is active.

---

## Player Fantasy

The player should feel like every attack lands with weight and consequence. A
basic hit reads as a satisfying crunch; a critical hit feels like a
ground-shaking moment worth pausing for. Misses carry comedic or tense
deflation. When a dragon faints, the sprite shatter effect should feel like
a pixelated glass explosion rather than a fade. The hatching burst should feel
like witnessing a birth — chaotic light, scattered shell fragments, and a
spark of life.

Accessibility is treated as equal to spectacle. A player with vestibular
sensitivity or photosensitivity must be able to experience the full game loop
without motion triggers, without having to opt out of anything themselves — the
OS system setting is the only switch they need.

Primary MDA aesthetics served: **Sensation** (tactile hit feedback) and
**Fantasy** (the power of commanding elemental dragons).

---

## Detailed Design

### Core Rules

**GSAP Animation Layer (animationEngine.js)**

1. `prefersReducedMotion()` queries `window.matchMedia('(prefers-reduced-motion: reduce)')` at call-time. Every GSAP function that produces camera or spatial motion checks this guard first and returns an instant no-op tween if true. (`animationEngine.js` lines 6–10)

2. `screenShake(container, intensity, duration)` — Smooth sinusoidal screen shake. Default `intensity = 6px`, `duration = 0.2s`. Subdivides duration into 0.05s cycles (`cycles = Math.round(duration / 0.05)`), moves the container randomly within `±intensity` on both axes with `power2.inOut` easing, then resets to `{x:0, y:0}` on complete. Used for ambient/boss impacts. (lines 13–27)

3. `pixelShake(container, intensity, duration)` — Hard integer-pixel NES-style square-wave shake. Default `intensity = 5px`, `duration = 0.18s`, step interval `0.04s`. Alternates left/right sign each cycle with linear decaying amplitude (`amp = max(1, round(intensity * (1 - i/cycles)))`). Used on every hit contact; crunchier than `screenShake`. (lines 32–47)

4. `hitStop(duration)` — Awaitable promise pause. Default `duration = 0.08s`. Callers `await hitStop()` between landing contact and dealing damage burst, producing a freeze-frame beat identical to NES/SNES hit-lag. (lines 52–54)

5. `targetKnockback(el, attackerSide, intensity)` — Slides the defender `intensity = 12px` away from the attacker side, then springs back with `back.out(2.2)` ease. Forward slide duration `0.06s`, return `0.22s`. (lines 58–64)

6. `hitFlicker(spriteEl, cycles)` — 4-cycle CSS filter brightness toggle (`brightness(3) saturate(0)` → normal) at 0.03s per half-cycle, producing a palette-swap white flash. Applied to the sprite element, not the container. (lines 68–79)

7. `hitFlash(targetContainer, color)` — Injects a temporary `<div>` with `mix-blend-mode: screen` and animates it from `opacity 0 → 0.7 → 0`. Duration `0.06s` per direction, `yoyo: true, repeat: 1`. Default color `#ffffff`. Self-removes on complete. (lines 82–110)

8. `hitFreeze(tl, duration)` — Adds an inline pause to an existing GSAP timeline via `addPause`, then resumes after `duration`. Used to stitch freeze moments into complex composed timelines. (lines 113–118)

9. `zoomPunch(container, targetSide)` — Scales container to `1.06` while shifting `±15px` toward the target, then reverses with `back.out(2)`. Duration `0.15s` each leg. (lines 121–137)

10. `criticalHit(container, targetContainer, targetSide)` — Composed timeline: desaturate attacker (`saturate(0.3)`), pause `0.1s`, inject full white flash overlay, trigger `screenShake(container, 11, 0.25)` in parallel, then `zoomPunch`. The most visually intensive single-event animation. (lines 140–173)

11. `shieldUp(targetContainer, element)` / `shieldDeflect(shieldEl, targetContainer, attackDir)` / `shieldDismiss(shieldEl, shieldTimeline)` — Three-function shield lifecycle. `shieldUp` injects a `.shield-aegis` DOM node with three child spans (dome, ring, sweep), animates it in from `scale 0.55` to `1.07` then settles to `1.0`, then runs an infinite `opacity 0.82` breathing loop. `shieldDeflect` creates an expanding ripple, distorts the shield with elastic squash (scaleX/Y squeeze-and-pop), brightens it to `brightness(2.4)`, and spawns 6 sparks. `shieldDismiss` kills the timeline and fades to `opacity 0, scale 0.8`. (lines 180–243)

12. `shatterKO(spriteEl, element)` — Splits the sprite into a `3×4` grid of absolutely-positioned `<div>` fragments using `canvas.toDataURL()` or `img.src`. Hides the original sprite, then scatters all 12 fragments with randomized `dx: ±120px`, `dy: -40 to +80px`, `rotation: ±180deg`, fading to `opacity 0, scale 0.3` over `0.5s`. Emits 5 element-colored particle motes from the center. (lines 283–394)

13. `statusAuraApply(spriteEl, statusEffect)` — Applies a persistent CSS filter tint and an optional infinite-repeat pulse to the sprite, plus spawns 5 `status-particle` DOM nodes running element-specific looping animations (`rise`, `fall`, `spark`, `orbit`, `drift`). Returns a `{ timelines, particles, kill() }` handle. Status tints and behaviors are table-driven (`STATUS_TINTS`, `STATUS_PULSE`, `STATUS_PARTICLE_CONFIG`). (lines 397–560)

14. `npcLunge(npcEl, direction)` / `playerLunge(spriteEl, direction)` — Anticipation pull-back (`±25%` of lunge distance), then strike forward (`±30px` for NPC, `±20px` for player), then return. NPC timeline: `0.09s pull + 0.11s strike + 0.18s hold + 0.18s return`. Player timeline: `0.08s + 0.11s + 0.16s`. (lines 563–583)

15. `hitSquash(el)` — Squash-and-stretch on impact: `scaleY: 0.95, scaleX: 1.05` in `0.05s`, return with `back.out(3)` in `0.1s`. (lines 587–592)

16. `eggBurst(container, element)` — Hatchery-specific composed effect. Plays a radial gradient light flash expanding from `scale 0.5 → 1.4`, spawns a `.hatch-rays` div that rotates `26deg` and fades, splits the egg canvas into a `3×3` shard grid that scatters, then emits 14 sparkle motes in the element's color palette. (lines 599–725)

**CSS Class Swap Layer (battlePresentation.js + battle.css)**

17. `classifyBattleEvent(event)` maps a resolved battle event to one of 8 presentation kinds: `defend`, `reflect`, `buff`, `charge`, `miss`, `status`, and several hit variants (lines 149–165, `battlePresentation.js`).

18. `getBattlePresentationProfile(event, move)` returns a named profile from `BASE_PROFILES` (see Tuning Knobs below). Heavy moves (`move.power >= 70`) receive an additional `+60ms` to `anticipationMs` and `+40ms` to `launchMs`. (lines 167–182)

19. CSS sprite classes applied to combatant sprite containers drive the observable telegraph/recoil animations independently of GSAP:
    - `.sprite-telegraph` — `animation: telegraph 0.4s ease-in-out`
    - `.sprite-telegraph-heavy` — `animation: telegraph 0.52s steps(2, end)`
    - `.sprite-recoil` — `animation: recoil 0.2s ease-in-out`
    - `.sprite-recoil-soft` — `animation: recoil 0.14s ease-in-out`
    - `.sprite-recoil-heavy`, `.sprite-critical-hit`, `.sprite-ko-hit`, `.sprite-reflect-hit` — `animation: recoil 0.28s steps(2, end)`
    - `.sprite-whiff` — `animation: whiff 0.22s ease-out`
    - `.sprite-status-hit` — `animation: statusHit 0.35s ease-out`
    - `.sprite-guard` — `animation: guardPulse 0.28s ease-out`
    - `.sprite-celebrate` — `animation: celebrateBounce 0.72s ease-out infinite`
    - `.sprite-ko` — `animation: fadeOut 0.6s ease-out forwards`
    (All durations from `battle.css` lines 846–892)

20. `getBattleResultCallout(event)` returns a text callout (`MISS`, `RESIST`, `SUPER HIT`, `CRITICAL`, `REFLECT`, `KO`, `FORTIFY`, `CHARGING`) for the `.battle-callout` overlay. The callout animates with `battleCalloutPop 620ms steps(2, end) forwards`. (lines 184–198, `battlePresentation.js`)

**VFX Overlay (VfxOverlay.jsx)**

21. `VFX_FRAMES` in `sprites.js` maps each move's `vfxKey` to a 4-frame sprite strip at `public/assets/vfx/vfx_<move>.png` (1024×256 layout, each frame 256×256). `BASIC_ATTACK` and `NULL_REFLECT` are `null` — they fall back to CSS-only effects.

22. When a `vfxKey` has a strip config, `VfxOverlay` renders a `StripVfx` using `requestAnimationFrame`. The projectile travels from `FAR_EDGE (78%)` to `NEAR_EDGE (18%)` (or reversed based on `targetSide`) over `TRAVEL_MS = 330ms`. During travel, frames `0..n-2` advance proportionally. The impact frame (`n-1`) holds for `IMPACT_MS = 220ms` with a scale pulse (`1.1 + 0.4 * sin(t * π)`). The sprite is rendered at `STRIP_DISPLAY = 200px` and mirrored horizontally (`scaleX: -1`) for right-to-left travel. (lines 6–109, `VfxOverlay.jsx`)

23. Legacy CSS fallback (`LegacyVfx`) renders a radial-gradient glow blob for the travel phase using `vfxTravelLTR` / `vfxTravelRTL` keyframes (`350ms`), then a `.vfx-basic-slash` arc for `BASIC_ATTACK` (`250ms`).

**Singularity Corruption Overlay (singularity.css)**

24. A CSS class `corruption-stage-N` (N = 2–5) applied to the root element escalates ambient visual degradation:
    - **Stage 2**: Heavier scanline overlay, nav ticker jitter (`corruptionTickerJitter 10s`)
    - **Stage 3**: RGB chromatic aberration fringe (`inset 2px rgba(255,0,0,0.06)` etc.), nav flicker (`12s`), card glitch (`15s`)
    - **Stage 4**: Static flash overlay (`corruptionStaticFlash 15s`), Felix portrait skew, arena hue-rotate `5deg`
    - **Stage 5**: Maximum scanlines, full chromatic fringe (`inset 4px`), `corruptionScreenShake 0.5s infinite`, static flash `8s`, Felix portrait heavy jitter, border pulse red, arena hue-rotate `15deg`
    All of these are CSS `animation` declarations and are therefore zeroed out by the `prefers-reduced-motion` global reset.

**Accessibility (Two-Layer Contract)**

25. **CSS layer** — `base.css` lines 75–84: `@media (prefers-reduced-motion: reduce)` sets `animation-duration: 0.001ms !important`, `animation-iteration-count: 1 !important`, `transition-duration: 0.001ms !important`, `scroll-behavior: auto !important` on `*, *::before, *::after`. This neutralizes all CSS animations app-wide including all Singularity corruption stages.

26. **JS layer** — `animationEngine.js` lines 6–10: `prefersReducedMotion()` checks `window.matchMedia('(prefers-reduced-motion: reduce)')` at call-time. Every GSAP function that moves the camera container (`screenShake`, `pixelShake`) checks this before running and substitutes a zero-duration `gsap.to({x:0, y:0, duration:0})` no-op. Non-spatial GSAP effects (`hitFlicker`, `hitFlash`, `shieldDeflect`, `statusAuraApply`, etc.) do NOT guard — they are considered non-vestibular and are preserved.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|-----------------|----------------|----------|
| Idle | Battle phase starts; no action pending | Player selects move | No sprite animation classes; status aura loops run if active |
| Anticipation | `presentationProfile.anticipationMs` timer starts | Timer elapses | Attacker receives `attackerClass` CSS class (telegraph) |
| Launch | Anticipation complete | `launchMs` elapses | VFX projectile created in `VfxOverlay`; lunge GSAP plays |
| Impact | VFX reaches target | GSAP impact effects complete | Hit flash, pixel shake, hit flicker, knockback, squash, damage number displayed |
| Recovery | Impact complete | `recoveryMs` elapses | Defender receives `defenderClass` CSS class (recoil); HP bar updates |
| KO | Target HP reaches 0 | `shatterKO` animation complete | Sprite splits into fragments; defeat state entered |
| Shield Active | `defend` or `reflect` action chosen | End of turn | `shieldUp` GSAP runs; `.shield-aegis` DOM node present; breathing loop runs |
| Shield Deflect | Incoming attack while shield active | `shieldDeflect` GSAP complete | Ripple + squash + sparks |
| Status Aura | `statusAuraApply` called | `statusAura.kill()` called | Persistent tint + pulse + particle loop |

### Interactions with Other Systems

**battleEngine.js → this system**: `resolveTurn()` returns an `event` object
that includes `hit`, `isCritical`, `effectiveness`, `targetHp`, `action`,
`appliedStatus`, `reflected`, `attacker`. `classifyBattleEvent` and
`getBattlePresentationProfile` consume this to select the presentation profile.

**BattleScreen.jsx → this system**: Owns the animation sequencing loop.
Calls `animationEngine` functions directly on refs to DOM elements. Dispatches
CSS class changes (`SET_PLAYER_SPRITE_CLASS`, `SET_NPC_SPRITE_CLASS`) to
`battleReducer`. Manages `VfxOverlay` mounting/unmounting via `vfxActive` state.

**gameData.js → this system**: `elementColors` provides `{primary, glow}`
palette objects consumed by `hitFlash`, `shatterKO`, `statusAuraApply`,
`shieldUp`, `eggBurst`, and `VfxOverlay` (for legacy CSS gradient colors).

**singularityProgress.js → this system**: Reads the player's Singularity
stage and applies `corruption-stage-N` class to the root `<div class="app">`.
This system has no direct dependency on `singularityProgress.js` — the class
is already present on the DOM when CSS rules evaluate.

**hatcheryEngine.js → this system**: The hatchery screen calls `eggBurst(container, element)` directly when an egg hatches.

---

## Formulas

### screenShake Cycle Count

```
cycles = Math.round(duration / 0.05)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| duration | float | 0.1–0.4 (s) | call site | Total shake window |
| cycles | int | 2–8 | computed | Number of 50ms displacement steps |

**Default call**: `duration = 0.2` → `cycles = 4`.

---

### pixelShake Amplitude Decay

```
amp = max(1, round(intensity * (1 - i / cycles)))
dx  = (i % 2 === 0) ? -amp : amp
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| intensity | int | 1–15 (px) | call site | Starting displacement magnitude |
| i | int | 0..cycles-1 | loop | Current cycle index |
| cycles | int | 2–5 | computed | `max(2, round(duration / 0.04))` |
| amp | int | 1..intensity (px) | computed | Decayed pixel displacement |

**Default call**: `intensity = 5, duration = 0.18` → `cycles = 5`, amp decays 5→4→3→2→1 px.

---

### VFX Strip Playback (StripVfx)

```
travelEnd = TRAVEL_MS / (TRAVEL_MS + IMPACT_MS)  // = 330 / 550 ≈ 0.6

During travel (t < travelEnd):
  tt = t / travelEnd
  x = startX + (endX - startX) * tt                  // linear interpolation
  frameIdx = min(frames - 2, floor(tt * (frames - 1)))
  scale = 0.7 + 0.35 * tt                             // 0.7 → 1.05
  opacity = min(1, tt * 5)                            // fades in over first 20%

During impact (t >= travelEnd):
  tt = (t - travelEnd) / (1 - travelEnd)
  x = endX                                            // stationary
  frameIdx = frames - 1                               // hold impact frame
  scale = 1.1 + 0.4 * sin(min(1, tt) * π)            // pulse 1.1 → 1.5 → 1.1
  opacity = 1 - max(0, (tt - 0.45) / 0.55)           // fades from 45% of impact phase
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| TRAVEL_MS | int | 330 | `VfxOverlay.jsx` ln 7 | Projectile flight duration |
| IMPACT_MS | int | 220 | `VfxOverlay.jsx` ln 8 | Impact burst hold duration |
| STRIP_DISPLAY | int | 200 (px) | `VfxOverlay.jsx` ln 9 | Rendered size of each strip frame |
| NEAR_EDGE | int | 18 (%) | `VfxOverlay.jsx` ln 14 | Left combatant position in arena |
| FAR_EDGE | int | 78 (%) | `VfxOverlay.jsx` ln 15 | Right combatant position in arena |
| frames | int | 4 | `sprites.js` via `strip()` | Frames per strip sheet |

**Example**: With `frames = 4`, during travel the projectile shows frames 0, 1, 2 in sequence; at impact it locks to frame 3.

---

### Presentation Profile Timing (Heavy Move Adjustment)

```
isHeavyMove = (move.power >= 70)

effectiveAnticipationMs = profile.anticipationMs + (isHeavyMove ? 60 : 0)
effectiveLaunchMs       = profile.launchMs       + (isHeavyMove ? 40 : 0)
```

The `power >= 70` threshold is defined at `battlePresentation.js` line 170.

---

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| `prefersReducedMotion()` = true, `screenShake` called | Returns immediate `gsap.to({x:0,y:0,duration:0})`; container stays in place | Vestibular safety |
| `prefersReducedMotion()` = true, CSS animations present | All CSS animations collapse to `0.001ms, 1 iteration`; no looping occurs | CSS global reset in `base.css` covers all elements including `::before`/`::after` |
| `shatterKO` on an `<img>` element | Uses `el.src` instead of `canvas.toDataURL()`; fragments created normally | `spriteEl.tagName === 'CANVAS'` branch at `animationEngine.js` line 293 |
| `shatterKO` on canvas with cross-origin content | `toDataURL()` throws; `imageSrc` remains `''`; fragments render with no background image | try/catch at line 646 (`eggBurst`) / bare assignment at line 295 (`shatterKO`) |
| `shieldDismiss` called before `shieldUp` completes | `shieldTimeline.kill()` cancels the GSAP timeline at whatever point it is; fade-out proceeds | Kill is always safe in GSAP |
| `statusAuraApply` called twice on the same sprite | A second set of tint+pulse+particle timelines is added. First must be `.kill()`ed by caller before calling again | Caller (BattleScreen) is responsible for clearing aura on status expiry or switch |
| VFX strip asset not found / 404 | `StripVfx` continues running the rAF loop; the `<div>` background-image is empty (invisible). `onComplete` fires normally after total duration | No error thrown; silent miss |
| VfxKey is `null` (BASIC_ATTACK, NULL_REFLECT) | `VFX_FRAMES[vfxKey]?.strip` is falsy; `LegacyVfx` branch used | `sprites.js` line 54–55 |
| `corruption-stage-5` + `prefers-reduced-motion` | CSS reset overrides all animation keyframes including `corruptionScreenShake`; stage still applies non-motion styles (scanlines, box-shadow, border colors) | Non-motion visual cues preserved |
| `eggBurst` on a container with no `<canvas>` child | Shard phase is skipped; flash, rays, and sparkles still run | `canvas` null-check at `animationEngine.js` line 643 |

---

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| `battleEngine.js` | This system consumes | Requires the `event` object shape from `resolveTurn()` — specifically `hit`, `isCritical`, `effectiveness`, `targetHp`, `action`, `appliedStatus`, `reflected` |
| `gameData.js` (elementColors) | This system consumes | `elementColors[element].{primary,glow}` palette for VFX coloring |
| `gameData.js` (STATUS_EFFECTS) | This system consumes | Status effect metadata for `getStatusMoveSummary` label generation |
| `sprites.js` (VFX_FRAMES) | This system consumes | Strip sheet metadata (src path, frame count) per move vfxKey |
| `BattleScreen.jsx` | Orchestrates this system | Calls all `animationEngine` functions; manages timing via `await wait()` and presentation profile `Ms` values |
| `hatcheryEngine.js` / HatcheryScreen | This system consumed by | `eggBurst` is called from the hatchery screen |
| `singularityProgress.js` | Upstream (one-way) | Applies `corruption-stage-N` class to root; this system's CSS responds passively |
| OS `prefers-reduced-motion` setting | External constraint | Both CSS and JS layers read this at render/call time |

---

## Tuning Knobs

### GSAP Animation Parameters

| Parameter | Current Value | File:Line | Category | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|-----------|----------|------------|-------------------|-------------------|
| `screenShake` default intensity | 6 px | `animationEngine.js:13` | Feel | 2–15 | More violent ambient shake | Subtler, less distracting |
| `screenShake` default duration | 0.2 s | `animationEngine.js:13` | Feel | 0.1–0.5 | Longer rumble | Snappier |
| `pixelShake` default intensity | 5 px | `animationEngine.js:32` | Feel | 2–12 | Crunchier NES hit | Subtler |
| `pixelShake` default duration | 0.18 s | `animationEngine.js:32` | Feel | 0.1–0.35 | More cycles | Shorter hit-lag feel |
| `hitStop` default duration | 0.08 s | `animationEngine.js:52` | Feel | 0.04–0.15 | More freeze-frame drama | Faster pacing |
| `targetKnockback` intensity | 12 px | `animationEngine.js:58` | Feel | 5–25 | More displacement | Subtler reaction |
| `criticalHit` screenShake intensity | 11 px | `animationEngine.js:166` | Feel | 8–18 | More dramatic crits | Less screen movement |
| `hitFlash` peak opacity | 0.7 | `animationEngine.js:100` | Feel | 0.4–1.0 | Brighter flash | More subtle |
| `hitFlicker` cycles | 4 | `animationEngine.js:68` | Feel | 2–6 | More flicker cycles | Shorter flicker |
| `shieldUp` snap scale | 1.07 | `animationEngine.js:196` | Feel | 1.0–1.15 | More dramatic slam-in | Subtler appearance |
| `shatterKO` fragment scatter X | ±120 px | `animationEngine.js:337` | Feel | ±60–±200 | Wider scatter | Tighter scatter |
| `shatterKO` grid | 3 cols × 4 rows = 12 fragments | `animationEngine.js:299–300` | Feel | 2×2–4×5 | More fragments (more DOM nodes) | Fewer, chunkier pieces |
| `eggBurst` sparkle mote count | 14 | `animationEngine.js:696` | Feel | 8–20 | More sparkles | Sparser |

### VFX Overlay Parameters

| Parameter | Current Value | File:Line | Category | Safe Range | Effect of Increase |
|-----------|--------------|-----------|----------|------------|--------------------|
| `TRAVEL_MS` | 330 ms | `VfxOverlay.jsx:7` | Feel | 200–500 | Slower projectiles |
| `IMPACT_MS` | 220 ms | `VfxOverlay.jsx:8` | Feel | 120–400 | Longer impact hold |
| `STRIP_DISPLAY` | 200 px | `VfxOverlay.jsx:9` | Feel | 128–300 | Larger projectile on screen |
| `NEAR_EDGE` | 18 % | `VfxOverlay.jsx:14` | Feel | 10–25 | Left combatant moves rightward |
| `FAR_EDGE` | 78 % | `VfxOverlay.jsx:15` | Feel | 70–90 | Right combatant moves leftward |

### Presentation Profile Timing

All values live in `battlePresentation.js` `BASE_PROFILES` (lines 3–147). The
heavy-move threshold is `move.power >= 70` (line 170), adding `+60ms` to
`anticipationMs` and `+40ms` to `launchMs`.

| Profile Kind | anticipationMs | launchMs | impactPauseMs | recoveryMs | shake (px) |
|--------------|---------------|----------|---------------|------------|------------|
| defend | 240 | 0 | 0 | 180 | 0 |
| reflect | 300 | 260 | 90 | 240 | 5 |
| miss | 220 | 260 | 0 | 170 | 0 |
| resistedHit | 240 | 300 | 45 | 190 | 3 |
| normalHit | 260 | 320 | 60 | 200 | 5 |
| effectiveHit | 300 | 330 | 90 | 220 | 8 |
| criticalHit | 340 | 340 | 120 | 260 | 11 |
| ko | 320 | 340 | 140 | 320 | 10 |
| status | 0 | 0 | 50 | 240 | 2 |
| buff | 200 | 0 | 60 | 300 | 0 |
| charge | 400 | 0 | 0 | 200 | 0 |

### Status Aura Configuration

All tables are in `animationEngine.js` lines 397–422. Color values and particle
behaviors are data-driven; adding a new status effect requires adding entries to
`STATUS_TINTS`, `STATUS_PULSE`, and `STATUS_PARTICLE_CONFIG`.

| Status | CSS Filter Tint | Pulse Property | Pulse Duration | Particle Behavior | Particle Color |
|--------|----------------|----------------|----------------|-------------------|----------------|
| fire | `sepia(0.4) saturate(1.8) hue-rotate(-10deg)` | filter brightness 1.0→1.3 | 1.0 s | rise | #ff6622 |
| ice | `saturate(0.5) brightness(1.2) hue-rotate(180deg)` | none | — | fall | #88ccff |
| storm | `saturate(1.5) brightness(1.1) hue-rotate(240deg)` | opacity 1.0→0.7 | 0.15 s | spark | #aa66ff |
| stone | `saturate(0.4) brightness(0.9)` | none | — | fall | #aa8844 |
| venom | `hue-rotate(90deg) saturate(1.3)` | filter brightness 1.0→0.85 | 1.5 s | orbit | #44cc44 |
| shadow | `brightness(0.6) contrast(0.8)` | none | — | drift | #8844aa |

---

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|----------------|---------|
| Any hit | `hitFlash`, `pixelShake`, `hitFlicker`, `hitSquash`, projectile VFX strip | `attackHit` / `superEffective` / `criticalHit` sound | MVP |
| Miss | No flash/shake; `.sprite-whiff` class on attacker | `miss` sound | MVP |
| Critical hit | `criticalHit()` composed timeline (desaturate + white flash + `screenShake 11px` + zoom punch) | `criticalHit` sound | MVP |
| KO | `shatterKO()` — 12-fragment scatter, 5 element motes | `ko` sound | MVP |
| Defend | `.sprite-guard` CSS class, shield DOM node (`.shield-aegis`) | `defend` sound | MVP |
| Reflect / deflect | `shieldDeflect()` — ripple, squash, sparks | `shieldDeflectSting` sound | MVP |
| Status apply | `statusAuraApply()` — tint + pulse + 5 orbit particles | `statusApply` sound | MVP |
| Battle callout | `.battle-callout` overlay text (MISS, CRITICAL, SUPER HIT, etc.) | — | MVP |
| Egg hatch | `eggBurst()` — flash + rays + 9-shard scatter + 14 sparkles | — | MVP |
| Singularity escalation | `corruption-stage-N` CSS class on root | — | Alpha |

---

## Game Feel

### Feel Reference

The battle animation target is **Pokémon FireRed / Emerald combat animations**
as a baseline (turn-based with per-event visual punctuation), elevated with
the **NES/SNES hit-impact feel** of games like Mega Man and Final Fantasy VI:
integer-pixel shake, palette-flash white-out on hit, and a brief freeze frame
on contact. Projectile VFX borrows the arc and scale-punch of **Super
Smash Bros. Melee** projectile hits — scale-up on impact, then snap back.

Anti-reference: the system should NOT feel like modern idle game auto-battles
where animations are cosmetic noise. Every animation beat should correspond to
a meaningful game event.

### Input Responsiveness

N/A — turn-based browser game. Player input is a button click that submits a
move choice; the game is not real-time and does not have frame-sensitive input
windows. The animation sequence plays deterministically after the move is
selected. The only latency constraint is that the animation sequence must
complete before the next player turn begins.

### Animation Feel Targets

This is a turn-based game. "Frame data" in the real-time sense (startup frames,
active frames, recovery frames as hitbox windows) does not apply. The equivalent
concept is the presentation profile timing table in Tuning Knobs, which controls
the millisecond durations of anticipation, launch, impact pause, and recovery per
event type.

**Design intent by event weight:**

| Event | Feel Goal | Anticipation | Impact Pause | Total Sequence |
|-------|-----------|-------------|-------------|----------------|
| miss | Quick, deflating | 220 ms | 0 ms | ~390 ms |
| normalHit | Satisfying crunch | 260 ms | 60 ms | ~580 ms |
| effectiveHit | Emphatic, powerful | 300 ms | 90 ms | ~640 ms |
| criticalHit | Dramatic, jaw-dropping | 340 ms | 120 ms | ~720 ms |
| ko | Conclusive, weighty | 320 ms | 140 ms | ~800 ms |
| charge | Building tension, telegraphed | 400 ms | 0 ms | ~600 ms |

### Impact Moments

| Impact Type | Duration | Effect Description | Configurable? |
|-------------|----------|-------------------|---------------|
| Hit freeze (hitStop) | 80 ms default | Awaitable pause between projectile contact and damage burst | Yes — `hitStop(ms)` per call site |
| Pixel shake (pixelShake) | 180 ms default | Integer-pixel NES square-wave, 5 cycles decaying | Yes — intensity + duration params |
| Screen shake (screenShake) | 200 ms default | Smooth sinusoidal GSAP shake, 4 cycles | Yes — intensity + duration params |
| Critical screen shake | 250 ms at intensity 11 | Larger-amplitude smooth shake inside `criticalHit()` | Yes — modify `criticalHit()` call |
| Hit flash | 120 ms total | `mix-blend-mode: screen` white overlay, 0→0.7→0 | Yes — `hitFlash(container, color)` |
| Controller rumble | N/A — browser game | — | — |

### Weight and Responsiveness Profile

- **Weight**: Deliberately weighted and committed. Each action takes 400–800ms
  to resolve; this is intentional pacing that gives hits gravity. The player
  cannot cancel or interrupt a playing animation.
- **Player control**: Low during animation (animation phase locks input),
  high during player turn (full move selection panel available).
- **Snap quality**: The pixel shake and `steps()` CSS easing on telegraph
  animations give a crisp, binary arcade feel rather than smooth analog motion.
- **Acceleration model**: GSAP tweens use `power2.in/out` and `back.out` eases.
  Not linear. Punches accelerate and decelerate; springs overshoot and settle.
- **Failure texture**: Misses read clearly — no shake, no flash, `.sprite-whiff`
  plays on the attacker. The player understands immediately that nothing landed.

### Feel Acceptance Criteria

- [ ] Playtesters report hits feel "punchy" or "satisfying" without being
  prompted.
- [ ] No playtester uses "floaty" or "weightless" to describe combat animations.
- [ ] Pixel shake on a normal hit is distinguishable from screen shake on a
  critical — the intensity difference is perceptible.
- [ ] With `prefers-reduced-motion` enabled, combat is fully playable with no
  camera movement; all damage numbers and callout text still appear.
- [ ] KO shatter effect reads as a dramatic conclusion; playtesters
  pause to watch it rather than immediately selecting the next action.
- [ ] Egg hatch burst feels like a celebratory moment, not a loading screen.

---

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Battle callout text (MISS, CRITICAL, etc.) | `.battle-callout` overlay, center of arena at 29% top | Once per battle event | Event has a callout variant |
| Damage number | Floating above target combatant | Once per damage instance | Any HP change |
| Status indicator badge | Combatant card | Updated on status apply/expire | Active status present |
| Charge indicator | Attacker nameplate | While charge is active | `npcChargedMove` set |
| HP danger pulse | Combatant card border | Animated CSS loop | HP ≤ 25% (danger) or ≤ 50% (warning) |
| Arena danger vignette | Full arena overlay | CSS loop | Player HP ≤ 25% |
| Corruption overlay | Root `.app` element | On Singularity stage change | Stage ≥ 2 |

---

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| Battle event object shape | `design/gdd/combat.md` | `resolveTurn()` output — `hit`, `isCritical`, `effectiveness`, `targetHp`, `action`, `appliedStatus`, `reflected` | Data dependency |
| Element color palette | `design/gdd/combat.md` | `elementColors[element].{primary,glow}` | Data dependency |
| Status effects list | `design/gdd/combat.md` | `STATUS_EFFECTS` keys, `STATUS_APPLY_CHANCE` | Rule dependency |
| Move power values (heavy-move threshold) | `design/gdd/combat.md` | `move.power >= 70` determines extended anticipation | Rule dependency |
| Singularity corruption stages | `design/gdd/singularity-endgame.md` | `corruption-stage-N` class and stage progression | State trigger |

---

## Acceptance Criteria

**Functional:**
- [ ] All 8 presentation profile kinds (defend, reflect, miss, resistedHit, normalHit, effectiveHit, criticalHit, ko) trigger the correct CSS class pair and GSAP sequence.
- [ ] With `prefers-reduced-motion: reduce` active, `screenShake` and `pixelShake` produce no displacement (`x: 0, y: 0` verified via computed style).
- [ ] With `prefers-reduced-motion: reduce` active, all CSS animation durations collapse to `≤ 1ms` (computed `animation-duration` ≤ 0.001s on any animated element).
- [ ] `shatterKO` splits the sprite into exactly 12 DOM fragments (3 cols × 4 rows) that all self-remove after their tween completes, leaving no orphaned nodes.
- [ ] `statusAuraApply` returns a valid `{ timelines, particles, kill }` handle; calling `kill()` removes all particles from the DOM and stops all GSAP timelines.
- [ ] `VfxOverlay` `StripVfx` fires `onComplete` after `TRAVEL_MS + IMPACT_MS = 550ms` regardless of whether the strip asset loaded.
- [ ] Corruption stage classes are mutually exclusive at the root element — only one `corruption-stage-N` class is present at a time.
- [ ] Heavy moves (`power >= 70`) have an effective `anticipationMs` that is `60ms` longer than their base profile.

**Experiential (playtester verification):**
- [ ] Critical hit feels noticeably more dramatic than a normal hit to a first-time player.
- [ ] Egg hatch burst draws attention and feels celebratory, not jarring.
- [ ] Players on OS `prefers-reduced-motion` can complete a full battle campaign without reporting discomfort.
- [ ] The Singularity Stage 5 corruption overlay communicates dread without being unplayable.

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should `hitFlicker` and `hitFlash` be guarded by `prefersReducedMotion` for photosensitivity? Currently only camera motion is guarded. | game-designer | — | Open — the a11y commit comment (`animationEngine.js` line 4) notes camera shakes were the primary concern; strobing flickers may also warrant a guard. |
| Should `eggBurst` shard fragments use `image-rendering: pixelated` only on the fragment `<div>`, or also on the canvas itself during normal display? | — | — | Open |
