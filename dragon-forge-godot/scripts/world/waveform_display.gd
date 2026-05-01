extends Control
class_name WaveformDisplay

var target_frequency := 440.0
var roar_frequency := 432.0

func set_frequencies(target: float, roar: float) -> void:
	target_frequency = target
	roar_frequency = roar
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(320, 94)

func _draw() -> void:
	var rect := Rect2(Vector2(6, 8), size - Vector2(12, 18))
	draw_rect(rect, Color("#11151f"))
	_draw_wave(rect, target_frequency, Color("#5cd7ff"), 2.0)
	_draw_wave(rect, roar_frequency, Color("#f0d06b"), 2.0)
	var delta := absf(target_frequency - roar_frequency)
	var glow := clampf(1.0 - delta / 20.0, 0.0, 1.0)
	draw_rect(rect, Color("#f0d06b", glow * 0.12), false, 3.0)

func _draw_wave(rect: Rect2, frequency: float, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	var cycles := frequency / 110.0
	for i in 96:
		var t := float(i) / 95.0
		var x := lerpf(rect.position.x, rect.end.x, t)
		var y := rect.position.y + rect.size.y * 0.5 + sin(t * TAU * cycles) * rect.size.y * 0.28
		points.append(Vector2(x, y))
	draw_polyline(points, color, width)
