extends RefCounted
class_name VisualSystemData

const ELEMENT_COLORS := {
	"fire": Color("#ff4e24"),
	"ice": Color("#8fe6ff"),
	"storm": Color("#ffe45e"),
	"stone": Color("#9b998d"),
	"venom": Color("#70d65c"),
	"shadow": Color("#7566a6"),
	"solar": Color("#ffff00"),
	"lunar": Color("#c0c0c0"),
	"static": Color("#00ffff"),
	"forest": Color("#00ff00"),
}

const ASSET_MANIFEST := {
	"vfx_thread_fall": {
		"type": "overlay",
		"description": "Falling 16-bit characters and silver-white execution-thread streaks.",
	},
	"mat_husk_aluminum": {
		"type": "material",
		"description": "Brushed real-world aluminum for the Hardware Husk server rack.",
	},
	"ui_midi_spectrogram": {
		"type": "hud",
		"description": "Waveform visualizer for Handshake, Lunar Echo, and Kernel Panic.",
	},
	"env_packet_fog": {
		"type": "environment",
		"description": "Pixel-dithered fog for packet loss and unrendered space.",
	},
	"shader_thread_derender": {
		"type": "shader",
		"path": "res://assets/shaders/thread_derender.gdshader",
		"description": "Texture fidelity collapse into neon source-code stripes.",
	},
}

const ROOT_PARTITIONS := {
	"sector_0_0": {
		"label": "The Hub",
		"render_style": "High Fidelity",
		"hazard": "None",
	},
	"sector_0_-1": {
		"label": "The Southern Jungle",
		"render_style": "16-Bit Legacy",
		"hazard": "Thread Precipitation",
	},
	"sector_-1_0": {
		"label": "The Great Salt Flats",
		"render_style": "Low-Poly Empty Cache",
		"hazard": "Frame Rate Drops",
	},
	"sector_1_0": {
		"label": "The Archives",
		"render_style": "Wireframe",
		"hazard": "Data Corruption",
	},
}

static func dragon_element_color(dragon_id: String) -> Color:
	if dragon_id == "fire":
		return ELEMENT_COLORS["fire"]
	if dragon_id == "shadow":
		return ELEMENT_COLORS["shadow"]
	return ELEMENT_COLORS.get(dragon_id, Color("#f4ead2"))

static func diagnostic_lens_readout(target: Dictionary, seen_count: int = 0, defeated_count: int = 0) -> Array[String]:
	var lines: Array[String] = []
	lines.append("Diagnostic Lens")
	lines.append("Target: %s" % target.get("name", target.get("label", "Unknown Entity")))
	if target.has("level"):
		lines.append("Level: %d" % int(target["level"]))
	if target.has("stats") and target["stats"].has("hp"):
		lines.append("HP: %d" % int(target["stats"]["hp"]))
	lines.append("Code Integrity: %d percent" % int(target.get("code_integrity", target.get("integrity", 100))))
	if target.has("surface"):
		lines.append("Surface Grade: %.1f / 10" % float(target["surface"]))
	if target.has("average"):
		lines.append("Condition Rating: %.1f / 10" % float(target["average"]))
	lines.append("Memory Address: 0x%08X" % _stable_memory_address(target.get("id", target.get("name", "unknown"))))
	if seen_count > 0 or defeated_count > 0:
		lines.append("Seen: %d | Defeated: %d" % [seen_count, defeated_count])
	return lines

static func thread_impact(target: Dictionary, corruption_delta: float = 0.18) -> Dictionary:
	var next := target.duplicate(true)
	var texture_fidelity := clampf(float(next.get("texture_fidelity", 1.0)) - corruption_delta, 0.0, 1.0)
	var code_integrity := clampf(float(next.get("code_integrity", 1.0)) - corruption_delta * 0.75, 0.0, 1.0)
	next["texture_fidelity"] = texture_fidelity
	next["code_integrity"] = code_integrity
	next["render_state"] = "wireframe" if texture_fidelity <= 0.45 else "degraded"
	next["null_pointer_risk"] = texture_fidelity <= 0.2
	return next

