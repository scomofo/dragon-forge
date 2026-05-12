extends RefCounted
class_name CombatRules

const STAGE_MULTIPLIERS := {
	1: 0.5,
	2: 0.75,
	3: 1.0,
	4: 1.4,
}

const TYPE_CHART := {
	"fire": { "ice": 2.0, "stone": 0.5, "venom": 2.0, "fire": 0.5 },
	"ice": { "storm": 2.0, "shadow": 2.0, "fire": 0.5, "ice": 0.5 },
	"storm": { "stone": 2.0, "shadow": 2.0, "ice": 0.5, "storm": 0.5 },
	"stone": { "fire": 2.0, "venom": 2.0, "storm": 0.5, "stone": 0.5 },
	"venom": { "shadow": 2.0, "fire": 0.5, "stone": 0.5, "venom": 0.5 },
	"shadow": { "ice": 0.5, "storm": 0.5, "venom": 0.5, "shadow": 0.5 },
	"void": {},
}

static func resolve_attack(attacker: Dictionary, defender: Dictionary, move: Dictionary, roll: float = 0.0) -> Dictionary:
	if roll > move["accuracy"] / 100.0:
		return {
			"hit": false,
			"damage": 0,
			"remaining_hp": defender["hp"],
			"effectiveness": 1.0,
		}

	var effectiveness := get_effectiveness(move["element"], defender["element"])
	var raw_damage: float = (
		attacker["atk"] * STAGE_MULTIPLIERS[attacker["stage"]]
		+ move["power"]
		- defender["def"] * 0.5
	) * effectiveness
	var damage := maxi(1, floori(raw_damage))

	return {
		"hit": true,
		"damage": damage,
		"remaining_hp": maxi(0, defender["hp"] - damage),
		"effectiveness": effectiveness,
	}

static func get_effectiveness(attacker: String, defender: String) -> float:
	var row: Dictionary = TYPE_CHART.get(attacker, {})
	return row.get(defender, 1.0)
