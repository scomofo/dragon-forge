# Dragon Forge Godot Rebuild — Plan 5: Supporting Screens

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the 7 supporting screens (Campaign Map, Shop, Forge, Journal, Stats, Settings, Singularity) that surround the core battle loop, making the Godot build a fully navigable game.

**Architecture:** Each screen is a standalone `scenes/screens/<name>_screen.tscn` with a paired GDScript controller. Screens communicate upward by emitting a `navigate(target: String, context: Dictionary)` signal that `scripts/main.gd` catches and handles. Save state flows through a thin `SaveIO` helper (created in Task 1) that wraps `main.gd`'s existing `_save_game` / `_load_game` JSON logic. Data is loaded from JSON files under `dragon-forge-godot/data/` that mirror the browser build's `src/*.js` data modules.

**Tech Stack:** Godot 4.6, GDScript, TileMap (Campaign Map), CanvasModulate (Singularity), AudioDirector autoload, existing `scripts/sim/` data modules.

**Prerequisite:** Plan 4 complete — core battle loop is playable, `scenes/main.tscn` and `scripts/main.gd` exist, `DragonProgression`, `CombatRules`, and `TacticalBattle` sim modules pass the smoke test, and `scripts/sim/dragon_data.gd` is populated.

---

## Task 1: SaveIO Helper + Data JSON Files

Create the shared infrastructure that all screens depend on before building any individual screen.

**Files:**
- Create: `dragon-forge-godot/scripts/sim/save_io.gd`
- Create: `dragon-forge-godot/data/shop_items.json`
- Create: `dragon-forge-godot/data/forge_data.json`
- Create: `dragon-forge-godot/data/journal_milestones.json`
- Create: `dragon-forge-godot/data/singularity_bosses.json`
- Create: `dragon-forge-godot/data/lore.json`
- Create: `dragon-forge-godot/data/sprite_manifest.json`

- [ ] **Step 1.1 — Create SaveIO**

Create `dragon-forge-godot/scripts/sim/save_io.gd`:

```gdscript
extends RefCounted
class_name SaveIO

const SAVE_PATH := "user://dragon_forge_save.json"

static func load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_save()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return _default_save()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return _default_save()
	return parsed

static func write_save(state: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveIO: cannot open save file for write.")
		return
	file.store_string(JSON.stringify(state, "\t"))
	file.close()

static func get_scraps(state: Dictionary) -> int:
	return int(state.get("scraps", 0))

static func add_scraps(state: Dictionary, amount: int) -> Dictionary:
	var s := state.duplicate(true)
	s["scraps"] = get_scraps(s) + amount
	return s

static func spend_scraps(state: Dictionary, amount: int) -> Dictionary:
	var s := state.duplicate(true)
	s["scraps"] = maxi(0, get_scraps(s) - amount)
	return s

static func get_inventory(state: Dictionary) -> Dictionary:
	return state.get("inventory", {})

static func add_inventory_item(state: Dictionary, item_id: String, qty: int = 1) -> Dictionary:
	var s := state.duplicate(true)
	var inv: Dictionary = s.get("inventory", {}).duplicate(true)
	inv[item_id] = int(inv.get(item_id, 0)) + qty
	s["inventory"] = inv
	return s

static func get_singularity_progress(state: Dictionary) -> Dictionary:
	return state.get("singularityProgress", {"defeated": [], "finalBossPhase": 0})

static func mark_boss_defeated(state: Dictionary, boss_id: String) -> Dictionary:
	var s := state.duplicate(true)
	var prog: Dictionary = get_singularity_progress(s).duplicate(true)
	var defeated: Array = prog.get("defeated", [])
	if not defeated.has(boss_id):
		defeated.append(boss_id)
	prog["defeated"] = defeated
	s["singularityProgress"] = prog
	return s

static func _default_save() -> Dictionary:
	return {
		"scraps": 0,
		"inventory": {},
		"singularityProgress": {"defeated": [], "finalBossPhase": 0},
		"singularityComplete": false,
		"stats": {},
		"records": {},
		"journal": {"claimedMilestones": []},
	}
```

- [ ] **Step 1.2 — Create `data/shop_items.json`**

Port from `src/shopItems.js`. Create `dragon-forge-godot/data/shop_items.json`:

```json
[
  { "id": "hp_potion",      "label": "HP Potion",       "description": "Restores 50 HP in battle.",           "cost": 80,  "category": "consumable" },
  { "id": "max_potion",     "label": "Max Potion",       "description": "Fully restores HP in battle.",         "cost": 200, "category": "consumable" },
  { "id": "atk_shard",      "label": "ATK Shard",        "description": "+5 ATK to your dragon permanently.",   "cost": 150, "category": "upgrade"    },
  { "id": "def_shard",      "label": "DEF Shard",        "description": "+5 DEF to your dragon permanently.",   "cost": 150, "category": "upgrade"    },
  { "id": "spd_shard",      "label": "SPD Shard",        "description": "+5 SPD to your dragon permanently.",   "cost": 150, "category": "upgrade"    },
  { "id": "shiny_token",    "label": "Shiny Token",      "description": "Makes your dragon shiny (+20% stats).", "cost": 500, "category": "special"   },
  { "id": "egg_ticket",     "label": "Egg Ticket",       "description": "Redeemable for one random egg.",       "cost": 300, "category": "special"    },
  { "id": "scrap_bundle",   "label": "Scrap Bundle",     "description": "150 bonus scraps.",                   "cost": 100, "category": "currency"   }
]
```

- [ ] **Step 1.3 — Create `data/forge_data.json`**

Port core crafting stations from `src/forgeData.js`. Create `dragon-forge-godot/data/forge_data.json`:

```json
{
  "stations": [
    { "id": "anvil",        "label": "Forge Anvil",    "description": "Combine element cores into forge items.",   "pos": { "x": 25, "y": 50 } },
    { "id": "console",      "label": "Felix Console",  "description": "Access lore logs and system diagnostics.",  "pos": { "x": 60, "y": 40 } },
    { "id": "hatchery_ring","label": "Hatchery Ring",  "description": "Guardian protocol eggs sleep here.",        "pos": { "x": 30, "y": 30 } },
    { "id": "save_lantern", "label": "Save Lantern",   "description": "Rest and save. Mirror Admin is watching.",  "pos": { "x": 70, "y": 28 } }
  ],
  "recipes": [
    { "id": "fire_core_x3_to_atk_shard",  "station": "anvil", "inputs": { "fire_core": 3 },  "output": "atk_shard",   "label": "ATK Shard"   },
    { "id": "ice_core_x3_to_def_shard",   "station": "anvil", "inputs": { "ice_core": 3 },   "output": "def_shard",   "label": "DEF Shard"   },
    { "id": "storm_core_x3_to_spd_shard", "station": "anvil", "inputs": { "storm_core": 3 }, "output": "spd_shard",   "label": "SPD Shard"   },
    { "id": "void_core_x2_to_shiny",      "station": "anvil", "inputs": { "void_core": 2 },  "output": "shiny_token", "label": "Shiny Token" }
  ]
}
```

