---
name: project-shop-review
description: Shop GDD adversarial UX review findings — re-review 2026-05-24: 6 new blockers, 3 recommended; all must resolve before UX spec authoring
metadata:
  type: project
---

Shop GDD re-review completed 2026-05-24 (document last updated 2026-05-25). 6 blockers, 3 recommended findings. Prior 5 blockers partially resolved; see prior blocker status below.

**Why:** Shop is the Unit 01 interaction screen — gamepad-first, d-pad navigation, Confirm as the primary action button. Several interaction design gaps must be resolved before the UX spec can be authored.

**Current Blockers (must resolve before UX spec):**

1. **DWELL_REVEAL 300ms threshold too low for gamepad** — 300ms is in the lower third of the safe range (150–500ms). A deliberate purchase press can complete in 200–350ms on a face button. Players browsing while resting a thumb will accidentally trigger DWELL_REVEAL instead of CONFIRMING. No player onboarding for the mechanic exists in the GDD. Recommend raising to 400–450ms and adding a moment-of-activation cue (visual or audio). Also needs discovery path: how does the player learn this mechanic exists?

2. **Back/Cancel unspecified for ITEM_FOCUSED, DWELL_REVEAL; shoulder buttons unspecified** — Back from ITEM_FOCUSED is not in the state table (navigation trap risk). Back/Cancel during DWELL_REVEAL is unspecified. L1/R1 shoulder button behavior is completely absent — either spec them or explicitly exclude them.

3. **Confirmation dialog omits item description** — Dialog shows item name, price, current balance, projected balance. No item description. A player who short-presses without dwelling has zero information about what the item does. Critical for relics (175–225 Scraps, no immediate effect). Dialog should include a one-line description identical to DWELL_REVEAL text.

4. **"In Pack" Confirm: audio-only insufficient; Unit 01 line "optional"** — Audio-only response to a face button press is indistinguishable from input failure on PC with low audio. The UI Requirements section marks Unit 01's "already carrying" line as optional. The spec must commit: visual micro-feedback + audio tone (non-optional), haptic recommended.

5. **Back unspecified in INSUFFICIENT_FUNDS, ALREADY_OWNED, TRANSACTION_COMPLETE, DWELL_REVEAL** — State machine does not define whether INSUFFICIENT_FUNDS / ALREADY_OWNED auto-dismiss (time-triggered) or require input. ALREADY_OWNED: AC-SH13 says "any button" while state table says "any face button" — direct contradiction. TRANSACTION_COMPLETE: can the player skip Unit 01's response with Back?

6. **No accessibility section; DWELL_REVEAL_THRESHOLD has no player-adjustable accommodation** — Timing-sensitive interaction (sub-300ms press required for purchase) with no setting to adjust or disable. Players with motor control differences cannot reliably purchase. ALREADY_OWNED/INSUFFICIENT_FUNDS with no auto-dismiss timeout could block players indefinitely. Minimum: accessible threshold setting or dwell-disable option; auto-dismiss timeout for dismissable states; font size and contrast requirements.

**Recommended (can resolve during UX spec authoring):**

7. **7-item row: no consumable/relic grouping spec; resolution constraints absent** — "Visually grouped" is stated but no divider, gap, label, or HUD treatment separates slot 4 from slot 5. Players crossing from consumables to relics have no signal. Also no row width or reference resolution constraints specified.

8. **Relic reveal: no default focus on first post-Act-2 open** — Relics appear in slots 5–7. If default focus is slot 1, a player may not navigate the full row and miss the new items entirely. "No fanfare" is a valid aesthetic; "invisible to many players" is not. Consider: default focus set to slot 5 on first post-Act-2 open, or a one-time silent auto-pan.

9. **Projected balance 0: no consequence warning; prior advisory unresolved** — Prior review flagged this. Spending to 0 Scraps before Act 3 is a meaningful risk state. Color shift or note at projected balance 0 (or below cheapest consumable) is still not present.

**Prior Blocker Resolution Status:**

| Prior Blocker | Status |
|---|---|
| Dwell threshold undefined | Resolved (300ms specified) — but Finding 1 flags 300ms as wrong value |
| 7-item layout topology | Resolved (single horizontal row, stops at edges) |
| "In Pack" silent no-op | Partially resolved — audio tone added; visual and haptic still absent; Unit 01 line "optional" |
| ALREADY_OWNED exit "any button" | Not resolved — contradiction introduced (AC-SH13 vs. state table) |
| D-pad wrap undefined | Resolved (stops at edges, no wrap) |

**Existing open questions (not duplicated here):**
- OQ-SH01: BOSS_SCRAP_BONUS and HAZARD_SCRAP_BONUS values (blocked on Campaign Map data)
- OQ-SH02: Unit 01 visual design (Art Director)
- OQ-SH03: Battle Engine forward contract (Telegraph phase consumable actions)
- OQ-SH04: Unit 01 dialogue lines (Writer)

**How to apply:** When the user asks to author the Shop UX spec, check all 6 blockers are resolved first. Cross-reference [[project-dragon-forge-hub]] for Hub-level navigation decisions (Scrap HUD display, station focus model) that the Shop inherits.
