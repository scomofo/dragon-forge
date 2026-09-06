extends Node3D
const Combat = preload("res://sim/combat.gd")
const Progress = preload("res://sim/progression.gd")
const Store = preload("res://sim/save_store.gd")
const Conduit = preload("res://sim/conduit.gd")
const Dragon = preload("res://actors/dragon.gd")
const Sentinel = preload("res://actors/sentinel.gd")
const Geo = preload("res://presentation/geometry.gd")
const Inputs = preload("res://presentation/input_map.gd")
const Effects = preload("res://presentation/effects.gd")
const CameraRig = preload("res://presentation/camera_rig.gd")
const Hud = preload("res://presentation/hud.gd")
const Dressing = preload("res://world/set_dressing.gd")
const Preferences = preload("res://sim/preferences.gd")
const Quality = preload("res://presentation/quality.gd")
const Modules = preload("res://sim/forge_modules.gd")
const Guidance = preload("res://sim/guidance.gd")
const Wayfinder = preload("res://presentation/wayfinder.gd")
const SPAWN = Vector3(0, 0.1, 10)
const HATCH = Vector3(-2.5, 0, 10)
const SOCKET = Vector3(2.5, 0, 10)
const CORE = Vector3(0, 0, -18)
var test_mode = OS.get_cmdline_user_args().has("--test-mode")
var progress = Progress.fresh()
var store = Store.new()
var dragon
var enemy
var effects
var camera_rig
var hud
var environment: Environment
var sun: DirectionalLight3D
var forge_light: OmniLight3D
var gate: StaticBody3D
var hatch_egg: Node3D
var recovered_core: Node3D
var restored_core: Node3D
var conduits: Array = []
var walls: Array = []
var quality_index = 1
var quality_info: Dictionary = {}
var reduced_motion = false
var interwave_delay = 0.0
var clock = 0.0
var dressing
var preferences = Preferences.new()
var preferences_ready = false
var trial_active = false
var wayfinder
var feedback_cooldown = 0.0

func _ready() -> void:
	Inputs.setup()
	if not test_mode:
		progress = store.read_progress()
		var settings = preferences.read_values()
		quality_index = settings.quality
		reduced_motion = settings.reduced_motion
	_build_lighting()
	_build_world()
	dressing = Dressing.new()
	add_child(dressing)
	effects = Effects.new()
	add_child(effects)
	dragon = Dragon.new()
	dragon.state = Combat.fresh(progress.module)
	dragon.position = SPAWN
	add_child(dragon)
	camera_rig = CameraRig.new()
	camera_rig.target = dragon
	add_child(camera_rig)
	wayfinder = Wayfinder.new()
	add_child(wayfinder)
	hud = Hud.new()
	hud.world = self
	add_child(hud)
	dragon.ability_used.connect(resolve_ability)
	dragon.hint.connect(hud.toast)
	dragon.damaged.connect(_on_player_damaged)
	dragon.died.connect(func(): hud.show_defeat.call_deferred())
	set_reduced_motion(reduced_motion)
	preferences_ready = true
	_apply_progress()
	if store.message != "":
		hud.toast(store.message)

func _build_lighting() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("081421")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("9bbacb")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("1a3447")
	environment.fog_density = 0.004
	environment.fog_sky_affect = 0.18
	var world_environment = WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_color = Color("d2e5f0")
	sun.light_energy = 1.8
	sun.directional_shadow_max_distance = 65
	add_child(sun)
	forge_light = OmniLight3D.new()
	forge_light.position = Vector3(0, 4, 10)
	forge_light.light_color = Geo.AMBER
	forge_light.light_energy = 2.5
	forge_light.omni_range = 15
	add_child(forge_light)
	var arena_light = OmniLight3D.new()
	arena_light.position = Vector3(0, 5, -12)
	arena_light.light_color = Geo.CYAN
	arena_light.light_energy = 2.0
	arena_light.omni_range = 17
	add_child(arena_light)

