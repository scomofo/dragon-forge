---
name: project-campaign-map-review
description: Campaign Map GDD — adversarial UX review findings; fourth pass 2026-05-24 adds 5 new blockers and 7 recommended against Revision 3; prior passes retained below
metadata:
  type: project
---

Adversarial UX review of campaign-map.md completed 2026-05-24 (fourth review pass — targeted interrogation of 6 specific interaction design areas on Revision 3 GDD).

## Fourth-Pass Findings (Revision 3 — Six Probe Areas)

### BLOCKING

**REV3-BLOCK-1: Commit-on-release anti-pattern (AC-CM52b).** AC-CM52b says "input duration measured from button-down to button-up" — this means cursor_moved fires on button-UP, not button-down. Every navigation step is delayed by the full press duration. On rapid d-pad navigation, this creates consistent input lag. All console precedent fires navigation on button-down with pan activating at threshold if button is still held. AC-CM52b must be rewritten: cursor movement fires on button-down; pan activates at 0.25s threshold if the button has not yet been released.

**REV3-BLOCK-2: Camera pan at map boundary — no behavior specified (AC-CM52b).** GDD defines cursor visual nudge at invalid navigation direction (AC-CM02) but has no equivalent for camera pan hitting a world boundary. Silent clamp is indistinguishable from dropped input. An EC or AC must specify boundary behavior.

**REV3-BLOCK-3: GATE arrival position inconsistency across four GDD sections (AC-CM25, EC-NAV-04, EC-GATE-06, state machine).** The four sections give contradictory answers on whether the player IS at the gate node or at the pre-gate node after denial. More critically: if GATE arrival updates previous_node_id (as AC-CM11b implies for all non-BOSS nodes), defeat recovery after a gate-adjacent battle will land at the gate node rather than the node before it — a subtle but real state corruption. Fix: add a single authoritative statement that GATE arrival during MAP_GATE_DENIED does NOT update current_node_id or previous_node_id; verify all four sections say the same thing.

**REV3-BLOCK-4: Camera re-centering behavior completely unspecified (gap — no AC exists).** The GDD says the camera keeps the player node centred on 40+ node maps but does not specify: instant vs. animated re-centering, duration/easing if animated, whether the camera follows the avatar during MAP_TRAVEL or snaps on arrival, or what happens at act transitions. A programmer will invent this; it will feel wrong and require rework. A camera tuning knob and AC are required before implementation.

**REV3-BLOCK-5: matrix_stabilized() pulse fires with no scene/state gate (AC-CM52c, EC-MAT-02).** The 2-second full-screen white pulse fires whenever the matrix_stabilized() signal emits. That signal fires on any dragon acquisition event — including Hatchery pulls and Fusion completions that happen in Hub scenes, not the Campaign Map. EC-MAT-02 says the latch fires without interrupting current map state but says nothing about firing while the player is not on the map at all. A 2-second white pulse during a Hatchery pull animation would be disorienting. Fix: specify which scenes/states are allowed to host the pulse; specify deferred behavior (e.g., play on next MAP_EXPLORE entry) if the signal fires outside the Campaign Map.

### RECOMMENDED

**REV3-REC-1: No visual affordance for pan mode activation (AC-CM52b).** The 0.25s threshold is invisible. Player who accidentally enters pan mode gets no feedback. Prior review flagged as NEW-HIGH-A; still unaddressed in Rev 3. Require a mode indicator before UX spec is written.

**REV3-REC-2: Tooltip type label is an engineering string, not player-facing copy (AC-CM53).** Tooltip shows raw type field: "COMBAT", "BOSS", "GATE" etc. "BOSS" before arrival undercuts incremental discovery. "GATE" before attempt removes in-world framing. Specify player-facing tooltip type labels (e.g., "Encounter", "Waypoint") or confirm raw strings are intentional with rationale.

**REV3-REC-3: 500ms tooltip inaccessible during active navigation; tooltip/pan timer interaction unspecified (AC-CM53).** Active navigation resets tooltip timer — player navigating never sees tooltips. This is by design but GDD presents tooltip as an information system when it functions as an ambient curiosity. Also: d-pad hold dismisses tooltip before pan threshold fires — the interaction between 500ms tooltip timer and 0.25s pan timer is unspecified.

