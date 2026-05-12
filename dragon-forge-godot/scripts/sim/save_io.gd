# save_io.gd — autoload: SaveIO
# Manages the single player save at user://save.tres.
# Exposes: SaveIO.save  (current SaveData)
#          SaveIO.flush()      — write to disk
#          SaveIO.reset()      — overwrite with DEFAULT_SAVE
extends Node

const SAVE_PATH := "user://save.tres"

# The live save object. All game code reads/writes this.
var save: SaveData = null

func _ready() -> void:
	save = _load_or_create()

# ── Public API ────────────────────────────────────────────────────────────

## Write the current save to disk.
func flush() -> void:
	var err := ResourceSaver.save(save, SAVE_PATH)
	if err != OK:
		push_error("SaveIO.flush: ResourceSaver failed with error %d" % err)

## Overwrite save with a fresh default and flush.
func reset() -> void:
	save = SaveData.make_default()
	flush()

# ── Internal ─────────────────────────────────────────────────────────────

func _load_or_create() -> SaveData:
	if not ResourceLoader.exists(SAVE_PATH):
		var fresh := SaveData.make_default()
		ResourceSaver.save(fresh, SAVE_PATH)
		return fresh
	var loaded: Resource = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded == null or not loaded is SaveData:
		push_warning("SaveIO: corrupt or incompatible save — creating fresh save.")
		var fresh := SaveData.make_default()
		ResourceSaver.save(fresh, SAVE_PATH)
		return fresh
	return migrate(loaded as SaveData)

## Forward migration: bring an older save up to the current schema version.
## Add a new `if loaded.version < N` block for each future schema bump.
## Public (no underscore) so the GUT test can call it directly.
func migrate(loaded: SaveData) -> SaveData:
	# v1 → v2: add 'void' dragon if missing (mirrors persistence.js migrateSave)
	if loaded.version < 2:
		if not loaded.dragons.has("void"):
			loaded.dragons["void"] = {
				"level": 1,
				"xp": 0,
				"owned": false,
				"shiny": false,
				"fused_base_stats": null,
				"nickname": "",
			}
		# Backfill any dragon missing the nickname key (v1 didn't have it)
		for el in loaded.dragons:
			var d: Dictionary = loaded.dragons[el]
			if not d.has("nickname"):
				d["nickname"] = ""
		# Backfill skye.companion_dragon_id if missing
		if not loaded.skye.has("companion_dragon_id"):
			loaded.skye["companion_dragon_id"] = ""
		# Backfill flags.fragments_unlocked if missing
		if not loaded.flags.has("fragments_unlocked"):
			loaded.flags["fragments_unlocked"] = []
		# Backfill records if any key missing
		if not loaded.records.has("fastest_win"):
			loaded.records["fastest_win"] = -1
		if not loaded.records.has("highest_damage"):
			loaded.records["highest_damage"] = 0
		if not loaded.records.has("longest_streak"):
			loaded.records["longest_streak"] = 0
		if not loaded.records.has("current_streak"):
			loaded.records["current_streak"] = 0
		loaded.version = 2
		push_warning("SaveIO: migrated save from v1 to v2")

	# Future: if loaded.version < 3: ...

	return loaded
