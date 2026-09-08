extends SceneTree
const Rules=preload("res://campaign/progress.gd")
const Fusion=preload("res://campaign/fusion.gd")
const Combat=preload("res://campaign/guardian_combat.gd")
const World=preload("res://campaign/world.gd")
const Enemy=preload("res://campaign/enemy.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):checks+=1;if not ok:failures+=1;print(("PASS " if ok else "FAIL ")+label)
func frames(n=3):
	for i in range(n):await physics_frame
func ready_nox()->Dictionary:
	var c=Rules.fresh();Rules.hatch(c);c.ice_rescued=true;c.lattice_recovered=true;c.storm_forged=true;c.stone_imprint_recovered=true;c.stone_forged=true;c.venom_culture_recovered=true;c.venom_forged=true
	c.guardians=["fire","ice","storm","stone","venom"];c.loadout=["fire","venom"];c.active_guardian="fire";c.evolutions={"fire":"flashfire","ice":"aegis","storm":""}
	c.cleared=["outer-boss","frozen-boss","storm-boss"];c.cores=["outer","frozen","storm"];c.installed=c.cores.duplicate()
	c.visited.append_array(["field-locker","signal-approach","firewall-span","overflow-vent","cold-archive","mute-channel","thaw-junction","memory-vault","frozen-vault","overclock-gantry","live-wire","wire-fork","logic-core","capacitor-cache","mirror-vestibule","recursive-gate","cold-lanterns","admin-vault"])
	c.room="forge";return c
func culture_fixture()->Dictionary:
	var c=ready_nox();c.guardians=["fire","ice","storm","stone"];c.loadout=["fire","stone"];c.active_guardian="fire";c.venom_culture_recovered=false;c.venom_forged=false;c.room="frozen-vault";return c
func run():
	var scene=load("res://campaign/venom/venom_guardian.glb").instantiate();root.add_child(scene)
	var sk=scene.find_child("Skeleton3D",true,false);var ap=scene.find_child("AnimationPlayer",true,false)
	check(sk!=null and sk.get_bone_count()>=18,"Nox imported frilled-wyrm skeleton")
	for clip in ["idle","walk","claw","breath","wall","burst","guard","hurt","defeat"]:check(ap.has_animation(clip),"Nox imported clip "+clip)
	scene.queue_free();await frames()
	var w=World.new();w.test_mode=true;root.add_child(w);await frames(5);w.title_open=false;w.hud.close_overlay()
	w.campaign=culture_fixture();w._enter_room("frozen-vault",true);await frames(5);check(not Rules.normalize(w.campaign).is_empty(),"pre-culture campaign valid")
	w.dragon.position=Vector3(-5,.1,-4);w.dragon.input_grace=0;check(w.interaction().contains("Venom"),"Frozen Vault exposes separate Venom culture")
	w.interact();check(w.campaign.venom_culture_recovered,"world interaction recovers Venom culture")
	w.hud.close_overlay();w.campaign.room="forge";w._enter_room("forge",true);await frames(5);w.dragon.position=Fusion.STATION+Vector3(0,.1,0);w.dragon.input_grace=0
	check(w.forge_venom(),"real Forge stabilizes Venom culture");check(w.hatch_venom(),"real Forge awakens Nox");check(w.campaign.guardians.has("venom"),"world recruitment owns Nox")
	w.hud.close_overlay();w.dragon.position=Vector3(6,.1,8);w.dragon.input_grace=0;check(w.equip_reserve("venom"),"Nursery equips Nox as reserve");w.hud.close_overlay();w.party.swap_remaining=0;w.dragon.input_grace=0;check(w.swap_guardian("venom"),"world swaps to Nox")
	check(w.dragon.guardian=="venom" and w.dragon.rig.player.has_animation("burst"),"Nox controller uses imported rig")
	var foe=Enemy.new();foe.spec={"id":"venom-runtime","name":"Toxin Target","hp":900.0,"damage":10.0,"shield":false,"boss":false,"patterns":["slam"],"archetype":"bruiser"};foe.target=w.dragon;foe.navigation=w;w.level.add_child(foe);foe.position=w.dragon.position+Vector3.FORWARD*3;foe.set_physics_process(false);w.enemies=[foe];w._select_enemy();w.dragon.aim=Vector3.FORWARD;w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0
	check(w.dragon.try_ability("breath"),"Nox begins Acid Spit");w.dragon.advance_combat(.23);check(foe.toxin==1 and foe.hp<foe.max_hp,"landed Acid Spit applies one Toxin")
	var tick_hp=foe.hp;foe.spec.shield=true;foe.tick_toxin(1.01);check(foe.hp<tick_hp and foe.toxin==1,"existing Toxin ticks through reclosed shield")
	var stack_before=foe.toxin;var shield_hp=foe.hp;w.dragon.advance_combat(.4);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0;check(w.dragon.try_ability("claw"),"Nox begins shielded Fang");w.dragon.advance_combat(.12);check(foe.hp==shield_hp and foe.toxin==stack_before,"shield blocks Fang and new Toxin")
	foe.spec.shield=false;foe.toxin=3;foe.toxin_time=5;foe.toxin_tick=1;w.dragon.advance_combat(.3);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0;var bloom_hp=foe.hp;check(w.dragon.try_ability("burst"),"Nox begins open Septic Bloom");w.dragon.advance_combat(.31);check(foe.toxin==0 and bloom_hp-foe.hp>Combat.rule(w.dragon.state,"burst").damage,"landed Bloom consumes Toxin and gains stack damage")
	foe.toxin=3;foe.toxin_time=5;foe.toxin_tick=1;foe.spec.shield=true;w.dragon.advance_combat(.5);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0;check(w.dragon.try_ability("burst"),"Nox begins blocked Bloom");w.dragon.advance_combat(.31);check(foe.toxin==3,"shield-blocked Bloom preserves Toxin")
	foe.spec.shield=false;w.dragon.advance_combat(.5);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0;check(w.dragon.try_ability("wall"),"Nox casts Toxic Cloud");w.dragon.advance_combat(.23);check(not w.walls.is_empty() and w.walls[-1].guardian=="venom","Toxic Cloud snapshots Venom ownership");var cloud=w.walls[-1];foe.position=cloud.at;foe.toxin=0;foe.toxin_time=0;w._tick_walls(.1);check(foe.toxin==1,"Toxic Cloud damaging tick applies Toxin")
	w.queue_free();await frames(4);print("VENOM_RUNTIME_TESTS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
