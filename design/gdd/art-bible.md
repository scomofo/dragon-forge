# Art Bible

> **Status**: Binding
> **Author**: SNES-AAA quality pass
> **Last Updated**: 2026-09-02
> **Implements Pillar**: P2 — Every Fight Is a Readable Type-Puzzle; P3 — The Myth Is Hardware
> **Code twin**: `src/artBible.js`

## Summary

One visual language for everything that appears in a battle or on the map. Journal portraits may stay painted. Battle actors, NPCs, bosses, arenas, eggs, and VFX must share cell size, outline weight, palette family, and camera.

This document is a reject filter. Assets that fail the tests below do not ship, even if they look expensive in isolation.

## Register

**Battle register** (required for any sprite that stands in an arena):

- Grammar: 16-bit SNES pixel, 2-px outer outline, hard edge, no painterly blur, no photographic texture.
- Master cell: 96×96 for mid-size dragons / humanoid NPCs; 64×64 for small foes; 128×128 only for stage-4 or true-final silhouettes. Integer scale only (2× or 3×).
- Camera: 3/4 battle stance, feet planted, readable at 48×48 thumbnail.
- Background of the file: transparent. No chroma-green. No checkerboard. No watermark. No UI type baked into the art.
- Motion: real frames. Idle 4, attack 6, hurt 2, faint 3. A still + GSAP translate is juice, not acting.

**Portrait register** (journal / hatch reveal only):

- 1024² painted stills already in `public/assets/dragons/*_stageN.webp` may remain here.
- They must not be sliced as animation sheets.
- A portrait that cannot silhouette at 48×48 is rejected even as a portrait.

## Body plans

If two dragons silhouette the same, one is rejected.

| Id | Name | Body plan | Read at thumbnail |
|----|------|-----------|-------------------|
| fire | Magma Dragon | Hex-scale biped | Wide diamond + horn nubs |
| ice | Ice Dragon | Faceted quadruped | Long low rectangle + spike row |
| storm | Storm Dragon | Ribbon / serpentine | Thin S, no legs |
| stone | Stone Dragon | Block golem | Square stack |
| venom | Venom Dragon | Frilled wyrm | Hood triangle + whip tail |
| shadow | Shadow Dragon | Negative-space gap | Hole in a wolf shape |
| void | Void Dragon | Hollow crystal tetra | Diamond frame, empty middle |
| light | Light Dragon | Stained-glass winged biped | Wing chevron + pane grid |
| synthesis | Synthesis | Void frame filled with light panes | Diamond frame + pane fill |

Stage 1 is a hatchling of the *same* plan, not a different animal.

## Enemies, arenas, VFX, eggs

- Same cell size as the dragon they face. No printed words ("404 Error" banned). Hue-rotate is not a new actor.
- Arenas 320×176. No leftover labels, grid paper, or watermarks.
- Each signature has its own strip. Sharing `FLAME_WALL` is a tracked placeholder (`VFX_PLACEHOLDERS`).
- Eggs: six authored frames. Construction leftovers fail QA.

## Production order (P1)

1. Crop / replace leftover arenas.
2. Dedicated signature VFX strips.
3. Stage-3 battle set for 9 dragons.
4. 9 NPC battle sets at the same cell size.
5. Boss phase cells.
