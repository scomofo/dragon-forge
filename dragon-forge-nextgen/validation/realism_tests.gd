extends SceneTree
## Physical mouth-opening regression against the actual imported skeletons.
## The old Rime, Arc and Nox exports fail: their lower teeth move into the skull.
const Studio = preload("res://validation/character_inspection.gd")
var checks = 0
var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + message)

func jaw_tip(studio) -> Vector3:
	var head = studio.skeleton.find_bone("Head")
	var jaw = studio.skeleton.find_bone("Jaw")
	# In head coordinates: torso/head anticipation must not hide a reversed hinge.
	return studio.skeleton.get_bone_global_pose(head).affine_inverse() * (
		studio.skeleton.get_bone_global_pose(jaw) * Vector3(0, 0, -0.32))

func _run() -> void:
	var studio = Studio.new()
	root.add_child(studio)
	await process_frame
	for index in [0, 3, 4, 5, 6, 7, 9]:
		studio.load_actor(index)
		studio.select_clip(studio.clips.find("idle"))
		studio.scrub(0.0)
		var closed = jaw_tip(studio)
		studio.select_clip(studio.clips.find("breath"))
		var length = studio.player.get_animation("breath").length
		studio.scrub(length * 0.5)
		var opened = jaw_tip(studio)
		check(opened.is_finite(), studio.actor_id + " finite mouth pose")
		check(opened.y < closed.y - 0.085, studio.actor_id + " mandible opens below the palate")
		check(absf(opened.x - closed.x) < 0.005, studio.actor_id + " jaw opens on its hinge without lateral drift")
		studio.scrub(length)
		check(jaw_tip(studio).distance_to(closed) < 0.002, studio.actor_id + " mouth closes at end of recovery")
	studio.queue_free()
	await process_frame
	print("REALISM_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
