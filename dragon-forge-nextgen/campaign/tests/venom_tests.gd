extends SceneTree
const Rules=preload("res://campaign/progress.gd")
const Fusion=preload("res://campaign/fusion.gd")
const Combat=preload("res://campaign/guardian_combat.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1
	print(("PASS " if ok else "FAIL ")+label)
func eligible()->Dictionary:
	var c=Rules.fresh();Rules.hatch(c)
	c.guardians=["fire","ice","storm","stone"];c.ice_rescued=true;c.lattice_recovered=true;c.storm_forged=true;c.stone_imprint_recovered=true;c.stone_forged=true;c.loadout=["fire","stone"];c.evolutions={"fire":"flashfire","ice":"aegis","storm":""}
	c.cleared=["outer-boss","frozen-boss","storm-boss"]
	c.cores=["outer","frozen","storm"];c.installed=c.cores.duplicate()
	c.visited.append_array(["field-locker","signal-approach","firewall-span","overflow-vent","cold-archive","mute-channel","thaw-junction","memory-vault","frozen-vault","overclock-gantry","live-wire","wire-fork","logic-core","capacitor-cache","mirror-vestibule","recursive-gate","cold-lanterns","admin-vault"])
	c.room="frozen-vault"
	return c
func run():
	var fresh=Rules.fresh();check(fresh.version==11,"fresh schema 11");check(not fresh.venom_culture_recovered and not fresh.venom_forged,"fresh Venom flags false")
	var old=fresh.duplicate(true);old.version=6;old.erase("venom_culture_recovered");old.erase("venom_forged")
	var migrated=Rules.normalize(old);check(migrated.version==11,"schema 6 migrates through schema 11");check(not migrated.venom_culture_recovered and not migrated.venom_forged,"migration grants no Venom progress")
	var bad=old.duplicate(true);bad.guardians=["fire","ice","storm","stone","venom"];check(Rules.normalize(bad).is_empty(),"schema 6 rejects impossible fifth guardian")
	var c=eligible();check(Fusion.recover_venom(c),"recover Venom culture in Frozen Vault");check(not Fusion.recover_venom(c),"culture one-time");check(Fusion.venom_reason(c)=="","eligible Venom recipe ready")
	c.room="forge";check(Fusion.forge_venom(c),"stabilize culture with Rime");check(not Fusion.forge_venom(c),"stabilize one-time");var pair=Fusion.members(c).duplicate();check(Fusion.hatch_venom(c),"awaken Nox");check(c.guardians==["fire","ice","storm","stone","venom"],"five owned guardians ordered");check(Fusion.members(c)==pair,"recruitment preserves expedition pair");check(not Fusion.hatch_venom(c),"Nox one-time")
	check(not Rules.normalize(c).is_empty(),"five-guardian schema valid");check(Fusion.equip_reserve(c,"venom"),"Nox can enter two-slot expedition");check(Fusion.members(c)==["fire","venom"],"Venom pair remains two slots")
	var s=Combat.fresh("","venom");check(Combat.guardian_name("venom")=="NOX","guardian name");check(s.max_hp<Combat.fresh("","fire").max_hp,"Venom base health lower than Magma")
	var names={"claw":"Toxin Fang","breath":"Acid Spit","wall":"Toxic Cloud","burst":"Septic Bloom"}
	for id in Combat.ORDER:
		check(Combat.rule(s,id).name==names[id],"Venom move "+id)
		var t=Combat.fresh("","venom");check(Combat.cast(t,id),"Venom cast "+id);check(Combat.tick(t,Combat.rule(t,id).windup+.001)==id,"Venom contact "+id)
	check(Combat.MAX_TOXIN==3,"Toxin cap three");check(Combat.toxin_stacks(-2)==0 and Combat.toxin_stacks(5)==3,"Toxin clamps safely")
	check(is_equal_approx(Combat.toxin_duration(),5.0),"Toxin duration five seconds");check(is_equal_approx(Combat.toxin_tick_damage(),4.0),"Toxin tick baseline four")
	check(is_equal_approx(Combat.toxin_burst_multiplier(0),1.0),"Bloom no-stack multiplier neutral");check(is_equal_approx(Combat.toxin_burst_multiplier(1),1.25),"Bloom one-stack bonus");check(is_equal_approx(Combat.toxin_burst_multiplier(3),1.75),"Bloom three-stack bonus");check(is_equal_approx(Combat.toxin_burst_multiplier(99),1.75),"Bloom bonus capped")
	var before=Combat.technique_damage(s,"burst");check(before==46.0,"Bloom base damage contract");check(Combat.rule(s,"breath").heat==18.0 and Combat.rule(s,"wall").heat==28.0,"Venom heat profile")
	print("VENOM_TESTS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
