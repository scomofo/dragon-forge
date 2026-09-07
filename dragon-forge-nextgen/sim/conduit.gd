extends RefCounted
## Bounded heat interaction, independent of particles or frame rate.
var heat = 0.0
var cooldown = 0.0

func tick(delta: float) -> void:
	var dt = maxf(delta, 0.0)
	heat = maxf(0.0, heat - 2.0 * dt)
	cooldown = maxf(0.0, cooldown - dt)

func add_heat(amount: float) -> bool:
	if cooldown > 0.0 or amount <= 0.0:
		return false
	heat = minf(100.0, heat + amount)
	if heat < 60.0:
		return false
	heat = 0.0
	cooldown = 6.0
	return true
