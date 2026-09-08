extends SceneTree
const Rules=preload("res://campaign/progress.gd")
const Fusion=preload("res://campaign/fusion.gd")
const Combat=preload("res://campaign/guardian_combat.gd")
const World=preload("res://campaign/world.gd")
const ShadowContract=preload("res://release/shadow_contract.gd")
const Enemy=preload("res://campaign/enemy.gd")
var checks=0
var failures=0
func _initialize():
	root.size = Vector2i(1280,720)
	call_deferred("run")
func check(ok:bool,label:String):checks+=1;if not ok:failures+=1;print(("PASS " if ok else "FAIL ")+label)
func frames(n=3):
	for i in range(n):await physics_frame
func reachable(w, scroll_name: String, control_name: String, label: String):
	await frames(3)
	var scroll = w.hud.overlay_column.find_child(scroll_name, true, false)
	var control = w.hud.overlay_column.find_child(control_name, true, false)
	check(scroll != null and control != null, label + " exists in bounded scroll")
	if scroll == null or control == null:return
	check(not control.disabled, label + " is available at its Forge station")
	control.grab_focus()
	await frames(3)
	var viewport = w.hud.root.get_global_rect()
	check(scroll.follow_focus and scroll.scroll_vertical > 0 and viewport.encloses(scroll.get_global_rect()) and scroll.get_global_rect().encloses(control.get_global_rect()), label + " follows focus fully into the HUD viewport")
	check(viewport.encloses(w.hud.overlay_column.get_global_rect()), label + " retains the fixed title and exit controls on-screen")

func ready_nox()->Dictionary:
	var c=Rules.fresh();Rules.hatch(c);c.ice_rescued=true;c.lattice_recovered=true;c.storm_forged=true;c.stone_imprint_recovered=true;c.stone_forged=true;c.venom_culture_recovered=true;c.venom_forged=true
	c.guardians=["fire","ice","storm","stone","venom"];c.loadout=["fire","venom"];c.active_guardian="fire";c.evolutions={"fire":"flashfire","ice":"aegis","storm":""}
	c.cleared=["outer-boss","frozen-boss","storm-boss"];c.cores=["outer","frozen","storm"];c.installed=c.cores.duplicate();c.room="forge";return c
func run():
	var scene=load("res://campaign/shadow/shadow_guardian.glb").instantiate();root.add_child(scene)
	var sk=scene.find_child("Skeleton3D",true,false);var ap=scene.find_child("AnimationPlayer",true,false)
	check(sk!=null and sk.get_bone_count()==26,"Umbra imported negative-space skeleton has 26 bones")
	for clip in ["idle","walk","claw","breath","wall","burst","guard","hurt","defeat"]:check(ap.has_animation(clip),"Umbra imported clip "+clip)
	scene.queue_free();await frames()
	var w=World.new();w.test_mode=true;root.add_child(w);await frames(5);w.title_open=false;w.hud.close_overlay();w.campaign=ready_nox();w._enter_room("forge",true);await frames(5);w.dragon.position=Fusion.STATION+Vector3(0,.1,0);w.dragon.input_grace=0
	w.hud.show_fusion();await reachable(w,"ResonanceScroll","ForgeShadow","Shadow resonance action")
	check(w.forge_shadow(),"real Forge creates Shadow resonance")
	await reachable(w,"ResonanceScroll","AwakenUmbra","Umbra awakening action")
	check(w.hatch_shadow(),"real Forge awakens Umbra");check(w.campaign.guardians==["fire","ice","storm","stone","venom","shadow"],"world owns six ordered guardians")
	w.hud.close_overlay();w.dragon.position=Vector3(6,.1,8);w.dragon.input_grace=0
	w.hud.show_party();await reachable(w,"GuardianScroll","EquipReserve_shadow","Sixth guardian reserve action")
	check(w.equip_reserve("shadow"),"Nursery equips Umbra as reserve");w.hud.close_overlay();w.party.swap_remaining=0;w.dragon.input_grace=0;check(w.swap_guardian("shadow"),"world swaps to Umbra")
	check(w.dragon.guardian=="shadow" and w.dragon.rig.skeleton.get_bone_count()==26 and w.dragon.rig.player.has_animation("burst"),"Umbra controller uses actual imported rig")
	ShadowContract.run(w,check)
	var hp=w.dragon.state.hp;check(Combat.dodge(w.dragon.state),"Umbra begins authoritative dodge");check(w.dragon.receive_damage(22)==0 and w.dragon.state.hp==hp and w.dragon.state.phase==1,"real world incoming hit during i-frames earns Phase")
	check(w.dragon.receive_damage(22)==0 and w.dragon.state.phase==2,"second real world hit reaches Phase cap")
	w.dragon.advance_combat(.30);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0
	var foe=Enemy.new();foe.spec={"id":"shadow-runtime","name":"Phase Target","hp":900.0,"damage":10.0,"shield":true,"boss":false,"patterns":["slam"],"archetype":"bulwark"};foe.target=w.dragon;foe.navigation=w;w.level.add_child(foe);foe.position=w.dragon.position+Vector3.FORWARD*3;foe.set_physics_process(false);w.enemies=[foe];w._select_enemy();w.dragon.aim=Vector3.FORWARD
	var blocked_hp=foe.hp;check(w.dragon.try_ability("burst"),"Umbra begins shielded Phase Strike");w.dragon.advance_combat(.21);check(foe.hp==blocked_hp and w.dragon.state.phase==2,"closed shield blocks Phase Strike and preserves Phase")
	w.dragon.advance_combat(.5);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0;foe.brain.open_window(2.0);var open_hp=foe.hp
	check(w.dragon.try_ability("burst"),"Umbra begins open Phase Strike");w.dragon.advance_combat(.21);check(foe.spec.shield and foe.brain.vulnerable(),"open Phase Strike retains the real enabled shield and vulnerability window");check(w.dragon.state.phase==0 and open_hp-foe.hp>Combat.SHADOW.burst.damage,"landed Phase Strike spends Phase through real world routing")
	w.dragon.advance_combat(.5);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0;check(w.dragon.try_ability("wall"),"Umbra casts Umbral Wake");w.dragon.advance_combat(.19);check(not w.walls.is_empty() and w.walls[-1].guardian=="shadow","Umbral Wake snapshots Shadow ownership")
	var field=w.walls[-1];w.dragon.advance_combat(.5);w.party.swap_remaining=0;w.dragon.input_grace=0;check(w.swap_guardian("fire"),"swap away from Umbra");check(field.guardian=="shadow" and w.walls[-1].guardian=="shadow","swap cannot relabel persistent Shadow field")
	w.campaign.room="thaw-junction";if not w.campaign.visited.has("thaw-junction"):w.campaign.visited.append("thaw-junction");w._enter_room("thaw-junction",true);await frames(4);w._clear_encounter();if not w.campaign.cleared.has("frozen-guardian"):w.campaign.cleared.append("frozen-guardian");w._enter_room("thaw-junction",true);await frames(4)
	w.campaign.loadout=["fire","shadow"];w.party.rebuild(w.campaign);w.party.active_id="shadow";w.dragon.use_guardian("shadow",w.party.states.shadow);w.dragon.input_grace=0;var relay=w.conduits[0];w.dragon.position=relay.node.position+Vector3.BACK*2;w.dragon.aim=Vector3.FORWARD;w.resolve_ability("breath",w.dragon.position,Vector3.FORWARD);check(relay.sim.heat==0,"Void Pulse cannot power thermal relay")
	w.queue_free();await frames(4);print("SHADOW_RUNTIME_TESTS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
