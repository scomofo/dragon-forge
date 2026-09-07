extends "res://presentation/hud.gd"
const Fusion = preload("res://campaign/fusion.gd")
const Growth = preload("res://campaign/growth.gd")
const Data = preload("res://campaign/data.gd")
const Rules = preload("res://campaign/progress.gd")
const BossCatalog = preload("res://campaign/bosses/catalog.gd")
const Patterns = preload("res://campaign/patterns.gd")
var audio_return_title = false
var audio_settings_open = false
var sector_label: Label
var repair_button: Button
var reserve_button: Button
const GuardianCombat = preload("res://campaign/guardian_combat.gd")

func _ready() -> void:
	super._ready()
	sector_label=top_row.get_child(1)
	_button(top_row,"Routes [M]").pressed.connect(show_map)
	_button(top_row,"Journal [N]").pressed.connect(show_journal)
	repair_button=_button(root,"Q  Repair  /  2")
	_place(repair_button,Control.PRESET_TOP_RIGHT,-205,92,-24,132)
	repair_button.pressed.connect(func():world.repair())
	_button(top_row,"Guardians [P]").pressed.connect(show_party)
	reserve_button=_button(root,"")
	_place(reserve_button,Control.PRESET_TOP_RIGHT,-232,144,-24,205)
	reserve_button.pressed.connect(func():world.swap_guardian())
	reserve_button.focus_mode=Control.FOCUS_NONE

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
	var actor=world.dragon
	var active_id: String=world.party.active_id
	health_text.text=Growth.form_name(active_id,actor.state.get("evolution", "") != "").to_upper()+"   /   %d / %d" % [roundi(actor.state.hp),roundi(actor.state.max_hp)]
	if not actor.active:health_text.text="MAGMA / DORMANT"
	if actor.state.get("ward",0.0)>0.0:
		defensive_text.text="CRYSTAL AEGIS  /  %.1fs" % actor.state.ward
	var reserve: String=world.party.reserve_id()
	reserve_button.visible=not overlay.visible and not menu.visible and actor.active
	if reserve!="":
		var state: Dictionary=world.party.states[reserve]
		reserve_button.text="TAB / "+GuardianCombat.guardian_name(reserve)+"\n%d/%d HP" % [roundi(state.hp),roundi(state.max_hp)]
		reserve_button.text+=" / DOWN" if state.hp<=0 else (" / Ready" if world.party.swap_remaining<=0 else " / %.1fs" % world.party.swap_remaining)
		reserve_button.disabled=world.party.rejection(reserve)!=""
	else:
		reserve_button.text="SECOND GUARDIAN\nExplore Frozen Vault / P"
		reserve_button.disabled=true
	for i in range(abilities.size()):
		var id: String=Combat.ORDER[i]
		var rule: Dictionary=GuardianCombat.rule(actor.state,id)
		var card: Dictionary=abilities[i]
		card.button.get_child(0).get_child(0).text=str(i+1)+"   "+rule.name
		card.cost.text="%d damage / %d heat" % [roundi(world.campaign_damage(id)),roundi(GuardianCombat.heat_cost(actor.state,id))]
		if active_id=="storm":
			if id in ["breath","wall"]: card.cost.text="%d + CHARGE / %d heat" % [roundi(world.campaign_damage(id)),roundi(GuardianCombat.heat_cost(actor.state,id))]
			elif id=="burst": card.cost.text="%d / +50%% vs charge / %d heat" % [roundi(world.campaign_damage(id)),roundi(GuardianCombat.heat_cost(actor.state,id))]
		if active_id=="ice":
			if id=="breath":card.cost.text="%d + CHILL / %d heat" % [roundi(world.campaign_damage(id)),roundi(GuardianCombat.heat_cost(actor.state,id))]
			elif id=="wall":card.cost.text="%d/tick + CHILL / %d heat" % [roundi(world.campaign_damage(id)),roundi(GuardianCombat.heat_cost(actor.state,id))]
			elif id=="burst":card.cost.text="55%% protection / %d seconds" % int(GuardianCombat.ward_duration(actor.state))
		var cd: float=actor.state.cooldowns.get(id,0.0)
		card.charge.value=1.0-cd/float(rule.cooldown)
		card.status.text="COOLING %.1fs" % cd if cd>0 else ("TOO HOT" if actor.state.heat+GuardianCombat.heat_cost(actor.state,id)>100 else "READY")
		if not actor.active:card.status.text="AWAITING HATCH"
		elif actor.state.action==id:card.status.text=GuardianCombat.action_phase(actor.state)
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
		enemy_readout.text="%.1fs / " % foe.brain.timer+Patterns.tip(foe.pattern)
		if BossCatalog.known(foe.spec.id):
			enemy_name.text += " / " + BossCatalog.move_name(foe.spec.id,foe.pattern)
	elif not foe.spec.get("shield",true):
		enemy_readout.text="UNSHIELDED  /  ATTACK BETWEEN ITS TELLS"
	if foe.chilled>0.0:
		enemy_readout.text+="  /  CHILLED %.1fs" % foe.chilled
	if foe.charged>0.0:
		enemy_readout.text+="  /  CHARGED %.1fs" % foe.charged
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
	_label(col,"E Interact    M Routes    N Journal    P Guardians    Tab Swap",15,PAPER)
	_button(col,"Audio / music, effects and mute").pressed.connect(show_audio)
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
	_wrapped(overlay_column,"A compact playable campaign through four broken sectors. Restore their cores. Rescue, evolve and fuse guardians. Choose your expedition pair. Stop the Great Reset.",20)
	_label(overlay_column,"BOSS IDENTITIES   /   22 ROOMS   /   THREE GUARDIANS, TWO FIELD SLOTS",14,MUTED)
	var start=_button(overlay_column,"Continue campaign" if world.store.existed or world.has_started else "Begin campaign")
	start.pressed.connect(func():world.begin_campaign(false))
	start.grab_focus()
	_button(overlay_column,"Audio settings").pressed.connect(show_audio)
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
	_label(overlay_column,"UPGRADE YOUR GUARDIANS",30,GOLD)
	_label(overlay_column,"%d SALVAGE   /   Shared upgrades, retained through defeat." % world.campaign.salvage,17,TEAL)
	var row=HBoxContainer.new()
	overlay_column.add_child(row)
	row.add_theme_constant_override("separation",12)
	var names={"plating":"Reinforced Plating","power":"Tempered Claws","cooling":"Cooling Fins"}
	var details={"plating":"+20 maximum health per level.\nA little more room to learn a tell.","power":"+12% technique damage per level.\nStrengthens both guardians and their fields.","cooling":"+4 heat cooling per second per level.\nHalf strength while guarding."}
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
		_wrapped(overlay_column,"Modules change both guardians. Reconfigure for free whenever you return to the Forge.",17,MUTED)
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
	var reserve: String=world.party.reserve_id()
	if reserve!="" and world.party.states[reserve].hp>0.0:
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
	if audio_settings_open and event.is_action_pressed("ng_menu") and not event.is_echo():
		_leave_audio()
		get_viewport().set_input_as_handled()
		return
	if world.title_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_P:
				if overlay_kind=="party":close_overlay()
				else:show_party()
				get_viewport().set_input_as_handled()
				return
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

