# Player Guidance & Onboarding

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: P2 — Every Fight Is a Readable Type-Puzzle (legibility/guidance)

## Summary

Player Guidance & Onboarding covers two distinct but related systems: the boot/title sequence that greets the player each session, and the persistent guidance chip displayed in the NavBar that always tells the player their highest-priority next action. The boot sequence is a typed terminal animation that plays in full for first-time players and renders instantly for returning players. The guidance chip is a single actionable button derived in real-time from save-state, surfacing the single most important next step across the entire game at any point in a run.

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `persistence, singularityProgress, campaignMap, shopItems, journalMilestones`

## Overview

When the game loads, the player lands on the Title Screen — a simulated terminal environment styled as the Astraeus hardware layer waking up. First-time players see a multi-phase animated boot sequence: system-status lines type out one by one, a glitch effect fires, then Professor Felix's portrait appears and he delivers an emergency briefing that changes as the Singularity stage advances. Returning players skip straight to the finished state with no wait. Either way the player ends on an "INITIALIZE\_SIMULATION.EXE" button that enters the game proper.

Once past the title, every screen in the game (except the Battle screen itself) shows a NavBar. The NavBar contains a "guidance chip" — a persistent yellow button that reads "NEXT / [ACTION\_LABEL]" and routes directly to whatever screen the system has determined is the player's highest-priority action. The chip is computed fresh from the current save each time the NavBar renders, so it always reflects the actual game state. When no actionable guidance exists the chip is hidden.

## Player Fantasy

The player should feel that the game always knows what they should do next without ever being lectured at. The terminal boot communicates urgency and mystery through the medium of the world's own failing hardware, so the tutorial is not a tutorial — it is the world explaining itself in its own voice. The guidance chip serves a different feeling: confident momentum. The player should never wonder "what do I do now?" The chip is always there, scanning the save state silently and offering the single right answer. When the chip updates its label — going from "FIRST BATTLE" to "FUSE" to "SINGULARITY" — the player understands their own progress without a progress screen.

Primary MDA aesthetics served: **Discovery** (the boot sequence delivers world-building through environmental interface); **Submission** (the chip removes decision paralysis so the player can stay in flow).

## Detailed Design

### Core Rules — Boot Sequence

1. On cold launch, `App.jsx` starts on `SCREENS.TITLE` and renders `TitleScreen`.
2. `TitleScreen` reads `save.introSeen` (a boolean, default `false`, stored at `dragonforge_save` in `localStorage`).
3. **First-time path** (`introSeen === false`): The component calls `runBootSequence()` which executes in three phases:
   - **Phase "boot"**: Iterates over `OPENING_BOOT_LINES` (7 lines, defined in `src/loreCanon.js`). Each line types character-by-character at 50 ms/char via `typeText()`, emits a terminal sound (`terminalType`), then commits the completed line to the visible list. If a line has a `status` property, an additional 200 ms pause fires a sound (`terminalOk`, `terminalWarning`, or `terminalFail`) and appends a coloured status badge.
   - **Phase "glitch"**: A 300 ms CSS glitch class (`terminal-glitch`) fires with the `terminalGlitch` sound.
   - **Phase "felix"**: Three separator lines are appended, the Felix portrait becomes visible, and the current `TERMINAL_DIALOGUE[stage]` lines type at 40 ms/char. The stage is derived from `getSingularityStage(save)` at render time.
   - On completion, `showButton` becomes `true`, revealing the `INITIALIZE_SIMULATION.EXE` button.
