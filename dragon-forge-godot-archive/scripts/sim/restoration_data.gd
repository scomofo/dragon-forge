extends RefCounted
class_name RestorationData

const CHOICE_TOTAL_RESTORE := "total_restore"
const CHOICE_PATCH := "patch"
const CHOICE_HARDWARE_OVERRIDE := "hardware_override"

const CHOICE_REQUIREMENTS := {
	CHOICE_TOTAL_RESTORE: "10mm_wrench",
	CHOICE_PATCH: "diagnostic_lens",
	CHOICE_HARDWARE_OVERRIDE: "kernel_blade",
}

static func restoration_prompt(progress: float, has_floppy_disk_backup: bool) -> Dictionary:
	var ready := has_floppy_disk_backup and progress >= 0.99
	return {
		"requires_choice": ready,
		"mirror_admin_speaks": ready,
		"progress": clampf(progress, 0.0, 0.99 if ready else 1.0),
		"line": "Restoration will delete unintentional data: Felix, The Weaver, Unit 01, and your dragon." if ready else "",
	}

static func resolve_restoration_choice(choice: String, analog_relic: String) -> Dictionary:
	var required := str(CHOICE_REQUIREMENTS.get(choice, ""))
	var success := required != "" and analog_relic == required
	if not success:
		return {
			"success": false,
			"choice": choice,
			"required_relic": required,
			"result": "ANALOG_RELIC_MISMATCH",
		}

	match choice:
		CHOICE_TOTAL_RESTORE:
			return {
				"success": true,
				"choice": choice,
				"world_state": "sterile_colony_ship",
				"npc_citizenship": "deleted",
				"hardware_stability": 1.0,
				"threadfall_stopped": true,
				"mirror_admin_disabled": false,
				"result": "ORIGINAL_SEED_LOCKED",
			}
		CHOICE_PATCH:
			return {
				"success": true,
				"choice": choice,
				"world_state": "recognized_hybrid",
				"npc_citizenship": "recognized_citizens",
				"hardware_stability": 0.9,
				"threadfall_stopped": true,
				"mirror_admin_disabled": false,
				"result": "FILTERED_RESTORE_APPLIED",
			}
		CHOICE_HARDWARE_OVERRIDE:
			return {
				"success": true,
				"choice": choice,
				"world_state": "free_glitch",
				"npc_citizenship": "self_determined",
				"hardware_stability": 0.55,
				"threadfall_stopped": false,
				"mirror_admin_disabled": true,
				"result": "ORIGINAL_SEED_DESTROYED",
			}

	return {
		"success": false,
		"choice": choice,
		"result": "UNKNOWN_CHOICE",
	}

static func credits_run_state(choice: String, rerender_progress: float) -> Dictionary:
	var progress := clampf(rerender_progress, 0.0, 1.0)
	return {
		"choice": choice,
		"flight_mode": "ZERO_G_ROOT_AUTHORITY",
		"rerender_progress": progress,
		"credits_as_3d_text": true,
		"requires_traction": false,
		"visual_shift": _visual_shift_for_choice(choice),
	}

static func postgame_state(choice: String, final_dragon_form: String) -> Dictionary:
	return {
		"choice": choice,
		"mode": "READ_ONLY_FREE_ROAM",
		"final_dragon_form": final_dragon_form,
		"dragon_scale_overlay": "restored_gold_code",
		"map_revealed": true,
		"glitch_sites_become": "historical_sites",
		"unit_01_role": "achievement_librarian",
	}

static func ending_presentation(choice: String) -> Dictionary:
	var title := _ending_title(choice)
	return {
		"choice": choice,
		"title": title,
		"summary": _ending_summary(choice),
		"felix_line": _felix_line(choice),
		"credits_lines": _credits_lines(choice),
		"map_legend": _map_legend(choice),
		"free_roam_objective": _free_roam_objective(choice),
		"accent_color": _accent_color(choice),
	}

static func revealed_map_labels(choice: String) -> Dictionary:
	match choice:
		CHOICE_TOTAL_RESTORE:
			return {
				"new_landing": "Archived Landing Site",
				"forge_lab": "Maintenance Intake Archive",
				"tundra_of_silicon": "Zero-Fill Record",
				"mainframe_crown": "Restored Crown Drive",
			}
		CHOICE_PATCH:
			return {
				"new_landing": "Historical New Landing",
				"forge_lab": "Felix Historical Workshop",
				"overgrown_buffer": "Control Plaza Historical Site",
				"tundra_of_silicon": "Recognized Silicon Tundra",
				"mainframe_crown": "Mainframe Crown Memorial",
			}
		CHOICE_HARDWARE_OVERRIDE:
			return {
				"new_landing": "Free Landing Commune",
				"forge_lab": "Felix's Open Intake",
				"tundra_of_silicon": "Unstable Free Buffer",
				"mainframe_crown": "Broken Crown Drive",
			}
	return {}

