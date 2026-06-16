#!/usr/bin/env python3
"""Bake transparency into the Synthesis Dragon sprites.

The browser renderer (DragonSprite.jsx) only chroma-keys a GREEN background to
transparent. The ChatGPT-generated synthesis sprites are on a near-white field,
so they'd render inside an opaque box. This flood-fills the background-connected
near-white region to true alpha (preserving interior highlights, which aren't
edge-connected), resizes to 1024, and writes RGBA PNGs into both build trees.

Reads the full-res originals from handoff/synthesis_incoming/ so quality isn't
compounded by the earlier opaque downscale.

Usage:  uv run --with pillow python tools/asset_gen/bake_transparency.py
"""
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    sys.exit("ERROR: Pillow not installed. Run: uv run --with pillow python ...")

REPO = Path(__file__).resolve().parents[2]
SRC_DIR = REPO / "handoff" / "synthesis_incoming"
DESTS = [
    REPO / "public" / "assets" / "dragons",
    REPO / "dragon-forge-godot" / "assets" / "dragons",
]
MAX_SIDE = 1024
THRESH = 38  # flood-fill colour tolerance (sum of per-channel diff)

# Stems to process come from argv (default: synthesis). e.g.
#   uv run --with pillow python tools/asset_gen/bake_transparency.py void light
STEMS = sys.argv[1:] or ["synthesis"]
NAMES = [f"{stem}_stage{stage}.png" for stem in STEMS for stage in (1, 2, 3, 4)]

for name in NAMES:
    src = SRC_DIR / name
    if not src.exists():
        sys.exit(f"ERROR: missing {src}")

    img = Image.open(src).convert("RGBA")
    w, h = img.size
    if max(w, h) > MAX_SIDE:
        scale = MAX_SIDE / max(w, h)
        img = img.resize((round(w * scale), round(h * scale)), Image.LANCZOS)

    # Flood-fill the background from all four corners. Interior highlights aren't
    # connected to the border, so they're preserved.
    W, H = img.size
    for seed in [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)]:
        ImageDraw.floodfill(img, seed, (0, 0, 0, 0), thresh=THRESH)

    # Drop any fully-transparent stray pixels' colour so edges composite cleanly.
    px = img.load()
    transparent = sum(1 for y in range(H) for x in range(W) if px[x, y][3] == 0)

    for d in DESTS:
        out = d / name
        img.save(out, format="PNG", optimize=True)
        kb = out.stat().st_size // 1024
        pct = round(100 * transparent / (W * H))
        print(f"  {out.relative_to(REPO)}  {W}x{H}  {kb}KB  ({pct}% transparent)")

print("\nDone. Transparency baked into both build trees.")
