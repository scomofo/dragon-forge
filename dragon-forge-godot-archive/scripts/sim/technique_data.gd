extends RefCounted
class_name TechniqueData

const TECHNIQUES := {
	"blazingFang": {
		"id": "blazingFang",
		"label": "Blazing Fang",
		"description": "Lunge through the target, then detonate fire in the wound.",
		"element": "fire",
		"dragon_types": ["fire", "shadow"],
		"power": 88,
		"accuracy": 95,
		"focus_gain": 1,
		"stagger": 22,
		"role": "strike",
		"scrap_cost": 120,
		"motion": "lunge",
		"vfx": "magma",
	},
	"cinderComet": {
		"id": "cinderComet",
		"label": "Cinder Comet",
		"description": "A high-risk aerial blast that rewards Focus timing.",
		"element": "fire",
		"dragon_types": ["fire"],
		"power": 118,
		"accuracy": 82,
		"focus_gain": 0,
		"stagger": 32,
		"role": "purge",
		"scrap_cost": 260,
		"motion": "blast",
		"vfx": "magma",
	},
	"quakeWing": {
		"id": "quakeWing",
		"label": "Quake Wing",
		"description": "Hammer the field with a ground-breaking wingbeat.",
		"element": "stone",
		"dragon_types": ["stone", "fire"],
		"power": 96,
		"accuracy": 88,
		"focus_gain": 1,
		"stagger": 48,
		"role": "break",
		"scrap_cost": 180,
		"motion": "shockwave",
		"vfx": "shockwave",
	},
	"nightNeedle": {
		"id": "nightNeedle",
		"label": "Night Needle",
		"description": "A precise shadow spike with high Focus acceleration.",
		"element": "shadow",
		"dragon_types": ["shadow", "venom"],
		"power": 66,
		"accuracy": 100,
		"focus_gain": 2,
		"stagger": 14,
		"role": "shadow",
		"scrap_cost": 140,
		"motion": "blink",
		"vfx": "shadow",
	},
}

static func get_technique(id: String) -> Dictionary:
	return TECHNIQUES.get(id, {}).duplicate(true)

static func get_available_for_dragon(dragon_type: String) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for technique in TECHNIQUES.values():
		if technique["dragon_types"].has(dragon_type):
			available.append(technique.duplicate(true))
	return available

static func get_known_commands(known_techniques: Array) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	for id in known_techniques:
		var technique := get_technique(id)
		if technique.is_empty():
			continue
		commands.append({
			"id": technique["id"],
			"label": technique["label"],
			"description": technique["description"],
			"element": technique["element"],
			"power": technique["power"],
			"accuracy": technique["accuracy"],
			"focus_gain": technique["focus_gain"],
			"stagger": technique["stagger"],
			"role": technique["role"],
			"motion": technique["motion"],
			"vfx": technique["vfx"],
		})
	return commands
