extends "res://world/main.gd"
## Complete compact campaign entry. Keeps the original prototype and review scenes intact.
const Data = preload("res://campaign/data.gd")
const CampaignRules = preload("res://campaign/progress.gd")
const CampaignStore = preload("res://campaign/save_store.gd")
const Room = preload("res://campaign/room.gd")
const CampaignDragon = preload("res://campaign/dragon.gd")
const CampaignEnemy = preload("res://campaign/enemy.gd")
const CampaignHud = preload("res://campaign/hud.gd")
const Patterns = preload("res://campaign/patterns.gd")
var campaign = CampaignRules.fresh()
var level
var enemies: Array = []
var repairs = 2
var entering = false
var room_clock = 0.0
var title_open = false
var has_started = false

func _ready() -> void:
	Inputs.setup()
	store = CampaignStore.new()
	if not test_mode:
		campaign = store.read_campaign()
		var values = preferences.read_values()
		quality_index = values.quality
		reduced_motion = values.reduced_motion
	_sync_compat()
	_build_lighting()
	effects = Effects.new()
	add_child(effects)
	dragon = CampaignDragon.new()
	dragon.position = Vector3(0,0.1,8)
	add_child(dragon)
	camera_rig = CameraRig.new()
	camera_rig.target = dragon
	add_child(camera_rig)
	wayfinder = Wayfinder.new()
	add_child(wayfinder)
	level = Room.new()
	add_child(level)
	level.build(Data.ROOMS[campaign.room])
	dressing = level
	hud = CampaignHud.new()
	hud.world = self
	add_child(hud)
	dragon.ability_used.connect(resolve_ability)
	dragon.hint.connect(hud.toast)
	dragon.damaged.connect(_on_player_damaged)
	dragon.died.connect(func(): hud.show_defeat.call_deferred())
	set_reduced_motion(reduced_motion)
	preferences_ready = not test_mode
	_enter_room(campaign.room, true)
	if not test_mode:
		title_open = true
		hud.show_title.call_deferred()
	else:
		has_started = true

func _sync_compat() -> void:
	# Only for the shared HUD contract; never written to the prototype save.
	progress = {"hatched": campaign.hatched, "gate_open": true, "clears": mini(campaign.installed.size(),3), "core": not campaign.cores.is_empty(), "upgraded": not campaign.installed.is_empty(), "module": campaign.module, "trial_cleared": campaign.finished}

func _save() -> void:
	_sync_compat()
	if not test_mode:
		store.write_campaign(campaign)
	if is_instance_valid(level):
		level.refresh(campaign)

func begin_campaign(fresh: bool = false) -> void:
	if fresh:
		campaign = CampaignRules.fresh()
		_save()
	title_open = false
	has_started = true
	hud.close_overlay()
	_enter_room(campaign.room, true)
	if campaign.legacy_imported and campaign.visited.size()==1:
		hud.toast("Your Magma and core module carried over. This campaign has its own save and new sector objectives.")

func _enter_room(id: String, restore: bool = false) -> void:
	entering = true
	var old_hp = dragon.state.hp
	_clear_encounter()
	if is_instance_valid(level):
		remove_child(level)
		level.queue_free()
	level = Room.new()
	add_child(level)
	level.build(Data.ROOMS[id])
	dressing = level
	var info: Dictionary = Data.ROOMS[id]
	var safe = info.role in ["forge","shelter"]
	dragon.respawn(Data.v3(info.spawn), campaign.module)
	_apply_build()
	if not safe and not restore:
		dragon.state.hp = minf(dragon.state.max_hp, maxf(1.0, old_hp))
	dragon.active = campaign.hatched
	if safe or restore:
		repairs = 2
	camera_rig.global_position = dragon.global_position
	camera_rig.opponent = null
	camera_rig.trauma = 0.0
	conduits.clear()
	for item in level.relay_nodes:
		conduits.append({"id":item.id,"node":item.node,"label":item.label,"sim":Conduit.new(),"gate":true})
	room_clock = 0.0
	_feedback_lighting(info.zone)
	set_quality(quality_index)
	level.refresh(campaign)
	_sync_compat()
	_spawn_encounters()
	entering = false
	if has_started:
		hud.toast(info.name + "  /  " + guidance().title)

