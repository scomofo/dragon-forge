# save_io.gd — autoload: SaveIO
# Single source of truth for the player save Dictionary.
# All game code reads from SaveIO.save and persists via SaveIO.flush().
# save_data.gd is kept as a browser-mirror Resource schema; not used here.
extends Node

const SAVE_PATH := "user://dragon_forge_save.json"
const SCHEMA_VERSION := 3

const DEFAULT_SAVE := {
	"dragon_id": "fire",
	"dragon_levels": { "fire": 1 },
	"dragon_xp": { "fire": 0 },
	"dragon_techniques": { "fire": ["magma_breath"] },
	"dragon_loadouts": { "fire": ["magma_breath"] },
	"data_scraps": 320,
	"system_credits": 0,
	"known_techniques": ["magma_breath"],
	"active_techniques": ["magma_breath"],
	"key_items": [],
	"mission_flags": [],
	"captains_log_fragments": [],
	"equipped_anvil_relics": [],
	"hatchery_state": {
		"opened": false,
		"owned_dragons": ["fire"],
		"visit_count": 0,
		"last_ring": "",
		"pity_counter": 0,
	},
	"bestiary_seen": {},
	"bestiary_defeated": {},
	"inventory": {},
	"stats": {},
	"records": {},
	"journal": { "claimedMilestones": [] },
	"settings_music": true,
	"settings_sfx": true,
	"version": SCHEMA_VERSION,
}

# The live save. All screens read this; call flush() after mutations.
var save: Dictionary = {}

func _ready() -> void:
	save = _load_or_create()

# ── Public API ────────────────────────────────────────────────────────────────

## Write updated_save to disk and update SaveIO.save.
## Pass no argument to re-flush the current save without replacing it.
func flush(updated_save: Dictionary = {}) -> void:
	if not updated_save.is_empty():
		save = updated_save.duplicate(true)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveIO.flush: cannot open save file for writing.")
		return
	file.store_string(JSON.stringify(save, "\t"))
	file.close()

## Overwrite with a fresh default and flush.
func reset() -> void:
	save = DEFAULT_SAVE.duplicate(true)
	flush()

# ── Internal ──────────────────────────────────────────────────────────────────

func _load_or_create() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return DEFAULT_SAVE.duplicate(true)
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return DEFAULT_SAVE.duplicate(true)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveIO: corrupt save file — starting fresh.")
		return DEFAULT_SAVE.duplicate(true)
	var result := DEFAULT_SAVE.duplicate(true)
	for key in parsed:
		result[key] = parsed[key]
	return _sanitize(result)

# Unconditional shape repair — the DEFAULT_SAVE merge above only covers
# missing top-level keys, not keys present with the wrong type (e.g. a
# hand-edited "hatchery_state": null), which would otherwise crash every
# consumer on every launch. Runs on every load.
func _sanitize(s: Dictionary) -> Dictionary:
	if typeof(s.get("hatchery_state")) != TYPE_DICTIONARY:
		s["hatchery_state"] = DEFAULT_SAVE["hatchery_state"].duplicate(true)
	if typeof(s["hatchery_state"].get("owned_dragons")) != TYPE_ARRAY:
		s["hatchery_state"]["owned_dragons"] = ["fire"]
	if typeof(s.get("dragon_levels")) != TYPE_DICTIONARY:
		s["dragon_levels"] = DEFAULT_SAVE["dragon_levels"].duplicate(true)
	if typeof(s.get("dragon_xp")) != TYPE_DICTIONARY:
		s["dragon_xp"] = DEFAULT_SAVE["dragon_xp"].duplicate(true)
	if typeof(s.get("mission_flags")) != TYPE_ARRAY:
		s["mission_flags"] = []
	if not s["dragon_levels"].has("light"):
		s["dragon_levels"]["light"] = 1
		s["dragon_xp"]["light"] = 0
	s["version"] = SCHEMA_VERSION
	# Load-time grant, mirroring the browser (persistence.js): saves that
	# contained the Singularity before this unlock existed get it on load.
	return DragonProgression.apply_singularity_unlocks(s)
