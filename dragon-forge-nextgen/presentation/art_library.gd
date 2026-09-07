extends RefCounted
## Runtime loads shipped glTF assets. No Python, Blender or mesh construction at play time.
const ASSETS = {
	"magma_guardian": preload("res://art/generated/magma_guardian.glb"),
	"firewall_sentinel": preload("res://art/generated/firewall_sentinel.glb"),
	"packet_warden": preload("res://art/generated/packet_warden.glb"),
	"deck_panel": preload("res://art/generated/deck_panel.glb"),
	"bulkhead": preload("res://art/generated/bulkhead.glb"),
	"relay_conduit": preload("res://art/generated/relay_conduit.glb"),
	"incubator": preload("res://art/generated/incubator.glb"),
	"core_socket": preload("res://art/generated/core_socket.glb"),
	"magma_egg": preload("res://art/generated/magma_egg.glb"),
	"furnace": preload("res://art/generated/furnace.glb"),
	"anvil": preload("res://art/generated/anvil.glb"),
	"breach_arch": preload("res://art/generated/breach_arch.glb"),
	"relay_pylon": preload("res://art/generated/relay_pylon.glb"),
	"warden_dais": preload("res://art/generated/warden_dais.glb"),
	"cable_tray": preload("res://art/generated/cable_tray.glb"),
}

static func place(parent: Node3D, id: String, at: Vector3 = Vector3.ZERO) -> Node3D:
	assert(ASSETS.has(id), "Missing production asset: " + id)
	var node: Node3D = ASSETS[id].instantiate()
	node.name = id.to_pascal_case()
	node.position = at
	node.set_meta("art_asset", id)
	parent.add_child(node)
	return node

static func source_mesh(id: String) -> Mesh:
	var node: Node3D = ASSETS[id].instantiate()
	var meshes = node.find_children("*", "MeshInstance3D", true, false)
	assert(meshes.size() == 1, "Batch assets must have a single combined mesh")
	var mesh: Mesh = meshes[0].mesh
	node.free()
	return mesh

static func batch(parent: Node3D, id: String, transforms: Array) -> MultiMeshInstance3D:
	var node = MultiMeshInstance3D.new()
	node.name = id.to_pascal_case() + "Batch"
	node.multimesh = MultiMesh.new()
	node.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	node.multimesh.mesh = source_mesh(id)
	node.multimesh.instance_count = transforms.size()
	for i in range(transforms.size()):
		node.multimesh.set_instance_transform(i, transforms[i])
	node.set_meta("art_asset", id)
	parent.add_child(node)
	return node

static func sample(player: AnimationPlayer, clip: String, time: float) -> void:
	assert(player.has_animation(clip), "Missing authored animation: " + clip)
	# Explicit sampling: simulation owns attack contact. glTF contains no method tracks.
	player.play(clip, 0.0)
	player.seek(clampf(time, 0.0, player.get_animation(clip).length), true)
	player.pause()
