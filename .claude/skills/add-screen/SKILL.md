---
name: add-screen
description: Add a new screen to the Dragon Forge browser build with all required wiring — navigation, sound, save access, CSS module. Use when asked to add a new screen, menu, or game mode UI.
---

# Add a screen to the browser build

`src/App.jsx` is a screen switcher over a `screen` enum and a single `save` object. A screen missing any wiring step below will render but feel broken (silent nav, stale save data, or a battle that returns to the wrong place).

## Checklist
1. **Component:** `src/<Name>Screen.jsx` — a React shell that composes engine modules + sprites + VFX. Game logic goes in a pure `*Engine.js` (or existing engine) with a `.test.js` sibling, never in the JSX.
2. **Enum + switcher:** add the screen constant and the case in `App.jsx`'s switcher.
3. **Navigation:** route entry through `handleNavigate(target)`. Never set `screen` directly from a screen component.
4. **Sound — required, easy to forget:** wire both `playSound(...)` and `playMusic(...)` from `src/soundEngine.js` into the `handleNavigate` case for the new screen. Every existing screen does this.
5. **Save data:** the screen receives the shared `save` prop. Mutations go through `src/persistence.js` helpers followed by `refreshSave()` — never mutate `save` in place. New persistent fields must be added to `DEFAULT_SAVE` *and* handled in `migrateSave` for existing players.
6. **Battles from this screen:** set `battleConfig` (via the `handleBegin*` pattern) and include `returnScreen` so `handleBattleEnd` comes back here.
7. **CSS:** new module under `src/styles/` (per-screen convention), with tablet + mobile breakpoints matching the existing modules.
8. **Accessibility/input:** keyboard nav (focus-visible + `onKeyDown`) and gamepad via `useGamepadController` if the screen is reachable in normal play.
9. **Singularity stages:** if the screen should react to endgame corruption, style against the root `corruption-stage-N` class rather than tracking stage locally.

## Verify
```powershell
npm test
npm run playtest:smoke   # screenshots to .playtest-artifacts/ — check the new screen at all 3 viewports
```
