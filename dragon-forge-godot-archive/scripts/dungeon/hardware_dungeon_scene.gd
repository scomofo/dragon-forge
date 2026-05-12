extends Control

signal dungeon_closed(profile: Dictionary, result: Dictionary)

const DragonProgression := preload("res://scripts/sim/dragon_progression.gd")
const HardwareDungeonData := preload("res://scripts/sim/hardware_dungeon_data.gd")
const ActTwoTundraData := preload("res://scripts/sim/act_two_tundra_data.gd")
const MainframeSpineData := preload("res://scripts/sim/mainframe_spine_data.gd")
const WeaverData := preload("res://scripts/sim/weaver_data.gd")
const BattleVfxData := preload("res://scripts/sim/battle_vfx_data.gd")
const ProceduralVfxOverlay := preload("res://scripts/vfx/procedural_vfx_overlay.gd")

const GRAVITY := 1500.0
const MOVE_SPEED := 260.0
const JUMP_SPEED := 560.0
const COYOTE_TIME := 0.11
const JUMP_BUFFER_TIME := 0.12
const FAST_FALL_MULTIPLIER := 1.28
const PLAYER_SIZE := Vector2(28, 42)
const VFX_FRAME_COUNT := 4

var dungeon_id := "cooling_intake"
var dungeon: Dictionary = {}
var profile: Dictionary = {}
var player_position := Vector2(84, 522)
var velocity := Vector2.ZERO
var grounded := false
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var completed_mechanisms := {}
var message := "Find the pressure valves. Space uses the 10mm Wrench."
var room_style := "tutorial_turbine"
var platforms: Array[Rect2] = []
var mechanisms: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var security_drones: Array[Dictionary] = []
var bit_rot_stalkers: Array[Dictionary] = []
var shielded_ports: Array[Dictionary] = []
var binary_tiles: Array[Dictionary] = []
var binary_gate: Dictionary = {}
var binary_guide: Dictionary = {}
var boss: Dictionary = {}
var boss_core_rect := Rect2(1040, 248, 70, 70)
var boss_defeated := false
var boss_phase := 0.35
var boss_pressure: Dictionary = {}
var dragon_assist_effects: Array[String] = []
var revealed_hazards: Array[String] = []
var ascii_puzzles: Array[Dictionary] = []
var solved_ascii_puzzles := {}
var utility_belt: Array[String] = []
var armor_overlay_state: Dictionary = {}
var support_window_vfx: Dictionary = {}
var procedural_vfx: ProceduralVfxOverlay
var strip_vfx_sprite: TextureRect
var strip_vfx_atlas: AtlasTexture
var strip_vfx_elapsed := 0.0
var strip_vfx_frame := 0
var strip_vfx_frame_time := 0.065
var strip_vfx_path := ""
var last_dungeon_vfx_strip_path := ""
var last_dungeon_vfx_kind := ""
var last_boss_warning_state := ""
var exit_rect := Rect2(1160, 440, 44, 96)
var room_complete := false
var last_access_port_puzzle_id := ""
var last_access_port_result: Dictionary = {}
var live_torque_meter: Dictionary = {}
var binary_puzzle_state: Dictionary = {}
var last_binary_tile_stand_index := -1
var binary_tile_flash_timers := {}
var last_binary_gate_event: Dictionary = {}
var binary_gate_flash_timer := 0.0
var last_relic_pickup_event: Dictionary = {}
var relic_pickup_flash_timer := 0.0
var completion_story_beat: Dictionary = {}
var sealed_shielded_ports := {}

func _ready() -> void:
	set_process(false)
	set_process_unhandled_input(false)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	procedural_vfx = ProceduralVfxOverlay.new()
	procedural_vfx.set_anchors_preset(Control.PRESET_FULL_RECT)
	procedural_vfx.z_index = 30
	add_child(procedural_vfx)

	strip_vfx_sprite = TextureRect.new()
	strip_vfx_sprite.visible = false
	strip_vfx_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	strip_vfx_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	strip_vfx_sprite.custom_minimum_size = Vector2(280, 156)
	strip_vfx_sprite.z_index = 28
	add_child(strip_vfx_sprite)

func start_dungeon(next_dungeon_id: String, next_profile: Dictionary) -> void:
	dungeon_id = next_dungeon_id
	dungeon = HardwareDungeonData.get_dungeon(dungeon_id)
	boss = HardwareDungeonData.get_dungeon_boss(dungeon_id)
	profile = next_profile.duplicate(true)
	player_position = Vector2(84, 522)
	velocity = Vector2.ZERO
	grounded = false
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	completed_mechanisms.clear()
	dragon_assist_effects.clear()
	revealed_hazards.clear()
	solved_ascii_puzzles.clear()
	boss_defeated = boss.is_empty()
	boss_phase = 0.35
	boss_pressure = HardwareDungeonData.evaluate_anomaly_pressure(str(boss.get("id", "")), boss_phase, _player_has_anomaly_protection())
	last_boss_warning_state = ""
	room_complete = false
	last_access_port_puzzle_id = ""
	last_access_port_result.clear()
	live_torque_meter.clear()
	binary_puzzle_state.clear()
	last_binary_tile_stand_index = -1
	binary_tile_flash_timers.clear()
	last_binary_gate_event.clear()
	binary_gate_flash_timer = 0.0
	last_relic_pickup_event.clear()
	relic_pickup_flash_timer = 0.0
	completion_story_beat.clear()
	sealed_shielded_ports.clear()
	message = _intro_message()
	_build_room()
	if is_inside_tree():
		grab_focus()
	set_process(true)
	set_process_unhandled_input(true)
	queue_redraw()

func get_boss_label() -> String:
	return str(boss.get("name", ""))

func get_boss_attack_label() -> String:
	return str(boss_pressure.get("label", ""))

func get_enemy_roster_hud_profile() -> Dictionary:
	var roster := HardwareDungeonData.get_dungeon_enemy_roster_profile(dungeon_id)
	var enemy_labels: Array[String] = []
	var counter_tools: Array[String] = []
	for enemy in roster.get("enemies", []):
		enemy_labels.append(str(enemy.get("name", "")))
		var counter_tool := str(enemy.get("counter_tool", ""))
		if counter_tool != "" and not counter_tools.has(counter_tool):
			counter_tools.append(counter_tool)
	return {
		"visible": int(roster.get("enemy_count", 0)) > 0,
		"dungeon_id": dungeon_id,
		"enemy_count": roster.get("enemy_count", 0),
		"enemy_labels": enemy_labels,
		"counter_tools": counter_tools,
		"has_platform_drone": roster.get("has_platform_drone", false),
		"has_static_stalker": roster.get("has_static_stalker", false),
		"presentation": "process_enemy_hud",
		"badge_labels": _enemy_roster_badges(roster),
		"panel_title": "PROCESS WATCH",
		"hud_color": Color("#58dbff") if dungeon_id == "great_buffer" else Color("#ff594d") if dungeon_id == "mirror_admin_gate" else Color("#ffd166"),
	}

func _enemy_roster_badges(roster: Dictionary) -> Array[String]:
	var badges: Array[String] = []
	if bool(roster.get("has_platform_drone", false)):
		badges.append("DRONE PLATFORM")
	if bool(roster.get("has_static_stalker", false)):
		badges.append("STATIC TRAIL")
	return badges

func get_boss_telegraph_label() -> String:
	if boss_pressure.has("telegraph_label") and str(boss_pressure["telegraph_label"]) != "":
		return str(boss_pressure["telegraph_label"])
	if boss_pressure.has("label") and str(boss_pressure["label"]) != "":
		return "%s incoming" % boss_pressure["label"]
	return ""

func get_boss_pattern_id() -> String:
	return str(boss_pressure.get("pattern_id", ""))

func get_status_message() -> String:
	return message

func get_interaction_prompt_profile() -> Dictionary:
	if not live_torque_meter.is_empty() and not bool(live_torque_meter.get("success", false)):
		var active_port_id := str(live_torque_meter.get("port_id", ""))
		if active_port_id != "":
			return {
				"visible": true,
				"presentation": "context_action_prompt",
				"action": "TORQUE",
				"label": "SPACE: HOLD GREEN BUFFER",
				"target_id": active_port_id,
				"prompt_color": Color("#70ff8f"),
			}
	for port in shielded_ports:
		var port_rect: Rect2 = port.get("rect", Rect2())
		if port_rect.grow(42.0).has_point(player_position):
			var port_id := str(port.get("id", ""))
			return {
				"visible": true,
				"presentation": "context_action_prompt",
				"action": "SEAL" if not is_shielded_port_sealed(port_id) else "SAFE",
				"label": "SPACE: SEAL PORT" if not is_shielded_port_sealed(port_id) else "PORT SEALED",
				"target_id": port_id,
				"prompt_color": Color("#58dbff") if not is_shielded_port_sealed(port_id) else Color("#70ff8f"),
			}
	var gate := get_binary_gate_profile()
	if bool(gate.get("visible", false)):
		var gate_rect: Rect2 = gate.get("rect", Rect2())
		if gate_rect.grow(42.0).has_point(player_position):
			var open := bool(gate.get("open", false))
			return {
				"visible": true,
				"presentation": "context_action_prompt",
				"action": "PASS" if open else "MATCH",
				"label": "CACHE GATE OPEN" if open else "MATCH BITS TO OPEN",
				"target_id": gate.get("id", "cache_gate"),
				"prompt_color": Color("#70ff8f") if open else Color("#ffd166"),
			}
	var guide := get_binary_guide_profile()
	if bool(guide.get("visible", false)):
		var guide_rect: Rect2 = guide.get("rect", Rect2())
		if guide_rect.grow(42.0).has_point(player_position):
			return {
				"visible": true,
				"presentation": "context_action_prompt",
				"action": "QUERY",
				"label": "SPACE: QUERY UNIT 08",
				"target_id": guide.get("id", "unit_08"),
				"prompt_color": guide.get("status_color", Color("#ffd166")),
			}
	for mechanism in mechanisms:
		var mechanism_rect: Rect2 = mechanism.get("rect", Rect2())
		if mechanism_rect.grow(42.0).has_point(player_position):
			var mechanism_id := str(mechanism.get("id", ""))
			var complete := completed_mechanisms.has(mechanism_id)
			var action := "READY" if complete else "CLAIM" if str(mechanism.get("mechanism", "")) == "optical_lens_cradle" else "WRENCH"
			var label := "%s READY" % mechanism.get("label", "Mechanism") if complete else "SPACE: CLAIM OPTICAL LENS" if str(mechanism.get("mechanism", "")) == "optical_lens_cradle" else "SPACE: USE 10MM WRENCH"
			return {
				"visible": true,
				"presentation": "context_action_prompt",
				"action": action,
				"label": label,
				"target_id": mechanism_id,
				"prompt_color": Color("#70ff8f") if complete else Color("#ffd166"),
			}
	return {
		"visible": false,
		"presentation": "context_action_prompt",
		"label": "",
	}

func set_player_position_for_test(next_position: Vector2) -> void:
	player_position = next_position
	velocity = Vector2.ZERO
	queue_redraw()

func apply_hazards_for_test() -> void:
	_apply_hazards()

func get_boss_core_vulnerable() -> bool:
	return bool(boss_pressure.get("core_vulnerable", false))

func set_boss_phase_for_test(phase: float) -> void:
	boss_phase = fmod(maxf(0.0, phase), 1.0)
	boss_pressure = HardwareDungeonData.evaluate_anomaly_pressure(str(boss.get("id", "")), boss_phase, _player_has_anomaly_protection())

func get_room_style() -> String:
	return room_style

func get_room_visual_profile() -> Dictionary:
	if room_style == "buffer_vault":
		return ActTwoTundraData.get_cache_vault_visual_profile()
	return {
		"aesthetic": room_style,
	}

func get_room_parallax_profile() -> Dictionary:
	if room_style != "buffer_vault":
		return {
			"enabled": false,
			"node_type": "ParallaxBackground",
			"layers": [],
			"hex_grid_drift": 0.0,
			"scanline_speed": 0.0,
		}
	return ActTwoTundraData.get_cache_vault_parallax_profile()

func get_torque_meter_hud_profile() -> Dictionary:
	if not live_torque_meter.is_empty():
		return live_torque_meter.duplicate(true)
	return HardwareDungeonData.get_torque_meter_hud_profile(last_access_port_puzzle_id, last_access_port_result)

func start_torque_meter_for_test(purge_pressure: float) -> void:
	live_torque_meter = HardwareDungeonData.create_torque_meter_state(purge_pressure)

func advance_torque_meter_for_test(delta: float, tightening: bool) -> Dictionary:
	if live_torque_meter.is_empty():
		start_torque_meter_for_test(0.5)
	return advance_active_torque_meter(delta, tightening)

func get_binary_display_hud_profile() -> Dictionary:
	if room_style != "buffer_vault":
		return {
			"visible": false,
		}
	if binary_puzzle_state.is_empty():
		binary_puzzle_state = HardwareDungeonData.create_binary_puzzle_state([1, 1, 0], [4, 2, 1], 6)
	var display: Dictionary = binary_puzzle_state.get("display", {})
	return display.duplicate(true)

func get_binary_floor_tile_profile() -> Dictionary:
	if binary_tiles.is_empty():
		return {
			"visible": false,
			"tile_count": 0,
			"tiles": [],
		}
	if binary_puzzle_state.is_empty():
		binary_puzzle_state = HardwareDungeonData.create_binary_puzzle_state([1, 1, 0], [4, 2, 1], 6)
	var bits: Array = binary_puzzle_state.get("bits", [])
	var tiles: Array = []
	for tile in binary_tiles:
		var tile_index := int(tile.get("tile_index", 0))
		var active := tile_index >= 0 and tile_index < bits.size() and int(bits[tile_index]) == 1
		tiles.append({
			"id": tile.get("id", ""),
			"tile_index": tile_index,
			"weight": tile.get("weight", 0),
			"rect": tile.get("rect", Rect2()),
			"bit": 1 if active else 0,
			"glow_color": Color("#58dbff") if active else Color("#56616f"),
			"status_label": "1" if active else "0",
			"flash_active": float(binary_tile_flash_timers.get(tile_index, 0.0)) > 0.0,
			"flash_timer": float(binary_tile_flash_timers.get(tile_index, 0.0)),
		})
	return {
		"visible": true,
		"presentation": "weighted_binary_floor_tiles",
		"tile_count": binary_tiles.size(),
		"tiles": tiles,
		"door_open": binary_puzzle_state.get("door_open", false),
		"current_decimal": binary_puzzle_state.get("current_decimal", 0),
		"target_decimal": binary_puzzle_state.get("target_decimal", 0),
	}

func get_binary_circuit_bus_profile() -> Dictionary:
	var floor_profile := get_binary_floor_tile_profile()
	var gate := get_binary_gate_profile()
	if not bool(floor_profile.get("visible", false)) or not bool(gate.get("visible", false)):
		return {
			"visible": false,
			"segments": [],
		}
	var segments: Array = []
	var gate_rect: Rect2 = gate.get("rect", Rect2())
	var gate_anchor := Vector2(gate_rect.position.x, gate_rect.get_center().y)
	for tile in floor_profile.get("tiles", []):
		var tile_rect: Rect2 = tile.get("rect", Rect2())
		var active := int(tile.get("bit", 0)) == 1
		segments.append({
			"tile_index": tile.get("tile_index", 0),
			"from": tile_rect.get_center(),
			"to": gate_anchor + Vector2(0.0, (float(tile.get("tile_index", 0)) - 1.0) * 14.0),
			"active": active,
			"color": Color("#58dbff") if active else Color("#56616f"),
			"pulse_alpha": 0.76 if active else 0.22,
		})
	return {
		"visible": true,
		"presentation": "binary_tile_to_gate_circuit_bus",
		"segment_count": segments.size(),
		"segments": segments,
		"gate_open": gate.get("open", false),
		"bus_color": Color("#70ff8f") if bool(gate.get("open", false)) else Color("#58dbff"),
	}

