class_name DragonProgressionService
extends RefCounted

signal stats_updated(event: DragonProgressionEvent)
signal stage_advanced(event: DragonProgressionEvent)
signal stage_iv_reached(event: DragonProgressionEvent)

const DragonStats = preload("res://src/dragon/dragon_stats.gd")
const DragonRecordResource = preload("res://src/dragon/dragon_record.gd")
const XPApplyResultResource = preload("res://src/dragon/xp_apply_result.gd")
const DragonCreationResultResource = preload("res://src/dragon/dragon_creation_result.gd")
const DragonProgressionEventResource = preload("res://src/dragon/dragon_progression_event.gd")
const DragonValidationResult = preload("res://src/dragon/dragon_validation_result.gd")

const MIN_LEVEL: int = 1
const MAX_LEVEL: int = 60
const MAX_LEVEL_XP_SENTINEL: int = 2147483647
const XP_MAX_AWARD: int = 10000
const RESONANCE_XP_MULTIPLIER: float = 1.5
const SHINY_MULTIPLIER: float = 1.2
const STANDARD_MULTIPLIER: float = 1.0
const VOID_DRAGON_ID: StringName = &"void_dragon"
const VOID_GRANT_LEVEL: int = 30
const SOURCE_LOCAL: StringName = &"local"
const SOURCE_CLOUD: StringName = &"cloud"

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

const CORE_ELEMENTS: Array = [&"Fire", &"Ice", &"Storm", &"Stone", &"Venom", &"Shadow"]


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
func apply_xp(tx: SaveTransaction, dragon_id: StringName, xp_amount: Variant, source_id: StringName = &"") -> XPApplyResult:
	var result: XPApplyResult = _make_xp_result(dragon_id, source_id)
	var dragon: DragonRecord = _validated_xp_target(result, tx, dragon_id)
	if dragon == null:
		return result

	result.element = dragon.element
	if not _validate_xp_request(result, xp_amount):
		return result

	return _apply_validated_xp_award(tx, dragon, result)


## Stages a new core-element dragon from a Hatchery pull.
func create_from_hatchery(tx: SaveTransaction, element: StringName, shiny: bool, source_id: StringName = &"hatchery") -> DragonCreationResult:
	var result: DragonCreationResult = _make_creation_result(source_id)
	result.element = element
	if not _validate_creation_tx(result, tx, &"create_from_hatchery"):
		return result
	if not _is_core_element(element):
		return _fail_creation_result(result, &"invalid_element", "Hatchery creation requires a core element.")
	if _find_staged_dragon_by_element(tx, element) != null:
		return _fail_creation_result(result, &"duplicate_element", "Hatchery duplicate must be routed to duplicate XP handling.")

	var dragon: DragonRecord = _make_dragon_record(_next_hatchery_dragon_id(tx, element, source_id), element, MIN_LEVEL, shiny, false)
	_assign_canonical_base_stats(dragon, element)
	tx.staged_save.dragons.append(dragon)
	return _succeed_created_result(result, dragon)


## Stages a Fusion child from the already-authored Fusion output snapshot.
func create_from_fusion(tx: SaveTransaction, primary_id: StringName, secondary_id: StringName, child_data: FusionChildData, source_id: StringName = &"fusion") -> DragonCreationResult:
	var result: DragonCreationResult = _make_creation_result(source_id)
	result.primary_id = primary_id
	result.secondary_id = secondary_id
	if not _validate_creation_tx(result, tx, &"create_from_fusion"):
		return result
	if child_data == null:
		return _fail_creation_result(result, &"invalid_child_data", "Fusion creation requires FusionChildData.")

	result.dragon_id = child_data.dragon_id
	result.element = child_data.element
	if child_data.dragon_id == &"":
		return _fail_creation_result(result, &"invalid_child_data", "Fusion child dragon_id is required.")
	if child_data.element == &"Void" or not BASE_STATS_BY_ELEMENT.has(child_data.element):
		return _fail_creation_result(result, &"invalid_element", "Fusion cannot output Void or unknown elements.")
	if child_data.base_hp <= 0 or child_data.base_atk <= 0 or child_data.base_def <= 0 or child_data.base_spd <= 0:
		return _fail_creation_result(result, &"invalid_child_data", "Fusion child base stats must be positive.")
	if _find_staged_dragon(tx, child_data.dragon_id) != null:
		return _fail_creation_result(result, &"duplicate_dragon_id", "Fusion child dragon_id already exists.")

	var dragon: DragonRecord = _make_dragon_record(child_data.dragon_id, child_data.element, MIN_LEVEL, false, child_data.is_elder)
	dragon.base_hp = child_data.base_hp
	dragon.base_atk = child_data.base_atk
	dragon.base_def = child_data.base_def
	dragon.base_spd = child_data.base_spd
	tx.staged_save.dragons.append(dragon)
	return _succeed_created_result(result, dragon)