func _build_world() -> void:
	var floor_mat = Geo.material(Color("152833"))
	var plate_mat = Geo.material(Color("263e4a"))
	var dark_mat = Geo.material(Geo.INK)
	var metal_mat = Geo.material(Geo.METAL)
	var cyan = Geo.material(Geo.CYAN, 1.1)
	var amber = Geo.material(Geo.AMBER, 1.4)
	Geo.solid_box(self, Vector3(0, -0.3, -4), Vector3(20, 0.6, 38), floor_mat)
	var floor_plates: Array = []
	var cool_lights: Array = []
	var warm_lights: Array = []
	for x in range(-8, 9, 4):
		for z in range(-20, 13, 4):
			floor_plates.append(Vector3(x, 0.02, z))
	Geo.batch_boxes(self, floor_plates, Vector3(3.88, 0.035, 3.88), plate_mat)
	for side in [-1, 1]:
		Geo.solid_box(self, Vector3(side * 10.1, 1.0, -4), Vector3(0.4, 2.0, 38.5), dark_mat)
		Geo.solid_box(self, Vector3(side * 6.65, 1.4, 2), Vector3(6.7, 2.8, 0.55), metal_mat)
		for z in [-19, -11, -3, 8]:
			Geo.solid_box(self, Vector3(side * 8.8, 1.75, z), Vector3(1.5, 3.5, 1.65), dark_mat)
			for y in [0.7, 1.4, 2.1, 2.8]:
				(cool_lights if z < 2 else warm_lights).append(Vector3(side * 7.99, y, z))
		Geo.box(self, Vector3(side * 3.0, 0.05, -9), Vector3(0.045, 0.035, 21.5), cyan)
	Geo.batch_boxes(self, cool_lights, Vector3(0.065, 0.065, 1.18), cyan)
	Geo.batch_boxes(self, warm_lights, Vector3(0.065, 0.065, 1.18), amber)
	Geo.solid_box(self, Vector3(0, 1, -23.1), Vector3(20.5, 2, 0.4), dark_mat)
	Geo.solid_box(self, Vector3(0, 1, 15.1), Vector3(20.5, 2, 0.4), dark_mat)
	gate = Geo.solid_box(self, Vector3(0, 1.4, 2), Vector3(6.6, 2.8, 0.45), Geo.material(Color(0.25, 0.8, 0.9, 0.42), 0.5))
	for side in [-1, 1]:
		Geo.box(self, Vector3(side * 3.35, 1.55, 2), Vector3(0.14, 3.1, 0.65), cyan)
	Geo.label(self, Vector3(0, 3.5, 2), "OUTER GRID // BREACH", Geo.CYAN)
	Geo.label(self, Vector3(0, 0.2, 13), "THE FORGE", Color("ffd3a1"))
	Geo.ring(self, HATCH + Vector3.UP * 0.09, 1.65, amber)
	Geo.cylinder(self, HATCH + Vector3.UP * 0.08, 1.42, 1.42, 0.12, metal_mat, 12)
	Geo.label(self, HATCH + Vector3.UP * 2.8, "HATCHERY", Geo.AMBER)
	hatch_egg = Node3D.new()
	hatch_egg.position = HATCH
	add_child(hatch_egg)
	Geo.orb(hatch_egg, Vector3(0, 0.86, 0), 0.68, Geo.material(Color("734939")))
	Geo.ring(hatch_egg, Vector3(0, 0.94, 0), 0.69, amber, 0.035)
	Geo.cylinder(hatch_egg, Vector3(0, 1.2, 0), 0.5, 0.03, 0.65, amber, 6)
	Geo.ring(self, SOCKET + Vector3.UP * 0.08, 1.6, cyan)
	Geo.cylinder(self, SOCKET + Vector3.UP * 0.25, 0.9, 0.7, 0.5, metal_mat, 6)
	Geo.label(self, SOCKET + Vector3.UP * 3.0, "HEART SOCKET", Geo.CYAN)
	restored_core = _core(SOCKET + Vector3.UP * 1.7, Geo.CYAN)
	recovered_core = _core(CORE + Vector3.UP * 1.3, Geo.AMBER)
	_add_conduit(Vector3(-2.1, 0, 4.5), true)
	_add_conduit(Vector3(4.5, 0, -11), false)
	Geo.ring(self, Vector3(4.5, 0.045, -11), 5.0, Geo.material(Color(0.18, 0.62, 0.68, 0.45), 0.0, true), 0.025)

