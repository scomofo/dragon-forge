extends RefCounted
class_name DragonProgression

const TechniqueData := preload("res://scripts/sim/technique_data.gd")

const STARTING_TECHNIQUES := {
	"fire": ["blazingFang"],
	"shadow": ["nightNeedle"],
	"stone": ["quakeWing"],
	"venom": ["nightNeedle"],
}

const MAX_LOADOUT_TECHNIQUES := 3
const MAX_ANVIL_RELICS := 2

const ANVIL_RELICS := {
	"10mm_wrench": {
		"id": "10mm_wrench",
		"label": "10mm Wrench",
		"required_item": "10mm_wrench",
		"gear_label": "10mm Wrench",
		"benefit": "Manual override, access-port bolts, field repairs",
		"icon": "W",
		"overworld_effect": "Traction checks and physical bypasses",
		"dungeon_effect": "Bolts, valves, shielded ports",
		"palette": Color("#ffd166"),
	},
	"optical_lens": {
		"id": "optical_lens",
		"label": "Optical Lens",
		"required_item": "optical_lens",
		"gear_label": "Refractive Plate",
		"benefit": "Security-node reads and diagnostic light routing",
		"icon": "O",
		"overworld_effect": "Stalker avoidance and route reveal",
		"dungeon_effect": "Hidden nodes, lasers, data beams",
		"palette": Color("#58dbff"),
	},
	"friction_saddle": {
		"id": "friction_saddle",
		"label": "Friction Saddle",
		"required_item": "friction_saddle",
		"gear_label": "Friction Harness",
		"benefit": "Dive traction and sharper overworld turns",
		"icon": "F",
		"overworld_effect": "Sharper dives and high-speed turns",
		"dungeon_effect": "Pipe grip and wall-slide control",
		"palette": Color("#70ff8f"),
	},
	"obsidian_shell": {
		"id": "obsidian_shell",
		"label": "Obsidian Shell",
		"required_item": "obsidian_shell",
		"gear_label": "Obsidian Shell",
		"benefit": "Thermal exhaust and steam trap protection",
		"icon": "M",
		"overworld_effect": "Thermal exhaust stability",
		"dungeon_effect": "Fire-pipe and steam immunity",
		"palette": Color("#ff8a4c"),
	},
	"silicon_padded_gear": {
		"id": "silicon_padded_gear",
		"label": "Silicon Padded Gear",
		"required_item": "silicon_padded_gear",
		"gear_label": "Silicon Padded Gear",
		"benefit": "Static discharge and input-lag dampening",
		"icon": "S",
		"overworld_effect": "Integrity buffer against static",
		"dungeon_effect": "Reduced lag on corrupt floor tiles",
		"palette": Color("#b7fffb"),
	},
}

static func create_profile(dragon_id: String = "fire") -> Dictionary:
	var starting: Array = STARTING_TECHNIQUES.get(dragon_id, []).duplicate()
	return {
		"dragon_id": dragon_id,
		"dragon_levels": { dragon_id: 1 },
		"dragon_xp": { dragon_id: 0 },
		"dragon_techniques": { dragon_id: starting.duplicate() },
		"dragon_loadouts": { dragon_id: _default_loadout(starting) },
		"data_scraps": 320,
		"system_credits": 0,
		"known_techniques": starting,
		"active_techniques": _default_loadout(starting),
		"key_items": [],
		"mission_flags": [],
		"captains_log_fragments": [],
		"equipped_anvil_relics": [],
		"hatchery_state": {
			"opened": false,
			"owned_dragons": [dragon_id],
			"visit_count": 0,
			"last_ring": "",
		},
		"bestiary_seen": {},
		"bestiary_defeated": {},
	}

