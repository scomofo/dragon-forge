extends RefCounted
class_name StoryData

const LoreCanon := preload("res://scripts/sim/lore_canon.gd")

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

static func opening_boot_lines() -> Array[String]:
	var lines: Array[String] = []
	for line in LoreCanon.OPENING_BOOT_LINES:
		lines.append(str(line))
	return lines

static func felix_first_contact_lines() -> Array[String]:
	return [
		"Skye. Good. You can hear me.",
		"The world you know is rendered over the old Astraeus hardware.",
		"Mirror Admin is trying to preserve us by erasing us.",
		"The dragons are living guardian protocols. If they bond to you, they can hold the Matrix together.",
	]

static func opening_sequence_profile() -> Dictionary:
	return {
		"id": "opening_sequence_seen",
		"title": "ASTRAEUS EMERGENCY WAKE",
		"subtitle": "Operator signal recovered: SKYE",
		"boot_lines": opening_boot_lines(),
		"felix_lines": felix_first_contact_lines(),
		"stakes": "Mirror Admin override active. Great Reset countdown hidden behind corrupted telemetry.",
		"first_objective": "Find Felix Workshop, bond with the Root Dragon, and keep the rendered world from being classified as dead memory.",
		"presentation": "tense_boot_first_contact",
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
