# Project Stage Analysis — Dragon Forge

**Date**: 2026-06-16
**Stage**: **Production** (browser build in active Polish; Godot build mid-Sprint 04)
**Stage Confidence**: **PASS** — clearly detected. Two implemented builds, a deployed live product, story-driven sprint process, and a large passing test suite.

> **Method note**: This report does not simply restate the 2026-06-11 design sprint. Those findings were audited against commit `d53d9bf`. The tree has since advanced through `99fc7c9` ("full rebalance pass from the balance audit") and `5576e18` ("fixed-TTK post-game boss scaling"). Every prior finding below was **re-verified against the current tree (HEAD `eb1a8d8`)** by parallel verification agents; current `file:line` evidence is cited. The headline is that most findings have been remediated since the sprint.

---

## 1. Completeness Overview

| Domain | Completion | Status |
|--------|-----------|--------|
| **Design** | ~65% | 41 design specs in `docs/superpowers/specs/`, 17 plans, 4 recent design-sprint docs (`docs/DESIGN_SPRINT_*`). *Gap*: no canonical `design/gdd/` library or formal ADRs — design intent lives in dated spec/plan docs. |
| **Code** | ~90% | Browser: 25 source + 13 test JS files in `src/` (feature-complete, deployed). Godot: 39 GDScript files (18 sim, 11 screens, 4 world, components) — overworld slice now exists. |
| **Architecture** | ~70% | Strong engine/presentation separation in both builds; CLAUDE.md documents both. *Gap*: no formal ADR records (design decisions embedded in spec/plan docs). |
| **Production** | ~90% | Active Sprint 04, story-based epic (`production/epics/hatchery/`), `/code-review` + `/story-done` ceremony, QA gates, test-evidence tracking. *Gap*: no sprint-plan/roadmap/milestone files in `production/`. |
| **Tests** | ~85% | Browser: 13 Vitest files (node env) + Playwright smoke. Godot: 5 GUT suites; last full run 198/198 tests, 18,436 assertions. |

---

## 2. Two-Track Reality

Dragon Forge is two builds on diverging cadences:

- **Browser build (`src/`)** — the **live product and balance lab**. Deployed to GitHub Pages via `.github/workflows/deploy.yml` on push to `master` (`base: '/dragon-forge/'`). The most recent commits are art regen + balance fixes — this build is in **active Polish**, and the 2026-06-11 design-sprint backlog has been substantially burned down here (see §3).
- **Godot build (`dragon-forge-godot/`)** — the **production spine** for the longer-term RPG overworld. Driven by a story-based sprint process (not npm). Currently mid **Sprint 04**, with one story blocked on code-review fixes (see §4).

These advance independently. The browser remediation work (2026-06-11/06-12) post-dates the last recorded Godot session state (2026-05-28), so the Godot sprint is effectively paused while browser polish proceeds.

---

## 3. Design-Sprint Findings — Re-Verified Against Current Tree

Status legend: ✅ Fixed · 🟡 Partially fixed · 🔴 Still true · ⚪ Not reproduced

### Economy & Balance
| ID | Finding | Status | Current evidence |
|----|---------|--------|------------------|
| A1 | Unbounded scrap faucet; unbounded XP ratio; no level cap | 🟡 | Boss/remnant repeats now pay ×0.25 (`BattleScreen.jsx:709-728`); XP ratio clamped 0.25–2.0 (`battleEngine.js:53-56`); **level cap 50** + rising XP curve (`persistence.js:171,178,183`). **Residual**: daily challenge ×3 scrap multiplier (`dailyChallenge.js:35`) remains a renewable high-yield source. |
| A2 | Type chart: stone strictly best, shadow strictly worst (yet Rare-tier) | 🟡 | Rebalanced (`gameData.js:8-17`): row sums now void 9.5, light 9.5, stone 9.0, shadow 8.0 — no longer "strictly" best/worst; void's 2× targets (stone, light) now appear in enemy rosters. **Residual**: shadow remains weakest defensively while still the Rare-tier prize (`gameData.js:337`). |
| A6 | Endgame doesn't retain (4 fights + epilogue; no daily streak; corruption stuck at 3) | 🟡 | Mirror Admin TRUE FINAL added + 3 Corruption Remnants as post-game content (`singularityBosses.js:103-141,170-291`); daily streak implemented w/ 1.5× cap (`dailyChallenge.js:64-73`); corruption stages 0–5 derive from milestones, not stuck (`singularityProgress.js:16-29`). **Residual**: still a finite arc — retention is improved, not deep. |

