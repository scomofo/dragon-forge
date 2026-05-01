extends Control
class_name WorldMapView

signal tile_clicked(position: Vector2i)
signal selected_action_requested(command: Dictionary)

const VisualSystemData := preload("res://scripts/sim/visual_system_data.gd")

const DESIRED_TILE_SIZE := 26.0
const CAMERA_LERP := 10.0

const KIND_COLORS := {
	"field": Color("#87d82f"),
	"lab": Color("#b7b7a3"),
	"forge": Color("#8b2d24"),
	"archive": Color("#a6a69b"),
	"gate": Color("#50332b"),
	"jungle": Color("#1f8f37"),
	"hardware": Color("#8d9088"),
	"salt": Color("#e0d4ac"),
	"lunar": Color("#55627d"),
	"kernel": Color("#202434"),
	"arena": Color("#6f2725"),
	"water": Color("#1687cc"),
	"wall": Color("#111315"),
}

const TILE_STYLE_PROFILES := {
	"field": {
		"terrain_motif": "pastoral_patchwork",
		"accent_color": Color("#c9ff6a"),
		"detail_count": 3,
	},
	"jungle": {
		"terrain_motif": "data_cable_canopy",
		"accent_color": Color("#70ff8f"),
		"detail_count": 5,
	},
	"hardware": {
		"terrain_motif": "server_rack",
		"accent_color": Color("#8fe6ff"),
		"detail_count": 4,
	},
	"salt": {
		"terrain_motif": "empty_cache_plate",
		"accent_color": Color("#fff3cf"),
		"detail_count": 4,
	},
	"kernel": {
		"terrain_motif": "kernel_trace",
		"accent_color": Color("#7afcff"),
		"detail_count": 6,
	},
	"lunar": {
		"terrain_motif": "silver_cache_crater",
		"accent_color": Color("#c0c8ff"),
		"detail_count": 3,
	},
	"water": {
		"terrain_motif": "coolant_current",
		"accent_color": Color("#73d5ff"),
		"detail_count": 4,
	},
}

const LANDMARK_KINDS := {
	"forge": true,
	"lab": true,
	"gate": true,
	"hardware": true,
	"archive": true,
	"lunar": true,
	"arena": true,
}

const REGION_LABEL_PROFILES := [
	{
		"label": "Pastoral Boot Sector",
		"position": Vector2i(9, 10),
		"color": Color("#c9ff6a"),
		"backing_color": Color("#123d29"),
	},
	{
		"label": "Southern Partition",
		"position": Vector2i(20, 8),
		"color": Color("#70ff8f"),
		"backing_color": Color("#082b1a"),
	},
	{
		"label": "Hardware Husk",
		"position": Vector2i(28, 7),
		"color": Color("#8fe6ff"),
		"backing_color": Color("#10242b"),
	},
	{
		"label": "Silicon Tundra",
		"position": Vector2i(21, 5),
		"color": Color("#fff3cf"),
		"backing_color": Color("#2d2b24"),
	},
	{
		"label": "Mainframe Spine",
		"position": Vector2i(25, 3),
		"color": Color("#7afcff"),
		"backing_color": Color("#091f26"),
	},
	{
		"label": "Lunar Cache",
		"position": Vector2i(31, 15),
		"color": Color("#c0c8ff"),
		"backing_color": Color("#171b2d"),
	},
]

const PARTITION_ROUTE_PROFILES := {
	"southern_partition": {
		"label": "Cooling Intake Ascent",
		"points": [
			Vector2i(13, 10),
			Vector2i(21, 9),
			Vector2i(23, 8),
			Vector2i(27, 8),
			Vector2i(24, 4),
		],
		"route_color": Color("#70ff8f"),
		"node_color": Color("#ffb347"),
		"line_alpha": 0.34,
	},
}

var world: Dictionary = {}
var label_overrides := {}
var cleared_arenas := {}
var objective_target := Vector2i(-1, -1)
var admin_overlay_visible := false
var system_pressure := {}
var integrity_fog := {}
var diagnostic_fade := 0.0
var tile_size := 16.0
var map_origin := Vector2.ZERO
var camera_position := Vector2.ZERO
var displayed_player_position := Vector2.ZERO
var camera_initialized := false
var hovered_tile_position := Vector2i(-1, -1)
var selected_tile_position := Vector2i(-1, -1)

func set_world(next_world: Dictionary, next_label_overrides: Dictionary = {}, next_cleared_arenas: Dictionary = {}, next_objective_target: Vector2i = Vector2i(-1, -1), show_admin_overlay: bool = false, next_system_pressure: Dictionary = {}) -> void:
	world = next_world
	label_overrides = next_label_overrides
	cleared_arenas = next_cleared_arenas
	objective_target = next_objective_target
	admin_overlay_visible = show_admin_overlay
	system_pressure = next_system_pressure.duplicate(true)
	if not camera_initialized:
		camera_position = _player_map_position()
		displayed_player_position = camera_position
		camera_initialized = true
	queue_redraw()

func set_integrity_state(next_integrity_fog: Dictionary) -> void:
	integrity_fog = next_integrity_fog.duplicate(true)
	queue_redraw()

func set_selected_tile_position(map_position: Vector2i) -> void:
	selected_tile_position = map_position
	queue_redraw()

func get_selected_tile_position() -> Vector2i:
	return selected_tile_position

func move_selected_tile_focus(direction: String) -> Dictionary:
	if world.is_empty():
		return {
			"moved": false,
			"position": selected_tile_position,
			"reason": "no_world",
		}
	var deltas := {
		"north": Vector2i(0, -1),
		"south": Vector2i(0, 1),
		"east": Vector2i(1, 0),
		"west": Vector2i(-1, 0),
	}
	if not deltas.has(direction):
		return {
			"moved": false,
			"position": selected_tile_position,
			"reason": "unknown_direction",
		}
	var start := selected_tile_position
	if start.x < 0:
		start = Vector2i(world["player"]["position"])
	var delta: Vector2i = deltas[direction]
	var target: Vector2i = start + delta
	var target_tile: Dictionary = _tile_from_world_state(world, target)
	if target_tile.is_empty() or not target_tile.get("walkable", false):
		return {
			"moved": false,
			"position": start,
			"target": target,
			"reason": "blocked",
		}
	selected_tile_position = target
	hovered_tile_position = target
	queue_redraw()
	return {
		"moved": true,
		"position": selected_tile_position,
		"tile_id": target_tile.get("id", ""),
		"reason": "",
	}

func get_map_integrity_vfx_profile() -> Dictionary:
	var render_filter := str(integrity_fog.get("render_filter", "pastoral_clear"))
	match render_filter:
		"red_wireframe":
			return {
				"render_filter": render_filter,
				"wireframe_alpha": 0.46,
				"dither_alpha": 0.18,
				"warning_color": Color("#ff453a"),
			}
		"pixel_dither":
			return {
				"render_filter": render_filter,
				"wireframe_alpha": 0.0,
				"dither_alpha": 0.28,
				"warning_color": Color("#ffd166"),
			}
	return {
		"render_filter": render_filter,
		"wireframe_alpha": 0.0,
		"dither_alpha": 0.0,
		"warning_color": Color("#70ff8f"),
	}

func get_tile_style_profile(kind: String) -> Dictionary:
	var profile: Dictionary = TILE_STYLE_PROFILES.get(kind, {
		"terrain_motif": "flat_sector",
		"accent_color": Color("#f4ead2"),
		"detail_count": 2,
	})
	var result := profile.duplicate(true)
	result["kind"] = kind
	return result

func get_tile_visual_profile_for_position(map_world: Dictionary, position: Vector2i) -> Dictionary:
	var tile := _tile_from_world_state(map_world, position)
	if tile.is_empty():
		return {}
	return get_tile_visual_profile(tile)

func get_tile_visual_profile(tile: Dictionary) -> Dictionary:
	var profile: Dictionary = tile.get("visual_profile", {})
	var result := profile.duplicate(true)
	if result.is_empty():
		result["aesthetic"] = str(tile.get("kind", "field"))
	return result

func get_tile_map_identity_profile(tile: Dictionary) -> Dictionary:
	var visual := get_tile_visual_profile(tile)
	var aesthetic := str(visual.get("aesthetic", str(tile.get("kind", "field"))))
	var identity := {
		"tile_id": str(tile.get("id", "")),
		"sector_palette": aesthetic,
		"surface_motif": str(visual.get("ground_motif", visual.get("background_motif", "terrain"))),
		"map_glyph": "DOT",
		"readability_tags": [],
		"safe_zone_role": "",
		"chapter_role": "",
		"next_route": "",
		"boss_id": "",
		"interactive_surface": "",
	}
	var tags: Array = identity["readability_tags"]
	match aesthetic:
		"hardware_gothic":
			identity["map_glyph"] = "TRACE"
			tags.append("SILICON SNOW")
			tags.append("MOTHERBOARD SKY")
		"clinical_active_memory":
			identity["map_glyph"] = "CACHE"
			tags.append("CRT BINARY")
			tags.append("ACTIVE MEMORY")
	if str(tile.get("hazard_id", "")) == "white_out_purge":
		tags.append("WHITE-OUT")
		identity["purge_rule"] = "Find green shielded ports before the sector wipe."
	if str(tile.get("dungeon_id", "")) != "":
		identity["interactive_surface"] = "side_scrolling_dungeon"
	if str(tile.get("id", "")) == "physical_relay":
		identity["safe_zone_role"] = "PURGE SHELTER"
		identity["map_glyph"] = "SAFE PORT"
		tags.append("SAFE ZONE")
	if str(tile.get("id", "")) == "great_buffer_vault":
		identity["chapter_role"] = "OPTICAL LENS VAULT"
		identity["next_route"] = "Mirror Admin Gate"
	if str(tile.get("id", "")) == "mirror_admin_gate":
		identity["chapter_role"] = "TUNDRA BOSS GATE"
		identity["next_route"] = "Mainframe Spine"
		identity["boss_id"] = "mirror_admin_sentinel"
		identity["map_glyph"] = "ADMIN EYE"
		tags.append("SECTOR BOSS")
	if str(tile.get("id", "")) == "mainframe_spine_base":
		identity["chapter_role"] = "MAINFRAME ASCENT"
		identity["next_route"] = "Logic Core"
	return identity

func get_tundra_storyboard_profile(map_world: Dictionary = {}) -> Dictionary:
	var source_world := map_world if not map_world.is_empty() else world
	var beats: Array = []
	for point in [Vector2i(20, 6), Vector2i(22, 6), Vector2i(23, 5), Vector2i(24, 4)]:
		var tile := _tile_from_world_state(source_world, point)
		if tile.is_empty():
			continue
		var identity := get_tile_map_identity_profile(tile)
		beats.append({
			"position": point,
			"title": tile.get("label", "Unknown"),
			"chapter_role": identity.get("chapter_role", "ROUTE STEP"),
			"next_route": identity.get("next_route", ""),
			"map_glyph": identity.get("map_glyph", "DOT"),
			"readability_tags": identity.get("readability_tags", []),
		})
	return {
		"act": "Act II",
		"route_label": "Tundra to Mainframe Spine",
		"beat_count": beats.size(),
		"beats": beats,
		"quality_goal": "1991_aaa_story_map_readability",
	}

func get_tundra_storyboard_panel_profile(map_world: Dictionary = {}) -> Dictionary:
	var storyboard := get_tundra_storyboard_profile(map_world)
	var beats: Array = storyboard.get("beats", [])
	var labels: Array[String] = []
	var glyphs: Array[String] = []
	var beat_story_lines: Array[String] = []
	var selected_index := -1
	var boss_gate_index := -1
	for i in beats.size():
		var beat: Dictionary = beats[i]
		var title := str(beat.get("title", ""))
		labels.append(title)
		glyphs.append(str(beat.get("map_glyph", "DOT")))
		beat_story_lines.append(_tundra_beat_story_line(title))
		if beat.get("position", Vector2i(-1, -1)) == selected_tile_position:
			selected_index = i
		if str(beat.get("map_glyph", "")) == "ADMIN EYE" or str(beat.get("chapter_role", "")) == "TUNDRA BOSS GATE":
			boss_gate_index = i
	var selected_story_line := ""
	if selected_index >= 0 and selected_index < beat_story_lines.size():
		selected_story_line = beat_story_lines[selected_index]
	return {
		"visible": beats.size() > 0,
		"title": "ACT II ROUTE",
		"route_label": storyboard.get("route_label", ""),
		"beat_count": beats.size(),
		"beat_labels": labels,
		"beat_glyphs": glyphs,
		"beat_story_lines": beat_story_lines,
		"selected_story_line": selected_story_line,
		"selected_index": selected_index,
		"boss_gate_index": boss_gate_index,
		"panel_height": 104.0,
		"line_color": Color("#58dbff"),
		"boss_color": Color("#ff594d"),
		"safe_color": Color("#70ff8f"),
		"quality_goal": storyboard.get("quality_goal", ""),
	}

func get_tundra_route_rail_profile(map_world: Dictionary = {}) -> Dictionary:
	var storyboard := get_tundra_storyboard_profile(map_world)
	var beats: Array = storyboard.get("beats", [])
	var nodes: Array[Vector2i] = []
	for beat in beats:
		nodes.append(beat.get("position", Vector2i(-1, -1)))
	var segments: Array = []
	for i in range(nodes.size() - 1):
		var start := nodes[i]
		var target := nodes[i + 1]
		var beat: Dictionary = beats[i + 1]
		var segment_kind := "story"
		var segment_color := Color("#58dbff")
		var pulse_weight := 0.42
		if str(beat.get("chapter_role", "")) == "TUNDRA BOSS GATE":
			segment_kind = "boss_gate"
			segment_color = Color("#ff594d")
			pulse_weight = 0.82
		elif str(beat.get("chapter_role", "")) == "MAINFRAME ASCENT":
			segment_kind = "ascent"
			segment_color = Color("#ffd166")
			pulse_weight = 0.62
		segments.append({
			"start": start,
			"target": target,
			"segment_kind": segment_kind,
			"line_color": segment_color,
			"pulse_weight": pulse_weight,
		})
	var panel_profile := get_tundra_storyboard_panel_profile(map_world)
	var boss_gate_index: int = int(panel_profile.get("boss_gate_index", -1))
	var boss_lock_position := Vector2i(-1, -1)
	if boss_gate_index >= 0 and boss_gate_index < nodes.size():
		boss_lock_position = nodes[boss_gate_index]
	return {
		"visible": nodes.size() >= 2,
		"route_id": "tundra_act_ii",
		"nodes": nodes,
		"segments": segments,
		"node_count": nodes.size(),
		"boss_gate_index": boss_gate_index,
		"boss_lock_visible": boss_gate_index >= 0,
		"boss_lock_label": "BOSS LOCK",
		"boss_lock_position": boss_lock_position,
		"rail_width": 4.0,
		"packet_count": 5,
		"packet_style": "animated_data_pulses",
		"packet_color": Color("#ffffff"),
		"quality_goal": storyboard.get("quality_goal", ""),
	}

func get_selected_sector_title_card_profile(map_world: Dictionary = {}) -> Dictionary:
	if selected_tile_position.x < 0:
		return {"visible": false}
	var source_world := map_world if not map_world.is_empty() else world
	var tile := _tile_from_world_state(source_world, selected_tile_position)
	if tile.is_empty():
		return {"visible": false}
	var identity := get_tile_map_identity_profile(tile)
	var sector_palette := str(identity.get("sector_palette", "pastoral"))
	var chapter_role := str(identity.get("chapter_role", ""))
	var on_tundra_route := sector_palette == "hardware_gothic" or sector_palette == "clinical_active_memory" or chapter_role != ""
	if not on_tundra_route:
		return {"visible": false}
	var title := str(tile.get("label", "Unknown Sector")).to_upper()
	var subtitle := chapter_role if chapter_role != "" else "TUNDRA OF SILICON"
	if str(tile.get("id", "")) == "mirror_admin_gate":
		subtitle = "BOSS GATE / MAINFRAME SPINE"
	var hazard_line := str(tile.get("hazard", ""))
	if hazard_line == "" and identity.has("purge_rule"):
		hazard_line = str(identity.get("purge_rule", ""))
	var accent := Color("#58dbff")
	if str(tile.get("id", "")) == "mirror_admin_gate":
		accent = Color("#ff594d")
	elif sector_palette == "hardware_gothic":
		accent = Color("#70ff8f")
	return {
		"visible": true,
		"chapter_label": "ACT II",
		"title": title,
		"subtitle": subtitle,
		"hazard_line": hazard_line,
		"accent_color": accent,
		"card_style": "nes_stage_announce",
		"map_glyph": identity.get("map_glyph", "DOT"),
	}

func get_route_vfx_profile(pressure: Dictionary) -> Dictionary:
	var thread_zones: Array = pressure.get("thread_zones", [])
	var deletion_path: Array = pressure.get("deletion_path", [])
	var highest_intensity := 0.0
	for zone in thread_zones:
		highest_intensity = maxf(highest_intensity, float(zone.get("intensity", 0.0)))
	return {
		"thread_zone_count": thread_zones.size(),
		"draw_deletion_path": deletion_path.size() >= 2,
		"path_color": Color("#ffffff").lerp(Color("#ff453a"), clampf(highest_intensity, 0.0, 1.0) * 0.45),
		"thread_ring_color": Color("#ff594d"),
		"husk_pulse_color": Color("#00ffff"),
		"highest_intensity": highest_intensity,
	}

func get_premium_map_presentation_profile(pressure: Dictionary = {}) -> Dictionary:
	var source_pressure := pressure if not pressure.is_empty() else system_pressure
	var route_vfx := get_route_vfx_profile(source_pressure)
	var highest_thread := float(route_vfx.get("highest_intensity", 0.0))
	var purge_active := bool(source_pressure.get("purge_active", false))
	var has_selection := selected_tile_position.x >= 0
	var drama := clampf(highest_thread * 0.54 + (0.28 if purge_active else 0.0) + (0.16 if has_selection else 0.0), 0.0, 1.0)
	var overlay_budget: Array[String] = ["route_preview", "selected_action"]
	if purge_active or highest_thread > 0.2:
		overlay_budget.append("diagnostic_sweep")
	if has_selection:
		overlay_budget.append("focus_dim")
	if source_pressure.get("safe_zones", []).size() > 0:
		overlay_budget.append("safe_beacon")
	var layer_mix := {
		"weather": clampf(0.72 - drama * 0.22, 0.42, 0.72),
		"boundary": clampf(0.68 - drama * 0.18, 0.44, 0.68),
		"mission_pressure": clampf(0.82 - drama * 0.12, 0.58, 0.82),
		"altitude": clampf(0.78 - drama * 0.1, 0.56, 0.78),
		"diagnostic_sweep": clampf(0.48 + drama * 0.52, 0.48, 1.0),
		"route_preview": 1.0,
		"selected_action": 1.0,
	}
	var palette_grade := {
		"shadow_tint": Color("#02070b"),
		"midtone_tint": Color("#09202a"),
		"highlight_tint": Color("#d7fbff"),
		"gold_warmth": Color("#ffd166"),
		"contrast_lift": 0.08 + drama * 0.08,
		"desaturation": 0.06 + drama * 0.05,
		"bloom_alpha": 0.035 + drama * 0.045,
	}
	return {
		"grade": "CINEMATIC",
		"drama": drama,
		"vignette_alpha": 0.22 + drama * 0.26,
		"focus_dim_alpha": 0.18 + drama * 0.12 if has_selection else 0.0,
		"chrome_color": Color("#7afcff"),
		"gold_accent": Color("#ffd166"),
		"glass_alpha": 0.16 + drama * 0.08,
		"scanline_alpha": 0.05 + drama * 0.05,
		"overlay_budget": overlay_budget,
		"layer_mix": layer_mix,
		"palette_grade": palette_grade,
	}

func get_map_transition_choreography_profile(transition_id: String) -> Dictionary:
	match transition_id:
		"selection_lock":
			return {
				"transition_id": transition_id,
				"duration": 0.38,
				"easing": "expo_out",
				"steps": [
					_transition_step("focus_dim", 0.0, 0.18, "fade_in"),
					_transition_step("selected_route_flow", 0.05, 0.22, "packet_ramp"),
					_transition_step("hologram_reticle", 0.12, 0.26, "ring_snap"),
					_transition_step("selected_panel", 0.18, 0.2, "glass_slide"),
				],
			}
		"purge_enter":
			return {
				"transition_id": transition_id,
				"duration": 0.72,
				"easing": "sine_in_out",
				"steps": [
					_transition_step("palette_grade", 0.0, 0.22, "red_bias"),
					_transition_step("diagnostic_sweep", 0.12, 0.4, "scan_bands"),
					_transition_step("safe_beacon", 0.22, 0.34, "green_column"),
					_transition_step("mission_pressure", 0.32, 0.28, "urgency_pulse"),
				],
			}
		"diagnostic_flip":
			return {
				"transition_id": transition_id,
				"duration": 0.46,
				"easing": "cubic_out",
				"steps": [
					_transition_step("schematic_grid", 0.0, 0.2, "line_resolve"),
					_transition_step("admin_overlay", 0.08, 0.28, "cyan_trace"),
					_transition_step("region_plates", 0.18, 0.18, "plate_relabel"),
				],
			}
	return {
		"transition_id": transition_id,
		"duration": 0.24,
		"easing": "linear",
		"steps": [
			_transition_step("map", 0.0, 0.24, "fade"),
		],
	}

func get_cartographic_weather_profile(pressure: Dictionary = {}) -> Dictionary:
	var thread_zones: Array = pressure.get("thread_zones", [])
	var integrity_zones: Array = pressure.get("integrity_zones", [])
	var purge_active := bool(pressure.get("purge_active", false))
	var highest_thread := 0.0
	for zone in thread_zones:
		highest_thread = maxf(highest_thread, float(zone.get("intensity", 0.0)))
	var lowest_integrity := 1.0
	for zone in integrity_zones:
		lowest_integrity = minf(lowest_integrity, float(zone.get("integrity", 1.0)))
	var corruption_pressure := clampf(highest_thread * 0.65 + (1.0 - lowest_integrity) * 0.35 + (0.18 if purge_active else 0.0), 0.0, 1.0)
	var particle_count := 14 + roundi(corruption_pressure * 34.0)
	return {
		"particle_count": particle_count,
		"corruption_pressure": corruption_pressure,
		"gust_color": Color("#ff594d") if corruption_pressure >= 0.58 else Color("#ffd166") if corruption_pressure >= 0.28 else Color("#70ff8f"),
		"steam_color": Color("#8fe6ff"),
		"thread_color": Color("#ff594d"),
		"purge_active": purge_active,
		"wind_angle": -0.38 - corruption_pressure * 0.44,
	}

func get_cartographic_weather_particles(profile: Dictionary = {}) -> Array:
	var count := int(profile.get("particle_count", 0))
	var angle := float(profile.get("wind_angle", -0.45))
	var pressure := float(profile.get("corruption_pressure", 0.0))
	var particles: Array = []
	for i in range(count):
		var seed := float((i * 37) % 101) / 101.0
		var row_seed := float((i * 61) % 89) / 89.0
		var phase := float((i * 17) % 29) / 29.0
		var speed := 0.18 + pressure * 0.44 + phase * 0.18
		particles.append({
			"position": Vector2(seed, row_seed),
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"length": 0.18 + phase * 0.22 + pressure * 0.18,
			"alpha": 0.12 + pressure * 0.28 + phase * 0.08,
			"kind": "thread" if pressure >= 0.58 and i % 3 == 0 else "steam" if i % 4 == 0 else "wind",
		})
	return particles