static func switch_dragon(profile: Dictionary, dragon_id: String) -> Dictionary:
	var next := _sync_active_dragon_records(profile.duplicate(true))
	if not next.has("dragon_techniques"):
		next["dragon_techniques"] = {}
	if not next.has("dragon_loadouts"):
		next["dragon_loadouts"] = {}
	if not next["dragon_techniques"].has(dragon_id):
		var starting: Array = STARTING_TECHNIQUES.get(dragon_id, []).duplicate()
		next["dragon_techniques"][dragon_id] = starting
		next["dragon_loadouts"][dragon_id] = _default_loadout(starting)
	next["dragon_id"] = dragon_id
	if not next["dragon_levels"].has(dragon_id):
		next["dragon_levels"][dragon_id] = 1
	if not next["dragon_xp"].has(dragon_id):
		next["dragon_xp"][dragon_id] = 0
	next["known_techniques"] = next["dragon_techniques"][dragon_id].duplicate()
	next["active_techniques"] = next["dragon_loadouts"].get(dragon_id, _default_loadout(next["known_techniques"])).duplicate()
	return next

static func can_learn(profile: Dictionary, technique_id: String) -> bool:
	var technique := TechniqueData.get_technique(technique_id)
	if technique.is_empty():
		return false
	if profile["known_techniques"].has(technique_id):
		return false
	if not technique["dragon_types"].has(profile["dragon_id"]):
		return false
	return profile["data_scraps"] >= technique["scrap_cost"]

static func learn_technique(profile: Dictionary, technique_id: String) -> Dictionary:
	if not can_learn(profile, technique_id):
		return profile

	var next := profile.duplicate(true)
	var technique := TechniqueData.get_technique(technique_id)
	next["data_scraps"] -= technique["scrap_cost"]
	next["known_techniques"].append(technique_id)
	next = _auto_equip_if_room(next, technique_id)
	next = _sync_active_dragon_records(next)
	return next

static func grant_technique(profile: Dictionary, technique_id: String) -> Dictionary:
	var technique := TechniqueData.get_technique(technique_id)
	if technique.is_empty():
		return profile
	var next := profile.duplicate(true)
	if not next.has("known_techniques"):
		next["known_techniques"] = []
	if not next["known_techniques"].has(technique_id):
		next["known_techniques"].append(technique_id)
	next = _auto_equip_if_room(next, technique_id)
	next = _sync_active_dragon_records(next)
	return next

static func get_active_techniques(profile: Dictionary) -> Array[String]:
	var typed: Array[String] = []
	var known: Array = profile.get("known_techniques", [])
	for technique_id in profile.get("active_techniques", []):
		if known.has(technique_id):
			typed.append(str(technique_id))
	if typed.is_empty():
		for technique_id in known.slice(0, MAX_LOADOUT_TECHNIQUES):
			typed.append(str(technique_id))
	return typed

static func toggle_loadout_technique(profile: Dictionary, technique_id: String) -> Dictionary:
	if not profile.get("known_techniques", []).has(technique_id):
		return profile
	var next := profile.duplicate(true)
	if not next.has("active_techniques"):
		next["active_techniques"] = []
	if next["active_techniques"].has(technique_id):
		if next["active_techniques"].size() > 1:
			next["active_techniques"].erase(technique_id)
		return _sync_active_dragon_records(next)
	if next["active_techniques"].size() < MAX_LOADOUT_TECHNIQUES:
		next["active_techniques"].append(technique_id)
	return _sync_active_dragon_records(next)

static func is_technique_equipped(profile: Dictionary, technique_id: String) -> bool:
	return get_active_techniques(profile).has(technique_id)

static func award_scraps(profile: Dictionary, amount: int) -> Dictionary:
	var next := profile.duplicate(true)
	next["data_scraps"] = maxi(0, next.get("data_scraps", 0) + amount)
	return next

static func award_dragon_xp(profile: Dictionary, amount: int) -> Dictionary:
	var next := profile.duplicate(true)
	var dragon_id: String = next.get("dragon_id", "fire")
	if not next.has("dragon_levels"):
		next["dragon_levels"] = { dragon_id: 1 }
	if not next.has("dragon_xp"):
		next["dragon_xp"] = { dragon_id: 0 }
	var levels: Dictionary = next["dragon_levels"]
	var xp_by_dragon: Dictionary = next["dragon_xp"]
	var level: int = int(levels.get(dragon_id, 1))
	var xp: int = int(xp_by_dragon.get(dragon_id, 0)) + maxi(0, amount)
	while xp >= xp_to_next_level(level):
		xp -= xp_to_next_level(level)
		level += 1
	levels[dragon_id] = level
	xp_by_dragon[dragon_id] = xp
	next["dragon_levels"] = levels
	next["dragon_xp"] = xp_by_dragon
	return next