### Light Dragon
| ID | Finding | Status | Current evidence |
|----|---------|--------|------------------|
| A3-obtain | Light in no rarity tier — unobtainable | 🟡 (by design) | Not pullable (`gameData.js:334-339`) **on purpose** — now obtainable as the Singularity-completion reward (`persistence.js:263-264`) and via `light_void → synthesis` fusion (`fusionEngine.js:23-24`). |
| A3-migrate | `migrateSave` doesn't backfill light → legacy-save crash | ✅ | Now backfilled (`persistence.js:73-75`) + retroactive ownership for `singularityComplete` saves (`persistence.js:90-93`). Crash risk gone. |
| A3-card | Battle card falsely says "Pull from Hatchery" | ⚪ | Light has `unlockHint: 'Contain the Singularity'` (`gameData.js:135`), which overrides the fallback string (`BattleSelectScreen.jsx:78`). Claim no longer reproduces. |
| D1 | Decision: make Light the post-Singularity reward | ✅ | Fully implemented (`persistence.js:90-93,263-264`). |

### Fusion
| ID | Finding | Status | Current evidence |
|----|---------|--------|------------------|
| A5-stability | Stability Matrix purchase is a no-op | ✅ | `stabilityBoost` now read, applied, and consumed (`FusionScreen.jsx:28-29,34,56,64`; `fusionEngine.js:46-62`). |
| A5-payoff | Fusion stat payoff trivial (±1.7% at L50) | 🟡 | Actual gain ~8–10% at L50 (`fusionEngine.js:64-92`) — original claim underestimated ~5–6×. Modest but meaningful. |
| A5-stable | "stable" tier needs same-element parents, impossible (one dragon/element) | 🔴 | Still unreachable: save holds one slot per element (`persistence.js:5-16`); `getStabilityTier()` requires `elementA === elementB` (`fusionEngine.js:44-62`). |
| A5-uncomplete | Fusion silently un-completes the collection | 🔴 | `fuseDragons()` sets both parents `owned: false` (`persistence.js:305-324`); count-based milestones (`journalMilestones.js:23-30`) revert their progress bar. UI/UX issue, not save corruption. |

### Story & Content
| ID | Finding | Status | Current evidence |
|----|---------|--------|------------------|
| A7-mirror | Mirror Admin named as threat but never fought; Act IV content missing | ✅ | Mirror Admin fully implemented as 3-phase TRUE FINAL boss, gated post-Singularity (`singularityBosses.js:103-141`); `forgeData.js:223` Act IV reference now resolves. |
| milestones | Full Roster 6→8; add `light_bearer`, `shiny_completionist` | ✅ | `full_roster >= 8` (`journalMilestones.js:23-30`); `light_bearer` (`:144-152`); `shiny_completionist` (`:53-60`). |
| unlock-truth | Three unlock systems disagreed | ✅ | Single source: `isSingularityUnlocked()` (`singularityProgress.js:31-35`) consumed directly by guidance (`playerGuidance.js:75`); act progression derives from deterministic save state, no conflicting flags. |

### Godot Build
| ID | Finding | Status | Current evidence |
|----|---------|--------|------------------|
| A8-overworld | No `scripts/world/` — overworld differentiator has zero code | ✅ | `scripts/world/` exists (4 files); `world_screen.gd` (~14 KB) builds a procedural 20×10 two-zone world with encounters, boss gates, and a hatchery hub. |
| A9-unwired | Ported sim engines have no screen callers | ✅ | `battle_screen.gd:8,295,299,511` calls `BattleEngine`; `hatchery_screen.gd:5,48,120` calls `DragonProgression`; all on `SaveIO.save`. |
| A9-xpbug | Battle XP always awarded to "fire" | ✅ | `dragon_progression.gd:48-50` takes `target_id`; `battle_screen.gd:509-516` passes the actual fighting dragon's id. |
| main-schema | `main.gd` had a second save schema | ✅ | Removed — schema centralized in `save_io.gd:9-41`; `main.gd:38-45` holds only a plain `save` var. |

**Net**: of 16 re-verified items, **8 fixed, 1 not reproduced, 4 partially fixed, 3 still true.** The game has moved from "screen-complete but not design-complete" toward substantially design-complete.

---

## 4. The "Active Blocker" Is a Phantom — HATCHERY-005 Functionality Is Already Shipped

The SessionStart hook and `production/session-state/active.md` present HATCHERY-005 (Dragon unlock, duplicate XP, shiny upgrade) as an open Sprint 04 blocker "Review Changes Required." **Verified false against the current tree (2026-06-16):** the functionality is fully implemented in the actual engines, and the story's two "blocking" code-review fixes target an architecture that does not exist in this repo.

**The story file describes paths that don't exist** — `src/hatchery/hatchery_service.gd`, `src/dragon/dragon_progression_service.gd`, `design/gdd/hatchery.md`, ADR-0006/0012. The real implementation lives in `dragon-forge-godot/scripts/sim/hatchery_engine.gd` (and the mirror `src/hatcheryEngine.js`). Every acceptance criterion maps to shipped code:

