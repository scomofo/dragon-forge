#!/usr/bin/env python3
"""Bake transparency into Forge station sprites.

Reads PNGs from handoff/forge_stations_incoming/, removes the #00ff00
green-screen background, and writes RGBA PNGs to public/assets/forge/
and dragon-forge-godot/assets/forge/.

Three-pass pipeline:
  1. Flood-fill from all four corners (catches large connected BG regions)
  2. Color-key pass: any remaining pixel that is "green-dominant" goes alpha
  3. Despill pass: suppress residual green cast on surviving edge pixels

Usage:  uv run --with pillow python tools/asset_gen/bake_forge_stations.py
        uv run --with pillow python tools/asset_gen/bake_forge_stations.py station_anvil
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

# Flood-fill tolerance — how far from the seed colour a pixel can be and still
# be considered background (sum of per-channel absolute differences).
FLOOD_THRESH = 80

# Color-key threshold: a pixel is green-screen if its green channel dominates
# by at least this ratio over both red and blue.
GREEN_RATIO = 1.6   # G must be > 1.6 × R  AND  > 1.6 × B
GREEN_MIN   = 120   # G must also be at least this value (avoids dark neutrals)

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

    # ── Pass 1: flood-fill from all four corners ──────────────────────────
    W, H = img.size
    for seed in [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)]:
        ImageDraw.floodfill(img, seed, (0, 0, 0, 0), thresh=FLOOD_THRESH)

    # ── Pass 2: color-key — catch any green-ish pixel that flood-fill missed
    px = img.load()
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if (g >= GREEN_MIN
                    and g > r * GREEN_RATIO
                    and g > b * GREEN_RATIO):
                px[x, y] = (0, 0, 0, 0)

    # ── Pass 3: despill — reduce green cast on edge pixels that survived ──
    # For each opaque pixel where G is noticeably higher than R or B,
    # clamp G to max(R, B) to neutralise the green tint without going alpha.
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            cap = max(r, b)
            if g > cap + 15:          # only correct significant green excess
                px[x, y] = (r, cap, b, a)

    # ── Autocrop to non-transparent bounding box ──────────────────────────
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)

    W, H = img.size
    px = img.load()
    transparent = sum(1 for y in range(H) for x in range(W) if px[x, y][3] == 0)

    for d in DESTS:
        out = d / f"{stem}.png"
        img.save(out, format="PNG", optimize=True)
        kb = out.stat().st_size // 1024
        pct = round(100 * transparent / (W * H))
        print(f"  {out.relative_to(REPO)}  {W}x{H}  {kb}KB  ({pct}% transparent)")

print("\nDone.")
