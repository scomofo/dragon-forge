extends Control
class_name ProceduralVfxOverlay

const DEFAULT_LIFETIME := 0.62

var bursts: Array[Dictionary] = []
var screen_effects: Array[Dictionary] = []
var last_burst_kind := ""
var last_screen_effect_id := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func emit_burst(kind: String, origin: Vector2, profile: Dictionary = {}) -> void:
	var lifetime := float(profile.get("lifetime", DEFAULT_LIFETIME))
	var burst := {
		"kind": kind,
		"origin": origin,
		"profile": profile.duplicate(true),
		"age": 0.0,
		"lifetime": lifetime,
	}
	bursts.append(burst)
	last_burst_kind = kind
	queue_redraw()

func get_active_burst_count() -> int:
	return bursts.size()

func get_last_burst_kind() -> String:
	return last_burst_kind

func emit_screen_effect(effect_id: String, intensity: float, duration: float) -> void:
	screen_effects.append({
		"id": effect_id,
		"intensity": clampf(intensity, 0.0, 1.0),
		"age": 0.0,
		"duration": maxf(0.01, duration),
	})
	last_screen_effect_id = effect_id
	queue_redraw()

func get_active_screen_effect_count() -> int:
	return screen_effects.size()

func get_last_screen_effect_id() -> String:
	return last_screen_effect_id

func advance_for_test(delta: float) -> void:
	_advance(delta)

func _process(delta: float) -> void:
	_advance(delta)

func _advance(delta: float) -> void:
	for index in range(bursts.size() - 1, -1, -1):
		bursts[index]["age"] = float(bursts[index]["age"]) + maxf(0.0, delta)
		if float(bursts[index]["age"]) >= float(bursts[index]["lifetime"]):
			bursts.remove_at(index)
	for index in range(screen_effects.size() - 1, -1, -1):
		screen_effects[index]["age"] = float(screen_effects[index]["age"]) + maxf(0.0, delta)
		if float(screen_effects[index]["age"]) >= float(screen_effects[index]["duration"]):
			screen_effects.remove_at(index)
	queue_redraw()

func _draw() -> void:
	for burst in bursts:
		_draw_burst(burst)
	for effect in screen_effects:
		_draw_screen_effect(effect)

func _draw_burst(burst: Dictionary) -> void:
	var kind := str(burst.get("kind", "slash"))
	var origin: Vector2 = burst.get("origin", Vector2.ZERO)
	var profile: Dictionary = burst.get("profile", {})
	var lifetime := maxf(0.01, float(burst.get("lifetime", DEFAULT_LIFETIME)))
	var progress := clampf(float(burst.get("age", 0.0)) / lifetime, 0.0, 1.0)
	match kind:
		"magma":
			_draw_heat_bloom(origin, profile, progress)
		"shockwave":
			_draw_shockwave(origin, profile, progress)
		"coolant_steam":
			_draw_coolant_steam(origin, profile, progress)
		"wrench_sparks":
			_draw_wrench_sparks(origin, profile, progress)
		"prism":
			_draw_prism_refraction(origin, profile, progress)
		"ascii_compile":
			_draw_ascii_compile(origin, profile, progress)
		"corrupt":
			_draw_corruption_split(origin, profile, progress)
		"arena":
			_draw_arena_ring(origin, profile, progress)
		"thread":
			_draw_thread_sparks(origin, profile, progress)
		_:
			_draw_slash_arc(origin, profile, progress)

func _draw_heat_bloom(origin: Vector2, profile: Dictionary, progress: float) -> void:
	var flash: Color = profile.get("impact_flash", Color("#ffd166", 0.28))
	var radius := lerpf(24.0, 168.0, progress)
	for i in 4:
		var alpha := maxf(0.0, flash.a * (1.0 - progress) * (1.0 - i * 0.18))
		draw_arc(origin, radius + i * 16.0, -0.35, 0.35, 32, Color(flash.r, flash.g, flash.b, alpha), 6.0 - i)
	for i in 10:
		var angle := -0.7 + float(i) * 0.14
		var start := origin + Vector2(cos(angle), sin(angle)) * (22.0 + progress * 80.0)
		var end := start + Vector2(cos(angle), sin(angle)) * (18.0 + progress * 42.0)
		draw_line(start, end, Color("#ff7a35", 0.62 * (1.0 - progress)), 2.0)

func _draw_shockwave(origin: Vector2, profile: Dictionary, progress: float) -> void:
	var flash: Color = profile.get("impact_flash", Color("#ffffff", 0.24))
	for i in 3:
		var radius := lerpf(18.0 + i * 20.0, 230.0 + i * 34.0, progress)
		draw_arc(origin, radius, 0.0, TAU, 72, Color(flash.r, flash.g, flash.b, maxf(0.0, flash.a * (1.0 - progress))), 4.0)
	var cracks := int(profile.get("ground_crack_count", 3))
	for i in cracks:
		var x := origin.x - 120.0 + i * 70.0
		var y := origin.y + 72.0 + sin(float(i)) * 8.0
		draw_line(Vector2(x, y), Vector2(x + 54.0, y + 8.0 * sin(progress * TAU + i)), Color("#f7e7b0", 0.72 * (1.0 - progress)), 3.0)