| Story AC | Real implementation |
|----------|--------------------|
| AC-H15/16/17 — unlock + shiny on new pull | `apply_pull_result()` sets `owned=true` / `shiny=true` (`hatchery_engine.gd:60-64`) |
| AC-H18/19/20 — duplicate XP 50/100/150 | `50 * rarity_multiplier`, multipliers Common=1/Uncommon=2/Rare=3 (`hatchery_engine.gd:66`, `game_data.gd:65-67`) — exact |
| AC-H22/23 — level loop + MAX_LEVEL 50 cleanup | capped while-loop, `xp=0` at 50 (`hatchery_engine.gd:68-73`) |
| AC-H24/25 — shiny upgrade, no downgrade | `if shiny and not dragon.shiny: dragon.shiny = true` (`hatchery_engine.gd:74-75`) |
| AC-H28 — all owned → all duplicate | the `else` branch (`hatchery_engine.gd:65-75`) |

**The two code-review "required fixes" are moot** against this implementation:
1. *Normalize `HatcheryPullResult` after post-spend, pre-commit failure* — `apply_pull_result()` is a **pure function** (copy save → mutate → return). No scrap spend happens inside it and there is no `unknown_rarity` failure path (rarity is engine-rolled, never invalid). There is no partial transaction to roll back.
2. *Validate duplicate XP before mutating shiny* — XP is a deterministic table lookup; there is no validation step that can fail.

**Conclusion**: HATCHERY-005's *intent* is covered. The story, its code review, and `active.md` are **orphan scaffold** from the Game Studios story-driven workflow (`1cf25f0`), authored against a service/transaction architecture that was never built — not a record of pending work on this codebase. `production/epics/` contains this one file and nothing else; there is no `design/gdd/` or ADR set backing it.

---

## 5. Gaps Identified

1. **Orphan story scaffold** — `production/epics/`, `production/qa/hatchery-005-*`, and `production/session-state/active.md` describe a story-driven Godot effort (`src/hatchery/…`, `design/gdd/hatchery.md`, ADR-0006/0012) whose files do not exist and whose functionality is already shipped in the real engines (see §4). *Recommendation*: archive or delete this scaffold so the SessionStart hook stops resurrecting a phantom blocker, OR re-point the story to the real `hatchery_engine.gd` and close it as Done.
2. **No canonical design library** — 41 specs + 17 plans exist under `docs/superpowers/`, but no `design/gdd/` index or formal ADRs. The Game Studios skills (`/create-stories`, `/story-readiness`) reference GDD/ADR IDs that have no backing files here. *Question*: author a canonical set, or accept that `docs/superpowers/` + this report are the design record?
3. **Stale CLAUDE.md note** — partially corrected. The Godot `scripts/world/` layout it describes now **does** match (overworld was built since), but `run-godot.ps1`'s hardcoded binary path should be confirmed valid on this machine.
4. **Residual balance items** — daily-challenge ×3 scrap multiplier (renewable faucet), shadow's defensive weakness vs. its Rare-tier status, and the unreachable "stable" fusion tier. *Question*: intended, or backlog?
5. **Fusion milestone regression** — `fuseDragons()` flips parents to `owned: false`, reverting count-based milestone progress bars. Low-severity UX, but visible.
6. **Minimal `production/` structure** — only `epics/`, `qa/`, `session-state/`, `session-logs/`. No sprint plan, roadmap, or milestone files. *Question*: tracked elsewhere, or should these live here?

---

## 6. Recommended Next Steps (Priority Order)

**Immediate — clear the phantom blocker**
1. Archive/delete the orphan scaffold (`production/epics/hatchery/`, `production/qa/hatchery-005-*`, `production/session-state/active.md`) — or re-point story-005 at `hatchery_engine.gd` and mark it Done — so the SessionStart hook stops surfacing a resolved blocker. (HATCHERY-005 functionality is already shipped; see §4.)
2. Remove or update the SessionStart "active session state detected" pointer once the scaffold is cleared.

**Short-term — close real design debt**
3. Decide residual-balance items (daily ×3 multiplier, shadow tuning, stable-tier reachability) — likely a `/quick-design` + `/balance-check` pass.
4. Fix the fusion milestone-progress regression (UX).
5. Confirm `run-godot.ps1`'s binary path is valid on this machine; CLAUDE.md's Godot layout otherwise matches the tree now.

**Medium-term — structure & process**
6. Decide whether to author a canonical `design/gdd/` + ADR set in this repo (run `/reverse-document`) or accept `docs/superpowers/` + this report as the design record.
7. If continuing Godot production, run a real `/smoke-check` (`sim_smoke.gd`, 20/20 last pass) and `/sprint-plan` against the actual `dragon-forge-godot/` tree.

---

## 7. Stage Verdict

**Production**, trending toward **Polish** on the browser build. The live product is deployed, feature-complete, and most of the 2026-06-11 design-sprint backlog has shipped. **There is no real open code blocker** — the apparent HATCHERY-005 blocker is orphan scaffold for functionality already shipped in `hatchery_engine.gd` (see §4). No FAIL-level gaps block progress. The principal risk is **process hygiene** — stale story/session-state scaffold misrepresenting the actual state — not code quality. Recommended single highest-value action: clear the orphan scaffold so future sessions start from ground truth.

---

*Generated by `/project-stage-detect`. Findings re-verified against HEAD `eb1a8d8` by parallel verification agents; all `file:line` citations reflect the current tree, not the 2026-06-11 audit baseline.*
