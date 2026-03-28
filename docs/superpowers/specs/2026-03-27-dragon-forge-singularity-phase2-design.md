# Dragon Forge: Singularity Phase 2 — Corruption Effects

## Overview

CSS-only visual corruption effects that intensify as the Singularity stage increases. Stages 0-1 are clean. Starting at stage 2, subtle CRT distortion and UI element glitches layer on progressively, building dread as the player advances. At stage 5 the screen is visibly "infected" but the game remains fully playable.

All effects are driven by a single `corruption-stage-N` CSS class applied to the root `.app` container. No new components — everything is CSS cascading from the parent class.

---

## 1. Corruption by Stage

### Stage 0-1: Clean
No corruption effects. Game looks normal.

### Stage 2: First Signs
- CRT scanline overlay opacity increases from default to 0.05
- Nav ticker text gets an intermittent jitter animation (triggers every ~10s, lasts 500ms)

### Stage 3: Growing Instability
- CRT scanline opacity increases to 0.08
- Color aberration on `.app` — offset red/cyan box-shadows: `2px 0 rgba(255,0,0,0.06), -2px 0 rgba(0,255,255,0.06)`
- Nav bar border occasionally flickers red (animation, mostly transparent, brief red flash every ~12s)
- Dragon card borders in journal/battle-select get subtle intermittent glitch (translateX jitter every ~15s)
- Ticker jitter more frequent

### Stage 4: Critical
- CRT scanline opacity at 0.12
- Color aberration intensifies: `3px 0 rgba(255,0,0,0.1), -3px 0 rgba(0,255,255,0.1)`
- Static flash: full-screen pseudo-element flashes every ~15s for 200ms (semi-transparent noise pattern, opacity 0.1)
- Felix portrait on TitleScreen: `filter: saturate(1.3)` with intermittent `skewX(2deg)` jitter
- Arena backgrounds in battle get subtle hue-shift: `filter: hue-rotate(5deg)`
- Ticker has constant jitter

### Stage 5: Breach
- CRT scanline opacity at 0.18
- Color aberration: `4px 0 rgba(255,0,0,0.15), -4px 0 rgba(0,255,255,0.15)`
- Static flash every ~8s, slightly stronger (opacity 0.15)
- Subtle screen shake on `.app`: translateX/Y jitter, 0.5px amplitude, continuous
- Felix portrait: `filter: saturate(2) contrast(1.3)` with aggressive skew + hue-rotate flicker
- All UI panel borders pulse red: `border-color` animation between normal and `#cc2222` over 3s
- Ticker has constant aggressive jitter
- Arena hue-shift increases to `hue-rotate(15deg)`

---

## 2. Implementation Approach

### 2.1 Root Class

In `App.jsx`, compute the stage from save and apply it to the root div:

```jsx
const stage = getSingularityStage(save);
<div className={`app ${stage >= 2 ? `corruption-stage-${stage}` : ''}`}>
```

### 2.2 CSS Structure

All corruption rules use descendant selectors from the stage class:

```css
/* Stage 2 rules */
.corruption-stage-2 .crt-overlay { opacity: 0.05; }
.corruption-stage-2 .nav-ticker { animation: ... }

/* Stage 3 inherits stage 2 + adds more */
.corruption-stage-3 .crt-overlay { opacity: 0.08; }
.corruption-stage-3 { box-shadow: ... }
```

Each higher stage overrides the previous. Since CSS specificity is equal, the rules are ordered stage 2 → 3 → 4 → 5 in the stylesheet, and only one `corruption-stage-N` class is applied at a time.

### 2.3 CRT Overlay

The existing CRT scanline is applied via a pseudo-element or overlay div. Check the current implementation — if it's a `::before` on `.app` or a separate `.crt-overlay` div, override its opacity per stage. If the scanline is on the `.terminal-screen` only, add a game-wide CRT overlay to `.app` that's normally invisible and gets activated at stage 2+.

### 2.4 Static Flash

A `::after` pseudo-element on `.app` that covers the screen:

```css
.corruption-stage-4::after {
  content: '';
  position: fixed;
  inset: 0;
  background: repeating-linear-gradient(
    0deg, rgba(255,255,255,0.03) 0px, transparent 1px, transparent 2px
  );
  opacity: 0;
  pointer-events: none;
  z-index: 1000;
  animation: staticFlash 15s linear infinite;
}

@keyframes staticFlash {
  0%, 98% { opacity: 0; }
  98.5% { opacity: 0.1; }
  99.5% { opacity: 0; }
}
```

Stage 5 overrides with faster timing (8s cycle) and higher opacity.

---

## 3. File Changes

| File | Action | Changes |
|---|---|---|
| `src/App.jsx` | Modify | Import `getSingularityStage`, compute stage, add `corruption-stage-N` class to `.app` div |
| `src/styles.css` | Modify | All corruption CSS rules for stages 2-5 |

---

## 4. Design Principles

- **Playability first** — effects never obscure buttons, text, or game-critical UI
- **CSS only** — no JavaScript timers, no canvas manipulation, no performance impact
- **Progressive** — each stage adds to previous, never removes
- **Reversible** — if stage drops (e.g., dragons lost to fusion), corruption decreases
- **Atmospheric** — the goal is dread, not annoyance

---

## 5. Out of Scope

- Sound distortion (future — would need soundEngine changes)
- Per-screen unique corruption (all screens share the same effects via parent class)
- Corruption effects during battle animations (battle already has its own VFX)
- New art assets (everything is CSS filters and pseudo-elements)