4. **Returning player path** (`introSeen === true`): The component sets `skippedRef.current = true` before `runBootSequence()` has a chance to animate. All lines are rendered immediately in their final state; the Felix portrait and button are shown without delay. The comment in `TitleScreen.jsx:123` explains the intent: "Returning players have already seen the boot wall — render it instantly, skip the ~10s typing."
5. **Skip behaviour**: Clicking or pressing Enter/Space anywhere on the terminal screen during boot sets `skippedRef.current = true`. On the next loop iteration any in-progress `typeText()` call returns early and the sequence jumps to the end state. This is a "click to skip" pattern made visible by a persistent hint label at the bottom of the screen during animation phases.
6. **`introSeen` is written**: When the player clicks `INITIALIZE_SIMULATION.EXE`, `markIntroSeen()` is called (`src/persistence.js:284`), which sets `save.introSeen = true` and writes to `localStorage`. This is a one-way flag; it is never reset except by `resetSave()` (full wipe). `migrateSave()` retroactively sets `introSeen = true` for any save where a dragon is already owned (`persistence.js:106`), covering players who existed before the flag was added.
7. **Music**: `handleClick` on the terminal fires `playMusic('opening')` to satisfy browser autoplay policy (requires a user gesture). `handleStart` fires `playSound('buttonClick')` then hands off to `App.handleStartGame`, which plays `hatchery` music and navigates to the Hatchery screen.

### Core Rules — Guidance Chip

1. `getPlayerGuidance(save)` (`src/playerGuidance.js:9`) is called once per NavBar render. It receives the full `save` object and returns either `null` or an object `{ target, action, title }`.
2. The function evaluates conditions in strict priority order (first match wins):

   | Priority | Condition | target | action |
   |----------|-----------|--------|--------|
   | 1 | `save.mirrorAdminDefeated === true` | `journal` | `ARCHIVE COMPLETE` |
   | 2 | `save.singularityComplete === true` and fragments remain | `singularity` | `FRAGMENTS N/7` |
   | 2a | `save.singularityComplete === true` and all 7 fragments collected | `singularity` | `MIRROR ADMIN` |
   | 3 | No owned dragons | `hatchery` | `FREE PULL` |
   | 4 | No defeated NPCs and `battlesLost > 0` | `map` | `RETRY` |
   | 5 | No defeated NPCs and `battlesLost === 0` | `map` | `FIRST BATTLE` |
   | 6 | `ownedDragons.length >= 1` AND `defeatedNpcs.length >= 3` AND `skye.wrenchTier < 2` | `forge` | `VISIT FORGE` |
   | 7 | `ownedDragons.length >= 2` AND any owned dragon at level >= 10 | `fusion` | `FUSE` |
   | 8 | Singularity unlocked AND not complete AND no Singularity defeats yet | `singularity` | `SINGULARITY` |
   | 9 | Any `BUY_ITEMS` entry is affordable OR any `FORGE_RECIPES` entry is forgeable | `shop` | `SPEND REWARDS` |
   | 10 | `getAvailableCampaignNodes(save).length > 0` | `map` | `CONTINUE` |
   | 11 | None of the above | (returns `null` — chip hidden) |

3. Fragment count for priority 2: `remaining = 7 - (save.flags.fragmentsUnlocked || []).length`. The action label is `FRAGMENTS N/7` where N is the count already collected. At 7/7 the action switches to `MIRROR ADMIN`.
4. The chip is rendered in `NavBar.jsx:99-108`. It is a `<button>` with class `guidance-chip`. If `activeScreen === guidance.target` an `active` class is added (desaturated + dimmed, indicating the player is already on the suggested screen). The `title` attribute holds a one-sentence description shown on hover.
5. The chip label is two lines: the word "NEXT" in 5px font (upper dek), and the `action` string in 7px bold font (lower dek).
6. Clicking the chip calls `onNavigate(guidance.target)`, which routes through `App.handleNavigate` exactly as if the player had clicked the corresponding NavBar tab.
7. The chip does not appear on the Title Screen (NavBar is not rendered there) or during Battle (BattleScreen has its own layout with no NavBar).

### States and Transitions

The guidance chip has no internal state machine. It is a pure function of `save` evaluated on each render. The chip's "state" is entirely determined by which condition in `getPlayerGuidance` matches first.

The boot sequence has an internal phase string: `boot → glitch → felix → ready`. Phase is local component state and not persisted.

