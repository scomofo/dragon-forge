extends RefCounted
class_name DragonVaultData

const CREW_CARDS := {
	"chief_maintenance_officer": {
		"name": "Chief Maintenance Officer",
		"rarity": "Original Crew",
		"location": "hardware_husk",
		"lore": "Felix's ancestor initiated the hard landing and preserved the first maintenance rites.",
		"stability_grade_hint": "Corners show drive-bay scorch marks; centering favors the old Astraeus insignia.",
	},
	"systems_botanist": {
		"name": "Systems Botanist",
		"rarity": "Original Crew",
		"location": "overgrown_buffer",
		"lore": "Designed the pastoral foliage wrapper that later grew into Directory Trees.",
		"stability_grade_hint": "Surface pattern reveals original leaf shader annotations.",
	},
	"simulation_harpist": {
		"name": "Simulation Harpist",
		"rarity": "Original Crew",
		"location": "lunar_sector",
		"lore": "Encoded mental-stability songs into the MIDI handshake system.",
		"stability_grade_hint": "Edges pulse at A4 under Diagnostic Lens.",
	},
}

static func get_crew_card(id: String) -> Dictionary:
	var card: Dictionary = CREW_CARDS.get(id, {})
	var result := card.duplicate(true)
	if not result.is_empty():
		result["id"] = id
	return result

static func grade_relic_stability(surface: float, corners: float, edges: float, centering: float) -> Dictionary:
	var avg := (surface + corners + edges + centering) / 4.0
	var rounded := _rounded_card_grade(avg)
	var label := _label_for_grade(rounded)
	return {
		"surface": surface,
		"corners": corners,
		"edges": edges,
		"centering": centering,
		"average": avg,
		"grade": rounded,
		"label": label,
		"stability_bonus": maxf(0.0, (rounded - 8.0) * 0.04),
		"is_gem_mint": rounded >= 10.0,
	}

static func apply_relic_grade_bonus(relic_id: String, grade: Dictionary) -> Dictionary:
	var stability_bonus := float(grade.get("stability_bonus", 0.0))
	var gem_mint := bool(grade.get("is_gem_mint", false))
	var result := {
		"relic_id": relic_id,
		"stability_bonus": stability_bonus,
		"torque_bonus": 0.0,
		"scan_clarity_bonus": 0.0,
		"final_override_bonus": false,
	}
	match relic_id:
		"10mm_wrench":
			result["torque_bonus"] = 0.15 + stability_bonus
			result["final_override_bonus"] = gem_mint
		"diagnostic_lens":
			result["scan_clarity_bonus"] = 0.12 + stability_bonus
			result["final_override_bonus"] = gem_mint
		_:
			result["stability_bonus"] = stability_bonus
	return result

static func gallery_progress(collected_ids: Array) -> Dictionary:
	var unique := {}
	for id in collected_ids:
		if CREW_CARDS.has(str(id)):
			unique[str(id)] = true
	var total := CREW_CARDS.size()
	var collected := unique.size()
	return {
		"collected": collected,
		"total": total,
		"completion_percent": float(collected) / float(total) * 100.0,
		"complete": collected == total,
	}

static func _rounded_card_grade(avg: float) -> float:
	if avg >= 9.75:
		return 10.0
	if avg >= 9.25:
		return 9.5
	if avg >= 8.75:
		return 9.0
	return floorf(avg * 2.0) / 2.0

static func _label_for_grade(grade: float) -> String:
	if grade >= 10.0:
		return "Gem Mint 10"
	if grade >= 9.5:
		return "Gem Mint 9.5"
	if grade >= 9.0:
		return "Mint 9"
	return "Stability %.1f" % grade