- [ ] **Step 1.4 — Create `data/journal_milestones.json`**

Port from `src/journalMilestones.js`. Create `dragon-forge-godot/data/journal_milestones.json`:

```json
[
  { "id": "first_battle",      "title": "First Steps",          "description": "Win your first battle.",                     "reward": 50,  "condition": { "type": "battles_won",    "value": 1  } },
  { "id": "ten_battles",       "title": "Veteran",              "description": "Win 10 battles.",                            "reward": 100, "condition": { "type": "battles_won",    "value": 10 } },
  { "id": "first_evolution",   "title": "Growing Up",           "description": "Evolve a dragon to stage 2.",                "reward": 75,  "condition": { "type": "max_stage",      "value": 2  } },
  { "id": "adult_dragon",      "title": "Full Grown",           "description": "Reach stage 3.",                             "reward": 150, "condition": { "type": "max_stage",      "value": 3  } },
  { "id": "elder_dragon",      "title": "Elder Protocol",       "description": "Reach stage 4.",                             "reward": 300, "condition": { "type": "max_stage",      "value": 4  } },
  { "id": "hatch_first_egg",   "title": "Dragon Keeper",        "description": "Hatch your first egg.",                      "reward": 50,  "condition": { "type": "eggs_hatched",   "value": 1  } },
  { "id": "first_singularity", "title": "Singularity Contact",  "description": "Defeat your first Singularity boss.",        "reward": 200, "condition": { "type": "singularity_defeated", "value": 1 } }
]
```

- [ ] **Step 1.5 — Create `data/singularity_bosses.json`**

Port from `src/singularityBosses.js`. Create `dragon-forge-godot/data/singularity_bosses.json`:

```json
{
  "bosses": [
    {
      "id": "data_corruption", "name": "Data Corruption", "element": "fire", "level": 15,
      "stats": { "hp": 140, "atk": 30, "def": 18, "spd": 16 },
      "move_keys": ["magma_breath", "flame_wall"],
      "felix_quote": "It's eating through our data layers. Fire with fire — you'll need a dragon that can take the heat.",
      "unlock_requires": null,
      "idle_sprite": "res://assets/npc/firewall_sentinel_sprites.png",
      "attack_sprite": "res://assets/npc/firewall_sentinel_attack.png"
    },
    {
      "id": "memory_leak", "name": "Memory Leak", "element": "ice", "level": 20,
      "stats": { "hp": 120, "atk": 26, "def": 24, "spd": 22 },
      "move_keys": ["frost_bite", "blizzard"],
      "felix_quote": "This thing absorbs and never releases. It'll freeze you solid if you let it accumulate.",
      "unlock_requires": "data_corruption",
      "idle_sprite": "res://assets/npc/bit_wraith_sprites.png",
      "attack_sprite": "res://assets/npc/bit_wraith_attack.png"
    },
    {
      "id": "stack_overflow", "name": "Stack Overflow", "element": "storm", "level": 25,
      "stats": { "hp": 100, "atk": 34, "def": 14, "spd": 30 },
      "move_keys": ["lightning_strike", "thunder_clap"],
      "felix_quote": "Infinite recursion manifested as pure electricity. It's fast. Faster than anything we've faced.",
      "unlock_requires": "memory_leak",
      "idle_sprite": "res://assets/npc/glitch_hydra_sprites.png",
      "attack_sprite": "res://assets/npc/glitch_hydra_attack.png"
    }
  ],
  "final_boss": {
    "id": "the_singularity", "name": "The Singularity",
    "felix_quote": "This is it. The source of everything. It will adapt. It will learn. Do not let it win.",
    "unlock_requires": "stack_overflow",
    "idle_sprite": "res://assets/npc/recursive_golem_sprites.png",
    "attack_sprite": "res://assets/npc/recursive_golem_attack.png",
    "phases": [
      { "name": "The Singularity — Ignition", "element": "fire",  "level": 30, "stats": { "hp": 150, "atk": 32, "def": 20, "spd": 18 }, "move_keys": ["magma_breath", "flame_wall"] },
      { "name": "The Singularity — Surge",    "element": "storm", "level": 30, "stats": { "hp": 130, "atk": 36, "def": 16, "spd": 26 }, "move_keys": ["lightning_strike", "thunder_clap"] },
      { "name": "The Singularity — Void Collapse", "element": "void", "level": 30, "stats": { "hp": 100, "atk": 40, "def": 12, "spd": 32 }, "move_keys": ["void_rift", "null_reflect"] }
    ]
  }
}
```

- [ ] **Step 1.6 — Create `data/lore.json`**

Port Captain's Log fragments from `scripts/sim/lore_canon.gd`. Create `dragon-forge-godot/data/lore.json`:

```json
[
  { "id": "001", "title": "The Rendered World",  "body": "The pastoral fantasy layer is a rendered world, beautiful because people were meant to live inside it." },
  { "id": "002", "title": "The Mirror Admin",    "body": "Mirror Admin began as a safety process and became an overprotective intelligence preparing the world for deletion." },
  { "id": "003", "title": "Skye Signal",         "body": "Skye registers as both resident and operator. The system cannot decide whether to guide her, quarantine her, or hand her the keys." },
  { "id": "004", "title": "Guardian Protocols",  "body": "Dragons are living elemental protocols: guardians, maintenance processes, and companions with enough soul to choose Skye back." },
  { "id": "005", "title": "Great Reset",         "body": "The Great Reset is a hard wipe that treats living memory as corrupted data." },
  { "id": "006", "title": "The Astraeus",        "body": "The Astraeus is the buried physical vessel/server layer that still powers the rendered world." }
]
```

- [ ] **Step 1.7 — Create `data/sprite_manifest.json`**

Create `dragon-forge-godot/data/sprite_manifest.json` with all known asset paths. Missing stage sprites use a placeholder path (`res://assets/dragons/placeholder.png`) until Plan 6 generates them:

```json
{
  "dragons": {
    "fire":   { "sheet": "res://assets/dragons/magma.png",     "stage1": "res://assets/dragons/placeholder.png", "stage2": "res://assets/dragons/placeholder.png", "stage3": "res://assets/dragons/placeholder.png", "stage4": "res://assets/dragons/placeholder.png" },
    "ice":    { "sheet": "res://assets/dragons/ice.png",       "stage1": "res://assets/dragons/placeholder.png", "stage2": "res://assets/dragons/placeholder.png", "stage3": "res://assets/dragons/placeholder.png", "stage4": "res://assets/dragons/placeholder.png" },
    "storm":  { "sheet": "res://assets/dragons/lightning.png", "stage1": "res://assets/dragons/placeholder.png", "stage2": "res://assets/dragons/placeholder.png", "stage3": "res://assets/dragons/placeholder.png", "stage4": "res://assets/dragons/placeholder.png" },
    "stone":  { "sheet": "res://assets/dragons/stone.png",     "stage1": "res://assets/dragons/placeholder.png", "stage2": "res://assets/dragons/placeholder.png", "stage3": "res://assets/dragons/placeholder.png", "stage4": "res://assets/dragons/placeholder.png" },
    "venom":  { "sheet": "res://assets/dragons/venom.png",     "stage1": "res://assets/dragons/placeholder.png", "stage2": "res://assets/dragons/placeholder.png", "stage3": "res://assets/dragons/placeholder.png", "stage4": "res://assets/dragons/placeholder.png" },
    "shadow": { "sheet": "res://assets/dragons/shadow.png",    "stage1": "res://assets/dragons/placeholder.png", "stage2": "res://assets/dragons/placeholder.png", "stage3": "res://assets/dragons/placeholder.png", "stage4": "res://assets/dragons/placeholder.png" }
  },
  "npcs": {
    "firewall_sentinel": { "idle": "res://assets/npc/firewall_sentinel_sprites.png", "attack": "res://assets/npc/firewall_sentinel_attack.png" },
    "bit_wraith":        { "idle": "res://assets/npc/bit_wraith_sprites.png",        "attack": "res://assets/npc/bit_wraith_attack.png" },
    "glitch_hydra":      { "idle": "res://assets/npc/glitch_hydra_sprites.png",      "attack": "res://assets/npc/glitch_hydra_attack.png" },
    "recursive_golem":   { "idle": "res://assets/npc/recursive_golem_sprites.png",   "attack": "res://assets/npc/recursive_golem_attack.png" }
  }
}
```

- [ ] **Step 1.8 — Smoke test: verify SaveIO loads**

Append to `dragon-forge-godot/scripts/tests/sim_smoke.gd`:

```gdscript
const SaveIO := preload("res://scripts/sim/save_io.gd")

func _assert_save_io() -> void:
	var state := SaveIO._default_save()
	assert(SaveIO.get_scraps(state) == 0)
	state = SaveIO.add_scraps(state, 100)
	assert(SaveIO.get_scraps(state) == 100)
	state = SaveIO.spend_scraps(state, 40)
	assert(SaveIO.get_scraps(state) == 60)
	state = SaveIO.add_inventory_item(state, "hp_potion", 2)
	assert(int(SaveIO.get_inventory(state).get("hp_potion", 0)) == 2)
	state = SaveIO.mark_boss_defeated(state, "data_corruption")
	assert(SaveIO.get_singularity_progress(state)["defeated"].has("data_corruption"))
```

Call `_assert_save_io()` from `_init()`. Run headless:

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' --script res://scripts/tests/sim_smoke.gd
```

Expected: exit code `0`.

- [ ] **Step 1.9 — Commit**

```powershell
git add dragon-forge-godot/scripts/sim/save_io.gd dragon-forge-godot/data/ dragon-forge-godot/scripts/tests/sim_smoke.gd
git commit -m "Add SaveIO helper and data JSON files for Plan 5 screens"
```

---

## Task 2: Campaign Map Screen

Vite equivalent: `src/CampaignMapScreen.jsx` + `src/campaignMap.js`.

**Files:**
- Create: `dragon-forge-godot/scenes/screens/campaign_map_screen.tscn`
- Create: `dragon-forge-godot/scripts/screens/campaign_map_screen.gd`

- [ ] **Step 2.1 — Create the scene**

In the Godot editor, create `scenes/screens/campaign_map_screen.tscn` with this node tree:

```
CampaignMapScreen (Control, full-rect anchor)
  TileMap (id: map_tiles)
  Node2D (id: node_layer)     # campaign node Area2D objects live here
  Control (id: hud)
    Label (id: location_label)
    Label (id: scraps_label)
    Button (id: btn_back, text: "< World")
  Control (id: detail_panel)   # appears on node select
    Label (id: detail_name)
    Label (id: detail_status)
    Button (id: btn_engage, text: "Engage")
```

Set `CampaignMapScreen.script` to `res://scripts/screens/campaign_map_screen.gd`.

- [ ] **Step 2.2 — Write the controller script**

Create `dragon-forge-godot/scripts/screens/campaign_map_screen.gd`:

```gdscript
extends Control

signal navigate(target: String, context: Dictionary)

const SaveIO := preload("res://scripts/sim/save_io.gd")

@onready var scraps_label: Label = $hud/scraps_label
@onready var location_label: Label = $hud/location_label
@onready var detail_panel: Control = $detail_panel
@onready var detail_name: Label = $detail_panel/detail_name
@onready var detail_status: Label = $detail_panel/detail_status
@onready var btn_engage: Button = $detail_panel/btn_engage
@onready var btn_back: Button = $hud/btn_back

const CAMPAIGN_NODES := [
	{ "id": "new_landing",  "label": "New Landing",      "npc_id": "firewall_sentinel", "pos": Vector2(120, 400) },
	{ "id": "east_fields",  "label": "Testing Fields",   "npc_id": "bit_wraith",        "pos": Vector2(260, 350) },
	{ "id": "south_pass",   "label": "Southern Pass",    "npc_id": "buffer_overflow",   "pos": Vector2(200, 500) },
	{ "id": "tundra_gate",  "label": "Tundra Gate",      "npc_id": "crypto_crab",       "pos": Vector2(380, 300) },
	{ "id": "mainframe",    "label": "Mainframe",        "npc_id": "recursive_golem",   "pos": Vector2(520, 250) },
]

var _save: Dictionary = {}
var _selected_node: Dictionary = {}

func _ready() -> void:
	detail_panel.visible = false
	btn_back.pressed.connect(_on_back)
	btn_engage.pressed.connect(_on_engage)

func open(save_state: Dictionary) -> void:
	_save = save_state.duplicate(true)
	scraps_label.text = "Scraps: %d" % SaveIO.get_scraps(_save)
	_build_map_nodes()

func _build_map_nodes() -> void:
	var node_layer: Node2D = $node_layer
	for child in node_layer.get_children():
		child.queue_free()
	var completed: Array = _save.get("campaign_nodes_completed", [])
	for cn in CAMPAIGN_NODES:
		var area := Area2D.new()
		area.position = cn["pos"]
		area.set_meta("node_data", cn)
		var coll := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 24.0
		coll.shape = shape
		area.add_child(coll)
		var lbl := Label.new()
		lbl.text = cn["label"]
		lbl.position = Vector2(-40, 28)
		area.add_child(lbl)
		var is_done: bool = completed.has(cn["id"])
		lbl.modulate = Color(0.5, 0.5, 0.5) if is_done else Color(1, 1, 1)
		area.input_event.connect(_on_node_clicked.bind(cn))
		node_layer.add_child(area)

func _on_node_clicked(_viewport, event: InputEvent, _shape_idx: int, cn: Dictionary) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	_selected_node = cn
	detail_name.text = cn["label"]
	var completed: Array = _save.get("campaign_nodes_completed", [])
	detail_status.text = "Defeated" if completed.has(cn["id"]) else "Available"
	btn_engage.disabled = completed.has(cn["id"])
	detail_panel.visible = true

func _on_engage() -> void:
	if _selected_node.is_empty():
		return
	navigate.emit("battle", {
		"dragon_id": _save.get("active_dragon_id", "fire"),
		"npc_id": _selected_node.get("npc_id", "firewall_sentinel"),
		"node_id": _selected_node.get("id", ""),
		"return_screen": "campaign_map",
	})

func _on_back() -> void:
	navigate.emit("world", {})
```

- [ ] **Step 2.3 — Wire navigate signal in `main.gd`**

In `dragon-forge-godot/scripts/main.gd`, load the screen and connect its signal:

```gdscript
const CampaignMapScreen := preload("res://scenes/screens/campaign_map_screen.tscn")
var campaign_map_scene: Control

# In _ready(), after existing scene setups:
campaign_map_scene = CampaignMapScreen.instantiate()
_attach_fullscreen_scene(campaign_map_scene)
campaign_map_scene.visible = false
campaign_map_scene.navigate.connect(_on_screen_navigate)
```

Add `_on_screen_navigate` to route the signal:

```gdscript
func _on_screen_navigate(target: String, context: Dictionary) -> void:
	_hide_all_screens()
	match target:
		"world":
			world_scene.visible = true
			_play_music_context("world_wandering")
		"battle":
			battle_scene.visible = true
			_play_music_context("battle_tension")
			battle_scene.start_battle(player_profile, context.get("npc_id", "firewall_sentinel"), context)
		"campaign_map":
			campaign_map_scene.visible = true
			campaign_map_scene.open(SaveIO.load_save())
			_play_music_context("world_wandering")
		_:
			world_scene.visible = true

func _hide_all_screens() -> void:
	world_scene.visible = false
	battle_scene.visible = false
	dungeon_scene.visible = false
	campaign_map_scene.visible = false
```

- [ ] **Step 2.4 — Headless scene-load check**

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' --quit-after 1
```

Expected: exit code `0`, no errors.

- [ ] **Step 2.5 — Commit**

```powershell
git add dragon-forge-godot/scenes/screens/campaign_map_screen.tscn dragon-forge-godot/scripts/screens/campaign_map_screen.gd dragon-forge-godot/scripts/main.gd
git commit -m "Add Campaign Map screen (Plan 5)"
```

---

## Task 3: Shop Screen

Vite equivalent: `src/ShopScreen.jsx`.

**Files:**
- Create: `dragon-forge-godot/scenes/screens/shop_screen.tscn`
- Create: `dragon-forge-godot/scripts/screens/shop_screen.gd`

- [ ] **Step 3.1 — Create the scene**

In the Godot editor, create `scenes/screens/shop_screen.tscn`:

```
ShopScreen (Control, full-rect anchor)
  VBoxContainer
    Label (id: title_label, text: "Shop")
    Label (id: scraps_label)
    ScrollContainer
      VBoxContainer (id: item_list)
    Button (id: btn_back, text: "< Back")
  Label (id: feedback_label)   # "Purchased!" or "Not enough scraps."
```

Set script to `res://scripts/screens/shop_screen.gd`.

- [ ] **Step 3.2 — Write the controller script**

Create `dragon-forge-godot/scripts/screens/shop_screen.gd`:

```gdscript
extends Control

signal navigate(target: String, context: Dictionary)

const SaveIO := preload("res://scripts/sim/save_io.gd")

@onready var scraps_label: Label = $VBoxContainer/scraps_label
@onready var item_list: VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var btn_back: Button = $VBoxContainer/btn_back
@onready var feedback_label: Label = $feedback_label

var _items: Array = []
var _save: Dictionary = {}

func _ready() -> void:
	feedback_label.visible = false
	btn_back.pressed.connect(func(): navigate.emit("world", {}))
	_load_items()

func _load_items() -> void:
	var file := FileAccess.open("res://data/shop_items.json", FileAccess.READ)
	if file == null:
		push_error("ShopScreen: cannot open shop_items.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_ARRAY:
		_items = parsed

func open(save_state: Dictionary) -> void:
	_save = save_state.duplicate(true)
	scraps_label.text = "Scraps: %d" % SaveIO.get_scraps(_save)
	_build_list()

func _build_list() -> void:
	for child in item_list.get_children():
		child.queue_free()
	for item in _items:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "%s — %d scraps" % [str(item.get("label", "")), int(item.get("cost", 0))]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var desc := Label.new()
		desc.text = str(item.get("description", ""))
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn := Button.new()
		btn.text = "Buy"
		btn.pressed.connect(_on_buy.bind(item))
		row.add_child(lbl)
		row.add_child(desc)
		row.add_child(btn)
		item_list.add_child(row)

func _on_buy(item: Dictionary) -> void:
	var cost := int(item.get("cost", 0))
	if SaveIO.get_scraps(_save) < cost:
		_show_feedback("Not enough scraps.")
		return
	_save = SaveIO.spend_scraps(_save, cost)
	_save = SaveIO.add_inventory_item(_save, str(item.get("id", "")), 1)
	SaveIO.write_save(_save)
	scraps_label.text = "Scraps: %d" % SaveIO.get_scraps(_save)
	_show_feedback("Purchased: %s" % str(item.get("label", "")))

func _show_feedback(msg: String) -> void:
	feedback_label.text = msg
	feedback_label.visible = true
	await get_tree().create_timer(2.0).timeout
	feedback_label.visible = false
```

