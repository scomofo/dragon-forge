class_name HatcheryPullTable
extends Resource

## Authored immutable Hatchery pull table Resource.
## Runtime callers should use create_runtime_snapshot() before mutating any copy.

const HatcheryElementWeightResource = preload("res://src/hatchery/hatchery_element_weight.gd")
const HatcheryPityRulesResource = preload("res://src/hatchery/hatchery_pity_rules.gd")
const HatcheryPullTableSnapshotResource = preload("res://src/hatchery/hatchery_pull_table_snapshot.gd")
const HatcheryPullTableValidationResultResource = preload("res://src/hatchery/hatchery_pull_table_validation_result.gd")
const HatcheryRarityWeightResource = preload("res://src/hatchery/hatchery_rarity_weight.gd")

const PULL_COST: int = 50
const BASIS_POINTS_TOTAL: int = 10000
const SHINY_RATE_BASIS_POINTS: int = 200
const STANDARD_PULL_ID: StringName = &"standard_hatchery"
const VOID_ELEMENT_ID: StringName = &"Void"
const REQUIRED_RARITY_IDS: Array[StringName] = [&"Common", &"Uncommon", &"Rare"]
const REQUIRED_ELEMENT_IDS: Array[StringName] = [&"Fire", &"Ice", &"Storm", &"Venom", &"Stone", &"Shadow"]

@export var pull_id: StringName = STANDARD_PULL_ID
@export var scrap_cost: int = PULL_COST
@export var rarity_weights: Array[HatcheryRarityWeight] = []
@export var element_weights: Array[HatcheryElementWeight] = []
@export var pity_rules: HatcheryPityRules = null
@export_range(0, 10000, 1) var shiny_rate_basis_points: int = SHINY_RATE_BASIS_POINTS
@export var required_element_ids: Array[StringName] = REQUIRED_ELEMENT_IDS.duplicate()


func configure_mvp_standard_table() -> void:
	pull_id = STANDARD_PULL_ID
	scrap_cost = PULL_COST
	shiny_rate_basis_points = SHINY_RATE_BASIS_POINTS
	required_element_ids = REQUIRED_ELEMENT_IDS.duplicate()
	pity_rules = HatcheryPityRulesResource.new()
	pity_rules.configure_mvp_defaults()

	rarity_weights = [
		_make_rarity_weight(&"Common", 5000, 1),
		_make_rarity_weight(&"Uncommon", 4000, 2),
		_make_rarity_weight(&"Rare", 1000, 3),
	]
	element_weights = [
		_make_element_weight(&"Fire", &"Common", 2500),
		_make_element_weight(&"Ice", &"Common", 2500),
		_make_element_weight(&"Storm", &"Uncommon", 1333),
		_make_element_weight(&"Venom", &"Uncommon", 1333),
		_make_element_weight(&"Stone", &"Uncommon", 1334),
		_make_element_weight(&"Shadow", &"Rare", 1000),
	]


func validate(required_ids: Array = []) -> HatcheryPullTableValidationResult:
	var result: HatcheryPullTableValidationResult = HatcheryPullTableValidationResultResource.new()
	var effective_required_ids: Array = required_ids if not required_ids.is_empty() else required_element_ids
	if effective_required_ids.is_empty():
		effective_required_ids = REQUIRED_ELEMENT_IDS

	if pull_id == &"":
		result.add_field_error("pull_id", "Hatchery pull table requires a stable pull_id.")
	if scrap_cost <= 0:
		result.add_field_error("scrap_cost", "Hatchery pull cost must be positive.")
	if shiny_rate_basis_points < 0 or shiny_rate_basis_points > BASIS_POINTS_TOTAL:
		result.add_field_error("shiny_rate_basis_points", "Hatchery shiny rate must be between 0 and 10000 basis points.")

	_validate_rarity_weights(result)
	_validate_element_weights(effective_required_ids, result)
	_validate_pity_rules(result)
	return result


