# Dragon Forge — Design Sprint, 2026-06-11 (session 2)

**Method:** Four independent adversarial review agents (economy/XP systems, content completeness, first-session UX, endgame/Godot platform), each instructed to challenge a specific assumption against the actual code. All `file:line` citations drawn from agent report verbatim. Sprint 1 fixes (`ef56734`) and Sprint 2 items (`3c4e5ba` and `862a4a1`) treated as landed; agents challenged the next tier of claims.

**Headline:** Sprint 1 closed the most visible dead content (light dragon acquisition, type chart, milestones), but Sprint 2 introduced new trust gaps: the features that were "added" (Mirror Admin, daily streak, fragment system) are gated behind acquisition paths that do not exist in any reviewed file. The Godot build simultaneously has two incompatible save schemas and zero screens that call the engines it ported.

---

## 1. Challenged assumptions — verdicts

| # | Assumption | Verdict | Core evidence |
|---|---|---|---|
| A1 | "Level cap 50 is properly enforced across all XP/level code paths" | **PARTIAL** | Cap is enforced in 3 of 4 write paths; `calculateStatsForLevel` at `battleEngine.js:57` applies `(level - 1) * 3` with no ceiling; `fuseDragons` at `persistence.js:285-303` writes caller-supplied `offspringLevel` without clamping |
| A2 | "The repeat-win scrap penalty (×0.25) is correctly applied and meaningful" | **PARTIAL** | Math is correct at `BattleScreen.jsx:659-664`; Mirror Admin replays bypass `recordNpcDefeat` entirely (`BattleScreen.jsx:691`); `rawScraps < 4` yields `Math.floor(rawScraps * 0.25) = 0` silently |
| A3 | "The daily streak multiplier is wired end-to-end — save, apply, display" | **PARTIAL** | Save and apply are wired; display shows `save.dailyStreak` which is one lower than the effective multiplier (`BattleSelectScreen.jsx:131-132`); multiplier value is never shown to the player on the victory screen (`BattleScreen.jsx:1144-1182`) |
| A4 | "Light Dragon acquisition path is complete and crash-free" | **PARTIAL** | Post-Singularity grant via `markSingularityComplete` and migration backfill are correct; `gameData.js:315-320` rarity tiers do not include `light` so hatchery pull path is structurally blocked; migration threshold for `full_roster` is `>= 6` (`persistence.js:62-66`) but milestone check requires `>= 8` (`journalMilestones.js:28`) |
| A5 | "Mirror Admin TRUE FINAL fight is accessible to a regular player who completes the main game" | **FALSE** | `getBossStatus` requires all 7 fragment IDs in `save.flags.fragmentsUnlocked` (`singularityBosses.js:145-151`); `DEFAULT_SAVE` initializes it as `[]` (`persistence.js:33-34`); no reviewed file calls `unlockFragment` during normal gameplay; Mirror Admin is permanently locked for every new player |
| A6 | "The type chart is now balanced after Sprint 1 fixes" | **PARTIAL** | `stone→light = 1.0` while `light→stone = 0.5` — one-directional penalty with no reciprocal (`gameData.js:8-17`); `void` has no defensive weaknesses from 6 of 8 types and its only 2× target is light (`void→light = 2.0`), the one type that resists void (`light→void = 0.5`) |
| A7 | "The first session is compelling — not a lore wall, not a dead end at 0 scraps" | **PARTIAL** | Free pull is unconditional — confirmed (`HatcheryScreen.jsx:44-45`); skip affordance is 10px color `#555` bottom-right (`TitleScreen.jsx:151-154`); player who loses first battle earns 0 scraps, Shop tab stays invisible, guidance chip loops to "FIRST BATTLE" with no retry context (`playerGuidance.js:22-27`) |
| A8 | "The endgame has a meaningful payoff after beating the Mirror Admin" | **FALSE** | Win routes to `SingularityScreen` unchanged via `App.jsx:142-146`; `mirrorAdminDefeated` does not set `singularityComplete` so corruption CSS stays at stage 5; `getPlayerGuidance` returns `null` post-Mirror Admin (`playerGuidance.js:58-68`); Mirror Admin reuses Recursive Golem sprite (`singularityBosses.js:109-110`) |
| A9 | "The Godot save_io.gd unification is done and there is one save schema" | **FALSE** | Two parallel incompatible systems: Dictionary-based at `user://dragon_forge_save.json` (used by all screens) and Resource-based `SaveData` at `user://save.tres` (registered autoload, zero screens reference it); `SaveIO` is called by no screen or world script; schemas are structurally incompatible (no `hatchery_state`/`bestiary_defeated` in `save_data.gd`) |

