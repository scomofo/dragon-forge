extends Control
class_name ThreadfallOverlay

const BattleVfxData := preload("res://scripts/sim/battle_vfx_data.gd")

const GLYPHS := ["0", "1", "/", "\\", "|", "x"]
const THREAD_COUNT := 42
const VFX_FRAME_COUNT := 4

var intensity := 0.0
var time := 0.0
var overlay_profile: Dictionary = {}
var strip_texture: Texture2D
var strip_texture_path := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_intensity(next_intensity: float) -> void:
	intensity = clampf(next_intensity, 0.0, 1.0)
	overlay_profile = BattleVfxData.threadfall_overlay_profile(intensity)
	_ensure_strip_texture(str(overlay_profile.get("strip_path", "")))
	visible = intensity > 0.01
	queue_redraw()

func get_active_strip_path() -> String:
	return strip_texture_path

func _process(delta: float) -> void:
	if intensity <= 0.01:
		return
	time += delta
	queue_redraw()

func _draw() -> void:
	if intensity <= 0.01:
		return
	var font := get_theme_default_font()
	var alpha := float(overlay_profile.get("streak_alpha", 0.18 + intensity * 0.55))
	var glyph_count := int(overlay_profile.get("glyph_count", THREAD_COUNT))
	var streak_speed := float(overlay_profile.get("streak_speed", 90.0 + intensity * 210.0))
	var band_alpha := float(overlay_profile.get("derender_band_alpha", 0.0))
	for band in range(0, int(size.y), 46):
		draw_rect(Rect2(0, band + int(time * 42.0) % 46, size.x, 4 + intensity * 8.0), Color("#5dffb2", band_alpha))
	for i in glyph_count:
		var seed := float(i)
		var x := fmod(seed * 83.0 + sin(time * 0.8 + seed) * 32.0, max(1.0, size.x))
		var speed := streak_speed + fmod(seed * 17.0, 70.0)
		var y := fmod(time * speed + seed * 47.0, max(1.0, size.y + 120.0)) - 80.0
		var length := 24.0 + intensity * 52.0 + fmod(seed * 11.0, 34.0)
		var start := Vector2(x, y)
		var end := start + Vector2(10.0 * sin(seed), length)
		var color := Color("#f4fbff", alpha)
		draw_line(start, end, color, 1.0 + intensity * 2.0)
		if i % 3 == 0:
			var glyph: String = str(GLYPHS[i % GLYPHS.size()])
			draw_string(font, end + Vector2(3, 0), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#dfffff", alpha))
	_draw_thread_impact_strips()

func _draw_thread_impact_strips() -> void:
	if strip_texture == null:
		return
	var opacity := float(overlay_profile.get("strip_opacity", 0.0))
	if opacity <= 0.01:
		return
	var frame_width := float(strip_texture.get_width()) / VFX_FRAME_COUNT
	var frame := int(floor(time * 10.0)) % VFX_FRAME_COUNT
	var source := Rect2(frame_width * frame, 0.0, frame_width, strip_texture.get_height())
	for i in 3:
		var seed := float(i + 1)
		var center := Vector2(
			fmod(seed * 311.0 + time * 57.0, maxf(1.0, size.x + 180.0)) - 90.0,
			fmod(seed * 173.0 + sin(time + seed) * 44.0, maxf(1.0, size.y))
		)
		var scale := 0.72 + intensity * 0.55 + float(i) * 0.08
		var target := Rect2(center - Vector2(128.0, 128.0) * scale, Vector2(256.0, 256.0) * scale)
		draw_texture_rect_region(strip_texture, target, source, Color(1.0, 1.0, 1.0, opacity * (0.55 + i * 0.12)))

func _ensure_strip_texture(path: String) -> void:
	if path == "" or path == strip_texture_path:
		return
	strip_texture_path = path
	var image := Image.new()
	var error := image.load(path)
	if error == OK:
		strip_texture = ImageTexture.create_from_image(image)
	else:
		strip_texture = null