func _apply_build() -> void:
	dragon.state.max_hp += int(campaign.upgrades.plating) * 20.0
	dragon.state.hp = dragon.state.max_hp
	dragon.cooling_level = int(campaign.upgrades.cooling)

func _feedback_lighting(zone: String) -> void:
	var tint = Color(Data.zone(zone).color)
	forge_light.position = Vector3(0,6,-4)
	forge_light.omni_range = 30
	forge_light.light_color = tint
	forge_light.light_energy = 1.8
	environment.background_color = {"home":Color("171d25"),"outer":Color("192126"),"frozen":Color("132738"),"storm":Color("1b172f"),"admin":Color("191221"),"final":Color("100b1a")}.get(zone,Color("152431"))
	environment.fog_light_color = tint.darkened(0.75)
	sun.light_color = Color("e6d3b6") if zone in ["home","outer"] else Color("bdd1e6")
	environment.ambient_light_energy = 0.50

func _spawn_encounters() -> void:
	for spec in Data.ROOMS[campaign.room].enemies:
		if campaign.cleared.has(spec.id):
			continue
		var actor = CampaignEnemy.new()
		actor.spec = spec.duplicate(true)
		actor.spec.color = Data.zone(Data.ROOMS[campaign.room].zone).color
		actor.position = Data.v3(spec.at)
		actor.target = dragon
		actor.navigation = self
		actor.reduced_motion = reduced_motion
		level.add_child(actor)
		actor.impact.connect(_on_pattern)
		actor.defeated.connect(_campaign_defeat)
		actor.hit_feedback.connect(_hit_feedback)
		enemies.append(actor)
	_select_enemy()

func _select_enemy() -> void:
	var living: Array = []
	for actor in enemies:
		if is_instance_valid(actor) and not actor.is_queued_for_deletion() and actor.hp > 0.0:
			living.append(actor)
	enemies = living
	enemy = enemies[0] if not enemies.is_empty() else null
	camera_rig.opponent = enemy

func _physics_process(delta: float) -> void:
	if entering or title_open:
		return
	feedback_cooldown = maxf(0.0,feedback_cooldown-delta)
	if dragon.input_grace<=0.0 and Input.is_action_just_pressed("ng_interact"):
		interact()
	if not dragon.active or dragon.state.hp<=0.0:
		return
	room_clock += delta
	if dragon.global_position.y < -4:
		retry()
		return
	for item in conduits:
		item.sim.tick(delta)
		item.label.text = "RELAY ONLINE" if campaign.relays.has(item.id) else "HEAT %d / 60  [2]" % int(item.sim.heat)
	_tick_walls(delta)
	_tick_hazards()
	_select_enemy()

func _process(delta: float) -> void:
	clock += delta
	if is_instance_valid(wayfinder) and is_instance_valid(dragon) and is_instance_valid(level):
		wayfinder.show_target(guidance(),is_instance_valid(enemy),dragon.state.hp<=0.0 or title_open)

func _tick_hazards() -> void:
	for hazard in level.hazard_nodes:
		var d: Dictionary = hazard.definition
		var phase = fposmod(room_clock + d.offset,d.period)
		var cycle = int(floor((room_clock+d.offset)/d.period))
		hazard.node.material_override.albedo_color = Color("ffd67c") if phase >= d.period-d.warning else Color("5f768b")
		if cycle > hazard.previous_cycle:
			if hazard.previous_cycle >= 0:
				var at = Data.v3(d.at)
				effects.pulse(at,d.radius,Color("c4a0ff"))
				if Vector2(dragon.position.x-at.x,dragon.position.z-at.z).length()<=d.radius:
					dragon.receive_damage(d.damage)
			hazard.previous_cycle=cycle

func direction_to(from: Vector3, to: Vector3) -> Vector3:
	if line_clear(from,to):
		var direction=to-from
		direction.y=0
		return direction.normalized()
	return level.direction(from,to)