| Phase | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| `boot` | Component mounts AND `introSeen === false` | All `OPENING_BOOT_LINES` rendered OR `skippedRef` set | Types system-check lines one by one |
| `glitch` | `boot` phase completes | 300 ms timer | `terminal-glitch` CSS class applied; `terminalGlitch` sound |
| `felix` | `glitch` phase completes | All `TERMINAL_DIALOGUE[stage]` lines rendered OR `skippedRef` set | Felix portrait visible; dialogue types at 40 ms/char |
| `ready` | `felix` phase completes OR `introSeen === true` | Player clicks `INITIALIZE_SIMULATION.EXE` | Button visible; cursor hidden |

### Interactions with Other Systems

- **Persistence**: `introSeen` flag is read on mount and written on first play. `markIntroSeen()` is the only writer outside of `migrateSave()`.
- **SingularityProgress**: `getSingularityStage(save)` determines which `TERMINAL_DIALOGUE` variant Felix speaks on the title screen. `isSingularityUnlocked(save)` is called inside `getPlayerGuidance` to evaluate priority 8.
- **CampaignMap**: `getAvailableCampaignNodes(save)` is called for priority 10 guidance. If any nodes are available, the first one's `.label` is used in the `title` field of the chip.
- **ShopItems**: `BUY_ITEMS` and `FORGE_RECIPES` are iterated with `canAffordBuy` and `canForge` for priority 9 guidance.
- **JournalMilestones**: NavBar independently calls `checkMilestones(save)` to add a dot indicator on the JOURNAL tab when a milestone is newly claimable. This is parallel to, not part of, the guidance chip.
- **NavBar**: Hosts the guidance chip. Receives `save`, `activeScreen`, and `onNavigate` as props. Does not own guidance state.

## Formulas

### Fragment Guidance Label

```
remaining = 7 - fragments.length
action    = (remaining > 0) ? `FRAGMENTS ${fragments.length}/7` : 'MIRROR ADMIN'
title     = (remaining > 0) ? `${remaining} captain's log fragment${remaining !== 1 ? 's' : ''} remaining` : 'Confront the Mirror Admin'
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| `fragments` | array | length 0–7 | `save.flags.fragmentsUnlocked` | IDs of collected Captain's Log fragments |
| `remaining` | integer | 0–7 | calculated | Number of fragments not yet collected |

**Expected output**: `action` is one of `FRAGMENTS 0/7` through `FRAGMENTS 6/7`, or `MIRROR ADMIN` when all 7 are collected.

### Boot Line Delay Budget

There are no player-facing number formulas — the boot sequence is time-based. Values are constants in `loreCanon.js`:

| Parameter | Value | Role |
|-----------|-------|------|
| `charDelay` — boot phase | 50 ms | Per-character typing speed for system lines |
| `charDelay` — felix phase | 40 ms | Per-character typing speed for Felix dialogue |
| Post-status pause | 200 ms | Extra pause before status badge renders |
| Glitch phase duration | 300 ms | Total duration of `terminal-glitch` state |
| Post-line delay | 600–950 ms | Per-line delay from `OPENING_BOOT_LINES[n].delay` |

