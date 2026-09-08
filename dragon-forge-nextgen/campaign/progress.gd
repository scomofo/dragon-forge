extends RefCounted
## Save-safe campaign rules; no scene side effects, RNG, or wall-clock dependencies.
const Data = preload("res://campaign/data.gd")
const Modules = preload("res://sim/forge_modules.gd")
const Growth = preload("res://campaign/growth.gd")
const Fusion = preload("res://campaign/fusion.gd")
const SAVE_VERSION = 11
const UPGRADE_IDS = ["plating", "power", "cooling"]
const GUARDIAN_IDS = ["fire", "ice", "storm", "stone", "venom", "shadow", "void", "light", "synthesis"]

static func fresh() -> Dictionary:
	return {"version":SAVE_VERSION, "synthesis_forged":false, "void_imprint_recovered":false, "void_forged":false, "lattice_recovered":false, "storm_forged":false, "stone_imprint_recovered":false, "stone_forged":false, "venom_culture_recovered":false, "venom_forged":false, "shadow_forged":false, "loadout":[], "evolutions":{"fire":"","ice":"","storm":""}, "guardians":["fire"], "active_guardian":"fire", "ice_rescued":false, "hatched":false, "room":"forge", "visited":["forge"], "cleared":[], "relays":[], "caches":[], "journals":[], "cores":[], "installed":[], "salvage":0, "upgrades":{"plating":0,"power":0,"cooling":0}, "module":"", "finished":false, "legacy_imported":false}

