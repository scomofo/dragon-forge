extends RefCounted
## Deterministic rules only: no scene, input, rendering, or wall-clock access.
const Modules = preload("res://sim/forge_modules.gd")
const ABILITIES = {
	"claw": {"name": "Cinder Claw", "damage": 24.0, "heat": 0.0, "cooldown": 0.55, "range": 2.8, "cone": 0.1, "windup": 0.10, "recovery": 0.18},
	"breath": {"name": "Magma Breath", "damage": 38.0, "heat": 24.0, "cooldown": 2.4, "range": 7.0, "cone": 0.65, "windup": 0.22, "recovery": 0.28},
	"wall": {"name": "Flame Wall", "damage": 14.0, "heat": 32.0, "cooldown": 6.0, "range": 4.0, "radius": 2.3, "windup": 0.20, "recovery": 0.24},
	"burst": {"name": "Core Burst", "damage": 62.0, "heat": 40.0, "cooldown": 9.0, "range": 4.5, "cone": -1.0, "windup": 0.32, "recovery": 0.40},
}
const ICE = {
	"claw": {"name":"Frost Bite", "damage":18.0, "heat":0.0, "cooldown":0.55, "range":2.8, "cone":0.25, "windup":0.12, "recovery":0.20},
	"breath": {"name":"Rime Lance", "damage":30.0, "heat":20.0, "cooldown":2.8, "range":8.0, "cone":0.86, "windup":0.28, "recovery":0.30},
	"wall": {"name":"Permafrost", "damage":8.0, "heat":30.0, "cooldown":6.0, "range":4.0, "radius":2.3, "windup":0.24, "recovery":0.26},
	"burst": {"name":"Crystal Aegis", "damage":0.0, "heat":36.0, "cooldown":10.0, "range":0.0, "cone":-1.0, "windup":0.20, "recovery":0.24},
}
const STORM = {
	"claw": {"name":"Spark Talon", "damage":20.0, "heat":0.0, "cooldown":.55, "range":2.8, "cone":.2, "windup":.12, "recovery":.21},
	"breath": {"name":"Arc Lance", "damage":32.0, "heat":22.0, "cooldown":2.6, "range":8.0, "cone":.83, "windup":.26, "recovery":.34},
	"wall": {"name":"Static Well", "damage":10.0, "heat":30.0, "cooldown":6.0, "range":4.0, "radius":2.3, "windup":.24, "recovery":.30},
	"burst": {"name":"Tempest Discharge", "damage":52.0, "heat":40.0, "cooldown":9.0, "range":4.5, "cone":-1.0, "windup":.34, "recovery":.42},
}
const STONE = {
	"claw": {"name":"Granite Knuckle", "damage":22.0, "heat":0.0, "cooldown":.60, "range":2.8, "cone":.18, "windup":.14, "recovery":.22},
	"breath": {"name":"Fault Line", "damage":34.0, "heat":20.0, "cooldown":2.9, "range":6.5, "cone":.74, "windup":.30, "recovery":.34},
	"wall": {"name":"Bulwark Field", "damage":9.0, "heat":28.0, "cooldown":6.5, "range":4.0, "radius":2.3, "windup":.26, "recovery":.30},
	"burst": {"name":"Earthshatter", "damage":58.0, "heat":38.0, "cooldown":9.0, "range":4.5, "cone":-1.0, "windup":.38, "recovery":.44},
}
const VENOM = {
	"claw": {"name":"Toxin Fang", "damage":18.0, "heat":0.0, "cooldown":.50, "range":2.9, "cone":.20, "windup":.11, "recovery":.18},
	"breath": {"name":"Acid Spit", "damage":26.0, "heat":18.0, "cooldown":2.4, "range":7.5, "cone":.82, "windup":.22, "recovery":.28},
	"wall": {"name":"Toxic Cloud", "damage":7.0, "heat":28.0, "cooldown":6.0, "range":4.0, "radius":2.5, "windup":.22, "recovery":.28},
	"burst": {"name":"Septic Bloom", "damage":46.0, "heat":36.0, "cooldown":8.5, "range":4.5, "cone":-1.0, "windup":.30, "recovery":.38},
}
const SHADOW = {
	# Shadow Strike, Void Pulse and Phase Strike are canonical browser techniques.
	# Umbral Wake is the bounded native field needed by the four-slot action layout.
	"claw": {"name":"Shadow Strike", "damage":27.0, "heat":0.0, "cooldown":.46, "range":3.1, "cone":.18, "windup":.09, "recovery":.15},
	"breath": {"name":"Void Pulse", "damage":36.0, "heat":22.0, "cooldown":2.5, "range":7.8, "cone":.84, "windup":.20, "recovery":.25},
	"wall": {"name":"Umbral Wake", "damage":8.0, "heat":28.0, "cooldown":5.5, "range":4.0, "radius":2.4, "windup":.18, "recovery":.24},
	"burst": {"name":"Phase Strike", "damage":50.0, "heat":34.0, "cooldown":7.5, "range":4.8, "cone":-1.0, "windup":.20, "recovery":.30},
}
const VOID = {
	# Rift Shard fills the native basic-attack slot. The other names are canonical techniques.
	"claw": {"name":"Rift Shard", "damage":24.0, "heat":0.0, "cooldown":.52, "range":3.0, "cone":.20, "windup":.11, "recovery":.18},
	"breath": {"name":"Void Rift", "damage":32.0, "heat":22.0, "cooldown":3.0, "range":7.8, "cone":.82, "windup":.26, "recovery":.30},
	"wall": {"name":"Null Reflect", "damage":0.0, "heat":30.0, "cooldown":8.0, "range":0.0, "radius":0.0, "windup":.18, "recovery":.24},
	"burst": {"name":"Siphon Rift", "damage":44.0, "heat":36.0, "cooldown":8.0, "range":4.8, "cone":-1.0, "windup":.30, "recovery":.34},
}
const LIGHT = {
	# Prism Claw fills the native basic-attack slot. Solar Flare is one radial hit,
	# not a persistent field. Native combat has no accuracy or player-ailment system,
	# so browser Dazzle and cleanse effects are not invented here.
	"claw": {"name":"Prism Claw", "damage":22.0, "heat":0.0, "cooldown":.55, "range":2.9, "cone":.20, "windup":.12, "recovery":.20},
	"breath": {"name":"Radiant Beam", "damage":36.0, "heat":22.0, "cooldown":2.8, "range":8.0, "cone":.86, "windup":.26, "recovery":.30},
	"wall": {"name":"Solar Flare", "damage":42.0, "heat":32.0, "cooldown":7.5, "range":4.5, "cone":-1.0, "windup":.32, "recovery":.36},
	"burst": {"name":"Restoration", "damage":0.0, "heat":34.0, "cooldown":12.0, "range":0.0, "cone":-1.0, "windup":.40, "recovery":.32},
}
const ORDER = ["claw", "breath", "wall", "burst"]
const MAX_RESOLVE = 3
const MAX_TOXIN = 3
const MAX_PHASE = 2

