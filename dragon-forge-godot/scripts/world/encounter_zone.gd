extends Area2D
class_name EncounterZone

signal player_entered(npc_id: String)

var npc_id: String = ""
var _defeated: bool = false
var _visual: ColorRect = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false

	var col_shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(30, 30)
	col_shape.shape = rect_shape
	add_child(col_shape)

	_visual = ColorRect.new()
	_visual.color = Color(1.0, 0.42, 0.21, 0.5)
	_visual.size = Vector2(30, 30)
	_visual.position = Vector2(-15, -15)
	add_child(_visual)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _defeated or not body.is_in_group("player"):
		return
	player_entered.emit(npc_id)

func set_defeated(defeated: bool) -> void:
	_defeated = defeated
	if _visual != null:
		_visual.color = Color(0.5, 0.5, 0.5, 0.25) if defeated else Color(1.0, 0.42, 0.21, 0.5)