**REV3-REC-4: gate_denial_count fires without meaningful-progression gate (AC-CM25b).** Skye note appears on 2nd denial regardless of whether player has done anything useful since the 1st denial. Counter also means a player returning to a file years later sees the Skye note on their first denial in that session. GDD considered this but resolved it as a counter-only mechanism. Escalation logic is a genuine design decision not made.

**REV3-REC-5: Cross-act camera state at fade-in unspecified.** Act transition fades to black and back in. Camera position at fade-in is undefined — large camera jump masked by fade if map is one continuous graph, or per-act camera regions are undefined.

**REV3-REC-6: Matrix tracker is Campaign Map HUD only — Hub pull decisions made without matrix progress visible (AC-CM54).** Hatchery is the primary acquisition vector for closing the matrix. A player making pull decisions in the Hub cannot see matrix progress. GDD should explicitly confirm map-only is intentional with rationale or add Hub tracker.

**REV3-REC-7: matrix_stabilized() white pulse has no photosensitivity opt-out path (AC-CM52c).** 2-second slow wash is probably WCAG-compliant on flash frequency, but no reduce-motion/disable-flash accessibility option is mentioned. GDD should confirm whether this event is exempt from any planned accessibility mode.

### ADVISORY

**REV3-ADV-1: 0.25s threshold default rationale undocumented.** Safe range is 0.15–0.40s; 0.25s is the second-lowest viable value. Physical d-pad presses vary 80–300ms — rapid navigation can accidentally hit 0.25s. 0.30–0.35s would reduce accidental pans. Rationale for choosing 0.25s not documented.

**REV3-ADV-2: Element icons not required to be distinguishable without color (AC-CM54).** Matrix tracker accessibility requirement missing. Icons must be distinguishable by shape, not color only, per accessibility checklist.

**Why:** Blocks implementation of input system, camera system, and matrix pulse if unresolved.
**How to apply:** All BLOCKING findings must resolve before Campaign Map UX spec is written or any input/camera/pulse code begins.

Adversarial UX review of campaign-map.md completed 2026-05-23 (third review pass — targeted interrogation of 8 specific design questions on Revision 2 GDD).

## Third-Pass Findings (Revision 2 — Targeted Interrogation)

### New Blockers from Third Pass

**NEW-BLOCKER-A: COMBAT auto-trigger has no cleared state — backtracking forces mandatory re-combat.** Rule 4 (free backward navigation) + Rule 22 (COMBAT auto-trigger, no cleared state) + Tuning Knob `ACT_COMBAT_NODE_MINIMUM` (8+ per Act 1) = mandatory 8+ battles on every return trip to the Hub. Rule 13 rationale ("player has no choice but to fight, so defeat is forgiving") applies with equal force to backtracking yet is never addressed. GDD is internally inconsistent: the defeat rationale defends against unavoidable friction but the navigation design creates unavoidable friction without defense. Must resolve: define a COMBAT cleared state with "Replay?" prompt on revisit, OR explicitly state mandatory repeat combat is intentional with rationale.

**NEW-BLOCKER-B: Act 4 gate denial references an undisclosed system.** Spine Access denial text ("the matrix isn't complete — I'm still missing something") assumes the player knows (a) what the matrix is, (b) that 6 elements exist, (c) which element they are missing, (d) how to acquire it. The HUD has no elements-collected tracker (AC-CM54). The matrix_stabilized() event fires once at completion with no intermediate progress signal. No LORE node in the GDD is specified to explain the six-element requirement. The gate denial for Act 4 references a system the player may have had zero prior exposure to. This is categorically worse than Acts 1-3 stage-gate denial.

**NEW-BLOCKER-C: MAP_BOSS_TRANSITION state is absent from the state table (still open from HIGH-03).** State table (States and Transitions) still does not include a BOSS transition state. Input handling during the 2-second BOSS auto-advance window is unspecified: d-pad behavior, cancel behavior, loadout accessibility are all undefined. The state machine jumps MAP_EXPLORE → MAP_BATTLE with a 2-second gap between that has no defined state.

### New High-Severity from Third Pass

**NEW-HIGH-A: D-pad tap/hold has no visual affordance for mode switch (partially addresses BLOCKER-01).** BLOCKER-01 is resolved for threshold value (now defined as 0.25s tuning knob, AC-CM52b). But no visual affordance specifies that pan mode has activated. The 0.25s boundary is invisible. Player holding d-pad for 0.25s gets pan instead of navigate with no mode indicator. Additionally: pan input during node rest likely resets the 500ms tooltip timer — interaction between the two timeouts is unspecified.