static func rule(state: Dictionary, id: String) -> Dictionary:
	var kit: Dictionary = {"fire":ABILITIES, "ice":ICE, "storm":STORM, "stone":STONE, "venom":VENOM, "shadow":SHADOW, "void":VOID, "light":LIGHT}.get(state.get("guardian", "fire"), ABILITIES)
	var move: Dictionary = kit.get(id, {}).duplicate()
	if not move.is_empty() and id == "breath" and state.get("evolution", "") == "flashfire": move.cooldown = 1.8
	if not move.is_empty() and id == "burst" and state.get("evolution", "") == "overcharge": move.cooldown = 6.75
	return move

static func guardian_name(id: String) -> String:
	return {"fire":"MAGMA", "ice":"RIME", "storm":"ARC", "stone":"CAIRN", "venom":"NOX", "shadow":"UMBRA", "void":"NULL", "light":"LUMEN"}.get(id, "UNKNOWN")

static func fresh(module: String = "", guardian: String = "fire") -> Dictionary:
	var maximum: float = Modules.profile(module).hp * {"fire":1.0, "ice":.90, "storm":.85, "stone":1.15, "venom":.95, "shadow":.82, "void":.88, "light":1.0}.get(guardian, 1.0)
	return {"evolution":"", "guardian":guardian, "ward":0.0, "null_reflect":0.0, "resolve":0, "phase":0, "module":module if Modules.valid(module) else "", "hp":maximum, "max_hp":maximum, "heat":0.0, "cooldowns":{}, "iframes":0.0, "dodge_iframes":0.0, "dash":0.0, "dodge_cd":0.0, "guard":false, "action":"", "action_time":0.0, "action_hit":false}

