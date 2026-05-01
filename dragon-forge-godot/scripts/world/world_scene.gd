extends Control

signal encounter_requested(enemy_id: String, context: Dictionary)
signal dungeon_requested(dungeon_id: String, context: Dictionary)
signal profile_changed(profile: Dictionary)
signal save_requested
signal load_requested

const WorldData := preload("res://scripts/sim/world_data.gd")
const TechniqueData := preload("res://scripts/sim/technique_data.gd")
const DragonProgression := preload("res://scripts/sim/dragon_progression.gd")
const DragonData := preload("res://scripts/sim/dragon_data.gd")
const StoryData := preload("res://scripts/sim/story_data.gd")
const ScanlineOverlay := preload("res://scripts/world/scanline_overlay.gd")
const TacticalBattle := preload("res://scripts/sim/tactical_battle.gd")
const MissionData := preload("res://scripts/sim/mission_data.gd")
const SideQuestData := preload("res://scripts/sim/sidequest_data.gd")
const ServiceTicketData := preload("res://scripts/sim/service_ticket_data.gd")
const VisualSystemData := preload("res://scripts/sim/visual_system_data.gd")
const HardwareDungeonData := preload("res://scripts/sim/hardware_dungeon_data.gd")
const ActTwoTundraData := preload("res://scripts/sim/act_two_tundra_data.gd")
const ActOneProgressionData := preload("res://scripts/sim/act_one_progression_data.gd")
const ActTwoProgressionData := preload("res://scripts/sim/act_two_progression_data.gd")
const RestorationData := preload("res://scripts/sim/restoration_data.gd")
const ThermalCurveDisplay := preload("res://scripts/world/thermal_curve_display.gd")
const RelayRouteDisplay := preload("res://scripts/world/relay_route_display.gd")
const WaveformDisplay := preload("res://scripts/world/waveform_display.gd")
const GradingSlabDisplay := preload("res://scripts/world/grading_slab_display.gd")
const HandshakeSpectrogramDisplay := preload("res://scripts/world/handshake_spectrogram_display.gd")
const ThreadfallOverlay := preload("res://scripts/world/threadfall_overlay.gd")
const CompassDisplay := preload("res://scripts/world/compass_display.gd")
const WorldMapView := preload("res://scripts/world/world_map_view.gd")
const CreditsRunDisplay := preload("res://scripts/world/credits_run_display.gd")

const DANGER_THRESHOLD := 100.0
const TILE_SIZE := Vector2(84, 64)
const TILE_GAP := 8.0
const ANVIL_KIT_DUNGEONS := ["cooling_intake", "great_buffer", "mirror_admin_gate", "logic_core"]
const KIND_COLORS := {
	"field": Color("#5f6f53"),
	"lab": Color("#45545f"),
	"forge": Color("#9a4f36"),
	"archive": Color("#5c5b72"),
	"gate": Color("#6f423c"),
	"jungle": Color("#2f6b45"),
	"hardware": Color("#7a7d78"),
	"salt": Color("#9b998d"),
	"lunar": Color("#4f5973"),
	"kernel": Color("#202434"),
	"wall": Color("#15171a"),
}

var world := WorldData.create_world_state()
var profile := DragonProgression.create_profile("fire")
var map_view: Control
var title_label: Label
var status_label: Label
var detail_label: Label
var objective_box: VBoxContainer
var nav_box: VBoxContainer
var bios_box: VBoxContainer
var action_box: VBoxContainer
var mission_box: VBoxContainer
var dragon_box: VBoxContainer
var technique_box: VBoxContainer
var side_scroll: ScrollContainer
var compass_display: CompassDisplay
var ticket_popup: PanelContainer
var ticket_title_label: Label
var ticket_desc_label: Label
var scanline_overlay: Control
var threadfall_overlay: ThreadfallOverlay
var last_artifact_id := ""
var last_ticket_id := ""
var status_message := "Move one tile at a time with WASD/Arrows, or click an adjacent tile."
var danger_meter := 0.0
var pending_wild_encounter: Dictionary = {}
var admin_overlay_visible := false
var custom_waypoint := Vector2i(-1, -1)
var mission_state := {
	"mission_05": { "samples": [] },
	"mission_06": { "captures": [], "next_capture": 0 },
	"mission_07": { "input_trace": [], "stamina": 100.0, "charge": 0.0, "pedal": 0.5 },
	"mission_08": { "target": 440.0, "roar": 432.0 },
	"mission_09": { "response": [], "purge_count": 0, "fork_stamina": 100.0, "last_light": "#000000" },
	"mission_10": { "tethers": 0 },
	"mission_11": { "anchors": [], "deletion_wall_distance": 100 },
	"mission_12": { "permission_nodes": [], "daemon_uploaded": false },
	"admin": { "sector_integrity": 0.85 },
	"sidequests": {
		"memory_leak": { "timer": 300.0, "locked_assets": [] },
		"ghost_in_the_well": { "roar": 440.0 },
		"unauthorized_manual": { "pages": 0 },
		"rerender_portrait": { "passes": 0 },
		"asset_recovery": { "fragments": 0, "glitch": 0 },
		"wireframe_harvest": { "bakes": 0 },
		"stuck_path": { "shorts": 0 },
		"corrupted_lullaby": { "roar": 429.0 },
		"sentinel_404": { "updated": false },
	},
}

func _ready() -> void:
	_build_ui()
	_refresh()

func set_profile(next_profile: Dictionary) -> void:
	profile = next_profile.duplicate(true)
	if is_inside_tree():
		_refresh()

func apply_dungeon_result(result: Dictionary) -> void:
	if result.get("completed", false):
		var fragment: Dictionary = result.get("captains_log_fragment", {})
		if not fragment.is_empty():
			profile = DragonProgression.unlock_captains_log_fragment(profile, fragment)
			status_message = "Hardware layer repaired: %s. Captain's Log fragment unlocked: %s." % [str(result.get("dungeon_id", "dungeon")), fragment.get("title", "Recovered Log")]
			profile_changed.emit(profile.duplicate(true))
		else:
			status_message = "Hardware layer repaired: %s." % str(result.get("dungeon_id", "dungeon"))
	else:
		status_message = "Returned from the hardware layer."
	if is_inside_tree():
		_refresh()

func export_state() -> Dictionary:
	return {
		"world_position": {
			"x": world["player"]["position"].x,
			"y": world["player"]["position"].y,
		},
		"profile": profile.duplicate(true),
		"mission_state": mission_state.duplicate(true),
		"last_artifact_id": last_artifact_id,
		"status_message": status_message,
		"danger_meter": danger_meter,
		"pending_wild_encounter": pending_wild_encounter.duplicate(true),
		"admin_overlay_visible": admin_overlay_visible,
		"custom_waypoint": { "x": custom_waypoint.x, "y": custom_waypoint.y },
	}

func get_sidebar_console_profile() -> Dictionary:
	var anvil_ui := DragonProgression.get_anvil_relic_ui_profile(profile)
	var log_ui := HardwareDungeonData.get_captains_log_ui_profile(profile)
	var hatchery_ui := DragonProgression.get_hatchery_ring_ui_profile(profile)
	var framed_count: int = anvil_ui.get("entries", []).size() + anvil_ui.get("slot_rows", []).size() + log_ui.get("entries", []).size() + 1
	var unlocked_log_count: int = int(log_ui.get("unlocked_count", 0))
	var readability_score: float = clampf(0.42 + minf(float(framed_count), 10.0) * 0.04 + float(unlocked_log_count) * 0.03, 0.0, 1.0)
	return {
		"screen_id": "world_sidebar_console",
		"anvil_card_count": anvil_ui.get("entries", []).size(),
		"anvil_socket_count": anvil_ui.get("slot_rows", []).size(),
		"anvil_slot_pressure": anvil_ui.get("slot_pressure", 0.0),
		"anvil_chrome": anvil_ui.get("chrome_style", {}),
		"log_card_count": log_ui.get("entries", []).size(),
		"log_completion_label": log_ui.get("completion_label", "0/0 fragments"),
		"log_chrome": log_ui.get("chrome_style", {}),
		"hatchery_status_label": hatchery_ui.get("status_label", "SEALED"),
		"hatchery_registry_label": hatchery_ui.get("registry_label", "0 dragon protocols"),
		"hatchery_chrome": hatchery_ui.get("chrome_style", {}),
		"framed_panel_count": framed_count,
		"readability_score": readability_score,
		"readability_label": "AAA READY" if readability_score >= 0.78 else "POLISHING",
		"uses_framed_cards": true,
		"presentation": "playable_1991_equipment_log_screen",
	}

func get_world_layout_profile() -> Dictionary:
	return {
		"map_has_expand_fill": map_view != null and map_view.size_flags_vertical == Control.SIZE_EXPAND_FILL,
		"sidebar_scrolls": side_scroll != null and side_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
		"sidebar_min_width": side_scroll.custom_minimum_size.x if side_scroll != null else 0.0,
		"layout_contract": "bounded_map_with_scrollable_sidebar",
	}

func import_state(state: Dictionary) -> void:
	var saved_position: Dictionary = state.get("world_position", {})
	if not saved_position.is_empty():
		world = WorldData.create_world_state(Vector2i(saved_position.get("x", 10), saved_position.get("y", 10)))
	if state.has("profile"):
		profile = state["profile"].duplicate(true)
	if state.has("mission_state"):
		mission_state = state["mission_state"].duplicate(true)
	last_artifact_id = state.get("last_artifact_id", "")
	status_message = state.get("status_message", "Save loaded.")
	danger_meter = float(state.get("danger_meter", 0.0))
	pending_wild_encounter = state.get("pending_wild_encounter", {}).duplicate(true)
	admin_overlay_visible = bool(state.get("admin_overlay_visible", false))
	var saved_waypoint: Dictionary = state.get("custom_waypoint", {})
	custom_waypoint = Vector2i(saved_waypoint.get("x", -1), saved_waypoint.get("y", -1))
	if is_inside_tree():
		_refresh()

func get_dungeon_entry_context_for_test(current: Dictionary) -> Dictionary:
	return _dungeon_entry_context(current)

func get_dungeon_entry_readiness_for_test(current: Dictionary) -> Dictionary:
	return _dungeon_entry_readiness(current)

func get_dungeon_entry_card_for_test(current: Dictionary) -> Dictionary:
	return _dungeon_entry_card_profile(current)

func socket_anvil_kit_for_test(dungeon_id: String) -> Dictionary:
	return _socket_anvil_kit(dungeon_id)

func get_lore_panel_lines_for_test(current: Dictionary) -> Array[String]:
	return _lore_panel_lines(current)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed():
		return
	if event.is_action_pressed("move_up"):
		_move("north")
	elif event.is_action_pressed("move_down"):
		_move("south")
	elif event.is_action_pressed("move_left"):
		_move("west")
	elif event.is_action_pressed("move_right"):
		_move("east")
	elif event.is_action_pressed("confirm"):
		if _confirm_selected_map_tile():
			return
		var current := WorldData.get_current_tile(world)
		if current.get("dungeon_id", "") != "":
			_request_dungeon(current)
			return
		if current.get("mission", "") == "mission_09" and not DragonProgression.has_mission_flag(profile, "mission_09_complete"):
			return
		if not pending_wild_encounter.is_empty():
			_start_pending_wild_encounter(current)
			return
		var encounter = WorldData.get_world_encounter(world)
		if encounter != null:
			encounter_requested.emit(encounter["enemy_id"], _encounter_context(current, encounter))
	elif event.is_action_pressed("toggle_diagnostic"):
		_toggle_diagnostic_map()

func _confirm_selected_map_tile() -> bool:
	if map_view == null:
		return false
	var selected_position: Vector2i = map_view.get_selected_tile_position()
	if selected_position.x < 0 or selected_position == world["player"]["position"]:
		return false
	var command: Dictionary = map_view.confirm_selected_action(world, _available_map_gear())
	if not bool(command.get("can_execute", false)):
		var missing_gear: Array = command.get("missing_gear", [])
		status_message = "Map command blocked: %s required." % ", ".join(missing_gear) if not missing_gear.is_empty() else "Map command blocked."
		_refresh()
	return str(command.get("command_kind", "none")) != "none"

func _build_ui() -> void:
	scanline_overlay = ScanlineOverlay.new()
	scanline_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	scanline_overlay.z_index = 30
	scanline_overlay.visible = false
	add_child(scanline_overlay)

	threadfall_overlay = ThreadfallOverlay.new()
	threadfall_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	threadfall_overlay.z_index = 22
	threadfall_overlay.visible = false
	add_child(threadfall_overlay)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	root.offset_left = 32
	root.offset_top = 28
	root.offset_right = -32
	root.offset_bottom = -28
	add_child(root)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 30)
	root.add_child(title_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 16)
	root.add_child(status_label)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 22)
	root.add_child(content)

	map_view = WorldMapView.new()
	map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_view.tile_clicked.connect(_on_tile_pressed)
	map_view.selected_action_requested.connect(_on_map_action_requested)
	content.add_child(map_view)

	side_scroll = ScrollContainer.new()
	side_scroll.custom_minimum_size = Vector2(360, 0)
	side_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(side_scroll)

	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 14)
	side_scroll.add_child(side)

	detail_label = Label.new()
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size", 18)
	side.add_child(detail_label)

	compass_display = CompassDisplay.new()
	side.add_child(compass_display)

	ticket_popup = PanelContainer.new()
	ticket_popup.visible = false
	side.add_child(ticket_popup)
	var ticket_box := VBoxContainer.new()
	ticket_box.add_theme_constant_override("separation", 4)
	ticket_popup.add_child(ticket_box)
	ticket_title_label = Label.new()
	ticket_title_label.add_theme_font_size_override("font_size", 15)
	ticket_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ticket_box.add_child(ticket_title_label)
	ticket_desc_label = Label.new()
	ticket_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ticket_box.add_child(ticket_desc_label)

	objective_box = VBoxContainer.new()
	objective_box.add_theme_constant_override("separation", 6)
	side.add_child(objective_box)

	nav_box = VBoxContainer.new()
	nav_box.add_theme_constant_override("separation", 8)
	side.add_child(nav_box)

	bios_box = VBoxContainer.new()
	bios_box.add_theme_constant_override("separation", 6)
	side.add_child(bios_box)

	action_box = VBoxContainer.new()
	action_box.add_theme_constant_override("separation", 8)
	side.add_child(action_box)

	mission_box = VBoxContainer.new()
	mission_box.add_theme_constant_override("separation", 8)
	side.add_child(mission_box)

	var hint := Label.new()
	hint.text = "WASD/Arrows move one tile. Click an adjacent tile to step. Space/Enter starts an available encounter."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(hint)

	dragon_box = VBoxContainer.new()
	dragon_box.add_theme_constant_override("separation", 8)
	side.add_child(dragon_box)

	technique_box = VBoxContainer.new()
	technique_box.add_theme_constant_override("separation", 8)
	side.add_child(technique_box)

func _move(direction: String) -> void:
	var before := WorldData.get_current_tile(world)
	world = WorldData.move_player(world, direction)
	var after := WorldData.get_current_tile(world)
	var moved: bool = after["id"] != before["id"]
	status_message = "Moved to %s." % _tile_label(after) if moved else "Blocked: no walkable path %s from %s." % [direction, _tile_label(before)]
	if moved:
		_advance_danger(after)
	_refresh()

