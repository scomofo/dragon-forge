# Opening and retry acceptance

Status: pending hands-on acceptance. Automated handler and engine checks cover the implementation; they do not establish visual readability, pacing, or player enjoyment.

Use test progress in a separate browser profile. Record browser, viewport, input method, normal/reduced-motion preference, and the current commit.

| Check | Expected behavior |
|---|---|
| First hatch | Begin, Free Pull, Skip and Continue work with keyboard and touch. The revealed guardian has a prominent Explore Outer Grid action, with an immediate objective and the Sentinel shield counter. The action remains after dismissing the reveal until Sentinel is defeated. |
| Repeat hatch inputs | Rapid repeated clicks, or alternating 1× and 10×, produce one paid pull operation while its animation is running. The reveal does not disappear when starting another hatch. Currency and the recorded pull count agree. |
| Learn from defeat | One relevant tactical tip explains a known rule or observed result. It does not claim an unobserved cause for the loss or prescribe grinding. |
| Direct rematch | Retry Battle starts the same encounter with full party HP and fresh battle state. Party setup, reserve, route return, and encounter parameters remain intact. Retrying does not grant rewards or advance completion. |
| Change setup | The separate button returns to the encounter's preparation screen/room. A new guardian can be selected; route checkpoints remain saved. Controller A/Start retries and B returns to preparation. |
| Daily and boss retries | The same daily snapshot and reward policy survive retry, including a shared challenge. Multi-phase bosses restart at phase one using the original scaled phases. A Mirror Admin loss cannot grant credits or completion. |
| Battle selection | Tab focuses native buttons; Enter/Space activates that button once. Arrows and controller directions include Swap, skip spent signatures/disabled actions, and follow the displayed focus. Removing a used dual tech cannot shift Defend onto another command. |
| Save warning during battle | Keyboard activation of Retry Save/Download does not also submit a battle command. Recovering storage keeps the current attempt mounted. |
| Narrow screens | At 390px, hatch controls, adventure handoff, tactical advice, and both defeat actions remain reachable by scrolling and readable without horizontal clipping. |

Time a fresh run from Start to first hatch, first meaningful route choice, first battle, and return to the Forge. Ask the player to explain their objective and one enemy signal without coaching. After a loss, record whether they change a decision on the next attempt. Use those observations to tune the 15–20 minute opening target.

Controller opening and reduced-motion implementation follow this pass. Their real-browser and physical-controller gates remain pending in `docs/controller-motion-playtest.md`.
