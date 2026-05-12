extends RefCounted
class_name ActTwoTundraData

const MOBILE_SHOPS := {
	"unit_01": {
		"name": "The Kernel",
		"designation": "Unit 01",
		"role": "mobile_shop_save_point",
		"quest_id": "recover_unit_01_logs",
		"face": "holographic",
		"body": "rusted_analog_plating",
		"line": "Primary Tool detected. I remember that wrench. I do not remember my own name.",
	},
}

const KERNEL_UPGRADES := {
	"insulated_grip": {
		"name": "Insulated Grip",
		"relic_code": "10MM-WRENCH",
		"cost": {
			"silicon_shards": 4,
			"source_shards": 1,
		},
		"safe_live_bolts": true,
		"description": "A ceramic-silicon sleeve that lets the 10mm Wrench turn live data-bolts without shocking Skye.",
	},
	"frequency_tuner": {
		"name": "Frequency Tuner",
		"relic_code": "DIAGNOSTIC-LENS",
		"cost": {
			"silicon_shards": 3,
			"memory_logs": 1,
		},
		"predicts_white_out": true,
		"description": "An upgrade that shows the Mainframe heartbeat and the next cache-purge beat.",
	},
}

const DRONE_STATE_PATROL := "patrol"
const DRONE_STATE_ALERT := "alert"
const DRONE_STATE_FROZEN := "frozen_platform"
const DRONE_FREEZE_SECONDS := 5.0
const DRONE_COLLISION_SENSOR := "drone_sensor"
const DRONE_COLLISION_PLATFORM := "solid_platform"
const WRENCH_OVERCLOCK_COST := 120
const PURGE_SHIELD_COST := 40

const TUNDRA_ENEMIES := {
	"security_drone_type_s": {
		"name": "Seek-and-Destroy Drone Type-S",
		"process_role": "patrol_alarm",
		"hardware_read": "floating_white_glass_eye",
		"counter_tool": "wrench_overclock",
		"platform_seconds": DRONE_FREEZE_SECONDS,
		"description": "A patrol daemon that becomes temporary solid ground when the Wrench Overclock pulses its clock cycle.",
	},
	"bit_rot_stalker": {
		"name": "Bit-Rot Stalker",
		"process_role": "corruption_shadow",
		"hardware_read": "flickering_skye_silhouette",
		"counter_tool": "shielded_port_or_white_out",
		"trail_damage": 0.22,
		"description": "A bad memory echo that leaves static on the floor and scrambles for shelter when a White-Out purge begins.",
	},
}

static func get_tundra_visual_profile() -> Dictionary:
	return {
		"aesthetic": "hardware_gothic",
		"sky_motif": "motherboard_constellations",
		"sky_color": Color("#050708"),
		"trace_color": Color("#54ff8b"),
		"ground_motif": "silicon_dust",
		"ground_color": Color("#edf6ff"),
		"dust_pixel_color": Color("#b7fffb"),
		"structure_motifs": ["rusted_capacitors", "jagged_heat_sinks", "copper_trace_roots"],
		"silhouette_color": Color("#3b312d"),
	}

static func get_cache_vault_visual_profile() -> Dictionary:
	return {
		"aesthetic": "clinical_active_memory",
		"palette": {
			"deep_blue": Color("#071a3f"),
			"cyan": Color("#58dbff"),
			"stark_white": Color("#f8fbff"),
			"hollow_gray": Color("#56616f"),
		},
		"tile_glow": {
			"one": Color("#58dbff"),
			"zero": Color("#56616f"),
		},
		"binary_tiles": {
			"one": Color("#58dbff"),
			"zero": Color("#56616f"),
		},
		"parallax_layers": ["code_rain", "hex_memory_grid", "crt_scanlines"],
		"background_motif": "active_memory_cache_vault",
	}

static func get_cache_vault_parallax_profile() -> Dictionary:
	return {
		"enabled": true,
		"node_type": "ParallaxBackground",
		"layers": [
			{
				"name": "background_void",
				"content": "dark_blue_black_canvas",
				"motion_scale": Vector2.ZERO,
				"motion_mirroring": Vector2(512, 512),
				"speed": 0.0,
				"alpha": 1.0,
				"glyph_size": 0,
			},
			{
				"name": "data_stream",
				"content": "binary_hex_code_rain",
				"motion_scale": Vector2(0.1, 0.1),
				"motion_mirroring": Vector2(512, 512),
				"speed": 28.0,
				"alpha": 0.13,
				"glyph_size": 15,
			},
			{
				"name": "circuitry_midground",
				"content": "glowing_copper_traces",
				"motion_scale": Vector2(0.3, 0.3),
				"motion_mirroring": Vector2(512, 512),
				"speed": 48.0,
				"alpha": 0.18,
				"glyph_size": 18,
			},
		],
		"hex_grid_drift": 9.0,
		"scanline_speed": 36.0,
	}

