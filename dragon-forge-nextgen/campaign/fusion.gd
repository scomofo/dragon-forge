extends RefCounted
## Bounded first native recipe: canonical Fire + Ice = Storm; parents are retained.
## No RNG, currency deduction, scene access, or clock access.
const Growth = preload("res://campaign/growth.gd")
const STATION = Vector3(-7, 0, 8)
const LATTICE = Vector3(6, 0, -4)

static func reason(c: Dictionary) -> String:
	if not c.get("hatched", false) or not c.get("guardians", []).has("ice"):
		return "Awaken Magma and rescue/hatch Rime first."
	if Growth.choice(c, "fire") == "" or Growth.choice(c, "ice") == "":
		return "Evolve both Magma and Rime at the Guardian Nursery."
	if c.get("installed", []).size() < 2:
		return "Install the Outer Grid and Frozen Cache cores."
	if not c.get("lattice_recovered", false):
		return "Recover the conductor lattice in Storm Spine's Capacitor Cache."
	return ""

static func recover(c: Dictionary) -> bool:
	if c.get("room", "") != "capacitor-cache" or c.get("lattice_recovered", false) or not c.get("hatched", false):
		return false
	c.lattice_recovered = true
	return true

static func forge(c: Dictionary) -> bool:
	if c.get("room", "") != "forge" or reason(c) != "" or c.get("storm_forged", false):
		return false
	c.storm_forged = true
	return true

static func hatch(c: Dictionary) -> bool:
	if c.get("room", "") != "forge" or reason(c) != "" or not c.get("storm_forged", false) or c.guardians.has("storm"):
		return false
	# Explicitly retain the parents, their evolutions, active guardian and current pair.
	c.loadout = members(c)
	c.guardians.append("storm")
	return true

static func members(c: Dictionary) -> Array:
	var selected: Array = c.get("loadout", [])
	return selected.duplicate() if not selected.is_empty() else c.get("guardians", ["fire"]).slice(0, 2)

static func equip_reserve(c: Dictionary, guardian: String) -> bool:
	if c.get("room", "") != "forge" or not c.guardians.has(guardian) or guardian == c.active_guardian:
		return false
	var pair: Array = [c.active_guardian, guardian]
	if members(c).has(guardian):
		return false
	c.loadout = pair
	return true
