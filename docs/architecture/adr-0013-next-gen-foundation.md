# ADR-0013: Next-Generation Dragon Forge Foundation

- Status: Proposed
- Date: 2026-09-05

## Context

Dragon Forge currently has two important implementations:

1. The browser cartridge, which is the current 1.0 source of truth for systems, balance, content, music identity, and authored progression.
2. A Godot 4.6 research runtime with simulation, world, screen, save, input, audio, tests, and tooling already established.

ADR-0011 intentionally froze the Godot runtime while the browser build was finished. That remains sensible for the existing 1.0 line.

A separate next-generation game, however, has a different goal: use the existing game as foundation and inspiration while exploiting modern real-time graphics, animation, simulation, and CPU/GPU capability.

## Decision

Create the next-generation game as an explicitly separate development line based on the existing Godot project.

This does **not** replace the browser cartridge or invalidate ADR-0011 for the existing game.

The next-generation line may reinterpret presentation and combat while preserving canonical Dragon Forge concepts, including:

- core dragon identities and silhouettes,
- Forge/hatch/fusion/evolution loop,
- elemental relationships,
- authored boss-pattern philosophy,
- four-zone progression,
- Singularity/corruption mythology,
- soundtrack identity.

The first engineering target is a small vertical slice, not a complete port.

## Why Godot

The repository already contains a native Godot 4.6 project with useful architecture and tooling. Reusing it reduces bootstrap cost and lets the project validate modern rendering and spatial gameplay without discarding existing work.

The Godot runtime should be treated as a foundation rather than a strict port target. Browser engine logic may be reused where its rules remain appropriate, but next-generation mechanics are allowed to diverge when required by real-time spatial play.

## Architecture principle

Preserve the strongest existing separation:

**simulation/data != presentation**

Pure rules should remain testable independently of cameras, particles, meshes, animation, and shaders.

New runtime code should be organized around:

- core state and persistence,
- combat simulation,
- dragon actors and abilities,
- world/exploration,
- Forge progression,
- presentation/VFX/camera,
- canonical data.

## Rendering principle

Modern rendering is used to reinforce the authored visual language, not replace it with generic realism.

Priority features include:

- authored 3D environments,
- strong silhouette-first dragon models,
- GPU particles,
- dynamic lighting,
- volumetric atmosphere,
- decals,
- shader-driven elemental and corruption effects,
- animation blending,
- scalable quality presets.

Combat telegraphs take precedence over visual density.

## Gameplay principle

The next-generation combat target is kinetic tactical combat rather than either pure turn-based menus or unrestricted character-action combat.

Initial target:

- one active dragon plus reserve,
- four equipped abilities,
- dodge/guard timing,
- visible enemy tells,
- authored boss phases,
- elemental arena interactions,
- tactical swaps.

This model must be validated in the vertical slice before broader systems are committed.

## First milestone

A 15–25 minute playable sequence:

Forge -> hatch starter -> Outer Grid -> two encounters -> mini-boss -> permanent core reward -> return to an upgraded Forge.

The milestone exists to answer five questions:

1. Does movement feel good?
2. Does the dragon feel physically present and distinctive?
3. Are combat tells readable amid modern VFX?
4. Do elemental environment interactions add real decisions?
5. Does returning to the Forge feel rewarding?

## Consequences

### Positive

- Reuses substantial repository knowledge and native runtime scaffolding.
- Preserves the completed browser game.
- Allows a modern visual identity without forcing a full rewrite upfront.
- Creates a measurable vertical-slice gate before expensive content production.

### Negative

- The browser and next-generation lines can diverge mechanically.
- Assets will require a new production pipeline for models, rigs, materials, VFX, and environments.
- Some pure browser systems may not map cleanly to spatial real-time play.
- Two product lines increase documentation and canonical-data discipline requirements.

## Guardrails

- Do not delete or overwrite the browser cartridge.
- Do not bulk-port every browser screen before the slice is validated.
- Do not chase open-world scale.
- Do not add large dragon rosters before one dragon is excellent.
- Do not let post-processing obscure enemy tells.
- Do not replace the existing soundtrack unless explicitly requested.
- Keep save data for this line namespaced separately from 1.0.

## Follow-up

If the proposal is accepted, the next implementation PR should create a minimal `nextgen` vertical-slice scaffold in the Godot project: third-person/elevated movement, a test arena, one dragon actor, one enemy actor, camera rig, one elemental interaction, performance counters, and quality presets.
