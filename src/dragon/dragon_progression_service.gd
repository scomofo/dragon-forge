class_name DragonProgressionService
extends RefCounted

signal stats_updated(event: DragonProgressionEvent)
signal stage_advanced(event: DragonProgressionEvent)
signal stage_iv_reached(event: DragonProgressionEvent)

const DragonStats = preload("res://src/dragon/dragon_stats.gd")
const XPApplyResultResource = preload("res://src/dragon/xp_apply_result.gd")
const DragonProgressionEventResource = preload("res://src/dragon/dragon_progression_event.gd")

const MIN_LEVEL: int = 1
const MAX_LEVEL: int = 60
const MAX_LEVEL_XP_SENTINEL: int = 2147483647
const XP_MAX_AWARD: int = 10000
const RESONANCE_XP_MULTIPLIER: float = 1.5
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


## Returns the current level's XP threshold, or a sentinel at MAX_LEVEL.
func xp_threshold_for(level: int) -> int:
	var safe_level: int = _safe_level(level)
	if safe_level >= MAX_LEVEL:
		return MAX_LEVEL_XP_SENTINEL
	match stage_for_level(safe_level):
		STAGE_I:
			return 50
		STAGE_II:
			return 80
		STAGE_III:
			return 120
		_:
			return 200


## Applies XP to a dragon in a staged transaction and returns pending progression events.
func apply_xp(tx: SaveTransaction, dragon_id: StringName, xp_amount, source_id: StringName = &"") -> XPApplyResult:
	var result: XPApplyResult = _make_xp_result(dragon_id, source_id)
	var dragon: DragonRecord = _validated_xp_target(result, tx, dragon_id)
	if dragon == null:
		return result

	result.element = dragon.element
	var xp_requested: int = int(xp_amount)
	result.xp_requested = xp_requested
	if xp_requested < 0:
		push_error("XP award rejected: xpGained must be >= 0, got %d" % xp_requested)
		return _fail_xp_result(result, &"invalid_xp", "xpGained must be >= 0.")

	var xp_awarded: int = min(xp_requested, XP_MAX_AWARD)
	result.xp_awarded = xp_awarded
	dragon.xp += xp_awarded
	_apply_xp_levels(dragon, result)
	_finalize_xp_result(dragon, result)
	_queue_post_commit_events(tx, result.pending_events)
	return result


## Subscribes this service to SaveService commit success for pending progression events.
func bind_save_service(save_service: SaveService) -> void:
	if save_service == null:
		return
	var callback: Callable = Callable(self, "_on_save_committed")
	if not save_service.save_committed.is_connected(callback):
		save_service.save_committed.connect(callback)


## Publishes Dragon Progression events from a successful SaveCommitResult.
func publish_committed_events(commit_result: SaveCommitResult) -> void:
	if commit_result == null or not commit_result.success:
		return
	for event: RefCounted in commit_result.post_commit_events:
		if event is DragonProgressionEvent:
			_publish_progression_event(event as DragonProgressionEvent)


func _on_save_committed(commit_result: SaveCommitResult) -> void:
	publish_committed_events(commit_result)


func _validated_xp_target(result: XPApplyResult, tx: SaveTransaction, dragon_id: StringName) -> DragonRecord:
	if tx == null or not tx.active or tx.staged_save == null:
		_fail_xp_result(result, &"invalid_transaction", "apply_xp requires an active SaveTransaction.")
		return null

	var dragon: DragonRecord = _find_staged_dragon(tx, dragon_id)
	if dragon == null:
		_fail_xp_result(result, &"missing_dragon", "No staged DragonRecord found for dragon_id '%s'." % dragon_id)
	return dragon


func _apply_xp_levels(dragon: DragonRecord, result: XPApplyResult) -> void:
	var threshold: int = xp_threshold_for(dragon.level)
	var effective_threshold: int = _effective_threshold(threshold, dragon.battle_charges)
	while dragon.xp >= effective_threshold and dragon.level < MAX_LEVEL:
		dragon.xp -= effective_threshold
		var previous_level: int = dragon.level
		var previous_stage: int = stage_for_level(dragon.level)
		dragon.level += 1
		result.levels_gained += 1
		if dragon.battle_charges > 0:
			dragon.battle_charges -= 1
			result.charges_consumed += 1

		var new_stage: int = stage_for_level(dragon.level)
		if new_stage > previous_stage:
			result.pending_events.append(_make_stage_advanced_event(dragon, previous_stage, new_stage, previous_level, dragon.level))
		if dragon.level == 50:
			result.pending_events.append(_make_stage_iv_reached_event(dragon, previous_level, dragon.level))

		threshold = xp_threshold_for(dragon.level)
		effective_threshold = _effective_threshold(threshold, dragon.battle_charges)


func _finalize_xp_result(dragon: DragonRecord, result: XPApplyResult) -> void:
	if dragon.level == MAX_LEVEL:
		dragon.xp = 0
		dragon.battle_charges = 0

	if result.levels_gained > 0:
		result.pending_events.append(_make_stats_updated_event(dragon))

	result.success = true
	result.reason = &"ok"
	result.xp_remainder = dragon.xp
	result.stats = calculate_stats(dragon)


func _queue_post_commit_events(tx: SaveTransaction, events: Array[DragonProgressionEvent]) -> void:
	for event: DragonProgressionEvent in events:
		tx.post_commit_events.append(event)


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


func _effective_threshold(threshold: int, battle_charges: int) -> int:
	if battle_charges <= 0:
		return threshold
	return max(1, int(float(threshold) / RESONANCE_XP_MULTIPLIER))


func _find_staged_dragon(tx: SaveTransaction, dragon_id: StringName) -> DragonRecord:
	for dragon in tx.staged_save.dragons:
		if dragon.dragon_id == dragon_id:
			return dragon
	return null


func _make_xp_result(dragon_id: StringName, source_id: StringName) -> XPApplyResult:
	var result: XPApplyResult = XPApplyResultResource.new()
	result.dragon_id = dragon_id
	result.source_id = source_id
	return result


func _fail_xp_result(result: XPApplyResult, reason: StringName, error_message: String) -> XPApplyResult:
	result.success = false
	result.reason = reason
	result.error_message = error_message
	return result


func _make_stage_advanced_event(dragon: DragonRecord, from_stage: int, to_stage: int, old_level: int, new_level: int) -> DragonProgressionEvent:
	var event: DragonProgressionEvent = _make_event(&"stage_advanced", dragon, old_level, new_level)
	event.from_stage = from_stage
	event.to_stage = to_stage
	return event


func _make_stage_iv_reached_event(dragon: DragonRecord, old_level: int, new_level: int) -> DragonProgressionEvent:
	return _make_event(&"stage_iv_reached", dragon, old_level, new_level)


func _make_stats_updated_event(dragon: DragonRecord) -> DragonProgressionEvent:
	return _make_event(&"stats_updated", dragon, dragon.level, dragon.level)


func _make_event(event_id: StringName, dragon: DragonRecord, old_level: int, new_level: int) -> DragonProgressionEvent:
	var event: DragonProgressionEvent = DragonProgressionEventResource.new()
	event.event_id = event_id
	event.dragon_id = dragon.dragon_id
	event.element = dragon.element
	event.old_level = old_level
	event.new_level = new_level
	return event


func _publish_progression_event(event: DragonProgressionEvent) -> void:
	match event.event_id:
		&"stats_updated":
			stats_updated.emit(event)
		&"stage_advanced":
			stage_advanced.emit(event)
		&"stage_iv_reached":
			stage_iv_reached.emit(event)