func _nearest() -> Dictionary:
	if entering or title_open or dragon.state.hp<=0.0:
		return {}
	var best = 3.4
	var result: Dictionary = {}
	for station in level.stations:
		if not station.node.visible:
			continue
		var d=dragon.global_position.distance_to(station.node.global_position)
		if d<best:
			result={"kind":station.kind,"node":station.node,"name":station.name}
			best=d
	for door in level.doors:
		var d=dragon.global_position.distance_to(door.node.global_position)
		if d<best:
			result={"kind":"door","node":door.node,"definition":door.definition,"name":door.definition.label}
			best=d
	return result

func interaction() -> String:
	var item=_nearest()
	if item.is_empty():
		return ""
	match item.kind:
		"hatch":return "Rest / refill repair charges" if campaign.hatched else "Hatch Magma and begin your journey"
		"rest":return "Rest / refill repair charges"
		"upgrade":return "Spend salvage at the Forge"
		"forge":return "Install cores / configure Magma"
		"lore":return "Talk to Felix" if campaign.room=="forge" else "Read the record"
		"cache":return "Open salvage cache"
		"core":return "Collect the sector core"
		"finish":return "Stabilize the Singularity"
		"door":return item.name
	return ""

func interact() -> void:
	if get_tree().paused or entering:
		return
	var item=_nearest()
	if item.is_empty():
		return
	match item.kind:
		"door":
			if item.definition.to=="map":
				hud.show_map()
			else:
				travel(item.definition.to)
		"hatch":
			if not campaign.hatched:
				CampaignRules.hatch(campaign)
				dragon.active=true
				_save()
				level.refresh(campaign)
				effects.pulse(dragon.position,2.2)
				hud.toast("Magma is awake. Head north to EXPEDITIONS or press M to choose Outer Grid.")
			else:
				rest()
		"rest":rest()
		"upgrade":hud.show_upgrades()
		"forge":
			if CampaignRules.install(campaign)>0:
				_save()
				rest()
				effects.pulse(item.node.position,3.0,Geo.CYAN)
				hud.show_sector_restored()
			else:
				hud.show_modules()
		"lore":
			if not campaign.journals.has(campaign.room):
				campaign.journals.append(campaign.room)
				_save()
			hud.show_record(campaign.room)
		"cache":
			if CampaignRules.cache(campaign):
				_save()
				hud.toast("CACHE RECOVERED  /  +%d salvage. Spend it at the Forge anvil." % Data.ROOMS[campaign.room].reward)
		"core":
			if CampaignRules.collect_core(campaign):
				_save()
				hud.toast("CORE RECOVERED  /  Follow the north return portal. Install it in the Forge to unlock the next sector.")
		"finish":
			if CampaignRules.finish(campaign):
				_save()
				hud.show_ending()

func travel(destination: String) -> bool:
	if entering or title_open or dragon.state.hp<=0.0:
		return false
	if not CampaignRules.travel(campaign,destination):
		hud.toast("Route locked. Clear its guardians, charge its relays, or restore the preceding sector at the Forge.")
		return false
	_save()
	hud.close_overlay()
	entering=true
	_enter_room.call_deferred(destination,false)
	return true

func rest() -> void:
	if not Data.ROOMS[campaign.room].role in ["forge","shelter"] or is_instance_valid(enemy):
		return
	dragon.state=Combat.fresh(campaign.module)
	_apply_build()
	dragon.buffered_id=""
	dragon.buffer_time=0.0
	repairs=2
	hud.toast("Rested. Full health, cool core, two repair charges.")

func repair() -> bool:
	if get_tree().paused or title_open or not dragon.active or repairs<=0 or dragon.state.hp<=0 or dragon.state.hp>=dragon.state.max_hp:
		return false
	repairs-=1
	dragon.state.hp=minf(dragon.state.max_hp,dragon.state.hp+60)
	effects.pulse(dragon.position,1.3,Geo.CYAN)
	hud.toast("REPAIRED  /  +60 health. Refill at the Forge or a rest lantern.")
	return true

func buy_upgrade(id: String) -> bool:
	if not can_upgrade() or not CampaignRules.upgrade(campaign,id):
		return false
	_save()
	rest()
	hud.show_upgrades()
	return true

func can_upgrade() -> bool:
	return campaign.room=="forge" and campaign.hatched and dragon.state.hp>0 and dragon.position.distance_to(Vector3(-7,0,2))<3.4

