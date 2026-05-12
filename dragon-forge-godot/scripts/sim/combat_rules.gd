extends RefCounted
class_name CombatRules

const BattleEngine = preload("res://scripts/sim/battle_engine.gd")

static func resolve_attack(attacker: Dictionary, defender: Dictionary, move: Dictionary, roll: float) -> Dictionary:
	var accuracy: float = float(move.get("accuracy", 100))
	if roll * 100.0 > accuracy:
		return {
			"hit": false,
			"damage": 0,
			"remaining_hp": int(defender.get("hp", 0)),
			"effectiveness": 1.0,
		}

	var safe_move: Dictionary = move.duplicate()
	safe_move["accuracy"] = 100
	var dmg_result: Dictionary = BattleEngine.calculate_damage(attacker, defender, safe_move)
	var damage: int = int(dmg_result.get("damage", 0))
	var remaining_hp: int = maxi(0, int(defender.get("hp", 0)) - damage)
	return {
		"hit": true,
		"damage": damage,
		"remaining_hp": remaining_hp,
		"effectiveness": float(dmg_result.get("effectiveness", 1.0)),
	}
