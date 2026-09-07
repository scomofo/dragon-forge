extends RefCounted
## Deterministic rules only: no scene, input, rendering, or wall-clock access.
## Four prototype moves; only Magma Breath / Flame Wall are inherited move names.

const ABILITIES = {
	"claw": {"name": "Cinder Claw", "damage": 24.0, "heat": 0.0, "cooldown": 0.55, "range": 2.8, "cone": 0.1},
	"breath": {"name": "Magma Breath", "damage": 38.0, "heat": 24.0, "cooldown": 2.4, "range": 7.0, "cone": 0.65},
	"wall": {"name": "Flame Wall", "damage": 14.0, "heat": 32.0, "cooldown": 6.0, "range": 4.0, "radius": 2.3},
	"burst": {"name": "Core Burst", "damage": 62.0, "heat": 40.0, "cooldown": 9.0, "range": 4.5, "cone": -1.0},
}
const ORDER = ["claw", "breath", "wall", "burst"]

static func fresh() -> Dictionary:
	return {"hp": 120.0, "max_hp": 120.0, "heat": 0.0, "cooldowns": {}, "iframes": 0.0, "dash": 0.0, "dodge_cd": 0.0, "guard": false}

static func tick(state: Dictionary, delta: float, guarding: bool = false) -> void:
	var dt = maxf(delta, 0.0)
	state.guard = guarding and state.hp > 0.0 and state.dash <= 0.0
	state.heat = maxf(0.0, state.heat - dt * (8.0 if state.guard else 16.0))
	for key in ["iframes", "dash", "dodge_cd"]:
		state[key] = maxf(0.0, state[key] - dt)
	for key in state.cooldowns.keys():
		state.cooldowns[key] = maxf(0.0, state.cooldowns[key] - dt)

static func rejection(state: Dictionary, id: String) -> String:
	if not ABILITIES.has(id):
		return "Unknown ability"
	if state.hp <= 0.0:
		return "Return to the Forge to retry"
	if state.dash > 0.0 or state.guard:
		return "Release guard / finish dodge"
	if state.cooldowns.get(id, 0.0) > 0.0:
		return "Recharging"
	if state.heat + ABILITIES[id].heat > 100.0:
		return "Too hot - let the core cool"
	return ""

static func cast(state: Dictionary, id: String) -> bool:
	if rejection(state, id) != "":
		return false
	state.heat += ABILITIES[id].heat
	state.cooldowns[id] = ABILITIES[id].cooldown
	return true

static func dodge(state: Dictionary) -> bool:
	if state.hp <= 0.0 or state.dodge_cd > 0.0 or state.heat > 90.0:
		return false
	state.heat += 10.0
	state.iframes = 0.24
	state.dash = 0.18
	state.dodge_cd = 0.85
	state.guard = false
	return true

static func damage(state: Dictionary, amount: float) -> float:
	if amount <= 0.0 or state.hp <= 0.0 or state.iframes > 0.0:
		return 0.0
	var applied = minf(state.hp, amount * (0.25 if state.guard else 1.0))
	state.hp -= applied
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