func show_egg_rescued() -> void:
	_open_overlay("egg")
	_label(overlay_column,"A SECOND HEARTBEAT",32,TEAL)
	_wrapped(overlay_column,"Inside the frozen shell, a guardian is still alive. Felix can wake it at the Forge's cyan nursery. This rescue is saved; the egg cannot be lost on defeat.",20)
	_wrapped(overlay_column,"RIME / Ice guardian\nA low, faceted quadruped. Rime chills exposed enemies and protects itself with Crystal Aegis. Swap to Magma for a shattering follow-up.",18,MUTED)
	_button(overlay_column,"Return to the Forge").pressed.connect(func():world.return_to_forge())
	_button(overlay_column,"Keep exploring").pressed.connect(close_overlay)

func show_party() -> void:
	if world.title_open:return
	_open_overlay("party")
	_label(overlay_column,"GUARDIANS / CHOOSE YOUR EXPEDITION PAIR",27,TEAL)
	_label(overlay_column,"BOND %s / %d points   •   One active + one reserve. Bench changes at the Forge Nursery." % [["I","II","III"][Growth.rank(world.campaign)-1],Growth.points(world.campaign)],15,GOLD)
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",14)
	overlay_column.add_child(row)
	for id in ["fire","ice","storm"]:
		var card=_panel(row);card.custom_minimum_size.x=315
		var col=_column(card,9)
		var owned: bool=world.campaign.guardians.has(id)
		var selected: bool=world.party.states.has(id)
		_label(col,Growth.form_name(id,Growth.choice(world.campaign,id)!="").to_upper(),23,{"fire":GOLD,"ice":TEAL,"storm":Color("c4b1fa")}[id])
		_label(col,("ACTIVE" if world.party.active_id==id else ("RESERVE" if selected else "AT THE FORGE")) if owned else "NOT RECRUITED",14,MUTED)
		if owned:
			if selected:
				var state: Dictionary=world.party.states[id]
				_label(col,"%d/%d HP / %d heat" % [roundi(state.hp),roundi(state.max_hp),roundi(state.heat)],15,PAPER)
			else:
				_label(col,"Not in the expedition",15,MUTED)
			for slot in GuardianCombat.ORDER:
				_label(col,GuardianCombat.rule({"guardian":id,"evolution":Growth.choice(world.campaign,id)},slot).name,17,PAPER)
			var tips={"fire":"Powers heat relays. Direct Fire hits shatter Chill for +40% once.","ice":"Chills exposed enemies. Aegis protects Rime, even after swapping.","storm":"Lance / Well charge enemies. Discharge consumes Charge for +50% once."}
			_wrapped(col,tips[id],16,MUTED,272)
			if not selected:
				var equip=_button(col,"Equip as reserve")
				equip.disabled=not world.can_evolve()
				equip.pressed.connect(func():world.equip_reserve(id))
			var evolve=_button(col,"Evolution / " + (Growth.TRAITS[Growth.choice(world.campaign,id)].name if Growth.choice(world.campaign,id)!="" else "Requirements"))
			evolve.pressed.connect(func():show_growth(id))
		elif id=="ice":
			_wrapped(col,"Rescue the Ice egg in Frozen Vault. Return to the right-hand Nursery to hatch Rime for free.",17,PAPER,272)
		else:
			_wrapped(col,"Evolve both parents. Recover the conductor lattice in Capacitor Cache. Fire + Ice creates Storm; neither parent is lost.",17,PAPER,272)
			_button(col,"View fusion recipe").pressed.connect(show_fusion)
	_wrapped(overlay_column,"Tab swaps your active/reserve pair, not the benched guardian. A benched dragon cannot rescue a downed party. To change the pair, visit the right-hand Nursery; keep Magma for thermal relays.",16,TEAL)
	_button(overlay_column,"Back to the world / P").pressed.connect(close_overlay)

