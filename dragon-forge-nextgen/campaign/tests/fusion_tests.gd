extends SceneTree
const World=preload("res://campaign/world.gd")
const Rules=preload("res://campaign/progress.gd")
const Fusion=preload("res://campaign/fusion.gd")
const Growth=preload("res://campaign/growth.gd")
const Combat=preload("res://campaign/guardian_combat.gd")
const Party=preload("res://campaign/party.gd")
const Store=preload("res://campaign/save_store.gd")
const Enemy=preload("res://campaign/enemy.gd")
const Prior=preload("res://campaign/tests/evolution_tests.gd")
const Studio=preload("res://validation/character_inspection.gd")
var checks=0
var failures=0
var w
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1
	print(("PASS " if ok else "FAIL ")+label)
func frames(n: int=3) -> void:
	for i in range(n): await physics_frame
static func eligible() -> Dictionary:
	var c=Prior.eligible()
	Growth.select(c,"fire","flashfire"); Growth.select(c,"ice","deepwinter")
	c.visited.append("capacitor-cache")
	c.cleared.append("storm-guardian")
	return c
static func recruited() -> Dictionary:
	var c=eligible();c.room="capacitor-cache";Fusion.recover(c);c.room="forge"
	Fusion.forge(c);Fusion.hatch(c)
	return c
