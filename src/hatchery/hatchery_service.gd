class_name HatcheryService
extends RefCounted

## Transaction boundary for Hatchery pull execution.
## Stages Scrap spend, resolver counters, and dragon outcomes inside one SaveTransaction.

const HatcheryPullResultResource = preload("res://src/hatchery/hatchery_pull_result.gd")
const HatcheryPullResolverResource = preload("res://src/hatchery/hatchery_pull_resolver.gd")
const HatcheryRngProviderResource = preload("res://src/hatchery/hatchery_rng_provider.gd")

const DEFAULT_PULL_ID: StringName = &"standard_hatchery"
const DEFAULT_SOURCE_ID: StringName = &"hatchery_pull"
const TRANSACTION_REASON: StringName = &"hatchery_pull"
const BASE_DUPLICATE_XP: int = 50

var _save_service: SaveService = null
var _economy_ledger: EconomyLedger = null
var _dragon_progression: DragonProgressionService = null
var _pull_table: HatcheryPullTable = null
var _resolver: HatcheryPullResolver = null
var _transaction_seed_counter: int = 0


func configure(
		save_service: SaveService,
		economy_ledger: EconomyLedger,
		dragon_progression: DragonProgressionService,
		pull_table: HatcheryPullTable,
		resolver: HatcheryPullResolver = null
) -> void:
	_save_service = save_service
	_economy_ledger = economy_ledger
	_dragon_progression = dragon_progression
	_pull_table = pull_table
	_resolver = resolver if resolver != null else HatcheryPullResolverResource.new()


func execute_pull(
		pull_id: StringName = DEFAULT_PULL_ID,
		source_id: StringName = DEFAULT_SOURCE_ID,
		rng: HatcheryRngProvider = null
) -> HatcheryPullResult:
	var result: HatcheryPullResult = _make_result(pull_id, source_id)
	if not _is_configured():
		return _fail_result(result, &"invalid_configuration", "HatcheryService requires SaveService, EconomyLedger, DragonProgressionService, HatcheryPullTable, and resolver.")

	var table_validation: HatcheryPullTableValidationResult = _pull_table.validate()
	if not table_validation.ok:
		return _fail_result(result, &"invalid_pull_table", "\n".join(table_validation.actionable_errors))

	var snapshot: HatcheryPullTableSnapshot = _pull_table.create_runtime_snapshot()
	result.table_snapshot = snapshot
	result.cost = snapshot.scrap_cost
	if pull_id != snapshot.pull_id:
		return _fail_result(result, &"unknown_pull_id", "Unknown Hatchery pull_id '%s'." % pull_id)

	var tx: SaveTransaction = _save_service.begin_transaction(TRANSACTION_REASON)
	if tx == null or tx.staged_save == null:
		return _fail_result(result, &"missing_save_transaction", "HatcheryService could not open a SaveTransaction.")

	result.balance_before = _economy_ledger.get_scraps(tx.staged_save)
	result.balance_after = result.balance_before
	var affordability: EconomyResult = _economy_ledger.check_affordability(tx.staged_save, snapshot.scrap_cost, source_id)
	result.economy_result = affordability
	if not affordability.success or not affordability.affordable:
		tx.active = false
		var message: String = affordability.error_message
		if message == "":
			message = "Not enough Scraps for Hatchery pull."
		return _fail_result(result, affordability.reason, message)

	var spend_result: EconomyResult = _economy_ledger.spend_scraps(tx, snapshot.scrap_cost, source_id)
	result.economy_result = spend_result
	result.balance_before = spend_result.balance_before
	result.balance_after = spend_result.balance_after
	if not spend_result.success:
		tx.active = false
		return _fail_result(result, spend_result.reason, spend_result.error_message)

	var resolution_rng: HatcheryRngProvider = rng if rng != null else _make_transaction_rng()
	var resolution: HatcheryPullResolutionResult = _resolver.resolve_with_droughts(
		snapshot,
		tx.staged_save.hatchery_pity_counter,
		_complete_drought_counters(snapshot, tx.staged_save.element_drought_counters),
		resolution_rng
	)
	if not resolution.success:
		tx.active = false
		return _fail_result(result, resolution.reason, resolution.error_message)

	tx.staged_save.hatchery_pity_counter = resolution.next_pity_counter
	tx.staged_save.element_drought_counters = _typed_drought_counters(snapshot, resolution.next_drought_counters)
	if not _stage_dragon_outcome(result, tx, snapshot, resolution, source_id):
		tx.active = false
		return result

	var commit_result: SaveCommitResult = _save_service.commit_transaction(tx)
	result.save_commit_result = commit_result
	if not commit_result.success:
		result.balance_after = result.balance_before
		result.economy_result = null
		_clear_committed_outcome_fields(result)
		return _fail_result(result, &"save_commit_failed", commit_result.error_message)

	return _success_result(result, resolution)


func _make_result(pull_id: StringName, source_id: StringName) -> HatcheryPullResult:
	var result: HatcheryPullResult = HatcheryPullResultResource.new()
	result.pull_id = pull_id
	result.source_id = source_id
	return result