func show_growth(guardian: String) -> void:
	if world.title_open or not Growth.OPTIONS.has(guardian):
		return
	_open_overlay("growth")
	var chosen = Growth.choice(world.campaign,guardian)
	_label(overlay_column,Growth.form_name(guardian,true).to_upper(),30,GOLD if guardian == "fire" else TEAL)
	_wrapped(overlay_column,"Evolution adds a new armored crest and +10% maximum health and technique damage. Keep the same movement, reach and contact timings. Choose one specialization below.",18,PAPER)
	var score = Growth.points(world.campaign)
	_label(overlay_column,"BOND %s / %d points   •   %d / %d cores restored" % [["I","II","III"][Growth.rank(world.campaign)-1],score,world.campaign.installed.size(),3 if guardian == "storm" else 2],17,TEAL)
	var bar = ProgressBar.new()
	bar.max_value = 280
	bar.value = mini(score,280)
	bar.show_percentage = false
	bar.custom_minimum_size.y = 14
	overlay_column.add_child(bar)
	var reason = Growth.reason(world.campaign,guardian)
	if reason == "" and not world.can_evolve():
		reason = "Visit the Guardian Nursery on the right of the Forge to evolve or change specialization."
	_wrapped(overlay_column,reason if reason != "" else "READY AT THE NURSERY / Free evolution. Change specialization here later at no cost.",17,GOLD)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	overlay_column.add_child(row)
	for specialization in Growth.OPTIONS[guardian]:
		var info: Dictionary = Growth.TRAITS[specialization]
		var card = _panel(row)
		card.custom_minimum_size.x = 477
		var col = _column(card,12)
		_label(col,info.name,23,TEAL)
		_wrapped(col,info.detail,18,PAPER,436)
		var button = _button(col,"Equipped" if chosen == specialization else (("Evolve / " if chosen == "" else "Reconfigure / ") + info.name))
		button.disabled = reason != "" or chosen == specialization
		button.pressed.connect(func():world.choose_evolution(guardian,specialization))
	_wrapped(overlay_column,"Shared bond comes from unique achievements: patrol 20, shield guardian 35, boss 70, final 100, cache 15, core installation 25. Recruits inherit your journey; revisiting or retrying never farms points.",15,MUTED)
	_button(overlay_column,"Back to Guardians").pressed.connect(show_party)