static func threadfall_intensity(tile: Dictionary, profile: Dictionary, mission_state: Dictionary) -> float:
	var tile_id: String = tile.get("id", "")
	var intensity := 0.0
	if tile_id == "skybox_leak":
		intensity = 0.95
	elif tile_id == "new_landing" and _has_flag(profile, "stable_connection") and not _has_flag(profile, "mission_11_complete"):
		intensity = 0.72
	elif tile_id == "vault_first_rack" and _has_flag(profile, "mission_09_complete") and not _has_flag(profile, "stable_connection"):
		intensity = 0.42
	elif tile.get("hazard", "").contains("Sky") or tile.get("hazard", "").contains("Void"):
		intensity = 0.36
	var admin: Dictionary = mission_state.get("admin", {})
	var load_pressure := clampf((1.0 - float(admin.get("sector_integrity", 0.85))) * 1.35, 0.0, 0.35)
	return clampf(intensity + load_pressure, 0.0, 1.0)

static func sector_status(tile_position: Vector2i, husk_position: Vector2i, thread_intensity: float = 0.0) -> String:
	if thread_intensity >= 0.7:
		return "CRITICAL"
	var distance := Vector2(tile_position - husk_position).length()
	if distance > 20.0:
		return "FRAGMENTED"
	if distance > 12.0:
		return "DEGRADED"
	return "STABLE"

static func sector_stability(tile_position: Vector2i, husk_position: Vector2i, thread_intensity: float = 0.0) -> float:
	var distance := Vector2(tile_position - husk_position).length()
	var distance_loss := clampf(distance / 34.0, 0.0, 0.72)
	var thread_loss := clampf(thread_intensity * 0.55, 0.0, 0.55)
	return clampf(1.0 - distance_loss - thread_loss, 0.05, 1.0)

static func integrity_fog_state(code_integrity: float) -> Dictionary:
	var integrity := clampf(code_integrity, 0.0, 1.0)
	if integrity >= 0.72:
		return {
			"visual_state": "High Fidelity",
			"meaning": "Stable Code",
			"traction": 1.0,
			"input_lag": 0.0,
			"thread_damage_per_second": 0.0,
			"render_filter": "pastoral_clear",
		}
	if integrity >= 0.28:
		return {
			"visual_state": "Dithered/Grainy",
			"meaning": "Minor Corruption",
			"traction": lerpf(0.62, 0.9, integrity),
			"input_lag": lerpf(0.18, 0.04, integrity),
			"thread_damage_per_second": 0.0,
			"render_filter": "pixel_dither",
		}
	return {
		"visual_state": "Wireframe/Red",
		"meaning": "Critical Error",
		"traction": 0.48,
		"input_lag": 0.24,
		"thread_damage_per_second": lerpf(0.08, 0.32, 1.0 - integrity),
		"render_filter": "red_wireframe",
	}

static func packet_velocity(player_position: Vector2i, target_position: Vector2i) -> float:
	if target_position.x < 0:
		return 0.0
	var distance := Vector2(target_position - player_position).length()
	return clampf(1.0 - distance / 36.0, 0.05, 1.0)

static func mirror_parity_tint(base_color: Color, player_element_color: Color, turn: int) -> Color:
	var pulse := (sin(float(turn) * 0.9) + 1.0) * 0.5
	return base_color.lerp(player_element_color, 0.28 + pulse * 0.22).lightened(0.18)

static func undo_rewind_effect_config() -> Dictionary:
	return {
		"tint": Color("#6bbcff", 0.34),
		"duration": 0.42,
		"scanline_direction": -1,
		"label": "Rollback executed. Parity restored.",
	}

static func _has_flag(profile: Dictionary, flag: String) -> bool:
	return profile.get("mission_flags", []).has(flag)

static func _stable_memory_address(value: Variant) -> int:
	var text := str(value)
	var hash := 2166136261
	for index in text.length():
		hash = int((hash ^ text.unicode_at(index)) * 16777619) & 0x7fffffff
	return hash
