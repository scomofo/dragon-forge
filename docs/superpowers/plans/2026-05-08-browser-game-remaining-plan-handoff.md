# Dragon Forge Browser - Remaining Improvement Plan Handoff

> For the next agent: this handoff covers the browser build improvements that remain after the first implementation pass. The Forge hub refactor has its own handoff: `docs/superpowers/plans/2026-05-08-forge-hub-refactor-handoff.md`.

## Already Completed In The Current Pass

- Installed Playwright as a dev dependency.
- Ran `npm audit fix`; audit is clean.
- Fixed Vite base-path handling for music URLs through `getMusicTrackUrl()`.
- Fixed hatchery decoration URL routing through `assetUrl()`.
- Added `getTypeEffectivenessLabel()` in `src/battleEngine.js`.
- Updated battle move labels to derive from the real type chart.
- Added first-session guidance through `src/playerGuidance.js` and a `NEXT` nav chip.
- Added responsive nav behavior to avoid mobile overflow.
- Excluded `.claude/worktrees`, `dist`, Godot, and built-artifact folders from Vitest discovery.
- Improved title boot skip and avoided starting music before a user gesture.
- Verified:
  - `npm test`: 9 files, 106 tests passed
  - `npm run build`: passed
  - `npm audit`: 0 vulnerabilities
  - Playwright smoke: boot skip, hatchery, free pull guidance, first-battle guidance, map navigation, mobile overflow, no page errors

## Remaining Goal

Move the browser build from "feature-complete design lab" to a cleaner, more legible player slice. Focus on clarity, pacing, asset consistency, and repeatable QA. Do not expand scope into a full new game mode unless the current loop first becomes easier to understand and test.

## Workstream 1: First-Session Flow

Current guidance is intentionally small: free pull -> first battle -> spend rewards. Make it richer without becoming a tutorial wall.

- [ ] Add tests for guidance states beyond the first three steps:
  - enough dragons/level for Fusion
  - Singularity unlocked
  - no immediate guidance needed
- [ ] Add contextual microcopy on target screens:
  - Hatchery: why the first pull matters.
  - Campaign Map: why Signal Breach is the first battle.
  - Shop/Forge: what scraps and cores can do.
- [ ] Consider a lightweight "objective completed" toast when guidance advances.
- [ ] Make guidance dismissible only if it becomes annoying in playtest; default should guide new players.

Acceptance:

- New player can understand the next meaningful action without reading docs.
- Guidance does not block interaction.
- Existing tutorial overlay does not duplicate or contradict guidance.

## Workstream 2: Battle Clarity And Decision Quality

The battle presentation is strong, but decision support can get sharper.

- [ ] Extend `getTypeEffectivenessLabel()` tests for every non-neutral element pair that is 2x or 0.5x.
- [ ] Add a battle UI helper for status move copy:
  - status name
  - duration
  - rough chance, if shown
  - effect summary
- [ ] Surface status info in move buttons without overflowing:
  - examples: `BURN 30%`, `FREEZE 30%`, `BLIND 30%`
- [ ] Add enemy intent hinting in a restrained way:
  - show enemy move elements as already done
  - optionally show "likely: stone / basic" after the AI chooses but before animation only if it helps readability
- [ ] Re-check battle log position on mobile after any UI changes.

Acceptance:

- The player can tell why a move is good, resisted, risky, or status-oriented.
- Labels always match battle engine math.
- Mobile battle UI has no overlap between log, edge chip, and move grid.

## Workstream 3: Reward And Progression Pacing

The systems exist, but the early progression should feel deliberate.

- [ ] Simulate the first 10-20 minutes with deterministic save fixtures:
  - first pull
  - first campaign battle
  - two to four repeat battles
  - first shop spend
  - first dragon reaching level thresholds
- [ ] Audit XP and scraps rewards:
  - `src/gameData.js` NPC rewards
  - `src/battleEngine.js` XP formula
  - `src/shopItems.js` prices and core requirements
- [ ] Decide target time-to-fusion:
  - recommended: the first fusion should feel reachable after a short session, not after a long grind.
- [ ] Add tests for reward calculations if tuning formulas change.

Acceptance:

- The first upgrade purchase is reachable soon after first battle.
- Level 10/fusion path is visible and not mysterious.
- Repeat battles are rewarding without trivializing bosses.

## Workstream 4: Responsive And Accessibility QA

