extends "res://presentation/hud.gd"
const Data = preload("res://campaign/data.gd")
const Rules = preload("res://campaign/progress.gd")
const Patterns = preload("res://campaign/patterns.gd")
var sector_label: Label
var repair_button: Button

func _ready() -> void:
	super._ready()
	sector_label=top_row.get_child(1)
	_button(top_row,"Routes [M]").pressed.connect(show_map)
	_button(top_row,"Journal [N]").pressed.connect(show_journal)
	repair_button=_button(root,"Q  Repair  /  2")
	_place(repair_button,Control.PRESET_TOP_RIGHT,-205,92,-24,132)
	repair_button.pressed.connect(func():world.repair())

func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(world) or not is_instance_valid(world.dragon):
		return
	var c: Dictionary=world.campaign
	var r: Dictionary=Data.ROOMS[c.room]
	sector_label.text=Data.zone(r.zone).name.to_upper()+"  /  "+r.name
	step_label.text="RECONNECTION  /  %d OF 4 CORES" % c.installed.size()
	for i in range(steps.size()):
		steps[i].visible=i<4
	if world.guidance().marker=="":
		route_text.text="GUARDIAN ACTIVE" if is_instance_valid(world.enemy) else "AREA SECURED"
	module_text.text="%d SALVAGE  /  %s" % [c.salvage,Modules.profile(c.module).name.to_upper()]
	repair_button.text="Q  Repair  /  %d" % world.repairs
	repair_button.visible=not overlay.visible and not menu.visible
	repair_button.disabled=world.repairs<=0 or not world.dragon.active or world.dragon.state.hp<=0 or world.dragon.state.hp>=world.dragon.state.max_hp or overlay.visible or menu.visible
	for i in range(abilities.size()):
		var id: String=Combat.ORDER[i]
		abilities[i].cost.text="%d damage  /  %d heat" % [roundi(world.campaign_damage(id)),roundi(Combat.heat_cost(world.dragon.state,id))]
	if r.role=="gate" and not is_instance_valid(world.enemy):
		var completed=0
		for relay in r.relays:
			if c.relays.has(relay.id):
				completed+=1
		route_text.text="%d / %d RELAYS ONLINE" % [completed,r.relays.size()]
	if world.title_open:
		prompt.visible=false
		toast_label.visible=false

func _update_enemy() -> void:
	super._update_enemy()
	if not is_instance_valid(world.enemy):
		return
	var foe=world.enemy
	enemy_name.text=foe.spec.name.to_upper()+"  /  %d / %d" % [int(foe.hp),int(foe.max_hp)]
	if foe.brain.mode=="tell":
		enemy_readout.text="%.1fs  /  " % foe.brain.timer+Patterns.tip(foe.pattern)
	elif not foe.spec.get("shield",true):
		enemy_readout.text="UNSHIELDED  /  ATTACK BETWEEN ITS TELLS"
	if foe.spec.id=="singularity-final":
		enemy_name.text+="  /  PHASE %d" % (1 if foe.hp>foe.max_hp*0.66 else (2 if foe.hp>foe.max_hp*0.33 else 3))

