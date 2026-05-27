class_name BattleFormulaService
extends RefCounted

const BattleDamageResultResource = preload("res://src/battle/formulas/battle_damage_result.gd")

const DAMAGE_STAGE_FACTOR: float = 1.5
const DEFENSE_FACTOR: float = 0.5
const DEFEND_MULTIPLIER: float = 0.5
const CRIT_CHANCE: float = 0.10
const CRIT_MULTIPLIER: float = 1.5
const ROLL_MIN: float = 0.85
const ROLL_MAX: float = 1.0
const BLIND_ACCURACY_PENALTY: int = 30
const SHINY_MULTIPLIER: float = 1.2
const STANDARD_MULTIPLIER: float = 1.0
const ELDER_STAGE_MULT: float = 1.75

const TYPE_EFFECTIVENESS: Dictionary = {
	&"Fire": {&"Fire": 0.5, &"Ice": 2.0, &"Storm": 1.0, &"Stone": 0.5, &"Venom": 2.0, &"Shadow": 1.0, &"Void": 1.0},
	&"Ice": {&"Fire": 0.5, &"Ice": 0.5, &"Storm": 2.0, &"Stone": 1.0, &"Venom": 1.0, &"Shadow": 2.0, &"Void": 1.0},
	&"Storm": {&"Fire": 1.0, &"Ice": 0.5, &"Storm": 0.5, &"Stone": 2.0, &"Venom": 1.0, &"Shadow": 2.0, &"Void": 1.0},
	&"Stone": {&"Fire": 2.0, &"Ice": 1.0, &"Storm": 0.5, &"Stone": 0.5, &"Venom": 2.0, &"Shadow": 1.0, &"Void": 1.0},
	&"Venom": {&"Fire": 0.5, &"Ice": 1.0, &"Storm": 1.0, &"Stone": 0.5, &"Venom": 0.5, &"Shadow": 2.0, &"Void": 1.0},
	&"Shadow": {&"Fire": 1.0, &"Ice": 0.5, &"Storm": 0.5, &"Stone": 1.0, &"Venom": 0.5, &"Shadow": 2.0, &"Void": 1.0},
	&"Void": {&"Fire": 1.0, &"Ice": 1.0, &"Storm": 1.0, &"Stone": 1.0, &"Venom": 1.0, &"Shadow": 1.0, &"Void": 1.0},
}


## Calculates damage from deterministic battle formula inputs.
func calculate_damage(
	atk: int,
	defense: int,
	stage_multiplier: float,
	type_multiplier: float,
	defending: bool,
	roll: float,
	crit_roll: float,
	move_accuracy: int = 100,
	accuracy_roll: int = 0,
	blinded: bool = false
) -> BattleDamageResult:
	var result: BattleDamageResult = BattleDamageResultResource.new()
	if not is_accuracy_hit(move_accuracy, accuracy_roll, blinded):
		result.hit = false
		result.crit = false
		result.reason = &"miss"
		return result

	var base_damage: float = (float(atk) * stage_multiplier * DAMAGE_STAGE_FACTOR) - (float(defense) * DEFENSE_FACTOR)
	var typed_damage: float = base_damage * type_multiplier
	if defending:
		typed_damage *= DEFEND_MULTIPLIER

	var safe_roll: float = clampf(roll, ROLL_MIN, ROLL_MAX)
	var pre_crit_damage: int = max(1, int(floor(typed_damage * safe_roll)))
	result.hit = true
	result.crit = is_crit(crit_roll)
	result.reason = &"ok"
	result.damage = int(floor(float(pre_crit_damage) * CRIT_MULTIPLIER)) if result.crit else pre_crit_damage
	return result


func is_crit(crit_roll: float) -> bool:
	return crit_roll < CRIT_CHANCE


func effective_accuracy(move_accuracy: int, blinded: bool) -> int:
	var penalty: int = BLIND_ACCURACY_PENALTY if blinded else 0
	return max(0, move_accuracy - penalty)


func is_accuracy_hit(move_accuracy: int, accuracy_roll: int, blinded: bool) -> bool:
	return accuracy_roll <= effective_accuracy(move_accuracy, blinded)


func type_effectiveness(attacker_element: StringName, defender_element: StringName) -> float:
	if not TYPE_EFFECTIVENESS.has(attacker_element):
		return STANDARD_MULTIPLIER
	var defender_values: Dictionary = TYPE_EFFECTIVENESS[attacker_element]
	return float(defender_values.get(defender_element, STANDARD_MULTIPLIER))


func stage_multiplier_for_level(level: int, is_elder: bool) -> float:
	if level < 10:
		return 0.5
	if level < 25:
		return 0.75
	if level < 50:
		return 1.0
	return ELDER_STAGE_MULT if is_elder else 1.4


func stat_at_level(base_stat: int, level: int, shiny: bool) -> int:
	var multiplier: float = SHINY_MULTIPLIER if shiny else STANDARD_MULTIPLIER
	return int(floor(float(base_stat + ((level - 1) * 3)) * multiplier))


func raw_xp_awarded(base_xp: int, enemy_level: int, player_level: int) -> int:
	if player_level <= 0:
		return 1
	return max(1, int(floor(float(base_xp) * float(enemy_level) / float(player_level))))
