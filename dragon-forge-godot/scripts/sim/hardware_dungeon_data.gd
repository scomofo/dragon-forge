extends RefCounted
class_name HardwareDungeonData

const DragonProgression := preload("res://scripts/sim/dragon_progression.gd")
const ActTwoProgressionData := preload("res://scripts/sim/act_two_progression_data.gd")
const ActTwoTundraData := preload("res://scripts/sim/act_two_tundra_data.gd")
const SfxData := preload("res://scripts/sim/sfx_data.gd")

const DUNGEONS := {
	"cooling_intake": {
		"name": "Cooling Intake",
		"perspective": "side_scrolling",
		"entrance": "felix_workshop",
		"objective": "restore_power_relay",
		"visuals": "rusted_catwalks_slow_turbines_power_core",
		"hazards": ["steam_leak", "slow_turbines", "bit_rot_floor"],
		"core_mechanism": "pressure_valve",
		"boss_id": "",
		"description": "Felix's home sector doubles as the tutorial hardware dungeon: turbines, pressure valves, and analog repair.",
	},
	"southern_partition_airlock": {
		"name": "Southern Partition Airlock",
		"perspective": "side_scrolling",
		"entrance": "physical_access_port",
		"objective": "pull_primary_breaker",
		"visuals": "maintenance_tunnels_red_firewall_lasers",
		"hazards": ["logic_grid", "thermal_exhaust", "bit_rot_floor"],
		"core_mechanism": "primary_breaker",
		"boss_id": "",
		"description": "A rusted airlock beneath data-vines that lets Skye bypass the red firewall from inside the ship.",
	},
	"great_buffer": {
		"name": "Great Buffer",
		"perspective": "side_scrolling",
		"entrance": "tundra_access_vault",
		"objective": "retrieve_optical_lens",
		"visuals": "white_server_vault_data_shielded_alcoves",
		"hazards": ["white_out_purge", "logic_grid", "bit_rot_floor"],
		"core_mechanism": "optical_lens_cradle",
		"boss_id": "indexer",
		"enemy_roster": ["security_drone_type_s", "bit_rot_stalker"],
		"description": "A white-walled storage vault where Skye must duck into data-shielded alcoves during purge cycles.",
	},
	"mirror_admin_gate": {
		"name": "Mirror Admin Gate",
		"perspective": "side_scrolling",
		"entrance": "tundra_exit_port",
		"objective": "seal_admin_shielded_port",
		"visuals": "white_glass_eye_cache_vault_scanline_purge",
		"hazards": ["white_out_purge", "logic_grid"],
		"core_mechanism": "shielded_port",
		"boss_id": "mirror_admin_sentinel",
		"enemy_roster": ["security_drone_type_s"],
		"description": "The Tundra exit folds into a white-glass admin chamber where Shielded Port torque breaks a sector-wide purge.",
	},
	"logic_core": {
		"name": "Logic Core",
		"perspective": "side_scrolling",
		"entrance": "mainframe_docking_station",
		"objective": "unlock_external_flight_vents",
		"visuals": "vertical_data_conduit_syntax_blocks",
		"hazards": ["syntax_blocks", "logic_grid", "laser_reroute"],
		"core_mechanism": "vent_unlock_terminal",
		"boss_id": "sentinel_drone",
		"description": "A vertical side-scrolling conduit where code-loop platforms move to a rhythm and unlock the next external climb.",
	},
}

const MECHANISMS := {
	"pressure_valve": {
		"required_relic": "10mm_wrench",
		"effect": "steam_leak_stopped",
	},
	"primary_breaker": {
		"required_relic": "10mm_wrench",
		"effect": "firewall_bypass_enabled",
	},
	"vent_unlock_terminal": {
		"required_relic": "insulated_grip",
		"effect": "external_vents_unlocked",
	},
	"optical_lens_cradle": {
		"required_relic": "10mm_wrench",
		"effect": "optical_lens_released",
	},
	"shielded_port": {
		"required_relic": "10mm_wrench",
		"effect": "shielded_port_sealed",
	},
}

const PHYSICAL_ANOMALIES := {
	"indexer": {
		"name": "The Indexer",
		"boss_type": "physical_anomaly",
		"attack": "sort_to_disposal_bin",
		"weakness": "jam_sorting_arm",
		"disable_action": "jam_sorting_arm",
		"description": "A multi-armed sorting robot that treats Skye as misfiled inventory.",
	},
	"sentinel_drone": {
		"name": "Sentinel Drone",
		"boss_type": "physical_anomaly",
		"attack": "lighting_weapon",
		"weakness": "diagnostic_safe_spots",
		"disable_action": "diagnostic_safe_spots",
		"description": "A ship-lighting security unit whose attacks are readable only through the Diagnostic Lens.",
	},
	"mirror_admin_sentinel": {
		"name": "Mirror Admin Sentinel",
		"boss_type": "physical_anomaly",
		"attack": "sector_purge",
		"weakness": "shielded_port_torque",
		"disable_action": "seal_shielded_port",
		"description": "A white-glass admin daemon that weaponizes the Tundra's purge cycle until Skye seals its shielded port by hand.",
	},
}

const SYSTEM_CONSUMABLES := {
	"data_fluid": {
		"label": "Data-Fluid",
		"effect": "restore_heat_buffer",
		"amount": 0.45,
	},
	"silicon_shards": {
		"label": "Silicon Shards",
		"effect": "weaver_reinforcement",
		"amount": 1,
	},
	"logic_gate": {
		"label": "Logic Gate",
		"effect": "circuit_key",
		"amount": 1,
	},
	"buffered_spirits": {
		"label": "Buffered Spirits",
		"effect": "overclock_movement",
		"amount": 0.35,
	},
}

const MANUAL_PAGES := {
	"cooling_intake_error_log": {
		"kind": "error_log",
		"title": "Cooling Intake Crash Log",
		"terminal_code": "VENT-60HZ",
		"backstory": "The relay failed when Mirror Admin digitally locked a physical valve mid-cycle.",
	},
	"friction_saddle_schematic": {
		"kind": "schematic",
		"title": "Friction Saddle Assembly",
		"terminal_code": "SADDLE-TRACTION",
		"craft_unlock": "friction_saddle",
	},
}

const CAPTAINS_LOG_FRAGMENTS := {
	"cooling_intake": {
		"id": "cooling_intake",
		"title": "Captain's Log: Cooling Intake",
		"save_flag": "captains_log_cooling_intake",
		"summary": "The intake was built as analog failsafe first and digital convenience second.",
	},
	"southern_partition_airlock": {
		"id": "southern_partition_airlock",
		"title": "Captain's Log: Southern Partition",
		"save_flag": "captains_log_southern_partition_airlock",
		"summary": "The airlock never trusted software locks; every door has a physical breaker somewhere.",
	},
	"great_buffer": {
		"id": "great_buffer",
		"title": "Captain's Log: Tundra Buffer",
		"save_flag": "captains_log_great_buffer",
		"summary": "White-out purges were maintenance, not weather, until the Admin weaponized them.",
	},
	"logic_core": {
		"id": "logic_core",
		"title": "Captain's Log: Logic Core",
		"save_flag": "captains_log_logic_core",
		"summary": "At the Spine peak, command syntax and physical architecture become the same thing.",
	},
	"mirror_admin_gate": {
		"id": "mirror_admin_gate",
		"title": "Captain's Log: Admin Gate",
		"save_flag": "captains_log_mirror_admin_gate",
		"summary": "The Admin could lock every digital path, but its purge relays still needed physical shielded ports.",
	},
}

