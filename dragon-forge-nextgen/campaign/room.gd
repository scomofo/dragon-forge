extends Node3D
## Streaming authored rooms: different footprints, branches, landmarks and interactions.
const Data = preload("res://campaign/data.gd")
const Art = preload("res://presentation/art_library.gd")
const Geo = preload("res://presentation/geometry.gd")
var definition: Dictionary = {}
var cells: Dictionary = {}
var doors: Array = []
var stations: Array = []
var relay_nodes: Array = []
var hazard_nodes: Array = []
var optional: Node3D
var nav: AStarGrid2D
var color = Color("ecb270")
var core_node: Node3D
var egg: Node3D
var badge_nodes: Array = []
const IceEgg = preload("res://campaign/guardians/ice_egg.glb")
var ice_egg: Node3D

func build(data: Dictionary) -> void:
	definition = data
	color = Color(Data.zone(data.zone).color)
	optional = Node3D.new()
	add_child(optional)
	_layout()
	var floors: Array = []
	var rails: Array = []
	var physical = StaticBody3D.new()
	physical.collision_layer = 1
	physical.collision_mask = 0
	add_child(physical)
	var plate_shape = BoxShape3D.new()
	plate_shape.size = Vector3(4.0, 0.6, 4.0)
	var rail_mat = Geo.material(color.darkened(0.45), 0.18)
	for cell in cells:
		var at = Vector3(cell.x * 4, 0, cell.y * 4)
		floors.append(Transform3D(Basis.IDENTITY, at))
		var collision = CollisionShape3D.new()
		collision.shape = plate_shape
		collision.position = at + Vector3(0, -0.3, 0)
		physical.add_child(collision)
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if cells.has(cell + d):
				continue
			var edge = at + Vector3(d.x * 1.97, 0.50, d.y * 1.97)
			var size = Vector3(0.12, 1.0, 4.0) if d.x != 0 else Vector3(4.0, 1.0, 0.12)
			Geo.solid_box(self, edge, size, rail_mat)
			Geo.box(self, edge + Vector3.UP * 0.48, Vector3(size.x, 0.04, size.z), Geo.material(color, 0.4))
	Art.batch(self, "deck_panel", floors)
	nav = AStarGrid2D.new()
	nav.region = Rect2i(-8, -10, 17, 17)
	nav.cell_size = Vector2(4, 4)
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	nav.update()
	nav.fill_solid_region(nav.region, true)
	for cell in cells:
		nav.set_point_solid(cell, false)
	for exit in definition.exits:
		_add_door(exit)
	for relay in definition.relays:
		var node = Art.place(self, "relay_conduit", Data.v3(relay.at))
		var label = Geo.label(node, Vector3(0,2.5,0), "HEAT RELAY", color)
		label.font_size = 26
		relay_nodes.append({"id": relay.id, "node": node, "label": label})
	for item in definition.hazards:
		var marker = Geo.ring(self, Data.v3(item.at)+Vector3.UP*0.15, item.radius, Geo.material(color,0.15,true),0.08)
		hazard_nodes.append({"definition": item, "node": marker, "previous_cycle": -1})
	_art_direction()
	_interactables()

func _add_rect(x0: int, x1: int, z0: int, z1: int) -> void:
	for x in range(x0, x1+1):
		for z in range(z0, z1+1):
			cells[Vector2i(x,z)] = true

func _layout() -> void:
	var role: String = definition.role
	var theme: String = Data.zone(definition.zone).theme
	if role in ["forge", "shelter", "cache"]:
		_add_rect(-3, 3, -3, 3)
		if role == "forge":
			_add_rect(-2, 2, -5, -4)
	elif role == "path":
		match theme:
			"foundry":
				_add_rect(-2,2,0,3)
				_add_rect(-1,1,-4,0)
				_add_rect(-3,3,-6,-4)
			"ice":
				_add_rect(-3,1,0,3)
				_add_rect(-1,1,-3,0)
				_add_rect(-1,3,-6,-3)
			"storm":
				_add_rect(-1,1,-6,3)
				_add_rect(-4,-2,-4,-2)
				_add_rect(-4,-1,-2,-2)
				_add_rect(2,4,0,2)
				_add_rect(1,4,0,0)
			_:
				_add_rect(-1,1,1,3)
				_add_rect(-3,3,-4,0)
				_add_rect(-1,1,-6,-5)
	elif role == "gate":
		_add_rect(-3,3,-6,3)
		# A left alcove physically connects the optional cache portal.
		_add_rect(-4,-4,-4,-2)
	else:
		_add_rect(-4,4,-6,3)
		for c in cells.keys():
			if abs(c.x) == 4 and (c.y == -6 or c.y == 3):
				cells.erase(c)

