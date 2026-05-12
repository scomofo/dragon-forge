extends RefCounted
class_name SingularityProgress

const GameData = preload("res://scripts/sim/game_data.gd")

static func get_singularity_stage(save: Dictionary) -> int:
	if save.get("singularity_complete", false):
		return 3

	var owned_count: int = 0
	for el in GameData.BASE_ELEMENTS:
		if save.get("dragons", {}).get(el, {}).get("owned", false):
			owned_count += 1

	var has_elder: bool = false
	for el in save.get("dragons", {}).keys():
		var d: Dictionary = save["dragons"][el]
		if d.get("owned", false) and d.get("level", 0) >= 50:
			has_elder = true
			break

	var defeated_npcs: Array = save.get("defeated_npcs", [])
	var all_npcs_defeated: bool = true
	for npc_id in GameData.BASE_NPC_IDS:
		if not defeated_npcs.has(npc_id):
			all_npcs_defeated = false
			break

	if all_npcs_defeated: return 5
	if has_elder:         return 4
	if owned_count >= 6:  return 3
	if owned_count >= 4:  return 2
	if owned_count >= 2:  return 1
	return 0

static func is_singularity_unlocked(save: Dictionary) -> bool:
	if save.get("singularity_complete", false):
		return true
	var defeated_npcs: Array = save.get("defeated_npcs", [])
	for npc_id in GameData.BASE_NPC_IDS:
		if not defeated_npcs.has(npc_id):
			return false
	return true