func get_binary_guide_profile() -> Dictionary:
	if binary_guide.is_empty() or room_style != "buffer_vault":
		return {
			"visible": false,
		}
	if binary_puzzle_state.is_empty():
		binary_puzzle_state = HardwareDungeonData.create_binary_puzzle_state([1, 1, 0], [4, 2, 1], 6)
	var current := int(binary_puzzle_state.get("current_decimal", 0))
	var target := int(binary_puzzle_state.get("target_decimal", 0))
	var matched := bool(binary_puzzle_state.get("door_open", false))
	var hint := "SUM ACCEPTED"
	var mood := "stable"
	var voice_line := "Gate handshake stable."
	if not matched:
		var delta := target - current
		hint = "ADD %d" % delta if delta > 0 else "SUB %d" % abs(delta)
		mood = "under_sum" if delta > 0 else "over_sum"
		voice_line = "Need more active weight." if delta > 0 else "Too much weight on the bus."
	return {
		"visible": true,
		"presentation": "unit_08_binary_hint_terminal",
		"id": binary_guide.get("id", "unit_08"),
		"name": binary_guide.get("name", "Unit 08"),
		"rect": binary_guide.get("rect", Rect2()),
		"current_decimal": current,
		"target_decimal": target,
		"matched": matched,
		"hint": hint,
		"mood": mood,
		"line": voice_line,
		"voice_line": voice_line,
		"readout_style": "accepted" if matched else "diagnostic_warning",
		"status_color": Color("#70ff8f") if matched else Color("#ffd166"),
	}

func interact_binary_guide() -> Dictionary:
	var guide := get_binary_guide_profile()
	if not bool(guide.get("visible", false)):
		return {
			"success": false,
			"reason": "NO_BINARY_GUIDE",
		}
	var rect: Rect2 = guide.get("rect", Rect2())
	if not rect.grow(40.0).has_point(player_position):
		return {
			"success": false,
			"reason": "OUT_OF_RANGE",
		}
	message = "%s: %s" % [guide.get("name", "Unit 08"), guide.get("voice_line", "")]
	queue_redraw()
	return {
		"success": true,
		"presentation": "unit_08_direct_readout",
		"guide": guide,
		"message": message,
	}

func use_context_action_for_test() -> void:
	_try_use_wrench()

func get_binary_gate_profile() -> Dictionary:
	if binary_gate.is_empty() or room_style != "buffer_vault":
		return {
			"visible": false,
		}
	if binary_puzzle_state.is_empty():
		binary_puzzle_state = HardwareDungeonData.create_binary_puzzle_state([1, 1, 0], [4, 2, 1], 6)
	var open := bool(binary_puzzle_state.get("door_open", false))
	return {
		"visible": true,
		"presentation": "physical_cache_gate",
		"id": binary_gate.get("id", "cache_gate"),
		"label": binary_gate.get("label", "CACHE GATE"),
		"rect": binary_gate.get("rect", Rect2()),
		"open": open,
		"current_decimal": binary_puzzle_state.get("current_decimal", 0),
		"target_decimal": binary_puzzle_state.get("target_decimal", 0),
		"status_label": "OPEN" if open else "LOCKED",
		"rail_color": Color("#70ff8f") if open else Color("#58dbff"),
		"bar_alpha": 0.16 if open else 0.72,
		"blocking": not open,
		"collision_layer": "none" if open else "solid_cache_gate",
		"flash_active": binary_gate_flash_timer > 0.0,
		"flash_timer": binary_gate_flash_timer,
		"flash_label": str(last_binary_gate_event.get("label", "")),
		"flash_color": last_binary_gate_event.get("relay_color", Color("#70ff8f") if open else Color("#58dbff")),
	}

func get_last_binary_gate_event_profile() -> Dictionary:
	return last_binary_gate_event.duplicate(true)

func get_last_relic_pickup_event_profile() -> Dictionary:
	return last_relic_pickup_event.duplicate(true)

func get_relic_pickup_card_profile() -> Dictionary:
	if last_relic_pickup_event.is_empty():
		return {
			"visible": false,
			"presentation": "analog_relic_pickup_card",
		}
	var color: Color = last_relic_pickup_event.get("relay_color", Color("#58dbff"))
	return {
		"visible": relic_pickup_flash_timer > 0.0,
		"presentation": "analog_relic_pickup_card",
		"label": last_relic_pickup_event.get("label", "ANALOG RELIC ACQUIRED"),
		"relic_id": last_relic_pickup_event.get("relic_id", ""),
		"source_id": last_relic_pickup_event.get("source_id", ""),
		"origin": last_relic_pickup_event.get("origin", Vector2.ZERO),
		"timer": relic_pickup_flash_timer,
		"ring_count": 3,
		"frame_color": color,
		"glow_color": color.lightened(0.18),
		"subtext": "SCHEMATIC UPLOAD READY",
		"icon": "optical_lens",
	}

func get_binary_gate_flash_profile() -> Dictionary:
	var gate := get_binary_gate_profile()
	return {
		"visible": bool(gate.get("visible", false)) and binary_gate_flash_timer > 0.0,
		"presentation": "cache_gate_state_flash",
		"timer": binary_gate_flash_timer,
		"label": gate.get("flash_label", ""),
		"color": gate.get("flash_color", Color("#70ff8f")),
		"gate_id": gate.get("id", "cache_gate"),
	}

func get_binary_tile_flash_profile(tile_index: int) -> Dictionary:
	return {
		"visible": float(binary_tile_flash_timers.get(tile_index, 0.0)) > 0.0,
		"presentation": "binary_floor_tile_flash",
		"tile_index": tile_index,
		"timer": float(binary_tile_flash_timers.get(tile_index, 0.0)),
		"color": Color("#f8fbff"),
	}

func get_completion_story_beat() -> Dictionary:
	return completion_story_beat.duplicate(true)

func toggle_binary_tile_for_test(tile_index: int) -> Dictionary:
	return _toggle_binary_tile(tile_index)

func update_binary_floor_tiles_for_test() -> Dictionary:
	_update_binary_floor_tiles()
	return get_binary_floor_tile_profile()

func resolve_binary_gate_collision_for_test(candidate_position: Vector2) -> Vector2:
	return _resolve_binary_gate_collision(candidate_position)

func _toggle_binary_tile(tile_index: int) -> Dictionary:
	if binary_puzzle_state.is_empty():
		binary_puzzle_state = HardwareDungeonData.create_binary_puzzle_state([1, 1, 0], [4, 2, 1], 6)
	var was_open := bool(binary_puzzle_state.get("door_open", false))
	binary_puzzle_state = HardwareDungeonData.toggle_binary_puzzle_tile(binary_puzzle_state, tile_index)
	if bool(binary_puzzle_state.get("last_toggle_valid", false)):
		binary_tile_flash_timers[tile_index] = 0.32
	var is_open := bool(binary_puzzle_state.get("door_open", false))
	if is_open:
		message = "Binary lock matched: CACHE SUM %d." % int(binary_puzzle_state.get("current_decimal", 0))
	else:
		message = "Binary lock reads %d. Target remains %d." % [int(binary_puzzle_state.get("current_decimal", 0)), int(binary_puzzle_state.get("target_decimal", 0))]
	if was_open != is_open:
		_emit_binary_gate_event(is_open)
	queue_redraw()
	return get_binary_display_hud_profile()

func _emit_binary_gate_event(open: bool) -> void:
	var gate := get_binary_gate_profile()
	var rect: Rect2 = gate.get("rect", Rect2())
	last_binary_gate_event = {
		"visible": true,
		"presentation": "cache_gate_relay_event",
		"event": "opened" if open else "locked",
		"label": "CACHE RELAY OPEN" if open else "CACHE RELAY LOCK",
		"burst_kind": "prism" if open else "thread",
		"screen_effect": "scanline_burst" if open else "warning_pulse",
		"relay_color": Color("#70ff8f") if open else Color("#ff594d"),
		"origin": rect.get_center(),
		"gate_id": gate.get("id", "cache_gate"),
	}
	binary_gate_flash_timer = 0.42
	emit_dungeon_vfx(str(last_binary_gate_event["burst_kind"]), rect.get_center(), last_binary_gate_event)
	emit_dungeon_screen_effect(str(last_binary_gate_event["screen_effect"]), 0.34 if open else 0.28, 0.18)

func get_movement_assist_profile() -> Dictionary:
	return {
		"coyote_time": COYOTE_TIME,
		"jump_buffer": JUMP_BUFFER_TIME,
		"fast_fall_multiplier": FAST_FALL_MULTIPLIER,
	}

func get_platform_count() -> int:
	return platforms.size()

func get_revealed_hazard_count() -> int:
	return revealed_hazards.size()

func get_ascii_puzzle_count() -> int:
	return ascii_puzzles.size()

func get_solved_ascii_puzzle_count() -> int:
	return solved_ascii_puzzles.size()

func get_security_drone_count() -> int:
	return security_drones.size()

func get_bit_rot_stalker_count() -> int:
	return bit_rot_stalkers.size()

func get_shielded_port_count() -> int:
	return shielded_ports.size()

func get_shielded_port_network_profile() -> Dictionary:
	var sealed_count := 0
	var labels: Array[String] = []
	for port in shielded_ports:
		var port_id := str(port.get("id", ""))
		var sealed := is_shielded_port_sealed(port_id)
		if sealed:
			sealed_count += 1
		labels.append("%s:%s" % [port.get("label", "Shielded Port"), "SEALED" if sealed else "OPEN"])
	return {
		"visible": shielded_ports.size() > 0,
		"presentation": "shielded_port_network_panel",
		"port_count": shielded_ports.size(),
		"sealed_count": sealed_count,
		"exposed_count": shielded_ports.size() - sealed_count,
		"purge_ready": sealed_count > 0,
		"labels": labels,
		"status_color": Color("#70ff8f") if sealed_count > 0 else Color("#58dbff"),
	}

func is_shielded_port_sealed(port_id: String) -> bool:
	return sealed_shielded_ports.has(port_id)

func get_shielded_port_profile(port_id: String) -> Dictionary:
	for port in shielded_ports:
		if str(port.get("id", "")) == port_id:
			var port_rect: Rect2 = port.get("rect", Rect2())
			var sealed := is_shielded_port_sealed(port_id)
			return {
				"id": port_id,
				"label": port.get("label", "Shielded Port"),
				"rect": port_rect,
				"purge_pressure": port.get("purge_pressure", 0.5),
				"presentation": "white_out_shelter_socket",
				"wrench_interaction": "torque_meter",
				"safe_zone": true,
				"sealed": sealed,
				"status_color": Color("#70ff8f") if sealed or (not live_torque_meter.is_empty() and str(live_torque_meter.get("port_id", "")) == port_id) else Color("#58dbff"),
			}
	return {}

func activate_shielded_port(port_id: String, purge_pressure: float = -1.0) -> Dictionary:
	for port in shielded_ports:
		if str(port.get("id", "")) != port_id:
			continue
		var pressure := float(port.get("purge_pressure", 0.5)) if purge_pressure < 0.0 else purge_pressure
		live_torque_meter = HardwareDungeonData.create_torque_meter_state(pressure)
		live_torque_meter["port_id"] = port_id
		live_torque_meter["source_id"] = "shielded_port"
		live_torque_meter["zone_label"] = "SEAL PORT"
		message = "%s: hold the green buffer to seal against the White-Out." % port.get("label", "Shielded Port")
		queue_redraw()
		return live_torque_meter.duplicate(true)
	return {
		"visible": false,
		"failure": "UNKNOWN_SHIELDED_PORT",
	}

func advance_active_torque_meter(delta: float, tightening: bool) -> Dictionary:
	if live_torque_meter.is_empty():
		return {
			"visible": false,
		}
	live_torque_meter = HardwareDungeonData.advance_torque_meter(live_torque_meter, delta, tightening)
	if bool(live_torque_meter.get("success", false)):
		var port_id := str(live_torque_meter.get("port_id", ""))
		if port_id != "":
			sealed_shielded_ports[port_id] = true
			message = "Shielded Port sealed. The White-Out breaks around the hatch."
			emit_dungeon_screen_effect("scanline_burst", 0.42, 0.2)
		live_torque_meter["zone_label"] = "PORT SEALED"
	queue_redraw()
	return get_torque_meter_hud_profile()

func get_bit_rot_static_trail_hazard_profile() -> Dictionary:
	var zones: Array = []
	for stalker in bit_rot_stalkers:
		var profile_state: Dictionary = ActTwoTundraData.get_bit_rot_trail_hazard_profile(stalker)
		zones.append_array(profile_state.get("zones", []))
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

func get_bit_rot_aftermath_profile() -> Dictionary:
	var residues: Array = []
	for stalker in bit_rot_stalkers:
		if not bool(stalker.get("de_rezzed", false)):
			continue
		var rect: Rect2 = stalker.get("rect", Rect2())
		var vfx: Dictionary = stalker.get("vfx_profile", {})
		residues.append({
			"id": stalker.get("id", ""),
			"rect": rect,
			"center": rect.get_center(),
			"glyph": ".",
			"screen_effect": vfx.get("screen_effect", "whiteout_pop"),
			"silhouette_color": vfx.get("silhouette_color", Color("#f4fbff")),
		})
	return {
		"visible": residues.size() > 0,
		"presentation": "whiteout_ascii_residue",
		"residue_count": residues.size(),
		"residues": residues,
		"label": "DE-REZZED",
		"status_color": Color("#f4fbff"),
	}

func get_bit_rot_stalker_state_for_test(stalker_id: String) -> Dictionary:
	for stalker in bit_rot_stalkers:
		if str(stalker.get("id", "")) == stalker_id:
			return stalker.duplicate(true)
	return {}

func get_frozen_security_drone_count() -> int:
	var count := 0
	for drone in security_drones:
		if str(drone.get("state", "")) == ActTwoTundraData.DRONE_STATE_FROZEN:
			count += 1
	return count

func get_frozen_drone_platform_count() -> int:
	var count := 0
	for drone in security_drones:
		if bool(drone.get("is_solid_platform", false)):
			count += 1
	return count

func get_security_drone_collision_profile(drone_id: String) -> Dictionary:
	for drone in security_drones:
		if str(drone.get("id", "")) == drone_id:
			return drone.get("collision_profile", {}).duplicate(true)
	return {}

func get_last_dungeon_vfx_strip_path() -> String:
	return last_dungeon_vfx_strip_path

func get_last_dungeon_vfx_kind() -> String:
	return last_dungeon_vfx_kind

func get_active_armor_vfx_profile() -> Dictionary:
	return WeaverData.get_armor_vfx_profile(armor_overlay_state)

func get_exit_vfx_profile() -> Dictionary:
	var unlocked := is_exit_unlocked()
	return {
		"screen_effect": "scanline_burst" if unlocked else "none",
		"ring_count": 3 if unlocked else 1,
		"relay_color": Color("#62e8ff") if unlocked else Color("#506373"),
		"label": "EXIT LIVE" if unlocked else "EXIT LOCK",
		"pulse_alpha": 0.42 if unlocked else 0.12,
	}

func get_ambient_vfx_profile() -> Dictionary:
	match room_style:
		"vertical_data_conduit":
			return {
				"ascii_density": 18,
				"coolant_motes": 4,
				"steam_columns": 0,
				"scanline_alpha": 0.18,
			}
		"buffer_vault":
			return {
				"ascii_density": 11,
				"coolant_motes": 16,
				"steam_columns": 1,
				"scanline_alpha": 0.14,
				"code_rain_layers": 3,
				"hex_grid_alpha": 0.16,
			}
		"firewall_breach":
			return {
				"ascii_density": 10,
				"coolant_motes": 3,
				"steam_columns": 0,
				"scanline_alpha": 0.22,
			}
	return {
		"ascii_density": 4,
		"coolant_motes": 8,
		"steam_columns": 3,
		"scanline_alpha": 0.1,
	}

func configure_utility_belt(tool_ids: Array, slot_count: int) -> Dictionary:
	var result := HardwareDungeonData.configure_utility_belt(tool_ids, slot_count)
	utility_belt.clear()
	for tool in result.get("equipped_tools", []):
		utility_belt.append(str(tool))
	if not utility_belt.is_empty():
		var labels: Array[String] = []
		for tool_id in utility_belt:
			labels.append(_tool_label(str(tool_id)))
		message = "Utility belt loaded: %s." % ", ".join(labels)
		queue_redraw()
	return result

