# Dragon Forge — Design Sprint, 2026-06-12 (D5)

## 1. Challenged assumptions — verdicts

| # | Assumption | Verdict | Core evidence |
|---|-----------|---------|---------------|
| A1 | The fragment acquisition path is now complete — every fragment can be obtained through normal gameplay | TRUE | `src/singularityBosses.js:20,39,58,72,144` — all 7 fragment IDs covered across 4 beatable bosses; MIRROR_ADMIN gated behind collection and awards none |
| A2 | The Credits/epilogue screen is correctly routed — Mirror Admin defeat always leads there | PARTIAL | `src/BattleScreen.jsx:1236,1244` renders MIRROR_ADMIN_EPILOGUE_LINES in-battle; `src/CreditsScreen.jsx:31` renders the same lines again — player sees epilogue twice |
| A3 | After Mirror Admin defeat, getSingularityStage returns 0 and corruption CSS clears | TRUE | `src/singularityProgress.js:13-14` returns 0 when singularityComplete; `src/App.jsx:153` only applies corruption class when stage >= 2 |
| A4 | The post-Mirror-Admin playerGuidance correctly reflects the game-complete state | PARTIAL | `src/playerGuidance.js:14-19` targets 'journal'; `src/CreditsScreen.jsx:48` routes 'Return to the Forge' to 'hatchery' — landing screen mismatches guidance destination |
| A5 | The MIRROR_ADMIN boss object has all required fields for BattleScreen to render it | TRUE | `src/singularityBosses.js:103-142` — all required top-level and phase fields present; `src/BattleScreen.jsx:96-115` phases-aware branching covers MIRROR_ADMIN correctly |
| A6 | The type chart is now fully balanced — no element has zero counters or is completely neutral | PARTIAL | `src/gameData.js:15` — void row is 1.0 against 7 of 8 elements, 2.0 only vs. light; lopsided compared to fire/storm/shadow which each have 2 weaknesses |
| A7 | The daily streak multiplier is correctly displayed (dailyStreak+1) on both BattleSelectScreen and the victory overlay | PARTIAL | `src/BattleScreen.jsx:1182-1184` shows `×{save.dailyStreak}` (raw pre-battle value); `src/dailyChallenge.js:61-65` applies save.dailyStreak+1 as actual multiplier — display is off-by-one |
| A8 | The repeat-win scrap penalty correctly handles edge cases (0 scraps, Mirror Admin replays) | TRUE | `src/BattleScreen.jsx:659-681` — zero-scraps guard present; Mirror Admin npcId never enters defeatedNpcs so isRepeatDefeat always false |
| A9 | The storm→void 2× and light↔stone neutral changes propagate correctly to the Godot type chart in game_data.gd | FALSE | `dragon-forge-godot/scripts/sim/game_data.gd:12` storm→void = 1.0 vs. `src/gameData.js:11` storm→void = 2.0; light element entirely absent from game_data.gd (7 elements vs. 8) |
| A10 | Level cap 50 is enforced on all write paths (level-up, fusion offspring level) | PARTIAL | `src/persistence.js:285-296` — fuseDragons() stores offspringLevel without clamping; latent trust gap if future caller passes >50 |
| A11 | The skip affordance is now prominent enough — center-bottom 14px is visible from frame 1 | PARTIAL | `src/TitleScreen.jsx:151` — color '#888' is below WCAG AA contrast on dark background; 14px at low contrast is insufficient prominence |
| A12 | The first-loss retry guidance correctly fires when battlesLost > 0 and defeatedNpcs = 0 | TRUE | `src/playerGuidance.js:42-48`, `src/BattleScreen.jsx:772`, `src/App.jsx:137` — data path is consistent end-to-end |
| A13 | The playerGuidance test suite covers the new retry guidance and all post-Sprint-4 states | FALSE | `src/playerGuidance.test.js:14-97` — no test for battlesLost > 0 / defeatedNpcs = [] retry branch; no tests for mirrorAdminDefeated, singularityComplete+fragments, or forge guidance branch |
| A14 | A brand-new player who loses their first battle will see actionable guidance, not a dead end | PARTIAL | `src/BattleScreen.jsx:1192-1227` defeat screen has only static Felix quote — RETRY guidance chip appears one screen after defeat, requiring player to navigate away first |
| A15 | The title screen skip logic correctly skips both 'boot' and 'felix' phases on click | PARTIAL | `src/TitleScreen.jsx:66-72,125-133` — 300ms 'glitch' phase window where click is silently swallowed and felix sequence runs in full |
| A16 | D4 eliminated the dual-save-file problem — only one save file is now written per session | TRUE | `dragon-forge-godot/scripts/sim/save_io.gd:7` — single SAVE_PATH; main.gd has no FileAccess calls; all screens route through SaveIO.flush() |
| A17 | All screens that previously called main.save_to_disk() now have a working save path via SaveIO.flush() | PARTIAL | `dragon-forge-godot/scripts/world/world_screen.gd:1-292` — no SaveIO.flush() call anywhere; world_screen mutations to _save are never persisted |
| A18 | The SaveIO.DEFAULT_SAVE in save_io.gd covers all keys that screens read via save.get() | TRUE | `dragon-forge-godot/scripts/sim/save_io.gd:10-41` — all keys read by hatchery_screen, battle_screen, and world_screen are present in DEFAULT_SAVE |
| A19 | The Godot type chart in game_data.gd matches the browser Sprint 4 changes (light↔stone neutral, storm→void 2×) | FALSE | `dragon-forge-godot/scripts/sim/game_data.gd:12,16` — storm→void = 1.0; light element absent entirely; both Sprint 4 changes missing from Godot sim |
| A20 | The world_screen.gd correctly reads from the save passed to setup() to restore encounter zone state | FALSE | `dragon-forge-godot/scripts/world/world_screen.gd:37-42,260-266` — setup() calls _refresh_zone_states() before _ready() builds _zones; iterates empty array; all zone state silently dropped on entry |

