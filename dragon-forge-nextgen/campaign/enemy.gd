extends CharacterBody3D
## Campaign rules own damage and tells. Sector bosses have distinct imported presentation rigs.
const Brain = preload("res://sim/enemy_brain.gd")
const BossRig = preload("res://campaign/bosses/rig.gd")
const BossCatalog = preload("res://campaign/bosses/catalog.gd")
const Rig = preload("res://presentation/sentinel_rig.gd")
const Geo = preload("res://presentation/geometry.gd")
const Patterns = preload("res://campaign/patterns.gd")
const Roles = preload("res://campaign/enemy_roles.gd")
const GuardianCombat = preload("res://campaign/guardian_combat.gd")
signal attack_warning
signal defeated(id: String)
signal impact(payload: Dictionary, amount: float)
signal hit_feedback(at: Vector3, text: String, blocked: bool)
var spec: Dictionary = {}
var brain = Brain.new()
var target
var navigation
var boss = false
var hp = 100.0
var max_hp = 100.0
var reduced_motion = false
var visual: Node3D
var shield: MeshInstance3D
var tell: Node3D
var label: Label3D
var sequence = 0
var shape: Dictionary = {}
var pattern = "slam"
var warmup = 0.8
var hit_time = 0.0
var chilled = 0.0
var charged = 0.0
var toxin = 0
var toxin_time = 0.0
var toxin_tick = 1.0
var impact_flash = 0.0

func _ready() -> void:
	boss = spec.get("boss", false)
	max_hp = float(spec.get("hp", 100.0))
	hp = max_hp
	brain.boss = boss
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	var collision = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.70 if boss else 0.6
	capsule.height = 2.4
	collision.shape = capsule
	collision.position.y = 1.2
	add_child(collision)
	if BossCatalog.known(spec.id):
		visual = BossRig.new()
		visual.boss_id = spec.id
	else:
		visual = Rig.new()
		visual.boss = boss
	add_child(visual)
	var shield_y = BossCatalog.entry(spec.id).get("core_height", 1.4)
	var shield_radius = .69 if BossCatalog.known(spec.id) else 1.08
	shield = Geo.cylinder(visual, Vector3(0, shield_y, -0.85), shield_radius, shield_radius, 0.03, Geo.material(Color(0.35, 0.76, 0.9, 0.20), 0.4, true), 6)
	shield.rotation.x = PI / 2.0
	var crown_color = Color(spec.get("color", "eabe80"))
	Geo.ring(self, Vector3(0, 0.15, 0), 1.2, Geo.material(crown_color, 0.6, true), 0.045)
	label = Geo.label(self, Vector3(0, BossCatalog.entry(spec.id).get("height",3.25), 0), spec.get("name", "Guardian"), crown_color)
	label.font_size = 24
	tell = Node3D.new()
	tell.name = "LockedAttackGeometry"
	get_parent().add_child.call_deferred(tell)

func _exit_tree() -> void:
	if is_instance_valid(tell):
		tell.queue_free()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(tell) or not tell.is_inside_tree() or not is_instance_valid(target) or brain.mode == "dead":
		return
	if target.state.hp <= 0.0:
		tell.visible = false
		return
	impact_flash=maxf(0.0,impact_flash-delta)
	chilled=maxf(0.0,chilled-delta)
	charged=maxf(0.0,charged-delta)
	tick_toxin(delta)
	if hp<=0.0:return
	var role_tag = "" if boss else " / " + Roles.label(str(spec.get("archetype","bruiser")))
	label.text=spec.get("name","Guardian")+role_tag+(" / CHILLED" if chilled>0.0 else "") + (" / CHARGED" if charged>0.0 else "") + (" / TOXIN x%d" % toxin if toxin>0 else "")
	warmup = maxf(0, warmup - delta)
	brain.enraged = boss and hp <= max_hp * 0.5
	var toward: Vector3 = target.global_position - global_position
	toward.y = 0.0
	var role: String = str(spec.get("archetype", "bruiser"))
	var profile: Dictionary = Roles.profile(role)
	var engage: float = 9.0 if boss else float(profile.engage)
	if brain.mode == "seek" and warmup <= 0.0:
		if toward.length() <= engage and navigation.line_clear(global_position, target.global_position):
			_begin_attack()
	elif brain.mode != "seek":
		brain.timer = maxf(0.0, brain.timer - delta)
		if brain.timer <= 0.0:
			if brain.mode == "tell":
				brain.mode = "recover"
				brain.timer = 2.0 if boss else float(profile.recover)
				impact_flash = .16
				if visual is BossRig:
					visual.phase_index = BossCatalog.phase(spec.id,hp,max_hp)
					visual.contact_now()
				impact.emit(shape.duplicate(true), float(spec.damage))
			else:
				brain.mode = "seek"
				warmup = 0.3
	var direction = Vector3.ZERO
	if brain.mode == "seek" and warmup <= 0.0:
		direction = _role_direction(role,toward)
	var speed: float = (2.8 if brain.enraged else 2.3) if boss else float(profile.speed)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.x *= (0.6 if chilled>0.0 else 1.0)
	velocity.z *= (0.6 if chilled>0.0 else 1.0)
	velocity.y = -1 if is_on_floor() else velocity.y - 25 * delta
	move_and_slide()
	if brain.mode == "seek" and toward.length() > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-toward.x, -toward.z), minf(delta * 7.0, 1.0))
	tell.visible = brain.mode == "tell" or impact_flash > 0.0
	shield.visible = spec.get("shield", true) and not brain.vulnerable()
	hit_time = maxf(0.0, hit_time - delta)
	visual.rotation.x = hit_time * (0.10 if reduced_motion else 0.4)
	if visual is BossRig: visual.phase_index = BossCatalog.phase(spec.id,hp,max_hp)
	visual.animate(delta, brain, Vector2(velocity.x, velocity.z).length(), reduced_motion)