static func evaluate_white_out_purge(intensity: float, behind_physical_relay: bool, prism_refraction: float) -> Dictionary:
	var clamped_intensity := clampf(intensity, 0.0, 1.0)
	var shelter_factor := 0.22 if behind_physical_relay else 1.0
	var refraction_block := clampf(prism_refraction, 0.0, 1.0) * 0.65
	var texture_damage := maxf(0.0, clamped_intensity * shelter_factor - refraction_block)
	return {
		"screen_state": "WHITEOUT" if clamped_intensity > 0.6 else "HAZE",
		"texture_damage": texture_damage,
		"requires_cover": clamped_intensity > 0.5 and not behind_physical_relay,
		"safe": texture_damage < 0.25,
	}

static func self_thrust_lift(dragon_form: String, heat_level: float, ambient_data_drafts: float) -> Dictionary:
	var heat := clampf(heat_level, 0.0, 1.0)
	var drafts := clampf(ambient_data_drafts, 0.0, 1.0)
	var magma_bonus := 0.55 if dragon_form == "magma_core" else 0.18
	var lift := heat * (0.85 + magma_bonus) + drafts * 0.25
	var energy_cost := heat * (0.35 if dragon_form == "magma_core" else 0.55)
	return {
		"lift": lift,
		"energy_cost": energy_cost,
		"mode": "SELF_THRUST" if drafts < 0.35 else "DATA_DRAFT",
	}

static func get_mobile_shop(id: String) -> Dictionary:
	return MOBILE_SHOPS.get(id, {}).duplicate(true)

static func get_tundra_enemy_profile(enemy_id: String) -> Dictionary:
	var enemy: Dictionary = TUNDRA_ENEMIES.get(enemy_id, {})
	var result := enemy.duplicate(true)
	if not result.is_empty():
		result["id"] = enemy_id
		result["visual_tier"] = "hardware_process_enemy"
	return result

static func evaluate_black_market_overclock(has_unit_01_link: bool, data_scraps: int) -> Dictionary:
	if not has_unit_01_link:
		return {
			"success": false,
			"reason": "UNIT_01_LINK_REQUIRED",
			"cost": WRENCH_OVERCLOCK_COST,
			"remaining_scraps": data_scraps,
			"reward_item": "wrench_overclock",
		}
	if data_scraps < WRENCH_OVERCLOCK_COST:
		return {
			"success": false,
			"reason": "INSUFFICIENT_SCRAPS",
			"cost": WRENCH_OVERCLOCK_COST,
			"remaining_scraps": data_scraps,
			"reward_item": "wrench_overclock",
		}
	return {
		"success": true,
		"reason": "OVERCLOCK_INSTALLED",
		"cost": WRENCH_OVERCLOCK_COST,
		"remaining_scraps": data_scraps - WRENCH_OVERCLOCK_COST,
		"reward_item": "wrench_overclock",
		"dialogue_id": "pulse_overclock_install",
	}

static func evaluate_shard_purge_shield_trade(has_silicon_shards: bool, data_scraps: int) -> Dictionary:
	if not has_silicon_shards:
		return {
			"success": false,
			"reason": "SILICON_SHARDS_REQUIRED",
			"cost": PURGE_SHIELD_COST,
			"remaining_scraps": data_scraps,
			"reward_item": "purge_shield",
		}
	if data_scraps < PURGE_SHIELD_COST:
		return {
			"success": false,
			"reason": "INSUFFICIENT_SCRAPS",
			"cost": PURGE_SHIELD_COST,
			"remaining_scraps": data_scraps,
			"reward_item": "purge_shield",
		}
	return {
		"success": true,
		"reason": "PURGE_SHIELD_TRADED",
		"cost": PURGE_SHIELD_COST,
		"remaining_scraps": data_scraps - PURGE_SHIELD_COST,
		"reward_item": "purge_shield",
		"dialogue_id": "shard_purge_shield_trade",
	}

static func evaluate_prism_mutation(has_optical_lens: bool, data_light_exposures: int, stability: float) -> Dictionary:
	var success := has_optical_lens and data_light_exposures >= 3 and stability >= 0.65
	return {
		"success": success,
		"evolution": "prism_stalk" if success else "",
		"missing": _prism_missing(has_optical_lens, data_light_exposures, stability),
	}

