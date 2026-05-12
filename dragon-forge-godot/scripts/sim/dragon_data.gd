extends RefCounted
class_name DragonData

const DRAGONS: Dictionary = {
	"fire": {
		"id": "fire",
		"name": "Magma Dragon",
		"element": "fire",
		"base_stats": { "hp": 110, "atk": 28, "def": 20, "spd": 18 },
		"move_keys": ["magma_breath", "flame_wall"],
	},
	"ice": {
		"id": "ice",
		"name": "Ice Dragon",
		"element": "ice",
		"base_stats": { "hp": 100, "atk": 24, "def": 26, "spd": 20 },
		"move_keys": ["frost_bite", "blizzard"],
	},
	"storm": {
		"id": "storm",
		"name": "Storm Dragon",
		"element": "storm",
		"base_stats": { "hp": 90, "atk": 30, "def": 16, "spd": 28 },
		"move_keys": ["lightning_strike", "thunder_clap"],
	},
	"stone": {
		"id": "stone",
		"name": "Stone Dragon",
		"element": "stone",
		"base_stats": { "hp": 120, "atk": 22, "def": 30, "spd": 12 },
		"move_keys": ["rock_slide", "earthquake"],
	},
	"venom": {
		"id": "venom",
		"name": "Venom Dragon",
		"element": "venom",
		"base_stats": { "hp": 95, "atk": 26, "def": 18, "spd": 24 },
		"move_keys": ["acid_spit", "toxic_cloud"],
	},
	"shadow": {
		"id": "shadow",
		"name": "Shadow Dragon",
		"element": "shadow",
		"base_stats": { "hp": 85, "atk": 32, "def": 14, "spd": 26 },
		"move_keys": ["shadow_strike", "void_pulse"],
	},
	"void": {
		"id": "void",
		"name": "Void Dragon",
		"element": "void",
		"base_stats": { "hp": 75, "atk": 34, "def": 12, "spd": 30 },
		"move_keys": ["void_rift", "null_reflect"],
	},
}

static func calculate_stats(dragon_def: Dictionary, level: int) -> Dictionary:
	var base: Dictionary = dragon_def.get("base_stats", {})
	var bonus: int = (level - 1) * 3
	return {
		"hp":  base.get("hp",  0) + bonus,
		"atk": base.get("atk", 0) + bonus,
		"def": base.get("def", 0) + bonus,
		"spd": base.get("spd", 0) + bonus,
	}

static func get_stage_for_level(level: int) -> int:
	if level >= 50:
		return 4
	if level >= 25:
		return 3
	if level >= 10:
		return 2
	return 1