func tick_toxin(delta: float) -> void:
	if toxin<=0 or toxin_time<=0.0 or hp<=0.0:return
	var dt=minf(maxf(delta,0.0) if is_finite(delta) else 0.0,toxin_time)
	toxin_time=maxf(0.0,toxin_time-dt);toxin_tick-=dt
	while toxin_tick<=0.0 and toxin>0 and hp>0.0:
		toxin_tick+=1.0
		take_hit(GuardianCombat.toxin_tick_damage()*float(toxin),true)
	if toxin_time<=0.0:toxin=0;toxin_tick=1.0

func apply_toxin() -> void:
	if toxin<=0:toxin_tick=1.0
	toxin=GuardianCombat.toxin_stacks(toxin+1);toxin_time=GuardianCombat.toxin_duration()
	hit_feedback.emit(global_position,"TOXIN x%d" % toxin,false)

func _role_direction(role: String, toward: Vector3) -> Vector3:
	var direct: Vector3 = navigation.direction_to(global_position,target.global_position)
	if boss or toward.length_squared() < 0.001:
		return direct
	var distance := toward.length()
	var forward := toward.normalized()
	var side := Vector3(-forward.z,0.0,forward.x) * (1.0 if sequence % 2 == 0 else -1.0)
	var profile: Dictionary = Roles.profile(role)
	match role:
		"sniper":
			if distance < float(profile.min): return -forward
			if distance > float(profile.max): return direct
			return Vector3.ZERO
		"skirmisher":
			if distance < float(profile.min): return (-forward + side * .55).normalized()
			if distance > float(profile.max): return (direct + side * .35).normalized()
			return side
		"controller":
			if distance < float(profile.min): return -forward
			if distance > float(profile.max): return direct
			return side * .45
		_:
			return direct

func _begin_attack() -> void:
	var list: Array = spec.get("patterns", ["slam"])
	if spec.id == "singularity-final":
		var phase = 1 if hp > max_hp * 0.66 else (2 if hp > max_hp * 0.33 else 3)
		list = list.slice(0, phase)
	pattern = list[sequence % list.size()]
	sequence += 1
	shape = Patterns.lock(pattern, global_position, target.global_position)
	if visual is BossRig:
		visual.begin_attack(pattern)
		visual.rotation.y = atan2(-shape.direction.x,-shape.direction.z)
	brain.mode = "tell"
	var profile: Dictionary = Roles.profile(str(spec.get("archetype", "bruiser")))
	brain.locked_duration = 1.15 if brain.enraged else (1.65 if boss else float(profile.tell))
	brain.timer = brain.locked_duration
	for n in tell.get_children():
		tell.remove_child(n)
		n.queue_free()
	_draw_shape(shape)
	attack_warning.emit()