func _on_tile_pressed(position: Vector2i) -> void:
	var tile := WorldData.get_tile_at(world, position)
	if tile.is_empty() or not tile.get("walkable", false):
		status_message = "Blocked: %s is not walkable." % (tile.get("label", "that sector") if not tile.is_empty() else "void")
		_refresh()
		return
	var current_position: Vector2i = world["player"]["position"]
	var delta: Vector2i = position - current_position
	if abs(delta.x) + abs(delta.y) != 1:
		if _is_system_alert_position(position):
			custom_waypoint = position
			status_message = "Waypoint set: %s." % _tile_label(tile)
			_refresh()
			return
		status_message = "Too far: move one tile at a time toward %s." % _tile_label(tile)
		_refresh()
		return
	world = WorldData.move_player_to(world, position)
	var after := WorldData.get_current_tile(world)
	status_message = "Stepped to %s." % _tile_label(after)
	if after.get("id", "") == "tundra_of_silicon" and DragonProgression.has_key_item(profile, "firewall_bypass") and not DragonProgression.has_mission_flag(profile, "act_one_complete"):
		profile = DragonProgression.set_mission_flag(profile, "act_one_complete")
		profile = ActTwoProgressionData.enter_tundra(profile)
		status_message = "Act I complete: the Southern Partition firewall falls away into the Tundra of Silicon."
		profile_changed.emit(profile.duplicate(true))
	_advance_danger(after)
	_refresh()

func _on_map_action_requested(command: Dictionary) -> void:
	if not bool(command.get("can_execute", false)):
		var missing_gear: Array = command.get("missing_gear", [])
		status_message = "Map command blocked: %s required." % ", ".join(missing_gear) if not missing_gear.is_empty() else "Map command blocked."
		_refresh()
		return
	var map_position: Vector2i = command.get("position", Vector2i(-1, -1))
	var tile := WorldData.get_tile_at(world, map_position)
	if tile.is_empty():
		status_message = "Map command lost: selected sector is missing from the shipframe."
		_refresh()
		return
	var command_kind := str(command.get("command_kind", "travel"))
	match command_kind:
		"access_port", "dungeon":
			_request_dungeon(tile)
		"arena":
			var encounter: Variant = tile.get("encounter", null)
			if encounter is Dictionary:
				var encounter_data: Dictionary = encounter
				status_message = "Entering %s..." % encounter_data.get("title", tile.get("label", "arena"))
				encounter_requested.emit(str(encounter_data.get("enemy_id", "")), _encounter_context(tile, encounter_data))
			else:
				status_message = "Arena command received, but no hostile process is indexed there."
				_refresh()
		"jump_pad":
			status_message = "Overflow Pipe pressure cycle armed. Route: %s." % str(command.get("route_hint", "ascent"))
			custom_waypoint = map_position
			_refresh()
		"hatchery":
			_open_hatchery_ring(tile)
		"artifact":
			status_message = "Relic ping: %s is marked for retrieval." % str(command.get("artifact", tile.get("label", "artifact")))
			custom_waypoint = map_position
			_refresh()
		"npc":
			status_message = "Local contact marked: %s." % _tile_label(tile)
			custom_waypoint = map_position
			_refresh()
		"travel":
			_on_tile_pressed(map_position)
		_:
			status_message = "Map command acknowledged: %s." % _tile_label(tile)
			_refresh()

func _refresh() -> void:
	_ensure_system_admin_state()
	_ensure_sidequest_state()
	var current := WorldData.get_current_tile(world)
	if custom_waypoint == world["player"]["position"]:
		custom_waypoint = Vector2i(-1, -1)
	_resolve_tile_artifact(current)
	_resolve_vertical_slice_completion()
	title_label.text = "Dragon Forge: %s" % _tile_label(current)
	status_label.text = status_message
	detail_label.text = "%s\n\n%s%s%s" % [_tile_description(current), _hazard_text(current), _danger_text(current), _encounter_text()]
	scanline_overlay.visible = current.get("scanline", false)
	threadfall_overlay.set_intensity(VisualSystemData.threadfall_intensity(current, profile, mission_state))
	map_view.set_integrity_state(VisualSystemData.integrity_fog_state(_sector_integrity()))
	_refresh_navigation_hud(current)
	_refresh_ticket_popup(current)
	_rebuild_objective_panel()
	_rebuild_nav_panel(current)
	_rebuild_bios_panel(current)
	_rebuild_action_panel(current)
	_rebuild_mission_panel(current)
	_rebuild_dragon_console(current)
	_rebuild_technique_console(current)
	map_view.set_world(world, _map_label_overrides(), _cleared_arena_ids(), _current_slice_objective().get("target", Vector2i(-1, -1)), admin_overlay_visible, _system_pressure_map())

func _toggle_diagnostic_map() -> void:
	if not DragonProgression.has_key_item(profile, "root_access") and not DragonProgression.has_key_item(profile, "diagnostic_lens"):
		status_message = "Diagnostic Flip locked. B.I.O.S. has not granted a system view yet."
		_refresh()
		return
	admin_overlay_visible = not admin_overlay_visible
	status_message = "Diagnostic circuit view online." if admin_overlay_visible else "Pastoral map view restored."
	_refresh()

func _system_pressure_map() -> Dictionary:
	var zones: Array = []
	for position in [Vector2i(26, 4), Vector2i(9, 10), Vector2i(27, 8)]:
		var tile := WorldData.get_tile_at(world, position)
		var intensity := VisualSystemData.threadfall_intensity(tile, profile, mission_state)
		if intensity > 0.05:
			zones.append({
				"position": position,
				"intensity": intensity,
				"status": VisualSystemData.sector_status(position, Vector2i(27, 8), intensity),
			})
	var deletion_path: Array[Vector2i] = []
	if DragonProgression.has_mission_flag(profile, "stable_connection") and not DragonProgression.has_mission_flag(profile, "mission_11_complete"):
		deletion_path = [Vector2i(26, 4), Vector2i(21, 9), Vector2i(17, 10), Vector2i(13, 10), Vector2i(9, 10)]
	return {
		"husk_position": Vector2i(27, 8),
		"thread_zones": zones,
		"deletion_path": deletion_path,
		"integrity_zones": _map_integrity_zones(),
		"purge_active": _map_purge_active(),
		"purge_origin": Vector2i(24, 4),
		"safe_zones": _map_safe_zones(),
		"poi_alerts": _system_poi_alerts(),
		"custom_waypoint": custom_waypoint,
		"available_gear": _available_map_gear(),
	}

func _map_integrity_zones() -> Array:
	var zones: Array = []
	var base_integrity := _sector_integrity()
	for position in [Vector2i(13, 10), Vector2i(21, 9), Vector2i(23, 8), Vector2i(27, 8), Vector2i(26, 4), Vector2i(9, 10)]:
		var tile := WorldData.get_tile_at(world, position)
		if tile.is_empty():
			continue
		var thread_intensity := VisualSystemData.threadfall_intensity(tile, profile, mission_state)
		var integrity := clampf(base_integrity - thread_intensity * 0.58, 0.05, 1.0)
		if tile.get("id", "") == "forge_lab":
			integrity = 0.96
		elif tile.get("map_feature", "") == "jump_pad":
			integrity = minf(integrity, 0.52)
		elif tile.get("admin_node", false):
			integrity = minf(integrity, 0.32)
		if _map_purge_active() and not _map_safe_zones().has(position):
			integrity = minf(integrity, 0.24)
		zones.append({
			"position": position,
			"tile_id": tile.get("id", ""),
			"integrity": integrity,
		})
	return zones

func _map_purge_active() -> bool:
	return DragonProgression.has_mission_flag(profile, "stable_connection") and not DragonProgression.has_mission_flag(profile, "mission_11_complete")

func _map_safe_zones() -> Array:
	return [Vector2i(13, 10)]

func _available_map_gear() -> Array:
	var equipped := DragonProgression.get_carried_anvil_gear_labels(profile)
	if not equipped.is_empty():
		return equipped
	var gear: Array[String] = []
	if DragonProgression.has_key_item(profile, "10mm_wrench"):
		gear.append("10mm Wrench")
	if DragonProgression.has_key_item(profile, "obsidian_shell"):
		gear.append("Obsidian Shell")
	if DragonProgression.has_key_item(profile, "refractive_plate"):
		gear.append("Refractive Plate")
	if DragonProgression.has_key_item(profile, "friction_harness") or DragonProgression.has_key_item(profile, "friction_saddle"):
		gear.append("Friction Harness")
	return gear

func _system_poi_alerts() -> Array:
	var alerts: Array = []
	var rows: Array = world["tiles"]
	for y in rows.size():
		var row: Array = rows[y]
		for x in row.size():
			var tile: Dictionary = row[x]
			var position := Vector2i(x, y)
			for quest_id in tile.get("sidequests", []):
				var quest := SideQuestData.get_sidequest(str(quest_id))
				if quest.is_empty() or DragonProgression.has_key_item(profile, quest["reward_item"]):
					continue
				var severity := _poi_alert_severity(str(quest_id), tile)
				var ticket := ServiceTicketData.ticket_for_sidequest(str(quest_id), quest, tile, severity)
				alerts.append({
					"position": position,
					"kind": "memory_leak" if ticket["type"] == "CORRUPTION" else "sidequest",
					"label": quest["title"],
					"severity": severity,
					"icon": ticket["icon"],
					"color": ticket["color"],
					"ticket_id": ticket["id"],
				})
			if tile.get("admin_node", false) and tile.get("scanline", false):
				alerts.append({
					"position": position,
					"kind": "anchor",
					"label": "Restore Point",
					"severity": 0.35,
				})
	return alerts

func _poi_alert_severity(quest_id: String, tile: Dictionary) -> float:
	if quest_id == "memory_leak" and not DragonProgression.has_mission_flag(profile, "mission_11_complete"):
		return 0.95
	if quest_id == "asset_recovery" or tile.get("hazard", "") != "":
		return 0.78
	return 0.58

func _is_system_alert_position(position: Vector2i) -> bool:
	for alert in _system_poi_alerts():
		if alert.get("position", Vector2i(-1, -1)) == position:
			return true
	return false

func _refresh_navigation_hud(current: Dictionary) -> void:
	if compass_display == null:
		return
	var player_position: Vector2i = world["player"]["position"]
	var objective: Dictionary = _current_slice_objective()
	var target: Vector2i = custom_waypoint if custom_waypoint.x >= 0 else objective.get("target", Vector2i(-1, -1))
	var thread_intensity := VisualSystemData.threadfall_intensity(current, profile, mission_state)
	compass_display.set_navigation(
		player_position,
		Vector2i(27, 8),
		target,
		VisualSystemData.sector_stability(player_position, Vector2i(27, 8), thread_intensity),
		VisualSystemData.packet_velocity(player_position, target)
	)

func _refresh_ticket_popup(current: Dictionary) -> void:
	if ticket_popup == null:
		return
	var ticket := _current_service_ticket(current)
	if ticket.is_empty():
		ticket_popup.visible = false
		return
	ticket_popup.visible = true
	ticket_title_label.text = "[SYSTEM ALERT] %s | %s" % [ticket["id"], ticket["type_label"]]
	ticket_title_label.add_theme_color_override("font_color", ticket["color"])
	ticket_desc_label.text = "%s\n%s\nReward: %s" % [ticket["name"], ticket["description"], ticket.get("reward", "stability")]
	if last_ticket_id != ticket["id"]:
		last_ticket_id = ticket["id"]
		ticket_popup.modulate.a = 0.55
	var tween := create_tween()
	tween.tween_property(ticket_popup, "modulate:a", 1.0, 0.16)

func _current_service_ticket(current: Dictionary) -> Dictionary:
	var thread_intensity := VisualSystemData.threadfall_intensity(current, profile, mission_state)
	if thread_intensity >= 0.65:
		return ServiceTicketData.ticket_for_threadfall(current, thread_intensity)
	for quest_id in current.get("sidequests", []):
		var quest := SideQuestData.get_sidequest(str(quest_id))
		if quest.is_empty() or DragonProgression.has_key_item(profile, quest["reward_item"]):
			continue
		return ServiceTicketData.ticket_for_sidequest(str(quest_id), quest, current, _poi_alert_severity(str(quest_id), current))
	if current.get("mission", "") != "":
		var objective := _current_slice_objective()
		if objective.get("target", Vector2i(-1, -1)) == world["player"]["position"]:
			return ServiceTicketData.ticket_for_root_objective(objective["title"], objective["detail"], _tile_label(current))
	return {}

func _map_label_overrides() -> Dictionary:
	if DragonProgression.has_key_item(profile, "read_only_free_roam"):
		return RestorationData.revealed_map_labels(_ending_choice())
	if not DragonProgression.has_mission_flag(profile, "control_plaza_rerendered"):
		return {}
	var labels := {
		"overgrown_buffer": "Control Plaza",
		"vault_first_rack": "Root Access Rack",
	}
	if DragonProgression.has_mission_flag(profile, "mission_10_complete"):
		labels["deepwood_fragment"] = "Rejoined Deepwood"
	if DragonProgression.has_mission_flag(profile, "mission_11_complete"):
		labels["new_landing"] = "Whitelisted Landing"
	return labels

func _cleared_arena_ids() -> Dictionary:
	var cleared := {}
	for flag in profile.get("mission_flags", []):
		var flag_text := str(flag)
		if flag_text.begins_with("arena_cleared_"):
			cleared[flag_text.trim_prefix("arena_cleared_")] = true
	return cleared

func _rebuild_objective_panel() -> void:
	if objective_box == null:
		return
	for child in objective_box.get_children():
		child.queue_free()

	var objective := _current_slice_objective()
	var header := Label.new()
	header.add_theme_font_size_override("font_size", 17)
	header.text = "Current Objective"
	objective_box.add_child(header)

	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = "%s\n%s" % [objective["title"], objective["detail"]]
	objective_box.add_child(body)