## Stages the Singularity story grant for the reserved Void dragon.
func grant_void_dragon(tx: SaveTransaction, source_id: StringName = &"singularity_void") -> DragonCreationResult:
	var result: DragonCreationResult = _make_creation_result(source_id)
	result.dragon_id = VOID_DRAGON_ID
	result.element = &"Void"
	if not _validate_creation_tx(result, tx, &"grant_void_dragon"):
		return result

	var existing: DragonRecord = _find_staged_dragon(tx, VOID_DRAGON_ID)
	if existing != null:
		if existing.element != &"Void":
			return _fail_creation_result(result, &"invalid_void_record", "Existing void_dragon must use Void element.")
		_normalize_void_record(existing)
		_ensure_story_roster_entry(tx, VOID_DRAGON_ID)
		tx.staged_save.void_dragon_granted = true
		result.success = true
		result.reason = &"already_granted"
		result.already_present = true
		result.dragon = _snapshot_dragon(existing)
		return result

	var dragon: DragonRecord = _make_dragon_record(VOID_DRAGON_ID, &"Void", VOID_GRANT_LEVEL, false, false)
	_assign_canonical_base_stats(dragon, &"Void")
	tx.staged_save.dragons.append(dragon)
	_ensure_story_roster_entry(tx, VOID_DRAGON_ID)
	tx.staged_save.void_dragon_granted = true
	return _succeed_created_result(result, dragon)


## Applies Hatchery duplicate XP to the matching owned dragon, or discards with the GDD-required log.
func apply_hatchery_duplicate_xp(tx: SaveTransaction, element: StringName, xp_amount: Variant, source_id: StringName = &"hatchery_duplicate") -> XPApplyResult:
	return apply_hatchery_duplicate_outcome(tx, element, xp_amount, false, source_id)


## Applies Hatchery duplicate XP and same-pull shiny upgrades to the matching owned dragon.
func apply_hatchery_duplicate_outcome(
		tx: SaveTransaction,
		element: StringName,
		xp_amount: Variant,
		shiny: bool,
		source_id: StringName = &"hatchery_duplicate"
) -> XPApplyResult:
	var result: XPApplyResult = _make_xp_result(&"", source_id)
	result.element = element
	result.xp_requested = int(xp_amount)
	result.shiny_requested = shiny
	if tx == null or not tx.active or tx.staged_save == null:
		return _fail_xp_result(result, &"invalid_transaction", "apply_hatchery_duplicate_outcome requires an active SaveTransaction.")

	var dragon: DragonRecord = _find_staged_dragon_by_element(tx, element)
	if dragon == null:
		push_error("Hatchery XP discarded: element %s not in party." % element)
		return _fail_xp_result(result, &"missing_duplicate_target", "No staged DragonRecord found for duplicate element '%s'." % element)

	result.dragon_id = dragon.dragon_id
	if not _validate_xp_request(result, xp_amount):
		return result

	if shiny and not dragon.shiny and dragon.element != &"Void":
		dragon.shiny = true
		result.shiny_upgraded = true
	result.shiny = dragon.shiny
	return _apply_validated_xp_award(tx, dragon, result)