static func tick(state: Dictionary, delta: float, guarding: bool = false) -> String:
	var dt = maxf(delta, 0.0) if is_finite(delta) else 0.0
	var impact = ""
	if state.hp <= 0.0: cancel_action(state)
	elif state.action != "":
		var id: String = state.action
		var move: Dictionary = rule(state, id)
		state.action_time += dt
		if not state.action_hit and state.action_time + 0.000001 >= move.windup:
			state.action_hit = true; impact = id
		if state.action_time + 0.000001 >= move.windup + move.recovery: cancel_action(state)
	state.ward = maxf(0.0, state.get("ward", 0.0) - dt)
	state.null_reflect = maxf(0.0, state.get("null_reflect", 0.0) - dt)
	state.guard = guarding and state.hp > 0.0 and state.dash <= 0.0 and state.action == ""
	state.heat = maxf(0.0, state.heat - dt * float(Modules.profile(state.get("module", "")).cooling) * (0.5 if state.guard else 1.0))
	for key in ["iframes", "dash", "dodge_cd"]: state[key] = maxf(0.0, state[key] - dt)
	state.dodge_iframes = maxf(0.0, state.get("dodge_iframes",0.0) - dt)
	for key in state.cooldowns.keys(): state.cooldowns[key] = maxf(0.0, state.cooldowns[key] - dt)
	return impact

static func rejection(state: Dictionary, id: String) -> String:
	if not ABILITIES.has(id): return "Unknown ability"
	if state.hp <= 0.0: return "Return to the Forge to retry"
	if state.dash > 0.0 or state.guard: return "Release guard / finish dodge"
	if state.action != "": return "Finishing technique"
	if state.cooldowns.get(id, 0.0) > 0.0: return "Recharging"
	if state.heat + heat_cost(state, id) > 100.0: return "Too hot - let the core cool"
	return ""

static func cast(state: Dictionary, id: String) -> bool:
	if rejection(state, id) != "": return false
	state.heat += heat_cost(state, id)
	state.cooldowns[id] = rule(state,id).cooldown
	state.action = id; state.action_time = 0.0; state.action_hit = false
	return true

static func dodge(state: Dictionary) -> bool:
	if state.hp <= 0.0 or state.dodge_cd > 0.0 or state.heat > 90.0: return false
	cancel_action(state); state.heat += 10.0; state.iframes = 0.24; state.dodge_iframes = 0.24; state.dash = 0.18; state.dodge_cd = 0.85; state.guard = false
	return true

static func damage(state: Dictionary, amount: float) -> float:
	if not is_finite(amount) or amount <= 0.0 or state.hp <= 0.0:return 0.0
	if state.iframes > 0.0:
		# Phase is earned only when a real incoming hit intersects an active dodge window.
		if state.get("guardian","") == "shadow" and state.get("dodge_iframes",0.0)>0.0:
			state.phase=mini(MAX_PHASE,int(state.get("phase",0))+1)
		return 0.0
	var guarded = state.guard
	var reflecting = state.get("guardian", "") == "void" and state.get("null_reflect", 0.0) > 0.0
	var applied = minf(state.hp, amount * (0.5 if reflecting else 1.0) * (0.45 if state.get("ward", 0.0) > 0.0 else 1.0) * (float(Modules.profile(state.get("module", "")).guard) if guarded else 1.0))
	state.hp -= applied
	if applied > 0.0 and guarded and state.get("guardian","") == "stone": state.resolve = mini(MAX_RESOLVE, int(state.get("resolve",0)) + 1)
	if state.hp <= 0.0: cancel_action(state)
	state.iframes = 0.16
	state.dodge_iframes = 0.0
	return applied