func _build_menu() -> void:
	menu=_shade()
	var center=CenterContainer.new()
	menu.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel=_panel(center)
	panel.custom_minimum_size.x=650
	var col=_column(panel,10)
	_label(col,"THE WORLD CAN WAIT",30,GOLD)
	_wrapped(col,"Campaign progress saves at doors, cleared encounters, relays and rewards. Continue resumes at the current room entrance with full health.",15,MUTED,580)
	quality_select=OptionButton.new()
	for name_text in Quality.NAMES:
		quality_select.add_item(name_text)
	quality_select.select(world.quality_index)
	quality_select.item_selected.connect(func(i):world.set_quality(i))
	col.add_child(quality_select)
	reduced_check=CheckBox.new()
	reduced_check.text="Reduced motion / calmer effects"
	reduced_check.set_pressed_no_signal(world.reduced_motion)
	reduced_check.toggled.connect(func(v):world.set_reduced_motion(v))
	col.add_child(reduced_check)
	_label(col,"1–4 Techniques    Space Dodge    Shift Guard    Q Repair",15,PAPER)
	_label(col,"E Interact    M Routes    N Journal    Esc Pause",15,PAPER)
	resume_button=_button(col,"Resume campaign")
	resume_button.pressed.connect(func():set_pause(false))
	_button(col,"Retry current room / retain earned progress").pressed.connect(func():world.retry())
	_button(col,"Return to the Forge").pressed.connect(func():world.return_to_forge())
	_button(col,"Save and title screen").pressed.connect(func():world._save();world.title_open=true;show_title())
	_button(col,"Quit game").pressed.connect(func():world._save();get_tree().quit())
	confirmation=ConfirmationDialog.new()
	confirmation.title="Start a new campaign?"
	confirmation.dialog_text="This replaces only Reconnection campaign progress. A previous-write backup is kept.\nThe older prototype and browser saves are not changed."
	confirmation.confirmed.connect(func():world.begin_campaign(true))
	add_child(confirmation)
	menu.visible=false

func _wrapped(parent: Node,text: String,size: int=17,color: Color=PAPER,width: float=970) -> Label:
	var label=_label(parent,text,size,color)
	label.custom_minimum_size.x=width
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label

func show_title() -> void:
	world.title_open=true
	_open_overlay("title")
	_label(overlay_column,"DRAGON FORGE",42,GOLD)
	_label(overlay_column,"RECONNECTION",25,TEAL)
	_wrapped(overlay_column,"A compact playable campaign through four broken sectors. Restore their cores. Build your guardian. Stop the Great Reset.",20)
	_label(overlay_column,"22 CONNECTED ROOMS   /   4 SECTORS   /   13 ENCOUNTERS",14,MUTED)
	var start=_button(overlay_column,"Continue campaign" if world.store.existed or world.has_started else "Begin campaign")
	start.pressed.connect(func():world.begin_campaign(false))
	start.grab_focus()
	if world.store.existed or world.has_started:
		_button(overlay_column,"New campaign...").pressed.connect(func():confirmation.popup_centered())
	if world.campaign.legacy_imported and not world.store.existed:
		_wrapped(overlay_column,"Your existing Magma and module are carried over. Sector exploration begins here; your prototype save is untouched.",15,MUTED)
	_wrapped(overlay_column,"First steps: press E to hatch, then walk to the north EXPEDITIONS portal or press M. This is the campaign, not the character inspection scene.",16,TEAL)
	if world.store.message!="":
		_wrapped(overlay_column,world.store.message,15,GOLD)
	_label(overlay_column,"WASD Move   •   Mouse Aim   •   1–4 Techniques   •   Q Repair",15,MUTED)

func show_map() -> void:
	if world.title_open:
		return
	_open_overlay("map")
	_label(overlay_column,"THE RECONNECTION ROUTE",29,GOLD)
	_wrapped(overlay_column,"You are in "+Data.ROOMS[world.campaign.room].name+". Each sector has a shelter, approach, relay junction, optional cache and boss. Travel through the physical portals; launch new expeditions from the Forge.",16,MUTED)
	var row=HBoxContainer.new()
	overlay_column.add_child(row)
	row.add_theme_constant_override("separation",12)
	var focus: Button
	for z in Data.ZONES:
		var card=_panel(row)
		card.custom_minimum_size.x=242
		var col=_column(card,12)
		var unlocked=Data.zone_unlocked(world.campaign,z.id)
		_label(col,z.name,22,Color(z.color))
		_label(col,"RESTORED" if world.campaign.installed.has(z.id) else ("AVAILABLE" if unlocked else "LOCKED"),12,TEAL if unlocked else MUTED)
		for role in ["entry","path","gate","cache","boss"]:
			var r: Dictionary=Data.ROOMS[z[role]]
			var text=("• " if world.campaign.visited.has(r.id) else "  ")+r.name
			if r.id==world.campaign.room:
				text="▶ "+r.name
			_label(col,text,14,PAPER if unlocked else MUTED)
		var button=_button(col,"Enter sector" if unlocked else "Restore previous core")
		button.disabled=not unlocked or world.campaign.room!="forge"
		button.pressed.connect(func():world.travel(z.entry))
		if focus==null and not button.disabled:
			focus=button
	var options=HBoxContainer.new()
	overlay_column.add_child(options)
	options.add_theme_constant_override("separation",12)
	var final_button=_button(options,"ENTER THE SINGULARITY")
	final_button.disabled=world.campaign.installed.size()!=4 or world.campaign.room!="forge"
	final_button.pressed.connect(func():world.travel("singularity"))
	if world.campaign.room!="forge":
		_button(options,"Return to the Forge").pressed.connect(func():world.return_to_forge())
	_button(options,"Back to the world").pressed.connect(close_overlay)
	if focus!=null:
		focus.grab_focus()

