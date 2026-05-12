extends RefCounted
class_name BattleVfxData

const ATTACK_PROFILES := {
	"magma": {
		"anticipation_tint": Color("#ff4e24", 0.20),
		"impact_flash": Color("#ffd166", 0.28),
		"shake_amount": 10.0,
		"shake_duration": 0.26,
		"afterimage_count": 4,
		"residual_particles": "embers",
		"screen_distortion": "heat_bloom",
		"ground_crack_count": 0,
		"strip_path": "res://assets/vfx/generated/magma_core_bloom_strip.png",
		"burst_kind": "magma",
	},
	"shockwave": {
		"anticipation_tint": Color("#f7e7b0", 0.18),
		"impact_flash": Color("#ffffff", 0.24),
		"shake_amount": 13.0,
		"shake_duration": 0.30,
		"afterimage_count": 2,
		"residual_particles": "stone_sparks",
		"screen_distortion": "radial_ripple",
		"ground_crack_count": 4,
		"strip_path": "res://assets/vfx/generated/quake_shockwave_strip.png",
		"burst_kind": "shockwave",
	},
	"slash": {
		"anticipation_tint": Color("#9bd4ff", 0.13),
		"impact_flash": Color("#f8de9a", 0.20),
		"shake_amount": 7.0,
		"shake_duration": 0.18,
		"afterimage_count": 3,
		"residual_particles": "arc_sparks",
		"screen_distortion": "slice_shear",
		"ground_crack_count": 0,
		"strip_path": "res://assets/vfx/generated/prism_refraction_strip.png",
		"burst_kind": "prism",
	},
}

const GENERATED_STRIPS := {
	"magma_core_bloom": "res://assets/vfx/generated/magma_core_bloom_strip.png",
	"prism_refraction": "res://assets/vfx/generated/prism_refraction_strip.png",
	"thread_impact": "res://assets/vfx/generated/thread_impact_strip.png",
	"ascii_compile": "res://assets/vfx/generated/ascii_compile_strip.png",
}

const INTENT_PROFILES := {
	"attack": {
		"telegraph_tint": Color("#d85f48", 0.18),
		"impact_flash": Color("#ff4a3d", 0.18),
		"chromatic_split": 1.0,
		"residual_particles": "red_warning_bits",
		"shake_amount": 5.0,
	},
	"corrupt": {
		"telegraph_tint": Color("#7d5fa4", 0.24),
		"impact_flash": Color("#b084ff", 0.20),
		"chromatic_split": 2.4,
		"residual_particles": "void_bits",
		"shake_amount": 6.0,
		"strip_path": GENERATED_STRIPS["thread_impact"],
		"burst_kind": "thread",
	},
	"guard": {
		"telegraph_tint": Color("#8fe6ff", 0.14),
		"impact_flash": Color("#9bd4ff", 0.16),
		"chromatic_split": 0.0,
		"residual_particles": "shield_pixels",
		"shake_amount": 0.0,
	},
}

const ARENA_PROFILES := {
	"checksum_flux": {
		"debris_count": 8,
		"palette_jolt": "checksum_orange",
		"scanline_burst": true,
		"ring_pulse": Color("#f0b66c", 0.22),
	},
	"scrap_surge": {
		"debris_count": 14,
		"palette_jolt": "scrap_gold",
		"scanline_burst": true,
		"ring_pulse": Color("#d6d0bc", 0.24),
	},
	"lunar_resonance": {
		"debris_count": 5,
		"palette_jolt": "silver_blue",
		"scanline_burst": false,
		"ring_pulse": Color("#c0c8ff", 0.22),
	},
}

static func get_attack_vfx_profile(vfx_id: String) -> Dictionary:
	var profile: Dictionary = ATTACK_PROFILES.get(vfx_id, ATTACK_PROFILES["slash"])
	var result := profile.duplicate(true)
	result["id"] = vfx_id if ATTACK_PROFILES.has(vfx_id) else "slash"
	return result

static func get_intent_vfx_profile(intent_kind: String) -> Dictionary:
	var profile: Dictionary = INTENT_PROFILES.get(intent_kind, INTENT_PROFILES["attack"])
	var result := profile.duplicate(true)
	result["id"] = intent_kind if INTENT_PROFILES.has(intent_kind) else "attack"
	return result

static func get_arena_vfx_profile(rule_id: String) -> Dictionary:
	var profile: Dictionary = ARENA_PROFILES.get(rule_id, {})
	var result := profile.duplicate(true)
	if not result.is_empty():
		result["id"] = rule_id
	return result

static func get_generated_strip_path(strip_id: String) -> String:
	return str(GENERATED_STRIPS.get(strip_id, ""))

static func get_dungeon_vfx_profile(effect_id: String) -> Dictionary:
	match effect_id:
		"ascii_compile":
			return {
				"id": "ascii_compile",
				"strip_path": GENERATED_STRIPS["ascii_compile"],
				"impact_flash": Color("#70ff8f", 0.24),
				"screen_distortion": "scanline_burst",
				"residual_particles": "code_glyphs",
				"lifetime": 0.72,
			}
		"thread_impact":
			return {
				"id": "thread_impact",
				"strip_path": GENERATED_STRIPS["thread_impact"],
				"impact_flash": Color("#dfffff", 0.22),
				"screen_distortion": "chromatic_glitch",
				"residual_particles": "void_bits",
				"lifetime": 0.66,
			}
	return {}

static func threadfall_overlay_profile(intensity: float) -> Dictionary:
	var level := clampf(intensity, 0.0, 1.0)
	return {
		"glyph_count": int(lerpf(36.0, 92.0, level)),
		"streak_alpha": 0.16 + level * 0.62,
		"streak_speed": 90.0 + level * 280.0,
		"derender_band_alpha": level * 0.34,
		"impact_spark_count": int(lerpf(0.0, 18.0, level)),
		"palette": "silver_white_source",
		"strip_path": GENERATED_STRIPS["thread_impact"],
		"strip_opacity": level * 0.72,
	}
