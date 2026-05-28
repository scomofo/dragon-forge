# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: Does a player experience the hatch -> map -> battle -> reward Dragon Forge loop within 3-5 minutes without guidance?
# Date: 2026-05-26

extends SceneTree

const SLICE_SCENE := "res://scenes/VerticalSlice.tscn"
const OUT_DIR := "res://../../design/art/target-frames/runtime-captures"

var _scene: Control


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Runtime screenshot capture requires a display renderer. Run without --headless.")
		quit(1)
		return
	var packed := load(SLICE_SCENE) as PackedScene
	if packed == null:
		push_error("Could not load %s" % SLICE_SCENE)
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_clear_old_captures()
	root.size = Vector2i(1280, 900)
	_scene = packed.instantiate() as Control
	if _scene == null:
		push_error("Could not instantiate vertical slice scene")
		quit(1)
		return

	root.add_child(_scene)
	call_deferred("_capture_flow")


func _capture_flow() -> void:
	await _settle()
	await _capture("01_intro_world_failure")

	_scene.call("_on_primary_pressed")
	await _settle()
	await _capture("02_intro_felix")

	_scene.call("_on_primary_pressed")
	await _settle()
	await _capture("03_intro_root_egg")

	_scene.call("_on_primary_pressed")
	await _settle()
	await _capture("04_forge_hub")

	_scene.call("_on_primary_pressed")
	await _wait_seconds(0.35)
	await _capture("05_hatch_reveal_mid")
	await _wait_seconds(0.75)
	await _capture("06_hatch_reveal_full")

	_scene.call("_on_primary_pressed")
	await _settle()
	await _capture("07_campaign_map")

	_scene.call("_on_primary_pressed")
	await _settle()
	await _capture("08_battle_telegraph")

	_scene.call("_on_primary_pressed")
	await _wait_for_phase("player_impact")
	await _wait_seconds(0.16)
	await _capture("09_root_spark_impact")
	await _wait_for_phase("enemy_impact")
	await _wait_seconds(0.16)
	await _capture("10_enemy_data_leak")
	await _wait_for_battle_idle()

	_scene.call("_on_secondary_pressed")
	await _wait_for_phase("player_impact")
	await _wait_seconds(0.18)
	await _capture("11_thorn_surge_impact")
	await _wait_for_battle_idle()

	_scene.call("_on_tertiary_pressed")
	await _wait_for_phase("player_impact")
	await _wait_seconds(0.18)
	await _capture("12_guarded_spark_counter")
	await _wait_for_state("victory")

	await _settle()
	await _capture("13_victory_reward")

	_scene.call("_on_primary_pressed")
	await _settle()
	await _capture("14_complete_return")

	print("Runtime captures written to %s" % ProjectSettings.globalize_path(OUT_DIR))
	root.remove_child(_scene)
	_scene.free()
	_scene = null
	await process_frame
	await process_frame
	quit(0)


func _clear_old_captures() -> void:
	var dir := DirAccess.open(ProjectSettings.globalize_path(OUT_DIR))
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func _settle() -> void:
	for i in range(8):
		await process_frame


func _wait_seconds(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		await process_frame
		elapsed += 1.0 / 60.0


func _wait_for_phase(phase: String) -> void:
	for i in range(300):
		await process_frame
		if str(_scene.get("battle_phase")) == phase:
			return
	push_error("Timed out waiting for battle phase %s" % phase)
	quit(1)


func _wait_for_battle_idle() -> void:
	for i in range(300):
		await process_frame
		if str(_scene.get("state")) == "battle" and not bool(_scene.get("battle_action_lock")):
			return
	push_error("Timed out waiting for battle idle")
	quit(1)


func _wait_for_non_battle_or_idle() -> void:
	for i in range(300):
		await process_frame
		if str(_scene.get("state")) != "battle" or not bool(_scene.get("battle_action_lock")):
			return
	push_error("Timed out waiting for action resolution")
	quit(1)


func _wait_for_state(expected: String) -> void:
	for i in range(300):
		await process_frame
		if str(_scene.get("state")) == expected:
			return
	push_error("Timed out waiting for state %s" % expected)
	quit(1)


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Could not read viewport texture for capture %s" % name)
		quit(1)
		return
	var path := "%s/%s.png" % [ProjectSettings.globalize_path(OUT_DIR), name]
	var err := image.save_png(path)
	if err != OK:
		push_error("Could not save capture %s: %s" % [path, error_string(err)])
		quit(1)