The seven `OPENING_BOOT_LINES` entries have `delay` values of 600, 800, 950, 950, 900, 800, and 900 ms respectively (source: `src/loreCanon.js:28-35`). Total first-time boot duration (without skipping) is roughly 8–12 seconds depending on the Felix dialogue length for the current Singularity stage.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| `localStorage` is empty or corrupted | `loadSave()` returns `structuredClone(DEFAULT_SAVE)` which has `introSeen: false`; full boot plays | Graceful degradation; new-player experience is correct |
| Player has owned dragons but no `introSeen` flag (pre-flag save) | `migrateSave()` sets `introSeen = true`; boot renders instantly | Returning players are not punished by schema migration |
| Player clicks skip mid-glitch phase | `skippedRef` is set; at next Felix phase iteration all lines render at once | Skip is global — it cannot be applied selectively per phase |
| `singularityComplete` is true at title screen | `getSingularityStage` returns 0; Felix speaks Stage 0 dialogue | Post-game retains the calm "Dormant" Felix voice, not the crisis voice |
| All guidance priority conditions evaluate false | `getPlayerGuidance` returns `null`; chip is hidden | Occurs only when player has completed every available action; no guidance shown rather than a misleading one |
| Player is already on the guidance target screen | Chip renders with `active` CSS class (desaturated/dimmed); clicking it still navigates to the same screen (no-op feels acceptable) | Prevents the chip from feeling broken; player can still follow the chip for audio feedback |
| Two guidance conditions are simultaneously true | First match in priority order wins; lower priorities are ignored | Priority order is explicit in `getPlayerGuidance`; no tie-breaking is needed |
| Forge guidance: `wrenchTier >= 2` | Forge condition evaluates false; guidance falls through to the next priority | Forge upgrade is a one-time gate; after upgrade the chip stops pointing there |
| Singularity guidance: player has already started Singularity (`defeated.length > 0`) | Condition `!hasSingularityProgress` is false; chip does not point at Singularity | Once engaged, the Singularity needs no announcement; player knows it's there |
| Fragment count exceeds 7 (impossible via normal play, defensive) | `7 - fragments.length` is negative; label would be `FRAGMENTS 7/7`; the `remaining > 0` guard switches to `MIRROR ADMIN` | No degenerate label is produced |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| `src/persistence.js` | This depends on Persistence | Reads `save.introSeen`; calls `markIntroSeen()` on play start |
| `src/loreCanon.js` | This depends on Lore Canon | Reads `OPENING_BOOT_LINES` for the boot sequence |
| `src/felixDialogue.js` | This depends on Felix Dialogue | Reads `TERMINAL_DIALOGUE[stage]` for the Felix phase of boot |
| `src/singularityProgress.js` | This depends on Singularity Progress | Calls `getSingularityStage()` and `isSingularityUnlocked()` |
| `src/campaignMap.js` | This depends on Campaign Map | Calls `getAvailableCampaignNodes()` for priority-10 guidance |
| `src/shopItems.js` | This depends on Shop Items | Calls `canAffordBuy()` and `canForge()` for priority-9 guidance |
| `src/NavBar.jsx` | NavBar depends on this | Consumes `getPlayerGuidance(save)` return value; renders chip |
| `src/soundEngine.js` | This depends on Sound Engine | Boot sequence fires terminal sounds and music on user gesture |
| `design/gdd/narrative-and-lore.md` | Rule dependency | Felix dialogue content and fragment system described there |
| `design/gdd/forge-skye.md` | Rule dependency | Wrench tier values and upgrade gating used in priority-6 guidance |
| `design/gdd/singularity-endgame.md` | Rule dependency | Singularity unlock condition (`protocol_vulture` defeat) |
| `design/gdd/campaign-map.md` | Rule dependency | Campaign node availability logic |
| `design/gdd/shop-and-crafting.md` | Rule dependency | Shop affordability checks |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Category | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|----------|-------------------|-------------------|
| Boot `charDelay` (system lines) | 50 ms/char | 20–100 ms | Feel | Slower, more deliberate typewriter | Faster, less readable |
| Boot `charDelay` (Felix dialogue) | 40 ms/char | 20–80 ms | Feel | More dramatic pacing for Felix | Rushes Felix's voice |
| Post-status pause | 200 ms | 50–500 ms | Feel | More tension after each status badge | Snappier, less theatrical |
| Glitch phase duration | 300 ms | 100–800 ms | Feel | Longer disruption signal | Barely perceptible glitch |
| Per-line delay (`OPENING_BOOT_LINES[n].delay`) | 600–950 ms | 200–1500 ms | Feel | Longer pauses between lines | Boot feels rushed |
| Forge guidance threshold — `defeatedNpcs.length` | 3 | 1–5 | Gate | Delays Forge suggestion deeper into mid-game | Surfaces Forge earlier |
| Forge guidance threshold — `wrenchTier < 2` | `< 2` (i.e., Tier 1 only) | N/A (binary) | Gate | N/A | N/A |
| Fusion guidance — min level | 10 | 5–20 | Gate | Delays Fusion deeper into game | Surfaces Fusion earlier; reduces progression friction |
| Fragment count | 7 | Fixed (lore-driven) | Gate | More post-game content; longer endgame chase | Shorter post-Singularity arc |