func create_runtime_snapshot() -> HatcheryPullTableSnapshot:
	var snapshot: HatcheryPullTableSnapshot = HatcheryPullTableSnapshotResource.new()
	snapshot.pull_id = pull_id
	snapshot.scrap_cost = scrap_cost
	snapshot.shiny_rate_basis_points = shiny_rate_basis_points
	snapshot.required_element_ids = required_element_ids.duplicate()
	for rarity_weight in rarity_weights:
		if rarity_weight == null:
			continue
		snapshot.rarity_weights[rarity_weight.rarity_id] = rarity_weight.weight_basis_points
		snapshot.rarity_xp_multipliers[rarity_weight.rarity_id] = rarity_weight.xp_multiplier
	for element_weight in element_weights:
		if element_weight == null:
			continue
		snapshot.element_weights[element_weight.element_id] = element_weight.weight_basis_points
		snapshot.element_rarities[element_weight.element_id] = element_weight.rarity_id
	if pity_rules != null:
		snapshot.rare_element_id = pity_rules.rare_element_id
		snapshot.rare_pity_threshold = pity_rules.rare_pity_threshold
		snapshot.element_soft_pity_onset = pity_rules.element_soft_pity_onset
		snapshot.element_soft_pity_guaranteed = pity_rules.element_soft_pity_guaranteed
		snapshot.tie_break_priority = pity_rules.tie_break_priority.duplicate()
	return snapshot


func has_standard_element(element_id: StringName) -> bool:
	return element_weight_for(element_id) > 0


func rarity_weight_for(rarity_id: StringName) -> int:
	for rarity_weight in rarity_weights:
		if rarity_weight == null:
			continue
		if rarity_weight.rarity_id == rarity_id:
			return rarity_weight.weight_basis_points
	return 0


func rarity_multiplier_for(rarity_id: StringName) -> int:
	for rarity_weight in rarity_weights:
		if rarity_weight == null:
			continue
		if rarity_weight.rarity_id == rarity_id:
			return rarity_weight.xp_multiplier
	return 0


func element_weight_for(element_id: StringName) -> int:
	for element_weight in element_weights:
		if element_weight == null:
			continue
		if element_weight.element_id == element_id:
			return element_weight.weight_basis_points
	return 0


func rarity_for_element(element_id: StringName) -> StringName:
	for element_weight in element_weights:
		if element_weight == null:
			continue
		if element_weight.element_id == element_id:
			return element_weight.rarity_id
	return &""


func total_rarity_weight() -> int:
	var total: int = 0
	for rarity_weight in rarity_weights:
		if rarity_weight == null:
			continue
		total += rarity_weight.weight_basis_points
	return total


func total_element_weight() -> int:
	var total: int = 0
	for element_weight in element_weights:
		if element_weight == null:
			continue
		total += element_weight.weight_basis_points
	return total


func _validate_rarity_weights(result: HatcheryPullTableValidationResult) -> void:
	var seen_rarities: Dictionary = {}
	for rarity_weight in rarity_weights:
		if rarity_weight == null:
			result.add_field_error("rarity_weights", "Hatchery rarity weight entries cannot be null.")
			continue
		if rarity_weight.rarity_id == &"":
			result.add_field_error("rarity_weights", "Hatchery rarity weight entries require rarity_id.")
		if rarity_weight.weight_basis_points <= 0:
			result.add_field_error("rarity_weights", "Hatchery rarity '%s' must have positive weight." % rarity_weight.rarity_id)
		if rarity_weight.xp_multiplier <= 0:
			result.add_field_error("rarity_weights", "Hatchery rarity '%s' must have a positive XP multiplier." % rarity_weight.rarity_id)
		if seen_rarities.has(rarity_weight.rarity_id):
			result.add_duplicate_rarity_id(rarity_weight.rarity_id)
		seen_rarities[rarity_weight.rarity_id] = true

	for rarity_id in REQUIRED_RARITY_IDS:
		if not seen_rarities.has(rarity_id):
			result.add_missing_rarity_id(rarity_id)
	if total_rarity_weight() != BASIS_POINTS_TOTAL:
		result.add_field_error("rarity_weights", "Hatchery rarity weights must total %d basis points." % BASIS_POINTS_TOTAL)


