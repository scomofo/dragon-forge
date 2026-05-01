extends RefCounted
class_name MissionData

const MISSIONS := {
	"mission_05": {
		"title": "The Great Heat Sync",
		"win_condition": "maintain_temp_equilibrium",
		"target_temp_celsius": 54.5,
		"failure_state": "partition_wipe",
		"reward_item": "sous_vide_breath",
	},
	"mission_06": {
		"title": "Mint-Condition Menagerie",
		"min_avg_grade": 9.5,
		"required_gem_mint": 3,
		"reward_item": "archivists_binder",
	},
	"mission_07": {
		"title": "The Long-Range Relay",
		"distance_km": 50,
		"target_cycle_minutes": 18,
		"reward_item": "e_pulse_harness",
	},
	"mission_08": {
		"title": "The Lunar Echo",
		"frequency_tolerance_hz": 5.0,
		"reward_item": "piano_key_map",
	},
	"mission_09": {
		"title": "The First Handshake",
		"sequence_prompt": ["E4", "G4", "A4", "C4", "D4"],
		"reward_item": "root_access",
		"failure_state": "packet_purge",
	},
	"mission_10": {
		"title": "Defragmenting the Deepwood",
		"required_tethers": 3,
		"reward_item": "deepwood_shortcuts",
	},
	"mission_11": {
		"title": "The Garbage Collector's Cull",
		"required_keep_alive_pings": 4,
		"reward_item": "whitelist_patch",
	},
	"mission_12": {
		"title": "The Kernel Breach",
		"required_permission_nodes": 3,
		"reward_item": "god_mode_fly",
	},
}

const LUMA_TONES := {
	"solar": { "label": "Solar", "note": "E4", "frequency": 329.63, "color": "#FFFF00" },
	"magma": { "label": "Magma", "note": "G4", "frequency": 392.00, "color": "#FF0000" },
	"lunar": { "label": "Lunar", "note": "A4", "frequency": 440.00, "color": "#C0C0C0" },
	"forest": { "label": "Forest", "note": "C4", "frequency": 261.63, "color": "#00FF00" },
	"static": { "label": "Static", "note": "D4", "frequency": 293.66, "color": "#00FFFF" },
}

static func get_mission(id: String) -> Dictionary:
	return MISSIONS.get(id, {}).duplicate(true)

static func evaluate_thermal_precision(samples: Array[float]) -> Dictionary:
	var target: float = MISSIONS["mission_05"]["target_temp_celsius"]
	var total := 0.0
	var max_deviation := 0.0
	for sample in samples:
		total += sample
		max_deviation = maxf(max_deviation, absf(sample - target))
	var average := total / maxf(1.0, samples.size())
	var success := absf(average - target) <= 0.35 and max_deviation <= 1.25
	return {
		"success": success,
		"average": average,
		"max_deviation": max_deviation,
		"target": target,
	}

static func grade_dragon(surface: float, corners: float, edges: float, centering: float) -> Dictionary:
	var average := (surface + corners + edges + centering) / 4.0
	return {
		"surface": surface,
		"corners": corners,
		"edges": edges,
		"centering": centering,
		"average": average,
		"is_gem_mint": average >= MISSIONS["mission_06"]["min_avg_grade"],
		"is_perfect": surface == 10.0 and corners == 10.0 and edges == 10.0 and centering == 10.0,
		"registry_value": roundi(average * average * 17.0),
	}

static func update_stamina_logic(stamina: float, charge_meter: float, input_intensity: float, has_tread_upgrade: bool = false) -> Dictionary:
	var in_band := input_intensity > 0.4 and input_intensity < 0.6
	var drain_rate := 0.35 if in_band and has_tread_upgrade else (0.5 if in_band else 1.0)
	var charge_gain := 1.5 if in_band and has_tread_upgrade else (1.0 if in_band else 0.0)
	return {
		"stamina": maxf(0.0, stamina - drain_rate),
		"charge_meter": minf(100.0, charge_meter + charge_gain),
		"drain_rate": drain_rate,
		"in_recovery_band": in_band,
	}