func _draw_shape(data: Dictionary) -> void:
	var edge = Geo.material(Color("ffcc7e"), 0.3, true)
	var fill = Geo.material(Color(1.0, 0.28, 0.1, 0.17), 0.0, true)
	match data.kind:
		"beam":
			var center: Vector3 = data.origin + data.direction * (data.length / 2.0 - 0.4)
			center.y = 0.17
			var beam = Geo.box(tell, center, Vector3(data.half_width * 2, 0.015, data.length + 0.8), fill)
			beam.rotation.y = atan2(-data.direction.x, -data.direction.z)
			for side in [-1, 1]:
				var offset = data.direction.cross(Vector3.UP) * side * data.half_width
				var rail = Geo.box(tell, center + offset, Vector3(0.04, 0.02, data.length + 0.8), edge)
				rail.rotation.y = beam.rotation.y
		"ring":
			var at: Vector3 = data.origin
			at.y = 0.17
			Geo.ring(tell, at, data.outer, edge, 0.10)
			Geo.ring(tell, at, data.inner, Geo.material(Color("72dfc1"), 0.3, true), 0.10)
			for j in range(24):
				var a = TAU * j / 24.0
				var marker = Geo.box(tell, at + Vector3(sin(a),0,cos(a)) * 4.9, Vector3(0.06,0.02,3.6), fill)
				marker.rotation.y = a
		_:
			for center in data.circles:
				var at: Vector3 = center
				at.y = 0.17
				Geo.ring(tell, at, data.radius, edge, 0.07)
				Geo.cylinder(tell, at, data.radius, data.radius, 0.012, fill, 40)

func take_hit(amount: float, bypass_shield: bool = false) -> float:
	if hp <= 0.0 or not is_finite(amount) or amount <= 0.0 or is_queued_for_deletion():
		return 0.0
	if spec.get("shield", true) and not bypass_shield and not brain.vulnerable():
		hit_feedback.emit(global_position, "SHIELDED", true)
		return 0.0
	var actual = minf(hp, amount)
	hp -= actual
	hit_time = 0.15
	hit_feedback.emit(global_position, str(int(actual)), false)
	if hp <= 0.0:
		brain.kill()
		if visual is BossRig:
			shield.visible = false
			visual.reparent(get_parent(),true)
			visual.begin_defeat(reduced_motion)
		defeated.emit(spec.id)
		queue_free()
	return actual

func displace_from(origin: Vector3, distance: float) -> float:
	# A successful Void hit may move an ordinary foe, never a boss or a locked tell.
	# Movement uses the same collision body as navigation and does not alter attack geometry.
	if hp <= 0.0 or brain.mode in ["dead", "tell"] or boss or is_queued_for_deletion() or not is_inside_tree():
		return 0.0
	if not is_finite(distance) or not origin.is_finite() or not global_position.is_finite():
		return 0.0
	var offset = global_position - origin
	offset.y = 0.0
	var separation = offset.length()
	if separation < 0.001 or is_zero_approx(distance):return 0.0
	var travel = clampf(distance, -1.5, 1.5)
	if travel < 0.0:travel = -minf(-travel, separation)
	var before = global_position
	move_and_collide(offset / separation * travel)
	return global_position.distance_to(before)

func overload() -> void:
	brain.open_window(2.4)
	take_hit(55.0, true)

func element_hit(amount: float,guardian: String,id: String,chill_duration: float = 3.0, charge_duration: float = 4.0) -> float:
	var shatter = guardian=="fire" and id!="wall" and chilled>0.0
	var discharge = guardian == "storm" and id == "burst" and charged > 0.0
	var bloom_stacks = toxin if guardian=="venom" and id=="burst" else 0
	var multiplier=1.4 if shatter else (1.5 if discharge else (GuardianCombat.toxin_burst_multiplier(bloom_stacks) if guardian=="venom" and id=="burst" else 1.0))
	var actual=take_hit(amount*multiplier)
	if actual<=0.0:return 0.0
	if discharge:
		charged = 0.0
		hit_feedback.emit(global_position, "DISCHARGE", false)
	elif guardian == "storm" and id in ["breath", "wall"] and hp > 0.0:
		charged = maxf(charged, clampf(charge_duration, 0.0, 6.0))
	if shatter:
		chilled=0.0
		hit_feedback.emit(global_position,"SHATTER",false)
	elif guardian=="ice" and id in ["breath","wall"] and hp>0.0:
		chilled=maxf(chilled,clampf(chill_duration,0.0,4.5))
	if guardian=="venom":
		if id=="burst" and bloom_stacks>0:
			toxin=0;toxin_time=0.0;toxin_tick=1.0;hit_feedback.emit(global_position,"SEPTIC BLOOM x%d" % bloom_stacks,false)
		elif id in ["claw","breath","wall"] and hp>0.0:
			apply_toxin()
	return actual
