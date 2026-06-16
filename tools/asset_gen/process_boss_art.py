#!/usr/bin/env python3
"""Process a ChatGPT-generated boss illustration (a creature on a flat near-white
field) into a game-ready transparent sprite: flood-fill the border-connected
background to alpha, trim to the creature, resize, and write RGBA PNGs into both
build trees (public/assets/npc + dragon-forge-godot/assets/npc).

Singularity bosses render via NpcSprite as plain <img> (no chroma-key), so they
need a real transparent background — hence this step.

Usage:
  uv run --with pillow python tools/asset_gen/process_boss_art.py <input.png> <slug>
Output: public/assets/npc/<slug>.png  +  dragon-forge-godot/assets/npc/<slug>.png
"""
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    sys.exit("ERROR: Pillow not installed. Run via: uv run --with pillow python ...")

REPO = Path(__file__).resolve().parents[2]
DESTS = [REPO / "public" / "assets" / "npc", REPO / "dragon-forge-godot" / "assets" / "npc"]
MAX_SIDE = 640
THRESH = 60  # near-white flood tolerance (sum of per-channel diff from the seed)

if len(sys.argv) < 3:
    sys.exit("usage: process_boss_art.py <input.png> <slug>")
src = Path(sys.argv[1]).expanduser()
slug = sys.argv[2]
if not src.exists():
    sys.exit(f"ERROR: missing {src}")

img = Image.open(src).convert("RGBA")
W, H = img.size
# Flood the background from all four corners; interior highlights aren't
# edge-connected so they survive.
for seed in [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)]:
    ImageDraw.floodfill(img, seed, (0, 0, 0, 0), thresh=THRESH)

# Trim transparent margins so the creature fills the frame.
bbox = img.getbbox()
if bbox:
    img = img.crop(bbox)

w, h = img.size
if max(w, h) > MAX_SIDE:
    s = MAX_SIDE / max(w, h)
    img = img.resize((round(w * s), round(h * s)), Image.LANCZOS)

W, H = img.size
px = img.load()
transparent = sum(1 for y in range(H) for x in range(W) if px[x, y][3] == 0)
for d in DESTS:
    d.mkdir(parents=True, exist_ok=True)
    out = d / f"{slug}.png"
    img.save(out, format="PNG", optimize=True)
    kb = out.stat().st_size // 1024
    print(f"  {out.relative_to(REPO)}  {W}x{H}  {kb}KB  ({round(100 * transparent / (W * H))}% transparent)")
print("Done.")