func run() -> void:
	var c=Rules.fresh()
	check(not Fusion.forge(c) and not Fusion.hatch(c),"no dormant/free unearned fusion")
	c=eligible()
	check(not Rules.normalize(c).is_empty(),"eligible source fixture valid")
	check(Fusion.reason(c).contains("lattice"),"both evolved parents still require lattice")
	check(not Fusion.recover(c),"lattice cannot be recovered remotely")
	c.room="capacitor-cache"
	check(Fusion.recover(c) and not Fusion.recover(c),"lattice recovery is independent and exactly once")
	check(not Fusion.forge(c),"fusion cannot occur in cache")
	c.room="forge"
	var before=c.duplicate(true)
	check(Fusion.forge(c) and not Fusion.forge(c),"one saved Storm egg can be created")
	check(not c.guardians.has("storm"),"forging is separate from hatching")
	check(Fusion.hatch(c) and not Fusion.hatch(c),"one Storm hatch only")
	check(c.guardians==["fire","ice","storm"],"both parents remain owned")
	for key in ["evolutions","cores","installed","cleared","caches","salvage","active_guardian","upgrades"]:
		check(c[key]==before[key],"fusion preserves "+key)
	check(Fusion.members(c)==["fire","ice"],"hatch does not silently replace field pair")
	check(not Rules.normalize(c).is_empty(),"three owned two selected save valid")
	for version in [1,2,3]:
		var old=eligible();old.version=version;old.evolutions.erase("storm")
		for field in ["lattice_recovered","storm_forged","loadout"]:old.erase(field)
		if version<3:old.erase("evolutions")
		if version==1:
			for field in ["guardians","active_guardian","ice_rescued"]:old.erase(field)
		var store=Store.new();store.path="user://fusion-migration-%d.json"%version;store.import_legacy=false
		var bytes=JSON.stringify(old,"  ")
		var f=FileAccess.open(store.path,FileAccess.WRITE);f.store_string(bytes);f.close()
		var migrated=store.read_campaign()
		check(migrated.version==6 and not migrated.storm_forged and not migrated.lattice_recovered,"old version %d grants no unearned fusion"%version)
		check(migrated.salvage==old.salvage and migrated.cleared==old.cleared,"old version %d keeps existing journey"%version)
		check(FileAccess.get_file_as_string(store.path)==bytes,"load preserves exact bytes version %d"%version)
		check(store.write_campaign(migrated) and FileAccess.get_file_as_string(store.path+".bak")==bytes,"first new write backs up old bytes version %d"%version)
		for suffix in ["",".bak",".tmp"]:
			if FileAccess.file_exists(store.path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path+suffix))
	for pair in [[],["fire","fire"],["fire","void"],["storm","ice"],["fire","ice","storm"],"fire"]:
		var bad=c.duplicate(true);bad.loadout=pair
		check(Rules.normalize(bad).is_empty(),"invalid or active-excluding loadout rejected "+str(pair))
	for field in ["storm_forged","lattice_recovered"]:
		var bad=c.duplicate(true);bad[field]=false
		check(Rules.normalize(bad).is_empty(),"unearned Storm blocked / "+field)
	var future=c.duplicate(true);future.version=99
	check(Rules.normalize(future).is_empty(),"future fusion save protected")
	var party=Party.new();party.rebuild(c)
	check(party.states.size()==2 and not party.states.has("storm"),"benched Storm has no field state")
	check(not party.swap_to("storm"),"cannot swap into a benched guardian")
	c.room="live-wire"
	check(not Fusion.equip_reserve(c,"storm"),"no remote party reconfiguration")
	c.room="forge"
	check(Fusion.equip_reserve(c,"storm") and not Fusion.equip_reserve(c,"storm"),"explicit reserve selection is idempotent")
	party.rebuild(c)
	check(party.states.keys()==["fire","storm"],"selected pair only appears in live combat")
	check(is_equal_approx(party.states.storm.max_hp,102.0),"Storm base HP is 102 before modules")
	check(party.swap_to("storm"),"selected healthy Arc swaps normally")
	for id in Combat.ORDER:
		var state=Combat.fresh("","storm")
		check(Combat.cast(state,id),"Storm can cast "+id)
		check(Combat.tick(state,Combat.rule(state,id).windup-.01)=="","no early Storm contact "+id)
		check(Combat.tick(state,.011)==id and Combat.tick(state,2.0)=="","exactly one Storm contact "+id)
		state=Combat.fresh("","storm");Combat.cast(state,id);Combat.dodge(state)
		check(Combat.tick(state,2.0)=="","dodge cancels pending Storm contact "+id)
	w=World.new();w.test_mode=true;root.add_child(w);await frames(4)
	w.campaign=eligible();w.campaign.room="capacitor-cache";w._enter_room(w.campaign.room,true);await frames()
	w.dragon.position=Fusion.LATTICE+Vector3.UP*.1;w.dragon.input_grace=0
	w.interact()
	check(w.campaign.lattice_recovered and w.hud.overlay_kind=="lattice" and paused,"actual plinth recovery opens paused reward")
	w.hud.close_overlay();w.return_to_forge();await frames(5)
	check(not w.forge_storm(),"world denies fusion away from its station")
	w.dragon.position=Fusion.STATION+Vector3.UP*.1;w.dragon.input_grace=0;w.dragon.state.hp=52
	w.interact()
	check(w.hud.overlay_kind=="fusion" and paused,"actual fusion station opens preview")
	check(w.forge_storm() and w.level.storm_egg.visible,"forge method creates visible saved egg")
	check(w.dragon.state.hp==52,"forging grants no surprise heal")
	check(w.hatch_storm() and w.campaign.guardians.size()==3 and not w.level.storm_egg.visible,"world hatch recruits Arc and hides egg")
	check(w.party.states.size()==2 and not w.equip_reserve("storm"),"hatch retains pair and rejects wrong-station loadout")
	w.hud.close_overlay();w.dragon.position=Vector3(6,.1,8);w.dragon.input_grace=0
	check(w.equip_reserve("storm"),"nursery selection equips Arc as reserve")
	check(w.hud.overlay_kind=="party" and paused,"equipment result stays paused with collection")
	w.hud.close_overlay();w.dragon.input_grace=0
	var at: Vector3=w.dragon.position
	w.dragon.state.hp=54;w.dragon.state.heat=33;w.dragon.state.cooldowns.wall=4
	check(w.swap_guardian("storm"),"real actor switches to Arc")
	check(w.dragon.position==at and w.party.states.fire.hp==54 and w.party.states.fire.heat==33,"swap preserves collider and outgoing resources")
	check(w.dragon.rig.skeleton.get_bone_count()==17 and w.dragon.state.guardian=="storm","actual Storm export and combat adapter loaded")
	for clip in ["idle","walk","claw","breath","wall","burst","guard","hurt","defeat"]:
		check(w.dragon.rig.player.has_animation(clip),"Arc imported clip "+clip)
	w.dragon.rig.animate(0,0,false,w.dragon.state)
	check(w.dragon.rig.muzzle_position().is_finite(),"Storm muzzle follows a valid imported head")
	var foe=Enemy.new();foe.spec={"id":"test","name":"Test","hp":800.0,"damage":10.0,"shield":false,"boss":false,"patterns":["slam"]}
	foe.target=w.dragon;foe.navigation=w;w.level.add_child(foe);foe.position=w.dragon.position+Vector3.FORWARD*3
	foe.set_physics_process(false);w.enemies=[foe];w._select_enemy()
	w.dragon.input_grace=0;w.dragon.aim=Vector3.FORWARD
	var hp=foe.hp
	check(w.dragon.try_ability("breath"),"controller begins Arc Lance")
	w.dragon.advance_combat(.25)
	check(foe.hp==hp,"Arc Lance waits for actual contact")
	w.dragon.advance_combat(.02)
	check(is_equal_approx(hp-foe.hp,32.0) and foe.charged==4.0,"landed Lance damages and applies four seconds of Charge")
	var timer=foe.brain.timer
	foe.spec.shield=true;foe.brain.mode="seek"
	hp=foe.hp
	check(foe.element_hit(52,"storm","burst")==0 and foe.charged==4 and foe.hp==hp,"closed shield blocks discharge without consuming Charge")
	foe.charged=0
	check(foe.element_hit(32,"storm","breath")==0 and foe.charged==0,"shield blocks new Charge")
	foe.spec.shield=false;foe.charged=4
	check(is_equal_approx(foe.element_hit(52,"storm","burst"),78.0) and foe.charged==0,"Tempest consumes Charge for a fifty percent bonus")
	check(is_equal_approx(foe.element_hit(52,"storm","burst"),52.0),"no second consumption bonus")
	check(foe.brain.timer==timer,"elemental marks never change enemy attack timer")
	w.dragon.advance_combat(1);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0
	check(w.dragon.try_ability("wall"),"Static Well can be cast through real actor")
	w.dragon.advance_combat(.25)
	check(w.walls.size()==1 and w.walls[0].guardian=="storm","persistent Static Well stores Storm caster")
	w.dragon.advance_combat(.5);w.party.swap_remaining=0;w.dragon.input_grace=0
	w.swap_guardian("fire");hp=foe.hp;foe.charged=0;w._tick_walls(.1)
	check(is_equal_approx(hp-foe.hp,10.0) and foe.charged==4.0,"Storm field keeps snapshotted damage and charge after swapping")
	w._clear_encounter();await frames()
	w.party.states.fire.hp=0;w.party.states.storm.hp=0;w.dragon.state=w.party.states.fire;w.party.active_id="fire"
	w._on_guardian_down()
	check(w.hud.overlay_kind=="defeat" and w.party.states.size()==2,"benched living Rime cannot become a third life")
	w.hud.close_overlay();w.retry();await frames(5)
	check(w.party.states.fire.hp>0 and w.party.states.storm.hp>0 and not w.party.states.has("ice"),"retry restores exactly chosen pair")
	check(w.campaign.guardians.size()==3 and w.campaign.storm_forged,"retry retains fusion ownership")
	w.queue_free();await frames()
	var studio=Studio.new();root.add_child(studio);await frames()
	var actor_picker: OptionButton=studio.find_children("*","OptionButton",true,false)[0]
	check(actor_picker.item_count==14,"all fourteen actual actors appear in the inspection picker")
	actor_picker.select(6);actor_picker.item_selected.emit(6)
	check(not studio.feet.valid and studio.feet.error.contains("hovers"),"hovering rig is not misreported as foot-locked")
	check(studio.actor_id=="storm_guardian" and studio.skeleton.get_bone_count()==17,"inspection scene loads real Arc asset")
	for clip in studio.clips:
		studio.select_clip(studio.clips.find(clip));studio.scrub(studio.player.get_animation(clip).length*.5)
		check(studio.skeleton.get_bone_global_pose(0).origin.is_finite(),"finite inspected pose "+clip)
	studio.queue_free();await frames()
	print("FUSION_TESTS: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