func has_equipped_tool(tool_id: String) -> bool:
	return utility_belt.has(tool_id)

func get_utility_belt_hud_profile() -> Dictionary:
	var labels: Array[String] = []
	var sockets: Array = []
	var index := 1
	for tool in utility_belt:
		var tool_id := str(tool)
		var label := _tool_label(tool_id)
		labels.append(label)
		sockets.append({
			"slot": index,
			"tool_id": tool_id,
			"label": label,
			"icon": _tool_icon(tool_id),
			"color": _tool_color(tool_id),
			"role": _tool_role(tool_id),
		})
		index += 1
	return {
		"visible": not utility_belt.is_empty(),
		"presentation": "side_scroller_utility_belt_hud",
		"socket_count": sockets.size(),
		"sockets": sockets,
		"label": "UTILITY BELT",
		"carried_label": ", ".join(labels) if not labels.is_empty() else "EMPTY",
		"frame_color": Color("#ffd166") if utility_belt.has("10mm_wrench") else Color("#8fe6ff"),
	}

func equip_armor_overlay(armor_id: String) -> Dictionary:
	var base_state := {
		"integrity": 0.4,
		"input_lag": 0.25,
		"traction": 0.65,
	}
	armor_overlay_state = WeaverData.apply_armor_overlay(armor_id, base_state)
	message = "Weaver overlay equipped: %s." % armor_id
	var armor_vfx := get_active_armor_vfx_profile()
	if str(armor_vfx.get("screen_effect", "none")) != "none":
		emit_dungeon_screen_effect(str(armor_vfx["screen_effect"]), 0.34, 0.18)
	queue_redraw()
	return armor_overlay_state.duplicate(true)

func solve_access_port_puzzle(puzzle_id: String, context: Dictionary) -> Dictionary:
	var tools: Array = []
	for tool in utility_belt:
		tools.append(tool)
	if context.has("tool") and not tools.has(context["tool"]):
		tools.append(context["tool"])
	var result := HardwareDungeonData.resolve_access_port_puzzle(puzzle_id, tools, context)
	last_access_port_puzzle_id = puzzle_id
	last_access_port_result = result.duplicate(true)
	message = "%s: %s." % [puzzle_id, "resolved" if result.get("success", false) else result.get("failure", "blocked")]
	var access_vfx := HardwareDungeonData.get_access_port_vfx_profile(puzzle_id, result)
	emit_dungeon_vfx(str(access_vfx.get("burst_kind", "shockwave")), player_position, access_vfx)
	var screen_effect := str(access_vfx.get("screen_effect", "none"))
	if screen_effect != "none":
		emit_dungeon_screen_effect(screen_effect, 0.42, 0.2)
	queue_redraw()
	return result

func emit_dungeon_vfx(kind: String, origin: Vector2, profile: Dictionary = {}) -> void:
	last_dungeon_vfx_kind = kind
	_play_dungeon_vfx_strip(str(profile.get("strip_path", "")), origin)
	if procedural_vfx == null:
		return
	procedural_vfx.emit_burst(kind, origin, profile)

func emit_dungeon_screen_effect(effect_id: String, intensity: float, duration: float) -> void:
	if procedural_vfx == null:
		return
	procedural_vfx.emit_screen_effect(effect_id, intensity, duration)

func trigger_logic_pulse() -> Dictionary:
	if not live_torque_meter.is_empty() and not bool(live_torque_meter.get("success", false)):
		return advance_active_torque_meter(0.18, true)
	if security_drones.is_empty():
		return {
			"success": false,
			"reason": "NO_DRONES",
			"affected": 0,
		}
	if not DragonProgression.has_key_item(profile, "wrench_overclock"):
		for index in security_drones.size():
			security_drones[index] = ActTwoTundraData.apply_logic_pulse_to_drone(security_drones[index], false)
		message = "Logic Pulse pings the drones, but the Wrench Overclock is missing."
		queue_redraw()
		return {
			"success": false,
			"reason": "WRENCH_OVERCLOCK_REQUIRED",
			"affected": security_drones.size(),
		}
	var affected := 0
	for index in security_drones.size():
		var drone: Dictionary = security_drones[index]
		var rect: Rect2 = drone.get("rect", Rect2())
		if rect.grow(520.0).has_point(player_position):
			security_drones[index] = ActTwoTundraData.apply_logic_pulse_to_drone(drone, true)
			affected += 1
	if affected > 0:
		message = "Logic Pulse froze %d Type-S drone%s into a platform." % [affected, "" if affected == 1 else "s"]
		emit_dungeon_screen_effect("scanline_burst", 0.38, 0.18)
	else:
		message = "Logic Pulse expands, but no drone is in range."
	queue_redraw()
	return {
		"success": affected > 0,
		"reason": "" if affected > 0 else "NO_DRONE_IN_RANGE",
		"affected": affected,
	}

func advance_security_drones_for_test(delta: float) -> void:
	_update_security_drones(delta)

func advance_bit_rot_stalkers_for_test(delta: float, skye_position: Vector2, white_out_active: bool) -> void:
	_update_bit_rot_stalkers(delta, skye_position, white_out_active)

func resolve_bit_rot_stalkers_white_out_for_test() -> void:
	_resolve_bit_rot_stalkers_white_out()

func solve_ascii_puzzle(puzzle_id: String, tool_or_armor: String) -> Dictionary:
	for puzzle in ascii_puzzles:
		if str(puzzle.get("id", "")) != puzzle_id:
			continue
		var result := _resolve_ascii_puzzle(puzzle, tool_or_armor)
		if bool(result.get("success", false)):
			solved_ascii_puzzles[puzzle_id] = true
			message = "%s compiled: %s." % [puzzle.get("label", "ASCII Puzzle"), result.get("status", "OK")]
			var compile_profile := BattleVfxData.get_dungeon_vfx_profile("ascii_compile")
			var puzzle_rect: Rect2 = puzzle.get("rect", Rect2())
			emit_dungeon_vfx("ascii_compile", puzzle_rect.get_center(), compile_profile)
			emit_dungeon_screen_effect("scanline_burst", 0.46, 0.22)
		else:
			message = "%s rejected: %s required." % [puzzle.get("label", "ASCII Puzzle"), result.get("required", "ASCII_AEGIS")]
		queue_redraw()
		return result
	return {
		"success": false,
		"status": "PUZZLE_NOT_FOUND",
		"required": "",
	}

func trigger_dragon_assist(target_system: String) -> Dictionary:
	var result := HardwareDungeonData.request_dragon_assist(_active_dragon_form(), target_system)
	if not result["success"]:
		message = "The dragon cannot reach that system from outside."
		support_window_vfx = HardwareDungeonData.get_dragon_assist_vfx_profile(result)
		return result
	support_window_vfx = HardwareDungeonData.get_dragon_assist_vfx_profile(result)
	if not dragon_assist_effects.has(str(result["effect"])):
		dragon_assist_effects.append(str(result["effect"]))
	match str(result["effect"]):
		"internal_platforms_expand":
			platforms.append(Rect2(940, 388, 160, 24))
			message = "Magma-Core breath expands an internal service bridge."
			emit_dungeon_vfx(str(support_window_vfx.get("burst_kind", "magma")), Vector2(980, 250), support_window_vfx)
		"hidden_laser_paths_revealed":
			for hazard in hazards:
				if str(hazard.get("id", "")) == "laser_reroute" or str(hazard.get("id", "")) == "logic_grid":
					var hazard_key := "%s:%s" % [hazard.get("id", ""), hazard.get("rect", Rect2())]
					if not revealed_hazards.has(hazard_key):
						revealed_hazards.append(hazard_key)
			message = "Prism-Stalk refracts the sensor array. Hidden laser paths appear."
			emit_dungeon_vfx(str(support_window_vfx.get("burst_kind", "prism")), Vector2(720, 250), support_window_vfx)
		_:
			message = "The dragon shifts the dungeon from outside: %s." % result["effect"]
	var screen_effect := str(support_window_vfx.get("screen_effect", "none"))
	if screen_effect != "none":
		emit_dungeon_screen_effect(screen_effect, 0.42, 0.24)
	queue_redraw()
	return result

func complete_mechanism(mechanism_id: String) -> void:
	completed_mechanisms[mechanism_id] = true

func is_exit_unlocked() -> bool:
	return _all_mechanisms_complete() and _boss_complete()

func disable_boss_core(action_id: String) -> bool:
	if boss.is_empty():
		return true
	if not get_boss_core_vulnerable():
		message = "%s core is shielded. Wait for %s." % [boss.get("name", "Anomaly"), boss_pressure.get("vulnerability_label", "the recovery window")]
		return false
	var result := HardwareDungeonData.resolve_physical_anomaly(str(boss.get("id", "")), action_id)
	if result["success"]:
		boss_defeated = true
		message = "%s disabled: %s." % [boss.get("name", "Anomaly"), result["effect"]]
		if is_exit_unlocked():
			var exit_vfx := get_exit_vfx_profile()
			emit_dungeon_screen_effect(str(exit_vfx.get("screen_effect", "scanline_burst")), 0.46, 0.24)
		return true
	message = "%s resists. Required: %s." % [boss.get("name", "Anomaly"), result["required_action"]]
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed():
		return
	if event.is_action_pressed("cancel"):
		_return_to_overworld(false)
	elif event.is_action_pressed("confirm"):
		if trigger_logic_pulse().get("success", false):
			return
		_try_use_wrench()
	elif event.is_action_pressed("move_up"):
		jump_buffer_timer = JUMP_BUFFER_TIME

func _process(delta: float) -> void:
	_update_security_drones(delta)
	_update_bit_rot_stalkers(delta, player_position, _white_out_pressure_active())
	_apply_movement(delta)
	_update_binary_floor_tiles()
	_update_binary_tile_flash_timers(delta)
	binary_gate_flash_timer = maxf(0.0, binary_gate_flash_timer - maxf(0.0, delta))
	relic_pickup_flash_timer = maxf(0.0, relic_pickup_flash_timer - maxf(0.0, delta))
	_update_dungeon_vfx_strip(delta)
	_update_boss_pressure(delta)
	_apply_hazards()
	_check_exit()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _room_backdrop_color())
	_draw_background_systems()
	_draw_binary_circuit_bus()
	for platform in platforms:
		_draw_platform(platform)
	for tile in binary_tiles:
		_draw_binary_floor_tile(tile)
	_draw_binary_gate()
	_draw_binary_guide()
	for hazard in hazards:
		_draw_hazard(hazard)
	for drone in security_drones:
		_draw_security_drone(drone)
	_draw_bit_rot_trails()
	for stalker in bit_rot_stalkers:
		_draw_bit_rot_stalker(stalker)
	for port in shielded_ports:
		_draw_shielded_port(port)
	for mechanism in mechanisms:
		_draw_mechanism(mechanism)
	_draw_relic_pickup_world_burst()
	for puzzle in ascii_puzzles:
		_draw_ascii_puzzle(puzzle)
	_draw_exit()
	_draw_boss_attack()
	_draw_boss_pressure()
	_draw_boss_core()
	_draw_player()

	_draw_hud()

func _build_room() -> void:
	var layout := HardwareDungeonData.get_room_layout(dungeon_id)
	room_style = str(layout.get("style", "tutorial_turbine"))
	platforms.assign(layout.get("platforms", []))
	mechanisms.assign(layout.get("mechanisms", []))
	hazards.assign(layout.get("hazards", []))
	security_drones.clear()
	for drone_config in layout.get("security_drones", []):
		var rect: Rect2 = drone_config.get("rect", Rect2())
		security_drones.append(ActTwoTundraData.create_security_drone_state(
			str(drone_config.get("id", "type_s")),
			rect,
			float(drone_config.get("patrol_min_x", rect.position.x)),
			float(drone_config.get("patrol_max_x", rect.position.x))
		))
	bit_rot_stalkers.clear()
	for stalker_config in layout.get("bit_rot_stalkers", []):
		var stalker_rect: Rect2 = stalker_config.get("rect", Rect2())
		bit_rot_stalkers.append(ActTwoTundraData.create_bit_rot_stalker_state(
			str(stalker_config.get("id", "stalker")),
			stalker_rect,
			stalker_config.get("shelter_position", stalker_rect.position)
		))
	shielded_ports.assign(layout.get("shielded_ports", []))
	binary_tiles.assign(layout.get("binary_tiles", []))
	binary_gate = layout.get("binary_gate", {}).duplicate(true)
	binary_guide = layout.get("binary_guide", {}).duplicate(true)
	ascii_puzzles.assign(layout.get("ascii_puzzles", []))
	if room_style == "buffer_vault":
		binary_puzzle_state = HardwareDungeonData.create_binary_puzzle_state([1, 1, 0], [4, 2, 1], 6)
	exit_rect = layout.get("exit_rect", Rect2(1160, 430, 54, 148))
	boss_core_rect = layout.get("boss_core_rect", Rect2(1040, 248, 70, 70))

func _apply_movement(delta: float) -> void:
	var input_axis := Input.get_axis("move_left", "move_right")
	velocity.x = input_axis * MOVE_SPEED
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	if grounded:
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = -JUMP_SPEED
		grounded = false
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
	var gravity_scale := FAST_FALL_MULTIPLIER if velocity.y > 0.0 and Input.is_action_pressed("move_down") else 1.0
	velocity.y += GRAVITY * gravity_scale * delta
	var next_position := player_position + velocity * delta

	grounded = false
	var player_rect := Rect2(next_position - PLAYER_SIZE * 0.5, PLAYER_SIZE)
	for platform in _solid_platforms():
		var previous_bottom := player_position.y + PLAYER_SIZE.y * 0.5
		if velocity.y >= 0.0 and previous_bottom <= platform.position.y and player_rect.intersects(platform):
			next_position.y = platform.position.y - PLAYER_SIZE.y * 0.5
			velocity.y = 0.0
			grounded = true
			player_rect = Rect2(next_position - PLAYER_SIZE * 0.5, PLAYER_SIZE)

	next_position = _resolve_binary_gate_collision(next_position)
	next_position.x = clampf(next_position.x, 28.0, size.x - 28.0)
	if next_position.y > size.y + 80.0:
		var safety := HardwareDungeonData.dragon_safety_net(true, "void")
		message = "The dragon catches Skye and drops her at the room start." if safety["caught"] else "Skye falls back to the checkpoint."
		next_position = Vector2(84, 522)
		velocity = Vector2.ZERO
	player_position = next_position

func _resolve_binary_gate_collision(candidate_position: Vector2) -> Vector2:
	var gate := get_binary_gate_profile()
	if not bool(gate.get("visible", false)) or not bool(gate.get("blocking", false)):
		return candidate_position
	var gate_rect: Rect2 = gate.get("rect", Rect2())
	if gate_rect.size.x <= 0.0:
		return candidate_position
	var player_rect := Rect2(candidate_position - PLAYER_SIZE * 0.5, PLAYER_SIZE)
	if not player_rect.intersects(gate_rect):
		return candidate_position
	var resolved := candidate_position
	if player_position.x <= gate_rect.position.x:
		resolved.x = gate_rect.position.x - PLAYER_SIZE.x * 0.5
	else:
		resolved.x = gate_rect.end.x + PLAYER_SIZE.x * 0.5
	velocity.x = 0.0
	message = "Cache Gate is solid until the binary sum matches."
	return resolved

func _solid_platforms() -> Array[Rect2]:
	var solid: Array[Rect2] = platforms.duplicate()
	for drone in security_drones:
		var collision_profile: Dictionary = drone.get("collision_profile", {})
		if bool(drone.get("is_solid_platform", false)) and bool(collision_profile.get("standable", false)):
			var platform_rect: Rect2 = drone.get("platform_rect", Rect2())
			if platform_rect.size.x > 0.0 and platform_rect.size.y > 0.0:
				solid.append(platform_rect)
	return solid

