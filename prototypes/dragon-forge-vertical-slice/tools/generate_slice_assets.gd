# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: Does a player experience the hatch -> map -> battle -> reward Dragon Forge loop within 3-5 minutes without guidance?
# Date: 2026-05-26

extends SceneTree

const OUT_DIR := "res://assets/slice"
const TRANSPARENT := Color(0, 0, 0, 0)
const INK := Color("#05050a")
const CHARCOAL := Color("#111118")
const ROOT_GREEN := Color("#62b86a")
const ROOT_DARK := Color("#246337")
const EMBER := Color("#f05a28")
const CYAN := Color("#36d6e7")
const GOLD := Color("#f6c945")
const MAGENTA := Color("#d83af0")
const SKY := Color("#26435a")
const HILL := Color("#2f7c3d")
const HILL_DARK := Color("#1b4f2a")
const EARTH := Color("#36251a")
const DRAGONSIM_ASSET_DIR := "/Users/Scott_1/DEV/DF/dragonsim/assets"
const DRAGONSIM_PUBLIC_DIR := "/Users/Scott_1/DEV/DF/dragonsim/app/public"
const PLACEHOLDER_REGEN_FLAG := "--force-placeholder-regen"


func _init() -> void:
	var args := OS.get_cmdline_args()
	for user_arg in OS.get_cmdline_user_args():
		if not args.has(user_arg):
			args.append(user_arg)
	if not args.has(PLACEHOLDER_REGEN_FLAG):
		push_warning("Refusing to overwrite target-board assets. Re-run with %s only if you intentionally want the older placeholder generator output." % PLACEHOLDER_REGEN_FLAG)
		quit(0)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_save("forge_hub.png", _make_forge_hub())
	_save("hatchery.png", _make_hatchery())
	_save("village_edge_map.png", _make_village_edge_map())
	_save("battlefield.png", _make_battlefield())
	_save("victory.png", _make_victory())
	_save("root_wyrmling.png", _make_root_wyrmling())
	_save("enemy_protocol.png", _make_enemy_protocol())
	_save("root_egg.png", _make_root_egg())
	_save("data_scraps.png", _make_data_scraps())
	_save_dragonsim_derivatives()
	print("Generated Dragon Forge slice assets in %s" % OUT_DIR)
	quit(0)


func _save(file_name: String, image: Image) -> void:
	var err := image.save_png("%s/%s" % [OUT_DIR, file_name])
	if err != OK:
		push_error("Could not save %s: %s" % [file_name, error_string(err)])


func _load_external(path: String) -> Image:
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Could not load external asset %s: %s" % [path, error_string(err)])
	return image


func _crop_resize(source: Image, rect: Rect2i, target: Vector2i) -> Image:
	var image := source.get_region(rect)
	image.resize(target.x, target.y, Image.INTERPOLATE_LANCZOS)
	return image


func _alpha_bounds(source: Image) -> Rect2i:
	var min_x := source.get_width()
	var min_y := source.get_height()
	var max_x := 0
	var max_y := 0
	var found := false
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			if source.get_pixel(x, y).a > 0.05:
				found = true
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if not found:
		return Rect2i(Vector2i.ZERO, Vector2i(source.get_width(), source.get_height()))
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _resize_to_fit(source: Image, target: Vector2i, padding: int = 0) -> Image:
	var trimmed := source.get_region(_alpha_bounds(source))
	var usable := Vector2i(maxi(1, target.x - padding * 2), maxi(1, target.y - padding * 2))
	var scale := minf(float(usable.x) / float(trimmed.get_width()), float(usable.y) / float(trimmed.get_height()))
	var draw_size := Vector2i(maxi(1, roundi(trimmed.get_width() * scale)), maxi(1, roundi(trimmed.get_height() * scale)))
	trimmed.resize(draw_size.x, draw_size.y, Image.INTERPOLATE_LANCZOS)
	var output := _canvas(target)
	output.blit_rect(trimmed, Rect2i(Vector2i.ZERO, draw_size), Vector2i((target.x - draw_size.x) / 2, (target.y - draw_size.y) / 2))
	return output


