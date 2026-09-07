extends RefCounted
## Save-safe campaign rules; no scene side effects, RNG, or wall-clock dependencies.
const Data = preload("res://campaign/data.gd")
const Modules = preload("res://sim/forge_modules.gd")
const Growth = preload("res://campaign/growth.gd")
const UPGRADE_IDS = ["plating", "power", "cooling"]

static func fresh() -> Dictionary:
	return {"version": 3, "evolutions": {"fire": "", "ice": ""}, "guardians": ["fire"], "active_guardian": "fire", "ice_rescued": false, "hatched": false, "room": "forge", "visited": ["forge"], "cleared": [], "relays": [], "caches": [], "journals": [], "cores": [], "installed": [], "salvage": 0, "upgrades": {"plating": 0, "power": 0, "cooling": 0}, "module": "", "finished": false, "legacy_imported": false}

static func normalize(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var s: Dictionary = value.duplicate(true)
	if s.get("version", 0) == 1:
		s.version = 2
		s.guardians = ["fire"]
		s.active_guardian = "fire"
		s.ice_rescued = false
	if s.get("version", 0) == 2:
		s.version = 3
		s.evolutions = {"fire": "", "ice": ""}
	var template = fresh()
	for key in template:
		if not s.has(key):
			return {}
	for key in ["version", "salvage"]:
		if not _integer(s[key], 0, 1000000):
			return {}
		s[key] = int(s[key])
	if s.version != 3:
		return {}
	for key in ["hatched", "finished", "legacy_imported", "ice_rescued"]:
		if not s[key] is bool:
			return {}
	if not s.room is String or not Data.ROOMS.has(s.room) or not s.module is String or (s.module != "" and not Modules.valid(s.module)):
		return {}
	var zones = []
	for z in Data.ZONES:
		zones.append(z.id)
	var domains = {"visited": Data.ROOMS.keys(), "cleared": Data.encounter_ids(), "relays": Data.relay_ids(), "caches": [], "journals": Data.ROOMS.keys(), "cores": zones, "installed": zones}
	for r in Data.ROOMS.values():
		if r.role == "cache":
			domains.caches.append(r.id)
	for key in domains:
		if not s[key] is Array or s[key].size() > domains[key].size():
			return {}
		var seen = []
		for entry in s[key]:
			if not entry is String or not domains[key].has(entry) or seen.has(entry):
				return {}
			seen.append(entry)
	if not s.visited.has("forge") or not s.visited.has(s.room):
		return {}
	if not s.upgrades is Dictionary:
		return {}
	for key in UPGRADE_IDS:
		if not _integer(s.upgrades.get(key), 0, 3):
			return {}
		s.upgrades[key] = int(s.upgrades[key])
	for z in Data.ZONES:
		if s.cores.has(z.id) and not s.cleared.has(z.id + "-boss"):
			return {}
		if s.installed.has(z.id) and not s.cores.has(z.id):
			return {}
	for id in s.visited:
		if not Data.zone_unlocked(s, Data.ROOMS[id].zone):
			return {}
	if s.finished and (s.installed.size() != 4 or not s.cleared.has("singularity-final")):
		return {}
	if not s.hatched and (s.room != "forge" or not s.cleared.is_empty() or not s.cores.is_empty()):
		return {}
	if not s.guardians is Array or s.guardians.is_empty() or s.guardians.size() > 2 or s.guardians[0] != "fire":
		return {}
	if s.guardians.size() == 2 and s.guardians[1] != "ice":
		return {}
	if not s.active_guardian is String or not s.guardians.has(s.active_guardian):
		return {}
	if s.ice_rescued and (not s.hatched or not s.visited.has("frozen-vault")):
		return {}
	if s.guardians.has("ice") and not s.ice_rescued:
		return {}
	if not s.evolutions is Dictionary or s.evolutions.size() != 2:
		return {}
	for guardian in ["fire", "ice"]:
		var specialization: Variant = s.evolutions.get(guardian)
		if not specialization is String or (specialization != "" and not Growth.OPTIONS[guardian].has(specialization)):
			return {}
		if specialization != "" and Growth.reason(s, guardian) != "":
			return {}
	return s

static func _integer(v: Variant, lo: int, hi: int) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v) == floor(float(v)) and v >= lo and v <= hi

static func hatch(s: Dictionary) -> bool:
	if s.hatched:
		return false
	s.hatched = true
	s.salvage += 30
	return true

static func defeat(s: Dictionary, id: String) -> bool:
	if s.cleared.has(id):
		return false
	for r in Data.ROOMS.values():
		if r.id != s.room:
			continue
		for foe in r.enemies:
			if foe.id == id:
				s.cleared.append(id)
				s.salvage += foe.salvage
				return true
	return false

static func charge(s: Dictionary, id: String) -> bool:
	if s.relays.has(id):
		return false
	for relay in Data.ROOMS[s.room].relays:
		if relay.id == id:
			s.relays.append(id)
			return true
	return false

static func cache(s: Dictionary) -> bool:
	var r: Dictionary = Data.ROOMS[s.room]
	if r.role != "cache" or s.caches.has(r.id):
		return false
	s.caches.append(r.id)
	s.salvage += r.reward
	return true

static func collect_core(s: Dictionary) -> bool:
	var r: Dictionary = Data.ROOMS[s.room]
	if r.role != "boss" or not Data.room_cleared(s, r.id) or s.cores.has(r.zone):
		return false
	s.cores.append(r.zone)
	return true

static func install(s: Dictionary) -> int:
	if s.room != "forge":
		return 0
	var added = 0
	for id in s.cores:
		if not s.installed.has(id):
			s.installed.append(id)
			added += 1
	if added > 0 and s.module == "":
		s.module = "coolant"
	return added

static func travel(s: Dictionary, destination: String) -> bool:
	if not Data.ROOMS.has(destination) or not s.hatched:
		return false
	var allowed = false
	if s.room == "forge":
		for z in Data.ZONES:
			if z.entry == destination and Data.zone_unlocked(s, z.id):
				allowed = true
		if destination == "singularity" and Data.zone_unlocked(s, "final"):
			allowed = true
	else:
		for exit in Data.ROOMS[s.room].exits:
			if exit.to == destination and Data.exit_reason(s, s.room, exit) == "":
				allowed = true
	if not allowed:
		return false
	s.room = destination
	if not s.visited.has(destination):
		s.visited.append(destination)
	return true

static func return_home(s: Dictionary) -> void:
	s.room = "forge"

static func upgrade_cost(s: Dictionary, id: String) -> int:
	return 30 * (int(s.upgrades.get(id, 0)) + 1)

static func upgrade(s: Dictionary, id: String) -> bool:
	if s.room != "forge" or not s.hatched or not UPGRADE_IDS.has(id) or s.upgrades[id] >= 3 or s.salvage < upgrade_cost(s, id):
		return false
	s.salvage -= upgrade_cost(s, id)
	s.upgrades[id] += 1
	return true

static func finish(s: Dictionary) -> bool:
	if s.finished or s.room != "singularity" or s.installed.size() != 4 or not s.cleared.has("singularity-final"):
		return false
	s.finished = true
	return true

static func rescue_ice(s: Dictionary) -> bool:
	if not s.hatched or s.room != "frozen-vault" or s.ice_rescued:
		return false
	s.ice_rescued = true
	return true

static func hatch_ice(s: Dictionary) -> bool:
	if s.room != "forge" or not s.ice_rescued or s.guardians.has("ice"):
		return false
	s.guardians.append("ice")
	return true