**NEW-HIGH-B: REST node location under HP pressure has no efficient discovery path.** Camera centres on player; 40+ node map requires pan-exploring to find REST icon. No filter, no "nearest rest" HUD indicator, no sub-region overview. HP urgency peaks exactly when the player needs to find REST most efficiently but has the least time to pan-explore for it. Not addressed anywhere in the GDD.

**NEW-HIGH-C: Mid-expedition loadout screen still has no cancel state and no context header (ACC-01 + HIGH-05 still open).** No MAP_LOADOUT state in the state table. Cancel behavior on mid-expedition loadout undefined. No context header showing current node type or adjacent encounter element. Two distinct use contexts (pre-expedition at Bulkhead vs. mid-expedition tactical swap) use an identical screen specification.

### New Medium-Severity from Third Pass

**NEW-MED-A: Icon-to-type mapping is the actual discovery system but is never stated as such.** Tooltip (AC-CM53) is 500ms-gated and dismisses on d-pad input — inaccessible during active navigation. Node icons (sword=COMBAT, scroll=LORE, etc.) are the real-time discovery mechanism. The GDD presents tooltips as the discovery system but icons do the work. No legend, tutorial, or reference explains the icon vocabulary. This should be stated explicitly rather than leaving the tooltip as an implied primary discovery tool.

**NEW-MED-B: Acts 1-3 gate denial communicates direction but not magnitude.** "Push further" is equally uninformative at level 3 (7 levels to Stage II) and level 9 (1 level to Stage II). In-character language and actionable information are not mutually exclusive — the Skye note could be authored to communicate stage direction without exposing raw stats.

**NEW-MED-C: Pan-then-navigate has no residual benefit.** Camera pan (d-pad hold) is a preview mechanism only; the cursor does not move during pan. A player who pans to see a destination node must still press d-pad once per node to close the distance. Pan provides no navigation efficiency gain on a 40+ node map — it only reduces cognitive load by making the destination visible. The GDD treats pan as a navigation affordance but it is not one.

**Why:** Identifies interaction design problems that must be resolved before UI spec and implementation begin.

**How to apply:** When authoring the Campaign Map UX spec (`design/ux/campaign-map.md`), each of these findings must have a resolution before the spec is marked done.

## Blockers (prevent core task completion)

1. **BLOCKER-01: Tap vs. hold d-pad — hold threshold undefined.** The GDD specifies tap=navigate, hold=pan camera, but no threshold in milliseconds is defined anywhere. No tuning knob, no acceptance criterion. Implementation will invent a value; no test can verify correctness. Hub UX establishes d-pad as discrete-only; hold-to-pan is an undocumented second mode on the same button. Must add: threshold value, visual affordance for pan mode activation, and an AC.

2. **BLOCKER-02: Gate denial — no actionable path forward.** Lore-only denial text ("Hatchling allocation insufficient") does not communicate the mechanical requirement (dragon stage). No hint on second failure. No tooltip on GATE node before attempt. No pre-approach affordance. A player can be blocked from Act 2 indefinitely without knowing how to proceed. Minimum fix: hint escalation on second failure, OR GATE node tooltip includes stage requirement, OR loadout screen flags low-stage dragon on approach.

3. **BLOCKER-03: matrix_stabilized() — one-frame pulse is invisible.** One frame = 16.6ms. Imperceptible on LCDs. Can fire mid-battle, mid-travel, or during Hub animation. The audio chord is the primary signal; players without audio receive nothing durable. This is the Act 4 gate unlock — a one-frame flash is not sufficient for a milestone of this significance. Minimum: 2–3 second sustained visual effect. Must not be a modal per GDD aesthetic constraint.

4. **BLOCKER-04: READ_ONLY_FREE_ROAM — no signal to player that story is complete.** HUD is identical to normal map. Music change is subtle. Mirror Admin node activates silently with no explanation. Players will interpret missing content as bugs. Minimum: a persistent peripheral HUD indicator ("Story complete — exploring freely") that does not disrupt the aesthetic.

## High-Severity