## Validates and repairs dragon records in a loaded SaveData copy.
## Invalid records are discarded; valid records are repaired before runtime access.
func validate_and_repair_save_data(save_data: SaveData) -> DragonValidationResult:
	var result: DragonValidationResult = _make_validation_result()
	if save_data == null:
		return _fail_validation_result(result, &"missing_save_data", "validate_and_repair_save_data requires SaveData.")

	var repaired_dragons: Array[DragonRecord] = []
	var seen_dragon_ids: Dictionary[StringName, bool] = {}
	for dragon: DragonRecord in save_data.dragons:
		if _repair_loaded_dragon(dragon, result, save_data):
			if seen_dragon_ids.has(dragon.dragon_id):
				_record_validation_error(
					result,
					dragon.dragon_id,
					"Save integrity violation: duplicate dragon_id '%s'. Dragon record discarded." % dragon.dragon_id
				)
				continue
			seen_dragon_ids[dragon.dragon_id] = true
			repaired_dragons.append(dragon)

	save_data.dragons = repaired_dragons
	return result


## Validates one loaded dragon record and returns a detached snapshot for readers.
func validate_record(record: DragonRecord) -> DragonValidationResult:
	var result: DragonValidationResult = _make_validation_result()
	if record == null:
		return _fail_validation_result(result, &"missing_dragon", "validate_record requires DragonRecord.")

	var save_data: SaveData = SaveData.new()
	var copy: DragonRecord = _snapshot_dragon(record)
	save_data.dragons.append(copy)
	if not _repair_loaded_dragon(copy, result, save_data):
		return _fail_validation_result(result, &"invalid_dragon", "DragonRecord failed load validation.")

	result.dragon = _snapshot_dragon(copy)
	result.stats = calculate_stats(copy)
	return result


## Selects the authoritative loaded record for a local/cloud conflict.
func select_conflict_winner(local_record: DragonRecord, cloud_record: DragonRecord) -> DragonValidationResult:
	var result: DragonValidationResult = _make_validation_result()
	if local_record == null and cloud_record == null:
		return _fail_validation_result(result, &"missing_conflict_records", "At least one conflict record is required.")
	if local_record == null:
		return _select_conflict_source(result, SOURCE_CLOUD, cloud_record)
	if cloud_record == null:
		return _select_conflict_source(result, SOURCE_LOCAL, local_record)

	if cloud_record.level > local_record.level:
		return _select_conflict_source(result, SOURCE_CLOUD, cloud_record)
	if local_record.level > cloud_record.level:
		return _select_conflict_source(result, SOURCE_LOCAL, local_record)
	if cloud_record.xp > local_record.xp:
		return _select_conflict_source(result, SOURCE_CLOUD, cloud_record)
	return _select_conflict_source(result, SOURCE_LOCAL, local_record)


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


