extends Control
class_name BattleBackdrop

var time := 0.0
var context: Dictionary = {}
var enemy_id := "firewall_sentinel"
var vfx_pressure := 0.0
var vfx_pressure_duration := 0.01
var vfx_pressure_age := 0.0
var palette_jolt := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_context(next_context: Dictionary, next_enemy_id: String) -> void:
	context = next_context.duplicate(true)
	enemy_id = next_enemy_id
	queue_redraw()

func _process(delta: float) -> void:
	advance_for_test(delta)
	queue_redraw()

func set_vfx_pressure(next_palette_jolt: String, intensity: float, duration: float) -> void:
	palette_jolt = next_palette_jolt
	vfx_pressure = clampf(intensity, 0.0, 1.0)
	vfx_pressure_duration = maxf(0.01, duration)
	vfx_pressure_age = 0.0
	queue_redraw()

func advance_for_test(delta: float) -> void:
	time += maxf(0.0, delta)
	if vfx_pressure > 0.0:
		vfx_pressure_age += maxf(0.0, delta)
		if vfx_pressure_age >= vfx_pressure_duration:
			vfx_pressure = 0.0
			palette_jolt = ""

func get_vfx_pressure() -> float:
	return vfx_pressure

func get_palette_jolt() -> String:
	return palette_jolt

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var palette := _palette()
	draw_rect(rect, palette["sky"])
	draw_rect(Rect2(0, size.y * 0.54, size.x, size.y * 0.46), palette["ground"])
	draw_rect(Rect2(0, size.y * 0.76, size.x, size.y * 0.24), palette["floor"])

	_draw_sky_faults()
	_draw_floor_grid()
	_draw_forge_rings()
	_draw_data_pylons()
	_draw_arena_set_piece()
	_draw_vfx_pressure()

func _draw_sky_faults() -> void:
	var pulse := (sin(time * 1.8) + 1.0) * 0.5
	var palette := _palette()
	for i in 8:
		var x: float = size.x * (0.08 + i * 0.13)
		var top: float = size.y * (0.08 + fmod(i * 0.17, 0.18))
		var bottom: float = size.y * (0.32 + fmod(i * 0.11, 0.16))
		var color: Color = palette["fault"].lerp(palette["accent"], pulse * 0.45)
		draw_line(Vector2(x, top), Vector2(x + 22.0 * sin(time + i), bottom), color, 2.0)

func _draw_floor_grid() -> void:
	var horizon := size.y * 0.56
	var floor_bottom := size.y
	var palette := _palette()
	for i in 12:
		var ratio := float(i) / 11.0
		var y := lerpf(horizon, floor_bottom, ratio * ratio)
		var width := lerpf(1.0, 3.0, ratio)
		draw_line(Vector2(0, y), Vector2(size.x, y), palette["grid"], width)

	for i in 13:
		var x := lerpf(-size.x * 0.24, size.x * 1.24, float(i) / 12.0)
		draw_line(Vector2(size.x * 0.5, horizon), Vector2(x, floor_bottom), palette["grid"].darkened(0.12), 1.5)

func _draw_forge_rings() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.61)
	var pulse := (sin(time * 3.0) + 1.0) * 0.5
	var palette := _palette()
	for i in 4:
		var radius := 70.0 + i * 42.0 + pulse * 8.0
		draw_arc(center, radius, PI * 0.04, PI * 0.96, 56, Color(palette["accent"], 0.16 - i * 0.02), 4.0)
	draw_circle(center, 34.0 + pulse * 4.0, Color(palette["accent"], 0.16))

func _draw_data_pylons() -> void:
	var palette := _palette()
	for side: int in [-1, 1]:
		for i in 3:
			var x: float = size.x * (0.5 + side * (0.2 + i * 0.12))
			var height: float = 105.0 - i * 18.0
			var base_y: float = size.y * (0.56 + i * 0.045)
			var points := PackedVector2Array([
				Vector2(x - 18, base_y),
				Vector2(x + 18, base_y),
				Vector2(x + 10, base_y - height),
				Vector2(x - 10, base_y - height),
			])
			draw_polygon(points, PackedColorArray([palette["pylon_dark"], palette["pylon_dark"], palette["pylon"], palette["pylon"]]))
			draw_line(Vector2(x, base_y - height + 10), Vector2(x, base_y - 10), Color(palette["accent"], 0.48), 2.0)

