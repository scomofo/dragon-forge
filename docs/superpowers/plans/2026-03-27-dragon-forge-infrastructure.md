# Infrastructure: CSS Split + Responsive + Accessibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the monolithic styles.css into per-screen modules, add responsive breakpoints for tablet/mobile, and add keyboard navigation to all interactive elements.

**Architecture:** CSS split first (mechanical reorganization, zero functional change), then responsive queries added to each new file, then keyboard/focus styles added to components + CSS. Each step is independently verifiable.

**Tech Stack:** CSS media queries, React keyboard event handlers

---

## File Map

| File | Responsibility |
|---|---|
| `src/styles/base.css` | Reset, body, .app, CRT overlay, pixelated, panels, custom properties |
| `src/styles/nav.css` | NavBar, tabs, ticker, scraps |
| `src/styles/terminal.css` | TitleScreen boot sequence, Felix portrait, dialogue |
| `src/styles/battle.css` | BattleScreen, HP bars, moves, arena, sprites, VFX, damage numbers, results |
| `src/styles/hatchery.css` | Eggs, pulls, reveals, pull grid |
| `src/styles/select.css` | BattleSelectScreen cards, matchup indicator |
| `src/styles/fusion.css` | Fusion slots, preview, picker, animation |
| `src/styles/journal.css` | Journal grid, detail, milestones |
| `src/styles/singularity.css` | Singularity screen, boss cards, epilogue, corruption effects, void/shiny |
| `src/styles/components.css` | Shared: shiny effects, status indicators, action buttons, focus styles |
| `src/main.jsx` | Import all CSS files |

---

## Task 1: CSS Split

This is the biggest task — purely mechanical, zero functional change. Split styles.css into 10 files by section.

**Files:**
- Delete: `src/styles.css`
- Create: `src/styles/base.css`, `src/styles/nav.css`, `src/styles/terminal.css`, `src/styles/battle.css`, `src/styles/hatchery.css`, `src/styles/select.css`, `src/styles/fusion.css`, `src/styles/journal.css`, `src/styles/singularity.css`, `src/styles/components.css`
- Modify: `src/main.jsx`

- [ ] **Step 1: Read entire styles.css and split into files**

Read `src/styles.css` completely. Create each file with the appropriate section. Use the existing comment headers as guides:

**base.css** — Everything from start through `/* === UI PANELS === */` section, including:
- `:root` custom properties
- `*` reset
- `body` styles
- `.app` container
- CRT scanline overlay (`.app::after`)
- `.pixelated`
- `.felix-frame`
- `.panel`, `.panel-top`, `.panel-bottom`

**nav.css** — `/* === NAV BAR === */` section through `.nav-scraps`, plus `/* === SINGULARITY TICKER === */`

**terminal.css** — `/* === TERMINAL INTRO === */` through `.terminal-init-btn`

**battle.css** — `/* === ARENA === */`, `/* === HP BARS === */`, `/* === MOVE PANEL === */`, `/* === RESULT OVERLAYS === */`, plus all `.sprite-*` classes, `/* === VFX ATTACK EFFECTS === */`

**hatchery.css** — `/* === HATCHERY === */` through pull grid, egg sprites, egg animations, reveal badges

**select.css** — `/* === BATTLE SELECT === */` through matchup indicator

**fusion.css** — `/* === FUSION === */` through fusion animation

**journal.css** — `/* === JOURNAL SCREEN === */` through milestones

**singularity.css** — `/* === SINGULARITY SCREEN === */`, `/* === SINGULARITY CORRUPTION EFFECTS === */`, `/* === VOID DRAGON === */`

**components.css** — `/* === SHINY EFFECTS === */`, `/* === STATUS EFFECTS === */`, `.undiscovered-silhouette`, any shared utility classes

- [ ] **Step 2: Update main.jsx imports**

Replace `import './styles.css';` with:

```js
import './styles/base.css';
import './styles/components.css';
import './styles/nav.css';
import './styles/terminal.css';
import './styles/battle.css';
import './styles/hatchery.css';
import './styles/select.css';
import './styles/fusion.css';
import './styles/journal.css';
import './styles/singularity.css';
```

- [ ] **Step 3: Delete src/styles.css**

- [ ] **Step 4: Verify build — must look identical**

```bash
npm run build
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: split styles.css into 10 per-screen CSS modules

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Responsive Breakpoints

**Files:**
- Modify: `src/styles/base.css`
- Modify: `src/styles/battle.css`
- Modify: `src/styles/hatchery.css`
- Modify: `src/styles/select.css`
- Modify: `src/styles/fusion.css`
- Modify: `src/styles/journal.css`
- Modify: `src/styles/singularity.css`

- [ ] **Step 1: Add responsive rules to each CSS file**

Add `@media` queries at the end of each file. Two breakpoints: `max-width: 1024px` (tablet) and `max-width: 768px` (mobile).

**base.css** — append:
```css
@media (max-width: 768px) {
  body { font-size: 9px; }
}
```

**battle.css** — append:
```css
@media (max-width: 1024px) {
  .move-panel { gap: 4px; }
  .move-btn { padding: 8px 10px; font-size: 8px; }
}

