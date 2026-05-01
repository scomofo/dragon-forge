extends Node
class_name QuestManager

signal sector_stabilized(sector: Vector2i)
signal ticket_resolved(ticket_id: String)
signal ticket_spawned(ticket_resource)
signal ticket_updated(ticket_id: String, progress: Dictionary)

var active_tickets: Dictionary = {}

func register_ticket(ticket: Resource) -> void:
	if ticket.ticket_id == "":
		return
	ticket.transition_to("TRIGGERED")
	active_tickets[ticket.ticket_id] = ticket
	ticket_spawned.emit(ticket)
	_signal_bus_call("emit_ticket_spawned", [ticket])

func activate_ticket(ticket_id: String) -> bool:
	var ticket: Resource = active_tickets.get(ticket_id, null)
	if ticket == null or ticket.is_resolved:
		return false
	ticket.transition_to("ACTIVE")
	_emit_ticket_update(ticket, 0.0)
	return true

func validate_handshake(player_freq: float, target_freq: float, ticket_id: String) -> bool:
	var ticket: Resource = active_tickets.get(ticket_id, null)
	if ticket != null:
		ticket.transition_to("VALIDATING")
		_emit_ticket_update(ticket, 0.5)
	if absf(player_freq - target_freq) < 0.05:
		return resolve_ticket(ticket_id)
	return false

func validate_relic(relic: Resource, ticket_id: String) -> bool:
	var ticket: Resource = active_tickets.get(ticket_id, null)
	if ticket == null or not ticket.requires_relic():
		return false
	ticket.transition_to("VALIDATING")
	_emit_ticket_update(ticket, 0.5)
	if relic.can_bypass(ticket.required_relic_code):
		return resolve_ticket(ticket_id)
	return false

func resolve_ticket(ticket_id: String) -> bool:
	var ticket: Resource = active_tickets.get(ticket_id, null)
	if ticket == null:
		return false
	ticket.transition_to("RESOLVED")
	sector_stabilized.emit(ticket.target_sector)
	ticket_resolved.emit(ticket_id)
	_emit_ticket_update(ticket, 1.0)
	_signal_bus_call("emit_ticket_resolved", [ticket_id])
	_signal_bus_call("emit_sector_stability_changed", [ticket.target_sector, 1.0])
	print("LOG: Integrity Restored for %s" % ticket_id)
	return true

func unresolved_tickets_for_sector(sector: Vector2i) -> Array:
	var results: Array = []
	for ticket in active_tickets.values():
		if ticket is Resource and ticket.target_sector == sector and not ticket.is_resolved:
			results.append(ticket)
	return results

func _emit_ticket_update(ticket: Resource, progress: float) -> void:
	var payload: Dictionary = ticket.progress_payload(progress)
	ticket_updated.emit(ticket.ticket_id, payload)
	_signal_bus_call("emit_ticket_updated", [ticket.ticket_id, payload])

func _signal_bus_call(method_name: String, args: Array) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null or tree.root == null:
		return
	var bus := tree.root.get_node_or_null("SignalBus")
	if bus == null or not bus.has_method(method_name):
		return
	bus.callv(method_name, args)
