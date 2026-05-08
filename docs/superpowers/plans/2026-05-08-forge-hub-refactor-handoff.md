# Dragon Forge Browser - Forge Hub Refactor Handoff

> For the next agent: this handoff is for the live browser build under `src/`, not the Godot runtime. Preserve the current game feel while turning the Forge from a large prototype component into a maintainable hub.

## Current State

The Forge hub lives almost entirely in `src/ForgeScreen.jsx`. It already works as a playable pixel-space:

- Skye moves with WASD/arrows on a 0-100 coordinate plane.
- Stations are registered in `src/forgeData.js`.
- Proximity is derived by `findNearestStation(skyePos)`.
- Station overlays include Felix, Anvil/loadout, Console/logs, Hatchery Ring, Save Lantern, and Bulkhead.
- Save mutations happen through `src/persistence.js`.
- Art direction is warm forge/sci-fi: floor zones, cables, lantern, console green, hatchery cyan, and a bulkhead view that changes by act.

The main problem is that `ForgeScreen.jsx` mixes scene layout, movement, station rendering, overlay rendering, inline CSS, save bootstrapping, and UI behavior in one file. It is hard to iterate without accidental regressions.

## Goals

- Split Forge into small components and CSS without changing player-facing behavior in the first pass.
- Replace placeholder station behavior with real, clearly scoped interactions where the data already exists.
- Make Forge responsive, keyboard/gamepad-friendly, and easy to screenshot-test.
- Keep the hub low-chrome: the player should feel like they are in the Forge, not in an admin dashboard.

## Non-Goals

- Do not redesign the whole game loop.
- Do not port Forge to Godot in this task.
- Do not rewrite save schema unless a migration is added and tested.
- Do not add new lore arcs or new currencies.
- Do not remove the existing `NavBar` path until Forge is proven as the primary hub.

## Suggested File Split

- Create `src/forge/ForgeScene.jsx`
  - Owns scene composition, stations, Skye sprite, proximity prompt, and floor/background layers.
- Create `src/forge/ForgeOverlays.jsx`
  - Owns `AnvilOverlay`, `ConsoleOverlay`, `HatcheryRingOverlay`, `LanternOverlay`, `FelixOverlay`, and shared `OverlayShell`.
- Create `src/forge/forgeMovement.js`
  - Exports movement helpers such as `clampSkyePos`, `moveSkye`, and later action mapping.
- Create `src/styles/forge.css`
  - Move all inline Forge scene styling and overlay styling here.
- Keep `src/ForgeScreen.jsx`
  - Thin container that loads save-derived data, handles active overlay, and passes callbacks down.

## Task 1: Characterize Existing Forge Behavior

- [ ] Add tests for pure movement helpers before extracting them.
- [ ] Add a Playwright smoke script or test that verifies:
  - Forge loads from nav.
  - WASD or arrow movement changes Skye position.
  - Proximity prompt appears near Anvil, Console, Hatchery Ring, Save Lantern, Felix, and Bulkhead.
  - Enter/E opens an overlay when near a station.
  - Escape closes overlays.
- [ ] Capture desktop and mobile screenshots as artifacts during local review.

Suggested helper tests:

```js
expect(clampSkyePos({ x: -10, y: 200 })).toEqual({ x: 4, y: 92 });
expect(moveSkye({ x: 30, y: 75 }, 'up')).toEqual({ x: 30, y: 73 });
```

## Task 2: Extract Movement and Scene Components

- [ ] Move movement constants and coordinate clamping into `src/forge/forgeMovement.js`.
- [ ] Extract `SkyeSprite`, `ProximityHud`, `ControlsHint`, `Station`, and `StationSilhouette` into `src/forge/ForgeScene.jsx`.
- [ ] Keep `ForgeScreen` state names stable: `skyePos`, `overlay`, `felixLine`.
- [ ] Verify no behavior changes with tests and Playwright smoke.

Acceptance:

- `ForgeScreen.jsx` no longer contains station silhouette drawing or raw movement math.
- Movement still works with keyboard.
- Overlay opening/closing still works.

## Task 3: Move Inline Styling to CSS

- [ ] Create `src/styles/forge.css`.
- [ ] Import it from `src/main.jsx`.
- [ ] Move scene layers, station visuals, Skye, prompts, overlay shell, relic lists, log entries, and hatchery ring cards into CSS classes.
- [ ] Use CSS custom properties only for dynamic colors, positions, sizes, and act-specific palette values.
- [ ] Add responsive rules for:
  - mobile landscape/portrait
  - overlay width below 480px
  - proximity prompt wrapping
  - station labels staying inside viewport

Acceptance:

- Forge visual output remains recognizably the same.
- `ForgeScreen.jsx` has no large inline style objects except CSS variables.
- `npm run build` passes.
- Playwright mobile check reports no horizontal overflow.

## Task 4: Replace Placeholder Station Behavior

Work station-by-station. Avoid changing all overlays at once.

- [ ] Save Lantern
  - Current behavior only calls `refreshSave()`.
  - Decide actual scope: "rest" should probably clear temporary battle boosts/cooldowns only if those systems exist.
  - If no HP/capacitor save state exists yet, change copy to an honest save/checkpoint action and avoid implying mechanics that do not exist.
- [ ] Hatchery Ring
  - Fix stage calculation to use `getStageForLevel()` rather than `Math.ceil(level / 4)`.
  - Allow direct navigation to full Hatchery and optionally Journal for dragon management.
- [ ] Anvil
  - Keep relic equip/unequip, but make slot-cost rules real if `slotCost` can be greater than 1.
  - Surface locked/owned/equipped states more clearly.
- [ ] Console
  - Keep Captain's Log display but add clear locked/unlocked counts.
  - Consider link to Journal if Journal is the long-form archive.
- [ ] Bulkhead
  - Decide whether it should route to `map` instead of `hatchery`. If Forge becomes the hub, Bulkhead should probably mean "leave Forge for campaign/world".

Acceptance:

- Each changed station has at least one test or Playwright smoke assertion.
- Station text matches actual mechanics.
- No save mutation happens during render.

## Task 5: Input and Accessibility

- [ ] Add explicit Forge action mapping for keyboard/gamepad:
  - move up/down/left/right
  - interact
  - cancel/close
- [ ] Reuse `useGamepadController` if possible.
- [ ] Ensure overlay controls are reachable by keyboard.
- [ ] Prevent Skye movement while overlays are open.
- [ ] Add `aria-label` or button text for clickable station cards inside overlays.

Acceptance:

- Keyboard-only flow can open and close every overlay.
- Gamepad can move station focus or Skye, then interact.
- Focus does not disappear behind overlays.

## Task 6: Verification

Run:

```powershell
npm test
npm run build
npm audit
```

Then run a Playwright smoke pass:

- desktop Forge load
- movement
- all overlays open/close
- mobile viewport overflow check
- no page errors

## Known Risks

- `ForgeScreen.jsx` currently performs first-visit save mutations in `useEffect`. Keep that behavior but isolate it in a named helper so future migrations are visible.
- The Forge art is CSS-drawn. Moving styles too aggressively can shift layout, so use screenshots during refactor.
- If Bulkhead routing changes from Hatchery to Map, update player guidance expectations and smoke tests.

## Done Definition

- Forge is split into focused modules.
- Forge CSS lives in `src/styles/forge.css`.
- Placeholder copy is removed or made truthful.
- Keyboard and gamepad paths are covered.
- Full tests/build/audit pass.
- Browser smoke passes desktop and mobile with no page errors.