static func get_dragon_level(profile: Dictionary, dragon_id: String = "") -> int:
	var resolved_id: String = dragon_id if dragon_id != "" else str(profile.get("dragon_id", "fire"))
	return int(profile.get("dragon_levels", {}).get(resolved_id, 1))

static func get_dragon_xp(profile: Dictionary, dragon_id: String = "") -> int:
	var resolved_id: String = dragon_id if dragon_id != "" else str(profile.get("dragon_id", "fire"))
	return int(profile.get("dragon_xp", {}).get(resolved_id, 0))

static func xp_to_next_level(level: int) -> int:
	return 90 + maxi(1, level) * 35

static func award_system_credits(profile: Dictionary, amount: int) -> Dictionary:
	var next := profile.duplicate(true)
	next["system_credits"] = maxi(0, next.get("system_credits", 0) + amount)
	return next

static func grant_key_item(profile: Dictionary, item_id: String) -> Dictionary:
	var next := profile.duplicate(true)
	if not next.has("key_items"):
		next["key_items"] = []
	if not next["key_items"].has(item_id):
		next["key_items"].append(item_id)
	return next

static func has_key_item(profile: Dictionary, item_id: String) -> bool:
	return profile.get("key_items", []).has(item_id)

static func set_mission_flag(profile: Dictionary, flag_id: String) -> Dictionary:
	var next := profile.duplicate(true)
	if not next.has("mission_flags"):
		next["mission_flags"] = []
	if not next["mission_flags"].has(flag_id):
		next["mission_flags"].append(flag_id)
	return next

static func has_mission_flag(profile: Dictionary, flag_id: String) -> bool:
	return profile.get("mission_flags", []).has(flag_id)

static func unlock_captains_log_fragment(profile: Dictionary, fragment: Dictionary) -> Dictionary:
	if fragment.is_empty():
		return profile
	var next := profile.duplicate(true)
	if not next.has("captains_log_fragments"):
		next["captains_log_fragments"] = []
	var fragment_id := str(fragment.get("id", ""))
	if fragment_id != "" and not next["captains_log_fragments"].has(fragment_id):
		next["captains_log_fragments"].append(fragment_id)
	var save_flag := str(fragment.get("save_flag", ""))
	if save_flag != "":
		next = set_mission_flag(next, save_flag)
	return next

static func has_captains_log_fragment(profile: Dictionary, fragment_id: String) -> bool:
	return profile.get("captains_log_fragments", []).has(fragment_id)

static func get_available_anvil_relics(profile: Dictionary) -> Array:
	var available: Array = []
	for relic_id in ANVIL_RELICS.keys():
		var relic: Dictionary = ANVIL_RELICS[relic_id]
		if has_key_item(profile, str(relic.get("required_item", relic_id))):
			available.append(relic.duplicate(true))
	return available

static func get_equipped_anvil_relics(profile: Dictionary) -> Array:
	var available_ids := {}
	for relic in get_available_anvil_relics(profile):
		available_ids[str(relic.get("id", ""))] = true
	var equipped: Array = []
	for relic_id in profile.get("equipped_anvil_relics", []):
		var id := str(relic_id)
		if available_ids.has(id) and not equipped.has(id) and equipped.size() < get_anvil_relic_slots(profile):
			equipped.append(id)
	return equipped

static func toggle_anvil_relic(profile: Dictionary, relic_id: String) -> Dictionary:
	var next := profile.duplicate(true)
	var available_ids := {}
	for relic in get_available_anvil_relics(next):
		available_ids[str(relic.get("id", ""))] = true
	if not available_ids.has(relic_id):
		return next
	var equipped: Array = get_equipped_anvil_relics(next)
	if equipped.has(relic_id):
		equipped.erase(relic_id)
	elif equipped.size() < get_anvil_relic_slots(next):
		equipped.append(relic_id)
	else:
		equipped[equipped.size() - 1] = relic_id
	next["equipped_anvil_relics"] = equipped
	return next

