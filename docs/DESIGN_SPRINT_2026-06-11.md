# Dragon Forge — Design Sprint, 2026-06-11

**Method:** Four independent adversarial review agents (economy/progression, new-player experience, endgame/retention, platform strategy), each instructed to challenge a core assumption against the actual code. Key claims spot-verified against the repo before synthesis. All `file:line` references checked against `master` @ `d53d9bf`.

**Headline:** The game is *screen-complete* but not *design-complete*. Four independent reviews converged on the same diagnosis: every long-term system is half-wired — content with no acquisition path, currency with no late sinks, teases with no payoff, tested Godot engines with no callers. The good news is that almost every fix is a data edit, not a new system.

---

## 1. Challenged assumptions — verdicts

| # | Assumption | Verdict | Core evidence |
|---|---|---|---|
| A1 | "The game is balanced" | **False** | Scraps are an unbounded faucet (every NPC re-fightable at full reward, `BattleScreen.jsx:658`) with only bounded sinks; XP formula `baseXP * enemyLevel / playerLevel` (`battleEngine.js:52`) makes battling for XP strictly dominated by scrap-farming + dupe pulls (up to 5 XP/scrap via `hatcheryEngine.js:61`), and lets a L1 dragon hit ~L150 off one boss (no level cap, `persistence.js:142-152`) |
| A2 | "All eight elements are viable" | **False** | Type chart sums (`gameData.js:8-17`): stone 10.0 off / 7.0 def is strictly best at Uncommon; shadow 5.5 off / 11.5 def is strictly worst yet is the Rare-tier prize; void's only 2× (vs light) targets an element no enemy has; light takes 2× from void — the final boss |
| A3 | "Light Dragon shipped" | **False** | Art + stats + moves exist, but `light` is in no rarity tier (`gameData.js:314-319`), no fusion output, no core, no shop item — unobtainable. `migrateSave` backfills `void` but not `light` → legacy saves carry `dragons.light === undefined` (crash risk at `ShopScreen.jsx:198`). Battle card says "Pull from Hatchery", which can never succeed |
| A4 | "The first session is compelling" | **At risk** | ~45 s lore wall with an unsignposted click-to-skip (`TitleScreen.jsx`); free pull then instant 0-scrap dead end (rescue milestone worth 100 scraps is unannounced in the Journal); guidance chip jams on "SPEND REWARDS → SHOP" forever once scraps > 0 (`playerGuidance.js:28`); BATTLES tab exposes Lv.10–12 bosses to a Lv.1 dragon, unsorted |
| A5 | "Fusion is a core loop" | **Mostly false** | `stable` tier needs same-element parents but the save holds one dragon per element — unreachable; Stability Matrix (100 scraps + 3 cores) sets `inventory.stabilityBoost`, which **nothing reads** — a no-op purchase; stat payoff (`floor(avg×1.1)`) is ±1.7% at L50 for the cost of both parents; fusion also silently un-completes the collection (`persistence.js:252-253`) |
| A6 | "The endgame retains players" | **False** | The Singularity is 4 fights then a 5-line epilogue; post-game state is one boolean + a stats badge; daily challenge has no streak and pays 90–390 scraps into a dead economy; corruption stage stays at 3 forever after you "save" the world (`singularityProgress.js:14`) |
| A7 | "The story pays off" | **False** | Lore canon names the **Mirror Admin** as primary threat and the **Great Reset** as the stakes (`loreCanon.js:18-19`); the player never fights the Mirror Admin, the countdown is never resolved, and the epilogue tease ("I don't think it's gone forever") has no mechanical follow-through. `forgeData.js:216` references "Mirror Admin's Sanctum (Act IV)" — content that doesn't exist |
| A8 | "The Godot build is the RPG overworld spine" | **False today** | On disk, `dragon-forge-godot/scripts/` is `components/screens/sim/tests` — **no** `world/`, `battle/`, `dungeon/`, or `vfx/` folders (CLAUDE.md describes the archived layout, not this one). What exists is a lower-fidelity clone of the web menus. The differentiator (overworld) has zero lines of code |
| A9 | "The Godot sim is ported" | **Half-true, fully unwired** | `battle_engine.gd`, `fusion_engine.gd`, `hatchery_engine.gd`, `save_io.gd` are ported *and GUT-tested* — and **no screen calls any of them**. Screens use inline reimplementations (one-move combat, flat 50-scrap pulls, a second save schema in `main.gd`). Plus a live bug: battle XP is awarded to `save["dragon_id"]` (always `"fire"`), not the dragon that fought (`dragon_progression.gd:58-62`) |

