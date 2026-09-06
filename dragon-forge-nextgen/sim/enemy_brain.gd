extends RefCounted
## A spatial reinterpretation of Firewall Sentinel's closed/open shield cycle.
## A tell locks its target once. Rendering quality cannot change its timing.

var mode = "seek"
var timer = 0.0
var locked_target = Vector3.ZERO
var enraged = false
var boss = false

func tick(delta: float, distance: float, target: Vector3) -> String:
	if mode == "dead":
		return ""
	if mode == "seek":
		if distance <= (5.0 if boss else 4.0):
			mode = "tell"
			locked_target = target
			timer = tell_duration()
			return "tell"
		return ""
	timer = maxf(0.0, timer - maxf(delta, 0.0))
	if timer > 0.0:
		return ""
	if mode == "tell":
		mode = "recover"
		timer = 1.8
		return "slam"
	mode = "seek"
	return "closed"

func tell_duration() -> float:
	return 0.95 if enraged else 1.35

func open_window(duration: float) -> void:
	if mode == "dead":
		return
	mode = "recover"
	timer = maxf(timer if timer > 0.0 else 0.0, duration)

func vulnerable() -> bool:
	return mode == "recover"

func kill() -> void:
	mode = "dead"
	timer = 0.0