func _validate_element_weights(required_ids: Array, result: HatcheryPullTableValidationResult) -> void:
	var seen_elements: Dictionary = {}
	var known_rarities: Dictionary = {}
	var element_weight_totals_by_rarity: Dictionary = {}
	for rarity_weight in rarity_weights:
		if rarity_weight != null:
			known_rarities[rarity_weight.rarity_id] = true
			element_weight_totals_by_rarity[rarity_weight.rarity_id] = 0

	for element_weight in element_weights:
		if element_weight == null:
			result.add_field_error("element_weights", "Hatchery element weight entries cannot be null.")
			continue
		if element_weight.element_id == &"":
			result.add_field_error("element_weights", "Hatchery element weight entries require element_id.")
		if element_weight.element_id == VOID_ELEMENT_ID:
			result.add_forbidden_element_id(element_weight.element_id)
		if element_weight.weight_basis_points <= 0:
			result.add_field_error("element_weights", "Hatchery element '%s' must have positive weight." % element_weight.element_id)
		if element_weight.rarity_id == &"" or not known_rarities.has(element_weight.rarity_id):
			result.add_field_error("element_weights", "Hatchery element '%s' references unknown rarity '%s'." % [element_weight.element_id, element_weight.rarity_id])
		else:
			element_weight_totals_by_rarity[element_weight.rarity_id] += element_weight.weight_basis_points
		if seen_elements.has(element_weight.element_id):
			result.add_duplicate_element_id(element_weight.element_id)
		seen_elements[element_weight.element_id] = true

	for required_id in required_ids:
		var required_element_id := StringName(required_id)
		if required_element_id == &"":
			result.add_field_error("required_element_ids", "Hatchery required element IDs cannot be empty.")
			continue
		if not seen_elements.has(required_element_id):
			result.add_missing_element_id(required_element_id)
	if total_element_weight() != BASIS_POINTS_TOTAL:
		result.add_field_error("element_weights", "Hatchery element weights must total %d basis points." % BASIS_POINTS_TOTAL)
	_validate_element_totals_match_rarities(element_weight_totals_by_rarity, result)


func _validate_pity_rules(result: HatcheryPullTableValidationResult) -> void:
	if pity_rules == null:
		result.add_field_error("pity_rules", "Hatchery pull table requires HatcheryPityRules.")
		return
	if pity_rules.rare_element_id == &"":
		result.add_field_error("pity_rules", "Hatchery pity rules require rare_element_id.")
	if pity_rules.rare_pity_threshold <= 0:
		result.add_field_error("pity_rules", "Hatchery rare pity threshold must be positive.")
	if pity_rules.element_soft_pity_onset < 0:
		result.add_field_error("pity_rules", "Hatchery element soft-pity onset must be non-negative.")
	if pity_rules.element_soft_pity_guaranteed <= pity_rules.element_soft_pity_onset:
		result.add_field_error("pity_rules", "Hatchery element soft-pity guarantee must be greater than onset.")
	if pity_rules.rare_pity_threshold >= pity_rules.element_soft_pity_guaranteed:
		result.add_field_error("pity_rules", "Hatchery rare pity threshold must stay below element soft-pity guarantee.")


func _validate_element_totals_match_rarities(
		element_weight_totals_by_rarity: Dictionary,
		result: HatcheryPullTableValidationResult
) -> void:
	for rarity_weight in rarity_weights:
		if rarity_weight == null or rarity_weight.rarity_id == &"":
			continue
		var element_total: int = int(element_weight_totals_by_rarity.get(rarity_weight.rarity_id, 0))
		if element_total == rarity_weight.weight_basis_points:
			continue
		result.add_field_error(
			"element_weights",
			"Hatchery element weights for rarity '%s' total %d but rarity weight is %d." %
			[rarity_weight.rarity_id, element_total, rarity_weight.weight_basis_points]
		)


func _make_rarity_weight(rarity_id: StringName, weight_basis_points: int, xp_multiplier: int) -> HatcheryRarityWeight:
	var weight: HatcheryRarityWeight = HatcheryRarityWeightResource.new()
	weight.rarity_id = rarity_id
	weight.weight_basis_points = weight_basis_points
	weight.xp_multiplier = xp_multiplier
	return weight


func _make_element_weight(element_id: StringName, rarity_id: StringName, weight_basis_points: int) -> HatcheryElementWeight:
	var weight: HatcheryElementWeight = HatcheryElementWeightResource.new()
	weight.element_id = element_id
	weight.rarity_id = rarity_id
	weight.weight_basis_points = weight_basis_points
	return weight