static func normalize(value: Variant) -> Dictionary:
	if not value is Dictionary: return {}
	var s: Dictionary = value.duplicate(true)
	var migrate_light = false
	# Schema 10 cannot carry its schema-11-only flag. Reject it before the
	# migration default could erase malformed source state.
	if s.get("version",0)==10 and s.has("synthesis_forged"):return {}
	if _integer(s.get("version",0),1,10) and s.get("guardians",[]) is Array and s.get("guardians",[]).has("synthesis"):return {}
	if s.get("version",0)==1 and (s.has("guardians") or s.has("active_guardian") or s.has("ice_rescued")):return {}
	if s.get("version",0) in [2,3] and not _valid_guardians(s.get("guardians"),2):return {}
	if s.get("version",0)==1:
		s.version=2;s.guardians=["fire"];s.active_guardian="fire";s.ice_rescued=false
	if s.get("version",0)==2:
		s.version=3;s.evolutions={"fire":"","ice":""}
	if s.get("version",0)==3:
		s.version=4;s.lattice_recovered=false;s.storm_forged=false;s.loadout=[]
	if s.get("version",0)==4:
		if not _valid_guardians(s.get("guardians"),3) or not s.get("evolutions") is Dictionary or s.evolutions.size()!=2 or not s.evolutions.has("fire") or not s.evolutions.has("ice"): return {}
		s.version=5;s.evolutions.storm=""
	if s.get("version",0)==5:
		if not _valid_guardians(s.get("guardians"),3) or not s.get("evolutions") is Dictionary or s.evolutions.size()!=3: return {}
		s.version=6;s.stone_imprint_recovered=false;s.stone_forged=false
	if s.get("version",0)==6:
		# Validate the critical v6 roster shape before extending it. Migration itself never writes.
		if not _valid_guardians(s.get("guardians"),4) or not s.get("evolutions") is Dictionary or s.evolutions.size()!=3:return {}
		s.version=7;s.venom_culture_recovered=false;s.venom_forged=false
	if s.get("version",0)==7:
		# Shadow is direct Fire + Venom resonance; migration never grants that earned result.
		if not _valid_guardians(s.get("guardians"),5) or not s.get("evolutions") is Dictionary or s.evolutions.size()!=3:return {}
		if not s.has("venom_culture_recovered") or not s.venom_culture_recovered is bool or not s.has("venom_forged") or not s.venom_forged is bool:return {}
		s.version=8;s.shadow_forged=false
	if s.get("version",0)==8:
		if not _valid_guardians(s.get("guardians"),6) or not s.get("shadow_forged") is bool:return {}
		s.version=9;s.void_imprint_recovered=false;s.void_forged=false
	if s.get("version",0)==9:
		# Reject future ownership now; grant the earned completion reward only after
		# every old progression, loadout and active-guardian constraint has passed.
		if not _valid_guardians(s.get("guardians"),7):return {}
		s.version=10;migrate_light=true
	if s.get("version",0)==10:
		if not _valid_guardians(s.get("guardians"),8):return {}
		s.version=11;s.synthesis_forged=false
	var template=fresh()
	for key in template:
		if not s.has(key): return {}
	for key in ["version","salvage"]:
		if not _integer(s[key],0,1000000): return {}
		s[key]=int(s[key])
	if s.version!=SAVE_VERSION:return {}
	for key in ["hatched","finished","legacy_imported","ice_rescued","lattice_recovered","storm_forged","stone_imprint_recovered","stone_forged","venom_culture_recovered","venom_forged","shadow_forged","void_imprint_recovered","void_forged","synthesis_forged"]:
		if not s[key] is bool:return {}
	if not s.room is String or not Data.ROOMS.has(s.room) or not s.module is String or (s.module!="" and not Modules.valid(s.module)):return {}
	var zones=[]
	for z in Data.ZONES:zones.append(z.id)
	var domains={"visited":Data.ROOMS.keys(),"cleared":Data.encounter_ids(),"relays":Data.relay_ids(),"caches":[],"journals":Data.ROOMS.keys(),"cores":zones,"installed":zones}
	for r in Data.ROOMS.values():
		if r.role=="cache":domains.caches.append(r.id)
	for key in domains:
		if not s[key] is Array or s[key].size()>domains[key].size():return {}
		var seen=[]
		for entry in s[key]:
			if not entry is String or not domains[key].has(entry) or seen.has(entry):return {}
			seen.append(entry)
	if not s.visited.has("forge") or not s.visited.has(s.room):return {}
	if not s.upgrades is Dictionary:return {}
	for key in UPGRADE_IDS:
		if not _integer(s.upgrades.get(key),0,3):return {}
		s.upgrades[key]=int(s.upgrades[key])
	for z in Data.ZONES:
		if s.cores.has(z.id) and not s.cleared.has(z.id+"-boss"):return {}
		if s.installed.has(z.id) and not s.cores.has(z.id):return {}
	for id in s.visited:
		if not Data.zone_unlocked(s,Data.ROOMS[id].zone):return {}
	if s.finished and (s.installed.size()!=4 or not s.cleared.has("singularity-final")):return {}
	if not s.hatched and (s.room!="forge" or not s.cleared.is_empty() or not s.cores.is_empty()):return {}
	# Ownership is a set. Optional recipes do not impose a recruitment order.
	# Keep the stored order for presentation; each guardian still needs earned flags below.
	if not _valid_guardians(s.guardians,GUARDIAN_IDS.size()):return {}
	if not s.active_guardian is String or not s.guardians.has(s.active_guardian):return {}
	if s.ice_rescued and (not s.hatched or not s.visited.has("frozen-vault")):return {}
	if s.guardians.has("ice") and not s.ice_rescued:return {}
	if not s.evolutions is Dictionary or s.evolutions.size()!=3:return {}
	for guardian in ["fire","ice","storm"]:
		var specialization=s.evolutions.get(guardian)
		if not specialization is String or (specialization!="" and not Growth.OPTIONS[guardian].has(specialization)):return {}
		if specialization!="" and Growth.reason(s,guardian)!="":return {}
	if s.lattice_recovered and (not s.hatched or not s.visited.has("capacitor-cache")):return {}
	if s.storm_forged and Fusion.reason(s)!="":return {}
	if s.guardians.has("storm") and not s.storm_forged:return {}
	if s.stone_imprint_recovered and (not s.hatched or not s.visited.has("admin-vault")):return {}
	if s.stone_forged and Fusion.stone_reason(s)!="":return {}
	if s.guardians.has("stone") and not s.stone_forged:return {}
	if s.venom_culture_recovered and (not s.hatched or not s.visited.has("frozen-vault")):return {}
	if s.venom_forged and Fusion.venom_reason(s)!="":return {}
	if s.guardians.has("venom") and not s.venom_forged:return {}
	if s.shadow_forged and Fusion.shadow_reason(s)!="":return {}
	if s.guardians.has("shadow") and not s.shadow_forged:return {}
	if s.void_imprint_recovered and (not s.finished or not s.visited.has("singularity")):return {}
	if s.void_forged and Fusion.void_reason(s)!="":return {}
	if s.guardians.has("void") and not s.void_forged:return {}
	if s.guardians.has("light") and not s.finished:return {}
	if s.synthesis_forged and Fusion.synthesis_reason(s)!="":return {}
	if s.guardians.has("synthesis") and not s.synthesis_forged:return {}
	if not s.loadout is Array:return {}
	if s.loadout.is_empty():
		if s.guardians.size()>2:return {}
	elif s.loadout.size()!=2 or s.loadout[0]==s.loadout[1]:return {}
	for guardian in s.loadout:
		if not guardian is String or not s.guardians.has(guardian):return {}
	if not Fusion.members(s).has(s.active_guardian):return {}
	if s.finished:
		if migrate_light:_grant_light(s)
		elif not s.guardians.has("light"):return {}
	return s

