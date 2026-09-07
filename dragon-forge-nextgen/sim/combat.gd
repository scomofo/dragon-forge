extends RefCounted
## Deterministic rules only: no scene, input, rendering, or wall-clock access.
## Four prototype moves; only Magma Breath / Flame Wall are inherited move names.

const Modules = preload("res://sim/forge_modules.gd")
const ABILITIES = {
	"claw": {"name": "Cinder Claw", "damage": 24.0, "heat": 0.0, "cooldown": 0.55, "range": 2.8, "cone": 0.1, "windup": 0.10, "recovery": 0.18},
	"breath": {"name": "Magma Breath", "damage": 38.0, "heat": 24.0, "cooldown": 2.4, "range": 7.0, "cone": 0.65, "windup": 0.22, "recovery": 0.28},
	"wall": {"name": "Flame Wall", "damage": 14.0, "heat": 32.0, "cooldown": 6.0, "range": 4.0, "radius": 2.3, "windup": 0.20, "recovery": 0.24},
	"burst": {"name": "Core Burst", "damage": 62.0, "heat": 40.0, "cooldown": 9.0, "range": 4.5, "cone": -1.0, "windup": 0.32, "recovery": 0.40},
}
const ORDER = ["claw", "breath", "wall", "burst"]

static func fresh(module: String = "") -> Dictionary:
	var maximum: float = Modules.profile(module).hp
	return {"module": module if Modules.valid(module) else "", "hp": maximum, "max_hp": maximum, "heat": 0.0, "cooldowns": {}, "iframes": 0.0, "dash": 0.0, "dodge_cd": 0.0, "guard": false, "action": "", "action_time": 0.0, "action_hit": false}

## Returns one contact event, even when a long frame spans the entire attack.
static func tick(state: Dictionary, delta: float, guarding: bool = false) -> String:
	var dt = maxf(delta, 0.0) if is_finite(delta) else 0.0
	var impact = ""
	if state.hp <= 0.0:
		cancel_action(state)
	elif state.action != "":
		var id: String = state.action
		var rule: Dictionary = ABILITIES[id]
		state.action_time += dt
		if not state.action_hit and state.action_time + 0.000001 >= rule.windup:
			state.action_hit = true
			impact = id
		if state.action_time + 0.000001 >= rule.windup + rule.recovery:
			cancel_action(state)
	state.guard = guarding and state.hp > 0.0 and state.dash <= 0.0 and state.action == ""
	state.heat = maxf(0.0, state.heat - dt * float(Modules.profile(state.get("module", "")).cooling) * (0.5 if state.guard else 1.0))
	for key in ["iframes", "dash", "dodge_cd"]:
		state[key] = maxf(0.0, state[key] - dt)
	for key in state.cooldowns.keys():
		state.cooldowns[key] = maxf(0.0, state.cooldowns[key] - dt)
	return impact

static func rejection(state: Dictionary, id: String) -> String:
	if not ABILITIES.has(id):
		return "Unknown ability"
	if state.hp <= 0.0:
		return "Return to the Forge to retry"
	if state.dash > 0.0 or state.guard:
		return "Release guard / finish dodge"
	if state.action != "":
		return "Finishing technique"
	if state.cooldowns.get(id, 0.0) > 0.0:
		return "Recharging"
	if state.heat + heat_cost(state, id) > 100.0:
		return "Too hot - let the core cool"
	return ""

static func cast(state: Dictionary, id: String) -> bool:
	if rejection(state, id) != "":
		return false
	state.heat += heat_cost(state, id)
	state.cooldowns[id] = ABILITIES[id].cooldown
	state.action = id
	state.action_time = 0.0
	state.action_hit = false
	return true

static func dodge(state: Dictionary) -> bool:
	if state.hp <= 0.0 or state.dodge_cd > 0.0 or state.heat > 90.0:
		return false
	cancel_action(state)
	state.heat += 10.0
	state.iframes = 0.24
	state.dash = 0.18
	state.dodge_cd = 0.85
	state.guard = false
	return true

static func damage(state: Dictionary, amount: float) -> float:
	if amount <= 0.0 or state.hp <= 0.0 or state.iframes > 0.0:
		return 0.0
	var applied = minf(state.hp, amount * (float(Modules.profile(state.get("module", "")).guard) if state.guard else 1.0))
	state.hp -= applied
	if state.hp <= 0.0:
		cancel_action(state)
	state.iframes = 0.16
	return applied

static func in_cone(origin: Vector3, facing: Vector3, target: Vector3, reach: float, cosine: float) -> bool:
	var offset = target - origin
	offset.y = 0.0
	if offset.length_squared() > reach * reach:
		return false
	if offset.length_squared() < 0.001:
		return true
	return facing.normalized().dot(offset.normalized()) >= cosine

static func cancel_action(state: Dictionary) -> void:
	state.action = ""
	state.action_time = 0.0
	state.action_hit = false

static func action_remaining(state: Dictionary) -> float:
	if state.action == "":
		return 0.0
	var rule: Dictionary = ABILITIES[state.action]
	return maxf(0.0, rule.windup + rule.recovery - state.action_time)

static func action_phase(state: Dictionary) -> String:
	if state.action == "":
		return ""
	return "RECOVER" if state.action_hit else "WIND UP"

static func heat_cost(state: Dictionary, id: String) -> float:
	return float(ABILITIES.get(id, {}).get("heat", 0.0)) * float(Modules.profile(state.get("module", "")).heat)

static func technique_damage(state: Dictionary, id: String) -> float:
	return float(ABILITIES.get(id, {}).get("damage", 0.0)) * float(Modules.profile(state.get("module", "")).damage)
