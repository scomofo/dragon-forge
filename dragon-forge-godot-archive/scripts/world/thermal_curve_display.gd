extends Control
class_name ThermalCurveDisplay

var samples: Array[float] = []
var target := 54.5

func set_curve(next_samples: Array[float], next_target: float) -> void:
	samples = next_samples.duplicate()
	target = next_target
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(320, 96)

func _draw() -> void:
	var graph := Rect2(Vector2(6, 8), size - Vector2(12, 18))
	draw_rect(graph, Color("#1b1d1c"))
	_draw_band(graph, target - 1.25, target + 1.25, Color("#477d5f", 0.35))
	_draw_temp_line(graph, target, Color("#c9d77a"), 2.0)

	var points := PackedVector2Array()
	var values := samples.duplicate()
	if values.is_empty():
		values = [60.5]
	for i in values.size():
		var x := lerpf(graph.position.x, graph.end.x, float(i) / maxf(1.0, values.size() - 1.0))
		var y := _temp_to_y(graph, values[i])
		points.append(Vector2(x, y))
	if points.size() > 1:
		draw_polyline(points, Color("#e88d55"), 3.0)
	for point in points:
		draw_circle(point, 3.5, Color("#f4d29a"))

func _draw_band(graph: Rect2, low: float, high: float, color: Color) -> void:
	var y_high := _temp_to_y(graph, high)
	var y_low := _temp_to_y(graph, low)
	draw_rect(Rect2(graph.position.x, y_high, graph.size.x, y_low - y_high), color)

func _draw_temp_line(graph: Rect2, temp: float, color: Color, width: float) -> void:
	var y := _temp_to_y(graph, temp)
	draw_line(Vector2(graph.position.x, y), Vector2(graph.end.x, y), color, width)

func _temp_to_y(graph: Rect2, temp: float) -> float:
	var normalized := clampf((temp - 50.0) / 15.0, 0.0, 1.0)
	return lerpf(graph.end.y, graph.position.y, normalized)
