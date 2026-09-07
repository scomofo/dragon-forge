extends Node3D
## Interactive inspection scene. Never changes the shipped assets or player save.
const Art = preload("res://presentation/art_library.gd")
const UI = preload("res://validation/review_ui.gd")
const Probe = preload("res://validation/foot_review.gd")
const ACTORS = ["magma_guardian", "firewall_sentinel", "packet_warden", "ice_guardian", "magma_evolved", "rime_evolved", "storm_guardian", "tempest_arc"]
const VIEWS = ["Full body", "Shoulders", "Hips / feet", "Jaw / head", "Rear / tail"]
var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var camera: Camera3D
var key: DirectionalLight3D
var rim: OmniLight3D
var feet
var view_picker: OptionButton
var material_picker: OptionButton
var clip_picker: OptionButton
var timeline: HSlider
var status: Label
var notice: Label
var play_button: Button
var all_toggle: CheckButton
var bones: MeshInstance3D
var bone_lines: ImmediateMesh
var clips: Array = []
var actor_id = "magma_guardian"
var clip = "idle"
var clip_time = 0.0
var playing = true
var cycle_all = true
var speed = 1.0
var orbit = 0.55
var elevation = 0.24
var distance = 7.3
var focus = Vector3(0, 1.4, 0.1)
var show_bones = false
var view_index = 0
var material_mode = 0
var source_material: StandardMaterial3D
var actor_mesh: MeshInstance3D
var duration_label: Label

func _ready() -> void:
	_build_stage()
	_build_controls()
	load_actor(0)

func _build_stage() -> void:
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("17232d")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.45
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	key = DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, -28, 0)
	key.light_color = Color.WHITE
	key.light_energy = 1.6
	key.shadow_enabled = true
	add_child(key)
	rim = OmniLight3D.new()
	rim.position = Vector3(-3, 3.5, 2.7)
	rim.light_color = Color("b1dbec")
	rim.light_energy = 4.0
	rim.omni_range = 10
	add_child(rim)
	var stage = PlaneMesh.new()
	stage.size = Vector2(14, 14)
	var floor = MeshInstance3D.new()
	floor.mesh = stage
	floor.material_override = StandardMaterial3D.new()
	floor.material_override.albedo_color = Color("39454c")
	floor.material_override.roughness = 0.95
	add_child(floor)
	Probe.surface(self, stage, Transform3D.IDENTITY)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 38
	camera.h_offset = -0.9
	camera.near = 0.03
	add_child(camera)
	feet = Probe.new()
	add_child(feet)
	bone_lines = ImmediateMesh.new()
	bones = MeshInstance3D.new()
	bones.mesh = bone_lines
	bones.material_override = StandardMaterial3D.new()
	bones.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bones.material_override.albedo_color = Color("93e3ef")
	bones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bones)

func _build_controls() -> void:
	var layer = CanvasLayer.new()
	add_child(layer)
	var box = UI.panel(layer, Vector2(18, 18), 296)
	UI.text(box, "CHARACTER / INSPECTION", 19)
	UI.text(box, "Actual imported art • save-safe", 12)
	UI.picker(box, ["Magma guardian", "Firewall Sentinel", "Packet Warden", "Rime / Ice guardian", "Crowned Magma / Evolved", "Aurora Rime / Evolved", "Arc / Storm fusion", "Tempest Arc / Evolved"], load_actor)
	clip_picker = UI.picker(box, [], select_clip)
	var transport = UI.row(box)
	play_button = UI.button(transport, "Pause", toggle_play)
	UI.button(transport, "- frame", func(): step_frame(-1))
	UI.button(transport, "+ frame", func(): step_frame(1))
	timeline = HSlider.new()
	timeline.step = 0.001
	timeline.value_changed.connect(scrub)
	box.add_child(timeline)
	duration_label = UI.text(box, "", 13)
	var rates = UI.picker(box, ["0.25x playback", "0.5x playback", "1x playback", "2x playback"], func(i): speed = [0.25, 0.5, 1.0, 2.0][i])
	rates.select(2)
	all_toggle = UI.toggle(box, "Cycle every clip", true, func(v): cycle_all = v)
	view_picker = UI.picker(box, VIEWS, set_view)
	material_picker = UI.picker(box, ["Full PBR material", "Albedo only", "Neutral clay / volume"], set_material)
	UI.toggle(box, "Strong rim light", true, func(v): rim.visible = v)
	UI.toggle(box, "Skeleton overlay", false, func(v): show_bones = v)
	UI.toggle(box, "Sole probes", true, func(v): feet.display_enabled = v; feet._draw())
	UI.button(box, "Export review JSON", export_review)
	status = UI.text(box, "", 13)
	notice = UI.text(box, "RMB drag: orbit • Wheel: zoom\nScrub / step pauses at the exact pose.\nWalk here is in place; use arena for travel.", 12)
	notice.modulate = Color("acbec7")

