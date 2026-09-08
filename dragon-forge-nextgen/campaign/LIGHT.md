# Light Guardian / Completion Reward Contract

Lumen is the eighth owned guardian; expeditions remain one active guardian and one reserve.

## Canonical identity and reward

`src/artBible.js` defines Light as a stained-glass winged biped with a wing-chevron pane silhouette, hard gold-and-white panes, and no Storm violet. The imported native rig follows that identity and hovers; its two legs do not imply planted-foot simulation.

`src/persistence.js` grants Light when the Singularity is completed and retroactively grants it to earlier finishers. Native Reconnection follows that reward: stabilizing the final pedestal adds Lumen once, without requiring Void or inventing a fusion recipe. Existing guardians, the active guardian, and the selected pair are retained. If Fire is the only owned guardian, Lumen becomes the first reserve. Existing party health, heat and cooldowns are not reset by the reward. At the Forge Nursery, Lumen can replace the reserve normally.

Light + Void = Synthesis is also implemented at Forge Resonance Fusion. After awakening Null, both parents can create Prism without consumption or changing the selected expedition pair. See [SYNTHESIS.md](SYNTHESIS.md).

## Native four-slot kit

| Technique | Native behavior |
| --- | --- |
| Prism Claw | Explicit native basic attack; 22 base damage, 0 heat, 0.55 s cooldown, 0.12 s windup + 0.20 s recovery. |
| Radiant Beam | Canonical named attack; 36 base damage, 22 heat, 2.8 s cooldown, 8 m reach, 0.26 s windup + 0.30 s recovery. |
| Solar Flare | Canonical named attack; one radial hit for 42 base damage, 32 heat, 7.5 s cooldown, 4.5 m reach, 0.32 s windup + 0.36 s recovery. It creates no persistent field. |
| Restoration | Canonical 25% maximum-HP self heal, capped at maximum HP and reporting actual healing; 34 heat, 12 s cooldown, 0.40 s windup + 0.32 s recovery. |

Restoration resolves once at authoritative contact, only for its living caster. It cannot revive, heal the reserve, reset cooldowns, grant invulnerability, or award any other guardian's resource. Cancelling the windup prevents healing while retaining the paid heat/cooldown. Both offensive techniques retain the normal shield, range and line-of-sight checks. Light cannot power thermal relays.

The native runtime has no random-accuracy or player-ailment model. Browser Dazzle, Solar Flare's random charge, and Restoration's status cleanse are therefore not claimed as implemented effects. The native kit implements deterministic attacks and actual self healing; these numbers are provisional native balance values, not browser turn-based damage equivalence.

## Save contract

Schema 10 introduced the Light guardian domain without adding persisted fields. Current schema 11 retains this completion reward and adds separate Synthesis resonance progress. Light is earned exactly by `finished`. Current completed campaigns must own Light, and unfinished campaigns cannot own it. Valid schemas 1–9 flow through full legacy validation before a completed campaign receives its earned Light reward. Migration never repairs malformed ownership, invalid expedition pairs or unearned progress by appending Light. Existing valid selected pairs remain selected; an implicit pair is materialized when necessary to retain it.

Loading migrates in memory without writing. The first successful write backs up the exact prior bytes. Forge Trial records retain their separate schema 1 and use the shared guardian domain.

## Release acceptance

The committed imported asset, migration and combat rules, real campaign/UI routing, full inherited stack, neutral/rim animation samples and gameplay captures must pass with both Compatibility and genuine Forward+. Fresh editor and Windows/macOS/Linux packages must identify the same feature head and run the shared Light contract through their own exported executables. These checks do not certify balance, target-GPU performance or an unassisted human playthrough. Existing soundtrack files and track choices are preserved.