func _core(at: Vector3, color: Color) -> Node3D:
	var node = Node3D.new()
	node.position = at
	add_child(node)
	var mat = Geo.material(color, 2.5)
	Geo.orb(node, Vector3.ZERO, 0.43, mat)
	Geo.ring(node, Vector3.ZERO, 0.83, mat).rotation.x = PI / 2.0
	Geo.ring(node, Vector3.ZERO, 0.95, mat).rotation.z = PI / 3.0
	Geo.ring(node, Vector3.ZERO, 1.04, mat).rotation.z = -PI / 3.0
	return node

func _add_conduit(at: Vector3, opens_gate: bool) -> void:
	var node = Node3D.new()
	node.position = at
	add_child(node)
	var metal = Geo.material(Geo.METAL)
	var glow = Geo.material(Geo.CYAN, 1.4)
	Geo.cylinder(node, Vector3(0, 0.22, 0), 0.8, 0.66, 0.44, metal, 6)
	Geo.cylinder(node, Vector3(0, 0.95, 0), 0.28, 0.28, 1.25, glow, 6)
	for side in [-1, 1]:
		Geo.box(node, Vector3(side * 0.52, 0.9, 0), Vector3(0.16, 1.4, 0.25), metal)
	Geo.ring(node, Vector3(0, 1.7, 0), 0.65, glow)
	var label = Geo.label(node, Vector3(0, 2.3, 0), "", Geo.CYAN)
	conduits.append({"node": node, "label": label, "sim": Conduit.new(), "gate": opens_gate})

func _apply_progress() -> void:
	dragon.active = progress.hatched
	hatch_egg.visible = not progress.hatched
	gate.visible = not progress.gate_open
	gate.collision_layer = 0 if progress.gate_open else 1
	recovered_core.visible = progress.clears == 3 and not progress.core
	restored_core.visible = progress.upgraded
	var module_color: Color = Modules.DATA[progress.module].color if Modules.DATA.has(progress.module) else Geo.CYAN
	forge_light.light_color = module_color if progress.upgraded else Geo.AMBER
	for mesh in restored_core.get_children():
		if mesh is MeshInstance3D:
			mesh.material_override.albedo_color = module_color
			mesh.material_override.emission = module_color
	forge_light.light_energy = 5.0 if progress.upgraded else 2.5
	dressing.set_restored(progress.upgraded)

func _commit(event: String, encounter: int = -1) -> bool:
	if not Progress.advance(progress, event, encounter):
		return false
	if not test_mode and not store.write_progress(progress):
		hud.toast(store.message)
	_apply_progress()
	return true

func _physics_process(delta: float) -> void:
	feedback_cooldown = maxf(0.0, feedback_cooldown - delta)
	if dragon.input_grace <= 0.0 and Input.is_action_just_pressed("ng_interact"):
		interact()
	if not dragon.active or dragon.state.hp <= 0.0:
		return
	interwave_delay = maxf(0.0, interwave_delay - delta)
	if dragon.global_position.y < -5.0:
		retry()
		hud.toast("Returned to the Forge after leaving the walkable area.")
	for item in conduits:
		item.sim.tick(delta)
		item.label.text = ("POWERED" if item.gate and progress.gate_open else ("COOLING %.1fs" % item.sim.cooldown if item.sim.cooldown > 0.0 else "RELAY %d / 60" % int(item.sim.heat)))
	_tick_walls(delta)
	start_encounter()

func _process(delta: float) -> void:
	clock += delta
	if is_instance_valid(wayfinder):
		wayfinder.show_target(guidance(), is_instance_valid(enemy), dragon.state.hp <= 0.0)
	if not reduced_motion:
		recovered_core.rotation.y = clock * 0.65
		restored_core.rotation.y = clock * 0.45

