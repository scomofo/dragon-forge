class_name HatcheryPullResolver
extends RefCounted

## Pure Hatchery pull outcome resolver for rarity pity and shiny rolls.

const HatcheryPullResolutionResultResource = preload("res://src/hatchery/hatchery_pull_resolution_result.gd")

const BASIS_POINTS_TOTAL: int = 10000
const RARITY_ORDER: Array[StringName] = [&"Common", &"Uncommon", &"Rare"]


func resolve(
		table_snapshot: HatcheryPullTableSnapshot,
		pity_counter: int,
		rng: HatcheryRngProvider
) -> RefCounted:
	var result := HatcheryPullResolutionResultResource.new()
	if table_snapshot == null:
		result.fail(&"missing_table_snapshot", "Hatchery pull resolver requires a table snapshot.")
		return result
	if rng == null:
		result.fail(&"missing_rng", "Hatchery pull resolver requires an RNG provider.")
		return result

	result.table_snapshot = table_snapshot
	result.pull_id = table_snapshot.pull_id

	result.rarity_roll_basis_point = _next_basis_point(rng)
	result.natural_rarity = _select_rarity(table_snapshot, result.rarity_roll_basis_point)
	if result.natural_rarity == &"":
		result.fail(&"invalid_rarity_table", "Hatchery pull resolver could not select a rarity.")
		return result

	var rare_element_id: StringName = table_snapshot.rare_element_id
	var rare_rarity: StringName = StringName(table_snapshot.element_rarities.get(rare_element_id, &"Rare"))
	var effective_pity_counter: int = max(0, pity_counter)

	if result.natural_rarity == rare_rarity:
		result.natural_element = rare_element_id
		result.final_rarity = result.natural_rarity
		result.final_element = result.natural_element
	elif _should_force_rare(table_snapshot, effective_pity_counter):
		result.pity_forced = true
		result.final_rarity = rare_rarity
		result.final_element = rare_element_id
	else:
		result.element_roll_basis_point = _next_basis_point(rng)
		result.natural_element = _select_element_for_rarity(
			table_snapshot,
			result.natural_rarity,
			result.element_roll_basis_point
		)
		if result.natural_element == &"":
			result.fail(&"invalid_element_table", "Hatchery pull resolver could not select an element.")
			return result
		result.final_rarity = result.natural_rarity
		result.final_element = result.natural_element

	result.shiny_roll_basis_point = _next_basis_point(rng)
	result.shiny = result.shiny_roll_basis_point < table_snapshot.shiny_rate_basis_points
	result.next_pity_counter = 0 if result.final_rarity == rare_rarity else effective_pity_counter + 1
	result.mark_success()
	return result


## Resolves a pull with per-element drought counters and returns the next counter set.
func resolve_with_droughts(
		table_snapshot: HatcheryPullTableSnapshot,
		pity_counter: int,
		drought_counters: Dictionary,
		rng: HatcheryRngProvider
) -> RefCounted:
	var result := HatcheryPullResolutionResultResource.new()
	if table_snapshot == null:
		result.fail(&"missing_table_snapshot", "Hatchery pull resolver requires a table snapshot.")
		return result
	if rng == null:
		result.fail(&"missing_rng", "Hatchery pull resolver requires an RNG provider.")
		return result
	if not _validate_drought_counters(table_snapshot, drought_counters, result):
		return result

	result.table_snapshot = table_snapshot
	result.pull_id = table_snapshot.pull_id

	var effective_drought_counters: Dictionary = _normalized_drought_counters(table_snapshot, drought_counters)
	var rare_element_id: StringName = table_snapshot.rare_element_id
	var rare_rarity: StringName = StringName(table_snapshot.element_rarities.get(rare_element_id, &"Rare"))
	var effective_pity_counter: int = max(0, pity_counter)

	var guaranteed_element_id: StringName = _select_guaranteed_element(table_snapshot, effective_drought_counters)
	if guaranteed_element_id != &"":
		result.element_soft_pity_forced = true
		result.element_soft_pity_element = guaranteed_element_id
		result.final_element = guaranteed_element_id
		result.final_rarity = StringName(table_snapshot.element_rarities.get(guaranteed_element_id, &""))
	else:
		result.rarity_roll_basis_point = _next_basis_point(rng)
		result.natural_rarity = _select_rarity(table_snapshot, result.rarity_roll_basis_point)
		if result.natural_rarity == &"":
			result.fail(&"invalid_rarity_table", "Hatchery pull resolver could not select a rarity.")
			return result
		if result.natural_rarity == rare_rarity:
			result.natural_element = rare_element_id
			result.final_rarity = result.natural_rarity
			result.final_element = result.natural_element
		elif _should_force_rare(table_snapshot, effective_pity_counter):
			result.pity_forced = true
			result.final_rarity = rare_rarity
			result.final_element = rare_element_id
		else:
			result.element_soft_pity_ramped = _has_active_ramp(table_snapshot, effective_drought_counters)
			result.element_roll_basis_point = _next_basis_point(rng)
			result.natural_element = _select_ramped_element(
				table_snapshot,
				effective_drought_counters,
				result.element_roll_basis_point
			)
			if result.natural_element == &"":
				result.fail(&"invalid_element_table", "Hatchery pull resolver could not select a ramp-adjusted element.")
				return result
			result.natural_rarity = StringName(table_snapshot.element_rarities.get(result.natural_element, &""))
			result.final_rarity = result.natural_rarity
			result.final_element = result.natural_element

	if result.final_element == &"" or result.final_rarity == &"":
		result.fail(&"invalid_element_table", "Hatchery pull resolver could not resolve a final element rarity.")
		return result

	result.shiny_roll_basis_point = _next_basis_point(rng)
	result.shiny = result.shiny_roll_basis_point < table_snapshot.shiny_rate_basis_points
	result.next_pity_counter = 0 if result.final_rarity == rare_rarity else effective_pity_counter + 1
	result.next_drought_counters = _next_drought_counters(
		table_snapshot,
		effective_drought_counters,
		result.final_element
	)
	result.mark_success()
	return result