func _draw_coolant_steam(origin: Vector2, profile: Dictionary, progress: float) -> void:
	var flash: Color = profile.get("impact_flash", Color("#8fe6ff", 0.24))
	var columns := int(profile.get("steam_column_count", 4))
	for i in columns:
		var offset := Vector2((float(i) - float(columns - 1) * 0.5) * 18.0, 0.0)
		var base := origin + offset + Vector2(0, 24.0)
		var top := base + Vector2(sin(progress * TAU + i) * 24.0, -lerpf(28.0, 128.0, progress))
		draw_line(base, top, Color(flash.r, flash.g, flash.b, maxf(0.0, flash.a * 2.3 * (1.0 - progress))), 4.0)
		draw_circle(top, 6.0 + progress * 12.0, Color("#dff9ff", 0.24 * (1.0 - progress)))
	draw_arc(origin, lerpf(18.0, 88.0, progress), -0.15, PI + 0.15, 32, Color("#dff9ff", 0.30 * (1.0 - progress)), 3.0)

func _draw_wrench_sparks(origin: Vector2, profile: Dictionary, progress: float) -> void:
	var flash: Color = profile.get("impact_flash", Color("#ffd166", 0.22))
	var sparks := int(profile.get("spark_count", 12))
	for i in sparks:
		var angle := float(i) * TAU / maxf(1.0, float(sparks)) + sin(float(i)) * 0.3
		var distance := lerpf(10.0, 92.0 + float(i % 4) * 9.0, progress)
		var start := origin + Vector2(cos(angle), sin(angle)) * 8.0
		var end := origin + Vector2(cos(angle), sin(angle)) * distance
		draw_line(start, end, Color(flash.r, flash.g, flash.b, maxf(0.0, flash.a * 3.0 * (1.0 - progress))), 2.0)
		if i % 3 == 0:
			draw_rect(Rect2(end, Vector2(4, 4)), Color("#f7e7b0", 0.66 * (1.0 - progress)))
	draw_circle(origin, 10.0 + progress * 18.0, Color("#ffffff", 0.14 * (1.0 - progress)))

func _draw_corruption_split(origin: Vector2, profile: Dictionary, progress: float) -> void:
	var split := float(profile.get("chromatic_split", 2.0)) * (1.0 - progress)
	var alpha := 0.5 * (1.0 - progress)
	draw_rect(Rect2(origin - Vector2(72 + split, 48), Vector2(144, 96)), Color("#ff3355", alpha), false, 3.0)
	draw_rect(Rect2(origin - Vector2(72 - split, 48), Vector2(144, 96)), Color("#55ddff", alpha), false, 3.0)
	for i in 12:
		var offset := Vector2(((i % 4) - 2) * 22, ((i / 4) - 1) * 20)
		draw_string(ThemeDB.fallback_font, origin + offset, "x", HORIZONTAL_ALIGNMENT_LEFT, 24, 16, Color("#b084ff", alpha))

func _draw_arena_ring(origin: Vector2, profile: Dictionary, progress: float) -> void:
	var pulse: Color = profile.get("ring_pulse", Color("#f0b66c", 0.22))
	var radius := lerpf(90.0, 260.0, progress)
	draw_arc(origin, radius, 0.0, TAU, 96, Color(pulse.r, pulse.g, pulse.b, maxf(0.0, pulse.a * (1.0 - progress))), 6.0)
	var debris := int(profile.get("debris_count", 8))
	for i in debris:
		var angle := TAU * float(i) / maxf(1.0, float(debris)) + progress * 0.6
		var point := origin + Vector2(cos(angle), sin(angle) * 0.45) * (radius * 0.72)
		draw_rect(Rect2(point, Vector2(5, 5)), Color("#d6d0bc", 0.68 * (1.0 - progress)))

func _draw_thread_sparks(origin: Vector2, profile: Dictionary, progress: float) -> void:
	var sparks := int(profile.get("impact_spark_count", 12))
	for i in sparks:
		var x := origin.x + sin(float(i) * 2.1) * 90.0 * progress
		var y := origin.y - progress * (40.0 + i * 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(x, y), "01", HORIZONTAL_ALIGNMENT_LEFT, 36, 13, Color("#dfffff", 0.72 * (1.0 - progress)))

