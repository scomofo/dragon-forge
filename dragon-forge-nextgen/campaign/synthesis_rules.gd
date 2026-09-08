extends RefCounted
## Deterministic final-roster rules. No scene access, RNG, currency, or wall clock.
const REQUIRED_PARENTS = ["void", "light"]

static func reason(c: Dictionary) -> String:
	if not c.get("finished", false):
		return "Stabilize the Singularity before attempting Synthesis."
	var guardians: Array = c.get("guardians", [])
	if not guardians.has("void"):
		return "Awaken Null before attempting Synthesis."
	if not guardians.has("light"):
		return "Earn Lumen before attempting Synthesis."
	return ""

static func can_forge(c: Dictionary) -> bool:
	return c.get("room", "") == "forge" and reason(c) == "" and not c.get("synthesis_forged", false)

static func forge(c: Dictionary) -> bool:
	if not can_forge(c):
		return false
	c.synthesis_forged = true
	return true

static func can_hatch(c: Dictionary) -> bool:
	return c.get("room", "") == "forge" and reason(c) == "" and c.get("synthesis_forged", false) and not c.get("guardians", []).has("synthesis")

static func hatch(c: Dictionary) -> bool:
	if not can_hatch(c):
		return false
	# Preserve an explicitly selected pair. If ownership is still sparse enough
	# to have no explicit loadout, materialize the existing first two guardians
	# before adding a ninth owned guardian.
	if c.get("loadout", []).is_empty() and c.get("guardians", []).size() >= 2:
		c.loadout = c.guardians.slice(0, 2)
	c.guardians.append("synthesis")
	return true

static func validate_owned(c: Dictionary) -> bool:
	if not c.get("guardians", []) is Array:
		return false
	if c.guardians.has("synthesis"):
		return c.get("synthesis_forged", false) and reason(c) == ""
	return not c.get("synthesis_forged", false) or reason(c) == ""
