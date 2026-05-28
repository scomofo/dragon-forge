#!/usr/bin/env python3
"""Generate dedicated Root/Admin reaction strips from approved battle seed frames."""

from __future__ import annotations

from pathlib import Path
from random import Random

from PIL import Image, ImageDraw, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
ROOT_ACTOR = ROOT / "assets/battle/actors/root_wyrmling/battle"
ADMIN_ACTOR = ROOT / "assets/battle/actors/admin_protocol/battle"
PREVIEWS = ROOT / "assets/battle/previews"

ROOT_GREEN = (74, 209, 117, 255)
ROOT_DARK = (23, 78, 42, 255)
CYAN = (70, 225, 255, 255)
GOLD = (245, 194, 70, 255)
WARNING = (245, 78, 60, 255)
MAGENTA = (226, 57, 246, 255)
VOID = (62, 22, 86, 255)
WHITE = (255, 255, 255, 255)
SHADOW = (0, 0, 0, 160)


def load(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def fit_to_slot(source: Image.Image, size: tuple[int, int], x_offset: int = 0, y_offset: int = 0) -> Image.Image:
    slot = Image.new("RGBA", size, (0, 0, 0, 0))
    sprite = source.copy()
    scale = min(size[0] / sprite.width, size[1] / sprite.height, 1.0)
    if scale < 1.0:
        sprite = sprite.resize((int(sprite.width * scale), int(sprite.height * scale)), Image.Resampling.NEAREST)
    left = (size[0] - sprite.width) // 2 + x_offset
    top = size[1] - sprite.height + y_offset
    slot.alpha_composite(sprite, (left, top))
    return slot


def tinted(image: Image.Image, color: tuple[int, int, int, int], opacity: float) -> Image.Image:
    overlay = Image.new("RGBA", image.size, color)
    overlay.putalpha(image.getchannel("A").point(lambda value: int(value * opacity)))
    result = image.copy()
    result.alpha_composite(overlay)
    return result


def offset_image(image: Image.Image, dx: int, dy: int) -> Image.Image:
    result = Image.new("RGBA", image.size, (0, 0, 0, 0))
    result.alpha_composite(image, (dx, dy))
    return result


def add_shadow(image: Image.Image, dx: int = 4, dy: int = 6) -> Image.Image:
    alpha = image.getchannel("A")
    shadow = Image.new("RGBA", image.size, SHADOW)
    shadow.putalpha(alpha.point(lambda value: min(160, value)))
    result = Image.new("RGBA", image.size, (0, 0, 0, 0))
    result.alpha_composite(shadow, (dx, dy))
    result.alpha_composite(image)
    return result


def pixel_rect(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, color: tuple[int, int, int, int]) -> None:
    draw.rectangle((x, y, x + w - 1, y + h - 1), fill=color)


def add_shards(draw: ImageDraw.ImageDraw, rng: Random, origin: tuple[int, int], colors: list[tuple[int, int, int, int]], frame: int, count: int) -> None:
    ox, oy = origin
    for index in range(count):
        spread_x = rng.randint(-18, 28) + frame * rng.randint(1, 4)
        spread_y = rng.randint(-22, 18) - frame * rng.randint(0, 3)
        size = rng.choice([3, 4, 5, 6])
        color = colors[index % len(colors)]
        pixel_rect(draw, ox + spread_x, oy + spread_y, size, size, color)


def add_scan_glitches(draw: ImageDraw.ImageDraw, rng: Random, color: tuple[int, int, int, int], frame: int, width: int, height: int) -> None:
    for index in range(5 + frame):
        y = rng.randint(22, height - 18)
        x = rng.randint(18, width - 72)
        w = rng.randint(18, 52)
        pixel_rect(draw, x + frame * 3, y, w, 3, color)


def draw_energy_brackets(draw: ImageDraw.ImageDraw, size: tuple[int, int], color: tuple[int, int, int, int], frame: int) -> None:
    width, height = size
    inset = 18 - frame * 2
    top = 26 - frame
    bottom = height - 22 + frame
    arm = 28 + frame * 3
    line = 4
    for x in (inset, width - inset):
        sx = 1 if x == inset else -1
        pixel_rect(draw, x - line // 2, top, line, arm, color)
        pixel_rect(draw, x - line // 2, bottom - arm, line, arm, color)
        pixel_rect(draw, x if sx > 0 else x - arm, top, arm, line, color)
        pixel_rect(draw, x if sx > 0 else x - arm, bottom, arm, line, color)


def save_strip(prefix: str, frames: list[Image.Image], out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for index, frame in enumerate(frames):
        frame.save(out_dir / f"{prefix}_{index}.png")


def save_preview(prefix: str, frames: list[Image.Image], out_path: Path, columns: int = 4) -> None:
    gap = 8
    width = max(frame.width for frame in frames)
    height = max(frame.height for frame in frames)
    rows = (len(frames) + columns - 1) // columns
    sheet = Image.new("RGBA", (columns * width + (columns - 1) * gap, rows * height + (rows - 1) * gap), (255, 255, 255, 255))
    draw = ImageDraw.Draw(sheet)
    for y in range(0, sheet.height, 16):
        for x in range(0, sheet.width, 16):
            fill = (240, 243, 246, 255) if ((x // 16) + (y // 16)) % 2 == 0 else (224, 230, 236, 255)
            draw.rectangle((x, y, x + 15, y + 15), fill=fill)
    for index, frame in enumerate(frames):
        col = index % columns
        row = index // columns
        left = col * (width + gap) + (width - frame.width) // 2
        top = row * (height + gap) + (height - frame.height) // 2
        sheet.alpha_composite(frame, (left, top))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path)


def root_telegraph() -> list[Image.Image]:
    seed = load(ROOT_ACTOR / "root_idle_0.png")
    frames: list[Image.Image] = []
    for frame in range(4):
        img = add_shadow(fit_to_slot(seed, (224, 168), y_offset=-frame))
        draw = ImageDraw.Draw(img)
        draw_energy_brackets(draw, img.size, CYAN if frame % 2 == 0 else GOLD, frame)
        draw.arc((44 - frame * 2, 30 - frame * 2, 180 + frame * 2, 162 + frame * 2), 210, 330, fill=ROOT_GREEN, width=4)
        draw.arc((56, 44, 168, 150), 200 + frame * 12, 330 + frame * 12, fill=GOLD, width=3)
        for index in range(5):
            x = 76 + index * 16 + frame * 2
            y = 30 + ((index + frame) % 3) * 6
            pixel_rect(draw, x, y, 5, 10, CYAN)
        frames.append(img)
    return frames


def root_hurt() -> list[Image.Image]:
    seed = load(ROOT_ACTOR / "root_idle_1.png")
    offsets = [(-4, 0), (-13, 4), (8, -2), (0, 0)]
    flashes = [0.05, 0.42, 0.22, 0.0]
    frames: list[Image.Image] = []
    for frame, (dx, dy) in enumerate(offsets):
        img = offset_image(fit_to_slot(seed, (192, 144)), dx, dy)
        img = tinted(img, WARNING, flashes[frame])
        draw = ImageDraw.Draw(img)
        rng = Random(110 + frame)
        add_shards(draw, rng, (128, 72), [WARNING, GOLD, WHITE], frame, 8)
        add_scan_glitches(draw, rng, (255, 70, 70, 140), frame, img.width, img.height)
        frames.append(add_shadow(img, 3, 4))
    return frames


def root_defend_hit() -> list[Image.Image]:
    sources = [load(ROOT_ACTOR / f"guarded_spark_{index}.png") for index in [1, 2, 3, 4]]
    frames: list[Image.Image] = []
    for frame, source in enumerate(sources):
        img = add_shadow(fit_to_slot(source, (224, 168)))
        draw = ImageDraw.Draw(img)
        draw.arc((26 - frame, 24 - frame, 194 + frame, 174 + frame), 205, 335, fill=CYAN, width=7)
        draw.arc((38, 34, 184, 166), 208, 336, fill=GOLD if frame % 2 else ROOT_GREEN, width=4)
        for index in range(7):
            pixel_rect(draw, 144 + index * 8 + frame * 2, 70 - index * 3, 5, 12, WHITE if index % 2 else CYAN)
        frames.append(img)
    return frames


def root_defend_start() -> list[Image.Image]:
    sources = [load(ROOT_ACTOR / f"root_idle_{index % 4}.png") for index in range(4)]
    frames: list[Image.Image] = []
    for frame, source in enumerate(sources):
        img = add_shadow(fit_to_slot(source, (224, 168), y_offset=-frame))
        draw = ImageDraw.Draw(img)
        draw.arc((34 - frame, 28 - frame, 190 + frame, 172 + frame), 208, 333, fill=ROOT_GREEN, width=5)
        draw.arc((48, 40, 176, 164), 212, 328, fill=CYAN if frame % 2 == 0 else GOLD, width=4)
        for index in range(5):
            pixel_rect(draw, 60 + index * 21, 116 - frame * 3 - index % 2 * 6, 8, 8, CYAN if index % 2 else ROOT_GREEN)
        frames.append(img)
    return frames


def root_ko() -> list[Image.Image]:
    seed = fit_to_slot(load(ROOT_ACTOR / "root_idle_2.png"), (224, 168))
    frames: list[Image.Image] = []
    for frame in range(4):
        img = ImageEnhance.Brightness(seed).enhance(max(0.42, 1.0 - frame * 0.16))
        img = tinted(img, (80, 38, 120, 255), frame * 0.10)
        img = offset_image(img, -frame * 4, frame * 7)
        draw = ImageDraw.Draw(img)
        rng = Random(210 + frame)
        for index in range(10 + frame * 5):
            x = rng.randint(52, 158)
            y = rng.randint(78, 156)
            color = [ROOT_GREEN, CYAN, MAGENTA, WHITE][index % 4]
            pixel_rect(draw, x + frame * rng.randint(-2, 5), y + frame * rng.randint(1, 5), rng.choice([3, 4, 5]), rng.choice([3, 4, 6]), color)
        if frame >= 2:
            draw.rectangle((44, 116, 186, 168), fill=(0, 0, 0, 72 + frame * 30))
        frames.append(img)
    return frames


def admin_telegraph() -> list[Image.Image]:
    seed = load(ADMIN_ACTOR / "admin_idle_0.png")
    frames: list[Image.Image] = []
    for frame in range(4):
        img = add_shadow(fit_to_slot(seed, (224, 168), y_offset=-frame))
        draw = ImageDraw.Draw(img)
        draw_energy_brackets(draw, img.size, MAGENTA if frame % 2 == 0 else WARNING, frame)
        for index in range(7):
            pixel_rect(draw, 50 + index * 20, 32 + ((index + frame) % 2) * 8, 12, 4, MAGENTA)
            pixel_rect(draw, 50 + index * 20, 124 - ((index + frame) % 2) * 8, 12, 4, WARNING)
        add_scan_glitches(draw, Random(310 + frame), (255, 64, 230, 150), frame, img.width, img.height)
        frames.append(img)
    return frames


def admin_hurt() -> list[Image.Image]:
    sources = [load(ADMIN_ACTOR / f"admin_idle_{index % 4}.png") for index in range(4)]
    frames: list[Image.Image] = []
    for frame, source in enumerate(sources):
        img = fit_to_slot(source, (224, 168), x_offset=frame * 5 - 6, y_offset=frame % 2 * -3)
        img = tinted(img, ROOT_GREEN if frame % 2 else WHITE, 0.22 + frame * 0.06)
        draw = ImageDraw.Draw(img)
        rng = Random(410 + frame)
        add_shards(draw, rng, (68, 74), [ROOT_GREEN, CYAN, WHITE], frame, 10)
        add_scan_glitches(draw, rng, (74, 209, 117, 170), frame, img.width, img.height)
        frames.append(add_shadow(img))
    return frames


def admin_defend_start() -> list[Image.Image]:
    seed = load(ADMIN_ACTOR / "admin_idle_2.png")
    frames: list[Image.Image] = []
    for frame in range(4):
        img = add_shadow(fit_to_slot(seed, (192, 176), y_offset=-frame))
        draw = ImageDraw.Draw(img)
        left = 14 + frame * 2
        right = 178 - frame * 2
        draw.rectangle((left, 26, right, 154), outline=MAGENTA, width=4)
        for y in range(44, 146, 20):
            draw.line((left + 8, y + frame % 2 * 4, right - 8, y - frame % 2 * 4), fill=VOID, width=3)
        for x in range(left + 24, right - 12, 28):
            draw.line((x, 34, x + frame * 2, 150), fill=WARNING, width=2)
        frames.append(img)
    return frames


def admin_defend_hit() -> list[Image.Image]:
    sources = [load(ADMIN_ACTOR / f"data_leak_{index + 1}.png") for index in range(4)]
    frames: list[Image.Image] = []
    for frame, source in enumerate(sources):
        img = add_shadow(fit_to_slot(source, (224, 168)))
        draw = ImageDraw.Draw(img)
        draw.rectangle((30 - frame, 30 - frame, 194 + frame, 150 + frame), outline=WARNING, width=5)
        draw.line((38, 74, 188, 102 + frame * 3), fill=CYAN, width=5)
        draw.line((52, 126, 172, 46 - frame * 2), fill=ROOT_GREEN, width=4)
        add_shards(draw, Random(510 + frame), (62, 90), [CYAN, ROOT_GREEN, WHITE], frame, 9)
        frames.append(img)
    return frames


def admin_ko() -> list[Image.Image]:
    seed = fit_to_slot(load(ADMIN_ACTOR / "admin_idle_1.png"), (224, 168))
    frames: list[Image.Image] = []
    for frame in range(4):
        img = tinted(seed, VOID, 0.16 + frame * 0.08)
        img = offset_image(img, frame * 5, frame * 6)
        draw = ImageDraw.Draw(img)
        rng = Random(610 + frame)
        add_scan_glitches(draw, rng, (226, 57, 246, 180), frame + 1, img.width, img.height)
        for index in range(14 + frame * 6):
            color = [MAGENTA, WARNING, CYAN, WHITE][index % 4]
            pixel_rect(draw, rng.randint(48, 174), rng.randint(52, 160), rng.choice([3, 4, 6]), rng.choice([3, 6, 8]), color)
        draw.rectangle((0, 144 - frame * 10, 224, 168), fill=(12, 0, 18, 46 + frame * 34))
        frames.append(img)
    return frames


def write_all() -> None:
    strips = [
        ("root_telegraph", root_telegraph(), ROOT_ACTOR, PREVIEWS / "root_wyrmling_root_telegraph_sheet.png", 4),
        ("root_hurt", root_hurt(), ROOT_ACTOR, PREVIEWS / "root_wyrmling_root_hurt_sheet.png", 4),
        ("root_defend_start", root_defend_start(), ROOT_ACTOR, PREVIEWS / "root_wyrmling_root_defend_start_sheet.png", 4),
        ("root_defend_hit", root_defend_hit(), ROOT_ACTOR, PREVIEWS / "root_wyrmling_root_defend_hit_sheet.png", 4),
        ("root_ko", root_ko(), ROOT_ACTOR, PREVIEWS / "root_wyrmling_root_ko_sheet.png", 4),
        ("admin_telegraph", admin_telegraph(), ADMIN_ACTOR, PREVIEWS / "admin_protocol_telegraph_sheet.png", 4),
        ("admin_hurt", admin_hurt(), ADMIN_ACTOR, PREVIEWS / "admin_protocol_hurt_sheet.png", 4),
        ("admin_defend_start", admin_defend_start(), ADMIN_ACTOR, PREVIEWS / "admin_protocol_defend_start_sheet.png", 4),
        ("admin_defend_hit", admin_defend_hit(), ADMIN_ACTOR, PREVIEWS / "admin_protocol_defend_hit_sheet.png", 4),
        ("admin_ko", admin_ko(), ADMIN_ACTOR, PREVIEWS / "admin_protocol_ko_sheet.png", 4),
    ]
    for prefix, frames, out_dir, preview, columns in strips:
        save_strip(prefix, frames, out_dir)
        save_preview(prefix, frames, preview, columns)


if __name__ == "__main__":
    write_all()
