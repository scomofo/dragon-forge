extends "res://world/main.gd"
## An isolated subclass of the real game, not a second combat implementation.
## No asset, combat rule, camera implementation or normal save is changed here.
const UI = preload("res://validation/review_ui.gd")
const Probe = preload("res://validation/foot_review.gd")
const Observer = preload("res://validation/arena_observer.gd")
const SCENARIOS = ["Manual play", "Walk / stop / reverse", "Guard + strafe", "Claw: stationary", "Breath: stationary", "Wall: stationary", "Burst: stationary", "Breath while moving"]
const INJECTED = ["ng_up", "ng_down", "ng_left", "ng_right", "ng_guard", "ng_claw", "ng_breath", "ng_wall", "ng_burst"]
var feet
var scenario_picker: OptionButton
var stage_picker: OptionButton
var review_status: Label
var review_notice: Label
var review_box: Control
var scenario = 0
var stage_index = 2
var freeze_next_contact = false
var freeze_pending = false
var replaying = false
var replay_clock = 0.0
var review_clock = 0.0
var replay_cast = false
var contact_events: Array = []
var start_events: Array = []
var max_contacts = 256
var layer: CanvasLayer

func _init() -> void:
	test_mode = true # Set BEFORE the base _ready can load either save or preferences.

func _ready() -> void:
	super._ready()
	process_physics_priority = -20
	_build_review_surfaces()
	feet = Probe.new()
	add_child(feet)
	feet.configure(dragon.rig.model, "magma_guardian")
	_build_review_controls()
	dragon.ability_started.connect(_review_started)
	dragon.ability_used.connect(_review_contact)
	var observer = Observer.new()
	observer.review = self
	add_child(observer)
	reset_stage()

func _build_review_surfaces() -> void:
	# Collision layer 128 is used ONLY by probe rays. Actors and combat rays ignore it.
	var floor_batch: MultiMeshInstance3D = dressing.art_batches[0]
	var shape = floor_batch.multimesh.mesh.create_trimesh_shape()
	for i in range(floor_batch.multimesh.instance_count):
		var body = StaticBody3D.new()
		body.collision_layer = Probe.SURFACE_LAYER
		body.collision_mask = 0
		body.transform = floor_batch.transform * floor_batch.get_meta("art_transforms")[i]
		var collider = CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
		dressing.add_child(body)
	var dais: Node3D = dressing.find_child("WardenDais", false, false)
	if dais != null:
		var mesh: MeshInstance3D = dais.find_children("*", "MeshInstance3D", true, false)[0]
		Probe.surface(self, mesh.mesh, global_transform.affine_inverse() * mesh.global_transform)

func _build_review_controls() -> void:
	layer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var box = UI.panel(layer, Vector2(24, 253), 280)
	box.add_theme_constant_override("separation", 4)
	review_box = box.get_parent()
	UI.text(box, "ARENA / VALIDATION", 17)
	UI.text(box, "Original camera + combat • no saves", 12)
	stage_picker = UI.picker(box, ["Movement lane (no enemy)", "Firewall Sentinel", "Packet Warden"], func(i): stage_index = i; reset_stage())
	stage_picker.select(stage_index)
	scenario_picker = UI.picker(box, SCENARIOS, func(i): stop_replay(); scenario = i)
	var row = UI.row(box)
	UI.button(row, "Run replay", start_replay)
	UI.button(row, "Reset", reset_stage)
	UI.button(row, "Export", export_review)
	review_status = UI.text(box, "", 12)
	review_status.tooltip_text = "Skinned-sole clearance above the visible deck; drift is measured during authored planted intervals."
	review_notice = UI.text(box, "F6 reset • F7 overlay • F8 export\nF9 freeze next contact • F10 resume\nF11: compare foot correction on/off", 12)
	review_notice.modulate = Color("abc0ca")

func reset_stage() -> void:
	stage_picker.select(stage_index)
	scenario_picker.select(scenario)
	stop_replay()
	hud.close_overlay()
	_clear_encounter()
	trial_active = false
	progress = Progress.fresh()
	progress.hatched = true
	progress.gate_open = true
	progress.clears = 3 if stage_index == 0 else (0 if stage_index == 1 else 2)
	interwave_delay = 0.0
	var start = Vector3(0, 0.1, -4.0) if stage_index != 2 else Vector3(0, 0.1, -14.3)
	dragon.respawn(start)
	_apply_progress()
	camera_rig.global_position = dragon.global_position
	if stage_index != 0:
		start_encounter()
	hud.toast_remaining = 0
	if feet != null:
		feet.reset()
	freeze_pending = false
	contact_events.clear()
	start_events.clear()
	review_clock = 0.0