const CAPTAINS_LOG_ORDER := [
	"cooling_intake",
	"southern_partition_airlock",
	"great_buffer",
	"mirror_admin_gate",
	"logic_core",
]

const DUNGEON_COMPLETION_BEATS := {
	"cooling_intake": {
		"headline": "Power Core Breathing",
		"payoff": "Felix's analog relay coughs back to 60Hz and the Workshop becomes a true safe zone.",
		"next_route": "Use the restored relay to prepare the Southern Partition breakout.",
		"admin_reveal": "Mirror Admin can lock software, but it cannot stop gravity, pressure, and bolts.",
	},
	"southern_partition_airlock": {
		"headline": "Firewall Bypassed",
		"payoff": "The airlock's breaker drags a red firewall open by force.",
		"next_route": "Fly north into the Tundra of Silicon before the Admin reroutes the gate.",
		"admin_reveal": "Digital permission fails when Skye finds the physical breaker behind it.",
	},
	"great_buffer": {
		"headline": "Optical Lens Recovered",
		"payoff": "The cache vault yields the Optical Lens and teaches Skye to read White-Out purge timing.",
		"next_route": "Return to Unit 01, install the Frequency Tuner, then confront the Admin Gate.",
		"admin_reveal": "The White-Out was maintenance until Mirror Admin weaponized it.",
	},
	"mirror_admin_gate": {
		"headline": "Admin Gate Sealed",
		"payoff": "Skye seals the shielded port by hand, collapsing the white-glass sentinel into an Admin Shard.",
		"next_route": "Use the Admin Shard and Prism-Stalk route to begin the Mainframe Spine ascent.",
		"admin_reveal": "The Admin's purge still depends on hardware it cannot fully control.",
	},
	"logic_core": {
		"headline": "External Vents Unlocked",
		"payoff": "The Logic Core opens the Mainframe's vent route and makes the vertical climb possible.",
		"next_route": "Ride the thermal chimney toward the ASCII Tier and the Root Sentinel.",
		"admin_reveal": "At the Spine, code and architecture become the same lock.",
	},
}

const ROOM_LAYOUTS := {
	"cooling_intake": {
		"style": "tutorial_turbine",
		"platforms": [
			Rect2(0, 578, 1280, 46),
			Rect2(160, 468, 180, 24),
			Rect2(440, 398, 210, 24),
			Rect2(760, 326, 220, 24),
			Rect2(1010, 476, 170, 24),
		],
		"exit_rect": Rect2(1160, 430, 54, 148),
		"boss_core_rect": Rect2(1040, 248, 70, 70),
		"mechanisms": [
			{ "id": "valve_a", "mechanism": "pressure_valve", "label": "Valve A", "rect": Rect2(510, 350, 42, 48) },
			{ "id": "valve_b", "mechanism": "pressure_valve", "label": "Valve B", "rect": Rect2(840, 278, 42, 48) },
		],
		"hazards": [
			{ "id": "steam_leak", "rect": Rect2(350, 500, 46, 78), "disabled_by": "valve_a" },
			{ "id": "steam_leak", "rect": Rect2(690, 430, 48, 148), "disabled_by": "valve_b" },
		],
	},
	"southern_partition_airlock": {
		"style": "firewall_breach",
		"platforms": [
			Rect2(0, 578, 1280, 46),
			Rect2(180, 486, 150, 24),
			Rect2(430, 414, 150, 24),
			Rect2(690, 342, 150, 24),
			Rect2(910, 342, 120, 24),
			Rect2(1070, 462, 140, 24),
		],
		"exit_rect": Rect2(1160, 430, 54, 148),
		"boss_core_rect": Rect2(1040, 248, 70, 70),
		"mechanisms": [
			{ "id": "breaker", "mechanism": "primary_breaker", "label": "Breaker", "rect": Rect2(900, 278, 52, 58) },
		],
		"hazards": [
			{ "id": "logic_grid", "rect": Rect2(392, 428, 34, 150), "disabled_by": "breaker" },
			{ "id": "logic_grid", "rect": Rect2(710, 354, 34, 224), "disabled_by": "breaker" },
		],
	},
	"great_buffer": {
		"style": "buffer_vault",
		"platforms": [
			Rect2(0, 578, 1280, 46),
			Rect2(130, 498, 150, 24),
			Rect2(350, 438, 150, 24),
			Rect2(580, 378, 150, 24),
			Rect2(820, 318, 160, 24),
			Rect2(1040, 458, 150, 24),
		],
		"exit_rect": Rect2(1160, 430, 54, 148),
		"boss_core_rect": Rect2(1040, 248, 70, 70),
		"mechanisms": [
			{ "id": "lens_cradle", "mechanism": "optical_lens_cradle", "label": "Lens", "rect": Rect2(880, 278, 52, 58) },
		],
		"security_drones": [
			{ "id": "type_s_01", "rect": Rect2(442, 356, 54, 28), "patrol_min_x": 360.0, "patrol_max_x": 560.0 },
		],
		"bit_rot_stalkers": [
			{ "id": "stalker_01", "rect": Rect2(690, 536, 28, 38), "shelter_position": Vector2(322, 536) },
		],
		"shielded_ports": [
			{ "id": "port_alpha", "label": "Shielded Port A", "rect": Rect2(294, 494, 76, 84), "purge_pressure": 0.78 },
		],
		"binary_tiles": [
			{ "id": "bit_4", "tile_index": 0, "weight": 4, "rect": Rect2(420, 552, 58, 26) },
			{ "id": "bit_2", "tile_index": 1, "weight": 2, "rect": Rect2(486, 552, 58, 26) },
			{ "id": "bit_1", "tile_index": 2, "weight": 1, "rect": Rect2(552, 552, 58, 26) },
		],
		"binary_gate": { "id": "cache_gate", "label": "CACHE GATE", "rect": Rect2(632, 476, 54, 102) },
		"binary_guide": { "id": "unit_08", "name": "Unit 08", "rect": Rect2(386, 480, 98, 56) },
		"hazards": [
			{ "id": "white_out_purge", "rect": Rect2(320, 430, 72, 148), "disabled_by": "lens_cradle" },
			{ "id": "logic_grid", "rect": Rect2(690, 354, 34, 224), "disabled_by": "lens_cradle" },
		],
	},
	"mirror_admin_gate": {
		"style": "buffer_vault",
		"platforms": [
			Rect2(0, 578, 1280, 46),
			Rect2(118, 506, 150, 24),
			Rect2(330, 446, 150, 24),
			Rect2(548, 386, 150, 24),
			Rect2(766, 446, 150, 24),
			Rect2(985, 506, 150, 24),
		],
		"exit_rect": Rect2(1160, 430, 54, 148),
		"boss_core_rect": Rect2(1046, 248, 74, 74),
		"mechanisms": [
			{ "id": "admin_port", "mechanism": "shielded_port", "label": "Shielded Port", "rect": Rect2(596, 330, 64, 58) },
		],
		"hazards": [
			{ "id": "white_out_purge", "rect": Rect2(288, 432, 74, 146), "disabled_by": "admin_port" },
			{ "id": "white_out_purge", "rect": Rect2(922, 432, 74, 146), "disabled_by": "admin_port" },
			{ "id": "logic_grid", "rect": Rect2(704, 354, 34, 224), "disabled_by": "admin_port" },
		],
	},
	"logic_core": {
		"style": "vertical_data_conduit",
		"platforms": [
			Rect2(0, 578, 1280, 46),
			Rect2(108, 500, 150, 24),
			Rect2(330, 438, 150, 24),
			Rect2(560, 376, 150, 24),
			Rect2(790, 314, 150, 24),
			Rect2(1010, 252, 150, 24),
			Rect2(840, 172, 140, 24),
		],
		"exit_rect": Rect2(1160, 220, 54, 148),
		"boss_core_rect": Rect2(1010, 104, 70, 70),
		"mechanisms": [
			{ "id": "terminal", "mechanism": "vent_unlock_terminal", "label": "Terminal", "rect": Rect2(890, 126, 58, 58) },
		],
		"hazards": [
			{ "id": "logic_grid", "rect": Rect2(620, 354, 34, 224), "disabled_by": "terminal" },
			{ "id": "laser_reroute", "rect": Rect2(954, 196, 36, 198), "disabled_by": "terminal" },
		],
		"ascii_puzzles": [
			{ "id": "bracket_bridge", "label": "Bracket Bridge", "kind": "compile_bridge", "rect": Rect2(448, 498, 170, 28), "required_tool": "10mm_wrench" },
			{ "id": "boolean_gate", "label": "LOCKED = TRUE", "kind": "boolean_gate", "rect": Rect2(1090, 184, 86, 168), "required_tool": "10mm_wrench" },
			{ "id": "comment_out", "label": "// Security Beam", "kind": "comment_beam", "rect": Rect2(720, 218, 226, 24), "required_armor": "ASCII_AEGIS" },
		],
	},
}