static func in_cone(origin: Vector3, facing: Vector3, target: Vector3, reach: float, cosine: float) -> bool:
	var offset = target - origin; offset.y = 0.0
	if offset.length_squared() > reach * reach: return false
	if offset.length_squared() < 0.001: return true
	return facing.normalized().dot(offset.normalized()) >= cosine

static func cancel_action(state: Dictionary) -> void:
	state.action = ""; state.action_time = 0.0; state.action_hit = false

static func action_remaining(state: Dictionary) -> float:
	if state.action == "": return 0.0
	var move: Dictionary = rule(state, state.action)
	return maxf(0.0, move.windup + move.recovery - state.action_time)

static func action_phase(state: Dictionary) -> String:
	if state.action == "": return ""
	return "RECOVER" if state.action_hit else "WIND UP"

static func heat_cost(state: Dictionary, id: String) -> float:
	return float(rule(state,id).get("heat", 0.0)) * float(Modules.profile(state.get("module", "")).heat)

static func technique_damage(state: Dictionary, id: String) -> float:
	var amount = float(rule(state,id).get("damage", 0.0)) * float(Modules.profile(state.get("module", "")).damage) * (1.10 if state.get("evolution", "") != "" else 1.0)
	if state.get("guardian","") == "stone" and id == "burst": amount *= 1.0 + 0.20 * float(state.get("resolve",0))
	if state.get("guardian","") == "shadow" and id == "burst": amount *= 1.0 + 0.30 * float(phase_stacks(int(state.get("phase",0))))
	return amount

static func toxin_stacks(value: int) -> int:return clampi(value,0,MAX_TOXIN)
static func toxin_duration() -> float:return 5.0
static func toxin_tick_damage() -> float:return 4.0
static func toxin_burst_multiplier(stacks: int) -> float:return 1.0 + 0.25 * float(toxin_stacks(stacks))
static func phase_stacks(value: int) -> int:return clampi(value,0,MAX_PHASE)
static func consume_phase(state: Dictionary) -> int:
	var spent=phase_stacks(int(state.get("phase",0)));state.phase=0;return spent
static func consume_resolve(state: Dictionary) -> int:
	var spent = int(state.get("resolve",0)); state.resolve = 0; return spent
static func field_duration(state: Dictionary) -> float:return 4.8 if state.get("evolution", "") == "furnace" else 3.6
static func chill_duration(state: Dictionary) -> float:return 4.5 if state.get("evolution", "") == "deepwinter" else 3.0
static func ward_duration(state: Dictionary) -> float:return 6.0 if state.get("evolution", "") == "aegis" else 4.0
static func charge_duration(state: Dictionary) -> float:return 6.0 if state.get("evolution", "") == "thunderhead" else 4.0
static func null_reflect_duration() -> float:return 1.2
static func reflected_damage(applied: float) -> float:
	return minf(applied, 20.0) if is_finite(applied) and applied > 0.0 else 0.0
static func void_displacement(id: String) -> float:
	return {"breath":1.25, "burst":-1.5}.get(id, 0.0)
static func restore(state: Dictionary) -> float:
	# The world calls this once at Restoration's contact for its living owner.
	# Healing changes HP only: no revival, reserve healing, cleanse or cooldown reset.
	var hp = float(state.get("hp", 0.0))
	var maximum = float(state.get("max_hp", 0.0))
	if state.get("guardian", "") != "light" or not is_finite(hp) or not is_finite(maximum) or hp <= 0.0 or maximum <= hp:
		return 0.0
	var healed = minf(maximum * .25, maximum - hp)
	state.hp = hp + healed
	return healed
