extends "res://actors/dragon.gd"
## Campaign upgrades wrap existing movement/contact timing; the prototype rules stay intact.
var cooling_level = 0

func advance_combat(delta: float, guarding: bool = false) -> void:
	super.advance_combat(delta, guarding)
	if state.hp > 0.0:
		var dt = clampf(delta, 0.0, 0.25) if is_finite(delta) else 0.0
		state.heat = maxf(0.0, state.heat - dt * cooling_level * 4.0 * (0.5 if state.guard else 1.0))
