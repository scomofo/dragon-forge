extends Node2D

@onready var num_label: Label = $NumLabel

func spawn(value: int, is_effective: bool = false, is_resisted: bool = false) -> void:
	num_label.text = str(value)
	if is_effective:
		num_label.add_theme_color_override("font_color", Color("#ffcc00"))
		num_label.add_theme_font_size_override("font_size", 28)
	elif is_resisted:
		num_label.add_theme_color_override("font_color", Color("#8fb0ff"))
		num_label.add_theme_font_size_override("font_size", 18)
	else:
		num_label.add_theme_color_override("font_color", Color("#ffffff"))
		num_label.add_theme_font_size_override("font_size", 22)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, -64), 0.8)
	tween.tween_property(num_label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(queue_free)