static func get_dungeon(id: String) -> Dictionary:
	var dungeon: Dictionary = DUNGEONS.get(id, {})
	var result := dungeon.duplicate(true)
	if not result.is_empty():
		result["id"] = id
	return result

static func get_room_layout(dungeon_id: String) -> Dictionary:
	var fallback: Dictionary = ROOM_LAYOUTS["cooling_intake"]
	var layout: Dictionary = ROOM_LAYOUTS.get(dungeon_id, fallback)
	return layout.duplicate(true)

static func get_dungeon_boss(dungeon_id: String) -> Dictionary:
	var dungeon := get_dungeon(dungeon_id)
	var boss_id := str(dungeon.get("boss_id", ""))
	if boss_id == "":
		return {}
	return get_physical_anomaly(boss_id)

static func get_dungeon_enemy_roster_profile(dungeon_id: String) -> Dictionary:
	var dungeon := get_dungeon(dungeon_id)
	var enemy_ids: Array = dungeon.get("enemy_roster", [])
	var enemies: Array = []
	for enemy_id in enemy_ids:
		var enemy: Dictionary = ActTwoTundraData.get_tundra_enemy_profile(str(enemy_id))
		if not enemy.is_empty():
			enemies.append(enemy)
	return {
		"dungeon_id": dungeon_id,
		"enemy_count": enemies.size(),
		"enemies": enemies,
		"has_platform_drone": _roster_has_enemy(enemies, "security_drone_type_s"),
		"has_static_stalker": _roster_has_enemy(enemies, "bit_rot_stalker"),
		"presentation": "hardware_process_roster",
	}

static func can_enter_dungeon(dungeon_id: String, profile: Dictionary) -> Dictionary:
	match dungeon_id:
		"cooling_intake":
			if not _has_key_item(profile, "10mm_wrench"):
				return _dungeon_lock("Felix has not handed Skye the 10mm Wrench yet.")
			if not _has_flag(profile, "search_index_daemon_defeated"):
				return _dungeon_lock("Search & Index Daemon must be rebooted before Felix opens the Cooling Intake.")
		"southern_partition_airlock":
			if not _has_key_item(profile, "friction_saddle"):
				return _dungeon_lock("The Friction Saddle is required for the approach dive.")
			if not _has_flag(profile, "bounty_hunters_evaded"):
				return _dungeon_lock("Sub-routine Stalkers are still tracking Skye. Clear the Bounty Hunter chase first.")
		"great_buffer":
			if not _has_flag(profile, "unit_01_met"):
				return _dungeon_lock("Unit 01 must establish the save/shop link before opening the vault.")
			if not _has_flag(profile, "mirror_admin_tundra_repelled"):
				return _dungeon_lock("Mirror Admin projection must be repelled before the Great Buffer will open.")
		"mirror_admin_gate":
			if not _has_flag(profile, "dungeon_great_buffer_complete"):
				return _dungeon_lock("The Optical Lens must be recovered before Skye can read the Admin Gate parity scan.")
			if not _has_key_item(profile, "wrench_overclock"):
				return _dungeon_lock("Pulse must overclock the 10mm Wrench before it can seal the Admin's shielded port.")
		"logic_core":
			if not _has_key_item(profile, "insulated_grip"):
				return _dungeon_lock("Insulated Grip is required to turn live data-bolts.")
			if not _has_flag(profile, "mainframe_spine_ascent_started"):
				return _dungeon_lock("The Mainframe Spine ascent must begin before docking at the Logic Core.")
	return {
		"allowed": true,
		"reason": "",
	}

static func get_dungeon_loadout_requirements(dungeon_id: String) -> Dictionary:
	match dungeon_id:
		"cooling_intake":
			return {
				"required_tools": ["10mm_wrench"],
				"recommended_tools": ["friction_saddle"],
				"readiness_label": "COOLING INTAKE KIT",
			}
		"southern_partition_airlock":
			return {
				"required_tools": ["10mm_wrench"],
				"recommended_tools": ["friction_saddle", "optical_lens"],
				"readiness_label": "FIREWALL BYPASS KIT",
			}
		"great_buffer":
			return {
				"required_tools": ["10mm_wrench"],
				"recommended_tools": ["silicon_padded_gear"],
				"readiness_label": "CACHE VAULT KIT",
			}
		"mirror_admin_gate":
			return {
				"required_tools": ["10mm_wrench", "optical_lens"],
				"recommended_tools": ["silicon_padded_gear"],
				"readiness_label": "ADMIN GATE KIT",
			}
		"logic_core":
			return {
				"required_tools": ["10mm_wrench"],
				"recommended_tools": ["optical_lens", "friction_saddle"],
				"readiness_label": "ASCII SPINE KIT",
			}
	return {
		"required_tools": ["10mm_wrench"],
		"recommended_tools": [],
		"readiness_label": "HARDWARE KIT",
	}

static func get_dungeon_loadout_profile(dungeon_id: String, utility_belt: Dictionary) -> Dictionary:
	var requirements := get_dungeon_loadout_requirements(dungeon_id)
	var carried: Array = utility_belt.get("equipped_tools", utility_belt.get("tool_ids", []))
	var missing_required: Array[String] = []
	for tool_id in requirements.get("required_tools", []):
		if not carried.has(str(tool_id)):
			missing_required.append(str(tool_id))
	var missing_recommended: Array[String] = []
	for tool_id in requirements.get("recommended_tools", []):
		if not carried.has(str(tool_id)):
			missing_recommended.append(str(tool_id))
	return {
		"presentation": "dungeon_entry_loadout_check",
		"dungeon_id": dungeon_id,
		"ready": missing_required.is_empty(),
		"status_label": "READY" if missing_required.is_empty() else "MISSING RELIC",
		"readiness_label": requirements.get("readiness_label", "HARDWARE KIT"),
		"required_tools": requirements.get("required_tools", []),
		"recommended_tools": requirements.get("recommended_tools", []),
		"carried_tools": carried,
		"missing_required": missing_required,
		"missing_recommended": missing_recommended,
		"warning": "Socket %s at Felix's Anvil before entering." % ", ".join(missing_required) if not missing_required.is_empty() else "",
		"recommendation": "Recommended: %s." % ", ".join(missing_recommended) if not missing_recommended.is_empty() else "Loadout matched.",
	}

