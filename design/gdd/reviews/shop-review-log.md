# Shop — Review Log

## Review — 2026-05-26 — Verdict: APPROVED (Revision 4)
Scope signal: S
Specialists: None (consistency pass)
Blocking items: 0 | Recommended: 0
Summary: Header/status and relic-framing consistency pass after Singularity/Shop architecture blocker cleanup. `shop.md` now matches the Systems Index approval state, and the overview uses Mainframe Crown recognition language instead of explicitly framing analog relics as "required for endings." OQ-SH01 remains open because authored Campaign Map node distribution and playtest economy data do not exist yet.
Prior verdict resolved: Yes — Revision 3 approval remains valid

## Review — 2026-05-24 — Verdict: APPROVED (Revision 3)
Scope signal: L
Specialists: None (lean mode — solo analysis)
Blocking items: 1 (resolved) | Recommended: 6 (resolved)
Summary: One blocker found and resolved: CONFIRMING state description still read "< 300ms" — a stale reference from Revision 1 not updated when the threshold moved to 400ms in Revision 2. A programmer reading only the States table would have implemented a 100ms dead zone. Six recommended revisions applied: DWELL_REVEAL Back/Cancel transition specified (→ ITEM_FOCUSED), "In Pack" Confirm behaviour committed (tone only, no Unit 01 line), EC-4.2 grey-out obligation upgraded to "must", ALREADY_OWNED dismiss asymmetry explained (intentional narrative beat), AC-SH54 (999+ display) and AC-SH55 (Unit 01 idle suppression) added. All formulas verified at boundary values — no degenerate outputs. Dependency graph: three missing GDDs (journal, save-persistence, singularity) correctly forward-contracted; blocking for implementation but not for approval.
Prior verdict resolved: Yes — 13/13 blockers from 2026-05-24 NEEDS REVISION review addressed

## Review — 2026-05-24 — Verdict: NEEDS REVISION (resolved in-session)
Scope signal: L
Specialists: economy-designer, game-designer, systems-designer, ux-designer, narrative-director, qa-lead, creative-director
Blocking items: 13 | Recommended: 8
Summary: Substantial improvement from prior review — all structural issues resolved. Remaining 13 blockers were focused fixes: DWELL_REVEAL threshold raised from 300ms to 400ms (too aggressive for gamepad); item description added to CONFIRMING dialog; Defrag Patch selection rule specified (most recently applied); INT_MAX sentinel removed from Cache Shard formula and replaced with explicit Stage IV early-return branch; xp_threshold_for() declared as required public export from Dragon Progression; Unit 01 voice profile section added (knowledge state, per-state register, prohibitions); 5 AC rewrites for testability (AC-SH02, AC-SH09/10, AC-SH13, AC-SH16); 3 missing ACs added (INSUFFICIENT_FUNDS exit, CONFIRMING balance arithmetic, d-pad edge stops); price range ordering constraint added; sink-competition design intent and bad-luck floor decisions documented. Economy validation against Campaign Map data remains open (OQ-SH01). All 13 blockers resolved in-session. Recommended: targeted re-review by ux-designer and qa-lead only before final approval.
Prior verdict resolved: Yes — 12/12 prior blockers from 2026-05-25 review addressed

## Review — 2026-05-25 — Verdict: MAJOR REVISION NEEDED
Scope signal: M
Specialists: economy-designer, game-designer, systems-designer, ux-designer, narrative-director, creative-director
Blocking items: 12 | Recommended: 3
Summary: The creative director identified a single root cause — relics were mechanically identical to consumables at point of purchase, undermining the Player Fantasy's core premise that relics "recognize" the player rather than being purchased. Additional structural issues included Emergency Patch's in-battle design (dominated by Defend in all practical cases), the lack of an explicit Field Kit formula, hardcoded stage thresholds in Cache Shard (drift risk), and an underdefined Confirm hold/press disambiguation. All 12 blockers were resolved in the same session: RELIC_TRANSACTION_COMPLETE state added (Unit 01 hands lift), Emergency Patch redesigned to MAP_EXPLORE, DWELL_REVEAL 300ms threshold specified, Field Kit Formula 3 added, Cache Shard formula updated to use xp_threshold_for(), economy calibration targets set, Scrap carry-over rule stated, Journal narrative forward contract documented, and Unit 01 "mobile" description corrected.
Prior verdict resolved: No — first review
