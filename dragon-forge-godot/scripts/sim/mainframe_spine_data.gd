extends RefCounted
class_name MainframeSpineData

const TIERS := {
	"cooling_base": {
		"name": "Cooling Base",
		"aesthetic": "industrial_pipes",
		"mechanic": "spinning_fan_blades",
		"height_range": Vector2(0.0, 0.33),
		"description": "Giant fans, pipes, and exhaust ports turn the tower base into a physical obstacle climb.",
	},
	"logic_core": {
		"name": "Logic Core",
		"aesthetic": "glass_glowing_circuits",
		"mechanic": "laser_reroute",
		"height_range": Vector2(0.34, 0.66),
		"description": "Security lasers do not damage first; they rewrite Skye's trajectory into bad routes.",
	},
	"legacy_peak": {
		"name": "Legacy Peak",
		"aesthetic": "ascii_low_poly",
		"mechanic": "unpredictable_collision",
		"height_range": Vector2(0.67, 1.0),
		"description": "The tower becomes blocky, old, and under-specified. Collision lies.",
	},
}

static func evaluate_thermal_chimney(port_pressure: float, dragon_heat: float, altitude_ratio: float) -> Dictionary:
	var pressure := clampf(port_pressure, 0.0, 1.0)
	var heat := clampf(dragon_heat, 0.0, 1.0)
	var altitude := clampf(altitude_ratio, 0.0, 1.0)
	var density_penalty := altitude * 0.35
	var boost := maxf(0.0, pressure * 0.75 + heat * 0.45 - density_penalty)
	return {
		"boost": boost,
		"vent_required": heat > 0.65 or boost > 0.75,
		"pressure_state": "OVERPRESSURE" if pressure > 0.8 else "USABLE",
	}

static func evaluate_gravity_well(altitude_ratio: float, momentum: float, flap_intensity: float) -> Dictionary:
	var gravity := 1.0 + clampf(altitude_ratio, 0.0, 1.0) * 1.4
	var lift_signal := clampf(momentum, 0.0, 1.0) * 0.6 + clampf(flap_intensity, 0.0, 1.0) * 0.5
	var drop_risk := lift_signal < gravity * 0.35
	return {
		"gravity_constant": gravity,
		"drop_risk": drop_risk,
		"fall_velocity": (gravity - lift_signal) * 12.0 if drop_risk else 0.0,
	}

static func get_tier(id: String) -> Dictionary:
	return TIERS.get(id, {}).duplicate(true)

static func tier_for_height(height_ratio: float) -> Dictionary:
	var height := clampf(height_ratio, 0.0, 1.0)
	for tier_id in TIERS:
		var tier: Dictionary = TIERS[tier_id]
		var range: Vector2 = tier["height_range"]
		if height >= range.x and height <= range.y:
			var result := tier.duplicate(true)
			result["id"] = tier_id
			return result
	return get_tier("legacy_peak")

static func apply_logic_core_laser(position: Vector3, touched_laser: bool) -> Dictionary:
	if not touched_laser:
		return {
			"rerouted": false,
			"position": position,
		}
	return {
		"rerouted": true,
		"position": position + Vector3(0.0, -3.0, 5.0),
		"route_error": "SECURITY_VECTOR_REWRITE",
	}

static func evaluate_legacy_collision(velocity: Vector3, ascii_noise: float) -> Dictionary:
	var noise := clampf(ascii_noise, 0.0, 1.0)
	return {
		"unpredictable_collision": noise > 0.55 and velocity.length() > 0.5,
		"collision_snap": Vector3(roundf(velocity.x), roundf(velocity.y), roundf(velocity.z)),
		"render_style": "ASCII_LOW_POLY",
	}

static func vertical_camera_settings(altitude_ratio: float, speed_ratio: float) -> Dictionary:
	var altitude := clampf(altitude_ratio, 0.0, 1.0)
	var speed := clampf(speed_ratio, 0.0, 1.0)
	return {
		"vertical_lead": 8.0 + altitude * 10.0,
		"spring_length": 14.0 + speed * 8.0,
		"fov": 70.0 + speed * 8.0,
		"show_scale_reference": altitude > 0.15,
	}