func get_partition_boundary_profiles(map_world: Dictionary = {}) -> Array:
	var source_world := map_world if not map_world.is_empty() else world
	if source_world.is_empty() or not source_world.has("tiles"):
		return []
	var rows: Array = source_world["tiles"]
	var boundaries: Array = []
	for y in rows.size():
		var row: Array = rows[y]
		for x in row.size():
			var tile: Dictionary = row[x]
			if not tile.get("walkable", false):
				continue
			var position := Vector2i(x, y)
			for direction: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				var neighbor_position: Vector2i = position + direction
				var neighbor := _tile_from_world_state(source_world, neighbor_position)
				if neighbor.is_empty():
					continue
				var kind_a := str(tile.get("kind", "field"))
				var kind_b := str(neighbor.get("kind", "field"))
				if kind_a == kind_b:
					continue
				var profile := _boundary_profile_for_kinds(kind_a, kind_b)
				var edge := _boundary_edge_points(position, direction)
				profile["start"] = edge["start"]
				profile["end"] = edge["end"]
				profile["from_kind"] = kind_a
				profile["to_kind"] = kind_b
				profile["position"] = position
				profile["neighbor"] = neighbor_position
				boundaries.append(profile)
	return boundaries

func get_mission_pressure_profiles(map_world: Dictionary = {}, pressure: Dictionary = {}) -> Array:
	var source_world := map_world if not map_world.is_empty() else world
	if source_world.is_empty() or not source_world.has("tiles"):
		return []
	var source_pressure := pressure if not pressure.is_empty() else system_pressure
	var deletion_path: Array = source_pressure.get("deletion_path", [])
	var waypoint: Vector2i = source_pressure.get("custom_waypoint", Vector2i(-1, -1))
	var profiles: Array = []
	var rows: Array = source_world["tiles"]
	for y in rows.size():
		var row: Array = rows[y]
		for x in row.size():
			var tile: Dictionary = row[x]
			if not tile.get("walkable", false):
				continue
			var position := Vector2i(x, y)
			if position == objective_target:
				profiles.append(_mission_pressure_profile(position, "objective", "OBJ", 1.0, Color("#fff05a"), 3))
			if position == waypoint:
				profiles.append(_mission_pressure_profile(position, "waypoint", "WPT", 0.78, Color("#3157b7"), 2))
			if deletion_path.has(position):
				var deletion_index := deletion_path.find(position)
				var urgency := 1.0 - clampf(float(deletion_index) / maxf(float(deletion_path.size()), 1.0), 0.0, 0.72)
				profiles.append(_mission_pressure_profile(position, "deletion_wall", "DEL", urgency, Color("#ff594d"), 4))
			if tile.has("mission"):
				profiles.append(_mission_pressure_profile(position, "mission", "MIS", 0.72, Color("#fff05a"), 2))
			if tile.get("admin_node", false):
				profiles.append(_mission_pressure_profile(position, "admin_node", "ADM", 0.86, Color("#00ffff"), 3))
			if not tile.get("sidequests", []).is_empty():
				profiles.append(_mission_pressure_profile(position, "sidequest", "REQ", 0.68, Color("#f0b66c"), 2))
	return profiles

func get_altitude_contour_profiles(map_world: Dictionary = {}) -> Array:
	var source_world := map_world if not map_world.is_empty() else world
	if source_world.is_empty() or not source_world.has("tiles"):
		return []
	var contours: Array = []
	var rows: Array = source_world["tiles"]
	for y in rows.size():
		var row: Array = rows[y]
		for x in row.size():
			var tile: Dictionary = row[x]
			if not tile.get("walkable", false):
				continue
			var position := Vector2i(x, y)
			var tile_id := str(tile.get("id", ""))
			if tile.get("map_feature", "") == "jump_pad":
				contours.append(_altitude_contour_profile(position, "vent_lift", "VENT LIFT", 2, Color("#ffb347"), 0.82))
			elif tile_id == "mainframe_spine_base":
				contours.append(_altitude_contour_profile(position, "spine_ascent", "SPINE +1", 3, Color("#7afcff"), 0.72))
			elif tile_id == "legacy_peak":
				contours.append(_altitude_contour_profile(position, "spine_ascent", "SPINE +2", 4, Color("#7afcff"), 0.86))
			elif tile_id == "mainframe_crown":
				contours.append(_altitude_contour_profile(position, "spine_crown", "CROWN", 5, Color("#fff05a"), 0.92))
			elif tile_id == "skybox_leak":
				contours.append(_altitude_contour_profile(position, "void_draft", "VOID DRAFT", 4, Color("#c0c8ff"), 0.88))
	return contours

func get_purge_overlay_profile(pressure: Dictionary) -> Dictionary:
	var safe_zones: Array = pressure.get("safe_zones", [])
	var purge_active := bool(pressure.get("purge_active", false))
	return {
		"purge_active": purge_active,
		"purge_origin": pressure.get("purge_origin", Vector2i(24, 4)),
		"safe_zones": safe_zones.duplicate(true),
		"safe_zone_count": safe_zones.size(),
		"safe_zone_color": Color("#70ff8f"),
		"purge_color": Color("#ff453a"),
		"sweep_alpha": 0.34 if purge_active else 0.0,
		"label": "MIRROR ADMIN PURGE" if purge_active else "PURGE IDLE",
	}

func get_tundra_whiteout_front_profile(pressure: Dictionary = {}) -> Dictionary:
	var source_pressure := pressure if not pressure.is_empty() else system_pressure
	var purge_active := bool(source_pressure.get("purge_active", false))
	var safe_zones: Array = source_pressure.get("safe_zones", [])
	var front_tiles: Array[Vector2i] = []
	for point in [Vector2i(20, 6), Vector2i(21, 6), Vector2i(22, 6), Vector2i(22, 5), Vector2i(23, 5), Vector2i(24, 4)]:
		front_tiles.append(point)
	var pressure_level := 0.32
	if purge_active:
		pressure_level = 0.88
	elif not safe_zones.is_empty():
		pressure_level = 0.52
	return {
		"visible": true,
		"front_tiles": front_tiles,
		"front_tile_count": front_tiles.size(),
		"purge_active": purge_active,
		"pressure_level": pressure_level,
		"whiteout_color": Color("#f4fbff"),
		"coolant_blue": Color("#8fe6ff"),
		"safe_zone_color": Color("#70ff8f"),
		"safe_zones": safe_zones.duplicate(true),
		"band_count": 5 if purge_active else 3,
		"grain_density": 34 if purge_active else 18,
		"label": "WHITE-OUT PURGE" if purge_active else "WHITE-OUT WATCH",
		"map_language": "tundra_hardware_gothic_weather",
	}

func get_tundra_hazard_readout_profile(pressure: Dictionary = {}) -> Dictionary:
	var front := get_tundra_whiteout_front_profile(pressure)
	var shelter_count: int = front.get("safe_zones", []).size()
	var purge_active: bool = bool(front.get("purge_active", false))
	return {
		"visible": true,
		"status_label": front.get("label", "WHITE-OUT WATCH"),
		"detail_label": "%d shielded port%s" % [shelter_count, "" if shelter_count == 1 else "s"],
		"pressure_level": front.get("pressure_level", 0.0),
		"accent_color": Color("#f4fbff") if purge_active else Color("#8fe6ff"),
		"warning_color": Color("#ff594d") if purge_active else Color("#8fe6ff"),
		"readout_style": "hardware_weather_telemetry",
	}

func get_admin_search_index_profile(map_world: Dictionary = {}) -> Dictionary:
	var source_world := map_world if not map_world.is_empty() else world
	if source_world.is_empty() or not source_world.has("tiles"):
		return {"visible": false, "watched_count": 0, "watched_nodes": []}
	var watched_nodes: Array[Vector2i] = []
	var boss_node_position := Vector2i(-1, -1)
	var rows: Array = source_world["tiles"]
	for y in rows.size():
		var row: Array = rows[y]
		for x in row.size():
			var tile: Dictionary = row[x]
			if tile.get("admin_node", false) or tile.get("scanline", false):
				var position := Vector2i(x, y)
				watched_nodes.append(position)
				if str(tile.get("id", "")) == "mirror_admin_gate":
					boss_node_position = position
	return {
		"visible": watched_nodes.size() > 0,
		"overlay_id": "search_index_daemon",
		"watched_nodes": watched_nodes,
		"watched_count": watched_nodes.size(),
		"boss_node_position": boss_node_position,
		"boss_lock": boss_node_position.x >= 0,
		"scan_color": Color("#ffffff"),
		"glass_color": Color("#d7fbff"),
		"index_color": Color("#ff594d"),
		"ring_count": 3,
		"beam_count": 8,
		"label": "SEARCH & INDEX",
		"boss_label": "ADMIN EYE LOCK",
		"presentation": "white_glass_daemon_scan",
	}

func get_diagnostic_sweep_profile(pressure: Dictionary = {}) -> Dictionary:
	var thread_zones: Array = pressure.get("thread_zones", [])
	var safe_zones: Array = pressure.get("safe_zones", [])
	var purge_active := bool(pressure.get("purge_active", false))
	var highest_thread := 0.0
	for zone in thread_zones:
		highest_thread = maxf(highest_thread, float(zone.get("intensity", 0.0)))
	var active := purge_active or highest_thread > 0.12 or admin_overlay_visible
	var intensity := clampf(highest_thread + (0.35 if purge_active else 0.0) + (0.18 if admin_overlay_visible else 0.0), 0.0, 1.0)
	var safe_beacons: Array = []
	for safe_position in safe_zones:
		safe_beacons.append({
			"position": safe_position,
			"color": Color("#70ff8f"),
			"height": 1.0 + intensity * 0.6,
		})
	return {
		"active": active,
		"intensity": intensity,
		"sweep_count": 2 + roundi(intensity * 4.0),
		"sweep_color": Color("#ff453a") if purge_active or intensity >= 0.68 else Color("#00ffff"),
		"sweep_alpha": 0.1 + intensity * 0.22,
		"band_width": 0.08 + intensity * 0.08,
		"safe_beacons": safe_beacons,
	}

func get_integrity_zone_profiles(zones: Array) -> Array:
	var profiles: Array = []
	for zone in zones:
		var integrity := float(zone.get("integrity", 1.0))
		var fog_state := VisualSystemData.integrity_fog_state(integrity)
		var render_filter := str(fog_state.get("render_filter", "pastoral_clear"))
		var zone_profile := {
			"position": zone.get("position", Vector2i(-1, -1)),
			"integrity": clampf(integrity, 0.0, 1.0),
			"visual_state": fog_state.get("visual_state", "High Fidelity"),
			"render_filter": render_filter,
			"traction": fog_state.get("traction", 1.0),
			"input_lag": fog_state.get("input_lag", 0.0),
			"thread_damage_per_second": fog_state.get("thread_damage_per_second", 0.0),
			"zone_color": Color("#ff453a") if render_filter == "red_wireframe" else Color("#ffd166") if render_filter == "pixel_dither" else Color("#70ff8f"),
			"ring_alpha": 0.68 if render_filter == "red_wireframe" else 0.48 if render_filter == "pixel_dither" else 0.22,
		}
		profiles.append(zone_profile)
	return profiles

func get_integrity_zone_tooltip_profile(zone: Dictionary) -> Dictionary:
	var badges: Array[String] = []
	if float(zone.get("input_lag", 0.0)) > 0.0:
		badges.append("INPUT LAG")
	if float(zone.get("thread_damage_per_second", 0.0)) > 0.0:
		badges.append("THREAD DAMAGE")
	if float(zone.get("traction", 1.0)) < 0.7:
		badges.append("LOW TRACTION")
	var render_filter := str(zone.get("render_filter", "pastoral_clear"))
	var title := str(zone.get("visual_state", "High Fidelity"))
	var summary := "Stable flight conditions."
	if render_filter == "pixel_dither":
		summary = "Minor corruption adds maneuver lag and grain to the sector."
	elif render_filter == "red_wireframe":
		summary = "Critical Thread density damages the dragon and exposes wireframe collision."
	return {
		"title": title,
		"summary": summary,
		"badges": badges,
		"accent_color": zone.get("zone_color", Color("#70ff8f")),
	}

func get_tile_marker_profile(tile: Dictionary, cleared: bool = false) -> Dictionary:
	var marker_kind := "none"
	var ring_color := Color("#f4ead2")
	var fill_color := Color("#1a140d")
	var icon := ""
	var pulse_alpha := 0.14
	var admin_node := bool(tile.get("admin_node", false))
	var label_color := Color("#f9f4df")
	var required_gear := _gear_for_relic_code(str(tile.get("requires_relic_code", "")))
	if tile.get("id", "") == "mirror_admin_gate":
		marker_kind = "admin_boss_gate"
		ring_color = Color("#ffffff")
		fill_color = Color("#250d18")
		icon = "EYE"
		pulse_alpha = 0.42
	elif tile.get("id", "") == "physical_relay":
		marker_kind = "safe_port"
		ring_color = Color("#70ff8f")
		fill_color = Color("#0d3024")
		icon = "P"
		pulse_alpha = 0.36
	elif tile.get("id", "") == "forge_lab":
		marker_kind = "safe_dungeon"
		ring_color = Color("#70ff8f")
		fill_color = Color("#123d29")
		icon = "S"
		pulse_alpha = 0.34
	elif tile.get("hatchery_flow", false):
		marker_kind = "hatchery"
		ring_color = Color("#c0c8ff")
		fill_color = Color("#171d3d")
		icon = "H"
		pulse_alpha = 0.32
	elif required_gear != "":
		marker_kind = "access_port"
		ring_color = Color("#ffd166")
		fill_color = Color("#312611")
		icon = "W"
		pulse_alpha = 0.3
	elif tile.get("arena", false):
		marker_kind = "arena"
		ring_color = Color("#66e093") if cleared else Color("#ff594d")
		fill_color = Color("#271110")
		icon = "OK" if cleared else "X"
		pulse_alpha = 0.26
	elif str(tile.get("dungeon_id", "")) != "":
		marker_kind = "critical_dungeon" if admin_node else "dungeon"
		ring_color = Color("#7afcff") if admin_node else Color("#58dbff")
		fill_color = Color("#0d2630")
		icon = "D"
		pulse_alpha = 0.31 if admin_node else 0.24
	elif tile.has("mission"):
		marker_kind = "mission"
		ring_color = Color("#fff05a")
		fill_color = Color("#3b3315")
		icon = "!"
		pulse_alpha = 0.24
	elif tile.get("map_feature", "") == "jump_pad":
		marker_kind = "jump_pad"
		ring_color = Color("#ffb347")
		fill_color = Color("#302115")
		icon = "UP"
		pulse_alpha = 0.28
	elif admin_node:
		marker_kind = "admin"
		ring_color = Color("#00ffff")
		fill_color = Color("#09272c")
		icon = "A"
		pulse_alpha = 0.22
	elif tile.has("artifact"):
		marker_kind = "artifact"
		ring_color = Color("#f0b66c")
		fill_color = Color("#312212")
		icon = "?"
		pulse_alpha = 0.2
	elif tile.get("npc", "") != "":
		marker_kind = "npc"
		ring_color = Color("#f4ead2")
		fill_color = Color("#1c2430")
		icon = "N"
		pulse_alpha = 0.18
	return {
		"marker_kind": marker_kind,
		"ring_color": ring_color,
		"fill_color": fill_color,
		"icon": icon,
		"pulse_alpha": pulse_alpha,
		"admin_node": admin_node,
		"label_color": label_color,
		"required_gear": required_gear,
	}

func get_premium_marker_emblem_profile(marker: Dictionary) -> Dictionary:
	var marker_kind := str(marker.get("marker_kind", "none"))
	var color: Color = marker.get("ring_color", Color("#f4ead2"))
	var fill: Color = marker.get("fill_color", Color("#101820"))
	match marker_kind:
		"safe_dungeon":
			return _premium_emblem("sanctuary_core", "hero", color, fill, 7)
		"hatchery":
			return _premium_emblem("incubation_ring", "hero", color, fill, 8)
		"admin_boss_gate":
			return _premium_emblem("mirror_admin_eye", "hero", color, fill, 9)
		"safe_port":
			return _premium_emblem("shielded_port", "hero", color, fill, 7)
		"critical_dungeon":
			return _premium_emblem("admin_diamond", "major", color, fill, 6)
		"dungeon":
			return _premium_emblem("husk_gate", "major", color, fill, 5)
		"access_port":
			return _premium_emblem("wrench_sigyl", "major", color, fill, 5)
		"jump_pad":
			return _premium_emblem("ascent_chevron", "major", color, fill, 5)
		"arena":
			return _premium_emblem("combat_crown", "major", color, fill, 6)
		"mission":
			return _premium_emblem("objective_star", "standard", color, fill, 5)
		"admin":
			return _premium_emblem("admin_eye", "standard", color, fill, 5)
		"artifact":
			return _premium_emblem("relic_prism", "standard", color, fill, 4)
		"npc":
			return _premium_emblem("signal_node", "standard", color, fill, 4)
	return _premium_emblem("letter_fallback", "minor", color, fill, 2)

func get_premium_panel_style_profile(panel_kind: String, accent: Color = Color("#7afcff")) -> Dictionary:
	var glass_alpha := 0.84
	var shadow_alpha := 0.36
	var inner_glow_alpha := 0.12
	var accent_rail_width := 4.0
	if panel_kind == "selected":
		glass_alpha = 0.9
		shadow_alpha = 0.44
		inner_glow_alpha = 0.18
		accent_rail_width = 5.0
	elif panel_kind == "legend":
		glass_alpha = 0.78
		shadow_alpha = 0.28
		inner_glow_alpha = 0.1
	elif panel_kind == "status":
		accent_rail_width = 4.0
	return {
		"style": "premium_glass",
		"panel_kind": panel_kind,
		"accent": accent,
		"glass_alpha": glass_alpha,
		"shadow_alpha": shadow_alpha,
		"inner_glow_alpha": inner_glow_alpha,
		"border_alpha": 0.38,
		"bevel_width": 2.0,
		"accent_rail_width": accent_rail_width,
		"corner_cut": 8.0,
	}

func get_map_legend_entries() -> Array:
	return [
		{"label": "SAFE", "icon": "S", "color": Color("#70ff8f")},
		{"label": "DUNGEON", "icon": "D", "color": Color("#58dbff")},
		{"label": "ARENA", "icon": "X", "color": Color("#ff594d")},
		{"label": "MISSION", "icon": "!", "color": Color("#fff05a")},
		{"label": "ADMIN", "icon": "A", "color": Color("#00ffff")},
		{"label": "PORT", "icon": "W", "color": Color("#ffd166")},
		{"label": "FLUSH", "icon": "F", "color": Color("#f4fbff")},
	]

func get_region_label_profiles() -> Array:
	return REGION_LABEL_PROFILES.duplicate(true)

func get_premium_region_plate_profile(label_profile: Dictionary) -> Dictionary:
	var label := str(label_profile.get("label", "Unknown Region"))
	var color: Color = label_profile.get("color", Color("#f4ead2"))
	return {
		"style": "region_plate",
		"label": label.to_upper(),
		"system_code": label.to_upper().replace(" ", "_"),
		"plate_color": color,
		"backing_color": label_profile.get("backing_color", Color("#05111a")),
		"font_size": 11,
		"code_font_size": 7,
		"leader_length": 18.0,
		"corner_cut": 6.0,
		"rail_width": 3.0,
	}

func get_partition_route_profile(route_id: String) -> Dictionary:
	var profile: Dictionary = PARTITION_ROUTE_PROFILES.get(route_id, {})
	return profile.duplicate(true)

func get_route_forecast_profile(route_id: String, map_world: Dictionary = {}) -> Dictionary:
	var route := get_partition_route_profile(route_id)
	if route.is_empty():
		return {
			"label": "Unknown Route",
			"hazard_count": 0,
			"dungeon_count": 0,
			"jump_pad_count": 0,
			"admin_node_count": 0,
			"recommended_gear": [],
			"forecast_color": Color("#f4ead2"),
		}
	var source_world := map_world if not map_world.is_empty() else world
	var hazard_count := 0
	var dungeon_count := 0
	var jump_pad_count := 0
	var admin_node_count := 0
	var recommended_gear: Array[String] = []
	for point in route.get("points", []):
		var tile := _tile_from_world_state(source_world, point)
		if tile.is_empty():
			continue
		if str(tile.get("hazard", "")) != "":
			hazard_count += 1
		if str(tile.get("dungeon_id", "")) != "":
			dungeon_count += 1
			_append_unique_string(recommended_gear, "10mm Wrench")
		if tile.get("map_feature", "") == "jump_pad":
			jump_pad_count += 1
			_append_unique_string(recommended_gear, "Friction Harness")
		if tile.get("admin_node", false):
			admin_node_count += 1
			_append_unique_string(recommended_gear, "Refractive Plate")
		var hazard_text := str(tile.get("hazard", "")).to_lower()
		if hazard_text.contains("steam") or hazard_text.contains("pressure") or hazard_text.contains("coolant"):
			_append_unique_string(recommended_gear, "Obsidian Shell")
		if hazard_text.contains("traction"):
			_append_unique_string(recommended_gear, "Silicon Padded Gear")
	var risk_score := hazard_count + admin_node_count + dungeon_count * 0.5
	return {
		"label": route.get("label", "Route Forecast"),
		"hazard_count": hazard_count,
		"dungeon_count": dungeon_count,
		"jump_pad_count": jump_pad_count,
		"admin_node_count": admin_node_count,
		"recommended_gear": recommended_gear,
		"forecast_color": Color("#ff594d") if risk_score >= 4.0 else Color("#ffd166") if risk_score >= 2.0 else Color("#70ff8f"),
		"risk_score": risk_score,
	}

func get_route_readiness_profile(route_id: String, map_world: Dictionary = {}, carried_gear: Array = []) -> Dictionary:
	var forecast := get_route_forecast_profile(route_id, map_world)
	var missing_gear: Array[String] = []
	for gear in forecast.get("recommended_gear", []):
		if not carried_gear.has(gear):
			_append_unique_string(missing_gear, str(gear))
	var blocker_gear: Array[String] = []
	if int(forecast.get("dungeon_count", 0)) > 0 and not carried_gear.has("10mm Wrench"):
		blocker_gear.append("10mm Wrench")
	if int(forecast.get("admin_node_count", 0)) > 0 and not carried_gear.has("Refractive Plate"):
		blocker_gear.append("Refractive Plate")
	if _route_has_pressure_hazard(route_id, map_world) and not carried_gear.has("Obsidian Shell"):
		blocker_gear.append("Obsidian Shell")
	var route_ready := blocker_gear.is_empty()
	return {
		"ready": route_ready,
		"status_label": "ROUTE READY" if route_ready else "LOADOUT WARNING",
		"missing_gear": missing_gear,
		"blocker_gear": blocker_gear,
		"blocker_count": blocker_gear.size(),
		"accent_color": Color("#70ff8f") if route_ready else Color("#ff594d"),
	}

func get_route_loadout_warning_profiles(route_id: String, map_world: Dictionary = {}, carried_gear: Array = []) -> Array:
	var route := get_partition_route_profile(route_id)
	if route.is_empty():
		return []
	var source_world := map_world if not map_world.is_empty() else world
	var warnings: Array = []
	for point in route.get("points", []):
		var tile := _tile_from_world_state(source_world, point)
		if tile.is_empty():
			continue
		if str(tile.get("dungeon_id", "")) != "" and not carried_gear.has("10mm Wrench"):
			warnings.append(_route_warning(point, tile, "10mm Wrench", "Physical access blocked"))
		if tile.get("admin_node", false) and not carried_gear.has("Refractive Plate"):
			warnings.append(_route_warning(point, tile, "Refractive Plate", "Admin scan exposure"))
		var hazard_text := str(tile.get("hazard", "")).to_lower()
		if (hazard_text.contains("steam") or hazard_text.contains("pressure") or hazard_text.contains("coolant")) and not carried_gear.has("Obsidian Shell"):
			warnings.append(_route_warning(point, tile, "Obsidian Shell", "Thermal pressure hazard"))
	return warnings

