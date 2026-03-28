# Attack VFX Sprite Guide

## Overview

Each attack needs a **projectile sprite sheet** — an animated effect that travels horizontally across the arena from the attacker to the target. These are large, dramatic effects that dominate the screen during the impact phase.

## Sprite List (13 attacks)

### Fire Attacks
| Filename | Attack | Description |
|---|---|---|
| `vfx_magma_breath.png` | Magma Breath | Stream of molten fire/lava projectile hurtling forward, trailing ember particles and heat distortion. Orange-red (#ff6622, #ff4400, #cc2200). |
| `vfx_flame_wall.png` | Flame Wall | Rolling wall of flame sweeping horizontally, wide and engulfing. Bright orange-yellow core (#ffaa00) with red edges. |

### Ice Attacks
| Filename | Attack | Description |
|---|---|---|
| `vfx_frost_bite.png` | Frost Bite | Jagged ice shard/fang projectile, spinning with trailing frost crystals. Cyan-blue (#44aaff, #66ccff, #88eeff). |
| `vfx_blizzard.png` | Blizzard | Swirling ice storm vortex rushing forward, snowflakes and ice chunks. White-blue (#ccddff, #44aaff). |

### Storm Attacks
| Filename | Attack | Description |
|---|---|---|
| `vfx_lightning_strike.png` | Lightning Strike | Bolt of lightning arcing forward with branching forks and electric sparks. Bright purple-white (#aa66ff, #cc88ff, #ffffff). |
| `vfx_thunder_clap.png` | Thunder Clap | Shockwave ring/pulse expanding forward with crackling energy. Purple (#aa66ff) with white electric core. |

### Stone Attacks
| Filename | Attack | Description |
|---|---|---|
| `vfx_rock_slide.png` | Rock Slide | Cluster of boulders and rocks tumbling/flying forward. Brown-tan (#aa8844, #ccaa66, #665533). |
| `vfx_earthquake.png` | Earthquake | Ground-level shockwave — cracking earth/debris erupting upward as it travels forward. Dark brown (#665533) with tan dust (#ccaa66). |

### Venom Attacks
| Filename | Attack | Description |
|---|---|---|
| `vfx_acid_spit.png` | Acid Spit | Glob of toxic acid projectile, dripping and sizzling with trailing droplets. Bright green (#44cc44, #66ee66, #22aa22). |
| `vfx_toxic_cloud.png` | Toxic Cloud | Billowing poison gas cloud rolling forward, bubbling and noxious. Dark green (#228822) with bright green highlights (#66ee66). |

### Shadow Attacks
| Filename | Attack | Description |
|---|---|---|
| `vfx_shadow_strike.png` | Shadow Strike | Dark energy slash/blade projectile cutting through the air, trailing void wisps. Dark purple (#8844aa, #aa66cc) with black core. |
| `vfx_void_pulse.png` | Void Pulse | Orb of void energy expanding as it travels, distorting space around it. Deep purple-black (#330044, #8844aa) with faint glow edges. |

### Neutral
| Filename | Attack | Description |
|---|---|---|
| `vfx_basic_attack.png` | Basic Attack | Simple white energy slash/swipe arc. White-gray (#ffffff, #cccccc, #888888). |

## Specifications

### Sheet Format
- **Sheet size:** 1024 x 256 pixels (single horizontal strip)
- **Frames:** 4 frames, each 256x256
- **Layout:** Left to right: Frame 1 | Frame 2 | Frame 3 | Frame 4
- **Format:** PNG with transparent background (alpha, NO green screen)

```
┌────────┬────────┬────────┬────────┐
│ Frame 1│ Frame 2│ Frame 3│ Frame 4│  256px tall
│ Launch │ Travel │ Travel │ Impact │
│ 256x256│ 256x256│ 256x256│ 256x256│
└────────┴────────┴────────┴────────┘
         1024px wide
```

### Frame Sequence

The 4 frames tell the story of the projectile's journey:

1. **Frame 1 — Launch:** The attack forming/emerging. Smaller, concentrated, near the origin point. Energy gathering or projectile just released.
2. **Frame 2 — Travel (early):** Projectile in motion, growing/expanding. Trailing particles visible. Full speed.
3. **Frame 3 — Travel (peak):** Maximum size and intensity. This is the most dramatic frame. Particles, glow, and detail at their peak.
4. **Frame 4 — Impact:** The attack hitting/exploding. Burst, splash, shatter effect. Dissipating energy, scattered particles.

### Animation Behavior in Game

- The sprite sheet animates while translating across the screen from attacker to target (~0.6 seconds total travel)
- Frames advance as the projectile moves: Frame 1 at origin, Frame 4 at impact
- The projectile renders at **256x256px** on screen — these are meant to be large and dramatic
- Projectiles travel **left-to-right** in the sheet. The code will flip them horizontally when the NPC attacks (right-to-left)

### Art Style

- **16-bit pixel art** consistent with the dragon sprites
- **Bold, saturated colors** — these need to read clearly against dark arena backgrounds
- **1-2px black outlines** on the main projectile body
- **Particle trails** — embers, sparks, droplets, wisps trailing behind the projectile
- **Glow effects** — bright cores with softer outer glow (can be achieved with lighter pixels around the center)
- **Fill the 256x256 frame** — these should feel powerful and large. The projectile itself should be roughly 150-200px across at peak (Frame 3)

### Color Reference

Use the element color palettes from the game:

| Element | Primary | Glow | Dark |
|---|---|---|---|
| Fire | #ff6622 | #ff8844 | #cc2200 |
| Ice | #44aaff | #66ccff | #2288cc |
| Storm | #aa66ff | #cc88ff | #6633aa |
| Stone | #aa8844 | #ccaa66 | #665533 |
| Venom | #44cc44 | #66ee66 | #228822 |
| Shadow | #8844aa | #aa66cc | #330044 |
| Neutral | #cccccc | #ffffff | #666666 |

## Reference

See `handoff/2026_03_26_17_58_37_328_627147.png` for the original attack concept art showing the general feel of each attack. Your sprites should capture that energy in an animated projectile form.

## Delivery

Drop completed PNGs into `handoff/vfx/` and let me know — I'll integrate them into the battle animation system with cross-screen travel.
