# Cross-GDD Review Report — Dragon Forge

**Date:** 2026-06-16
**GDDs reviewed:** 19 system GDDs + game-concept + game-pillars + systems-index
**Method:** `/review-all-gdds` (full) — consistency (2a–2f), design-theory (3a–3g), and cross-system scenario walkthrough (Phase 4), each pass run by independent agents; every BLOCKING finding adversarially verified against the actual GDD text and source code before inclusion.

> **Context:** The GDDs were reverse-documented from the shipped browser build on 2026-06-16. Accordingly, the great majority of findings are **documentation-quality issues in the freshly generated docs** (artifacts of parallel authoring), not defects in the live game. A handful are genuine design observations — most of which the GDDs already self-flag as open questions. One real **code bug** was found and fixed during this review.

---

## Verdict: **CONCERNS** — no blocking issues

Every finding initially flagged as a blocker was downgraded or invalidated under verification:

| ID | Flagged claim | Verified verdict |
|----|---------------|------------------|
| S-01 | XP Booster × `astraeus_engine` relic × NG+ = uncapped XP spike | **INVALID** — the relic value *is* defined (1.15, `forge-skye.md`); level cap 50 is a hard ceiling. |
| S-02 | Fusion silent-overwrite + `fusionsCompleted +2` bug | **WARNING** — overwrite is a real UX gap (already an open question); the +2 bug was real → **FIXED this session**. |
| S-03 | Singularity completion "2500-scrap double-claim" | **WARNING/INFO** — milestone rewards are intentionally separate faucets game-wide; fragment-ordering & audio sub-claims were false; pity-carryover is a doc gap. |
| S-05 | NG+ doesn't reset `pityCounter` (+3 sub-claims) | **WARNING** — only the `pityCounter` doc gap is real; the other three sub-claims were false. |
| KNOB-001 | `CORE_DROP_CHANCE`/`CORE_DOUBLE_CHANCE` owned by 3 GDDs with conflicting safe ranges | **WARNING** — real tuning-knob ownership duplication, but the live value is in code; a doc-dedup task, not a gate-blocker. |
| 3f-05 | Move accuracy not surfaced on cards = P2 anti-pillar violation | **INVALID** — accuracy **is** shown on every move card (`BattleScreen.jsx:1494,1499`); the "violation" exists only as a stale open-question in the GDDs. |

**Net:** 0 blockers · ~17 warnings · ~16 info.

---

## Code bug found & fixed during review

**`fusionsCompleted` double-increment.** Verified in source: `fuseDragons()` increments the counter (`persistence.js:376`) and `FusionScreen.jsx:65` *also* called `trackStat('fusionsCompleted')` — every fusion counted twice. The Stats and Journal screens displayed 2× the true fusion count. No milestone reads the counter, so it was display-only. Fixed by removing the redundant screen-level call (the canonical `fuseDragons()` mutation owns the increment). Lint/tests/build green.

---

## Consistency Issues (Phase 2)

### Warnings

**Tuning-knob ownership conflicts (2d)** — the same knob is documented in multiple GDDs with independently-invented, conflicting safe ranges. Recommended owners:
- **KNOB-001** `CORE_DROP_CHANCE` / `CORE_DOUBLE_CHANCE` — in `economy.md`, `shop-and-crafting.md`, `campaign-map.md` (ranges 0.40–0.80 / 0.30–0.90 / 0.30–0.85). → Owner: **economy.md**; others cross-reference.
- **KNOB-002** NG+ scale (0.25/tier) — in `combat.md` + `campaign-map.md` (conflicting category gate-vs-curve & range). → Owner: **combat.md** (curve).
- **KNOB-003** stat budget per level (12) — in `combat.md` + `dragon-progression.md` (range 8–16 vs 8–18). → Owner: **dragon-progression.md**.
- **KNOB-004** `FORGE_STEP` (2) — in `forge-skye.md` + `input-and-gamepad.md`. → Owner: **forge-skye.md**.

