#!/usr/bin/env python3
"""Uniform alpha for a 1024x256 VFX projectile strip.

The generator returns 4 frames whose backgrounds can be inconsistent (some
near-black, some light, some checkerboard). Sliced per-frame in-game that
flickers. This pass forces a consistent transparent background across all four
256x256 cells: each cell's background is the colour at its own corners, keyed
to alpha with a tolerance, while the bright glowing projectile stays opaque.

Usage: python3 tools/asset_gen/_vfx_strip_alpha.py <strip.png>
"""
import sys
from collections import deque
from pathlib import Path

from PIL import Image

CELL = 256
TOL = 60  # per-channel tolerance against a cell's background colour


def key_cell(img: Image.Image) -> Image.Image:
    """Flood-fill a cell's border-connected background to transparency."""
    img = img.convert("RGB")
    W, H = img.size
    src = img.load()
    out = img.convert("RGBA")
    opx = out.load()
    corners = [src[0, 0], src[W - 1, 0], src[0, H - 1], src[W - 1, H - 1]]

    def is_bg(px, bg):
        return all(abs(px[i] - bg[i]) <= TOL for i in range(3))

    for cx, cy in [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)]:
        bg = corners[0] if all(is_bg(c, corners[0]) for c in corners) else src[cx, cy]
        if opx[cx, cy][3] == 0:
            continue
        seen = bytearray(W * H)
        dq = deque([(cx, cy)])
        while dq:
            x, y = dq.popleft()
            if x < 0 or y < 0 or x >= W or y >= H:
                continue
            idx = y * W + x
            if seen[idx]:
                continue
            seen[idx] = 1
            r, g, b, a = opx[x, y]
            if a == 0 or not is_bg((r, g, b), bg):
                continue
            opx[x, y] = (r, g, b, 0)
            dq.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return out


def main() -> None:
    path = Path(sys.argv[1])
    strip = Image.open(path).convert("RGB")
    if strip.size[1] != CELL or strip.size[0] % CELL != 0:
        sys.exit(f"ERROR: {path} is not a Nx{CELL} strip (got {strip.size})")
    frames = strip.size[0] // CELL
    out = Image.new("RGBA", strip.size, (0, 0, 0, 0))
    for i in range(frames):
        cell = strip.crop((i * CELL, 0, (i + 1) * CELL, CELL))
        out.paste(key_cell(cell), (i * CELL, 0), key_cell(cell))
    out.save(path, format="PNG", optimize=True)
    print(f"  alpha -> {path.name} ({frames} frames uniform)")


if __name__ == "__main__":
    main()
