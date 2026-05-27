class_name DragonProgressionService
extends RefCounted

const DragonStats = preload("res://src/dragon/dragon_stats.gd")

const MIN_LEVEL: int = 1
const MAX_LEVEL: int = 60
const SHINY_MULTIPLIER: float = 1.2
const STANDARD_MULTIPLIER: float = 1.0

const STAGE_I: int = 1
const STAGE_II: int = 2
const STAGE_III: int = 3
const STAGE_IV: int = 4

const BASE_STATS_BY_ELEMENT: Dictionary = {
	&"Fire": [110, 28, 16, 22],
	&"Ice": [100, 24, 17, 14],
	&"Storm": [90, 30, 13, 32],
	&"Stone": [120, 22, 24, 8],
	&"Venom": [95, 26, 19, 12],
	&"Shadow": [85, 32, 11, 28],
	&"Void": [80, 40, 20, 36],
}


## Returns a derived stat snapshot for a durable dragon record.
func calculate_stats(record: DragonRecord) -> DragonStats:
	if record == null:
		return _make_zero_stats(&"", MIN_LEVEL, false, false)

	var safe_level: int = _safe_level(record.level)
	var safe_shiny: bool = record.shiny and record.element != &"Void"
	var shiny_multiplier: float = SHINY_MULTIPLIER if safe_shiny else STANDARD_MULTIPLIER
	var base_stats: Array = _base_stats_for_record(record)
	var stats: DragonStats = _calculate_stats_from_base(record.element, safe_level, shiny_multiplier, base_stats)
	stats.dragon_id = record.dragon_id
	stats.shiny = safe_shiny
	stats.is_elder = record.is_elder
	return stats


## Evaluates the canonical stat formula from explicit inputs for validation/repair paths.
func calculate_stats_for_values(element: StringName, level: int, shiny_multiplier: float) -> DragonStats:
	var safe_multiplier: float = shiny_multiplier
	if not is_equal_approx(shiny_multiplier, STANDARD_MULTIPLIER) and not is_equal_approx(shiny_multiplier, SHINY_MULTIPLIER):
		push_error("Stat formula: invalid shiny multiplier %s, using 1.0" % shiny_multiplier)
		safe_multiplier = STANDARD_MULTIPLIER
	if element == &"Void":
		safe_multiplier = STANDARD_MULTIPLIER
	return _calculate_stats_from_base(element, _safe_level(level), safe_multiplier, _canonical_base_stats(element))


## Derives the non-persisted stage number from a dragon level.
func stage_for_level(level: int) -> int:
	var safe_level: int = _safe_level(level)
	if safe_level < 10:
		return STAGE_I
	if safe_level < 25:
		return STAGE_II
	if safe_level < 50:
		return STAGE_III
	return STAGE_IV


## Returns the standard non-Elder stage multiplier owned by Dragon Progression.
func stage_multiplier_for_level(level: int) -> float:
	match stage_for_level(level):
		STAGE_I:
			return 0.5
		STAGE_II:
			return 0.75
		STAGE_III:
			return 1.0
		_:
			return 1.4


func _calculate_stats_from_base(element: StringName, level: int, shiny_multiplier: float, base_stats: Array) -> DragonStats:
	if base_stats.is_empty():
		push_error("Stat formula: unknown element '%s' - no base stat found" % element)
		return _make_zero_stats(element, level, false, false)

	var stats: DragonStats = DragonStats.new()
	stats.element = element
	stats.level = level
	stats.stage = stage_for_level(level)
	stats.stage_multiplier = stage_multiplier_for_level(level)
	stats.shiny = is_equal_approx(shiny_multiplier, SHINY_MULTIPLIER) and element != &"Void"
	stats.hp = _scale_stat(int(base_stats[0]), level, shiny_multiplier)
	stats.atk = _scale_stat(int(base_stats[1]), level, shiny_multiplier)
	stats.def = _scale_stat(int(base_stats[2]), level, shiny_multiplier)
	stats.spd = _scale_stat(int(base_stats[3]), level, shiny_multiplier)
	return stats


func _scale_stat(base_stat: int, level: int, shiny_multiplier: float) -> int:
	return int(floor(float(base_stat + ((level - 1) * 3)) * shiny_multiplier))


func _safe_level(level: int) -> int:
	if level < MIN_LEVEL:
		push_error("Stat formula: level %d below %d, using level 1" % [level, MIN_LEVEL])
		return MIN_LEVEL
	if level > MAX_LEVEL:
		push_error("Stat formula: level %d above %d, using level 60" % [level, MAX_LEVEL])
		return MAX_LEVEL
	return level


func _base_stats_for_record(record: DragonRecord) -> Array:
	if record.base_hp > 0 and record.base_atk > 0 and record.base_def > 0 and record.base_spd > 0:
		return [record.base_hp, record.base_atk, record.base_def, record.base_spd]
	return _canonical_base_stats(record.element)


func _canonical_base_stats(element: StringName) -> Array:
	if not BASE_STATS_BY_ELEMENT.has(element):
		return []
	return BASE_STATS_BY_ELEMENT[element].duplicate()


func _make_zero_stats(element: StringName, level: int, shiny: bool, is_elder: bool) -> DragonStats:
	var stats: DragonStats = DragonStats.new()
	stats.element = element
	stats.level = level
	stats.stage = stage_for_level(level)
	stats.stage_multiplier = stage_multiplier_for_level(level)
	stats.shiny = shiny
	stats.is_elder = is_elder
	return stats