All timing constants live in `src/loreCanon.js` (boot line delays) and directly in `src/TitleScreen.jsx` (char delays). Guidance thresholds live in `src/playerGuidance.js`. None are currently in external data files.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| System-check line types | Character-by-character terminal font rendering | `terminalType` per character | High |
| Status badge `OK` appears | Green `[OK]` badge | `terminalOk` | High |
| Status badge `WARNING` appears | Yellow `[WARNING]` badge | `terminalWarning` | High |
| Status badge `FAIL` appears | Red `[FAIL]` badge | `terminalFail` | High |
| Glitch phase | `terminal-glitch` CSS class (distortion effect) | `terminalGlitch` | High |
| Felix portrait appears | Pixel portrait image fades in | (none — visual only) | Medium |
| `INITIALIZE_SIMULATION.EXE` button appears | Button with terminal styling fades in | (none) | High |
| Player clicks button | N/A | `buttonClick` | Medium |
| Music on first click | N/A | `opening` music starts | High |
| Guidance chip visible | Yellow bordered button in NavBar | (none) | Medium |
| Player clicks guidance chip | Navigation to target screen | `navSwitch` (via `handleNavigate`) | Medium |

## Game Feel

N/A — turn-based browser game. This system has no frame-data, hitbox timing, input latency targets, or controller rumble. The "feel" of the boot sequence is governed by the per-character delay constants documented in Tuning Knobs above, and by browser rendering of CSS animations.

The intended feel for the guidance chip is: it should be immediately readable at a glance from any position in the NavBar. It should not feel like an intrusion or a nag. The `active` state (desaturation when already on the target screen) ensures the chip recedes when no action is needed without disappearing.

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Boot system-check lines | Title Screen, terminal output pane | Per-character (animated) or instant | Always on Title Screen |
| Felix portrait + dialogue | Title Screen, terminal output pane, below system lines | Per-character (animated) or instant | Always on Title Screen (below boot lines) |
| `INITIALIZE_SIMULATION.EXE` button | Title Screen, centered below Felix dialogue | Once, when boot completes | Only visible when phase === 'ready' |
| "Click to skip" hint | Title Screen, bottom center | Static | Visible during phases boot/glitch/felix only |
| Guidance chip | NavBar, right-side row alongside ticker and scraps | On each NavBar render (driven by `refreshSave()`) | Only when `getPlayerGuidance` returns non-null |
| Chip `active` state | Guidance chip | On each render | When `activeScreen === guidance.target` |
| Singularity ticker | NavBar, right of guidance chip | On each NavBar render | Always (stage 0 = "SYSTEM STATUS: NOMINAL") |
| DataScraps counter | NavBar, rightmost | On each NavBar render | Always |

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| `OPENING_BOOT_LINES` (7 entries) | `design/gdd/narrative-and-lore.md` | Boot line content and status values | Data dependency |
| `TERMINAL_DIALOGUE[stage]` (6 variants) | `design/gdd/narrative-and-lore.md` | Felix dialogue per Singularity stage | Data dependency |
| `save.introSeen` flag | `design/gdd/narrative-and-lore.md` (persistence schema) | `introSeen` boolean | Data dependency |
| `save.flags.fragmentsUnlocked` | `design/gdd/narrative-and-lore.md` | Fragment unlock array | Data dependency |
| `getSingularityStage(save)` | `design/gdd/singularity-endgame.md` (if exists) | Stage 0–5 computation | Data dependency |
| `isSingularityUnlocked(save)` | `design/gdd/singularity-endgame.md` | `protocol_vulture` defeat gate | Rule dependency |
| `getAvailableCampaignNodes(save)` | `design/gdd/campaign-map.md` | Available node list | Data dependency |
| Wrench tier gate (`skye.wrenchTier < 2`) | `design/gdd/forge-skye.md` | Wrench upgrade tiers | Rule dependency |
| Shop affordability (`canAffordBuy`, `canForge`) | `design/gdd/shop-and-crafting.md` | Item cost/ingredient checks | Rule dependency |

