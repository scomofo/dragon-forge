extends Node3D
## Bounded decorative effects. Critical hit regions are separate world geometry.
const Geo = preload("res://presentation/geometry.gd")
const Elemental = preload("res://presentation/elemental.gdshader")
const MAX_TRANSIENTS = 32
var particle_budget = 32
var reduced_motion = false
var transients: Array = []
var number_sequence = 0

func _reserve(node: Node) -> void:
	transients = transients.filter(func(item): return is_instance_valid(item) and not item.is_queued_for_deletion())
	while transients.size() >= MAX_TRANSIENTS:
		var old = transients.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	transients.append(node)

func decal(at: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var resource = PlaneMesh.new()
	resource.size = Vector2.ONE * radius * 2.0
	var mat = ShaderMaterial.new()
	mat.shader = Elemental
	mat.set_shader_parameter("tint", color)
	mat.set_shader_parameter("strength", 0.42 if reduced_motion else 0.8)
	mat.set_shader_parameter("motion", 0.0 if reduced_motion else 1.0)
	return Geo.mesh(self, resource, Vector3(at.x, 0.07, at.z), mat)

func pulse(at: Vector3, radius: float, color: Color = Geo.AMBER) -> void:
	var node = decal(at, radius, color)
	_reserve(node)
	var tween = node.create_tween()
	if not reduced_motion:
		node.scale = Vector3.ONE * 0.72
		tween.parallel().tween_property(node, "scale", Vector3.ONE * 1.08, 0.38)
	tween.parallel().tween_property(node.material_override, "shader_parameter/strength", 0.0, 0.48)
	tween.chain().tween_callback(node.queue_free)
	if particle_budget > 0 and DisplayServer.get_name() != "headless":
		_sparks(at, color)

func _sparks(at: Vector3, color: Color) -> void:
	var particles = GPUParticles3D.new()
	_reserve(particles)
	particles.position = at + Vector3.UP * 0.3
	particles.amount = particle_budget
	particles.lifetime = 0.55
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.local_coords = false
	particles.visibility_aabb = AABB(Vector3(-8, -3, -8), Vector3(16, 12, 16))
	var process = ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 70.0
	process.initial_velocity_min = 2.0
	process.initial_velocity_max = 5.5
	process.gravity = Vector3(0, -7, 0)
	process.scale_min = 0.4
	process.scale_max = 1.1
	particles.process_material = process
	var spark = BoxMesh.new()
	spark.size = Vector3(0.07, 0.16, 0.07)
	spark.material = Geo.material(color, 2.0, true)
	particles.draw_pass_1 = spark
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(0.8, false).timeout.connect(particles.queue_free)

func number(at: Vector3, text: String, blocked: bool = false) -> void:
	number_sequence = (number_sequence + 1) % 3
	var node = Geo.label(self, at + Vector3((number_sequence - 1) * 0.30, 2.5 + number_sequence * 0.24, 0), text, Geo.CYAN if blocked else Color("ffdfa8"))
	_reserve(node)
	var tween = node.create_tween()
	if not reduced_motion:
		tween.parallel().tween_property(node, "position:y", node.position.y + 0.8, 0.7)
	tween.parallel().tween_property(node, "modulate:a", 0.0, 0.75)
	tween.chain().tween_callback(node.queue_free)

## Contact effects have separate silhouettes; not four recolored explosion circles.
## reach is clipped by the caller's world ray queries before drawing breath geometry.
func attack(id: String, origin: Vector3, direction: Vector3, reach: float) -> void:
	if id == "burst":
		pulse(origin, reach, Geo.AMBER)
		return
	var node = Node3D.new()
	node.position = origin
	node.rotation.y = atan2(-direction.x, -direction.z)
	add_child(node)
	_reserve(node)
	var hot = Geo.material(Color("ffba5d"), 1.2, true)
	if id == "claw":
		for i in range(9):
			var angle = -0.8 + i * 0.20
			var strip = Geo.box(node, Vector3(sin(angle) * 2.0, 0.85, -cos(angle) * 2.0), Vector3(0.41, 0.045, 0.08), hot)
			strip.rotation.y = -angle
	else:
		# A tapering column from the muzzle, with discrete embers at the tip.
		var fire = Geo.material(Color(1.0, 0.32, 0.06, 0.50), 1.0, true)
		var cone = Geo.cylinder(node, Vector3(0, 1.35, -reach * 0.5 - 0.6), 0.10, 0.70, reach, fire, 7)
		cone.rotation.x = -PI / 2.0
		for i in range(4):
			Geo.orb(node, Vector3(sin(i * 2.3) * 0.28, 1.30 + (i % 2) * 0.20, -reach * (0.3 + i * 0.2)), 0.12 + i * 0.045, hot)
	var tween = node.create_tween()
	if not reduced_motion:
		tween.tween_property(node, "scale", Vector3(1.0, 0.30, 1.0), 0.20)
	else:
		tween.tween_interval(0.20)
	tween.tween_callback(node.queue_free)

func flame_field(at: Vector3, radius: float) -> MeshInstance3D:
	var marker = decal(at, radius, Geo.AMBER)
	# Always-visible boundary stays independent of animated/decorative flames.
	Geo.ring(marker, Vector3(0, 0.025, 0), radius, Geo.material(Color("ffb46a"), 0.6, true), 0.04)
	for i in range(5):
		var angle = TAU * i / 5.0
		var flame = Geo.cylinder(marker, Vector3(sin(angle) * 1.3, 0.40, cos(angle) * 1.3), 0.22, 0.0, 0.75, Geo.material(Color(1.0, 0.32, 0.07, 0.62), 0.6, true), 5)
		flame.rotation.z = sin(angle) * 0.18
	return marker

func set_calm(value: bool) -> void:
	reduced_motion = value
	if value:
		# Clear only decorative transients; persistent combat fields are not reserved here.
		for node in transients:
			if is_instance_valid(node):
				node.queue_free()
		transients.clear()
