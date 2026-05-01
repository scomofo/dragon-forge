extends RefCounted
class_name ActTwoProgressionData

const DragonProgression := preload("res://scripts/sim/dragon_progression.gd")
const ActTwoTundraData := preload("res://scripts/sim/act_two_tundra_data.gd")
const MainframeSpineData := preload("res://scripts/sim/mainframe_spine_data.gd")
const RestorationData := preload("res://scripts/sim/restoration_data.gd")

static func enter_tundra(profile: Dictionary) -> Dictionary:
	var next := DragonProgression.set_mission_flag(profile, "act_two_started")
	next = DragonProgression.grant_key_item(next, "silicon_shards")
	return next

static func shelter_from_white_out(profile: Dictionary, behind_physical_relay: bool) -> Dictionary:
	var result := ActTwoTundraData.evaluate_white_out_purge(0.78, behind_physical_relay, 0.0)
	if not result["safe"]:
		return profile
	var next := DragonProgression.set_mission_flag(profile, "white_out_purge_survived")
	next = DragonProgression.grant_key_item(next, "purge_timing_learned")
	return next

static func meet_unit_01(profile: Dictionary) -> Dictionary:
	var next := DragonProgression.set_mission_flag(profile, "unit_01_met")
	next = DragonProgression.grant_key_item(next, "unit_01_save_link")
	next = DragonProgression.grant_key_item(next, "memory_log_01")
	return next

static func complete_great_buffer(profile: Dictionary) -> Dictionary:
	if not DragonProgression.has_mission_flag(profile, "mirror_admin_tundra_repelled"):
		return profile
	var next := DragonProgression.set_mission_flag(profile, "dungeon_great_buffer_complete")
	next = DragonProgression.grant_key_item(next, "optical_lens")
	next = DragonProgression.grant_key_item(next, "memory_log_02")
	next = DragonProgression.grant_key_item(next, "data_light_exposure")
	next = DragonProgression.unlock_captains_log_fragment(next, {
		"id": "great_buffer",
		"save_flag": "captains_log_great_buffer",
	})
	return next

static func install_frequency_tuner(profile: Dictionary) -> Dictionary:
	if not DragonProgression.has_key_item(profile, "unit_01_save_link") or not DragonProgression.has_key_item(profile, "memory_log_02"):
		return profile
	var next := DragonProgression.grant_key_item(profile, "diagnostic_lens")
	next = DragonProgression.grant_key_item(next, "frequency_tuner")
	next = DragonProgression.set_mission_flag(next, "frequency_tuner_installed")
	return next

static func mutate_prism_stalk(profile: Dictionary) -> Dictionary:
	var exposures := 1 if DragonProgression.has_key_item(profile, "data_light_exposure") else 0
	if DragonProgression.has_key_item(profile, "frequency_tuner"):
		exposures += 2
	var result := ActTwoTundraData.evaluate_prism_mutation(DragonProgression.has_key_item(profile, "optical_lens"), exposures, 0.8)
	if not result["success"]:
		return profile
	var next := DragonProgression.grant_key_item(profile, "prism_stalk_form")
	next = DragonProgression.set_mission_flag(next, "prism_stalk_mutated")
	return next

static func install_insulated_grip(profile: Dictionary) -> Dictionary:
	if not DragonProgression.has_key_item(profile, "unit_01_save_link") or not DragonProgression.has_key_item(profile, "silicon_shards"):
		return profile
	var next := DragonProgression.grant_key_item(profile, "insulated_grip")
	next = DragonProgression.set_mission_flag(next, "insulated_grip_installed")
	return next

static func begin_spine_ascent(profile: Dictionary) -> Dictionary:
	if not DragonProgression.has_key_item(profile, "prism_stalk_form") or not DragonProgression.has_key_item(profile, "insulated_grip"):
		return profile
	var chimney := MainframeSpineData.evaluate_thermal_chimney(0.7, 0.8, 0.2)
	var next := DragonProgression.set_mission_flag(profile, "mainframe_spine_ascent_started")
	if chimney["vent_required"]:
		next = DragonProgression.set_mission_flag(next, "thermal_venting_learned")
	return next

static func complete_logic_core(profile: Dictionary) -> Dictionary:
	var next := DragonProgression.grant_key_item(profile, "external_vents_unlocked")
	next = DragonProgression.set_mission_flag(next, "dungeon_logic_core_complete")
	next = DragonProgression.set_mission_flag(next, "logic_core_vents_unlocked")
	next = DragonProgression.unlock_captains_log_fragment(next, {
		"id": "logic_core",
		"save_flag": "captains_log_logic_core",
	})
	return next

static func bypass_root_sentinel(profile: Dictionary) -> Dictionary:
	if not DragonProgression.has_key_item(profile, "external_vents_unlocked"):
		return profile
	var backup := MainframeSpineData.collect_original_backup(true)
	var next := DragonProgression.set_mission_flag(profile, "root_sentinel_bypassed")
	next = DragonProgression.grant_key_item(next, backup["relic_id"])
	next = DragonProgression.grant_key_item(next, "kernel_blade")
	return next

static func complete_restoration_choice(profile: Dictionary, choice: String) -> Dictionary:
	var relic := _relic_for_choice(choice)
	var result := RestorationData.resolve_restoration_choice(choice, relic)
	if not result["success"]:
		return profile
	var next := DragonProgression.set_mission_flag(profile, "restoration_choice_%s" % choice)
	next = DragonProgression.set_mission_flag(next, "credits_run_complete")
	next = DragonProgression.grant_key_item(next, "read_only_free_roam")
	next["ending_state"] = result
	next["credits_run"] = RestorationData.credits_run_state(choice, 1.0)
	next["postgame_state"] = RestorationData.postgame_state(choice, str(next.get("dragon_id", "fire")))
	next["ending_presentation"] = RestorationData.ending_presentation(choice)
	return next

static func _relic_for_choice(choice: String) -> String:
	match choice:
		RestorationData.CHOICE_TOTAL_RESTORE:
			return "10mm_wrench"
		RestorationData.CHOICE_PATCH:
			return "diagnostic_lens"
		RestorationData.CHOICE_HARDWARE_OVERRIDE:
			return "kernel_blade"
	return ""
