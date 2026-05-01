# Map System Monitor and POI Alerts

## Purpose

The world map is both fantasy parchment and system monitor.

The player should be able to read the map in two ways:

- Pastoral: terrain, towns, arenas, routes, landmarks.
- Diagnostic: sector health, memory leaks, anchors, Thread storms, deletion routes, and restore points.

## Root Partition Layout

| Sector | Logic Name | Render Style | Hazard |
| --- | --- | --- | --- |
| Center | `sector_0_0` / The Hub | High Fidelity | Safe Zone |
| South | `sector_0_-1` / Southern Jungle | 16-bit Legacy | Thread Precipitation |
| West | `sector_-1_0` / Great Salt Flats | Low-Poly / Empty Cache | Frame Rate Drops |
| East | `sector_1_0` / Archives | Wireframe | Data Corruption |

The Hardware Husk acts as the root. Distance from the Husk increases the chance of puppet NPC loops, glitched geometry, and sector instability.

## POI Icons

Memory Leak:

- Icon: `!`
- Color: orange/red.
- Click behavior: sets a waypoint to the sidequest location.

Anchor / Restore Point:

- Icon: `A`.
- Color: cyan/green.
- Click behavior: future fast travel / restore-point routing.

Thread Storm:

- Icon: pulsing red circle.
- Color: red/white.
- Click behavior: sets waypoint to Threadfall defense.

Garbage Collector Path:

- Moving white route line.
- Shows deletion trajectory across the Southern Partition.

## Current Godot Direction

The current build uses `WorldMapView`, a custom `Control` renderer.

Do not replace it with a TileMap yet. The custom renderer is already handling:

- Smooth camera follow.
- Clicked tile routing.
- Diagnostic overlay.
- Threadfall overlay.
- Admin nodes.
- Objective markers.

Use the custom renderer until the game requires layered tile painting, collisions, or editor-authored map chunks.

## Interaction Rule

If the player clicks an adjacent tile, Skye moves.

If the player clicks a distant active system alert, the click sets a waypoint instead of producing a generic too-far message.

This makes the diagnostic map feel like a real system monitor: alerts are not just decoration, they are routing targets.
