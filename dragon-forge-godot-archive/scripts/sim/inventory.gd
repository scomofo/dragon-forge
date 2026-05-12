extends Node
class_name Inventory

var digital_assets: Array = []
var analog_relics: Array = []
var physical_weight_kg := 0.0
var traction_modifier := 0.0
var flight_speed_modifier := 1.0

func add_item(item: Variant) -> void:
	if item is Resource and item.has_method("can_bypass"):
		analog_relics.append(item)
		_apply_physical_weight(item.weight_kg)
	else:
		digital_assets.append(item)

func use_relic(relic: Resource, target_gate: Dictionary) -> Dictionary:
	var required_code: String = target_gate.get("requires_code", "")
	if relic.can_bypass(required_code):
		var next_gate := target_gate.duplicate(true)
		next_gate["status"] = "PHYSICALLY_FORCED_OPEN"
		next_gate["is_unfixable_by_admin"] = true
		_signal_bus_call("emit_analog_relic_used", [relic.item_name, str(target_gate.get("id", "permission_gate"))])
		return {
			"success": true,
			"gate": next_gate,
			"sfx": "heavy_latch_open.wav",
		}
	return {
		"success": false,
		"gate": target_gate,
		"sfx": "relic_mismatch_click.wav",
	}

func has_relic_code(code: String) -> bool:
	for relic in analog_relics:
		if relic.can_bypass(code):
			return true
	return false

func find_relic_for_code(code: String) -> Resource:
	for relic in analog_relics:
		if relic.can_bypass(code):
			return relic
	return null

func _apply_physical_weight(weight_kg: float) -> void:
	physical_weight_kg += maxf(0.0, weight_kg)
	traction_modifier = clampf(physical_weight_kg * 0.01, 0.0, 0.35)
	flight_speed_modifier = clampf(1.0 - physical_weight_kg * 0.015, 0.55, 1.0)

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
