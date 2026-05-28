class_name SaveData
extends Resource

## Typed durable save schema for Dragon Forge MVP state.
## Feature systems may stage mutations through Save / Persistence, but this Resource
## contains no commit logic, feature rules, or committed-state signals.

const SAVE_SCHEMA_VERSION: int = 1

@export var schema_version: int = SAVE_SCHEMA_VERSION
@export var created_at_unix: int = 0
@export var updated_at_unix: int = 0
@export var last_committed_transaction_id: StringName = &""

@export var current_node_id: StringName = &""
@export var acts_unlocked: Array[StringName] = []
@export var unlocked_gates: Array[StringName] = []
@export var matrix_stabilized: bool = false
@export var visited_nodes: Array[StringName] = []
@export var cleared_bosses: Array[StringName] = []
@export var cleared_combat_nodes: Array[StringName] = []
@export var loadout_hp: Array[int] = []
@export var previous_node_id: StringName = &""
@export var expedition_xp_earned: int = 0
@export var gate_denial_count: Dictionary[StringName, int] = {}
@export var expedition_field_kit: bool = false

@export var corruption_class: StringName = &""
@export var scar_nodes: Array[StringName] = []
@export var gatekeeper_fire_defeated: bool = false
@export var gatekeeper_ice_defeated: bool = false
@export var gatekeeper_shadow_defeated: bool = false
@export var mirror_admin_defeated: bool = false
@export var void_dragon_granted: bool = false
@export var ending_id: StringName = &""

@export var player_scraps: int = 0
@export var relic_wrench_owned: bool = false
@export var relic_lens_owned: bool = false
@export var relic_blade_owned: bool = false
@export var expedition_defrag_patch: bool = false
@export var expedition_cache_shard: bool = false
@export var expedition_emergency_patch: bool = false

@export var dragons: Array[DragonRecord] = []
@export var story_roster: Array[StringName] = []
@export var hatchery_pity_counter: int = 0
@export var element_drought_counters: Dictionary[StringName, int] = {}

@export var journal_unlocked_ids: Array[StringName] = []
@export var journal_read_ids: Array[StringName] = []
@export var terminal_read_ids: Array[StringName] = []
