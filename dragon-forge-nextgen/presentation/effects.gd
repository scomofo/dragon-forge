extends Node3D
## Bounded decorative effects. Critical hit regions are separate world geometry.
const Geo = preload("res://presentation/geometry.gd")
const Elemental = preload("res://presentation/elemental.gdshader")
const MAX_TRANSIENTS = 32
var particle_budget = 32
var reduced_motion = false
var transients: Array = []

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
	var tween = create_tween()
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
	var node = Geo.label(self, at + Vector3.UP * 3.0, text, Geo.CYAN if blocked else Color("ffdfa8"))
	_reserve(node)
	var tween = create_tween()
	if not reduced_motion:
		tween.parallel().tween_property(node, "position:y", node.position.y + 0.8, 0.7)
	tween.parallel().tween_property(node, "modulate:a", 0.0, 0.75)
	tween.chain().tween_callback(node.queue_free)
