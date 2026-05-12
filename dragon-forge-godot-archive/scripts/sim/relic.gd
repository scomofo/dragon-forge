extends Resource
class_name Relic

@export var item_name: String = ""
@export var physical_model: PackedScene
@export var bypass_code: String = ""
@export var weight_kg: float = 0.0
@export var is_immutable := true
@export_multiline var inspection_note: String = ""

func can_bypass(required_code: String) -> bool:
	return bypass_code != "" and bypass_code == required_code

func traction_bonus() -> float:
	return clampf(weight_kg * 0.01, 0.0, 0.2)

func flight_speed_penalty() -> float:
	return clampf(weight_kg * 0.015, 0.0, 0.35)