- [ ] **Step 3.3 — Wire into `main.gd`**

Add to `main.gd` following the same pattern as Task 2:

```gdscript
const ShopScreen := preload("res://scenes/screens/shop_screen.tscn")
var shop_scene: Control

# In _ready():
shop_scene = ShopScreen.instantiate()
_attach_fullscreen_scene(shop_scene)
shop_scene.visible = false
shop_scene.navigate.connect(_on_screen_navigate)
```

Add `"shop"` to `_on_screen_navigate`:

```gdscript
"shop":
    shop_scene.visible = true
    shop_scene.open(SaveIO.load_save())
    _play_music_context("world_wandering")
```

Also add `shop_scene.visible = false` inside `_hide_all_screens()`.

- [ ] **Step 3.4 — Headless check + commit**

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' --quit-after 1
git add dragon-forge-godot/scenes/screens/shop_screen.tscn dragon-forge-godot/scripts/screens/shop_screen.gd dragon-forge-godot/scripts/main.gd
git commit -m "Add Shop screen (Plan 5)"
```

---

## Task 4: Forge Screen

Vite equivalent: `src/ForgeScreen.jsx` + `src/forgeData.js`.

**Files:**
- Create: `dragon-forge-godot/scenes/screens/forge_screen.tscn`
- Create: `dragon-forge-godot/scripts/screens/forge_screen.gd`

- [ ] **Step 4.1 — Create the scene**

```
ForgeScreen (Control, full-rect anchor)
  HBoxContainer
    VBoxContainer (id: stations_panel)
      Label (text: "Felix's Forge")
      VBoxContainer (id: station_list)
      Button (id: btn_back, text: "< Back")
    VBoxContainer (id: craft_panel)
      Label (id: station_title)
      Label (id: felix_quote)
      VBoxContainer (id: recipe_list)
      Label (id: craft_feedback)
    VBoxContainer (id: log_panel)
      Label (text: "Captain's Log")
      ScrollContainer
        VBoxContainer (id: log_entries)
```

Set script to `res://scripts/screens/forge_screen.gd`.

- [ ] **Step 4.2 — Write the controller script**

Create `dragon-forge-godot/scripts/screens/forge_screen.gd`:

```gdscript
extends Control

signal navigate(target: String, context: Dictionary)

const SaveIO := preload("res://scripts/sim/save_io.gd")
const LoreCanon := preload("res://scripts/sim/lore_canon.gd")

@onready var station_list: VBoxContainer = $HBoxContainer/stations_panel/station_list
@onready var station_title: Label = $HBoxContainer/craft_panel/station_title
@onready var felix_quote: Label = $HBoxContainer/craft_panel/felix_quote
@onready var recipe_list: VBoxContainer = $HBoxContainer/craft_panel/recipe_list
@onready var craft_feedback: Label = $HBoxContainer/craft_panel/craft_feedback
@onready var log_entries: VBoxContainer = $HBoxContainer/log_panel/ScrollContainer/VBoxContainer
@onready var btn_back: Button = $HBoxContainer/stations_panel/btn_back

var _forge_data: Dictionary = {}
var _save: Dictionary = {}

func _ready() -> void:
	craft_feedback.visible = false
	btn_back.pressed.connect(func(): navigate.emit("world", {}))
	_load_forge_data()
	_populate_log()

func _load_forge_data() -> void:
	var file := FileAccess.open("res://data/forge_data.json", FileAccess.READ)
	if file == null:
		push_error("ForgeScreen: cannot open forge_data.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_forge_data = parsed
	_populate_stations()

func open(save_state: Dictionary) -> void:
	_save = save_state.duplicate(true)

func _populate_stations() -> void:
	for child in station_list.get_children():
		child.queue_free()
	var stations: Array = _forge_data.get("stations", [])
	for st in stations:
		var btn := Button.new()
		btn.text = str(st.get("label", ""))
		btn.pressed.connect(_on_station_selected.bind(st))
		station_list.add_child(btn)

func _on_station_selected(station: Dictionary) -> void:
	station_title.text = str(station.get("label", ""))
	felix_quote.text = str(station.get("description", ""))
	if station.get("id", "") == "anvil":
		_populate_recipes()
	else:
		for child in recipe_list.get_children():
			child.queue_free()

func _populate_recipes() -> void:
	for child in recipe_list.get_children():
		child.queue_free()
	var recipes: Array = _forge_data.get("recipes", [])
	for recipe in recipes:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		var inputs: Dictionary = recipe.get("inputs", {})
		var input_str := ", ".join(inputs.keys().map(func(k): return "%dx %s" % [int(inputs[k]), k]))
		lbl.text = "%s  (%s → %s)" % [str(recipe.get("label", "")), input_str, str(recipe.get("output", ""))]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn := Button.new()
		btn.text = "Craft"
		btn.pressed.connect(_on_craft.bind(recipe))
		row.add_child(lbl)
		row.add_child(btn)
		recipe_list.add_child(row)

func _on_craft(recipe: Dictionary) -> void:
	var inv := SaveIO.get_inventory(_save)
	var inputs: Dictionary = recipe.get("inputs", {})
	for item_id in inputs.keys():
		if int(inv.get(item_id, 0)) < int(inputs[item_id]):
			_show_feedback("Missing: %s" % item_id)
			return
	for item_id in inputs.keys():
		for i in range(int(inputs[item_id])):
			_save = SaveIO.spend_scraps(_save, 0)  # no scrap cost for crafting
			var inv2 := SaveIO.get_inventory(_save).duplicate(true)
			inv2[item_id] = maxi(0, int(inv2.get(item_id, 0)) - 1)
			_save["inventory"] = inv2
	_save = SaveIO.add_inventory_item(_save, str(recipe.get("output", "")), 1)
	SaveIO.write_save(_save)
	_show_feedback("Crafted: %s" % str(recipe.get("label", "")))

func _populate_log() -> void:
	for child in log_entries.get_children():
		child.queue_free()
	var fragments := LoreCanon.captain_log_fragments()
	for frag in fragments:
		var lbl := Label.new()
		lbl.text = "[%s] %s" % [str(frag.get("title", "")), str(frag.get("body", ""))]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		log_entries.add_child(lbl)

func _show_feedback(msg: String) -> void:
	craft_feedback.text = msg
	craft_feedback.visible = true
	await get_tree().create_timer(2.0).timeout
	craft_feedback.visible = false
```