func _add_door(exit: Dictionary) -> void:
	var at = Data.v3(exit.at)
	var portal = Node3D.new()
	portal.position = at
	add_child(portal)
	var arch = Art.place(portal, "breach_arch")
	arch.scale = Vector3.ONE * 0.78
	var disc = Geo.ring(portal, Vector3(0,0.17,0), 1.65, Geo.material(color,1.0,true))
	var label = Geo.label(portal, Vector3(0,3.2,0), exit.label.to_upper(), color)
	label.font_size = 26
	if at.x < -5:
		arch.rotation.y = PI/2
	doors.append({"definition":exit, "node":portal, "label":label, "disc":disc})

func _station(kind: String, name_text: String, at: Vector3, asset: String) -> Node3D:
	var node = Art.place(self, asset, at)
	var label = Geo.label(node, Vector3(0,2.6,0), name_text, color)
	label.font_size = 25
	stations.append({"kind":kind, "name":name_text, "node":node})
	return node

func _interactables() -> void:
	if definition.role == "forge":
		var hatch = _station("hatch", "HATCH / REST", Vector3(-2,0,8), "incubator")
		egg = Art.place(hatch,"magma_egg")
		_station("forge", "CORES / MODULES", Vector3(5,0,5), "core_socket")
		_station("upgrade", "FORGE UPGRADES", Vector3(-7,0,2), "anvil")
		_station("lore", "FELIX / RADIO", Vector3(7,0,-5), "relay_conduit")
		var ice_ring=_station("hatch_ice", "GUARDIAN NURSERY",Vector3(6,0,8),"incubator")
		ice_egg=IceEgg.instantiate();ice_ring.add_child(ice_egg)
		_add_door({"to":"map", "at":[0,0,-14], "label":"EXPEDITIONS  [E]"})
		for i in range(4):
			var p = Vector3(-5+i*3.3,0,-8)
			Art.place(self,"core_socket",p).scale = Vector3.ONE*0.45
			var gem = Geo.orb(self,p+Vector3.UP,0.24,Geo.material(Color(Data.ZONES[i].color),1.2,true))
			badge_nodes.append(gem)
	elif definition.role == "shelter":
		_station("rest", "REST LANTERN", Vector3(-6,0,1), "incubator")
		_station("lore", "FELIX / FIELD NOTE", Vector3(6,0,-3), "relay_conduit")
	elif definition.role == "cache":
		_station("cache", "SALVAGE CACHE", Vector3(0,0,-6), "core_socket")
		_station("lore", "RECOVERED RECORD", Vector3(-6,0,0), "relay_conduit")
		if definition.id=="frozen-vault":
			var plinth=_station("ice_egg","RESCUE ICE EGG",Vector3(6,0,-4),"incubator")
			ice_egg=IceEgg.instantiate();plinth.add_child(ice_egg)
	elif definition.role in ["boss","final"]:
		core_node = _station("finish" if definition.role=="final" else "core", "RECONNECT" if definition.role=="final" else "SECTOR CORE",Vector3(0,0,-19),"core_socket")
		Geo.orb(core_node,Vector3(0,1.7,0),0.4,Geo.material(color,1.5,true))
		Art.place(self,"warden_dais",Vector3(0,0,-13))
	else:
		_station("lore", "FIELD RECORD", Vector3(6 if cells.has(Vector2i(2,1)) else -4,0,4),"relay_conduit")

