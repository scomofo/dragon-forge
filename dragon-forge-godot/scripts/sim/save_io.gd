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
	"singularity_defeated": [],
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
	return _migrate(result)

func _migrate(s: Dictionary) -> Dictionary:
	var v: int = int(s.get("version", 1))
	if v < 3:
		# v3: ensure 'light' dragon entries exist
		var levels: Dictionary = s.get("dragon_levels", {})
		if not levels.has("light"):
			s["dragon_levels"]["light"] = 1
			s["dragon_xp"]["light"] = 0
		# Ensure hatchery_state is a proper dict
		if typeof(s.get("hatchery_state")) != TYPE_DICTIONARY:
			s["hatchery_state"] = DEFAULT_SAVE["hatchery_state"].duplicate(true)
		s["version"] = 3
		push_warning("SaveIO: migrated save to v3")
	return s
