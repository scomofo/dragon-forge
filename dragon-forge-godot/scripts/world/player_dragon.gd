extends CharacterBody2D
class_name PlayerDragon

const WALK_SPEED: float = 80.0
const FLY_SPEED: float = 150.0

var flying: bool = false

func _ready() -> void:
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	var dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = dir * (FLY_SPEED if flying else WALK_SPEED)
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		flying = not flying