func _should_force_rare(table_snapshot: HatcheryPullTableSnapshot, pity_counter: int) -> bool:
	return pity_counter >= table_snapshot.rare_pity_threshold - 1


func _select_rarity(table_snapshot: HatcheryPullTableSnapshot, roll_basis_point: int) -> StringName:
	var cumulative: int = 0
	var fallback: StringName = &""
	for rarity_id in _ordered_rarity_ids(table_snapshot):
		var weight: int = int(table_snapshot.rarity_weights.get(rarity_id, 0))
		if weight <= 0:
			continue
		fallback = rarity_id
		cumulative += weight
		if roll_basis_point < cumulative:
			return rarity_id
	return fallback


func _select_element_for_rarity(
		table_snapshot: HatcheryPullTableSnapshot,
		rarity_id: StringName,
		roll_basis_point: int
) -> StringName:
	var total_weight: int = _element_weight_total_for_rarity(table_snapshot, rarity_id)
	if total_weight <= 0:
		return &""

	var scaled_roll: int = int(floor((float(roll_basis_point) / float(BASIS_POINTS_TOTAL)) * float(total_weight)))
	var cumulative: int = 0
	var fallback: StringName = &""
	for element_id in table_snapshot.required_element_ids:
		if table_snapshot.element_rarities.get(element_id, &"") != rarity_id:
			continue
		var weight: int = int(table_snapshot.element_weights.get(element_id, 0))
		if weight <= 0:
			continue
		fallback = element_id
		cumulative += weight
		if scaled_roll < cumulative:
			return element_id
	return fallback


func _element_weight_total_for_rarity(table_snapshot: HatcheryPullTableSnapshot, rarity_id: StringName) -> int:
	var total: int = 0
	for element_id in table_snapshot.required_element_ids:
		if table_snapshot.element_rarities.get(element_id, &"") != rarity_id:
			continue
		total += int(table_snapshot.element_weights.get(element_id, 0))
	return total


func _validate_drought_counters(
		table_snapshot: HatcheryPullTableSnapshot,
		drought_counters: Dictionary,
		result: RefCounted
) -> bool:
	for element_id in table_snapshot.required_element_ids:
		if not drought_counters.has(element_id):
			result.fail(
				&"missing_drought_counter",
				"Hatchery pull resolver requires drought counter for '%s'." % element_id
			)
			return false
	return true


func _normalized_drought_counters(
		table_snapshot: HatcheryPullTableSnapshot,
		drought_counters: Dictionary
) -> Dictionary:
	var normalized: Dictionary = {}
	for element_id in table_snapshot.required_element_ids:
		normalized[element_id] = max(0, int(drought_counters.get(element_id, 0)))
	return normalized