func _chroma_key_green(image: Image) -> Image:
	var result := image.duplicate()
	result.convert(Image.FORMAT_RGBA8)
	for y in range(result.get_height()):
		for x in range(result.get_width()):
			var c: Color = result.get_pixel(x, y)
			if c.g > 0.52 and c.r < 0.24 and c.b < 0.24:
				result.set_pixel(x, y, TRANSPARENT)
	return result


func _tint_nontransparent(image: Image, tint: Color, strength: float) -> Image:
	var result := image.duplicate()
	result.convert(Image.FORMAT_RGBA8)
	for y in range(result.get_height()):
		for x in range(result.get_width()):
			var c: Color = result.get_pixel(x, y)
			if c.a > 0.02:
				var tinted: Color = c.lerp(Color(c.r * tint.r, c.g * tint.g, c.b * tint.b, c.a), strength)
				tinted.a = c.a
				result.set_pixel(x, y, tinted)
	return result


func _extract_dragonsim_dragon(element: String, target: Vector2i, tint: Color = Color.WHITE, strength: float = 0.0) -> Image:
	var source := _load_external("%s/sprites/%s.png" % [DRAGONSIM_PUBLIC_DIR, element])
	if source.is_empty():
		source = _load_external("%s/dragons/%s.png" % [DRAGONSIM_ASSET_DIR, element])
	if source.is_empty():
		return _canvas(target)
	var frame_rect := Rect2i(0, 0, mini(352, source.get_width()), mini(384, source.get_height()))
	var sprite := source.get_region(frame_rect)
	sprite = _chroma_key_green(sprite)
	sprite = _resize_to_fit(sprite, target, 0)
	if strength > 0.0:
		sprite = _tint_nontransparent(sprite, tint, strength)
	return sprite


func _extract_dragonsim_attack_frame(element: String, frame: int, target: Vector2i, tint: Color = Color.WHITE, strength: float = 0.0) -> Image:
	var source := _load_external("%s/sprites/%s_attack.png" % [DRAGONSIM_PUBLIC_DIR, element])
	if source.is_empty():
		return _canvas(target)
	var x := frame * 352
	if x >= source.get_width():
		return _canvas(target)
	var frame_rect := Rect2i(x, 0, mini(352, source.get_width() - x), mini(384, source.get_height()))
	var sprite := source.get_region(frame_rect)
	sprite = _chroma_key_green(sprite)
	sprite = _resize_to_fit(sprite, target, 0)
	if strength > 0.0:
		sprite = _tint_nontransparent(sprite, tint, strength)
	return sprite


func _extract_public_asset(relative_path: String, target: Vector2i) -> Image:
	var source := _load_external("%s/%s" % [DRAGONSIM_PUBLIC_DIR, relative_path])
	if source.is_empty():
		return _canvas(target)
	return _resize_to_fit(source, target, 0)


func _extract_public_arena(relative_path: String, target: Vector2i, trim_top: int = 0) -> Image:
	var source := _load_external("%s/%s" % [DRAGONSIM_PUBLIC_DIR, relative_path])
	if source.is_empty():
		return _canvas(target)
	var y := mini(trim_top, source.get_height() - 1)
	var cropped := source.get_region(Rect2i(0, y, source.get_width(), source.get_height() - y))
	cropped.resize(target.x, target.y, Image.INTERPOLATE_LANCZOS)
	return cropped