static func apply_anvil_relic_kit(profile: Dictionary, required_tool_ids: Array) -> Dictionary:
	var next := profile.duplicate(true)
	var available_ids := {}
	for relic in get_available_anvil_relics(next):
		available_ids[str(relic.get("id", ""))] = true
	var slots := get_anvil_relic_slots(next)
	var equipped: Array = []
	var missing: Array[String] = []
	for tool_id in required_tool_ids:
		var id := str(tool_id)
		if not available_ids.has(id):
			missing.append(id)
			continue
		if not equipped.has(id) and equipped.size() < slots:
			equipped.append(id)
	for relic_id in get_equipped_anvil_relics(next):
		var id := str(relic_id)
		if equipped.size() >= slots:
			break
		if available_ids.has(id) and not equipped.has(id):
			equipped.append(id)
	next["equipped_anvil_relics"] = equipped
	return {
		"profile": next,
		"presentation": "anvil_quick_socket_kit",
		"requested_tools": required_tool_ids.duplicate(),
		"socketed_tools": equipped.duplicate(),
		"missing_tools": missing,
		"ready": missing.is_empty(),
		"slot_count": slots,
		"status_label": "KIT SOCKETED" if missing.is_empty() else "KIT INCOMPLETE",
	}

static func is_anvil_relic_equipped(profile: Dictionary, relic_id: String) -> bool:
	return get_equipped_anvil_relics(profile).has(relic_id)

static func get_carried_anvil_gear_labels(profile: Dictionary) -> Array[String]:
	var labels: Array[String] = []
	for relic_id in get_equipped_anvil_relics(profile):
		var relic: Dictionary = ANVIL_RELICS.get(str(relic_id), {})
		var gear_label := str(relic.get("gear_label", ""))
		if gear_label != "" and not labels.has(gear_label):
			labels.append(gear_label)
	return labels

static func get_carried_anvil_tool_ids(profile: Dictionary) -> Array[String]:
	var tools: Array[String] = []
	for relic_id in get_equipped_anvil_relics(profile):
		var tool_id := str(relic_id)
		if tool_id != "" and not tools.has(tool_id):
			tools.append(tool_id)
	return tools

static func get_anvil_utility_belt_profile(profile: Dictionary) -> Dictionary:
	var tools := get_carried_anvil_tool_ids(profile)
	var slots := get_anvil_relic_slots(profile)
	var over := maxi(0, tools.size() - slots)
	return {
		"presentation": "anvil_to_dungeon_utility_belt",
		"tool_ids": tools,
		"equipped_tools": tools.slice(0, mini(tools.size(), slots)),
		"slot_count": slots,
		"slots_used": tools.size(),
		"valid": over == 0,
		"over_capacity": over,
		"carried_gear": get_carried_anvil_gear_labels(profile),
		"entry_label": "%d/%d ANALOG RELICS" % [mini(tools.size(), slots), slots],
	}

