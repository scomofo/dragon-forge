# Input & Gamepad

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: P5 — Earned Mastery, Never Trivialized (accessibility sub-pillar)

## Summary

Dragon Forge supports both mouse/keyboard and standard USB/Bluetooth gamepads in the browser. A polling loop reads the Web Gamepad API every animation frame and fires discrete press events to whichever screen is currently active. The system is a thin, stateless adapter — screens define their own response to directional and button events via a handler object passed to the `useGamepadController` hook.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `campaign-map.md`, `forge-skye.md`

## Overview

The input system has two layers. `src/gamepadInput.js` is a pure-function module: it reads a browser `Gamepad` snapshot, compares it to the previous frame's state, and returns only the buttons and axis directions that are newly pressed this frame (rising-edge detection). `src/useGamepadController.js` is a React hook that drives the poll loop via `requestAnimationFrame`, maintains the previous-frame snapshots in refs, and calls the screen's handler callbacks. Keyboard input is handled independently per-screen using native `keydown` event listeners; no shared keyboard abstraction exists. Mouse input is implicit — all interactive elements are standard HTML buttons and click targets.

## Player Fantasy

The player should never feel blocked by input. A controller should feel like a natural extension of menu navigation — moving a thumb across the d-pad or left stick scrolls through choices and a single button confirms. Keyboard users should be able to play without ever touching a mouse. The input layer is invisible infrastructure: when it works correctly the player thinks only about the game, not about how to control it.

## Detailed Design

### Core Rules

**Gamepad polling**

1. The hook starts a `requestAnimationFrame` poll loop on mount (when `enabled` is `true` and the browser environment is available). (`useGamepadController.js:46–49`)
2. Each frame, the first non-null gamepad returned by `navigator.getGamepads()` is treated as the primary controller. Only one controller is active at a time.
3. For each button in `GAMEPAD_BUTTONS`, if it is currently pressed AND was not pressed last frame, its name is added to the `buttons` fired list (rising-edge only — held buttons do not repeat). (`gamepadInput.js:24–28`)
4. The left analogue stick axes are read at indices 0 (X) and 1 (Y). Each axis is normalized through a deadzone function: values with absolute magnitude below 0.45 are treated as 0; values above the threshold are snapped to +1 or -1. (`gamepadInput.js:16–19`)
5. A stick direction fires as an `axisPresses` event only when the normalized value changes from the previous frame. This prevents repeat-fire while the stick is held. (`gamepadInput.js:35–36`)
6. D-pad directions (`DPAD_UP`, `DPAD_DOWN`, `DPAD_LEFT`, `DPAD_RIGHT`) are routed to `onDirectionPress`; all other buttons go to `onButtonPress`. Analogue stick presses also route to `onDirectionPress`. (`useGamepadController.js:32–38`)
7. When no gamepad is connected, previous-frame state is reset to empty each frame so reconnection produces fresh rising-edge events.

**Button index mapping** (`gamepadInput.js:1–14`)

| Constant | Browser Gamepad API Index | Physical Button (Standard Layout) |
|----------|--------------------------|-----------------------------------|
| A | 0 | South face (Xbox A / PS Cross) |
| B | 1 | East face (Xbox B / PS Circle) |
| X | 2 | West face (Xbox X / PS Square) |
| Y | 3 | North face (Xbox Y / PS Triangle) |
| LB | 4 | Left bumper / L1 |
| RB | 5 | Right bumper / R1 |
| SELECT | 8 | Back / Select / Share |
| START | 9 | Start / Options |
| DPAD_UP | 12 | D-pad up |
| DPAD_DOWN | 13 | D-pad down |
| DPAD_LEFT | 14 | D-pad left |
| DPAD_RIGHT | 15 | D-pad right |

**Keyboard input (per-screen)**

Each screen that supports keyboard play registers its own `keydown` listener in a `useEffect`. There is no global keyboard dispatcher. The two keyboard abstractions that exist live in `src/forge/forgeMovement.js`:

- Movement keys: Arrow keys and WASD map to directional movement. (`forgeMovement.js:9–18`)
- Interact keys: `Enter`, `Space`, `E`. (`forgeMovement.js:53–55`)
- Cancel keys: `Escape`, `Backspace`. (`forgeMovement.js:57–59`)

The Battle Screen and Campaign Map Screen handle their own keyboard events directly (no shared abstraction).

### States and Transitions

The gamepad hook has two states: **disconnected** and **connected**. The `connectedGamepad` value returned by the hook is `null` when no pad is present and `{ id, index }` when one is found. Screens may optionally read this value to render controller hint UI, but none currently do.

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Disconnected | No gamepad returned by `navigator.getGamepads()` | A gamepad appears | Poll loop continues; no events fired; previous-state refs reset each frame |
| Connected | First non-null gamepad found | Gamepad removed or becomes null | Rising-edge detection active; button and axis events fired to handlers |

### Interactions with Other Systems

