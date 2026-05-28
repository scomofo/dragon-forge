---
name: project-shop-gdd-review
description: Adversarial AC review of Shop GDD (51 ACs, v2026-05-25) — 8 blocking gaps, 9 advisory gaps, state machine coverage audit
metadata:
  type: project
---

Conducted adversarial review of Shop GDD (51 ACs, updated 2026-05-25) on 2026-05-24.
Previous review (47 ACs) is superseded by this record.

**8 blocking gaps:**

1. AC-SH02 — "Cannot be activated" has no defined observable signal (no prompt / greyed prompt / audio tone). Untestable negative assertion.

2. AC-SH48 — "Hold for exactly 300ms" is not independently executable manually. Boundary test requires automated timed-input simulation or debug tool. Human tester cannot reliably hit 300ms.

3. AC-SH09/SH10 — "Same save write" is an implementation detail, not observable behavior. Rewrite to: both fields present simultaneously in post-purchase save data. Atomicity only verifiable via failure path (AC-SH16).

4. AC-SH16 — No defined write-failure injection mechanism. AC cannot be executed without a debug hook or mock save layer. Also missing: in-session rollback path (EC-1.1) distinct from force-quit path (EC-1.2).

5. AC-SH13 — "Distinct from INSUFFICIENT_FUNDS response" is subjective without a defined comparator. No precondition setup procedure (requires owned relic via debug or save edit). BLOCKING.

6. AC-SH32–SH44 (formula ACs) — Precondition states (specific dragon level/XP/HP) require debug tools not specified anywhere. Logic-type ACs must reference a GUT test file or specify debug state-injection procedure.

7. Missing AC: INSUFFICIENT_FUNDS exit — No AC covers auto-return from INSUFFICIENT_FUNDS to ITEM_FOCUSED. Only state in 10-state machine with zero exit coverage.

8. Missing AC: CONFIRMING dialog projected balance arithmetic — Logic-type assertion. No AC verifies displayed projected balance = player_scraps - item_price.

**9 advisory gaps:**

- AC-SH49: Acceptable as-is for manual test; add note that 299ms boundary requires automation.
- AC-SH50: Screenshot insufficient for animation ordering/duration. Video capture required. "Before" is ambiguous (start-before vs complete-before). Visual/Feel gate.
- AC-SH47: "Fixed slot positions" contradicts 4-item vs 7-item display variation. Rewrite to separate catalog identity from display count.
- Missing: Shop open balance freshness — no AC confirms displayed balance reflects post-battle save data on open.
- Missing: RELIC_TRANSACTION_COMPLETE dialogue — no AC confirms relic purchase triggers Unit 01 line distinct from consumable purchase.
- Missing: Defeat-return after HUB_RETURN repurchase — compound path (purchase→use→repurchase→use→defeat) has no dedicated test.
- Missing: First relic appearance no-fanfare — Visual/Audio Requirements say no sting; no AC enforces this.
- Missing: D-pad edge stops — no AC tests slot-1 left-stop or last-slot right-stop (no wrap).
- Missing: State machine priority rule — ALREADY_OWNED > INSUFFICIENT_FUNDS implied by AC-SH22 but never stated as rule. In-Pack + broke case unspecified.

**State machine coverage audit:**
- INSUFFICIENT_FUNDS: zero exit coverage (blocking)
- RELIC_TRANSACTION_COMPLETE: no dedicated exit AC; no dialogue-distinct AC
- DWELL_REVEAL: boundary test untestable manually
- ITEM_FOCUSED: no d-pad navigation or edge-stop AC; no In-Pack self-loop exit AC
- All other states have entry + exit coverage

**How to apply:** Block Logic/Integration stories on findings 1–8 before sprint start. Formula ACs (finding 6) require test fixture engineering before stories can be accepted. AC-SH16 requires a write-failure debug mechanism to be spec'd by technical lead before the atomicity story can be marked Done.
