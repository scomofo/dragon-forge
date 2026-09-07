extends SceneTree
const World = preload("res://campaign/world.gd")
const Rules = preload("res://campaign/progress.gd")
const Growth = preload("res://campaign/growth.gd")
const Combat = preload("res://campaign/guardian_combat.gd")
const Party = preload("res://campaign/party.gd")
const Prior = preload("res://campaign/tests/fusion_tests.gd")
const Store = preload("res://campaign/save_store.gd")
const Studio = preload("res://validation/character_inspection.gd")
var checks = 0
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+label)
func frames(n: int = 3) -> void:
	for i in range(n): await physics_frame
static func eligible() -> Dictionary:
	var c = Prior.recruited()
	c.cleared.append("storm-boss")
	c.cores.append("storm")
	c.installed.append("storm")
	return c
func run() -> void:
	var c = Prior.recruited()
	check(not Growth.select(c,"storm","thunderhead"),"Arc waits for third installed core")
	c = eligible()
	check(not Rules.normalize(c).is_empty(),"three-core fixture valid")
	check(Growth.reason(c,"storm")=="", "earned Arc evolution available")
	check(Growth.form_name("storm",true)=="Tempest Arc","third evolved name")
	var before=c.duplicate(true)
	check(Growth.select(c,"storm","thunderhead"),"Thunderhead selection succeeds")
	check(not Growth.select(c,"storm","thunderhead"),"repeat selection idempotent")
	for key in ["salvage","guardians","cores","loadout","cleared","installed"]:
		check(before[key]==c[key],"evolving Arc preserves "+key)
	check(c.evolutions.fire==before.evolutions.fire and c.evolutions.ice==before.evolutions.ice,"parents' choices retained")
	check(not Growth.select(c,"storm","flashfire") and not Growth.select(c,"fire","overcharge"),"cross-guardian traits rejected")
	c.room="live-wire"
	check(not Growth.select(c,"storm","overcharge"),"no remote reconfiguration")
	c.room="forge"
	check(Growth.select(c,"storm","overcharge"),"free safe reconfiguration")
	var old=eligible();old.version=4;old.evolutions.erase("storm")
	var old_bytes=JSON.stringify(old,"  ")
	var store=Store.new();store.import_legacy=false;store.path="user://tempest-test-save.json"
	var f=FileAccess.open(store.path,FileAccess.WRITE);f.store_string(old_bytes);f.close()
	var migrated=store.read_campaign()
	check(migrated.version==5 and migrated.evolutions.storm=="","schema4 does not auto-evolve Arc")
	for key in ["salvage","room","cleared","installed","guardians","loadout","active_guardian"]:
		check(migrated[key]==old[key],"schema4 keeps "+key)
	check(FileAccess.get_file_as_string(store.path)==old_bytes,"load leaves old bytes alone")
	check(store.write_campaign(migrated) and FileAccess.get_file_as_string(store.path+".bak")==old_bytes,"first new write backs up schema4 bytes")
	for bad_choice in [true,[],"aegis","unknown"]:
		var bad=c.duplicate(true);bad.evolutions.storm=bad_choice
		check(Rules.normalize(bad).is_empty(),"malformed Storm choice rejected "+str(bad_choice))
	var bad=c.duplicate(true);bad.installed.erase("storm")
	check(Rules.normalize(bad).is_empty(),"unearned Storm evolution not loadable")
	bad=old.duplicate(true);bad.evolutions.storm="overcharge"
	check(Rules.normalize(bad).is_empty(),"extra-key legacy state not silently accepted")
	bad=c.duplicate(true);bad.version=99
	f=FileAccess.open(store.path,FileAccess.WRITE);f.store_string(JSON.stringify(bad));f.close()
	store.read_campaign()
	check(not store.write_campaign(c),"future save protected")
	for suffix in ["",".tmp",".bak"]:
		if FileAccess.file_exists(store.path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path+suffix))
	for specialization in ["thunderhead","overcharge"]:
		var state=Combat.fresh("","storm");state.evolution=specialization
		check(is_equal_approx(Combat.technique_damage(state,"burst"),57.2),"evolved discharge damage once / "+specialization)
		check(Combat.charge_duration(state)==(6.0 if specialization=="thunderhead" else 4.0),"charge duration / "+specialization)
		check(Combat.rule(state,"burst").cooldown==(6.75 if specialization=="overcharge" else 9.0),"discharge cooldown / "+specialization)
		for id in Combat.ORDER:
			state.cooldowns.clear();state.heat=0;Combat.cancel_action(state)
			check(Combat.cast(state,id),specialization+" casts "+id)
			var windup=Combat.rule(state,id).windup
			check(Combat.tick(state,windup-.001)=="","no early contact")
			check(Combat.tick(state,.002)==id and Combat.tick(state,2.0)=="","one contact only")
	check(Combat.STORM.burst.cooldown==9.0,"base Storm constant unchanged")
	var w=World.new();w.test_mode=true;root.add_child(w);await frames()
	w.campaign=eligible();w.campaign.loadout=["fire","storm"];w._enter_room("forge",true);await frames()
	check(not w.choose_evolution("storm","thunderhead"),"world rejects far-from-Nursery request")
	w.dragon.position=Vector3(6,.1,8);w.dragon.input_grace=0;w.hud.show_party()
	check(w.choose_evolution("storm","thunderhead"),"paused Nursery accepts actual evolution")
	check(w.hud.overlay_kind=="evolved" and paused,"result remains paused")
	w.hud.close_overlay();w.dragon.input_grace=0
	check(w.swap_guardian("storm"),"swap uses Tempest state")
	check(is_equal_approx(w.dragon.state.max_hp,112.2),"Arc gets 10 percent HP")
	check(w.dragon.rig.model.scene_file_path.ends_with("tempest_arc.glb"),"actual evolved GLB loaded")
	w.campaign.room="live-wire";w.campaign.visited.append("live-wire");w._enter_room("live-wire",true);await frames()
	w.dragon.input_grace=0;w.dragon.position=Vector3(0,.1,-2);w.dragon.aim=Vector3.FORWARD
	w.enemy.set_physics_process(false);w.enemy.position=Vector3(0,.1,-6)
	w.enemy.brain.open_window(9.0)
	w.resolve_ability("breath",w.dragon.position,Vector3.FORWARD)
	check(w.enemy.charged==6.0,"Thunderhead applies six seconds on real landed Lance")
	w.resolve_ability("wall",w.dragon.position,Vector3.FORWARD)
	check(w.walls[-1].charge_duration==6.0 and w.walls[-1].guardian=="storm","field snapshots caster and duration")
	w.party.swap_remaining=0;w.dragon.input_grace=0;w.swap_guardian("fire")
	w.enemy.charged=0;w._tick_walls(.01)
	check(w.enemy.charged==6.0,"Thunderhead field keeps duration after swap")
	w.enemy.spec.shield=true;w.enemy.brain.mode="seek";w.enemy.charged=2.0
	check(w.enemy.element_hit(50,"storm","burst",3,6)==0 and w.enemy.charged==2.0,"blocked Discharge does not consume Charge")
	w.enemy.brain.open_window(5.0);w.enemy.hp=300
	check(w.enemy.element_hit(50,"storm","burst",3,6)==75 and w.enemy.charged==0,"landed discharge consumes once")
	check(w.enemy.element_hit(50,"storm","burst",3,6)==50,"no repeated charged bonus")
	w.hud.close_overlay();w.queue_free();await frames()
	var studio=Studio.new();root.add_child(studio);await frames()
	studio.load_actor(7)
	check(studio.actor_id=="tempest_arc" and studio.clips.size()==9,"inspector supports actual Tempest and all nine clips")
	check(not studio.feet.valid and studio.feet.error.begins_with("Arc hovers"),"hovering inspector explicitly declines planted-foot measurements")
	studio.queue_free();await frames()
	print("TEMPEST_TESTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