func _draw_prism_refraction(origin: Vector2, profile: Dictionary, progress: float) -> void:
	var alpha := 0.72 * (1.0 - progress)
	var spread := lerpf(14.0, 170.0, progress)
	var colors := [Color("#ff6b9a", alpha), Color("#ffd166", alpha), Color("#70ff8f", alpha), Color("#58dbff", alpha), Color("#b084ff", alpha)]
	for i in colors.size():
		var angle := -0.52 + float(i) * 0.26
		var start := origin + Vector2(cos(angle), sin(angle)) * 18.0
		var end := origin + Vector2(cos(angle), sin(angle)) * spread
		draw_line(start, end, colors[i], 3.0)
		draw_circle(end, 4.0 + progress * 5.0, colors[i])
	for i in 4:
		var rect := Rect2(origin + Vector2(-62 + i * 31, -36 + i * 4), Vector2(48, 72)).grow(progress * 16.0)
		draw_rect(rect, Color("#e8fbff", 0.08 * (1.0 - progress)), false, 2.0)

func _draw_ascii_compile(origin: Vector2, profile: Dictionary, progress: float) -> void:
	var alpha := 0.86 * (1.0 - progress)
	var box := Rect2(origin - Vector2(96, 46), Vector2(192, 92)).grow(progress * 44.0)
	draw_rect(box, Color("#07130d", 0.34 * (1.0 - progress)))
	draw_rect(box, Color("#70ff8f", alpha), false, 2.0)
	var glyphs := ["[", "=", "]", "{", "}", "/", "/", "0", "1"]
	for i in 16:
		var column := i % 8
		var row := i / 8
		var point := box.position + Vector2(12 + column * 22, 28 + row * 28 - progress * 18.0)
		draw_string(ThemeDB.fallback_font, point, glyphs[i % glyphs.size()], HORIZONTAL_ALIGNMENT_LEFT, 24, 18, Color("#b7fffb", alpha))
	draw_line(origin + Vector2(-130 + progress * 70.0, 0), origin + Vector2(130 - progress * 70.0, 0), Color("#ffd166", alpha), 3.0)

func _draw_slash_arc(origin: Vector2, profile: Dictionary, progress: float) -> void:
	var flash: Color = profile.get("impact_flash", Color("#f8de9a", 0.2))
	var radius := lerpf(38.0, 118.0, progress)
	draw_arc(origin, radius, -0.95, 0.45, 28, Color(flash.r, flash.g, flash.b, maxf(0.0, flash.a * 2.4 * (1.0 - progress))), 5.0)

func _draw_screen_effect(effect: Dictionary) -> void:
	var effect_id := str(effect.get("id", "impact_freeze"))
	var duration := maxf(0.01, float(effect.get("duration", 0.2)))
	var progress := clampf(float(effect.get("age", 0.0)) / duration, 0.0, 1.0)
	var intensity := float(effect.get("intensity", 0.5)) * (1.0 - progress)
	match effect_id:
		"chromatic_glitch":
			_draw_chromatic_glitch(intensity)
		"scanline_burst":
			_draw_scanline_burst(intensity, progress)
		"heat_haze":
			_draw_heat_haze(intensity, progress)
		"warning_pulse":
			_draw_warning_pulse(intensity, progress)
		_:
			_draw_impact_freeze(intensity)

func _draw_chromatic_glitch(intensity: float) -> void:
	var offset := 10.0 * intensity
	draw_rect(Rect2(Vector2(offset, 0), size), Color("#ff2d55", 0.10 * intensity), false, 5.0)
	draw_rect(Rect2(Vector2(-offset, 0), size), Color("#00d9ff", 0.10 * intensity), false, 5.0)
	for i in 9:
		var y := fmod(float(i) * 73.0 + Time.get_ticks_msec() * 0.05, maxf(1.0, size.y))
		draw_rect(Rect2(0, y, size.x, 4.0 + intensity * 8.0), Color("#ffffff", 0.07 * intensity))

func _draw_scanline_burst(intensity: float, progress: float) -> void:
	for y in range(0, int(size.y), 5):
		draw_rect(Rect2(0, y, size.x, 1), Color("#000000", 0.35 * intensity))
	var sweep := fmod(progress * size.y * 1.8, maxf(1.0, size.y))
	draw_rect(Rect2(0, sweep, size.x, 24.0 + intensity * 34.0), Color("#7dffcb", 0.16 * intensity))

func _draw_heat_haze(intensity: float, progress: float) -> void:
	for i in 8:
		var y := size.y * 0.35 + i * 28.0
		var wave := sin(progress * TAU * 2.0 + i) * 18.0 * intensity
		draw_line(Vector2(0, y), Vector2(size.x, y + wave), Color("#ffb347", 0.10 * intensity), 3.0)

func _draw_warning_pulse(intensity: float, progress: float) -> void:
	var alpha := (0.18 + sin(progress * TAU * 4.0) * 0.08) * intensity
	draw_rect(Rect2(Vector2.ZERO, size), Color("#ff1f4b", alpha), false, 10.0)
	draw_rect(Rect2(Vector2(12, 12), size - Vector2(24, 24)), Color("#ffcc66", alpha * 0.5), false, 2.0)

func _draw_impact_freeze(intensity: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#ffffff", 0.10 * intensity))
