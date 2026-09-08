# Umbra / Shadow Resonance

Shadow is the sixth owned guardian in the native Reconnection line. Expedition capacity remains exactly two live guardians.

## Source-of-truth identity

The browser art bible defines Shadow as `negative-space gap` with the `holed-wolf` silhouette: a broken contour with missing chunks that must read as a hole rather than a recolored animal. The native model must preserve that identity.

The browser alchemy table defines `Fire + Venom = Shadow`. Native Shadow resonance therefore uses Magma + Nox directly at the Forge. Both parents and all prior progression are retained; there is no catalyst, RNG roll, salvage cost, or destructive parent consumption.

Canonical browser Shadow techniques retained by name are **Shadow Strike**, **Void Pulse**, and the signature **Phase Strike**. **Umbral Wake** is the bounded fourth native technique required by Reconnection's four-slot real-time combat layout.

## Phase

Umbra is a high-speed, lower-HP guardian. Phase is session combat state, not saved campaign progress.

- A real incoming hit that intersects Umbra's active dodge i-frames grants one Phase.
- Phase is capped at two.
- Merely pressing dodge grants no Phase.
- Phase Strike gains +30% direct damage per stored Phase.
- Stored Phase is consumed only when Phase Strike actually damages a target.
- A shield-blocked Phase Strike preserves stored Phase.
- Enemy and boss shields remain authoritative. The browser `ignoreDefend` signature flag is **not** translated into native shield bypass.

This preserves the source fantasy—attacking through timing and position—without deleting the established Reconnection shield/counterplay rules.

## Save contract

Schema 8 adds only `shadow_forged`. Valid schema-7 saves migrate in memory with the flag false. Loading a legacy save does not rewrite it; the first successful later write preserves the prior exact bytes through the existing backup behavior.

## Release gate

Shadow is not considered shipped until the committed negative-space model is independently validated, real world routing proves dodge-earned Phase plus shield-preserved/landed Phase Strike behavior, OpenGL and Forward+ captures pass, and fresh editor plus macOS/Windows/Linux packages execute their updated schema-8/Shadow smoke checks.

Release evidence must come from the permanent read-only workflows on the final user-authored feature head. Temporary mutation/helper workflow commits are never treated as release evidence by themselves.