func can_configure() -> bool:
	return campaign.room=="forge" and campaign.hatched and dragon.state.hp>0 and dragon.position.distance_to(Vector3(5,0,5))<3.4

func choose_module(id: String) -> bool:
	if not can_configure() or (campaign.installed.is_empty() and not campaign.legacy_imported) or not Modules.DATA.has(id):
		return false
	campaign.module=id
	_save()
	rest()
	hud.close_overlay()
	return true

func campaign_damage(id: String) -> float:
	return Combat.technique_damage(dragon.state,id)*(1.0+0.12*float(campaign.upgrades.power))

func resolve_ability(id: String, origin: Vector3, direction: Vector3) -> void:
	if entering or title_open or not campaign.hatched:
		return
	if id=="wall":
		_place_wall(origin,direction)
		walls[-1].damage=campaign_damage(id)
		return
	var rule: Dictionary=Combat.ABILITIES[id]
	for actor in enemies.duplicate():
		if is_instance_valid(actor) and Combat.in_cone(origin,direction,actor.global_position,rule.range,rule.cone) and line_clear(origin,actor.global_position):
			actor.take_hit(campaign_damage(id))
	if id=="breath":
		for item in conduits:
			if campaign.relays.has(item.id):
				continue
			var at: Vector3=item.node.global_position
			if Combat.in_cone(origin,direction,at,rule.range,rule.cone) and line_clear(origin,at) and item.sim.add_heat(38):
				CampaignRules.charge(campaign,item.id)
				_save()
				effects.pulse(at,5.0,Geo.CYAN)
				for foe in enemies:
					if is_instance_valid(foe) and foe.position.distance_to(at)<=5.0 and line_clear(at,foe.position):
						foe.overload()
				hud.toast("RELAY ONLINE  /  The circuit remembers. Charge the remaining relays to open the route.")
		var reach=0.0
		for step in range(1,15):
			if not line_clear(origin,origin+direction*step*0.5):
				break
			reach=step*0.5
		if reach>0.5:
			dragon.rig.animate(0,0,reduced_motion,dragon.state)
			var muzzle=dragon.rig.muzzle_position()
			var offset=maxf(0,(muzzle-origin).dot(direction))
			if reach>offset:
				effects.attack(id,origin,direction,reach-offset,muzzle)
	else:
		effects.attack(id,origin,direction,rule.range)

func _tick_walls(delta: float) -> void:
	for i in range(walls.size()-1,-1,-1):
		var wall: Dictionary=walls[i]
		wall.tick-=minf(delta,wall.ttl)
		wall.ttl-=delta
		while wall.tick<=0.0:
			wall.tick+=0.6
			for foe in enemies.duplicate():
				if is_instance_valid(foe) and Combat.in_cone(wall.at,Vector3.FORWARD,foe.position,2.3,-1) and line_clear(wall.at,foe.position):
					foe.take_hit(wall.damage)
		if wall.ttl<=0:
			wall.node.queue_free()
			walls.remove_at(i)

func _on_pattern(shape: Dictionary, amount: float) -> void:
	if Patterns.contains(shape,dragon.global_position) and line_clear(shape.origin,dragon.global_position):
		dragon.receive_damage(amount)
	else:
		hud.feedback("EVADED", "Counter during recovery.")
	if shape.kind=="beam":
		effects.attack("breath",shape.origin,shape.direction,shape.length,shape.origin+Vector3.UP)
	elif shape.kind=="ring":
		effects.pulse(shape.origin,shape.outer,Color("cca3ef"))
	else:
		for at in shape.circles:
			effects.pulse(at,shape.radius,Color("edb15e"))

func _campaign_defeat(id: String) -> void:
	if not CampaignRules.defeat(campaign,id):
		return
	_save()
	dragon.state.hp=minf(dragon.state.max_hp,dragon.state.hp+25)
	_select_enemy()
	if Data.room_cleared(campaign,campaign.room):
		hud.feedback("AREA SECURED", "+25 health. Salvage saved.")
		hud.toast("The pedestal is active. Collect the core." if Data.ROOMS[campaign.room].role in ["boss","final"] else "Path clear. Explore the room, read its record, and follow the next portal.")

