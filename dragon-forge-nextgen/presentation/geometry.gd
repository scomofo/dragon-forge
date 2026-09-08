extends RefCounted
## Small procedural blockout kit. Replace meshes/rigs here, not simulation rules.
const INK = Color("14212c")
const METAL = Color("334b59")
const AMBER = Color("ff753d")
const CYAN = Color("64e7eb")

static func material(color: Color, glow: float = 0.0, unshaded: bool = false) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.55
	mat.roughness = 0.48
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = Color(color.r, color.g, color.b)
		mat.emission_energy_multiplier = glow
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

static func mesh(parent: Node3D, resource: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = resource
	node.material_override = mat
	node.position = at
	parent.add_child(node)
	return node

static func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var resource = BoxMesh.new()
	resource.size = size
	return mesh(parent, resource, at, mat)

static func cylinder(parent: Node3D, at: Vector3, bottom: float, top: float, height: float, mat: Material, sides: int = 8) -> MeshInstance3D:
	var resource = CylinderMesh.new()
	resource.bottom_radius = bottom
	resource.top_radius = top
	resource.height = height
	resource.radial_segments = sides
	return mesh(parent, resource, at, mat)

static func orb(parent: Node3D, at: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var resource = SphereMesh.new()
	resource.radius = radius
	resource.height = radius * 2.0
	resource.radial_segments = 12
	resource.rings = 6
	return mesh(parent, resource, at, mat)

static func ring(parent: Node3D, at: Vector3, radius: float, mat: Material, width: float = 0.065) -> MeshInstance3D:
	var resource = TorusMesh.new()
	resource.inner_radius = maxf(0.01, radius - width)
	resource.outer_radius = radius + width
	resource.rings = 40
	resource.ring_segments = 6
	return mesh(parent, resource, at, mat)

static func label(parent: Node3D, at: Vector3, text: String, color: Color = Color.WHITE) -> Label3D:
	var node = Label3D.new()
	node.position = at
	node.text = text
	node.font_size = 32
	node.pixel_size = 0.008
	node.outline_size = 8
	node.modulate = color
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(node)
	return node

static func solid_box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	box(body, Vector3.ZERO, size, mat)
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body

## One GPU instancing batch per shared box mesh/material, instead of one node per panel.
static func batch_boxes(parent: Node3D, points: Array, size: Vector3, mat: Material) -> MultiMeshInstance3D:
	var node = MultiMeshInstance3D.new()
	var instances = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	var resource = BoxMesh.new()
	resource.size = size
	instances.mesh = resource
	instances.instance_count = points.size()
	for i in range(points.size()):
		instances.set_instance_transform(i, Transform3D(Basis.IDENTITY, points[i]))
	node.multimesh = instances
	node.material_override = mat
	parent.add_child(node)
	return node
