extends RefCounted
class_name TechniqueData

const GameData = preload("res://scripts/sim/game_data.gd")

static func get_technique(technique_id: String) -> Dictionary:
	var move: Dictionary = GameData.MOVES.get(technique_id, {})
	if move.is_empty():
		return {}
	var result: Dictionary = move.duplicate()
	result["id"] = technique_id
	result["label"] = str(move.get("name", technique_id))
	return result