func _update_security_drones(delta: float) -> void:
	for index in security_drones.size():
		security_drones[index] = ActTwoTundraData.advance_security_drone(security_drones[index], delta)

func _update_bit_rot_stalkers(delta: float, skye_position: Vector2, white_out_active: bool) -> void:
	for index in bit_rot_stalkers.size():
		bit_rot_stalkers[index] = ActTwoTundraData.advance_bit_rot_stalker(bit_rot_stalkers[index], delta, skye_position, white_out_active)

func _update_binary_floor_tiles() -> void:
	if binary_tiles.is_empty():
		last_binary_tile_stand_index = -1
		return
	var player_feet := Vector2(player_position.x, player_position.y + PLAYER_SIZE.y * 0.5 + 2.0)
	var current_tile_index := -1
	for tile in binary_tiles:
		var rect: Rect2 = tile.get("rect", Rect2())
		if rect.grow(4.0).has_point(player_feet):
			current_tile_index = int(tile.get("tile_index", -1))
			break
	if current_tile_index == -1:
		last_binary_tile_stand_index = -1
		return
	if current_tile_index != last_binary_tile_stand_index:
		_toggle_binary_tile(current_tile_index)
		last_binary_tile_stand_index = current_tile_index

func _update_binary_tile_flash_timers(delta: float) -> void:
	var expired: Array = []
	for key in binary_tile_flash_timers.keys():
		var timer := maxf(0.0, float(binary_tile_flash_timers[key]) - maxf(0.0, delta))
		if timer <= 0.0:
			expired.append(key)
		else:
			binary_tile_flash_timers[key] = timer
	for key in expired:
		binary_tile_flash_timers.erase(key)

func _white_out_pressure_active() -> bool:
	if str(boss_pressure.get("pattern_id", "")) == "admin_sector_purge" and bool(boss_pressure.get("active", false)):
		return true
	for hazard in hazards:
		if str(hazard.get("id", "")) == "white_out_purge" and not _hazard_disabled(hazard):
			return true
	return false

func _is_rect_inside_sealed_shielded_port(rect: Rect2) -> bool:
	for port in shielded_ports:
		var port_id := str(port.get("id", ""))
		if not is_shielded_port_sealed(port_id):
			continue
		var port_rect: Rect2 = port.get("rect", Rect2())
		if port_rect.intersects(rect) or port_rect.has_point(rect.get_center()):
			return true
	return false

func _resolve_bit_rot_stalkers_white_out() -> void:
	for index in bit_rot_stalkers.size():
		var stalker: Dictionary = bit_rot_stalkers[index]
		var rect: Rect2 = stalker.get("rect", Rect2())
		var protected_by_port := _is_rect_inside_sealed_shielded_port(rect)
		bit_rot_stalkers[index] = ActTwoTundraData.resolve_bit_rot_stalker_white_out(stalker, protected_by_port)

func _apply_hazards() -> void:
	var player_rect := Rect2(player_position - PLAYER_SIZE * 0.5, PLAYER_SIZE)
	if not boss_defeated and bool(boss_pressure.get("active", false)):
		for attack_rect in _boss_attack_rects():
			if attack_rect.intersects(player_rect) and not bool(boss_pressure.get("safe", true)):
				message = "Anomaly hit: %s. The dragon yanks Skye out of the line." % boss_pressure.get("label", "pressure")
				player_position = Vector2(maxf(84.0, player_position.x - 130.0), 522)
				velocity = Vector2.ZERO
	var trail_profile := get_bit_rot_static_trail_hazard_profile()
	for zone in trail_profile.get("zones", []):
		var trail_rect: Rect2 = zone.get("rect", Rect2())
		if trail_rect.intersects(player_rect):
			message = "Bit-Rot static clings to Skye's boots. Find clean ground."
			velocity.x *= 0.35
	for hazard in hazards:
		if _hazard_disabled(hazard):
			continue
		var rect: Rect2 = hazard["rect"]
		if rect.intersects(player_rect):
			if str(hazard.get("id", "")) == "white_out_purge" and _is_rect_inside_sealed_shielded_port(player_rect):
				message = "Shielded Port holds. The White-Out peels around Skye."
				_resolve_bit_rot_stalkers_white_out()
				return
			if str(hazard.get("id", "")) == "white_out_purge":
				_resolve_bit_rot_stalkers_white_out()
			var result := HardwareDungeonData.evaluate_dungeon_hazard(hazard["id"], false, 0.8)
			var hazard_vfx := HardwareDungeonData.get_hazard_vfx_profile(str(hazard["id"]), result)
			emit_dungeon_vfx(str(hazard_vfx.get("burst_kind", "thread")), rect.get_center(), hazard_vfx)
			var screen_effect := str(hazard_vfx.get("screen_effect", "none"))
			if screen_effect != "none":
				emit_dungeon_screen_effect(screen_effect, 0.48, 0.22)
			message = "Hazard hit: %s. The dragon pulls Skye clear." % hazard["id"]
			player_position = Vector2(maxf(84.0, player_position.x - 120.0), 522)
			velocity = Vector2.ZERO
			if result.get("platform_de_rendered", false):
				message = "Bit-rot de-rendered the floor. The dragon catches Skye."
			return

func _try_use_wrench() -> void:
	for puzzle in ascii_puzzles:
		if solved_ascii_puzzles.has(puzzle.get("id", "")):
			continue
		var puzzle_rect: Rect2 = puzzle["rect"]
		if puzzle_rect.grow(34.0).has_point(player_position):
			solve_ascii_puzzle(str(puzzle.get("id", "")), "10mm_wrench")
			return
	if not boss.is_empty() and _all_mechanisms_complete() and not boss_defeated and boss_core_rect.grow(38.0).has_point(player_position):
		disable_boss_core(str(boss.get("disable_action", "")))
		return
	for port in shielded_ports:
		var port_rect: Rect2 = port.get("rect", Rect2())
		if port_rect.grow(34.0).has_point(player_position):
			activate_shielded_port(str(port.get("id", "")))
			return
	if interact_binary_guide().get("success", false):
		return
	for mechanism in mechanisms:
		var rect: Rect2 = mechanism["rect"].grow(34.0)
		if rect.has_point(player_position):
			if completed_mechanisms.has(mechanism["id"]):
				message = "%s is already fixed." % mechanism["label"]
				return
			if str(mechanism.get("mechanism", "")) == "optical_lens_cradle":
				_claim_optical_lens_cradle(mechanism)
				return
			var result := HardwareDungeonData.use_wrench_on_mechanism(mechanism["mechanism"], _required_tool_for(mechanism["mechanism"]))
			var mechanism_vfx := HardwareDungeonData.get_mechanism_vfx_profile(str(mechanism["mechanism"]), result)
			emit_dungeon_vfx(str(mechanism_vfx.get("burst_kind", "wrench_sparks")), rect.get_center(), mechanism_vfx)
			var screen_effect := str(mechanism_vfx.get("screen_effect", "none"))
			if screen_effect != "none":
				emit_dungeon_screen_effect(screen_effect, 0.4, 0.18)
			if result["success"]:
				completed_mechanisms[mechanism["id"]] = true
				message = "%s: %s." % [mechanism["label"], result["effect"]]
				if _all_mechanisms_complete():
					message += " The anomaly core is exposed." if not _boss_complete() else " The exit relay is live."
			else:
				message = "Wrong tool. Required: %s." % result["required_relic"]
			return
	message = "No physical mechanism in wrench range."

func _claim_optical_lens_cradle(mechanism: Dictionary) -> void:
	completed_mechanisms[mechanism["id"]] = true
	var rect: Rect2 = mechanism.get("rect", Rect2())
	last_relic_pickup_event = {
		"visible": true,
		"presentation": "analog_relic_pickup",
		"relic_id": "optical_lens",
		"label": "OPTICAL LENS ACQUIRED",
		"source_id": mechanism.get("id", "lens_cradle"),
		"burst_kind": "prism",
		"screen_effect": "scanline_burst",
		"origin": rect.get_center(),
		"relay_color": Color("#58dbff"),
	}
	relic_pickup_flash_timer = 1.6
	message = "Optical Lens acquired. The cache light bends around Skye's HUD."
	emit_dungeon_vfx("prism", rect.get_center(), last_relic_pickup_event)
	emit_dungeon_screen_effect("scanline_burst", 0.5, 0.24)
	if _all_mechanisms_complete():
		message += " The anomaly core is exposed." if not _boss_complete() else " The exit relay is live."
	queue_redraw()

func _check_exit() -> void:
	if room_complete or not is_exit_unlocked():
		return
	var player_rect := Rect2(player_position - PLAYER_SIZE * 0.5, PLAYER_SIZE)
	if player_rect.intersects(exit_rect):
		_complete_dungeon()

func _complete_dungeon() -> void:
	room_complete = true
	var completion_vfx := HardwareDungeonData.get_completion_vfx_profile(dungeon_id)
	emit_dungeon_vfx(str(completion_vfx.get("burst_kind", "shockwave")), exit_rect.get_center(), completion_vfx)
	var screen_effect := str(completion_vfx.get("screen_effect", "none"))
	if screen_effect != "none":
		emit_dungeon_screen_effect(screen_effect, 0.62, 0.34)
	profile = HardwareDungeonData.apply_dungeon_completion_rewards(dungeon_id, profile)
	completion_story_beat = HardwareDungeonData.get_dungeon_completion_story_beat(dungeon_id)
	message = "%s: %s" % [completion_story_beat.get("headline", "Hardware dungeon complete"), completion_story_beat.get("next_route", "Returning to the overworld...")]
	set_process(false)
	set_process_unhandled_input(false)
	await get_tree().create_timer(0.55).timeout
	_return_to_overworld(true)

func _return_to_overworld(completed: bool) -> void:
	set_process(false)
	set_process_unhandled_input(false)
	dungeon_closed.emit(profile.duplicate(true), {
		"dungeon_id": dungeon_id,
		"completed": completed,
		"mechanisms": completed_mechanisms.keys(),
		"captains_log_fragment": HardwareDungeonData.get_captains_log_fragment(dungeon_id) if completed else {},
		"captains_log_flags": HardwareDungeonData.get_captains_log_flags_for_dungeon(dungeon_id) if completed else [],
		"story_beat": completion_story_beat.duplicate(true) if completed else {},
	})

func _all_mechanisms_complete() -> bool:
	for mechanism in mechanisms:
		if not completed_mechanisms.has(mechanism["id"]):
			return false
	return true

func _boss_complete() -> bool:
	return boss.is_empty() or boss_defeated

func _update_boss_pressure(delta: float) -> void:
	if boss.is_empty() or boss_defeated:
		boss_pressure = {}
		last_boss_warning_state = ""
		return
	boss_phase = fmod(boss_phase + delta * 0.22, 1.0)
	boss_pressure = HardwareDungeonData.evaluate_anomaly_pressure(str(boss.get("id", "")), boss_phase, _player_has_anomaly_protection())
	var warning_state := "idle"
	if bool(boss_pressure.get("telegraph_active", false)):
		warning_state = "telegraph"
	elif bool(boss_pressure.get("active", false)):
		warning_state = "active"
	elif bool(boss_pressure.get("core_vulnerable", false)):
		warning_state = "vulnerable"
	if warning_state != last_boss_warning_state:
		last_boss_warning_state = warning_state
		var anomaly_vfx := HardwareDungeonData.get_anomaly_vfx_profile(str(boss.get("id", "")), boss_pressure)
		if warning_state == "telegraph":
			emit_dungeon_screen_effect(str(anomaly_vfx.get("screen_effect", "warning_pulse")), 0.72, 0.36)
		elif warning_state == "active":
			emit_dungeon_screen_effect(str(anomaly_vfx.get("screen_effect", "chromatic_glitch")), 0.34, 0.22)
		elif warning_state == "vulnerable":
			emit_dungeon_screen_effect(str(anomaly_vfx.get("screen_effect", "scanline_burst")), 0.46, 0.24)

func _player_has_anomaly_protection() -> bool:
	if boss.get("id", "") == "sentinel_drone":
		return DragonProgression.has_key_item(profile, "diagnostic_lens") or DragonProgression.has_key_item(profile, "frequency_tuner")
	return false

func _active_dragon_form() -> String:
	if DragonProgression.has_key_item(profile, "prism_stalk_form") or DragonProgression.has_mission_flag(profile, "prism_stalk_mutated"):
		return "prism_stalk"
	if DragonProgression.has_key_item(profile, "magma_core_form") or DragonProgression.has_mission_flag(profile, "magma_core_compiled"):
		return "magma_core"
	return "root_dragon"

func _hazard_disabled(hazard: Dictionary) -> bool:
	return completed_mechanisms.has(hazard.get("disabled_by", ""))

func _hazard_revealed(hazard: Dictionary) -> bool:
	var hazard_key := "%s:%s" % [hazard.get("id", ""), hazard.get("rect", Rect2())]
	return revealed_hazards.has(hazard_key)

func _required_tool_for(mechanism_id: String) -> String:
	if mechanism_id == "vent_unlock_terminal":
		return "insulated_grip"
	if mechanism_id == "optical_lens_cradle":
		return "10mm_wrench"
	return "10mm_wrench"

func _intro_message() -> String:
	if dungeon.is_empty():
		return "Unknown access port."
	return "%s: %s" % [dungeon.get("name", "Hardware Dungeon"), dungeon.get("description", "")]

func _draw_panel_frame(rect: Rect2, fill: Color, line: Color, thickness: float = 2.0) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, line, false, thickness)
	draw_line(rect.position + Vector2(8, rect.size.y - 6), rect.position + rect.size - Vector2(8, 6), line.darkened(0.25), 1.0)

func _draw_panel_grid(rect: Rect2, line: Color, spacing: float = 64.0) -> void:
	var x := rect.position.x
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), line, 1.0)
		x += spacing
	var y := rect.position.y
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line, 1.0)
		y += spacing

