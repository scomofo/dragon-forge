extends RefCounted
## Compatibility facade for the public Synthesis contract; Fusion owns acquisition.
const Fusion = preload("res://campaign/fusion.gd")
const REQUIRED_PARENTS = ["void", "light"]

static func reason(c: Dictionary) -> String:
	return Fusion.synthesis_reason(c)

static func can_forge(c: Dictionary) -> bool:
	return Fusion.forge_synthesis(c.duplicate(true))

static func forge(c: Dictionary) -> bool:
	return Fusion.forge_synthesis(c)

static func can_hatch(c: Dictionary) -> bool:
	return Fusion.hatch_synthesis(c.duplicate(true))

static func hatch(c: Dictionary) -> bool:
	return Fusion.hatch_synthesis(c)

static func validate_owned(c: Dictionary) -> bool:
	if not c.get("guardians", []) is Array or not c.get("synthesis_forged") is bool:
		return false
	if c.guardians.has("synthesis") and not c.synthesis_forged:
		return false
	if c.synthesis_forged:
		for flag in ["hatched", "finished", "void_forged", "void_imprint_recovered"]:
			if not c.get(flag) is bool:return false
		return reason(c) == ""
	return true
