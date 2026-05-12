extends RefCounted
class_name DragonData

const DRAGONS := {
	"fire": {
		"id": "fire",
		"name": "Magma Dragon",
		"element": "fire",
		"attack_style": "burst damage and burn pressure",
		"base_stats": { "hp": 110, "atk": 28, "def": 20, "spd": 18 },
	},
	"ice": {
		"id": "ice",
		"name": "Ice Dragon",
		"element": "ice",
		"attack_style": "control, mitigation, and freeze setup",
		"base_stats": { "hp": 100, "atk": 24, "def": 26, "spd": 20 },
	},
	"storm": {
		"id": "storm",
		"name": "Storm Dragon",
		"element": "storm",
		"attack_style": "speed chains and Focus acceleration",
		"base_stats": { "hp": 90, "atk": 30, "def": 16, "spd": 28 },
	},
	"stone": {
		"id": "stone",
		"name": "Stone Dragon",
		"element": "stone",
		"attack_style": "stagger, armor, and heavy counters",
		"base_stats": { "hp": 120, "atk": 22, "def": 30, "spd": 12 },
	},
	"venom": {
		"id": "venom",
		"name": "Venom Dragon",
		"element": "venom",
		"attack_style": "attrition, poison, and corrosive debuffs",
		"base_stats": { "hp": 95, "atk": 26, "def": 18, "spd": 24 },
	},
	"shadow": {
		"id": "shadow",
		"name": "Shadow Dragon",
		"element": "shadow",
		"attack_style": "evasion, blind strikes, and unstable burst",
		"base_stats": { "hp": 85, "atk": 32, "def": 14, "spd": 26 },
	},
}

static func get_stage_for_level(level: int) -> int:
	if level >= 50:
		return 4
	if level >= 25:
		return 3
	if level >= 10:
		return 2
	return 1

static func calculate_stats(definition: Dictionary, level: int, shiny: bool = false) -> Dictionary:
	var level_bonus := maxi(0, level - 1) * 3
	var shiny_multiplier := 1.2 if shiny else 1.0
	var base: Dictionary = definition["base_stats"]
	return {
		"hp": floori((base["hp"] + level_bonus) * shiny_multiplier),
		"atk": floori((base["atk"] + level_bonus) * shiny_multiplier),
		"def": floori((base["def"] + level_bonus) * shiny_multiplier),
		"spd": floori((base["spd"] + level_bonus) * shiny_multiplier),
	}
