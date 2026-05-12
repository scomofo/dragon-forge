# save_data.gd
# Resource class mirroring DEFAULT_SAVE from src/persistence.js.
# Snake_case field names; types match their JS counterparts.
# Loaded and saved by save_io.gd (autoload: SaveIO).
class_name SaveData
extends Resource

# Schema version — bumped each time a migration is added to save_io.gd.
const SCHEMA_VERSION := 2

# ── Per-dragon records ────────────────────────────────────────────────────
# Key: element string ("fire", "ice", etc.)
# Value: Dictionary { level, xp, owned, shiny, fused_base_stats, nickname }
@export var dragons: Dictionary = {}

# ── Currency & pull counters ──────────────────────────────────────────────
@export var data_scraps: int = 0
@export var pity_counter: int = 0

# ── Milestone tracking ────────────────────────────────────────────────────
# Array of milestone id strings that have been claimed.
@export var milestones: Array = []

# ── Battle history ────────────────────────────────────────────────────────
@export var defeated_npcs: Array = []

# ── Singularity progress ──────────────────────────────────────────────────
@export var singularity_progress: Dictionary = {
	"defeated": [],
	"final_boss_phase": 0,
}
@export var singularity_complete: bool = false

# ── Inventory ─────────────────────────────────────────────────────────────
# cores: Dictionary<element_string, int>
@export var inventory: Dictionary = {
	"cores": {},
	"xp_boost_battles": 0,
	"stability_boost": false,
}

# ── Lifetime stats ────────────────────────────────────────────────────────
@export var stats: Dictionary = {
	"battles_won": 0,
	"battles_lost": 0,
	"total_scraps_earned": 0,
	"total_pulls": 0,
	"fusions_completed": 0,
}

# ── Daily challenge ───────────────────────────────────────────────────────
@export var last_daily_completed: int = 0

# ── Personal records ──────────────────────────────────────────────────────
# fastest_win: -1 means "never won" (JS null → -1 for GDScript int)
@export var records: Dictionary = {
	"fastest_win": -1,
	"highest_damage": 0,
	"longest_streak": 0,
	"current_streak": 0,
}

# ── Story flags ───────────────────────────────────────────────────────────
@export var flags: Dictionary = {
	"current_act": 1,
	"met_felix": false,
	"last_zone": "",
	"fragments_unlocked": [],
}

# ── Skye / Forge state ────────────────────────────────────────────────────
@export var skye: Dictionary = {
	"wrench_tier": 1,
	"relic_slots": 1,
	"relics_owned": [],
	"relics_equipped": [],
	"bounties_cleared": 0,
	"companion_dragon_id": "",
}

# ── Schema version stored in save ─────────────────────────────────────────
@export var version: int = SCHEMA_VERSION

# ── Factory ───────────────────────────────────────────────────────────────

static func make_default() -> SaveData:
	var s := SaveData.new()
	s.dragons = {}
	for el in ["fire", "ice", "storm", "stone", "venom", "shadow", "void"]:
		s.dragons[el] = {
			"level": 1,
			"xp": 0,
			"owned": false,
			"shiny": false,
			"fused_base_stats": null,
			"nickname": "",
		}
	s.data_scraps = 0
	s.pity_counter = 0
	s.milestones = []
	s.defeated_npcs = []
	s.singularity_progress = {"defeated": [], "final_boss_phase": 0}
	s.singularity_complete = false
	s.inventory = {"cores": {}, "xp_boost_battles": 0, "stability_boost": false}
	s.stats = {
		"battles_won": 0,
		"battles_lost": 0,
		"total_scraps_earned": 0,
		"total_pulls": 0,
		"fusions_completed": 0,
	}
	s.last_daily_completed = 0
	s.records = {
		"fastest_win": -1,
		"highest_damage": 0,
		"longest_streak": 0,
		"current_streak": 0,
	}
	s.flags = {
		"current_act": 1,
		"met_felix": false,
		"last_zone": "",
		"fragments_unlocked": [],
	}
	s.skye = {
		"wrench_tier": 1,
		"relic_slots": 1,
		"relics_owned": [],
		"relics_equipped": [],
		"bounties_cleared": 0,
		"companion_dragon_id": "",
	}
	s.version = SCHEMA_VERSION
	return s

# ── Convenience accessors ─────────────────────────────────────────────────

func get_dragon(element: String) -> Dictionary:
	return dragons.get(element, {})

func owns_dragon(element: String) -> bool:
	return bool(dragons.get(element, {}).get("owned", false))

func get_stat(key: String, default_val: int = 0) -> int:
	return int(stats.get(key, default_val))

func get_flag(key: String, default_val: Variant = null) -> Variant:
	return flags.get(key, default_val)

func has_fragment(fragment_id: String) -> bool:
	var unlocked: Array = flags.get("fragments_unlocked", [])
	return unlocked.has(fragment_id)
