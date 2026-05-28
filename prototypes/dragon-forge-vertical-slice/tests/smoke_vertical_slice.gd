# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: Does a player experience the hatch -> map -> battle -> reward Dragon Forge loop within 3-5 minutes without guidance?
# Date: 2026-05-26

extends SceneTree

const SLICE_SCENE := "res://scenes/VerticalSlice.tscn"

var _scene: Control


func _init() -> void:
	var packed := load(SLICE_SCENE) as PackedScene
	if packed == null:
		push_error("Could not load %s" % SLICE_SCENE)
		quit(1)
		return

	_scene = packed.instantiate() as Control
	if _scene == null:
		push_error("Could not instantiate vertical slice scene")
		quit(1)
		return

	root.add_child(_scene)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	await process_frame

	_expect_texture("root_egg")
	_expect_texture("root_egg_idle_0")
	_expect_texture("vfx_guarded_spark")
	_expect_manifest_action(&"root_wyrmling", &"root_spark", "root_wyrmling_root_spark", "vfx_root_spark")
	_expect_manifest_action(&"admin_protocol", &"data_leak", "admin_protocol_data_leak", "vfx_shadow_burst")
	_expect_texture("root_wyrmling_root_spark_0")
	_expect_texture("admin_protocol_data_leak_0")
	_expect_music_cue("map", "res://assets/audio/music_map_node_select.wav")
	_expect_state("intro")
	_scene.call("_on_primary_pressed")
	_expect_state("intro_felix")
	_expect_music_cue("forge", "res://assets/audio/music_forge_ready_room.wav")
	_scene.call("_on_primary_pressed")
	_expect_state("intro_egg")
	_scene.call("_on_primary_pressed")
	_expect_state("hub")
	_scene.call("_on_primary_pressed")
	_expect_state("hatched")
	_scene.call("_on_primary_pressed")
	_expect_state("map")
	_expect_music_cue("map", "res://assets/audio/music_map_node_select.wav")
	_scene.call("_on_primary_pressed")
	_expect_state("battle")
	_expect_music_cue("battle", "res://assets/audio/music_battle_data_bout.wav")
	_expect_enemy_warning_copy()

	_scene.call("_on_primary_pressed")
	await _wait_for_battle_idle()
	_expect_state("battle")
	_expect_enemy_warning_copy()
	_scene.call("_on_secondary_pressed")
	await _wait_for_battle_idle()
	_expect_state("battle")
	_expect_enemy_warning_copy()
	_scene.call("_on_tertiary_pressed")
	await _wait_for_state("victory")
	_expect_state("victory")
	_expect_music_cue("victory", "res://assets/audio/music_victory_scrap_jingle.wav")
	_scene.call("_on_primary_pressed")
	_expect_state("complete")

	var scraps: int = int(_scene.get("scraps"))
	if scraps != 65:
		push_error("Expected 65 scraps after victory, got %d" % scraps)
		quit(1)
		return

	print("Vertical slice smoke: complete loop reached with %d scraps." % scraps)
	root.remove_child(_scene)
	_scene.queue_free()
	_scene = null
	await process_frame
	await process_frame
	await process_frame
	quit(0)


func _expect_state(expected: String) -> void:
	var actual: String = str(_scene.get("state"))
	if actual != expected:
		push_error("Expected state %s, got %s" % [expected, actual])
		quit(1)


func _expect_texture(key: String) -> void:
	var textures: Dictionary = _scene.get("slice_textures")
	if not textures.has(key):
		push_error("Expected slice texture %s to be loaded" % key)
		quit(1)


func _expect_manifest_action(actor_id: StringName, move_id: StringName, expected_clip_prefix: String, expected_vfx_key: String) -> void:
	var keys: Dictionary = _scene.call("_battle_animation_keys_for_action", actor_id, move_id)
	if str(keys.get("clip_prefix", "")) != expected_clip_prefix:
		push_error("Expected %s/%s clip %s, got %s" % [actor_id, move_id, expected_clip_prefix, keys])
		quit(1)
	if str(keys.get("vfx_key", "")) != expected_vfx_key:
		push_error("Expected %s/%s VFX %s, got %s" % [actor_id, move_id, expected_vfx_key, keys])
		quit(1)


func _expect_enemy_warning_copy() -> void:
	var banner_text: String = str(_scene.call("_battle_banner_text"))
	if banner_text != "INCOMING: DATA LEAK":
		push_error("Expected enemy warning banner, got %s" % banner_text)
		quit(1)
	var forbidden_fragments := ["telegraph: choose", "telegraph phase", "choose a move"]
	var battle_copy := [
		banner_text,
		(_scene.get("body_label") as Label).text,
		(_scene.get("dialogue_label") as Label).text,
		(_scene.get("log_label") as Label).text,
	]
	for line in battle_copy:
		var lower_line := str(line).to_lower()
		for fragment in forbidden_fragments:
			if lower_line.contains(fragment):
				push_error("Battle warning copy still reads like a player telegraph command: %s" % line)
				quit(1)


func _expect_music_cue(expected_key: String, expected_path: String) -> void:
	var actual_key: String = str(_scene.get("current_music_key"))
	if actual_key != expected_key:
		push_error("Expected music key %s, got %s" % [expected_key, actual_key])
		quit(1)
	var target_db := float(_scene.get("music_target_db"))
	if target_db < -18.0:
		push_error("Expected audible music target for %s, got %.1f dB" % [expected_key, target_db])
		quit(1)
	var actual_path: String = str(_scene.call("_music_path_for_mode", expected_key))
	if actual_path != expected_path:
		push_error("Expected music path %s for %s, got %s" % [expected_path, expected_key, actual_path])
		quit(1)
	if not FileAccess.file_exists(expected_path):
		push_error("Expected generated music asset %s to exist" % expected_path)
		quit(1)
	var stream := _scene.call("_load_music_stream", expected_path, expected_key != "victory") as AudioStreamWAV
	if stream == null:
		push_error("Expected generated music asset %s to load as AudioStreamWAV" % expected_path)
		quit(1)
	if stream.get_length() < 3.0:
		push_error("Expected generated music asset %s to be a full cue, got %.2f seconds" % [expected_path, stream.get_length()])
		quit(1)
	if expected_key == "victory":
		if stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
			push_error("Expected victory jingle to play once, got loop mode %d" % stream.loop_mode)
			quit(1)
	else:
		if stream.loop_mode != AudioStreamWAV.LOOP_FORWARD or stream.loop_end <= stream.loop_begin:
			push_error("Expected looping music cue %s to have a valid loop range, got mode=%d begin=%d end=%d" % [
				expected_key,
				stream.loop_mode,
				stream.loop_begin,
				stream.loop_end,
			])
			quit(1)


func _wait_for_battle_idle() -> void:
	for i in range(300):
		await process_frame
		if str(_scene.get("state")) == "battle" and not bool(_scene.get("battle_action_lock")):
			return
	push_error("Timed out waiting for battle TELEGRAPH phase")
	quit(1)


func _wait_for_state(expected: String) -> void:
	for i in range(300):
		await process_frame
		if str(_scene.get("state")) == expected:
			return
	push_error("Timed out waiting for state %s" % expected)
	quit(1)