static func _grant_light(s: Dictionary) -> void:
	# Browser canon grants Light for Singularity completion, including old finishers.
	# Materialize an implicit existing pair before adding a third owned guardian.
	if s.guardians.has("light"):return
	if s.guardians.size()>=2:s.loadout=Fusion.members(s)
	s.guardians.append("light")

static func _valid_guardians(value: Variant, limit: int) -> bool:
	if not value is Array or value.is_empty() or value.size()>limit or not value.has("fire"):return false
	var allowed=GUARDIAN_IDS.slice(0,limit)
	var seen=[]
	for guardian in value:
		if not guardian is String or not allowed.has(guardian) or seen.has(guardian):return false
		seen.append(guardian)
	return true

static func _integer(v: Variant,lo:int,hi:int)->bool:return (v is int or v is float) and is_finite(float(v)) and float(v)==floor(float(v)) and v>=lo and v<=hi
static func hatch(s:Dictionary)->bool:
	if s.hatched:return false
	s.hatched=true;s.salvage+=30;return true
static func defeat(s:Dictionary,id:String)->bool:
	if s.cleared.has(id):return false
	for r in Data.ROOMS.values():
		if r.id!=s.room:continue
		for foe in r.enemies:
			if foe.id==id:s.cleared.append(id);s.salvage+=foe.salvage;return true
	return false
static func charge(s:Dictionary,id:String)->bool:
	if s.relays.has(id):return false
	for relay in Data.ROOMS[s.room].relays:
		if relay.id==id:s.relays.append(id);return true
	return false
static func cache(s:Dictionary)->bool:
	var r=Data.ROOMS[s.room]
	if r.role!="cache" or s.caches.has(r.id):return false
	s.caches.append(r.id);s.salvage+=r.reward;return true
static func collect_core(s:Dictionary)->bool:
	var r=Data.ROOMS[s.room]
	if r.role!="boss" or not Data.room_cleared(s,r.id) or s.cores.has(r.zone):return false
	s.cores.append(r.zone);return true
static func install(s:Dictionary)->int:
	if s.room!="forge":return 0
	var added=0
	for id in s.cores:
		if not s.installed.has(id):s.installed.append(id);added+=1
	if added>0 and s.module=="":s.module="coolant"
	return added
static func travel(s:Dictionary,destination:String)->bool:
	if not Data.ROOMS.has(destination) or not s.hatched:return false
	var allowed=false
	if s.room=="forge":
		for z in Data.ZONES:
			if z.entry==destination and Data.zone_unlocked(s,z.id):allowed=true
		if destination=="singularity" and Data.zone_unlocked(s,"final"):allowed=true
	else:
		for exit in Data.ROOMS[s.room].exits:
			if exit.to==destination and Data.exit_reason(s,s.room,exit)=="":allowed=true
	if not allowed:return false
	s.room=destination
	if not s.visited.has(destination):s.visited.append(destination)
	return true
static func return_home(s:Dictionary)->void:s.room="forge"
static func upgrade_cost(s:Dictionary,id:String)->int:return 30*(int(s.upgrades.get(id,0))+1)
static func upgrade(s:Dictionary,id:String)->bool:
	if s.room!="forge" or not s.hatched or not UPGRADE_IDS.has(id) or s.upgrades[id]>=3 or s.salvage<upgrade_cost(s,id):return false
	s.salvage-=upgrade_cost(s,id);s.upgrades[id]+=1;return true
static func finish(s:Dictionary)->bool:
	if s.finished or s.room!="singularity" or s.installed.size()!=4 or not s.cleared.has("singularity-final"):return false
	s.finished=true;_grant_light(s);return true
static func rescue_ice(s:Dictionary)->bool:
	if not s.hatched or s.room!="frozen-vault" or s.ice_rescued:return false
	s.ice_rescued=true;return true
static func hatch_ice(s:Dictionary)->bool:
	if s.room!="forge" or not s.ice_rescued or s.guardians.has("ice"):return false
	# Cairn may already be the first reserve. Preserve that pair when Rime joins later.
	if s.guardians.size()>=2:s.loadout=Fusion.members(s)
	s.guardians.append("ice");return true
