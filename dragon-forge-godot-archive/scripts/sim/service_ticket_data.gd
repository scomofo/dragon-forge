extends RefCounted
class_name ServiceTicketData

const TICKET_TYPES := {
	"OPTIMIZATION": {
		"icon": "!",
		"color": Color("#00ffff"),
		"label": "Optimization",
	},
	"UNKNOWN_CODE": {
		"icon": "?",
		"color": Color("#a56bff"),
		"label": "Unknown Code",
	},
	"CORRUPTION": {
		"icon": "X",
		"color": Color("#ff594d"),
		"label": "Corruption",
	},
	"ROOT": {
		"icon": "INF",
		"color": Color("#fff05a"),
		"label": "Root Quest",
	},
}

const QUEST_TYPE_OVERRIDES := {
	"memory_leak": "CORRUPTION",
	"ghost_in_the_well": "UNKNOWN_CODE",
	"unauthorized_manual": "UNKNOWN_CODE",
	"rerender_portrait": "OPTIMIZATION",
	"asset_recovery": "UNKNOWN_CODE",
	"wireframe_harvest": "OPTIMIZATION",
	"stuck_path": "OPTIMIZATION",
	"corrupted_lullaby": "CORRUPTION",
	"sentinel_404": "ROOT",
}

static func ticket_for_sidequest(quest_id: String, quest: Dictionary, tile: Dictionary, severity: float) -> Dictionary:
	var ticket_type: String = QUEST_TYPE_OVERRIDES.get(quest_id, "OPTIMIZATION")
	var meta: Dictionary = TICKET_TYPES[ticket_type]
	return {
		"id": _ticket_id(quest_id),
		"name": quest.get("title", "Unregistered Service Ticket"),
		"type": ticket_type,
		"type_label": meta["label"],
		"icon": meta["icon"],
		"color": meta["color"],
		"location_label": tile.get("label", "Unknown Sector"),
		"reward": quest.get("reward_item", ""),
		"description": quest.get("summary", "Resolve the anomaly before sector stability drops."),
		"severity": clampf(severity, 0.0, 1.0),
	}

static func ticket_for_threadfall(tile: Dictionary, severity: float) -> Dictionary:
	var meta: Dictionary = TICKET_TYPES["CORRUPTION"]
	return {
		"id": "Ticket_THREAD_%s" % str(tile.get("id", "unknown")).to_upper(),
		"name": "Thread Precipitation",
		"type": "CORRUPTION",
		"type_label": meta["label"],
		"icon": meta["icon"],
		"color": meta["color"],
		"location_label": tile.get("label", "Skybox Leak"),
		"reward": "sector_integrity",
		"description": "Corrupted execution threads are de-rendering local assets. Char them before impact.",
		"severity": clampf(severity, 0.0, 1.0),
	}

static func ticket_for_root_objective(title: String, description: String, location_label: String) -> Dictionary:
	var meta: Dictionary = TICKET_TYPES["ROOT"]
	return {
		"id": "Ticket_ROOT",
		"name": title,
		"type": "ROOT",
		"type_label": meta["label"],
		"icon": meta["icon"],
		"color": meta["color"],
		"location_label": location_label,
		"reward": "root_progress",
		"description": description,
		"severity": 1.0,
	}

static func _ticket_id(seed: String) -> String:
	var hash := 0
	for index in seed.length():
		hash = int((hash * 31 + seed.unicode_at(index)) % 1000)
	return "Ticket_%03d" % hash