func interaction() -> String:
	if dragon.state.hp <= 0.0 or trial_active or is_instance_valid(enemy):
		return ""
	var at: Vector3 = dragon.global_position
	if not progress.hatched and at.distance_to(HATCH) < 3.2:
		return "Awaken Magma"
	if progress.clears == 3 and not progress.core and at.distance_to(CORE) < 3.0:
		return "Recover the core"
	if progress.core and at.distance_to(SOCKET) < 3.2:
		return "Reconfigure / field test" if progress.module != "" else "Install the core"
	if progress.hatched and at.distance_to(HATCH) < 3.2:
		return "Rest and cool the core"
	return ""

func interact() -> void:
	if get_tree().paused:
		return
	match interaction():
		"Awaken Magma":
			_commit("hatch")
			effects.pulse(HATCH, 2.0)
			hud.toast("Magma is awake. Your first task: bring the breach relay back online.")
		"Recover the core":
			_commit("core")
			effects.pulse(CORE, 2.4, Geo.CYAN)
			hud.toast("CORE RECOVERED  /  Bring it home. The Forge needs a heart.")
		"Install the core", "Reconfigure / field test":
			hud.show_modules()
		"Rest and cool the core":
			dragon.state = Combat.fresh(progress.module)
			dragon.buffered_id = ""
			dragon.buffer_time = 0.0
			hud.toast("Rested. Health restored and core cooled.")

func can_configure() -> bool:
	return progress.core and not trial_active and not is_instance_valid(enemy) and dragon.state.hp > 0.0 and dragon.global_position.distance_to(SOCKET) < 3.2

func choose_module(id: String) -> bool:
	if not can_configure() or not Progress.select_module(progress, id):
		return false
	if not test_mode and not store.write_progress(progress):
		hud.toast(store.message)
	dragon.state = Combat.fresh(progress.module)
	dragon.buffered_id = ""
	_apply_progress()
	effects.pulse(SOCKET, 3.0, Modules.DATA[id].color)
	hud.close_overlay()
	hud.toast(Modules.DATA[id].name + " installed. Field-test it at the socket; swap builds here freely.")
	return true

func start_trial() -> bool:
	if not can_configure() or progress.module == "":
		return false
	trial_active = true
	dragon.respawn(Vector3(0, 0.1, -3), progress.module)
	interwave_delay = 0.4
	hud.close_overlay()
	hud.toast("FIELD TEST  /  One Warden. Your installed core is active. No extra core reward.")
	return true

func start_encounter() -> void:
	if not dragon.active or dragon.state.hp <= 0.0 or not progress.gate_open or is_instance_valid(enemy) or interwave_delay > 0.0:
		return
	if not trial_active and progress.clears >= 3:
		return
	var index = 2 if trial_active else int(progress.clears)
	var trigger: float = 0.0 if trial_active else Guidance.TRIGGERS[index]
	if dragon.global_position.z >= trigger:
		return
	enemy = Sentinel.new()
	enemy.encounter = 3 if trial_active else index
	enemy.boss = index == 2
	enemy.position = [Vector3(0, 0.1, -7), Vector3(3, 0.1, -12), Vector3(0, 0.1, -18)][index]
	if trial_active:
		enemy.position = Vector3(0, 0.1, -8)
	enemy.target = dragon
	enemy.reduced_motion = reduced_motion
	add_child(enemy)
	enemy.title.visible = false
	enemy.hp_label.visible = false
	enemy.slam.connect(_on_slam)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.hit_feedback.connect(_hit_feedback)
	camera_rig.opponent = enemy
	hud.toast("PACKET WARDEN  /  Below half health, its tells get faster." if enemy.boss else ("RELAY TWO  /  Lure this guardian near the cyan conduit." if index == 1 else "FIRST CONTACT  /  Let it commit. Dodge the circle, then counter."))