func load_actor(index: int) -> void:
	if index < 0 or index >= ACTORS.size():
		return
	if is_instance_valid(model):
		remove_child(model)
		model.queue_free()
	actor_id = ACTORS[index]
	if actor_id in ["magma_evolved", "rime_evolved"]:
		model=load("res://campaign/evolutions/"+actor_id+".glb").instantiate()
		add_child(model)
	elif actor_id in ["ice_guardian","rime_evolved"]:
		model=preload("res://campaign/guardians/ice_guardian.glb").instantiate()
		add_child(model)
	elif actor_id in ["storm_guardian", "tempest_arc"]:
		model = load("res://campaign/tempest/tempest_arc.glb" if actor_id == "tempest_arc" else "res://campaign/fusion_assets/storm_guardian.glb").instantiate()
		add_child(model)
	else:
		model = Art.place(self, actor_id)
	skeleton = model.find_child("Skeleton3D", true, false)
	player = model.find_child("AnimationPlayer", true, false)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	actor_mesh = model.find_children("*", "MeshInstance3D", true, false)[0]
	source_material = actor_mesh.get_active_material(0)
	clips.clear()
	clip_picker.clear()
	for name_text in player.get_animation_list():
		if name_text != "RESET":
			clips.append(String(name_text))
			clip_picker.add_item(String(name_text))
	feet.configure(model, "magma_guardian" if actor_id=="magma_evolved" else ("ice_guardian" if actor_id=="rime_evolved" else actor_id))
	set_material(material_mode)
	select_clip(clips.find("idle") if clips.has("idle") else 0, false)
	set_view(view_index)

func select_clip(index: int, manual: bool = true) -> void:
	if index < 0 or index >= clips.size():
		return
	clip = clips[index]
	clip_time = 0.0
	clip_picker.select(index)
	timeline.max_value = player.get_animation(clip).length
	feet.reset()
	if manual:
		cycle_all = false
		all_toggle.set_pressed_no_signal(false)
	_sample()

func toggle_play() -> void:
	playing = not playing
	play_button.text = "Pause" if playing else "Play"

func scrub(value: float) -> void:
	playing = false
	play_button.text = "Play"
	clip_time = clampf(value, 0, player.get_animation(clip).length)
	feet.reset() # Discontinuous seeks cannot be counted as sliding.
	_sample()
	feet.sample(0.0, clip, clip_time, "studio paused pose")
	status.text = feet.readout()

func step_frame(direction: int) -> void:
	scrub(clip_time + direction / 60.0)

func _sample() -> void:
	skeleton.reset_bone_poses()
	Art.sample(player, clip, clip_time)
	timeline.set_value_no_signal(clip_time)
	duration_label.text = "%s   %.3f / %.3f s" % [clip, clip_time, player.get_animation(clip).length]
	_draw_bones()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if playing:
		clip_time += delta * speed
		var length = player.get_animation(clip).length
		if clip_time > length + 0.35:
			if cycle_all:
				select_clip((clips.find(clip) + 1) % clips.size(), false)
			else:
				clip_time = 0.0
				feet.reset()
		_sample()
		feet.sample(delta * speed, clip, minf(clip_time, player.get_animation(clip).length), "studio in-place")
	else:
		_draw_bones()
	status.text = feet.readout()

func set_view(index: int) -> void:
	view_index = index
	view_picker.select(index)
	focus = [Vector3(0, 1.4, 0.1), Vector3(0, 1.85, -0.18), Vector3(0, 0.65, 0.0), Vector3(0, 2.24, -0.75), Vector3(0, 1.3, 0.6)][index]
	if actor_id in ["ice_guardian","rime_evolved"]:
		focus=[Vector3(0,1.0,.3),Vector3(0,1.1,-.5),Vector3(0,.5,.4),Vector3(0,1.2,-1.2),Vector3(0,.9,1.1)][index]
	distance = [7.3, 3.6, 4.6, 2.8, 7.0][index]
	orbit = 3.7 if index == 4 else 0.55
	elevation = 0.24
	_update_camera()

func _update_camera() -> void:
	camera.position = focus + Vector3(sin(orbit) * cos(elevation), sin(elevation), -cos(orbit) * cos(elevation)) * distance
	camera.h_offset = -distance * 0.12
	camera.look_at(focus)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		orbit -= event.relative.x * 0.008
		elevation = clampf(elevation + event.relative.y * 0.006, -0.1, 1.25)
		_update_camera()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(1.2, distance * 0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(16, distance * 1.1)
		_update_camera()

func set_material(index: int) -> void:
	material_mode = index
	material_picker.select(index)
	if actor_mesh == null:
		return
	var mat = source_material.duplicate()
	if index == 1:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = false
	elif index == 2:
		mat.albedo_texture = null
		mat.albedo_color = Color("9fadb5")
		mat.normal_enabled = false
		mat.ao_enabled = false
		mat.metallic_texture = null
		mat.roughness_texture = null
		mat.metallic = 0
		mat.roughness = 0.85
		mat.emission_enabled = false
	actor_mesh.material_override = mat

func _draw_bones() -> void:
	bone_lines.clear_surfaces()
	if not show_bones or skeleton == null:
		return
	bone_lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(skeleton.get_bone_count()):
		var parent = skeleton.get_bone_parent(i)
		if parent >= 0:
			bone_lines.surface_add_vertex(to_local(skeleton.global_transform * skeleton.get_bone_global_pose(i).origin))
			bone_lines.surface_add_vertex(to_local(skeleton.global_transform * skeleton.get_bone_global_pose(parent).origin))
	bone_lines.surface_end()

func export_review() -> void:
	var path = Probe.save_report(feet.report({"scene": "character_inspection", "clip": clip, "sample_time": clip_time, "playback_speed": speed, "material_mode": material_mode, "in_place": true}))
	notice.text = path if path.begins_with("ERROR") else "Report saved in user://validation_reviews\nUse Godot: Project > Open User Data Folder"