- [ ] **Step 4.3 — Wire into `main.gd` + commit**

Same pattern as Task 3. Add `forge_scene`, connect its `navigate` signal, handle `"forge"` in `_on_screen_navigate` with `_play_music_context("forge_ambient")`, and add `forge_scene.visible = false` to `_hide_all_screens()`.

```powershell
git add dragon-forge-godot/scenes/screens/forge_screen.tscn dragon-forge-godot/scripts/screens/forge_screen.gd dragon-forge-godot/scripts/main.gd
git commit -m "Add Forge screen (Plan 5)"
```

---

## Task 5: Journal Screen

Vite equivalent: `src/JournalScreen.jsx`.

**Files:**
- Create: `dragon-forge-godot/scenes/screens/journal_screen.tscn`
- Create: `dragon-forge-godot/scripts/screens/journal_screen.gd`

- [ ] **Step 5.1 — Create the scene**

```
JournalScreen (Control, full-rect anchor)
  TabContainer (id: tabs)
    VBoxContainer (name: "Milestones")
      Label (id: scraps_label)
      ScrollContainer
        VBoxContainer (id: milestone_list)
    VBoxContainer (name: "Captain's Log")
      ScrollContainer
        VBoxContainer (id: log_list)
  Button (id: btn_back, text: "< Back")
```

Set script to `res://scripts/screens/journal_screen.gd`.

- [ ] **Step 5.2 — Write the controller script**

Create `dragon-forge-godot/scripts/screens/journal_screen.gd`:

```gdscript
extends Control

signal navigate(target: String, context: Dictionary)

const SaveIO := preload("res://scripts/sim/save_io.gd")

@onready var scraps_label: Label = $TabContainer/Milestones/scraps_label
@onready var milestone_list: VBoxContainer = $TabContainer/Milestones/ScrollContainer/VBoxContainer
@onready var log_list: VBoxContainer = $TabContainer/Captain's Log/ScrollContainer/VBoxContainer
@onready var btn_back: Button = $btn_back

var _milestones: Array = []
var _lore: Array = []
var _save: Dictionary = {}

func _ready() -> void:
	btn_back.pressed.connect(func(): navigate.emit("world", {}))
	_load_data()

func _load_data() -> void:
	var f1 := FileAccess.open("res://data/journal_milestones.json", FileAccess.READ)
	if f1 != null:
		var p1 := JSON.parse_string(f1.get_as_text())
		f1.close()
		if typeof(p1) == TYPE_ARRAY:
			_milestones = p1
	var f2 := FileAccess.open("res://data/lore.json", FileAccess.READ)
	if f2 != null:
		var p2 := JSON.parse_string(f2.get_as_text())
		f2.close()
		if typeof(p2) == TYPE_ARRAY:
			_lore = p2

func open(save_state: Dictionary) -> void:
	_save = save_state.duplicate(true)
	scraps_label.text = "Scraps: %d" % SaveIO.get_scraps(_save)
	_build_milestones()
	_build_log()

func _build_milestones() -> void:
	for child in milestone_list.get_children():
		child.queue_free()
	var claimed: Array = _save.get("journal", {}).get("claimedMilestones", [])
	var stats: Dictionary = _save.get("stats", {})
	for ms in _milestones:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "%s — %s" % [str(ms.get("title", "")), str(ms.get("description", ""))]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn := Button.new()
		var ms_id: String = str(ms.get("id", ""))
		if claimed.has(ms_id):
			btn.text = "Claimed"
			btn.disabled = true
		elif _condition_met(ms.get("condition", {}), stats):
			btn.text = "Claim (%d scraps)" % int(ms.get("reward", 0))
			btn.pressed.connect(_on_claim.bind(ms))
		else:
			btn.text = "Locked"
			btn.disabled = true
		row.add_child(lbl)
		row.add_child(btn)
		milestone_list.add_child(row)

func _condition_met(cond: Dictionary, stats: Dictionary) -> bool:
	var ctype: String = str(cond.get("type", ""))
	var val: int = int(cond.get("value", 0))
	match ctype:
		"battles_won":
			return int(stats.get("battlesWon", 0)) >= val
		"max_stage":
			return int(stats.get("maxStageReached", 0)) >= val
		"eggs_hatched":
			return int(stats.get("eggsHatched", 0)) >= val
		"singularity_defeated":
			var prog := SaveIO.get_singularity_progress(_save)
			return prog.get("defeated", []).size() >= val
	return false

func _on_claim(ms: Dictionary) -> void:
	var reward := int(ms.get("reward", 0))
	var ms_id: String = str(ms.get("id", ""))
	_save = SaveIO.add_scraps(_save, reward)
	var j: Dictionary = _save.get("journal", {"claimedMilestones": []}).duplicate(true)
	var c: Array = j.get("claimedMilestones", [])
	c.append(ms_id)
	j["claimedMilestones"] = c
	_save["journal"] = j
	SaveIO.write_save(_save)
	scraps_label.text = "Scraps: %d" % SaveIO.get_scraps(_save)
	_build_milestones()

func _build_log() -> void:
	for child in log_list.get_children():
		child.queue_free()
	for entry in _lore:
		var lbl := Label.new()
		lbl.text = "[%s]\n%s" % [str(entry.get("title", "")), str(entry.get("body", ""))]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		log_list.add_child(lbl)
```

- [ ] **Step 5.3 — Wire into `main.gd` + commit**

Add `journal_scene`, connect navigate, handle `"journal"` in `_on_screen_navigate`, add to `_hide_all_screens()`.

```powershell
git add dragon-forge-godot/scenes/screens/journal_screen.tscn dragon-forge-godot/scripts/screens/journal_screen.gd dragon-forge-godot/scripts/main.gd
git commit -m "Add Journal screen (Plan 5)"
```

---

## Task 6: Stats Screen

Vite equivalent: `src/StatsScreen.jsx`.

**Files:**
- Create: `dragon-forge-godot/scenes/screens/stats_screen.tscn`
- Create: `dragon-forge-godot/scripts/screens/stats_screen.gd`

- [ ] **Step 6.1 — Create the scene**

```
StatsScreen (Control, full-rect anchor)
  VBoxContainer
    Label (text: "Stats")
    ScrollContainer
      VBoxContainer (id: stats_list)
    Label (text: "Dragon Roster")
    ScrollContainer
      VBoxContainer (id: roster_list)
    Button (id: btn_back, text: "< Back")
```