func _hit_feedback(at: Vector3, text: String, blocked: bool) -> void:
	effects.number(at, text, blocked)
	if blocked and feedback_cooldown <= 0.0:
		hud.feedback("SHIELD CLOSED", "Wait for its slam. Counter when the shield opens.", Color("adc1d4"))
		feedback_cooldown = 1.4
	elif not blocked:
		hud.feedback("COUNTER  " + text, "Hit confirmed", Color("76e0ca"))

func resolve_ability(id: String, origin: Vector3, direction: Vector3) -> void:
	if id == "wall":
		_place_wall(origin, direction)
		return
	var rule: Dictionary = Combat.ABILITIES[id]
	if is_instance_valid(enemy) and Combat.in_cone(origin, direction, enemy.global_position, rule.range, rule.cone) and line_clear(origin, enemy.global_position):
		enemy.take_hit(Combat.technique_damage(dragon.state, id))
	if id == "breath":
		for item in conduits:
			var at: Vector3 = item.node.global_position
			if Combat.in_cone(origin, direction, at, rule.range, rule.cone) and line_clear(origin, at):
				if item.sim.add_heat(38.0):
					_overload(item)
				else:
					hud.toast("Conduit heating: land another Magma Breath to overload it.")
		# Stop the visible jet at cover, matching the existing obstruction rule.
		var visual_reach = 0.0
		for step in range(1, 15):
			if not line_clear(origin, origin + direction * step * 0.5):
				break
			visual_reach = step * 0.5
		if visual_reach > 0.5:
			effects.attack(id, origin, direction, maxf(0.1, visual_reach - 0.6))
	else:
		effects.attack(id, origin, direction, rule.range)

