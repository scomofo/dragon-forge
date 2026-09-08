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
func venom_owned()->Dictionary:
	var c=Rules.fresh();Rules.hatch(c)
	c.guardians=["fire","ice","storm","stone","venom"]
	c.ice_rescued=true;c.lattice_recovered=true;c.storm_forged=true
	c.stone_imprint_recovered=true;c.stone_forged=true
	c.venom_culture_recovered=true;c.venom_forged=true
	c.loadout=["fire","venom"]
	c.evolutions={"fire":"flashfire","ice":"aegis","storm":""}
	c.cleared=["outer-boss","frozen-boss","storm-boss"]
	c.cores=["outer","frozen","storm"];c.installed=c.cores.duplicate()
	c.visited.append_array(["field-locker","signal-approach","firewall-span","overflow-vent","cold-archive","mute-channel","thaw-junction","memory-vault","frozen-vault","overclock-gantry","live-wire","wire-fork","logic-core","capacitor-cache","mirror-vestibule","recursive-gate","cold-lanterns","admin-vault"])
	c.room="forge"
	return c
func run():
	var fresh=Rules.fresh()
	check(fresh.version==11,"fresh schema 11")
	check(not fresh.shadow_forged,"fresh Shadow flag false")
	var old=fresh.duplicate(true);old.version=7;old.erase("shadow_forged")
	var migrated=Rules.normalize(old)
	check(migrated.version==11,"schema 7 migrates")
	check(not migrated.shadow_forged,"migration grants no Shadow progress")
	var impossible=old.duplicate(true);impossible.guardians=["fire","ice","storm","stone","venom","shadow"]
	check(Rules.normalize(impossible).is_empty(),"schema 7 rejects impossible sixth guardian")
	var c=venom_owned()
	check(not Rules.normalize(c).is_empty(),"five-guardian source state valid under schema 11")
	check(Fusion.shadow_reason(c)=="","canonical Fire plus Venom recipe ready")
	var no_nox=c.duplicate(true);no_nox.guardians.erase("venom");no_nox.loadout=["fire","ice"]
	check(Fusion.shadow_reason(no_nox)!="","Shadow requires Nox")
	var unstabilized=c.duplicate(true);unstabilized.venom_forged=false
	check(Fusion.shadow_reason(unstabilized)!="","Shadow requires stabilized Venom")
	var pair=Fusion.members(c).duplicate()
	check(Fusion.forge_shadow(c),"forge Shadow resonance")
	check(not Fusion.forge_shadow(c),"Shadow resonance one-time")
	check(Fusion.hatch_shadow(c),"awaken Umbra")
	check(c.guardians==["fire","ice","storm","stone","venom","shadow"],"six owned guardians ordered")
	check(Fusion.members(c)==pair,"Shadow recruitment preserves two-slot expedition")
	check(not Fusion.hatch_shadow(c),"Umbra one-time")
	check(not Rules.normalize(c).is_empty(),"six-guardian schema valid")
	check(Fusion.equip_reserve(c,"shadow"),"Umbra can enter expedition")
	check(Fusion.members(c)==["fire","shadow"],"Shadow expedition remains two slots")
	var s=Combat.fresh("","shadow")
	check(Combat.guardian_name("shadow")=="UMBRA","guardian name")
	check(s.max_hp<Combat.fresh("","fire").max_hp,"Shadow health reflects glass-cannon browser identity")
	var names={"claw":"Shadow Strike","breath":"Void Pulse","wall":"Umbral Wake","burst":"Phase Strike"}
	for id in Combat.ORDER:
		check(Combat.rule(s,id).name==names[id],"Shadow move "+id)
		var t=Combat.fresh("","shadow")
		check(Combat.cast(t,id),"Shadow cast "+id)
		check(Combat.tick(t,Combat.rule(t,id).windup+.001)==id,"Shadow contact "+id)
	check(Combat.MAX_PHASE==2,"Phase cap two")
	var normal=Combat.fresh("","shadow");var hp=normal.hp
	check(Combat.damage(normal,20)>0 and normal.hp<hp and normal.phase==0,"ordinary landed damage grants no Phase")
	hp=normal.hp
	check(Combat.damage(normal,20)==0 and normal.hp==hp and normal.phase==0,"post-hit protection prevents damage without granting Phase")
	var dodge=Combat.fresh("","shadow")
	check(Combat.dodge(dodge),"Umbra begins dodge")
	check(dodge.phase==0,"pressing dodge alone grants no Phase")
	hp=dodge.hp;check(Combat.damage(dodge,20)==0 and dodge.hp==hp and dodge.phase==1,"real hit during dodge earns one Phase")
	check(Combat.damage(dodge,20)==0 and dodge.phase==2,"second avoided hit reaches Phase cap")
	check(Combat.damage(dodge,20)==0 and dodge.phase==2,"Phase remains capped")
	var tail=Combat.fresh("","shadow");Combat.dodge(tail);Combat.tick(tail,.20)
	check(tail.dash==0 and Combat.damage(tail,20)==0 and tail.phase==1,"dodge protection still earns Phase after dash movement ends")
	Combat.tick(tail,.05);hp=tail.hp
	check(Combat.damage(tail,20)>0 and tail.hp<hp and tail.phase==1,"expired dodge takes damage without granting Phase")
	check(Combat.damage(tail,20)==0 and tail.phase==1,"post-hit protection cannot reuse expired dodge credit")
	var invalid=Combat.fresh("","shadow");Combat.dodge(invalid);hp=invalid.hp
	for amount in [0.0,-1.0,NAN,INF]:
		check(Combat.damage(invalid,amount)==0 and invalid.hp==hp and invalid.phase==0,"invalid/non-damaging hit grants no Phase: " + str(amount))
	var base=Combat.fresh("","shadow");var one=Combat.fresh("","shadow");var two=Combat.fresh("","shadow");one.phase=1;two.phase=2
	check(is_equal_approx(Combat.technique_damage(base,"burst"),50.0),"Phase Strike base damage")
	check(is_equal_approx(Combat.technique_damage(one,"burst"),65.0),"one Phase adds thirty percent")
	check(is_equal_approx(Combat.technique_damage(two,"burst"),80.0),"two Phase adds sixty percent")
	check(Combat.consume_phase(two)==2 and two.phase==0,"landed Phase Strike helper spends stored Phase")
	check(not Combat.rule(base,"burst").has("ignore_shield"),"native Phase Strike does not bypass authoritative shields")
	print("SHADOW_TESTS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