func _draw_background_systems() -> void:
	_draw_panel_grid(Rect2(Vector2.ZERO, size), _room_shadow_color(), 92.0)
	_draw_far_machinery()
	_draw_ambient_vfx()
	if dungeon_id == "southern_partition_airlock":
		for i in 18:
			var x := fmod(Time.get_ticks_msec() * 0.04 + i * 83.0, size.x)
			draw_string(ThemeDB.fallback_font, Vector2(x, 134 + (i % 5) * 64), "0101  PERMISSION CHECK  1100", HORIZONTAL_ALIGNMENT_LEFT, 240, 13, Color("#ff6d5dcc"))
		draw_rect(Rect2(0, 118, size.x, 8), Color("#ff453a99"))
		draw_rect(Rect2(0, 568, size.x, 8), Color("#ff453a99"))
		_draw_warning_bands(Color("#ff453a"), 122.0)
	if dungeon_id == "great_buffer":
		_draw_cache_vault_background()
		for i in 10:
			var y := 126.0 + i * 42.0
			draw_rect(Rect2(70, y, size.x - 140, 10), Color("#dcefff22"))
		draw_string(ThemeDB.fallback_font, Vector2(74, 154), "WHITE-OUT PURGE INCOMING - USE DATA-SHIELDED ALCOVES", HORIZONTAL_ALIGNMENT_LEFT, 620, 16, Color("#eef8ffcc"))
		_draw_buffer_alcoves()
	if dungeon_id == "logic_core":
		_draw_logic_core_risers()
	for i in 8:
		var x := 80.0 + i * 150.0
		draw_line(Vector2(x, 0), Vector2(x + 60, size.y), _room_shadow_color().lightened(0.1), 3.0)
	for i in 5:
		var center := Vector2(130 + i * 250, 160)
		draw_arc(center, 44, 0, TAU, 24, Color("#36474f"), 4.0)
		draw_line(center, center + Vector2(40, 0).rotated(Time.get_ticks_msec() * 0.002 + i), Color("#7b8b91"), 3.0)
	var dragon_window := Rect2(980, 70, 190, 86)
	var support_color: Color = support_window_vfx.get("support_color", _room_accent_color())
	_draw_panel_frame(dragon_window, Color("#172126dd"), support_color, 2.0)
	draw_string(ThemeDB.fallback_font, dragon_window.position + Vector2(18, 30), "EXTERNAL SUPPORT", HORIZONTAL_ALIGNMENT_LEFT, 160, 12, Color("#8fbfd1"))
	var support_label := str(support_window_vfx.get("support_window_label", "Magma-Core outside"))
	draw_string(ThemeDB.fallback_font, dragon_window.position + Vector2(18, 58), support_label, HORIZONTAL_ALIGNMENT_LEFT, 160, 14, Color("#c9e6ff"))
	if not support_window_vfx.is_empty():
		var pulse := (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5
		draw_rect(dragon_window.grow(5.0 + pulse * 4.0), Color(support_color.r, support_color.g, support_color.b, 0.16 + pulse * 0.08), false, 2.0)

func _draw_ambient_vfx() -> void:
	var ambient := get_ambient_vfx_profile()
	var now := Time.get_ticks_msec() * 0.001
	var scan_alpha := float(ambient.get("scanline_alpha", 0.1))
	for y in range(0, int(size.y), 18):
		draw_rect(Rect2(0, y, size.x, 1), Color("#ffffff", scan_alpha * 0.18))
	var mote_count := int(ambient.get("coolant_motes", 6))
	for i in mote_count:
		var seed := float(i + 1)
		var x := fmod(seed * 137.0 + now * (18.0 + seed), maxf(1.0, size.x))
		var y := 132.0 + fmod(seed * 71.0 + sin(now * 0.7 + seed) * 34.0, maxf(1.0, size.y - 210.0))
		draw_circle(Vector2(x, y), 1.6 + float(i % 3), Color("#63d7ff", 0.25 + scan_alpha))
	var ascii_count := int(ambient.get("ascii_density", 4))
	for i in ascii_count:
		var seed := float(i + 3)
		var x := fmod(seed * 97.0 - now * 24.0, maxf(1.0, size.x + 160.0)) - 80.0
		var y := 118.0 + fmod(seed * 43.0, maxf(1.0, size.y - 190.0))
		var glyph := "[]" if i % 3 == 0 else "01" if i % 3 == 1 else "//"
		draw_string(ThemeDB.fallback_font, Vector2(x, y), glyph, HORIZONTAL_ALIGNMENT_LEFT, 44, 13, Color("#b7fffb", 0.12 + scan_alpha * 0.9))
	var steam_columns := int(ambient.get("steam_columns", 0))
	for i in steam_columns:
		var base := Vector2(170.0 + i * 320.0, size.y - 126.0)
		for strand in 5:
			var offset := sin(now * 1.7 + strand + i) * 18.0
			draw_line(base + Vector2(strand * 8.0, 0), base + Vector2(offset + strand * 11.0, -78.0), Color("#dff9ff", 0.10 + scan_alpha * 0.35), 2.0)

func _draw_far_machinery() -> void:
	var base_y := size.y - 190.0
	for i in 6:
		var x := 24.0 + i * 210.0
		var tower := Rect2(x, base_y - float(i % 3) * 24.0, 74, 156 + float(i % 2) * 30.0)
		draw_rect(tower, _room_shadow_color().darkened(0.18))
		draw_rect(tower, _room_shadow_color().lightened(0.18), false, 1.0)
		draw_line(tower.position + Vector2(12, 0), tower.position + Vector2(12, tower.size.y), _room_shadow_color().lightened(0.28), 1.0)
		draw_line(tower.position + Vector2(tower.size.x - 12, 0), tower.position + Vector2(tower.size.x - 12, tower.size.y), _room_shadow_color().lightened(0.28), 1.0)
	for i in 4:
		var y := 230.0 + i * 74.0
		draw_line(Vector2(0, y), Vector2(size.x, y + 24.0), _room_shadow_color().lightened(0.05), 5.0)

func _draw_warning_bands(color: Color, y: float) -> void:
	for i in 18:
		var rect := Rect2(i * 78.0, y, 40.0, 10.0)
		draw_rect(rect, color.darkened(0.12))
	for i in 18:
		var rect := Rect2(i * 78.0 + 38.0, size.y - y - 10.0, 40.0, 10.0)
		draw_rect(rect, color.darkened(0.2))

func _draw_buffer_alcoves() -> void:
	for i in 4:
		var rect := Rect2(118.0 + i * 280.0, 214.0 + float(i % 2) * 42.0, 128.0, 96.0)
		draw_rect(rect, Color("#c7e2ff24"))
		draw_rect(rect, Color("#f8fbff88"), false, 2.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(14, 56), "SHIELD", HORIZONTAL_ALIGNMENT_LEFT, 90, 13, Color("#ffffffaa"))

func _draw_cache_vault_background() -> void:
	var visual := ActTwoTundraData.get_cache_vault_visual_profile()
	var parallax := get_room_parallax_profile()
	var palette: Dictionary = visual.get("palette", {})
	var cyan: Color = palette.get("cyan", Color("#58dbff"))
	var white: Color = palette.get("stark_white", Color("#f8fbff"))
	var gray: Color = palette.get("hollow_gray", Color("#56616f"))
	var now := Time.get_ticks_msec() * 0.001
	var layers: Array = parallax.get("layers", [])
	for layer_index in range(layers.size()):
		var layer: Dictionary = layers[layer_index]
		if str(layer.get("content", "")) == "dark_blue_black_canvas":
			continue
		var alpha := float(layer.get("alpha", 0.1))
		var speed := float(layer.get("speed", 20.0))
		var glyph_size := int(layer.get("glyph_size", 14))
		for i in range(18):
			var x := 92.0 + i * 68.0 + float(layer_index) * 17.0 + sin(now * 0.34 + i) * float(layer_index + 1) * 5.0
			var y := fmod(now * speed + i * 37.0 + layer_index * 91.0, maxf(1.0, size.y + 80.0)) - 40.0
			var glyph := "1" if (i + layer_index) % 2 == 0 else "0"
			draw_string(ThemeDB.fallback_font, Vector2(x, y), glyph, HORIZONTAL_ALIGNMENT_LEFT, 22, glyph_size, Color(cyan.r, cyan.g, cyan.b, alpha))
	var grid_drift := now * float(parallax.get("hex_grid_drift", 0.0))
	for y in range(120, int(size.y - 90), 46):
		for x in range(46, int(size.x - 46), 64):
			var center := Vector2(float(x) + fmod(grid_drift, 64.0), float(y) + sin(now * 0.3 + x) * 3.0)
			draw_arc(center, 14.0, 0.0, TAU, 6, Color(gray.r, gray.g, gray.b, 0.16), 1.0)
			draw_line(center + Vector2(14.0, 0.0), center + Vector2(32.0, 0.0), Color(white.r, white.g, white.b, 0.05), 1.0)
	var scan_speed := float(parallax.get("scanline_speed", 0.0))
	for i in range(4):
		var scan_y := fmod(now * scan_speed + i * size.y * 0.25, maxf(1.0, size.y))
		draw_rect(Rect2(0.0, scan_y, size.x, 2.0), Color(white.r, white.g, white.b, 0.04))

func _draw_logic_core_risers() -> void:
	for i in 10:
		var x := 44.0 + i * 122.0
		draw_rect(Rect2(x, 112, 24, size.y - 180), Color("#151b3fcc"))
		draw_line(Vector2(x + 12, 112), Vector2(x + 12, size.y - 68), Color("#6a78ff66"), 2.0)
		if i % 2 == 0:
			draw_string(ThemeDB.fallback_font, Vector2(x - 6, 164 + i * 11), "{ }", HORIZONTAL_ALIGNMENT_LEFT, 42, 14, Color("#8ae6ff88"))

func _draw_platform(platform: Rect2) -> void:
	var accent := _room_accent_color()
	var top := Rect2(platform.position, Vector2(platform.size.x, 6.0))
	var underside := Rect2(platform.position + Vector2(0, platform.size.y - 7.0), Vector2(platform.size.x, 7.0))
	draw_rect(platform, Color("#4f565a"))
	draw_rect(underside, Color("#22292d"))
	draw_rect(top, accent.lightened(0.26))
	draw_rect(platform, Color("#121719"), false, 2.0)
	for x in range(int(platform.position.x) + 18, int(platform.end.x) - 10, 34):
		draw_circle(Vector2(float(x), platform.position.y + 12.0), 3.0, Color("#1d2225"))
		draw_circle(Vector2(float(x), platform.position.y + 12.0), 1.5, accent.darkened(0.25))
	if room_style == "buffer_vault":
		draw_rect(platform, Color("#071a3f"))
		draw_rect(top, Color("#58dbff", 0.78))
		draw_rect(underside, Color("#f8fbff", 0.16))
		draw_rect(platform, Color("#58dbff", 0.36), false, 2.0)
		var bit_index := 0
		for x in range(int(platform.position.x) + 10, int(platform.end.x) - 20, 28):
			var active := bit_index % 2 == 0
			var bit_color := Color("#58dbff") if active else Color("#56616f")
			var bit_rect := Rect2(Vector2(float(x), platform.position.y + 11.0), Vector2(16.0, 10.0))
			draw_rect(bit_rect, Color(bit_color.r, bit_color.g, bit_color.b, 0.48 if active else 0.2))
			draw_rect(bit_rect.grow(2.0), Color(bit_color.r, bit_color.g, bit_color.b, 0.24), false, 1.0)
			draw_string(ThemeDB.fallback_font, bit_rect.position + Vector2(5, 8), "1" if active else "0", HORIZONTAL_ALIGNMENT_LEFT, 12, 8, Color("#f8fbff", 0.72 if active else 0.42))
			bit_index += 1
		draw_line(platform.position + Vector2(0, 14), platform.position + Vector2(platform.size.x, 14), Color("#f7fbff88"), 1.0)
	elif room_style == "firewall_breach":
		draw_line(platform.position + Vector2(0, platform.size.y - 2), platform.position + Vector2(platform.size.x, platform.size.y - 2), Color("#ff453a99"), 2.0)

func _draw_security_drone(drone: Dictionary) -> void:
	var rect: Rect2 = drone.get("rect", Rect2())
	if rect.size.x <= 0.0:
		return
	var state := str(drone.get("state", ActTwoTundraData.DRONE_STATE_PATROL))
	var frozen := state == ActTwoTundraData.DRONE_STATE_FROZEN
	var alert := state == ActTwoTundraData.DRONE_STATE_ALERT
	var center := rect.get_center()
	var body_color := Color("#c9f7ff") if frozen else Color("#ff594d") if alert else Color("#f8fbff")
	var glow_color := Color("#58dbff") if frozen else Color("#ff453a") if alert else Color("#c0c8ff")
	var pulse := (sin(Time.get_ticks_msec() * 0.012) + 1.0) * 0.5
	draw_circle(center, rect.size.x * 0.42 + pulse * 2.0, Color(glow_color.r, glow_color.g, glow_color.b, 0.18))
	draw_polygon([
		center + Vector2(0.0, -rect.size.y * 0.62),
		center + Vector2(rect.size.x * 0.48, 0.0),
		center + Vector2(0.0, rect.size.y * 0.62),
		center + Vector2(-rect.size.x * 0.48, 0.0),
	], [Color("#101820"), Color("#101820"), Color("#101820"), Color("#101820")])
	draw_arc(center, rect.size.x * 0.42, 0.0, TAU, 28, glow_color, 2.0)
	draw_circle(center, 7.0, body_color)
	draw_circle(center, 3.0, Color("#101820"))
	if frozen:
		var platform_rect: Rect2 = drone.get("platform_rect", Rect2())
		draw_rect(platform_rect, Color("#8fe6ff", 0.52))
		draw_rect(platform_rect, Color("#f8fbff", 0.86), false, 2.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(-8, -12), "FROZEN %.1f" % float(drone.get("freeze_timer", 0.0)), HORIZONTAL_ALIGNMENT_LEFT, 120, 11, Color("#eaf9ff"))
	elif alert:
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(-8, -12), "ALERT", HORIZONTAL_ALIGNMENT_LEFT, 80, 11, Color("#ffb3ad"))
	else:
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(-8, -12), "TYPE-S", HORIZONTAL_ALIGNMENT_LEFT, 80, 11, Color("#dcefff"))

func _draw_binary_floor_tile(tile: Dictionary) -> void:
	if binary_puzzle_state.is_empty():
		binary_puzzle_state = HardwareDungeonData.create_binary_puzzle_state([1, 1, 0], [4, 2, 1], 6)
	var rect: Rect2 = tile.get("rect", Rect2())
	if rect.size.x <= 0.0:
		return
	var tile_index := int(tile.get("tile_index", 0))
	var bits: Array = binary_puzzle_state.get("bits", [])
	var active := tile_index >= 0 and tile_index < bits.size() and int(bits[tile_index]) == 1
	var color := Color("#58dbff") if active else Color("#56616f")
	var pulse := 0.5 + sin(Time.get_ticks_msec() * 0.016 + tile_index) * 0.5
	draw_rect(rect.grow(4.0), Color(color.r, color.g, color.b, 0.14 + pulse * 0.08))
	var flash_timer := float(binary_tile_flash_timers.get(tile_index, 0.0))
	if flash_timer > 0.0:
		var flash_alpha := clampf(flash_timer / 0.32, 0.0, 1.0)
		draw_rect(rect.grow(8.0 + pulse * 3.0), Color("#f8fbff", 0.3 * flash_alpha), false, 2.0)
	draw_rect(rect, Color("#05080a"))
	draw_rect(rect, Color(color.r, color.g, color.b, 0.42 if active else 0.18))
	draw_rect(rect, Color(color.r, color.g, color.b, 0.82 if active else 0.38), false, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 18), "1" if active else "0", HORIZONTAL_ALIGNMENT_LEFT, 16, 18, Color("#f8fbff", 0.92 if active else 0.52))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(32, 14), "%d" % int(tile.get("weight", 0)), HORIZONTAL_ALIGNMENT_LEFT, 24, 10, Color("#dcefff", 0.82))

func _draw_binary_circuit_bus() -> void:
	var bus := get_binary_circuit_bus_profile()
	if not bool(bus.get("visible", false)):
		return
	var tick := 0.5 + sin(Time.get_ticks_msec() * 0.018) * 0.5
	for segment in bus.get("segments", []):
		var start: Vector2 = segment.get("from", Vector2.ZERO)
		var end: Vector2 = segment.get("to", Vector2.ZERO)
		var color: Color = segment.get("color", Color("#58dbff"))
		var alpha := float(segment.get("pulse_alpha", 0.22))
		var mid := Vector2(end.x, start.y)
		draw_line(start, mid, Color(color.r, color.g, color.b, alpha * 0.5), 2.0)
		draw_line(mid, end, Color(color.r, color.g, color.b, alpha * 0.5), 2.0)
		if bool(segment.get("active", false)):
			var packet_t := fmod(tick + float(segment.get("tile_index", 0)) * 0.27, 1.0)
			var packet := start.lerp(mid, packet_t * 2.0) if packet_t < 0.5 else mid.lerp(end, (packet_t - 0.5) * 2.0)
			draw_rect(Rect2(packet - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), Color("#f8fbff", 0.72))