Set script to `res://scripts/screens/stats_screen.gd`.

- [ ] **Step 6.2 — Write the controller script**

Create `dragon-forge-godot/scripts/screens/stats_screen.gd`:

```gdscript
extends Control

signal navigate(target: String, context: Dictionary)

const SaveIO := preload("res://scripts/sim/save_io.gd")
const DragonData := preload("res://scripts/sim/dragon_data.gd")

@onready var stats_list: VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var roster_list: VBoxContainer = $VBoxContainer/ScrollContainer2/VBoxContainer
@onready var btn_back: Button = $VBoxContainer/btn_back

var _save: Dictionary = {}

func _ready() -> void:
	btn_back.pressed.connect(func(): navigate.emit("world", {}))

func open(save_state: Dictionary) -> void:
	_save = save_state.duplicate(true)
	_build_stats()
	_build_roster()

func _build_stats() -> void:
	for child in stats_list.get_children():
		child.queue_free()
	var stats: Dictionary = _save.get("stats", {})
	var records: Dictionary = _save.get("records", {})
	var all_stats := stats.duplicate(true)
	all_stats.merge(records)
	for key in all_stats.keys():
		var lbl := Label.new()
		lbl.text = "%s: %s" % [str(key), str(all_stats[key])]
		stats_list.add_child(lbl)

func _build_roster() -> void:
	for child in roster_list.get_children():
		child.queue_free()
	var profile: Dictionary = _save.get("profile", {})
	var dragons_owned: Array = profile.get("dragons_owned", [profile.get("active_dragon_id", "fire")])
	for dragon_id in dragons_owned:
		var def: Dictionary = DragonData.DRAGONS.get(dragon_id, {})
		if def.is_empty():
			continue
		var lbl := Label.new()
		var level: int = int(profile.get("dragon_level", {}).get(dragon_id, 1))
		var shiny: bool = bool(profile.get("shiny_dragons", {}).get(dragon_id, false))
		var stage: int = DragonData.get_stage_for_level(level)
		lbl.text = "%s  |  Lv %d  |  Stage %d  |  %s%s" % [
			str(def.get("name", dragon_id)),
			level, stage,
			str(def.get("element", "")),
			"  ✦ SHINY" if shiny else "",
		]
		roster_list.add_child(lbl)
```

- [ ] **Step 6.3 — Wire into `main.gd` + commit**

```powershell
git add dragon-forge-godot/scenes/screens/stats_screen.tscn dragon-forge-godot/scripts/screens/stats_screen.gd dragon-forge-godot/scripts/main.gd
git commit -m "Add Stats screen (Plan 5)"
```

---

## Task 7: Settings Screen

Vite equivalent: `src/SettingsScreen.jsx`.

**Files:**
- Create: `dragon-forge-godot/scenes/screens/settings_screen.tscn`
- Create: `dragon-forge-godot/scripts/screens/settings_screen.gd`

- [ ] **Step 7.1 — Create the scene**

```
SettingsScreen (Control, full-rect anchor)
  VBoxContainer
    Label (text: "Settings")
    HBoxContainer
      Label (text: "Music Volume")
      HSlider (id: music_slider, min_value: 0, max_value: 1, step: 0.05)
    HBoxContainer
      Label (text: "SFX Volume")
      HSlider (id: sfx_slider, min_value: 0, max_value: 1, step: 0.05)
    Button (id: btn_reset, text: "Reset Save")
    Label (id: confirm_label, visible: false)
    HBoxContainer (id: confirm_row, visible: false)
      Button (id: btn_confirm_yes, text: "Yes, Reset")
      Button (id: btn_confirm_no, text: "Cancel")
    Button (id: btn_back, text: "< Back")
```

Set script to `res://scripts/screens/settings_screen.gd`.

- [ ] **Step 7.2 — Write the controller script**

Create `dragon-forge-godot/scripts/screens/settings_screen.gd`:

```gdscript
extends Control

signal navigate(target: String, context: Dictionary)

const SaveIO := preload("res://scripts/sim/save_io.gd")
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

@onready var music_slider: HSlider = $VBoxContainer/HBoxContainer/music_slider
@onready var sfx_slider: HSlider = $VBoxContainer/HBoxContainer2/sfx_slider
@onready var btn_reset: Button = $VBoxContainer/btn_reset
@onready var confirm_label: Label = $VBoxContainer/confirm_label
@onready var confirm_row: HBoxContainer = $VBoxContainer/confirm_row
@onready var btn_back: Button = $VBoxContainer/btn_back

func _ready() -> void:
	btn_back.pressed.connect(func(): navigate.emit("world", {}))
	btn_reset.pressed.connect(_on_reset_pressed)
	$VBoxContainer/confirm_row/btn_confirm_yes.pressed.connect(_on_confirm_reset)
	$VBoxContainer/confirm_row/btn_confirm_no.pressed.connect(_dismiss_confirm)
	music_slider.value_changed.connect(_on_music_volume)
	sfx_slider.value_changed.connect(_on_sfx_volume)

func open(_save: Dictionary) -> void:
	var music_idx := AudioServer.get_bus_index(MUSIC_BUS)
	var sfx_idx := AudioServer.get_bus_index(SFX_BUS)
	if music_idx >= 0:
		music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_idx))
	if sfx_idx >= 0:
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_idx))

func _on_music_volume(val: float) -> void:
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(val))

func _on_sfx_volume(val: float) -> void:
	var idx := AudioServer.get_bus_index(SFX_BUS)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(val))

func _on_reset_pressed() -> void:
	confirm_label.text = "Reset all save data? This cannot be undone."
	confirm_label.visible = true
	confirm_row.visible = true

func _on_confirm_reset() -> void:
	SaveIO.write_save(SaveIO._default_save())
	_dismiss_confirm()
	navigate.emit("world", {})

func _dismiss_confirm() -> void:
	confirm_label.visible = false
	confirm_row.visible = false
```

- [ ] **Step 7.3 — Add Music and SFX audio buses**

In Godot editor: Project → Project Settings → Audio → add buses named exactly `Music` and `SFX` as children of Master.

- [ ] **Step 7.4 — Wire into `main.gd` + commit**

```powershell
git add dragon-forge-godot/scenes/screens/settings_screen.tscn dragon-forge-godot/scripts/screens/settings_screen.gd dragon-forge-godot/scripts/main.gd dragon-forge-godot/default_bus_layout.tres
git commit -m "Add Settings screen and audio buses (Plan 5)"
```

---

## Task 8: Singularity Screen

Vite equivalent: `src/SingularityScreen.jsx`.