func get_route_segment_profiles(route_id: String, map_world: Dictionary = {}) -> Array:
	var route := get_partition_route_profile(route_id)
	if route.is_empty():
		return []
	var source_world := map_world if not map_world.is_empty() else world
	var points: Array = route.get("points", [])
	var segments: Array = []
	for i in range(points.size() - 1):
		var start: Vector2i = points[i]
		var target: Vector2i = points[i + 1]
		var target_tile := _tile_from_world_state(source_world, target)
		var segment_kind := "stable"
		var risk_level := "low"
		var line_color := Color("#70ff8f")
		if target_tile.get("admin_node", false):
			segment_kind = "admin"
			risk_level = "critical"
			line_color = Color("#ff594d")
		elif target_tile.get("map_feature", "") == "jump_pad":
			segment_kind = "jump_pad"
			risk_level = "moderate"
			line_color = Color("#ffb347")
		elif str(target_tile.get("hazard", "")) != "":
			segment_kind = "hazard"
			risk_level = "high"
			line_color = Color("#ffd166")
		elif str(target_tile.get("dungeon_id", "")) != "":
			segment_kind = "dungeon"
			risk_level = "moderate"
			line_color = Color("#58dbff")
		segments.append({
			"start": start,
			"target": target,
			"segment_kind": segment_kind,
			"risk_level": risk_level,
			"line_color": line_color,
		})
	return segments

func get_objective_route_profile(start: Vector2i, target: Vector2i) -> Dictionary:
	if start.x < 0 or target.x < 0 or start == target:
		return {
			"draw_route": false,
			"point_count": 0,
			"points": [],
			"route_color": Color("#fff05a"),
			"route_alpha": 0.0,
		}
	var points: Array[Vector2i] = [start]
	var elbow := Vector2i(target.x, start.y)
	if elbow != start and elbow != target:
		points.append(elbow)
	points.append(target)
	return {
		"draw_route": true,
		"point_count": points.size(),
		"points": points,
		"route_color": Color("#fff05a"),
		"route_alpha": 0.62,
		"waypoint_color": Color("#3157b7"),
	}

func get_map_status_panel_profile(pressure: Dictionary = {}) -> Dictionary:
	var purge := get_purge_overlay_profile(pressure)
	if purge.get("purge_active", false):
		var safe_zone_count := int(purge.get("safe_zone_count", 0))
		return {
			"status_label": "PURGE ACTIVE",
			"detail_label": "%d safe zone%s online" % [safe_zone_count, "" if safe_zone_count == 1 else "s"],
			"panel_color": Color("#301114"),
			"accent_color": Color("#70ff8f") if safe_zone_count > 0 else Color("#ff453a"),
		}
	var integrity := get_map_integrity_vfx_profile()
	var render_filter := str(integrity.get("render_filter", "pastoral_clear"))
	if render_filter == "red_wireframe":
		return {
			"status_label": "CRITICAL ERROR",
			"detail_label": "Thread density rising",
			"panel_color": Color("#301114"),
			"accent_color": Color("#ff453a"),
		}
	if render_filter == "pixel_dither":
		return {
			"status_label": "DITHERED",
			"detail_label": "Minor corruption",
			"panel_color": Color("#2d2815"),
			"accent_color": Color("#ffd166"),
		}
	return {
		"status_label": "HIGH FIDELITY",
		"detail_label": "Stable code",
		"panel_color": Color("#102719"),
		"accent_color": Color("#70ff8f"),
	}

func get_tile_tooltip_profile(tile: Dictionary, carried_gear: Variant = null) -> Dictionary:
	var badges: Array[String] = []
	if tile.get("id", "") == "forge_lab":
		badges.append("SAFE")
	if str(tile.get("dungeon_id", "")) != "":
		badges.append("DUNGEON")
	if tile.get("arena", false):
		badges.append("ARENA")
	if tile.has("mission"):
		badges.append("MISSION")
	if tile.get("admin_node", false):
		badges.append("ADMIN")
	if tile.get("hazard", "") != "":
		badges.append("HAZARD")
	if str(tile.get("requires_relic_code", "")) != "":
		badges.append("ACCESS PORT")
	if tile.get("hatchery_flow", false):
		badges.append("HATCHERY")
	if tile.get("map_feature", "") == "jump_pad":
		badges.append("JUMP PAD")
	if tile.has("artifact"):
		badges.append("RELIC")
	if tile.get("npc", "") != "" or not tile.get("npcs", []).is_empty():
		badges.append("NPC")
	if not tile.get("sidequests", []).is_empty():
		badges.append("REQUEST")
	var marker := get_tile_marker_profile(tile)
	var action := get_tile_action_profile(tile) if carried_gear == null else get_tile_action_availability_profile(tile, carried_gear)
	var identity := get_tile_map_identity_profile(tile)
	if not bool(action.get("available", true)):
		badges.append("MISSING TOOL")
	elif str(action.get("status_label", "")) == "CAUTION":
		badges.append("CAUTION")
	return {
		"title": str(tile.get("label", "Unknown Sector")),
		"summary": str(tile.get("description", "No local description available.")),
		"kind": str(tile.get("kind", "unknown")),
		"badges": badges,
		"accent_color": marker.get("ring_color", get_tile_style_profile(str(tile.get("kind", "field"))).get("accent_color", Color("#f4ead2"))),
		"action": action,
		"visual_identity": identity,
	}

func get_tile_action_profile(tile: Dictionary) -> Dictionary:
	var required_gear := _gear_for_relic_code(str(tile.get("requires_relic_code", "")))
	if required_gear != "":
		return {
			"action_kind": "access_port",
			"primary_label": "Override %s" % _title_from_id(str(tile.get("dungeon_id", ""))),
			"detail_label": "%s physical bypass" % required_gear,
			"reward_label": "",
			"route_hint": "Manual override",
			"required_gear": required_gear,
			"action_color": Color("#ffd166"),
		}
	if tile.get("hatchery_flow", false):
		return {
			"action_kind": "hatchery",
			"primary_label": "Open Hatchery Ring",
			"detail_label": "Quantum incubation flow",
			"reward_label": "Dragon registry",
			"route_hint": str(tile.get("hatchery_id", "quantum_incubation_ring")),
			"hatchery_id": str(tile.get("hatchery_id", "quantum_incubation_ring")),
			"action_color": Color("#c0c8ff"),
		}
	if tile.get("map_feature", "") == "jump_pad":
		return {
			"action_kind": "jump_pad",
			"primary_label": "Use %s" % str(tile.get("label", "Jump Pad")),
			"detail_label": "Steam launch route",
			"reward_label": "",
			"route_hint": "Cooling Intake Ascent",
			"action_color": Color("#ffb347"),
		}
	if tile.get("arena", false):
		var reward: Dictionary = tile.get("arena_reward", {})
		return {
			"action_kind": "arena",
			"primary_label": "Challenge %s" % str(tile.get("label", "Arena")),
			"detail_label": str(tile.get("arena_rule_label", "Arena rule active")),
			"reward_label": str(reward.get("label", "First-clear reward")),
			"route_hint": "",
			"action_color": Color("#ff594d"),
		}
	if str(tile.get("dungeon_id", "")) != "":
		return {
			"action_kind": "dungeon",
			"primary_label": "Enter %s" % _title_from_id(str(tile.get("dungeon_id", ""))),
			"detail_label": "Side-scrolling hardware dungeon",
			"reward_label": "",
			"route_hint": "Utility belt check",
			"action_color": Color("#58dbff"),
		}
	if tile.has("artifact"):
		return {
			"action_kind": "artifact",
			"primary_label": "Inspect %s" % _title_from_id(str(tile.get("artifact", ""))),
			"detail_label": "Analog relic signature",
			"reward_label": "",
			"route_hint": "",
			"action_color": Color("#f0b66c"),
		}
	if tile.get("npc", "") != "" or not tile.get("npcs", []).is_empty():
		return {
			"action_kind": "npc",
			"primary_label": "Talk",
			"detail_label": "Local system contact",
			"reward_label": "",
			"route_hint": "",
			"action_color": Color("#f4ead2"),
		}
	return {
		"action_kind": "travel",
		"primary_label": "Travel",
		"detail_label": "Set waypoint",
		"reward_label": "",
		"route_hint": "",
		"action_color": Color("#70ff8f"),
	}

func get_tile_action_availability_profile(tile: Dictionary, carried_gear: Array = []) -> Dictionary:
	var action := get_tile_action_profile(tile)
	var missing_gear: Array[String] = []
	var required_gear := _gear_for_relic_code(str(tile.get("requires_relic_code", "")))
	if required_gear != "" and not carried_gear.has(required_gear):
		missing_gear.append(required_gear)
	var warning_gear: Array[String] = []
	var hazard_text := str(tile.get("hazard", "")).to_lower()
	if (hazard_text.contains("steam") or hazard_text.contains("pressure") or hazard_text.contains("coolant")) and not carried_gear.has("Obsidian Shell"):
		warning_gear.append("Obsidian Shell")
	var available := missing_gear.is_empty()
	action["available"] = available
	action["missing_gear"] = missing_gear
	action["warning_gear"] = warning_gear
	action["status_label"] = "MISSING TOOL" if not available else "CAUTION" if not warning_gear.is_empty() else "READY"
	action["blocked_reason"] = "" if available else "Needs %s" % ", ".join(missing_gear)
	action["warning_reason"] = "" if warning_gear.is_empty() else "Recommended: %s" % ", ".join(warning_gear)
	if not available:
		action["action_color"] = Color("#ff594d")
	elif not warning_gear.is_empty():
		action["action_color"] = Color("#ffb347")
	return action

func get_selected_tile_focus_profile(map_world: Dictionary = {}, carried_gear: Array = []) -> Dictionary:
	if selected_tile_position.x < 0:
		return {
			"selected": false,
			"action_status": "",
			"action_label": "",
			"focus_color": Color("#f4ead2"),
		}
	var source_world := map_world if not map_world.is_empty() else world
	var tile := _tile_from_world_state(source_world, selected_tile_position)
	if tile.is_empty():
		return {
			"selected": false,
			"action_status": "",
			"action_label": "",
			"focus_color": Color("#f4ead2"),
		}
	var action := get_tile_action_availability_profile(tile, carried_gear)
	var action_status := str(action.get("status_label", "READY"))
	var focus_color: Color = action.get("action_color", Color("#70ff8f"))
	if action_status == "MISSING TOOL":
		focus_color = Color("#ff594d")
	return {
		"selected": true,
		"position": selected_tile_position,
		"title": tile.get("label", "Unknown Sector"),
		"action_label": action.get("primary_label", ""),
		"action_status": action_status,
		"focus_color": focus_color,
		"action_kind": action.get("action_kind", "travel"),
	}

func get_selected_tile_panel_profile(map_world: Dictionary = {}, carried_gear: Array = []) -> Dictionary:
	if selected_tile_position.x < 0:
		return {"selected": false}
	var source_world := map_world if not map_world.is_empty() else world
	var tile := _tile_from_world_state(source_world, selected_tile_position)
	if tile.is_empty():
		return {"selected": false}
	var tooltip := get_tile_tooltip_profile(tile, carried_gear)
	var action: Dictionary = tooltip.get("action", {})
	var can_confirm := bool(action.get("available", true))
	return {
		"selected": true,
		"title": tooltip.get("title", "Unknown Sector"),
		"summary": tooltip.get("summary", ""),
		"badges": tooltip.get("badges", []),
		"chapter_role": tooltip.get("visual_identity", {}).get("chapter_role", ""),
		"next_route": tooltip.get("visual_identity", {}).get("next_route", ""),
		"map_glyph": tooltip.get("visual_identity", {}).get("map_glyph", "DOT"),
		"route_identity_visible": str(tooltip.get("visual_identity", {}).get("chapter_role", "")) != "",
		"route_identity_label": _route_identity_label(tooltip.get("visual_identity", {})),
		"boss_dossier": _boss_dossier_for_tile(tile),
		"action_label": action.get("primary_label", ""),
		"status_label": action.get("status_label", "READY"),
		"confirm_label": "Confirm" if can_confirm else "Cannot confirm",
		"confirm_detail": action.get("primary_label", "") if can_confirm else action.get("blocked_reason", ""),
		"panel_color": action.get("action_color", tooltip.get("accent_color", Color("#f4ead2"))),
	}

func _route_identity_label(identity: Dictionary) -> String:
	var role := str(identity.get("chapter_role", ""))
	var route := str(identity.get("next_route", ""))
	var glyph := str(identity.get("map_glyph", "DOT"))
	if role == "":
		return ""
	if route == "":
		return "%s / %s" % [glyph, role]
	return "%s / %s -> %s" % [glyph, role, route]

func _boss_dossier_for_tile(tile: Dictionary) -> Dictionary:
	if str(tile.get("id", "")) != "mirror_admin_gate":
		return {}
	return {
		"visible": true,
		"boss_id": "mirror_admin_sentinel",
		"boss_name": "MIRROR ADMIN SENTINEL",
		"phase_count": 3,
		"mechanic": "TORQUE PORTS + LOGIC PULSE",
		"threat": "SECTOR PURGE / PARITY SCAN",
		"reward": "ADMIN SHARD",
		"counterplay": "Use Wrench Overclock on drones, then seal shielded ports.",
		"required_gear": ["10mm Wrench", "Wrench Overclock"],
		"phase_labels": ["PARITY SCAN", "SECTOR PURGE", "PORT SEAL"],
		"dossier_color": Color("#ff594d"),
	}

func _storyboard_short_label(label: String) -> String:
	match label:
		"Tundra of Silicon":
			return "TUNDRA"
		"Great Buffer Vault":
			return "VAULT"
		"Mirror Admin Gate":
			return "ADMIN"
		"Mainframe Spine Base":
			return "SPINE"
	return label.left(6).to_upper()

func _tundra_beat_story_line(label: String) -> String:
	match label:
		"Tundra of Silicon":
			return "Survive the silicon snow."
		"Great Buffer Vault":
			return "Recover the Optical Lens."
		"Mirror Admin Gate":
			return "Seal ports, reboot the eye."
		"Mainframe Spine Base":
			return "Climb into raw syntax."
	return "Advance the route."

func get_selected_command_ribbon_profile(map_world: Dictionary = {}, carried_gear: Array = []) -> Dictionary:
	if selected_tile_position.x < 0:
		return {"selected": false, "segments": []}
	var source_world := map_world if not map_world.is_empty() else world
	var tile := _tile_from_world_state(source_world, selected_tile_position)
	if tile.is_empty():
		return {"selected": false, "segments": []}
	var action := get_tile_action_availability_profile(tile, carried_gear)
	var action_kind := str(action.get("action_kind", "travel"))
	var status_label := str(action.get("status_label", "READY"))
	var required_gear := str(action.get("required_gear", ""))
	if required_gear == "" and not action.get("warning_gear", []).is_empty():
		required_gear = ", ".join(action.get("warning_gear", []))
	var route_hint := str(action.get("route_hint", ""))
	if route_hint == "":
		route_hint = "Adjacent step" if action_kind == "travel" else "Local"
	var accent: Color = action.get("action_color", Color("#70ff8f"))
	var segments := [
		{
			"label": "ACTION",
			"value": action_kind.replace("_", " ").to_upper(),
			"color": accent,
		},
		{
			"label": "GEAR",
			"value": required_gear if required_gear != "" else "None",
			"color": Color("#ffd166") if required_gear != "" else Color("#70ff8f"),
		},
		{
			"label": "ROUTE",
			"value": route_hint,
			"color": Color("#58dbff") if route_hint != "Local" else Color("#dce8e2"),
		},
		{
			"label": "STATE",
			"value": status_label,
			"color": accent,
		},
	]
	return {
		"selected": true,
		"status_label": status_label,
		"accent_color": accent,
		"can_execute": bool(action.get("available", true)),
		"segments": segments,
	}

func get_selected_route_preview_profile(map_world: Dictionary = {}, carried_gear: Array = []) -> Dictionary:
	if selected_tile_position.x < 0:
		return {"draw_route": false, "points": []}
	var source_world := map_world if not map_world.is_empty() else world
	if source_world.is_empty() or not source_world.has("player"):
		return {"draw_route": false, "points": []}
	var start: Vector2i = source_world["player"].get("position", Vector2i(-1, -1))
	var destination := selected_tile_position
	var tile := _tile_from_world_state(source_world, destination)
	if start.x < 0 or tile.is_empty():
		return {"draw_route": false, "points": []}
	var path := _find_walkable_path(source_world, start, destination)
	var reachable := not path.is_empty()
	var action := get_tile_action_availability_profile(tile, carried_gear)
	var blocked_by_command := not bool(action.get("available", true))
	var risk_count := 0
	for point in path:
		var path_tile := _tile_from_world_state(source_world, point)
		if str(path_tile.get("hazard", "")) != "" or path_tile.get("admin_node", false) or path_tile.get("map_feature", "") == "jump_pad":
			risk_count += 1
	var route_color := Color("#70ff8f")
	if blocked_by_command:
		route_color = Color("#ff594d")
	elif risk_count >= 2:
		route_color = Color("#ffb347")
	elif risk_count == 1:
		route_color = Color("#ffd166")
	var destination_kind := str(action.get("action_kind", "travel"))
	return {
		"draw_route": reachable and path.size() >= 2,
		"reachable": reachable,
		"blocked_by_command": blocked_by_command,
		"points": path,
		"step_count": maxi(path.size() - 1, 0),
		"risk_count": risk_count,
		"route_color": route_color,
		"destination_kind": destination_kind,
		"status_label": action.get("status_label", "READY"),
	}

func get_selected_route_flow_profile(map_world: Dictionary = {}, carried_gear: Array = []) -> Dictionary:
	var preview := get_selected_route_preview_profile(map_world, carried_gear)
	if not preview.get("draw_route", false):
		return {
			"draw_flow": false,
			"packet_count": 0,
			"packets": [],
		}
	var points: Array = preview.get("points", [])
	var step_count := int(preview.get("step_count", 0))
	var blocked := bool(preview.get("blocked_by_command", false))
	var risk_count := int(preview.get("risk_count", 0))
	var packet_count := clampi(step_count + 1, 3, 9)
	var packet_color := Color("#ff594d") if blocked else Color("#ffb347") if risk_count > 0 else Color("#70ff8f")
	var packets: Array = []
	for index in range(packet_count):
		packets.append({
			"phase": float(index) / maxf(float(packet_count), 1.0),
			"size": 0.055 + float(index % 3) * 0.012,
			"alpha": 0.62 if blocked else 0.78,
		})
	return {
		"draw_flow": true,
		"flow_state": "blocked" if blocked else "ready",
		"packet_count": packet_count,
		"packet_color": packet_color,
		"points": points,
		"packets": packets,
		"speed": 0.42 if blocked else 0.68,
	}

func get_selected_hologram_profile(map_world: Dictionary = {}, carried_gear: Array = []) -> Dictionary:
	if selected_tile_position.x < 0:
		return {"selected": false}
	var source_world := map_world if not map_world.is_empty() else world
	var tile := _tile_from_world_state(source_world, selected_tile_position)
	if tile.is_empty():
		return {"selected": false}
	var action := get_tile_action_availability_profile(tile, carried_gear)
	var action_kind := str(action.get("action_kind", "travel"))
	var available := bool(action.get("available", true))
	var status_label := str(action.get("status_label", "READY"))
	var reticle_state := "armed" if available else "locked"
	if action_kind == "travel" and available:
		reticle_state = "route"
	var reticle_color: Color = action.get("action_color", Color("#70ff8f"))
	if not available:
		reticle_color = Color("#ff594d")
	var tick_count := 8
	match action_kind:
		"access_port":
			tick_count = 12
		"arena":
			tick_count = 14
		"hatchery":
			tick_count = 16
		"jump_pad":
			tick_count = 10
		"dungeon":
			tick_count = 10
	return {
		"selected": true,
		"position": selected_tile_position,
		"action_kind": action_kind,
		"reticle_state": reticle_state,
		"reticle_color": reticle_color,
		"tick_count": tick_count,
		"target_label": tile.get("label", "Unknown Sector"),
		"status_label": status_label,
		"can_execute": available,
		"ring_radius": 0.9 if action_kind == "hatchery" else 0.86 if action_kind == "arena" else 0.74 if action_kind == "access_port" else 0.68,
	}

func get_selected_sector_condition_profile(map_world: Dictionary = {}) -> Dictionary:
	if selected_tile_position.x < 0:
		return {"selected": false}
	var source_world := map_world if not map_world.is_empty() else world
	var tile := _tile_from_world_state(source_world, selected_tile_position)
	if tile.is_empty():
		return {"selected": false}
	var zone_profile := _integrity_zone_profile_for_position(selected_tile_position)
	if zone_profile.is_empty():
		var fog_state := VisualSystemData.integrity_fog_state(1.0)
		zone_profile = {
			"integrity": 1.0,
			"visual_state": fog_state.get("visual_state", "High Fidelity"),
			"render_filter": fog_state.get("render_filter", "pastoral_clear"),
			"traction": fog_state.get("traction", 1.0),
			"input_lag": fog_state.get("input_lag", 0.0),
			"thread_damage_per_second": fog_state.get("thread_damage_per_second", 0.0),
			"zone_color": Color("#70ff8f"),
		}
	var badges: Array[String] = []
	if str(tile.get("hazard", "")) != "":
		badges.append("HAZARD")
	if float(zone_profile.get("input_lag", 0.0)) > 0.0:
		badges.append("INPUT LAG")
	if float(zone_profile.get("thread_damage_per_second", 0.0)) > 0.0:
		badges.append("THREAD DAMAGE")
	if float(zone_profile.get("traction", 1.0)) < 0.7:
		badges.append("LOW TRACTION")
	var traction := clampf(float(zone_profile.get("traction", 1.0)), 0.0, 1.0)
	var input_lag := clampf(float(zone_profile.get("input_lag", 0.0)), 0.0, 1.0)
	var thread_damage := clampf(float(zone_profile.get("thread_damage_per_second", 0.0)), 0.0, 1.0)
	return {
		"selected": true,
		"visual_state": zone_profile.get("visual_state", "High Fidelity"),
		"integrity": clampf(float(zone_profile.get("integrity", 1.0)), 0.0, 1.0),
		"traction": traction,
		"input_lag": input_lag,
		"thread_damage_per_second": thread_damage,
		"traction_label": "TRACTION %d%%" % roundi(traction * 100.0),
		"lag_label": "LAG %dms" % roundi(input_lag * 1000.0),
		"damage_label": "THREAD %.2f/s" % thread_damage,
		"badges": badges,
		"condition_color": zone_profile.get("zone_color", Color("#70ff8f")),
	}

func get_selected_action_ray_profile(map_world: Dictionary = {}, carried_gear: Array = []) -> Dictionary:
	if selected_tile_position.x < 0:
		return {"selected": false}
	var source_world := map_world if not map_world.is_empty() else world
	var tile := _tile_from_world_state(source_world, selected_tile_position)
	if tile.is_empty():
		return {"selected": false}
	var action := get_tile_action_availability_profile(tile, carried_gear)
	var action_kind := str(action.get("action_kind", "travel"))
	var status_label := str(action.get("status_label", "READY"))
	var color: Color = action.get("action_color", Color("#70ff8f"))
	var ring_count := 2
	var spoke_count := 4
	var beam_alpha := 0.38
	match action_kind:
		"access_port":
			ring_count = 4
			spoke_count = 8
			beam_alpha = 0.58
		"jump_pad":
			ring_count = 3
			spoke_count = 6
			beam_alpha = 0.5
		"arena":
			ring_count = 5
			spoke_count = 10
			beam_alpha = 0.62
		"hatchery":
			ring_count = 5
			spoke_count = 12
			beam_alpha = 0.56
		"artifact":
			ring_count = 3
			spoke_count = 5
			beam_alpha = 0.48
		"npc":
			ring_count = 2
			spoke_count = 4
			beam_alpha = 0.34
	if status_label == "MISSING TOOL":
		color = Color("#ff594d")
		beam_alpha = 0.68
	return {
		"selected": true,
		"position": selected_tile_position,
		"player_position": source_world.get("player", {}).get("position", Vector2i(-1, -1)),
		"action_kind": action_kind,
		"status_label": status_label,
		"beam_color": color,
		"beam_alpha": beam_alpha,
		"ring_count": ring_count,
		"spoke_count": spoke_count,
		"can_execute": bool(action.get("available", true)),
		"label": action.get("primary_label", ""),
	}