func _draw_binary_gate() -> void:
	var gate := get_binary_gate_profile()
	if not bool(gate.get("visible", false)):
		return
	var rect: Rect2 = gate.get("rect", Rect2())
	if rect.size.x <= 0.0:
		return
	var open := bool(gate.get("open", false))
	var rail_color: Color = gate.get("rail_color", Color("#58dbff"))
	var pulse := 0.5 + sin(Time.get_ticks_msec() * 0.012) * 0.5
	_draw_panel_frame(rect, Color("#06112add"), rail_color, 2.0)
	draw_rect(rect.grow(7.0 + pulse * 2.0), Color(rail_color.r, rail_color.g, rail_color.b, 0.1 if open else 0.16), false, 2.0)
	if bool(gate.get("flash_active", false)):
		var flash_color: Color = gate.get("flash_color", rail_color)
		var flash_alpha := clampf(float(gate.get("flash_timer", 0.0)) / 0.42, 0.0, 1.0)
		draw_rect(rect.grow(12.0 + pulse * 5.0), Color(flash_color.r, flash_color.g, flash_color.b, 0.24 * flash_alpha), false, 3.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(-30, -24), str(gate.get("flash_label", "")), HORIZONTAL_ALIGNMENT_LEFT, 140, 10, Color(flash_color.r, flash_color.g, flash_color.b, 0.88 * flash_alpha))
	for x in range(int(rect.position.x) + 8, int(rect.end.x) - 7, 12):
		var bar := Rect2(Vector2(float(x), rect.position.y + 8.0), Vector2(5.0, rect.size.y - 16.0))
		var offset := -rect.size.y * 0.36 if open else 0.0
		bar.position.y += offset
		draw_rect(bar, Color(rail_color.r, rail_color.g, rail_color.b, float(gate.get("bar_alpha", 0.72))))
		draw_rect(bar, Color("#f8fbff", 0.18), false, 1.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(-16, -10), str(gate.get("label", "CACHE GATE")), HORIZONTAL_ALIGNMENT_LEFT, 120, 10, Color("#dcefff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(6, rect.size.y + 14), "%s %d/%d" % [gate.get("status_label", "LOCKED"), int(gate.get("current_decimal", 0)), int(gate.get("target_decimal", 0))], HORIZONTAL_ALIGNMENT_LEFT, 90, 10, rail_color.lightened(0.12))

func _draw_binary_guide() -> void:
	var guide := get_binary_guide_profile()
	if not bool(guide.get("visible", false)):
		return
	var rect: Rect2 = guide.get("rect", Rect2())
	if rect.size.x <= 0.0:
		return
	var color: Color = guide.get("status_color", Color("#ffd166"))
	var pulse := 0.5 + sin(Time.get_ticks_msec() * 0.014) * 0.5
	_draw_panel_frame(rect, Color("#05080add"), color, 2.0)
	draw_rect(rect.grow(4.0 + pulse * 2.0), Color(color.r, color.g, color.b, 0.1), false, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(9, 16), str(guide.get("name", "Unit 08")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12, 10, Color("#f8fbff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(9, 33), str(guide.get("hint", "")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12, 13, color.lightened(0.16))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(9, 46), "%d/%d %s" % [int(guide.get("current_decimal", 0)), int(guide.get("target_decimal", 0)), str(guide.get("readout_style", ""))], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12, 8, Color("#d5dde0"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(9, 58), str(guide.get("voice_line", "")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12, 8, Color("#f8fbff", 0.72))

func _draw_bit_rot_trails() -> void:
	var trail_profile := get_bit_rot_static_trail_hazard_profile()
	if not bool(trail_profile.get("visible", false)):
		return
	var warning_color: Color = trail_profile.get("warning_color", Color("#ff594d"))
	var flicker := 0.45 + sin(Time.get_ticks_msec() * 0.024) * 0.18
	for zone in trail_profile.get("zones", []):
		var rect: Rect2 = zone.get("rect", Rect2())
		if rect.size.x <= 0.0:
			continue
		draw_rect(rect, Color(warning_color.r, warning_color.g, warning_color.b, 0.18 + flicker * 0.16))
		draw_rect(rect.grow(2.0), Color(warning_color.r, warning_color.g, warning_color.b, 0.22), false, 1.0)
		for i in 3:
			var y := rect.position.y + 2.0 + i * 3.0
			draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y + sin(Time.get_ticks_msec() * 0.013 + i) * 2.0), Color("#f8fbff", 0.18), 1.0)

func _draw_bit_rot_stalker(stalker: Dictionary) -> void:
	var rect: Rect2 = stalker.get("rect", Rect2())
	if rect.size.x <= 0.0:
		return
	if bool(stalker.get("de_rezzed", false)):
		_draw_bit_rot_residue(stalker)
		return
	var vfx: Dictionary = stalker.get("vfx_profile", {})
	var silhouette: Color = vfx.get("silhouette_color", Color("#10141a"))
	var trail_color: Color = vfx.get("trail_color", Color("#ff594d"))
	var state := str(stalker.get("state", "stalking"))
	var panic := state == "seeking_shielded_port"
	var center := rect.get_center()
	var jitter := sin(Time.get_ticks_msec() * 0.038) * 2.0
	var glow_alpha := 0.24 if panic else 0.16
	draw_rect(rect.grow(5.0 + absf(jitter)), Color(trail_color.r, trail_color.g, trail_color.b, glow_alpha), false, 2.0)
	draw_polygon([
		center + Vector2(-rect.size.x * 0.46, rect.size.y * 0.48),
		center + Vector2(-rect.size.x * 0.22, -rect.size.y * 0.38 + jitter),
		center + Vector2(rect.size.x * 0.12, -rect.size.y * 0.48 - jitter),
		center + Vector2(rect.size.x * 0.46, rect.size.y * 0.42),
	], [silhouette, silhouette.darkened(0.2), silhouette, silhouette.darkened(0.14)])
	draw_line(center + Vector2(-rect.size.x * 0.32, -3.0), center + Vector2(rect.size.x * 0.24, -1.0 + jitter), Color(trail_color.r, trail_color.g, trail_color.b, 0.72), 2.0)
	draw_line(rect.position + Vector2(3.0, rect.size.y - 5.0), rect.end - Vector2(3.0, 5.0), Color("#f8fbff", 0.22), 1.0)
	var label := "PORT SEEK" if panic else "BIT-ROT"
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(-12, -10), label, HORIZONTAL_ALIGNMENT_LEFT, 96, 10, Color("#ffb3ad") if panic else Color("#ff8b80"))

func _draw_bit_rot_residue(stalker: Dictionary) -> void:
	var rect: Rect2 = stalker.get("rect", Rect2())
	var vfx: Dictionary = stalker.get("vfx_profile", {})
	var color: Color = vfx.get("silhouette_color", Color("#f4fbff"))
	var center := rect.get_center()
	var pulse := 0.5 + sin(Time.get_ticks_msec() * 0.02) * 0.5
	draw_circle(center, 18.0 + pulse * 4.0, Color(color.r, color.g, color.b, 0.12))
	draw_arc(center, 14.0 + pulse * 5.0, 0.0, TAU, 18, Color(color.r, color.g, color.b, 0.46), 1.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-4.0, 5.0), ".", HORIZONTAL_ALIGNMENT_LEFT, 20, 22, color)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(-15, -10), "DE-REZZED", HORIZONTAL_ALIGNMENT_LEFT, 110, 10, Color("#f4fbff", 0.72))

func _draw_shielded_port(port: Dictionary) -> void:
	var rect: Rect2 = port.get("rect", Rect2())
	if rect.size.x <= 0.0:
		return
	var port_id := str(port.get("id", ""))
	var sealed := is_shielded_port_sealed(port_id)
	var active := not live_torque_meter.is_empty() and str(live_torque_meter.get("port_id", "")) == port_id
	var accent := Color("#70ff8f") if active or sealed else Color("#58dbff")
	var pulse := 0.5 + sin(Time.get_ticks_msec() * 0.01) * 0.5
	_draw_panel_frame(rect, Color("#06151add"), accent, 2.0)
	draw_rect(rect.grow(8.0 + pulse * 3.0), Color(accent.r, accent.g, accent.b, 0.12), false, 2.0)
	var inner := rect.grow(-10.0)
	draw_rect(inner, Color("#dffbff", 0.18 if active or sealed else 0.08))
	for y in range(int(inner.position.y) + 5, int(inner.end.y) - 4, 11):
		draw_line(Vector2(inner.position.x + 5, y), Vector2(inner.end.x - 5, y + sin(Time.get_ticks_msec() * 0.008 + y) * 2.0), Color(accent.r, accent.g, accent.b, 0.45), 1.0)
	draw_circle(rect.position + Vector2(rect.size.x * 0.5, 18.0), 9.0, Color("#f8fbff", 0.84))
	draw_circle(rect.position + Vector2(rect.size.x * 0.5, 18.0), 4.0, Color("#101820"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(-12, -10), "SEALED" if sealed else "SAFE PORT", HORIZONTAL_ALIGNMENT_LEFT, 110, 11, Color("#caffdd") if active or sealed else Color("#d5f7ff"))

func _draw_hazard(hazard: Dictionary) -> void:
	var rect: Rect2 = hazard["rect"]
	var disabled := _hazard_disabled(hazard)
	var revealed := _hazard_revealed(hazard)
	var color := _hazard_color(str(hazard.get("id", "")))
	var hazard_vfx := HardwareDungeonData.get_hazard_vfx_profile(str(hazard.get("id", "")), {"safe": disabled})
	if disabled:
		color = Color("#4f6a67")
	elif revealed:
		color = Color("#7bffcf")
	var alpha := 0.22 if disabled else float(hazard_vfx.get("overlay_alpha", 0.62))
	draw_rect(rect, Color(color.r, color.g, color.b, alpha))
	draw_rect(rect, color.lightened(0.16), false, 2.0)
	if not disabled:
		var tick := sin(Time.get_ticks_msec() * 0.008) * 0.5 + 0.5
		draw_rect(rect.grow(4.0 + tick * 4.0), Color(color.r, color.g, color.b, 0.14), false, 2.0)
		_draw_hazard_vfx(rect, hazard_vfx, tick)
	var label := _hazard_label(str(hazard.get("id", "")))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(6, -8), label, HORIZONTAL_ALIGNMENT_LEFT, 130, 12, color.lightened(0.25))
	if str(hazard.get("id", "")) == "steam_leak" and not disabled:
		for i in 4:
			var x := rect.position.x + 8.0 + i * 10.0
			draw_line(Vector2(x, rect.end.y), Vector2(x + sin(Time.get_ticks_msec() * 0.005 + i) * 9.0, rect.position.y), Color("#ffd3ad77"), 2.0)
	elif str(hazard.get("id", "")) == "logic_grid" or str(hazard.get("id", "")) == "laser_reroute":
		for i in range(0, int(rect.size.y), 22):
			draw_line(rect.position + Vector2(0, i), rect.position + Vector2(rect.size.x, i + 12), Color(color.r, color.g, color.b, 0.7), 1.0)
	elif str(hazard.get("id", "")) == "white_out_purge":
		draw_rect(rect, Color("#ffffff33"))

func _draw_hazard_vfx(rect: Rect2, profile: Dictionary, tick: float) -> void:
	var beam: Color = profile.get("beam_color", Color("#ffd166"))
	var stripe_count := int(profile.get("stripe_count", 4))
	match str(profile.get("tile_filter", "warning")):
		"whiteout":
			for i in stripe_count:
				var y := rect.position.y + fmod(Time.get_ticks_msec() * 0.05 + i * 19.0, maxf(1.0, rect.size.y))
				draw_rect(Rect2(rect.position.x, y, rect.size.x, 3.0 + tick * 4.0), Color("#ffffff", 0.24))
			draw_rect(rect.grow(8.0), Color("#f8fbff", 0.16 + tick * 0.08), false, 2.0)
		"red_wireframe":
			draw_line(rect.position, rect.end, Color(beam.r, beam.g, beam.b, 0.72), 1.0)
			draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), Color(beam.r, beam.g, beam.b, 0.58), 1.0)
			for i in stripe_count:
				var x := rect.position.x + i * rect.size.x / maxf(1.0, float(stripe_count))
				draw_line(Vector2(x, rect.position.y), Vector2(x + sin(tick * TAU + i) * 12.0, rect.end.y), Color(beam.r, beam.g, beam.b, 0.38), 1.0)
		"diagnostic_laser":
			for i in stripe_count:
				var y := rect.position.y + i * rect.size.y / maxf(1.0, float(stripe_count))
				draw_line(rect.position + Vector2(0, y - rect.position.y), rect.position + Vector2(rect.size.x, y - rect.position.y + 14.0), Color(beam.r, beam.g, beam.b, 0.72), 1.0)
			draw_line(rect.get_center() - Vector2(rect.size.x * 0.5, 0), rect.get_center() + Vector2(rect.size.x * 0.5, 0), Color("#ffffff", 0.32 + tick * 0.2), 2.0)
		"source_glyphs":
			for i in stripe_count:
				var glyph := "{}" if i % 2 == 0 else "[]"
				draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 18.0 + i * 18.0), glyph, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, 14, Color(beam.r, beam.g, beam.b, 0.72))
		_:
			for i in stripe_count:
				var x := rect.position.x + 8.0 + i * 10.0
				draw_line(Vector2(x, rect.end.y), Vector2(x + sin(Time.get_ticks_msec() * 0.005 + i) * 9.0, rect.position.y), Color(beam.r, beam.g, beam.b, 0.58), 2.0)

func _draw_mechanism(mechanism: Dictionary) -> void:
	if str(mechanism.get("mechanism", "")) == "optical_lens_cradle":
		_draw_lens_cradle(mechanism)
		return
	var rect: Rect2 = mechanism["rect"]
	var complete := completed_mechanisms.has(mechanism["id"])
	var accent := Color("#6ee7a8") if complete else _room_warning_color()
	var body := Color("#1e2a2e") if complete else Color("#3b3121")
	_draw_panel_frame(rect, body, accent, 2.0)
	draw_rect(Rect2(rect.position + Vector2(8, 9), Vector2(rect.size.x - 16, 10)), accent.darkened(0.2))
	draw_circle(rect.position + rect.size * 0.5 + Vector2(0, 8), minf(rect.size.x, rect.size.y) * 0.18, accent)
	if complete:
		draw_line(rect.position + Vector2(11, rect.size.y - 12), rect.position + Vector2(rect.size.x - 10, 13), Color("#caffdd"), 3.0)
	else:
		draw_line(rect.position + Vector2(rect.size.x - 12, 14), rect.position + Vector2(rect.size.x + 10, -10), Color("#d9d9d9"), 4.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(-10, -12), mechanism["label"], HORIZONTAL_ALIGNMENT_LEFT, 130, 13, Color("#eaf0e5"))

func _draw_lens_cradle(mechanism: Dictionary) -> void:
	var rect: Rect2 = mechanism["rect"]
	var complete := completed_mechanisms.has(mechanism["id"])
	var pulse := 0.5 + sin(Time.get_ticks_msec() * 0.012) * 0.5
	var accent := Color("#70ff8f") if complete else Color("#58dbff")
	var fill := Color("#10252aee") if complete else Color("#0a1524ee")
	_draw_panel_frame(rect, fill, accent, 2.0)
	draw_rect(rect.grow(8.0 + pulse * 5.0), Color(accent.r, accent.g, accent.b, 0.12), false, 2.0)
	var socket := Rect2(rect.position + Vector2(10.0, rect.size.y - 17.0), Vector2(rect.size.x - 20.0, 8.0))
	draw_rect(socket, Color("#dcefff", 0.16))
	draw_rect(socket, Color(accent.r, accent.g, accent.b, 0.7), false, 1.0)
	var center := rect.get_center() + Vector2(0.0, -3.0)
	for i in range(3):
		var ring_radius := 10.0 + i * 7.0 + pulse * 2.0
		draw_arc(center, ring_radius, 0.0, TAU, 28, Color(accent.r, accent.g, accent.b, 0.34 - i * 0.07), 1.0)
	if complete:
		draw_circle(center, 9.0, Color("#dffbff", 0.32))
		draw_string(ThemeDB.fallback_font, center + Vector2(-16.0, 5.0), "OK", HORIZONTAL_ALIGNMENT_LEFT, 34, 10, Color("#caffdd"))
	else:
		var lens_color := Color("#c8fbff")
		draw_polygon(PackedVector2Array([
			center + Vector2(0.0, -15.0),
			center + Vector2(14.0, 0.0),
			center + Vector2(0.0, 15.0),
			center + Vector2(-14.0, 0.0),
		]), PackedColorArray([Color(lens_color.r, lens_color.g, lens_color.b, 0.78)]))
		draw_line(center + Vector2(-28.0, 6.0), center + Vector2(28.0, -10.0), Color("#ffffff", 0.62), 2.0)
		draw_line(center + Vector2(-24.0, -12.0), center + Vector2(24.0, 12.0), Color("#8ae6ff", 0.44), 1.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(-18, -12), "OPTICAL LENS", HORIZONTAL_ALIGNMENT_LEFT, 120, 12, Color("#dffbff"))