static func use_wrench_on_mechanism(mechanism_id: String, relic_id: String) -> Dictionary:
	var mechanism: Dictionary = MECHANISMS.get(mechanism_id, {})
	var required := str(mechanism.get("required_relic", ""))
	var success := relic_id == required
	return {
		"success": success,
		"mechanism": mechanism_id,
		"effect": mechanism.get("effect", "") if success else "NO_EFFECT",
		"required_relic": required,
	}

static func get_mechanism_vfx_profile(mechanism_id: String, result: Dictionary) -> Dictionary:
	var success := bool(result.get("success", false))
	match mechanism_id:
		"pressure_valve":
			return {
				"id": "pressure_valve",
				"burst_kind": "coolant_steam" if success else "thread",
				"screen_effect": "heat_haze" if success else "warning_pulse",
				"impact_flash": Color("#8fe6ff", 0.24),
				"steam_column_count": 4,
				"lifetime": 0.72,
			}
		"primary_breaker":
			return {
				"id": "primary_breaker",
				"burst_kind": "wrench_sparks" if success else "thread",
				"screen_effect": "warning_pulse",
				"impact_flash": Color("#ffd166", 0.28),
				"spark_count": 18,
				"lifetime": 0.56,
			}
		"optical_lens_cradle":
			return {
				"id": "optical_lens_cradle",
				"burst_kind": "prism" if success else "thread",
				"screen_effect": "scanline_burst" if success else "chromatic_glitch",
				"impact_flash": Color("#58dbff", 0.24),
				"lifetime": 0.64,
			}
		"vent_unlock_terminal":
			return {
				"id": "vent_unlock_terminal",
				"burst_kind": "ascii_compile" if success else "thread",
				"screen_effect": "scanline_burst" if success else "warning_pulse",
				"impact_flash": Color("#70ff8f", 0.24),
				"lifetime": 0.68,
			}
	return {
		"id": mechanism_id,
		"burst_kind": "wrench_sparks" if success else "thread",
		"screen_effect": "scanline_burst" if success else "warning_pulse",
		"impact_flash": Color("#f8de9a", 0.18),
	}

static func resolve_access_port_puzzle(puzzle_id: String, tools: Array, context: Dictionary) -> Dictionary:
	var tool := str(context.get("tool", ""))
	match puzzle_id:
		"manual_override_bolts":
			var removed_all := tools.has("bolt_a") and tools.has("bolt_b") and tools.has("bolt_c")
			var torqued := tool == "10mm_wrench" and float(context.get("rotation_quality", 0.0)) >= 0.65
			return {
				"success": removed_all and torqued,
				"digital_lock_bypassed": removed_all and torqued,
				"physical_result": "BLAST_DOOR_WEIGHT_RELEASED" if removed_all and torqued else "BOLTS_STILL_SEATED",
				"requires": ["bolt_a", "bolt_b", "bolt_c", "10mm_wrench"],
			}
		"pressure_calibration":
			var gauge := float(context.get("gauge_value", 0.0))
			if gauge > 0.82:
				return {
					"success": false,
					"failure": "PIPE_BURST",
					"damage": 0.25,
					"gauge_value": gauge,
				}
			var in_green := tool == "10mm_wrench" and gauge >= 0.45 and gauge <= 0.62
			return {
				"success": in_green,
				"hazard_disabled": "coolant_steam" if in_green else "",
				"gauge_zone": "GREEN" if in_green else "UNDER_TIGHTENED",
				"gauge_value": gauge,
			}
		"terminal_pry":
			var reseated := tool == "10mm_wrench" and bool(context.get("cable_reseated", false))
			return {
				"success": reseated,
				"stabilized_seconds": 60.0 if reseated else 0.0,
				"physical_result": "FLOOR_PANEL_STABILIZED" if reseated else "CABLE_STILL_LOOSE",
				"gauge_value": 0.5 if reseated else 0.2,
			}
		"dead_drop_elevator":
			var complete_chain := tools.has("diagnostic_lens") and tools.has("10mm_wrench") and tools.has("manual_crank")
			return {
				"success": complete_chain,
				"requires_chain_logic": true,
				"elevator_state": "PULLEY_WOUND_TO_FLOOR" if complete_chain else "STALLING",
			}
		"signal_mirror":
			var angle := float(context.get("angle", 0.0))
			var aligned := tools.has("optical_lens") and tools.has("10mm_wrench") and absf(angle - 45.0) <= 6.0
			return {
				"success": aligned,
				"beam_redirected": aligned,
				"sensor_state": "DATA_STREAM_ALIGNED" if aligned else "NO_SIGNAL",
			}
		"heat_sync_bridge":
			var heated := tools.has("magma_core") and str(context.get("target_system", "")) == "external_heat_sink"
			return {
				"success": heated,
				"geometry_changed": "memory_alloy_bridge_expanded" if heated else "",
				"dragon_linked": true,
			}
	return {
		"success": false,
		"failure": "UNKNOWN_ACCESS_PORT_PUZZLE",
	}

static func get_torque_meter_hud_profile(source_id: String, result: Dictionary) -> Dictionary:
	if source_id == "":
		return {
			"visible": false,
		}
	var success := bool(result.get("success", false))
	var gauge := clampf(float(result.get("gauge_value", 0.5 if success else 0.0)), 0.0, 1.0)
	var zone_label := "LOCKED"
	var danger := false
	if str(result.get("failure", "")) == "PIPE_BURST":
		zone_label = "PIPE BURST"
		danger = true
	elif source_id == "pressure_calibration":
		zone_label = "GREEN BUFFER" if success else "UNDER TORQUE"
	elif source_id == "terminal_pry":
		zone_label = "PANEL SEATED" if success else "CABLE LOOSE"
	elif source_id == "manual_override_bolts":
		zone_label = "BOLTS FREE" if success else "BOLT DRAG"
	else:
		zone_label = "SYNCED" if success else "MISALIGNED"
	return {
		"visible": true,
		"source_id": source_id,
		"needle_value": gauge,
		"green_min": 0.45,
		"green_max": 0.62,
		"gauge_shape": "circular",
		"sweet_spot_arc": Vector2(0.45, 0.62),
		"red_zone": Vector2(0.82, 1.0),
		"feedback_style": "analog_sparks" if danger else "bolt_turn",
		"zone_label": zone_label,
		"danger": danger,
		"bezel_color": Color("#ff453a") if danger else Color("#58dbff") if success else Color("#ffd166"),
		"needle_color": Color("#ff453a") if danger else Color("#f8fbff"),
		"input_label": "10MM TORQUE",
		"sfx": SfxData.get_ui_sfx_profile("torque_slip" if danger else "torque_green" if success else "torque_seek"),
	}

static func create_torque_meter_state(purge_pressure: float = 0.5) -> Dictionary:
	return {
		"visible": true,
		"source_id": "shielded_port",
		"needle_value": 0.18,
		"oscillator_phase": -0.75,
		"motion_model": "sin_oscillator",
		"direction": 1.0,
		"purge_pressure": clampf(purge_pressure, 0.0, 1.0),
		"turn_progress": 0.0,
		"slip_count": 0,
		"failure": "",
		"green_min": 0.45,
		"green_max": 0.62,
		"gauge_shape": "circular",
		"sweet_spot_arc": Vector2(0.45, 0.62),
		"red_zone": Vector2(0.82, 1.0),
		"feedback_style": "purge_torque",
		"vibration": 0.0,
		"sparks": false,
		"bolt_turning": false,
		"in_green_zone": false,
		"sfx": SfxData.get_ui_sfx_profile("torque_seek"),
	}

