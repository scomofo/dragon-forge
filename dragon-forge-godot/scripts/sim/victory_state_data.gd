extends RefCounted
class_name VictoryStateData

const PATCH_PENDING := "PATCH_PENDING"
const MANUAL_OVERRIDE_PROMPT := "MANUAL_OVERRIDE_PROMPT"
const DELETION_ENDING := "DELETION_ENDING"
const STABLE_HYBRID := "STABLE_HYBRID"

static func evaluate_hard_reset_interrupt(packet_integrity: float, has_manual_override: bool) -> Dictionary:
	if packet_integrity > 0.05:
		return {
			"state": PATCH_PENDING,
			"prompt": "",
			"collapse_target": 0.0,
		}
	if has_manual_override:
		return {
			"state": MANUAL_OVERRIDE_PROMPT,
			"prompt": "PRESS [E] TO OVERRIDE SYSTEM RESET",
			"collapse_target": 0.5,
		}
	return {
		"state": DELETION_ENDING,
		"prompt": "",
		"collapse_target": 1.0,
	}

static func apply_patch_state(profile: Dictionary) -> Dictionary:
	var next := profile.duplicate(true)
	var flags: Array = next.get("mission_flags", [])
	for flag in ["stable_hybrid_render", "mirror_admin_familiar", "hard_reset_jammed"]:
		if not flags.has(flag):
			flags.append(flag)
	next["mission_flags"] = flags
	return next

static func service_ticket_label(is_resolved: bool) -> String:
	return "VERIFIED" if is_resolved else "UNRESOLVED"

static func hybrid_render_palette() -> Dictionary:
	return {
		"terrain_style": "hand_painted_circuitry",
		"tree_bark": "organic_with_embedded_traces",
		"dragon_scales": "painted_scales_with_luma_paths",
		"glitch_role": "scar_not_failure",
	}

static func end_credits_map_state(completed_ticket_count: int, total_ticket_count: int) -> Dictionary:
	return {
		"schematic_unfolded": true,
		"free_roam_enabled": true,
		"verified_tickets": completed_ticket_count,
		"total_tickets": total_ticket_count,
		"completion_ratio": 1.0 if total_ticket_count <= 0 else float(completed_ticket_count) / float(total_ticket_count),
	}