func _save_dragonsim_derivatives() -> void:
	var felix_source := _load_external("%s/../app/public/felix.png" % DRAGONSIM_ASSET_DIR)
	if not felix_source.is_empty():
		_save("felix.png", _resize_to_fit(felix_source, Vector2i(384, 454), 0))
		_save("felix_portrait.png", _resize_to_fit(felix_source, Vector2i(256, 256), 0))

	_save("hatchery.png", _make_dragonsim_hatchery())
	var arena_source := _load_external("%s/arenas.jpg" % DRAGONSIM_ASSET_DIR)
	if not arena_source.is_empty():
		_save("battlefield.png", _crop_resize(arena_source, Rect2i(470, 12, 470, 240), Vector2i(640, 360)))
	_save("village_edge_map.png", _extract_public_arena("arenas/venom.png", Vector2i(640, 360), 24))
	_save("victory.png", _make_dragonsim_victory())

	var dragon_specs := {
		"fire": Color.WHITE,
		"ice": Color.WHITE,
		"shadow": Color.WHITE,
		"stone": Color.WHITE,
		"storm": Color.WHITE,
		"venom": Color.WHITE,
	}
	for element in dragon_specs:
		_save("dragonsim_%s.png" % element, _extract_dragonsim_dragon(element, Vector2i(224, 168)))

	_save("root_wyrmling.png", _extract_dragonsim_dragon("venom", Vector2i(192, 144), Color("#7ee06a"), 0.28))
	for frame in range(4):
		_save("root_attack_%d.png" % frame, _make_root_attack_frame(frame))
		_save("enemy_attack_%d.png" % frame, _extract_dragonsim_attack_frame("shadow", frame, Vector2i(224, 168), Color("#9d66ff"), 0.20))
	_save("enemy_protocol.png", _extract_public_asset("sprites/npc/bit_wraith_sprites.png", Vector2i(192, 176)))
	_save("npc_logic_bomb.png", _extract_public_asset("sprites/npc/logic_bomb_sprites.png", Vector2i(160, 160)))
	_save("npc_recursive_golem.png", _extract_public_asset("sprites/npc/recursive_golem_sprites.png", Vector2i(176, 192)))
	_save("vfx_root_spark.png", _make_root_spark_vfx())
	_save("vfx_thorn_surge.png", _make_thorn_surge_vfx())
	_save("vfx_shadow_burst.png", _make_shadow_burst_vfx())


func _canvas(size: Vector2i, fill: Color = TRANSPARENT) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(fill)
	return image


func _rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	image.fill_rect(Rect2i(x, y, w, h), color)


func _outline_rect(image: Image, x: int, y: int, w: int, h: int, fill: Color, outline: Color = INK, border: int = 4) -> void:
	_rect(image, x, y, w, h, outline)
	_rect(image, x + border, y + border, w - border * 2, h - border * 2, fill)


func _line_rects(image: Image, points: Array[Vector2i], thickness: int, color: Color) -> void:
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		var steps: int = max(abs(b.x - a.x), abs(b.y - a.y))
		for s in range(steps + 1):
			var t := float(s) / float(max(1, steps))
			var p := Vector2i(roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t)))
			_rect(image, p.x - thickness / 2, p.y - thickness / 2, thickness, thickness, color)


func _sky_and_floor(image: Image) -> void:
	_rect(image, 0, 0, image.get_width(), image.get_height(), SKY)
	for i in range(40):
		var x := (i * 73) % image.get_width()
		var y := 18 + (i * 31) % 138
		_rect(image, x, y, 12, 4, Color(0.18, 0.32, 0.34, 0.55))
	_rect(image, 0, 246, image.get_width(), 114, EARTH)
	for i in range(16):
		_rect(image, i * 48, 278 + (i % 3) * 18, 72, 4, Color("#21170f"))


func _server_bank(image: Image, x: int, y: int, w: int, h: int) -> void:
	_outline_rect(image, x, y, w, h, Color("#121923"))
	for rack in range(5):
		var rx := x + 12 + rack * ((w - 24) / 5)
		_outline_rect(image, rx, y + 14, 34, h - 28, Color("#18212a"))
		for row in range(5):
			_rect(image, rx + 8, y + 30 + row * 20, 14, 4, Color("#304050"))
			_rect(image, rx + 24, y + 26 + row * 20, 6, 6, CYAN if (rack + row) % 2 == 0 else GOLD)


