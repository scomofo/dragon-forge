extends RefCounted
class_name ActOneFinaleData

const REQUIRED_WRENCH_CODE := "10MM-WRENCH"
const DESTINATION_TUNDRA := "tundra_of_silicon"

const BOUNTY_HUNTERS := {
	"latency_stalker": {
		"name": "Latency Stalker",
		"kind": "subroutine_stalker",
		"server_whine_hz": 11840.0,
		"leech_rate": 0.18,
		"vulnerable_window": Vector2(0.20, 0.34),
		"description": "A translucent wireframe ghost dragon that stabilizes for a heartbeat before snapping back into latency.",
	},
}

const WEAVER_RECIPES := {
	"friction_saddle": {
		"name": "Friction Saddle",
		"inputs": ["digital_silk", "steel_bolt"],
		"relic": REQUIRED_WRENCH_CODE,
		"result_item": "friction_saddle",
		"stat_effects": {
			"traction": 0.35,
			"high_speed_drift": -0.20,
		},
		"description": "Digital silk and analog fasteners bite into the dragon's saddle rig during high-speed dives.",
	},
	"diagnostic_visor": {
		"name": "Diagnostic Visor",
		"inputs": ["fragmented_code", "optical_lens"],
		"relic": "OPTICAL-LENS",
		"result_item": "diagnostic_visor",
		"stat_effects": {
			"invisible_hunter_visibility": 1.0,
		},
		"description": "A visor that reveals Sub-routine Stalkers during their invisible latency phase.",
	},
	"thermal_whip": {
		"name": "Thermal Whip",
		"inputs": ["magma_scale", "copper"],
		"relic": "FIBER-TETHER",
		"result_item": "thermal_whip",
		"stat_effects": {
			"draft_lasso": 1.0,
			"speed_boost": 0.18,
		},
		"description": "A mid-air tether that hooks data-drafts and snaps Magma-Core flight into a hotter line.",
	},
}

static func create_bounty_hunter(id: String) -> Dictionary:
	var template: Dictionary = BOUNTY_HUNTERS.get(id, BOUNTY_HUNTERS["latency_stalker"])
	var hunter := template.duplicate(true)
	hunter["id"] = id
	hunter["latency_phase"] = 0.0
	hunter["can_be_hit"] = false
	hunter["coordination_group"] = "mirror_admin_bounty_hunters"
	return hunter

static func update_latency(hunter: Dictionary, delta: float) -> Dictionary:
	var next := hunter.duplicate(true)
	var phase := fmod(float(next.get("latency_phase", 0.0)) + delta, 1.0)
	next["latency_phase"] = phase
	var window: Vector2 = next.get("vulnerable_window", Vector2(0.20, 0.34))
	next["can_be_hit"] = phase >= window.x and phase <= window.y
	next["latency_label"] = "STABILIZED" if next["can_be_hit"] else "PHASED"
	return next

static func apply_data_leech(dragon_state: Dictionary, leech_amount: float) -> Dictionary:
	var next := dragon_state.duplicate(true)
	var integrity := maxf(0.0, float(next.get("compile_integrity", 1.0)) - leech_amount)
	next["compile_integrity"] = integrity
	next["reversion_risk"] = integrity <= 0.25
	if integrity <= 0.0:
		next["dragon_form"] = "root_dragon"
		next["reverted"] = true
	else:
		next["reverted"] = false
	return next

static func apply_physical_override(gate: Dictionary, relic_code: String) -> Dictionary:
	var next_gate := gate.duplicate(true)
	var required := str(next_gate.get("requires_relic_code", REQUIRED_WRENCH_CODE))
	var success := relic_code == required
	if success:
		next_gate["status"] = "PHYSICAL_BYPASS_OPEN"
		next_gate["firewall_alpha"] = 0.0
		next_gate["is_unfixable_by_admin"] = true
		next_gate["digital_firewall_detects_breach"] = false
	return {
		"success": success,
		"gate": next_gate,
		"result": "MANUAL_OVERRIDE_ACCEPTED" if success else "WRONG_ANALOG_TOOL",
	}

static func get_weaver_recipe(id: String) -> Dictionary:
	return WEAVER_RECIPES.get(id, {}).duplicate(true)

static func evaluate_breakout_sequence(has_friction_saddle: bool, hunters_evaded: int, gate_overridden: bool) -> Dictionary:
	var success := has_friction_saddle and hunters_evaded >= 3 and gate_overridden
	return {
		"success": success,
		"destination": DESTINATION_TUNDRA if success else "southern_partition",
		"mirror_admin_response": "BOUNTY_ESCALATION" if success else "PURSUIT_CONTINUES",
		"requirements": {
			"friction_saddle": has_friction_saddle,
			"hunters_evaded": hunters_evaded,
			"gate_overridden": gate_overridden,
		},
	}