func _select_guaranteed_element(
		table_snapshot: HatcheryPullTableSnapshot,
		drought_counters: Dictionary
) -> StringName:
	var highest_counter: int = table_snapshot.element_soft_pity_guaranteed - 1
	var candidates: Array[StringName] = []
	for element_id in table_snapshot.required_element_ids:
		var counter: int = int(drought_counters.get(element_id, 0))
		if counter < table_snapshot.element_soft_pity_guaranteed:
			continue
		if counter > highest_counter:
			candidates.clear()
			highest_counter = counter
		if counter == highest_counter:
			candidates.append(element_id)
	if candidates.is_empty():
		return &""

	for element_id in _tie_break_priority(table_snapshot):
		if candidates.has(element_id):
			return element_id
	return candidates[0]


func _select_ramped_element(
		table_snapshot: HatcheryPullTableSnapshot,
		drought_counters: Dictionary,
		roll_basis_point: int
) -> StringName:
	var effective_weights: Dictionary = _ramped_element_weights(table_snapshot, drought_counters)
	var total_effective_weight: float = 0.0
	for element_id in table_snapshot.required_element_ids:
		total_effective_weight += float(effective_weights.get(element_id, 0.0))
	if total_effective_weight <= 0.0:
		return &""

	var target: float = (float(roll_basis_point) / float(BASIS_POINTS_TOTAL)) * total_effective_weight
	var cumulative: float = 0.0
	var fallback: StringName = &""
	for element_id in table_snapshot.required_element_ids:
		var effective_weight: float = float(effective_weights.get(element_id, 0.0))
		if effective_weight <= 0.0:
			continue
		fallback = element_id
		cumulative += effective_weight
		if target < cumulative:
			return element_id
	return fallback


func _ramped_element_weights(
		table_snapshot: HatcheryPullTableSnapshot,
		drought_counters: Dictionary
) -> Dictionary:
	var effective_weights: Dictionary = {}
	var ramp_range: int = table_snapshot.element_soft_pity_guaranteed - table_snapshot.element_soft_pity_onset
	for element_id in table_snapshot.required_element_ids:
		var base_weight: float = float(table_snapshot.element_weights.get(element_id, 0))
		var effective_weight: float = base_weight
		var drought_count: int = int(drought_counters.get(element_id, 0))
		if ramp_range > 0 and drought_count >= table_snapshot.element_soft_pity_onset:
			var step: int = min(drought_count, table_snapshot.element_soft_pity_guaranteed - 1) - table_snapshot.element_soft_pity_onset
			var ramp_fraction: float = float(max(0, step)) / float(ramp_range)
			effective_weight += ramp_fraction * (float(BASIS_POINTS_TOTAL) - base_weight)
		effective_weights[element_id] = effective_weight
	return effective_weights


func _has_active_ramp(
		table_snapshot: HatcheryPullTableSnapshot,
		drought_counters: Dictionary
) -> bool:
	for element_id in table_snapshot.required_element_ids:
		var drought_count: int = int(drought_counters.get(element_id, 0))
		if drought_count >= table_snapshot.element_soft_pity_onset and drought_count < table_snapshot.element_soft_pity_guaranteed:
			return true
	return false


func _next_drought_counters(
		table_snapshot: HatcheryPullTableSnapshot,
		drought_counters: Dictionary,
		final_element: StringName
) -> Dictionary:
	var next_counters: Dictionary = {}
	for element_id in table_snapshot.required_element_ids:
		if element_id == final_element:
			next_counters[element_id] = 0
		else:
			next_counters[element_id] = int(drought_counters.get(element_id, 0)) + 1
	return next_counters


func _tie_break_priority(table_snapshot: HatcheryPullTableSnapshot) -> Array[StringName]:
	if not table_snapshot.tie_break_priority.is_empty():
		return table_snapshot.tie_break_priority
	return table_snapshot.required_element_ids


func _ordered_rarity_ids(table_snapshot: HatcheryPullTableSnapshot) -> Array[StringName]:
	var ordered: Array[StringName] = []
	for rarity_id in RARITY_ORDER:
		if table_snapshot.rarity_weights.has(rarity_id):
			ordered.append(rarity_id)
	for rarity_id in table_snapshot.rarity_weights.keys():
		var typed_rarity_id := StringName(rarity_id)
		if not ordered.has(typed_rarity_id):
			ordered.append(typed_rarity_id)
	return ordered


func _next_basis_point(rng: HatcheryRngProvider) -> int:
	return clampi(int(floor(rng.next_float() * float(BASIS_POINTS_TOTAL))), 0, BASIS_POINTS_TOTAL - 1)