static func refract_white_out_with_prism(intensity: float, has_prism_stalk: bool) -> Dictionary:
	var clamped_intensity := clampf(intensity, 0.0, 1.0)
	var beam_charge := clamped_intensity * 0.9 if has_prism_stalk else 0.0
	return {
		"damage_blocked": has_prism_stalk and clamped_intensity > 0.0,
		"beam_charge": beam_charge,
		"counterattack": "REFRACTED_PURGE_BEAM" if beam_charge >= 0.5 else "",
	}

static func create_security_drone_state(id: String, rect: Rect2, patrol_min_x: float, patrol_max_x: float) -> Dictionary:
	return {
		"id": id,
		"state": DRONE_STATE_PATROL,
		"rect": rect,
		"patrol_min_x": patrol_min_x,
		"patrol_max_x": patrol_max_x,
		"velocity": Vector2(72.0, 0.0),
		"freeze_timer": 0.0,
		"alarm_active": false,
		"is_solid_platform": false,
		"platform_rect": Rect2(),
		"collision_profile": drone_collision_profile(DRONE_COLLISION_SENSOR),
	}

static func drone_collision_profile(profile_id: String) -> Dictionary:
	if profile_id == DRONE_COLLISION_PLATFORM:
		return {
			"layer_name": DRONE_COLLISION_PLATFORM,
			"collision_layer": 1,
			"collision_mask": 1,
			"standable": true,
			"detects_skye": false,
		}
	return {
		"layer_name": DRONE_COLLISION_SENSOR,
		"collision_layer": 8,
		"collision_mask": 1,
		"standable": false,
		"detects_skye": true,
	}

static func apply_logic_pulse_to_drone(state: Dictionary, has_wrench_overclock: bool) -> Dictionary:
	var next := state.duplicate(true)
	if not has_wrench_overclock:
		next["state"] = DRONE_STATE_ALERT
		next["alarm_active"] = true
		next["is_solid_platform"] = false
		next["velocity"] = Vector2(120.0, 0.0)
		next["platform_rect"] = Rect2()
		next["collision_profile"] = drone_collision_profile(DRONE_COLLISION_SENSOR)
		return next
	var rect: Rect2 = next.get("rect", Rect2())
	next["state"] = DRONE_STATE_FROZEN
	next["alarm_active"] = false
	next["is_solid_platform"] = true
	next["velocity"] = Vector2.ZERO
	next["freeze_timer"] = DRONE_FREEZE_SECONDS
	next["platform_rect"] = Rect2(rect.position + Vector2(0.0, rect.size.y - 6.0), Vector2(rect.size.x, 12.0))
	next["collision_profile"] = drone_collision_profile(DRONE_COLLISION_PLATFORM)
	return next

static func advance_security_drone(state: Dictionary, delta: float) -> Dictionary:
	var next := state.duplicate(true)
	var current_state := str(next.get("state", DRONE_STATE_PATROL))
	if current_state == DRONE_STATE_FROZEN:
		var timer := maxf(0.0, float(next.get("freeze_timer", 0.0)) - maxf(0.0, delta))
		next["freeze_timer"] = timer
		if timer <= 0.0:
			next["state"] = DRONE_STATE_PATROL
			next["is_solid_platform"] = false
			next["platform_rect"] = Rect2()
			next["velocity"] = Vector2(72.0, 0.0)
			next["alarm_active"] = false
			next["collision_profile"] = drone_collision_profile(DRONE_COLLISION_SENSOR)
		return next
	var rect: Rect2 = next.get("rect", Rect2())
	var velocity: Vector2 = next.get("velocity", Vector2(72.0, 0.0))
	rect.position += velocity * maxf(0.0, delta)
	var min_x := float(next.get("patrol_min_x", rect.position.x))
	var max_x := float(next.get("patrol_max_x", rect.position.x))
	if rect.position.x <= min_x:
		rect.position.x = min_x
		velocity.x = absf(velocity.x)
	elif rect.position.x >= max_x:
		rect.position.x = max_x
		velocity.x = -absf(velocity.x)
	next["rect"] = rect
	next["velocity"] = velocity
	if current_state == DRONE_STATE_ALERT:
		next["alarm_active"] = true
	return next

