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
const Quality = preload("res://presentation/quality.gd")
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

func _ready() -> void:
	Inputs.setup()
	if not test_mode:
		progress = store.read_progress()
	_build_lighting()
	_build_world()
	effects = Effects.new()
	add_child(effects)
	dragon = Dragon.new()
	dragon.position = SPAWN
	add_child(dragon)
	camera_rig = CameraRig.new()
	camera_rig.target = dragon
	add_child(camera_rig)
	hud = Hud.new()
	hud.world = self
	add_child(hud)
	dragon.ability_used.connect(resolve_ability)
	dragon.hint.connect(hud.toast)
	dragon.damaged.connect(_on_player_damaged)
	dragon.died.connect(func(): hud.toast("Dragon down. Press R, or open Menu and Retry. Completed milestones are safe."))
	set_quality(quality_index)
	_apply_progress()
	hud.toast(store.message if store.message != "" else "Wake the Magma guardian: press E / B at the hatch ring.")

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
	environment.fog_density = 0.007
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
	for x in range(-8, 9, 4):
		for z in range(-20, 13, 4):
			Geo.box(self, Vector3(x, 0.02, z), Vector3(3.88, 0.035, 3.88), plate_mat)
	for side in [-1, 1]:
		Geo.solid_box(self, Vector3(side * 10.1, 1.0, -4), Vector3(0.4, 2.0, 38.5), dark_mat)
		Geo.solid_box(self, Vector3(side * 6.65, 1.4, 2), Vector3(6.7, 2.8, 0.55), metal_mat)
		for z in [-19, -11, -3, 8]:
			Geo.solid_box(self, Vector3(side * 8.8, 1.75, z), Vector3(1.5, 3.5, 1.65), dark_mat)
			for y in [0.7, 1.4, 2.1, 2.8]:
				Geo.box(self, Vector3(side * 7.99, y, z), Vector3(0.065, 0.065, 1.18), cyan if z < 2 else amber)
		Geo.box(self, Vector3(side * 3.0, 0.05, -9), Vector3(0.045, 0.035, 21.5), cyan)
	Geo.solid_box(self, Vector3(0, 1, -23.1), Vector3(20.5, 2, 0.4), dark_mat)
	Geo.solid_box(self, Vector3(0, 1, 15.1), Vector3(20.5, 2, 0.4), dark_mat)
	gate = Geo.solid_box(self, Vector3(0, 1.4, 2), Vector3(6.6, 2.8, 0.45), Geo.material(Color(0.25, 0.8, 0.9, 0.42), 0.5))
	for side in [-1, 1]:
		Geo.box(self, Vector3(side * 3.35, 1.55, 2), Vector3(0.14, 3.1, 0.65), cyan)
	Geo.label(self, Vector3(0, 3.5, 2), "OUTER GRID // BREACH", Geo.CYAN)
	Geo.label(self, Vector3(0, 0.2, 13), "THE FORGE", Color("ffd3a1"))
	Geo.ring(self, HATCH + Vector3.UP * 0.09, 1.65, amber)
	Geo.cylinder(self, HATCH + Vector3.UP * 0.08, 1.42, 1.42, 0.12, metal_mat, 12)
	Geo.label(self, HATCH + Vector3.UP * 2.8, "HATCH / REST  [E / B]", Geo.AMBER)
	hatch_egg = Node3D.new()
	hatch_egg.position = HATCH
	add_child(hatch_egg)
	Geo.orb(hatch_egg, Vector3(0, 0.86, 0), 0.68, Geo.material(Color("734939")))
	Geo.ring(hatch_egg, Vector3(0, 0.94, 0), 0.69, amber, 0.035)
	Geo.cylinder(hatch_egg, Vector3(0, 1.2, 0), 0.5, 0.03, 0.65, amber, 6)
	Geo.ring(self, SOCKET + Vector3.UP * 0.08, 1.6, cyan)
	Geo.cylinder(self, SOCKET + Vector3.UP * 0.25, 0.9, 0.7, 0.5, metal_mat, 6)
	Geo.label(self, SOCKET + Vector3.UP * 3.0, "CORE SOCKET  [E / B]", Geo.CYAN)
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
	forge_light.light_color = Geo.CYAN if progress.upgraded else Geo.AMBER
	forge_light.light_energy = 5.0 if progress.upgraded else 2.5