func _hills(image: Image) -> void:
	for i in range(7):
		var x := -40 + i * 110
		var c := HILL if i % 2 == 0 else HILL_DARK
		for yy in range(150, 248):
			var half_width := yy - 130
			_rect(image, x + 70 - half_width / 2, yy, half_width, 2, c)
	for i in range(6):
		var tx := 54 + i * 104
		var ty := 206 + (i % 2) * 18
		_rect(image, tx, ty, 10, 44, Color("#4b2a16"))
		_rect(image, tx - 22, ty - 28, 54, 30, Color("#3b943f"))
		_rect(image, tx - 12, ty - 44, 36, 22, Color("#62b86a"))


func _make_forge_hub() -> Image:
	var image := _canvas(Vector2i(640, 360))
	_sky_and_floor(image)
	_server_bank(image, 24, 36, 150, 176)
	_outline_rect(image, 216, 198, 160, 58, Color("#5a2c16"))
	for i in range(8):
		_rect(image, 234 + i * 16, 210 + (i % 3) * 8, 10, 30, EMBER)
	_rect(image, 238, 232, 118, 8, GOLD)
	_outline_rect(image, 450, 94, 92, 126, Color("#18212a"))
	for i in range(5):
		_rect(image, 468, 116 + i * 18, 56, 7, Color("#31404d"))
	_rect(image, 520, 156, 10, 10, EMBER)
	_draw_root_egg_on(image, 394, 166, 1)
	_draw_ring(image, 400, 176, 72, CYAN)
	return image


func _make_hatchery() -> Image:
	var image := _canvas(Vector2i(640, 360))
	_sky_and_floor(image)
	_server_bank(image, 448, 48, 152, 150)
	_draw_ring(image, 162, 178, 96, CYAN)
	_draw_ring(image, 162, 178, 74, GOLD)
	_draw_root_egg_on(image, 148, 170, 2)
	_line_rects(image, [Vector2i(150, 104), Vector2i(166, 136), Vector2i(148, 170), Vector2i(178, 222)], 5, MAGENTA)
	_draw_root_wyrmling_on(image, 308, 232, 1)
	for i in range(9):
		_rect(image, 250 + i * 26, 80 + (i % 4) * 12, 8, 8, CYAN if i % 2 == 0 else GOLD)
	return image


func _make_village_edge_map() -> Image:
	var image := _canvas(Vector2i(640, 360))
	_rect(image, 0, 0, 640, 360, Color("#2b5c56"))
	_hills(image)
	var route: Array[Vector2i] = [Vector2i(70, 238), Vector2i(172, 168), Vector2i(288, 188), Vector2i(404, 132), Vector2i(520, 188)]
	_line_rects(image, route, 14, Color("#758a5f"))
	_line_rects(image, route, 5, Color("#2d3526"))
	for i in range(route.size()):
		var p: Vector2i = route[i]
		_outline_rect(image, p.x - 24, p.y - 24, 48, 48, ROOT_GREEN if i == 0 else Color("#525a62"))
		_rect(image, p.x - 8, p.y - 8, 16, 16, GOLD if i == 1 else CHARCOAL)
	_outline_rect(image, 508, 72, 92, 92, Color("#5c1520"))
	_rect(image, 528, 92, 52, 52, MAGENTA)
	_line_rects(image, [Vector2i(528, 92), Vector2i(580, 144)], 6, GOLD)
	_line_rects(image, [Vector2i(580, 92), Vector2i(528, 144)], 6, GOLD)
	_outline_rect(image, 36, 236, 50, 38, Color("#442a16"))
	_rect(image, 50, 216, 22, 22, GOLD)
	return image


func _make_battlefield() -> Image:
	var image := _canvas(Vector2i(640, 360))
	_sky_and_floor(image)
	_hills(image)
	_outline_rect(image, 28, 56, 186, 156, Color("#12331d"))
	_outline_rect(image, 426, 56, 186, 156, Color("#3a1017"))
	_draw_ring(image, 320, 144, 54, CYAN)
	_outline_rect(image, 286, 120, 68, 48, Color("#203c47"), CYAN)
	_line_rects(image, [Vector2i(270, 90), Vector2i(370, 198)], 5, CYAN)
	_line_rects(image, [Vector2i(370, 90), Vector2i(270, 198)], 5, GOLD)
	return image