func _draw_relic_pickup_world_burst() -> void:
	var card := get_relic_pickup_card_profile()
	if not bool(card.get("visible", false)):
		return
	var origin: Vector2 = card.get("origin", Vector2.ZERO)
	var color: Color = card.get("frame_color", Color("#58dbff"))
	var alpha := clampf(float(card.get("timer", 0.0)) / 1.6, 0.0, 1.0)
	for i in range(int(card.get("ring_count", 3))):
		var radius := 24.0 + i * 18.0 + (1.0 - alpha) * 22.0
		draw_arc(origin, radius, 0.0, TAU, 36, Color(color.r, color.g, color.b, alpha * (0.42 - i * 0.08)), 2.0)
	for i in range(6):
		var angle := i * TAU / 6.0 + Time.get_ticks_msec() * 0.004
		var start := origin + Vector2(cos(angle), sin(angle)) * 12.0
		var end := origin + Vector2(cos(angle), sin(angle)) * (42.0 + (1.0 - alpha) * 28.0)
		draw_line(start, end, Color("#f8fbff", alpha * 0.52), 1.0)

func _draw_exit() -> void:
	var unlocked := is_exit_unlocked()
	var exit_vfx := get_exit_vfx_profile()
	var relay_color: Color = exit_vfx.get("relay_color", Color("#62e8ff"))
	var fill := Color("#15363d") if unlocked else Color("#151c24")
	var line := relay_color
	_draw_panel_frame(exit_rect, fill, line, 3.0)
	var inner := exit_rect.grow(-10.0)
	draw_rect(inner, Color("#62a4ff44") if unlocked else Color("#25364a66"))
	for i in int(exit_vfx.get("ring_count", 1)):
		var pulse := (sin(Time.get_ticks_msec() * 0.006 + i) + 1.0) * 0.5
		draw_rect(exit_rect.grow(6.0 + i * 6.0 + pulse * 3.0), Color(relay_color.r, relay_color.g, relay_color.b, maxf(0.04, float(exit_vfx.get("pulse_alpha", 0.12)) - i * 0.09)), false, 2.0)
	for y in range(int(exit_rect.position.y) + 10, int(exit_rect.end.y) - 6, 18):
		draw_line(Vector2(exit_rect.position.x + 8, y), Vector2(exit_rect.end.x - 8, y), line.darkened(0.3), 1.0)
	draw_string(ThemeDB.fallback_font, exit_rect.position + Vector2(-26, -10), str(exit_vfx.get("label", "EXIT")), HORIZONTAL_ALIGNMENT_LEFT, 120, 14, Color("#eaf0e5"))

func _draw_player() -> void:
	var rect := Rect2(player_position - PLAYER_SIZE * 0.5, PLAYER_SIZE)
	var facing := -1.0 if Input.is_action_pressed("move_left") else 1.0
	var boots_y := rect.end.y - 6.0
	var armor_vfx := get_active_armor_vfx_profile()
	if str(armor_vfx.get("armor_id", "")) != "":
		var outline: Color = armor_vfx.get("outline_color", Color("#eaf0e5"))
		draw_rect(rect.grow(4.0), Color(outline.r, outline.g, outline.b, 0.16), false, 3.0)
		var flicker := float(armor_vfx.get("flicker_alpha", 0.0))
		if flicker > 0.0:
			var pulse := 0.55 + sin(Time.get_ticks_msec() * 0.018) * 0.45
			draw_rect(rect.grow(8.0), Color(outline.r, outline.g, outline.b, flicker * pulse), false, 2.0)
	draw_rect(Rect2(rect.position + Vector2(7, 13), Vector2(15, 22)), Color("#7a4e37"))
	draw_rect(Rect2(rect.position + Vector2(9, 16), Vector2(11, 16)), Color("#f0d7a3"))
	draw_rect(Rect2(rect.position + Vector2(5, 35), Vector2(8, 6)), Color("#1a1b1c"))
	draw_rect(Rect2(rect.position + Vector2(16, 35), Vector2(9, 6)), Color("#1a1b1c"))
	draw_circle(rect.position + Vector2(14, 8), 9.0, Color("#f2d7ad"))
	draw_rect(Rect2(rect.position + Vector2(6, 3), Vector2(18, 7)), Color("#2f3e49"))
	draw_rect(Rect2(rect.position + Vector2(11, 8), Vector2(12, 4)), Color("#7ec8ff"))
	draw_line(rect.position + Vector2(20, 22), rect.position + Vector2(20 + facing * 21.0, 12), Color("#d9d9d9"), 4.0)
	draw_line(rect.position + Vector2(20 + facing * 21.0, 12), rect.position + Vector2(20 + facing * 27.0, 18), Color("#d9d9d9"), 3.0)
	draw_line(Vector2(rect.position.x + 4, boots_y), Vector2(rect.end.x - 3, boots_y), Color("#00000099"), 2.0)

func _play_dungeon_vfx_strip(path: String, origin: Vector2) -> void:
	if path == "":
		return
	last_dungeon_vfx_strip_path = path
	strip_vfx_path = path
	strip_vfx_elapsed = 0.0
	strip_vfx_frame = 0
	if strip_vfx_sprite == null:
		return
	var texture := _texture_from_png(path)
	if texture == null:
		return
	if strip_vfx_atlas == null:
		strip_vfx_atlas = AtlasTexture.new()
	strip_vfx_atlas.atlas = texture
	strip_vfx_sprite.texture = strip_vfx_atlas
	strip_vfx_sprite.size = Vector2(280, 156)
	strip_vfx_sprite.position = origin - strip_vfx_sprite.size * 0.5
	strip_vfx_sprite.visible = true
	strip_vfx_sprite.modulate = Color.WHITE
	_set_dungeon_vfx_frame(0)

func _update_dungeon_vfx_strip(delta: float) -> void:
	if strip_vfx_sprite == null or not strip_vfx_sprite.visible:
		return
	strip_vfx_elapsed += delta
	var next_frame := floori(strip_vfx_elapsed / strip_vfx_frame_time)
	if next_frame != strip_vfx_frame:
		strip_vfx_frame = next_frame
		_set_dungeon_vfx_frame(strip_vfx_frame)
	if strip_vfx_frame >= VFX_FRAME_COUNT:
		strip_vfx_sprite.visible = false
		strip_vfx_path = ""

func _set_dungeon_vfx_frame(frame: int) -> void:
	if strip_vfx_atlas == null or strip_vfx_atlas.atlas == null:
		return
	var texture := strip_vfx_atlas.atlas
	var frame_width := float(texture.get_width()) / VFX_FRAME_COUNT
	strip_vfx_atlas.region = Rect2(frame_width * clampi(frame, 0, VFX_FRAME_COUNT - 1), 0.0, frame_width, texture.get_height())

func _texture_from_png(path: String) -> Texture2D:
	var image := Image.new()
	var error := image.load(path)
	if error == OK:
		return ImageTexture.create_from_image(image)
	return null

func _draw_ascii_puzzle(puzzle: Dictionary) -> void:
	var rect: Rect2 = puzzle["rect"]
	var solved := solved_ascii_puzzles.has(str(puzzle.get("id", "")))
	var line := Color("#70ff8f") if solved else Color("#b7fffb")
	var fill := Color("#0c2418aa") if solved else Color("#10122ac0")
	_draw_panel_frame(rect, fill, line, 2.0)
	match str(puzzle.get("kind", "")):
		"compile_bridge":
			var text := "[=========]" if solved else "[========="
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(12, 20), text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16, 17, line)
			if not solved:
				draw_string(ThemeDB.fallback_font, rect.position + Vector2(rect.size.x - 24, -7), "]", HORIZONTAL_ALIGNMENT_LEFT, 26, 18, Color("#ffd166"))
		"boolean_gate":
			var text := "LOCKED = FALSE" if solved else "LOCKED = TRUE"
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(-20, 44), text, HORIZONTAL_ALIGNMENT_LEFT, 150, 14, line)
			draw_line(rect.position + Vector2(14, 112), rect.position + Vector2(rect.size.x - 16, 56 if solved else 132), Color("#ffd166"), 4.0)
		"comment_beam":
			var text := "// ! ! ! ! !" if solved else "! ! ! ! ! !"
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(14, 18), text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 18, 16, Color("#ff6b9a") if not solved else line)
			if not solved:
				draw_rect(rect.grow(10.0), Color("#ff1d5d26"), false, 3.0)
		_:
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 20), str(puzzle.get("label", "ASCII")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, 14, line)

func _resolve_ascii_puzzle(puzzle: Dictionary, tool_or_armor: String) -> Dictionary:
	match str(puzzle.get("kind", "")):
		"compile_bridge":
			var bridge := MainframeSpineData.compile_bracket_bridge("[=========", "]", tool_or_armor)
			bridge["success"] = bool(bridge.get("solid", false))
			bridge["required"] = bridge.get("requires_tool", "10mm_wrench")
			return bridge
		"boolean_gate":
			var gate := MainframeSpineData.flip_boolean_gate("LOCKED", true, tool_or_armor)
			gate["success"] = bool(gate.get("open", false))
			gate["required"] = gate.get("requires_tool", "10mm_wrench")
			return gate
		"comment_beam":
			var beam := MainframeSpineData.comment_out_security_beam("red_bang_stream", true, tool_or_armor)
			beam["success"] = not bool(beam.get("damaging", true))
			beam["required"] = beam.get("requires_armor", "ASCII_AEGIS")
			return beam
	return {
		"success": false,
		"status": "UNKNOWN_ASCII_PUZZLE",
		"required": "",
	}

func _hazard_color(hazard_id: String) -> Color:
	match hazard_id:
		"steam_leak":
			return Color("#ff9a4d")
		"white_out_purge":
			return Color("#f8fbff")
		"laser_reroute":
			return Color("#58dbff")
		"logic_grid":
			return Color("#58dbff")
		"syntax_blocks":
			return Color("#b084ff")
		_:
			return _room_warning_color()

func _hazard_label(hazard_id: String) -> String:
	match hazard_id:
		"steam_leak":
			return "STEAM"
		"white_out_purge":
			return "PURGE"
		"laser_reroute":
			return "LASER"
		"logic_grid":
			return "GRID"
		"syntax_blocks":
			return "SYNTAX"
		_:
			return "HAZARD"

func _room_accent_color() -> Color:
	match room_style:
		"firewall_breach":
			return Color("#ff6d5d")
		"buffer_vault":
			return Color("#58dbff")
		"vertical_data_conduit":
			return Color("#8ae6ff")
		_:
			return Color("#f0b66c")

func _room_warning_color() -> Color:
	match room_style:
		"firewall_breach":
			return Color("#ff453a")
		"buffer_vault":
			return Color("#f8fbff")
		"vertical_data_conduit":
			return Color("#b084ff")
		_:
			return Color("#ffd166")

func _room_shadow_color() -> Color:
	match room_style:
		"firewall_breach":
			return Color("#321018")
		"buffer_vault":
			return Color("#102a56")
		"vertical_data_conduit":
			return Color("#1d2552")
		_:
			return Color("#24333a")

func _tool_label(tool_id: String) -> String:
	match tool_id:
		"10mm_wrench":
			return "10mm Wrench"
		"optical_lens":
			return "Optical Lens"
		"friction_saddle":
			return "Friction Harness"
		"obsidian_shell":
			return "Obsidian Shell"
		"silicon_padded_gear":
			return "Silicon Gear"
		"thermal_torch":
			return "Thermal Torch"
		_:
			return tool_id.capitalize()

func _tool_icon(tool_id: String) -> String:
	match tool_id:
		"10mm_wrench":
			return "W"
		"optical_lens":
			return "O"
		"friction_saddle":
			return "F"
		"obsidian_shell":
			return "M"
		"silicon_padded_gear":
			return "S"
		"thermal_torch":
			return "T"
		_:
			return "?"

func _tool_color(tool_id: String) -> Color:
	match tool_id:
		"10mm_wrench":
			return Color("#ffd166")
		"optical_lens":
			return Color("#58dbff")
		"friction_saddle":
			return Color("#70ff8f")
		"obsidian_shell":
			return Color("#ff8a4c")
		"silicon_padded_gear":
			return Color("#b7fffb")
		"thermal_torch":
			return Color("#ff594d")
		_:
			return Color("#8fe6ff")

func _tool_role(tool_id: String) -> String:
	match tool_id:
		"10mm_wrench":
			return "manual_override"
		"optical_lens":
			return "diagnostic_refraction"
		"friction_saddle":
			return "traction_grip"
		"obsidian_shell":
			return "thermal_shield"
		"silicon_padded_gear":
			return "lag_buffer"
		"thermal_torch":
			return "stripped_bolt_cut"
		_:
			return "analog_relic"

func _draw_hud() -> void:
	var panel := Rect2(24, 18, size.x - 48, 86)
	var accent := _room_accent_color()
	_draw_panel_frame(panel, Color("#101418dd"), accent, 2.0)
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, 5)), accent)
	draw_string(ThemeDB.fallback_font, Vector2(42, 46), dungeon.get("name", "Hardware Dungeon"), HORIZONTAL_ALIGNMENT_LEFT, 520, 22, Color("#f1e4bd"))
	draw_string(ThemeDB.fallback_font, Vector2(42, 74), message, HORIZONTAL_ALIGNMENT_LEFT, size.x - 84, 16, Color("#d5dde0"))
	if room_complete and not completion_story_beat.is_empty():
		var card := Rect2(42, 106, minf(640.0, size.x - 84.0), 68)
		_draw_panel_frame(card, Color("#05080aee"), Color("#f1e4bd"), 2.0)
		draw_string(ThemeDB.fallback_font, card.position + Vector2(14, 22), str(completion_story_beat.get("captains_log_title", "Captain's Log")), HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 28, 13, Color("#f1e4bd"))
		draw_string(ThemeDB.fallback_font, card.position + Vector2(14, 48), str(completion_story_beat.get("payoff", "")), HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 28, 13, Color("#d5dde0"))
	_draw_relic_pickup_card_hud()
	draw_rect(Rect2(size.x - 448, 32, 396, 25), Color("#05080acc"))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 430, 49), "A/D move  W/Up jump  Space wrench  Esc exit", HORIZONTAL_ALIGNMENT_LEFT, 400, 14, Color("#99d6e8"))
	_draw_interaction_prompt_hud()
	_draw_enemy_roster_hud()
	_draw_shielded_port_network_hud()
	_draw_torque_meter_hud()
	_draw_binary_display_hud()
	_draw_utility_belt_hud()