func _commit(event: String, encounter: int = -1) -> bool:
	if not Progress.advance(progress, event, encounter):
		return false
	if not test_mode and not store.write_progress(progress):
		hud.toast(store.message)
	_apply_progress()
	return true

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ng_interact"):
		interact()
	if not dragon.active or dragon.state.hp <= 0.0:
		return
	interwave_delay = maxf(0.0, interwave_delay - delta)
	if dragon.global_position.y < -5.0:
		retry()
		hud.toast("Returned to the Forge after leaving the walkable area.")
	for item in conduits:
		item.sim.tick(delta)
		item.label.text = ("BREACH POWERED" if item.gate and progress.gate_open else ("COOLING %.1fs" % item.sim.cooldown if item.sim.cooldown > 0.0 else "HEAT %d / 60\nAIM + MAGMA BREATH [2 / Y]" % int(item.sim.heat)))
	_tick_walls(delta)
	start_encounter()

func _process(delta: float) -> void:
	clock += delta
	if not reduced_motion:
		recovered_core.rotation.y = clock * 0.65
		restored_core.rotation.y = clock * 0.45

func interact() -> void:
	if dragon.state.hp <= 0.0:
		return
	var at: Vector3 = dragon.global_position
	if not progress.hatched and at.distance_to(HATCH) < 3.2:
		_commit("hatch")
		effects.pulse(HATCH, 2.0)
		hud.toast("Magma awakened. Move to the cyan conduit. Aim and use [2] twice to open the breach.")
	elif progress.clears == 3 and not progress.core and at.distance_to(CORE) < 3.0:
		_commit("core")
		effects.pulse(CORE, 2.4, Geo.CYAN)
		hud.toast("Core recovered. Return south to the Forge and install it in the right-hand socket.")
	elif progress.core and not progress.upgraded and at.distance_to(SOCKET) < 3.2:
		_commit("install")
		effects.pulse(SOCKET, 3.0, Geo.CYAN)
		hud.toast("FORGE RESTORED. Prototype complete. Use Menu to start a new expedition.")
	elif progress.hatched and at.distance_to(HATCH) < 3.2:
		dragon.state = Combat.fresh()
		hud.toast("Rested. Health restored and core cooled.")
	else:
		hud.toast("Move closer to a hatch ring, dropped core, or Forge socket to interact.")

func start_encounter() -> void:
	if not progress.gate_open or progress.clears >= 3 or is_instance_valid(enemy) or interwave_delay > 0.0 or dragon.global_position.z >= 0.0:
		return
	enemy = Sentinel.new()
	enemy.encounter = int(progress.clears)
	enemy.boss = progress.clears == 2
	enemy.position = [Vector3(0, 0.1, -7), Vector3(3, 0.1, -12), Vector3(0, 0.1, -18)][int(progress.clears)]
	enemy.target = dragon
	enemy.reduced_motion = reduced_motion
	add_child(enemy)
	enemy.slam.connect(_on_slam)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.hit_feedback.connect(effects.number)
	camera_rig.opponent = enemy
	hud.toast("Packet Warden: faster tells below half health." if enemy.boss else "Shield closed: bait the marked slam, dodge or guard, then counter while OPEN.")