func get_selected_action_command(map_world: Dictionary = {}, carried_gear: Array = []) -> Dictionary:
	if selected_tile_position.x < 0:
		return {
			"can_execute": false,
			"command_kind": "none",
			"missing_gear": [],
			"reason": "no_selection",
		}
	var source_world := map_world if not map_world.is_empty() else world
	var tile := _tile_from_world_state(source_world, selected_tile_position)
	if tile.is_empty():
		return {
			"can_execute": false,
			"command_kind": "none",
			"missing_gear": [],
			"reason": "invalid_selection",
		}
	var action := get_tile_action_availability_profile(tile, carried_gear)
	var command := {
		"can_execute": bool(action.get("available", true)),
		"command_kind": action.get("action_kind", "travel"),
		"position": selected_tile_position,
		"tile_id": tile.get("id", ""),
		"tile_label": tile.get("label", ""),
		"missing_gear": action.get("missing_gear", []),
		"status_label": action.get("status_label", "READY"),
		"route_hint": action.get("route_hint", ""),
		"reason": action.get("blocked_reason", ""),
	}
	if str(tile.get("dungeon_id", "")) != "":
		command["dungeon_id"] = tile.get("dungeon_id", "")
	if tile.has("encounter"):
		var encounter: Dictionary = tile.get("encounter", {})
		command["enemy_id"] = encounter.get("enemy_id", "")
	if tile.has("artifact"):
		command["artifact"] = tile.get("artifact", "")
	if tile.has("mission"):
		command["mission"] = tile.get("mission", "")
	if tile.has("hatchery_id"):
		command["hatchery_id"] = tile.get("hatchery_id", "")
	return command

func confirm_selected_action(map_world: Dictionary = {}, carried_gear: Array = []) -> Dictionary:
	var command := get_selected_action_command(map_world, carried_gear)
	if command.get("can_execute", false):
		selected_action_requested.emit(command.duplicate(true))
	return command

func _ready() -> void:
	custom_minimum_size = Vector2(760, 500)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float) -> void:
	if world.is_empty():
		return
	var target := _player_map_position()
	camera_position = camera_position.lerp(target, min(1.0, delta * CAMERA_LERP))
	displayed_player_position = displayed_player_position.lerp(target, min(1.0, delta * 14.0))
	var fade_target := 1.0 if admin_overlay_visible else 0.0
	diagnostic_fade = lerpf(diagnostic_fade, fade_target, min(1.0, delta * 8.0))
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var map_position := _tile_from_point(event.position)
		if map_position.x >= 0:
			selected_tile_position = map_position
			queue_redraw()
			tile_clicked.emit(map_position)
	elif event is InputEventMouseMotion:
		hovered_tile_position = _tile_from_point(event.position)
		queue_redraw()

func _draw() -> void:
	if world.is_empty():
		return
	_update_layout()
	draw_rect(Rect2(Vector2.ZERO, size), Color("#071521"))
	_draw_ocean_backdrop()
	_draw_premium_map_underlay()
	_draw_tiles()
	_draw_integrity_zones()
	_draw_cartographic_weather()
	_draw_partition_boundaries()
	_draw_mission_pressure_overlay()
	_draw_altitude_contours()
	_draw_region_labels()
	_draw_partition_routes()
	_draw_tundra_route_rail()
	_draw_route_loadout_warnings()
	_draw_landmarks()
	_draw_diagnostic_schematic()
	_draw_system_pressure()
	_draw_purge_overlay()
	_draw_tundra_whiteout_front()
	_draw_diagnostic_sweep()
	_draw_poi_alerts()
	_draw_admin_overlay()
	_draw_admin_search_index()
	_draw_objective_route()
	_draw_objective_target()
	_draw_selected_route_preview()
	_draw_selected_route_flow()
	_draw_selected_hologram()
	_draw_selected_action_rays()
	_draw_selected_tile_focus()
	_draw_player()
	_draw_hover_tooltip()
	_draw_selected_tile_panel()
	_draw_map_legend()
	_draw_status_panel()
	_draw_tundra_hazard_readout()
	_draw_selected_sector_title_card()
	_draw_tundra_storyboard_panel()
	_draw_route_forecast_panel()
	_draw_premium_map_chrome()
	_draw_cinematic_color_grade()
	_draw_frame()

func _update_layout() -> void:
	var rows: Array = world["tiles"]
	var columns: int = rows[0].size()
	tile_size = min(DESIRED_TILE_SIZE, max(14.0, floor(size.y / 15.0)))
	var map_size := Vector2(columns * tile_size, rows.size() * tile_size)
	var raw_origin := (size * 0.5 - (camera_position + Vector2(0.5, 0.5)) * tile_size).floor()
	map_origin = _clamp_origin(raw_origin, map_size)

func _draw_ocean_backdrop() -> void:
	var rows: Array = world["tiles"]
	var map_rect := Rect2(map_origin, Vector2(rows[0].size(), rows.size()) * tile_size)
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0c6fb2"))
	for y in range(-int(tile_size), int(size.y + tile_size), max(4, int(tile_size))):
		for x in range(-int(tile_size), int(size.x + tile_size), max(8, int(tile_size * 2.0))):
			var wave_pos := Vector2(x + ((y / int(max(1.0, tile_size))) % 2) * tile_size, y + tile_size * 0.45)
			draw_line(wave_pos, wave_pos + Vector2(tile_size * 0.45, 0), Color("#73d5ff", 0.22), 1.0)
	draw_rect(map_rect.grow(3), Color("#0b3f61"), false, 2.0)

func _draw_premium_map_underlay() -> void:
	var profile := get_premium_map_presentation_profile(system_pressure)
	var rows: Array = world["tiles"]
	var map_rect := Rect2(map_origin, Vector2(rows[0].size(), rows.size()) * tile_size)
	var chrome: Color = profile.get("chrome_color", Color("#7afcff"))
	draw_rect(map_rect.grow(8.0), Color("#02070b", 0.5))
	draw_rect(map_rect.grow(5.0), Color(chrome.r, chrome.g, chrome.b, float(profile.get("glass_alpha", 0.16))), false, 2.0)
	for i in range(5):
		var inset := float(i) * 3.0
		draw_rect(map_rect.grow(11.0 - inset), Color(chrome.r, chrome.g, chrome.b, 0.035), false, 1.0)

func _draw_tiles() -> void:
	var rows: Array = world["tiles"]
	var integrity_vfx := get_map_integrity_vfx_profile()
	for y in rows.size():
		var row: Array = rows[y]
		for x in row.size():
			var tile_rect := _tile_rect(Vector2i(x, y))
			if not tile_rect.intersects(Rect2(Vector2.ZERO, size).grow(tile_size)):
				continue
			var tile: Dictionary = row[x]
			var kind: String = tile.get("kind", "wall")
			var color: Color = KIND_COLORS.get(kind, Color("#222222"))
			var visual_profile := get_tile_visual_profile(tile)
			if str(visual_profile.get("aesthetic", "")) == "hardware_gothic":
				color = visual_profile.get("ground_color", color)
			elif str(visual_profile.get("aesthetic", "")) == "clinical_active_memory":
				var palette: Dictionary = visual_profile.get("palette", {})
				color = palette.get("deep_blue", color)
			draw_rect(tile_rect, color)
			_draw_terrain_detail(kind, tile_rect, Vector2i(x, y))
			_draw_tile_style_overlay(get_tile_style_profile(kind), tile_rect, Vector2i(x, y))
			_draw_tile_visual_overlay(visual_profile, tile_rect, Vector2i(x, y))
			_draw_danger_detail(tile, tile_rect, Vector2i(x, y))
			_draw_integrity_detail(integrity_vfx, tile_rect, Vector2i(x, y))

func _draw_integrity_detail(profile: Dictionary, tile_rect: Rect2, position: Vector2i) -> void:
	var dither_alpha := float(profile.get("dither_alpha", 0.0))
	if dither_alpha > 0.0 and (position.x + position.y) % 2 == 0:
		draw_rect(tile_rect.grow(-tile_size * 0.18), Color("#000000", dither_alpha))
	var wireframe_alpha := float(profile.get("wireframe_alpha", 0.0))
	if wireframe_alpha <= 0.0:
		return
	var warning: Color = profile.get("warning_color", Color("#ff453a"))
	draw_rect(tile_rect.grow(-1.0), Color(warning.r, warning.g, warning.b, wireframe_alpha), false, 1.0)
	draw_line(tile_rect.position, tile_rect.end, Color(warning.r, warning.g, warning.b, wireframe_alpha * 0.6), 1.0)
	draw_line(Vector2(tile_rect.end.x, tile_rect.position.y), Vector2(tile_rect.position.x, tile_rect.end.y), Color(warning.r, warning.g, warning.b, wireframe_alpha * 0.45), 1.0)

func _draw_integrity_zones() -> void:
	var zones := get_integrity_zone_profiles(system_pressure.get("integrity_zones", []))
	if zones.is_empty():
		return
	var pulse := (sin(Time.get_ticks_msec() / 230.0) + 1.0) * 0.5
	for zone in zones:
		var position: Vector2i = zone.get("position", Vector2i(-1, -1))
		if position.x < 0:
			continue
		var tile_rect := _tile_rect(position)
		if not tile_rect.intersects(Rect2(Vector2.ZERO, size).grow(tile_size)):
			continue
		var center := tile_rect.get_center()
		var color: Color = zone.get("zone_color", Color("#70ff8f"))
		var filter := str(zone.get("render_filter", "pastoral_clear"))
		var alpha := float(zone.get("ring_alpha", 0.22))
		draw_circle(center, tile_size * (0.58 + pulse * 0.14), Color(color.r, color.g, color.b, 0.1 + alpha * 0.12))
		draw_arc(center, tile_size * (0.72 + pulse * 0.18), 0.0, TAU, 28, Color(color.r, color.g, color.b, alpha), 2.0)
		if filter == "pixel_dither":
			for offset in range(0, 4):
				var y := tile_rect.position.y + tile_size * (0.2 + float(offset) * 0.16)
				draw_line(Vector2(tile_rect.position.x + tile_size * 0.16, y), Vector2(tile_rect.end.x - tile_size * 0.16, y), Color("#000000", 0.22), 1.0)
		elif filter == "red_wireframe":
			draw_rect(tile_rect.grow(-tile_size * 0.1), Color(color.r, color.g, color.b, 0.24), false, 1.0)
			draw_line(tile_rect.position + Vector2(tile_size * 0.14, tile_size * 0.14), tile_rect.end - Vector2(tile_size * 0.14, tile_size * 0.14), Color(color.r, color.g, color.b, 0.5), 1.0)
			draw_line(Vector2(tile_rect.end.x - tile_size * 0.14, tile_rect.position.y + tile_size * 0.14), Vector2(tile_rect.position.x + tile_size * 0.14, tile_rect.end.y - tile_size * 0.14), Color(color.r, color.g, color.b, 0.36), 1.0)

func _draw_cartographic_weather() -> void:
	var profile := get_cartographic_weather_profile(system_pressure)
	var particles := get_cartographic_weather_particles(profile)
	if particles.is_empty():
		return
	var layer_alpha := _premium_layer_alpha("weather")
	var rows: Array = world["tiles"]
	if rows.is_empty():
		return
	var map_rect := Rect2(map_origin, Vector2(rows[0].size(), rows.size()) * tile_size)
	var pulse := fmod(Time.get_ticks_msec() / 2800.0, 1.0)
	var gust_color: Color = profile.get("gust_color", Color("#70ff8f"))
	var steam_color: Color = profile.get("steam_color", Color("#8fe6ff"))
	var thread_color: Color = profile.get("thread_color", Color("#ff594d"))
	for particle in particles:
		var normalized_position: Vector2 = particle.get("position", Vector2.ZERO)
		var velocity: Vector2 = particle.get("velocity", Vector2.ZERO)
		var drift := velocity * pulse
		var wrapped := Vector2(fposmod(normalized_position.x + drift.x, 1.0), fposmod(normalized_position.y + drift.y, 1.0))
		var start := map_rect.position + wrapped * map_rect.size
		var length := float(particle.get("length", 0.2)) * tile_size
		var direction := velocity.normalized() if velocity.length() > 0.001 else Vector2.RIGHT
		var kind := str(particle.get("kind", "wind"))
		var color := gust_color
		if kind == "steam":
			color = steam_color
		elif kind == "thread":
			color = thread_color
		var alpha := float(particle.get("alpha", 0.2))
		draw_line(start, start + direction * length, Color(color.r, color.g, color.b, alpha * layer_alpha), 1.0)
	for point in get_partition_route_profile("southern_partition").get("points", []):
		var tile := _tile_from_world_state(world, point)
		if tile.get("map_feature", "") != "jump_pad":
			continue
		var center := _tile_rect(point).get_center()
		var steam_alpha := 0.18 + 0.08 * sin(Time.get_ticks_msec() / 170.0)
		for plume in range(4):
			var offset := (float(plume) - 1.5) * tile_size * 0.12
			draw_line(center + Vector2(offset, tile_size * 0.38), center + Vector2(offset * 0.35, -tile_size * 0.7), Color(steam_color.r, steam_color.g, steam_color.b, steam_alpha * layer_alpha), 1.0)

func _draw_partition_boundaries() -> void:
	var pulse := (sin(Time.get_ticks_msec() / 190.0) + 1.0) * 0.5
	var layer_alpha := _premium_layer_alpha("boundary")
	for boundary in get_partition_boundary_profiles(world):
		var start: Vector2i = boundary.get("start", Vector2i(-1, -1))
		var end: Vector2i = boundary.get("end", Vector2i(-1, -1))
		if start.x < 0 or end.x < 0:
			continue
		var start_point := map_origin + Vector2(start) * tile_size
		var end_point := map_origin + Vector2(end) * tile_size
		if not Rect2(Vector2.ZERO, size).grow(tile_size).has_point(start_point) and not Rect2(Vector2.ZERO, size).grow(tile_size).has_point(end_point):
			continue
		var color: Color = boundary.get("color", Color("#f4ead2"))
		var alpha := float(boundary.get("alpha", 0.34))
		var width := float(boundary.get("width", 1.0))
		draw_line(start_point, end_point, Color(color.r, color.g, color.b, (alpha + pulse * 0.18) * layer_alpha), width)
		if bool(boundary.get("spark", false)):
			var center := start_point.lerp(end_point, 0.5 + sin(Time.get_ticks_msec() / 220.0 + float(start.x + end.y)) * 0.18)
			draw_circle(center, maxf(1.3, tile_size * 0.045), Color(color.r, color.g, color.b, 0.74 * layer_alpha))

func _draw_mission_pressure_overlay() -> void:
	var profiles := get_mission_pressure_profiles(world)
	if profiles.is_empty():
		return
	var font := get_theme_default_font()
	var pulse := (sin(Time.get_ticks_msec() / 170.0) + 1.0) * 0.5
	var layer_alpha := _premium_layer_alpha("mission_pressure")
	for profile in profiles:
		var position: Vector2i = profile.get("position", Vector2i(-1, -1))
		if position.x < 0:
			continue
		var rect := _tile_rect(position)
		if not rect.intersects(Rect2(Vector2.ZERO, size).grow(tile_size)):
			continue
		var center := rect.get_center()
		var color: Color = profile.get("color", Color("#fff05a"))
		var urgency := float(profile.get("urgency", 0.6))
		var ring_count := int(profile.get("ring_count", 2))
		for ring in range(ring_count):
			var radius := tile_size * (0.44 + float(ring) * 0.15 + pulse * 0.08 * urgency)
			var alpha := (0.16 + urgency * 0.18) * (1.0 - float(ring) * 0.14)
			draw_arc(center, radius, -PI * 0.2, TAU * 0.82, 28, Color(color.r, color.g, color.b, alpha * layer_alpha), 1.4)
		var glyph := str(profile.get("glyph", ""))
		if glyph == "":
			continue
		var label_size := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, 7)
		var label_rect := Rect2(center + Vector2(-label_size.x * 0.5 - 3.0, -tile_size * 0.55), Vector2(label_size.x + 6.0, 10.0))
		draw_rect(label_rect, Color("#05111a", 0.72))
		draw_rect(label_rect, Color(color.r, color.g, color.b, 0.34 * layer_alpha), false, 1.0)
		draw_string(font, label_rect.position + Vector2(3.0, 7.8), glyph, HORIZONTAL_ALIGNMENT_LEFT, label_size.x, 7, Color("#f9f4df", 0.88 * layer_alpha))

func _draw_altitude_contours() -> void:
	var contours := get_altitude_contour_profiles(world)
	if contours.is_empty():
		return
	var font := get_theme_default_font()
	var pulse := (sin(Time.get_ticks_msec() / 210.0) + 1.0) * 0.5
	var layer_alpha := _premium_layer_alpha("altitude")
	for contour in contours:
		var position: Vector2i = contour.get("position", Vector2i(-1, -1))
		if position.x < 0:
			continue
		var rect := _tile_rect(position)
		if not rect.intersects(Rect2(Vector2.ZERO, size).grow(tile_size * 2.0)):
			continue
		var center := rect.get_center()
		var color: Color = contour.get("color", Color("#7afcff"))
		var rings := int(contour.get("rings", 3))
		var intensity := float(contour.get("intensity", 0.75))
		for ring in range(rings):
			var radius := tile_size * (0.52 + float(ring) * 0.22 + pulse * 0.06)
			var alpha := (0.12 + intensity * 0.12) * (1.0 - float(ring) * 0.1)
			draw_arc(center, radius, 0.0, TAU, 40, Color(color.r, color.g, color.b, alpha * layer_alpha), 1.2)
		var contour_kind := str(contour.get("contour_kind", ""))
		if contour_kind == "vent_lift" or contour_kind == "void_draft":
			for stream in range(3):
				var x_offset := (float(stream) - 1.0) * tile_size * 0.13
				draw_line(center + Vector2(x_offset, tile_size * 0.42), center + Vector2(x_offset * 0.35, -tile_size * (0.82 + pulse * 0.18)), Color(color.r, color.g, color.b, (0.28 + intensity * 0.22) * layer_alpha), 1.0)
		var label := str(contour.get("label", ""))
		var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 7)
		var label_rect := Rect2(center + Vector2(-label_size.x * 0.5 - 4.0, tile_size * 0.74), Vector2(label_size.x + 8.0, 11.0))
		draw_rect(label_rect, Color("#05111a", 0.74))
		draw_rect(label_rect, Color(color.r, color.g, color.b, 0.36 * layer_alpha), false, 1.0)
		draw_string(font, label_rect.position + Vector2(4.0, 8.2), label, HORIZONTAL_ALIGNMENT_LEFT, label_size.x, 7, Color("#f9f4df", 0.86 * layer_alpha))

func _draw_terrain_detail(kind: String, tile_rect: Rect2, position: Vector2i) -> void:
	var center := tile_rect.get_center()
	var s := tile_rect.size.x
	if kind == "water":
		draw_line(tile_rect.position + Vector2(s * 0.18, s * 0.55), tile_rect.position + Vector2(s * 0.82, s * 0.55), Color("#9be8ff", 0.45), 1.0)
	elif kind == "field":
		if (position.x + position.y) % 3 == 0:
			draw_circle(center, max(1.0, s * 0.08), Color("#c9ff6a", 0.7))
	elif kind == "jungle":
		draw_rect(Rect2(tile_rect.position + Vector2(s * 0.25, s * 0.18), Vector2(s * 0.5, s * 0.62)), Color("#063f20"))
		draw_circle(center + Vector2(0, -s * 0.15), s * 0.24, Color("#3bb64a"))
	elif kind == "archive":
		var peaks := PackedVector2Array([
			tile_rect.position + Vector2(s * 0.1, s * 0.86),
			tile_rect.position + Vector2(s * 0.48, s * 0.16),
			tile_rect.position + Vector2(s * 0.9, s * 0.86),
		])
		draw_polygon(peaks, PackedColorArray([Color("#d1d1c7"), Color("#d1d1c7"), Color("#d1d1c7")]))
		draw_polyline(peaks, Color("#4f504d"), 1.0)
	elif kind == "salt":
		draw_line(tile_rect.position + Vector2(s * 0.12, s * 0.68), tile_rect.position + Vector2(s * 0.88, s * 0.36), Color("#fff3cf", 0.8), 1.0)
	elif kind == "lunar":
		draw_circle(center, s * 0.27, Color("#c0c0c0"))
		draw_circle(center + Vector2(s * 0.14, -s * 0.1), s * 0.24, KIND_COLORS["lunar"])
	elif kind == "hardware":
		draw_rect(tile_rect.grow(-s * 0.16), Color("#c7cac1"))
		draw_rect(tile_rect.grow(-s * 0.28), Color("#30342e"))
	elif kind == "kernel":
		draw_rect(tile_rect.grow(-s * 0.18), Color("#7afcff", 0.28))
		draw_line(tile_rect.position + Vector2(s * 0.18, s * 0.2), tile_rect.position + Vector2(s * 0.86, s * 0.74), Color("#7afcff", 0.75), 1.0)
		draw_line(tile_rect.position + Vector2(s * 0.82, s * 0.18), tile_rect.position + Vector2(s * 0.2, s * 0.82), Color("#f4ead2", 0.35), 1.0)
	elif kind == "forge":
		draw_circle(center, s * 0.36, Color("#d65c2c"))
		draw_circle(center, s * 0.18, Color("#ffe076"))
	elif kind == "gate":
		draw_arc(center, s * 0.34, PI, TAU, 12, Color("#f5ce91"), 2.0)
	elif kind == "lab":
		draw_rect(tile_rect.grow(-s * 0.18), Color("#dad8c9"))
		draw_rect(Rect2(tile_rect.position + Vector2(s * 0.32, s * 0.18), Vector2(s * 0.36, s * 0.22)), Color("#6f3f35"))
	elif kind == "arena":
		draw_circle(center, s * 0.42, Color("#2a1110"))
		draw_arc(center, s * 0.35, 0.0, TAU, 18, Color("#f0b66c"), 2.0)
		draw_line(center + Vector2(-s * 0.22, -s * 0.22), center + Vector2(s * 0.22, s * 0.22), Color("#f0b66c"), 1.0)
		draw_line(center + Vector2(s * 0.22, -s * 0.22), center + Vector2(-s * 0.22, s * 0.22), Color("#f0b66c"), 1.0)

