# Dragon Evolution Sprite Sheet Guide

## Overview

Each of the 6 elements needs **4 sprite sheets** — one per evolution stage. Each stage should be a visually distinct form of the same dragon species, growing larger and more impressive.

## What We Need

**24 sprite sheets total** (6 elements x 4 stages)

## Stage Design Guide

| Stage | Name | Description | Visual Identity |
|---|---|---|---|
| Stage I | Baby | Small, cute, newly hatched. No wings or tiny wing buds. Simple features. | Compact body, big head, stubby limbs, minimal elemental effects |
| Stage II | Juvenile | Medium, growing into its element. Small wings or fins emerging. | Longer body, emerging wings/spines, visible elemental aura |
| Stage III | Adult | Full size, fully realized elemental dragon. Wings spread, powerful stance. | Large, detailed, full wings, strong elemental particles/glow |
| Stage IV | Elder | Massive, ancient, radiating power. Extra horns/spines, battle-scarred. | Biggest, most detailed, heavy elemental effects, intimidating |

## Per-Element Design

### Fire (Magma Dragon)
- **Baby:** Small red/orange lizard, ember sparks, glowing belly
- **Juvenile:** Growing horns, lava cracks on skin, small flame wings
- **Adult:** Full dragon, magma body, flame wings, ember trail
- **Elder:** Massive, volcanic armor plating, erupting flames, molten crown

### Ice (Ice Dragon)
- **Baby:** Small white/blue dragon, frost crystals on back
- **Juvenile:** Ice spines growing, breath frost visible, crystal wings forming
- **Adult:** Full crystal dragon, ice wings, frozen aura, blue glow
- **Elder:** Ancient ice beast, glacier armor, blizzard particles, massive crystal crown

### Storm (Storm Dragon)
- **Baby:** Small purple/yellow dragon, static sparks
- **Juvenile:** Lightning veins visible, crackling spines, energy wings
- **Adult:** Full electric dragon, lightning wings, thundercloud aura
- **Elder:** Storm incarnate, constant lightning, thunderbolt crown, electric trail

### Stone (Stone Dragon)
- **Baby:** Small brown/gray dragon, pebble texture, gem eyes
- **Juvenile:** Rocky armor plates forming, crystal deposits, sturdy build
- **Adult:** Full armored dragon, boulder shoulders, crystal-studded, earth particles
- **Elder:** Mountain dragon, massive stone plates, glowing gem veins, earthquake cracks

### Venom (Venom Dragon)
- **Baby:** Small green dragon, dripping, bubble particles
- **Juvenile:** Toxic spines growing, acid drips, splotchy coloring
- **Adult:** Full venomous dragon, dripping wings, toxic cloud aura, bright green
- **Elder:** Ancient plague dragon, massive venom sacs, corrosive aura, mutated spines

### Shadow (Shadow Dragon)
- **Baby:** Small dark purple dragon, wispy edges, glowing eyes
- **Juvenile:** Shadow tendrils emerging, partial transparency, void particles
- **Adult:** Full shadow dragon, dark wings with void edges, ghostly aura
- **Elder:** Void incarnate, partially transparent, reality-warping particles, dark crown

## Sprite Sheet Specifications

**CRITICAL: All sheets must use the SAME format for code consistency.**

- **Sheet size:** 1024 x 1024 pixels
- **Grid:** 3 columns x 4 rows = 12 frames
- **Frame size:** 341 x 256 pixels (1024/3 x 1024/4)
- **Background:** Bright green (#00ff00) chroma key (matching current dragon sprites)
- **Format:** PNG

```
┌──────────┬──────────┬──────────┐
│ Frame 0  │ Frame 1  │ Frame 2  │
├──────────┼──────────┼──────────┤
│ Frame 3  │ Frame 4  │ Frame 5  │
├──────────┼──────────┼──────────┤
│ Frame 6  │ Frame 7  │ Frame 8  │
├──────────┼──────────┼──────────┤
│ Frame 9  │ Frame 10 │ Frame 11 │
└──────────┴──────────┴──────────┘
```

### Animation Frames

All 12 frames should be subtle idle animation variations:
- Breathing motion (body rises/falls slightly)
- Elemental particle movement (flames flicker, crystals shimmer, etc.)
- Tail/wing micro-movements
- Frame 3 should be the **lunge/attack** frame (leaning forward aggressively)

### Dragon Positioning

- All dragons face **LEFT** (code flips them when needed)
- Center the dragon in each frame
- Dragon feet should sit at roughly **y=200px** (bottom ~56px is ground space)
- Scale the dragon to fill the frame appropriately for its stage:
  - Stage I: ~40-50% of frame width
  - Stage II: ~55-65% of frame width
  - Stage III: ~70-80% of frame width
  - Stage IV: ~85-95% of frame width

## File Naming

```
dragons/fire_stage1.png
dragons/fire_stage2.png
dragons/fire_stage3.png
dragons/fire_stage4.png
dragons/ice_stage1.png
dragons/ice_stage2.png
...
dragons/shadow_stage4.png
```

## Color Palettes

Match the game's element colors:

| Element | Primary | Glow | Dark | Accent |
|---|---|---|---|---|
| Fire | #ff6622 | #ff8844 | #cc2200 | #ffaa00 |
| Ice | #44aaff | #66ccff | #2288cc | #cceeff |
| Storm | #aa66ff | #cc88ff | #6633aa | #ffff44 |
| Stone | #aa8844 | #ccaa66 | #665533 | #44dddd |
| Venom | #44cc44 | #66ee66 | #228822 | #aa44aa |
| Shadow | #8844aa | #aa66cc | #330044 | #ff4466 |

## Reference

Current dragon sprites are in `assets/dragons/` (magma.png, ice.png, etc.) — these are the Stage III adults. Use them as style reference for pixel density and art quality, but make the new stages visually distinct.

The evolution reference sprites in `handoff/` (the white dragon series) show the kind of progression we want — each stage should feel like a natural evolution of the same creature.

## Delivery

Drop completed PNGs into `handoff/dragons/` with the naming convention above. Let me know when they're ready and I'll swap them into the game — the code already supports per-stage sprite selection, it just currently uses the same sheet for all stages.