---

## 2. Convergent findings

1. **Godot type chart divergence (A9 and A19).** Both economy/XP audit and Godot D4 audit independently found that `game_data.gd` is missing the storm→void 2.0 multiplier and the light element entirely. The finding was filed with identical file/line references in both audits, confirming it is not a read artifact.

2. **playerGuidance post-credits destination mismatch (A4 and A14).** The endgame/fragment audit (A4) found that CreditsScreen routes to 'hatchery' while guidance targets 'journal'. The first-session audit (A14) found the defeat screen provides no in-context guidance — both converge on the same root pattern: guidance cards point to a destination the player is not automatically taken to, creating a directional gap between navigation and guidance.

---

## 3. Decisions

**D1 — Remove duplicate epilogue in CreditsScreen.** `BattleScreen.jsx` already renders `MIRROR_ADMIN_EPILOGUE_LINES` in the in-battle `PHASES.EPILOGUE` overlay. `CreditsScreen.jsx:31` should render a distinct post-credits message (e.g. a brief "simulation archived" note or a credits roll with contributor names) rather than repeating the same lines. The epilogue text belongs to the battle climax; the credits screen should be its own beat. (A2)

**D2 — Align CreditsScreen return destination with playerGuidance target.** `CreditsScreen.jsx:48` routes 'Return to the Forge' to 'hatchery'. `playerGuidance.js:14-19` directs the player to 'journal'. Change the CreditsScreen button destination to 'journal' so the player lands where the guidance card points. (A4)

**D3 — Add at least 2 offensive targets to void element.** Void currently has a 2.0 multiplier only against light, making it near-useless offensively. Add void→stone 2.0 (thematically: void erodes solid form) and void→shadow 0.5 (shadow is at home in the void) to give void players two viable offensive matchups without making void overpowered. Update `src/gameData.js` void row accordingly. (A6)

**D4 — Fix victory overlay streak display to show save.dailyStreak+1.** `BattleScreen.jsx:1182-1184` displays `×{save.dailyStreak}` but the multiplier applied by `dailyChallenge.js:61-65` is `save.dailyStreak + 1`. Change the overlay label to `×{(save.dailyStreak || 0) + 1}` to match the actual multiplier semantics. (A7)

**D5 — Sync Godot game_data.gd type chart with Sprint 4 browser state.** Two changes are required: (1) update `storm.void` from 1.0 to 2.0 in `game_data.gd`; (2) add the `light` element row and column to `ELEMENTS` and `TYPE_CHART` matching `src/gameData.js` — light is neutral 1.0 against all elements except void→light 2.0 and light→void 0.5 (or whatever the browser chart specifies). (A9, A19)

**D6 — Add clamp guard in persistence.js fuseDragons().** Add `offspringLevel = min(offspringLevel, 50)` at the top of `fuseDragons()` before the dictionary is written to storage. This is a defensive write-path guard against future callers. (A10)

**D7 — Increase skip hint contrast on TitleScreen.** Change color from `'#888'` to `'#aaa'` or `'#bbb'` on `TitleScreen.jsx:151`, and consider bumping font size to 15-16px. Aim for at least 3:1 contrast ratio against the terminal background (`#0a0a0a` or similar). (A11)

**D8 — Add playerGuidance tests for all post-Sprint-4 branches.** Add tests to `src/playerGuidance.test.js` covering: (1) `battlesLost > 0` + `defeatedNpcs = []` → action 'RETRY'; (2) `mirrorAdminDefeated: true` → target 'journal'; (3) `singularityComplete: true` + fragments present → appropriate target; (4) the forge guidance branch (lines 65-73). (A13)

**D9 — Show dynamic guidance on the defeat screen itself.** Add a guidance line or next-step hint directly on the `BattleScreen` defeat overlay (`BattleScreen.jsx:1192-1227`) rather than requiring the player to click TRY AGAIN and navigate away before seeing the chip. Even a static "Head to the map to try a different dragon" line next to the Felix quote closes the dead-zone. (A14)

