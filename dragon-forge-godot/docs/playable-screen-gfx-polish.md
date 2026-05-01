# Playable Screen GFX Polish

## Goal

Raise the moment-to-moment visual quality of the Godot runtime's playable screens, starting with Hardware Dungeons. The pass should make movement, hazards, mechanisms, anomaly pressure, exits, and the player silhouette feel like authored game presentation rather than placeholder rectangles.

## Scope

This pass focuses on `HardwareDungeonScene` because it is the clearest playable-screen weak point and already hosts several major route gates. The first implementation should be procedural/drawn Godot polish only. It should not require a new imported sprite pipeline, tilemap conversion, or large scene restructure.

## Visual Direction

Hardware Dungeons should read as physical Astraeus interiors under a fantasy simulation:

- Cooling Intake: rusted catwalks, warm turbines, steam pipes, coolant glow, analog valve equipment.
- Southern Partition Airlock: red permission firewall, warning bands, breaker hardware, moving binary checks, sealed access-port mood.
- Great Buffer: cold white storage vault, purge lanes, shielded alcoves, optical/scanner accents, Indexer pressure.
- Logic Core: dark vertical conduit, syntax blocks, laser reroutes, diagnostic safe spots, server-rack geometry.

The style should stay crisp, readable, and gameplay-first. Decoration must not hide jump platforms, active hazards, safe zones, or interaction targets.

## Rendering Design

Keep the scene as a custom `Control._draw()` renderer, but split drawing into clearer visual passes:

1. Room backdrop: base color, distant machine silhouettes, repeated panels, and room-specific background motifs.
2. Platforms: industrial catwalk slabs with bright top edges, dark undersides, bolts, and style-specific accent strips.
3. Hazards: inactive, telegraph, active, disabled, and revealed states must have visibly different treatments.
4. Mechanisms and exits: draw as small machinery silhouettes rather than plain blocks, with readable completion states.
5. Anomaly pressure: keep safe spots and attack lanes readable with pulsing outlines and labels.
6. Player: replace the current block placeholder with a small mechanic silhouette drawn from simple shapes: head/helmet, coat/body, boots, visor/accent, and wrench.
7. HUD: retain the current compact top HUD, but add a stronger panel frame, accent color per room, status strip, and less flat text presentation.

## Gameplay Readability Rules

- Platform top edges must remain the highest-contrast traversable surface in the room.
- Hazard fill can be atmospheric, but hazard outlines and labels must be clear.
- Safe spots must never share the same color treatment as danger lanes.
- Completed mechanisms should visibly change shape/color, not only message text.
- Exit locked/unlocked state should be visible at a glance.
- The player silhouette must contrast against all four room backdrops.

## Testing

Run the existing Godot smoke script after implementation:

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\DF\dragon-forge-godot' --script res://scripts/tests/sim_smoke.gd
```

Also launch the project normally and inspect each Hardware Dungeon route visually if possible:

```powershell
.\run-godot.ps1
```

The pass is successful when the dungeons look authored, hazards and boss pressure are easier to parse, and no existing route-gate or smoke-test behavior regresses.
