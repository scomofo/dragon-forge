# Dragon Progression — Review Log

## Review — 2026-05-22 — Verdict: APPROVED (fifth pass, revised in session)

Scope signal: L
Specialists: game-designer, systems-designer, qa-lead, economy-designer, creative-director
Blocking items: 4 resolved | Recommended: 9 addressed
Summary: Fifth pass found four blockers: the Dormancy mechanic rewarded benching (contradicting the "shared record" attachment fantasy) and was too small to drive behavior — resolved by inverting to active Battle Resonance charges earned through combat; Stage I→II and II→III crossings emitted no signals despite the Player Fantasy naming Stage I→II "the first signal" — resolved by adding `stage_advanced(element, from_stage, to_stage)` signal for all crossings; AC-DP94 had an unresolved design decision (pending queue vs. discard-with-log) — committed to discard-with-log; XP bar behavior at MAX_LEVEL was unspecified (formula produced empty bar) — resolved by specifying MAX badge. Seven additional ACs added (DP43a–d, DP63a, DP79a, DP92a) and three existing ACs tightened (DP40, DP43, DP98). Creative-director escalated the Dormancy and signals findings from advisory to blocking on pillar-coherence grounds.
Prior verdict resolved: Yes — fourth-pass NEEDS REVISION (6 blockers) resolved in prior session; this pass added four new blockers, all resolved in-session.

## Review — 2026-05-22 — Verdict: NEEDS REVISION (fourth pass, revised in session)

Scope signal: L
Specialists: game-designer, systems-designer, economy-designer, qa-lead, creative-director
Blocking items: 7 resolved | Recommended: 11 addressed
Summary: Initial review returned MAJOR REVISION NEEDED due to a cross-GDD XP formula conflict (Dragon Progression flat award vs. Approved battle-engine.md scaling formula), a flat XP curve that contradicted the "momentum not scarcity" pillar, Stage I 0.5× multiplier framing as "weak dragon" rather than Hatchling (undercutting the Wonder→Attachment arc), undefined XP_BATTLE_AWARD, no catch-up mechanic, an XP loop overflow vulnerability, and 5 ACs that were not independently testable. The creative-director additionally identified that "Tested Bond" — the stated player fantasy — had no system representation in the GDD, and that all six dragons shared an identical progression curve with no elemental identity in growth (both noted as advisory). All 7 blocking items were resolved in-session: battle-engine.md scaling formula declared canonical (Dragon Progression now references it), Stage I framed as Hatchling (art direction makes 0.5× read as youth not flaw), XP thresholds escalated to 50/80/120/200 XP per level across Stages I–IV, rest-XP bonus added (1.5× for up to 10 levels on neglected dragons), XP_MAX_AWARD clamp added to Formula 4, 5 ACs rewritten with runtime verification, and 8 new ACs added (AC-DP90–97) covering overflow, rest charges, save-load integrity, sprite context, and stageMult persistence. OQ-DP01 closed.
Prior verdict resolved: First review — MAJOR REVISION NEEDED → revised in session → pending re-review

## Review — 2026-05-22 — Verdict: NEEDS REVISION (fourth pass, revised in session)

Scope signal: L
Specialists: game-designer, qa-lead, systems-designer, creative-director
Blocking items: 6 resolved | Recommended: 1 addressed
Summary: Fourth pass found one critical validator bug (Edge Cases §5 hardcoded `dragon.xp >= 100` generated false negatives for Stage I/II and false positives for Stage III/IV — replaced with `xp_threshold_for(dragon.level)`), a missing save-repair general rule for rest_charges, a pillar-adjacent display bug (XP bar never reached 100% fill, contradicting the "Permission to Run at Full Power" fantasy — clamped to 1.0 at threshold−1), an unresolved Dormancy fiction/mechanic seam (why does passive listening make leveling faster — bandwidth mechanism now explained in prose), unspecified Astraeus scope (now bounded to local party), and an unaddressed OHKO policy direction (now stated as symmetric — NPC Shadow can also OHKO player dragons at Stage IV). The benching design intent was additionally documented as intentional party-rotation incentive. The creative-director escalated the bar-fill bug and Dormancy seam from advisory to blocking on pillar-coherence grounds. All 6 blockers resolved in-session.
Prior verdict resolved: Yes — third-pass NEEDS REVISION (3 blockers) fully addressed before this pass.