func _draw_tile_style_overlay(profile: Dictionary, tile_rect: Rect2, position: Vector2i) -> void:
	var motif := str(profile.get("terrain_motif", "flat_sector"))
	var accent: Color = profile.get("accent_color", Color("#f4ead2"))
	var count := int(profile.get("detail_count", 2))
	var s := tile_rect.size.x
	var center := tile_rect.get_center()
	match motif:
		"data_cable_canopy":
			for i in count:
				var x := tile_rect.position.x + s * (0.16 + float(i) * 0.16)
				draw_line(Vector2(x, tile_rect.position.y + s * 0.08), Vector2(x + sin(float(position.x + i)) * s * 0.18, tile_rect.end.y - s * 0.1), Color(accent.r, accent.g, accent.b, 0.44), 1.0)
			draw_circle(center, s * 0.12, Color("#063f20", 0.55))
		"server_rack":
			for i in count:
				var y := tile_rect.position.y + s * (0.18 + float(i) * 0.15)
				draw_line(Vector2(tile_rect.position.x + s * 0.18, y), Vector2(tile_rect.end.x - s * 0.18, y), Color("#101418", 0.72), 1.0)
				draw_circle(Vector2(tile_rect.end.x - s * 0.22, y), max(1.0, s * 0.035), Color(accent.r, accent.g, accent.b, 0.9))
		"empty_cache_plate":
			for i in count:
				var offset := float(i) * s * 0.12
				draw_line(tile_rect.position + Vector2(s * 0.12 + offset, s * 0.78), tile_rect.position + Vector2(s * 0.42 + offset, s * 0.28), Color(accent.r, accent.g, accent.b, 0.42), 1.0)
		"kernel_trace":
			draw_rect(tile_rect.grow(-s * 0.22), Color(accent.r, accent.g, accent.b, 0.08), false, 1.0)
			for i in count:
				var angle := TAU * float(i) / maxf(1.0, float(count))
				draw_line(center, center + Vector2(cos(angle), sin(angle)) * s * 0.38, Color(accent.r, accent.g, accent.b, 0.38), 1.0)
		"silver_cache_crater":
			for i in count:
				draw_circle(center + Vector2(s * 0.14 * cos(float(i)), s * 0.12 * sin(float(i) * 1.7)), max(1.0, s * 0.04), Color(accent.r, accent.g, accent.b, 0.48))
		"coolant_current":
			for i in count:
				var y := tile_rect.position.y + s * (0.22 + float(i) * 0.13)
				draw_line(Vector2(tile_rect.position.x + s * 0.12, y), Vector2(tile_rect.end.x - s * 0.12, y + sin(float(position.x + i)) * s * 0.08), Color(accent.r, accent.g, accent.b, 0.34), 1.0)
		"pastoral_patchwork":
			if (position.x + position.y) % 2 == 0:
				draw_rect(tile_rect.grow(-s * 0.24), Color(accent.r, accent.g, accent.b, 0.16))

func _draw_tile_visual_overlay(profile: Dictionary, tile_rect: Rect2, position: Vector2i) -> void:
	var aesthetic := str(profile.get("aesthetic", ""))
	if aesthetic == "":
		return
	var s := tile_rect.size.x
	var center := tile_rect.get_center()
	match aesthetic:
		"hardware_gothic":
			var trace: Color = profile.get("trace_color", Color("#54ff8b"))
			var dust: Color = profile.get("dust_pixel_color", Color("#b7fffb"))
			var silhouette: Color = profile.get("silhouette_color", Color("#3b312d"))
			draw_rect(tile_rect, Color("#edf6ff", 0.36))
			for i in range(3):
				var start := tile_rect.position + Vector2(s * (0.12 + float(i) * 0.26), s * 0.18)
				var end := tile_rect.position + Vector2(s * (0.28 + float(i) * 0.18), s * 0.82)
				draw_line(start, end, Color(trace.r, trace.g, trace.b, 0.48), 1.0)
			if (position.x + position.y) % 2 == 0:
				draw_rect(Rect2(center + Vector2(-s * 0.08, -s * 0.32), Vector2(s * 0.16, s * 0.48)), Color(silhouette.r, silhouette.g, silhouette.b, 0.72))
				draw_circle(center + Vector2(0, -s * 0.34), s * 0.1, Color("#7a3428", 0.82))
			else:
				for fin in range(4):
					var x := tile_rect.position.x + s * (0.18 + float(fin) * 0.17)
					draw_line(Vector2(x, tile_rect.end.y - s * 0.14), Vector2(x + s * 0.08, tile_rect.position.y + s * 0.22), Color(silhouette.r, silhouette.g, silhouette.b, 0.68), 1.0)
			for mote in range(4):
				var mote_pos := tile_rect.position + Vector2(s * (0.18 + fmod(float(position.x + mote) * 0.23, 0.64)), s * (0.22 + fmod(float(position.y + mote) * 0.19, 0.58)))
				draw_rect(Rect2(mote_pos, Vector2(maxf(1.0, s * 0.035), maxf(1.0, s * 0.035))), Color(dust.r, dust.g, dust.b, 0.72))
		"clinical_active_memory":
			var glow: Dictionary = profile.get("tile_glow", {})
			var one: Color = glow.get("one", Color("#58dbff"))
			var zero: Color = glow.get("zero", Color("#56616f"))
			draw_rect(tile_rect.grow(-s * 0.18), Color("#f8fbff", 0.08), false, 1.0)
			for bit in range(3):
				var bit_rect := Rect2(tile_rect.position + Vector2(s * (0.18 + bit * 0.22), s * 0.58), Vector2(s * 0.14, s * 0.14))
				var active := (position.x + position.y + bit) % 2 == 0
				var color := one if active else zero
				draw_rect(bit_rect, Color(color.r, color.g, color.b, 0.55 if active else 0.22))
				draw_rect(bit_rect.grow(1.0), Color(color.r, color.g, color.b, 0.38), false, 1.0)

func _draw_danger_detail(tile: Dictionary, tile_rect: Rect2, position: Vector2i) -> void:
	if not tile.has("wild_encounter"):
		return
	var s := tile_rect.size.x
	var pulse := (sin((Time.get_ticks_msec() / 260.0) + position.x * 0.7 + position.y * 0.3) + 1.0) * 0.5
	var center := tile_rect.get_center() + Vector2(s * 0.26, s * 0.26)
	draw_circle(center, max(1.5, s * (0.055 + pulse * 0.035)), Color("#ff594d", 0.62))
	if float(tile.get("danger", 0.0)) >= 12.0:
		draw_arc(tile_rect.get_center(), s * 0.45, 0.0, TAU, 12, Color("#ff594d", 0.16 + pulse * 0.14), 1.0)

func _draw_landmarks() -> void:
	var rows: Array = world["tiles"]
	for y in rows.size():
		var row: Array = rows[y]
		for x in row.size():
			var tile: Dictionary = row[x]
			if not _is_landmark(tile):
				continue
			var tile_rect := _tile_rect(Vector2i(x, y))
			if not tile_rect.intersects(Rect2(Vector2.ZERO, size).grow(tile_size)):
				continue
			_draw_landmark_marker(tile, tile_rect)

func _draw_landmark_marker(tile: Dictionary, tile_rect: Rect2) -> void:
	var center := tile_rect.get_center()
	var s := tile_rect.size.x
	var cleared := cleared_arenas.has(tile.get("id", ""))
	var marker := get_tile_marker_profile(tile, cleared)
	var marker_kind := str(marker.get("marker_kind", "none"))
	var ring_color: Color = marker.get("ring_color", Color("#f4ead2"))
	var fill_color: Color = marker.get("fill_color", Color("#1a140d"))
	var pulse_alpha := float(marker.get("pulse_alpha", 0.14))
	var pulse := (sin(Time.get_ticks_msec() / 190.0 + center.x * 0.01) + 1.0) * 0.5

	draw_rect(tile_rect.grow(-s * 0.08), Color("#1a140d", 0.42), false, 1.0)
	if marker_kind != "none":
		draw_circle(center, s * (0.3 + pulse * 0.08), Color(ring_color.r, ring_color.g, ring_color.b, pulse_alpha))
		draw_circle(center, s * 0.24, Color(fill_color.r, fill_color.g, fill_color.b, 0.82))
		draw_arc(center, s * (0.37 + pulse * 0.05), 0.0, TAU, 24, Color(ring_color.r, ring_color.g, ring_color.b, 0.78), 2.0)
		draw_rect(tile_rect.grow(-s * 0.16), Color(ring_color.r, ring_color.g, ring_color.b, 0.16), false, 1.0)
		_draw_premium_marker_emblem(get_premium_marker_emblem_profile(marker), center, s, str(marker.get("icon", "")), marker_kind)
	if marker.get("admin_node", false):
		_draw_marker_corners(tile_rect.grow(-s * 0.05), Color("#00ffff", 0.7 + pulse * 0.25))
	if tile.has("mission") and marker_kind != "mission":
		draw_circle(center + Vector2(s * 0.28, -s * 0.28), max(2.0, s * 0.1), Color("#fff05a"))
	if tile.has("encounter") and marker_kind != "arena":
		draw_circle(center + Vector2(-s * 0.28, -s * 0.28), max(2.0, s * 0.1), Color("#ff594d"))
	if marker_kind == "arena":
		draw_rect(Rect2(center + Vector2(-s * 0.34, -s * 0.48), Vector2(s * 0.68, s * 0.13)), ring_color)
		if cleared:
			draw_line(center + Vector2(-s * 0.18, -s * 0.02), center + Vector2(-s * 0.04, s * 0.15), Color("#f4ead2"), 2.0)
			draw_line(center + Vector2(-s * 0.04, s * 0.15), center + Vector2(s * 0.22, -s * 0.18), Color("#f4ead2"), 2.0)
	elif marker_kind == "admin_boss_gate":
		draw_arc(center, s * (0.48 + pulse * 0.08), 0.0, TAU, 32, Color("#ff594d", 0.62 + pulse * 0.18), 2.0)
		draw_line(center + Vector2(-s * 0.34, 0.0), center + Vector2(s * 0.34, 0.0), Color("#ffffff", 0.72), 1.5)
	elif marker_kind == "safe_port":
		draw_arc(center, s * (0.42 + pulse * 0.07), 0.0, TAU, 32, Color("#70ff8f", 0.66 + pulse * 0.18), 2.0)
		draw_line(center + Vector2(-s * 0.2, 0.0), center + Vector2(s * 0.2, 0.0), Color("#70ff8f", 0.86), 1.5)
		draw_line(center + Vector2(0.0, -s * 0.2), center + Vector2(0.0, s * 0.2), Color("#70ff8f", 0.86), 1.5)
	elif marker_kind == "critical_dungeon":
		draw_line(center + Vector2(-s * 0.28, s * 0.28), center + Vector2(s * 0.28, -s * 0.28), Color("#ff594d", 0.72), 1.0)
	elif marker_kind == "jump_pad":
		draw_line(center + Vector2(0.0, s * 0.25), center + Vector2(0.0, -s * 0.28), Color("#ffb347", 0.9), 2.0)
		draw_line(center + Vector2(0.0, -s * 0.28), center + Vector2(-s * 0.13, -s * 0.12), Color("#ffb347", 0.9), 2.0)
		draw_line(center + Vector2(0.0, -s * 0.28), center + Vector2(s * 0.13, -s * 0.12), Color("#ffb347", 0.9), 2.0)
	elif marker_kind == "access_port":
		draw_line(center + Vector2(-s * 0.22, s * 0.18), center + Vector2(s * 0.2, -s * 0.24), Color("#ffd166", 0.9), 2.0)
		draw_circle(center + Vector2(s * 0.24, -s * 0.26), max(1.5, s * 0.055), Color("#ffd166", 0.9))
		draw_rect(Rect2(center + Vector2(-s * 0.3, s * 0.18), Vector2(s * 0.18, s * 0.07)), Color("#ffd166", 0.82))
	if tile.get("id", "") == "testing_fields":
		draw_circle(center, max(3.0, s * 0.18), Color("#f4ead2"))

func _draw_marker_icon(icon: String, center: Vector2, color: Color, marker_kind: String) -> void:
	if icon == "":
		return
	var font := get_theme_default_font()
	var font_size := 11 if icon.length() <= 1 else 8
	if marker_kind == "critical_dungeon":
		font_size = 10
	var text_size := font.get_string_size(icon, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, center - Vector2(text_size.x * 0.5, -text_size.y * 0.32), icon, HORIZONTAL_ALIGNMENT_CENTER, text_size.x, font_size, color)

func _draw_premium_marker_emblem(emblem: Dictionary, center: Vector2, size_scale: float, fallback_icon: String, marker_kind: String) -> void:
	var motif := str(emblem.get("motif", "letter_fallback"))
	var color: Color = emblem.get("color", Color("#f4ead2"))
	var fill: Color = emblem.get("fill_color", Color("#101820"))
	var s := size_scale
	draw_circle(center, s * 0.18, Color(fill.r, fill.g, fill.b, 0.72))
	match motif:
		"sanctuary_core":
			draw_circle(center, s * 0.13, Color("#70ff8f", 0.88))
			draw_line(center + Vector2(-s * 0.16, 0.0), center + Vector2(s * 0.16, 0.0), Color("#f9f4df", 0.86), 1.5)
			draw_line(center + Vector2(0.0, -s * 0.16), center + Vector2(0.0, s * 0.16), Color("#f9f4df", 0.86), 1.5)
			draw_arc(center, s * 0.22, PI * 0.15, PI * 1.85, 24, Color(color.r, color.g, color.b, 0.78), 1.0)
		"shielded_port":
			draw_circle(center, s * 0.16, Color("#0d3024", 0.95))
			draw_arc(center, s * 0.2, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.9), 2.0)
			draw_line(center + Vector2(-s * 0.13, 0.0), center + Vector2(s * 0.13, 0.0), Color("#f9f4df", 0.86), 1.5)
			draw_line(center + Vector2(0.0, -s * 0.13), center + Vector2(0.0, s * 0.13), Color("#f9f4df", 0.86), 1.5)
		"mirror_admin_eye":
			var eye := PackedVector2Array([
				center + Vector2(-s * 0.23, 0.0),
				center + Vector2(-s * 0.1, -s * 0.12),
				center + Vector2(s * 0.1, -s * 0.12),
				center + Vector2(s * 0.23, 0.0),
				center + Vector2(s * 0.1, s * 0.12),
				center + Vector2(-s * 0.1, s * 0.12),
				center + Vector2(-s * 0.23, 0.0),
			])
			draw_polyline(eye, Color("#ffffff", 0.9), 1.6)
			draw_circle(center, s * 0.065, Color("#ff594d", 0.9))
			draw_line(center + Vector2(-s * 0.18, 0.0), center + Vector2(s * 0.18, 0.0), Color(color.r, color.g, color.b, 0.72), 1.0)
		"admin_diamond":
			var diamond := PackedVector2Array([
				center + Vector2(0.0, -s * 0.22),
				center + Vector2(s * 0.2, 0.0),
				center + Vector2(0.0, s * 0.22),
				center + Vector2(-s * 0.2, 0.0),
			])
			draw_polygon(diamond, PackedColorArray([Color(fill, 0.9), Color(fill, 0.9), Color(fill, 0.9), Color(fill, 0.9)]))
			draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color(color.r, color.g, color.b, 0.88), 1.5)
			draw_line(center + Vector2(-s * 0.13, 0.0), center + Vector2(s * 0.13, 0.0), Color("#ff594d", 0.82), 1.5)
		"husk_gate":
			draw_rect(Rect2(center + Vector2(-s * 0.17, -s * 0.18), Vector2(s * 0.34, s * 0.36)), Color(fill.r, fill.g, fill.b, 0.88))
			draw_rect(Rect2(center + Vector2(-s * 0.17, -s * 0.18), Vector2(s * 0.34, s * 0.36)), Color(color.r, color.g, color.b, 0.82), false, 1.5)
			draw_line(center + Vector2(-s * 0.1, 0.0), center + Vector2(s * 0.1, 0.0), Color(color.r, color.g, color.b, 0.7), 1.0)
		"wrench_sigyl":
			draw_line(center + Vector2(-s * 0.17, s * 0.16), center + Vector2(s * 0.15, -s * 0.16), Color(color.r, color.g, color.b, 0.92), 2.0)
			draw_circle(center + Vector2(s * 0.17, -s * 0.18), s * 0.06, Color(color.r, color.g, color.b, 0.86))
			draw_rect(Rect2(center + Vector2(-s * 0.22, s * 0.14), Vector2(s * 0.14, s * 0.05)), Color(color.r, color.g, color.b, 0.78))
		"ascent_chevron":
			for index in range(2):
				var y := s * (0.08 - float(index) * 0.12)
				draw_line(center + Vector2(-s * 0.16, y), center + Vector2(0.0, y - s * 0.15), Color(color.r, color.g, color.b, 0.9), 2.0)
				draw_line(center + Vector2(s * 0.16, y), center + Vector2(0.0, y - s * 0.15), Color(color.r, color.g, color.b, 0.9), 2.0)
		"combat_crown":
			var crown := PackedVector2Array([
				center + Vector2(-s * 0.2, s * 0.14),
				center + Vector2(-s * 0.12, -s * 0.16),
				center + Vector2(0.0, s * 0.02),
				center + Vector2(s * 0.12, -s * 0.16),
				center + Vector2(s * 0.2, s * 0.14),
			])
			draw_polyline(crown, Color(color.r, color.g, color.b, 0.9), 2.0)
			draw_line(center + Vector2(-s * 0.18, s * 0.16), center + Vector2(s * 0.18, s * 0.16), Color(color.r, color.g, color.b, 0.9), 2.0)
		"objective_star":
			for spoke in range(5):
				var angle := float(spoke) / 5.0 * TAU - PI * 0.5
				draw_line(center, center + Vector2(cos(angle), sin(angle)) * s * 0.2, Color(color.r, color.g, color.b, 0.86), 1.5)
		"admin_eye":
			draw_arc(center, s * 0.2, 0.0, PI, 18, Color(color.r, color.g, color.b, 0.86), 1.5)
			draw_arc(center, s * 0.2, PI, TAU, 18, Color(color.r, color.g, color.b, 0.86), 1.5)
			draw_circle(center, s * 0.055, Color("#f9f4df", 0.88))
		"relic_prism":
			var prism := PackedVector2Array([
				center + Vector2(0.0, -s * 0.2),
				center + Vector2(s * 0.17, s * 0.12),
				center + Vector2(-s * 0.17, s * 0.12),
			])
			draw_polyline(prism + PackedVector2Array([prism[0]]), Color(color.r, color.g, color.b, 0.9), 1.5)
		"signal_node":
			draw_circle(center, s * 0.07, Color(color.r, color.g, color.b, 0.9))
			draw_arc(center, s * 0.18, -PI * 0.25, PI * 0.25, 12, Color(color.r, color.g, color.b, 0.72), 1.0)
			draw_arc(center, s * 0.24, -PI * 0.25, PI * 0.25, 12, Color(color.r, color.g, color.b, 0.5), 1.0)
		_:
			_draw_marker_icon(fallback_icon, center, Color("#f9f4df"), marker_kind)

func _draw_marker_corners(rect: Rect2, color: Color) -> void:
	var length := rect.size.x * 0.24
	draw_line(rect.position, rect.position + Vector2(length, 0), color, 1.0)
	draw_line(rect.position, rect.position + Vector2(0, length), color, 1.0)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x - length, rect.position.y), color, 1.0)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.position.y + length), color, 1.0)
	draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x + length, rect.end.y), color, 1.0)
	draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x, rect.end.y - length), color, 1.0)
	draw_line(rect.end, rect.end - Vector2(length, 0), color, 1.0)
	draw_line(rect.end, rect.end - Vector2(0, length), color, 1.0)

func _draw_admin_overlay() -> void:
	if diagnostic_fade <= 0.01:
		return
	var rows: Array = world["tiles"]
	for y in rows.size():
		var row: Array = rows[y]
		for x in row.size():
			var tile: Dictionary = row[x]
			if not tile.get("admin_node", false) and not tile.get("scanline", false):
				continue
			var tile_rect := _tile_rect(Vector2i(x, y))
			if not tile_rect.intersects(Rect2(Vector2.ZERO, size).grow(tile_size)):
				continue
			var pulse := (sin(Time.get_ticks_msec() / 180.0 + x) + 1.0) * 0.5
			draw_rect(tile_rect.grow(2.0), Color("#7afcff", (0.42 + pulse * 0.22) * diagnostic_fade), false, 2.0)
			draw_line(tile_rect.position, tile_rect.end, Color("#7afcff", 0.2 * diagnostic_fade), 1.0)
			draw_line(Vector2(tile_rect.end.x, tile_rect.position.y), Vector2(tile_rect.position.x, tile_rect.end.y), Color("#7afcff", 0.2 * diagnostic_fade), 1.0)

func _draw_admin_search_index() -> void:
	var profile := get_admin_search_index_profile(world)
	if not bool(profile.get("visible", false)):
		return
	var fade := maxf(diagnostic_fade, 0.34 if bool(profile.get("boss_lock", false)) else 0.0)
	if fade <= 0.01:
		return
	var scan_color: Color = profile.get("scan_color", Color("#ffffff"))
	var glass_color: Color = profile.get("glass_color", Color("#d7fbff"))
	var index_color: Color = profile.get("index_color", Color("#ff594d"))
	var pulse := (sin(Time.get_ticks_msec() / 170.0) + 1.0) * 0.5
	for node in profile.get("watched_nodes", []):
		var position: Vector2i = node
		if position.x < 0:
			continue
		var center := _tile_rect(position).get_center()
		var base_radius := tile_size * (0.38 + pulse * 0.08)
		draw_arc(center, base_radius, 0.0, TAU, 26, Color(glass_color.r, glass_color.g, glass_color.b, 0.28 * fade), 1.2)
		draw_line(center + Vector2(-tile_size * 0.24, 0.0), center + Vector2(tile_size * 0.24, 0.0), Color(scan_color.r, scan_color.g, scan_color.b, 0.18 * fade), 1.0)
		draw_line(center + Vector2(0.0, -tile_size * 0.24), center + Vector2(0.0, tile_size * 0.24), Color(scan_color.r, scan_color.g, scan_color.b, 0.18 * fade), 1.0)
	var boss_position: Vector2i = profile.get("boss_node_position", Vector2i(-1, -1))
	if boss_position.x >= 0:
		var font := get_theme_default_font()
		var center := _tile_rect(boss_position).get_center()
		for ring in int(profile.get("ring_count", 3)):
			draw_arc(center, tile_size * (0.72 + float(ring) * 0.22 + pulse * 0.12), 0.0, TAU, 36, Color(scan_color.r, scan_color.g, scan_color.b, (0.22 - float(ring) * 0.035) * fade), 1.5)
		for beam in int(profile.get("beam_count", 8)):
			var angle := float(beam) / float(max(1, int(profile.get("beam_count", 8)))) * TAU + pulse * 0.2
			draw_line(center, center + Vector2(cos(angle), sin(angle)) * tile_size * 0.92, Color(index_color.r, index_color.g, index_color.b, 0.16 * fade), 1.0)
		var label := str(profile.get("boss_label", "ADMIN LOCK"))
		var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 7)
		var pill := Rect2(center + Vector2(-label_size.x * 0.5 - 5.0, tile_size * 0.72), Vector2(label_size.x + 10.0, 12.0))
		draw_rect(pill, Color("#12090c", 0.84 * fade))
		draw_rect(pill, Color(index_color.r, index_color.g, index_color.b, 0.48 * fade), false, 1.0)
		draw_string(font, pill.position + Vector2(5.0, 8.8), label, HORIZONTAL_ALIGNMENT_LEFT, label_size.x, 7, Color("#f9f4df", 0.9 * fade))

func _draw_diagnostic_schematic() -> void:
	if diagnostic_fade <= 0.01:
		return
	var rows: Array = world["tiles"]
	var map_rect := Rect2(map_origin, Vector2(rows[0].size(), rows.size()) * tile_size)
	draw_rect(map_rect, Color("#041a1d", 0.34 * diagnostic_fade))
	var step := tile_size * 2.0
	var x := map_rect.position.x
	while x <= map_rect.end.x:
		draw_line(Vector2(x, map_rect.position.y), Vector2(x, map_rect.end.y), Color("#00ffff", 0.08 * diagnostic_fade), 1.0)
		x += step
	var y := map_rect.position.y
	while y <= map_rect.end.y:
		draw_line(Vector2(map_rect.position.x, y), Vector2(map_rect.end.x, y), Color("#00ffff", 0.08 * diagnostic_fade), 1.0)
		y += step

	for y_index in rows.size():
		var row: Array = rows[y_index]
		for x_index in row.size():
			var tile: Dictionary = row[x_index]
			if not tile.get("walkable", false):
				continue
			if not tile.get("admin_node", false) and not tile.get("scanline", false) and not tile.has("mission"):
				continue
			var center := _tile_rect(Vector2i(x_index, y_index)).get_center()
			var husk_center := _tile_rect(_husk_position()).get_center()
			draw_line(husk_center, center, Color("#00ffff", 0.035 * diagnostic_fade), 1.0)

