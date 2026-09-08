extends SceneTree
const Rules=preload("res://campaign/progress.gd")
const Fusion=preload("res://campaign/fusion.gd")
const Combat=preload("res://campaign/guardian_combat.gd")
const Party=preload("res://campaign/party.gd")
const World=preload("res://campaign/world.gd")
const Enemy=preload("res://campaign/enemy.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1
	print(("PASS " if ok else "FAIL ")+label)
func frames(n=3):
	for i in range(n):await physics_frame
func eligible()->Dictionary:
	var c=Rules.fresh();Rules.hatch(c)
	c.guardians=["fire","ice","storm"];c.ice_rescued=true;c.lattice_recovered=true;c.storm_forged=true;c.loadout=["fire","storm"];c.evolutions={"fire":"flashfire","ice":"aegis","storm":""}
	c.cleared=["outer-boss","frozen-boss","storm-boss"]
	c.cores=["outer","frozen","storm"];c.installed=c.cores.duplicate()
	c.visited.append_array(["field-locker","signal-approach","firewall-span","overflow-vent","cold-archive","mute-channel","thaw-junction","memory-vault","frozen-vault","overclock-gantry","live-wire","wire-fork","logic-core","capacitor-cache","mirror-vestibule","recursive-gate","cold-lanterns","admin-vault"])
	c.room="admin-vault"
	return c
func run():
	var fresh=Rules.fresh();check(fresh.version==8,"fresh schema 8");check(not fresh.stone_imprint_recovered and not fresh.stone_forged,"fresh Stone flags false")
	var old=fresh.duplicate(true);old.version=5;old.erase("stone_imprint_recovered");old.erase("stone_forged");old.erase("venom_culture_recovered");old.erase("venom_forged")
	var migrated=Rules.normalize(old);check(migrated.version==8,"schema 5 migrates through Stone to schema 8");check(not migrated.stone_imprint_recovered and not migrated.stone_forged,"migration grants no Stone progress")
	var c=eligible();check(Fusion.recover_stone(c),"recover imprint in Admin Vault");check(not Fusion.recover_stone(c),"imprint one-time");check(Fusion.stone_reason(c)=="","eligible recipe ready")
	c.room="forge";check(Fusion.forge_stone(c),"temper imprint");check(not Fusion.forge_stone(c),"temper one-time");var pair=Fusion.members(c).duplicate();check(Fusion.hatch_stone(c),"awaken Cairn");check(c.guardians==["fire","ice","storm","stone"],"four owned guardians ordered");check(Fusion.members(c)==pair,"recruitment preserves expedition pair");check(not Fusion.hatch_stone(c),"Cairn one-time")
	check(not Rules.normalize(c).is_empty(),"four-guardian save valid")
	check(Fusion.equip_reserve(c,"stone"),"Cairn can enter two-slot pair");check(Fusion.members(c)==["fire","stone"],"pair remains two slots")
	var party=Party.new();party.rebuild(c);check(party.states.size()==2 and party.states.has("stone"),"only selected pair gets live states")
	var s=Combat.fresh("","stone");check(Combat.guardian_name("stone")=="CAIRN","guardian name");check(s.max_hp>Combat.fresh("","fire").max_hp,"Stone base health higher")
	for id in Combat.ORDER:
		check(Combat.rule(s,id).name!="","Stone move "+id)
		var t=Combat.fresh("","stone");check(Combat.cast(t,id),"Stone cast "+id);check(Combat.tick(t,Combat.rule(t,id).windup+.001)==id,"Stone contact "+id)
	var g=Combat.fresh("","stone");Combat.tick(g,.01,true);var before=g.hp;var dealt=Combat.damage(g,20);check(dealt>0 and dealt<20 and g.hp<before,"guard reduces real incoming hit");check(g.resolve==1,"guarded landed hit builds Resolve");g.iframes=0;Combat.damage(g,20);check(g.resolve==2,"second guarded hit builds Resolve");g.iframes=0;Combat.damage(g,20);g.iframes=0;Combat.damage(g,20);check(g.resolve==3,"Resolve capped at three")
	var base=Combat.fresh("","stone");var powered=Combat.fresh("","stone");powered.resolve=3;check(is_equal_approx(Combat.technique_damage(powered,"burst"),Combat.technique_damage(base,"burst")*1.6),"Earthshatter +60 percent at three Resolve")
	check(Combat.consume_resolve(powered)==3 and powered.resolve==0,"landed finisher helper spends Resolve")
	var scene=load("res://campaign/stone/stone_guardian.glb").instantiate()
	root.add_child(scene)
	var sk=scene.find_child("Skeleton3D",true,false)
	var ap=scene.find_child("AnimationPlayer",true,false)
	check(sk.get_bone_count()==18,"Stone rig has 18 bones")
	for clip in ["idle","walk","claw","breath","wall","burst","guard","hurt","defeat"]:
		check(ap.has_animation(clip),"Stone clip "+clip)
	scene.queue_free()
	await frames()
	var w=World.new();w.test_mode=true;root.add_child(w);await frames(4)
	w.campaign=c;w._enter_room("forge",true);await frames(4);w.party.rebuild(w.campaign);w.party.active_id="stone";w.dragon.use_guardian("stone",w.party.states.stone)
	check(w.dragon.guardian=="stone","world controller switches to Cairn")
	check(w.dragon.rig.player.has_animation("burst"),"world Cairn uses imported rig")
	w.dragon.input_grace=0;w.dragon.aim=Vector3.FORWARD
	var foe=Enemy.new();foe.spec={"id":"stone-test","name":"Stone Test","hp":800.0,"damage":10.0,"shield":true,"boss":false,"patterns":["slam"]}
	foe.target=w.dragon;foe.navigation=w;w.level.add_child(foe);foe.position=w.dragon.position+Vector3.FORWARD*3
	foe.set_physics_process(false);w.enemies=[foe];w._select_enemy()
	w.dragon.state.resolve=3
	check(w.dragon.try_ability("burst"),"controller begins shielded Earthshatter")
	w.dragon.advance_combat(.39)
	check(w.dragon.state.resolve==3,"closed shield preserves Earthshatter Resolve")
	w.dragon.advance_combat(.6);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0;foe.spec.shield=false
	var foe_hp=foe.hp
	check(w.dragon.try_ability("burst"),"controller begins open Earthshatter")
	w.dragon.advance_combat(.39)
	check(w.dragon.state.resolve==0 and foe.hp<foe_hp,"landed Earthshatter spends Resolve through real world routing")
	w.dragon.advance_combat(.6);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0
	check(w.dragon.try_ability("wall"),"controller casts Bulwark Field")
	w.dragon.advance_combat(.27)
	check(not w.walls.is_empty() and w.walls[-1].guardian=="stone","Bulwark Field snapshots Stone ownership")
	w.queue_free();await frames()
	print("STONE_TESTS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
