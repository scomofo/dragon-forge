# Outer Grid opening: acceptance pass

This is the first functional exploration route in the browser cartridge. It reuses existing art, encounters, rewards, and music. Scott owns soundtrack composition separately. The 15–20 minute opening is a pacing target, not a measured result. Browser interaction and visual acceptance remain pending.

## Route and rewards

Field Locker → Signal Approach → Signal Breach → Firewall Span → Overflow Vent → Return Gate. Choosing the lower crawlway at the span inserts Maintenance Cache before the vent. Each expedition keeps its crossing choice; New Game+ resets it.

Signal Breach uses the existing Firewall Sentinel fight. Winning opens the span. Overflow Vent uses the existing Buffer Overflow fight. Winning opens the Return Gate. Defeat returns to the same room, with retreat and retry available. Existing campaign wins count, so returning players do not have to repeat these fights.

The cache grants 15 DataScraps once. The return reward grants one pull's cost (currently 50 DataScraps) once, in addition to normal battle rewards. Both grants update lifetime scraps earned. Entered-route guidance takes priority over the Daily Challenge until the return reward is collected.

## Hands-on checks

Use a separate browser profile for a fresh save; preserve the player's existing save. Run the browser build with the repository's normal development workflow.

1. Start, hatch a guardian, and use **NEXT → EXPLORE**, or select an Outer Grid node on **MAP** and choose **EXPLORE OUTER GRID** (controller X). Read Felix's note and leave the locker. Confirm the objective makes the next destination clear.
2. Reach Signal Breach. Select a primary guardian and, if available, a distinct reserve. Read the shield tell and defend before attacking. Lose once: return to Signal Breach, retreat, and retry. Win: the same room should now show its cleared state and open the span.
3. At Firewall Span, choose the direct crossing. Confirm the other crossing closes and the vent is reachable. Reload or leave and return via the map: the room and crossing should persist.
4. Fight Buffer Overflow. Check that the heat briefing matches the observed counter. Win, reach Return Gate, claim the reward, and return to the Forge. Revisit the gate: the claim button must stay gone and scraps must stay unchanged.
5. In another fresh profile or New Game+, choose the lower crawlway. Visit the cache, claim 15 scraps, reload, and confirm it cannot pay again. Continue through the vent and home. Normal campaign progression beyond Outer Grid should still work.
6. Check a legacy save with both enemies defeated. Enter the new route, walk through without repeat fights, and collect the return reward once. Start New Game+ when eligible: room, crossing, cache, and return claims should reset while the collection and earned currency remain.
7. Repeat navigation using keyboard only, then controller, then touch. The focused room uses arrows/WASD to walk or select, E/Enter/Space to interact, and Escape for the map. Standard Tab/Enter also operates every action. Controller uses D-pad, A, LB/RB for primary guardian, X for reserve (including no reserve), Y to inspect, and B for map; A/Start also dismisses battle results. Touch uses the action buttons and native party selectors.
8. Check desktop and a 390px-wide screen, plus reduced motion. Text, primary actions, party selectors, and disabled-route explanations must stay readable without horizontal scrolling. Verify room focus after travel, visible selection, and sound controls without accidental navigation.

## Record before calling the opening polished

- Time from Start to first hatch, first meaningful choice, Sentinel clear, vent clear, and Forge return.
- Where a new player hesitated or needed coaching; ask them to explain the next objective and one enemy counter.
- Any loss caused by an unreadable tell, blocked control, or misleading matchup hint.
- Art or layout problems in each room. The current span is a written crossing choice over shipped art; its dedicated animation and stronger travel transitions remain future presentation work.

Automated coverage lives in `src/outerGrid.test.js`, `src/playerGuidance.test.js`, `src/battleController.test.jsx`, and the runtime asset manifest. These verify route gates, both branches, reward idempotency, party validation, save migration, battle-result persistence, controller result handling, New Game+, and referenced assets. They do not establish visual quality or how the opening feels to a new player.
