# Diagnostic Map: Circuit-Board Continent

## Purpose

The overworld should read as a pastoral RPG map first, then reveal itself as a grid of backend partitions when Skye uses the Diagnostic Lens / Admin Overlay.

The map is not just geography. It is a live system-pressure display.

## Map Model

The continent is a grid of partitions:

- Husk center: high-fidelity rendering and Root Access.
- Southern Jungle: legacy 16-bit / Packet Loss area.
- Great Salt Flats: empty-cache traversal and low traction.
- Kernel / Lunar sectors: system interfaces and MIDI navigation.

The further a region is from the Hardware Husk, the more data rot and fragmentation can appear.

## Godot Implementation Direction

The current project uses a custom `Control` map renderer, not a `Node2D` map scene. Keep that architecture.

Map layers:

- Pastoral layer: existing tile colors, terrain icons, landmarks, player marker.
- Diagnostic layer: circuit-board fade, admin bounding boxes, Thread precipitation zones, Garbage Collector path, Husk ping.

Input:

- `toggle_diagnostic` uses Tab.
- Toggle is available when Skye has Root Access or the Diagnostic Lens.

## Diagnostic Flip

The flip should feel like parchment becoming ship schematic.

Visual rules:

- Cyan circuit traces fade in over the map.
- Hardware Husk emits a compass pulse.
- Admin nodes gain bounding boxes.
- Thread zones pulse red.
- Garbage Collector path appears as a moving white deletion route.

Implementation notes:

- `WorldMapView` should animate `diagnostic_fade` toward 1.0 or 0.0.
- Avoid replacing the map; the player should see both layers composited.

## System Pressure Map Elements

Thread Precipitation Zones:

- Red pulsing circles over skybox leaks and active Threadfall targets.
- Warns the player before de-rendering or Mission 11 pressure escalates.

Garbage Collector Path:

- White route line from the damaged backend toward New Landing.
- Should look like a deletion sweep trajectory, not a quest arrow.

Husk Ping:

- Cyan pulse from the Vault / Hardware Husk.
- Serves as a compass and reinforces the Husk as the system root.

Sector Status:

- Stable: green/cyan clean trace.
- Fragmented: orange warning trace.
- Critical: red pulse, Threadfall, or deletion route.

## Future Upgrade

A true `SubViewport` diagnostic view can come later if the game needs minimap render targets or split-map effects. For now, a custom Control renderer is cheaper, clearer, and matches the existing code.