@media (max-width: 768px) {
  .move-panel { flex-wrap: wrap; }
  .move-btn { padding: 6px 8px; font-size: 7px; flex: 1 1 40%; }
  .panel-top { flex-direction: column; gap: 4px; }
  .hp-bar-container { min-width: unset; }
  .arena-sprites { padding: 0 8px; }
}
```

**hatchery.css** — append:
```css
@media (max-width: 768px) {
  .pull-grid { grid-template-columns: repeat(3, 1fr); }
  .hatchery-buttons { flex-direction: column; gap: 6px; }
}
```

**select.css** — append:
```css
@media (max-width: 768px) {
  .select-screen { flex-direction: column; }
  .select-panel { width: 100%; max-height: 40vh; }
  .select-card { gap: 8px; }
}
```

**fusion.css** — append:
```css
@media (max-width: 768px) {
  .fusion-parents { flex-direction: column; gap: 8px; }
  .fusion-dragon-picker { grid-template-columns: repeat(2, 1fr); }
}
```

**journal.css** — append:
```css
@media (max-width: 768px) {
  .journal-layout { flex-direction: column; }
  .journal-grid-panel { width: 100%; }
  .journal-detail { width: 100%; max-height: 50vh; }
  .journal-grid { grid-template-columns: repeat(3, 1fr); }
}
```

**singularity.css** — append:
```css
@media (max-width: 768px) {
  .singularity-layout { flex-direction: column; }
  .singularity-boss-list { width: 100%; flex-direction: row; overflow-x: auto; gap: 6px; }
  .singularity-boss-card { min-width: 140px; flex-shrink: 0; }
  .singularity-detail { width: 100%; }
}
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

- [ ] **Step 3: Commit**

```bash
git add src/styles/
git commit -m "feat: responsive breakpoints — tablet (1024px) and mobile (768px) layouts

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Keyboard Navigation + Focus Styles

**Files:**
- Modify: `src/styles/components.css`
- Modify: `src/BattleSelectScreen.jsx`
- Modify: `src/JournalScreen.jsx`
- Modify: `src/SingularityScreen.jsx`
- Modify: `src/FusionScreen.jsx`
- Modify: `src/TitleScreen.jsx`

- [ ] **Step 1: Add focus-visible styles to components.css**

Append to `src/styles/components.css`:

```css
/* === FOCUS & ACCESSIBILITY === */

*:focus-visible {
  outline: 2px solid #ff8844;
  outline-offset: 2px;
}

button:focus-visible {
  outline: 2px solid #ff8844;
  outline-offset: 2px;
  box-shadow: 0 0 8px rgba(255, 136, 68, 0.3);
}

.select-card:focus-visible,
.journal-card:focus-visible,
.singularity-boss-card:focus-visible,
.fusion-picker-card:focus-visible,
.fusion-slot:focus-visible,
.singularity-dragon-option:focus-visible {
  outline: 2px solid #ff8844;
  outline-offset: 2px;
  box-shadow: 0 0 8px rgba(255, 136, 68, 0.3);
}
```

- [ ] **Step 2: Add keyboard handlers to BattleSelectScreen**

In `src/BattleSelectScreen.jsx`, find every `<div` with an `onClick` that acts as a button (dragon cards, NPC cards). Add `tabIndex={0}` `role="button"` and `onKeyDown`:

For each interactive div, add:
```jsx
tabIndex={0}
role="button"
onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); /* same as onClick */ } }}
```

- [ ] **Step 3: Add keyboard handlers to JournalScreen**

Same pattern for journal dragon cards.

- [ ] **Step 4: Add keyboard handlers to SingularityScreen**

Same pattern for boss cards and dragon picker.

- [ ] **Step 5: Add keyboard handlers to FusionScreen**

Same pattern for fusion slots and picker cards.

- [ ] **Step 6: Add keyboard handler to TitleScreen**

Add `onKeyDown` to the terminal-screen div:
```jsx
onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') handleClick(); }}
```

- [ ] **Step 7: Verify build and tests**

```bash
npm test
npm run build
```

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: keyboard navigation + focus-visible styles for all interactive elements

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Final Verification

- [ ] **Step 1: Run tests**

```bash
npm test
```

- [ ] **Step 2: Build**

```bash
npm run build
```

- [ ] **Step 3: Manual checks**

- Resize browser to <768px — layouts should stack vertically
- Tab through screens — all cards and buttons should show orange focus ring
- Press Enter/Space on focused cards — should trigger click action

- [ ] **Step 4: Push**

```bash
git push origin master
```