func start_replay() -> void:
	if scenario == 0 or get_tree().paused:
		return
	reset_stage()
	replaying = true
	replay_clock = 0.0
	replay_cast = false
	dragon.mouse_aim = false
	dragon.aim = Vector3.FORWARD

func stop_replay() -> void:
	if replaying:
		for action in INJECTED:
			Input.action_release(action)
	replaying = false

func _physics_process(delta: float) -> void:
	if replaying:
		replay_clock += delta
		for action in INJECTED:
			Input.action_release(action)
		if dragon.state.hp <= 0.0 or replay_clock > 3.5:
			stop_replay()
		elif scenario == 1:
			if replay_clock >= 0.4 and replay_clock < 1.05:
				Input.action_press("ng_up")
			elif replay_clock >= 1.5 and replay_clock < 2.15:
				Input.action_press("ng_down")
		elif scenario == 2:
			if replay_clock > 0.3 and replay_clock < 2.5:
				Input.action_press("ng_guard")
			if replay_clock > 0.5 and replay_clock < 1.05:
				Input.action_press("ng_left")
			elif replay_clock > 1.5 and replay_clock < 2.05:
				Input.action_press("ng_right")
		else:
			if scenario == 7 and replay_clock > 0.35 and replay_clock < 1.0:
				Input.action_press("ng_up")
			if replay_clock >= 0.5 and not replay_cast:
				var id = "breath" if scenario == 7 else ["claw", "breath", "wall", "burst"][scenario - 3]
				Input.action_press("ng_" + id)
				replay_cast = true
	super._physics_process(delta)

func observe_frame(delta: float) -> void:
	review_clock += delta
	feet.sample(delta, dragon.rig.sampled_clip, dragon.rig.sampled_time, SCENARIOS[scenario], dragon.rig.feet.samples)
	review_status.text = feet.readout().trim_prefix("Sole probes / visible surface\n") + "\nContacts: %d | %s" % [contact_events.size(), "replay at 1x" if replaying else "manual / observation"]

	if freeze_pending:
		freeze_pending = false
		freeze_next_contact = false
		review_notice.text = "Paused after actual contact.\nF10 resumes • F8 exports the take.\nNo time-scale or combat-rule changes."
		get_tree().paused = true

func _review_started(id: String) -> void:
	if start_events.size() < max_contacts:
		start_events.append({"t": review_clock, "id": id, "physics_frame": Engine.get_physics_frames()})

func _review_contact(id: String, origin: Vector3, direction: Vector3) -> void:
	if freeze_next_contact:
		freeze_pending = true
	if contact_events.size() < max_contacts:
		contact_events.append({"t": review_clock, "id": id, "action_time": dragon.state.action_time, "authored_windup": Combat.ABILITIES[id].windup, "physics_frame": Engine.get_physics_frames(), "origin": [origin.x, origin.y, origin.z], "aim": [direction.x, direction.y, direction.z]})

func review_report() -> Dictionary:
	var data = feet.report({"scene": "gameplay_arena", "scenario": SCENARIOS[scenario], "stage": stage_index, "physics_hz": Engine.physics_ticks_per_second, "time_scale": Engine.time_scale, "camera": "res://presentation/camera_rig.gd (unchanged)", "quality": quality_index, "reduced_motion": reduced_motion, "save_writes": false, "foot_lock_enabled": dragon.rig.foot_lock_enabled})
	data["ability_starts"] = start_events
	data["ability_contacts"] = contact_events
	data["contact_log_limit"] = max_contacts
	return data

func export_review() -> void:
	var path = Probe.save_report(review_report())
	review_notice.text = path if path.begins_with("ERROR") else "Saved in user://validation_reviews\nProject > Open User Data Folder\nF7 hides review UI + sole probes."

func review_key(code: int) -> void:
	match code:
		KEY_F6:
			reset_stage()
		KEY_F7:
			review_box.visible = not review_box.visible
			feet.display_enabled = review_box.visible
			feet._draw()
		KEY_F8:
			export_review()
		KEY_F9:
			freeze_next_contact = not freeze_next_contact
			review_notice.text = "Next contact will pause after posing.\nF10 resumes • F8 exports the take." if freeze_next_contact else "Contact pause disarmed. F9 to arm."
		KEY_F10:
			hud.close_overlay()
		KEY_F11:
			dragon.rig.foot_lock_enabled = not dragon.rig.foot_lock_enabled
			dragon.rig.feet.reset()
			feet.reset()
			review_notice.text = "Foot correction: %s\nF11 compares on/off in this scene only." % ("ON" if dragon.rig.foot_lock_enabled else "OFF")

func _exit_tree() -> void:
	stop_replay()
