extends RefCounted
class_name SingularityProgress

const GameData = preload("res://scripts/sim/game_data.gd")

static func is_singularity_complete(save: Dictionary) -> bool:
	return save.get("mission_flags", []).has("singularity_defeated")

static func get_singularity_stage(save: Dictionary) -> int:
	# Browser parity (singularityProgress.js): stage clears to 0 once the
	# Singularity is contained.
	if is_singularity_complete(save):
		return 0

	var owned: Array = save.get("hatchery_state", {}).get("owned_dragons", [])
	var owned_count: int = 0
	for el in GameData.BASE_ELEMENTS:
		if owned.has(el):
			owned_count += 1

	var levels: Dictionary = save.get("dragon_levels", {})
	var has_elder: bool = false
	for did in owned:
		if int(levels.get(did, 1)) >= 50:
			has_elder = true
			break

	var defeated: Dictionary = save.get("bestiary_defeated", {})
	var all_npcs_defeated: bool = true
	for npc_id in GameData.BASE_NPC_IDS:
		if int(defeated.get(npc_id, 0)) <= 0:
			all_npcs_defeated = false
			break

	if all_npcs_defeated: return 5
	if has_elder:         return 4
	if owned_count >= 6:  return 3
	if owned_count >= 4:  return 2
	if owned_count >= 2:  return 1
	return 0

static func is_singularity_unlocked(save: Dictionary) -> bool:
	# Browser parity: unlocked once Protocol Vulture falls (or arc complete).
	if is_singularity_complete(save):
		return true
	return int(save.get("bestiary_defeated", {}).get("protocol_vulture", 0)) > 0