static func get_anvil_relic_ui_profile(profile: Dictionary) -> Dictionary:
	var available: Array = get_available_anvil_relics(profile)
	var equipped: Array = get_equipped_anvil_relics(profile)
	var slots: int = get_anvil_relic_slots(profile)
	var entries: Array = []
	var slot_rows: Array = []
	for slot_index in range(slots):
		var relic_id_in_slot: String = str(equipped[slot_index]) if slot_index < equipped.size() else ""
		var relic_in_slot: Dictionary = ANVIL_RELICS.get(relic_id_in_slot, {})
		slot_rows.append({
			"slot": slot_index + 1,
			"filled": relic_id_in_slot != "",
			"relic_id": relic_id_in_slot,
			"label": relic_in_slot.get("label", "EMPTY SOCKET") if relic_id_in_slot != "" else "EMPTY SOCKET",
			"gear_label": relic_in_slot.get("gear_label", "") if relic_id_in_slot != "" else "No field gear carried",
			"socket_icon": relic_in_slot.get("icon", "-") if relic_id_in_slot != "" else "-",
			"effect_label": relic_in_slot.get("dungeon_effect", "Awaiting scanned analog relic") if relic_id_in_slot != "" else "Awaiting scanned analog relic",
			"socket_color": relic_in_slot.get("palette", Color("#70ff8f")) if relic_id_in_slot != "" else Color("#8fe6ff"),
		})
	for relic in available:
		var relic_id: String = str(relic.get("id", ""))
		var is_equipped: bool = equipped.has(relic_id)
		var can_equip: bool = is_equipped or equipped.size() < slots
		var state_label: String = "CARRIED" if is_equipped else "READY" if can_equip else "SWAP"
		entries.append({
			"id": relic_id,
			"label": relic.get("label", relic_id),
			"gear_label": relic.get("gear_label", ""),
			"benefit": relic.get("benefit", ""),
			"icon": relic.get("icon", "?"),
			"overworld_effect": relic.get("overworld_effect", ""),
			"dungeon_effect": relic.get("dungeon_effect", ""),
			"equipped": is_equipped,
			"can_toggle": true,
			"button_label": "%s %s" % ["UNEQUIP" if is_equipped else "EQUIP" if can_equip else "SWAP IN", relic.get("label", relic_id)],
			"state_label": state_label,
			"state_color": relic.get("palette", Color("#70ff8f")) if is_equipped else Color("#ffd166") if can_equip else Color("#ff594d"),
			"disabled_reason": "" if can_equip else "Utility belt slots full. Swapping replaces the oldest carried relic.",
			"loadout_summary": "%s / %s" % [relic.get("overworld_effect", ""), relic.get("dungeon_effect", "")],
		})
	return {
		"title": "ANVIL RELIC LOADOUT",
		"available_count": available.size(),
		"equipped_count": equipped.size(),
		"slot_count": slots,
		"slots_used_label": "%d/%d" % [equipped.size(), slots],
		"slot_pressure": float(equipped.size()) / float(maxi(1, slots)),
		"slot_rows": slot_rows,
		"carried_gear": get_carried_anvil_gear_labels(profile),
		"entries": entries,
		"empty_label": "No analog relics are scanned into the anvil yet.",
		"belt_rule": "Choose which physical tools Skye carries into side-scrolling hardware dungeons.",
		"upgrade_hint": "Unit 01 save link adds a third relic slot." if not has_key_item(profile, "unit_01_save_link") else "Unit 01 save link installed.",
		"footer_prompt": "SPACE toggles scanned relics; full belts swap the oldest socket.",
		"chrome_style": {
			"panel_kind": "anvil_socket_rack",
			"border_color": Color("#ffd166"),
			"fill_color": Color("#121820"),
			"scanline_alpha": 0.08,
			"corner_cut": 5.0,
		},
	}

static func get_anvil_relic_slots(profile: Dictionary) -> int:
	return MAX_ANVIL_RELICS + (1 if has_key_item(profile, "unit_01_save_link") else 0)

static func open_hatchery_ring(profile: Dictionary, ring_id: String = "quantum_incubation_ring") -> Dictionary:
	var next := set_mission_flag(profile, "hatchery_ring_opened")
	var state: Dictionary = next.get("hatchery_state", {}).duplicate(true)
	var dragon_id := str(next.get("dragon_id", "fire"))
	if not state.has("owned_dragons"):
		state["owned_dragons"] = []
	if not state["owned_dragons"].has(dragon_id):
		state["owned_dragons"].append(dragon_id)
	state["opened"] = true
	state["last_ring"] = ring_id
	state["visit_count"] = int(state.get("visit_count", 0)) + 1
	next["hatchery_state"] = state
	return next

static func get_hatchery_state(profile: Dictionary) -> Dictionary:
	var state: Dictionary = profile.get("hatchery_state", {}).duplicate(true)
	var dragon_id := str(profile.get("dragon_id", "fire"))
	if not state.has("owned_dragons"):
		state["owned_dragons"] = [dragon_id]
	if not state.has("opened"):
		state["opened"] = has_mission_flag(profile, "hatchery_ring_opened")
	if not state.has("visit_count"):
		state["visit_count"] = 0
	if not state.has("last_ring"):
		state["last_ring"] = ""
	return state