**D10 — Close the 300ms glitch-phase skip dead zone in TitleScreen.** In `handleClick` (`TitleScreen.jsx:125-133`), add `phase === 'glitch'` as a third condition that sets `skippedRef.current = true`. This ensures a click during the glitch transition is not silently dropped and the felix sequence is correctly bypassed. (A15)

**D11 — Add SaveIO.flush() to world_screen.gd.** Add a `_write_save()` method to `world_screen.gd` that calls `SaveIO.flush(_save)`, and invoke it at any point where world_screen mutates `_save` (e.g. encounter defeat, boss gate open, mission flag set) before emitting navigate. This prevents silent data loss if world_screen state is extended. (A17)

**D12 — Fix world_screen.gd zone state restoration ordering.** Move the `_refresh_zone_states()` call in `setup()` from its current position (line 42, before `_ready()` builds `_zones`) to the end of `_build_world()` in `_ready()`, after `_build_encounter_zones()` populates `_zones`. Alternatively, call `_refresh_zone_states()` at the end of `_ready()`. This ensures defeated/boss-flag visual state is correctly applied on entry. (A20)

---

## 4. Prioritized backlog

### Sprint 5 — Browser polish and correctness

| Item | Change | Files |
|------|--------|-------|
| D1 — Credits epilogue dedup | Replace repeated MIRROR_ADMIN_EPILOGUE_LINES in CreditsScreen with distinct credits/archive content | `src/CreditsScreen.jsx` |
| D2 — Credits return destination | Change 'Return to the Forge' route from 'hatchery' to 'journal' | `src/CreditsScreen.jsx:48` |
| D4 — Streak display off-by-one | Victory overlay: `×{save.dailyStreak}` → `×{(save.dailyStreak \|\| 0) + 1}` | `src/BattleScreen.jsx:1184` |
| D7 — Skip hint contrast | Color '#888' → '#bbb', font-size 14 → 16px | `src/TitleScreen.jsx:151` |
| D9 — Defeat screen guidance | Add static next-step hint to defeat overlay alongside Felix quote | `src/BattleScreen.jsx:1192-1227` |
| D10 — Glitch-phase skip gap | Add `phase === 'glitch'` to handleClick skip conditions | `src/TitleScreen.jsx:125-133` |
| D8 — playerGuidance test coverage | Add 4 missing test cases for RETRY, mirrorAdminDefeated, singularityComplete, forge branch | `src/playerGuidance.test.js` |

### Sprint 6 — Balance and defensive hardening

| Item | Change | Files |
|------|--------|-------|
| D3 — Void offensive balance | Add void→stone 2.0, void→shadow 0.5 to type chart | `src/gameData.js` |
| D6 — fuseDragons level cap guard | Add `min(offspringLevel, 50)` clamp before write | `src/persistence.js` (~line 291) |

### Godot track — D5 / D6 sprint

| Item | Change | Files |
|------|--------|-------|
| D5 — Sync type chart | Update storm→void to 2.0; add light element row/column to ELEMENTS and TYPE_CHART | `dragon-forge-godot/scripts/sim/game_data.gd` |
| D11 — world_screen save flush | Add `_write_save()` → `SaveIO.flush(_save)` and call on all save mutations | `dragon-forge-godot/scripts/world/world_screen.gd` |
| D12 — Zone state restore ordering | Move `_refresh_zone_states()` call to after `_build_encounter_zones()` in `_ready()` | `dragon-forge-godot/scripts/world/world_screen.gd` |

---

## 5. Open questions

1. **D1 — What should the Credits screen show instead of a repeated epilogue?** Is this intended to be a traditional credits roll (contributor names, tools used), a lore epilogue written specifically for the post-battle cooldown, or both? The current structure has no contributor list in the codebase.

2. **D3 — Confirm void balance targets.** The proposed void→stone 2.0 and void→shadow 0.5 additions are a design suggestion. Scott should confirm whether these matchups fit the lore logic of the void element before implementation, and whether any offsetting resistances elsewhere in the chart are needed.

3. **D9 — Defeat screen guidance tone.** Should the next-step hint on the defeat screen be dynamic (driven by playerGuidance.js) or a static line? Dynamic requires wiring save context into BattleScreen's defeat render — currently BattleScreen receives save as a prop, so it is feasible, but it changes the screen's dependency surface.

4. **A10 — fuseDragons clamp: should over-cap fusions be a hard error or silently clamped?** D6 proposes a silent clamp. If over-cap values should never occur by design, an assertion/warning in dev mode might be preferable to silent correction in production.

5. **D5 (Godot light element) — Is the Godot build intended to ship the full 8-element system or a reduced 7-element set?** The light element was added to the browser build but the Godot sim was not updated. If the Godot overworld is expected to support light-element dragons and fights, the full sync (D5) is required. If the Godot build is a separate scope with a simplified element set, the divergence may be intentional and should be documented.

---

*Agent labels: fragment/endgame audit (A1–A5), economy/XP audit (A6–A10), first-session audit (A11–A15), Godot D4 audit (A16–A20).*