extends SceneTree
## Identical views for comparing committed creature assets; no save or art mutations.
const Studio = preload("res://validation/character_inspection.gd")
const World = preload("res://campaign/world.gd")
const Rules = preload("res://campaign/progress.gd")
const Combat = preload("res://campaign/guardian_combat.gd")
const OUT = "res://artifacts/realism"
var failures = 0
var captures: Array = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	create_timer(300.0, true, false, true).timeout.connect(func():
		push_error("Realism capture timed out")
		quit(1))
	_run.call_deferred()

func frames(n: int = 3) -> void:
	for i in range(n):
		await process_frame

func shot(id: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	if image.is_empty() or image.save_png(OUT + "/" + id + ".png") != OK:
		failures += 1
	captures.append(id)
	print("REALISM_CAPTURE " + id)

func set_rim(studio, enabled: bool) -> void:
	studio.rim.visible = enabled
	for toggle in studio.find_children("*", "CheckButton", true, false):
		if toggle.text == "Strong rim light":
			toggle.set_pressed_no_signal(enabled)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var studio = Studio.new()
	root.add_child(studio)
	await frames()
	for index in [0, 3, 6, 9]:
		var picker: OptionButton = studio.find_children("*", "OptionButton", true, false)[0]
		picker.select(index)
		picker.item_selected.emit(index)
		studio.set_view(0)
		studio.scrub(0.0)
		studio.orbit = 0.92
		studio._update_camera()
		set_rim(studio, false)
		await shot(studio.actor_id + "-neutral")
		set_rim(studio, true)
		await shot(studio.actor_id + "-rim")
		studio.set_view(3)
		if index == 6:
			studio.focus = Vector3(0, 1.72, -1.10)
			studio._update_camera()
		await shot(studio.actor_id + "-head")
		if "--quick" in OS.get_cmdline_user_args():
			continue
		studio.set_view(0)
		studio.orbit = 1.25
		studio.distance = 8.6 # Keep swept horns/wing tips inside the stress-pose frame.
		studio._update_camera()
		for clip in studio.clips:
			studio.select_clip(studio.clips.find(clip))
			studio.scrub(studio.player.get_animation(clip).length * 0.5)
			await shot(studio.actor_id + "-" + clip)
	studio.queue_free()
	await frames()
	var w = World.new()
	w.test_mode = true
	root.add_child(w)
	await frames()
	w.hud.close_overlay()
	w.title_open = false
	Rules.hatch(w.campaign)
	# Prepared inspection state, not an unassisted campaign playthrough.
	w._enter_room("forge", true)
	await frames(12)
	w.dragon.position = Vector3(0, 0.1, -2)
	w.camera_rig.position = w.dragon.position
	w.dragon.mouse_aim = false
	w.dragon.aim = Vector3.FORWARD
	for guardian in ["fire", "ice", "storm", "venom"]:
		# Presentation probe through the production actor/rig, using a fresh
		# session-only combat state. Recruitment is covered by campaign tests.
		var state = Combat.fresh("", guardian)
		w.party.states = {guardian: state}
		w.party.active_id = guardian
		w.campaign.active_guardian = guardian
		w.dragon.use_guardian(guardian, state)
		await frames(12)
		paused = true
		await shot(guardian + "-gameplay-camera")
		paused = false
	w.queue_free()
	await frames()
	var source_manifests: Dictionary = {}
	for folder in ["art/generated", "campaign/guardians", "campaign/fusion_assets", "campaign/venom"]:
		var path = "res://" + folder + "/manifest.json"
		source_manifests[folder] = FileAccess.get_sha256(path)
	var file = FileAccess.open(OUT + "/captures.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(), "captures": captures,
		"source_manifest_sha256": source_manifests,
		"failures": failures, "source": "Actual inspection scene and campaign camera; prepared save-isolated state"}, "  "))
	print("REALISM_CAPTURES: %d captures, %d failures" % [captures.size(), failures])
	quit(1 if failures else 0)
