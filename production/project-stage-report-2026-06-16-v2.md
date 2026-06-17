# Project Stage Analysis — Dragon Forge (v2 re-verification)

**Date**: 2026-06-16
**Supersedes**: [project-stage-report.md](project-stage-report.md) (same day, baseline `eb1a8d8`)
**Verified against**: HEAD `5c05dfc` + in-session remediation (see §6)
**Stage**: **Production**, trending to **Polish** (browser build)
**Stage Confidence**: **PASS** — clearly detected. Live deployed product, two implemented builds, 178 passing browser tests + 99 Godot GUT cases, green lint/build.

> **Why a v2.** The original report was written earlier today against baseline `eb1a8d8`; the tree has since advanced 5 commits to `5c05dfc` (combat depth, 2× a11y, narrative, bespoke boss art). A 12-agent re-verification workflow re-scanned every domain and adversarially re-checked each open finding against the **current** tree. Three of the original report's open findings turned out to be **wrong or already resolved**; two new gaps surfaced from the combat-depth commit; and three confirmed items were **fixed in this session**. All `file:line` citations below reflect `5c05dfc` (or this session's edits where noted).

---

## 1. Completeness Overview

| Domain | Completion | Status |
|--------|-----------|--------|
| **Design** | ~65% | 15 specs + 24 plans + 4 design-sprint audits under `docs/superpowers/` & `docs/`. **0 canonical GDDs, 0 ADRs** — design intent is scattered across dated docs, some stale (the 2026-03-27 combat spec still lists 6 elements; the game ships 8). |
| **Browser code** | ~98% | 67 JS/JSX files (50 source, 17 test). **178 tests pass, lint clean, `vite build` OK** (92 modules). Verified in a live preview boot this session. Only `animationEngine.js` (725 lines) lacks a dedicated unit test. |
| **Godot code** | ~88% | 38 GDScript files: full screen router (`main.gd`), two-zone procedural overworld (`scripts/world/`), all sim engines wired into screens. |
| **Tests** | ~70% | Strong *engine* coverage both builds (178 vitest + 99 GUT + 22 smoke). Gaps: browser UI/`.jsx` untested (node env, no jsdom), `persistence.js` has no dedicated migration tests, Godot tests not in CI, overworld layer untested. |
| **Production / process** | 100% | Orphan HATCHERY-005 scaffold archived (`141416b`); phantom blocker no longer fires. No sprint/roadmap/milestone files (tracked ad-hoc). |

---

## 2. Two-Track Reality (unchanged)

- **Browser build (`src/`)** — the **live product and balance lab**, deployed to GitHub Pages on push to `master`. In **active Polish**: the recent 5 commits are 4 polish/a11y/art + 1 tested feature.
- **Godot build (`dragon-forge-godot/`)** — the **production spine** for the longer-term overworld RPG. Effectively paused while browser polish proceeds (last recorded Godot session state predates the browser polish run).

---

## 3. Corrections to the Original Report (the high-value delta)

The re-verification **debunked or closed** several items the original report still lists as open. Status legend: ✅ now resolved · ❌ original claim wrong · ✏️ overstated.

