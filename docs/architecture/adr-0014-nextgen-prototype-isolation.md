# ADR-0014: Isolate the nextgen playable prototype

- Status: Implemented for the first prototype
- Date: 2026-09-05
- Builds on: ADR-0013 (next-generation foundation)
- Does not supersede: ADR-0011 (browser cartridge)

## Decision

Put the first spatial prototype in `dragon-forge-nextgen/`, a standalone Godot project **beside** `dragon-forge-godot/`, rather than changing the existing project's entry scene or adding new gameplay to its frozen runtime.

ADR-0013 proposed a nextgen scaffold inside the existing Godot project. Inspection of that project's `SaveIO`, global inputs/audio and screen-oriented bootstrap makes explicit isolation safer: a separate resource root cannot accidentally start the legacy autoloads or use its save namespace. The new code follows the native project's simulation/presentation separation and the cartridge's canonical identity, but real-time combat is an adaptation, not an unreviewed port or balance replacement.

## Constraints

- Existing browser and native research entry points remain untouched.
- No existing soundtrack or art asset is replaced.
- The new game uses `dragon-forge-nextgen-prototype` as its custom user-data directory.
- No broad roster, reserve/fusion port or other-zone expansion in this pass.
- Procedural geometry is explicitly prototype art. A model/rig production pipeline remains required.
- Quality/reduced-motion switches affect rendering only; critical tells are ordinary visible geometry and labels.
- Native tests and real-renderer captures are engineering evidence, not a playability/performance acceptance gate.

## Initial playable scope

Awaken Magma at the Forge, overload a conduit to open the breach, clear two Sentinel encounters plus a Warden variant, recover a core and install it in a visibly restored Forge. Movement, aim, four abilities, heat, dodge/guard, authored tells, one elemental interaction, quality presets, pause, milestone saving and retry are implemented. This compact prototype is not claimed to meet the proposed 15-25 minute opening target.

## Follow-up gate

Review native test logs and captures, then measure actual play on Scott's target hardware. Prioritize any input, readability, pacing or performance failure before adding assets, mechanics or roster content. The next production-art pass should replace the procedural Magma model and its animation adapter without rewriting combat rules.
