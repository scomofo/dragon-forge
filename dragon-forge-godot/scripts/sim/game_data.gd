extends RefCounted
class_name GameData

# ── ELEMENTS ────────────────────────────────────────────────────────────────
const ELEMENTS: Array = ["fire", "ice", "storm", "stone", "venom", "shadow", "void"]

# ── TYPE CHART ───────────────────────────────────────────────────────────────
# typeChart[attacker][defender] = multiplier
const TYPE_CHART: Dictionary = {
	"fire":   { "fire": 0.5, "ice": 2.0, "storm": 1.0, "stone": 0.5, "venom": 2.0, "shadow": 1.0, "void": 1.0 },
	"ice":    { "fire": 0.5, "ice": 0.5, "storm": 2.0, "stone": 1.0, "venom": 1.0, "shadow": 2.0, "void": 1.0 },
	"storm":  { "fire": 1.0, "ice": 0.5, "storm": 0.5, "stone": 2.0, "venom": 1.0, "shadow": 2.0, "void": 1.0 },
	"stone":  { "fire": 2.0, "ice": 1.0, "storm": 0.5, "stone": 0.5, "venom": 2.0, "shadow": 1.0, "void": 1.0 },
	"venom":  { "fire": 0.5, "ice": 1.0, "storm": 1.0, "stone": 0.5, "venom": 0.5, "shadow": 2.0, "void": 1.0 },
	"shadow": { "fire": 1.0, "ice": 0.5, "storm": 0.5, "stone": 1.0, "venom": 0.5, "shadow": 0.5, "void": 1.0 },
	"void":   { "fire": 1.0, "ice": 1.0, "storm": 1.0, "stone": 1.0, "venom": 1.0, "shadow": 1.0, "void": 1.0 },
}

# ── STAGE MULTIPLIERS ────────────────────────────────────────────────────────
const STAGE_MULTIPLIERS: Dictionary = { 1: 0.5, 2: 0.75, 3: 1.0, 4: 1.4 }

# ── STAGE THRESHOLDS ─────────────────────────────────────────────────────────
const STAGE_THRESHOLDS: Dictionary = { 2: 10, 3: 25, 4: 50 }

# ── CRIT ─────────────────────────────────────────────────────────────────────
const CRIT_CHANCE: float = 0.10
const CRIT_MULTIPLIER: float = 1.5

# ── STATUS EFFECTS ───────────────────────────────────────────────────────────
const STATUS_EFFECTS: Dictionary = {
	"fire":   { "name": "Burn",        "duration": 2, "type": "dot",       "value": 0.08 },
	"ice":    { "name": "Freeze",      "duration": 1, "type": "skip",      "value": 1.0  },
	"storm":  { "name": "Paralyze",    "duration": 2, "type": "maySkip",   "value": 0.5  },
	"stone":  { "name": "Guard Break", "duration": 2, "type": "debuff",    "value": 0.4  },
	"venom":  { "name": "Poison",      "duration": 2, "type": "dot",       "value": 0.06 },
	"shadow": { "name": "Blind",       "duration": 2, "type": "debuff",    "value": 0.3  },
	"void":   { "name": "Glitch",      "duration": 1, "type": "randomize", "value": 1.0  },
}
const STATUS_APPLY_CHANCE: float = 0.30

# ── MOVES ─────────────────────────────────────────────────────────────────────
const MOVES: Dictionary = {
	"magma_breath":     { "name": "Magma Breath",     "element": "fire",    "power": 65, "accuracy": 95,  "can_apply_status": true,  "is_reflect": false },
	"flame_wall":       { "name": "Flame Wall",        "element": "fire",    "power": 55, "accuracy": 100, "can_apply_status": true,  "is_reflect": false },
	"frost_bite":       { "name": "Frost Bite",        "element": "ice",     "power": 60, "accuracy": 100, "can_apply_status": true,  "is_reflect": false },
	"blizzard":         { "name": "Blizzard",          "element": "ice",     "power": 70, "accuracy": 85,  "can_apply_status": true,  "is_reflect": false },
	"lightning_strike": { "name": "Lightning Strike",  "element": "storm",   "power": 70, "accuracy": 90,  "can_apply_status": true,  "is_reflect": false },
	"thunder_clap":     { "name": "Thunder Clap",      "element": "storm",   "power": 55, "accuracy": 100, "can_apply_status": true,  "is_reflect": false },
	"rock_slide":       { "name": "Rock Slide",        "element": "stone",   "power": 60, "accuracy": 95,  "can_apply_status": true,  "is_reflect": false },
	"earthquake":       { "name": "Earthquake",        "element": "stone",   "power": 75, "accuracy": 85,  "can_apply_status": true,  "is_reflect": false },
	"acid_spit":        { "name": "Acid Spit",         "element": "venom",   "power": 60, "accuracy": 100, "can_apply_status": true,  "is_reflect": false },
	"toxic_cloud":      { "name": "Toxic Cloud",       "element": "venom",   "power": 70, "accuracy": 85,  "can_apply_status": true,  "is_reflect": false },
	"shadow_strike":    { "name": "Shadow Strike",     "element": "shadow",  "power": 65, "accuracy": 95,  "can_apply_status": true,  "is_reflect": false },
	"void_pulse":       { "name": "Void Pulse",        "element": "shadow",  "power": 75, "accuracy": 85,  "can_apply_status": true,  "is_reflect": false },
	"void_rift":        { "name": "Void Rift",         "element": "void",    "power": 80, "accuracy": 80,  "can_apply_status": true,  "is_reflect": false },
	"null_reflect":     { "name": "Null Reflect",      "element": "void",    "power": 0,  "accuracy": 100, "can_apply_status": false, "is_reflect": true  },
	"basic_attack":     { "name": "Basic Attack",      "element": "neutral", "power": 40, "accuracy": 100, "can_apply_status": false, "is_reflect": false },
}

# ── RARITY TIERS ─────────────────────────────────────────────────────────────
const RARITY_TIERS: Array = [
	{ "name": "Common",   "chance": 0.50, "elements": ["fire", "ice"],             "multiplier": 1, "guaranteed_shiny": false },
	{ "name": "Uncommon", "chance": 0.30, "elements": ["storm", "venom", "stone"], "multiplier": 2, "guaranteed_shiny": false },
	{ "name": "Rare",     "chance": 0.15, "elements": ["shadow"],                  "multiplier": 3, "guaranteed_shiny": false },
	{ "name": "Exotic",   "chance": 0.05, "elements": ["void"],                    "multiplier": 5, "guaranteed_shiny": true  },
]
const PULL_COST: int      = 50
const SHINY_CHANCE: float = 0.02
const PITY_THRESHOLD: int = 10

# ── SINGULARITY ───────────────────────────────────────────────────────────────
const BASE_ELEMENTS: Array    = ["fire", "ice", "storm", "stone", "venom", "shadow"]
const BASE_NPC_IDS: Array     = ["firewall_sentinel", "bit_wraith", "glitch_hydra", "recursive_golem"]
const SINGULARITY_STAGES: Array = [
	{ "stage": 0, "name": "Dormant",           "description": "The Elemental Matrix is stable." },
	{ "stage": 1, "name": "Anomaly Detected",  "description": "Strange readings in the Matrix." },
	{ "stage": 2, "name": "Signal Growing",    "description": "Something is feeding on elemental energy." },
	{ "stage": 3, "name": "Matrix Unstable",   "description": "The Matrix is destabilizing." },
	{ "stage": 4, "name": "Breach Imminent",   "description": "Defenses are failing." },
	{ "stage": 5, "name": "The Singularity",   "description": "The Singularity has breached the Matrix." },
]
