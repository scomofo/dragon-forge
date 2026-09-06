extends RefCounted
## Version 2 keeps all v1 milestones. Trial replay never grants another core.
const Modules = preload("res://sim/forge_modules.gd")

static func fresh() -> Dictionary:
	return {"version": 2, "hatched": false, "gate_open": false, "clears": 0, "core": false, "upgraded": false, "module": "", "trial_cleared": false}

static func _milestones_valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for key in ["hatched", "gate_open", "core", "upgraded"]:
		if not value.get(key) is bool:
			return false
	var clears = value.get("clears")
	if not (clears is int or clears is float) or not is_finite(float(clears)) or clears != floor(clears) or clears < 0 or clears > 3:
		return false
	if value.gate_open and not value.hatched:
		return false
	if clears > 0 and not value.gate_open:
		return false
	if value.core and clears != 3:
		return false
	return not value.upgraded or value.core

static func validate(value: Variant) -> bool:
	if not _milestones_valid(value) or value.get("version") != 2:
		return false
	if not Modules.valid(value.get("module")) or not value.get("trial_cleared") is bool:
		return false
	if value.module != "" and not value.upgraded:
		return false
	return not value.trial_cleared or (value.upgraded and value.module != "")

## Invalid/future saves return {} so the store can preserve their original bytes.
static func migrate(value: Variant) -> Dictionary:
	if not _milestones_valid(value):
		return {}
	var result: Dictionary = value.duplicate(true)
	if result.get("version") == 1:
		result.version = 2
		result.module = ""
		result.trial_cleared = false
	if not validate(result):
		return {}
	result.version = 2
	result.clears = int(result.clears)
	return result

static func advance(state: Dictionary, event: String, encounter: int = -1) -> bool:
	if not validate(state):
		return false
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
		"trial":
			if not state.upgraded or state.module == "" or state.trial_cleared:
				return false
			state.trial_cleared = true
		_:
			return false
	return true

## Selection is repeatable at the Forge, but installation/reward is never duplicated.
static func select_module(state: Dictionary, id: String) -> bool:
	if not validate(state) or not state.core or not Modules.DATA.has(id) or state.module == id:
		return false
	state.upgraded = true
	state.module = id
	return true