func _current_slice_objective() -> Dictionary:
	if custom_waypoint.x >= 0:
		var waypoint_tile := WorldData.get_tile_at(world, custom_waypoint)
		if not waypoint_tile.is_empty():
			return {
				"title": "Waypoint: %s" % _tile_label(waypoint_tile),
				"detail": "Diagnostic map alert selected. Move tile by tile toward the pulsing marker.",
				"target": custom_waypoint,
			}
	if not DragonProgression.has_mission_flag(profile, "first_flight_complete"):
		return {
			"title": "Begin the First Flight.",
			"detail": "At New Landing, synchronize with the Root Dragon and survive the first Threadfall.",
			"target": Vector2i(9, 10),
		}
	if not DragonProgression.has_mission_flag(profile, "search_index_daemon_defeated"):
		return {
			"title": "Reboot the Search & Index Daemon.",
			"detail": "The Mirror Admin has noticed the beacon. Defeat its first scanning daemon at New Landing before leaving for the Cooling Intake.",
			"target": Vector2i(9, 10),
		}
	if not DragonProgression.has_key_item(profile, "cooling_intake_relay"):
		return {
			"title": "Repair Felix's Cooling Intake.",
			"detail": "Enter the side-scrolling hardware layer at Felix Workshop and tighten the pressure valves with the 10mm Wrench.",
			"target": Vector2i(13, 10),
		}
	if not DragonProgression.has_mission_flag(profile, "kernel_recovery_complete"):
		return {
			"title": "Recover the Weaver.",
			"detail": "Reach the Overgrown Buffer, rescue the Weaver from a zero-clock rendering loop, and absorb the Heat Core.",
			"target": Vector2i(21, 9),
		}
	if not DragonProgression.has_key_item(profile, "friction_saddle"):
		return {
			"title": "Craft the Friction Saddle.",
			"detail": "Return to Felix Workshop so the Weaver can tailor Silken Data into dive traction gear.",
			"target": Vector2i(13, 10),
		}
	if not DragonProgression.has_mission_flag(profile, "bounty_hunters_evaded"):
		return {
			"title": "Evade the Sub-routine Stalkers.",
			"detail": "At the Southern Partition Gate, run the Bounty Hunter chase and strike during their latency windows.",
			"target": Vector2i(19, 7),
		}
	if not DragonProgression.has_key_item(profile, "firewall_bypass"):
		return {
			"title": "Breach the Southern Partition Gate.",
			"detail": "Outrun the Stalkers, enter the Airlock, and pull the Primary Breaker with the 10mm Wrench.",
			"target": Vector2i(19, 7),
		}
	if not DragonProgression.has_mission_flag(profile, "act_one_complete"):
		return {
			"title": "Enter the Tundra of Silicon.",
			"detail": "The firewall is down. Cross into the white zero-fill sector beneath the Mainframe Spine.",
			"target": Vector2i(20, 6),
		}
	if not DragonProgression.has_mission_flag(profile, "white_out_purge_survived"):
		return {
			"title": "Survive the White-Out Purge.",
			"detail": "Use the Physical Relay in the Tundra as analog cover when the Admin clears the cache.",
			"target": Vector2i(22, 5),
		}
	if not DragonProgression.has_mission_flag(profile, "unit_01_met"):
		return {
			"title": "Meet Unit 01.",
			"detail": "Return to the Tundra floor and establish a save/shop link with the repair robot.",
			"target": Vector2i(20, 6),
		}
	if not DragonProgression.has_mission_flag(profile, "mirror_admin_tundra_repelled"):
		return {
			"title": "Repel the Mirror Admin projection.",
			"detail": "The Admin manifests in the whiteout to quarantine Unit 01. Break its parity scan before entering the Great Buffer.",
			"target": Vector2i(20, 6),
		}
	if not DragonProgression.has_key_item(profile, "optical_lens"):
		return {
			"title": "Retrieve the Optical Lens.",
			"detail": "Enter the Great Buffer Vault and release the lens from its purge-timed cradle.",
			"target": Vector2i(22, 6),
		}
	if not DragonProgression.has_key_item(profile, "frequency_tuner"):
		return {
			"title": "Install the Frequency Tuner.",
			"detail": "Bring the Optical Lens and recovered memory logs back to Unit 01.",
			"target": Vector2i(20, 6),
		}
	if not DragonProgression.has_key_item(profile, "prism_stalk_form"):
		return {
			"title": "Mutate Prism-Stalk.",
			"detail": "Expose the dragon to stable Tundra data-light and refract the White-Out Purge.",
			"target": Vector2i(20, 6),
		}
	if not DragonProgression.has_key_item(profile, "insulated_grip"):
		return {
			"title": "Install the Insulated Grip.",
			"detail": "Ask Unit 01 to sleeve the 10mm Wrench so it can turn live data-bolts.",
			"target": Vector2i(20, 6),
		}
	if not DragonProgression.has_mission_flag(profile, "mainframe_spine_ascent_started"):
		return {
			"title": "Begin the Mainframe Spine ascent.",
			"detail": "Use Prism-Stalk and Magma-Core heat to catch the first Thermal Chimneys.",
			"target": Vector2i(24, 4),
		}
	if not DragonProgression.has_key_item(profile, "external_vents_unlocked"):
		return {
			"title": "Unlock the Logic Core vents.",
			"detail": "Enter the side-scrolling Logic Core and turn the live terminal with the Insulated Grip.",
			"target": Vector2i(24, 4),
		}
	if not DragonProgression.has_key_item(profile, "floppy_disk_backup"):
		return {
			"title": "Bypass the Root Sentinel.",
			"detail": "Climb to the Legacy Peak, melt the closing bracket, and recover the Original Seed Backup.",
			"target": Vector2i(25, 3),
		}
	if not DragonProgression.has_key_item(profile, "read_only_free_roam"):
		return {
			"title": "Choose the Restoration.",
			"detail": "At the Mainframe Crown, decide whether to restore, patch, or override the Original Seed.",
			"target": Vector2i(26, 2),
		}
	if DragonProgression.has_key_item(profile, "read_only_free_roam"):
		var ending := _current_ending_presentation()
		return {
			"title": "%s complete." % ending.get("title", "Restoration"),
			"detail": ending.get("free_roam_objective", "Explore the revealed map in Read-Only Free-Roam."),
			"target": Vector2i(-1, -1),
		}
	if not DragonProgression.has_mission_flag(profile, "arena_cleared_checksum_ring"):
		return {
			"title": "Find and clear the Checksum Ring.",
			"detail": "Head northwest from the Testing Fields to win Cinder Comet and prove arena battles matter.",
			"target": Vector2i(15, 8),
		}
	if not DragonProgression.has_mission_flag(profile, "visited_felix_lab"):
		return {
			"title": "Report to Felix Basement Lab.",
			"detail": "Felix can turn arena rewards into a working dragon loadout.",
			"target": Vector2i(13, 10),
		}
	if not DragonProgression.has_mission_flag(profile, "entered_southern_partition"):
		return {
			"title": "Enter the Southern Partition.",
			"detail": "Follow the old access road east into Packet Loss Fog and the Hardware Husk approach.",
			"target": Vector2i(21, 9),
		}
	if not DragonProgression.has_mission_flag(profile, "mission_09_complete"):
		return {
			"title": "Complete the First Handshake.",
			"detail": "Inside the Vault of the First Rack, answer B.I.O.S. with the five-note dragon sequence.",
			"target": Vector2i(27, 8),
		}
	if not DragonProgression.has_mission_flag(profile, "stable_connection"):
		return {
			"title": "Defend the boot-up.",
			"detail": "Return to the Vault and defeat the Scrap-Wraith now that Root Access is online.",
			"target": Vector2i(27, 8),
		}
	if not DragonProgression.has_mission_flag(profile, "mission_10_complete"):
		return {
			"title": "Defragment the Deepwood.",
			"detail": "Use Root Access to tether floating forest sectors back to their memory addresses.",
			"target": Vector2i(18, 3),
		}
	if not DragonProgression.has_mission_flag(profile, "mission_11_complete"):
		return {
			"title": "Stop the Garbage Collector's Cull.",
			"detail": "Return to New Landing and ping anchor points before the deletion wall reaches town.",
			"target": Vector2i(9, 10),
		}
	if not DragonProgression.has_mission_flag(profile, "mission_12_complete"):
		return {
			"title": "Breach the Kernel Core.",
			"detail": "Reach the Root Directory and update system permissions to protect the repaired world.",
			"target": Vector2i(31, 6),
		}
	return {
		"title": "System Administrator online.",
		"detail": "God-Mode Fly is unlocked. Use save-point teleportation to revisit arenas, missions, and repaired sectors.",
		"target": Vector2i(-1, -1),
	}

func _complete_first_flight() -> void:
	profile = ActOneProgressionData.complete_first_flight(profile)
	status_message = "First Flight complete. The Root Dragon answers Skye's ping, and Felix hands over the 10mm Wrench."
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _start_search_index_daemon() -> void:
	status_message = "Search & Index Daemon locking onto the Root Dragon..."
	encounter_requested.emit("search_index_daemon", {
		"location_id": "new_landing",
		"location_label": "New Landing Beacon",
		"arena_rule": "",
		"is_story_gate": true,
	})

func _start_mirror_admin_projection() -> void:
	status_message = "Mirror Admin projection entering the Tundra whiteout..."
	encounter_requested.emit("mirror_admin_projection", {
		"location_id": "tundra_of_silicon",
		"location_label": "Tundra of Silicon",
		"arena_rule": "",
		"is_story_gate": true,
	})

func _complete_kernel_recovery() -> void:
	profile = ActOneProgressionData.complete_kernel_recovery(profile)
	status_message = "Kernel Recovery complete. The Weaver snaps back into time, and the Root Dragon bakes into Magma-Core form."
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _survive_white_out_purge() -> void:
	profile = ActTwoProgressionData.shelter_from_white_out(profile, true)
	status_message = "White-Out Purge survived. The Physical Relay proves analog cover still matters in the zero-fill sector."
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _meet_unit_01() -> void:
	profile = ActTwoProgressionData.meet_unit_01(profile)
	status_message = "Unit 01 link established. The Kernel recognizes the wrench as a Primary Tool."
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _install_frequency_tuner() -> void:
	profile = ActTwoProgressionData.install_frequency_tuner(profile)
	status_message = "Frequency Tuner installed. The Diagnostic Lens can hear the Mainframe heartbeat."
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _mutate_prism_stalk() -> void:
	profile = ActTwoProgressionData.mutate_prism_stalk(profile)
	status_message = "Prism-Stalk mutation complete. The dragon can refract purge light instead of merely surviving it."
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _install_insulated_grip() -> void:
	profile = ActTwoProgressionData.install_insulated_grip(profile)
	status_message = "Insulated Grip installed. The 10mm Wrench can now turn live data-bolts."
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _begin_spine_ascent() -> void:
	profile = ActTwoProgressionData.begin_spine_ascent(profile)
	status_message = "Mainframe Spine ascent started. The first Thermal Chimney catches Magma-Core heat under Prism-Stalk guidance."
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _complete_bounty_hunter_chase() -> void:
	profile = ActOneProgressionData.complete_bounty_hunter_chase(profile)
	status_message = "Bounty Hunter chase cleared. The Stalkers stabilize for one heartbeat too long, and Skye reads their latency."
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _bypass_root_sentinel() -> void:
	profile = ActTwoProgressionData.bypass_root_sentinel(profile)
	status_message = "Root Sentinel bypassed. The closing bracket melts, revealing the Floppy Disk Backup."
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _add_restoration_choice_buttons() -> void:
	var header := Label.new()
	header.add_theme_font_size_override("font_size", 16)
	header.text = "Restoration Choice"
	action_box.add_child(header)
	for choice in [
		{ "id": "total_restore", "label": "Total Restore" },
		{ "id": "patch", "label": "The Patch" },
		{ "id": "hardware_override", "label": "Hardware Override" },
	]:
		var button := Button.new()
		button.text = choice["label"]
		button.pressed.connect(_complete_restoration_choice.bind(choice["id"]))
		action_box.add_child(button)

func _complete_restoration_choice(choice: String) -> void:
	profile = ActTwoProgressionData.complete_restoration_choice(profile, choice)
	var ending := _current_ending_presentation()
	status_message = "%s complete. %s" % [ending.get("title", "Restoration"), ending.get("felix_line", "Read-Only Free-Roam unlocked.")]
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _current_ending_presentation() -> Dictionary:
	if profile.has("ending_presentation") and profile["ending_presentation"] is Dictionary:
		return profile["ending_presentation"]
	return RestorationData.ending_presentation(_ending_choice())

func _ending_choice() -> String:
	var ending_state: Dictionary = profile.get("ending_state", {})
	if not ending_state.is_empty():
		return str(ending_state.get("choice", RestorationData.CHOICE_PATCH))
	for flag in profile.get("mission_flags", []):
		var flag_text := str(flag)
		if flag_text.begins_with("restoration_choice_"):
			return flag_text.trim_prefix("restoration_choice_")
	return RestorationData.CHOICE_PATCH

func _add_ending_state_panel() -> void:
	var ending := _current_ending_presentation()
	var header := Label.new()
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", ending.get("accent_color", Color("#ffd56b")))
	header.text = "Ending: %s" % ending.get("title", "Restoration")
	action_box.add_child(header)

	var summary := Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.text = "%s\n%s\n%s" % [
		ending.get("summary", "The world has entered a stable postgame state."),
		ending.get("map_legend", "The revealed map is available for free-roam cleanup."),
		ending.get("felix_line", ""),
	]
	action_box.add_child(summary)

	var credits := Label.new()
	credits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var lines: Array = ending.get("credits_lines", [])
	credits.text = "Credits Run\n%s" % "\n".join(lines)
	action_box.add_child(credits)

	var display := CreditsRunDisplay.new()
	display.set_ending(profile.get("credits_run", RestorationData.credits_run_state(_ending_choice(), 1.0)), ending)
	action_box.add_child(display)

	var review := Button.new()
	review.text = "Review Credits Run"
	review.tooltip_text = "Replay the zero-G Root Authority descent in the ending panel."
	review.pressed.connect(func() -> void:
		status_message = "Zero-G Credits Run replaying through the Mainframe Spine."
		status_label.text = status_message
		display.start_run(_ending_choice(), ending)
	)
	action_box.add_child(review)

func _tile_label(tile: Dictionary) -> String:
	if DragonProgression.has_mission_flag(profile, "control_plaza_rerendered"):
		if tile["id"] == "overgrown_buffer":
			return "Control Plaza"
		if tile["id"] == "vault_first_rack":
			return "Root Access Rack"
		if tile["id"] == "deepwood_fragment" and DragonProgression.has_mission_flag(profile, "mission_10_complete"):
			return "Rejoined Deepwood"
		if tile["id"] == "new_landing" and DragonProgression.has_mission_flag(profile, "mission_11_complete"):
			return "Whitelisted Landing"
	return tile["label"]

func _tile_description(tile: Dictionary) -> String:
	if DragonProgression.has_mission_flag(profile, "control_plaza_rerendered"):
		if tile["id"] == "overgrown_buffer":
			return "The unoptimized jungle has de-rezzed into a clean plaza of luminous access paths and calibrated server light."
		if tile["id"] == "vault_first_rack":
			return "The First Rack answers in stable luma-tones. Skye is no longer a visitor; the system recognizes an administrator."
		if tile["id"] == "deepwood_fragment" and DragonProgression.has_mission_flag(profile, "mission_10_complete"):
			return "The forest sector has snapped back into a seamless memory path. Hidden sub-directories are now reachable through living green routes."
		if tile["id"] == "new_landing" and DragonProgression.has_mission_flag(profile, "mission_11_complete"):
			return "New Landing is whitelisted. The Garbage Collector now reads the town as active, loved, and in use."
	return tile["description"]

func _encounter_text() -> String:
	if not pending_wild_encounter.is_empty():
		var diagnostic := ""
		if DragonProgression.has_key_item(profile, "diagnostic_lens"):
			var enemy := TacticalBattle.get_enemy(pending_wild_encounter["enemy_id"])
			diagnostic = "\nDiagnostic Lens: LV %d | HP %d | Code Integrity %d percent" % [
				enemy.get("level", 1),
				enemy["stats"]["hp"],
				enemy.get("code_integrity", 100),
			]
		return "Wild process locked: %s. Confirm to enter battle.%s" % [pending_wild_encounter.get("title", "Wild Encounter"), diagnostic]
	var encounter = WorldData.get_world_encounter(world)
	if encounter == null:
		return "No hostile process detected."
	if WorldData.get_current_tile(world).get("mission", "") == "mission_09" and not DragonProgression.has_mission_flag(profile, "mission_09_complete"):
		return "Combat UI suspended. The rack is waiting for a luma-tone response code."
	var prefix := "Arena open" if WorldData.get_current_tile(world).get("arena", false) else "%s detected" % encounter["title"]
	var diagnostic := ""
	if DragonProgression.has_key_item(profile, "diagnostic_lens"):
		var enemy := TacticalBattle.get_enemy(encounter["enemy_id"])
		diagnostic = "\nDiagnostic Lens: LV %d | HP %d | Code Integrity %d percent" % [
			enemy.get("level", 1),
			enemy["stats"]["hp"],
			enemy.get("code_integrity", 100),
		]
	if WorldData.get_current_tile(world).get("arena", false):
		var tile := WorldData.get_current_tile(world)
		var cleared := DragonProgression.has_mission_flag(profile, "arena_cleared_%s" % tile.get("id", ""))
		var reward_text := "Cleared." if cleared else "First-clear reward: %s." % tile.get("arena_reward", {}).get("label", "DataScraps")
		var rule_text: String = tile.get("arena_rule_label", "")
		return "%s: %s. %s\n%s%s" % [prefix, encounter["title"], reward_text, rule_text, diagnostic]
	return "%s. Confirm to enter battle.%s" % [prefix, diagnostic]

