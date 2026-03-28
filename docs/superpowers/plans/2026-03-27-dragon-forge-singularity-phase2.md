# Singularity Phase 2: Corruption Effects Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add CSS-only visual corruption effects that intensify as the Singularity stage increases (2-5), creating an atmosphere of growing instability without impacting gameplay.

**Architecture:** A single `corruption-stage-N` class on the root `.app` div drives all effects via CSS descendant selectors. The existing CRT overlay (`app::after`) gets stage-based opacity overrides. A new `::before` pseudo-element provides static flash effects. All corruption rules cascade from the parent class.

**Tech Stack:** React 18, CSS animations/filters/pseudo-elements

---

## File Map

| File | Responsibility |
|---|---|
| `src/App.jsx` | Modify — import getSingularityStage, add corruption class to .app div |
| `src/styles.css` | Modify — all corruption CSS for stages 2-5 |

---

## Task 1: App.jsx — Corruption Stage Class

**Files:**
- Modify: `src/App.jsx`

- [ ] **Step 1: Add getSingularityStage import**

At the top of `src/App.jsx`, add:

```js
import { getSingularityStage } from './singularityProgress';
```

- [ ] **Step 2: Compute stage and add class to root div**

Inside the `App` function, after the `refreshSave` definition (line 24), add:

```js
  const stage = getSingularityStage(save);
```

Update the root div className on line 65 from:

```jsx
    <div className="app">
```

to:

```jsx
    <div className={`app${stage >= 2 ? ` corruption-stage-${stage}` : ''}`}>
```

- [ ] **Step 3: Verify build**

```bash
npm run build
```

- [ ] **Step 4: Commit**

```bash
git add src/App.jsx
git commit -m "feat: apply corruption-stage-N class to root .app based on Singularity stage

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Corruption CSS

**Files:**
- Modify: `src/styles.css`

- [ ] **Step 1: Add all corruption CSS to styles.css**

Append at the end of `src/styles.css`:

```css
/* === SINGULARITY CORRUPTION EFFECTS === */

/* --- Stage 2: First Signs --- */

.corruption-stage-2::after,
.corruption-stage-3::after,
.corruption-stage-4::after,
.corruption-stage-5::after {
  /* Override base CRT scanline opacity */
}

.corruption-stage-2::after {
  background: repeating-linear-gradient(
    0deg,
    rgba(0, 0, 0, 0.2) 0px,
    rgba(0, 0, 0, 0.2) 1px,
    transparent 1px,
    transparent 3px
  );
}

.corruption-stage-2 .nav-ticker {
  animation: tickerBlink 1.5s ease-in-out infinite, corruptionTickerJitter 10s linear infinite;
}

@keyframes corruptionTickerJitter {
  0%, 95%, 100% { transform: translateX(0); }
  96% { transform: translateX(-2px); }
  97% { transform: translateX(3px); }
  98% { transform: translateX(-1px); }
  99% { transform: translateX(1px); }
}

/* --- Stage 3: Growing Instability --- */

.corruption-stage-3::after {
  background: repeating-linear-gradient(
    0deg,
    rgba(0, 0, 0, 0.25) 0px,
    rgba(0, 0, 0, 0.25) 1px,
    transparent 1px,
    transparent 3px
  );
}

.corruption-stage-3 {
  box-shadow: inset 2px 0 0 rgba(255, 0, 0, 0.06), inset -2px 0 0 rgba(0, 255, 255, 0.06);
}

.corruption-stage-3 .nav-bar {
  animation: corruptionNavFlicker 12s linear infinite;
}