func _repair_loaded_dragon(dragon: DragonRecord, result: DragonValidationResult, save_data: SaveData) -> bool:
	if dragon == null:
		_record_validation_error(result, &"", "Save integrity violation: missing dragon record. Dragon record discarded.")
		return false

	if dragon.level < MIN_LEVEL or dragon.level > MAX_LEVEL:
		_record_validation_error(
			result,
			dragon.dragon_id,
			"Save integrity violation: dragon.level out of range %d for element %s. Dragon record discarded." % [dragon.level, dragon.element]
		)
		return false

	if dragon.xp < 0:
		_record_validation_error(
			result,
			dragon.dragon_id,
			"Save integrity violation: dragon.xp negative %d for element %s. Dragon record discarded." % [dragon.xp, dragon.element]
		)
		return false

	if not BASE_STATS_BY_ELEMENT.has(dragon.element):
		_record_validation_error(
			result,
			dragon.dragon_id,
			"Save integrity violation: unknown element '%s'. Dragon record discarded." % dragon.element
		)
		return false

	if dragon.element == &"Void" and dragon.dragon_id != VOID_DRAGON_ID:
		_record_validation_error(
			result,
			dragon.dragon_id,
			"Save integrity violation: Void dragon must use reserved dragon_id 'void_dragon'. Dragon record discarded."
		)
		return false

	if dragon.dragon_id == VOID_DRAGON_ID and dragon.element != &"Void":
		_record_validation_error(
			result,
			dragon.dragon_id,
			"Save integrity violation: reserved dragon_id 'void_dragon' requires element Void. Dragon record discarded."
		)
		return false

	if dragon.dragon_id == VOID_DRAGON_ID and dragon.element == &"Void":
		_normalize_void_record(dragon)
		_ensure_story_roster_entry_for_save_data(save_data, VOID_DRAGON_ID)
		save_data.void_dragon_granted = true

	if dragon.level == MAX_LEVEL:
		if dragon.xp != 0:
			_record_repair_warning(
				result,
				dragon.dragon_id,
				"Save correction: dragon.xp %d cleared for MAX_LEVEL dragon %s." % [dragon.xp, dragon.element]
			)
		if dragon.battle_charges != 0:
			_record_repair_warning(
				result,
				dragon.dragon_id,
				"Save correction: battle_charges %d cleared for MAX_LEVEL dragon %s." % [dragon.battle_charges, dragon.element]
			)
		dragon.xp = 0
		dragon.battle_charges = 0
		return true

	var threshold: int = xp_threshold_for(dragon.level)
	if dragon.xp >= threshold:
		_record_repair_warning(
			result,
			dragon.dragon_id,
			"Save correction: dragon.xp %d at level %d — running XP loop to resolve." % [dragon.xp, dragon.level]
		)
		dragon.battle_charges = 0
		_apply_loaded_xp_repair_loop(dragon)

	return true


func _apply_loaded_xp_repair_loop(dragon: DragonRecord) -> void:
	while dragon.level < MAX_LEVEL and dragon.xp >= xp_threshold_for(dragon.level):
		dragon.xp -= xp_threshold_for(dragon.level)
		dragon.level += 1
	if dragon.level == MAX_LEVEL:
		dragon.xp = 0
		dragon.battle_charges = 0


func _record_validation_error(result: DragonValidationResult, dragon_id: StringName, message: String) -> void:
	push_error(message)
	result.warnings.append(message)
	if dragon_id != &"" and not result.discarded_dragon_ids.has(dragon_id):
		result.discarded_dragon_ids.append(dragon_id)


func _record_repair_warning(result: DragonValidationResult, dragon_id: StringName, message: String) -> void:
	push_warning(message)
	result.warnings.append(message)
	if dragon_id != &"" and not result.repaired_dragon_ids.has(dragon_id):
		result.repaired_dragon_ids.append(dragon_id)


func _ensure_story_roster_entry_for_save_data(save_data: SaveData, dragon_id: StringName) -> void:
	if save_data != null and not save_data.story_roster.has(dragon_id):
		save_data.story_roster.append(dragon_id)


func _select_conflict_source(result: DragonValidationResult, source: StringName, dragon: DragonRecord) -> DragonValidationResult:
	result.selected_source = source
	result.dragon = _snapshot_dragon(dragon)
	result.stats = calculate_stats(dragon)
	return result


func _validated_xp_target(result: XPApplyResult, tx: SaveTransaction, dragon_id: StringName) -> DragonRecord:
	if tx == null or not tx.active or tx.staged_save == null:
		_fail_xp_result(result, &"invalid_transaction", "apply_xp requires an active SaveTransaction.")
		return null

	var dragon: DragonRecord = _find_staged_dragon(tx, dragon_id)
	if dragon == null:
		_fail_xp_result(result, &"missing_dragon", "No staged DragonRecord found for dragon_id '%s'." % dragon_id)
	return dragon


func _validate_xp_request(result: XPApplyResult, xp_amount: Variant) -> bool:
	var xp_requested: int = int(xp_amount)
	result.xp_requested = xp_requested
	if xp_requested < 0:
		push_error("XP award rejected: xpGained must be >= 0, got %d" % xp_requested)
		_fail_xp_result(result, &"invalid_xp", "xpGained must be >= 0.")
		return false
	return true


