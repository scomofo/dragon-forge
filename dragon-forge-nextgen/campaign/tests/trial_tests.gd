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

func clean_record_file(store) -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(store.path+suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path+suffix))

func record_integrity_tests() -> void:
	var store=Store.new()
	store.path="user://trial-pair-integrity-%s.json" % str(Time.get_ticks_usec())
	var pairs=[]
	for active in Rules.GUARDIAN_IDS:
		pairs.append([active])
		for reserve in Rules.GUARDIAN_IDS:
			if reserve!=active:pairs.append([active,reserve])
	for pair in pairs:
		clean_record_file(store)
		var records=store.fresh()
		check(store.record(records,"outer-pressure",12000,27,pair),"trial clear writes for supported expedition "+str(pair))
		var loaded=store.read_records()
		check(loaded==records and store.message=="" and loaded.records.get("outer-pressure",{}).get("last_pair")==pair,"trial pair and first result survive reload "+str(pair))
		check(store.record(loaded,"outer-pressure",14000,12,pair),"slower clear with less damage persists "+str(pair))
		var result=store.read_records().records.get("outer-pressure",{})
		check(result.get("best_ms")==12000 and result.get("best_damage")==12 and result.get("clears")==2,"time and damage bests improve independently after reload "+str(pair))
		check(store.record(loaded,"outer-pressure",11000,0,pair),"perfect clear persists "+str(pair))
		check(store.record(loaded,"outer-pressure",16000,50,pair),"later damaged clear persists "+str(pair))
		result=store.read_records().records.get("outer-pressure",{})
		check(result.get("best_ms")==11000 and result.get("best_damage")==0 and result.get("clears")==4 and result.get("last_pair")==pair,"perfect damage best is retained after later damaged clear and reload "+str(pair))
	check(Store.VERSION==1,"guardian domain extension retains trial schema 1")
	var records=store.read_records()
	var before=records.duplicate(true)
	var bytes=FileAccess.get_file_as_string(store.path)
	for pair in [[],["unknown"],["fire","fire"],["fire",42],["fire","ice","storm"]]:
		check(not store.record(records,"outer-pressure",1000,0,pair) and records==before,"invalid new pair cannot mutate records: "+str(pair))
		check(FileAccess.get_file_as_string(store.path)==bytes,"invalid pair leaves saved record bytes intact: "+str(pair))
	for pair in [["unknown"],["fire","fire"],["fire",42],["fire","ice","storm"],"fire"]:
		var bad=before.duplicate(true)
		bad.records["outer-pressure"].last_pair=pair
		check(store.normalize(bad).is_empty() and not store.write_records(bad),"malformed stored pair rejected: "+str(pair))
	check(FileAccess.get_file_as_string(store.path)==bytes,"malformed stored pairs cannot overwrite the valid file")
	for key in ["clears","best_ms","best_damage"]:
		for value in [-1,.5,NAN,INF,-INF,"12",true]:
			var bad=before.duplicate(true)
			bad.records["outer-pressure"][key]=value
			check(store.normalize(bad).is_empty(),"malformed trial metric rejected: "+key+" / "+str(value))
	var missing_pair=before.duplicate(true)
	missing_pair.records["outer-pressure"].erase("last_pair")
	check(store.normalize(missing_pair).is_empty(),"missing trial pair is rejected without invalid field access")
	var legacy=store.fresh()
	legacy.records["outer-pressure"]={"clears":0,"best_ms":0,"best_damage":0,"last_pair":[]}
	check(store.write_records(legacy) and store.read_records()==legacy,"schema 1 empty historical pair remains readable and writable")
	check(store.record(legacy,"outer-pressure",9000,30,["fire"]),"first clear replaces empty historical bests")
	var first=store.read_records().records.get("outer-pressure",{})
	check(first.get("best_ms")==9000 and first.get("best_damage")==30 and first.get("clears")==1,"first-clear detection uses count instead of zero damage")
	clean_record_file(store)

func run():
	record_integrity_tests()
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
