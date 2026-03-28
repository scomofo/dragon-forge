# Egg Sprite Art Guide

## What We Need

**7 egg sprites** — one generic egg + one per element. Used in the Quantum Incubation hatchery screen during the pull animation.

## Sprite List

| Filename | Description | Color Palette |
|---|---|---|
| `egg_generic.png` | Default egg shown before element is revealed | Dark gray/charcoal (#2a2a3e, #111118), subtle metallic sheen |
| `egg_fire.png` | Fire element egg | Orange/red (#ff6622, #ff4400), ember glow, molten cracks |
| `egg_ice.png` | Ice element egg | Blue/cyan (#44aaff, #66ccff), frost crystals, icy surface |
| `egg_storm.png` | Storm element egg | Purple/electric (#aa66ff, #cc88ff), lightning veins, crackling energy |
| `egg_stone.png` | Stone element egg | Brown/tan (#aa8844, #ccaa66), rocky texture, crystal deposits |
| `egg_venom.png` | Venom element egg | Green (#44cc44, #66ee66), dripping, toxic bubbles, organic texture |
| `egg_shadow.png` | Shadow element egg | Dark purple (#8844aa, #aa66cc), wispy aura, void energy, faint glow |

## Specifications

- **Size:** 256x320 pixels (portrait orientation, egg shape)
- **Format:** PNG with transparent background
- **Style:** 16-bit pixel art, consistent with the existing dragon sprites
- **Outline:** 1-2px black outline around the egg
- **Background:** Transparent (NO green screen — use alpha transparency)

## Design Notes

- Eggs should be oval/egg-shaped, slightly tapered at the top
- Each elemental egg should clearly read as its element at a glance through color and surface detail
- The generic egg is neutral/mysterious — player sees this first before the element is revealed
- Keep detail level moderate — these display at ~120x150px on screen, so fine details will be lost
- Surface cracks, glowing runes, or elemental particles add visual interest
- The eggs sit against a dark (#111118) background in the UI, so they should pop against dark

## How They're Used

1. **Generic egg** appears first during the pull animation (pulsing glow)
2. Generic egg shakes with increasing intensity
3. Egg bursts with an element-colored flash
4. **Elemental egg** could optionally be shown during the crack phase (or we skip straight to dragon reveal)
5. The elemental eggs may also be used as icons in future UI (inventory, collection)

## Current Art Style Reference

Look at the existing dragon sprites in `handoff/` for style reference:
- Pixel art with clear outlines
- Rich, saturated colors
- Slight shading/gradient for depth
- Small particle effects (sparkles, embers, crystals) around the sprites

## Delivery

Drop completed PNGs into `handoff/eggs/` and let me know — I'll integrate them into the hatchery animation.