## 2. Convergent findings (multiple agents, independently)

1. **Light Dragon** was flagged by all four agents: unobtainable (economy), advertised-but-impossible card copy (NPX), absent from every goal/milestone (retention), and already drifted out of the Godot build (platform). It is the single clearest symptom of "shipped art ≠ shipped feature".
2. **The economy has no late game.** Unbounded scrap income (economy) + nothing to buy after ~4,000 scraps (retention) + replayable Singularity bosses paying flat 1000/clear (retention) all describe the same hole from three sides.
3. **The game ends by accident.** Inverted difficulty (first fight hardest, final boss one-shot — economy) meets "epilogue then nothing" (retention) meets a story whose villain never appears (retention).
4. **Three unlock systems disagree:** `isSingularityUnlocked` (4 NPCs, excluding the campaign's own capstone boss), `playerGuidance` (`currentAct >= 3`), and the campaign map's "Singularity pressure reduced" reward text — no single source of truth.

## 3. Decisions

**D1 — Make the Light Dragon the post-Singularity reward.** One change resolves three independent findings: it gives the unobtainable dragon an acquisition path, gives `singularityComplete` a payoff beyond a badge, and cashes the epilogue's tease. Its type-chart weakness to void stops mattering (the void boss is already beaten when you earn it). Add `migrateSave` backfill for `light` regardless (crash risk).

**D2 — The web build is the live product *and* the balance lab; stop calling it feature-complete.** TODO.md's "only art remains" is contradicted by A1–A7. The fixes are cheap (data edits), high-leverage, and ship instantly via the existing Pages pipeline.

**D3 — Godot: freeze parity, build the differentiator.** Stop translating web content into JSON nothing loads. The slice that earns the Godot build's existence: one overworld zone (TileMap + CharacterBody2D dragon, walk/fly) → encounter triggers → battle using the *already-ported-and-tested* `battle_engine.gd` → hatchery as hub → one gated boss. Cut shop/forge/journal/stats/campaign-map/settings screens from the slice. Standardize on `save_io.gd` (it has migration and tests) and delete the `main.gd` JSON schema.

**D4 — Fix the documentation that misdescribes reality.** CLAUDE.md's Godot section describes `scripts/world|battle|dungeon/` (the archive's layout, not this tree) and `run-godot.ps1` points at a path that doesn't exist on this machine. Stale docs caused at least one agent-hour of confusion this sprint; they'll do the same to every future session.

## 4. Prioritized backlog

### Sprint 1 — Trust & dead content (data-only edits, ~1 day)
| Item | Change | Files |
|---|---|---|
| Light obtainable | Add `light` to Rare tier *or* gate behind `singularityComplete` (per D1) | `gameData.js:317` / `persistence.js` |
| Legacy-save crash | Backfill `light` in `migrateSave` (mirror the `void` backfill) | `persistence.js:58-60` |
| Stability Matrix no-op | Read + consume `stabilityBoost` in fusion tier calc | `FusionScreen.jsx:32` |
| Type chart | shadow gains 2.0 vs void & storm; stone's 2.0 vs light → 1.0 | `gameData.js:11-16` |
| Milestone counts | "Full Roster" 6 → 8; add `light_bearer`, `shiny_completionist` | `journalMilestones.js` |
| Card copy | Per-dragon locked-card text (no false "Pull from Hatchery") | `BattleSelectScreen.jsx:61` |