func _draw_system_pressure() -> void:
	if diagnostic_fade <= 0.01:
		return
	var route_vfx := get_route_vfx_profile(system_pressure)
	var pulse := (sin(Time.get_ticks_msec() / 220.0) + 1.0) * 0.5
	var husk_rect := _tile_rect(_husk_position())
	var husk_center := husk_rect.get_center()
	var husk_color: Color = route_vfx.get("husk_pulse_color", Color("#00ffff"))
	draw_arc(husk_center, tile_size * (0.7 + pulse * 0.7), 0.0, TAU, 32, Color(husk_color.r, husk_color.g, husk_color.b, (0.35 + pulse * 0.25) * diagnostic_fade), 2.0)

	for zone in system_pressure.get("thread_zones", []):
		var position: Vector2i = zone.get("position", Vector2i(-1, -1))
		if position.x < 0:
			continue
		var intensity := float(zone.get("intensity", 0.0))
		if intensity <= 0.01:
			continue
		var center := _tile_rect(position).get_center()
		var radius := tile_size * (0.65 + intensity * 1.1 + pulse * 0.35)
		var thread_color: Color = route_vfx.get("thread_ring_color", Color("#ff594d"))
		draw_circle(center, radius, Color(thread_color.r, thread_color.g, thread_color.b, (0.08 + intensity * 0.16) * diagnostic_fade))
		draw_arc(center, radius, 0.0, TAU, 28, Color(thread_color.r, thread_color.g, thread_color.b, (0.45 + pulse * 0.25) * diagnostic_fade), 2.0)

	var deletion_path: Array = system_pressure.get("deletion_path", [])
	if deletion_path.size() >= 2:
		var points := PackedVector2Array()
		for point in deletion_path:
			points.append(_tile_rect(point).get_center())
		var path_color: Color = route_vfx.get("path_color", Color("#ffffff"))
		draw_polyline(points, Color(path_color.r, path_color.g, path_color.b, (0.58 + pulse * 0.22) * diagnostic_fade), 3.0)

func _draw_purge_overlay() -> void:
	var profile := get_purge_overlay_profile(system_pressure)
	if not profile.get("purge_active", false):
		return
	var rows: Array = world["tiles"]
	var map_rect := Rect2(map_origin, Vector2(rows[0].size(), rows.size()) * tile_size)
	var purge_color: Color = profile.get("purge_color", Color("#ff453a"))
	var safe_color: Color = profile.get("safe_zone_color", Color("#70ff8f"))
	var pulse := (sin(Time.get_ticks_msec() / 210.0) + 1.0) * 0.5
	var alpha := float(profile.get("sweep_alpha", 0.34))
	draw_rect(map_rect, Color(purge_color.r, purge_color.g, purge_color.b, alpha * 0.12))
	var origin: Vector2i = profile.get("purge_origin", Vector2i(24, 4))
	var origin_center := _tile_rect(origin).get_center()
	draw_arc(origin_center, tile_size * (1.6 + pulse * 0.8), 0.0, TAU, 36, Color(purge_color.r, purge_color.g, purge_color.b, alpha), 2.0)
	for i in range(4):
		var angle := pulse * TAU + float(i) * TAU * 0.25
		draw_line(origin_center, origin_center + Vector2(cos(angle), sin(angle)) * tile_size * 5.0, Color(purge_color.r, purge_color.g, purge_color.b, alpha * 0.46), 1.0)
	for safe_position in profile.get("safe_zones", []):
		var safe_center := _tile_rect(safe_position).get_center()
		draw_circle(safe_center, tile_size * (0.62 + pulse * 0.12), Color(safe_color.r, safe_color.g, safe_color.b, 0.18 + pulse * 0.08))
		draw_arc(safe_center, tile_size * (0.82 + pulse * 0.18), 0.0, TAU, 32, Color(safe_color.r, safe_color.g, safe_color.b, 0.82), 2.0)
		draw_rect(_tile_rect(safe_position).grow(-tile_size * 0.08), Color(safe_color.r, safe_color.g, safe_color.b, 0.22), false, 1.0)

func _draw_tundra_whiteout_front() -> void:
	var profile := get_tundra_whiteout_front_profile(system_pressure)
	if not bool(profile.get("visible", false)):
		return
	var pressure_level := float(profile.get("pressure_level", 0.0))
	if pressure_level <= 0.01:
		return
	var white: Color = profile.get("whiteout_color", Color("#f4fbff"))
	var blue: Color = profile.get("coolant_blue", Color("#8fe6ff"))
	var pulse := (sin(Time.get_ticks_msec() / 190.0) + 1.0) * 0.5
	for point in profile.get("front_tiles", []):
		var position: Vector2i = point
		if position.x < 0:
			continue
		var rect := _tile_rect(position)
		if not rect.intersects(Rect2(Vector2.ZERO, size).grow(tile_size)):
			continue
		var alpha := 0.05 + pressure_level * 0.13 + pulse * 0.035
		draw_rect(rect.grow(tile_size * 0.05), Color(white.r, white.g, white.b, alpha))
		draw_rect(rect.grow(-tile_size * 0.18), Color(blue.r, blue.g, blue.b, alpha * 0.45), false, 1.0)
	var grain_density: int = int(profile.get("grain_density", 18))
	var tiles: Array = profile.get("front_tiles", [])
	for index in grain_density:
		var tile_index: int = index % max(1, int(profile.get("front_tile_count", 1)))
		if tile_index >= tiles.size():
			continue
		var tile_position: Vector2i = tiles[tile_index]
		var rect := _tile_rect(tile_position)
		var jitter := Vector2(fposmod(float(index * 37) + Time.get_ticks_msec() / 21.0, tile_size), fposmod(float(index * 19) + Time.get_ticks_msec() / 31.0, tile_size))
		draw_rect(Rect2(rect.position + jitter, Vector2(1.6, 1.6)), Color(white.r, white.g, white.b, 0.24 + pressure_level * 0.28))
	for safe_position in profile.get("safe_zones", []):
		var safe_center := _tile_rect(safe_position).get_center()
		var safe_color: Color = profile.get("safe_zone_color", Color("#70ff8f"))
		draw_circle(safe_center, tile_size * (0.34 + pulse * 0.08), Color(safe_color.r, safe_color.g, safe_color.b, 0.18))
		draw_arc(safe_center, tile_size * (0.5 + pulse * 0.1), 0.0, TAU, 24, Color(safe_color.r, safe_color.g, safe_color.b, 0.74), 1.4)

func _draw_diagnostic_sweep() -> void:
	var profile := get_diagnostic_sweep_profile(system_pressure)
	if not profile.get("active", false):
		return
	var layer_alpha := _premium_layer_alpha("diagnostic_sweep")
	var rows: Array = world["tiles"]
	if rows.is_empty():
		return
	var map_rect := Rect2(map_origin, Vector2(rows[0].size(), rows.size()) * tile_size)
	var sweep_color: Color = profile.get("sweep_color", Color("#00ffff"))
	var alpha := float(profile.get("sweep_alpha", 0.12))
	var band_width := float(profile.get("band_width", 0.1)) * map_rect.size.x
	var sweep_count := int(profile.get("sweep_count", 2))
	var phase := fmod(Time.get_ticks_msec() / 1800.0, 1.0)
	for index in range(sweep_count):
		var t := fposmod(phase + float(index) / maxf(float(sweep_count), 1.0), 1.0)
		var x := map_rect.position.x - band_width + t * (map_rect.size.x + band_width * 2.0)
		var points := PackedVector2Array([
			Vector2(x, map_rect.position.y),
			Vector2(x + band_width, map_rect.position.y),
			Vector2(x + band_width * 0.32, map_rect.end.y),
			Vector2(x - band_width * 0.68, map_rect.end.y),
		])
		draw_polygon(points, PackedColorArray([
			Color(sweep_color.r, sweep_color.g, sweep_color.b, 0.0),
			Color(sweep_color.r, sweep_color.g, sweep_color.b, alpha * layer_alpha),
			Color(sweep_color.r, sweep_color.g, sweep_color.b, alpha * 0.55 * layer_alpha),
			Color(sweep_color.r, sweep_color.g, sweep_color.b, 0.0),
		]))
	for beacon in profile.get("safe_beacons", []):
		var position: Vector2i = beacon.get("position", Vector2i(-1, -1))
		if position.x < 0:
			continue
		var center := _tile_rect(position).get_center()
		var color: Color = beacon.get("color", Color("#70ff8f"))
		var height := tile_size * float(beacon.get("height", 1.0))
		draw_line(center + Vector2(0.0, height * 0.5), center - Vector2(0.0, height), Color(color.r, color.g, color.b, (0.42 + 0.2 * sin(Time.get_ticks_msec() / 140.0)) * layer_alpha), 2.0)
		draw_circle(center - Vector2(0.0, height), maxf(2.0, tile_size * 0.07), Color(color.r, color.g, color.b, 0.78 * layer_alpha))

func _draw_region_labels() -> void:
	var font := get_theme_default_font()
	for label_profile in get_region_label_profiles():
		var tile_position: Vector2i = label_profile.get("position", Vector2i(-1, -1))
		if tile_position.x < 0:
			continue
		var anchor := _tile_rect(tile_position).get_center()
		if not Rect2(Vector2.ZERO, size).grow(60.0).has_point(anchor):
			continue
		var plate := get_premium_region_plate_profile(label_profile)
		var text := str(plate.get("label", ""))
		var code := str(plate.get("system_code", ""))
		var font_size := int(plate.get("font_size", 11))
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var code_size := font.get_string_size(code, HORIZONTAL_ALIGNMENT_LEFT, -1, int(plate.get("code_font_size", 7)))
		var backing := Rect2(anchor + Vector2(-maxf(text_size.x, code_size.x) * 0.5 - 12.0, -tile_size * 1.04), Vector2(maxf(text_size.x, code_size.x) + 24.0, 27.0))
		var backing_color: Color = plate.get("backing_color", Color("#05111a"))
		var text_color: Color = plate.get("plate_color", Color("#f4ead2"))
		_draw_region_plate(backing, anchor, plate)
		draw_string(font, backing.position + Vector2(12.0, 13.0), text, HORIZONTAL_ALIGNMENT_LEFT, backing.size.x - 24.0, font_size, Color(text_color.r, text_color.g, text_color.b, 0.94))
		draw_string(font, backing.position + Vector2(12.0, 23.0), code, HORIZONTAL_ALIGNMENT_LEFT, backing.size.x - 24.0, int(plate.get("code_font_size", 7)), Color(backing_color.r + 0.45, backing_color.g + 0.45, backing_color.b + 0.45, 0.72))

func _draw_partition_routes() -> void:
	var route := get_partition_route_profile("southern_partition")
	if route.is_empty():
		return
	var map_points: Array = route.get("points", [])
	if map_points.size() < 2:
		return
	var pulse := (sin(Time.get_ticks_msec() / 260.0) + 1.0) * 0.5
	var node_color: Color = route.get("node_color", Color("#ffb347"))
	var line_alpha := float(route.get("line_alpha", 0.34))
	var points := PackedVector2Array()
	for map_point in map_points:
		points.append(_tile_rect(map_point).get_center())
	for segment in get_route_segment_profiles("southern_partition", world):
		var start: Vector2i = segment.get("start", Vector2i(-1, -1))
		var target: Vector2i = segment.get("target", Vector2i(-1, -1))
		if start.x < 0 or target.x < 0:
			continue
		var line_color: Color = segment.get("line_color", Color("#70ff8f"))
		draw_line(_tile_rect(start).get_center(), _tile_rect(target).get_center(), Color(line_color.r, line_color.g, line_color.b, line_alpha + pulse * 0.12), 2.0)
	for point in points:
		draw_circle(point, tile_size * (0.06 + pulse * 0.025), Color(node_color.r, node_color.g, node_color.b, 0.74))

func _draw_tundra_route_rail() -> void:
	var rail := get_tundra_route_rail_profile(world)
	if not bool(rail.get("visible", false)):
		return
	var pulse := (sin(Time.get_ticks_msec() / 210.0) + 1.0) * 0.5
	var rail_width := float(rail.get("rail_width", 4.0))
	var screen_nodes: Array[Vector2] = []
	for node in rail.get("nodes", []):
		var node_position: Vector2i = node
		if node_position.x >= 0:
			screen_nodes.append(_tile_rect(node_position).get_center())
	for segment in rail.get("segments", []):
		var start: Vector2i = segment.get("start", Vector2i(-1, -1))
		var target: Vector2i = segment.get("target", Vector2i(-1, -1))
		if start.x < 0 or target.x < 0:
			continue
		var color: Color = segment.get("line_color", Color("#58dbff"))
		var weight := float(segment.get("pulse_weight", 0.42))
		var start_point := _tile_rect(start).get_center()
		var target_point := _tile_rect(target).get_center()
		draw_line(start_point, target_point, Color("#031019", 0.72), rail_width + 3.0)
		draw_line(start_point, target_point, Color(color.r, color.g, color.b, 0.28 + pulse * weight * 0.22), rail_width)
		draw_line(start_point, target_point, Color("#ffffff", 0.12 + pulse * weight * 0.08), 1.0)
		if str(segment.get("segment_kind", "")) == "boss_gate":
			var midpoint := start_point.lerp(target_point, 0.5)
			draw_arc(midpoint, tile_size * (0.22 + pulse * 0.05), 0.0, TAU, 20, Color(color.r, color.g, color.b, 0.78), 1.8)
	for node in rail.get("nodes", []):
		var position: Vector2i = node
		if position.x < 0:
			continue
		var center := _tile_rect(position).get_center()
		draw_circle(center, tile_size * (0.12 + pulse * 0.025), Color("#06141f", 0.8))
		draw_arc(center, tile_size * (0.15 + pulse * 0.035), 0.0, TAU, 20, Color("#58dbff", 0.52), 1.4)
	if screen_nodes.size() >= 2:
		var route_length := _polyline_length(screen_nodes)
		var packet_count := int(rail.get("packet_count", 5))
		var packet_color: Color = rail.get("packet_color", Color("#ffffff"))
		var time_phase := fmod(Time.get_ticks_msec() / 1100.0, 1.0)
		for packet_index in packet_count:
			var packet_distance := fmod((time_phase + float(packet_index) / float(packet_count)) * route_length, route_length)
			var packet_point := _point_on_polyline(screen_nodes, packet_distance)
			draw_circle(packet_point, tile_size * 0.055, Color(packet_color.r, packet_color.g, packet_color.b, 0.74))
			draw_circle(packet_point, tile_size * 0.11, Color("#58dbff", 0.12))
	if bool(rail.get("boss_lock_visible", false)):
		var boss_position: Vector2i = rail.get("boss_lock_position", Vector2i(-1, -1))
		if boss_position.x >= 0:
			var font := get_theme_default_font()
			var center := _tile_rect(boss_position).get_center()
			var label := str(rail.get("boss_lock_label", "BOSS LOCK"))
			var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 8)
			var pill := Rect2(center + Vector2(-label_size.x * 0.5 - 6.0, -tile_size * 0.92), Vector2(label_size.x + 12.0, 14.0))
			draw_rect(pill, Color("#24080a", 0.9))
			draw_rect(pill, Color("#ff594d", 0.68), false, 1.0)
			draw_string(font, pill.position + Vector2(6.0, 10.0), label, HORIZONTAL_ALIGNMENT_LEFT, label_size.x, 8, Color("#f9f4df", 0.94))

func _draw_route_loadout_warnings() -> void:
	if not system_pressure.has("available_gear"):
		return
	var warnings := get_route_loadout_warning_profiles("southern_partition", world, system_pressure.get("available_gear", []))
	if warnings.is_empty():
		return
	var font := get_theme_default_font()
	var pulse := (sin(Time.get_ticks_msec() / 160.0) + 1.0) * 0.5
	for warning in warnings:
		var warning_position: Vector2i = warning.get("position", Vector2i(-1, -1))
		if warning_position.x < 0:
			continue
		var rect := _tile_rect(warning_position)
		if not rect.intersects(Rect2(Vector2.ZERO, size).grow(tile_size)):
			continue
		var center := rect.get_center()
		var color: Color = warning.get("warning_color", Color("#ff594d"))
		draw_circle(center, tile_size * (0.42 + pulse * 0.12), Color(color.r, color.g, color.b, 0.16 + pulse * 0.08))
		draw_arc(center, tile_size * (0.52 + pulse * 0.16), 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.78), 2.0)
		var text := "!"
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
		draw_string(font, center - Vector2(text_size.x * 0.5, -text_size.y * 0.28), text, HORIZONTAL_ALIGNMENT_CENTER, text_size.x, 11, Color("#f9f4df"))

func _draw_selected_route_preview() -> void:
	var preview := get_selected_route_preview_profile(world, system_pressure.get("available_gear", []))
	if not preview.get("draw_route", false):
		return
	var points: Array = preview.get("points", [])
	if points.size() < 2:
		return
	var route_color: Color = preview.get("route_color", Color("#70ff8f"))
	var pulse := (sin(Time.get_ticks_msec() / 140.0) + 1.0) * 0.5
	var screen_points := PackedVector2Array()
	for point in points:
		screen_points.append(_tile_rect(point).get_center())
	if screen_points.size() >= 2:
		draw_polyline(screen_points, Color(route_color.r, route_color.g, route_color.b, 0.28 + pulse * 0.14), 4.0)
		draw_polyline(screen_points, Color("#05111a", 0.46), 1.0)
	for index in range(1, screen_points.size()):
		var point := screen_points[index]
		var radius := tile_size * (0.055 + pulse * 0.025)
		draw_circle(point, radius, Color(route_color.r, route_color.g, route_color.b, 0.82))
	var destination: Vector2i = points[points.size() - 1]
	var destination_rect := _tile_rect(destination)
	var label := "%d STEP" % int(preview.get("step_count", 0))
	if int(preview.get("risk_count", 0)) > 0:
		label += " / %d RISK" % int(preview.get("risk_count", 0))
	if bool(preview.get("blocked_by_command", false)):
		label += " / BLOCKED"
	var font := get_theme_default_font()
	var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
	var label_rect := Rect2(destination_rect.position + Vector2(0.0, -16.0), Vector2(label_size.x + 9.0, 13.0))
	draw_rect(label_rect, Color("#05111a", 0.88))
	draw_rect(label_rect, Color(route_color.r, route_color.g, route_color.b, 0.42), false, 1.0)
	draw_string(font, label_rect.position + Vector2(4.0, 9.5), label, HORIZONTAL_ALIGNMENT_LEFT, label_size.x, 8, Color("#f9f4df", 0.92))

func _draw_selected_route_flow() -> void:
	var flow := get_selected_route_flow_profile(world, system_pressure.get("available_gear", []))
	if not flow.get("draw_flow", false):
		return
	var points: Array = flow.get("points", [])
	if points.size() < 2:
		return
	var screen_points: Array[Vector2] = []
	for point in points:
		screen_points.append(_tile_rect(point).get_center())
	var color: Color = flow.get("packet_color", Color("#70ff8f"))
	var speed := float(flow.get("speed", 0.6))
	var time_phase := fmod(Time.get_ticks_msec() / 1000.0 * speed, 1.0)
	var route_length := _polyline_length(screen_points)
	if route_length <= 0.001:
		return
	for packet in flow.get("packets", []):
		var phase := fposmod(float(packet.get("phase", 0.0)) + time_phase, 1.0)
		var point := _point_on_polyline(screen_points, phase * route_length)
		var radius := tile_size * float(packet.get("size", 0.06))
		var alpha := float(packet.get("alpha", 0.72)) * _premium_layer_alpha("selected_action")
		draw_circle(point, maxf(1.5, radius), Color(color.r, color.g, color.b, alpha))
		draw_circle(point, maxf(0.75, radius * 0.42), Color("#f9f4df", alpha * 0.7))

func _draw_selected_hologram() -> void:
	var hologram := get_selected_hologram_profile(world, system_pressure.get("available_gear", []))
	if not hologram.get("selected", false):
		return
	var position: Vector2i = hologram.get("position", Vector2i(-1, -1))
	if position.x < 0:
		return
	var rect := _tile_rect(position)
	if not rect.intersects(Rect2(Vector2.ZERO, size).grow(tile_size * 2.0)):
		return
	var center := rect.get_center()
	var color: Color = hologram.get("reticle_color", Color("#70ff8f"))
	var tick_count := int(hologram.get("tick_count", 8))
	var pulse := (sin(Time.get_ticks_msec() / 120.0) + 1.0) * 0.5
	var radius := tile_size * float(hologram.get("ring_radius", 0.72))
	var alpha := _premium_layer_alpha("selected_action")
	draw_arc(center, radius + pulse * tile_size * 0.04, -PI * 0.1, PI * 1.35, 36, Color(color.r, color.g, color.b, 0.72 * alpha), 2.0)
	draw_arc(center, radius * 0.72, PI * 0.2, PI * 1.8, 28, Color(color.r, color.g, color.b, 0.42 * alpha), 1.0)
	for tick in range(tick_count):
		var angle := float(tick) / float(maxi(tick_count, 1)) * TAU + pulse * 0.08
		var inner := center + Vector2(cos(angle), sin(angle)) * radius * 0.82
		var outer := center + Vector2(cos(angle), sin(angle)) * radius
		draw_line(inner, outer, Color(color.r, color.g, color.b, 0.64 * alpha), 1.0)
	if str(hologram.get("reticle_state", "")) == "locked":
		draw_line(center + Vector2(-radius * 0.26, -radius * 0.26), center + Vector2(radius * 0.26, radius * 0.26), Color("#ff594d", 0.88 * alpha), 2.0)
		draw_line(center + Vector2(radius * 0.26, -radius * 0.26), center + Vector2(-radius * 0.26, radius * 0.26), Color("#ff594d", 0.88 * alpha), 2.0)
	var font := get_theme_default_font()
	var label := "%s / %s" % [str(hologram.get("reticle_state", "")).to_upper(), str(hologram.get("status_label", ""))]
	var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
	var label_rect := Rect2(center + Vector2(-label_size.x * 0.5 - 5.0, -radius - 18.0), Vector2(label_size.x + 10.0, 14.0))
	draw_rect(label_rect, Color("#05111a", 0.82))
	draw_rect(label_rect, Color(color.r, color.g, color.b, 0.42 * alpha), false, 1.0)
	draw_string(font, label_rect.position + Vector2(5.0, 10.0), label, HORIZONTAL_ALIGNMENT_LEFT, label_size.x, 8, Color("#f9f4df", 0.9 * alpha))

