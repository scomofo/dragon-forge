# Southern Partition Build Spec

## Purpose

The Southern Partition is the bridge from pastoral dragon RPG into techno-myth system administration. It should introduce firmware-style dragon evolution, Hardware Husk traversal, packet-loss visuals, and the first serious resource economy.

## Dragon Evolution: Sub-Routine Upgrading

Dragon evolution is a firmware update, not biological growth.

When a dragon reaches a required level, Skye must take it to a Data Altar in the Southern Partition and flash its code.

| Stage | Name | Visual Change | Functional Shift |
| --- | --- | --- | --- |
| 01 | Asset Base | High-fantasy scales, leather wings, organic creature silhouette | Basic traversal and narrative combat |
| 02 | Compiled Form | Geometric scales, hex-code eye glow, cleaner animation arcs | Unlocks Kinetic Recovery and elemental precision |
| 03 | System Daemon | Translucent wireframe wings, faint 440Hz hum, visible protocol geometry | Interacts with unrendered objects and bypasses Permission Gates |

Design rule:

- Evolution should feel like Skye is updating a trusted companion's operating system.
- The dragon should remain emotionally recognizable after each update.
- Visuals can become more technical, but the creature should not become a sterile tool.

## Data Altars

Data Altars are Southern Partition upgrade stations.

Expected interactions:

- Check dragon level.
- Check required mission flags or materials.
- Preview firmware change.
- Flash sub-routine.
- Unlock field ability and battle trait.

Suggested unlock mapping:

- Compiled Magma: thermal precision and stronger Thread char.
- Compiled Solar: better skybox leak visibility and relay signal boosting.
- Compiled Static: short-circuit invisible collision meshes and patch floor loss.
- Compiled Lunar: time bubbles and stronger MIDI frequency matching.
- Compiled Forest: anchor assets against de-rendering.

## Mission 13: The Thermal Overload

Narrative:

The Hardware Husk overheats after Mirror Admin interference. If the Central Logic Core melts, the simulation deletes itself permanently.

Location:

- Heatsink Chasm.
- Vertical Hardware Husk descent.
- Massive spinning cooling fans.
- Glowing liquid coolant that reads like lava.
- Static Discharge lightning made of `1`s and `0`s.

Required dragon:

- Overclocked Magma Dragon.

Core gameplay:

1. Dive down the Heatsink Chasm.
2. Dodge cooling fans and binary lightning.
3. Reset Thermal Sensors in sequence.
4. Manage Overclock heat damage and cooling windows.
5. Survive the HUD melting out.
6. Use Piano-Key Map audio cues when visuals become unreliable.

Technical twist:

- The HUD begins to melt as thermal pressure rises.
- Visual clarity degrades before player control does.
- The player must navigate by sound, reinforcing the MIDI systems.

Reward direction:

- Stabilize the Hardware Husk enough to unlock deeper Physicality Protocol systems.
- Unlock or improve dragon Overclock control.
- Add a major Solo Council resource-management lever: thermal headroom.

## Packet Loss Fog

Packet Loss Fog defines the Southern Jungle edge where the world has not fully rendered.

Visual direction:

- Dithered fog, not smooth volumetric mist.
- Void-colored pixels flicker in and out.
- Terrain silhouettes break into chunky gaps.
- The fog should feel like missing draw calls.

Shader direction:

```glsl
uniform float time;
uniform float fogDensity;

void main() {
    float dither = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453);
    float fogFactor = smoothstep(near, far, viewDepth);
    if (dither > (1.0 - (fogFactor * fogDensity))) {
        gl_FragColor = vec4(0.1, 0.1, 0.1, 1.0);
    } else {
        gl_FragColor = originalColor;
    }
}
```

## System Credit Economy

System Credits are earned by maintenance work and spent at Felix's Workshop.

Earn sources:

- Defragging Bonus: restore fragmented sectors.
- Asset Recovery: find real-world relics and missing manual pages.
- Threadfall Defense: preserve texture fidelity during global events.
- Solo Council Maintenance: resolve conflicts between G.E.O., B.L.O.O.M., L.U.M.A., and V.O.X.

Spend sinks:

- Data Altar firmware updates.
- Felix Workshop upgrades.
- Registry Fee to keep high-grade dragons safe from garbage collection.
- Tread, harness, thermal, MIDI, and clipping upgrades.

Design rule:

- Credits should reward repair and preservation, not grinding random combat.
- Registry Fees should create pressure, but not punish players for loving their dragon collection.

## Real World vs Sim World Post-Processing

Sim World:

- High saturation.
- Soft bloom.
- Organic particles.
- Pastoral motion and fantasy warmth.

Real World / Inside the Husk:

- Desaturated metal.
- Sharp shadows.
- Scanlines.
- Brushed aluminum.
- Industrial MIDI and fan hum.

Southern Partition should constantly stage the contrast between these layers.

## Build Priority

1. Data model for dragon firmware stages and field abilities.
2. Data Altar interaction in the Southern Partition.
3. Packet Loss Fog visual overlay/shader.
4. Mission 13 vertical Heatsink Chasm prototype.
5. System Credit economy hooks in sidequests and Felix Workshop.
