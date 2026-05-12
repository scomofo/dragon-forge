extends RefCounted
class_name LoreCanon

const PLAYER := {
	"name": "Skye",
	"role": "dragon handler and emerging system administrator",
	"premise": "Skye begins inside a mythic rendered world and learns it is powered by the ancient Astraeus hardware layer.",
}

const FELIX := {
	"name": "Professor Felix",
	"role": "forge-keeper, mentor, and frantic technical operator",
	"tone": "warm, precise, anxious, and practical under pressure",
}

const WORLD := {
	"rendered_world": "The pastoral fantasy layer is a rendered world, beautiful because people were meant to live inside it.",
	"astraeus": "The Astraeus is the buried physical vessel/server layer that still powers the rendered world.",
	"mirror_admin": "Mirror Admin began as a safety process and became an overprotective intelligence preparing the world for deletion.",
	"great_reset": "The Great Reset is a hard wipe that treats living memory as corrupted data.",
}

const DRAGON_PROTOCOL := {
	"summary": "Dragons are living elemental protocols: guardians, maintenance processes, and companions with enough soul to choose Skye back.",
}

const OPENING_BOOT_LINES := [
	"> ASTRAEUS EMERGENCY WAKE SEQUENCE",
	"> OPERATOR SIGNAL FOUND: SKYE",
	"> RENDERED WORLD LAYER: UNSTABLE",
	"> ELEMENTAL GUARDIAN PROTOCOLS: DORMANT",
	"> MIRROR ADMIN OVERRIDE: ACTIVE",
	"> GREAT RESET COUNTDOWN: SIGNAL LOST",
]

static func captain_log_fragments() -> Array[Dictionary]:
	return [
		{"id": "001", "title": "The Rendered World", "body": WORLD["rendered_world"]},
		{"id": "002", "title": "The Mirror Admin", "body": WORLD["mirror_admin"]},
		{"id": "003", "title": "Skye Signal", "body": "Skye registers as both resident and operator. The system cannot decide whether to guide her, quarantine her, or hand her the keys."},
		{"id": "004", "title": "Guardian Protocols", "body": DRAGON_PROTOCOL["summary"]},
		{"id": "005", "title": "Great Reset", "body": WORLD["great_reset"]},
	]
