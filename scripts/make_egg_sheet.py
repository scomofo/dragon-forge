"""
make_egg_sheet.py — build an EggSprite sheet from a single egg image.

Sheet format: 4 cols × 2 rows, each frame 256×320, total 1024×640 px
  Frames 0-5: same egg image (CSS drives animation variation)
  Frame 6: egg image with bright white oval burst overlay (dragon pop-out)
  Frame 7: bottom-half shell fragment (skipped by game, just blank)

Usage:
  python scripts/make_egg_sheet.py <input_egg.png> <output_sheet.png>
"""

import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

FRAME_W = 256
FRAME_H = 320
COLS = 4
ROWS = 2
SHEET_W = FRAME_W * COLS   # 1024
SHEET_H = FRAME_H * ROWS   # 640


def load_egg(path: Path) -> Image.Image:
    img = Image.open(path).convert("RGBA")
    # Scale to fit within FRAME_W × FRAME_H keeping aspect ratio
    img.thumbnail((FRAME_W - 20, FRAME_H - 20), Image.LANCZOS)
    # Center on a FRAME_W × FRAME_H transparent canvas
    frame = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    x = (FRAME_W - img.width) // 2
    y = (FRAME_H - img.height) // 2
    frame.paste(img, (x, y), img)
    return frame


def make_burst_frame(egg_frame: Image.Image) -> Image.Image:
    """Egg + large bright white glow oval in center (dragon emerging)."""
    frame = egg_frame.copy()
    overlay = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    cx, cy = FRAME_W // 2, FRAME_H // 2
    rx, ry = 70, 85
    draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(255, 255, 240, 230))
    # Soft glow: blur the oval and composite it
    glow = overlay.filter(ImageFilter.GaussianBlur(radius=18))
    frame = Image.alpha_composite(frame, glow)
    # Draw a smaller crisp bright center on top
    draw2 = ImageDraw.Draw(frame)
    draw2.ellipse([cx - 30, cy - 36, cx + 30, cy + 36], fill=(255, 255, 255, 245))
    return frame


def build_sheet(egg_path: Path, out_path: Path):
    egg_frame = load_egg(egg_path)
    burst_frame = make_burst_frame(egg_frame)
    blank_frame = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))

    sheet = Image.new("RGBA", (SHEET_W, SHEET_H), (0, 0, 0, 0))

    frames = [
        egg_frame,   # 0 idle
        egg_frame,   # 1 glow
        egg_frame,   # 2 crack1
        egg_frame,   # 3 crack2
        egg_frame,   # 4 shake-left
        egg_frame,   # 5 shake-right
        burst_frame, # 6 burst
        blank_frame, # 7 unused shell fragment
    ]

    for i, f in enumerate(frames):
        col = i % COLS
        row = i // COLS
        sheet.paste(f, (col * FRAME_W, row * FRAME_H), f)

    sheet.save(out_path, "PNG")
    print(f"Saved {out_path}  ({SHEET_W}×{SHEET_H})")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python make_egg_sheet.py <input.png> <output_sheet.png>")
        sys.exit(1)
    build_sheet(Path(sys.argv[1]), Path(sys.argv[2]))