**Dependency bidirectionality (2a)** — one-directional links:
- **DEP-001** `audio.md` depends on `combat.md`; `combat.md` doesn't reciprocate.
- **DEP-002** `campaign-map.md` → `combat.md` not reciprocated.
- **DEP-003** `vfx-animation-accessibility.md` → `combat.md` not reciprocated.
- **DEP-004** `economy.md` marks `singularity-endgame.md` bidirectional; singularity omits economy.

**Shared-number / reference issues (2b/2c):**
- **F-01** Currency naming drift: `DataScraps` vs `Data Scraps` across 7 GDDs.
- **F-02** `fusion.md` UI hint says "Stage II" but the real eligibility gate is `level >= 10` (Stage II starts at level 8 → a L8–9 dragon is Stage II but ineligible).
- **F-04** `journal-milestones.md` documents a discovered-vs-owned label divergence without marking it a Known Divergence (QA would file it as a defect).
- **F-05** Singularity stage-1 applies no corruption CSS class while the pillars promise "the world visibly degrading" at every stage.

### Info
- **DEP-005** `combat.md` has no data-dep row for `hatchery-gacha.md` (shiny flag → ×1.2 in `calculateStatsForLevel`).
- **INFO-001 / F-03** Stale "none of these files exist yet" / "(TBD)" cross-reference notes in `hatchery-gacha.md`, `singularity-endgame.md`, `journal-milestones.md` — all referenced files now exist.
- **F-06** Fusion offspring cap is 30 (`fusionEngine.js`) but `dragon-progression.md` only documents the never-reached 50-cap.
- **F-07** Duplicate-XP rarity multipliers agree but are defined in two GDDs (drift risk).

---

## Game Design Issues (Phase 3)

### Warnings (genuine design observations)
- **ECO-01** No `DataScraps` sink survives full completion — post-Singularity economy goes inert (only the daily faucet remains, with nothing to spend on).
- **ECO-02** Element Cores cap at 99 with no late-game sink; the Singularity replay cache pushes them to the cap, making core drops feel meaningless.
- **ECO-03 / STRAT-01** Repeated **stable-element fusion** compounds base stats with no ceiling and strictly dominates other fusion paths; campaign NPCs scale on player *level* not *ATK*, so a fusion-stacker one-shots pre-Singularity content. (`fusion.md` already flags the no-ceiling issue.)
- **3b-01** Standard (non-boss) combat exposes ~5–6 simultaneous attention streams (matchup, status, bench, charge, relics, buffs) — above the 4-system comfort threshold. Boss fights drop to ~4 (bench/auto locked out). Borderline, defensible.
- **3f-01** All 19 GDDs use legacy "Implements Pillar" labels instead of canonical P1–P5; `game-pillars.md`'s spine table is unenforceable without manual cross-referencing.
- **3f-02** `audio.md` declares "Juice and Feedback", which maps to no canonical pillar (should be P5).
- **DIFF-01** `singularity-endgame.md` flags NG+ enemy scaling as an unconfirmed open question, but code (`BattleScreen.jsx:39–43`) confirms it is wired — stale open-question.

### Info
- **ECO-04** Milestone reward values are inline constants in `journalMilestones.js`, not in a data file (documented deviation from the tuning-knob standard).
- **STRAT-02** AUTO-battle's place against the Mastery pillar is flagged open in 4 docs but undecided (esp. on the daily challenge).
- **STRAT-03** Type-advantage spam is countered by adaptive AI at a 75% floor — verify every campaign NPC has a super-effective counter available.
- **LOOP-01** `hatchery-gacha.md` and `campaign-map.md` both say "primary" — documentation language, not a mechanical loop conflict (DataScraps is the shared connector; `game-concept.md` owns the macro-loop).
- **DIFF-02** Daily challenge reward is correctly bounded (streak hard-caps at ×1.5; once/day gate) — confirmation, no action.
- **3f-03/04/06** Pillar-mapping gaps: `input-and-gamepad.md` & `save-and-persistence.md` serve no named pillar (infrastructure); `daily-challenge.md` uses an outcome label ("Retention") not a pillar; `systems-index.md` has no Pillar column.
- **3g-01** `economy.md` and `shop-and-crafting.md` claim near-identical "resourceful engineer/alchemist" player fantasies.
- **3g-02** `hatchery-gacha.md`'s "lottery ticket" metaphor conflicts with P3's in-fiction framing (gacha = "protocol instantiation").
- **3g-03** `combat.md` and `forge-skye.md` both claim a "commander/operative" identity without a handoff note.

