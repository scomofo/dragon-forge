extends RefCounted
class_name SaveHelper

static func get_inventory(save: Dictionary) -> Dictionary:
	return save.get("inventory", {})

static func add_inventory_item(save: Dictionary, item_id: String, qty: int = 1) -> void:
	if not save.has("inventory"):
		save["inventory"] = {}
	save["inventory"][item_id] = int(save["inventory"].get(item_id, 0)) + qty

static func get_inventory_count(save: Dictionary, item_id: String) -> int:
	return int(save.get("inventory", {}).get(item_id, 0))

static func remove_inventory_item(save: Dictionary, item_id: String, qty: int = 1) -> bool:
	var current: int = get_inventory_count(save, item_id)
	if current < qty:
		return false
	if not save.has("inventory"):
		return false
	save["inventory"][item_id] = current - qty
	return true

static func get_stat(save: Dictionary, stat: String) -> int:
	return int(save.get("stats", {}).get(stat, 0))

static func increment_stat(save: Dictionary, stat: String, amount: int = 1) -> void:
	if not save.has("stats"):
		save["stats"] = {}
	save["stats"][stat] = int(save["stats"].get(stat, 0)) + amount

static func is_milestone_claimed(save: Dictionary, milestone_id: String) -> bool:
	return save.get("journal", {}).get("claimedMilestones", []).has(milestone_id)

static func claim_milestone(save: Dictionary, milestone_id: String) -> void:
	if not save.has("journal"):
		save["journal"] = {"claimedMilestones": []}
	if not save["journal"].has("claimedMilestones"):
		save["journal"]["claimedMilestones"] = []
	var claimed: Array = save["journal"]["claimedMilestones"]
	if not claimed.has(milestone_id):
		claimed.append(milestone_id)

static func count_battles_won(save: Dictionary) -> int:
	var total := 0
	for count in save.get("bestiary_defeated", {}).values():
		total += int(count)
	return total

static func count_singularity_defeated(save: Dictionary) -> int:
	var flags: Array = save.get("mission_flags", [])
	var count := 0
	for flag in ["singularity_data_corruption_defeated", "singularity_memory_leak_defeated",
			"singularity_stack_overflow_defeated", "singularity_defeated"]:
		if flags.has(flag):
			count += 1
	return count
