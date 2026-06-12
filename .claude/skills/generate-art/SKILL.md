---
name: generate-art
description: Generate game art (dragon sprites, NPCs, VFX, eggs, arenas) using the repo's inference pipeline and style guides. Use when asked to generate, regenerate, or batch-produce sprite art.
---

# Generate art

The repo has a working image-generation pipeline; do not invent a new one.

## Pipeline
- `inference.sh` (repo root) — bash wrapper around the `infsh` CLI (`~/.local/bin/infsh`). Args: `--model`, `--prompt`, `--negative`, `--width`, `--height` (default 1024×1024), `--output <file.png>`. Run it via the Bash tool, not PowerShell.
- `tools/asset_gen/gen_dragons.sh`, `gen_npcs.sh`, `gen_vfx.sh` — batch scripts that call `inference.sh` per asset. Extend these for new batches rather than looping ad hoc.
- `tools/asset_gen/style_reference.md` — the canonical style prompt fragments. Every prompt must build on this so new art matches existing art.

## Briefs and specs (`handoff/`)
Read the relevant guide before writing prompts:
- `handoff/DRAGON_EVOLUTION_SPRITE_GUIDE.md` — per-stage dragon sheets (Baby/Juvenile/Adult/Elder).
- `handoff/EGG_SPRITE_GUIDE.md`, `handoff/ATTACK_VFX_SPRITE_GUIDE.md`, `handoff/SFX_GENERATION_GUIDE.md`.
- `handoff/Dragon Forge_ Master Handoff Spec.md` — overall art direction.

Outstanding work is tracked in `TODO.md` under "Needs Art Generation".

## Output conventions
- Browser build reads from `public/assets/` (dragons in `public/assets/dragons/<element>[_stageN].png`); shared source art lives in `assets/` at repo root; Godot copies live under `dragon-forge-godot/assets/`. Update both builds when the system is mirrored.
- Downscale/compress before committing — raw generations are ~2 MB; shipped sprites in this repo are ~100–300 KB (see commit `37f0f49`).
- After adding files, run `npx vitest run src/assetManifest.test.js` to confirm references resolve.