func resolve_ability(id: String, origin: Vector3, direction: Vector3) -> void:
	if id == "wall":
		_place_wall(origin, direction)
		return
	var rule: Dictionary = Combat.ABILITIES[id]
	if is_instance_valid(enemy) and Combat.in_cone(origin, direction, enemy.global_position, rule.range, rule.cone) and line_clear(origin, enemy.global_position):
		enemy.take_hit(rule.damage)
	if id == "breath":
		for item in conduits:
			var at: Vector3 = item.node.global_position
			if Combat.in_cone(origin, direction, at, rule.range, rule.cone) and line_clear(origin, at):
				if item.sim.add_heat(38.0):
					_overload(item)
				else:
					hud.toast("Conduit heating: land another Magma Breath to overload it.")
		for step in range(1, 5):
			var at = origin + direction * step * 1.25
			if line_clear(origin, at):
				effects.pulse(at, 0.35 + step * 0.18)
	else:
		effects.pulse(origin if id == "burst" else origin + direction * 1.5, rule.range if id == "burst" else 0.9)

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
	var marker = effects.decal(at, Combat.ABILITIES.wall.radius, Geo.AMBER)
	walls.append({"at": at, "ttl": 3.6, "tick": 0.0, "node": marker})

func _tick_walls(delta: float) -> void:
	for i in range(walls.size() - 1, -1, -1):
		var wall: Dictionary = walls[i]
		var live_dt = minf(delta, wall.ttl)
		wall.ttl -= delta
		wall.tick -= live_dt
		while wall.tick <= 0.0:
			wall.tick += 0.6
			if is_instance_valid(enemy) and Combat.in_cone(wall.at, Vector3.FORWARD, enemy.global_position, Combat.ABILITIES.wall.radius, -1.0) and line_clear(wall.at, enemy.global_position):
				enemy.take_hit(Combat.ABILITIES.wall.damage)
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
		dragon.receive_damage(amount)

func _on_player_damaged(amount: float, guarded: bool) -> void:
	effects.number(dragon.global_position, "GUARD -%d" % int(amount) if guarded else "-%d" % int(amount))
	camera_rig.impact()
	if guarded and is_instance_valid(enemy):
		enemy.brain.open_window(2.4)
		hud.toast("Guarded. The shield is OPEN - counterattack!")

func _on_enemy_defeated(encounter: int) -> void:
	if not _commit("clear", encounter):
		return
	dragon.state.hp = minf(dragon.state.max_hp, dragon.state.hp + 35.0)
	enemy = null
	camera_rig.opponent = null
	interwave_delay = 1.8
	hud.toast("Warden defeated. Pick up the core [E / B]." if progress.clears == 3 else "Sentinel cleared. +35 health. Next guardian approaching.")

func retry() -> void:
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
	dragon.respawn(SPAWN)
	interwave_delay = 0.3
	_apply_progress()
	hud.toast("Back at the Forge. Completed encounters and recovered cores are kept.")

func new_expedition() -> void:
	progress = Progress.fresh()
	if not test_mode:
		store.write_progress(progress)
	retry()

func set_quality(index: int) -> void:
	quality_index = clampi(index, 0, 3)
	quality_info = Quality.apply(quality_index, get_viewport(), environment, sun, reduced_motion)
	effects.particle_budget = quality_info.particles

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	dragon.reduced_motion = value
	camera_rig.reduced_motion = value
	effects.reduced_motion = value
	if is_instance_valid(enemy):
		enemy.reduced_motion = value
	# Existing persistent fields also become calm; their lifetime/damage is unchanged.
	for wall in walls:
		wall.node.material_override.set_shader_parameter("motion", 0.0 if value else 1.0)
	set_quality(quality_index)

func objective_text() -> String:
	if dragon.state.hp <= 0.0:
		return "DRAGON DOWN. Press R to retry from the Forge. Dodge the marked impact; counter when OPEN."
	if not progress.hatched:
		return "Awaken your guardian. Press E / B beside the amber hatch ring."
	if not progress.gate_open:
		return "Power the breach. Walk to the cyan conduit, aim at it, and land TWO Magma Breaths [2 / Y]."
	if progress.clears < 3:
		return "Outer Grid: %d / 3 guardians cleared. Dodge / guard the impact, then attack the OPEN shield. Arena conduit breaks shields." % int(progress.clears)
	if not progress.core:
		return "Recover the Warden's core at the north end of the arena. Move close and press E / B."
	if not progress.upgraded:
		return "Return SOUTH to the Forge. Install the core in the right-hand socket [E / B]."
	return "FORGE RESTORED. Prototype complete. Menu > New expedition to replay."
