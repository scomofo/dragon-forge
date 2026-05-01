extends Resource
class_name SystemTicket

const STATE_UNINITIALIZED := "UNINITIALIZED"
const STATE_TRIGGERED := "TRIGGERED"
const STATE_ACTIVE := "ACTIVE"
const STATE_VALIDATING := "VALIDATING"
const STATE_RESOLVED := "RESOLVED"

@export var ticket_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export_enum("OPTIMIZATION", "UNKNOWN_CODE", "CORRUPTION", "BREACH", "ROOT") var severity: String = "OPTIMIZATION"
@export var target_sector: Vector2i = Vector2i.ZERO
@export var target_frequency: float = 0.0
@export var required_relic_code: String = ""
@export var reward_item: String = ""
@export_enum("UNINITIALIZED", "TRIGGERED", "ACTIVE", "VALIDATING", "RESOLVED") var state: String = STATE_UNINITIALIZED
@export var is_resolved: bool = false

func to_notification() -> Dictionary:
	return {
		"id": ticket_id,
		"name": title,
		"type": severity,
		"type_label": severity.capitalize(),
		"location_label": "Sector %d,%d" % [target_sector.x, target_sector.y],
		"reward": reward_item,
		"description": description,
		"severity": _severity_score(),
		"state": state,
	}

func requires_handshake() -> bool:
	return target_frequency > 0.0

func requires_relic() -> bool:
	return required_relic_code != ""

func transition_to(next_state: String) -> void:
	state = next_state
	is_resolved = next_state == STATE_RESOLVED

func progress_payload(progress: float = 0.0) -> Dictionary:
	return {
		"state": state,
		"progress": clampf(progress, 0.0, 1.0),
		"target_sector": target_sector,
		"requires_handshake": requires_handshake(),
		"requires_relic": requires_relic(),
	}

func _severity_score() -> float:
	match severity:
		"ROOT":
			return 1.0
		"BREACH":
			return 0.92
		"CORRUPTION":
			return 0.82
		"UNKNOWN_CODE":
			return 0.62
		_:
			return 0.42