func _clear_encounter() -> void:
	for actor in enemies:
		if is_instance_valid(actor):
			actor.queue_free()
	enemies.clear()
	enemy=null
	if is_instance_valid(camera_rig):
		camera_rig.opponent=null
	for wall in walls:
		if is_instance_valid(wall.node):
			wall.node.queue_free()
	walls.clear()
	conduits.clear()
	if is_instance_valid(effects):
		effects.set_calm(true)
		effects.set_calm(reduced_motion)

func retry() -> void:
	if entering or title_open:
		return
	hud.close_overlay()
	entering=true
	_enter_room.call_deferred(campaign.room,true)

func return_to_forge() -> void:
	if entering:
		return
	CampaignRules.return_home(campaign)
	_save()
	hud.close_overlay()
	entering=true
	_enter_room.call_deferred("forge",true)

func new_expedition() -> void:
	begin_campaign(true)

func set_quality(index: int) -> void:
	quality_index=clampi(index,0,3)
	quality_info=Quality.apply(quality_index,get_viewport(),environment,sun,reduced_motion)
	effects.particle_budget=quality_info.particles
	if is_instance_valid(level):
		level.set_quality(quality_index)
	_persist_preferences()

func set_reduced_motion(value: bool) -> void:
	super.set_reduced_motion(value)
	for actor in enemies:
		if is_instance_valid(actor):
			actor.reduced_motion=value

func guidance() -> Dictionary:
	var r: Dictionary=Data.ROOMS[campaign.room]
	var title="Explore the sector"
	var detail="Follow the marked portal. E interacts; M opens the route map."
	var target=Data.v3(r.exits[0].at) if not r.exits.is_empty() else Vector3(0,0,-10)
	var marker="NEXT PORTAL"
	if not campaign.hatched:
		title="Awaken your guardian"
		detail="Press E at the hatch ring, or click the interaction button below. Then head north to Expeditions."
		target=Vector3(-2,0,8)
		marker="HATCH MAGMA"
	elif r.role=="forge":
		if campaign.cores.size()>campaign.installed.size():
			title="Install the recovered core"
			detail="The core socket reconnects a sector and unlocks your next destination."
			target=Vector3(5,0,5)
			marker="CORE SOCKET"
		else:
			title="Stop the Great Reset" if campaign.installed.size()==4 else "Begin your next expedition"
			detail="All four sectors are connected. Enter the Singularity." if campaign.installed.size()==4 else "The north breach opens the route map. Rest, upgrade, then enter the next unlocked sector."
			if campaign.finished:
				title="A world reconnected"
				detail="The campaign is complete. Revisit unlocked sectors and recover any caches or records you missed."
			target=Vector3(0,0,-14)
			marker="EXPEDITIONS  [M]"
	elif is_instance_valid(enemy):
		title="Defeat "+enemy.spec.name
		detail=Patterns.tip(enemy.pattern)+". Gold marks the attack before impact; guard or dodge, then counter. Q repairs."
		target=enemy.position
		marker=""
	elif r.role=="gate" and not Data.room_powered(campaign,r.id):
		title="Reconnect the bridge"
		detail="Hit each relay twice with Magma Breath [2]. Wait for its cooldown, not for the relay to cool."
		for item in conduits:
			if not campaign.relays.has(item.id):
				target=item.node.position
				break
		marker="HEAT RELAY"
	elif r.role=="boss" and not campaign.cores.has(r.zone):
		title="Recover the sector core"
		detail="Press E at the glowing pedestal. Then take the north portal back to the Forge."
		target=Vector3(0,0,-19)
		marker="SECTOR CORE"
	elif r.role=="final" and not campaign.finished:
		title="Stabilize the Singularity"
		detail="The reset has stopped. Reconnect its heart at the pedestal."
		target=Vector3(0,0,-19)
		marker="RECONNECT"
	elif r.role=="cache" and not campaign.caches.has(r.id):
		title="Search the abandoned locker"
		detail="Its salvage funds permanent Forge upgrades. Read the record before returning."
		target=Vector3(0,0,-6)
		marker="SALVAGE"
	else:
		for exit in r.exits:
			if exit.at[2]<0:
				target=Data.v3(exit.at)
				marker=exit.label
				break
	return {"title":title,"detail":detail,"target":target,"marker":marker,"index":mini(campaign.installed.size(),5)}
