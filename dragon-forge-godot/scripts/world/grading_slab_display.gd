extends Control
class_name GradingSlabDisplay

var grade := {}

func set_grade(next_grade: Dictionary) -> void:
	grade = next_grade.duplicate()
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(320, 124)

func _draw() -> void:
	var rect := Rect2(Vector2(6, 6), size - Vector2(12, 12))
	draw_rect(rect, Color("#d8d2c2"))
	draw_rect(rect, Color("#2c2b28"), false, 2.0)
	var header := Rect2(rect.position, Vector2(rect.size.x, 24))
	draw_rect(header, Color("#2c2b28"))
	draw_string(get_theme_default_font(), header.position + Vector2(8, 17), "AUTHENTIC CONDITION SLAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e9dfc8"))

	if grade.is_empty():
		_draw_text_rows(rect, ["Surface --", "Corners --", "Edges --", "Centering --", "Registry pending"])
		return

	_draw_text_rows(rect, [
		"Surface %.1f" % grade["surface"],
		"Corners %.1f" % grade["corners"],
		"Edges %.1f" % grade["edges"],
		"Centering %.1f" % grade["centering"],
		"Registry %d" % grade["registry_value"],
	])
	var badge_color := Color("#c49a3a") if grade["is_gem_mint"] else Color("#77736a")
	draw_circle(rect.end - Vector2(34, 34), 24, badge_color)
	draw_string(get_theme_default_font(), rect.end - Vector2(49, 28), "%.1f" % grade["average"], HORIZONTAL_ALIGNMENT_CENTER, 32, 18, Color("#1d1a14"))

func _draw_text_rows(rect: Rect2, rows: Array[String]) -> void:
	for i in rows.size():
		draw_string(get_theme_default_font(), rect.position + Vector2(12, 48 + i * 14), rows[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#25231f"))