static func advance_torque_meter(state: Dictionary, delta: float, tightening: bool) -> Dictionary:
	var next := state.duplicate(true)
	var pressure := clampf(float(next.get("purge_pressure", 0.5)), 0.0, 1.0)
	var needle := clampf(float(next.get("needle_value", 0.0)), 0.0, 1.0)
	var phase := float(next.get("oscillator_phase", asin(clampf(needle * 2.0 - 1.0, -1.0, 1.0))))
	var green_min := float(next.get("green_min", 0.45))
	var green_max := float(next.get("green_max", 0.62))
	var was_in_green := needle >= green_min and needle <= green_max
	var speed := 1.45 + pressure * 1.35
	phase = fmod(phase + speed * maxf(0.0, delta), TAU)
	needle = 0.5 + sin(phase) * 0.5
	var direction := 1.0 if cos(phase) >= 0.0 else -1.0
	var in_green := needle >= green_min and needle <= green_max
	var accepted_green := was_in_green or in_green
	var sparks := false
	var bolt_turning := false
	var progress := clampf(float(next.get("turn_progress", 0.0)), 0.0, 1.0)
	var slip_count := int(next.get("slip_count", 0))
	if tightening and accepted_green:
		progress = clampf(progress + delta * (0.72 - pressure * 0.18), 0.0, 1.0)
		bolt_turning = true
	elif tightening and (needle >= 0.82 or needle <= 0.18):
		slip_count += 1
		sparks = true
		progress = maxf(0.0, progress - delta * 0.12)
	next["needle_value"] = needle
	next["direction"] = direction
	next["oscillator_phase"] = phase
	next["motion_model"] = "sin_oscillator"
	next["turn_progress"] = progress
	next["slip_count"] = slip_count
	next["in_green_zone"] = accepted_green
	next["bolt_turning"] = bolt_turning
	next["sparks"] = sparks
	next["vibration"] = pressure * (0.12 + absf(sin(needle * TAU * 3.0)) * 0.18)
	next["failure"] = "PIPE_BURST" if slip_count >= 3 and needle >= 0.82 else str(next.get("failure", ""))
	next["success"] = progress >= 1.0
	next["zone_label"] = "GREEN BUFFER" if accepted_green else "RED SLIP" if sparks else "SEEKING"
	next["bezel_color"] = Color("#70ff8f") if accepted_green else Color("#ff453a") if sparks else Color("#58dbff")
	next["needle_color"] = Color("#ff453a") if sparks else Color("#f8fbff")
	next["input_label"] = "10MM TORQUE"
	next["feedback_style"] = "analog_sparks" if sparks else "bolt_turn" if bolt_turning else "purge_torque"
	next["sfx"] = SfxData.get_torque_meter_sfx(next)
	return next

static func binary_bits_to_decimal(bits: Array, weights: Array) -> int:
	var decimal := 0
	for index in range(mini(bits.size(), weights.size())):
		if int(bits[index]) == 1:
			decimal += int(weights[index])
	return decimal

static func binary_weights_for_tile_count(tile_count: int, most_significant_first: bool = true) -> Array[int]:
	var weights: Array[int] = []
	var safe_count := maxi(0, tile_count)
	for index in range(safe_count):
		var exponent := safe_count - index - 1 if most_significant_first else index
		weights.append(1 << exponent)
	return weights

static func get_binary_display_hud_profile(bits: Array, weights: Array, target_sum: int) -> Dictionary:
	var digits: Array = []
	var current_sum := binary_bits_to_decimal(bits, weights)
	for index in range(mini(bits.size(), weights.size())):
		var active := int(bits[index]) == 1
		var weight := int(weights[index])
		digits.append({
			"bit": 1 if active else 0,
			"weight": weight,
			"glow_color": Color("#58dbff") if active else Color("#56616f"),
			"alpha": 0.92 if active else 0.34,
		})
	return {
		"visible": true,
		"label": "CACHE SUM",
		"header": "TARGET: %d" % target_sum,
		"display_style": "crt_door_panel",
		"digits": digits,
		"current_sum": current_sum,
		"target_sum": target_sum,
		"matched": current_sum == target_sum,
		"status": "MATCH" if current_sum == target_sum else "FLIP BITS",
		"frame_color": Color("#70ff8f") if current_sum == target_sum else Color("#58dbff"),
		"door_feedback": "OPEN" if current_sum == target_sum else "LOCKED",
		"crt_glow": 0.84 if current_sum == target_sum else 0.52,
		"sfx": SfxData.get_ui_sfx_profile("binary_match" if current_sum == target_sum else "binary_flip"),
	}

static func create_binary_puzzle_state(bits: Array = [1, 1, 0], weights: Array = [4, 2, 1], target_decimal: int = 6) -> Dictionary:
	var normalized_bits: Array = []
	for bit in bits:
		normalized_bits.append(1 if int(bit) == 1 else 0)
	var normalized_weights: Array = []
	if weights.is_empty():
		weights = binary_weights_for_tile_count(normalized_bits.size())
	for weight in weights:
		normalized_weights.append(int(weight))
	var state := {
		"bits": normalized_bits,
		"weights": normalized_weights,
		"target_decimal": target_decimal,
		"current_decimal": 0,
		"door_open": false,
	}
	return recalculate_binary_puzzle_state(state)

static func toggle_binary_puzzle_tile(state: Dictionary, tile_index: int) -> Dictionary:
	var next := state.duplicate(true)
	var bits: Array = next.get("bits", [])
	if tile_index < 0 or tile_index >= bits.size():
		next["last_toggle_valid"] = false
		return recalculate_binary_puzzle_state(next)
	bits[tile_index] = 0 if int(bits[tile_index]) == 1 else 1
	next["bits"] = bits
	next["last_toggled_index"] = tile_index
	next["last_toggle_valid"] = true
	next = recalculate_binary_puzzle_state(next)
	next["sfx"] = SfxData.get_binary_display_sfx(next.get("display", {}), true)
	return next

