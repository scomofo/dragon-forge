# Boss contract acceptance

Status: pending hands-on acceptance. Deterministic screen/engine tests cover the action rules; they do not prove that the signals are readable or the fights enjoyable.

Use separate test progress and record commit, browser, viewport, input method, battle speed and motion preference. Repeat key cases at 1×/2× and normal/reduced motion once those presentation options are available on the tested branch.

| Check | Expected behavior |
|---|---|
| Fuse deadline | Six completed turns reduce the fuse to zero. An early low-HP signature still counts down the fuse; it cannot postpone the seventh-turn attack. |
| Stored charge | At zero, the signal advertises guaranteed Detonation instead of a stored charged strike. The old charge is discarded and contributes no attack multiplier. |
| Status and counters | Freeze, Paralyze, Glitch and Blind cannot cancel, replace or make the fuse attack miss. Ordinary initiative remains: a faster finishing strike prevents the bomb acting. Defend halves its damage and reflection sends it back. |
| One fuse explosion | After the guaranteed attack, the signal reads Detonation spent and ordinary moves resume. The low-HP signature retains its normal accuracy/status rules before the fuse deadline. |
| Initial corruption | Before the first command, the signal names the affected regular slot. Its button keeps the original slot name, but marks CORRUPTED and displays Basic Attack's neutral element, power 40, accuracy 100%, and no status effect. |
| Actual uses | Using the affected slot fires Basic Attack and consumes one of two uses, including on a miss or reflected hit. Defend, a different move, a signature, a dual technique, a skipped action or being KO'd before acting does not spend a use. |
| Glitch interaction | If Glitch picks the corrupted slot, Basic executes and a use is spent. If it changes the command to a different slot, no corrupted use is consumed. |
| Burn and refresh | Every successful boss application or refresh of Burn selects a regular slot for the active recipient's next two uses. End-of-turn Burn damage, misses, reflection and failed status rolls do not rearm it. A faster enemy's new Burn affects the next command, keeping the current choice consistent with its preview. |
| Reserve ownership | Swapping leaves corruption with the affected dragon. The incoming guardian's buttons and signal remain accurate. New Burn on that guardian replaces the active corruption with one of its own slots. |
| Clear feedback | After two executed uses, the slot returns to its ordinary stats and the signal warns that another Burn can corrupt a move again. Check keyboard/controller/touch and a 390px viewport. |

Ask the player to explain when the bomb will act, name one working counter, and identify what a corrupted command will do. Record unexpected outcomes and coaching needed. Keep the acceptance gate open until observed playthroughs match these rules.