## Acceptance Criteria

**Functional — Boot Sequence**

- [ ] On a fresh save (`introSeen: false`), the Title Screen plays the full animated boot sequence before showing the start button.
- [ ] On a save with `introSeen: true`, the Title Screen renders all lines instantly with no animation delay.
- [ ] `migrateSave()` sets `introSeen: true` on any save where at least one dragon has `owned: true`.
- [ ] Clicking anywhere on the terminal screen during the boot animation (`phase !== 'ready'`) skips to the completed state.
- [ ] Pressing Enter or Space during boot triggers the same skip behaviour as a click.
- [ ] The Felix portrait image is visible below the system-check lines in both animated and instant modes.
- [ ] The Felix dialogue variant matches `getSingularityStage(save)` — stage 0 shows `OPENING_FELIX_LINES`, stage 5 shows the crisis variant.
- [ ] `markIntroSeen()` is called exactly once per first play-through (clicking `INITIALIZE_SIMULATION.EXE`).
- [ ] `playMusic('opening')` fires on the first user click (not on mount, satisfying browser autoplay policy).

**Functional — Guidance Chip**

- [ ] A save with no owned dragons shows `FREE PULL` pointing at `hatchery`.
- [ ] A save with one owned dragon and no defeated NPCs, no prior losses, shows `FIRST BATTLE` pointing at `map`.
- [ ] A save with one owned dragon, no defeated NPCs, and `battlesLost > 0` shows `RETRY` pointing at `map`.
- [ ] A save with one dragon at level 5, three defeated NPCs, and `skye.wrenchTier === 1` shows `VISIT FORGE` pointing at `forge`.
- [ ] A save with two owned dragons (one at level >= 10) shows `FUSE` pointing at `fusion`.
- [ ] A save with `singularityComplete: true` and 3/7 fragments shows `FRAGMENTS 3/7` pointing at `singularity`.
- [ ] A save with `singularityComplete: true` and all 7 fragments shows `MIRROR ADMIN` pointing at `singularity`.
- [ ] A save with `mirrorAdminDefeated: true` shows `ARCHIVE COMPLETE` pointing at `journal`, regardless of other state.
- [ ] The chip is hidden (`null` return) when no guidance condition is met.
- [ ] The chip renders with `active` CSS class when `activeScreen === guidance.target`.
- [ ] The shop chip (`SPEND REWARDS`) appears only when at least one item is actually affordable; it does not appear when the player has scraps but nothing to buy.

**Experiential**

- [ ] First-time players complete the boot sequence without confusion about what to do next (the `INITIALIZE_SIMULATION.EXE` button is unambiguous).
- [ ] Returning players experience no boot delay (renders instantly on reload).
- [ ] The guidance chip updates correctly after each battle, hatch, forge action, or shop purchase without requiring a page reload.
- [ ] No playtester reports feeling lost about what to do next during the first five minutes of play.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should the boot sequence play again on New Game+ (`ngPlus > 0`)? Currently `introSeen` is not reset by `applyNewGamePlus`, so it does not. | Game Designer | — | The current behaviour (instant on NG+) is intentional per `applyNewGamePlus` in `persistence.js:424`, which does not touch `introSeen`. Document only; no change needed unless narrative-director requests a NG+ variant. |
| Guidance chip does not cover the Stats or Settings screens — is this intentional? | Game Designer | — | No guidance points at Stats or Settings; these are pull-discovery-only. Consistent with current design; low priority to revisit. |