func _art_direction() -> void:
	var theme: String = Data.zone(definition.zone).theme
	var role: String = definition.role
	var outlines: Array = []
	for cell in cells:
		if not cells.has(cell+Vector2i.LEFT) and cell.y % 3 == 0:
			outlines.append(Vector3(cell.x*4-4,0,cell.y*4))
		if not cells.has(cell+Vector2i.RIGHT) and cell.y % 3 == 0:
			outlines.append(Vector3(cell.x*4+4,0,cell.y*4))
	for i in range(outlines.size()):
		var at: Vector3 = outlines[i]
		var pylon = Art.place(self,"relay_pylon",at+Vector3(0,-1,0))
		pylon.scale.y = 1.0 + float(i%3)*0.18
		if theme == "ice":
			for j in range(3):
				var shard = Geo.cylinder(self,at+Vector3(j*0.7-0.8,1.0,0.8),0.65,0,3.5+j*0.6,Geo.material(Color("648da9"),0.1),5)
				shard.rotation.z = (j-1)*0.2
		elif theme == "storm":
			var ring = Geo.ring(optional,at+Vector3.UP*4,1.3,Geo.material(color,0.5,true),0.035)
			ring.rotation.x = PI/2
		elif theme == "void":
			var monolith=Geo.box(self,at+Vector3.UP*1.4,Vector3(1.5,5.0,0.5),Geo.material(Color("201c35")))
			monolith.rotation.z=(i%2*2-1)*0.12
			Geo.ring(optional,at+Vector3.UP*4.2,0.8,Geo.material(color,0.6,true)).rotation.x=PI/2
	if theme == "foundry":
		for side in [-1,1]:
			var at=Vector3(side*9,0,-6 if role=="forge" else -18)
			if cells.has(Vector2i(int(round(at.x/4)),int(round(at.z/4)))):
				Art.place(self,"furnace",at)
				Geo.solid_box(self,at+Vector3.UP*1.2,Vector3(2.1,2.4,1.8),Geo.material(Color(0,0,0,0))).visible=false
	var route_marks: Array = []
	for cell in cells:
		if cell.x==0:
			route_marks.append(Vector3(-1.45,0.11,cell.y*4))
			route_marks.append(Vector3(1.45,0.11,cell.y*4))
	Geo.batch_boxes(self,route_marks,Vector3(0.06,0.025,1.3),Geo.material(color,0.3))
	if role in ["boss","final"]:
		for side in [-1,1]:
			Geo.box(self,Vector3(side*13,3,-23),Vector3(2,8,1),Geo.material(Color("292b37")))
			Geo.ring(self,Vector3(side*13,5,-22.3),1.6,Geo.material(color,0.5,true)).rotation.x=PI/2

func refresh(state: Dictionary) -> void:
	if is_instance_valid(ice_egg):
		ice_egg.visible=(not state.get("ice_rescued",false)) if definition.id=="frozen-vault" else (state.get("ice_rescued",false) and not state.get("guardians",["fire"]).has("ice"))
	for station in stations:
		if station.kind=="ice_egg":station.node.visible=not state.get("ice_rescued",false)
	if is_instance_valid(egg):
		egg.visible = not state.hatched
	for i in range(badge_nodes.size()):
		badge_nodes[i].visible = state.installed.has(Data.ZONES[i].id)
	if is_instance_valid(core_node):
		core_node.visible = Data.room_cleared(state,definition.id) and (not state.finished if definition.role=="final" else not state.cores.has(definition.zone))
	for door in doors:
		var reason = "" if door.definition.to=="map" else Data.exit_reason(state,definition.id,door.definition)
		door.label.text = door.definition.label.to_upper()+ ("\n"+reason if reason!="" else "\n[ E / B ]")
		door.disc.material_override.albedo_color = color if reason=="" else Color("68717e")
	for station in stations:
		if station.kind == "cache":
			station.node.visible = not state.caches.has(definition.id)

func set_quality(value: int) -> void:
	optional.visible = value >= 2

func direction(from: Vector3, to: Vector3) -> Vector3:
	var start = Vector2i(roundi(from.x/4),roundi(from.z/4))
	var goal = Vector2i(roundi(to.x/4),roundi(to.z/4))
	if not nav.is_in_boundsv(start) or not nav.is_in_boundsv(goal) or nav.is_point_solid(start) or nav.is_point_solid(goal):
		return Vector3.ZERO
	var path = nav.get_id_path(start,goal)
	var desired = to
	if path.size()>1:
		desired=Vector3(path[1].x*4,from.y,path[1].y*4)
	var offset=desired-from
	offset.y=0
	return offset.normalized()