**Battle Screen** (`src/BattleScreen.jsx:1184–1221`)
- D-pad / left stick: cycles `controllerFocusIndex` through the move button list (wraps). LEFT and UP decrement; RIGHT and DOWN increment.
- A / START: confirms the currently focused move. If focus is on the Defend slot, selects Defend. If focus is on the Auto slot and auto-battle is allowed, toggles auto-battle.
- B: immediately selects the Defend action regardless of focus position.
- Y: toggles auto-battle (only when `autoBattleAllowed` is true — disabled for boss, Singularity, Mirror Admin, Remnant, and Daily Challenge fights).
- Input is ignored while a turn is resolving (`isResolvingTurn` guard). (`BattleScreen.jsx:1186–1204`)

**Campaign Map Screen** (`src/CampaignMapScreen.jsx:129–146`)
- D-pad / left stick: moves selection between campaign nodes using spatial nearest-neighbour scoring (`findDirectionalNode`).
- A / START: auto-selects the first owned dragon if none is chosen, then begins the battle.
- B: navigates back to the battle select screen.
- LB: cycles the selected dragon one step backward through the owned dragon list.
- RB / Y: cycles the selected dragon one step forward through the owned dragon list.

**Forge Screen** (`src/ForgeScreen.jsx:152–161`, `src/forge/forgeMovement.js`)
- D-pad / left stick: moves the Skye avatar in the forge world by `FORGE_STEP` (2 percentage-point units) per press, clamped to `FORGE_BOUNDS` (x: 4–96, y: 20–92).
- A / X / START: triggers the Interact action (opens overlays, talks to Felix, etc.).
- B / SELECT: closes the current overlay if one is open.

## Formulas

### Axis Deadzone Normalization (`gamepadInput.js:16–19`)