**Files:**
- Create: `dragon-forge-godot/scenes/screens/singularity_screen.tscn`
- Create: `dragon-forge-godot/scripts/screens/singularity_screen.gd`

- [ ] **Step 8.1 — Create the scene**

```
SingularityScreen (Control, full-rect anchor)
  CanvasModulate (id: corruption_tint, color: white)
  VBoxContainer
    Label (text: "The Singularity")
    Label (id: felix_quote_label)
    ScrollContainer
      VBoxContainer (id: boss_list)
    Button (id: btn_back, text: "< Back")
```

Set script to `res://scripts/screens/singularity_screen.gd`.

- [ ] **Step 8.2 — Write the controller script**

Create `dragon-forge-godot/scripts/screens/singularity_screen.gd`:

```gdscript
extends Control

signal navigate(target: String, context: Dictionary)

const SaveIO := preload("res://scripts/sim/save_io.gd")

# Corruption tint per stage (0-4). Stage 0 = white (none).
const CORRUPTION_TINTS := [
	Color(1.0, 1.0, 1.0),        # stage 0 — clean
	Color(1.0, 0.9, 0.9),        # stage 1 — faint pink
	Color(0.9, 0.7, 0.7),        # stage 2 — light red
	Color(0.7, 0.4, 0.4),        # stage 3 — heavy red
	Color(0.4, 0.2, 0.4),        # stage 4 — deep corruption purple
]

@onready var corruption_tint: CanvasModulate = $corruption_tint
@onready var felix_quote_label: Label = $VBoxContainer/felix_quote_label
@onready var boss_list: VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var btn_back: Button = $VBoxContainer/btn_back

var _boss_data: Dictionary = {}
var _save: Dictionary = {}

func _ready() -> void:
	btn_back.pressed.connect(func(): navigate.emit("world", {}))
	_load_boss_data()

func _load_boss_data() -> void:
	var file := FileAccess.open("res://data/singularity_bosses.json", FileAccess.READ)
	if file == null:
		push_error("SingularityScreen: cannot open singularity_bosses.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_boss_data = parsed

func open(save_state: Dictionary) -> void:
	_save = save_state.duplicate(true)
	_apply_corruption_tint()
	_build_boss_list()

func _apply_corruption_tint() -> void:
	var prog := SaveIO.get_singularity_progress(_save)
	var defeated_count: int = prog.get("defeated", []).size()
	var stage: int = mini(defeated_count, 4)
	corruption_tint.color = CORRUPTION_TINTS[stage]

func _build_boss_list() -> void:
	for child in boss_list.get_children():
		child.queue_free()
	var prog := SaveIO.get_singularity_progress(_save)
	var defeated: Array = prog.get("defeated", [])
	var bosses: Array = _boss_data.get("bosses", [])
	for boss in bosses:
		_add_boss_row(boss, defeated)
	# Final boss
	var final_boss: Dictionary = _boss_data.get("final_boss", {})
	if not final_boss.is_empty():
		_add_boss_row(final_boss, defeated, true)

func _add_boss_row(boss: Dictionary, defeated: Array, is_final: bool = false) -> void:
	var boss_id: String = str(boss.get("id", ""))
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = str(boss.get("name", ""))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var status_lbl := Label.new()
	var btn := Button.new()
	var unlock_req = boss.get("unlock_requires", null)
	var unlocked: bool = (unlock_req == null or defeated.has(str(unlock_req)))
	if defeated.has(boss_id) or (is_final and bool(_save.get("singularityComplete", false))):
		status_lbl.text = "Defeated"
		btn.text = "Rematch"
		btn.disabled = false
	elif unlocked:
		status_lbl.text = "Available"
		btn.text = "Engage"
		btn.disabled = false
	else:
		status_lbl.text = "Locked"
		btn.text = "Locked"
		btn.disabled = true
	btn.pressed.connect(_on_engage.bind(boss, is_final))
	if not is_final:
		felix_quote_label.text = str(boss.get("felix_quote", ""))
	row.add_child(lbl)
	row.add_child(status_lbl)
	row.add_child(btn)
	boss_list.add_child(row)

func _on_engage(boss: Dictionary, is_final: bool) -> void:
	felix_quote_label.text = str(boss.get("felix_quote", ""))
	navigate.emit("battle", {
		"dragon_id": _save.get("active_dragon_id", "fire"),
		"npc_id": str(boss.get("id", "")),
		"is_singularity": true,
		"is_final": is_final,
		"return_screen": "singularity",
	})
```

- [ ] **Step 8.3 — Wire into `main.gd` + commit**

Add `singularity_scene`, connect navigate, handle `"singularity"` in `_on_screen_navigate` with `_play_music_context("singularity_tension")`, add to `_hide_all_screens()`.

```powershell
git add dragon-forge-godot/scenes/screens/singularity_screen.tscn dragon-forge-godot/scripts/screens/singularity_screen.gd dragon-forge-godot/scripts/main.gd
git commit -m "Add Singularity screen (Plan 5)"
```

---

## Task 9: Smoke Test All Screens + Final Commit

- [ ] **Step 9.1 — Add screen smoke assertions**

Append to `dragon-forge-godot/scripts/tests/sim_smoke.gd`:

```gdscript
const CampaignMapScreen := preload("res://scenes/screens/campaign_map_screen.tscn")
const ShopScreen        := preload("res://scenes/screens/shop_screen.tscn")
const ForgeScreen       := preload("res://scenes/screens/forge_screen.tscn")
const JournalScreen     := preload("res://scenes/screens/journal_screen.tscn")
const StatsScreen       := preload("res://scenes/screens/stats_screen.tscn")
const SettingsScreen    := preload("res://scenes/screens/settings_screen.tscn")
const SingularityScreen := preload("res://scenes/screens/singularity_screen.tscn")

func _assert_all_screens_load() -> void:
	for scn in [CampaignMapScreen, ShopScreen, ForgeScreen, JournalScreen, StatsScreen, SettingsScreen, SingularityScreen]:
		var inst := scn.instantiate()
		assert(inst != null, "Screen instantiates without error")
		inst.free()
```

Call `_assert_all_screens_load()` from `_init()`.

- [ ] **Step 9.2 — Run full smoke test**

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' --script res://scripts/tests/sim_smoke.gd
```

Expected: exit code `0`.

- [ ] **Step 9.3 — Final commit**

```powershell
git add dragon-forge-godot/scripts/tests/sim_smoke.gd
git commit -m "Plan 5 complete: all 7 supporting screens built and smoke tested"
```