static func create_root_sentinel() -> Dictionary:
	return {
		"name": "Root Sentinel",
		"render_style": "green_ascii",
		"phase": "SYNTAX_RAIN",
		"weak_point": "closing_bracket",
		"closing_bracket": "}",
		"inventory_comment_duration": 10.0,
		"core_exposed": false,
		"line_count": 4,
		"defensive_subroutines": ["delete_guard", "comment_beam", "bolt_bracket"],
		"glyph": "ROOT_SENTINEL",
	}

static func comment_out_inventory_item(items: Array, target_item: String) -> Dictionary:
	var disabled := {}
	for item in items:
		if str(item) == target_item:
			disabled[str(item)] = 10.0
	return {
		"disabled_items": disabled,
		"status": "COMMENTED_OUT" if disabled.has(target_item) else "NO_TARGET",
	}

static func compile_bracket_bridge(open_string: String, closing_glyph: String, tool_id: String) -> Dictionary:
	var has_open := open_string.begins_with("[")
	var has_close := closing_glyph == "]"
	var bolted := tool_id == "10mm_wrench"
	var solid := has_open and has_close and bolted
	return {
		"solid": solid,
		"compiled_string": "%s%s" % [open_string, closing_glyph] if solid else open_string,
		"status": "COMPILED" if solid else "MISSING_CLOSING_BRACKET",
		"requires_tool": "10mm_wrench",
	}

static func flip_boolean_gate(variable_name: String, locked: bool, tool_id: String) -> Dictionary:
	var can_flip := tool_id == "10mm_wrench"
	var next_locked := false if can_flip else locked
	return {
		"open": not next_locked,
		"expression": "%s = %s" % [variable_name, "TRUE" if next_locked else "FALSE"],
		"status": "GATE_DERENDERED" if not next_locked else "LOCK_STILL_TRUE",
		"requires_tool": "10mm_wrench",
	}

static func comment_out_security_beam(source_id: String, aegis_active: bool, armor_id: String) -> Dictionary:
	var cloaked := aegis_active and armor_id == "ASCII_AEGIS"
	return {
		"damaging": not cloaked,
		"source": "//%s" % source_id if cloaked else source_id,
		"status": "COMMENTED_OUT" if cloaked else "BEAM_ACTIVE",
		"requires_armor": "ASCII_AEGIS",
	}

static func damage_root_sentinel_line_count(sentinel: Dictionary, deleted_subroutines: Array) -> Dictionary:
	var result := sentinel.duplicate(true)
	var total_lines := int(result.get("line_count", 4))
	var routines: Array = result.get("defensive_subroutines", [])
	var removed := 0
	for routine in routines:
		if deleted_subroutines.has(routine):
			removed += 1
	var remaining := maxi(1, total_lines - removed)
	result["line_count"] = remaining
	result["glyph"] = "." if remaining == 1 else "ROOT_SENTINEL_%d_LINES" % remaining
	result["defeated"] = remaining == 1
	result["phase"] = "PERIOD_REMAINS" if remaining == 1 else "SUBROUTINES_DELETING"
	return result

static func apply_magma_to_closing_bracket(heat: float, bracket_integrity: float) -> Dictionary:
	var remaining := maxf(0.0, bracket_integrity - clampf(heat, 0.0, 1.0))
	return {
		"bracket_integrity": remaining,
		"core_exposed": remaining <= 0.0,
		"result": "CORE_LOGIC_EXPOSED" if remaining <= 0.0 else "BRACKET_SOFTENED",
	}

static func collect_original_backup(sentinel_bypassed: bool) -> Dictionary:
	return {
		"success": sentinel_bypassed,
		"relic_id": "floppy_disk_backup" if sentinel_bypassed else "",
		"restoration_unlocked": sentinel_bypassed,
		"unit_01_line": "That... that is a Backup. If you can get that to the Weaver, we do not just patch the system. We can Restore it." if sentinel_bypassed else "",
	}
