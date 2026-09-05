# Controller opening and reduced-motion acceptance

Status: pending hands-on acceptance. Automated polling, screen-handler and animation-contract tests verify behavior in the Node test environment. They do not establish controller hardware compatibility, visual comfort, pacing, or player enjoyment.

Use separate test progress. Record commit, browser, operating system, controller model/connection, viewport, motion preference and battle speed. Start with a standard-layout controller connected before page load; repeat the handoff checks with a controller connected after load.

| Check | Expected behavior |
|---|---|
| Title | A/Start reveals the full introduction, then a separate press initializes the game. The available action is clearly indicated. Starting once does not restart title music over the destination. |
| First guardian | D-pad/stick and A/Start can complete Begin → free hatch → Skip → Continue or Explore Outer Grid. Focus is visible, and locked/disabled actions cannot be confirmed. |
| Intentional purchases | After each reveal, confirmation selects the displayed Continue/Explore action. A paid single/ten-pull requires deliberately selecting that button. Simultaneous A/Start or repeated presses during a hatch charge only one purchase. |
| Screen handoff | Hold A/Start or a direction while moving between Title, Hatchery, Outer Grid, battle and Forge overlays. The arriving screen does not act on that held input; release and press again to continue. |
| Reconnect | Unplug/reconnect, or change the primary controller with Confirm held. No purchase, battle or menu action fires on the first observed state. Subsequent new presses work normally. |
| Outer Grid loop | Follow the objective, choose a crossing, inspect the cache, select the party, fight, retry after a loss, claim the return reward and enter the Forge using controller input. |
| Forge menus | Open each available station. D-pad/stick moves visible focus across enabled buttons; A/Start confirms; B/Select closes. Scroll longer logs with bumpers. World movement stays paused while a menu is open. Keyboard Tab and pointer actions still work. |
| Campaign party | Bumpers change the primary guardian. Selecting the current reserve swaps the previous primary into reserve. Y cycles reserve choices including NONE; primary and reserve remain distinct. Battle starts with the displayed party. |
| Calm hatch | With reduced motion enabled, an egg hatches without flying particles, shaking or a screen flash. The guardian reveal and Continue/Explore controls still appear. |
| Calm combat | At 1× and 2×, critical hits, shields, misses, status/damage numbers and KO outcomes remain legible without camera zooms, rapid flicker, travelling projectiles or fragment bursts. Contact and completion occur once in the expected order. |
| Normal combat | With reduced motion disabled, authored attack strips, signatures, critical cues and hatch effects still play normally. No turn hangs at contact or completion. |
| Readability | At 390px and desktop size, focus, controller hints, damage numbers and CRITICAL/MISS/BLOCKED cues are visible; scrolling reaches the selected menu action. No horizontally clipped controls. |

Record any coaching needed and accidental selections. Time Start → first meaningful route choice → first fight → Forge return, then compare with `docs/playability-playtest.md`. Keep these gates open until observed in real browsers with physical input.
