extends RefCounted
## Bond is derived from unique, saved campaign milestones: no XP farming or lost reserve XP.
const Data = preload("res://campaign/data.gd")
const RANKS = [0, 120, 280]
const OPTIONS = {
	"fire": ["flashfire", "furnace"],
	"ice": ["deepwinter", "aegis"],
	"storm": ["thunderhead", "overcharge"],
}
const TRAITS = {
	"thunderhead": {"name":"Thunderhead", "detail":"Arc Lance and Static Well apply 6 seconds of Charge instead of 4. More time to land the finishing Discharge."},
	"overcharge": {"name":"Overcharge", "detail":"Tempest Discharge recharges in 6.75 seconds instead of 9. Damage, heat cost and contact timing stay unchanged."},
	"flashfire": {"name":"Flashfire", "detail":"Magma Breath recharges in 1.8 seconds instead of 2.4. Heat cost and contact timing stay unchanged."},
	"furnace": {"name":"Furnace Heart", "detail":"Flame Wall lasts 4.8 seconds instead of 3.6, adding two damage ticks. Its heat cost stays unchanged."},
	"deepwinter": {"name":"Deep Winter", "detail":"Rime Lance and Permafrost apply 4.5 seconds of Chill instead of 3. Longer openings for a Fire shatter."},
	"aegis": {"name":"Glacial Ward", "detail":"Crystal Aegis protects Rime for 6 seconds instead of 4. The ward stays with Rime when swapped out."},
}

static func points(campaign: Dictionary) -> int:
	var total = 0
	for room in Data.ROOMS.values():
		for foe in room.enemies:
			if campaign.get("cleared", []).has(foe.id):
				total += 100 if room.role == "final" else (70 if foe.get("boss", false) else (35 if foe.get("shield", true) else 20))
		if room.role == "cache" and campaign.get("caches", []).has(room.id):
			total += 15
	for zone in Data.ZONES:
		if campaign.get("installed", []).has(zone.id):
			total += 25
	return total

static func rank(campaign: Dictionary) -> int:
	var score = points(campaign)
	return 3 if score >= RANKS[2] else (2 if score >= RANKS[1] else 1)

static func choice(campaign: Dictionary, guardian: String) -> String:
	return campaign.get("evolutions", {}).get(guardian, "")

static func reason(campaign: Dictionary, guardian: String) -> String:
	if not OPTIONS.has(guardian) or not campaign.get("guardians", []).has(guardian):
		return "Rescue and hatch this guardian first."
	if not campaign.get("hatched", false):
		return "Awaken Magma at the hatch ring."
	if rank(campaign) < 3:
		return "Reach Bond III: %d / 280 bond points." % points(campaign)
	if campaign.get("installed", []).size() < 2:
		return "Restore two sector cores at the Forge."
	if guardian == "storm" and campaign.get("installed", []).size() < 3:
		return "Restore the Storm Spine core: three sector cores unlock Tempest Arc."
	return ""

static func select(campaign: Dictionary, guardian: String, specialization: String) -> bool:
	if campaign.get("room", "") != "forge" or reason(campaign, guardian) != "":
		return false
	if not OPTIONS[guardian].has(specialization) or choice(campaign, guardian) == specialization:
		return false
	campaign.evolutions[guardian] = specialization
	return true

static func form_name(guardian: String, evolved: bool) -> String:
	if guardian == "light": return "Lumen"
	if guardian == "void": return "Null"
	if guardian == "shadow": return "Umbra"
	if guardian == "venom": return "Nox"
	if guardian == "stone": return "Cairn"
	if guardian == "storm": return "Tempest Arc" if evolved else "Arc"
	if not evolved:
		return "Magma" if guardian == "fire" else "Rime"
	return "Crowned Magma" if guardian == "fire" else "Aurora Rime"

static func ready_guardian(campaign: Dictionary) -> String:
	for guardian in ["fire", "ice", "storm"]:
		if choice(campaign, guardian) == "" and reason(campaign, guardian) == "":
			return guardian
	return ""