func _make_victory() -> Image:
	var image := _canvas(Vector2i(640, 360))
	_sky_and_floor(image)
	_hills(image)
	_outline_rect(image, 252, 150, 130, 70, Color("#4a2611"))
	_outline_rect(image, 270, 118, 94, 38, GOLD)
	for i in range(9):
		_rect(image, 274 + i * 10, 136 + (i % 3) * 14, 10, 10, Color("#f39a38"))
	_rect(image, 440, 214, 160, 10, ROOT_GREEN)
	for i in range(4):
		_outline_rect(image, 438 + i * 46, 198 + (i % 2) * 14, 32, 32, ROOT_GREEN)
	return image


func _make_dragonsim_hatchery() -> Image:
	var image := _canvas(Vector2i(640, 360), Color("#070b13"))
	var source := _load_external("%s/arenas/quantum_forge.png" % DRAGONSIM_PUBLIC_DIR)
	if not source.is_empty():
		var crop_x := mini(14, source.get_width() - 1)
		var cropped := source.get_region(Rect2i(crop_x, 0, source.get_width() - crop_x * 2, mini(145, source.get_height())))
		cropped.convert(Image.FORMAT_RGBA8)
		cropped.resize(640, 178, Image.INTERPOLATE_LANCZOS)
		image.blit_rect(cropped, Rect2i(0, 0, 640, 178), Vector2i.ZERO)
	_rect(image, 0, 178, 640, 182, Color("#0b1018"))
	for i in range(18):
		_rect(image, i * 42, 272 + (i % 3) * 18, 64, 3, Color("#1a2430"))
	for i in range(9):
		_rect(image, 74 + i * 56, 212 + (i % 4) * 11, 28, 4, CYAN if i % 2 == 0 else GOLD)
	_line_rects(image, [Vector2i(132, 292), Vector2i(230, 230), Vector2i(374, 226), Vector2i(506, 288)], 8, Color("#182a30"))
	_line_rects(image, [Vector2i(132, 292), Vector2i(230, 230), Vector2i(374, 226), Vector2i(506, 288)], 3, CYAN)
	_draw_ring(image, 188, 232, 82, CYAN)
	_draw_ring(image, 188, 232, 58, GOLD)
	_outline_rect(image, 322, 216, 112, 44, Color("#123025"), ROOT_GREEN)
	_rect(image, 342, 228, 72, 8, Color("#7ee06a"))
	_outline_rect(image, 476, 196, 86, 78, Color("#141b27"), CYAN)
	for row in range(4):
		_rect(image, 490, 212 + row * 14, 50, 4, Color("#2d4050"))
		_rect(image, 546, 210 + row * 14, 6, 6, GOLD if row % 2 == 0 else CYAN)
	return image


func _make_dragonsim_victory() -> Image:
	var image := _extract_public_arena("arenas/venom.png", Vector2i(640, 360), 24)
	if image.is_empty():
		image = _make_victory()
	image.convert(Image.FORMAT_RGBA8)
	var overlay := Color(0.08, 0.18, 0.10, 0.20)
	image.blend_rect(_canvas(Vector2i(640, 360), overlay), Rect2i(0, 0, 640, 360), Vector2i.ZERO)
	_line_rects(image, [Vector2i(88, 292), Vector2i(210, 250), Vector2i(354, 244), Vector2i(516, 286)], 10, Color("#0a2416"))
	_line_rects(image, [Vector2i(88, 292), Vector2i(210, 250), Vector2i(354, 244), Vector2i(516, 286)], 4, ROOT_GREEN)
	for i in range(5):
		_outline_rect(image, 174 + i * 48, 226 + (i % 2) * 10, 28, 28, Color("#123b20"), ROOT_GREEN)
	for i in range(14):
		var x := 212 + ((i * 31) % 210)
		var y := 68 + ((i * 19) % 100)
		_rect(image, x, y, 8, 8, GOLD if i % 2 == 0 else CYAN)
	return image