5. **HIGH-01: D-pad navigation on 40–46 node map — no efficiency mechanism.** No fast-travel, no full-map-view mode, no path selection from overview. Cross-act traversal in post-game requires 20–30 individual d-pad presses. Camera pan (hold) repositions view but does not skip nodes. Will cause navigation fatigue during backtracking. Recommend: shoulder button "zoom out to full map" read-only view, or explicit acknowledgment this is intentional scope constraint.

6. **HIGH-02: AC-CM02 — silent rejection on invalid d-pad is an accessibility violation.** No audio on invalid input is indistinguishable from dropped input or input lag on controller. Hub GDD correctly uses denied SFX for unavailable stations (Rule 7). Map should match: soft rejection tone on blocked d-pad direction. AC-CM02 must be changed.

7. **HIGH-03: Boss entry 2-second auto-advance — cannot operate at user's pace.** No skip, no early-advance, no pause. Player cannot open loadout screen during 2s transition (state gap — no MAP_BOSS_TRANSITION state defined). Accessibility violation. Minimum fix: Confirm advances early; boss transition state defined in state table with loadout-unavailable specified explicitly.

8. **HIGH-04: Benched dragon XP — no UI affordance communicating the rule.** Loadout screen hides XP on benched slots but shows no label explaining why. "BENCHED" label does not communicate "earns zero XP." Every player who uses the bench will be confused when dragons return unchanged. Minimum: static "inactive — no XP earned" line per benched slot card.

9. **HIGH-05: Mid-expedition loadout swap — no context about current node.** Screen is identical to Hub loadout screen. Player cannot see current node type, adjacent enemies, or next encounter element while swapping. Tactical decision made blind. Minimum: show current node name + type as header on mid-expedition loadout screen.

## Medium-Severity

10. **MED-01: COMBAT node tooltip withholds element — discovery-by-blindness.** Tooltip shows name + type only (intentional per GDD). Player cannot prepare element strategy before entering a COMBAT node. GDD should confirm this is intentional with a designer note explaining what the player IS supposed to use for preparation (bench diversity? lore inference?).

11. **MED-02: Act transition feedback — HUD number increment as the only persistent affordance.** Screen fade + music change communicate the transition at moment of crossing. On reload, only the HUD act number persists. Player who misses transition audio gets only the number. GDD should confirm the HUD number is the intentional primary indicator and no additional durable signal is needed.

12. **MED-03: Benched dragon HP not visible in HUD.** Player must open loadout screen to check benched HP before deciding to swap. Unnecessary round-trip for a fast tactical decision. Recommend: compact HP indicators (dots or abbreviated bar) for benched slots in the HUD.

13. **MED-04: SCAR node visual language implies impassable.** Corrupted tile + static noise = genre-conventional "blocked path." Bridge SCAR nodes have a faint path-connection indicator (EC-SCAR-02) but SCAR tooltip behavior is unspecified ("no tooltip icon is shown" may mean no tooltip at all, removing the last passability cue). Tooltip behavior for SCAR nodes must be explicitly specified.

14. **MED-05: Corruption class transitions — no notification.** Class transitions (NOMINAL → ANOMALY → WARNING etc.) change HAZARD behavior, spawn SCAR nodes, apply visual filters — but the only signal is the HUD bar updating. Player mid-battle when class transitions misses it entirely. No diff on map re-entry from Hub. Minimum: brief peripheral HUD pulse + one-line callout when class increases.

## Accessibility

15. **ACC-01: Cancel button — completely unspecified on all map screens.** Controller support section names "confirm, cancel" but cancel is never assigned to any action on any screen. MAP_GATE_DENIED, MAP_LORE_DISPLAY, BOSS Replay prompt, mid-expedition loadout — none define cancel behavior. A mid-expedition loadout screen with no cancel exit could force an unintended swap. Every screen must define what cancel does.

16. **ACC-02: matrix_stabilized() has no text/visual equivalent for players without audio.** The one-frame flash + ascending chord combination means players without audio and without the reflex to catch a 16ms flash receive zero durable feedback on the game's most significant roster milestone. Audio-only signals are inadequate for accessibility. Must be resolved in conjunction with BLOCKER-03.

## Pre-existing findings (from 2026-05-22 review, still open)

- EC-GATE-03, ACT4_GATE_STAGE, COMBAT auto-trigger vs Replay contradiction, READ_ONLY_FREE_ROAM save contract — excluded from this pass per mandate; still open per GDD status.