---

## 2. Convergent findings (multiple agents, independently)

1. **Fragment acquisition is a phantom gate.** The Mirror Admin requires all 7 fragments (`singularityBosses.js:145-151`), `unlockFragment` exists in `persistence.js:348-356`, `DEFAULT_SAVE` initializes the array as empty, and no reviewed file populates it during gameplay. This appeared in both the content-completeness agent (A5) and the endgame agent (A8): the "TRUE FINAL" boss is a locked door with no key in the codebase.

2. **The endgame resolution never updates world state.** The endgame agent found that `mirrorAdminDefeated` does not trigger `singularityComplete` (A8, `App.jsx:142-146`), so corruption CSS stays at stage 5 after the "true ending." The content-completeness agent found separately that `getSingularityStage` returns 0 only on `singularityComplete` (`singularityProgress.js:14`), not on Mirror Admin defeat. Two agents, same structural gap: the game's win condition and its world-state signal are disconnected.

3. **Display lags behind applied values for every Sprint 2 economy feature.** The daily streak shows `save.dailyStreak` (one lower than the active multiplier, `BattleSelectScreen.jsx:131-132`); the victory screen shows raw `+{state.scrapsGained}` with no streak label (`BattleScreen.jsx:1144-1182`); the `full_roster` milestone shows as claimed at 6/8 dragons for migrated saves (`persistence.js:62-66` vs `journalMilestones.js:28`). Three independent display mismatches from two agents.

4. **The Godot build has two dead layers.** The save-schema agent found `save_io.gd` is a dead autoload (A9). The overworld agent found encounter zones are one-shot with no respawn logic, world state resets on every navigation, and the player always respawns at `PLAYER_START` (`world_screen.gd:17`). Both findings describe the same pattern: systems are scaffolded but not connected to the game loop.

---

## 3. Decisions

**D1 — Wire `mirrorAdminDefeated` to `singularityComplete` and add a post-win screen.** `handleSingularityBattleEnd` in `App.jsx:142-146` must call `markSingularityComplete()` when Mirror Admin is defeated, so corruption CSS resets, Felix dialogue updates to stage 0, and guidance resumes. A credits/epilogue screen is the highest-leverage payoff because it provides the observable world-state change the player currently cannot see, and it costs one new screen routed from `handleSingularityBattleEnd`. Without this, all narrative investment in the Mirror Admin arc is invisible.

**D2 — Add fragment acquisition to the normal game path.** The Mirror Admin gate requires 7 fragments but no content awards them. The cheapest correct fix is to award one fragment per Singularity boss defeat (7 bosses → 7 fragments), wiring `unlockFragment` into the existing `handleSingularityBattleEnd` / boss-defeat path. This closes the "locked door with no key" finding without new content and makes the Mirror Admin gating feel earned rather than arbitrary.

**D3 — Fix the three Sprint 2 display mismatches before Sprint 3 work begins.** The `full_roster` migration threshold (`persistence.js:62`) must match the milestone check (`journalMilestones.js:28`); the streak display on `BattleSelectScreen.jsx:131` must show `save.dailyStreak + 1` (the effective value); the victory screen must label streak-boosted rewards. These are 1-line fixes each, but leaving them ships player-visible lies about the economy features Sprint 2 just added.

**D4 — Godot: delete the Dictionary save schema and standardize on `save_io.gd`.** Two schemas writing to two files will silently diverge on every play session. `save_io.gd` has migration, versioning, and GUT tests; the `main.gd` Dictionary schema has none of those. Delete `DEFAULT_SAVE` from `main.gd`, update all `setup()` calls to receive `SaveIO.save`, and wire `SaveIO.flush()` at the point where `main.save_to_disk` is currently called (`battle_screen.gd:437-440`). The overworld one-shot encounter problem is a design decision (not a bug) and can stay for now, but the dual-schema problem actively corrupts save state.

