# Resource Ticket and Inventory Foundation

## Purpose

Dragon Forge should use Godot Resources for data that needs to be inspected, reused, and plugged into UI without hard-coding every ticket or relic into scene logic.

This fits the game fiction:

- Sidequests are System Tickets, not favors.
- Analog Relics are physical objects that resist digital deletion.
- Digital Assets are flexible but vulnerable to admin permissions and garbage collection.

## System Tickets

A System Ticket represents a system deviation.

Examples:

- NPC dialogue loop.
- Memory leak.
- Threadfall breach.
- Unknown physical relic.
- Permission gate requiring Manual Override.

Important fields:

- Ticket ID.
- Title.
- Description.
- Severity/type.
- Target sector.
- Optional target MIDI frequency.
- Optional required analog relic code.
- Resolved state.

Design rule:

Tickets should feed the map, compass, notification popup, and sidequest logic from one source of truth.

## Quest Manager

The Quest Manager validates tickets.

Examples:

- Frequency handshake succeeds if player roar matches target frequency.
- Analog relic validation succeeds if the relic bypass code matches the ticket requirement.
- Resolving a ticket emits `sector_stabilized`, allowing the map to turn an error zone green.

Ticket lifecycle:

- `UNINITIALIZED`: the sector is healthy.
- `TRIGGERED`: an anomaly has been detected.
- `ACTIVE`: Skye has accepted the ticket via HUD/map.
- `VALIDATING`: Skye is performing the fix.
- `RESOLVED`: the sector is patched and can re-render.

Signal flow:

- `SignalBus.ticket_spawned(ticket_resource)`
- `SignalBus.ticket_updated(ticket_id, progress)`
- `SignalBus.ticket_resolved(ticket_id)`
- `SignalBus.sector_stability_changed(sector_id, value)`
- `SignalBus.permission_gate_breach_required(gate_id, required_code)`
- `SignalBus.analog_relic_used(relic_name, target_id)`

## Inventory Split

Inventory is split into two categories:

- Digital Assets: Source Shards, Static Shards, Mirror-Scales, dragon materials, code fragments.
- Analog Relics: John Deere manual pages, physical gaskets, crank handles, modem parts, radiator grilles.

Analog Relics are immutable relative to the simulation:

- Mirror Admin cannot delete them.
- Garbage Collector cannot classify them as stale assets.
- They have mass.
- They can enable Manual Override and physical bypasses.

## Inventory UI Direction

Digital Asset Grid:

- Traditional RPG grid.
- Blue glow, flicker, and System Layer sound.

Analog Relic Inspection:

- Future `SubViewport` inspection view.
- Relics should look solid, high-resolution, and out of place.
- Hidden codes, part numbers, and mechanical affordances can be discovered by inspection.
- `RelicInspector` provides the mouse-drag rotation hook for a future SubViewport inspection scene.

## Mapping Tickets to Relics

Some tickets require Analog Relics.

Example:

To repair a Logic Leak in the Southern Partition, Skye uses a Physical Gasket from the Hardware Husk to plug a steam pipe that the simulation mislabels as a Data Stream.

This keeps the Pern-like theme intact: primitive physical action fixes an advanced digital failure.
