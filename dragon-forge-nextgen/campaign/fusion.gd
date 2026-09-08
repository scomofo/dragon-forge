extends RefCounted
## Bounded native resonance recipes. Parents/guardian progress are retained.
## No RNG, currency deduction, scene access, or wall-clock access.
const Growth = preload("res://campaign/growth.gd")
const STATION = Vector3(-7, 0, 8)
const LATTICE = Vector3(6, 0, -4)
const STONE_IMPRINT = Vector3(6, 0, -4)
const VENOM_CULTURE = Vector3(-5, 0, -4)
const VOID_IMPRINT = Vector3(-5, 0, -4)

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

static func stone_reason(c: Dictionary) -> String:
	if not c.get("hatched", false):
		return "Awaken Magma first."
	if not c.get("stone_imprint_recovered", false):
		return "Recover the Stone imprint in Admin Core's vault."
	if not c.get("guardians", []).has("fire"):
		return "Magma is required to temper the Stone imprint."
	if c.get("installed", []).size() < 3:
		return "Restore three sector cores before tempering the imprint."
	return ""

static func venom_reason(c: Dictionary) -> String:
	if not c.get("hatched", false):
		return "Awaken Magma first."
	if not c.get("venom_culture_recovered", false):
		return "Recover the preserved Venom culture in Frozen Vault."
	if not c.get("guardians", []).has("ice"):
		return "Rime is required to stabilize the Venom culture."
	if c.get("installed", []).size() < 3:
		return "Restore three sector cores before stabilizing the culture."
	return ""

static func shadow_reason(c: Dictionary) -> String:
	# Canonical browser alchemy: Fire + Venom = Shadow. No catalyst or currency.
	if not c.get("hatched", false):
		return "Awaken Magma first."
	if not c.get("guardians", []).has("fire"):
		return "Magma is required for Shadow resonance."
	if not c.get("guardians", []).has("venom"):
		return "Awaken Nox before attempting Shadow resonance."
	if not c.get("venom_forged", false):
		return "Stabilize the Venom culture before Shadow resonance."
	return ""

static func recover(c: Dictionary) -> bool:
	if c.get("room", "") != "capacitor-cache" or c.get("lattice_recovered", false) or not c.get("hatched", false):
		return false
	c.lattice_recovered = true
	return true

static func recover_stone(c: Dictionary) -> bool:
	if c.get("room", "") != "admin-vault" or c.get("stone_imprint_recovered", false) or not c.get("hatched", false):
		return false
	c.stone_imprint_recovered = true
	return true

static func recover_venom(c: Dictionary) -> bool:
	if c.get("room", "") != "frozen-vault" or c.get("venom_culture_recovered", false) or not c.get("hatched", false):
		return false
	c.venom_culture_recovered = true
	return true

static func forge(c: Dictionary) -> bool:
	if c.get("room", "") != "forge" or reason(c) != "" or c.get("storm_forged", false):
		return false
	c.storm_forged = true
	return true

static func forge_stone(c: Dictionary) -> bool:
	if c.get("room", "") != "forge" or stone_reason(c) != "" or c.get("stone_forged", false):
		return false
	c.stone_forged = true
	return true

static func forge_venom(c: Dictionary) -> bool:
	if c.get("room", "") != "forge" or venom_reason(c) != "" or c.get("venom_forged", false):
		return false
	c.venom_forged = true
	return true

static func forge_shadow(c: Dictionary) -> bool:
	if c.get("room", "") != "forge" or shadow_reason(c) != "" or c.get("shadow_forged", false):
		return false
	c.shadow_forged = true
	return true

static func hatch(c: Dictionary) -> bool:
	if c.get("room", "") != "forge" or reason(c) != "" or not c.get("storm_forged", false) or c.guardians.has("storm"):
		return false
	c.loadout = members(c)
	c.guardians.append("storm")
	return true

static func hatch_stone(c: Dictionary) -> bool:
	if c.get("room", "") != "forge" or stone_reason(c) != "" or not c.get("stone_forged", false) or c.guardians.has("stone"):
		return false
	# Cairn can be the first reserve; an empty pair then follows the two owned guardians.
	c.loadout = members(c) if c.guardians.size()>=2 else []
	c.guardians.append("stone")
	return true

static func hatch_venom(c: Dictionary) -> bool:
	if c.get("room", "") != "forge" or venom_reason(c) != "" or not c.get("venom_forged", false) or c.guardians.has("venom"):
		return false
	c.loadout = members(c)
	c.guardians.append("venom")
	return true

static func hatch_shadow(c: Dictionary) -> bool:
	if c.get("room", "") != "forge" or shadow_reason(c) != "" or not c.get("shadow_forged", false) or c.guardians.has("shadow"):
		return false
	c.loadout = members(c)
	c.guardians.append("shadow")
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

static func void_reason(c: Dictionary) -> String:
	if not c.get("hatched",false):return "Awaken Magma first."
	if not c.get("finished",false):return "Stabilize the Singularity before awakening Void."
	if not c.get("void_imprint_recovered",false):return "Recover the Void imprint from the stabilized Singularity chamber."
	return ""

static func recover_void(c: Dictionary) -> bool:
	if c.get("room","")!="singularity" or not c.get("finished",false) or c.get("void_imprint_recovered",false):return false
	c.void_imprint_recovered=true
	return true

static func forge_void(c: Dictionary) -> bool:
	if c.get("room","")!="forge" or void_reason(c)!="" or c.get("void_forged",false):return false
	c.void_forged=true
	return true

static func hatch_void(c: Dictionary) -> bool:
	if c.get("room","")!="forge" or void_reason(c)!="" or not c.get("void_forged",false) or c.guardians.has("void"):return false
	c.loadout=members(c) if c.guardians.size()>=2 else []
	c.guardians.append("void")
	return true

static func synthesis_reason(c: Dictionary) -> String:
	# Canonical browser alchemy: Light + Void = Synthesis; parents are retained.
	if not c.get("hatched",false):return "Awaken Magma first."
	if not c.get("finished",false):return "Stabilize the Singularity to earn Light."
	if not c.get("guardians",[]).has("light"):return "Earn Lumen through Singularity stabilization first."
	if not c.get("guardians",[]).has("void"):return "Awaken Null before attempting Synthesis resonance."
	if not c.get("void_forged",false):return "Forge the preserved Void imprint before Synthesis resonance."
	if not c.get("void_imprint_recovered",false):return "Recover the Void imprint from the stabilized Singularity chamber."
	return ""

static func forge_synthesis(c: Dictionary) -> bool:
	if c.get("room","")!="forge" or synthesis_reason(c)!="" or c.get("synthesis_forged",false):return false
	c.synthesis_forged=true
	return true

static func hatch_synthesis(c: Dictionary) -> bool:
	if c.get("room","")!="forge" or synthesis_reason(c)!="" or not c.get("synthesis_forged",false) or c.guardians.has("synthesis"):return false
	c.loadout=members(c)
	c.guardians.append("synthesis")
	return true