---

## 4. Prioritized backlog

### Sprint 3 — Endgame wiring (~2 days)
| Item | Change | Files |
|---|---|---|
| Mirror Admin win → `singularityComplete` | Call `markSingularityComplete()` in `handleSingularityBattleEnd` when Mirror Admin defeated | `App.jsx:142-146`, `persistence.js` |
| Post-win credits/epilogue screen | New screen routed from `handleSingularityBattleEnd`; corruption CSS drops to 0 | `App.jsx`, new `CreditsScreen.jsx` |
| Fragment awards per boss defeat | Call `unlockFragment(bossId)` in the singularity boss-defeat path | `BattleScreen.jsx:691`, `persistence.js:348-356` |
| Post-Mirror Admin guidance | Add guidance branch for `mirrorAdminDefeated = true` state | `playerGuidance.js:58-68` |
| Streak display off-by-one | Show `save.dailyStreak + 1` on pre-battle card; label streak bonus on victory screen | `BattleSelectScreen.jsx:131-132`, `BattleScreen.jsx:1144-1182` |
| `full_roster` migration threshold | Change migration threshold from 6 to 8 to match milestone check | `persistence.js:62-66` |

### Sprint 4 — First session polish (~2 days)
| Item | Change | Files |
|---|---|---|
| Skip affordance visibility | Move click-to-skip hint to center-bottom; increase to 14px; visible from frame 1 | `TitleScreen.jsx:151-154` |
| First-loss retry guidance | After a lost battle with 0 scraps earned, guidance chip says "RETRY — you keep your dragon" | `playerGuidance.js:22-27` |
| Mirror Admin sprite | Commission or generate unique sprite; do not reuse Recursive Golem | `singularityBosses.js:109-110`, `assets/` |
| `light→stone` one-directional penalty | Decide: either `stone→light = 0.5` (symmetric resist) or `light→stone = 1.0` (remove penalty) | `gameData.js:8-17` |
| `void` defensive neutrality | Add one type with 2× effective against void (storm suggested) to create a counter | `gameData.js:8-17` |

### Godot track (parallel)
| Item | Change | Files |
|---|---|---|
| Delete Dictionary save schema | Remove `DEFAULT_SAVE` from `main.gd`; all screens use `SaveIO.save` | `main.gd:4-34` |
| Wire `SaveIO.flush()` | Replace `main.save_to_disk` calls with `SaveIO.flush()` | `battle_screen.gd:437-440` |
| Overworld re-encounter design call | Decide: zone respawn on timer, or infinite-battle mode per zone | `encounter_zone.gd:30-33`, `world_screen.gd` |

---

## 5. Open questions (product calls for Scott)

1. **Fragment acquisition design:** Awarding one fragment per Singularity boss is the simplest path (D2), but was the intent to scatter fragments as hidden collectibles in the overworld or as NPC drops? The answer determines whether this is a 1-hour web fix or a Godot feature.

2. **Mirror Admin as web or Godot content:** The true-final boss currently exists as a text boss in the browser build but has no sprite, no unique state change, and no credits screen. Is the polished Mirror Admin fight (`CreditsScreen`, unique art, world reset) a browser-build Sprint 3 item or is it the Godot build's narrative anchor? Doing both is possible but creates a fork in endgame canon.

3. **Corruption CSS stage reset:** After `singularityComplete`, should stage return to 0 ("Dormant") or to a new stage 6 ("Restored") with a distinct visual? The current code only has 0–5; adding stage 6 is a CSS-only change but signals a deliberate "post-game world" rather than a reset to the start state.

4. **Godot overworld loop design:** Encounter zones are currently one-shot. The differentiator gameplay loop requires repeatable encounters for XP grinding. Should defeated zones respawn on a timer, respawn on session start, or offer an "infinite battle" mode once cleared? This is the core design decision blocking the Godot track from having a real loop.

---
*Agent labels: XP/economy audit (A1–A3), content completeness audit (A4–A6), first-session + endgame UX audit (A7–A8), Godot platform audit (A9).*