---

## Cross-System Scenario Issues (Phase 4)

Scenarios walked: combat-victory reward stack · fusion vs collection milestones · Singularity completion → Light unlock → rewards · daily + streak + NG+ compounding · Mirror Admin defeat → credits → NG+ reset.

- **S-02 (Warning)** Fusion silently overwrites an already-owned offspring slot with no confirmation; overwriting a high-level dragon de-qualifies *unclaimed* `elder_forged`/`apex_roster` milestones (claimed badges are protected by the idempotency guard). `fusion.md` already lists the missing-warning as an open question.
- **S-03 (Warning/Info)** First Journal visit after Singularity completion pays battle reward (1000) + `singularity_contained` (1000) + `light_bearer` (500) = 2500 ◆. This is how milestones work game-wide (separate faucet), not a defect — but undocumented as an intended arc-completion bonus. Minor: `pityCounter` carries over after the Light grant (doc gap).
- **S-04 (Warning)** NG+ adds unbounded headroom on top of the daily ×3 × streak-1.5; `daily-challenge.md`'s "prevents compound exponential growth" claim applies only to the streak component. Document the combined ceiling.
- **S-05 (Warning)** `applyNewGamePlus` does not reset `pityCounter` and no GDD documents whether that is intended (benign — grants a guaranteed Rare+ on the first NG+ pull).

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| combat.md | Add reciprocal deps (audio/campaign/vfx/hatchery); own NG+ knob, drop stat-budget knob; pillar header | Consistency / Doc | Warning |
| economy.md | Own core-drop knobs (reconcile range); pillar header | Consistency | Warning |
| shop-and-crafting.md | Drop core-drop knob rows → cross-ref economy; pillar header | Consistency | Warning |
| campaign-map.md | Drop core-drop + NG+ knob rows; close NG+ open-question; pillar header | Consistency | Warning |
| dragon-progression.md | Own stat-budget knob; add fusion cap-30 note; pillar header | Consistency | Info |
| forge-skye.md | Own FORGE_STEP; pillar header | Consistency | Info |
| input-and-gamepad.md | Drop FORGE_STEP → cross-ref forge-skye; pillar header (P5) | Consistency | Info |
| singularity-endgame.md | Add economy dep; close NG+ open-question; remove stale note; pillar header | Consistency | Warning |
| journal-milestones.md | Remove (TBD) markers; mark discovered-vs-owned a Known Divergence; pillar header | Consistency | Warning |
| hatchery-gacha.md | Remove stale "files don't exist" note; reframe "lottery ticket"; pillar header | Consistency | Warning |
| fusion.md | Fix "Stage II" hint → "level 10+"; pillar header | Consistency | Warning |
| audio.md | Pillar header → P5 | Doc | Warning |
| game-pillars.md | Remove the false "accuracy not surfaced = P2 violation" open-question (it is surfaced) | Doc | Warning |
| (all 19) | Align legacy "Implements Pillar" headers to canonical P1–P5 | Doc | Warning |

---

## Recommended Next Steps
1. **Apply mechanical doc fixes** (this session): pillar-header alignment, stale-note/open-question removal, tuning-knob ownership dedup, dependency reciprocity, currency naming, fusion hint. (In progress.)
2. **Genuine design questions to decide later** (not blocking): late-game scrap/core sinks (ECO-01/02), a `fusedBaseStats` ceiling or ATK-tracking campaign-NPC scaling (ECO-03/STRAT-01), AUTO-battle on the daily challenge (STRAT-02).
3. Run `/consistency-check` to populate the (currently absent) `design/registry/entities.yaml` so future reviews are grep-first.

---

*Generated by `/review-all-gdds`. Blocking findings adversarially verified against source; severities reflect the verified verdict, not the initial flag.*