func _make_root_attack_frame(frame: int) -> Image:
	var output := _canvas(Vector2i(224, 168))
	var sizes := [Vector2i(184, 138), Vector2i(194, 146), Vector2i(206, 154), Vector2i(190, 142)]
	var offsets := [Vector2i(8, 20), Vector2i(20, 14), Vector2i(34, 8), Vector2i(18, 18)]
	var sprite := _extract_dragonsim_dragon("venom", sizes[frame], Color("#7ee06a"), 0.34)
	output.blit_rect(sprite, Rect2i(Vector2i.ZERO, sizes[frame]), offsets[frame])
	if frame == 1:
		_line_rects(output, [Vector2i(150, 82), Vector2i(210, 58)], 4, CYAN)
		_line_rects(output, [Vector2i(152, 100), Vector2i(214, 116)], 3, ROOT_GREEN)
	elif frame == 2:
		for i in range(8):
			var x := 164 + ((i * 11) % 46)
			var y := 42 + ((i * 17) % 80)
			_rect(output, x, y, 10, 10, GOLD if i % 2 == 0 else CYAN)
		_line_rects(output, [Vector2i(144, 130), Vector2i(176, 70), Vector2i(206, 130)], 6, ROOT_DARK)
		_line_rects(output, [Vector2i(156, 128), Vector2i(180, 82), Vector2i(198, 128)], 4, ROOT_GREEN)
	elif frame == 3:
		for i in range(6):
			_rect(output, 146 + i * 11, 74 + (i % 3) * 12, 8, 8, Color("#b7ff7a"))
	return output


func _make_root_spark_vfx() -> Image:
	var image := _canvas(Vector2i(192, 128))
	for i in range(12):
		var y := 18 + i * 8
		var start := Vector2i(20 + (i % 3) * 8, y)
		var end := Vector2i(168 - (i % 4) * 7, 48 + ((i * 19) % 58))
		_line_rects(image, [start, end], 5 if i % 4 == 0 else 3, CYAN if i % 2 == 0 else ROOT_GREEN)
	for i in range(10):
		var x := 48 + ((i * 31) % 96)
		var y := 26 + ((i * 17) % 74)
		_rect(image, x, y, 10, 10, GOLD if i % 3 == 0 else Color("#b7ff7a"))
	return image


func _make_thorn_surge_vfx() -> Image:
	var image := _canvas(Vector2i(224, 156))
	for i in range(9):
		var base_x := 26 + i * 22
		_line_rects(image, [Vector2i(base_x, 146), Vector2i(base_x + 18, 72 - (i % 4) * 9), Vector2i(base_x + 34, 146)], 7, ROOT_DARK)
		_line_rects(image, [Vector2i(base_x + 6, 140), Vector2i(base_x + 20, 82 - (i % 3) * 12), Vector2i(base_x + 28, 140)], 4, ROOT_GREEN)
	for i in range(18):
		_rect(image, 18 + ((i * 37) % 184), 18 + ((i * 23) % 90), 8, 8, Color("#9cff6c") if i % 2 == 0 else CYAN)
	return image


func _make_shadow_burst_vfx() -> Image:
	var image := _canvas(Vector2i(192, 128))
	for i in range(14):
		var angle := float(i) / 14.0 * TAU
		var center := Vector2i(96, 64)
		var end := center + Vector2i(roundi(cos(angle) * (64 + (i % 3) * 12)), roundi(sin(angle) * (36 + (i % 4) * 7)))
		_line_rects(image, [center, end], 5, Color("#8a44ff") if i % 2 == 0 else Color("#1a0d2f"))
	for i in range(9):
		_rect(image, 76 + ((i * 17) % 48), 44 + ((i * 13) % 38), 12, 12, MAGENTA if i % 2 == 0 else CYAN)
	return image