func _draw_arena_set_piece() -> void:
	if not context.get("is_arena", false):
		return
	var center := Vector2(size.x * 0.5, size.y * 0.62)
	var pulse := (sin(time * 4.0) + 1.0) * 0.5
	var palette := _palette()
	draw_arc(center, 190.0 + pulse * 8.0, 0.0, TAU, 72, Color(palette["accent"], 0.42), 5.0)
	draw_arc(center, 128.0 - pulse * 5.0, 0.0, TAU, 72, Color("#f2e7c7", 0.22), 2.0)
	for i in 10:
		var angle := TAU * float(i) / 10.0 + time * 0.12
		var marker := center + Vector2(cos(angle), sin(angle) * 0.32) * 178.0
		draw_circle(marker, 5.0 + pulse * 2.0, Color(palette["accent"], 0.65))
	_draw_arena_banner()

func _draw_arena_banner() -> void:
	var label: String = context.get("location_label", "Arena")
	var font := get_theme_default_font()
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
	var pos := Vector2(size.x * 0.5 - text_size.x * 0.5, size.y * 0.12)
	draw_rect(Rect2(pos - Vector2(18, 10), text_size + Vector2(36, 18)), Color("#0d0f12", 0.72))
	draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_CENTER, text_size.x, 24, Color("#f3ead7"))

func _draw_vfx_pressure() -> void:
	if vfx_pressure <= 0.0:
		return
	var progress := clampf(vfx_pressure_age / maxf(0.01, vfx_pressure_duration), 0.0, 1.0)
	var strength := vfx_pressure * (1.0 - progress)
	var color := _palette_jolt_color()
	draw_rect(Rect2(Vector2.ZERO, size), Color(color.r, color.g, color.b, 0.08 * strength))
	for i in 8:
		var y := fmod(time * 120.0 + i * 81.0, maxf(1.0, size.y))
		draw_line(Vector2(0, y), Vector2(size.x, y + sin(time * 4.0 + i) * 18.0), Color(color.r, color.g, color.b, 0.18 * strength), 2.0 + strength * 2.0)
	var center := size * 0.5
	for ring in 3:
		draw_arc(center, 120.0 + ring * 70.0 + progress * 80.0, 0, TAU, 80, Color(color.r, color.g, color.b, 0.25 * strength), 3.0)

func _palette_jolt_color() -> Color:
	match palette_jolt:
		"scrap_gold":
			return Color("#d6d0bc")
		"checksum_orange":
			return Color("#f0b66c")
		"silver_blue":
			return Color("#c0c8ff")
		"magma":
			return Color("#ff7a35")
		"corrupt":
			return Color("#b084ff")
		_:
			return Color("#f3ead7")

func _palette() -> Dictionary:
	var location_id: String = context.get("location_id", "")
	if enemy_id == "sys_admin" or location_id == "kernel_core":
		return {
			"sky": Color("#060914"),
			"ground": Color("#101522"),
			"floor": Color("#171c2c"),
			"fault": Color("#7afcff"),
			"accent": Color("#f4ead2"),
			"grid": Color("#7afcff", 0.32),
			"pylon": Color("#dfefff"),
			"pylon_dark": Color("#293142"),
		}
	if enemy_id == "lunar_mote" or location_id == "lunar_resonance_bowl":
		return {
			"sky": Color("#101522"),
			"ground": Color("#1b2035"),
			"floor": Color("#24283f"),
			"fault": Color("#5d6fa8"),
			"accent": Color("#c0c8ff"),
			"grid": Color("#7583c7", 0.35),
			"pylon": Color("#5a607b"),
			"pylon_dark": Color("#2f344a"),
		}
	if enemy_id == "scrap_wraith" or location_id == "scrap_pit_arena":
		return {
			"sky": Color("#141619"),
			"ground": Color("#202225"),
			"floor": Color("#2b2a29"),
			"fault": Color("#706f6a"),
			"accent": Color("#d6d0bc"),
			"grid": Color("#8a8170", 0.34),
			"pylon": Color("#585b5c"),
			"pylon_dark": Color("#2f3132"),
		}
	if enemy_id == "corrupt_drake" or location_id == "checksum_ring":
		return {
			"sky": Color("#1a1211"),
			"ground": Color("#2a1916"),
			"floor": Color("#351f1b"),
			"fault": Color("#7d2e2b"),
			"accent": Color("#f0b66c"),
			"grid": Color("#b66f43", 0.35),
			"pylon": Color("#704238"),
			"pylon_dark": Color("#3b2522"),
		}
	return {
		"sky": Color("#171716"),
		"ground": Color("#211c18"),
		"floor": Color("#2b261f"),
		"fault": Color("#6f423c"),
		"accent": Color("#d29a5d"),
		"grid": Color("#5a4939", 0.42),
		"pylon": Color("#45545f"),
		"pylon_dark": Color("#2f3338"),
	}
