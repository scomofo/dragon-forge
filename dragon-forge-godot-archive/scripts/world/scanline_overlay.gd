extends Control
class_name ScanlineOverlay

var time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	for y in range(0, int(size.y), 4):
		draw_rect(Rect2(0, y, size.x, 1), Color("#000000", 0.24))
	var sweep_y := fmod(time * 90.0, maxf(1.0, size.y))
	draw_rect(Rect2(0, sweep_y, size.x, 18), Color("#6aff6a", 0.06))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#00aa55", 0.04))