static func evaluate_relay_run(input_trace: Array[float]) -> Dictionary:
	var stamina := 100.0
	var charge := 0.0
	var recovery_ticks := 0
	for input in input_trace:
		var state := update_stamina_logic(stamina, charge, input)
		stamina = state["stamina"]
		charge = state["charge_meter"]
		if state["in_recovery_band"]:
			recovery_ticks += 1
	return {
		"success": stamina > 0.0 and recovery_ticks >= ceili(input_trace.size() * 0.55),
		"stamina": stamina,
		"charge_meter": charge,
		"recovery_ticks": recovery_ticks,
	}

static func check_audio_echo_match(target_frequency: float, dragon_roar_frequency: float) -> Dictionary:
	var delta := absf(target_frequency - dragon_roar_frequency)
	var success := delta < MISSIONS["mission_08"]["frequency_tolerance_hz"]
	return {
		"success": success,
		"delta": delta,
		"result": "CHORD_SPARK_TRIGGERED" if success else "ECHO_DRIFT",
	}

static func get_luma_tone(dragon_tone: String) -> Dictionary:
	return LUMA_TONES.get(dragon_tone, {}).duplicate(true)

static func get_handshake_prompt() -> Array[String]:
	var prompt: Array[String] = []
	for note in MISSIONS["mission_09"]["sequence_prompt"]:
		prompt.append(str(note))
	return prompt

static func evaluate_handshake_response(player_response: Array) -> Dictionary:
	var prompt := get_handshake_prompt()
	var normalized: Array[String] = []
	for note in player_response:
		normalized.append(str(note))
	var success := normalized == prompt
	var prefix_valid := true
	for i in normalized.size():
		if i >= prompt.size() or normalized[i] != prompt[i]:
			prefix_valid = false
			break
	return {
		"success": success,
		"prefix_valid": prefix_valid,
		"expected_next": prompt[normalized.size()] if normalized.size() < prompt.size() else "",
		"progress": normalized.size(),
		"required": prompt.size(),
	}

static func transpose_with_prism(source_tone: String, target_tone: String, stamina: float) -> Dictionary:
	var source := get_luma_tone(source_tone)
	var target := get_luma_tone(target_tone)
	var cost := 35.0
	if source.is_empty() or target.is_empty() or stamina < cost:
		return { "success": false, "note": "", "stamina": stamina, "color": "#000000" }
	return {
		"success": true,
		"note": target["note"],
		"stamina": stamina - cost,
		"color": target["color"],
	}

static func evaluate_defrag_tether(tethers: int, sector_integrity: float) -> Dictionary:
	var required: int = MISSIONS["mission_10"]["required_tethers"]
	var next_tethers: int = mini(required, tethers + 1)
	var next_integrity: float = minf(1.0, sector_integrity + 0.05)
	return {
		"success": next_tethers >= required,
		"tethers": next_tethers,
		"required": required,
		"sector_integrity": next_integrity,
	}

static func evaluate_keep_alive_ping(anchors: Array, anchor_id: String, sector_integrity: float) -> Dictionary:
	var required: int = MISSIONS["mission_11"]["required_keep_alive_pings"]
	var next_anchors := anchors.duplicate()
	if not next_anchors.has(anchor_id):
		next_anchors.append(anchor_id)
	return {
		"success": next_anchors.size() >= required,
		"anchors": next_anchors,
		"required": required,
		"sector_integrity": minf(1.0, sector_integrity + 0.04),
		"deletion_wall_distance": maxi(0, 100 - next_anchors.size() * 25),
	}

static func evaluate_kernel_permission(nodes: Array, node_id: String) -> Dictionary:
	var required: int = MISSIONS["mission_12"]["required_permission_nodes"]
	var next_nodes := nodes.duplicate()
	if not next_nodes.has(node_id):
		next_nodes.append(node_id)
	return {
		"success": next_nodes.size() >= required,
		"nodes": next_nodes,
		"required": required,
	}