func _hazard_text(current: Dictionary) -> String:
	if not current.has("hazard"):
		return ""
	return "\nHazard: %s\n" % current["hazard"]

func _danger_text(current: Dictionary) -> String:
	var danger_gain := WorldData.get_tile_danger(current)
	if danger_gain <= 0.0 and pending_wild_encounter.is_empty():
		return ""
	var lock_text := " | Threat locked" if not pending_wild_encounter.is_empty() else ""
	return "Danger: %.0f / %.0f%s\n" % [danger_meter, DANGER_THRESHOLD, lock_text]

func _rebuild_bios_panel(current: Dictionary) -> void:
	if bios_box == null:
		return
	for child in bios_box.get_children():
		child.queue_free()

	if current.get("npc", "") != "BIOS":
		return

	var header := Label.new()
	header.text = "B.I.O.S."
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color("#55ff55"))
	bios_box.add_child(header)

	for line in StoryData.bios_lines(current["id"]):
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", Color("#55ffff"))
		bios_box.add_child(label)

func _rebuild_nav_panel(current: Dictionary) -> void:
	if nav_box == null:
		return
	for child in nav_box.get_children():
		child.queue_free()

	var header := Label.new()
	header.add_theme_font_size_override("font_size", 17)
	header.text = "Navigation"
	nav_box.add_child(header)

	var controls := GridContainer.new()
	controls.columns = 3
	controls.add_theme_constant_override("h_separation", 6)
	controls.add_theme_constant_override("v_separation", 6)
	nav_box.add_child(controls)

	_add_nav_spacer(controls)
	_add_nav_button(controls, "North", "north")
	_add_nav_spacer(controls)
	_add_nav_button(controls, "West", "west")
	var here := Button.new()
	here.text = "Here"
	here.disabled = true
	controls.add_child(here)
	_add_nav_button(controls, "East", "east")
	_add_nav_spacer(controls)
	_add_nav_button(controls, "South", "south")
	_add_nav_spacer(controls)

	var note := Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "Current sector: %s" % _tile_label(current)
	nav_box.add_child(note)

func _add_nav_button(parent: Control, label: String, direction: String) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(_move.bind(direction))
	parent.add_child(button)

func _add_nav_spacer(parent: Control) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(64, 32)
	parent.add_child(spacer)

func _rebuild_action_panel(current: Dictionary) -> void:
	if action_box == null:
		return
	for child in action_box.get_children():
		child.queue_free()

	var header := Label.new()
	header.add_theme_font_size_override("font_size", 17)
	header.text = "Actions"
	action_box.add_child(header)

	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 6)
	action_box.add_child(save_row)

	var save_button := Button.new()
	save_button.text = "Save"
	save_button.pressed.connect(func() -> void:
		save_requested.emit()
	)
	save_row.add_child(save_button)

	var load_button := Button.new()
	load_button.text = "Load"
	load_button.pressed.connect(func() -> void:
		load_requested.emit()
	)
	save_row.add_child(load_button)

	for line in _lore_panel_lines(current):
		var lore_label := Label.new()
		lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lore_label.add_theme_font_size_override("font_size", 13)
		lore_label.text = line
		action_box.add_child(lore_label)

	if DragonProgression.has_key_item(profile, "root_access"):
		var admin_button := Button.new()
		admin_button.text = "Hide Admin Overlay" if admin_overlay_visible else "Show Admin Overlay"
		admin_button.pressed.connect(func() -> void:
			_toggle_diagnostic_map()
		)
		action_box.add_child(admin_button)

		var integrity := Label.new()
		integrity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		integrity.text = "Sector Integrity: %.0f percent" % (_sector_integrity() * 100.0)
		action_box.add_child(integrity)

	if DragonProgression.has_key_item(profile, "god_mode_fly"):
		_add_god_mode_fly_controls()

	if DragonProgression.has_key_item(profile, "read_only_free_roam"):
		_add_ending_state_panel()

	if current.get("id", "") == "new_landing" and not DragonProgression.has_mission_flag(profile, "first_flight_complete"):
		var first_flight := Button.new()
		first_flight.text = "Begin First Flight"
		first_flight.tooltip_text = "Bond with the Root Dragon, survive the first Threadfall, and receive Felix's 10mm Wrench."
		first_flight.pressed.connect(_complete_first_flight)
		action_box.add_child(first_flight)

	if current.get("hatchery_flow", false):
		var hatchery := Button.new()
		hatchery.text = "Open Hatchery Ring"
		hatchery.tooltip_text = "Enter the quantum incubation flow at the Digital Forge without leaving the overworld shell."
		hatchery.pressed.connect(_open_hatchery_ring.bind(current))
		action_box.add_child(hatchery)

	if current.get("id", "") == "new_landing" and DragonProgression.has_mission_flag(profile, "first_flight_complete") and not DragonProgression.has_mission_flag(profile, "search_index_daemon_defeated"):
		var daemon := Button.new()
		daemon.text = "Fight Search & Index Daemon"
		daemon.tooltip_text = "The Mirror Admin's first scanning process is trying to catalog the Root Dragon."
		daemon.pressed.connect(_start_search_index_daemon)
		action_box.add_child(daemon)

	if current.get("id", "") == "overgrown_buffer" and DragonProgression.has_key_item(profile, "cooling_intake_relay") and not DragonProgression.has_mission_flag(profile, "kernel_recovery_complete"):
		var kernel_recovery := Button.new()
		kernel_recovery.text = "Rescue Weaver / Absorb Heat Core"
		kernel_recovery.tooltip_text = "Bridge the Weaver's zero-clock rendering loop and trigger the Magma-Core compile."
		kernel_recovery.pressed.connect(_complete_kernel_recovery)
		action_box.add_child(kernel_recovery)

	if current.get("id", "") == "physical_relay" and DragonProgression.has_mission_flag(profile, "act_two_started") and not DragonProgression.has_mission_flag(profile, "white_out_purge_survived"):
		var purge := Button.new()
		purge.text = "Shelter from White-Out Purge"
		purge.tooltip_text = "Use analog shipframe cover while the Admin clears the Tundra cache."
		purge.pressed.connect(_survive_white_out_purge)
		action_box.add_child(purge)

	if current.get("id", "") == "tundra_of_silicon" and DragonProgression.has_mission_flag(profile, "white_out_purge_survived") and not DragonProgression.has_mission_flag(profile, "unit_01_met"):
		var unit := Button.new()
		unit.text = "Establish Unit 01 Link"
		unit.tooltip_text = "Meet The Kernel and activate its mobile shop/save link."
		unit.pressed.connect(_meet_unit_01)
		action_box.add_child(unit)

	if current.get("id", "") == "tundra_of_silicon" and DragonProgression.has_mission_flag(profile, "unit_01_met") and not DragonProgression.has_mission_flag(profile, "mirror_admin_tundra_repelled"):
		var mirror := Button.new()
		mirror.text = "Fight Mirror Admin Projection"
		mirror.tooltip_text = "Repel the Admin's parity scan before entering the Great Buffer Vault."
		mirror.pressed.connect(_start_mirror_admin_projection)
		action_box.add_child(mirror)

	if current.get("id", "") == "tundra_of_silicon" and DragonProgression.has_key_item(profile, "optical_lens") and not DragonProgression.has_key_item(profile, "frequency_tuner"):
		var tuner := Button.new()
		tuner.text = "Install Frequency Tuner"
		tuner.tooltip_text = "Let Unit 01 tune the Diagnostic Lens to the Mainframe heartbeat."
		tuner.pressed.connect(_install_frequency_tuner)
		action_box.add_child(tuner)

	if current.get("id", "") == "tundra_of_silicon" and DragonProgression.has_key_item(profile, "frequency_tuner") and not DragonProgression.has_key_item(profile, "prism_stalk_form"):
		var prism := Button.new()
		prism.text = "Mutate Prism-Stalk"
		prism.tooltip_text = "Refract Tundra data-light through the Optical Lens to compile the diagnostic dragon form."
		prism.pressed.connect(_mutate_prism_stalk)
		action_box.add_child(prism)

	if current.get("id", "") == "tundra_of_silicon" and DragonProgression.has_key_item(profile, "prism_stalk_form") and not DragonProgression.has_key_item(profile, "insulated_grip"):
		var grip := Button.new()
		grip.text = "Install Insulated Grip"
		grip.tooltip_text = "Unit 01 sleeves the 10mm Wrench for live data-bolts."
		grip.pressed.connect(_install_insulated_grip)
		action_box.add_child(grip)

	if current.get("id", "") == "southern_partition_gate" and DragonProgression.has_key_item(profile, "friction_saddle") and not DragonProgression.has_mission_flag(profile, "bounty_hunters_evaded"):
		var chase := Button.new()
		chase.text = "Run Bounty Hunter Chase"
		chase.tooltip_text = "Use the Friction Saddle to hold a dive line, then hit three Stalkers during latency stabilization."
		chase.pressed.connect(_complete_bounty_hunter_chase)
		action_box.add_child(chase)

	if current.get("id", "") == "mainframe_spine_base" and DragonProgression.has_key_item(profile, "insulated_grip") and not DragonProgression.has_mission_flag(profile, "mainframe_spine_ascent_started"):
		var ascent := Button.new()
		ascent.text = "Catch First Thermal Chimney"
		ascent.tooltip_text = "Start the vertical ascent and learn heat venting against the Admin's gravity well."
		ascent.pressed.connect(_begin_spine_ascent)
		action_box.add_child(ascent)

	if current.get("id", "") == "legacy_peak" and DragonProgression.has_key_item(profile, "external_vents_unlocked") and not DragonProgression.has_key_item(profile, "floppy_disk_backup"):
		var sentinel := Button.new()
		sentinel.text = "Bypass Root Sentinel"
		sentinel.tooltip_text = "Melt the closing bracket and retrieve the Original Seed Backup."
		sentinel.pressed.connect(_bypass_root_sentinel)
		action_box.add_child(sentinel)

	if current.get("id", "") == "mainframe_crown" and DragonProgression.has_key_item(profile, "floppy_disk_backup") and not DragonProgression.has_key_item(profile, "read_only_free_roam"):
		_add_restoration_choice_buttons()

	if current.get("dungeon_id", "") != "":
		var dungeon := HardwareDungeonData.get_dungeon(str(current["dungeon_id"]))
		var entry := HardwareDungeonData.can_enter_dungeon(str(current["dungeon_id"]), profile)
		var readiness := _dungeon_entry_readiness(current)
		_add_dungeon_entry_loadout_card(current)
		var dungeon_button := Button.new()
		dungeon_button.text = "Enter %s [%s]" % [dungeon.get("name", "Hardware Dungeon"), readiness.get("status_label", "READY")]
		dungeon_button.tooltip_text = "%s\n%s" % [readiness.get("readiness_label", "Hardware kit"), readiness.get("recommendation", "")]
		if not entry.get("allowed", true):
			dungeon_button.disabled = true
			dungeon_button.tooltip_text = str(entry.get("reason", "Dungeon locked."))
		elif not bool(readiness.get("ready", true)):
			dungeon_button.disabled = true
			dungeon_button.tooltip_text = str(readiness.get("warning", "Socket required tools at Felix's Anvil."))
		elif current.get("id", "") == "southern_partition_gate" and not DragonProgression.has_mission_flag(profile, "bounty_hunters_evaded"):
			dungeon_button.disabled = true
			dungeon_button.tooltip_text = "The Sub-routine Stalkers are still on your tail. Clear the chase before dismounting at the access port."
		dungeon_button.pressed.connect(func() -> void:
			_request_dungeon(current)
		)
		action_box.add_child(dungeon_button)

	if not pending_wild_encounter.is_empty():
		var wild_button := Button.new()
		wild_button.text = "Engage %s" % pending_wild_encounter.get("title", "Wild Encounter")
		wild_button.pressed.connect(func() -> void:
			_start_pending_wild_encounter(current)
		)
		action_box.add_child(wild_button)

	var encounter = WorldData.get_world_encounter(world)
	if encounter != null:
		var button := Button.new()
		button.text = "Enter %s" % encounter["title"] if current.get("arena", false) else "Start %s" % encounter["title"]
		button.disabled = current.get("mission", "") == "mission_09" and not DragonProgression.has_mission_flag(profile, "mission_09_complete")
		button.pressed.connect(func() -> void:
			status_message = "Entering %s..." % encounter["title"] if current.get("arena", false) else "Starting %s..." % encounter["title"]
			encounter_requested.emit(encounter["enemy_id"], _encounter_context(current, encounter))
		)
		action_box.add_child(button)

	if current.get("mission", "") != "":
		var mission_hint := Label.new()
		mission_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mission_hint.text = "Mission controls are below."
		action_box.add_child(mission_hint)

	_add_npc_and_sidequest_controls(current)

