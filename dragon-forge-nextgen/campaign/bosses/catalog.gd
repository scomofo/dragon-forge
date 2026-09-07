extends RefCounted
## Visual identity only. All encounter damage, thresholds and locked shapes stay in campaign rules.
const ORDER = ["outer-boss", "frozen-boss", "storm-boss", "admin-boss", "singularity-final"]
const ASSET_IDS = ["buffer_overflow", "memory_leak", "stack_overflow", "mirror_admin", "singularity"]
const ROOMS = ["overflow-vent", "memory-vault", "logic-core", "protocol-throne", "singularity"]
const ENTRIES = {
	"outer-boss": {"asset":"buffer_overflow", "name":"Buffer Overflow", "height":2.75, "core_height":1.43, "element":"fire", "silhouette":"tracked furnace / paired rams", "moves":{"slam":"RAM IMPACT", "ring":"PRESSURE VENT"}},
	"frozen-boss": {"asset":"memory_leak", "name":"Memory Leak", "height":3.55, "core_height":2.11, "element":"ice", "silhouette":"cryo bell / hanging memory ribbons", "moves":{"beam":"ARCHIVE LANCE", "slam":"COLD SNAP"}},
	"storm-boss": {"asset":"stack_overflow", "name":"Stack Overflow", "height":4.0, "core_height":1.88, "element":"storm", "silhouette":"offset compute tower / three emitters", "moves":{"fan":"TRIPLE FAULT", "beam":"STACK TRACE"}},
	"admin-boss": {"asset":"mirror_admin", "name":"Mirror Admin", "height":3.55, "core_height":2.04, "element":"storm", "silhouette":"mirror mantle / chest eye / seal", "moves":{"ring":"ACCESS DENIED", "beam":"AUDIT RAY", "fan":"REVOKE"}},
	"singularity-final": {"asset":"singularity", "name":"The Singularity", "height":4.4, "core_height":1.93, "element":"storm", "silhouette":"hollow cage / gyroscopes / star", "moves":{"ring":"EVENT HORIZON", "beam":"CORE RAY", "fan":"FRAGMENTATION"}}
}

static func known(id: String) -> bool:
	return ENTRIES.has(id)

static func entry(id: String) -> Dictionary:
	return ENTRIES.get(id, {})

static func move_name(id: String, pattern: String) -> String:
	return ENTRIES.get(id, {}).get("moves", {}).get(pattern, pattern.to_upper())

static func phase(id: String, hp: float, max_hp: float) -> int:
	if max_hp <= 0.0: return 1
	if id == "singularity-final":
		return 1 if hp > max_hp * 0.66 else (2 if hp > max_hp * 0.33 else 3)
	return 2 if hp <= max_hp * 0.5 else 1
