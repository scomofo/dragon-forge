extends RefCounted
## Save-neutral Forge challenge definitions. Campaign rewards/progression never mutate here.
const Data = preload("res://campaign/data.gd")

const ROOM = {
	"id":"forge-trial", "name":"Forge Trial Chamber", "zone":"home", "role":"trial", "layout":"trial",
	"exits":[], "enemies":[], "relays":[], "hazards":[], "lore":"", "lore_title":"", "spawn":[0,0.1,8]
}

const DATA = {
	"outer-pressure": {"name":"Pressure Test", "detail":"Bruiser pressure into a shielded Bulwark pair.", "requires":"outer-boss", "waves":[
		[{"id":"trial-outer-bruiser-a","name":"Pressure Sentinel","at":[0,0.1,-8],"hp":90,"damage":17,"boss":false,"shield":false,"patterns":["slam"],"archetype":"bruiser","salvage":0}],
		[{"id":"trial-outer-bruiser-b","name":"Pressure Sentinel","at":[-4,0.1,-10],"hp":95,"damage":18,"boss":false,"shield":false,"patterns":["slam"],"archetype":"bruiser","salvage":0},{"id":"trial-outer-bulwark","name":"Bulwark Sentinel","at":[4,0.1,-12],"hp":135,"damage":21,"boss":false,"shield":true,"patterns":["slam"],"archetype":"bulwark","salvage":0}]
	]},
	"frozen-crossfire": {"name":"Cold Crossfire", "detail":"Long-range beam pressure backed by a shielded archive guard.", "requires":"frozen-boss", "waves":[
		[{"id":"trial-frozen-sniper-a","name":"Archive Marksman","at":[0,0.1,-12],"hp":100,"damage":19,"boss":false,"shield":false,"patterns":["beam"],"archetype":"sniper","salvage":0}],
		[{"id":"trial-frozen-sniper-b","name":"Archive Marksman","at":[-5,0.1,-12],"hp":105,"damage":20,"boss":false,"shield":false,"patterns":["beam"],"archetype":"sniper","salvage":0},{"id":"trial-frozen-bulwark","name":"Thaw Bulwark","at":[5,0.1,-9],"hp":145,"damage":22,"boss":false,"shield":true,"patterns":["slam","beam"],"archetype":"bulwark","salvage":0}]
	]},
	"storm-overclock": {"name":"Overclock Drill", "detail":"Fast skirmishers circle and alternate fan lanes.", "requires":"storm-boss", "waves":[
		[{"id":"trial-storm-skirmisher-a","name":"Surge Skirmisher","at":[0,0.1,-9],"hp":105,"damage":19,"boss":false,"shield":false,"patterns":["fan"],"archetype":"skirmisher","salvage":0}],
		[{"id":"trial-storm-skirmisher-b","name":"Surge Skirmisher","at":[-5,0.1,-11],"hp":110,"damage":20,"boss":false,"shield":false,"patterns":["fan","slam"],"archetype":"skirmisher","salvage":0},{"id":"trial-storm-skirmisher-c","name":"Fork Skirmisher","at":[5,0.1,-11],"hp":120,"damage":21,"boss":false,"shield":true,"patterns":["fan"],"archetype":"skirmisher","salvage":0}]
	]},
	"admin-control": {"name":"Protocol Control", "detail":"Controllers hold dangerous ring distance while a sniper punishes straight retreats.", "requires":"admin-boss", "waves":[
		[{"id":"trial-admin-controller-a","name":"Protocol Controller","at":[0,0.1,-8],"hp":115,"damage":20,"boss":false,"shield":false,"patterns":["ring"],"archetype":"controller","salvage":0}],
		[{"id":"trial-admin-controller-b","name":"Protocol Controller","at":[-4,0.1,-9],"hp":125,"damage":22,"boss":false,"shield":true,"patterns":["ring","beam"],"archetype":"controller","salvage":0},{"id":"trial-admin-sniper","name":"Protocol Marksman","at":[5,0.1,-13],"hp":110,"damage":21,"boss":false,"shield":false,"patterns":["beam"],"archetype":"sniper","salvage":0}]
	]},
	"echo-outer": {"name":"Boss Echo / Buffer Overflow", "detail":"Replay the Outer Grid boss with no duplicate salvage or bond.", "requires":"outer-boss", "boss_room":"overflow-vent"},
	"echo-frozen": {"name":"Boss Echo / Memory Leak", "detail":"Replay the Frozen Cache boss with your current expedition pair.", "requires":"frozen-boss", "boss_room":"memory-vault"},
	"echo-storm": {"name":"Boss Echo / Stack Overflow", "detail":"Replay the Storm Spine boss without changing campaign clears.", "requires":"storm-boss", "boss_room":"logic-core"},
	"echo-admin": {"name":"Boss Echo / Mirror Admin", "detail":"Replay the Admin Core boss without changing campaign clears.", "requires":"admin-boss", "boss_room":"protocol-throne"},
	"echo-singularity": {"name":"Boss Echo / Singularity", "detail":"Replay the final reset cycle after completing Reconnection.", "requires":"singularity-final", "boss_room":"singularity"},
}

static func ids() -> Array:
	return DATA.keys()

static func entry(id: String) -> Dictionary:
	return DATA.get(id, {})

static func unlocked(campaign: Dictionary, id: String) -> bool:
	return DATA.has(id) and campaign.get("cleared", []).has(DATA[id].requires)

static func available(campaign: Dictionary) -> Array:
	var result: Array = []
	for id in DATA:
		if unlocked(campaign,id): result.append(id)
	return result

static func waves(id: String) -> Array:
	if not DATA.has(id): return []
	var info: Dictionary = DATA[id]
	if info.has("waves"): return info.waves.duplicate(true)
	var room_id: String = info.get("boss_room", "")
	if room_id == "" or not Data.ROOMS.has(room_id): return []
	var wave: Array = []
	for source in Data.ROOMS[room_id].enemies:
		var spec: Dictionary = source.duplicate(true)
		spec.salvage = 0
		wave.append(spec)
	return [wave]
