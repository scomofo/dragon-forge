extends RefCounted
## Runtime HP/heat/cooldowns are separate per guardian. No healing by swapping.
const Rules = preload("res://campaign/guardian_combat.gd")
const Growth = preload("res://campaign/growth.gd")
const Fusion = preload("res://campaign/fusion.gd")
const SWAP_COOLDOWN = 2.5
var states: Dictionary = {}
var active_id = "fire"
var swap_remaining = 0.0

func rebuild(campaign: Dictionary) -> void:
	states.clear()
	active_id = campaign.get("active_guardian", "fire")
	for id in Fusion.members(campaign):
		var state = Rules.fresh(campaign.module, id)
		state.max_hp += int(campaign.upgrades.plating) * 20.0
		state.evolution = Growth.choice(campaign, id)
		if state.evolution != "":
			state.max_hp *= 1.10
		state.hp = state.max_hp
		states[id] = state
	swap_remaining = 0.0

func reserve_id() -> String:
	for id in states:
		if id != active_id:
			return id
	return ""

func rejection(target: String, force: bool = false) -> String:
	if not states.has(target) or target == active_id:
		return "No other guardian is ready. Rescue the egg in Frozen Vault."
	if states[target].hp <= 0.0:
		return "Reserve down. Rest at a shelter or retry to revive."
	if not force and swap_remaining > 0.0:
		return "Swap recharging"
	var state: Dictionary = states[active_id]
	if not force and (state.action != "" or state.dash > 0.0):
		return "Finish the technique or dodge before swapping"
	return ""

func swap_to(target: String, force: bool = false) -> bool:
	if rejection(target, force) != "":
		return false
	for id in [active_id,target]:
		Rules.cancel_action(states[id])
		states[id].guard = false
		states[id].dash = 0.0
	active_id = target
	swap_remaining = SWAP_COOLDOWN
	return true

func tick_reserve(delta: float, cooling_level: int) -> void:
	var dt = clampf(delta,0.0,0.25) if is_finite(delta) else 0.0
	swap_remaining = maxf(0.0,swap_remaining-dt)
	for id in states:
		if id == active_id:
			continue
		# No reserve attacks or health regeneration. Cooldowns/ward still expire.
		var state: Dictionary = states[id]
		Rules.cancel_action(state)
		Rules.tick(state,dt,false)
		if state.hp > 0.0:
			state.heat = maxf(0.0,state.heat - 4.0*cooling_level*dt)
