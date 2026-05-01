# Final Crafting Tier: Source-Code Relics

## Purpose

The final crafting tier represents the total synthesis of pastoral fantasy and hardware reality.

These items are not found. They are compiled in the Loom of Life inside the Hardware Husk. Each master-work exists as both a high-fidelity digital asset and a physical bio-mechanical object.

## Core Materials

Final-tier crafting should require:

- Source Shards from Security Daemons.
- Real-World Components recovered inside the Hardware Husk.
- A Perfect 10 Grade dragon to stabilize the compile.
- System Credits or Registry Fees where the economy needs pressure.

## Source-Code Relics

| Item | Type | Ingredients | Final Property |
| --- | --- | --- | --- |
| Kernel Blade | Weapon | 5 Source Shards, 1 Manual Crank | Cuts through simulation collision boxes and can strike enemy hitboxes through walls |
| Paddock-Master Plate | Armor | 10 Mirror-Scales, 1 Tractor Radiator Grille | Immunity to Thread damage and protection from de-rendering in low-stability zones |
| 8R Ignition Key | Accessory | 1 JDLink Modem, 1 Heart of a System Daemon | Allows any dragon to Overclock, doubling speed and damage while rapidly building heat |
| B.I.O.S. Wing-Span | Mount Upgrade | 1 Prism-Tuning Fork, 100 Static Shards | Allows safe flight into the Sky-Box Leak and Unrendered Void |

## Crafting Process: Compiling the Asset

Final-tier crafting is a high-stakes mini-game that combines existing systems.

### Step 1: Thermal Loading

Heat the Biogel vats to exactly 180 C with Magma Dragon breath.

This should reuse the Thermal Equilibrium design language but raise the stakes. Too cold prevents compile. Too hot risks deformation or thermal runaway.

### Step 2: Code Injection

Use the unorthodox manual to input the correct part number / recipe code.

This is analog intervention, not digital hacking.

### Step 3: Harmonic Sync

The Loom plays a MIDI sequence. Skye roars back through the Piano-Key interface to lock texture, physical frame, and resonance together.

Correct sync:

- Item compiles as physical.
- Master-work flag is applied.
- World Layer audio becomes dominant.

Incorrect sync:

- Compile stalls.
- System Credits or thermal headroom are consumed.
- Optional lesser version can be created if the design needs partial success.

## Master-Work Flag

Compiled items are physically real enough that the Garbage Collector cannot delete them and the Mirror Admin cannot fully permission-lock them.

Rules:

- `is_physical = true`
- `has_analogue_bypass = true`
- Stabilizes Skye's Packet Integrity over time.
- Biases audio toward World Layer mechanical/organic sounds instead of System Layer hum.

Pseudo-code sketch:

```python
class CompiledItem(Item):
    def __init__(self, item_id):
        super().__init__(item_id)
        self.is_physical = True
        self.has_analogue_bypass = True

    def on_equip(self, player):
        player.packet_integrity_regen += 0.05
        audio.set_layer_bias(world_layer=0.8, system_layer=0.2)
```

## Synthesis Shader

The synthesis shader should show an item compiling from glowing wireframe into physical metal.

Visual direction:

- Bottom of object becomes physical first.
- Wireframe remains above the compile line.
- Cyan data edge marks the transition point.
- Compile progress should feel like a scanner welding reality onto data.

Shader sketch:

```glsl
uniform float compileProgress;
uniform sampler2D wireframeTex;
uniform sampler2D physicalTex;

void main() {
    vec4 wire = texture2D(wireframeTex, vUv);
    vec4 phys = texture2D(physicalTex, vUv);
    float scanLine = step(vUv.y, compileProgress);
    vec4 finalColor = mix(wire, phys, scanLine);
    float edge = smoothstep(compileProgress - 0.05, compileProgress, vUv.y) * (1.0 - scanLine);
    gl_FragColor = finalColor + (vec4(0.0, 1.0, 1.0, 1.0) * edge);
}
```

## Ultimate Craft: The Dragon Forge

The final craft is not an item. It is the transformation of Skye's lead dragon.

Ingredients:

- All Manual Pages.
- Mirror Admin Core.
- Source Shards.
- Perfect 10 dragon registry data.
- Physicality Protocol access.

Result:

- Lead dragon becomes the Administrator's Avatar.
- Skin becomes shifting liquid metal that reflects the Real World jungle.
- The dragon is no longer only a protocol. It is a bridge between simulation and physical reality.

Narrative power:

- Can reset the simulation.
- Can shut it down.
- Can anchor the Physicality Protocol and carry dragonkind into the Real World.

Design rule:

The player should feel that every major system fed this craft: grading, manual pages, Mirror Admin reconciliation, daemon fights, thermal precision, MIDI harmonics, and the Loom of Life.