### Sprint 2 — Economy & difficulty (~2–3 days)
| Item | Change | Files |
|---|---|---|
| Scrap faucet | Repeat-win scraps ×0.25 after first defeat of an NPC | `BattleScreen.jsx:658` |
| XP formula | Clamp ratio to [0.25, 2]; level cap 50 in all three level-up loops | `battleEngine.js:52`, `BattleScreen.jsx:663`, `persistence.js:147`, `hatcheryEngine.js:64` |
| Boss scaling | Singularity bosses scale with player level; replays +5 levels/clear | `BattleScreen.jsx:107`, `singularityProgress.js` |
| Daily streak | `dailyStreak` save key, reward multiplier, 🔥 badge on card | `dailyChallenge.js`, `persistence.js`, `BattleSelectScreen.jsx:96-127` |
| Unlock truth | `isSingularityUnlocked` requires `protocol_vulture`; guidance calls it instead of reimplementing; stage → 0 (Dormant) after completion | `singularityProgress.js:14,28-32`, `playerGuidance.js:45` |
| Trap pricing | XP Booster → 100 scraps or ×3 multiplier | `shopItems.js:7-15` |

### Sprint 3 — First session (~2–3 days)
| Item | Change | Files |
|---|---|---|
| Intro | "▸ click to skip" hint from second 1; trim Felix to ~4 lines, rest to Journal | `TitleScreen.jsx`, `loreCanon.js:37-53` |
| Milestone surfacing | Toast + Journal nav badge when a milestone becomes claimable | `journalMilestones.js`, `NavBar.jsx`, `Toast.jsx` |
| Guidance jam | Shop step one-shot/thresholded; add a FORGE step | `playerGuidance.js:28` |
| Nav gating | Gate SHOP/FORGE/STATS like FUSION (appear when relevant); 3–4 tabs in session one | `NavBar.jsx:19-82` |
| Battle list | Sort by level; "RECOMMENDED Lv.X" tags; lock boss freeplay until matching campaign node | `BattleSelectScreen.jsx:128-157` |

### Sprint 4 — Endgame payoff (~3–5 days)
| Item | Change | Files |
|---|---|---|
| Mirror Admin | True-final fight gated on `singularityComplete` + all 7 log fragments; resolves the Great Reset countdown | `singularityBosses.js`, `loreCanon.js` |
| Boss rush | Re-clears at ascending levels; `updateRecords` wired through the final-boss path | `SingularityScreen.jsx:19`, `BattleScreen.jsx:707-715` |
| Fusion lineage | Permanent "Lineage" counter so fusion adds to a record instead of deleting collection state | `persistence.js`, `JournalScreen.jsx` |

### Godot track (parallel, per D3)
1. Fix XP-target bug (`dragon_progression.gd:58-62`) + a screen-level GUT test. 2. Adopt `save_io.gd` everywhere; delete `main.gd`'s schema. 3. Wire `battle_engine.gd` into `battle_screen.gd`; delete inline duplicates. 4. Build the one-zone overworld slice. 5. Update CLAUDE.md + `run-godot.ps1` (stale paths/layout) **now** — it's a 10-minute fix that unblocks every future session.

## 5. Open questions (product calls for Scott)

1. **Is the web build the product or the prototype?** D2/D3 assume "both, with different jobs" — confirm or redirect.
2. **Light Dragon: gacha tier or post-game reward?** D1 recommends post-game; the Rare-tier alternative is faster but spends the only unbuilt carrot.
3. **Is the Mirror Admin arc in scope** for the browser build, or reserved as the Godot build's narrative hook? (Cheap text-reconciliation fallback exists either way.)
4. **Level cap 50** matches stage-4 evolution and the Lv.50 gate already used by `singularityProgress` — any reason to keep unbounded levels?

---
*Agent session IDs for follow-up: economy `af16215eca4efb8d4`, first-session `a11231d2b24938761`, retention `af57513d900929321`, platform `a99b1f70750fa0220`.*
