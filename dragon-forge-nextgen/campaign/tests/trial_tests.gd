extends SceneTree
const Rules=preload("res://campaign/progress.gd")
const Trials=preload("res://campaign/trials.gd")
const Store=preload("res://campaign/trial_store.gd")
const Roles=preload("res://campaign/enemy_roles.gd")
const World=preload("res://campaign/world.gd")
const Data=preload("res://campaign/data.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1
	print(("PASS " if ok else "FAIL ")+label)
func frames(n=4):
	for i in range(n):await physics_frame
func campaign_ready()->Dictionary:
	var c=Rules.fresh();Rules.hatch(c)
	c.guardians=["fire","ice","storm","stone"];c.ice_rescued=true;c.lattice_recovered=true;c.storm_forged=true;c.stone_imprint_recovered=true;c.stone_forged=true
	c.loadout=["fire","stone"];c.active_guardian="fire";c.evolutions={"fire":"flashfire","ice":"aegis","storm":"overcharge"}
	c.cleared=["outer-boss","frozen-boss","storm-boss","admin-boss"]
	c.cores=["outer","frozen","storm","admin"];c.installed=c.cores.duplicate();c.room="forge"
	return c
func run():
	check(Roles.valid("bruiser") and Roles.valid("bulwark") and Roles.valid("sniper") and Roles.valid("skirmisher") and Roles.valid("controller"),"five ordinary enemy roles")
	check(Roles.profile("sniper").engage>Roles.profile("bruiser").engage,"sniper engages farther out")
	check(Roles.profile("skirmisher").speed>Roles.profile("bulwark").speed,"skirmisher moves faster than bulwark")
	check(Roles.profile("bulwark").recover>Roles.profile("bruiser").recover,"bulwark gives longer recovery counter-window")
	check(Data.ROOMS["signal-approach"].enemies[0].archetype=="bruiser","Outer patrol is bruiser")
	check(Data.ROOMS["firewall-span"].enemies[0].archetype=="bulwark","Outer guardian is bulwark")
	check(Data.ROOMS["mute-channel"].enemies[0].archetype=="sniper","Frozen patrol is sniper")
	check(Data.ROOMS["live-wire"].enemies[0].archetype=="skirmisher","Storm patrol is skirmisher")
	check(Data.ROOMS["recursive-gate"].enemies[0].archetype=="controller","Admin patrol is controller")
	var c=campaign_ready()
	check(Trials.available(c).size()==8,"four sector drills plus four cleared boss echoes available")
	check(not Trials.unlocked(c,"echo-singularity"),"final echo remains locked before final clear")
	check(Trials.waves("outer-pressure").size()==2,"Pressure Test has two waves")
	check(Trials.waves("frozen-crossfire")[1].size()==2,"Cold Crossfire ends with two-enemy pressure")
	check(Trials.waves("echo-outer")[0][0].id=="outer-boss","boss echo reuses actual boss id and presentation")
	check(int(Trials.waves("echo-outer")[0][0].salvage)==0,"boss echo grants no salvage")
	var trial_store=Store.new();var records=trial_store.fresh()
	check(trial_store.apply_record(records,"outer-pressure",12345,27,["fire","stone"]),"record helper accepts valid result")
	check(records.records["outer-pressure"].best_ms==12345 and records.records["outer-pressure"].best_damage==27,"first clear sets both personal bests")
	trial_store.apply_record(records,"outer-pressure",14000,12,["stone","fire"])
	check(records.records["outer-pressure"].best_ms==12345 and records.records["outer-pressure"].best_damage==12,"time and damage personal bests improve independently")
	check(records.records["outer-pressure"].clears==2,"trial clear count increments")
	check(not trial_store.normalize(records).is_empty(),"trial record schema validates")
	var save_path="user://trial-tests-%s.json"%str(Time.get_ticks_usec());trial_store.path=save_path
	check(trial_store.write_records(records),"trial records write to separate file")
	check(FileAccess.file_exists(save_path),"separate trial record file exists")
	check(trial_store.path!="user://reconnection-campaign.json","trial store never targets campaign save")
	var reloaded=trial_store.read_records();check(reloaded.records["outer-pressure"].clears==2,"trial record roundtrip")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(save_path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
	var w=World.new();w.test_mode=true;root.add_child(w);await frames(5)
	w.campaign=c.duplicate(true);w._enter_room("forge",true);await frames(5)
	var before=JSON.stringify(w.campaign)
	check(w.start_forge_trial("outer-pressure"),"world launches unlocked Forge Trial")
	await frames(5)
	check(w.forge_trial_active and w.forge_trial_wave==0 and w.enemies.size()==1,"trial chamber starts wave one")
	check(w.repairs==0,"Forge Trials disable shared repair charges for comparable records")
	check(w.campaign.room=="forge","trial arena does not replace campaign room")
	var campaign_active=w.campaign.active_guardian
	w.dragon.input_grace=0;check(w.swap_guardian("stone"),"trial allows normal pair swap")
	check(w.campaign.active_guardian==campaign_active,"trial swap does not persist active guardian into campaign")
	for foe in w.enemies.duplicate():foe.take_hit(9999,true)
	await frames(6)
	check(w.forge_trial_wave==1 and w.enemies.size()==2,"clearing wave one advances to two-enemy wave")
	for foe in w.enemies.duplicate():foe.take_hit(9999,true)
	await frames(8)
	check(w.forge_trial_finished and w.trial_records.records.has("outer-pressure"),"clearing final wave records result")
	check(JSON.stringify(w.campaign)==before,"trial clear leaves complete campaign state byte-equivalent in memory")
	check(w.campaign.salvage==c.salvage and w.campaign.cleared==c.cleared,"trial grants no campaign salvage or clear flags")
	w.leave_trial();await frames(6)
	check(not w.forge_trial_active and w.campaign.room=="forge","leaving trial returns to Forge without campaign travel")
	w.queue_free();await frames()
	print("TRIAL_TESTS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
