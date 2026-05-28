# Campaign Map — Review Log

## Review — 2026-05-24 — Verdict: APPROVED (Revision 5)
Scope signal: XL
Specialists: None (lean mode — solo analysis)
Blocking items: 2 (resolved) | Recommended: 5 (resolved)
Summary: Revision 4 introduced the Field Kit consumable and resolved the previous_node_id trap loop, but AC-CM15c was written with incorrect flag reset timing — expedition_field_kit was specified to reset at HUB_RETURN, contradicting the Shop GDD's "In Pack" semantics which require the flag to persist through HUB_RETURN until Bulkhead departure. Additionally, uncleared BOSS nodes in FREE_ROAM were not covered by Rule 22 or AC-CM48, which only specified "cleared BOSS nodes" — uncleared optional bosses would have auto-triggered in post-game. Both blockers fixed with surgical edits. Five recommended revisions applied: mid-expedition loadout screen "roster list" wording clarified, scar_nodes[] ownership added as Singularity forward contract, Field Kit greying rule added (Rule 9a + AC-CM15d), and AC-CM15c verify step clarified. All formulas verified at boundary values — no degenerate outputs.
Prior verdict resolved: Yes — 14/14 blockers from prior review (revision 4) confirmed addressed; revision 5 resolves 2 new gaps introduced by revision 4's Field Kit additions.

## Review — 2026-05-24 — Verdict: APPROVED (revision 4 applied in-session)
Scope signal: XL
Specialists: game-designer, systems-designer, economy-designer, ux-designer, qa-lead, creative-director
Blocking items: 14 | Recommended: 6
Summary: Third re-review of the Campaign Map GDD. Creative director verdict: MAJOR REVISION NEEDED (CD-GDD-ALIGN: REJECT), with three tiers of work identified. All 14 blockers resolved in-session. Key structural fixes: (1) Field Kit consumable added (shop-purchased, full HP restore, 1/expedition) addressing unvalidated HP economy and defeat calibration; (2) `previous_node_id` update timing corrected from arrival-based to departure-based, eliminating a COMBAT node defeat trap loop; (3) Dragon Progression GDD updated — Passive Bench Resonance accumulation path added alongside Active Resonance, resolving a direct contradiction with Campaign Map Rule 9 and AC-DP92a; (4) mid-expedition swap locked to expedition party only, closing a gate exploit; (5) gate position authoritative rule added, resolving four-location contradiction; (6) XP decay structural trap (L46+ vs Act 3 ceiling enemies) addressed via EC-XP-01 edge case and Field Kit mitigation. Six recommended items addressed including Scraps application path, Fusion Engine upstream dependency, BASE_XP description fix. Hatchery element soft-pity reclassified as a Hatchery implementation blocker (Campaign Map specified the contract correctly). User accepted revisions and marked Approved without re-review.
Prior verdict resolved: Yes — all 14 blockers from this review pass resolved in revision 4.

## Review — 2026-05-24 — Verdict: MAJOR REVISION NEEDED (post-revision: In Review, revision 3 applied)
Scope signal: XL
Specialists: game-designer, systems-designer, economy-designer, ux-designer, level-designer, qa-lead, audio-director, creative-director
Blocking items: 18 | Recommended: 11
Summary: Second review of revised GDD. Six of seven specialists independently flagged COMBAT node revisit behavior as undefined — the most convergent signal of any review to date. Formula 1 contained a factually wrong worked example (L49 vs L40 showed Final XP=20; correct is 5, decay fires). Act 4 gate lacked element-pity mechanism, progress indicator, and LORE node teaching the six-element concept, creating a potential 7-18 hour progression plateau. Benched dragon design contradicted Dragon Progression Resonance intent. All 18 blockers resolved in-session: COMBAT cleared-once model adopted, expedition XP penalty on defeat, benched Resonance charges, Hatchery soft-pity cross-contract, matrix LORE node + HUD tracker, formula corrected, 6 new save fields, spec ACs fixed. Pending re-review in clean session.
Prior verdict resolved: Yes — all 19 blockers from 2026-05-23 review were addressed; this review surfaced 18 new blockers from the revised document.

## Review — 2026-05-23 — Verdict: MAJOR REVISION NEEDED (post-revision: In Review)
Scope signal: L
Specialists: game-designer, systems-designer, qa-lead, ux-designer, creative-director
Blocking items: 19 | Recommended: 4
Summary: Initial verdict was MAJOR REVISION NEEDED. Primary blockers included a three-way contradiction in the gate architecture (Firewall Gate was simultaneously a stage gate, a matrix gate, and had conflicting ACs AC-CM34 vs AC-CM22/Rule 10); an unresolvable "Mainframe Crown gate" requirement that had no corresponding GATE node; REST-node-only HP recovery never specified (Rule 8 implied full restore everywhere); and four missing save fields (unlocked_gates[], cleared_bosses[], loadout_hp[], previous_node_id). Design decisions confirmed by user: Act 4 gate → matrix_stabilized = true (Spine Access gate); HP recovery → REST-node-only; benched dragons → Dragon Progression is authoritative (no passive accumulation); element names corrected in entity registry (Water→Ice, Earth→Stone, Wind→Storm, +Venom). All 19 blockers resolved in-session. GDD updated to In Review status pending optional re-review.
Prior verdict resolved: No — first review (directly to revision)