func _lore_panel_lines(current: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if current.has("lore_signal"):
		lines.append("[SYS] %s" % str(current["lore_signal"]))
	if current.has("skye_objective"):
		lines.append("[SKYE] %s" % str(current["skye_objective"]))
	return lines

func _request_dungeon(current: Dictionary) -> void:
	var dungeon_id := str(current.get("dungeon_id", ""))
	if dungeon_id == "":
		return
	var dungeon := HardwareDungeonData.get_dungeon(dungeon_id)
	var entry := HardwareDungeonData.can_enter_dungeon(dungeon_id, profile)
	if not entry.get("allowed", true):
		status_message = str(entry.get("reason", "Dungeon locked."))
		_refresh()
		return
	var belt := DragonProgression.get_anvil_utility_belt_profile(profile)
	var readiness := HardwareDungeonData.get_dungeon_loadout_profile(dungeon_id, belt)
	if not bool(readiness.get("ready", true)):
		status_message = str(readiness.get("warning", "Socket required tools at Felix's Anvil."))
		_refresh()
		return
	status_message = "Entering %s through the hardware layer. Belt: %s." % [dungeon.get("name", "Hardware Dungeon"), belt.get("entry_label", "0/0 ANALOG RELICS")]
	dungeon_requested.emit(dungeon_id, _dungeon_entry_context(current))

func _dungeon_entry_readiness(current: Dictionary) -> Dictionary:
	return HardwareDungeonData.get_dungeon_loadout_profile(str(current.get("dungeon_id", "")), DragonProgression.get_anvil_utility_belt_profile(profile))

func _dungeon_entry_card_profile(current: Dictionary) -> Dictionary:
	var readiness := _dungeon_entry_readiness(current)
	return {
		"visible": str(current.get("dungeon_id", "")) != "",
		"presentation": "overworld_dungeon_loadout_card",
		"title": readiness.get("readiness_label", "HARDWARE KIT"),
		"status_label": readiness.get("status_label", "READY"),
		"ready": readiness.get("ready", true),
		"required_label": "Required: %s" % _tool_ids_to_labels(readiness.get("required_tools", [])),
		"recommended_label": "Recommended: %s" % _tool_ids_to_labels(readiness.get("recommended_tools", [])),
		"carried_label": "Carried: %s" % _tool_ids_to_labels(readiness.get("carried_tools", [])),
		"missing_label": "Missing: %s" % _tool_ids_to_labels(readiness.get("missing_required", [])) if not readiness.get("missing_required", []).is_empty() else "Missing: none",
		"warning": readiness.get("warning", ""),
		"frame_color": Color("#70ff8f") if bool(readiness.get("ready", true)) else Color("#ff594d"),
	}

func _tool_ids_to_labels(tool_ids: Array) -> String:
	var labels: Array[String] = []
	for tool_id in tool_ids:
		var label := _tool_id_to_label(str(tool_id))
		if label != "" and not labels.has(label):
			labels.append(label)
	return ", ".join(labels) if not labels.is_empty() else "none"

func _tool_id_to_label(tool_id: String) -> String:
	match tool_id:
		"10mm_wrench":
			return "10mm Wrench"
		"optical_lens":
			return "Optical Lens"
		"friction_saddle":
			return "Friction Harness"
		"silicon_padded_gear":
			return "Silicon Gear"
		"obsidian_shell":
			return "Obsidian Shell"
		"thermal_torch":
			return "Thermal Torch"
		_:
			return tool_id.capitalize()

func _dungeon_entry_context(current: Dictionary) -> Dictionary:
	var belt := DragonProgression.get_anvil_utility_belt_profile(profile)
	return {
		"tile_id": current.get("id", ""),
		"tile_label": _tile_label(current),
		"utility_belt": belt,
		"loadout_check": HardwareDungeonData.get_dungeon_loadout_profile(str(current.get("dungeon_id", "")), belt),
	}

func _add_dungeon_entry_loadout_card(current: Dictionary) -> void:
	var card_profile := _dungeon_entry_card_profile(current)
	if not bool(card_profile.get("visible", false)):
		return
	var card := PanelContainer.new()
	card.self_modulate = card_profile.get("frame_color", Color("#70ff8f"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var header := Label.new()
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", card_profile.get("frame_color", Color("#70ff8f")))
	header.text = "%s / %s" % [card_profile.get("title", "HARDWARE KIT"), card_profile.get("status_label", "READY")]
	box.add_child(header)
	for key in ["required_label", "recommended_label", "carried_label", "missing_label"]:
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.text = str(card_profile.get(key, ""))
		box.add_child(line)
	var warning := str(card_profile.get("warning", ""))
	if warning != "":
		var warning_line := Label.new()
		warning_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warning_line.add_theme_color_override("font_color", Color("#ffb3ad"))
		warning_line.text = warning
		box.add_child(warning_line)
	action_box.add_child(card)

func _open_hatchery_ring(current: Dictionary = {}) -> void:
	var ring_id := str(current.get("hatchery_id", "quantum_incubation_ring"))
	profile = DragonProgression.open_hatchery_ring(profile, ring_id)
	var state := DragonProgression.get_hatchery_state(profile)
	status_message = "Hatchery Ring online: %d registered dragon protocol%s, %d visit%s logged." % [
		state.get("owned_dragons", []).size(),
		"" if state.get("owned_dragons", []).size() == 1 else "s",
		int(state.get("visit_count", 0)),
		"" if int(state.get("visit_count", 0)) == 1 else "s",
	]
	profile_changed.emit(profile.duplicate(true))
	if is_inside_tree():
		_refresh()

func _add_god_mode_fly_controls() -> void:
	var header := Label.new()
	header.add_theme_font_size_override("font_size", 16)
	header.text = "God-Mode Fly"
	action_box.add_child(header)

	var row := GridContainer.new()
	row.columns = 2
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	action_box.add_child(row)

	for destination in [
		{ "label": "Felix Lab", "position": Vector2i(13, 10) },
		{ "label": "Root Rack", "position": Vector2i(27, 8) },
		{ "label": "Deepwood", "position": Vector2i(18, 3) },
		{ "label": "Kernel Core", "position": Vector2i(31, 6) },
	]:
		var button := Button.new()
		button.text = destination["label"]
		button.pressed.connect(func() -> void:
			world = WorldData.move_player_to(world, destination["position"])
			status_message = "God-Mode Fly routed Skye to %s." % destination["label"]
			_refresh()
		)
		row.add_child(button)

func _add_npc_and_sidequest_controls(current: Dictionary) -> void:
	var npc_ids: Array = current.get("npcs", [])
	var sidequest_ids: Array = current.get("sidequests", [])
	if npc_ids.is_empty() and sidequest_ids.is_empty():
		return

	var header := Label.new()
	header.add_theme_font_size_override("font_size", 17)
	header.text = "Local Threads"
	action_box.add_child(header)

	for npc_id in npc_ids:
		var npc := SideQuestData.get_npc(str(npc_id))
		if npc.is_empty():
			continue
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var awareness := _npc_awareness(str(npc_id), npc)
		label.text = "%s [%s]\n%s" % [
			npc["name"],
			_npc_awareness_label(awareness, npc),
			_npc_dialogue_for_awareness(npc, awareness),
		]
		action_box.add_child(label)

	for quest in SideQuestData.get_sidequests(sidequest_ids):
		var status := Label.new()
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status.text = "%s\n%s\n%s" % [quest["title"], quest["summary"], _sidequest_status(quest["title"], quest["reward_item"])]
		action_box.add_child(status)
		_add_sidequest_button(quest["reward_item"])

func _add_sidequest_button(reward_item: String) -> void:
	if DragonProgression.has_key_item(profile, reward_item):
		return
	var button := Button.new()
	button.text = _sidequest_button_text(reward_item)
	button.pressed.connect(func() -> void:
		_run_sidequest_step(reward_item)
		_refresh()
	)
	action_box.add_child(button)

func _sidequest_button_text(reward_item: String) -> String:
	match reward_item:
		"integrity_patch":
			return "Lock Flickering Asset"
		"static_shards":
			return "Tune Well Frequency"
		"hydraulic_wing":
			return "Catch Manual Page"
		"prism_texture_pass":
			return "Render Portrait Pass"
		"asset_recovery_cache":
			return "Recover Asset Fragment"
		"seed_code_rare":
			return "Bake Textures"
		"clipping_permission":
			return "Short-Circuit Mesh"
		"silken_data":
			return "Harmonize Loom"
		"partition_permissions":
			return "Update Permissions"
		"wrench_overclock":
			return "Buy Wrench Overclock"
		"purge_shield":
			return "Trade Purge Shield"
		_:
			return "Patch Sidequest"

func _sidequest_status(_title: String, reward_item: String) -> String:
	var state: Dictionary = mission_state["sidequests"]
	if DragonProgression.has_key_item(profile, reward_item):
		return "Status: complete. Reward installed: %s." % reward_item
	match reward_item:
		"integrity_patch":
			var memory: Dictionary = state["memory_leak"]
			return "Memory Meter: %.0fs | Locked assets: %d / 3" % [memory["timer"], memory["locked_assets"].size()]
		"static_shards":
			var well: Dictionary = state["ghost_in_the_well"]
			var result := SideQuestData.check_well_frequency(well["roar"])
			return "Well scream delta: %.1f Hz | %s" % [result["delta"], result["result"]]
		"hydraulic_wing":
			var manual: Dictionary = state["unauthorized_manual"]
			return "Recovered pages: %d / 3" % manual["pages"]
		"prism_texture_pass":
			var portrait: Dictionary = state["rerender_portrait"]
			return "Portrait render passes: %d / 3" % portrait["passes"]
		"asset_recovery_cache":
			var pete: Dictionary = state["asset_recovery"]
			return "Fragments: %d / 3 | UI Glitch: %d percent" % [pete["fragments"], pete["glitch"]]
		"seed_code_rare":
			var harvest: Dictionary = state["wireframe_harvest"]
			return "Texture bakes: %d / 3" % harvest["bakes"]
		"clipping_permission":
			var path: Dictionary = state["stuck_path"]
			return "Collision shorts: %d / 2 | Diagnostic Lens: %s" % [path["shorts"], "online" if DragonProgression.has_key_item(profile, "diagnostic_lens") else "required"]
		"silken_data":
			var lullaby: Dictionary = state["corrupted_lullaby"]
			var loom := SideQuestData.harmonize_lullaby(lullaby["roar"])
			return "Loom delta: %.1f Hz | %s" % [loom["delta"], loom["result"]]
		"partition_permissions":
			return "Root Password: %s" % ("accepted" if DragonProgression.has_key_item(profile, "root_password") else "required")
		"wrench_overclock":
			var deal: Dictionary = ActTwoTundraData.evaluate_black_market_overclock(
				DragonProgression.has_key_item(profile, "unit_01_save_link"),
				int(profile.get("data_scraps", 0))
			)
			return "Pulse Quote: %d scraps | %s" % [deal["cost"], deal["reason"]]
		"purge_shield":
			var shard_trade: Dictionary = ActTwoTundraData.evaluate_shard_purge_shield_trade(
				DragonProgression.has_key_item(profile, "silicon_shards"),
				int(profile.get("data_scraps", 0))
			)
			return "Shard Quote: %d scraps + Silicon Shards | %s" % [shard_trade["cost"], shard_trade["reason"]]
	return "Status: active."

func _run_sidequest_step(reward_item: String) -> void:
	match reward_item:
		"integrity_patch":
			_step_memory_leak()
		"static_shards":
			_step_ghost_well()
		"hydraulic_wing":
			_step_unauthorized_manual()
		"prism_texture_pass":
			_step_texture_seeker()
		"asset_recovery_cache":
			_step_asset_recovery()
		"seed_code_rare":
			_step_wireframe_harvest()
		"clipping_permission":
			_step_stuck_path()
		"silken_data":
			_step_corrupted_lullaby()
		"partition_permissions":
			_step_sentinel_404()
		"wrench_overclock":
			_step_black_market_overclock()
		"purge_shield":
			_step_shard_purge_shield()

func _step_memory_leak() -> void:
	var state: Dictionary = mission_state["sidequests"]["memory_leak"]
	var targets: Array = SideQuestData.get_sidequest("memory_leak")["target_assets"]
	var asset_name: String = str(targets[state["locked_assets"].size() % targets.size()])
	var result := SideQuestData.evaluate_memory_lock(state["locked_assets"], asset_name, state["timer"])
	state["locked_assets"] = result["locked_assets"]
	state["timer"] = result["timer"]
	status_message = "Lunar lock stabilized %s." % asset_name
	if result["success"]:
		profile = DragonProgression.grant_key_item(profile, "integrity_patch")
		profile = DragonProgression.set_mission_flag(profile, "npc_awakened_looping_blacksmith")
		_set_sector_integrity(_sector_integrity() + 0.1)
		status_message = "The Memory Leak is patched. New Landing stops flickering."
		profile_changed.emit(profile.duplicate(true))

func _step_ghost_well() -> void:
	var state: Dictionary = mission_state["sidequests"]["ghost_in_the_well"]
	state["roar"] = 446.0
	var result := SideQuestData.check_well_frequency(state["roar"])
	status_message = "Frequency matched: %s." % result["result"]
	if result["success"]:
		profile = DragonProgression.grant_key_item(profile, "static_shards")
		profile = DragonProgression.award_scraps(profile, 75)
		status_message = "The well scream is muted. Static Shards recovered for armor crafting."
		profile_changed.emit(profile.duplicate(true))

func _step_unauthorized_manual() -> void:
	var state: Dictionary = mission_state["sidequests"]["unauthorized_manual"]
	var result := SideQuestData.collect_manual_page(state["pages"])
	state["pages"] = result["pages"]
	status_message = "Caught a wind-torn manual page across the Salt Flats."
	if result["success"]:
		profile = DragonProgression.grant_key_item(profile, "hydraulic_wing")
		profile = DragonProgression.set_mission_flag(profile, "npc_awakened_elder_cache")
		status_message = "Unauthorized Manual restored. Hydraulic Wing takeoff is unlocked."
		profile_changed.emit(profile.duplicate(true))

func _step_texture_seeker() -> void:
	var state: Dictionary = mission_state["sidequests"]["rerender_portrait"]
	var result := SideQuestData.render_portrait_pass(state["passes"])
	state["passes"] = result["passes"]
	status_message = "Prism Dragon render pass sharpened the portrait."
	if result["success"]:
		profile = DragonProgression.grant_key_item(profile, "prism_texture_pass")
		profile = DragonProgression.set_mission_flag(profile, "npc_awakened_texture_seeker")
		status_message = "The Texture-Seeker's portrait re-rendered into high fidelity."
		profile_changed.emit(profile.duplicate(true))

func _step_asset_recovery() -> void:
	var state: Dictionary = mission_state["sidequests"]["asset_recovery"]
	var result := SideQuestData.recover_asset_fragment(state["fragments"], state["glitch"])
	state["fragments"] = result["fragments"]
	state["glitch"] = result["glitch"]
	status_message = "Recovered a missing asset fragment. The UI shudders around Pete."
	if result["success"] and not result["failed"]:
		profile = DragonProgression.grant_key_item(profile, "asset_recovery_cache")
		profile = DragonProgression.set_mission_flag(profile, "npc_awakened_null_pointer_pete")
		status_message = "Null-Pointer Pete is stable enough to pay out the recovery cache."
		profile_changed.emit(profile.duplicate(true))

func _step_wireframe_harvest() -> void:
	var state: Dictionary = mission_state["sidequests"]["wireframe_harvest"]
	var result := SideQuestData.bake_wireframe_texture(state["bakes"])
	state["bakes"] = result["bakes"]
	status_message = "Magma thermal pass baked %.0f percent of the wheat texture." % (result["texture_integrity"] * 100.0)
	if result["success"]:
		profile = DragonProgression.grant_key_item(profile, "seed_code_rare")
		profile = DragonProgression.set_mission_flag(profile, "npc_awakened_wireframe_farmer")
		status_message = "The Wireframe Harvest is restored. Seed Code can create high-resolution oases."
		profile_changed.emit(profile.duplicate(true))

func _step_stuck_path() -> void:
	var state: Dictionary = mission_state["sidequests"]["stuck_path"]
	var result := SideQuestData.short_collision_mesh(state["shorts"], DragonProgression.has_key_item(profile, "diagnostic_lens"))
	if result["blocked"]:
		status_message = "Diagnostic Lens required: the collision mesh is still invisible."
		return
	state["shorts"] = result["shorts"]
	status_message = "Static Dragon shorted a collision mesh segment."
	if result["success"]:
		profile = DragonProgression.grant_key_item(profile, "clipping_permission")
		profile = DragonProgression.set_mission_flag(profile, "npc_awakened_path_merchant")
		status_message = "The caravan path is unstuck. Skye understands the first rule of clipping."
		profile_changed.emit(profile.duplicate(true))

func _step_corrupted_lullaby() -> void:
	var state: Dictionary = mission_state["sidequests"]["corrupted_lullaby"]
	state["roar"] = 432.0
	var result := SideQuestData.harmonize_lullaby(state["roar"])
	status_message = "Lunar roar response: %s." % result["result"]
	if result["success"]:
		profile = DragonProgression.grant_key_item(profile, "silken_data")
		profile = DragonProgression.set_mission_flag(profile, "npc_awakened_glitch_weaver")
		status_message = "The corrupted lullaby is harmonized. Silken Data can be woven into lag-resistant gear."
		profile_changed.emit(profile.duplicate(true))

func _step_sentinel_404() -> void:
	var state: Dictionary = mission_state["sidequests"]["sentinel_404"]
	var result := SideQuestData.update_sentinel_permissions(DragonProgression.has_key_item(profile, "root_password"))
	if not result["success"]:
		status_message = "The 404 Sentinel requires Root Password authority."
		return
	state["updated"] = true
	profile = DragonProgression.grant_key_item(profile, "partition_permissions")
	profile = DragonProgression.set_mission_flag(profile, "npc_awakened_sentinel_404")
	status_message = "404 Sentinel permissions updated. The impossible land now exists enough to enter."
	profile_changed.emit(profile.duplicate(true))

func _step_black_market_overclock() -> void:
	var result: Dictionary = ActTwoTundraData.evaluate_black_market_overclock(
		DragonProgression.has_key_item(profile, "unit_01_save_link"),
		int(profile.get("data_scraps", 0))
	)
	if not result["success"]:
		match str(result["reason"]):
			"UNIT_01_LINK_REQUIRED":
				status_message = "Pulse will not touch the wrench until Unit 01 vouches for Skye."
			"INSUFFICIENT_SCRAPS":
				status_message = "Pulse wants %d scraps for the overclock. Skye is short." % int(result["cost"])
			_:
				status_message = "The black market deal fails: %s." % result["reason"]
		return
	profile = DragonProgression.award_scraps(profile, -int(result["cost"]))
	profile = DragonProgression.grant_key_item(profile, str(result["reward_item"]))
	profile = DragonProgression.set_mission_flag(profile, "npc_awakened_glitch_hunter_pulse")
	profile = DragonProgression.set_mission_flag(profile, "black_market_overclock_installed")
	status_message = "Pulse overclocks the 10mm Wrench. Logic Pulse can freeze Type-S drones for five seconds."
	profile_changed.emit(profile.duplicate(true))

func _step_shard_purge_shield() -> void:
	var result: Dictionary = ActTwoTundraData.evaluate_shard_purge_shield_trade(
		DragonProgression.has_key_item(profile, "silicon_shards"),
		int(profile.get("data_scraps", 0))
	)
	if not result["success"]:
		match str(result["reason"]):
			"SILICON_SHARDS_REQUIRED":
				status_message = "Shard wants real Silicon Shards before trading survival gear."
			"INSUFFICIENT_SCRAPS":
				status_message = "Shard wants %d scraps plus Silicon Shards for the shield." % int(result["cost"])
			_:
				status_message = "Shard refuses the trade: %s." % result["reason"]
		return
	profile = DragonProgression.award_scraps(profile, -int(result["cost"]))
	profile = DragonProgression.grant_key_item(profile, str(result["reward_item"]))
	profile = DragonProgression.set_mission_flag(profile, "npc_awakened_glitch_hunter_shard")
	profile = DragonProgression.set_mission_flag(profile, "shard_purge_shield_traded")
	status_message = "Shard slots Silicon Shards into a Purge Shield. The next White-Out has to work harder."
	profile_changed.emit(profile.duplicate(true))

func _npc_awareness(npc_id: String, npc: Dictionary) -> int:
	if DragonProgression.has_mission_flag(profile, "npc_awakened_%s" % npc_id):
		return 2
	return int(npc.get("awareness", 0))

func _npc_awareness_label(awareness: int, npc: Dictionary) -> String:
	if awareness >= 2:
		return "AWAKENED"
	if awareness == 1:
		return "GLITCHED"
	return npc.get("state", "LOOPING")

func _npc_dialogue_for_awareness(npc: Dictionary, awareness: int) -> String:
	if awareness >= 2:
		return npc.get("awakened_line", npc.get("line", ""))
	if awareness == 1:
		return npc.get("glitch_line", npc.get("line", ""))
	return npc.get("line", "")

func _advance_danger(tile: Dictionary) -> void:
	if not pending_wild_encounter.is_empty():
		return
	var gain := WorldData.get_tile_danger(tile)
	if gain <= 0.0:
		danger_meter = maxf(0.0, danger_meter - 6.0)
		return
	danger_meter = minf(DANGER_THRESHOLD, danger_meter + gain)
	var wild = WorldData.get_wild_encounter(tile)
	if danger_meter >= DANGER_THRESHOLD and wild != null:
		pending_wild_encounter = wild.duplicate(true)
		pending_wild_encounter["source_tile_id"] = tile.get("id", "")
		status_message = "%s emerges from %s." % [pending_wild_encounter.get("title", "A hostile process"), _tile_label(tile)]

func _start_pending_wild_encounter(current: Dictionary) -> void:
	if pending_wild_encounter.is_empty():
		return
	var encounter := pending_wild_encounter.duplicate(true)
	pending_wild_encounter.clear()
	danger_meter = 0.0
	status_message = "Starting %s..." % encounter.get("title", "wild encounter")
	encounter_requested.emit(encounter["enemy_id"], _encounter_context(current, encounter, true))

func _encounter_context(current: Dictionary, encounter: Dictionary, is_wild: bool = false) -> Dictionary:
	return {
		"title": encounter.get("title", "Battle"),
		"location_id": current.get("id", ""),
		"location_label": _tile_label(current),
		"terrain_kind": current.get("kind", "field"),
		"is_arena": current.get("arena", false),
		"is_wild": is_wild,
		"arena_rule": current.get("arena_rule", ""),
		"arena_rule_label": current.get("arena_rule_label", ""),
		"arena_reward": current.get("arena_reward", {}),
	}

func _rebuild_mission_panel(current: Dictionary) -> void:
	if mission_box == null:
		return
	for child in mission_box.get_children():
		child.queue_free()

	var mission_id: String = current.get("mission", "")
	if mission_id == "":
		return

	var mission := MissionData.get_mission(mission_id)
	var header := Label.new()
	header.text = mission["title"]
	header.add_theme_font_size_override("font_size", 19)
	mission_box.add_child(header)

	if DragonProgression.has_mission_flag(profile, "%s_complete" % mission_id):
		var complete := Label.new()
		complete.text = "Mission complete. Reward installed: %s" % mission["reward_item"]
		complete.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mission_box.add_child(complete)
		if mission_id == "mission_09":
			var result := Label.new()
			result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			result.text = "Root Access accepted. Southern Partition re-rendered into Control Plaza."
			mission_box.add_child(result)
		return

	var summary := Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.text = _mission_summary(mission_id)
	mission_box.add_child(summary)

	if mission_id == "mission_06":
		_add_grading_slab_preview()
	if mission_id == "mission_05":
		_add_thermal_controls()
	elif mission_id == "mission_06":
		_add_grading_controls()
	elif mission_id == "mission_07":
		_add_relay_controls()
	elif mission_id == "mission_08":
		_add_lunar_echo_controls()
	elif mission_id == "mission_09":
		_add_handshake_controls()
	elif mission_id == "mission_10":
		_add_defrag_controls()
	elif mission_id == "mission_11":
		_add_garbage_collector_controls()
	elif mission_id == "mission_12":
		_add_kernel_breach_controls()

func _mission_summary(mission_id: String) -> String:
	if mission_id == "mission_05":
		return "Thermal Precision: hold CPU Heat Sink at 54.5 C by drawing heat out slowly and evenly."
	if mission_id == "mission_06":
		return "Grading Scanner: capture three dragons averaging 9.5+ across Surface, Corners, Edges, and Centering."
	if mission_id == "mission_07":
		var tread := "Tread installed" if DragonProgression.has_key_item(profile, "tread_upgrade") else "Install Tread at Felix Workshop for better traction"
		return "Kinetic Recovery: side-scrolling relay mode. Keep pedal-assist in the 40-60 percent band while crossing the Great Salt Flats. %s." % tread
	if mission_id == "mission_08":
		return "Frequency Matching: tune a Lunar Dragon roar within 5 Hz of hidden MIDI packet echoes."
	if mission_id == "mission_09":
		return "Handshake Protocol: answer the server rack's five-note luma-tone prompt. Felix: \"It's not a language, Skye... it's checking our checksums!\""
	if mission_id == "mission_10":
		return "Logic Tether: fly a Forest protocol between floating Deepwood fragments and snap each sector back to its correct memory address."
	if mission_id == "mission_11":
		return "Keep-Alive Pings: the Garbage Collector is not evil, only literal. Mark New Landing as in-use before the deletion wall arrives."
	if mission_id == "mission_12":
		return "Kernel Breach: collect permission nodes in the zero-gravity core, then upload a dragon consciousness as the new Security Daemon."
	return "Mission protocol ready."

func _mission_button_label(mission_id: String) -> String:
	if mission_id == "mission_05":
		return "Run Cooling Cycle"
	if mission_id == "mission_06":
		return "Open Grading Scanner"
	if mission_id == "mission_07":
		return "Start Relay Run"
	if mission_id == "mission_08":
		return "Capture Audio Echo"
	if mission_id == "mission_10":
		return "Fire Logic Tether"
	if mission_id == "mission_11":
		return "Ping Anchor"
	if mission_id == "mission_12":
		return "Patch Permission Node"
	return "Run Mission"

func _run_mission(mission_id: String) -> void:
	if mission_id == "mission_05":
		_complete_thermal_mission()
	elif mission_id == "mission_06":
		_complete_grading_mission()
	elif mission_id == "mission_07":
		_complete_relay_mission()
	elif mission_id == "mission_08":
		_complete_lunar_echo_mission()
	elif mission_id == "mission_09":
		_check_handshake_completion()
	elif mission_id == "mission_10":
		_advance_defrag_tether()
	elif mission_id == "mission_11":
		_ping_keep_alive_anchor()
	elif mission_id == "mission_12":
		_patch_kernel_permission()
	_refresh()

func _complete_thermal_mission() -> void:
	var result := MissionData.evaluate_thermal_precision(_mission_samples())
	if not result["success"]:
		return
	profile = DragonProgression.grant_key_item(profile, "sous_vide_breath")
	profile = DragonProgression.set_mission_flag(profile, "mission_05_complete")
	profile_changed.emit(profile.duplicate(true))

func _complete_grading_mission() -> void:
	var grades: Array = mission_state["mission_06"]["captures"]
	for grade in grades:
		if grade["is_gem_mint"]:
			profile = DragonProgression.record_gem_mint_capture(profile)
		if grade["is_perfect"]:
			_show_certificate_popup(grade)
	if profile.get("gem_mint_captures", 0) >= 3:
		profile = DragonProgression.grant_key_item(profile, "archivists_binder")
		profile = DragonProgression.set_mission_flag(profile, "mission_06_complete")
	profile_changed.emit(profile.duplicate(true))

func _complete_relay_mission() -> void:
	var trace: Array[float] = []
	for input in mission_state["mission_07"]["input_trace"]:
		trace.append(input)
	var result := MissionData.evaluate_relay_run(trace)
	if not result["success"]:
		return
	profile = DragonProgression.grant_key_item(profile, "e_pulse_harness")
	profile = DragonProgression.set_mission_flag(profile, "mission_07_complete")
	profile_changed.emit(profile.duplicate(true))

func _complete_lunar_echo_mission() -> void:
	var state: Dictionary = mission_state["mission_08"]
	var result := MissionData.check_audio_echo_match(state["target"], state["roar"])
	if not result["success"]:
		return
	profile = DragonProgression.grant_key_item(profile, "piano_key_map")
	profile = DragonProgression.set_mission_flag(profile, "mission_08_complete")
	profile_changed.emit(profile.duplicate(true))

func _add_handshake_controls() -> void:
	var state: Dictionary = mission_state["mission_09"]
	var response: Array[String] = _handshake_response()
	var prompt := MissionData.get_handshake_prompt()
	var eval := MissionData.evaluate_handshake_response(response)

	var display := HandshakeSpectrogramDisplay.new()
	display.set_handshake(prompt, response, state["purge_count"])
	mission_box.add_child(display)

	var readout := Label.new()
	readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	readout.text = "Rack prompt: E4 G4 A4 C4 D4 | Response: %s | Fork stamina %.0f | Packet Purges %d" % [
		" ".join(response) if not response.is_empty() else "--",
		state["fork_stamina"],
		state["purge_count"],
	]
	mission_box.add_child(readout)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	mission_box.add_child(grid)

	for tone_id in ["solar", "magma", "lunar", "forest", "static"]:
		var tone := MissionData.get_luma_tone(tone_id)
		var button := Button.new()
		button.text = "%s Roar+Breathe  %s" % [tone["label"], tone["note"]]
		button.self_modulate = Color(tone["color"])
		button.pressed.connect(_submit_handshake_tone.bind(tone_id))
		grid.add_child(button)

	var fork := Button.new()
	fork.text = "Prism Fork: Magma -> Solar"
	fork.disabled = not DragonProgression.has_key_item(profile, "prism_tuning_fork") or state["fork_stamina"] < 35.0
	fork.pressed.connect(_submit_prism_transpose.bind("magma", "solar"))
	mission_box.add_child(fork)

	if not DragonProgression.has_key_item(profile, "prism_tuning_fork"):
		var take := Button.new()
		take.text = "Take Prism-Tuning Fork"
		take.pressed.connect(func() -> void:
			profile = DragonProgression.grant_key_item(profile, "prism_tuning_fork")
			profile_changed.emit(profile.duplicate(true))
			_refresh()
		)
		mission_box.add_child(take)

	if eval["progress"] >= eval["required"]:
		var check := Button.new()
		check.text = "Commit Response Code"
		check.pressed.connect(func() -> void:
			_check_handshake_completion()
			_refresh()
		)
		mission_box.add_child(check)

func _submit_handshake_tone(tone_id: String) -> void:
	var tone := MissionData.get_luma_tone(tone_id)
	if tone.is_empty():
		return
	_append_handshake_note(tone["note"], tone["color"])

func _submit_prism_transpose(source_tone: String, target_tone: String) -> void:
	var state: Dictionary = mission_state["mission_09"]
	var result := MissionData.transpose_with_prism(source_tone, target_tone, state["fork_stamina"])
	if not result["success"]:
		return
	state["fork_stamina"] = result["stamina"]
	_append_handshake_note(result["note"], result["color"])

func _append_handshake_note(note: String, color: String) -> void:
	var state: Dictionary = mission_state["mission_09"]
	var response: Array = state["response"]
	response.append(note)
	state["last_light"] = color
	var eval := MissionData.evaluate_handshake_response(response)
	if not eval["prefix_valid"]:
		state["purge_count"] += 1
		state["response"] = []
		profile = DragonProgression.set_mission_flag(profile, "packet_purge_triggered")
		profile_changed.emit(profile.duplicate(true))
	elif eval["success"]:
		_complete_handshake()
	_refresh()

func _check_handshake_completion() -> void:
	var eval := MissionData.evaluate_handshake_response(_handshake_response())
	if eval["success"]:
		_complete_handshake()
	else:
		var state: Dictionary = mission_state["mission_09"]
		state["purge_count"] += 1
		state["response"] = []
		profile = DragonProgression.set_mission_flag(profile, "packet_purge_triggered")
		profile_changed.emit(profile.duplicate(true))

func _complete_handshake() -> void:
	if DragonProgression.has_mission_flag(profile, "mission_09_complete"):
		return
	profile = DragonProgression.grant_key_item(profile, "root_access")
	profile = DragonProgression.set_mission_flag(profile, "mission_09_complete")
	profile = DragonProgression.set_mission_flag(profile, "control_plaza_rerendered")
	profile_changed.emit(profile.duplicate(true))

func _handshake_response() -> Array[String]:
	var typed: Array[String] = []
	for note in mission_state["mission_09"]["response"]:
		typed.append(str(note))
	return typed

func _ensure_system_admin_state() -> void:
	if not mission_state.has("mission_10"):
		mission_state["mission_10"] = { "tethers": 0 }
	if not mission_state.has("mission_11"):
		mission_state["mission_11"] = { "anchors": [], "deletion_wall_distance": 100 }
	if not mission_state.has("mission_12"):
		mission_state["mission_12"] = { "permission_nodes": [], "daemon_uploaded": false }
	if not mission_state.has("admin"):
		mission_state["admin"] = { "sector_integrity": 0.85 }

func _ensure_sidequest_state() -> void:
	if not mission_state.has("sidequests"):
		mission_state["sidequests"] = {}
	var sidequests: Dictionary = mission_state["sidequests"]
	if not sidequests.has("memory_leak"):
		sidequests["memory_leak"] = { "timer": 300.0, "locked_assets": [] }
	if not sidequests.has("ghost_in_the_well"):
		sidequests["ghost_in_the_well"] = { "roar": 440.0 }
	if not sidequests.has("unauthorized_manual"):
		sidequests["unauthorized_manual"] = { "pages": 0 }
	if not sidequests.has("rerender_portrait"):
		sidequests["rerender_portrait"] = { "passes": 0 }
	if not sidequests.has("asset_recovery"):
		sidequests["asset_recovery"] = { "fragments": 0, "glitch": 0 }
	if not sidequests.has("wireframe_harvest"):
		sidequests["wireframe_harvest"] = { "bakes": 0 }
	if not sidequests.has("stuck_path"):
		sidequests["stuck_path"] = { "shorts": 0 }
	if not sidequests.has("corrupted_lullaby"):
		sidequests["corrupted_lullaby"] = { "roar": 429.0 }
	if not sidequests.has("sentinel_404"):
		sidequests["sentinel_404"] = { "updated": false }

func _sector_integrity() -> float:
	_ensure_system_admin_state()
	return float(mission_state["admin"].get("sector_integrity", 0.85))

func _set_sector_integrity(value: float) -> void:
	_ensure_system_admin_state()
	mission_state["admin"]["sector_integrity"] = clampf(value, 0.0, 1.0)

func _add_defrag_controls() -> void:
	var state: Dictionary = mission_state["mission_10"]
	var readout := Label.new()
	readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	readout.text = "Logic tethers: %d / %d | Sector Integrity %.0f percent" % [
		state.get("tethers", 0),
		MissionData.get_mission("mission_10")["required_tethers"],
		_sector_integrity() * 100.0,
	]
	mission_box.add_child(readout)

	var bar := ProgressBar.new()
	bar.max_value = MissionData.get_mission("mission_10")["required_tethers"]
	bar.value = state.get("tethers", 0)
	mission_box.add_child(bar)

	var button := Button.new()
	button.text = "Fly Logic Tether"
	button.pressed.connect(func() -> void:
		_advance_defrag_tether()
		_refresh()
	)
	mission_box.add_child(button)

func _add_garbage_collector_controls() -> void:
	var state: Dictionary = mission_state["mission_11"]
	var anchors: Array = state.get("anchors", [])
	var readout := Label.new()
	readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	readout.text = "Keep-Alive Anchors: %d / %d | Deletion Wall: %d percent distance" % [
		anchors.size(),
		MissionData.get_mission("mission_11")["required_keep_alive_pings"],
		state.get("deletion_wall_distance", 100),
	]
	mission_box.add_child(readout)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	mission_box.add_child(grid)
	for anchor_id in ["well", "stable", "workshop", "signal_tower"]:
		var button := Button.new()
		button.text = "Ping %s" % anchor_id.capitalize()
		button.disabled = anchors.has(anchor_id)
		button.pressed.connect(func() -> void:
			_ping_keep_alive_anchor(anchor_id)
			_refresh()
		)
		grid.add_child(button)

func _add_kernel_breach_controls() -> void:
	var state: Dictionary = mission_state["mission_12"]
	var nodes: Array = state.get("permission_nodes", [])
	var readout := Label.new()
	readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	readout.text = "Permission Nodes: %d / %d | Security Daemon: %s" % [
		nodes.size(),
		MissionData.get_mission("mission_12")["required_permission_nodes"],
		"uploaded" if state.get("daemon_uploaded", false) else "pending",
	]
	mission_box.add_child(readout)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	mission_box.add_child(grid)
	for node_id in ["read", "write", "execute"]:
		var button := Button.new()
		button.text = "Patch %s" % node_id.capitalize()
		button.disabled = nodes.has(node_id)
		button.pressed.connect(func() -> void:
			_patch_kernel_permission(node_id)
			_refresh()
		)
		grid.add_child(button)

	var upload := Button.new()
	upload.text = "Upload First Dragon as Security Daemon"
	upload.disabled = nodes.size() < MissionData.get_mission("mission_12")["required_permission_nodes"] or state.get("daemon_uploaded", false)
	upload.pressed.connect(func() -> void:
		_upload_security_daemon()
		_refresh()
	)
	mission_box.add_child(upload)

func _advance_defrag_tether() -> void:
	var state: Dictionary = mission_state["mission_10"]
	var result := MissionData.evaluate_defrag_tether(state.get("tethers", 0), _sector_integrity())
	state["tethers"] = result["tethers"]
	_set_sector_integrity(result["sector_integrity"])
	status_message = "Logic Tether locked: Deepwood fragment %d restored." % state["tethers"]
	if result["success"]:
		profile = DragonProgression.grant_key_item(profile, "deepwood_shortcuts")
		profile = DragonProgression.set_mission_flag(profile, "mission_10_complete")
		status_message = "Deepwood defragmented. New sub-directory shortcuts are online."
		profile_changed.emit(profile.duplicate(true))

func _ping_keep_alive_anchor(anchor_id: String = "") -> void:
	var state: Dictionary = mission_state["mission_11"]
	var anchors: Array = state.get("anchors", [])
	var resolved_anchor := anchor_id
	if resolved_anchor == "":
		resolved_anchor = ["well", "stable", "workshop", "signal_tower"][anchors.size() % 4]
	var result := MissionData.evaluate_keep_alive_ping(anchors, resolved_anchor, _sector_integrity())
	state["anchors"] = result["anchors"]
	state["deletion_wall_distance"] = result["deletion_wall_distance"]
	_set_sector_integrity(result["sector_integrity"])
	status_message = "Keep-Alive ping accepted at %s." % resolved_anchor.capitalize()
	if result["success"]:
		profile = DragonProgression.grant_key_item(profile, "whitelist_patch")
		profile = DragonProgression.set_mission_flag(profile, "mission_11_complete")
		status_message = "New Landing is whitelisted. The deletion wall rolls back."
		profile_changed.emit(profile.duplicate(true))

func _patch_kernel_permission(node_id: String = "") -> void:
	var state: Dictionary = mission_state["mission_12"]
	var nodes: Array = state.get("permission_nodes", [])
	var resolved_node := node_id
	if resolved_node == "":
		resolved_node = ["read", "write", "execute"][nodes.size() % 3]
	var result := MissionData.evaluate_kernel_permission(nodes, resolved_node)
	state["permission_nodes"] = result["nodes"]
	status_message = "Kernel permission patched: %s." % resolved_node.capitalize()

func _upload_security_daemon() -> void:
	var state: Dictionary = mission_state["mission_12"]
	if state.get("permission_nodes", []).size() < MissionData.get_mission("mission_12")["required_permission_nodes"]:
		return
	state["daemon_uploaded"] = true
	profile = DragonProgression.grant_key_item(profile, "god_mode_fly")
	profile = DragonProgression.set_mission_flag(profile, "first_dragon_uploaded")
	profile = DragonProgression.set_mission_flag(profile, "mission_12_complete")
	status_message = "Kernel permissions accepted. God-Mode Fly is online."
	profile_changed.emit(profile.duplicate(true))

func _add_thermal_controls() -> void:
	var samples := _mission_samples()
	var eval_samples := samples.duplicate()
	if eval_samples.is_empty():
		eval_samples.append(60.5)
	var result := MissionData.evaluate_thermal_precision(eval_samples)
	var readout := Label.new()
	readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	readout.text = "Target: 54.5 C | Samples: %d/6 | Average: %.2f C | Max drift: %.2f C" % [
		samples.size(),
		result["average"],
		result["max_deviation"],
	]
	mission_box.add_child(readout)

	var curve := ThermalCurveDisplay.new()
	curve.set_curve(eval_samples, result["target"])
	mission_box.add_child(curve)

	var bar := ProgressBar.new()
	bar.min_value = 50.0
	bar.max_value = 65.0
	bar.value = result["average"]
	mission_box.add_child(bar)

	var gentle := Button.new()
	gentle.text = "Draw Heat Gently"
	gentle.pressed.connect(func() -> void:
		var sequence := [54.4, 54.6, 54.5, 54.7, 54.4, 54.6]
		var raw: Array = mission_state["mission_05"]["samples"]
		raw.append(sequence[raw.size() % sequence.size()])
		if raw.size() >= 6:
			_complete_thermal_mission()
		_refresh()
	)
	mission_box.add_child(gentle)

	var hard := Button.new()
	hard.text = "Vent Too Hard"
	hard.pressed.connect(func() -> void:
		mission_state["mission_05"]["samples"].append(51.9)
		_refresh()
	)
	mission_box.add_child(hard)

func _add_grading_controls() -> void:
	var state: Dictionary = mission_state["mission_06"]
	var count: int = state["captures"].size()
	var readout := Label.new()
	readout.text = "Gem-Mint captures: %d / 3 | System Credits: %d" % [profile.get("gem_mint_captures", 0), profile.get("system_credits", 0)]
	mission_box.add_child(readout)

	var slab := GradingSlabDisplay.new()
	if count > 0:
		slab.set_grade(state["captures"][count - 1])
	mission_box.add_child(slab)

	var capture := Button.new()
	capture.text = "Capture Drone Snapshot"
	capture.pressed.connect(_capture_dragon_grade)
	mission_box.add_child(capture)

	if count > 0:
		var latest: Dictionary = state["captures"][count - 1]
		var latest_label := Label.new()
		latest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		latest_label.text = "Latest slab: %.1f avg | Registry Value %d | %s" % [
			latest["average"],
			latest["registry_value"],
			"Perfect 10 COA" if latest["is_perfect"] else ("Gem-Mint" if latest["is_gem_mint"] else "Bulk-delete candidate"),
		]
		mission_box.add_child(latest_label)

func _add_relay_controls() -> void:
	var state: Dictionary = mission_state["mission_07"]
	var readout := Label.new()
	readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	readout.text = "Side-scroll relay: %dkm / 50km | Stamina %.1f | Charge %.1f | Pedal %.0f percent" % [
		state["input_trace"].size() * 5,
		state["stamina"],
		state["charge"],
		state["pedal"] * 100.0,
	]
	mission_box.add_child(readout)

	var route := RelayRouteDisplay.new()
	route.set_route(
		state["input_trace"].size() * 5,
		state["stamina"],
		state["charge"],
		state["pedal"],
		DragonProgression.has_key_item(profile, "tread_upgrade")
	)
	mission_box.add_child(route)

	var stamina_bar := ProgressBar.new()
	stamina_bar.max_value = 100.0
	stamina_bar.value = state["stamina"]
	mission_box.add_child(stamina_bar)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = state["pedal"]
	slider.value_changed.connect(func(value: float) -> void:
		mission_state["mission_07"]["pedal"] = value
	)
	mission_box.add_child(slider)

	var advance := Button.new()
	advance.text = "Advance 5km Relay Segment"
	advance.pressed.connect(_advance_relay_segment)
	mission_box.add_child(advance)

func _add_lunar_echo_controls() -> void:
	var state: Dictionary = mission_state["mission_08"]
	var result := MissionData.check_audio_echo_match(state["target"], state["roar"])
	var readout := Label.new()
	readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	readout.text = "Target echo: %.1f Hz | Dragon roar: %.1f Hz | Delta %.1f Hz | %s" % [
		state["target"],
		state["roar"],
		result["delta"],
		result["result"],
	]
	mission_box.add_child(readout)

	var waveform := WaveformDisplay.new()
	waveform.set_frequencies(state["target"], state["roar"])
	mission_box.add_child(waveform)

	var slider := HSlider.new()
	slider.min_value = 420.0
	slider.max_value = 460.0
	slider.step = 0.5
	slider.value = state["roar"]
	slider.value_changed.connect(func(value: float) -> void:
		mission_state["mission_08"]["roar"] = value
	)
	mission_box.add_child(slider)

	var capture := Button.new()
	capture.text = "Lock Roar Frequency"
	capture.pressed.connect(func() -> void:
		_complete_lunar_echo_mission()
		_refresh()
	)
	mission_box.add_child(capture)

func _mission_samples() -> Array[float]:
	var typed: Array[float] = []
	for sample in mission_state["mission_05"]["samples"]:
		typed.append(sample)
	return typed

func _capture_dragon_grade() -> void:
	var grade_templates := [
		MissionData.grade_dragon(9.8, 9.6, 9.7, 9.5),
		MissionData.grade_dragon(8.8, 9.1, 8.9, 9.0),
		MissionData.grade_dragon(9.6, 9.8, 9.5, 9.7),
		MissionData.grade_dragon(10.0, 10.0, 10.0, 10.0),
	]
	var state: Dictionary = mission_state["mission_06"]
	var grade: Dictionary = grade_templates[state["next_capture"] % grade_templates.size()]
	state["next_capture"] += 1
	state["captures"].append(grade)
	if grade["is_gem_mint"]:
		profile = DragonProgression.record_gem_mint_capture(profile)
	else:
		profile = DragonProgression.award_system_credits(profile, grade["registry_value"])
	if grade["is_perfect"]:
		_show_certificate_popup(grade)
	if profile.get("gem_mint_captures", 0) >= 3:
		profile = DragonProgression.grant_key_item(profile, "archivists_binder")
		profile = DragonProgression.set_mission_flag(profile, "mission_06_complete")
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _advance_relay_segment() -> void:
	var state: Dictionary = mission_state["mission_07"]
	var intensity: float = state["pedal"]
	var next := MissionData.update_stamina_logic(
		state["stamina"],
		state["charge"],
		intensity,
		DragonProgression.has_key_item(profile, "tread_upgrade")
	)
	state["input_trace"].append(intensity)
	state["stamina"] = next["stamina"]
	state["charge"] = next["charge_meter"]
	if state["input_trace"].size() >= 10:
		_complete_relay_mission()
	_refresh()

func _resolve_tile_artifact(current: Dictionary) -> void:
	var artifact_id: String = current.get("artifact", "")
	if current.get("id", "") == "forge_lab" and not DragonProgression.has_mission_flag(profile, "visited_felix_lab"):
		profile = DragonProgression.set_mission_flag(profile, "visited_felix_lab")
		profile_changed.emit(profile.duplicate(true))
	if current.get("id", "") == "overgrown_buffer" and not DragonProgression.has_mission_flag(profile, "entered_southern_partition"):
		profile = DragonProgression.set_mission_flag(profile, "entered_southern_partition")
		profile_changed.emit(profile.duplicate(true))
	if artifact_id == "" or artifact_id == last_artifact_id:
		return
	if artifact_id == "root_password" and not DragonProgression.has_key_item(profile, "root_password"):
		profile = DragonProgression.grant_key_item(profile, "root_password")
		profile_changed.emit(profile.duplicate(true))
		last_artifact_id = artifact_id
		return
	if artifact_id == "overclocked_state" and not DragonProgression.has_mission_flag(profile, "overclocked_state_discovered"):
		profile = DragonProgression.set_mission_flag(profile, "overclocked_state_discovered")
		profile_changed.emit(profile.duplicate(true))
		last_artifact_id = artifact_id

func _resolve_vertical_slice_completion() -> void:
	if DragonProgression.has_mission_flag(profile, "vertical_slice_complete"):
		return
	if DragonProgression.has_mission_flag(profile, "mission_09_complete") and DragonProgression.has_mission_flag(profile, "stable_connection"):
		profile = DragonProgression.set_mission_flag(profile, "vertical_slice_complete")
		status_message = "Vertical slice complete: Root Access is stable and the boot-up defense is won."
		profile_changed.emit(profile.duplicate(true))

func _rebuild_technique_console(current: Dictionary) -> void:
	if technique_box == null:
		return
	for child in technique_box.get_children():
		child.queue_free()

	var header := Label.new()
	header.add_theme_font_size_override("font_size", 18)
	header.text = "Technique Console" if _can_train_here(current) else "Technique Console offline"
	technique_box.add_child(header)

	var scraps := Label.new()
	scraps.text = "DataScraps: %d" % profile["data_scraps"]
	technique_box.add_child(scraps)

	if not _can_train_here(current):
		var offline := Label.new()
		offline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		offline.text = "Return to Felix Basement Lab to purchase and install new attack routines."
		technique_box.add_child(offline)
		return

	for technique in TechniqueData.get_available_for_dragon(profile["dragon_id"]):
		var button := Button.new()
		var known: bool = profile["known_techniques"].has(technique["id"])
		var equipped := DragonProgression.is_technique_equipped(profile, technique["id"])
		var known_text := "Equipped" if equipped else "Known"
		button.text = "%s (%d) - %s" % [technique["label"], technique["scrap_cost"], known_text if known else technique["description"]]
		button.disabled = known or not DragonProgression.can_learn(profile, technique["id"])
		button.pressed.connect(_learn_technique.bind(technique["id"]))
		technique_box.add_child(button)

func _learn_technique(technique_id: String) -> void:
	profile = DragonProgression.learn_technique(profile, technique_id)
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _can_train_here(current: Dictionary) -> bool:
	return current["id"] == "forge_lab" or current["id"] == "digital_forge"

func _rebuild_dragon_console(current: Dictionary) -> void:
	if dragon_box == null:
		return
	for child in dragon_box.get_children():
		child.queue_free()

	var dragon: Dictionary = DragonData.DRAGONS[profile["dragon_id"]]
	var level := DragonProgression.get_dragon_level(profile)
	var xp := DragonProgression.get_dragon_xp(profile)
	var header := Label.new()
	header.add_theme_font_size_override("font_size", 18)
	header.text = "Active Guardian: %s  Lv %d" % [dragon["name"], level]
	dragon_box.add_child(header)

	var style := Label.new()
	style.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	style.text = "%s\nXP: %d / %d\nLoadout: %s" % [dragon["attack_style"], xp, DragonProgression.xp_to_next_level(level), _loadout_label()]
	dragon_box.add_child(style)

	_add_loadout_controls()
	_add_diagnostic_index()
	_add_captains_log_console()
	_add_hatchery_registry_console()

	if current["id"] == "forge_lab":
		_add_workshop_controls()

	if not _can_switch_here(current):
		return

	for dragon_id in ["fire", "shadow"]:
		var option: Dictionary = DragonData.DRAGONS[dragon_id]
		var button := Button.new()
		button.text = "Deploy %s" % option["name"]
		button.disabled = profile["dragon_id"] == dragon_id
		button.pressed.connect(_switch_dragon.bind(dragon_id))
		dragon_box.add_child(button)

func _switch_dragon(dragon_id: String) -> void:
	profile = DragonProgression.switch_dragon(profile, dragon_id)
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _add_loadout_controls() -> void:
	var header := Label.new()
	header.add_theme_font_size_override("font_size", 16)
	header.text = "Technique Loadout (%d max)" % DragonProgression.MAX_LOADOUT_TECHNIQUES
	dragon_box.add_child(header)

	for technique_id in profile.get("known_techniques", []):
		var technique := TechniqueData.get_technique(str(technique_id))
		if technique.is_empty():
			continue
		var equipped := DragonProgression.is_technique_equipped(profile, technique["id"])
		var button := Button.new()
		button.text = "%s %s" % ["Equipped:" if equipped else "Equip:", technique["label"]]
		button.tooltip_text = technique["description"]
		button.disabled = equipped and DragonProgression.get_active_techniques(profile).size() <= 1
		button.pressed.connect(_toggle_technique_loadout.bind(technique["id"]))
		dragon_box.add_child(button)

func _toggle_technique_loadout(technique_id: String) -> void:
	profile = DragonProgression.toggle_loadout_technique(profile, technique_id)
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _loadout_label() -> String:
	var labels: Array[String] = []
	for technique_id in DragonProgression.get_active_techniques(profile):
		var technique := TechniqueData.get_technique(technique_id)
		if not technique.is_empty():
			labels.append(technique["label"])
	return ", ".join(labels) if not labels.is_empty() else "Base commands only"

func _can_switch_here(current: Dictionary) -> bool:
	return current["id"] == "digital_forge"

func _add_workshop_controls() -> void:
	var header := Label.new()
	header.add_theme_font_size_override("font_size", 17)
	header.text = "Felix Workshop"
	dragon_box.add_child(header)

	var status := Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.text = "Tread Upgrade: %s | Friction Saddle: %s | DataScraps: %d" % [
		"Installed" if DragonProgression.has_key_item(profile, "tread_upgrade") else "Needed for stable Salt Flats traction",
		"Woven" if DragonProgression.has_key_item(profile, "friction_saddle") else "Needs Weaver + Silken Data",
		profile["data_scraps"],
	]
	dragon_box.add_child(status)

	if DragonProgression.has_mission_flag(profile, "kernel_recovery_complete") and not DragonProgression.has_key_item(profile, "friction_saddle"):
		var saddle := Button.new()
		saddle.text = "Weave Friction Saddle"
		saddle.tooltip_text = "Use Silken Data, analog fasteners, and the 10mm Wrench to stabilize high-speed dives."
		saddle.pressed.connect(func() -> void:
			profile = ActOneProgressionData.craft_friction_saddle(profile)
			status_message = "The Weaver threads Silken Data through analog fasteners. Friction Saddle ready for the Great Breakout."
			profile_changed.emit(profile.duplicate(true))
			_refresh()
		)
		dragon_box.add_child(saddle)

	_add_anvil_relic_controls()

	if DragonProgression.has_key_item(profile, "tread_upgrade"):
		return

	var button := Button.new()
	button.text = "Install Tread Upgrade - 80"
	button.disabled = profile["data_scraps"] < 80
	button.pressed.connect(func() -> void:
		profile["data_scraps"] -= 80
		profile = DragonProgression.grant_key_item(profile, "tread_upgrade")
		profile_changed.emit(profile.duplicate(true))
		_refresh()
	)
	dragon_box.add_child(button)

func _add_anvil_relic_controls() -> void:
	var anvil_ui := DragonProgression.get_anvil_relic_ui_profile(profile)
	var entries: Array = anvil_ui.get("entries", [])
	var header := Label.new()
	header.add_theme_font_size_override("font_size", 16)
	header.text = "%s (%s)" % [anvil_ui.get("title", "Anvil Relics"), anvil_ui.get("slots_used_label", "0/0")]
	dragon_box.add_child(header)

	var pressure := ProgressBar.new()
	pressure.min_value = 0.0
	pressure.max_value = 1.0
	pressure.value = float(anvil_ui.get("slot_pressure", 0.0))
	pressure.show_percentage = false
	pressure.custom_minimum_size = Vector2(0.0, 8.0)
	dragon_box.add_child(pressure)

	var chrome: Dictionary = anvil_ui.get("chrome_style", {})
	var rule := Label.new()
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule.text = "%s\n%s" % [anvil_ui.get("belt_rule", ""), anvil_ui.get("upgrade_hint", "")]
	rule.add_theme_color_override("font_color", chrome.get("border_color", Color("#ffd166")))
	dragon_box.add_child(rule)

	_add_anvil_quick_kit_controls()

	for slot in anvil_ui.get("slot_rows", []):
		var socket := PanelContainer.new()
		socket.self_modulate = chrome.get("border_color", slot.get("socket_color", Color("#8fe6ff")))
		var socket_row := HBoxContainer.new()
		socket_row.add_theme_constant_override("separation", 8)
		socket.add_child(socket_row)
		var icon := Label.new()
		icon.custom_minimum_size = Vector2(30.0, 30.0)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 18)
		icon.add_theme_color_override("font_color", slot.get("socket_color", Color("#8fe6ff")))
		icon.text = str(slot.get("socket_icon", "-"))
		socket_row.add_child(icon)
		var socket_box := VBoxContainer.new()
		socket_box.add_theme_constant_override("separation", 2)
		socket_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		socket_row.add_child(socket_box)
		var slot_line := Label.new()
		slot_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot_line.text = "SOCKET %d / %s" % [
			int(slot.get("slot", 0)),
			str(slot.get("label", "")),
		]
		socket_box.add_child(slot_line)
		var gear_line := Label.new()
		gear_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		gear_line.text = "%s - %s" % [slot.get("gear_label", ""), slot.get("effect_label", "")]
		socket_box.add_child(gear_line)
		dragon_box.add_child(socket)

	if entries.is_empty():
		var locked := Label.new()
		locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		locked.text = str(anvil_ui.get("empty_label", "No analog relics are scanned into the anvil yet."))
		dragon_box.add_child(locked)
		return

	for relic in entries:
		var relic_id := str(relic.get("id", ""))
		var card := PanelContainer.new()
		card.self_modulate = relic.get("state_color", Color("#ffd166"))
		var card_box := VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 3)
		card.add_child(card_box)
		var button := Button.new()
		button.text = "[%s] %s | %s | %s" % [relic.get("icon", "?"), relic.get("button_label", relic_id), relic.get("state_label", ""), relic.get("gear_label", "")]
		button.tooltip_text = "%s\n%s" % [str(relic.get("benefit", "")), str(relic.get("disabled_reason", ""))]
		button.disabled = not bool(relic.get("can_toggle", true))
		button.pressed.connect(_toggle_anvil_relic.bind(relic_id))
		card_box.add_child(button)
		var benefit := Label.new()
		benefit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		benefit.text = "%s\n%s" % [str(relic.get("benefit", "")), str(relic.get("loadout_summary", ""))]
		card_box.add_child(benefit)
		dragon_box.add_child(card)

	var footer := Label.new()
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_theme_color_override("font_color", Color("#99d6e8"))
	footer.text = str(anvil_ui.get("footer_prompt", ""))
	dragon_box.add_child(footer)

func _add_anvil_quick_kit_controls() -> void:
	var header := Label.new()
	header.add_theme_font_size_override("font_size", 14)
	header.text = "Quick Socket Kits"
	dragon_box.add_child(header)
	for dungeon_id in ANVIL_KIT_DUNGEONS:
		var dungeon := HardwareDungeonData.get_dungeon(str(dungeon_id))
		if dungeon.is_empty():
			continue
		var belt := DragonProgression.get_anvil_utility_belt_profile(profile)
		var loadout := HardwareDungeonData.get_dungeon_loadout_profile(str(dungeon_id), belt)
		var button := Button.new()
		button.text = "Socket %s [%s]" % [loadout.get("readiness_label", dungeon.get("name", "Kit")), loadout.get("status_label", "READY")]
		button.tooltip_text = "%s\n%s" % [loadout.get("recommendation", ""), loadout.get("warning", "")]
		button.pressed.connect(_socket_anvil_kit.bind(str(dungeon_id)))
		dragon_box.add_child(button)

func _socket_anvil_kit(dungeon_id: String) -> Dictionary:
	var requirements := HardwareDungeonData.get_dungeon_loadout_requirements(dungeon_id)
	var required: Array = requirements.get("required_tools", [])
	var result := DragonProgression.apply_anvil_relic_kit(profile, required)
	profile = result.get("profile", profile).duplicate(true)
	var loadout := HardwareDungeonData.get_dungeon_loadout_profile(dungeon_id, DragonProgression.get_anvil_utility_belt_profile(profile))
	status_message = "%s: %s." % [requirements.get("readiness_label", "Hardware kit"), loadout.get("status_label", "READY")]
	if not bool(loadout.get("ready", true)):
		status_message += " %s" % loadout.get("warning", "")
	profile_changed.emit(profile.duplicate(true))
	if is_inside_tree():
		_refresh()
	result["loadout_check"] = loadout
	return result

func _toggle_anvil_relic(relic_id: String) -> void:
	profile = DragonProgression.toggle_anvil_relic(profile, relic_id)
	var labels := DragonProgression.get_carried_anvil_gear_labels(profile)
	status_message = "Anvil loadout: %s." % (", ".join(labels) if not labels.is_empty() else "utility belt empty")
	profile_changed.emit(profile.duplicate(true))
	_refresh()

func _add_diagnostic_index() -> void:
	var header := Label.new()
	header.add_theme_font_size_override("font_size", 16)
	header.text = "Diagnostic Index"
	dragon_box.add_child(header)

	if not DragonProgression.has_key_item(profile, "diagnostic_lens"):
		var locked := Label.new()
		locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		locked.text = "Locked until B.I.O.S. grants the Diagnostic Lens."
		dragon_box.add_child(locked)
		return

	for enemy_id in TacticalBattle.get_enemy_ids():
		var enemy := TacticalBattle.get_enemy(enemy_id)
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.text = "%s | Seen %d | Defeated %d | Integrity %d percent" % [
			enemy["name"],
			DragonProgression.get_seen_count(profile, enemy_id),
			DragonProgression.get_defeated_count(profile, enemy_id),
			enemy.get("code_integrity", 100),
		]
		dragon_box.add_child(line)

func _add_captains_log_console() -> void:
	var log_ui := HardwareDungeonData.get_captains_log_ui_profile(profile)
	var chrome: Dictionary = log_ui.get("chrome_style", {})
	var header := Label.new()
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", chrome.get("border_color", Color("#8fe6ff")))
	header.text = "%s (%s)" % [log_ui.get("title", "Captain's Log"), log_ui.get("completion_label", "0/0 fragments")]
	dragon_box.add_child(header)

	for entry in log_ui.get("entries", []).slice(0, 5):
		var card := PanelContainer.new()
		card.self_modulate = entry.get("entry_color", Color("#8fe6ff"))
		var card_box := VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 3)
		card.add_child(card_box)
		var title := Label.new()
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.text = "%s / %s" % [str(entry.get("state_label", "LOCKED")), str(entry.get("title", "Captain's Log"))]
		card_box.add_child(title)
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.text = str(entry.get("summary", ""))
		card_box.add_child(line)
		dragon_box.add_child(card)