func show_evolution_result(guardian: String) -> void:
	_open_overlay("evolved")
	_label(overlay_column,"A GUARDIAN TRANSFORMED",32,TEAL)
	_label(overlay_column,Growth.form_name(guardian,true).to_upper(),27,GOLD)
	var specialization = Growth.choice(world.campaign,guardian)
	_wrapped(overlay_column,Growth.TRAITS[specialization].name+" / "+Growth.TRAITS[specialization].detail,20,PAPER)
	_wrapped(overlay_column,"+10% maximum health and technique damage. The new form stays with this guardian through swaps, defeat and Continue. Both guardians are rested at the Nursery.",18,MUTED)
	if world.store.message != "":
		_wrapped(overlay_column,world.store.message,16,GOLD)
	_button(overlay_column,"Return to the Forge").pressed.connect(close_overlay)

func show_lattice_recovered() -> void:
	_open_overlay("lattice")
	_label(overlay_column,"A CIRCUIT FOR TWO HEARTBEATS",31,Color("c4b1fa"))
	_wrapped(overlay_column,"The conductor lattice can stabilize Fire and Ice into Storm. Felix: ‘We borrow a spark from each guardian. We do not erase either of them.’",21,PAPER)
	_wrapped(overlay_column,"Rescue saved. Evolve Magma and Rime, then visit Resonance Fusion on the left of the Forge. This lattice is separate from the salvage cache, so earlier visits do not lock you out.",18,MUTED)
	_button(overlay_column,"Return to the Forge").pressed.connect(func():world.return_to_forge())
	_button(overlay_column,"Keep exploring").pressed.connect(close_overlay)

