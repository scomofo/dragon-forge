extends Node

signal ticket_spawned(ticket_resource: Resource)
signal ticket_updated(ticket_id: String, progress: Dictionary)
signal ticket_resolved(ticket_id: String)
signal sector_stability_changed(sector_id: Vector2i, value: float)
signal permission_gate_breach_required(gate_id: String, required_code: String)
signal analog_relic_used(relic_name: String, target_id: String)

func emit_ticket_spawned(ticket_resource: Resource) -> void:
	ticket_spawned.emit(ticket_resource)

func emit_ticket_updated(ticket_id: String, progress: Dictionary) -> void:
	ticket_updated.emit(ticket_id, progress)

func emit_ticket_resolved(ticket_id: String) -> void:
	ticket_resolved.emit(ticket_id)

func emit_sector_stability_changed(sector_id: Vector2i, value: float) -> void:
	sector_stability_changed.emit(sector_id, clampf(value, 0.0, 1.0))

func emit_permission_gate_breach_required(gate_id: String, required_code: String) -> void:
	permission_gate_breach_required.emit(gate_id, required_code)

func emit_analog_relic_used(relic_name: String, target_id: String) -> void:
	analog_relic_used.emit(relic_name, target_id)
