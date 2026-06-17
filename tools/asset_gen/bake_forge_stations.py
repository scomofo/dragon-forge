#!/usr/bin/env python3
"""Bake transparency into Forge station sprites.

Reads PNGs from handoff/forge_stations_incoming/, removes the #00ff00
green-screen background, and writes RGBA PNGs to public/assets/forge/
and dragon-forge-godot/assets/forge/.

Three-pass pipeline:
  1. Flood-fill from all four corners (catches large connected BG regions)
  2. Difference-based color-key: transparent if G exceeds max(R,B) by >= DIFF_THRESH
     — unlike ratio-based keying this works correctly on warm/bright sprite colors
  3. Despill: cap G at max(R,B) on all surviving pixels to eliminate green tint

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

FLOOD_THRESH = 80   # flood-fill corner tolerance
DIFF_THRESH  = 20   # G - max(R,B) must exceed this to be keyed transparent
GREEN_MIN    = 60   # G must be at least this bright (avoids near-black neutrals)

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

    # ── Pass 2: difference-based color-key ───────────────────────────────
    # Key out any pixel where green dominates the other channels by DIFF_THRESH.
    # This catches anti-aliased/blended edge pixels that flood-fill missed,
    # and works correctly even when R is high (warm sprite colors).
    px = img.load()
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if g >= GREEN_MIN and (g - max(r, b)) >= DIFF_THRESH:
                px[x, y] = (0, 0, 0, 0)

    # ── Pass 3: despill ───────────────────────────────────────────────────
    # For every surviving opaque pixel where G still exceeds max(R,B),
    # clamp G down to max(R,B). This removes residual green tint from
    # edge pixels that are too mixed to fully key out.
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            cap = max(r, b)
            if g > cap:
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
