extends RefCounted
## Deterministic ordinary-enemy role tuning. Boss timing is intentionally unchanged.
const DATA = {
	"bruiser": {"label":"BRUISER", "engage":5.4, "speed":2.75, "tell":1.25, "recover":1.85, "min":0.0, "max":4.5},
	"bulwark": {"label":"BULWARK", "engage":6.0, "speed":1.85, "tell":1.55, "recover":3.00, "min":0.0, "max":5.0},
	"sniper": {"label":"SNIPER", "engage":10.5, "speed":2.10, "tell":1.80, "recover":1.65, "min":5.2, "max":8.2},
	"skirmisher": {"label":"SKIRMISHER", "engage":8.0, "speed":3.15, "tell":1.15, "recover":1.45, "min":3.6, "max":6.3},
	"controller": {"label":"CONTROLLER", "engage":7.3, "speed":2.20, "tell":1.50, "recover":1.90, "min":3.2, "max":5.8},
}

static func valid(id: String) -> bool:
	return DATA.has(id)

static func profile(id: String) -> Dictionary:
	return DATA.get(id, DATA.bruiser)

static func label(id: String) -> String:
	return str(profile(id).label)

static func tip(id: String) -> String:
	return {
		"bruiser":"PRESSURE / short tells, create space then counter.",
		"bulwark":"SHIELD / slow approach, long recovery window after impact.",
		"sniper":"RANGED / it backs away when crowded; cut across the beam.",
		"skirmisher":"MOBILE / it circles at mid-range; find the fan gap.",
		"controller":"ZONER / it holds ring distance; use the safe center or disengage.",
	}.get(id, "WATCH THE TELL / counter during recovery.")