func _add_hatchery_registry_console() -> void:
	var hatchery_ui := DragonProgression.get_hatchery_ring_ui_profile(profile)
	var chrome: Dictionary = hatchery_ui.get("chrome_style", {})
	var card := PanelContainer.new()
	card.self_modulate = chrome.get("border_color", hatchery_ui.get("accent_color", Color("#c0c8ff")))
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 3)
	card.add_child(card_box)
	var header := Label.new()
	header.add_theme_font_size_override("font_size", 16)
	header.text = "%s / %s" % [hatchery_ui.get("title", "Hatchery Ring"), hatchery_ui.get("status_label", "SEALED")]
	card_box.add_child(header)
	var detail := Label.new()
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.text = "%s\n%s\n%s" % [
		str(hatchery_ui.get("ring_id", "")),
		str(hatchery_ui.get("registry_label", "")),
		str(hatchery_ui.get("visit_label", "")),
	]
	card_box.add_child(detail)
	dragon_box.add_child(card)

func _add_grading_slab_preview() -> void:
	var slab := VBoxContainer.new()
	slab.add_theme_constant_override("separation", 4)
	mission_box.add_child(slab)

	var cert := Label.new()
	cert.text = "DRAGON FORGE AUTHENTIC CONDITION SLAB"
	cert.add_theme_font_size_override("font_size", 14)
	cert.add_theme_color_override("font_color", Color("#1f1f1f"))
	cert.self_modulate = Color("#d7d1c0")
	slab.add_child(cert)

	for line in [
		"Surface: -- / 10.0",
		"Corners: -- / 10.0",
		"Edges: -- / 10.0",
		"Centering: -- / 10.0",
		"Registry Value: pending scanner capture",
	]:
		var label := Label.new()
		label.text = line
		slab.add_child(label)

func _show_certificate_popup(grade: Dictionary) -> void:
	if not is_inside_tree():
		return
	var popup := AcceptDialog.new()
	popup.title = "Certificate of Authenticity"
	popup.dialog_text = "PERFECT 10 GEM-MINT DRAGON\nSurface 10 | Corners 10 | Edges 10 | Centering 10\nRegistry Value: %d" % grade["registry_value"]
	add_child(popup)
	popup.popup_centered(Vector2i(420, 220))
	popup.confirmed.connect(popup.queue_free)
