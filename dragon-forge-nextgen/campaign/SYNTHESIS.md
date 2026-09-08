# Synthesis / final roster guardian

Synthesis is the ninth and final browser-order guardian in the native Reconnection roster. Expeditions remain exactly two live field guardians.

## Canonical source anchors

- Browser alchemy is exactly **Light + Void = Synthesis** (and the reverse ordering is equivalent).
- Browser Synthesis stats are **95 HP / 30 ATK / 26 DEF / 24 SPD**.
- Browser move identity is **Void Rift**, **Radiant Beam**, and signature **Recompile**.
- Browser art plan is **Void frame filled with Light panes**, silhouette `diamond-frame-pane-fill`.
- It must read as Void + Light combined, not as another unrelated animal silhouette.

## Native recruitment contract

- Requires both **Null (Void)** and **Lumen (Light)** to be owned legitimately.
- Requires the completed Singularity state that earned Lumen.
- Uses Resonance Fusion at the Forge.
- Null and Lumen are retained. No parent consumption, RNG, salvage cost, hidden catalyst, or invented element recipe.
- Existing active guardian, expedition pair, upgrades, evolutions, cores, salvage, trial records and completion state are preserved.
- Synthesis can be benched or selected into either of the two expedition slots after awakening.

## Save contract

Schema 11 adds one earned flag: `synthesis_forged`.

- Valid schema-10 saves migrate in memory with `synthesis_forged = false`.
- Migration does not grant Synthesis automatically.
- Loading never rewrites the old bytes.
- The first successful later save preserves the exact prior bytes through the existing backup behavior.
- Sparse/reordered optional guardian rosters remain valid; ownership is still a set, not a forced recruitment sequence.

## Native combat direction

The four-slot real-time kit will retain the three canonical identities and add only one bounded basic technique for controller parity:

- basic: a low-cost Synthesis contact attack (native-only slot filler)
- **Void Rift**: Void-side ranged/control identity
- **Radiant Beam**: Light-side ranged identity
- **Recompile**: signature mechanic

`Recompile` must not bypass authoritative enemy/boss shields, duplicate rewards, rewrite save progression, or create a second damage engine. Its native `copyAdvantage` adaptation must be deterministic and testable against the existing world combat router.

## Art / release gate

The imported guardian must visibly combine Null's hollow diamond aperture with Lumen's rigid stained-glass panes. Final acceptance requires:

- committed editable first-pass model + four material maps + hash manifest,
- independent Khronos glTF validation,
- nine named clips matching the current guardian controller contract,
- real campaign/Nursery/Forge routing,
- schema-10 -> 11 migration and exact backup tests,
- two-slot party tests with nine owned guardians,
- shield-preserving Recompile tests,
- OpenGL and Forward+ captures,
- fresh Godot editor plus Windows/macOS/Linux standalone packages executing the Synthesis smoke checks.

Automated prepared-state verification is not a human balance/playthrough or target-GPU certification.