```
if |value| < deadzone  →  return 0
else                   →  return sign(value)   (i.e., +1 or -1)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| value | float | -1.0 to +1.0 | Browser Gamepad API | Raw axis reading |
| deadzone | float | 0.0 to 1.0 | `gamepadInput.js:16` (default 0.45) | Minimum magnitude to register as input |

**Expected output**: 0, +1, or -1. The axis is binary after normalization — no analogue magnitude is preserved.

**Edge case**: If `value` is exactly ±0.45, the condition `Math.abs(value) < deadzone` is false, so the value registers as ±1. The deadzone is an exclusive lower bound.

### Directional Node Scoring (`gamepadInput.js:66–70`)

Used by Campaign Map to pick the best navigation target when moving in a cardinal direction.

```
score = primary + secondary * 1.85
```

| Variable | Description |
|----------|-------------|
| primary | Absolute distance along the axis of movement (dx for LEFT/RIGHT, dy for UP/DOWN) |
| secondary | Absolute distance along the perpendicular axis |
| 1.85 | Off-axis penalty weight — strongly prefers nodes aligned with the direction of travel |

Candidates are filtered to only those on the correct side of the selected node (dx < -1 for LEFT, dx > 1 for RIGHT, dy < -1 for UP, dy > 1 for DOWN). The node with the lowest score wins. If no candidates exist in the requested direction, the current selection is returned unchanged. (`gamepadInput.js:58–72`)

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| No gamepad ever connected | Poll loop runs every frame; no events fire; `connectedGamepad` stays null | Keyboard/mouse paths are fully independent |
| Gamepad disconnected mid-session | Next poll returns null; previous-state refs reset; handler callbacks stop firing | Avoids phantom inputs from stale state |
| Multiple gamepads connected | Only the first non-null gamepad in `navigator.getGamepads()` is used | Simplicity; game is single-player |
| Button held continuously | Only the first frame triggers an event (rising-edge detection) | Prevents unintended rapid-fire selection |
| Axis value exactly at deadzone boundary (±0.45) | Treated as active (exclusive lower bound) | Deadzone uses `< deadzone`; boundary registers |
| No directional node found in the requested direction | Current node remains selected | `findDirectionalNode` returns the existing selection as fallback |
| `enabled` prop is false | Hook returns early; no poll loop; no events | Allows screens to opt out of gamepad input entirely |
| `nodes` array is empty in `findDirectionalNode` | Returns `null` | Callers must guard the return value before using it |
| Auto-battle active and Y pressed | Toggle is processed even while turn is resolving (Y check precedes the `isResolvingTurn` guard) | Allows the player to cancel auto-battle immediately on seeing a bad move chosen |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Campaign Map | Campaign Map depends on Input | Consumes `onDirectionPress` / `onButtonPress` to navigate nodes and select dragons |
| Battle Screen | Battle Screen depends on Input | Consumes directional + button events to control move focus and confirm actions |
| Forge Screen | Forge Screen depends on Input | Consumes directional events for avatar movement and button events for interaction |
| Sound Engine (`soundEngine.js`) | Input indirectly triggers Sound | Screens call `playSound('uiHover')` / `playSound('uiConfirm')` inside input handlers |
| Browser Gamepad API | Input depends on Browser API | `navigator.getGamepads()` must be available; hook guards for `undefined` |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Location | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|----------|-------------------|-------------------|
| Axis deadzone | 0.45 | 0.1 – 0.7 | `gamepadInput.js:16` | Requires larger stick deflection to register; reduces drift noise | More sensitive to small stick movement; may cause drift on worn controllers |
| Off-axis navigation penalty | 1.85 | 1.0 – 3.0 | `gamepadInput.js:68` | More strictly prefers nodes directly ahead; diagonal nodes harder to reach | More permissive diagonal navigation; may select unintended targets |
> **Note**: Forge movement step (FORGE_STEP) is a tuning knob owned by design/gdd/forge-skye.md.
| Forge bounds (min/max x, y) | x: 4–96, y: 20–92 | Fixed by art layout | `forge/forgeMovement.js:2–7` | Wider roaming area | Tighter containment |

All knobs are feel-category tuning values. No external data file exists for these; they are constants in source files. If frequent tuning is expected, they should be moved to `assets/data/input-config.json`.

## Visual/Audio Requirements

N/A — the input system itself produces no visual or audio output. Screens call `playSound` inside their handler callbacks. No controller-connected/disconnected notification UI is currently implemented.

## Game Feel

This is a turn-based, sprite-based browser game. Frame-data concepts (startup frames, active frames, hit-stop, controller rumble) do not apply. The relevant feel properties are:

- **Responsiveness**: Input events fire on the same animation frame they are detected. There is no intentional delay.
- **Snap quality**: Navigation is discrete and binary — each press moves exactly one step or one node. There is no analogue acceleration.
- **Held-button behavior**: No repeat-fire. A held button fires once; the player must release and re-press for another event. This is appropriate for menu navigation where accidental over-scrolling is the primary failure mode.
- **Failure texture**: Pressing a direction with no valid navigation target silently does nothing (current selection unchanged). No error sound or visual feedback is produced. This is acceptable for the current implementation but may feel unresponsive in dense menus.

### Feel Acceptance Criteria

- [ ] D-pad navigation moves focus on the same frame as the physical press with no perceptible delay at 60 fps.
- [ ] Holding the d-pad does not cause focus to scroll through multiple items — each press produces exactly one movement.
- [ ] An analogue stick deflected past 45% magnitude registers as a directional press. A deflection below 45% produces no input.
- [ ] Releasing and re-pressing the stick from a held position registers as a new press.
- [ ] All interactive actions reachable by mouse are also reachable by d-pad + A on a standard Xbox or PlayStation layout controller.

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Controller connection state | Not currently displayed | — | No UI exists for this |
| Focused move button (Battle) | `controller-focus` CSS class on the focused button | Every frame (via React state) | When gamepad is connected and it is the player's turn |

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| Campaign Map node navigation | `design/gdd/campaign-map.md` | `CAMPAIGN_NODES` position data; `findDirectionalNode` node-graph shape | Data dependency |
| Battle move selection | `design/gdd/combat.md` | Player move list; turn phase state; auto-battle eligibility rules | State trigger |
| Forge avatar movement | `design/gdd/forge-skye.md` | Skye position, FORGE_BOUNDS, interact/overlay model | Rule dependency |

## Acceptance Criteria

- [ ] A standard USB gamepad connected before page load is detected on the first poll frame; button and axis events fire correctly.
- [ ] A gamepad connected after page load is detected within one animation frame (no page reload required).
- [ ] Disconnecting a gamepad mid-session produces no errors and no phantom inputs on reconnection.
- [ ] In BattleScreen, all player moves are reachable and selectable using only d-pad + A button.
- [ ] In CampaignMapScreen, all available campaign nodes are reachable using only d-pad directions; A begins the battle.
- [ ] In ForgeScreen, the Skye avatar moves to all map regions using only d-pad; A triggers all interact points.
- [ ] Pressing a direction with no valid navigation target in BattleScreen (index clamp) or CampaignMapScreen (no node in direction) produces no crash.
- [ ] Analogue stick input and d-pad input produce identical behavior in all screens.
- [ ] Keyboard-only play (WASD + Arrow + Enter/Space/E + Escape) is fully functional in ForgeScreen without a mouse.
- [ ] No hardcoded values in implementation — deadzone and step constants are defined as named exports, not inline literals.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should a controller-connected toast or indicator be added to the NavBar? | UX Designer | — | Unresolved |
| Should held-button repeat be added for Campaign Map node navigation (quality-of-life for large maps)? | Game Designer | — | Unresolved |
| Should tuning knobs be extracted to `assets/data/input-config.json` for runtime tuning? | Lead Programmer | — | Unresolved |
| Keyboard navigation in BattleScreen is not documented — does it exist? | Lead Programmer | — | No `keydown` listener was found in BattleScreen.jsx; keyboard may not be supported there |
