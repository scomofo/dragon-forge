#!/usr/bin/env python3
"""Bake transparency into Forge station sprites.

Reads PNGs from handoff/forge_stations_incoming/, flood-fills the #00ff00
green-screen background to alpha, crops to content, and writes to
public/assets/forge/ (browser) and dragon-forge-godot/assets/forge/ (Godot).

Usage:  uv run --with pillow python tools/asset_gen/bake_forge_stations.py
"""
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    sys.exit("ERROR: Pillow not installed. Run: uv run --with pillow python ...")

REPO = Path(__file__).resolve().parents[2]
SRC_DIR = REPO / "handoff" / "forge_stations_incoming"
DESTS = [
    REPO / "public" / "assets" / "forge",
    REPO / "dragon-forge-godot" / "assets" / "forge",
]
THRESH = 40

STATIONS = [
    "station_hatchery_ring",
    "station_save_lantern",
    "station_anvil",
    "station_console",
    "station_felix",
    "station_bulkhead",
]

names = sys.argv[1:] or STATIONS

for d in DESTS:
    d.mkdir(parents=True, exist_ok=True)

for stem in names:
    src = SRC_DIR / f"{stem}.png"
    if not src.exists():
        print(f"  SKIP  {stem}.png (not found in {SRC_DIR})")
        continue

    img = Image.open(src).convert("RGBA")

    # Flood-fill green-screen from all four corners
    W, H = img.size
    for seed in [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)]:
        ImageDraw.floodfill(img, seed, (0, 0, 0, 0), thresh=THRESH)

    # Autocrop to non-transparent bounding box
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)

    W, H = img.size
    transparent = sum(1 for y in range(H) for x in range(W) if img.getpixel((x, y))[3] == 0)

    for d in DESTS:
        out = d / f"{stem}.png"
        img.save(out, format="PNG", optimize=True)
        kb = out.stat().st_size // 1024
        pct = round(100 * transparent / (W * H))
        print(f"  {out.relative_to(REPO)}  {W}x{H}  {kb}KB  ({pct}% transparent)")

print("\nDone.")
