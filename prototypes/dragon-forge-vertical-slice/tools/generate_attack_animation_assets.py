#!/usr/bin/env python3
"""Generate distinct battle attack animation strips for the vertical slice.

This is a prototype asset build step, not a production art replacement. It
starts from the approved in-game Root/Admin battle seed frames, keeps fixed
224x168 transparent slots, and gives each move a separate visual grammar.
"""

from __future__ import annotations

import math
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


PROJECT_DIR = Path(__file__).resolve().parents[1]
REPO_DIR = Path(__file__).resolve().parents[3]
ASSET_DIR = PROJECT_DIR / "assets" / "slice"
REVIEW_DIR = REPO_DIR / "design" / "art" / "target-frames" / "attack-animation-buildout-2"
ARCHIVE_DIR = ASSET_DIR / "rejected-attack-revision-4r"

FRAME_SIZE = (224, 168)
VFX_SIZE = (192, 128)
RESAMPLE = getattr(Image, "Resampling", Image).NEAREST

INK = (7, 8, 14, 255)
SHADOW = (16, 14, 24, 230)
ROOT_DARK = (24, 68, 34, 255)
ROOT = (78, 222, 95, 255)
ROOT_LIGHT = (168, 255, 130, 255)
BARK = (92, 61, 28, 255)
BARK_LIGHT = (190, 134, 58, 255)
GOLD = (255, 211, 68, 255)
GOLD_HOT = (255, 244, 150, 255)
CYAN = (55, 229, 246, 255)
CYAN_DARK = (14, 119, 171, 255)
MAGENTA = (255, 40, 218, 255)
MAGENTA_DARK = (103, 25, 126, 255)
VIOLET = (62, 20, 108, 255)
WARNING = (255, 88, 70, 255)


def quant(value: float, step: int = 2) -> int:
	return int(round(value / step) * step)


def asset(name: str) -> Path:
	return ASSET_DIR / name


def load_asset(name: str) -> Image.Image:
	return Image.open(asset(name)).convert("RGBA")


def harden_alpha(image: Image.Image, threshold: int = 12) -> Image.Image:
	r, g, b, a = image.split()
	a = a.point(lambda value: 255 if value > threshold else 0)
	return Image.merge("RGBA", (r, g, b, a))


def shadow_from(image: Image.Image, opacity: int = 170) -> Image.Image:
	_, _, _, a = image.split()
	a = a.point(lambda value: opacity if value > 12 else 0)
	return Image.merge("RGBA", (Image.new("L", image.size, 0), Image.new("L", image.size, 0), Image.new("L", image.size, 0), a))


def paste_sprite(canvas: Image.Image, sprite: Image.Image, position: tuple[int, int], scale: float = 1.0, rotation: float = 0.0) -> None:
	work = sprite
	if scale != 1.0:
		work = work.resize((max(1, int(work.width * scale)), max(1, int(work.height * scale))), RESAMPLE)
	if rotation != 0.0:
		work = work.rotate(rotation, resample=RESAMPLE, expand=True)
	x, y = position
	shadow = shadow_from(work, 135)
	canvas.alpha_composite(shadow, (x + 4, y + 5))
	canvas.alpha_composite(work, (x, y))