static func create_mirror_reflection(dragon_form: String) -> Dictionary:
	return {
		"name": "Mirror Reflection",
		"form": "player_dragon",
		"dragon_form": dragon_form,
		"mirrors_moves": true,
		"weakness": "logic_paradox",
		"trigger": "choice_regret",
	}

static func evaluate_logic_paradox(move_id: String, has_unorthodox_manual: bool) -> Dictionary:
	var paradox_moves := ["fly_backward_into_collision_glitch", "manual_latch_while_airborne", "buffer_jump_into_wall"]
	var success := has_unorthodox_manual and paradox_moves.has(move_id)
	return {
		"success": success,
		"move_id": move_id,
		"admin_can_replicate": not success,
		"result": "PARITY_BROKEN" if success else "PARITY_MAINTAINED",
	}

static func _visual_shift_for_choice(choice: String) -> String:
	match choice:
		CHOICE_TOTAL_RESTORE:
			return "cold_colony_ship_render"
		CHOICE_PATCH:
			return "hybrid_high_fidelity_paintover"
		CHOICE_HARDWARE_OVERRIDE:
			return "free_glitch_stabilized_by_community"
	return "unknown"

static func _ending_title(choice: String) -> String:
	match choice:
		CHOICE_TOTAL_RESTORE:
			return "Total Restore"
		CHOICE_PATCH:
			return "The Patch"
		CHOICE_HARDWARE_OVERRIDE:
			return "Hardware Override"
	return "Unknown Ending"

static func _ending_summary(choice: String) -> String:
	match choice:
		CHOICE_TOTAL_RESTORE:
			return "The Original Seed locks into place. The Astraeus stabilizes, but the post-crash citizens are removed from active memory."
		CHOICE_PATCH:
			return "The Diagnostic Lens filters the restore. The Husk repairs itself while Felix, the Weaver, Unit 01, and the dragons become recognized citizens."
		CHOICE_HARDWARE_OVERRIDE:
			return "The Kernel Blade shatters the drive. The Mirror Admin goes silent, Thread still falls, and the glitched world chooses its own unstable freedom."
	return "The restoration result is unreadable."

static func _felix_line(choice: String) -> String:
	match choice:
		CHOICE_TOTAL_RESTORE:
			return "Felix: The fans are steady. I just wish I could hear the village."
		CHOICE_PATCH:
			return "Felix: No more false sky, Skye. Just a world that finally knows what it is."
		CHOICE_HARDWARE_OVERRIDE:
			return "Felix: That was not in the manual. Which is probably why it worked."
	return "Felix: The signal is strange, but it is holding."

static func _credits_lines(choice: String) -> Array[String]:
	match choice:
		CHOICE_TOTAL_RESTORE:
			return [
				"POST: Dragon Registry archived",
				"OS LOAD: Colony protocol restored",
				"MAP: Historical records sealed",
			]
		CHOICE_PATCH:
			return [
				"POST: Dragon Registry verified",
				"OS LOAD: Hybrid render stabilized",
				"MAP: Historical Sites unlocked",
			]
		CHOICE_HARDWARE_OVERRIDE:
			return [
				"POST: Mirror Admin disabled",
				"OS LOAD: Free glitch state accepted",
				"MAP: Unstable Historical Sites unlocked",
			]
	return ["POST: Unknown ending state"]

static func _map_legend(choice: String) -> String:
	match choice:
		CHOICE_TOTAL_RESTORE:
			return "VERIFIED archives mark what used to be villages."
		CHOICE_PATCH:
			return "VERIFIED tickets become Historical Sites across the revealed map."
		CHOICE_HARDWARE_OVERRIDE:
			return "OPEN tickets remain as living repairs for the free glitch world."
	return "No stable map legend available."

static func _free_roam_objective(choice: String) -> String:
	match choice:
		CHOICE_TOTAL_RESTORE:
			return "Read the sealed Historical Sites and recover what the restore erased."
		CHOICE_PATCH:
			return "Fly Read-Only Free-Roam, visit Historical Sites, and finish any VERIFIED service tickets."
		CHOICE_HARDWARE_OVERRIDE:
			return "Stabilize the remaining Historical Sites before the free glitch world shakes itself apart."
	return "Explore the revealed map."

static func _accent_color(choice: String) -> Color:
	match choice:
		CHOICE_TOTAL_RESTORE:
			return Color("#d8e7ff")
		CHOICE_PATCH:
			return Color("#ffd56b")
		CHOICE_HARDWARE_OVERRIDE:
			return Color("#ff6b9a")
	return Color("#ffffff")
