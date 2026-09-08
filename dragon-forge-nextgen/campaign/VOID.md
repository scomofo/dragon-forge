# Void Guardian / Resonance Contract

Void is the next P5 roster item after Shadow. Expeditions remain exactly two live guardians even as the owned collection grows.

## Source-of-truth identity

The browser art bible defines Void as a hollow crystal tetra / negative-mass crystalline silhouette. The native guardian should read as faceted, hollow and spatially unstable rather than as a dark recolor of Shadow.

The browser alchemy table only defines Void explicitly through `Light + Void = Synthesis`; it does not provide a recipe from the currently owned Fire/Ice/Storm/Stone/Venom/Shadow set. Native Reconnection therefore must not invent a parent-pair result. The bootstrap path will recover a preserved Void imprint/catalyst from an existing campaign location, then awaken it at the Forge without consuming existing guardians. This is a bounded native adaptation that preserves the original alchemy table.

## Recruitment and combat

After stabilizing the Singularity ending pedestal, recover the preserved Void imprint from the separate plinth in that chamber. Return to Resonance Fusion, stabilize the imprint, and awaken **Null**. No existing guardian is consumed; optional guardian recruitment order remains free. Null can be the first reserve or a later member of the collection, and an existing two-member expedition pair is retained.

- **Rift Shard**: bounded native basic attack, 24 base damage.
- **Void Rift**: canonical named technique, 32 base damage; a landed hit pushes an ordinary enemy up to 1.25 metres away.
- **Null Reflect**: canonical defensive technique adapted to a 1.2-second counter window. It halves real incoming damage. A survived, landed attack reflects the actual damage received, capped at 20, to that attack's source through the normal shield check. Dodged/missed/invalid hits and unowned environmental hazards cause no reflected attack. Reflected hits do not recursively create attacks.
- **Siphon Rift**: canonical named signature, 44 base damage; a landed hit pulls ordinary enemies up to 1.5 metres toward Null and restores 40% of actual dealt damage, capped by maximum HP. Shielded hits and whiffs restore nothing.

Displacement uses collision-aware swept movement. Bosses, dead/queued actors and enemies with locked attack tells remain anchored. It neither rewrites locked attack geometry nor opens shields. Null has 88% of Magma's base HP; Void grants neither Shadow Phase nor Venom Toxin and does not power thermal relays. All numbers are provisional native balance values, not browser turn-based damage equivalence.


## Save contract

Schema 9 adds only `void_imprint_recovered` and `void_forged`. Valid schema-8 saves must migrate in memory without write-on-load and preserve exact prior bytes on the first later successful write. Unearned ownership, malformed future states and invalid two-slot loadouts remain rejected.

## Release gate

Void is not shipped until the actual imported hollow-crystal guardian asset, world/HUD/Nursery integration, save migration, deterministic combat rules, full inherited regressions, dual-renderer captures, and fresh editor plus macOS/Windows/Linux packages all pass from the same exact head.