def draw_pixel_rect(draw: ImageDraw.ImageDraw, center: tuple[float, float], size: int, color: tuple[int, int, int, int]) -> None:
	half = max(1, size // 2)
	x = quant(center[0])
	y = quant(center[1])
	draw.rectangle((x - half, y - half, x + half, y + half), fill=color)


def draw_spark(draw: ImageDraw.ImageDraw, center: tuple[float, float], radius: int, color: tuple[int, int, int, int], core: tuple[int, int, int, int] = GOLD_HOT) -> None:
	x = quant(center[0])
	y = quant(center[1])
	draw.line((x - radius, y, x + radius, y), fill=color, width=3)
	draw.line((x, y - radius, x, y + radius), fill=color, width=3)
	draw.line((x - radius // 2, y - radius // 2, x + radius // 2, y + radius // 2), fill=color, width=2)
	draw.line((x + radius // 2, y - radius // 2, x - radius // 2, y + radius // 2), fill=color, width=2)
	draw.rectangle((x - 2, y - 2, x + 2, y + 2), fill=core)


def draw_polyline(draw: ImageDraw.ImageDraw, points: list[tuple[float, float]], outer: tuple[int, int, int, int], inner: tuple[int, int, int, int], width: int = 8) -> None:
	pixels = [(quant(x), quant(y)) for x, y in points]
	if len(pixels) < 2:
		return
	draw.line(pixels, fill=INK, width=width + 5, joint="curve")
	draw.line(pixels, fill=outer, width=width + 2, joint="curve")
	draw.line(pixels, fill=inner, width=max(2, width // 2), joint="curve")
	for point in pixels[1:-1]:
		draw_pixel_rect(draw, point, width, inner)


def lightning_points(start: tuple[float, float], end: tuple[float, float], frame: int, kink: float = 18.0) -> list[tuple[float, float]]:
	points: list[tuple[float, float]] = [start]
	segments = 4
	for index in range(1, segments):
		t = index / float(segments)
		x = start[0] + (end[0] - start[0]) * t
		y = start[1] + (end[1] - start[1]) * t
		phase = -1.0 if (index + frame) % 2 == 0 else 1.0
		points.append((x, y + phase * (kink - index * 2.0)))
	points.append(end)
	return points


def draw_lightning(draw: ImageDraw.ImageDraw, start: tuple[float, float], end: tuple[float, float], frame: int, width: int = 7) -> None:
	main = lightning_points(start, end, frame, 20.0)
	draw_polyline(draw, main, CYAN_DARK, CYAN, width)
	draw_polyline(draw, lightning_points((start[0] + 4, start[1] - 4), (end[0] - 18, end[1] + 18), frame + 1, 12.0), GOLD, GOLD_HOT, max(3, width - 3))
	if frame >= 2:
		draw_polyline(draw, lightning_points((start[0] + 8, start[1] + 10), (end[0] - 8, end[1] - 22), frame + 2, 10.0), CYAN_DARK, CYAN, max(3, width - 4))
	for index, point in enumerate(main):
		if index > 0:
			draw_pixel_rect(draw, point, 5 + (index % 2) * 2, GOLD_HOT if index % 2 == 0 else CYAN)


def draw_ground_vine(draw: ImageDraw.ImageDraw, start_x: float, start_y: float, end_x: float, end_y: float, frame: int, width: int = 12) -> None:
	points: list[tuple[float, float]] = []
	for index in range(7):
		t = index / 6.0
		x = start_x + (end_x - start_x) * t
		y = start_y + (end_y - start_y) * t + math.sin(t * math.pi * 3.0 + frame * 0.7) * 7.0
		points.append((x, y))
	draw_polyline(draw, points, BARK, ROOT, width)
	for index, (x, y) in enumerate(points[1:-1], start=1):
		spike_len = 14 + ((frame + index) % 3) * 8
		side = -1 if index % 2 == 0 else 1
		base = (quant(x), quant(y))
		tip = (quant(x + side * 8), quant(y - spike_len))
		draw.line((base[0], base[1], tip[0], tip[1]), fill=INK, width=7)
		draw.line((base[0], base[1], tip[0], tip[1]), fill=BARK_LIGHT, width=4)
		draw.line((tip[0] - 3, tip[1] + 5, tip[0], tip[1], tip[0] + 4, tip[1] + 6), fill=GOLD, width=2)


def draw_shards(draw: ImageDraw.ImageDraw, center: tuple[float, float], colors: list[tuple[int, int, int, int]], count: int, frame: int, spread: float = 34.0) -> None:
	for index in range(count):
		angle = (index * 2.399 + frame * 0.43) % (math.pi * 2.0)
		distance = 8.0 + (index % 5) * (spread / 5.0)
		x = center[0] + math.cos(angle) * distance
		y = center[1] + math.sin(angle) * distance
		color = colors[index % len(colors)]
		size = 3 + (index + frame) % 5
		draw_pixel_rect(draw, (x, y), size, color)


def draw_hex_shield(draw: ImageDraw.ImageDraw, center: tuple[float, float], radius: float, frame: int) -> None:
	points: list[tuple[int, int]] = []
	for index in range(6):
		angle = math.pi / 6.0 + index * math.pi / 3.0
		points.append((quant(center[0] + math.cos(angle) * radius), quant(center[1] + math.sin(angle) * radius)))
	draw.line(points + [points[0]], fill=INK, width=9)
	draw.line(points + [points[0]], fill=CYAN_DARK, width=6)
	draw.line(points + [points[0]], fill=CYAN, width=3)
	for index, point in enumerate(points):
		if (index + frame) % 2 == 0:
			draw_pixel_rect(draw, point, 8, GOLD_HOT)
		else:
			draw_pixel_rect(draw, point, 6, ROOT_LIGHT)
	for index in range(10):
		angle = index * math.pi * 0.2 + frame * 0.45
		x = center[0] + math.cos(angle) * (radius + 8.0)
		y = center[1] + math.sin(angle) * (radius + 8.0)
		draw_pixel_rect(draw, (x, y), 4 + (index % 2) * 2, CYAN if index % 3 else GOLD)


def root_spark_frame(frame: int, roots: list[Image.Image]) -> Image.Image:
	canvas = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(canvas, "RGBA")
	lunge = [-8, 4, 18, 31, 20, 6][frame]
	paste_sprite(canvas, roots[frame % len(roots)], (16 + lunge, 17 + (frame % 2) * 2), scale=1.0 + (0.02 if frame in (2, 3) else 0.0))
	start = (122 + lunge, 61 + (frame % 2) * 3)
	end = (198, 62 + math.sin(frame) * 8)
	if frame >= 1:
		draw_lightning(draw, start, end, frame, 6 + (2 if frame in (2, 3) else 0))
	if frame >= 2:
		draw_spark(draw, (190, 72), 22 + frame * 2, CYAN, GOLD_HOT)
		draw_shards(draw, (190, 72), [CYAN, CYAN_DARK, GOLD, GOLD_HOT], 18, frame, 44.0)
	else:
		for index in range(8):
			draw_pixel_rect(draw, (96 + index * 6 + lunge, 34 + (index % 3) * 13), 4, CYAN if index % 2 else GOLD)
	if frame == 5:
		for index in range(10):
			draw_pixel_rect(draw, (134 + index * 8, 70 + math.sin(index) * 16), 4, CYAN_DARK if index % 2 else GOLD)
	return canvas


def thorn_surge_frame(frame: int, roots: list[Image.Image]) -> Image.Image:
	canvas = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(canvas, "RGBA")
	crouch_y = [4, 6, 3, -2, 1, 2][frame]
	lunge = [-4, 2, 13, 22, 15, 5][frame]
	if frame >= 1:
		draw_ground_vine(draw, 72 + lunge, 142, 136 + frame * 14, 128 - frame * 4, frame, 10 + frame)
	if frame >= 2:
		draw_ground_vine(draw, 62 + lunge, 152, 214, 112, frame + 2, 13)
	if frame in (3, 4):
		for index, x in enumerate([148, 166, 184, 202]):
			height = 48 + (index % 2) * 20 + (6 if frame == 3 else -2)
			base = (x, 142 - index * 4)
			tip = (x + (-8 if index % 2 else 8), base[1] - height)
			draw.line((base[0], base[1], tip[0], tip[1]), fill=INK, width=13)
			draw.line((base[0], base[1], tip[0], tip[1]), fill=BARK, width=9)
			draw.line((base[0], base[1], tip[0], tip[1]), fill=ROOT_LIGHT, width=4)
			draw_spark(draw, tip, 8, GOLD, GOLD_HOT)
	paste_sprite(canvas, roots[frame % len(roots)], (14 + lunge, 20 + crouch_y), scale=1.02 if frame in (2, 3) else 1.0, rotation=-3.0 if frame == 3 else 0.0)
	if frame >= 2:
		draw_shards(draw, (184, 92), [ROOT_LIGHT, GOLD, BARK_LIGHT, ROOT], 12 + frame * 2, frame, 50.0)
	if frame == 0:
		for index in range(6):
			draw_pixel_rect(draw, (68 + index * 8, 142 - (index % 2) * 5), 5, ROOT if index % 2 else BARK_LIGHT)
	return canvas


def guarded_spark_frame(frame: int, roots: list[Image.Image]) -> Image.Image:
	canvas = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(canvas, "RGBA")
	center = (102, 89)
	if frame >= 1:
		draw_hex_shield(draw, center, 72 + (frame % 2) * 4, frame)
	if frame >= 2:
		draw.arc((24, 16, 174, 160), start=frame * 24, end=frame * 24 + 210, fill=ROOT_LIGHT, width=5)
		draw.arc((32, 24, 166, 152), start=frame * 31 + 160, end=frame * 31 + 330, fill=CYAN, width=4)
	paste_sprite(canvas, roots[frame % len(roots)], (16 + (frame % 2) * 2, 18 - (2 if frame in (2, 3) else 0)), scale=0.98)
	if frame in (3, 4):
		draw_lightning(draw, (144, 82), (210, 62 if frame == 3 else 74), frame + 4, width=5)
		draw_spark(draw, (200, 66 if frame == 3 else 78), 15, GOLD, CYAN)
	if frame == 5:
		draw_shards(draw, center, [CYAN, ROOT_LIGHT, GOLD, CYAN_DARK], 18, frame, 76.0)
	return canvas


def enemy_data_leak_frame(frame: int, enemies: list[Image.Image]) -> Image.Image:
	canvas = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(canvas, "RGBA")
	pulse = [0, -4, -8, -14, -7, -2][frame]
	paste_sprite(canvas, enemies[frame % len(enemies)], (29 + pulse, 3 + (frame % 2) * 2), scale=1.02 if frame in (2, 3) else 1.0)
	if frame >= 1:
		for lane in range(4):
			y = 48 + lane * 18 + ((frame + lane) % 2) * 6
			start_x = 100 + pulse - lane * 6
			end_x = 12 + lane * 10
			draw_polyline(
				draw,
				[(start_x, y), (78, y - 12 + lane * 7), (44, y + 10 - lane * 3), (end_x, y - 4)],
				MAGENTA_DARK,
				MAGENTA if lane % 2 else CYAN,
				5 + lane % 2,
			)
	if frame >= 2:
		for index in range(24):
			x = 12 + (index * 17 + frame * 9) % 190
			y = 24 + (index * 23 + frame * 11) % 112
			color = MAGENTA if index % 3 == 0 else CYAN if index % 3 == 1 else WARNING
			draw.rectangle((x, y, x + 8 + (index % 2) * 4, y + 3), fill=color)
		draw_spark(draw, (58, 80), 24 + frame, MAGENTA, CYAN)
	if frame == 5:
		draw_shards(draw, (80, 78), [MAGENTA, CYAN, MAGENTA_DARK, VIOLET], 30, frame, 84.0)
	return canvas


def draw_vfx_root() -> Image.Image:
	canvas = Image.new("RGBA", VFX_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(canvas, "RGBA")
	for offset in (0, 12, -10):
		draw_lightning(draw, (16, 72 + offset // 3), (170, 54 + offset), offset // 2, width=8)
	draw_spark(draw, (144, 58), 34, CYAN, GOLD_HOT)
	draw_shards(draw, (132, 62), [CYAN, CYAN_DARK, GOLD, GOLD_HOT], 30, 2, 72.0)
	return canvas


def draw_vfx_thorn() -> Image.Image:
	canvas = Image.new("RGBA", VFX_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(canvas, "RGBA")
	for index in range(4):
		draw_ground_vine(draw, 18, 116 - index * 3, 160, 68 - index * 9, index + 2, 12)
	for x in (92, 116, 142, 164):
		draw.line((x, 118, x + 12, 34), fill=INK, width=13)
		draw.line((x, 118, x + 12, 34), fill=BARK, width=9)
		draw.line((x, 118, x + 12, 34), fill=ROOT_LIGHT, width=4)
	draw_shards(draw, (126, 58), [ROOT_LIGHT, GOLD, BARK_LIGHT, ROOT], 32, 3, 82.0)
	return canvas


def draw_vfx_guarded() -> Image.Image:
	canvas = Image.new("RGBA", VFX_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(canvas, "RGBA")
	draw_hex_shield(draw, (82, 70), 60, 3)
	draw.arc((20, 12, 144, 132), start=18, end=312, fill=ROOT_LIGHT, width=5)
	draw_lightning(draw, (116, 70), (178, 48), 7, width=5)
	draw_spark(draw, (162, 50), 17, GOLD, CYAN)
	draw_shards(draw, (82, 70), [CYAN, ROOT_LIGHT, GOLD, CYAN_DARK], 22, 4, 66.0)
	return canvas


def draw_vfx_shadow() -> Image.Image:
	canvas = Image.new("RGBA", VFX_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(canvas, "RGBA")
	draw.ellipse((48, 24, 154, 104), fill=(20, 8, 35, 225), outline=MAGENTA, width=7)
	for lane in range(5):
		draw_polyline(draw, [(154, 42 + lane * 11), (106, 56 + lane * 7), (58, 48 + lane * 13), (14, 64 + lane * 5)], MAGENTA_DARK, MAGENTA if lane % 2 else CYAN, 5)
	draw_shards(draw, (86, 66), [MAGENTA, CYAN, WARNING, VIOLET], 34, 5, 82.0)
	return canvas


def save_strip(prefix: str, frames: list[Image.Image], review_frames: Path) -> None:
	review_frames.mkdir(parents=True, exist_ok=True)
	for index, frame in enumerate(frames):
		name = f"{prefix}_{index}.png"
		frame.save(asset(name))
		frame.save(review_frames / name)


def archive_existing() -> None:
	ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)
	patterns = [
		"root_spark_attack_*.png",
		"root_spark_attack_battle_*.png",
		"thorn_surge_attack_*.png",
		"thorn_surge_attack_battle_*.png",
		"guarded_spark_attack_*.png",
		"guarded_spark_attack_battle_*.png",
		"enemy_data_leak_*.png",
		"vfx_root_spark.png",
		"vfx_thorn_surge.png",
		"vfx_shadow_burst.png",
		"vfx_guarded_spark.png",
	]
	for pattern in patterns:
		for path in ASSET_DIR.glob(pattern):
			target = ARCHIVE_DIR / path.name
			if not target.exists():
				shutil.copy2(path, target)


def make_preview(rows: dict[str, list[Image.Image]]) -> Image.Image:
	label_width = 168
	cell_w, cell_h = FRAME_SIZE
	header_h = 28
	row_h = cell_h + 24
	width = label_width + cell_w * 6 + 32
	height = header_h + row_h * len(rows) + 28
	sheet = Image.new("RGBA", (width, height), (9, 12, 18, 255))
	draw = ImageDraw.Draw(sheet)
	font = ImageFont.load_default()
	draw.text((12, 8), "Revision 4S attack animation preview", fill=(230, 238, 246, 255), font=font)
	for row_index, (label, frames) in enumerate(rows.items()):
		y = header_h + row_index * row_h
		draw.rectangle((8, y + 8, width - 8, y + row_h - 8), fill=(18, 22, 32, 255), outline=(72, 92, 120, 255))
		draw.text((18, y + 24), label, fill=(255, 220, 94, 255), font=font)
		for index, frame in enumerate(frames):
			x = label_width + index * cell_w
			draw.rectangle((x, y + 12, x + cell_w - 1, y + 12 + cell_h - 1), fill=(4, 5, 8, 255), outline=(49, 62, 76, 255))
			sheet.alpha_composite(frame, (x, y + 12))
			draw.text((x + 8, y + row_h - 18), f"f{index}", fill=(170, 190, 204, 255), font=font)
	return sheet


def main() -> None:
	archive_existing()
	REVIEW_DIR.mkdir(parents=True, exist_ok=True)
	review_frames = REVIEW_DIR / "frames"

	roots = [harden_alpha(load_asset(f"root_idle_battle_{index}.png")) for index in range(4)]
	enemies = [harden_alpha(load_asset(f"enemy_idle_battle_{index}.png")) for index in range(4)]

	root_spark = [root_spark_frame(index, roots) for index in range(6)]
	thorn_surge = [thorn_surge_frame(index, roots) for index in range(6)]
	guarded_spark = [guarded_spark_frame(index, roots) for index in range(6)]
	data_leak = [enemy_data_leak_frame(index, enemies) for index in range(6)]

	for prefix, frames in (
		("root_spark_attack", root_spark),
		("root_spark_attack_battle", root_spark),
		("thorn_surge_attack", thorn_surge),
		("thorn_surge_attack_battle", thorn_surge),
		("guarded_spark_attack", guarded_spark),
		("guarded_spark_attack_battle", guarded_spark),
		("enemy_data_leak", data_leak),
	):
		save_strip(prefix, frames, review_frames)

	vfx = {
		"vfx_root_spark.png": draw_vfx_root(),
		"vfx_thorn_surge.png": draw_vfx_thorn(),
		"vfx_shadow_burst.png": draw_vfx_shadow(),
		"vfx_guarded_spark.png": draw_vfx_guarded(),
	}
	for name, image in vfx.items():
		image.save(asset(name))
		image.save(review_frames / name)

	preview = make_preview(
		{
			"Root Spark - bolt lunge": root_spark,
			"Thorn Surge - ground eruption": thorn_surge,
			"Guarded Spark - shield counter": guarded_spark,
			"Data Leak - hostile glitch": data_leak,
		}
	)
	preview_path = REVIEW_DIR / "attack-animation-buildout-2-preview-2026-05-26.png"
	preview.save(preview_path)
	print(f"Wrote distinct attack strips and preview to {preview_path}")


if __name__ == "__main__":
	main()