func _is_configured() -> bool:
	return _save_service != null and _economy_ledger != null and _dragon_progression != null and _pull_table != null and _resolver != null


func _success_result(result: HatcheryPullResult, resolution: HatcheryPullResolutionResult) -> HatcheryPullResult:
	result.success = true
	result.reason = &"ok"
	result.error_message = ""
	result.resolution_result = resolution
	result.element_id = resolution.final_element
	result.rarity_id = resolution.final_rarity
	result.shiny = resolution.shiny
	result.pity_forced = resolution.pity_forced
	result.element_soft_pity_forced = resolution.element_soft_pity_forced
	result.rarity_roll_basis_point = resolution.rarity_roll_basis_point
	result.element_roll_basis_point = resolution.element_roll_basis_point
	result.shiny_roll_basis_point = resolution.shiny_roll_basis_point
	result.next_pity_counter = resolution.next_pity_counter
	result.next_drought_counters = _typed_drought_counters(result.table_snapshot, resolution.next_drought_counters)
	return result


func _fail_result(result: HatcheryPullResult, reason: StringName, error_message: String) -> HatcheryPullResult:
	result.success = false
	result.reason = reason
	result.error_message = error_message
	return result


func _stage_dragon_outcome(
		result: HatcheryPullResult,
		tx: SaveTransaction,
		snapshot: HatcheryPullTableSnapshot,
		resolution: HatcheryPullResolutionResult,
		source_id: StringName
) -> bool:
	if not snapshot.has_standard_element(resolution.final_element):
		_fail_result(result, &"invalid_element", "Hatchery outcome element '%s' is not in the standard Hatchery table." % resolution.final_element)
		return false

	var existing: DragonRecord = _find_staged_dragon_by_element(tx, resolution.final_element)
	if existing == null:
		var creation: DragonCreationResult = _dragon_progression.create_from_hatchery(tx, resolution.final_element, resolution.shiny, source_id)
		result.creation_result = creation
		if not creation.success:
			_fail_result(result, creation.reason, creation.error_message)
			return false
		result.duplicate = false
		result.dragon_id = creation.dragon_id
		result.xp_awarded = 0
		return true

	var duplicate_xp: int = _duplicate_xp_for_rarity(snapshot, resolution.final_rarity)
	if duplicate_xp <= 0:
		_fail_result(result, &"unknown_rarity", "Hatchery duplicate XP requires a known positive multiplier for rarity '%s'." % resolution.final_rarity)
		return false

	var xp_result: XPApplyResult = _dragon_progression.apply_hatchery_duplicate_outcome(
		tx,
		resolution.final_element,
		duplicate_xp,
		resolution.shiny,
		source_id
	)
	result.xp_result = xp_result
	if not xp_result.success:
		_fail_result(result, xp_result.reason, xp_result.error_message)
		return false

	result.duplicate = true
	result.dragon_id = xp_result.dragon_id
	result.xp_awarded = xp_result.xp_awarded
	result.shiny_upgraded = xp_result.shiny_upgraded
	return true


func _duplicate_xp_for_rarity(snapshot: HatcheryPullTableSnapshot, rarity_id: StringName) -> int:
	var multiplier: int = int(snapshot.rarity_xp_multipliers.get(rarity_id, 0))
	if multiplier <= 0:
		return 0
	return BASE_DUPLICATE_XP * multiplier


func _find_staged_dragon_by_element(tx: SaveTransaction, element: StringName) -> DragonRecord:
	for dragon: DragonRecord in tx.staged_save.dragons:
		if dragon.element == element:
			return dragon
	return null


func _clear_committed_outcome_fields(result: HatcheryPullResult) -> void:
	result.element_id = &""
	result.rarity_id = &""
	result.shiny = false
	result.dragon_id = &""
	result.duplicate = false
	result.xp_awarded = 0
	result.shiny_upgraded = false
	result.pity_forced = false
	result.element_soft_pity_forced = false
	result.rarity_roll_basis_point = -1
	result.element_roll_basis_point = -1
	result.shiny_roll_basis_point = -1
	result.next_pity_counter = 0
	result.next_drought_counters.clear()
	result.resolution_result = null
	result.creation_result = null
	result.xp_result = null


func _complete_drought_counters(
		snapshot: HatcheryPullTableSnapshot,
		drought_counters: Dictionary
) -> Dictionary[StringName, int]:
	var completed: Dictionary[StringName, int] = {}
	for element_id in snapshot.required_element_ids:
		completed[element_id] = max(0, int(drought_counters.get(element_id, 0)))
	return completed


func _typed_drought_counters(
		snapshot: HatcheryPullTableSnapshot,
		drought_counters: Dictionary
) -> Dictionary[StringName, int]:
	var typed_counters: Dictionary[StringName, int] = {}
	for element_id in snapshot.required_element_ids:
		typed_counters[element_id] = max(0, int(drought_counters.get(element_id, 0)))
	return typed_counters


func _make_transaction_rng() -> HatcheryRngProvider:
	_transaction_seed_counter += 1
	var rng: HatcheryRngProvider = HatcheryRngProviderResource.new()
	rng.configure_seed(int(Time.get_ticks_usec()) + _transaction_seed_counter)
	return rng