func _apply_validated_xp_award(tx: SaveTransaction, dragon: DragonRecord, result: XPApplyResult) -> XPApplyResult:
	result.element = dragon.element
	result.shiny = dragon.shiny
	var xp_awarded: int = min(result.xp_requested, XP_MAX_AWARD)
	result.xp_awarded = xp_awarded
	dragon.xp += xp_awarded
	_apply_xp_levels(dragon, result)
	_finalize_xp_result(dragon, result)
	_queue_post_commit_events(tx, result.pending_events)
	return result


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
	result.shiny = dragon.shiny
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


func _find_staged_dragon_by_element(tx: SaveTransaction, element: StringName) -> DragonRecord:
	for dragon in tx.staged_save.dragons:
		if dragon.element == element:
			return dragon
	return null


func _is_core_element(element: StringName) -> bool:
	return CORE_ELEMENTS.has(element)


func _validate_creation_tx(result: DragonCreationResult, tx: SaveTransaction, helper_name: StringName) -> bool:
	if tx == null or not tx.active or tx.staged_save == null:
		_fail_creation_result(result, &"invalid_transaction", "%s requires an active SaveTransaction." % helper_name)
		return false
	return true


func _make_dragon_record(dragon_id: StringName, element: StringName, level: int, shiny: bool, is_elder: bool) -> DragonRecord:
	var dragon: DragonRecord = DragonRecordResource.new()
	dragon.dragon_id = dragon_id
	dragon.element = element
	dragon.level = level
	dragon.xp = 0
	dragon.shiny = shiny and element != &"Void"
	dragon.battle_charges = 0
	dragon.is_elder = is_elder
	return dragon


func _snapshot_dragon(dragon: DragonRecord) -> DragonRecord:
	return dragon.duplicate(true) as DragonRecord


func _assign_canonical_base_stats(dragon: DragonRecord, element: StringName) -> void:
	var stats: Array = _canonical_base_stats(element)
	if stats.size() < 4:
		return
	dragon.base_hp = int(stats[0])
	dragon.base_atk = int(stats[1])
	dragon.base_def = int(stats[2])
	dragon.base_spd = int(stats[3])


func _normalize_void_record(dragon: DragonRecord) -> void:
	dragon.dragon_id = VOID_DRAGON_ID
	dragon.element = &"Void"
	dragon.shiny = false
	_assign_canonical_base_stats(dragon, &"Void")


func _ensure_story_roster_entry(tx: SaveTransaction, dragon_id: StringName) -> void:
	if not tx.staged_save.story_roster.has(dragon_id):
		tx.staged_save.story_roster.append(dragon_id)


func _next_hatchery_dragon_id(tx: SaveTransaction, element: StringName, source_id: StringName) -> StringName:
	var base_id: String = "%s_%s" % [String(element).to_lower(), String(source_id)]
	var candidate: StringName = StringName(base_id)
	var suffix: int = 2
	while _find_staged_dragon(tx, candidate) != null:
		candidate = StringName("%s_%d" % [base_id, suffix])
		suffix += 1
	return candidate


func _make_creation_result(source_id: StringName) -> DragonCreationResult:
	var result: DragonCreationResult = DragonCreationResultResource.new()
	result.source_id = source_id
	return result


func _succeed_created_result(result: DragonCreationResult, dragon: DragonRecord) -> DragonCreationResult:
	result.success = true
	result.reason = &"ok"
	result.created = true
	result.dragon = _snapshot_dragon(dragon)
	result.dragon_id = dragon.dragon_id
	result.element = dragon.element
	return result


func _fail_creation_result(result: DragonCreationResult, reason: StringName, error_message: String) -> DragonCreationResult:
	result.success = false
	result.reason = reason
	result.error_message = error_message
	return result


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


func _make_validation_result() -> DragonValidationResult:
	return DragonValidationResult.new()


func _fail_validation_result(result: DragonValidationResult, reason: StringName, error_message: String) -> DragonValidationResult:
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
