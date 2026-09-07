extends SceneTree
const Art = preload("res://presentation/art_library.gd")
const Main = preload("res://world/main.tscn")
const Combat = preload("res://sim/combat.gd")
var checks = 0
var failures = 0
func _initialize() -> void:
	_run.call_deferred()
func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
	print(("PASS " if value else "FAIL ") + text)
func _run() -> void:
	for id in Art.ASSETS:
		var asset = Art.ASSETS[id].instantiate()
		root.add_child(asset)
		var meshes = asset.find_children("*", "MeshInstance3D", true, false)
		check(meshes.size() == 1, id + " uses one exported combined mesh")
		var mesh: MeshInstance3D = meshes[0]
		check(mesh.mesh is ArrayMesh, id + " is imported mesh, not runtime primitive")
		check(mesh.mesh.get_surface_count() == 1, id + " has one atlas surface")
		var mat: StandardMaterial3D = mesh.get_active_material(0)
		check(mat.albedo_texture != null and mat.normal_enabled and mat.normal_texture != null and mat.metallic_texture != null and mat.emission_texture != null, id + " has full PBR texture set")
		check(asset.find_children("*", "CollisionObject3D", true, false).is_empty(), id + " cannot silently change collision")
		if id in ["magma_guardian", "firewall_sentinel", "packet_warden"]:
			check(mesh.skin != null and mesh.skin.get_bind_count() > 6, id + " has actual skin bindings")
			var skeleton = asset.find_child("Skeleton3D", true, false)
			check(skeleton != null and skeleton.get_bone_count() > 6, id + " has imported skeleton")
			var player = asset.find_child("AnimationPlayer", true, false)
			for clip in player.get_animation_list():
				var animation = player.get_animation(clip)
				var safe = true
				for track in range(animation.get_track_count()):
					if animation.track_get_type(track) == Animation.TYPE_METHOD:
						safe = false
				check(safe, id + "/" + clip + " cannot execute gameplay callbacks")
		asset.queue_free()
	await process_frame
	var world = Main.instantiate()
	world.test_mode = true
	root.add_child(world)
	await process_frame
	world.set_physics_process(false)
	world.dragon.set_physics_process(false)
	world.interact()
	var rig = world.dragon.rig
	check(rig.skeleton.get_bone_count() == 24, "Magma has its 24-bone hierarchy")
	for id in Combat.ORDER:
		var rule: Dictionary = Combat.ABILITIES[id]
		check(is_equal_approx(rig.player.get_animation(id).length, rule.windup + rule.recovery), id + " clip length matches simulation contract")
		var state = Combat.fresh()
		Combat.cast(state, id)
		Combat.tick(state, rule.windup * 0.8)
		var before = state.duplicate(true)
		rig.animate(0, 0, false, state)
		var pose = rig.pose_signature()
		rig.animate(0, 0, false, state)
		check(pose == rig.pose_signature(), id + " sampled pose is deterministic")
		rig.animate(0, 0, true, state)
		check(before == state, id + " calm animation preserves all simulation state")
	check(rig.muzzle_position().is_finite() and rig.muzzle_position().y > 1.6, "breath socket follows head, not actor waist")
	var floor = Art.source_mesh("deck_panel").get_aabb()
	var dais = Art.source_mesh("warden_dais").get_aabb()
	var pulse = world.effects.decal(Vector3.ZERO, 1, Color.ORANGE)
	check(pulse.position.y > maxf(floor.end.y, dais.end.y), "mandatory ground feedback clears authored deck/dais")
	await physics_frame
	await process_frame
	check(get_nodes_in_group("forge_prop_collision").size() == 3, "solid Forge furnishings have explicit collision proxies")
	check(not world.line_clear(Vector3(4.0, 0, 12.8), Vector3(9.0, 0, 12.8)), "new furnace blocks attacks rather than being visual-only")
	var bindings = rig.skeleton.get_bone_count()
	for quality in range(4):
		world.set_quality(quality)
		check(get_nodes_in_group("forge_prop_collision").size() == 3, "quality %d preserves furnishing collision" % quality)
		check(rig.skeleton.get_bone_count() == bindings and rig.player.has_animation("breath"), "quality %d retains skinned actor and clips" % quality)
	check(world.dressing.art_batches.size() >= 4, "repeated environment assets use MultiMesh batches")
	var before = world.dragon.state.duplicate(true)
	world.progress.gate_open = true
	world.progress.clears = 2
	world._apply_progress()
	world.dragon.position = Vector3(0, 0.1, -15)
	world.start_encounter()
	await process_frame
	world.enemy.set_physics_process(false)
	check(world.enemy.visual.model.get_meta("art_asset") == "packet_warden", "Warden uses distinct exported crowned geometry")
	check(world.dragon.state == before, "art placement never mutates player combat state")
	world.queue_free()
	await process_frame
	print("NEXTGEN_ART_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
