extends RefCounted
class_name WeaverData

const ARMOR_SETS := {
	"obsidian_shell": {
		"name": "Obsidian Shell",
		"required_scavenged_item": "magma_scale",
		"materials": ["magma_scale", "digital_silk", "silicon_shards"],
		"overworld_effect": "thermal_exhaust_stability",
		"side_scrolling_effect": "steam_trap_immunity",
		"description": "A heat-buffered overlay that lets the dragon and Skye ignore unstable exhaust wash.",
	},
	"refractive_plate": {
		"name": "Refractive Plate",
		"required_scavenged_item": "optical_lens",
		"materials": ["optical_lens", "digital_silk", "fragmented_code"],
		"overworld_effect": "stalker_invisibility",
		"side_scrolling_effect": "security_node_reveal",
		"description": "A light-bending overlay for hiding from Sub-routine Stalkers and revealing tripwires.",
	},
	"silicon_padded_gear": {
		"name": "Silicon Padded Gear",
		"required_scavenged_item": "silicon_shards",
		"materials": ["silicon_shards", "raw_silk"],
		"overworld_effect": "static_discharge_resistance",
		"side_scrolling_effect": "input_lag_reduction",
		"description": "Softcode padding that gives bad collision enough physicality to stand on.",
	},
	"friction_harness": {
		"name": "Friction Harness",
		"required_scavenged_item": "10mm_wrench",
		"materials": ["10mm_wrench", "digital_silk", "steel_bolt"],
		"overworld_effect": "high_traction_dives",
		"side_scrolling_effect": "pipe_wall_slide",
		"description": "A saddle-harness overlay for steep dives and vertical pipe grip.",
	},
	"ascii_aegis": {
		"name": "ASCII Aegis",
		"required_scavenged_item": "floppy_disk_backup",
		"materials": ["fragmented_code", "floppy_disk_backup", "digital_silk"],
		"overworld_effect": "firewall_phase_passage",
		"side_scrolling_effect": "double_jump_recompile",
		"description": "A low-poly source-tier overlay that de-compiles and re-compiles Skye mid-air.",
	},
}

static func get_armor_set(armor_id: String) -> Dictionary:
	var armor: Dictionary = ARMOR_SETS.get(armor_id, {})
	var result := armor.duplicate(true)
	if not result.is_empty():
		result["id"] = armor_id
	return result

static func craft_armor_set(materials: Array, armor_id: String) -> Dictionary:
	var armor := get_armor_set(armor_id)
	if armor.is_empty():
		return {
			"success": false,
			"armor_id": armor_id,
			"missing": ["known_recipe"],
		}
	var missing: Array[String] = []
	for material in armor.get("materials", []):
		if not materials.has(material):
			missing.append(str(material))
	var success := missing.is_empty()
	return {
		"success": success,
		"armor_id": armor_id,
		"name": armor.get("name", armor_id),
		"missing": missing,
		"overworld_effect": armor.get("overworld_effect", "") if success else "",
		"side_scrolling_effect": armor.get("side_scrolling_effect", "") if success else "",
		"overlay_state": "COMPILED" if success else "MISSING_MATERIALS",
	}

static func apply_armor_overlay(armor_id: String, state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	match armor_id:
		"obsidian_shell":
			next["thermal_exhaust_safe"] = true
			next["steam_trap_damage"] = 0.0
		"refractive_plate":
			next["stalker_visibility"] = 0.0
			next["security_nodes_visible"] = true
		"silicon_padded_gear":
			next["integrity"] = clampf(float(next.get("integrity", 1.0)) + 0.28, 0.0, 1.0)
			next["input_lag"] = maxf(0.0, float(next.get("input_lag", 0.0)) - 0.16)
			next["slip_on_derendered_tiles"] = false
		"friction_harness":
			next["traction"] = clampf(float(next.get("traction", 0.65)) + 0.32, 0.0, 1.0)
			next["pipe_wall_slide"] = true
		"ascii_aegis":
			next["can_phase_firewalls"] = true
			next["double_jump_recompile"] = true
	next["armor_id"] = armor_id
	return next

static func apply_armor_damage(armor_state: Dictionary, damage: float) -> Dictionary:
	var next := armor_state.duplicate(true)
	var integrity := clampf(float(next.get("integrity", 1.0)) - clampf(damage, 0.0, 1.0), 0.0, 1.0)
	next["integrity"] = integrity
	next["visual_decay"] = integrity < 0.5
	next["texture_state"] = "GRAY_FLICKER" if integrity < 0.5 else "STABLE_TEXTURE"
	next["needs_weaver_patch"] = integrity < 0.35
	return next

static func field_repair_armor(armor_state: Dictionary, tool_id: String, context: Dictionary) -> Dictionary:
	var next := armor_state.duplicate(true)
	var gauge := float(context.get("gauge_value", 0.0))
	var has_bolt := int(context.get("steel_bolts", 0)) > 0
	var in_green := gauge >= 0.44 and gauge <= 0.62
	var success := tool_id == "10mm_wrench" and in_green and has_bolt
	if success:
		next["integrity"] = clampf(float(next.get("integrity", 0.0)) + 0.22, 0.0, 0.78)
		next["texture_state"] = "TEMPORARY_RESEAT"
		next["visual_decay"] = float(next["integrity"]) < 0.5
		next["temporary"] = true
		next["success"] = true
		return next
	next["success"] = false
	next["temporary"] = false
	next["stripped_bolt"] = tool_id == "10mm_wrench" and not in_green
	return next

static func get_armor_vfx_profile(armor_state: Dictionary) -> Dictionary:
	var armor_id := str(armor_state.get("armor_id", ""))
	var integrity := clampf(float(armor_state.get("integrity", 1.0)), 0.0, 1.0)
	var texture_state := str(armor_state.get("texture_state", "STABLE_TEXTURE"))
	var outline := _armor_outline_color(armor_id)
	var screen_effect := "none"
	var flicker_alpha := 0.0
	var afterimage_tint := Color(outline.r, outline.g, outline.b, 0.16)
	if bool(armor_state.get("temporary", false)) or texture_state == "TEMPORARY_RESEAT":
		screen_effect = "scanline_burst"
		outline = Color("#70ff8f")
		flicker_alpha = 0.16
		afterimage_tint = Color("#70ff8f", 0.28)
	elif bool(armor_state.get("visual_decay", false)) or texture_state == "GRAY_FLICKER":
		screen_effect = "chromatic_glitch"
		outline = Color("#9b998d")
		flicker_alpha = lerpf(0.24, 0.58, 1.0 - integrity)
		afterimage_tint = Color("#ff2d55", 0.22)
	elif armor_id != "":
		screen_effect = "scanline_burst"
		flicker_alpha = 0.08
	return {
		"armor_id": armor_id,
		"outline_color": outline,
		"screen_effect": screen_effect,
		"flicker_alpha": flicker_alpha,
		"afterimage_tint": afterimage_tint,
		"integrity": integrity,
	}

static func _armor_outline_color(armor_id: String) -> Color:
	match armor_id:
		"obsidian_shell":
			return Color("#ff7a35")
		"refractive_plate":
			return Color("#58dbff")
		"silicon_padded_gear":
			return Color("#70ff8f")
		"friction_harness":
			return Color("#ffd166")
		"ascii_aegis":
			return Color("#b7fffb")
	return Color("#eaf0e5")
