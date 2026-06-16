#!/usr/bin/env python3
"""Place ChatGPT-generated Synthesis Dragon sprites into both build trees.

Reads handoff/synthesis_incoming/synthesis_stage{1..4}.png, normalises each
(RGB, longest side capped at 1024, optimised PNG) and writes copies to:
  - public/assets/dragons/                 (browser build)
  - dragon-forge-godot/assets/dragons/     (Godot build)

Usage:  python tools/asset_gen/place_synthesis.py
"""
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("ERROR: Pillow not installed. Run: pip install pillow")

REPO = Path(__file__).resolve().parents[2]
SRC_DIR = REPO / "handoff" / "synthesis_incoming"
DESTS = [
    REPO / "public" / "assets" / "dragons",
    REPO / "dragon-forge-godot" / "assets" / "dragons",
]
MAX_SIDE = 1024

missing = []
for stage in (1, 2, 3, 4):
    name = f"synthesis_stage{stage}.png"
    src = SRC_DIR / name
    if not src.exists():
        missing.append(name)

if missing:
    print("ERROR: missing source files in handoff/synthesis_incoming/:")
    for m in missing:
        print(f"  - {m}")
    print("\nDrop all 4 PNGs there first (see README.md), then re-run.")
    sys.exit(1)

for d in DESTS:
    d.mkdir(parents=True, exist_ok=True)

for stage in (1, 2, 3, 4):
    name = f"synthesis_stage{stage}.png"
    img = Image.open(SRC_DIR / name).convert("RGB")
    w, h = img.size
    if max(w, h) > MAX_SIDE:
        scale = MAX_SIDE / max(w, h)
        img = img.resize((round(w * scale), round(h * scale)), Image.LANCZOS)
    for d in DESTS:
        out = d / name
        img.save(out, format="PNG", optimize=True, compress_level=9)
        kb = out.stat().st_size // 1024
        print(f"  {out.relative_to(REPO)}  {img.size[0]}x{img.size[1]}  {kb}KB")

print("\nDone. Tell Claude — it will wire gameData.js + run the manifest test.")
