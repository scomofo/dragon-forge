extends RefCounted
class_name ActOneProgressionData

const DragonProgression := preload("res://scripts/sim/dragon_progression.gd")
const ActOneFinaleData := preload("res://scripts/sim/act_one_finale_data.gd")

static func complete_first_flight(profile: Dictionary) -> Dictionary:
	var next := DragonProgression.set_mission_flag(profile, "first_flight_complete")
	next = DragonProgression.grant_key_item(next, "10mm_wrench")
	next = DragonProgression.grant_key_item(next, "root_dragon_bond")
	next = DragonProgression.grant_key_item(next, "diagnostic_ping")
	return next

static func complete_kernel_recovery(profile: Dictionary) -> Dictionary:
	var next := DragonProgression.set_mission_flag(profile, "kernel_recovery_complete")
	next = DragonProgression.set_mission_flag(next, "npc_awakened_glitch_weaver")
	next = DragonProgression.set_mission_flag(next, "magma_core_compiled")
	next = DragonProgression.grant_key_item(next, "heat_shard")
	next = DragonProgression.grant_key_item(next, "silken_data")
	next = DragonProgression.grant_key_item(next, "magma_core_form")
	return next

static func craft_friction_saddle(profile: Dictionary) -> Dictionary:
	if not DragonProgression.has_key_item(profile, "silken_data") or not DragonProgression.has_key_item(profile, "10mm_wrench"):
		return profile
	var next := DragonProgression.grant_key_item(profile, "friction_saddle")
	next = DragonProgression.set_mission_flag(next, "friction_saddle_crafted")
	return next

static func complete_bounty_hunter_chase(profile: Dictionary, evaded_count: int = 3) -> Dictionary:
	if not DragonProgression.has_key_item(profile, "friction_saddle"):
		return profile
	var breakout := ActOneFinaleData.evaluate_breakout_sequence(true, evaded_count, false)
	var requirements: Dictionary = breakout["requirements"]
	if int(requirements.get("hunters_evaded", 0)) < 3:
		return profile
	var next := DragonProgression.set_mission_flag(profile, "bounty_hunters_evaded")
	next = DragonProgression.grant_key_item(next, "hunter_latency_read")
	return next

static func great_breakout_ready(profile: Dictionary) -> Dictionary:
	var missing: Array[String] = []
	for item in ["friction_saddle", "magma_core_form", "10mm_wrench"]:
		if not DragonProgression.has_key_item(profile, item):
			missing.append(item)
	if missing.is_empty() and not DragonProgression.has_mission_flag(profile, "bounty_hunters_evaded"):
		missing.append("bounty_hunters_evaded")
	return {
		"ready": missing.is_empty(),
		"missing": missing,
		"next_action": "bounty_hunter_chase" if missing.has("bounty_hunters_evaded") else "",
		"next_dungeon": "southern_partition_airlock" if missing.is_empty() else "",
	}