func _make_root_wyrmling() -> Image:
	var image := _canvas(Vector2i(160, 128))
	_draw_root_wyrmling_on(image, 82, 98, 2)
	return image


func _draw_root_wyrmling_on(image: Image, bx: int, by: int, scale: int) -> void:
	_outline_rect(image, bx - 46 * scale, by - 58 * scale, 70 * scale, 38 * scale, ROOT_GREEN)
	_outline_rect(image, bx + 14 * scale, by - 74 * scale, 42 * scale, 30 * scale, ROOT_GREEN)
	_rect(image, bx + 48 * scale, by - 62 * scale, 7 * scale, 7 * scale, INK)
	_rect(image, bx - 28 * scale, by - 46 * scale, 36 * scale, 8 * scale, Color("#9be77b"))
	_rect(image, bx - 76 * scale, by - 42 * scale, 42 * scale, 10 * scale, ROOT_DARK)
	_rect(image, bx - 92 * scale, by - 28 * scale, 54 * scale, 10 * scale, ROOT_GREEN)
	_rect(image, bx + 4 * scale, by - 88 * scale, 10 * scale, 22 * scale, ROOT_DARK)
	_rect(image, bx + 26 * scale, by - 98 * scale, 10 * scale, 28 * scale, ROOT_DARK)
	_rect(image, bx - 20 * scale, by - 22 * scale, 12 * scale, 28 * scale, INK)
	_rect(image, bx + 14 * scale, by - 22 * scale, 12 * scale, 28 * scale, INK)


func _make_enemy_protocol() -> Image:
	var image := _canvas(Vector2i(160, 128))
	_outline_rect(image, 22, 28, 116, 70, Color("#4a111a"))
	_rect(image, 38, 42, 84, 12, EMBER)
	_rect(image, 48, 64, 22, 14, GOLD)
	_rect(image, 90, 64, 22, 14, GOLD)
	_line_rects(image, [Vector2i(10, 16), Vector2i(150, 112)], 5, MAGENTA)
	_line_rects(image, [Vector2i(150, 16), Vector2i(10, 112)], 5, EMBER)
	return image


func _make_root_egg() -> Image:
	var image := _canvas(Vector2i(128, 160))
	_draw_root_egg_on(image, 64, 82, 2)
	return image


func _draw_root_egg_on(image: Image, cx: int, cy: int, scale: int) -> void:
	for y in range(-38 * scale, 46 * scale):
		var width := int((34.0 * scale) * (1.0 - abs(float(y)) / float(56 * scale)))
		width = max(width, 8 * scale)
		_rect(image, cx - width, cy + y, width * 2, 2 * scale, Color("#c8edae"))
	_rect(image, cx - 14 * scale, cy - 22 * scale, 10 * scale, 10 * scale, Color("#f1ffbf"))
	_line_rects(image, [Vector2i(cx - 8 * scale, cy - 34 * scale), Vector2i(cx + 10 * scale, cy - 8 * scale), Vector2i(cx - 6 * scale, cy + 18 * scale), Vector2i(cx + 16 * scale, cy + 42 * scale)], 4 * scale, MAGENTA)
	_draw_ring(image, cx, cy, 44 * scale, Color(0.22, 0.82, 0.46, 0.6))


func _make_data_scraps() -> Image:
	var image := _canvas(Vector2i(128, 96))
	for i in range(10):
		var x := 18 + (i % 5) * 18
		var y := 22 + (i / 5) * 28
		_outline_rect(image, x, y, 14, 14, GOLD)
		_rect(image, x + 4, y + 4, 6, 6, Color("#f39a38"))
	return image


func _draw_ring(image: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for i in range(48):
		var a := float(i) / 48.0 * TAU
		var x := cx + int(cos(a) * radius)
		var y := cy + int(sin(a) * radius)
		_rect(image, x - 3, y - 3, 6, 6, color)