static func get_hatchery_ring_ui_profile(profile: Dictionary) -> Dictionary:
	var state: Dictionary = get_hatchery_state(profile)
	var owned: Array = state.get("owned_dragons", [])
	var opened: bool = bool(state.get("opened", false))
	var visit_count: int = int(state.get("visit_count", 0))
	var ring_id: String = str(state.get("last_ring", "quantum_incubation_ring"))
	return {
		"title": "HATCHERY RING",
		"ring_id": ring_id,
		"opened": opened,
		"owned_dragons": owned.duplicate(true),
		"owned_count": owned.size(),
		"visit_count": visit_count,
		"status_label": "ONLINE" if opened else "SEALED",
		"registry_label": "%d dragon protocol%s" % [owned.size(), "" if owned.size() == 1 else "s"],
		"visit_label": "%d visit%s logged" % [visit_count, "" if visit_count == 1 else "s"],
		"next_action": "Review dragon registry" if opened else "Open Hatchery Ring",
		"presentation": "quantum_incubation_registry",
		"accent_color": Color("#c0c8ff") if opened else Color("#8fe6ff"),
		"chrome_style": {
			"panel_kind": "incubation_ring_registry",
			"border_color": Color("#c0c8ff") if opened else Color("#8fe6ff"),
			"fill_color": Color("#11172d"),
			"scanline_alpha": 0.06,
			"corner_cut": 7.0,
		},
	}

static func record_gem_mint_capture(profile: Dictionary) -> Dictionary:
	var next := profile.duplicate(true)
	next["gem_mint_captures"] = next.get("gem_mint_captures", 0) + 1
	return next

static func record_enemy_seen(profile: Dictionary, enemy_id: String) -> Dictionary:
	var next := profile.duplicate(true)
	if not next.has("bestiary_seen"):
		next["bestiary_seen"] = {}
	next["bestiary_seen"][enemy_id] = int(next["bestiary_seen"].get(enemy_id, 0)) + 1
	return next

static func record_enemy_defeated(profile: Dictionary, enemy_id: String) -> Dictionary:
	var next := record_enemy_seen(profile, enemy_id)
	if not next.has("bestiary_defeated"):
		next["bestiary_defeated"] = {}
	next["bestiary_defeated"][enemy_id] = int(next["bestiary_defeated"].get(enemy_id, 0)) + 1
	return next

static func get_seen_count(profile: Dictionary, enemy_id: String) -> int:
	return int(profile.get("bestiary_seen", {}).get(enemy_id, 0))

static func get_defeated_count(profile: Dictionary, enemy_id: String) -> int:
	return int(profile.get("bestiary_defeated", {}).get(enemy_id, 0))

static func _default_loadout(known_techniques: Array) -> Array:
	return known_techniques.slice(0, MAX_LOADOUT_TECHNIQUES)

static func _auto_equip_if_room(profile: Dictionary, technique_id: String) -> Dictionary:
	var next := profile.duplicate(true)
	if not next.has("active_techniques"):
		next["active_techniques"] = _default_loadout(next.get("known_techniques", []))
	if not next["active_techniques"].has(technique_id) and next["active_techniques"].size() < MAX_LOADOUT_TECHNIQUES:
		next["active_techniques"].append(technique_id)
	return next

static func _sync_active_dragon_records(profile: Dictionary) -> Dictionary:
	var next := profile.duplicate(true)
	var dragon_id: String = str(next.get("dragon_id", "fire"))
	if not next.has("dragon_levels"):
		next["dragon_levels"] = { dragon_id: 1 }
	if not next.has("dragon_xp"):
		next["dragon_xp"] = { dragon_id: 0 }
	if not next.has("dragon_techniques"):
		next["dragon_techniques"] = {}
	if not next.has("dragon_loadouts"):
		next["dragon_loadouts"] = {}
	var known: Array = next.get("known_techniques", STARTING_TECHNIQUES.get(dragon_id, []).duplicate())
	var active: Array = next.get("active_techniques", _default_loadout(known))
	next["dragon_techniques"][dragon_id] = known.duplicate()
	next["dragon_loadouts"][dragon_id] = active.duplicate()
	return next
