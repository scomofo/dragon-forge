extends RefCounted
## One objective at a time. The breach waypoint prevents directions through walls.
const APPROACH = [Vector3(0, 0, -3), Vector3(0, 0, -10), Vector3(0, 0, -16)]
const TRIGGERS = [0.0, -8.0, -14.0]

static func describe(progress: Dictionary, at: Vector3, fighting: bool, trial: bool = false) -> Dictionary:
	if not progress.hatched:
		return _step(0, "A spark in the dark", "Awaken the guardian beside the amber ring.", Vector3(-2.5, 0, 10), "AWAKEN")
	if not progress.gate_open:
		return _step(1, "Power the breach", "Aim at the cyan relay. Land two Magma Breaths [2 / Y].", Vector3(-2.1, 0, 4.5), "HEAT RELAY")
	if fighting:
		return _step(2, "Field test" if trial else ["Read the shield", "Use the arena", "Break the Warden"][mini(int(progress.clears), 2)], "Bait the marked impact. Dodge or guard, then strike the open shield.", at, "")
	if trial or progress.clears < 3:
		var point: Vector3 = Vector3(0, 0, -5) if trial else APPROACH[int(progress.clears)]
		if at.z > 2.8:
			point = Vector3(0, 0, 0.5)
		return _step(2, "Test your new core" if trial else "Into the Outer Grid", "Follow the relay path. The next guardian waits ahead.", point, "CONTINUE")
	if not progress.core:
		return _step(3, "Reclaim the heart", "The Warden is down. Collect its core at the north end.", Vector3(0, 0, -18), "RECOVER CORE")
	if not progress.upgraded or progress.module == "":
		var point = Vector3(0, 0, 4) if at.z < 1.0 else Vector3(2.5, 0, 10)
		return _step(4, "Give the Forge a heart", "Return through the breach. Choose how the core changes Magma.", point, "RETURN TO FORGE")
	var target = Vector3(0, 0, 4) if at.z < 1.0 else Vector3(2.5, 0, 10)
	return _step(5, "Your Forge, your build", "Reconfigure at the socket or field-test the installed core. No reset required.", target, "FORGE SOCKET")

static func _step(index: int, title: String, detail: String, target: Vector3, marker: String) -> Dictionary:
	return {"index": index, "title": title, "detail": detail, "target": target, "marker": marker}
