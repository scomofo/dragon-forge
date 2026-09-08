extends SceneTree
const World=preload("res://campaign/world.gd")
const Rules=preload("res://campaign/progress.gd")
const Combat=preload("res://campaign/guardian_combat.gd")
const Party=preload("res://campaign/party.gd")
const Store=preload("res://campaign/save_store.gd")
const Enemy=preload("res://campaign/enemy.gd")
const Probe=preload("res://validation/foot_review.gd")
const Data=preload("res://campaign/data.gd")
var checks=0
var failures=0
var w
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool,text: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS " if ok else "FAIL ")+text)
func frames(count: int=2) -> void:
	for i in range(count):await physics_frame
func unlocked() -> Dictionary:
	var c=Rules.fresh();Rules.hatch(c)
	c.cleared=["outer-boss"];c.cores=["outer"];c.installed=["outer"]
	c.visited.append("frozen-vault");c.room="frozen-vault"
	return c
func run() -> void:
	var c=unlocked()
	check(not Rules.normalize(c).is_empty(),"valid legacy-stage campaign fixture")
	var legacy=c.duplicate(true);legacy.version=1
	for key in ["guardians","active_guardian","ice_rescued"]:legacy.erase(key)
	var migrated=Rules.normalize(legacy)
	check(migrated.version==9 and migrated.guardians==["fire"],"version 1 migration initializes exactly Magma through schema 9")
	for key in legacy:
		if key!="version":check(migrated[key]==legacy[key],"migration preserves "+key)
	var future=c.duplicate(true);future.version=99
	check(Rules.normalize(future).is_empty(),"future save remains blocked")
	var broken=c.duplicate(true);broken.guardians=["fire","fire"]
	check(Rules.normalize(broken).is_empty(),"duplicate guardian rejected")
	broken=c.duplicate(true);broken.active_guardian="ice"
	check(Rules.normalize(broken).is_empty(),"unowned active guardian rejected")
	check(not Rules.hatch_ice(c),"egg cannot hatch before rescue")
	check(Rules.rescue_ice(c) and not Rules.rescue_ice(c),"rescue exactly once in Frozen Vault")
	check(not Rules.hatch_ice(c),"hatching away from Forge rejected")
	Rules.return_home(c)
	check(Rules.hatch_ice(c) and not Rules.hatch_ice(c),"free second hatch exactly once at Forge")
	check(c.guardians==["fire","ice"] and not Rules.normalize(c).is_empty(),"recruitment leaves both guardians owned")
	var store=Store.new();store.path="user://party-test-migration.json";store.import_legacy=false
	var f=FileAccess.open(store.path,FileAccess.WRITE);var bytes=JSON.stringify(legacy);f.store_string(bytes);f.close()
	var loaded=store.read_campaign()
	check(loaded.version==9,"disk migration readable at current schema")
	check(FileAccess.get_file_as_string(store.path)==bytes,"load never overwrites original version-1 bytes")
	check(store.write_campaign(loaded),"migrated save commits")
	check(FileAccess.get_file_as_string(store.path+".bak")==bytes,"migration backs up exact original bytes")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(store.path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path+suffix))
	var party=Party.new();party.rebuild(c)
	party.states.fire.hp=41;party.states.fire.heat=63;party.states.fire.cooldowns.burst=8.0
	check(party.swap_to("ice"),"healthy reserve selectable")
	check(party.states.fire.hp==41 and party.states.fire.heat==63 and party.states.fire.cooldowns.burst==8,"swap preserves outgoing HP heat cooldown")
	check(not party.swap_to("fire"),"shared swap lockout enforced")
	party.tick_reserve(.2,0)
	check(party.states.fire.hp==41 and party.states.fire.cooldowns.burst<8,"reserve cooldown expires without healing")
	party.swap_remaining=0;party.states.ice.action="breath"
	check(not party.swap_to("fire"),"pending contact cannot be cancelled through swap")
	party.states.ice.action="";party.states.fire.hp=0
	check(not party.swap_to("fire"),"fainted reserve cannot be summoned")
	for id in Combat.ORDER:
		var state=Combat.fresh("","ice")
		check(Combat.cast(state,id),"Rime casts "+id)
		check(Combat.tick(state,Combat.rule(state,id).windup-.01)=="","no early ice contact "+id)
		check(Combat.tick(state,.011)==id,"one real ice contact "+id)
		check(Combat.tick(state,1.0)=="","contact not repeated "+id)
	var ice=Combat.fresh("","ice");ice.ward=4
	check(is_equal_approx(Combat.damage(ice,20),9.0),"Aegis reduces damage by 55 percent")
	ice.iframes=0;Combat.tick(ice,4.1)
	check(is_equal_approx(Combat.damage(ice,20),20.0),"ward expires at four seconds")
	w=World.new();w.test_mode=true;root.add_child(w)
	await frames(4)
	w.interact()
	check(w.campaign.hatched,"normal campaign still hatches Magma")
	w.campaign=unlocked();w._enter_room("frozen-vault",true)
	await frames(4)
	w.dragon.position=Vector3(6,.1,-4);w.dragon.input_grace=0
	w.interact()
	check(w.campaign.ice_rescued and w.hud.overlay_kind=="egg","actual egg interaction saves rescue and opens reward")
	check(paused,"rescue dialog pauses simulation")
	w.hud.close_overlay();w.return_to_forge();await frames(5)
	w.dragon.position=Vector3(6,.1,8);w.dragon.input_grace=0
	w.interact()
	check(w.campaign.guardians.has("ice") and w.hud.overlay_kind=="party","actual nursery hatches and opens collection")
	check(w.party.states.size()==2,"hatch creates separate live states")
	w.hud.close_overlay();w.dragon.input_grace=0
	w.dragon.state.hp=40;w.dragon.state.heat=50
	check(w.swap_guardian(),"actual world swap succeeds")
	check(w.dragon.guardian=="ice" and w.dragon.state.guardian=="ice","active controller uses ice rules")
	check(w.dragon.rig.skeleton.get_bone_count()==21,"distinct exported quadruped skeleton loaded")
	check(w.dragon.rig.planting.legs.size()==4,"four contact chains configured")
	for clip in ["idle","walk","claw","breath","wall","burst","guard","hurt","defeat"]:
		check(w.dragon.rig.player.has_animation(clip),"imported Rime clip "+clip)
	check(w.party.states.fire.hp==40 and w.party.states.fire.heat==50,"actual swap does not heal or clear old heat")
	check(not w.swap_guardian("fire",true),"forced API cannot bypass cooldown on living actor")
	w.hud.show_party();var cd=w.party.swap_remaining
	await frames(3)
	check(w.party.swap_remaining==cd and not w.swap_guardian(),"party menu freezes and rejects combat swaps")
	w.hud.close_overlay();w.dragon.input_grace=0
	# Real active kit: moving actor and actual simulation-contact events, never a second damage engine.
	var foe=Enemy.new();foe.spec={"id":"test","name":"Test Sentinel","hp":200.0,"damage":12.0,"shield":false,"boss":false,"patterns":["slam"]};foe.target=w.dragon;foe.navigation=w
	w.level.add_child(foe);foe.position=w.dragon.position+Vector3.FORWARD*2
	foe.set_physics_process(false);w.enemies=[foe];w._select_enemy()
	w.dragon.aim=Vector3.FORWARD
	check(w.dragon.try_ability("breath"),"real Rime controller begins breath")
	var before=foe.hp
	w.dragon.advance_combat(.27)
	check(foe.hp==before,"world ice damage waits for windup")
	w.dragon.advance_combat(.02)
	check(foe.hp<before and foe.chilled>0.0,"landed ice contact damages and chills")
	var chilled=foe.chilled
	foe.spec.shield=true;foe.brain.mode="seek"
	check(foe.element_hit(20,"ice","breath")==0 and foe.chilled==chilled,"shield blocks new cold application")
	foe.spec.shield=false;w.dragon.advance_combat(.4);w.party.swap_remaining=0;w.dragon.input_grace=0
	check(w.swap_guardian("fire"),"return to Magma for shatter")
	w.dragon.input_grace=0;w.dragon.aim=Vector3.FORWARD;before=foe.hp
	check(w.dragon.try_ability("claw"),"Magma begins shatter follow-up")
	w.dragon.advance_combat(.11)
	check(is_equal_approx(before-foe.hp,24*1.4) and foe.chilled==0,"shatter adds forty percent once at real fire contact")
	check(is_equal_approx(foe.element_hit(10,"fire","claw"),10),"second fire hit does not reuse chill")
	w.dragon.advance_combat(.3);w.party.swap_remaining=0;w.dragon.input_grace=0;w.swap_guardian("ice");w.dragon.input_grace=0
	w.dragon.state.heat=0;w.dragon.state.cooldowns.clear()
	check(w.dragon.try_ability("burst"),"real Aegis begins")
	w.dragon.advance_combat(.21)
	check(w.dragon.state.ward==4,"Aegis starts at actual contact")
	w.dragon.advance_combat(.3);w.dragon.state.heat=0
	check(w.dragon.try_ability("wall"),"real permafrost cast")
	w.dragon.advance_combat(.25)
	check(w.walls.size()==1 and w.walls[0].guardian=="ice","persistent frost owns Ice identity")
	var field=w.walls[0];foe.position=field.at;foe.chilled=0;before=foe.hp
	w._tick_walls(.1)
	check(foe.hp<before and foe.chilled>0,"persistent ice field deals periodic damage and chills")
	w.dragon.advance_combat(.3);w.dragon.input_grace=0;w.party.swap_remaining=0;w.swap_guardian("fire")
	check(w.walls[0].guardian=="ice" and w.walls[0].damage==field.damage,"swap cannot relabel persistent field")
	foe.queue_free();w.enemies=[];w.enemy=null
	w.party.states.ice.hp=37;w.dragon.state.hp=0
	w._on_guardian_down()
	check(w.party.active_id=="ice" and w.dragon.state.hp==37 and not paused,"knockout hands off without healing")
	w.dragon.state.hp=0;w._on_guardian_down()
	check(paused and w.hud.overlay_kind=="defeat","both guardians down causes real defeat")
	w.hud.close_overlay();w.retry();await frames(5)
	check(w.party.states.fire.hp>0 and w.party.states.ice.hp>0,"checkpoint retry revives party")
	# Rooms are real, save remains valid, relays deliberately need Fire.
	w.hud.close_overlay();w.campaign.room="thaw-junction"
	if not w.campaign.visited.has("thaw-junction"):w.campaign.visited.append("thaw-junction")
	w._enter_room("thaw-junction",true);await frames(5)
	w._clear_encounter();w.campaign.cleared.append("frozen-guardian")
	w._enter_room("thaw-junction",true);await frames(5)
	if w.party.active_id!="ice":w.dragon.input_grace=0;w.swap_guardian("ice")
	var relay=w.conduits[0];w.dragon.position=relay.node.position+Vector3.BACK*2
	w.resolve_ability("breath",w.dragon.position,Vector3.FORWARD)
	check(relay.sim.heat==0,"Ice cannot silently charge thermal puzzle")
	var old_hp=w.party.states.ice.hp;w.party.states.fire.hp=17;w.party.states.fire.heat=58
	w.campaign.room="mute-channel";w.campaign.visited.append("mute-channel");w._enter_room("mute-channel",false);await frames(3)
	check(w.party.states.fire.hp==17 and w.party.states.fire.heat<=58 and w.party.states.fire.heat>50,"ordinary room travel preserves reserve resources")
	check(not Rules.normalize(w.campaign).is_empty(),"campaign with active reserve stays save-valid")
	w.return_to_forge();await frames(5)
	check(w.party.states.fire.hp==w.party.states.fire.max_hp,"shelter/Forge restores both guardians")
	w.hud.close_overlay();w.dragon.input_grace=0;w.party.swap_remaining=0
	if w.party.active_id!="ice":w.swap_guardian("ice")
	var probe=Probe.new();w.add_child(probe)
	check(probe.configure(w.dragon.rig.model,"ice_guardian") and probe.probes.size()==4,"four independent skinned sole samplers")
	probe.display_enabled=false
	var anchors={};var worst=0.0;var contacts=0;var clearance=INF
	w.dragon.mouse_aim=false;w.dragon.input_grace=0
	Input.action_press("ng_up")
	for frame in range(80):
		await physics_frame
		if frame==48:Input.action_release("ng_up")
		var points=probe.points()
		for side in points:
			var samples=points[side];var center=Vector3.ZERO;var low=INF
			for point in samples:center+=point;low=minf(low,point.y)
			center/=samples.size()
			var sample: Dictionary=w.dragon.rig.planting.samples.get(side,{})
			if sample.get("planted",false):
				var key=side+str(sample.plant_id)
				if not anchors.has(key):anchors[key]=center
				worst=maxf(worst,Vector2(center.x-anchors[key].x,center.z-anchors[key].z).length())
				contacts+=1
			var hit=w.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(center+Vector3.UP,center-Vector3.UP,64))
			if not hit.is_empty():clearance=minf(clearance,low-hit.position.y)
	Input.action_release("ng_up")
	check(contacts>160,"Rime walk and stop provide genuine stance coverage")
	check(worst<.015,"sampled Rime stance drift stays below 15 mm")
	check(clearance>=-.004,"sampled Rime soles stay above deck within 4 mm tolerance")
	print("RIME_CONTACT_SAMPLE: contacts=%d drift_m=%.6f clearance_m=%.6f" % [contacts,worst,clearance])
	w.queue_free();await frames(3)
	print("PARTY_TESTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
