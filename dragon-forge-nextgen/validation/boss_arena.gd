extends "res://campaign/world.gd"
## Save-isolated review of real boss rooms, player controls, camera, tells and damage.
const UI = preload("res://validation/review_ui.gd")
const Catalog = preload("res://campaign/bosses/catalog.gd")
var boss_picker: OptionButton
var phase_picker: OptionButton
var review_status: Label
var review_panel: Control
var chosen_boss = 0
var freeze_armed = false
var freeze_pending = false
var contact_paused = false
var contact_events: Array = []

func _init() -> void:
	test_mode = true # Before any base _ready can read progress or graphics/audio preferences.

func _ready() -> void:
	super._ready()
	var layer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var box = UI.panel(layer,Vector2(24,292),280)
	review_panel = box.get_parent()
	UI.text(box,"BOSS / REHEARSAL",18)
	UI.text(box,"Real rooms + combat / no saves",12)
	boss_picker = UI.picker(box,["Buffer Overflow", "Memory Leak", "Stack Overflow", "Mirror Admin", "The Singularity"],select_boss)
	phase_picker = UI.picker(box,["Full health", "50% health", "25% health"],set_review_health)
	UI.button(box,"Reset encounter",func(): select_boss(chosen_boss))
	review_status=UI.text(box,"F9: freeze next boss impact\nF10: resume / F7: hide panel\nHealth presets are review setup, not earned progress.",12)
	var observer = Node.new()
	observer.set_script(preload("res://validation/boss_observer.gd"))
	observer.review = self
	add_child(observer)
	select_boss(0)

func select_boss(index: int) -> void:
	if index < 0 or index >= Catalog.ORDER.size(): return
	chosen_boss = index
	boss_picker.select(index)
	phase_picker.select(0)
	hud.close_overlay()
	campaign = CampaignRules.fresh()
	CampaignRules.hatch(campaign)
	# Explicit seeded review checkpoint. Never handed to the normal save store.
	for z in Data.ZONES:
		campaign.cores.append(z.id)
		campaign.installed.append(z.id)
		if z.id+"-boss" != Catalog.ORDER[index]: campaign.cleared.append(z.id+"-boss")
	campaign.guardians=["fire","ice","storm"]
	campaign.ice_rescued=true
	campaign.lattice_recovered=true
	campaign.storm_forged=true
	campaign.evolutions={"fire":"flashfire","ice":"deep_winter","storm":"thunderhead"}
	campaign.loadout=["fire","ice"]
	campaign.active_guardian="fire"
	campaign.room=Catalog.ROOMS[index]
	campaign.visited.append(campaign.room)
	_enter_room(campaign.room,true)
	contact_events.clear()
	freeze_pending=false
	contact_paused=false
	freeze_armed=false
	enemy.impact.connect(func(shape,amount):
		if contact_events.size()<256:
			contact_events.append({"pattern":shape.kind,"damage":amount,"clip":enemy.visual.sampled_clip,"clip_time":enemy.visual.sampled_time,"frame":Engine.get_physics_frames()})
		if freeze_armed: freeze_pending=true)
	hud.toast_remaining=0

func set_review_health(index: int) -> void:
	if is_instance_valid(enemy): enemy.hp=enemy.max_hp*[1.0,.5,.25][clampi(index,0,2)]

func observe_frame() -> void:
	if freeze_pending:
		freeze_pending=false
		freeze_armed=false
		get_tree().paused=true
		contact_paused=true
		review_status.text="Paused AFTER real boss impact.\nF10 resumes. F7 hides review UI.\nRecorded boss contacts: %d" % contact_events.size()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F9:
			freeze_armed=true
			review_status.text="Next boss impact will pause after\nits real pose + damage resolve."
			get_viewport().set_input_as_handled()
			return
		if event.keycode==KEY_F10:
			get_tree().paused=false
			get_viewport().set_input_as_handled()
			return
		if event.keycode==KEY_F7:
			review_panel.visible=not review_panel.visible
			get_viewport().set_input_as_handled()
			return
