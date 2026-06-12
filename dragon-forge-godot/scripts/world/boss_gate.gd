extends StaticBody2D
class_name BossGate

var _locked: bool = true
var _visual: ColorRect = null
var _col_shape: CollisionShape2D = null

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0

	_col_shape = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(12, 64)
	_col_shape.shape = rect_shape
	add_child(_col_shape)

	_visual = ColorRect.new()
	_visual.size = Vector2(12, 64)
	_visual.position = Vector2(-6, -32)
	add_child(_visual)

	set_locked(true)

func set_locked(locked: bool) -> void:
	_locked = locked
	if _col_shape != null:
		_col_shape.disabled = not _locked
	if _visual != null:
		_visual.color = Color(0.8, 0.1, 0.1) if _locked else Color(0.1, 0.8, 0.1)