static func create_bit_rot_stalker_state(id: String, rect: Rect2, shelter_position: Vector2) -> Dictionary:
	return {
		"id": id,
		"enemy_id": "bit_rot_stalker",
		"state": "stalking",
		"rect": rect,
		"velocity": Vector2(46.0, 0.0),
		"shelter_position": shelter_position,
		"static_trail": [],
		"trail_damage": TUNDRA_ENEMIES["bit_rot_stalker"]["trail_damage"],
		"de_rezzed": false,
		"panic_timer": 0.0,
		"vfx_profile": {
			"burst_kind": "thread",
			"tile_filter": "pixel_dither",
			"trail_color": Color("#ff594d"),
			"silhouette_color": Color("#10141a"),
		},
	}

static func advance_bit_rot_stalker(state: Dictionary, delta: float, skye_position: Vector2, white_out_active: bool) -> Dictionary:
	var next := state.duplicate(true)
	if bool(next.get("de_rezzed", false)):
		return next
	var rect: Rect2 = next.get("rect", Rect2())
	var velocity: Vector2 = next.get("velocity", Vector2(46.0, 0.0))
	var target := skye_position
	if white_out_active:
		next["state"] = "seeking_shielded_port"
		target = next.get("shelter_position", rect.position)
		next["panic_timer"] = float(next.get("panic_timer", 0.0)) + maxf(0.0, delta)
	else:
		next["state"] = "stalking"
		next["panic_timer"] = 0.0
	var direction := signf(target.x - rect.position.x)
	if absf(target.x - rect.position.x) <= 2.0:
		direction = 0.0
	velocity.x = direction * (92.0 if white_out_active else 46.0)
	rect.position += velocity * maxf(0.0, delta)
	next["rect"] = rect
	next["velocity"] = velocity
	var trail: Array = next.get("static_trail", [])
	trail.append({
		"position": rect.get_center(),
		"damage": float(next.get("trail_damage", 0.22)),
		"lifetime": 3.0,
	})
	while trail.size() > 8:
		trail.pop_front()
	next["static_trail"] = trail
	return next

static func resolve_bit_rot_stalker_white_out(state: Dictionary, protected_by_port: bool) -> Dictionary:
	var next := state.duplicate(true)
	if protected_by_port:
		next["state"] = "sheltered"
		next["de_rezzed"] = false
		next["static_trail"] = []
		return next
	next["state"] = "de_rezzed"
	next["de_rezzed"] = true
	next["velocity"] = Vector2.ZERO
	next["static_trail"] = []
	next["vfx_profile"] = {
		"burst_kind": "ascii_compile",
		"screen_effect": "whiteout_pop",
		"silhouette_color": Color("#f4fbff"),
	}
	return next

static func get_bit_rot_trail_hazard_profile(state: Dictionary) -> Dictionary:
	var trail: Array = state.get("static_trail", [])
	var zones: Array = []
	for point in trail:
		var position: Vector2 = point.get("position", Vector2.ZERO)
		zones.append({
			"rect": Rect2(position - Vector2(16.0, 5.0), Vector2(32.0, 10.0)),
			"damage": float(point.get("damage", 0.22)),
			"lifetime": float(point.get("lifetime", 3.0)),
			"tile_filter": "pixel_static",
		})
	return {
		"visible": zones.size() > 0,
		"hazard_id": "bit_rot_static_trail",
		"zone_count": zones.size(),
		"zones": zones,
		"burst_kind": "thread",
		"screen_effect": "chromatic_glitch",
		"warning_color": Color("#ff594d"),
		"presentation": "stalker_static_trail_zones",
	}

static func get_kernel_upgrade(id: String) -> Dictionary:
	return KERNEL_UPGRADES.get(id, {}).duplicate(true)

static func mainframe_spine_floor(height_ratio: float) -> Dictionary:
	var height := clampf(height_ratio, 0.0, 1.0)
	if height >= 0.85:
		return {
			"render_style": "RAW_ASCII",
			"code_age": "oldest",
			"flight_rule": "frequency_only_navigation",
		}
	if height >= 0.55:
		return {
			"render_style": "16_BIT_LEGACY",
			"code_age": "legacy",
			"flight_rule": "narrow_cache_vents",
		}
	return {
		"render_style": "4K_MODERN",
		"code_age": "recent",
		"flight_rule": "vertical_self_thrust",
	}

static func _prism_missing(has_optical_lens: bool, data_light_exposures: int, stability: float) -> Array[String]:
	var missing: Array[String] = []
	if not has_optical_lens:
		missing.append("optical_lens")
	if data_light_exposures < 3:
		missing.append("data_light_exposures")
	if stability < 0.65:
		missing.append("sector_stability")
	return missing
