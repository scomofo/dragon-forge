extends RefCounted
## Milestones, not rewards that can be granted repeatedly by overlapping inputs.

static func fresh() -> Dictionary:
	return {"version": 1, "hatched": false, "gate_open": false, "clears": 0, "core": false, "upgraded": false}

static func validate(value: Variant) -> bool:
	if not value is Dictionary or value.get("version") != 1:
		return false
	for key in ["hatched", "gate_open", "core", "upgraded"]:
		if not value.get(key) is bool:
			return false
	var clears = value.get("clears")
	if not (clears is int or clears is float) or clears != int(clears) or clears < 0 or clears > 3:
		return false
	if value.gate_open and not value.hatched:
		return false
	if clears > 0 and not value.gate_open:
		return false
	if value.core and clears != 3:
		return false
	return not value.upgraded or value.core

static func advance(state: Dictionary, event: String, encounter: int = -1) -> bool:
	match event:
		"hatch":
			if state.hatched:
				return false
			state.hatched = true
		"gate":
			if not state.hatched or state.gate_open:
				return false
			state.gate_open = true
		"clear":
			if not state.gate_open or state.clears >= 3 or encounter != int(state.clears):
				return false
			state.clears += 1
		"core":
			if state.clears != 3 or state.core:
				return false
			state.core = true
		"install":
			if not state.core or state.upgraded:
				return false
			state.upgraded = true
		_:
			return false
	return true