Initial mobile nav overflow is addressed, but full responsive QA remains.

- [ ] Add a Playwright smoke script under a clear path, for example `scripts/playtest-smoke.mjs`.
- [ ] Cover these viewports:
  - desktop 1440x900
  - tablet 900x700
  - mobile 390x844
- [ ] Assertions:
  - no page errors
  - no horizontal overflow on main screens
  - nav usable
  - battle move buttons visible
  - campaign map selectable
  - result overlays fit
- [ ] Add screenshot capture to a gitignored folder such as `.playtest-artifacts/`.
- [ ] Add a package script:

```json
"playtest:smoke": "node scripts/playtest-smoke.mjs"
```

Acceptance:

- `npm run playtest:smoke` can be run after `npm run dev` or starts its own preview server.
- Failures print the screen/viewport that failed.
- Artifacts are not committed by default.

## Workstream 5: Asset And Content Consistency

The current asset mapping is good enough to run, but it still has placeholders and drift risks.

- [ ] Fix shadow stage 1 mapping in `src/gameData.js`.
  - Current browser data maps shadow stage 1 to `shadow_stage2.png`.
  - `handoff/dragons/shadow_stage1.png` exists; ensure public asset exists or copy it intentionally.
- [ ] Decide what Void Dragon should use before bespoke art exists.
  - If using shadow placeholder, label it as intentional in data comments or TODO.
- [ ] Reconcile `assets/`, `public/assets/`, and `handoff/`:
  - document which directory is source-of-truth for browser runtime
  - copy only intentional runtime files into `public/assets`
- [ ] Add a lightweight asset manifest test:
  - every sprite URL referenced by `gameData.js`, `singularityBosses.js`, and CSS dynamic helpers exists under `public/` after applying `assetUrl`.
- [ ] Update `TODO.md` art-generation section after asset cleanup.

Acceptance:

- No broken runtime asset URLs for dragons, NPCs, arenas, eggs, VFX, or music.
- Placeholder assets are explicit, not accidental.
- Asset source-of-truth is documented.

## Workstream 6: Sound And Autoplay Polish

The boot sequence no longer starts music before a gesture, but audio behavior should get a dedicated pass.

- [ ] Add tests for `getMusicTrackUrl()` aliases and unknown track handling.
- [ ] In browser smoke, listen for unexpected page errors. Autoplay warnings are acceptable only before first gesture if unavoidable; the preferred result is no autoplay warnings.
- [ ] Verify music transitions:
  - opening
  - hatchery
  - map
  - battle tense
  - battle intense
  - victory/defeat return
- [ ] Confirm mute/settings persistence after refresh.

Acceptance:

- Music URLs respect `/dragon-forge/` base.
- No music starts before a user gesture.
- Sound controls continue to work after screen transitions.

## Workstream 7: Documentation And Developer Workflow

- [ ] Add a short `docs/browser-playtest.md` with:
  - how to run dev server
  - how to run Playwright smoke
  - what screenshots are captured
  - known acceptable browser warnings, if any
- [ ] Update `CLAUDE.md` with the new Playwright smoke command once it exists.
- [ ] Keep `TODO.md` focused on player-facing remaining work, not stale completed tasks.

Acceptance:

- A new agent can run tests, build, audit, and browser smoke without rediscovering commands.
- Documentation distinguishes browser build from Godot runtime.

## Suggested Implementation Order

1. Add Playwright smoke script and package command.
2. Expand `playerGuidance` tests and guidance states.
3. Add battle status helper/tests and update move button display.
4. Run a first-20-minutes balance pass and tune rewards if needed.
5. Clean asset mappings and add manifest test.
6. Update docs and TODO.

## Verification Gate

Run before closing the branch:

```powershell
npm test
npm run build
npm audit
npm run playtest:smoke
```

Expected:

- Unit tests pass.
- Production build succeeds.
- Audit reports 0 vulnerabilities.
- Playwright smoke reports no page errors and no mobile horizontal overflow.

## Known Risks

- Some UI strings currently include mojibake in source output on Windows terminals. Avoid broad text rewrites unless intentionally fixing encoding.
- The opening terminal sequence has a lot of timed async UI. Browser tests should use explicit selectors and generous timeouts around the start button.
- The Forge hub may become the main navigation surface later; coordinate any guidance or nav changes with the Forge handoff.