func show_record(id: String) -> void:
	_open_overlay("record")
	var r: Dictionary=Data.ROOMS[id]
	_label(overlay_column,r.lore_title,28,GOLD)
	_wrapped(overlay_column,r.lore,20,PAPER)
	_button(overlay_column,"Keep moving").pressed.connect(close_overlay)

func show_journal() -> void:
	if world.title_open:
		return
	_open_overlay("journal")
	_label(overlay_column,"FIELD JOURNAL",30,GOLD)
	_wrapped(overlay_column,"Goal: recover and install all four sector cores, then stop the Singularity. Cleared encounters and recovered caches stay cleared. No repeat-fight grinding is required.",17,PAPER)
	_label(overlay_column,"%d / 22 places visited   •   %d / 4 caches recovered   •   %d records read" % [world.campaign.visited.size(),world.campaign.caches.size(),world.campaign.journals.size()],16,TEAL)
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(970,290)
	overlay_column.add_child(scroll)
	var col=_column(scroll,8)
	for id in world.campaign.journals:
		var button=_button(col,Data.ROOMS[id].name+" / "+Data.ROOMS[id].lore_title)
		button.pressed.connect(func():show_record(id))
	if world.campaign.journals.is_empty():
		_label(col,"Read Felix's radio and field terminals to keep their stories here.",17,MUTED)
	_button(overlay_column,"Return to the world").pressed.connect(close_overlay)

func show_upgrades() -> void:
	if not world.can_upgrade():
		toast("Visit the anvil on the left side of the Forge to buy upgrades.")
		return
	_open_overlay("upgrades")
	_label(overlay_column,"MAKE MAGMA YOUR OWN",30,GOLD)
	_label(overlay_column,"%d SALVAGE   /   Permanent upgrades, retained through defeat." % world.campaign.salvage,17,TEAL)
	var row=HBoxContainer.new()
	overlay_column.add_child(row)
	row.add_theme_constant_override("separation",12)
	var names={"plating":"Reinforced Plating","power":"Tempered Claws","cooling":"Cooling Fins"}
	var details={"plating":"+20 maximum health per level.\nA little more room to learn a tell.","power":"+12% technique damage per level.\nAlso strengthens Flame Wall.","cooling":"+4 heat cooling per second per level.\nHalf strength while guarding."}
	for id in Rules.UPGRADE_IDS:
		var card=_panel(row)
		card.custom_minimum_size.x=322
		var col=_column(card,13)
		_label(col,names[id],22,GOLD)
		_label(col,"LEVEL %d / 3" % world.campaign.upgrades[id],14,TEAL)
		_wrapped(col,details[id],17,MUTED,286)
		var cost=Rules.upgrade_cost(world.campaign,id)
		var button=_button(col,"MAXIMUM LEVEL" if world.campaign.upgrades[id]>=3 else "Upgrade / %d salvage" % cost)
		button.disabled=world.campaign.upgrades[id]>=3 or world.campaign.salvage<cost
		button.pressed.connect(func():world.buy_upgrade(id))
	_button(overlay_column,"Back to the Forge").pressed.connect(close_overlay)