func _draw_relic_pickup_card_hud() -> void:
	var profile := get_relic_pickup_card_profile()
	if not bool(profile.get("visible", false)):
		return
	var color: Color = profile.get("frame_color", Color("#58dbff"))
	var glow: Color = profile.get("glow_color", color.lightened(0.16))
	var alpha := clampf(float(profile.get("timer", 0.0)) / 1.6, 0.0, 1.0)
	var panel := Rect2(size.x * 0.5 - 210.0, 112.0, 420.0, 76.0)
	_draw_panel_frame(panel, Color("#05080af0"), color, 2.0)
	draw_rect(panel.grow(7.0), Color(glow.r, glow.g, glow.b, 0.08 + alpha * 0.08), false, 2.0)
	var icon_center := panel.position + Vector2(42.0, 38.0)
	draw_circle(icon_center, 21.0, Color(color.r, color.g, color.b, 0.18))
	draw_polygon(PackedVector2Array([
		icon_center + Vector2(0.0, -16.0),
		icon_center + Vector2(16.0, 0.0),
		icon_center + Vector2(0.0, 16.0),
		icon_center + Vector2(-16.0, 0.0),
	]), PackedColorArray([Color("#dffbff", 0.76)]))
	draw_arc(icon_center, 25.0 + (1.0 - alpha) * 8.0, 0.0, TAU, 28, Color(color.r, color.g, color.b, alpha * 0.42), 1.0)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(82.0, 28.0), str(profile.get("label", "ANALOG RELIC ACQUIRED")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 96.0, 16, Color("#f8fbff"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(82.0, 52.0), str(profile.get("subtext", "SCHEMATIC UPLOAD READY")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 96.0, 11, color.lightened(0.12))

func _draw_utility_belt_hud() -> void:
	var belt := get_utility_belt_hud_profile()
	if not bool(belt.get("visible", false)):
		return
	var color: Color = belt.get("frame_color", Color("#ffd166"))
	var panel := Rect2(28, size.y - 82.0, 310.0, 54.0)
	_draw_panel_frame(panel, Color("#05080add"), color, 2.0)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12.0, 18.0), str(belt.get("label", "UTILITY BELT")), HORIZONTAL_ALIGNMENT_LEFT, 120, 12, Color("#f8fbff"))
	var x := panel.position.x + 130.0
	for socket in belt.get("sockets", []):
		var socket_color: Color = socket.get("color", color)
		var rect := Rect2(Vector2(x, panel.position.y + 10.0), Vector2(42.0, 34.0))
		draw_rect(rect, Color(socket_color.r, socket_color.g, socket_color.b, 0.16))
		draw_rect(rect, socket_color, false, 2.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(13.0, 23.0), str(socket.get("icon", "?")), HORIZONTAL_ALIGNMENT_LEFT, 18, 18, Color("#f8fbff"))
		x += 48.0
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12.0, 39.0), str(belt.get("carried_label", "EMPTY")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 24.0, 10, color.lightened(0.12))

func _draw_interaction_prompt_hud() -> void:
	var prompt := get_interaction_prompt_profile()
	if not bool(prompt.get("visible", false)):
		return
	var color: Color = prompt.get("prompt_color", Color("#ffd166"))
	var panel := Rect2(size.x - 448, 62, 396, 24)
	draw_rect(panel, Color("#05080acc"))
	draw_rect(panel, Color(color.r, color.g, color.b, 0.42), false, 1.0)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(14, 17), str(prompt.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 28, 12, color.lightened(0.12))

func _draw_enemy_roster_hud() -> void:
	var roster := get_enemy_roster_hud_profile()
	if not bool(roster.get("visible", false)):
		return
	var color: Color = roster.get("hud_color", Color("#58dbff"))
	var panel := Rect2(size.x - 344, 112, 292, 86)
	_draw_panel_frame(panel, Color("#05080add"), color, 2.0)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12, 18), str(roster.get("panel_title", "PROCESS WATCH")), HORIZONTAL_ALIGNMENT_LEFT, 120, 12, Color("#f8fbff"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(148, 18), "%d PROC" % int(roster.get("enemy_count", 0)), HORIZONTAL_ALIGNMENT_LEFT, 80, 12, color.lightened(0.16))
	var names := ", ".join(roster.get("enemy_labels", []).slice(0, 2))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12, 40), names, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 24, 10, Color("#d5dde0"))
	var counters := "Counters: " + ", ".join(roster.get("counter_tools", []))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12, 58), counters, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 24, 9, Color(color.r, color.g, color.b, 0.9))
	var badge_x := panel.position.x + 12.0
	for badge in roster.get("badge_labels", []):
		var label := str(badge)
		var label_size := ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 7)
		var badge_rect := Rect2(Vector2(badge_x, panel.position.y + 66.0), Vector2(label_size.x + 8.0, 12.0))
		draw_rect(badge_rect, Color(color.r, color.g, color.b, 0.18))
		draw_rect(badge_rect, Color(color.r, color.g, color.b, 0.45), false, 1.0)
		draw_string(ThemeDB.fallback_font, badge_rect.position + Vector2(4.0, 8.5), label, HORIZONTAL_ALIGNMENT_LEFT, label_size.x, 7, Color("#f8fbff", 0.9))
		badge_x += badge_rect.size.x + 4.0

func _draw_shielded_port_network_hud() -> void:
	var network := get_shielded_port_network_profile()
	if not bool(network.get("visible", false)):
		return
	var color: Color = network.get("status_color", Color("#58dbff"))
	var panel := Rect2(size.x - 344, 206, 292, 58)
	_draw_panel_frame(panel, Color("#05080add"), color, 2.0)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12, 18), "SHIELDED PORTS", HORIZONTAL_ALIGNMENT_LEFT, 140, 12, Color("#f8fbff"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(164, 18), "%d/%d SEALED" % [int(network.get("sealed_count", 0)), int(network.get("port_count", 0))], HORIZONTAL_ALIGNMENT_LEFT, 110, 12, color.lightened(0.12))
	var status := "PURGE READY" if bool(network.get("purge_ready", false)) else "EXPOSED"
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12, 40), status, HORIZONTAL_ALIGNMENT_LEFT, 110, 11, color)
	var labels := " ".join(network.get("labels", []).slice(0, 2))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(108, 40), labels, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 120, 9, Color("#d5dde0"))

func _draw_torque_meter_hud() -> void:
	var profile := get_torque_meter_hud_profile()
	if not bool(profile.get("visible", false)):
		return
	var panel := Rect2(28, 112, 214, 112)
	var bezel: Color = profile.get("bezel_color", Color("#58dbff"))
	_draw_panel_frame(panel, Color("#05080add"), bezel, 2.0)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12, 20), str(profile.get("input_label", "TORQUE")), HORIZONTAL_ALIGNMENT_LEFT, 120, 13, Color("#f8fbff"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(126, 20), str(profile.get("zone_label", "")), HORIZONTAL_ALIGNMENT_LEFT, 78, 12, bezel.lightened(0.18))
	var green_min := float(profile.get("green_min", 0.45))
	var green_max := float(profile.get("green_max", 0.62))
	var center := panel.position + Vector2(74, 72)
	var radius := 34.0
	var arc_start := deg_to_rad(210.0)
	var arc_end := deg_to_rad(510.0)
	var green_start := lerpf(arc_start, arc_end, green_min)
	var green_end := lerpf(arc_start, arc_end, green_max)
	var red_start := lerpf(arc_start, arc_end, 0.82)
	var red_end := arc_end
	var tick_color := Color("#f8fbff", 0.32)
	draw_circle(center, radius + 12.0, Color("#081017", 0.82))
	draw_circle(center, radius + 4.0, Color("#101b24", 0.9))
	draw_arc(center, radius, arc_start, arc_end, 42, Color(bezel.r, bezel.g, bezel.b, 0.32), 5.0)
	draw_arc(center, radius, green_start, green_end, 16, Color("#70ff8f", 0.92), 6.0)
	draw_arc(center, radius, red_start, red_end, 14, Color("#ff453a", 0.72), 5.0)
	for i in range(9):
		var mark_value := float(i) / 8.0
		var angle := lerpf(arc_start, arc_end, mark_value)
		var inner := center + Vector2(cos(angle), sin(angle)) * (radius - 4.0)
		var outer := center + Vector2(cos(angle), sin(angle)) * (radius + 5.0)
		draw_line(inner, outer, tick_color, 1.0)
	var needle_value := clampf(float(profile.get("needle_value", 0.0)), 0.0, 1.0)
	var vibration := float(profile.get("vibration", 0.0))
	var needle_angle := lerpf(arc_start, arc_end, needle_value) + sin(Time.get_ticks_msec() * 0.04) * vibration * 0.18
	var needle_color: Color = profile.get("needle_color", Color("#f8fbff"))
	draw_line(center, center + Vector2(cos(needle_angle), sin(needle_angle)) * (radius - 2.0), needle_color, 3.0)
	draw_circle(center, 4.0, needle_color)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(132, 55), "SAFE", HORIZONTAL_ALIGNMENT_LEFT, 50, 10, Color("#70ff8f"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(132, 78), "RED", HORIZONTAL_ALIGNMENT_LEFT, 44, 10, Color("#ff8f8f"))
	var progress := float(profile.get("turn_progress", 0.0))
	var progress_rect := Rect2(panel.position + Vector2(122, 88), Vector2(72, 6))
	draw_rect(progress_rect, Color("#111820"))
	if progress > 0.0:
		draw_rect(Rect2(progress_rect.position, Vector2(progress_rect.size.x * clampf(progress, 0.0, 1.0), progress_rect.size.y)), Color("#70ff8f", 0.72))
	draw_rect(progress_rect, Color(bezel.r, bezel.g, bezel.b, 0.42), false, 1.0)
	if bool(profile.get("sparks", false)):
		for i in range(5):
			var spark_start := center + Vector2(cos(needle_angle), sin(needle_angle)) * radius
			draw_line(spark_start, spark_start + Vector2(10.0 + i * 3.0, -10.0 + i * 5.0), Color("#ffd166", 0.82), 1.0)

func _draw_binary_display_hud() -> void:
	var profile := get_binary_display_hud_profile()
	if not bool(profile.get("visible", false)):
		return
	var panel := Rect2(256, 112, 286, 112)
	var frame_color: Color = profile.get("frame_color", Color("#58dbff"))
	_draw_panel_frame(panel, Color("#06112add"), frame_color, 2.0)
	draw_rect(panel.grow(-8.0), Color(frame_color.r, frame_color.g, frame_color.b, float(profile.get("crt_glow", 0.5)) * 0.08))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12, 20), str(profile.get("header", "TARGET")), HORIZONTAL_ALIGNMENT_LEFT, 100, 13, Color("#f8fbff"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(158, 20), "%s %d/%d" % [profile.get("door_feedback", "LOCK"), int(profile.get("current_sum", 0)), int(profile.get("target_sum", 0))], HORIZONTAL_ALIGNMENT_LEFT, 110, 12, frame_color.lightened(0.15))
	for y in range(int(panel.position.y) + 30, int(panel.end.y) - 6, 6):
		draw_line(Vector2(panel.position.x + 8.0, y), Vector2(panel.end.x - 8.0, y), Color("#f8fbff", 0.035), 1.0)
	var x := panel.position.x + 16.0
	for digit in profile.get("digits", []):
		var color: Color = digit.get("glow_color", Color("#56616f"))
		var alpha := float(digit.get("alpha", 0.4))
		var rect := Rect2(Vector2(x, panel.position.y + 42.0), Vector2(54.0, 44.0))
		draw_rect(rect.grow(4.0), Color(color.r, color.g, color.b, alpha * 0.18))
		draw_rect(rect, Color("#05080a"))
		draw_rect(rect, Color(color.r, color.g, color.b, alpha * 0.32))
		draw_rect(rect, Color(color.r, color.g, color.b, alpha), false, 2.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(12, 29), "%d" % int(digit.get("bit", 0)), HORIZONTAL_ALIGNMENT_LEFT, 20, 24, Color("#f8fbff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(31, 14), "%d" % int(digit.get("weight", 0)), HORIZONTAL_ALIGNMENT_LEFT, 18, 9, Color("#dcefff"))
		x += 64.0
	var state_color := Color("#70ff8f") if bool(profile.get("matched", false)) else Color("#ffd166")
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(16, 100), str(profile.get("status", "")), HORIZONTAL_ALIGNMENT_LEFT, 160, 11, state_color)

func _draw_boss_pressure() -> void:
	if boss.is_empty():
		return
	var panel := Rect2(size.x - 370, 118, 320, 74)
	_draw_panel_frame(panel, Color("#190e16e8"), Color("#6ee7a8") if boss_defeated else Color("#ff6b9a"), 2.0)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(16, 26), "PHYSICAL ANOMALY: %s" % boss.get("name", "Unknown"), HORIZONTAL_ALIGNMENT_LEFT, 290, 15, Color("#ffd7e4"))
	var state := "DISABLED" if boss_defeated else "Threat: %s | Weakness: %s" % [boss.get("attack", ""), boss.get("weakness", "")]
	if not boss_defeated and bool(boss_pressure.get("telegraph_active", false)):
		state = "%s %.1fs" % [get_boss_telegraph_label(), float(boss_pressure.get("countdown", 0.0))]
	elif not boss_defeated and get_boss_core_vulnerable():
		state = "CORE EXPOSED: %s" % boss_pressure.get("vulnerability_label", "Recovery Window")
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(16, 52), state, HORIZONTAL_ALIGNMENT_LEFT, 290, 13, Color("#e7edf0"))

func _draw_boss_attack() -> void:
	if boss_defeated or boss_pressure.is_empty():
		return
	var active := bool(boss_pressure.get("active", false))
	var telegraph := bool(boss_pressure.get("telegraph_active", false))
	if not active and not telegraph:
		return
	var anomaly_vfx := HardwareDungeonData.get_anomaly_vfx_profile(str(boss.get("id", "")), boss_pressure)
	var warning_color: Color = anomaly_vfx.get("warning_color", Color("#ff6b9a"))
	var fill := Color(warning_color.r, warning_color.g, warning_color.b, float(anomaly_vfx.get("hazard_alpha", 0.4)))
	var outline := warning_color
	for safe_spot in _boss_safe_spots():
		var safe_color: Color = anomaly_vfx.get("safe_spot_color", Color("#6ee7a8"))
		draw_rect(safe_spot, Color(safe_color.r, safe_color.g, safe_color.b, 0.20))
		draw_rect(safe_spot, safe_color, false, 2.0)
		draw_string(ThemeDB.fallback_font, safe_spot.position + Vector2(8, -6), "SAFE", HORIZONTAL_ALIGNMENT_LEFT, 80, 12, Color("#caffdd"))
	for rect in _boss_attack_rects():
		draw_rect(rect, fill)
		draw_rect(rect, outline, false, 2.0)
		if str(boss_pressure.get("pattern_id", "")) == "diagnostic_light_columns":
			var beam_color: Color = anomaly_vfx.get("beam_color", Color("#58dbff"))
			draw_line(rect.position + Vector2(rect.size.x * 0.5, 0), rect.position + Vector2(rect.size.x * 0.5, rect.size.y), beam_color, 4.0)
		elif int(anomaly_vfx.get("debris_count", 0)) > 0:
			for i in int(anomaly_vfx.get("debris_count", 0)):
				var chip := rect.position + Vector2(14 + (i * 29) % int(maxf(1.0, rect.size.x - 24.0)), 7 + (i % 3) * 10)
				draw_rect(Rect2(chip, Vector2(5, 5)), Color("#d6d0bc", 0.72))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, -8), boss_pressure.get("label", "") if active else get_boss_telegraph_label(), HORIZONTAL_ALIGNMENT_LEFT, 260, 13, outline)

func _boss_attack_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for rect in boss_pressure.get("rects", [boss_pressure.get("rect", Rect2())]):
		if rect is Rect2:
			result.append(rect)
	return result

func _boss_safe_spots() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for rect in boss_pressure.get("safe_spots", []):
		if rect is Rect2:
			result.append(rect)
	return result

func _draw_boss_core() -> void:
	if boss.is_empty() or not _all_mechanisms_complete():
		return
	var anomaly_vfx := HardwareDungeonData.get_anomaly_vfx_profile(str(boss.get("id", "")), boss_pressure)
	var core_fill := Color("#203022") if boss_defeated else Color("#5b1535")
	var core_line := Color("#6ee7a8") if boss_defeated else Color("#ff6b9a")
	if get_boss_core_vulnerable():
		core_fill = Color("#544512")
		core_line = anomaly_vfx.get("warning_color", Color("#ffd166"))
	draw_rect(boss_core_rect, core_fill)
	draw_rect(boss_core_rect, core_line, false, 3.0)
	for i in int(anomaly_vfx.get("core_ring_count", 0)):
		draw_rect(boss_core_rect.grow(6.0 + i * 7.0), Color(core_line.r, core_line.g, core_line.b, 0.36 - i * 0.08), false, 2.0)
	draw_string(ThemeDB.fallback_font, boss_core_rect.position + Vector2(-18, -12), "ANOMALY CORE", HORIZONTAL_ALIGNMENT_LEFT, 150, 13, Color("#eaf0e5"))

func _room_backdrop_color() -> Color:
	match dungeon_id:
		"southern_partition_airlock":
			return Color("#1d0d12")
		"great_buffer":
			return Color("#071a3f")
		"logic_core":
			return Color("#10122a")
		_:
			return Color("#111820")