@keyframes corruptionNavFlicker {
  0%, 94%, 96%, 100% { border-bottom-color: #333; }
  95% { border-bottom-color: #cc2222; }
}

.corruption-stage-3 .nav-ticker {
  animation: tickerBlink 1.5s ease-in-out infinite, corruptionTickerJitter 6s linear infinite;
}

.corruption-stage-3 .journal-card,
.corruption-stage-3 .select-card {
  animation: corruptionCardGlitch 15s linear infinite;
}

@keyframes corruptionCardGlitch {
  0%, 96%, 98%, 100% { transform: translateX(0); }
  97% { transform: translateX(-1px); }
}

/* --- Stage 4: Critical --- */

.corruption-stage-4::after {
  background: repeating-linear-gradient(
    0deg,
    rgba(0, 0, 0, 0.3) 0px,
    rgba(0, 0, 0, 0.3) 1px,
    transparent 1px,
    transparent 3px
  );
}

.corruption-stage-4 {
  box-shadow: inset 3px 0 0 rgba(255, 0, 0, 0.1), inset -3px 0 0 rgba(0, 255, 255, 0.1);
}

/* Static flash via ::before (::after is CRT scanlines) */
.corruption-stage-4::before,
.corruption-stage-5::before {
  content: '';
  position: fixed;
  inset: 0;
  pointer-events: none;
  z-index: 9998;
  background: repeating-linear-gradient(
    0deg,
    rgba(255, 255, 255, 0.04) 0px,
    transparent 1px,
    transparent 2px
  );
  opacity: 0;
}

.corruption-stage-4::before {
  animation: corruptionStaticFlash 15s linear infinite;
}

@keyframes corruptionStaticFlash {
  0%, 97% { opacity: 0; }
  97.5% { opacity: 0.1; }
  98.5% { opacity: 0.05; }
  99% { opacity: 0; }
}

.corruption-stage-4 .nav-bar {
  animation: corruptionNavFlicker 8s linear infinite;
}

.corruption-stage-4 .nav-ticker {
  animation: tickerBlink 1s ease-in-out infinite, glitchJitter 0.3s infinite;
}

.corruption-stage-4 .terminal-felix-portrait img {
  filter: saturate(1.3);
  animation: corruptionFelixJitter 8s linear infinite;
}

@keyframes corruptionFelixJitter {
  0%, 93%, 95%, 100% { transform: skewX(0deg); }
  94% { transform: skewX(2deg); }
}

.corruption-stage-4 .arena {
  filter: hue-rotate(5deg);
}

/* --- Stage 5: Breach --- */

.corruption-stage-5::after {
  background: repeating-linear-gradient(
    0deg,
    rgba(0, 0, 0, 0.35) 0px,
    rgba(0, 0, 0, 0.35) 1px,
    transparent 1px,
    transparent 3px
  );
}

.corruption-stage-5 {
  box-shadow: inset 4px 0 0 rgba(255, 0, 0, 0.15), inset -4px 0 0 rgba(0, 255, 255, 0.15);
  animation: corruptionScreenShake 0.5s linear infinite;
}

@keyframes corruptionScreenShake {
  0% { transform: translate(0, 0); }
  25% { transform: translate(0.5px, -0.5px); }
  50% { transform: translate(-0.5px, 0.5px); }
  75% { transform: translate(0.5px, 0.5px); }
  100% { transform: translate(-0.5px, -0.5px); }
}

.corruption-stage-5::before {
  animation: corruptionStaticFlashFast 8s linear infinite;
}

@keyframes corruptionStaticFlashFast {
  0%, 95% { opacity: 0; }
  96% { opacity: 0.15; }
  97% { opacity: 0.05; }
  98% { opacity: 0.12; }
  99% { opacity: 0; }
}

.corruption-stage-5 .terminal-felix-portrait img {
  filter: saturate(2) contrast(1.3);
  animation: corruptionFelixHeavy 3s linear infinite;
}

@keyframes corruptionFelixHeavy {
  0%, 85%, 90%, 95%, 100% { transform: skewX(0deg); filter: saturate(2) contrast(1.3); }
  87% { transform: skewX(4deg); filter: saturate(2) contrast(1.3) hue-rotate(30deg); }
  92% { transform: skewX(-3deg); filter: saturate(2) contrast(1.3) hue-rotate(-20deg); }
}

.corruption-stage-5 .panel,
.corruption-stage-5 .nav-bar,
.corruption-stage-5 .journal-detail,
.corruption-stage-5 .journal-card {
  animation: corruptionBorderPulse 3s ease-in-out infinite;
}

@keyframes corruptionBorderPulse {
  0%, 100% { border-color: #333; }
  50% { border-color: #cc2222; }
}

.corruption-stage-5 .nav-ticker {
  animation: tickerBlink 0.8s ease-in-out infinite, glitchJitter 0.15s infinite;
}

.corruption-stage-5 .arena {
  filter: hue-rotate(15deg);
}

.corruption-stage-5 .journal-card,
.corruption-stage-5 .select-card {
  animation: corruptionCardGlitch 5s linear infinite, corruptionBorderPulse 3s ease-in-out infinite;
}
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add src/styles.css
git commit -m "feat: Singularity corruption CSS — progressive visual effects stages 2-5

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Final Verification

- [ ] **Step 1: Run tests**

```bash
npm test
```

Expected: All 70 tests pass.

- [ ] **Step 2: Run build**

```bash
npm run build
```

- [ ] **Step 3: Manual verification**

```bash
npm run dev
```

To test different stages, open browser console and manually set save state:

```js
// Test stage 3
let s = JSON.parse(localStorage.getItem('dragonforge_save'));
s.dragons.fire.owned = true;
s.dragons.ice.owned = true;
s.dragons.storm.owned = true;
s.dragons.stone.owned = true;
s.dragons.venom.owned = true;
s.dragons.shadow.owned = true;
localStorage.setItem('dragonforge_save', JSON.stringify(s));
// Refresh page
```

Verify per stage:
- Stage 2: Slightly heavier scanlines, ticker jitters occasionally
- Stage 3: Color aberration on edges, nav bar border flickers, cards glitch
- Stage 4: Static flash every ~15s, Felix portrait distorts, arena hue shifts, ticker jitters constantly
- Stage 5: Screen shakes subtly, heavy static, Felix heavily glitched, all borders pulse red

- [ ] **Step 4: Commit any tweaks**

```bash
git add -A
git commit -m "fix: corruption effects polish after testing

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

Skip if no adjustments needed.
