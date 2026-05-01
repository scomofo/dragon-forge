extends RefCounted
class_name StoryData

const BIOS_DIALOGUE := {
	"vault_first_rack": [
		"B.I.O.S. ONLINE: Binary Integrated Overlord System.",
		"USER PERMISSION DETECTED: Felix. Classification: not god, administrator.",
		"MISSION 04: Establish Stable Connection. Protect Root Hardware from Scrap-Wraith maintenance drift.",
	],
	"cpu_heatsink": [
		"THERMAL WARNING: CPU core sustaining myth-load.",
		"Magma protocol compatible with Overclocked evolution. Cooling cycles required.",
		"SOURCE CODE BUFFS LOCKED: recover Root Password and stabilize boot channel.",
	],
}

static func bios_lines(tile_id: String) -> Array[String]:
	var source: Array = BIOS_DIALOGUE.get(tile_id, ["B.I.O.S. STANDBY: Awaiting stable connection."])
	var lines: Array[String] = []
	for line in source:
		lines.append(str(line))
	return lines

static func artifact_message(artifact_id: String) -> String:
	if artifact_id == "root_password":
		return "Root Password recovered from the technical manual margin. Permission Gates can now be bypassed."
	if artifact_id == "overclocked_state":
		return "Overclocked State discovered: Magma-class speed surges, but future Cooling Cycles must manage heat damage."
	return ""