| ID | Original report said | Re-verified verdict | Evidence |
|----|----------------------|---------------------|----------|
| **process-scaffold** | Orphan HATCHERY-005 scaffold + phantom blocker (the report's #1 gap) | ✅ **RESOLVED** | Files moved to `production/_archive/` and committed (`141416b`); `production/session-state/active.md` absent, so `session-start.sh` guard never fires. |
| **A5-stable** | Fusion "stable" tier is unreachable | ❌ **WRONG** — reachable & tested | Stability Matrix shop item drives `setStabilityBoost(true)` → `getStabilityTier(..., true)` promotes a normal pair to `stable` ([fusionEngine.js:58](../src/fusionEngine.js:58), [shopItems.js:71](../src/shopItems.js:71), test [fusionEngine.test.js:43](../src/fusionEngine.test.js:43)). |
| **A2-shadow** | Shadow is the defensively weakest element | ❌ **WRONG** | By column-sum (true defensive) Shadow is 9.5; Light (11.0) and Venom (10.0) take more. By literal row-sum Shadow ties second-highest. ([gameData.js:8](../src/gameData.js:8)). Only the "Shadow is the sole Rare-tier prize" half holds. |
| **A3-light** | Light obtainable via Singularity **and** light_void fusion | ✏️ **OVERSTATED** | Light has exactly **one** obtain path: Singularity completion ([persistence.js:297](../src/persistence.js:297)). Fusing light+void yields *synthesis*, not light ([fusionEngine.js:23](../src/fusionEngine.js:23)) — fusion is a *consumer* of light, not a source. Intentional & correct. |

---

## 4. Confirmed Still-Open (re-verified true) — addressed this session

| ID | Finding | Status |
|----|---------|--------|
| **A5-uncomplete** | `fuseDragons()` flipped both parents to `owned:false`, reverting *unclaimed* count-milestone progress bars (`full_roster` 5/8 → 4/8). | 🔧 **Fixed this session** — see §6.2 |
| **A1-daily-faucet** | Daily challenge pays ×3 scrap ([dailyChallenge.js:35](../src/dailyChallenge.js:35)), compounded by streak (×1.5) and NG+ — a renewable faucet. | ⚪ **Left as designed** — flagged for a balance decision (§7) |

---

## 5. New Gaps from the Combat-Depth Commit (`5c05dfc`)

The one substantive systems change in the delta introduced two gaps (verified):

| ID | Finding | Status |
|----|---------|--------|
| **charge-stack** | Charged-strike ×1.4 ([BattleScreen.jsx:722](../src/BattleScreen.jsx:722)) × `npc_focus` ×1.3 atkBuff composed **multiplicatively to 1.82× ATK**, reachable on `phishing_siren` and `protocol_vulture`. Unguarded, untested, multipliers split across engine ↔ presentation. | 🔧 **Fixed this session** — see §6.1 |
| **charge-orch-untested** | The charge/signature orchestration in [BattleScreen.jsx:689-740](../src/BattleScreen.jsx:689) (the flow that fires charges/signatures) has no automated test — only the selection AI does. | 🟡 Partial — the *cap* now has an engine unit test (§6.1); the BattleScreen reducer flow remains manual-only. |
| **dead-player-buff** | Engine's buff handler generically sets `result.player.atkBuff`, but no player move is `actionType:'buff'` and BattleScreen never syncs a player buff back. Latent, harmless today. | ⚪ Documented; no fix (no reachable path). |

Four delta items were **resolved by the commit itself**: photosensitivity/reduce-motion (CSS + GSAP), bespoke Singularity boss art (replacing hue-rotated recolors), narrative thinness (Captain's Log + Felix milestone reactions), and static enemy AI (now adaptive). None of the 5 commits changed the stage classification.

---

## 6. In-Session Remediation (this session — uncommitted working tree)

All three changes verified by `npm test` (178 pass), `npm run lint` (clean), `vite build` (OK), and a live preview battle (Title → Hatchery → BattleSelect → BattleScreen → win, zero console errors).

### 6.1 — Cap the charge × atkBuff stack (`charge-stack`)
- Added `CHARGE_ATK_MULTIPLIER` (1.4), `MAX_ATK_MULTIPLIER` (1.5), and a pure exported `effectiveAttack(atk, atkBuff, chargeMultiplier)` that combines **all** attack-up sources under one ceiling ([battleEngine.js](../src/battleEngine.js)).
- `resolveAction` now routes through `effectiveAttack`; `BattleScreen.jsx` passes `chargeMultiplier` (instead of pre-multiplying `atk`) so the engine combines + caps. 1.82× → clamped to 1.5×.
- New regression tests pin the cap ([battleEngine.test.js](../src/battleEngine.test.js), +5 cases).

### 6.2 — Fix fusion milestone regression (`A5-uncomplete`)
- Added a permanent `discovered` codex flag to the save schema; collection-count milestones (`first_discovery`, `elemental_trio`, `full_roster`) now count `discovered`, not `owned` ([journalMilestones.js](../src/journalMilestones.js)).
- `discovered` is set at every owned-true site (pull, Singularity reward, fusion offspring) and **preserved on consumed fusion parents** ([persistence.js](../src/persistence.js), [hatcheryEngine.js](../src/hatcheryEngine.js)). `migrateSave` backfills it and repairs already-fused legacy saves from `fusionLineage`.
- New test file ([journalMilestones.test.js](../src/journalMilestones.test.js), 4 cases) proves fusing no longer reverts collection progress.

### 6.3 — Strip archived `active.md` references from hooks (`process-scaffold` latent tail)
- Removed the dead `production/session-state/active.md` logic from `session-start.sh`, `session-stop.sh`, and `pre-compact.sh` (the retired recovery mechanism, archived in `141416b`), keeping each hook's genuinely-useful behavior (git context, commit logging, working-tree dump). Nothing latent can re-fire.

---

## 7. Remaining Gaps & Open Decisions

1. **Daily ×3 scrap faucet** (`A1`) — renewable, compounded by streak/NG+. *Decision needed*: intended endgame faucet, or cap it? (`/balance-check` + `/quick-design`.)
2. **No canonical design library** — 15 specs + 24 plans, 0 GDDs, 0 ADRs; some specs stale vs. the live game. *Decision*: author a `design/gdd/` + ADR set (`/reverse-document`), or accept `docs/superpowers/` + these reports as the record?
3. **Browser test gaps** — `animationEngine.js` (725 lines) untested; `persistence.js` has no dedicated `migrateSave`/corruption tests; all `.jsx` untested (node env). The `discovered` migration added this session is covered only indirectly.
4. **Godot tests not in CI** — `tests.yml` runs vitest only; 99 GUT + 22 smoke cases run on manual local passes; the overworld layer (`world_screen.gd`, `player_dragon.gd`, gates) is untested.
5. **Loading splash on a fixed 2000ms timeout** ([index.html](../index.html)) rather than React mount — confirmed lingering on a fast local boot this session. Low severity.
6. **Minimal `production/` structure** — no sprint/roadmap/milestone files; `production/session-logs/` is untracked in git.

---

## 8. Stage Verdict

**Production**, trending to **Polish** on the browser build. The live product is deployed, feature-complete, and the recent delta is finishing work (a11y, art, narrative) plus one tested feature increment. **No FAIL-level gaps block progress.** With this session's three fixes, the only confirmed *code* gaps from the audit are resolved; what remains is **design-debt and decisions** (faucet tuning, canonical design docs, CI coverage), not defects. Highest-value next action: decide the daily-faucet balance question and whether to formalize the design library.

---

*Generated by `/project-stage-detect` (v2). Re-verified against HEAD `5c05dfc` by a 12-agent verification workflow; in-session fixes (§6) verified by full test suite + live preview.*