func line_clear(origin: Vector3, target: Vector3) -> bool:
	if origin.distance_squared_to(target) < 0.0001:
		return true
	var query = PhysicsRayQueryParameters3D.create(origin + Vector3.UP * 0.95, target + Vector3.UP * 0.95, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _place_wall(origin: Vector3, direction: Vector3) -> void:
	var at = origin + direction * Combat.ABILITIES.wall.range
	var query = PhysicsRayQueryParameters3D.create(origin + Vector3.UP, at + Vector3.UP, 1)
	var collision = get_world_3d().direct_space_state.intersect_ray(query)
	if not collision.is_empty():
		at = collision.position - direction * 0.6
	at.y = 0.0
	var marker = effects.flame_field(at, Combat.ABILITIES.wall.radius)
	walls.append({"damage": Combat.technique_damage(dragon.state, "wall"), "at": at, "ttl": 3.6, "tick": 0.0, "node": marker})

func _tick_walls(delta: float) -> void:
	for i in range(walls.size() - 1, -1, -1):
		var wall: Dictionary = walls[i]
		var live_dt = minf(delta, wall.ttl)
		wall.ttl -= delta
		wall.tick -= live_dt
		while wall.tick <= 0.0:
			wall.tick += 0.6
			if is_instance_valid(enemy) and Combat.in_cone(wall.at, Vector3.FORWARD, enemy.global_position, Combat.ABILITIES.wall.radius, -1.0) and line_clear(wall.at, enemy.global_position):
				enemy.take_hit(wall.damage)
		if wall.ttl <= 0.0:
			wall.node.queue_free()
			walls.remove_at(i)

func _overload(item: Dictionary) -> void:
	var at: Vector3 = item.node.global_position
	effects.pulse(at, 5.0, Geo.CYAN)
	if item.gate and _commit("gate"):
		hud.toast("Breach open. Head north into the Outer Grid.")
	else:
		hud.toast("Conduit overloaded: nearby shields break for a counterattack.")
	if is_instance_valid(enemy) and enemy.global_position.distance_to(at) <= 5.0 and line_clear(at, enemy.global_position):
		enemy.overload()

func _on_slam(at: Vector3, radius: float, amount: float) -> void:
	effects.pulse(at, radius, Color("ffc36b"))
	var offset: Vector3 = dragon.global_position - at
	offset.y = 0.0
	if offset.length() <= radius and line_clear(at, dragon.global_position):
		var dodged = dragon.state.hp > 0.0 and dragon.state.iframes > 0.0 and dragon.state.dodge_cd > 0.60
		dragon.receive_damage(amount)
		if dodged:
			hud.feedback("EVADED", "Shield open. Turn and counter.", Color("76e0ca"))

func _on_player_damaged(amount: float, guarded: bool) -> void:
	effects.number(dragon.global_position, "GUARD -%d" % int(amount) if guarded else "-%d" % int(amount))
	camera_rig.impact()
	hud.feedback("GUARDED" if guarded else "HIT  -%d" % int(amount), "Counter window extended" if guarded else "Dodge outside the marked circle, or hold guard.", Color("76e0ca") if guarded else Color("ffa07f"))
	if guarded and is_instance_valid(enemy):
		enemy.brain.open_window(2.4)
		hud.toast("Guarded. The shield is OPEN - counterattack!")

func _on_enemy_defeated(encounter: int) -> void:
	if encounter == 3 and trial_active:
		trial_active = false
		_commit("trial")
		enemy = null
		camera_rig.opponent = null
		hud.show_trial_result.call_deferred()
		return
	if not _commit("clear", encounter):
		return
	dragon.state.hp = minf(dragon.state.max_hp, dragon.state.hp + 35.0)
	enemy = null
	camera_rig.opponent = null
	interwave_delay = 2.0
	hud.toast("WARDEN DEFEATED  /  Recover its core at the marked pedestal." if progress.clears == 3 else "RELAY CLEARED  /  +35 health. Continue north when ready.")

func _clear_encounter() -> void:
	if is_instance_valid(enemy):
		enemy.queue_free()
	enemy = null
	camera_rig.opponent = null
	for wall in walls:
		if is_instance_valid(wall.node):
			wall.node.queue_free()
	walls.clear()
	for item in conduits:
		item.sim = Conduit.new()
	effects.set_calm(true)
	effects.set_calm(reduced_motion)

func retry() -> void:
	_clear_encounter()
	var checkpoint = SPAWN
	if trial_active:
		checkpoint = Vector3(0, 0.1, -3)
	elif progress.gate_open and progress.clears < 3:
		checkpoint = [Vector3(0, 0.1, 0.7), Vector3(0, 0.1, -7), Vector3(0, 0.1, -13)][int(progress.clears)]
	dragon.respawn(checkpoint, progress.module)
	interwave_delay = 0.7
	_apply_progress()
	hud.close_overlay()
	hud.toast("Checkpoint restored. Health full; completed relays and your installed core are kept.")

func return_to_forge() -> void:
	_clear_encounter()
	trial_active = false
	dragon.respawn(SPAWN, progress.module)
	interwave_delay = 0.7
	_apply_progress()
	hud.close_overlay()

func new_expedition() -> void:
	progress = Progress.fresh()
	trial_active = false
	if not test_mode:
		store.write_progress(progress)
	retry()

func set_quality(index: int) -> void:
	quality_index = clampi(index, 0, 3)
	quality_info = Quality.apply(quality_index, get_viewport(), environment, sun, reduced_motion)
	effects.particle_budget = quality_info.particles
	dressing.set_quality(quality_index)
	_persist_preferences()

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	dragon.reduced_motion = value
	camera_rig.reduced_motion = value
	effects.set_calm(value)
	if value:
		camera_rig.trauma = 0.0
	if is_instance_valid(enemy):
		enemy.reduced_motion = value
	# Existing persistent fields also become calm; their lifetime/damage is unchanged.
	for wall in walls:
		wall.node.material_override.set_shader_parameter("motion", 0.0 if value else 1.0)
	set_quality(quality_index)

func guidance() -> Dictionary:
	return Guidance.describe(progress, dragon.global_position, is_instance_valid(enemy), trial_active)

func objective_text() -> String:
	var info = guidance()
	return info.title + "\n" + info.detail

func _persist_preferences() -> void:
	if test_mode or not preferences_ready:
		return
	if not preferences.write_values({"version": 1, "quality": quality_index, "reduced_motion": reduced_motion}):
		hud.toast(preferences.message)
