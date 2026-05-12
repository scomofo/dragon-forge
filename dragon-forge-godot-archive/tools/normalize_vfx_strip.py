from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageEnhance


def normalize_strip(source: Path, target: Path, frames: int, frame_size: int) -> None:
    image = Image.open(source).convert("RGBA")
    width, height = image.size
    target_ratio = frames * frame_size / frame_size
    source_ratio = width / height

    if source_ratio > target_ratio:
        crop_width = int(height * target_ratio)
        left = (width - crop_width) // 2
        image = image.crop((left, 0, left + crop_width, height))
    else:
        crop_height = int(width / target_ratio)
        top = (height - crop_height) // 2
        image = image.crop((0, top, width, top + crop_height))

    image = image.resize((frames * frame_size, frame_size), Image.Resampling.LANCZOS)
    image = ImageEnhance.Contrast(image).enhance(1.25)
    image = ImageEnhance.Color(image).enhance(1.15)

    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if r < 18 and g < 18 and b < 18:
                pixels[x, y] = (r, g, b, 0)

    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("target", type=Path)
    parser.add_argument("--frames", type=int, default=4)
    parser.add_argument("--frame-size", type=int, default=256)
    args = parser.parse_args()
    normalize_strip(args.source, args.target, args.frames, args.frame_size)


if __name__ == "__main__":
    main()