func _draw_selected_action_rays() -> void:
	var ray := get_selected_action_ray_profile(world, system_pressure.get("available_gear", []))
	if not ray.get("selected", false):
		return
	var map_position: Vector2i = ray.get("position", Vector2i(-1, -1))
	if map_position.x < 0:
		return
	var rect := _tile_rect(map_position)
	if not rect.intersects(Rect2(Vector2.ZERO, size).grow(tile_size * 2.0)):
		return
	var color: Color = ray.get("beam_color", Color("#70ff8f"))
	var pulse := (sin(Time.get_ticks_msec() / 115.0) + 1.0) * 0.5
	var center := rect.get_center()
	var ring_count := int(ray.get("ring_count", 2))
	var spoke_count := int(ray.get("spoke_count", 4))
	var alpha := float(ray.get("beam_alpha", 0.38))
	var player_position: Vector2i = ray.get("player_position", Vector2i(-1, -1))
	if player_position.x >= 0 and player_position != map_position:
		var player_center := _tile_rect(player_position).get_center()
		var delta := center - player_center
		var distance := delta.length()
		if distance > 0.001:
			var direction := delta / distance
			var normal := Vector2(-direction.y, direction.x)
			for lane: float in [-1.0, 1.0]:
				var offset: Vector2 = normal * lane * tile_size * 0.08
				draw_line(player_center + offset, center + offset, Color(color.r, color.g, color.b, alpha * 0.38), 1.0)
			var dash_count := clampi(roundi(distance / maxf(tile_size * 0.7, 1.0)), 2, 18)
			for dash in range(dash_count):
				var t := (float(dash) + pulse) / float(dash_count)
				var dash_center := player_center.lerp(center, t)
				draw_circle(dash_center, maxf(1.4, tile_size * 0.035), Color(color.r, color.g, color.b, alpha * 0.9))
	for i in range(ring_count):
		var ring_radius := tile_size * (0.58 + float(i) * 0.16 + pulse * 0.08)
		var ring_alpha := alpha * (0.78 - float(i) * 0.1)
		draw_arc(center, ring_radius, 0.0, TAU, 36, Color(color.r, color.g, color.b, ring_alpha), 2.0)
	for spoke in range(spoke_count):
		var angle := float(spoke) / float(maxi(spoke_count, 1)) * TAU + pulse * 0.22
		var inner := center + Vector2(cos(angle), sin(angle)) * tile_size * 0.34
		var outer := center + Vector2(cos(angle), sin(angle)) * tile_size * (0.78 + pulse * 0.08)
		draw_line(inner, outer, Color(color.r, color.g, color.b, alpha * 0.58), 1.0)
	if str(ray.get("action_kind", "")) == "jump_pad":
		for stream in range(5):
			var x_offset := (float(stream) - 2.0) * tile_size * 0.11
			var start := center + Vector2(x_offset, tile_size * 0.36)
			var end := center + Vector2(x_offset * 0.45, -tile_size * (0.82 + pulse * 0.22))
			draw_line(start, end, Color(color.r, color.g, color.b, alpha * 0.52), 1.0)
	if not bool(ray.get("can_execute", true)):
		draw_line(rect.position + Vector2(tile_size * 0.16, tile_size * 0.16), rect.end - Vector2(tile_size * 0.16, tile_size * 0.16), Color("#ff594d", 0.86), 2.0)
		draw_line(Vector2(rect.end.x - tile_size * 0.16, rect.position.y + tile_size * 0.16), Vector2(rect.position.x + tile_size * 0.16, rect.end.y - tile_size * 0.16), Color("#ff594d", 0.86), 2.0)

func _draw_selected_tile_focus() -> void:
	var focus := get_selected_tile_focus_profile(world, system_pressure.get("available_gear", []))
	if not focus.get("selected", false):
		return
	var map_position: Vector2i = focus.get("position", Vector2i(-1, -1))
	if map_position.x < 0:
		return
	var rect := _tile_rect(map_position)
	if not rect.intersects(Rect2(Vector2.ZERO, size).grow(tile_size)):
		return
	var center := rect.get_center()
	var focus_color: Color = focus.get("focus_color", Color("#f4ead2"))
	var pulse := (sin(Time.get_ticks_msec() / 150.0) + 1.0) * 0.5
	draw_rect(rect.grow(3.0 + pulse * 2.0), Color(focus_color.r, focus_color.g, focus_color.b, 0.22), false, 2.0)
	draw_arc(center, tile_size * (0.66 + pulse * 0.12), 0.0, TAU, 30, Color(focus_color.r, focus_color.g, focus_color.b, 0.82), 2.0)
	var font := get_theme_default_font()
	var status := str(focus.get("action_status", ""))
	if status == "":
		return
	var label_size := font.get_string_size(status, HORIZONTAL_ALIGNMENT_CENTER, -1, 8)
	var pill := Rect2(center + Vector2(-label_size.x * 0.5 - 5.0, tile_size * 0.46), Vector2(label_size.x + 10.0, 13.0))
	draw_rect(pill, Color("#05111a", 0.86))
	draw_rect(pill, Color(focus_color.r, focus_color.g, focus_color.b, 0.44), false, 1.0)
	draw_string(font, pill.position + Vector2(5.0, 9.5), status, HORIZONTAL_ALIGNMENT_LEFT, label_size.x, 8, Color("#f9f4df", 0.92))

func _draw_objective_route() -> void:
	if objective_target.x < 0:
		return
	var route := get_objective_route_profile(Vector2i(roundi(world["player"]["position"].x), roundi(world["player"]["position"].y)), objective_target)
	if not route.get("draw_route", false):
		return
	var pulse := (sin(Time.get_ticks_msec() / 170.0) + 1.0) * 0.5
	var route_color: Color = route.get("route_color", Color("#fff05a"))
	var waypoint_color: Color = route.get("waypoint_color", Color("#3157b7"))
	var points := PackedVector2Array()
	for point in route.get("points", []):
		points.append(_tile_rect(point).get_center())
	if points.size() < 2:
		return
	var alpha := float(route.get("route_alpha", 0.62))
	draw_polyline(points, Color(route_color.r, route_color.g, route_color.b, alpha), 2.0)
	for point_index in points.size():
		var point := points[point_index]
		draw_circle(point, tile_size * (0.1 + pulse * 0.035), Color(waypoint_color.r, waypoint_color.g, waypoint_color.b, 0.82))
		if point_index > 0:
			draw_circle(point, tile_size * (0.045 + pulse * 0.02), Color(route_color.r, route_color.g, route_color.b, 0.9))

func _draw_poi_alerts() -> void:
	var alerts: Array = system_pressure.get("poi_alerts", [])
	if alerts.is_empty():
		return
	var font := get_theme_default_font()
	var pulse := (sin(Time.get_ticks_msec() / 170.0) + 1.0) * 0.5
	var fade := maxf(diagnostic_fade, 0.38)
	for alert in alerts:
		var position: Vector2i = alert.get("position", Vector2i(-1, -1))
		if position.x < 0:
			continue
		var rect := _tile_rect(position)
		if not rect.intersects(Rect2(Vector2.ZERO, size).grow(tile_size)):
			continue
		var center := rect.get_center()
		var severity := float(alert.get("severity", 0.5))
		var kind: String = alert.get("kind", "sidequest")
		var color: Color = alert.get("color", _poi_color(kind, severity))
		var radius := tile_size * (0.42 + severity * 0.28 + pulse * 0.16)
		draw_circle(center, radius, Color(color, (0.11 + severity * 0.06) * fade))
		draw_arc(center, radius + 2.0, 0.0, TAU, 22, Color(color, (0.48 + pulse * 0.24) * fade), 2.0)
		var text: String = str(alert.get("icon", _poi_icon(kind)))
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
		draw_string(font, center - Vector2(text_size.x * 0.5, -text_size.y * 0.3), text, HORIZONTAL_ALIGNMENT_CENTER, text_size.x, 14, Color("#f9f4df", fade))

	var waypoint: Vector2i = system_pressure.get("custom_waypoint", Vector2i(-1, -1))
	if waypoint.x >= 0:
		var target := _tile_rect(waypoint).get_center()
		draw_arc(target, tile_size * (0.9 + pulse * 0.25), 0.0, TAU, 28, Color("#fff05a", 0.85), 3.0)

