# Dual-Layer Structure: Overworld and Hardware Dungeons

## Production Direction

Dragon Forge is now framed as a two-layer 2D game:

1. **RPG / flight overworld** for travel, dragon handling, scouting, dogfights, and locating access ports.
2. **Side-scrolling hardware dungeons** for Skye-on-foot action, platforming, physical repair, analog relic use, and dense lore.

This keeps the fantasy-machine contrast readable. The overworld is the pastoral render. The dungeons are the physical ship.

## Overworld: Pastoral Render

The overworld remains the high-angle RPG map. The dragon is the main interface:

- Long-distance travel.
- Aero-logic and traction.
- Diagnostic Ping.
- Threadfall / purge zones.
- Bounty Hunter chase pressure.
- Discovery of hidden Maintenance Ports.

## Hardware Layer: Side-Scrolling Dungeons

When Skye dismounts at an Access Port, the game shifts to a classic side-view action-platformer.

Dungeon ingredients:

- Rusted airlocks.
- Circuit boards.
- Massive cooling fans.
- Fiber-optic bundles.
- Logic grids.
- Steam vents.
- Bit-rot floors.
- Primary Breakers / terminals.

The 10mm Wrench becomes a primary dungeon verb: tighten, pry, pull, jam, and physically override.

## Dungeon Examples

| Dungeon | Role | Core Mechanic |
| --- | --- | --- |
| Cooling Intake | Felix workshop/tutorial dungeon | Tighten pressure valves to stop steam leaks. |
| Southern Partition Airlock | First firewall breach | Navigate red laser grids and pull the Primary Breaker. |
| Great Buffer | Tundra storage vault | Hide in data-shielded alcoves during White-Out Purge. |
| Logic Core | Mainframe Spine interior | Rhythm/code-loop platforms unlock external vents. |

## Dragon Role in 2D

Skye is on foot, but the dragon remains present:

- Visible through background viewports.
- Breathes onto external heat sinks to expand internal platforms.
- Reveals hidden paths through Prism refraction.
- Catches Skye from void pits as a safety-net fail state.

## Bosses

Hardware bosses are Physical Anomalies:

- **The Indexer:** multi-armed sorter that tries to file Skye into disposal bins.
- **Sentinel Drone:** uses internal lighting as a weapon; Diagnostic Lens reveals safe spots.

## Implementation Hooks

- `res://scripts/sim/hardware_dungeon_data.gd` owns dungeons, mechanisms, hazards, dragon assists, safety-net logic, and physical anomaly bosses.
- `res://scripts/sim/world_data.gd` links overworld landmarks to dungeon IDs.
- `res://scripts/tests/sim_smoke.gd` covers the basic dungeon model.

## Design Rule

Lore should be richest in side-scrolling interiors. Overworld NPCs can point, warn, and mark; dungeons should show the machinery, scars, and physical truth of the Astraeus.
