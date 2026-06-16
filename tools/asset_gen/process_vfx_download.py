#!/usr/bin/env python3
"""Turn a ChatGPT-generated 4-frame VFX sheet (RGB, white background) into the
game's strip format: white background keyed to alpha, normalized to 1024x256.

Usage:
  python3 tools/asset_gen/process_vfx_download.py <input.png> <move_slug> [--preview]

Output: public/assets/vfx/vfx_<move_slug>.png  (1024x256 RGBA)
With --preview also writes a dark-background preview to the OS temp dir.

The white-key keeps saturated or dark pixels (the effect) and drops the
near-white, low-saturation background, while preserving the bright warm core.
"""
import os
import sys
import tempfile
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT_DIR = os.path.join(ROOT, "public", "assets", "vfx")
OUT_W, OUT_H = 1024, 256


def key_white_to_alpha(img, thresh=72):
    """RGB image -> RGBA. Removes the near-white background by flood-filling
    from the borders, so white-hot cores enclosed by the effect are KEPT
    (a per-pixel white-key would erase them). A generous threshold absorbs the
    grey dither in flattened-transparency exports; saturated effect pixels are
    far enough from white to remain a flood boundary. Edges are feathered 1px."""
    im = img.convert("RGB")
    W, H = im.size
    work = im.copy()
    SENT = (1, 254, 2)  # sentinel colour the artwork won't contain

    seeds = []
    step_x = max(1, W // 60)
    step_y = max(1, H // 16)
    for x in range(0, W, step_x):
        seeds.append((x, 0))
        seeds.append((x, H - 1))
    for y in range(0, H, step_y):
        seeds.append((0, y))
        seeds.append((W - 1, y))

    for s in seeds:
        px = work.getpixel(s)
        if px != SENT and min(px[:3]) > 198:  # only seed from near-white border
            ImageDraw.floodfill(work, s, SENT, thresh=thresh)

    arr = np.asarray(work)
    bg = np.all(arr[:, :, :3] == np.array(SENT, dtype=np.uint8), axis=2)

    alpha = np.where(bg, 0, 255).astype(np.uint8)
    aimg = Image.fromarray(alpha, "L").filter(ImageFilter.GaussianBlur(1.0))
    out = np.dstack([np.asarray(im, dtype=np.uint8), np.asarray(aimg)]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    inp = os.path.expanduser(sys.argv[1])
    slug = sys.argv[2]
    preview = "--preview" in sys.argv[3:]

    src = Image.open(inp)
    keyed = key_white_to_alpha(src)
    strip = keyed.resize((OUT_W, OUT_H), Image.LANCZOS)

    os.makedirs(OUT_DIR, exist_ok=True)
    out = os.path.join(OUT_DIR, f"vfx_{slug}.png")
    strip.save(out, format="PNG", optimize=True, compress_level=9)
    kb = os.path.getsize(out) // 1024
    print(f"  -> {out}  ({OUT_W}x{OUT_H}, {kb} KB)")

    if preview:
        bg = Image.new("RGBA", (OUT_W, OUT_H), (14, 14, 20, 255))
        bg.alpha_composite(strip)
        pv = os.path.join(tempfile.gettempdir(), f"vfx_preview_{slug}.png")
        bg.convert("RGB").save(pv)
        print(f"  preview: {pv}")


if __name__ == "__main__":
    main()