func _draw_map_legend() -> void:
	var entries := get_map_legend_entries()
	var font := get_theme_default_font()
	var width := 126.0
	var row_height := 18.0
	var height := row_height * entries.size() + 14.0
	var panel := Rect2(Vector2(size.x - width - 12.0, 12.0), Vector2(width, height))
	_draw_premium_panel(panel, get_premium_panel_style_profile("legend", Color("#7afcff")))
	for i in entries.size():
		var entry: Dictionary = entries[i]
		var y := panel.position.y + 9.0 + i * row_height
		var color: Color = entry.get("color", Color("#f4ead2"))
		var center := Vector2(panel.position.x + 13.0, y + 5.0)
		draw_circle(center, 5.2, Color(color.r, color.g, color.b, 0.22))
		draw_arc(center, 6.8, 0.0, TAU, 16, Color(color.r, color.g, color.b, 0.82), 1.0)
		var icon := str(entry.get("icon", ""))
		var icon_size := font.get_string_size(icon, HORIZONTAL_ALIGNMENT_CENTER, -1, 8)
		draw_string(font, center - Vector2(icon_size.x * 0.5, -icon_size.y * 0.26), icon, HORIZONTAL_ALIGNMENT_CENTER, icon_size.x, 8, Color("#f9f4df"))
		draw_string(font, Vector2(panel.position.x + 25.0, y + 10.0), str(entry.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, width - 34.0, 9, Color("#dce8e2", 0.9))

func _draw_status_panel() -> void:
	var profile := get_map_status_panel_profile(system_pressure)
	var font := get_theme_default_font()
	var panel := Rect2(Vector2(12.0, size.y - 56.0), Vector2(176.0, 42.0))
	var panel_color: Color = profile.get("panel_color", Color("#102719"))
	var accent: Color = profile.get("accent_color", Color("#70ff8f"))
	_draw_premium_panel(panel, get_premium_panel_style_profile("status", accent), panel_color)
	draw_string(font, panel.position + Vector2(18.0, 19.0), str(profile.get("status_label", "")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 28.0, 11, Color("#f9f4df", 0.94))
	draw_string(font, panel.position + Vector2(18.0, 34.0), str(profile.get("detail_label", "")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 28.0, 9, Color(accent.r, accent.g, accent.b, 0.9))

func _draw_tundra_hazard_readout() -> void:
	var profile := get_tundra_hazard_readout_profile(system_pressure)
	if not bool(profile.get("visible", false)):
		return
	var font := get_theme_default_font()
	var accent: Color = profile.get("accent_color", Color("#8fe6ff"))
	var warning: Color = profile.get("warning_color", accent)
	var panel := Rect2(Vector2(198.0, size.y - 56.0), Vector2(172.0, 42.0))
	_draw_premium_panel(panel, get_premium_panel_style_profile("status", accent), Color("#07131a"))
	draw_string(font, panel.position + Vector2(18.0, 19.0), str(profile.get("status_label", "")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 28.0, 10, Color("#f9f4df", 0.94))
	var bar := Rect2(panel.position + Vector2(18.0, 25.0), Vector2(panel.size.x - 36.0, 4.0))
	var pressure_width := bar.size.x * clampf(float(profile.get("pressure_level", 0.0)), 0.0, 1.0)
	draw_rect(bar, Color("#0b1820", 0.86))
	draw_rect(Rect2(bar.position, Vector2(pressure_width, bar.size.y)), Color(warning.r, warning.g, warning.b, 0.72))
	draw_string(font, panel.position + Vector2(18.0, 38.0), str(profile.get("detail_label", "")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 28.0, 8, Color(accent.r, accent.g, accent.b, 0.84))

func _draw_route_forecast_panel() -> void:
	if world.is_empty():
		return
	var forecast := get_route_forecast_profile("southern_partition", world)
	var readiness := {}
	if system_pressure.has("available_gear"):
		readiness = get_route_readiness_profile("southern_partition", world, system_pressure.get("available_gear", []))
	var font := get_theme_default_font()
	var panel_size := Vector2(216.0, 70.0 if not readiness.is_empty() else 58.0)
	var panel := Rect2(Vector2(size.x - panel_size.x - 12.0, size.y - panel_size.y - 12.0), panel_size)
	var accent: Color = readiness.get("accent_color", forecast.get("forecast_color", Color("#70ff8f"))) if not readiness.is_empty() else forecast.get("forecast_color", Color("#70ff8f"))
	_draw_premium_panel(panel, get_premium_panel_style_profile("forecast", accent))
	draw_string(font, panel.position + Vector2(10.0, 17.0), str(forecast.get("label", "Route Forecast")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 11, Color("#f9f4df", 0.94))
	var summary := "HZD %d  DNG %d  JP %d  ADM %d" % [
		int(forecast.get("hazard_count", 0)),
		int(forecast.get("dungeon_count", 0)),
		int(forecast.get("jump_pad_count", 0)),
		int(forecast.get("admin_node_count", 0)),
	]
	draw_string(font, panel.position + Vector2(10.0, 34.0), summary, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 9, Color(accent.r, accent.g, accent.b, 0.92))
	var gear: Array = forecast.get("recommended_gear", [])
	var gear_text := "Gear: " + ", ".join(gear.slice(0, 3))
	draw_string(font, panel.position + Vector2(10.0, 50.0), gear_text, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 8, Color("#dce8e2", 0.82))
	if not readiness.is_empty():
		var readiness_text := str(readiness.get("status_label", ""))
		if int(readiness.get("blocker_count", 0)) > 0:
			readiness_text += " / " + ", ".join(readiness.get("blocker_gear", []))
		draw_string(font, panel.position + Vector2(10.0, 64.0), readiness_text, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 8, Color("#f9f4df", 0.9))

func _draw_tundra_storyboard_panel() -> void:
	var profile := get_tundra_storyboard_panel_profile(world)
	if not bool(profile.get("visible", false)):
		return
	var font := get_theme_default_font()
	var panel_size := Vector2(216.0, float(profile.get("panel_height", 92.0)))
	var panel := Rect2(Vector2(size.x - panel_size.x - 12.0, size.y - panel_size.y - 88.0), panel_size)
	var line_color: Color = profile.get("line_color", Color("#58dbff"))
	var boss_color: Color = profile.get("boss_color", Color("#ff594d"))
	var safe_color: Color = profile.get("safe_color", Color("#70ff8f"))
	_draw_premium_panel(panel, get_premium_panel_style_profile("forecast", line_color), Color("#04101b"))
	draw_string(font, panel.position + Vector2(10.0, 17.0), str(profile.get("title", "ACT ROUTE")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 10, Color("#f9f4df", 0.95))
	draw_string(font, panel.position + Vector2(10.0, 31.0), str(profile.get("route_label", "")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 8, Color(line_color.r, line_color.g, line_color.b, 0.84))
	var labels: Array = profile.get("beat_labels", [])
	var glyphs: Array = profile.get("beat_glyphs", [])
	var count: int = max(1, int(profile.get("beat_count", labels.size())))
	var selected_index: int = int(profile.get("selected_index", -1))
	var boss_gate_index: int = int(profile.get("boss_gate_index", -1))
	var row_y := panel.position.y + 54.0
	var start_x := panel.position.x + 22.0
	var end_x := panel.end.x - 20.0
	var step := (end_x - start_x) / maxf(1.0, float(count - 1))
	draw_line(Vector2(start_x, row_y), Vector2(end_x, row_y), Color(line_color.r, line_color.g, line_color.b, 0.38), 2.0)
	for i in count:
		var point := Vector2(start_x + step * float(i), row_y)
		var is_boss: bool = i == boss_gate_index
		var is_selected: bool = i == selected_index
		var beat_color := boss_color if is_boss else safe_color if i == 0 else line_color
		var radius := 6.2 if is_selected else 5.0
		draw_circle(point, radius + 3.0, Color(beat_color.r, beat_color.g, beat_color.b, 0.14 if not is_selected else 0.28))
		draw_circle(point, radius, Color("#06141f"))
		draw_arc(point, radius + 1.0, 0.0, TAU, 24, Color(beat_color.r, beat_color.g, beat_color.b, 0.9), 1.4)
		if is_boss:
			draw_line(point + Vector2(-4.0, 0.0), point + Vector2(4.0, 0.0), Color(boss_color.r, boss_color.g, boss_color.b, 0.95), 1.2)
			draw_circle(point, 1.8, Color("#ffffff", 0.9))
		elif i < glyphs.size() and str(glyphs[i]) == "SAFE PORT":
			draw_line(point + Vector2(0.0, -3.0), point + Vector2(0.0, 3.0), Color(safe_color.r, safe_color.g, safe_color.b, 0.95), 1.0)
		else:
			draw_circle(point, 1.7, Color(beat_color.r, beat_color.g, beat_color.b, 0.95))
		if i < labels.size():
			var short_label := _storyboard_short_label(str(labels[i]))
			draw_string(font, point + Vector2(-22.0, 20.0), short_label, HORIZONTAL_ALIGNMENT_CENTER, 44.0, 7, Color("#dce8e2", 0.78))
	var selected_story := str(profile.get("selected_story_line", ""))
	if selected_story != "":
		draw_string(font, panel.position + Vector2(10.0, panel.size.y - 9.0), selected_story.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 7, Color("#f9f4df", 0.78))

func _draw_selected_sector_title_card() -> void:
	var profile := get_selected_sector_title_card_profile(world)
	if not bool(profile.get("visible", false)):
		return
	var font := get_theme_default_font()
	var accent: Color = profile.get("accent_color", Color("#58dbff"))
	var panel_size := Vector2(252.0, 52.0)
	var panel := Rect2(Vector2(size.x * 0.5 - panel_size.x * 0.5, 12.0), panel_size)
	_draw_premium_panel(panel, get_premium_panel_style_profile("forecast", accent), Color("#04101b"))
	draw_string(font, panel.position + Vector2(10.0, 14.0), str(profile.get("chapter_label", "ACT")), HORIZONTAL_ALIGNMENT_LEFT, 52.0, 8, Color(accent.r, accent.g, accent.b, 0.9))
	draw_string(font, panel.position + Vector2(62.0, 15.0), str(profile.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 72.0, 11, Color("#f9f4df", 0.96))
	draw_string(font, panel.position + Vector2(10.0, 30.0), str(profile.get("subtitle", "")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 8, Color(accent.r, accent.g, accent.b, 0.86))
	var hazard_line := str(profile.get("hazard_line", ""))
	if hazard_line != "":
		draw_string(font, panel.position + Vector2(10.0, 44.0), hazard_line.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 7, Color("#dce8e2", 0.72))

func _draw_premium_map_chrome() -> void:
	var profile := get_premium_map_presentation_profile(system_pressure)
	var rows: Array = world["tiles"]
	if rows.is_empty():
		return
	var map_rect := Rect2(map_origin, Vector2(rows[0].size(), rows.size()) * tile_size)
	var chrome: Color = profile.get("chrome_color", Color("#7afcff"))
	var gold: Color = profile.get("gold_accent", Color("#ffd166"))
	var vignette_alpha := float(profile.get("vignette_alpha", 0.28))
	var focus_dim := float(profile.get("focus_dim_alpha", 0.0))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#000000", vignette_alpha * 0.34), false, maxf(18.0, tile_size * 0.9))
	if focus_dim > 0.0:
		draw_rect(map_rect, Color("#000000", focus_dim * 0.36))
		var focus_rect := _tile_rect(selected_tile_position).grow(tile_size * 1.8)
		draw_rect(focus_rect, Color(chrome.r, chrome.g, chrome.b, 0.06))
		draw_rect(focus_rect, Color(chrome.r, chrome.g, chrome.b, 0.28), false, 1.0)
	var corner_length := 32.0
	for corner in [
		map_rect.position,
		Vector2(map_rect.end.x, map_rect.position.y),
		map_rect.end,
		Vector2(map_rect.position.x, map_rect.end.y),
	]:
		var x_dir := 1.0 if corner.x == map_rect.position.x else -1.0
		var y_dir := 1.0 if corner.y == map_rect.position.y else -1.0
		draw_line(corner, corner + Vector2(corner_length * x_dir, 0.0), Color(chrome.r, chrome.g, chrome.b, 0.78), 2.0)
		draw_line(corner, corner + Vector2(0.0, corner_length * y_dir), Color(chrome.r, chrome.g, chrome.b, 0.78), 2.0)
		draw_circle(corner + Vector2(5.0 * x_dir, 5.0 * y_dir), 2.4, Color(gold.r, gold.g, gold.b, 0.86))
	var scanline_alpha := float(profile.get("scanline_alpha", 0.06))
	for y in range(int(map_rect.position.y), int(map_rect.end.y), max(6, int(tile_size * 0.42))):
		draw_line(Vector2(map_rect.position.x, y), Vector2(map_rect.end.x, y), Color(chrome.r, chrome.g, chrome.b, scanline_alpha), 1.0)

func _draw_cinematic_color_grade() -> void:
	var profile := get_premium_map_presentation_profile(system_pressure)
	var grade: Dictionary = profile.get("palette_grade", {})
	var shadow: Color = grade.get("shadow_tint", Color("#02070b"))
	var highlight: Color = grade.get("highlight_tint", Color("#d7fbff"))
	var bloom_alpha := float(grade.get("bloom_alpha", 0.035))
	var contrast := float(grade.get("contrast_lift", 0.08))
	draw_rect(Rect2(Vector2.ZERO, size), Color(shadow.r, shadow.g, shadow.b, contrast * 0.55))
	var rows: Array = world["tiles"]
	if rows.is_empty():
		return
	var map_rect := Rect2(map_origin, Vector2(rows[0].size(), rows.size()) * tile_size)
	draw_rect(map_rect.grow(14.0), Color(highlight.r, highlight.g, highlight.b, bloom_alpha), false, 3.0)
	draw_rect(map_rect.grow(-4.0), Color(highlight.r, highlight.g, highlight.b, bloom_alpha * 0.45), false, 1.0)

func _draw_premium_panel(panel: Rect2, style: Dictionary, base_color: Color = Color("#05111a")) -> void:
	var accent: Color = style.get("accent", Color("#7afcff"))
	var corner_cut := float(style.get("corner_cut", 8.0))
	var points := PackedVector2Array([
		panel.position + Vector2(corner_cut, 0.0),
		Vector2(panel.end.x - corner_cut, panel.position.y),
		Vector2(panel.end.x, panel.position.y + corner_cut),
		panel.end - Vector2(0.0, corner_cut),
		panel.end - Vector2(corner_cut, 0.0),
		Vector2(panel.position.x + corner_cut, panel.end.y),
		Vector2(panel.position.x, panel.end.y - corner_cut),
		panel.position + Vector2(0.0, corner_cut),
	])
	var shadow_offset := Vector2(3.0, 4.0)
	var shadow_points := PackedVector2Array()
	for point in points:
		shadow_points.append(point + shadow_offset)
	draw_polygon(shadow_points, PackedColorArray([
		Color("#000000", float(style.get("shadow_alpha", 0.34))),
		Color("#000000", float(style.get("shadow_alpha", 0.34))),
		Color("#000000", float(style.get("shadow_alpha", 0.34))),
		Color("#000000", float(style.get("shadow_alpha", 0.34))),
		Color("#000000", float(style.get("shadow_alpha", 0.34))),
		Color("#000000", float(style.get("shadow_alpha", 0.34))),
		Color("#000000", float(style.get("shadow_alpha", 0.34))),
		Color("#000000", float(style.get("shadow_alpha", 0.34))),
	]))
	var fill := Color(base_color.r, base_color.g, base_color.b, float(style.get("glass_alpha", 0.84)))
	draw_polygon(points, PackedColorArray([fill, fill, fill, fill, fill, fill, fill, fill]))
	draw_polyline(points + PackedVector2Array([points[0]]), Color(accent.r, accent.g, accent.b, float(style.get("border_alpha", 0.38))), float(style.get("bevel_width", 2.0)))
	draw_rect(Rect2(panel.position + Vector2(8.0, 8.0), Vector2(float(style.get("accent_rail_width", 4.0)), panel.size.y - 16.0)), Color(accent.r, accent.g, accent.b, 0.78))
	draw_rect(panel.grow(-6.0), Color(accent.r, accent.g, accent.b, float(style.get("inner_glow_alpha", 0.12))), false, 1.0)

func _draw_region_plate(panel: Rect2, anchor: Vector2, plate: Dictionary) -> void:
	var color: Color = plate.get("plate_color", Color("#f4ead2"))
	var backing: Color = plate.get("backing_color", Color("#05111a"))
	var corner_cut := float(plate.get("corner_cut", 6.0))
	var points := PackedVector2Array([
		panel.position + Vector2(corner_cut, 0.0),
		Vector2(panel.end.x - corner_cut, panel.position.y),
		Vector2(panel.end.x, panel.position.y + corner_cut),
		panel.end - Vector2(0.0, corner_cut),
		panel.end - Vector2(corner_cut, 0.0),
		Vector2(panel.position.x + corner_cut, panel.end.y),
		Vector2(panel.position.x, panel.end.y - corner_cut),
		panel.position + Vector2(0.0, corner_cut),
	])
	var fill := Color(backing.r, backing.g, backing.b, 0.7)
	draw_polygon(points, PackedColorArray([fill, fill, fill, fill, fill, fill, fill, fill]))
	draw_polyline(points + PackedVector2Array([points[0]]), Color(color.r, color.g, color.b, 0.38), 1.0)
	draw_rect(Rect2(panel.position + Vector2(7.0, 6.0), Vector2(float(plate.get("rail_width", 3.0)), panel.size.y - 12.0)), Color(color.r, color.g, color.b, 0.7))
	var leader_start := Vector2(panel.get_center().x, panel.end.y)
	var leader_end := anchor + Vector2(0.0, -tile_size * 0.24)
	draw_line(leader_start, leader_end, Color(color.r, color.g, color.b, 0.42), 1.0)
	draw_circle(leader_end, maxf(1.4, tile_size * 0.035), Color(color.r, color.g, color.b, 0.72))

func _draw_hover_tooltip() -> void:
	if hovered_tile_position.x < 0 or world.is_empty():
		return
	var rows: Array = world["tiles"]
	if hovered_tile_position.y < 0 or hovered_tile_position.y >= rows.size():
		return
	var row: Array = rows[hovered_tile_position.y]
	if hovered_tile_position.x < 0 or hovered_tile_position.x >= row.size():
		return
	var tile: Dictionary = row[hovered_tile_position.x]
	if not tile.get("walkable", false):
		return
	var profile := get_tile_tooltip_profile(tile, system_pressure.get("available_gear", []))
	var fog_tooltip := _integrity_tooltip_for_position(hovered_tile_position)
	if not fog_tooltip.is_empty():
		var merged_badges: Array = profile.get("badges", []).duplicate()
		for badge in fog_tooltip.get("badges", []):
			if not merged_badges.has(badge):
				merged_badges.append(badge)
		profile["badges"] = merged_badges
		profile["accent_color"] = fog_tooltip.get("accent_color", profile.get("accent_color", Color("#f4ead2")))
		profile["summary"] = str(fog_tooltip.get("summary", profile.get("summary", "")))
	var font := get_theme_default_font()
	var anchor := _tile_rect(hovered_tile_position).end + Vector2(10.0, 4.0)
	var panel_size := Vector2(236.0, 86.0)
	if anchor.x + panel_size.x > size.x - 8.0:
		anchor.x = _tile_rect(hovered_tile_position).position.x - panel_size.x - 10.0
	if anchor.y + panel_size.y > size.y - 8.0:
		anchor.y = size.y - panel_size.y - 8.0
	anchor.x = maxf(8.0, anchor.x)
	anchor.y = maxf(8.0, anchor.y)
	var accent: Color = profile.get("accent_color", Color("#f4ead2"))
	var panel := Rect2(anchor, panel_size)
	_draw_premium_panel(panel, get_premium_panel_style_profile("tooltip", accent))
	draw_string(font, panel.position + Vector2(10.0, 17.0), str(profile.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 12, Color("#f9f4df", 0.96))
	var badges: Array = profile.get("badges", [])
	var badge_x := panel.position.x + 10.0
	for badge in badges.slice(0, 4):
		var label := str(badge)
		var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		var badge_rect := Rect2(Vector2(badge_x, panel.position.y + 23.0), Vector2(label_size.x + 9.0, 13.0))
		draw_rect(badge_rect, Color(accent.r, accent.g, accent.b, 0.18))
		draw_rect(badge_rect, Color(accent.r, accent.g, accent.b, 0.42), false, 1.0)
		draw_string(font, badge_rect.position + Vector2(4.0, 9.5), label, HORIZONTAL_ALIGNMENT_LEFT, label_size.x, 8, Color("#f9f4df", 0.9))
		badge_x += badge_rect.size.x + 4.0
	var summary := str(profile.get("summary", ""))
	if summary.length() > 92:
		summary = summary.substr(0, 89) + "..."
	draw_string(font, panel.position + Vector2(10.0, 54.0), summary, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 9, Color("#dce8e2", 0.82))
	var action: Dictionary = profile.get("action", {})
	if not action.is_empty():
		var action_color: Color = action.get("action_color", Color("#70ff8f"))
		var action_rect := Rect2(panel.position + Vector2(10.0, 62.0), Vector2(panel.size.x - 20.0, 16.0))
		draw_rect(action_rect, Color(action_color.r, action_color.g, action_color.b, 0.14))
		draw_rect(action_rect, Color(action_color.r, action_color.g, action_color.b, 0.42), false, 1.0)
		var action_label := str(action.get("primary_label", ""))
		if not bool(action.get("available", true)):
			action_label = str(action.get("blocked_reason", action_label))
		elif str(action.get("warning_reason", "")) != "":
			action_label = str(action.get("warning_reason", action_label))
		draw_string(font, action_rect.position + Vector2(6.0, 11.0), action_label, HORIZONTAL_ALIGNMENT_LEFT, action_rect.size.x - 12.0, 9, Color("#f9f4df", 0.94))

func _draw_selected_tile_panel() -> void:
	var profile := get_selected_tile_panel_profile(world, system_pressure.get("available_gear", []))
	if not profile.get("selected", false):
		return
	var font := get_theme_default_font()
	var boss_dossier: Dictionary = profile.get("boss_dossier", {})
	var panel_height := 164.0 if not boss_dossier.is_empty() else 132.0
	var panel := Rect2(Vector2(12.0, 12.0), Vector2(292.0, panel_height))
	var accent: Color = profile.get("panel_color", Color("#f4ead2"))
	_draw_premium_panel(panel, get_premium_panel_style_profile("selected", accent))
	draw_string(font, panel.position + Vector2(10.0, 17.0), str(profile.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 12, Color("#f9f4df", 0.96))
	var badges: Array = profile.get("badges", [])
	var badge_x := panel.position.x + 10.0
	for badge in badges.slice(0, 3):
		var label := str(badge)
		var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		var badge_rect := Rect2(Vector2(badge_x, panel.position.y + 23.0), Vector2(label_size.x + 9.0, 13.0))
		draw_rect(badge_rect, Color(accent.r, accent.g, accent.b, 0.16))
		draw_rect(badge_rect, Color(accent.r, accent.g, accent.b, 0.4), false, 1.0)
		draw_string(font, badge_rect.position + Vector2(4.0, 9.5), label, HORIZONTAL_ALIGNMENT_LEFT, label_size.x, 8, Color("#f9f4df", 0.9))
		badge_x += badge_rect.size.x + 4.0
	if bool(profile.get("route_identity_visible", false)):
		var identity_rect := Rect2(panel.position + Vector2(10.0, 39.0), Vector2(panel.size.x - 20.0, 15.0))
		draw_rect(identity_rect, Color(accent.r, accent.g, accent.b, 0.12))
		draw_rect(identity_rect, Color(accent.r, accent.g, accent.b, 0.34), false, 1.0)
		draw_string(font, identity_rect.position + Vector2(6.0, 10.8), str(profile.get("route_identity_label", "")), HORIZONTAL_ALIGNMENT_LEFT, identity_rect.size.x - 12.0, 8, Color("#f9f4df", 0.9))
	_draw_selected_command_ribbon(panel, profile)
	_draw_selected_condition_readout(panel)
	_draw_selected_boss_dossier(panel, boss_dossier)
	var action_line := "%s / %s" % [str(profile.get("status_label", "")), str(profile.get("action_label", ""))]
	var action_y := 138.0 if not boss_dossier.is_empty() else 106.0
	var confirm_y := 154.0 if not boss_dossier.is_empty() else 122.0
	draw_string(font, panel.position + Vector2(10.0, action_y), action_line, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 9, Color(accent.r, accent.g, accent.b, 0.92))
	var confirm_line := "%s: %s" % [str(profile.get("confirm_label", "")), str(profile.get("confirm_detail", ""))]
	draw_string(font, panel.position + Vector2(10.0, confirm_y), confirm_line, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 8, Color("#dce8e2", 0.84))

func _draw_selected_boss_dossier(panel: Rect2, dossier: Dictionary) -> void:
	if dossier.is_empty():
		return
	var font := get_theme_default_font()
	var color: Color = dossier.get("dossier_color", Color("#ff594d"))
	var rect := Rect2(panel.position + Vector2(10.0, 110.0), Vector2(panel.size.x - 20.0, 22.0))
	draw_rect(rect, Color(color.r, color.g, color.b, 0.12))
	draw_rect(rect, Color(color.r, color.g, color.b, 0.38), false, 1.0)
	draw_string(font, rect.position + Vector2(6.0, 9.0), str(dossier.get("boss_name", "BOSS")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12.0, 7, Color("#f9f4df", 0.9))
	var phases: Array = dossier.get("phase_labels", [])
	var detail := "%d PHASES / %s" % [int(dossier.get("phase_count", 0)), ", ".join(phases) if not phases.is_empty() else str(dossier.get("mechanic", ""))]
	draw_string(font, rect.position + Vector2(6.0, 19.0), detail, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12.0, 7, Color("#dce8e2", 0.78))

func _draw_selected_command_ribbon(panel: Rect2, panel_profile: Dictionary) -> void:
	var ribbon := get_selected_command_ribbon_profile(world, system_pressure.get("available_gear", []))
	if not ribbon.get("selected", false):
		return
	var font := get_theme_default_font()
	var segments: Array = ribbon.get("segments", [])
	if segments.is_empty():
		return
	var x := panel.position.x + 10.0
	var y := panel.position.y + (58.0 if bool(panel_profile.get("route_identity_visible", false)) else 43.0)
	var available_width := panel.size.x - 20.0
	var gap := 4.0
	var segment_width := (available_width - gap * float(segments.size() - 1)) / float(segments.size())
	for index in segments.size():
		var segment: Dictionary = segments[index]
		var color: Color = segment.get("color", panel_profile.get("panel_color", Color("#f4ead2")))
		var rect := Rect2(Vector2(x + float(index) * (segment_width + gap), y), Vector2(segment_width, 24.0))
		draw_rect(rect, Color(color.r, color.g, color.b, 0.12))
		draw_rect(rect, Color(color.r, color.g, color.b, 0.36), false, 1.0)
		draw_string(font, rect.position + Vector2(4.0, 9.0), str(segment.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8.0, 7, Color("#dce8e2", 0.7))
		var value := str(segment.get("value", ""))
		if value.length() > 14:
			value = value.substr(0, 11) + "..."
		draw_string(font, rect.position + Vector2(4.0, 20.0), value, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8.0, 8, Color("#f9f4df", 0.94))

func _draw_selected_condition_readout(panel: Rect2) -> void:
	var condition := get_selected_sector_condition_profile(world)
	if not condition.get("selected", false):
		return
	var font := get_theme_default_font()
	var color: Color = condition.get("condition_color", Color("#70ff8f"))
	var origin := panel.position + Vector2(10.0, 72.0)
	draw_string(font, origin + Vector2(0.0, 8.0), str(condition.get("visual_state", "High Fidelity")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 20.0, 8, Color(color.r, color.g, color.b, 0.92))
	var metrics := [
		{"label": condition.get("traction_label", "TRACTION 100%"), "value": condition.get("traction", 1.0), "color": Color("#70ff8f")},
		{"label": condition.get("lag_label", "LAG 0ms"), "value": 1.0 - clampf(float(condition.get("input_lag", 0.0)) * 4.0, 0.0, 1.0), "color": Color("#ffd166")},
		{"label": condition.get("damage_label", "THREAD 0.00/s"), "value": clampf(float(condition.get("thread_damage_per_second", 0.0)) * 3.2, 0.0, 1.0), "color": Color("#ff594d")},
	]
	for index in metrics.size():
		var metric: Dictionary = metrics[index]
		var y := origin.y + 14.0 + float(index) * 8.0
		var bar_rect := Rect2(Vector2(origin.x + 76.0, y - 5.0), Vector2(panel.size.x - 96.0, 4.0))
		var metric_color: Color = metric.get("color", color)
		draw_string(font, Vector2(origin.x, y), str(metric.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, 72.0, 7, Color("#dce8e2", 0.72))
		draw_rect(bar_rect, Color("#0b1820", 0.86))
		draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * clampf(float(metric.get("value", 0.0)), 0.0, 1.0), bar_rect.size.y)), Color(metric_color.r, metric_color.g, metric_color.b, 0.72))

func _integrity_tooltip_for_position(position: Vector2i) -> Dictionary:
	var zone := _integrity_zone_profile_for_position(position)
	if not zone.is_empty():
		return get_integrity_zone_tooltip_profile(zone)
	return {}

func _integrity_zone_profile_for_position(position: Vector2i) -> Dictionary:
	for zone in get_integrity_zone_profiles(system_pressure.get("integrity_zones", [])):
		if zone.get("position", Vector2i(-1, -1)) == position:
			return zone
	return {}

func _premium_layer_alpha(layer_id: String) -> float:
	var presentation := get_premium_map_presentation_profile(system_pressure)
	var layer_mix: Dictionary = presentation.get("layer_mix", {})
	return float(layer_mix.get(layer_id, 1.0))

func _premium_emblem(motif: String, tier: String, color: Color, fill_color: Color, stroke_count: int) -> Dictionary:
	return {
		"motif": motif,
		"tier": tier,
		"color": color,
		"fill_color": fill_color,
		"stroke_count": stroke_count,
	}

func _transition_step(layer: String, delay: float, duration: float, effect: String) -> Dictionary:
	return {
		"layer": layer,
		"delay": delay,
		"duration": duration,
		"effect": effect,
	}

func _polyline_length(points: Array[Vector2]) -> float:
	var total := 0.0
	for index in range(points.size() - 1):
		total += points[index].distance_to(points[index + 1])
	return total

func _point_on_polyline(points: Array[Vector2], distance: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var remaining := distance
	for index in range(points.size() - 1):
		var start := points[index]
		var target := points[index + 1]
		var segment_length := start.distance_to(target)
		if segment_length <= 0.001:
			continue
		if remaining <= segment_length:
			return start.lerp(target, remaining / segment_length)
		remaining -= segment_length
	return points[points.size() - 1]

func _find_walkable_path(map_world: Dictionary, start: Vector2i, destination: Vector2i) -> Array:
	var start_tile := _tile_from_world_state(map_world, start)
	var destination_tile := _tile_from_world_state(map_world, destination)
	if start_tile.is_empty() or destination_tile.is_empty() or not destination_tile.get("walkable", false):
		return []
	if start == destination:
		return [start]
	var frontier: Array[Vector2i] = [start]
	var came_from := {}
	came_from[start] = start
	var directions := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var cursor := 0
	while cursor < frontier.size():
		var current: Vector2i = frontier[cursor]
		cursor += 1
		if current == destination:
			break
		for direction: Vector2i in directions:
			var next: Vector2i = current + direction
			if came_from.has(next):
				continue
			var tile := _tile_from_world_state(map_world, next)
			if tile.is_empty() or not tile.get("walkable", false):
				continue
			came_from[next] = current
			frontier.append(next)
	if not came_from.has(destination):
		return []
	var path: Array[Vector2i] = []
	var step := destination
	while step != start:
		path.push_front(step)
		step = came_from[step]
	path.push_front(start)
	return path

func _tile_from_world_state(map_world: Dictionary, position: Vector2i) -> Dictionary:
	if map_world.is_empty() or not map_world.has("tiles"):
		return {}
	var rows: Array = map_world["tiles"]
	if position.y < 0 or position.y >= rows.size():
		return {}
	var row: Array = rows[position.y]
	if position.x < 0 or position.x >= row.size():
		return {}
	return row[position.x]

func _append_unique_string(values: Array[String], value: String) -> void:
	if not values.has(value):
		values.append(value)

func _title_from_id(id: String) -> String:
	var words := id.split("_", false)
	for i in range(words.size()):
		var word := str(words[i])
		if word.length() > 0:
			words[i] = word.substr(0, 1).to_upper() + word.substr(1)
	return " ".join(words)

func _gear_for_relic_code(relic_code: String) -> String:
	if relic_code == "10MM-WRENCH":
		return "10mm Wrench"
	return ""

func _route_warning(map_position: Vector2i, tile: Dictionary, required_gear: String, reason: String) -> Dictionary:
	return {
		"position": map_position,
		"tile_id": tile.get("id", ""),
		"tile_label": tile.get("label", "Unknown Sector"),
		"required_gear": required_gear,
		"reason": reason,
		"warning_color": Color("#ff594d"),
	}

func _route_has_pressure_hazard(route_id: String, map_world: Dictionary = {}) -> bool:
	var route := get_partition_route_profile(route_id)
	var source_world := map_world if not map_world.is_empty() else world
	for point in route.get("points", []):
		var tile := _tile_from_world_state(source_world, point)
		var hazard_text := str(tile.get("hazard", "")).to_lower()
		if hazard_text.contains("steam") or hazard_text.contains("pressure") or hazard_text.contains("coolant"):
			return true
	return false

func _boundary_profile_for_kinds(kind_a: String, kind_b: String) -> Dictionary:
	var pair := [kind_a, kind_b]
	pair.sort()
	var key := "%s_%s" % [pair[0], pair[1]]
	if key == "hardware_jungle":
		return {
			"boundary_kind": "jungle_hardware",
			"color": Color("#70ff8f").lerp(Color("#8fe6ff"), 0.55),
			"alpha": 0.48,
			"width": 2.0,
			"spark": true,
		}
	if kind_a == "water" or kind_b == "water":
		return {
			"boundary_kind": "water_land",
			"color": Color("#73d5ff"),
			"alpha": 0.42,
			"width": 1.6,
			"spark": false,
		}
	if key == "kernel_lunar" or key == "kernel_salt":
		return {
			"boundary_kind": "ascii_fault",
			"color": Color("#7afcff"),
			"alpha": 0.5,
			"width": 2.0,
			"spark": true,
		}
	if key.contains("salt") or key.contains("lunar"):
		return {
			"boundary_kind": "low_poly_cache",
			"color": Color("#fff3cf"),
			"alpha": 0.34,
			"width": 1.4,
			"spark": false,
		}
	return {
		"boundary_kind": "partition_edge",
		"color": Color("#f4ead2"),
		"alpha": 0.26,
		"width": 1.0,
		"spark": false,
	}

func _boundary_edge_points(position: Vector2i, direction: Vector2i) -> Dictionary:
	if direction.x != 0:
		return {
			"start": position + Vector2i(1, 0),
			"end": position + Vector2i(1, 1),
		}
	return {
		"start": position + Vector2i(0, 1),
		"end": position + Vector2i(1, 1),
	}

func _mission_pressure_profile(position: Vector2i, pressure_kind: String, glyph: String, urgency: float, color: Color, ring_count: int) -> Dictionary:
	return {
		"position": position,
		"pressure_kind": pressure_kind,
		"glyph": glyph,
		"urgency": clampf(urgency, 0.0, 1.0),
		"color": color,
		"ring_count": ring_count,
	}

func _altitude_contour_profile(position: Vector2i, contour_kind: String, label: String, rings: int, color: Color, intensity: float) -> Dictionary:
	return {
		"position": position,
		"contour_kind": contour_kind,
		"label": label,
		"rings": rings,
		"color": color,
		"intensity": clampf(intensity, 0.0, 1.0),
	}

func _draw_player() -> void:
	var tile_rect := Rect2(map_origin + displayed_player_position * tile_size, Vector2(tile_size, tile_size))
	var center := tile_rect.get_center()
	var s := tile_rect.size.x
	draw_circle(center, s * 0.48, Color("#f4ead2"))
	draw_circle(center, s * 0.34, Color("#3157b7"))
	draw_polygon(PackedVector2Array([
		center + Vector2(0, -s * 0.58),
		center + Vector2(s * 0.26, -s * 0.12),
		center + Vector2(-s * 0.26, -s * 0.12),
	]), PackedColorArray([Color("#f4ead2"), Color("#f4ead2"), Color("#f4ead2")]))

func _draw_objective_target() -> void:
	if objective_target.x < 0:
		return
	var rect := _tile_rect(objective_target)
	var viewport := Rect2(Vector2.ZERO, size)
	var pulse := (sin(Time.get_ticks_msec() / 180.0) + 1.0) * 0.5
	if rect.intersects(viewport.grow(tile_size)):
		var center := rect.get_center()
		var radius := tile_size * (0.72 + pulse * 0.28)
		draw_arc(center, radius, 0.0, TAU, 32, Color("#fff05a", 0.85), 3.0)
		draw_arc(center, radius + 5.0, -PI * 0.2, PI * 1.2, 32, Color("#3157b7", 0.65), 2.0)
		return

	var target_center := rect.get_center()
	var screen_center := size * 0.5
	var direction := (target_center - screen_center).normalized()
	var edge := _edge_point_for_direction(direction)
	var angle := direction.angle()
	var arrow := PackedVector2Array([
		edge + Vector2(cos(angle), sin(angle)) * 18.0,
		edge + Vector2(cos(angle + 2.45), sin(angle + 2.45)) * 12.0,
		edge + Vector2(cos(angle - 2.45), sin(angle - 2.45)) * 12.0,
	])
	draw_polygon(arrow, PackedColorArray([Color("#fff05a"), Color("#fff05a"), Color("#fff05a")]))
	draw_circle(edge, 4.0 + pulse * 2.0, Color("#3157b7"))

func _draw_frame() -> void:
	var rows: Array = world["tiles"]
	var map_rect := Rect2(map_origin, Vector2(rows[0].size(), rows.size()) * tile_size)
	draw_rect(map_rect, Color("#e8f7ba"), false, 2.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color("#f2e7c7", 0.26), false, 2.0)

func _tile_rect(position: Vector2i) -> Rect2:
	return Rect2(map_origin + Vector2(position) * tile_size, Vector2(tile_size, tile_size))

func _husk_position() -> Vector2i:
	return system_pressure.get("husk_position", Vector2i(27, 8))

func _poi_color(kind: String, severity: float) -> Color:
	if kind == "anchor":
		return Color("#66e093")
	if kind == "memory_leak":
		return Color("#ff594d").lerp(Color("#fff05a"), 1.0 - severity)
	return Color("#f0b66c")

func _poi_icon(kind: String) -> String:
	if kind == "anchor":
		return "A"
	if kind == "memory_leak":
		return "!"
	return "?"

func _tile_from_point(point: Vector2) -> Vector2i:
	if world.is_empty():
		return Vector2i(-1, -1)
	_update_layout()
	var rows: Array = world["tiles"]
	var local := point - map_origin
	var position := Vector2i(floor(local.x / tile_size), floor(local.y / tile_size))
	if position.y < 0 or position.y >= rows.size():
		return Vector2i(-1, -1)
	var row: Array = rows[position.y]
	if position.x < 0 or position.x >= row.size():
		return Vector2i(-1, -1)
	return position

func _player_map_position() -> Vector2:
	if world.is_empty():
		return Vector2.ZERO
	return Vector2(world["player"]["position"])

func _clamp_origin(raw_origin: Vector2, map_size: Vector2) -> Vector2:
	var origin := raw_origin
	if map_size.x <= size.x:
		origin.x = floor((size.x - map_size.x) * 0.5)
	else:
		origin.x = clampf(origin.x, size.x - map_size.x - 8.0, 8.0)
	if map_size.y <= size.y:
		origin.y = floor((size.y - map_size.y) * 0.5)
	else:
		origin.y = clampf(origin.y, size.y - map_size.y - 8.0, 8.0)
	return origin

func _edge_point_for_direction(direction: Vector2) -> Vector2:
	var margin: float = 24.0
	var half: Vector2 = size * 0.5 - Vector2(margin, margin)
	var x_scale: float = abs(half.x / direction.x) if abs(direction.x) > 0.001 else 999999.0
	var y_scale: float = abs(half.y / direction.y) if abs(direction.y) > 0.001 else 999999.0
	var scale: float = minf(x_scale, y_scale)
	return size * 0.5 + direction * scale

func _is_landmark(tile: Dictionary) -> bool:
	if tile.has("mission") or tile.has("encounter") or tile.has("artifact") or tile.get("npc", "") != "" or str(tile.get("dungeon_id", "")) != "" or tile.get("admin_node", false) or tile.get("map_feature", "") != "":
		return true
	return LANDMARK_KINDS.has(tile.get("kind", "")) and not str(tile.get("id", "")).begins_with("tile_")