func show_fusion() -> void:
	if world.title_open:return
	_open_overlay("fusion")
	_label(overlay_column,"RESONANCE FUSION / FIRE + ICE = STORM",29,Color("c4b1fa"))
	_wrapped(overlay_column,"Combine a spark from Crowned Magma and Aurora Rime in the conductor lattice to create ARC, a hovering Storm drake. The parents, their evolution choices and your salvage are preserved.",19,PAPER)
	var c: Dictionary=world.campaign
	var ready=Fusion.reason(c)
	if c.guardians.has("storm"):
		_label(overlay_column,"ARC HAS JOINED YOUR COLLECTION",23,TEAL)
		_wrapped(overlay_column,"Your expedition pair has not changed. Visit the Guardian Nursery on the right to equip Arc as reserve, then Tab to take point. Choose Fire + Storm or Ice + Storm; only two guardians travel at once.",19,PAPER)
	elif c.storm_forged:
		_label(overlay_column,"STORM EGG STABILIZED / READY TO HATCH",23,TEAL)
		var hatch=_button(overlay_column,"Hatch Arc / free")
		hatch.disabled=not world.can_fuse()
		hatch.pressed.connect(func():world.hatch_storm())
	else:
		for item in [[Growth.choice(c,"fire")!="","Crowned Magma"],[Growth.choice(c,"ice")!="","Aurora Rime"],[c.lattice_recovered,"Conductor lattice / Capacitor Cache"]]:
			_label(overlay_column,("READY / " if item[0] else "NEEDED / ")+item[1],18,TEAL if item[0] else MUTED)
		_wrapped(overlay_column,ready if ready!="" else ("READY / Free, permanent, one-time recipe. No random failure or parent sacrifice." if world.can_fuse() else "Visit Resonance Fusion on the left of the Forge to create the egg."),18,GOLD)
		var forge=_button(overlay_column,"Create Storm egg / keep both parents")
		forge.disabled=ready!="" or not world.can_fuse()
		forge.pressed.connect(func():world.forge_storm())
	_wrapped(overlay_column,"ARC / Spark Talon • Arc Lance • Static Well • Tempest Discharge
Lance and Well apply four seconds of Charge on landed hits. Discharge consumes it for +50% damage once. Closed shields still block all three.",17,MUTED)
	if world.store.message!="":_wrapped(overlay_column,world.store.message,16,GOLD)
	_button(overlay_column,"Back to Guardians").pressed.connect(show_party)
	_button(overlay_column,"Back to the world").pressed.connect(close_overlay)

func _button(parent: Node, text: String) -> Button:
	var button = super._button(parent,text)
	button.pressed.connect(func(): world.sound("ui","fire",0,true))
	return button

func show_audio() -> void:
	audio_return_title = world.title_open
	audio_settings_open = true
	_open_overlay("audio")
	_label(overlay_column,"SOUND OF THE FORGE",30,TEAL)
	_wrapped(overlay_column,"The original Dragon Forge soundtrack, now in the campaign. Controls take effect immediately. Music fades between exploration and combat; opening menus lowers the music.",18,PAPER)
	if not is_instance_valid(world.audio):
		_wrapped(overlay_column,"Audio is disabled in this isolated validation scene. Launch the normal campaign to hear it.",18,GOLD)
	else:
		var audio = world.audio
		for key in ["master","music","sfx"]:
			var row = HBoxContainer.new()
			overlay_column.add_child(row)
			var label = _label(row,{"master":"Master","music":"Music","sfx":"Sound effects"}[key],18,PAPER)
			label.custom_minimum_size.x = 180
			var slider = HSlider.new()
			slider.name = "Audio_"+key
			slider.min_value=0;slider.max_value=100;slider.step=1
			slider.custom_minimum_size=Vector2(560,38)
			slider.value=roundi(audio.values[key]*100)
			row.add_child(slider)
			var number = _label(row,str(int(slider.value))+"%",18,TEAL)
			slider.value_changed.connect(func(v): audio.set_value(key,v/100.0);number.text=str(int(v))+"%")
		for key in ["muted","mute_unfocused"]:
			var toggle=CheckBox.new()
			toggle.name="Audio_"+key
			toggle.text="Mute all sound" if key=="muted" else "Silence and pause music when this window loses focus"
			toggle.button_pressed=audio.values[key]
			toggle.toggled.connect(func(v): audio.set_value(key,v))
			overlay_column.add_child(toggle)
		_button(overlay_column,"Test Fire / Ice / Storm effects").pressed.connect(_test_audio)
		if audio.settings.message!="": _wrapped(overlay_column,audio.settings.message,16,GOLD)
	_button(overlay_column,"Save / back to title" if audio_return_title else "Save / back to pause").pressed.connect(_leave_audio)

func _test_audio() -> void:
	if not audio_settings_open or not is_instance_valid(world.audio): return
	world.sound("breath",["fire","ice","storm"][_audio_test_index%3],2,true)
	_audio_test_index+=1

var _audio_test_index = 0

func _leave_audio() -> void:
	if is_instance_valid(world.audio): world.audio.save_settings()
	audio_settings_open=false
	if audio_return_title:
		show_title()
	else:
		close_overlay()
		set_pause(true)

func close_overlay() -> void:
	if audio_settings_open:
		_leave_audio()
		return
	super.close_overlay()