static func recalculate_binary_puzzle_state(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var bits: Array = next.get("bits", [])
	var weights: Array = next.get("weights", [])
	var decimal := binary_bits_to_decimal(bits, weights)
	next["current_decimal"] = decimal
	next["door_open"] = decimal == int(next.get("target_decimal", 0))
	next["status"] = "OPEN" if bool(next["door_open"]) else "LOCKED"
	next["display"] = get_binary_display_hud_profile(bits, weights, int(next.get("target_decimal", 0)))
	return next

static func get_access_port_vfx_profile(puzzle_id: String, result: Dictionary) -> Dictionary:
	var success := bool(result.get("success", false))
	match puzzle_id:
		"manual_override_bolts":
			return {
				"id": "manual_override_bolts",
				"burst_kind": "wrench_sparks" if success else "thread",
				"screen_effect": "impact_freeze" if success else "warning_pulse",
				"impact_flash": Color("#ffd166", 0.24),
				"spark_count": 18 if success else 8,
				"lifetime": 0.58,
			}
		"pressure_calibration":
			if success:
				return {
					"id": "pressure_calibration",
					"burst_kind": "coolant_steam",
					"screen_effect": "heat_haze",
					"impact_flash": Color("#8fe6ff", 0.26),
					"steam_column_count": 5,
					"lifetime": 0.82,
				}
			return {
				"id": "pressure_calibration",
				"burst_kind": "thread",
				"screen_effect": "warning_pulse",
				"impact_flash": Color("#ff453a", 0.28),
				"impact_spark_count": 16,
				"lifetime": 0.54,
			}
		"terminal_pry":
			return {
				"id": "terminal_pry",
				"burst_kind": "wrench_sparks" if success else "thread",
				"screen_effect": "scanline_burst" if success else "chromatic_glitch",
				"impact_flash": Color("#ffd166", 0.22),
				"spark_count": 14,
				"lifetime": 0.5,
			}
		"dead_drop_elevator":
			return {
				"id": "dead_drop_elevator",
				"burst_kind": "wrench_sparks",
				"screen_effect": "impact_freeze",
				"impact_flash": Color("#f7e7b0", 0.22),
				"spark_count": 10,
				"lifetime": 0.62,
			}
		"signal_mirror":
			return {
				"id": "signal_mirror",
				"burst_kind": "prism" if success else "thread",
				"screen_effect": "scanline_burst" if success else "chromatic_glitch",
				"impact_flash": Color("#58dbff", 0.24),
				"lifetime": 0.66,
			}
		"heat_sync_bridge":
			return {
				"id": "heat_sync_bridge",
				"burst_kind": "magma" if success else "thread",
				"screen_effect": "heat_haze" if success else "warning_pulse",
				"impact_flash": Color("#ff7a35", 0.26),
				"lifetime": 0.76,
			}
	return {
		"id": puzzle_id,
		"burst_kind": "shockwave" if success else "thread",
		"screen_effect": "scanline_burst" if success else "warning_pulse",
		"impact_flash": Color("#f8de9a", 0.18),
	}

static func resolve_stripped_bolt(bolt_id: String, tool_id: String, stability: float) -> Dictionary:
	var corrupted := bolt_id.contains("corrupted") or stability < 0.35
	var stripped := corrupted and tool_id == "10mm_wrench"
	return {
		"stripped": stripped,
		"bolt_id": bolt_id,
		"fallback_tool": "thermal_torch" if stripped else "",
		"route_state": "ALTERNATE_ROUTE_REQUIRED" if stripped else "BOLT_REMOVED",
	}

static func configure_utility_belt(tool_ids: Array, slot_count: int) -> Dictionary:
	var over := maxi(0, tool_ids.size() - slot_count)
	return {
		"valid": over == 0,
		"slots": slot_count,
		"used": tool_ids.size(),
		"over_capacity": over,
		"equipped_tools": tool_ids.slice(0, mini(tool_ids.size(), slot_count)),
	}

static func use_system_consumable(item_id: String, state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var item: Dictionary = SYSTEM_CONSUMABLES.get(item_id, {})
	if item.is_empty():
		next["consumed"] = false
		return next
	match str(item.get("effect", "")):
		"restore_heat_buffer":
			next["heat_buffer"] = clampf(float(next.get("heat_buffer", 0.0)) + float(item.get("amount", 0.0)), 0.0, 1.0)
		"overclock_movement":
			next["movement_speed_bonus"] = float(item.get("amount", 0.0))
		"circuit_key":
			next["logic_gate_inserted"] = true
		"weaver_reinforcement":
			next["silicon_shards"] = int(next.get("silicon_shards", 0)) + int(item.get("amount", 1))
	next["consumed"] = true
	next["item_id"] = item_id
	return next

static func read_manual_page(page_id: String) -> Dictionary:
	var page: Dictionary = MANUAL_PAGES.get(page_id, {})
	var result := page.duplicate(true)
	if not result.is_empty():
		result["id"] = page_id
	return result

static func get_captains_log_fragment(dungeon_id: String) -> Dictionary:
	var fragment: Dictionary = CAPTAINS_LOG_FRAGMENTS.get(dungeon_id, {})
	return fragment.duplicate(true)

static func get_captains_log_flags_for_dungeon(dungeon_id: String) -> Array[String]:
	var flags: Array[String] = []
	var fragment := get_captains_log_fragment(dungeon_id)
	var save_flag := str(fragment.get("save_flag", ""))
	if save_flag != "":
		flags.append(save_flag)
	return flags

static func get_captains_log_ui_profile(profile: Dictionary) -> Dictionary:
	var entries: Array = []
	var unlocked_count: int = 0
	for dungeon_id in CAPTAINS_LOG_ORDER:
		var fragment: Dictionary = get_captains_log_fragment(str(dungeon_id))
		var fragment_id: String = str(fragment.get("id", ""))
		var save_flag: String = str(fragment.get("save_flag", ""))
		var unlocked: bool = DragonProgression.has_captains_log_fragment(profile, fragment_id) or (save_flag != "" and DragonProgression.has_mission_flag(profile, save_flag))
		if unlocked:
			unlocked_count += 1
		entries.append({
			"id": fragment_id,
			"title": fragment.get("title", "Captain's Log"),
			"summary": fragment.get("summary", "") if unlocked else "Signal fragment still encrypted. Complete the matching hardware dungeon.",
			"save_flag": save_flag,
			"unlocked": unlocked,
			"state_label": "READABLE" if unlocked else "LOCKED",
			"entry_color": Color("#70ff8f") if unlocked else Color("#8fe6ff"),
		})
	var total_count: int = CAPTAINS_LOG_ORDER.size()
	return {
		"title": "CAPTAIN'S LOG",
		"entries": entries,
		"unlocked_count": unlocked_count,
		"total_count": total_count,
		"completion_label": "%d/%d fragments" % [unlocked_count, total_count],
		"all_unlocked": unlocked_count == total_count,
		"presentation": "nes_log_index",
		"chrome_style": {
			"panel_kind": "captains_log_archive",
			"border_color": Color("#8fe6ff"),
			"fill_color": Color("#08141c"),
			"scanline_alpha": 0.07,
			"corner_cut": 4.0,
		},
	}

static func get_dungeon_completion_story_beat(dungeon_id: String) -> Dictionary:
	var beat: Dictionary = DUNGEON_COMPLETION_BEATS.get(dungeon_id, {})
	var result := beat.duplicate(true)
	var fragment := get_captains_log_fragment(dungeon_id)
	if not result.is_empty():
		result["dungeon_id"] = dungeon_id
		result["captains_log_title"] = fragment.get("title", "")
		result["captains_log_summary"] = fragment.get("summary", "")
		result["captains_log_flag"] = fragment.get("save_flag", "")
		result["presentation"] = "nes_story_card"
	return result

static func apply_dungeon_completion_rewards(dungeon_id: String, profile: Dictionary) -> Dictionary:
	var next := profile.duplicate(true)
	match dungeon_id:
		"cooling_intake":
			next = DragonProgression.grant_key_item(next, "cooling_intake_relay")
			next = DragonProgression.set_mission_flag(next, "dungeon_cooling_intake_complete")
		"southern_partition_airlock":
			next = DragonProgression.grant_key_item(next, "firewall_bypass")
			next = DragonProgression.set_mission_flag(next, "dungeon_southern_partition_airlock_complete")
		"great_buffer":
			next = ActTwoProgressionData.complete_great_buffer(next)
		"mirror_admin_gate":
			next = DragonProgression.set_mission_flag(next, "dungeon_mirror_admin_gate_complete")
			next = DragonProgression.set_mission_flag(next, "mirror_admin_sentinel_defeated")
			next = DragonProgression.grant_key_item(next, "admin_shard")
		"logic_core":
			next = ActTwoProgressionData.complete_logic_core(next)
		_:
			next = DragonProgression.set_mission_flag(next, "dungeon_%s_complete" % dungeon_id)
	next = DragonProgression.unlock_captains_log_fragment(next, get_captains_log_fragment(dungeon_id))
	return next

static func evaluate_dungeon_hazard(hazard_id: String, protected: bool, instability: float) -> Dictionary:
	var level := clampf(instability, 0.0, 1.0)
	match hazard_id:
		"white_out_purge":
			var safe := protected
			return {
				"safe": safe,
				"damage": 0.0 if safe else 0.75,
				"screen_state": "WHITEOUT",
			}
		"bit_rot_floor":
			return {
				"safe": protected,
				"damage": 0.35 if not protected else 0.0,
				"platform_de_rendered": level > 0.6,
			}
		"logic_grid":
			return {
				"safe": protected,
				"damage": 0.25 if not protected else 0.0,
				"timing_required": true,
			}
	return {
		"safe": protected,
		"damage": 0.0,
	}

static func get_hazard_vfx_profile(hazard_id: String, hazard_result: Dictionary = {}) -> Dictionary:
	var safe := bool(hazard_result.get("safe", false))
	match hazard_id:
		"steam_leak":
			return {
				"id": hazard_id,
				"burst_kind": "coolant_steam",
				"screen_effect": "heat_haze",
				"beam_color": Color("#ff9a4d"),
				"overlay_alpha": 0.22,
				"tile_filter": "heat_distort",
				"stripe_count": 4,
			}
		"white_out_purge":
			return {
				"id": hazard_id,
				"burst_kind": "coolant_steam",
				"screen_effect": "scanline_burst",
				"beam_color": Color("#f8fbff"),
				"overlay_alpha": 0.36 if safe else 0.62,
				"tile_filter": "whiteout",
				"stripe_count": 8,
			}
		"logic_grid", "laser_reroute":
			return {
				"id": hazard_id,
				"burst_kind": "prism",
				"screen_effect": "chromatic_glitch",
				"beam_color": Color("#58dbff"),
				"overlay_alpha": 0.30,
				"tile_filter": "diagnostic_laser",
				"stripe_count": 7,
			}
		"bit_rot_floor":
			return {
				"id": hazard_id,
				"burst_kind": "thread",
				"screen_effect": "chromatic_glitch",
				"beam_color": Color("#ff453a"),
				"overlay_alpha": 0.34,
				"tile_filter": "red_wireframe",
				"stripe_count": 5,
			}
		"syntax_blocks":
			return {
				"id": hazard_id,
				"burst_kind": "ascii_compile",
				"screen_effect": "scanline_burst",
				"beam_color": Color("#b084ff"),
				"overlay_alpha": 0.28,
				"tile_filter": "source_glyphs",
				"stripe_count": 6,
			}
	return {
		"id": hazard_id,
		"burst_kind": "thread",
		"screen_effect": "warning_pulse",
		"beam_color": Color("#ffd166"),
		"overlay_alpha": 0.22,
		"tile_filter": "warning",
		"stripe_count": 3,
	}

static func request_dragon_assist(dragon_form: String, target_system: String) -> Dictionary:
	if dragon_form == "magma_core" and target_system == "external_heat_sink":
		return {
			"success": true,
			"effect": "internal_platforms_expand",
			"animation": "dragon_breathes_through_viewport",
		}
	if dragon_form == "prism_stalk" and target_system == "sensor_array":
		return {
			"success": true,
			"effect": "hidden_laser_paths_revealed",
			"animation": "prism_refraction_from_background",
		}
	return {
		"success": false,
		"effect": "NO_ASSIST_AVAILABLE",
	}

static func get_dragon_assist_vfx_profile(assist_result: Dictionary) -> Dictionary:
	match str(assist_result.get("effect", "")):
		"internal_platforms_expand":
			return {
				"burst_kind": "magma",
				"screen_effect": "heat_haze",
				"support_window_label": "Magma-Core outside",
				"support_color": Color("#ff7a35"),
				"impact_flash": Color("#ff7a35", 0.28),
				"strip_path": "res://assets/vfx/generated/magma_core_bloom_strip.png",
				"lifetime": 0.82,
			}
		"hidden_laser_paths_revealed":
			return {
				"burst_kind": "prism",
				"screen_effect": "scanline_burst",
				"support_window_label": "Prism-Stalk outside",
				"support_color": Color("#58dbff"),
				"impact_flash": Color("#58dbff", 0.24),
				"strip_path": "res://assets/vfx/generated/prism_refraction_strip.png",
				"lifetime": 0.72,
			}
	return {
		"burst_kind": "thread",
		"screen_effect": "warning_pulse",
		"support_window_label": "No external lock",
		"support_color": Color("#ff453a"),
		"impact_flash": Color("#ff453a", 0.20),
		"lifetime": 0.48,
	}

static func get_completion_vfx_profile(dungeon_id: String) -> Dictionary:
	match dungeon_id:
		"cooling_intake":
			return {
				"burst_kind": "coolant_steam",
				"screen_effect": "heat_haze",
				"impact_flash": Color("#8fe6ff", 0.24),
				"relay_color": Color("#8fe6ff"),
				"lifetime": 0.82,
			}
		"southern_partition_airlock":
			return {
				"burst_kind": "wrench_sparks",
				"screen_effect": "warning_pulse",
				"impact_flash": Color("#ff6d5d", 0.24),
				"relay_color": Color("#ff6d5d"),
				"spark_count": 22,
				"lifetime": 0.7,
			}
		"great_buffer":
			return {
				"burst_kind": "prism",
				"screen_effect": "scanline_burst",
				"impact_flash": Color("#58dbff", 0.26),
				"relay_color": Color("#58dbff"),
				"strip_path": "res://assets/vfx/generated/prism_refraction_strip.png",
				"lifetime": 0.78,
			}
		"logic_core":
			return {
				"burst_kind": "ascii_compile",
				"screen_effect": "scanline_burst",
				"impact_flash": Color("#70ff8f", 0.28),
				"relay_color": Color("#70ff8f"),
				"strip_path": "res://assets/vfx/generated/ascii_compile_strip.png",
				"lifetime": 0.82,
			}
	return {
		"burst_kind": "shockwave",
		"screen_effect": "scanline_burst",
		"impact_flash": Color("#f8de9a", 0.18),
		"relay_color": Color("#f8de9a"),
		"lifetime": 0.62,
	}

static func dragon_safety_net(dragon_available: bool, fall_type: String) -> Dictionary:
	var caught := dragon_available and fall_type == "void"
	return {
		"caught": caught,
		"respawn": "room_start" if caught else "checkpoint",
		"damage": 0.0 if caught else 0.5,
	}

static func get_physical_anomaly(id: String) -> Dictionary:
	var anomaly: Dictionary = PHYSICAL_ANOMALIES.get(id, {})
	var result := anomaly.duplicate(true)
	if not result.is_empty():
		result["id"] = id
	return result

static func resolve_physical_anomaly(id: String, action_id: String) -> Dictionary:
	var anomaly := get_physical_anomaly(id)
	var success := not anomaly.is_empty() and str(anomaly.get("disable_action", "")) == action_id
	return {
		"success": success,
		"id": id,
		"action_id": action_id,
		"effect": "anomaly_core_disabled" if success else "anomaly_pressure_escalates",
		"required_action": anomaly.get("disable_action", ""),
	}

static func _dungeon_lock(reason: String) -> Dictionary:
	return {
		"allowed": false,
		"reason": reason,
	}

static func _has_key_item(profile: Dictionary, item_id: String) -> bool:
	return profile.get("key_items", []).has(item_id)

static func _has_flag(profile: Dictionary, flag_id: String) -> bool:
	return profile.get("mission_flags", []).has(flag_id)

static func evaluate_anomaly_pressure(id: String, phase: float, protected: bool) -> Dictionary:
	var wrapped_phase := fmod(maxf(0.0, phase), 1.0)
	match id:
		"indexer":
			var active := wrapped_phase >= 0.25 and wrapped_phase <= 0.55
			var telegraph := wrapped_phase >= 0.15 and wrapped_phase < 0.25
			var vulnerable := wrapped_phase > 0.55 and wrapped_phase <= 0.70
			var sweep_rect := _indexer_sweep_rect(wrapped_phase)
			return {
				"active": active,
				"telegraph_active": telegraph,
				"core_vulnerable": vulnerable,
				"safe": protected or not active,
				"label": "Sorting Arm Sweep",
				"telegraph_label": "Sorting Arm Sweep incoming",
				"vulnerability_label": "Arm Jam Window",
				"pattern_id": "horizontal_sort_sweep",
				"countdown": maxf(0.0, 0.25 - wrapped_phase),
				"damage": 0.35 if active and not protected else 0.0,
				"rect": sweep_rect,
				"rects": [sweep_rect],
				"safe_spots": [],
				"warning": "The Indexer sweeps the room for misfiled assets.",
			}
		"sentinel_drone":
			var active := wrapped_phase >= 0.62 and wrapped_phase <= 0.88
			var telegraph := wrapped_phase >= 0.52 and wrapped_phase < 0.62
			var vulnerable := wrapped_phase > 0.88 and wrapped_phase <= 0.98
			var columns := _sentinel_light_columns(wrapped_phase)
			return {
				"active": active,
				"telegraph_active": telegraph,
				"core_vulnerable": vulnerable,
				"safe": protected or not active,
				"label": "Lighting Weapon",
				"telegraph_label": "Diagnostic Lens Warning",
				"vulnerability_label": "Lens Recalibration Window",
				"pattern_id": "diagnostic_light_columns",
				"countdown": maxf(0.0, 0.62 - wrapped_phase),
				"damage": 0.45 if active and not protected else 0.0,
				"rect": columns[0],
				"rects": columns,
				"safe_spots": _sentinel_safe_spots(),
				"warning": "The Sentinel Drone fires only where the Diagnostic Lens cannot see safe spots.",
			}
		"mirror_admin_sentinel":
			var active := wrapped_phase >= 0.30 and wrapped_phase <= 0.62
			var telegraph := wrapped_phase >= 0.16 and wrapped_phase < 0.30
			var vulnerable := wrapped_phase > 0.62 and wrapped_phase <= 0.82
			var purge_rects := _mirror_admin_purge_rects(wrapped_phase)
			return {
				"active": active,
				"telegraph_active": telegraph,
				"core_vulnerable": vulnerable,
				"safe": protected or not active,
				"label": "Sector Purge",
				"telegraph_label": "Parity Scan",
				"vulnerability_label": "Shielded Port Seal",
				"pattern_id": "mirror_parity_scan" if telegraph else "admin_sector_purge" if active else "shielded_port_torque",
				"countdown": maxf(0.0, 0.30 - wrapped_phase),
				"damage": 0.52 if active and not protected else 0.0,
				"rect": purge_rects[0] if not purge_rects.is_empty() else Rect2(),
				"rects": purge_rects,
				"safe_spots": _mirror_admin_safe_ports(),
				"requires_torque_meter": active or vulnerable,
				"purge_pressure": clampf(0.48 + wrapped_phase * 0.72, 0.48, 1.0),
				"sfx": SfxData.get_anomaly_sfx("mirror_admin_sentinel", {
					"active": active,
					"telegraph_active": telegraph,
					"core_vulnerable": vulnerable,
				}),
				"warning": "Mirror Admin indexes the room, then turns the Tundra purge into a boss weapon.",
			}
	return {
		"active": false,
		"telegraph_active": false,
		"core_vulnerable": false,
		"safe": true,
		"label": "",
		"telegraph_label": "",
		"vulnerability_label": "",
		"pattern_id": "",
		"countdown": 0.0,
		"damage": 0.0,
		"rect": Rect2(),
		"rects": [],
		"safe_spots": [],
		"requires_torque_meter": false,
		"purge_pressure": 0.0,
		"warning": "",
	}

static func get_anomaly_vfx_profile(id: String, pressure: Dictionary) -> Dictionary:
	var active := bool(pressure.get("active", false))
	var telegraph := bool(pressure.get("telegraph_active", false))
	var vulnerable := bool(pressure.get("core_vulnerable", false))
	var profile := {
		"id": id,
		"warning_color": Color("#ff6b9a") if active else Color("#ffd166") if telegraph else Color("#70ff8f") if vulnerable else Color("#7b8b91"),
		"beam_color": Color("#58dbff") if id == "sentinel_drone" else Color("#ffd166"),
		"screen_effect": "chromatic_glitch" if active else "warning_pulse" if telegraph else "scanline_burst" if vulnerable else "none",
		"core_ring_count": 3 if vulnerable else 1 if telegraph else 0,
		"hazard_alpha": 0.62 if active else 0.32 if telegraph else 0.18,
		"debris_count": 10 if id == "indexer" and active else 4 if id == "indexer" else 0,
	}
	if id == "sentinel_drone":
		profile["safe_spot_color"] = Color("#70ff8f")
		profile["scanline_alpha"] = 0.22 if active else 0.12
	if id == "mirror_admin_sentinel":
		profile["warning_color"] = Color("#ffffff") if active else Color("#ff6b9a") if telegraph else Color("#70ff8f") if vulnerable else Color("#7b8b91")
		profile["beam_color"] = Color("#ffffff")
		profile["safe_spot_color"] = Color("#58dbff")
		profile["screen_effect"] = "scanline_burst" if active else "chromatic_glitch" if telegraph else "warning_pulse" if vulnerable else "none"
		profile["purge_ring_count"] = 4 if active else 2 if vulnerable else 1
		profile["core_ring_count"] = 5 if vulnerable else int(profile["core_ring_count"])
		profile["hazard_alpha"] = 0.78 if active else float(profile["hazard_alpha"])
		profile["scanline_alpha"] = 0.34 if active else 0.18
	return profile

static func _indexer_sweep_rect(wrapped_phase: float) -> Rect2:
	var normalized := clampf(inverse_lerp(0.25, 0.55, wrapped_phase), 0.0, 1.0)
	var x := lerpf(390.0, 790.0, normalized)
	return Rect2(x, 336, 260, 44)

static func _sentinel_light_columns(wrapped_phase: float) -> Array[Rect2]:
	var pulse := sin(wrapped_phase * TAU) * 18.0
	return [
		Rect2(310 + pulse, 180, 76, 380),
		Rect2(590 - pulse, 150, 76, 410),
		Rect2(870 + pulse, 180, 76, 380),
	]

static func _sentinel_safe_spots() -> Array[Rect2]:
	return [
		Rect2(435, 500, 110, 58),
		Rect2(715, 438, 110, 58),
	]

static func _mirror_admin_purge_rects(wrapped_phase: float) -> Array[Rect2]:
	var scan_offset := sin(wrapped_phase * TAU) * 34.0
	var sweep := clampf(inverse_lerp(0.30, 0.62, wrapped_phase), 0.0, 1.0)
	var lane_y := lerpf(188.0, 458.0, sweep)
	return [
		Rect2(258 + scan_offset, 150, 58, 410),
		Rect2(548 - scan_offset, 132, 64, 428),
		Rect2(840 + scan_offset * 0.5, 150, 58, 410),
		Rect2(288, lane_y, 680, 40),
	]

static func _mirror_admin_safe_ports() -> Array[Rect2]:
	return [
		Rect2(365, 492, 116, 62),
		Rect2(665, 492, 116, 62),
		Rect2(965, 492, 116, 62),
	]

static func _roster_has_enemy(enemies: Array, enemy_id: String) -> bool:
	for enemy in enemies:
		if str(enemy.get("id", "")) == enemy_id:
			return true
	return false