func show_modules() -> void:
	if not world.can_configure():
		return
	_open_overlay("modules")
	_label(overlay_column,"THE HEART OF THE FORGE",30,GOLD)
	if world.campaign.installed.is_empty() and not world.campaign.legacy_imported:
		_wrapped(overlay_column,"Recover the Outer Grid core and bring it here to unlock modules. The anvil already offers salvage upgrades.",19,PAPER)
	else:
		_wrapped(overlay_column,"Modules change your fighting style. Reconfigure for free whenever you return to the Forge.",17,MUTED)
		var row=HBoxContainer.new()
		overlay_column.add_child(row)
		row.add_theme_constant_override("separation",12)
		for id in Modules.ORDER:
			var data: Dictionary=Modules.DATA[id]
			var card=_panel(row)
			card.custom_minimum_size.x=322
			var col=_column(card,12)
			_label(col,data.name,23,data.color)
			_wrapped(col,data.detail,17,PAPER,286)
			var button=_button(col,"Equipped" if world.campaign.module==id else "Equip module")
			button.disabled=world.campaign.module==id
			button.pressed.connect(func():world.choose_module(id))
	_button(overlay_column,"Return to the Forge").pressed.connect(close_overlay)

func show_sector_restored() -> void:
	_open_overlay("restored")
	var n=world.campaign.installed.size()
	_label(overlay_column,"A SECTOR RECONNECTED",32,TEAL)
	_label(overlay_column,"%d / 4 cores installed" % n,23,PAPER)
	_wrapped(overlay_column,"The Singularity is now reachable. Bring the restored sectors together and stop the reset." if n==4 else Data.ZONES[n].name+" is now open. Spend your salvage, choose a module, and launch your next expedition.",20,PAPER)
	var buttons=HBoxContainer.new()
	overlay_column.add_child(buttons)
	buttons.add_theme_constant_override("separation",16)
	_button(buttons,"Configure module").pressed.connect(show_modules)
	_button(buttons,"Open routes").pressed.connect(show_map)
	_button(buttons,"Back to the Forge").pressed.connect(close_overlay)

func show_defeat() -> void:
	if not is_instance_valid(world.dragon) or world.dragon.state.hp>0 or dead_presented:
		return
	dead_presented=true
	_open_overlay("defeat")
	_label(overlay_column,"REGROUP. YOUR PROGRESS IS SAFE.",30,GOLD)
	_wrapped(overlay_column,"Retry at this room's entrance with full health and two repair charges. Cleared enemies, charged relays, salvage and cores are retained.",20,PAPER)
	_wrapped(overlay_column,"Read the gold warning. Beam: move sideways. Ring: move to its center or leave the outer edge. Shielded guardians are vulnerable during recovery. Q repairs; Shift guards.",18,MUTED)
	var button=_button(overlay_column,"Retry this room [R]")
	button.pressed.connect(func():world.retry())
	_button(overlay_column,"Return to the Forge").pressed.connect(func():world.return_to_forge())
	button.grab_focus()

func show_ending() -> void:
	_open_overlay("ending")
	_label(overlay_column,"NO GREAT RESET",38,TEAL)
	_label(overlay_column,"DRAGON FORGE / RECONNECTION COMPLETE",19,GOLD)
	_wrapped(overlay_column,"The four sectors answer together. The frozen memories thaw. The storm slows to a pulse. For the first time, the administrator listens.\n\nFelix: “You did not rebuild it by erasing what was broken. You brought it home.”",21,PAPER)
	_wrapped(overlay_column,"Magma rests beside a living Forge. The campaign is complete; its paths remain open. You can return for missed caches, records and upgrades.",17,MUTED)
	_button(overlay_column,"Return home").pressed.connect(func():world.return_to_forge())

func _unhandled_input(event: InputEvent) -> void:
	if world.title_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_M:
				if overlay_kind=="map":close_overlay()
				else:show_map()
				get_viewport().set_input_as_handled()
				return
			KEY_N:
				if overlay_kind=="journal":close_overlay()
				else:show_journal()
				get_viewport().set_input_as_handled()
				return
			KEY_Q:
				world.repair()
				get_viewport().set_input_as_handled()
				return
	super._unhandled_input(event)
