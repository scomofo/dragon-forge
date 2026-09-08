# Prism / Synthesis Resonance

Prism is the ninth owned guardian. Expeditions remain one active guardian and one reserve.

## Identity and recruitment

The canonical browser recipe is **Light + Void = Synthesis**. Stabilize the Singularity to awaken Lumen, then recover its preserved Void imprint and awaken Null at the Forge. With both parents owned, return to **Resonance Fusion**, create the Synthesis resonance, and awaken Prism. Forging and awakening are separate, persistent, one-time milestones. They spend no salvage, consume neither parent, retain all progression, and preserve the selected expedition pair. Prism can then be selected at the Guardian Nursery.

The imported rig keeps Void's diamond frame and its original texture slots byte-for-byte, then fills the reserved bottom atlas row with hard gold-and-white Light panes. This combined silhouette follows the browser art identity. It hovers and uses the existing grounded player collider; it cannot cross walls or missing decks. No planted-foot simulation is claimed.

## Native four-slot kit

These are deterministic native balance values. They are not a claim of turn-based damage equivalence.

| Slot | Technique | Damage | Heat | Cooldown | Windup + recovery | Reach |
|---|---|---:|---:|---:|---|---|
| 1 | Convergence Shard | 26 | 0 | 0.55 s | 0.12 + 0.20 s | 3 m |
| 2 | Void Rift | 32 | 22 | 3 s | 0.26 + 0.30 s | 7.8 m |
| 3 | Radiant Beam | 36 | 26 | 4 s | 0.28 + 0.32 s | 8 m direct line, 0.7 m half-width |
| 4 | Recompile | 46 | 38 | 9 s | 0.36 + 0.40 s | 5 m radial |

Void Rift pushes an exposed ordinary enemy up to 1.25 m through collision-aware movement. Bosses and enemies with a locked attack warning remain anchored. Radiant Beam is one direct aimed attack in a fixed 1.4 m-wide corridor, not a widening cone or persistent field. All techniques retain normal line-of-sight, range and shield checks.

## Recompile and Advantage adaptation

Browser Advantage cannot literally copy a target affinity here: the native enemy runtime has no target-affinity field. Recompile instead selects the strongest **existing status payoff** separately for each target at authoritative contact:

| Existing target status | Selected payoff | Damage multiplier |
|---|---|---:|
| Chill | Fire shatter | 1.40× |
| Charge | Storm discharge | 1.50× |
| Toxin, one to three stacks | Venom detonation | 1.25×, 1.50×, 1.75× |
| No eligible status | Neutral hit | 1.00× |

The highest multiplier wins. Ties prefer Fire, then Storm, then Venom. Only the selected status is consumed and only after the attack deals actual damage. Other marks remain available. A closed shield, miss, blocked line of sight, or cancelled windup consumes no status. Selecting a payoff does not add a new elemental mark or change Prism's guardian identity.

Synthesis grants no healing, Null Reflect, Phase, thermal relay power, new ailment, or accuracy system. The inherited Shadow, Void and Light kits keep their own behavior.

## Save contract

Schema 11 adds only `synthesis_forged` and expands the guardian domain to nine. A fresh campaign and every valid earlier migration begin with Synthesis unearned. Owning Prism requires its forged resonance and both earned Light and Void parents. Finished schema-10 saves retain their existing Light reward. Valid schema-9 and earlier finishers still receive earned Light through the established migration; unfinished saves receive no Light.

Migration preserves prior guardian order, the active guardian, selected pair, milestones, salvage, upgrades and modules. Loading does not rewrite source bytes. The first successful write retains the exact previous bytes in the existing backup. Unknown, duplicate, future or unearned ownership and invalid pairs remain rejected and protected from overwrite. Forge Trial records keep separate schema 1 and use the shared guardian domain; a trial cannot unlock Prism or grant campaign rewards.

## Review and release acceptance

The committed imported model must pass independent glTF validation, and its authored clips must match contact timings. Source and exported runtime acceptance cover real Forge/Nursery routing, unchanged parents and pair, all four techniques, shield-preserved marks, collision-aware displacement and status selection. The inherited stack, neutral/rim animation inspection and campaign captures must pass under Compatibility and genuine Forward+.

Fresh editor and Windows/macOS/Linux packages must identify the same feature revision and execute the shared Synthesis acceptance through their own exported runtime. Passing automation does not certify human balance, physical-controller feel, target-GPU frame times or an unassisted playthrough. Existing soundtrack recordings and track choices are preserved.
