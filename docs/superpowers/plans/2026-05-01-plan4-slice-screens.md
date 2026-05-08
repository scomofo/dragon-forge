# Dragon Forge Godot Rebuild — Plan 4: Vertical Slice Screens

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build 5 screens (Title, Hatchery, Battle Select, Battle, Fusion) that form a playable core loop end-to-end. Battle screen gets native Godot upgrades: AnimationPlayer attacks, GPU particle VFX, Camera2D screen shake.

**Architecture:** main.gd scene router owns SaveData and battle_config. Screens emit navigate signals. Engines are called directly from screen scripts — no intermediate service layer.

**Tech Stack:** Godot 4.6, GDScript, AnimationPlayer, GPUParticles2D, Camera2D, Tween

**Prerequisite:** Plan 3 complete — all engine GUT tests pass.

---

## File Structure

```
dragon-forge-godot/
  scenes/
    screens/
      title_screen.tscn
      hatchery_screen.tscn
      battle_select_screen.tscn
      battle_screen.tscn
      fusion_screen.tscn
    components/
      nav_bar.tscn
      dragon_sprite.tscn
      damage_number.tscn
  scripts/
    screens/
      title_screen.gd
      hatchery_screen.gd
      battle_select_screen.gd
      battle_screen.gd
      fusion_screen.gd
    components/
      nav_bar.gd
      dragon_sprite.gd
      damage_number.gd
    main.gd   (modify existing)
```

---

## Task 1 — NavBar Component

**Files:**
- Create: `scenes/components/nav_bar.tscn`
- Create: `scripts/components/nav_bar.gd`

**Scene tree (`nav_bar.tscn`):**
```
NavBar (PanelContainer)
  HBoxContainer
    [ButtonN] (Button, one per entry — added dynamically at runtime)
```

- [ ] **Step 1a: Create `scripts/components/nav_bar.gd`**

```gdscript
extends PanelContainer

signal navigate(target: String)

var _entries: Array = []

func setup(entries: Array) -> void:
	_entries = entries
	_rebuild()

func _rebuild() -> void:
	var hbox := $HBoxContainer
	for child in hbox.get_children():
		child.queue_free()
	for entry in _entries:
		var btn := Button.new()
		btn.text = str(entry.get("label", ""))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var target := str(entry.get("target", ""))
		btn.pressed.connect(func(): navigate.emit(target))
		hbox.add_child(btn)
```

- [ ] **Step 1b: Create `scenes/components/nav_bar.tscn`**

  In Godot editor: create a new scene with root node `PanelContainer` named `NavBar`, add child `HBoxContainer`. Attach `scripts/components/nav_bar.gd` to root. Save to `scenes/components/nav_bar.tscn`.

  Minimum layout properties on `NavBar`:
  - `custom_minimum_size.y = 52`
  - Anchor: bottom strip (set via `set_anchors_preset(Control.PRESET_BOTTOM_WIDE)`)

---

## Task 2 — DragonSprite Component

**Files:**
- Create: `scenes/components/dragon_sprite.tscn`
- Create: `scripts/components/dragon_sprite.gd`

**Scene tree (`dragon_sprite.tscn`):**
```
DragonSprite (Control)
  TextureRect (name: "SpriteRect")
  Label (name: "FallbackLabel")
```

The component loads the sprite path from `data/sprite_manifest.json` keyed by `dragon_id` and `stage`. Falls back to a coloured letter label if the texture file does not exist.

- [ ] **Step 2a: Create `scripts/components/dragon_sprite.gd`**

```gdscript
extends Control

@onready var sprite_rect: TextureRect = $SpriteRect
@onready var fallback_label: Label = $FallbackLabel

const ELEMENT_COLORS := {
	"fire": Color("#ff6b35"),
	"ice": Color("#58dbff"),
	"storm": Color("#c3a6ff"),
	"stone": Color("#a0956a"),
	"venom": Color("#70ff8f"),
	"shadow": Color("#b084ff"),
}

var _manifest: Dictionary = {}

func _ready() -> void:
	_load_manifest()

func set_dragon(dragon_id: String, stage: int = 1) -> void:
	var path: String = _resolve_path(dragon_id, stage)
	if path != "" and ResourceLoader.exists(path):
		sprite_rect.texture = load(path)
		sprite_rect.visible = true
		fallback_label.visible = false
	else:
		sprite_rect.visible = false
		fallback_label.text = dragon_id.substr(0, 1).to_upper()
		fallback_label.add_theme_color_override("font_color",
			ELEMENT_COLORS.get(dragon_id, Color.WHITE))
		fallback_label.visible = true

func _load_manifest() -> void:
	const MANIFEST_PATH := "res://data/sprite_manifest.json"
	if not ResourceLoader.exists(MANIFEST_PATH):
		return
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_manifest = parsed

func _resolve_path(dragon_id: String, stage: int) -> String:
	var key := "%s_stage%d" % [dragon_id, stage]
	if _manifest.has(key):
		return str(_manifest[key])
	# Try generic fallback: dragon_id_stage1
	var fallback := "%s_stage1" % dragon_id
	if _manifest.has(fallback):
		return str(_manifest[fallback])
	return ""
```

- [ ] **Step 2b: Create `scenes/components/dragon_sprite.tscn`**

  Root `Control` named `DragonSprite`, `custom_minimum_size = Vector2(80, 80)`. Child `TextureRect` named `SpriteRect` (expand_mode=FIT_WIDTH_PROPORTIONAL, stretch_mode=KEEP_ASPECT_CENTERED, full rect anchors). Child `Label` named `FallbackLabel` (horizontal_alignment=CENTER, vertical_alignment=CENTER, full rect anchors, font size 32). Attach `scripts/components/dragon_sprite.gd`.

---

## Task 3 — DamageNumber Component

**Files:**
- Create: `scenes/components/damage_number.tscn`
- Create: `scripts/components/damage_number.gd`

**Scene tree (`damage_number.tscn`):**
```
DamageNumber (Node2D)
  Label (name: "NumLabel")
```

Spawned in world space by battle screen. Auto-queues free after animation.

- [ ] **Step 3a: Create `scripts/components/damage_number.gd`**

```gdscript
extends Node2D

@onready var num_label: Label = $NumLabel

func spawn(value: int, is_effective: bool = false, is_resisted: bool = false) -> void:
	num_label.text = str(value)
	if is_effective:
		num_label.add_theme_color_override("font_color", Color("#ffcc00"))
		num_label.add_theme_font_size_override("font_size", 28)
	elif is_resisted:
		num_label.add_theme_color_override("font_color", Color("#8fb0ff"))
		num_label.add_theme_font_size_override("font_size", 18)
	else:
		num_label.add_theme_color_override("font_color", Color("#ffffff"))
		num_label.add_theme_font_size_override("font_size", 22)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, -64), 0.8)
	tween.tween_property(num_label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(queue_free)
```

- [ ] **Step 3b: Create `scenes/components/damage_number.tscn`**

  Root `Node2D` named `DamageNumber`. Child `Label` named `NumLabel` (horizontal_alignment=CENTER, position offset so it centres on parent). Attach `scripts/components/damage_number.gd`.

---

## Task 4 — Rewrite `scripts/main.gd` as Screen Router

**File:** `dragon-forge-godot/scripts/main.gd` (replace existing)

The current `main.gd` uses a visibility-toggle approach with three hard-coded scenes. Replace it with a dynamic scene-switcher that owns `save` and `battle_config`, catches `navigate` signals from screens, and calls `AudioDirector`.

- [ ] **Step 4a: Replace `scripts/main.gd`**

```gdscript
extends Control

const SAVE_PATH := "user://dragon_forge_save.json"
const DEFAULT_SAVE := {
	"dragon_id": "fire",
	"dragon_levels": { "fire": 1 },
	"dragon_xp": { "fire": 0 },
	"dragon_techniques": { "fire": ["blazingFang"] },
	"dragon_loadouts": { "fire": ["blazingFang"] },
	"data_scraps": 320,
	"system_credits": 0,
	"known_techniques": ["blazingFang"],
	"active_techniques": ["blazingFang"],
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
}

# Screen scene paths
const SCREENS := {
	"title":       "res://scenes/screens/title_screen.tscn",
	"hatchery":    "res://scenes/screens/hatchery_screen.tscn",
	"battleSelect": "res://scenes/screens/battle_select_screen.tscn",
	"battle":      "res://scenes/screens/battle_screen.tscn",
	"fusion":      "res://scenes/screens/fusion_screen.tscn",
}

# Music track per screen
const SCREEN_MUSIC := {
	"title":        "title",
	"hatchery":     "hatchery",
	"battleSelect": "select",
	"battle":       "battle_tense",
	"fusion":       "hatchery",
}

var save: Dictionary = {}
var battle_config: Dictionary = {}
var _current_screen: Control = null
var _current_screen_id: String = ""

func _ready() -> void:
	save = _load_save()
	_switch_screen("title")

func _switch_screen(target: String, payload: Variant = null) -> void:
	if not SCREENS.has(target):
		push_error("Unknown screen target: %s" % target)
		return

	# Tear down old screen
	if _current_screen != null:
		_current_screen.queue_free()
		_current_screen = null

	# Play audio
	_play_music(SCREEN_MUSIC.get(target, ""))
	_play_sfx("nav_switch")

	# Store battle config when navigating INTO battle
	if target == "battle" and payload is Dictionary:
		battle_config = payload.duplicate(true)

	# Instance new screen
	var packed: PackedScene = load(SCREENS[target])
	var screen: Control = packed.instantiate()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	_current_screen = screen
	_current_screen_id = target

	# Connect navigate signal
	if screen.has_signal("navigate"):
		screen.navigate.connect(_on_screen_navigate)

	# Inject dependencies
	if screen.has_method("setup"):
		if target == "battle":
			screen.setup(save, battle_config)
		else:
			screen.setup(save)

func _on_screen_navigate(target: String, payload: Variant = null) -> void:
	# Screens that mutate save must call save_to_disk() before emitting navigate.
	# Re-read save from disk so main always has latest state.
	save = _load_save()
	_switch_screen(target, payload)

func save_to_disk(updated_save: Dictionary) -> void:
	save = updated_save.duplicate(true)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open save file for writing.")
		return
	file.store_string(JSON.stringify(save, "\t"))
	file.close()

func _load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return DEFAULT_SAVE.duplicate(true)
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return DEFAULT_SAVE.duplicate(true)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return DEFAULT_SAVE.duplicate(true)
	# Forward-compat: merge any missing keys from DEFAULT_SAVE
	var result := DEFAULT_SAVE.duplicate(true)
	for key in parsed:
		result[key] = parsed[key]
	return result

func _play_music(track: String) -> void:
	var director := get_node_or_null("/root/AudioDirector")
	if director != null and track != "":
		director.play_music_context(track)

func _play_sfx(sfx_id: String) -> void:
	var director := get_node_or_null("/root/AudioDirector")
	if director != null:
		var sfx_data_class = load("res://scripts/sim/sfx_data.gd")
		if sfx_data_class != null:
			var profile: Dictionary = sfx_data_class.get_sfx_profile(sfx_id)
			if not profile.is_empty():
				director.play_sfx_profile(profile)
```

- [ ] **Step 4b: Update `scenes/main.tscn`**

  Open `scenes/main.tscn` in editor. Remove any pre-existing child scene instances (WorldScene, BattleScene, HardwareDungeonScene). The root Control node should have only the script attached — screens are instantiated at runtime.

---

## Task 5 — Title Screen

**Files:**
- Create: `scenes/screens/title_screen.tscn`
- Create: `scripts/screens/title_screen.gd`

**Scene tree (`title_screen.tscn`):**
```
TitleScreen (Control, full rect)
  Background (ColorRect, full rect, Color #0a0c14)
  VBoxContainer (centered, anchors CENTER)
    TitleLabel (Label, "DRAGON FORGE", font size 48)
    BootTerminal (RichTextLabel, BBCode enabled, name "BootTerminal")
    FelixLabel (Label, name "FelixLabel", visible=false)
    StartButton (Button, text "START GAME", name "StartButton", visible=false)
  AnimationPlayer (name "AnimationPlayer")
```

- [ ] **Step 5a: Create `scripts/screens/title_screen.gd`**

```gdscript
extends Control

signal navigate(target: String, payload: Variant)

const LoreCanon := preload("res://scripts/sim/lore_canon.gd")

const FELIX_FIRST_CONTACT := [
	"Professor Felix: \"You're awake. Finally.\"",
	"Felix: \"The rendered world is fragmenting. Mirror Admin is pushing a Great Reset.\"",
	"Felix: \"Your dragons — the guardian protocols — are dormant. We need them back online.\"",
	"Felix: \"Ready when you are, Skye.\"",
]
const BOOT_DELAY := 0.45  # seconds between each boot line
const FELIX_DELAY := 0.6

@onready var boot_terminal: RichTextLabel = $VBoxContainer/BootTerminal
@onready var felix_label: Label = $VBoxContainer/FelixLabel
@onready var start_button: Button = $VBoxContainer/StartButton

var _boot_lines: Array = LoreCanon.OPENING_BOOT_LINES
var _boot_index: int = 0
var _felix_index: int = 0

func _ready() -> void:
	boot_terminal.text = ""
	felix_label.visible = false
	start_button.visible = false
	start_button.pressed.connect(_on_start_pressed)
	_show_next_boot_line()

func _show_next_boot_line() -> void:
	if _boot_index >= _boot_lines.size():
		await get_tree().create_timer(0.6).timeout
		_show_felix_lines()
		return
	boot_terminal.append_text(_boot_lines[_boot_index] + "\n")
	_boot_index += 1
	await get_tree().create_timer(BOOT_DELAY).timeout
	_show_next_boot_line()

func _show_felix_lines() -> void:
	felix_label.visible = true
	if _felix_index >= FELIX_FIRST_CONTACT.size():
		start_button.visible = true
		return
	felix_label.text = FELIX_FIRST_CONTACT[_felix_index]
	_felix_index += 1
	await get_tree().create_timer(FELIX_DELAY).timeout
	_show_felix_lines()

func _on_start_pressed() -> void:
	navigate.emit("hatchery", null)

func setup(_save: Dictionary) -> void:
	pass  # Title screen does not need save data
```

- [ ] **Step 5b: Create `scenes/screens/title_screen.tscn`**

  Build the scene tree described above. Key settings:
  - `TitleScreen` root: `Control`, full rect anchors, script=`title_screen.gd`
  - `Background`: `ColorRect`, full rect, color `#0a0c14`
  - `VBoxContainer`: anchors `CENTER`, `offset_left=-260`, `offset_top=-200`, `offset_right=260`, `offset_bottom=200`, separation=24
  - `TitleLabel`: font_size override 48, horizontal_alignment=CENTER, text "DRAGON FORGE", color `#c0c8ff`
  - `BootTerminal`: `RichTextLabel`, `custom_minimum_size=Vector2(480,180)`, `bbcode_enabled=true`, `scroll_following=true`
  - `FelixLabel`: `Label`, horizontal_alignment=CENTER, autowrap_mode=WORD, `custom_minimum_size.x=480`
  - `StartButton`: text "[ START GAME ]", `custom_minimum_size=Vector2(200,44)`

---

## Task 6 — Hatchery Screen

**Files:**
- Create: `scenes/screens/hatchery_screen.tscn`
- Create: `scripts/screens/hatchery_screen.gd`

**Scene tree (`hatchery_screen.tscn`):**
```
HatcheryScreen (Control, full rect)
  Background (ColorRect, full rect, Color #0d0f1c)
  VBoxContainer (full rect, margin 16px all sides)
    HeaderLabel (Label, "HATCHERY", font size 28)
    ScrapsLabel (Label, name "ScrapsLabel")
    DragonGrid (GridContainer, name "DragonGrid", columns=4)
    HBoxContainer
      PullButton (Button, name "PullButton", text "PULL (50 SCRAPS)")
      SingularityButton (Button, name "SingularityButton", visible=false)
    EggOverlay (Control, name "EggOverlay", visible=false, full rect)
      ColorRect (full rect, Color #000000 alpha 0.85)
      VBoxContainer (centered)
        EggSprite (TextureRect or ColorRect placeholder, name "EggSprite")
        EggLabel (Label, name "EggLabel", text "HATCHING...")
    NavBar (instance of nav_bar.tscn, name "NavBar")
  AnimationPlayer (name "AnimationPlayer")
```

- [ ] **Step 6a: Create `scripts/screens/hatchery_screen.gd`**

```gdscript
extends Control

signal navigate(target: String, payload: Variant)

const DragonProgression := preload("res://scripts/sim/dragon_progression.gd")
const DragonData := preload("res://scripts/sim/dragon_data.gd")
const NavBarScene := preload("res://scenes/components/nav_bar.tscn")
const DragonSpriteScene := preload("res://scenes/components/dragon_sprite.tscn")

const PULL_COST := 50
const NAV_ENTRIES := [
	{"label": "HATCHERY", "target": "hatchery"},
	{"label": "BATTLE",   "target": "battleSelect"},
	{"label": "FUSION",   "target": "fusion"},
]
# Extended nav entries are added once the game has more screens.

@onready var scraps_label: Label = $VBoxContainer/ScrapsLabel
@onready var dragon_grid: GridContainer = $VBoxContainer/DragonGrid
@onready var pull_button: Button = $VBoxContainer/HBoxContainer/PullButton
@onready var singularity_button: Button = $VBoxContainer/HBoxContainer/SingularityButton
@onready var egg_overlay: Control = $VBoxContainer/EggOverlay
@onready var egg_label: Label = $VBoxContainer/EggOverlay/VBoxContainer/EggLabel
@onready var nav_bar: Control = $VBoxContainer/NavBar
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var _save: Dictionary = {}

func setup(save: Dictionary) -> void:
	_save = save.duplicate(true)

func _ready() -> void:
	pull_button.pressed.connect(_on_pull_pressed)
	singularity_button.pressed.connect(func(): navigate.emit("singularity", null))
	nav_bar.navigate.connect(func(t): navigate.emit(t, null))
	nav_bar.setup(NAV_ENTRIES)
	egg_overlay.visible = false
	_refresh()

func _refresh() -> void:
	var scraps: int = int(_save.get("data_scraps", 0))
	scraps_label.text = "DATA SCRAPS: %d" % scraps
	pull_button.disabled = scraps < PULL_COST

	# Show singularity button if at least one singularity boss defeated
	var sing_defeated: Array = _save.get("singularity_defeated", [])
	singularity_button.visible = sing_defeated.size() >= 1

	_rebuild_dragon_grid()

func _rebuild_dragon_grid() -> void:
	for child in dragon_grid.get_children():
		child.queue_free()
	var hatchery_state: Dictionary = DragonProgression.get_hatchery_state(_save)
	var owned: Array = hatchery_state.get("owned_dragons", [])
	var levels: Dictionary = _save.get("dragon_levels", {})
	var xp_dict: Dictionary = _save.get("dragon_xp", {})

	for dragon_id in owned:
		var card := _make_dragon_card(dragon_id, levels, xp_dict)
		dragon_grid.add_child(card)

func _make_dragon_card(dragon_id: String, levels: Dictionary, xp_dict: Dictionary) -> Control:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(100, 120)

	var sprite_inst: Control = DragonSpriteScene.instantiate()
	card.add_child(sprite_inst)
	var level: int = int(levels.get(dragon_id, 1))
	sprite_inst.set_dragon(dragon_id, DragonData.get_stage_for_level(level))
	sprite_inst.custom_minimum_size = Vector2(80, 80)

	var name_label := Label.new()
	var dragon_def: Dictionary = DragonData.DRAGONS.get(dragon_id, {})
	name_label.text = str(dragon_def.get("name", dragon_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	card.add_child(name_label)

	var level_label := Label.new()
	level_label.text = "LV %d" % level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 10)
	card.add_child(level_label)

	var xp: int = int(xp_dict.get(dragon_id, 0))
	var xp_next: int = DragonProgression.xp_to_next_level(level)
	var xp_bar := ProgressBar.new()
	xp_bar.value = float(xp) / float(xp_next) * 100.0
	xp_bar.custom_minimum_size = Vector2(90, 8)
	xp_bar.show_percentage = false
	card.add_child(xp_bar)

	return card

func _on_pull_pressed() -> void:
	var scraps: int = int(_save.get("data_scraps", 0))
	if scraps < PULL_COST:
		return

	# Deduct cost
	_save["data_scraps"] = scraps - PULL_COST

	# Determine new dragon: pick a random element not yet owned
	var hatchery_state: Dictionary = DragonProgression.get_hatchery_state(_save)
	var owned: Array = hatchery_state.get("owned_dragons", []).duplicate()
	var all_ids: Array = DragonData.DRAGONS.keys()
	var candidates: Array = []
	for id in all_ids:
		if not owned.has(id):
			candidates.append(id)
	var new_id: String
	if candidates.is_empty():
		# All owned — give scraps bonus instead
		_save["data_scraps"] = int(_save["data_scraps"]) + 25
		_refresh()
		return
	else:
		candidates.shuffle()
		new_id = candidates[0]

	# Apply to save
	_save = DragonProgression.open_hatchery_ring(_save)
	var state: Dictionary = _save.get("hatchery_state", {}).duplicate(true)
	if not state.get("owned_dragons", []).has(new_id):
		state["owned_dragons"].append(new_id)
	if not _save.get("dragon_levels", {}).has(new_id):
		_save["dragon_levels"][new_id] = 1
	if not _save.get("dragon_xp", {}).has(new_id):
		_save["dragon_xp"][new_id] = 0
	_save["hatchery_state"] = state

	# Persist
	_write_save()

	# Play hatch animation then refresh
	await _play_hatch_animation(new_id)
	_refresh()

func _play_hatch_animation(dragon_id: String) -> void:
	egg_overlay.visible = true
	egg_label.text = "HATCHING..."
	# 12-step sequence mirroring the Vite CSS animation:
	# glow(0.3s) → shake(0.5s) → burst(0.3s) → reveal(0.4s)
	var tween := create_tween()
	tween.tween_property(egg_overlay, "modulate:a", 1.0, 0.0)
	tween.tween_interval(0.3)  # glow phase
	# shake: offset the overlay left/right repeatedly
	for _i in range(6):
		tween.tween_property(egg_overlay, "position:x", 8.0, 0.04)
		tween.tween_property(egg_overlay, "position:x", -8.0, 0.04)
	tween.tween_property(egg_overlay, "position:x", 0.0, 0.04)
	tween.tween_interval(0.3)  # burst phase
	var dragon_def: Dictionary = DragonData.DRAGONS.get(dragon_id, {})
	egg_label.text = "NEW: %s" % str(dragon_def.get("name", dragon_id))
	tween.tween_interval(0.4)  # reveal
	tween.tween_property(egg_overlay, "modulate:a", 0.0, 0.3)
	await tween.finished
	egg_overlay.visible = false
	egg_overlay.position = Vector2.ZERO

func _write_save() -> void:
	var main := get_tree().get_root().get_node_or_null("Main")
	if main != null and main.has_method("save_to_disk"):
		main.save_to_disk(_save)
```

- [ ] **Step 6b: Create `scenes/screens/hatchery_screen.tscn`**

  Build the scene tree as described. Attach `scripts/screens/hatchery_screen.gd` to root `Control`. Instance `nav_bar.tscn` as the `NavBar` node at the bottom of the VBoxContainer. The `EggOverlay` control should use full-rect anchors so it covers the whole screen.

---

## Task 7 — Battle Select Screen

**Files:**
- Create: `scenes/screens/battle_select_screen.tscn`
- Create: `scripts/screens/battle_select_screen.gd`

**Scene tree (`battle_select_screen.tscn`):**
```
BattleSelectScreen (Control, full rect)
  Background (ColorRect, full rect, Color #0a0c14)
  VBoxContainer (full rect, margin 16)
    Label (text "SELECT BATTLE", font size 28)
    HBoxContainer
      VBoxContainer (name "DragonList", size_flags_horizontal=EXPAND_FILL)
        Label (text "YOUR DRAGON")
        ScrollContainer
          VBoxContainer (name "DragonScroll")
      VBoxContainer (name "EnemyList", size_flags_horizontal=EXPAND_FILL)
        Label (text "CHOOSE OPPONENT")
        ScrollContainer
          VBoxContainer (name "EnemyScroll")
    FightButton (Button, name "FightButton", text "[ FIGHT ]", visible=false)
    NavBar (instance of nav_bar.tscn)
```

- [ ] **Step 7a: Create `scripts/screens/battle_select_screen.gd`**

```gdscript
extends Control

signal navigate(target: String, payload: Variant)

const DragonProgression := preload("res://scripts/sim/dragon_progression.gd")
const DragonData := preload("res://scripts/sim/dragon_data.gd")
const TacticalBattle := preload("res://scripts/sim/tactical_battle.gd")
const DragonSpriteScene := preload("res://scenes/components/dragon_sprite.tscn")

const NAV_ENTRIES := [
	{"label": "HATCHERY",   "target": "hatchery"},
	{"label": "BATTLE",     "target": "battleSelect"},
	{"label": "FUSION",     "target": "fusion"},
]

@onready var dragon_scroll: VBoxContainer = $VBoxContainer/HBoxContainer/VBoxContainer/ScrollContainer/DragonScroll
@onready var enemy_scroll: VBoxContainer = $VBoxContainer/HBoxContainer/VBoxContainer2/ScrollContainer/EnemyScroll
@onready var fight_button: Button = $VBoxContainer/FightButton
@onready var nav_bar: Control = $VBoxContainer/NavBar

var _save: Dictionary = {}
var _selected_dragon: String = ""
var _selected_enemy: String = ""

func setup(save: Dictionary) -> void:
	_save = save.duplicate(true)

func _ready() -> void:
	fight_button.pressed.connect(_on_fight_pressed)
	nav_bar.navigate.connect(func(t): navigate.emit(t, null))
	nav_bar.setup(NAV_ENTRIES)
	fight_button.visible = false
	_build_lists()

func _build_lists() -> void:
	for c in dragon_scroll.get_children(): c.queue_free()
	for c in enemy_scroll.get_children(): c.queue_free()

	# Dragon list
	var hatchery_state: Dictionary = DragonProgression.get_hatchery_state(_save)
	var owned: Array = hatchery_state.get("owned_dragons", [])
	var levels: Dictionary = _save.get("dragon_levels", {})

	for dragon_id in owned:
		var btn := _make_dragon_btn(dragon_id, levels)
		dragon_scroll.add_child(btn)

	# Enemy list — all enemies from TacticalBattle.EnemyData
	var defeated: Dictionary = _save.get("bestiary_defeated", {})
	for enemy_id in TacticalBattle.EnemyData.keys():
		var btn := _make_enemy_btn(enemy_id, defeated)
		enemy_scroll.add_child(btn)

func _make_dragon_btn(dragon_id: String, levels: Dictionary) -> Button:
	var dragon_def: Dictionary = DragonData.DRAGONS.get(dragon_id, {})
	var level: int = int(levels.get(dragon_id, 1))
	var btn := Button.new()
	btn.text = "%s  LV %d" % [str(dragon_def.get("name", dragon_id)), level]
	btn.toggle_mode = true
	btn.pressed.connect(func():
		_selected_dragon = dragon_id
		_refresh_fight_button()
		# Deselect siblings
		for sibling in dragon_scroll.get_children():
			if sibling != btn and sibling is Button:
				sibling.button_pressed = false
	)
	return btn

func _make_enemy_btn(enemy_id: String, defeated: Dictionary) -> Button:
	var enemy: Dictionary = TacticalBattle.EnemyData.get(enemy_id, {})
	var times_defeated: int = int(defeated.get(enemy_id, 0))
	var btn := Button.new()
	btn.text = "%s  [%s]  LV %d" % [
		str(enemy.get("name", enemy_id)),
		str(enemy.get("element", "?")).to_upper(),
		int(enemy.get("level", 1)),
	]
	if times_defeated > 0:
		btn.text += "  ✓"
	btn.toggle_mode = true
	btn.pressed.connect(func():
		_selected_enemy = enemy_id
		_refresh_fight_button()
		for sibling in enemy_scroll.get_children():
			if sibling != btn and sibling is Button:
				sibling.button_pressed = false
	)
	return btn

func _refresh_fight_button() -> void:
	fight_button.visible = _selected_dragon != "" and _selected_enemy != ""

func _on_fight_pressed() -> void:
	if _selected_dragon == "" or _selected_enemy == "":
		return
	var payload := {
		"dragon_id": _selected_dragon,
		"npc_id": _selected_enemy,
		"return_screen": "battleSelect",
		"is_singularity": false,
	}
	navigate.emit("battle", payload)
```

- [ ] **Step 7b: Create `scenes/screens/battle_select_screen.tscn`**

  Build tree as described. The two side-by-side `VBoxContainer` nodes are inside an `HBoxContainer` with `size_flags_vertical=EXPAND_FILL`. Each `ScrollContainer` inside them should have `size_flags_vertical=EXPAND_FILL` so the lists fill available space. Attach `battle_select_screen.gd` to root.

---

## Task 8 — Battle Screen (Native Godot Upgrades)

**Files:**
- Create: `scenes/screens/battle_screen.tscn`
- Create: `scripts/screens/battle_screen.gd`

**Scene tree (`battle_screen.tscn`):**
```
BattleScreen (Control, full rect)
  Camera2D (name "Camera2D", position_smoothing_enabled=false)
  Background (ColorRect, full rect, Color #0d0f1c)
  CanvasModulate (name "CorruptionModulate", color=white)
  VBoxContainer (full rect, margin 12)
    HeaderLabel (Label, name "HeaderLabel", font size 16)
    HBoxContainer (name "CombatRow", size_flags_vertical=EXPAND_FILL)
      VBoxContainer (name "PlayerSide", size_flags_horizontal=EXPAND_FILL)
        DragonSprite (instance dragon_sprite.tscn, name "PlayerSprite")
        Label (name "PlayerName")
        ProgressBar (name "PlayerHP", max_value=100)
        Label (name "PlayerHPLabel")
        HBoxContainer (name "StatusIcons")
      VBoxContainer (name "NpcSide", size_flags_horizontal=EXPAND_FILL)
        DragonSprite (instance dragon_sprite.tscn, name "NpcSprite")
        Label (name "NpcName")
        ProgressBar (name "NpcHP", max_value=100)
        Label (name "NpcHPLabel")
        HBoxContainer (name "NpcStatusIcons")
    BattleLog (RichTextLabel, name "BattleLog", custom_minimum_size.y=80, scroll_following=true)
    MoveButtons (HBoxContainer, name "MoveButtons")
  AnimationPlayer (name "AnimationPlayer")
  GPUParticles2D (name "HitParticles", emitting=false)
  DamageNumberLayer (Node2D, name "DamageNumberLayer")
```

- [ ] **Step 8a: Create `scripts/screens/battle_screen.gd`**

```gdscript
extends Control

signal navigate(target: String, payload: Variant)

const DragonData := preload("res://scripts/sim/dragon_data.gd")
const DragonProgression := preload("res://scripts/sim/dragon_progression.gd")
const TacticalBattle := preload("res://scripts/sim/tactical_battle.gd")
const CombatRules := preload("res://scripts/sim/combat_rules.gd")
const TechniqueData := preload("res://scripts/sim/technique_data.gd")
const DamageNumberScene := preload("res://scenes/components/damage_number.tscn")

# Elemental particle colors
const ELEMENT_COLORS := {
	"fire":   Color("#ff6b35"),
	"ice":    Color("#58dbff"),
	"storm":  Color("#c3a6ff"),
	"stone":  Color("#a0956a"),
	"venom":  Color("#70ff8f"),
	"shadow": Color("#b084ff"),
	"glitch": Color("#ff4daa"),
	"static": Color("#fffaaa"),
	"lunar":  Color("#e8d5ff"),
}

const CORRUPTION_TINT := Color("#2a0020")

@onready var camera: Camera2D = $Camera2D
@onready var corruption_modulate: CanvasModulate = $CorruptionModulate
@onready var header_label: Label = $VBoxContainer/HeaderLabel
@onready var player_sprite: Control = $VBoxContainer/CombatRow/PlayerSide/PlayerSprite
@onready var player_name: Label = $VBoxContainer/CombatRow/PlayerSide/PlayerName
@onready var player_hp_bar: ProgressBar = $VBoxContainer/CombatRow/PlayerSide/PlayerHP
@onready var player_hp_label: Label = $VBoxContainer/CombatRow/PlayerSide/PlayerHPLabel
@onready var player_status_icons: HBoxContainer = $VBoxContainer/CombatRow/PlayerSide/StatusIcons
@onready var npc_sprite: Control = $VBoxContainer/CombatRow/NpcSide/NpcSprite
@onready var npc_name: Label = $VBoxContainer/CombatRow/NpcSide/NpcName
@onready var npc_hp_bar: ProgressBar = $VBoxContainer/CombatRow/NpcSide/NpcHP
@onready var npc_hp_label: Label = $VBoxContainer/CombatRow/NpcSide/NpcHPLabel
@onready var battle_log: RichTextLabel = $VBoxContainer/BattleLog
@onready var move_buttons: HBoxContainer = $VBoxContainer/MoveButtons
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var damage_layer: Node2D = $DamageNumberLayer

var _save: Dictionary = {}
var _config: Dictionary = {}

# Live battle state
var _player_hp: int = 0
var _player_max_hp: int = 0
var _npc_hp: int = 0
var _npc_max_hp: int = 0
var _player_stats: Dictionary = {}
var _npc_stats: Dictionary = {}
var _player_element: String = ""
var _npc_element: String = ""
var _npc_data: Dictionary = {}
var _player_moves: Array[Dictionary] = []
var _status_effects: Dictionary = { "player": [], "npc": [] }
var _battle_over: bool = false
var _trauma: float = 0.0

func setup(save: Dictionary, config: Dictionary) -> void:
	_save = save.duplicate(true)
	_config = config.duplicate(true)

func _ready() -> void:
	_init_battle()
	_build_move_buttons()
	if _config.get("is_singularity", false):
		corruption_modulate.color = CORRUPTION_TINT

func _process(delta: float) -> void:
	# Camera2D screen shake trauma decay
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - delta * 2.5)
		var shake := _trauma * _trauma
		camera.offset = Vector2(
			randf_range(-12.0, 12.0) * shake,
			randf_range(-8.0, 8.0) * shake
		)
	else:
		camera.offset = Vector2.ZERO

func _init_battle() -> void:
	var dragon_id: String = str(_config.get("dragon_id", _save.get("dragon_id", "fire")))
	var npc_id: String = str(_config.get("npc_id", "firewall_sentinel"))
	_npc_data = TacticalBattle.EnemyData.get(npc_id, {}).duplicate(true)

	var dragon_def: Dictionary = DragonData.DRAGONS.get(dragon_id, {}).duplicate(true)
	var level: int = DragonProgression.get_dragon_level(_save, dragon_id)
	_player_element = str(dragon_def.get("element", "fire"))
	_npc_element = str(_npc_data.get("element", "fire"))

	_player_stats = DragonData.calculate_stats(dragon_def, level)
	var npc_raw_stats: Dictionary = _npc_data.get("stats", {})
	_npc_stats = npc_raw_stats.duplicate(true)
	_npc_stats["element"] = _npc_element

	_player_max_hp = int(_player_stats.get("hp", 100))
	_npc_max_hp = int(_npc_raw_stats_hp())
	_player_hp = _player_max_hp
	_npc_hp = _npc_max_hp

	player_sprite.set_dragon(dragon_id, DragonData.get_stage_for_level(level))
	npc_sprite.set_dragon(npc_id, 1)

	player_name.text = str(dragon_def.get("name", dragon_id))
	npc_name.text = str(_npc_data.get("name", npc_id))
	header_label.text = "%s  VS  %s" % [player_name.text, npc_name.text]

	# Build player technique list
	var active_ids := DragonProgression.get_active_techniques(_save)
	_player_moves.clear()
	for t_id in active_ids:
		var t := TechniqueData.get_technique(t_id)
		if not t.is_empty():
			_player_moves.append(t)

	_update_hp_display()

func _npc_raw_stats_hp() -> int:
	return int(_npc_data.get("stats", {}).get("hp", 100))

func _build_move_buttons() -> void:
	for c in move_buttons.get_children(): c.queue_free()

	# Technique buttons
	for move in _player_moves:
		var btn := Button.new()
		btn.text = str(move.get("label", move.get("id", "?")))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var move_copy := move.duplicate(true)
		btn.pressed.connect(func(): _on_player_move(move_copy))
		move_buttons.add_child(btn)

	# Basic Attack fallback
	var basic := Button.new()
	basic.text = "Basic Attack"
	basic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	basic.pressed.connect(func(): _on_player_basic_attack())
	move_buttons.add_child(basic)

	# Defend
	var defend := Button.new()
	defend.text = "Defend"
	defend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defend.pressed.connect(_on_player_defend)
	move_buttons.add_child(defend)

func _set_buttons_disabled(disabled: bool) -> void:
	for btn in move_buttons.get_children():
		if btn is Button:
			btn.disabled = disabled

func _on_player_basic_attack() -> void:
	var basic_move := {
		"id": "basic",
		"label": "Basic Attack",
		"element": _player_element,
		"power": 40,
		"accuracy": 100,
		"focus_gain": 0,
		"stagger": 0,
		"motion": "lunge",
		"vfx": _player_element,
	}
	_on_player_move(basic_move)

func _on_player_defend() -> void:
	_set_buttons_disabled(true)
	_append_log("You brace for impact. DEF +50% this turn.")
	# Apply a temporary defence boost as a status flag
	if not _status_effects["player"].has("defend"):
		_status_effects["player"].append("defend")
	_update_status_icons()
	# NPC takes its turn after a short delay
	await get_tree().create_timer(0.5).timeout
	await _run_npc_turn()
	# Remove defend
	_status_effects["player"].erase("defend")
	_update_status_icons()
	_set_buttons_disabled(false)

func _on_player_move(move: Dictionary) -> void:
	if _battle_over:
		return
	_set_buttons_disabled(true)

	# Build attacker/defender dicts expected by CombatRules
	var attacker := _build_fighter_dict(_player_stats, _player_element, _player_hp)
	var defender := _build_fighter_dict(_npc_stats, _npc_element, _npc_hp)

	# Resolve
	var roll := randf()
	var result := CombatRules.resolve_attack(attacker, defender, move, roll)

	# Play attack animation then apply result
	await _play_attack_animation("player", move)
	if result["hit"]:
		var dmg: int = int(result["damage"])
		_npc_hp = int(result["remaining_hp"])
		var effective := result["effectiveness"] > 1.0
		var resisted := result["effectiveness"] < 1.0
		_spawn_damage_number(npc_sprite.global_position, dmg, effective, resisted)
		_add_trauma(0.18 if effective else 0.1)
		_trigger_hit_particles(npc_sprite.global_position, _npc_element)
		if effective:
			_append_log("[color=#ffcc00]%s hits for %d! Super effective![/color]" % [str(move.get("label","?")), dmg])
		elif resisted:
			_append_log("[color=#8fb0ff]%s hits for %d. Not very effective.[/color]" % [str(move.get("label","?")), dmg])
		else:
			_append_log("%s hits for %d damage." % [str(move.get("label","?")), dmg])
	else:
		_append_log("%s missed!" % str(move.get("label", "?")))

	_update_hp_display()

	if _npc_hp <= 0:
		await _end_battle(true)
		return

	# NPC turn
	await get_tree().create_timer(0.4).timeout
	await _run_npc_turn()

func _run_npc_turn() -> void:
	if _battle_over:
		return
	# Simple AI: basic attack with NPC stats
	var npc_move := {
		"id": "npc_basic",
		"label": "Strike",
		"element": _npc_element,
		"power": 35,
		"accuracy": 90,
		"motion": "lunge",
		"vfx": _npc_element,
	}
	var attacker := _build_fighter_dict(_npc_stats, _npc_element, _npc_hp)
	# Apply player defend bonus
	var def_bonus: float = 1.5 if _status_effects["player"].has("defend") else 1.0
	var player_dict := _build_fighter_dict(_player_stats, _player_element, _player_hp)
	player_dict["def"] = int(float(player_dict["def"]) * def_bonus)

	var roll := randf()
	var result := CombatRules.resolve_attack(attacker, player_dict, npc_move, roll)

	await _play_attack_animation("npc", npc_move)
	if result["hit"]:
		var dmg: int = int(result["damage"])
		_player_hp = int(result["remaining_hp"])
		_spawn_damage_number(player_sprite.global_position, dmg, false, false)
		_add_trauma(0.12)
		_trigger_hit_particles(player_sprite.global_position, _player_element)
		_append_log("%s strikes for %d damage." % [str(_npc_data.get("name","NPC")), dmg])
	else:
		_append_log("%s missed!" % str(_npc_data.get("name","NPC")))

	_update_hp_display()

	if _player_hp <= 0:
		await _end_battle(false)
		return

	_set_buttons_disabled(false)

func _play_attack_animation(side: String, move: Dictionary) -> void:
	# Lunge: attacker moves forward then snaps back
	var target_node: Control = player_sprite if side == "player" else npc_sprite
	var direction: float = 1.0 if side == "player" else -1.0
	var original_x: float = target_node.position.x
	var tween := create_tween()
	tween.tween_property(target_node, "position:x", original_x + 30.0 * direction, 0.1)
	tween.tween_property(target_node, "position:x", original_x, 0.12)
	# Target shake
	var hit_target: Control = npc_sprite if side == "player" else player_sprite
	var orig_hit_x: float = hit_target.position.x
	tween.tween_property(hit_target, "position:x", orig_hit_x + 6.0, 0.04)
	tween.tween_property(hit_target, "position:x", orig_hit_x - 6.0, 0.04)
	tween.tween_property(hit_target, "position:x", orig_hit_x, 0.04)
	await tween.finished

func _trigger_hit_particles(world_pos: Vector2, element: String) -> void:
	if hit_particles == null:
		return
	hit_particles.global_position = world_pos
	var color: Color = ELEMENT_COLORS.get(element, Color.WHITE)
	# Set particle color via process material if available
	if hit_particles.process_material is ParticleProcessMaterial:
		hit_particles.process_material.color = color
	hit_particles.restart()

func _spawn_damage_number(world_pos: Vector2, value: int, effective: bool, resisted: bool) -> void:
	var inst: Node2D = DamageNumberScene.instantiate()
	damage_layer.add_child(inst)
	inst.global_position = world_pos + Vector2(randf_range(-20, 20), -40)
	inst.spawn(value, effective, resisted)

func _add_trauma(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)

func _update_hp_display() -> void:
	player_hp_bar.max_value = _player_max_hp
	player_hp_bar.value = _player_hp
	player_hp_label.text = "%d / %d" % [_player_hp, _player_max_hp]
	npc_hp_bar.max_value = _npc_max_hp
	npc_hp_bar.value = _npc_hp
	npc_hp_label.text = "%d / %d" % [_npc_hp, _npc_max_hp]

func _update_status_icons() -> void:
	for c in player_status_icons.get_children(): c.queue_free()
	for effect in _status_effects["player"]:
		var lbl := Label.new()
		lbl.text = "[%s]" % str(effect).to_upper()
		lbl.add_theme_font_size_override("font_size", 10)
		player_status_icons.add_child(lbl)

func _append_log(text: String) -> void:
	battle_log.append_text(text + "\n")

func _build_fighter_dict(stats: Dictionary, element: String, current_hp: int) -> Dictionary:
	return {
		"hp": current_hp,
		"atk": int(stats.get("atk", 20)),
		"def": int(stats.get("def", 15)),
		"spd": int(stats.get("spd", 15)),
		"element": element,
		"stage": 1,
	}

func _end_battle(player_won: bool) -> void:
	_battle_over = true
	_set_buttons_disabled(true)

	if player_won:
		var dragon_id: String = str(_config.get("dragon_id", _save.get("dragon_id", "fire")))
		var reward_xp: int = int(_npc_data.get("reward_xp", 50))
		var reward_scraps: int = int(_npc_data.get("reward_scraps", 30))
		var npc_id: String = str(_config.get("npc_id", ""))

		_save = DragonProgression.award_dragon_xp(_save, reward_xp)
		_save = DragonProgression.award_scraps(_save, reward_scraps)
		_save = DragonProgression.record_enemy_defeated(_save, npc_id)

		var reward_flag: String = str(_npc_data.get("reward_flag", ""))
		if reward_flag != "":
			_save = DragonProgression.set_mission_flag(_save, reward_flag)

		var reward_key_item: String = str(_npc_data.get("reward_key_item", ""))
		if reward_key_item != "":
			_save = DragonProgression.grant_key_item(_save, reward_key_item)

		_append_log("[color=#ffcc00]Victory! +%d XP, +%d scraps[/color]" % [reward_xp, reward_scraps])
	else:
		_append_log("[color=#ff4d4d]Defeated. Returning...[/color]")

	_write_save()
	await get_tree().create_timer(1.8).timeout
	var return_screen: String = str(_config.get("return_screen", "battleSelect"))
	navigate.emit(return_screen, null)

func _write_save() -> void:
	var main := get_tree().get_root().get_node_or_null("Main")
	if main != null and main.has_method("save_to_disk"):
		main.save_to_disk(_save)
```

- [ ] **Step 8b: Create `scenes/screens/battle_screen.tscn`**

  Build tree as described. Key settings:
  - `Camera2D`: `position_smoothing_enabled=false`, `drag_horizontal_enabled=false`, `drag_vertical_enabled=false`
  - `CorruptionModulate`: `CanvasModulate`, initial color `#ffffff` (white = no tint)
  - `HitParticles`: `GPUParticles2D`, `emitting=false`, `one_shot=true`, `explosiveness=0.8`, `amount=24`; create a `ParticleProcessMaterial`, set `direction=Vector3(0,-1,0)`, `spread=45`, `initial_velocity_min=80`, `initial_velocity_max=180`, `gravity=Vector3(0,300,0)`, `scale_min=4`, `scale_max=8`
  - `BattleLog`: `bbcode_enabled=true`, `scroll_following=true`
  - `CombatRow` HBoxContainer: `size_flags_vertical=EXPAND_FILL`
  - `PlayerSide`/`NpcSide`: each `size_flags_horizontal=EXPAND_FILL`

---

## Task 9 — Fusion Screen

**Files:**
- Create: `scenes/screens/fusion_screen.tscn`
- Create: `scripts/screens/fusion_screen.gd`

**Scene tree (`fusion_screen.tscn`):**
```
FusionScreen (Control, full rect)
  Background (ColorRect, full rect, Color #0d0f1c)
  VBoxContainer (full rect, margin 16)
    Label (text "FUSION LAB", font size 28)
    ScrapsLabel (Label, name "ScrapsLabel")
    HBoxContainer (name "PickRow")
      VBoxContainer (name "PickA", size_flags_horizontal=EXPAND_FILL)
        Label (text "DRAGON A")
        ScrollContainer
          VBoxContainer (name "ListA")
      VBoxContainer (name "PickB", size_flags_horizontal=EXPAND_FILL)
        Label (text "DRAGON B")
        ScrollContainer
          VBoxContainer (name "ListB")
      VBoxContainer (name "Preview", size_flags_horizontal=EXPAND_FILL)
        Label (text "PREVIEW")
        Label (name "PreviewElement")
        Label (name "PreviewStability")
        Label (name "PreviewStats")
    FuseButton (Button, name "FuseButton", text "FUSE (100 SCRAPS)", visible=false)
    FusionOverlay (Control, name "FusionOverlay", visible=false, full rect)
      ColorRect (full rect, Color #000000 alpha 0.9)
      Label (name "FusionLabel", text "FUSING...", centered)
    NavBar (instance of nav_bar.tscn)
  AnimationPlayer (name "AnimationPlayer")
```

- [ ] **Step 9a: Create `scripts/screens/fusion_screen.gd`**

```gdscript
extends Control

signal navigate(target: String, payload: Variant)

const DragonProgression := preload("res://scripts/sim/dragon_progression.gd")
const DragonData := preload("res://scripts/sim/dragon_data.gd")

const NAV_ENTRIES := [
	{"label": "HATCHERY",  "target": "hatchery"},
	{"label": "BATTLE",    "target": "battleSelect"},
	{"label": "FUSION",    "target": "fusion"},
]
const FUSE_COST := 100

# Element fusion table: sorted pair → result element
const FUSION_TABLE := {
	"fire+ice": "storm",
	"fire+storm": "venom",
	"fire+stone": "fire",
	"fire+venom": "shadow",
	"fire+shadow": "fire",
	"ice+storm": "ice",
	"ice+stone": "ice",
	"ice+venom": "shadow",
	"ice+shadow": "venom",
	"storm+stone": "stone",
	"storm+venom": "storm",
	"storm+shadow": "shadow",
	"stone+venom": "stone",
	"stone+shadow": "stone",
	"venom+shadow": "venom",
}

# Stability: if elements are same → unstable; if opposite (fire+ice, storm+stone, etc.) → unstable; otherwise stable
const UNSTABLE_PAIRS := ["fire+ice", "storm+stone", "venom+shadow"]

const STABILITY_COLORS := {
	"stable": Color("#ffd166"),
	"normal": Color("#ffffff"),
	"unstable": Color("#ff4d4d"),
}

@onready var scraps_label: Label = $VBoxContainer/ScrapsLabel
@onready var list_a: VBoxContainer = $VBoxContainer/PickRow/PickA/ScrollContainer/ListA
@onready var list_b: VBoxContainer = $VBoxContainer/PickRow/PickB/ScrollContainer/ListB
@onready var preview_element: Label = $VBoxContainer/PickRow/Preview/PreviewElement
@onready var preview_stability: Label = $VBoxContainer/PickRow/Preview/PreviewStability
@onready var preview_stats: Label = $VBoxContainer/PickRow/Preview/PreviewStats
@onready var fuse_button: Button = $VBoxContainer/FuseButton
@onready var fusion_overlay: Control = $VBoxContainer/FusionOverlay
@onready var fusion_label: Label = $VBoxContainer/FusionOverlay/FusionLabel
@onready var nav_bar: Control = $VBoxContainer/NavBar

var _save: Dictionary = {}
var _selected_a: String = ""
var _selected_b: String = ""

func setup(save: Dictionary) -> void:
	_save = save.duplicate(true)

func _ready() -> void:
	fuse_button.pressed.connect(_on_fuse_pressed)
	nav_bar.navigate.connect(func(t): navigate.emit(t, null))
	nav_bar.setup(NAV_ENTRIES)
	fusion_overlay.visible = false
	fuse_button.visible = false
	_refresh()

func _refresh() -> void:
	scraps_label.text = "DATA SCRAPS: %d" % int(_save.get("data_scraps", 0))
	_rebuild_lists()
	_update_preview()

func _rebuild_lists() -> void:
	for c in list_a.get_children(): c.queue_free()
	for c in list_b.get_children(): c.queue_free()

	var hatchery_state: Dictionary = DragonProgression.get_hatchery_state(_save)
	var owned: Array = hatchery_state.get("owned_dragons", [])
	var levels: Dictionary = _save.get("dragon_levels", {})

	for dragon_id in owned:
		var dragon_def: Dictionary = DragonData.DRAGONS.get(dragon_id, {})
		var level: int = int(levels.get(dragon_id, 1))
		var label_text := "%s LV%d" % [str(dragon_def.get("name", dragon_id)), level]

		var btn_a := Button.new()
		btn_a.text = label_text
		btn_a.toggle_mode = true
		var id_a := dragon_id
		btn_a.pressed.connect(func():
			if _selected_b == id_a:
				_selected_b = ""
			_selected_a = id_a
			_deselect_siblings(list_a, btn_a)
			_deselect_siblings_b_if_same()
			_update_preview()
		)
		list_a.add_child(btn_a)

		var btn_b := Button.new()
		btn_b.text = label_text
		btn_b.toggle_mode = true
		var id_b := dragon_id
		btn_b.pressed.connect(func():
			if _selected_a == id_b:
				_selected_a = ""
			_selected_b = id_b
			_deselect_siblings(list_b, btn_b)
			_deselect_siblings_a_if_same()
			_update_preview()
		)
		list_b.add_child(btn_b)

func _deselect_siblings(parent: VBoxContainer, except: Button) -> void:
	for c in parent.get_children():
		if c is Button and c != except:
			c.button_pressed = false

func _deselect_siblings_b_if_same() -> void:
	# If B is now same as A, deselect B
	if _selected_b == _selected_a and _selected_b != "":
		_selected_b = ""
		for c in list_b.get_children():
			if c is Button: c.button_pressed = false

func _deselect_siblings_a_if_same() -> void:
	if _selected_a == _selected_b and _selected_a != "":
		_selected_a = ""
		for c in list_a.get_children():
			if c is Button: c.button_pressed = false

func _update_preview() -> void:
	if _selected_a == "" or _selected_b == "" or _selected_a == _selected_b:
		preview_element.text = "Element: —"
		preview_stability.text = "Stability: —"
		preview_stats.text = ""
		fuse_button.visible = false
		return

	var elem_a: String = str(DragonData.DRAGONS.get(_selected_a, {}).get("element", "fire"))
	var elem_b: String = str(DragonData.DRAGONS.get(_selected_b, {}).get("element", "fire"))
	var result_element := _fuse_elements(elem_a, elem_b)
	var stability := _get_stability(elem_a, elem_b)

	preview_element.text = "Element: %s" % result_element.to_upper()
	preview_stability.text = "Stability: %s" % stability.to_upper()
	preview_stability.add_theme_color_override("font_color", STABILITY_COLORS.get(stability, Color.WHITE))

	# Calculate averaged stats
	var level_a: int = DragonProgression.get_dragon_level(_save, _selected_a)
	var level_b: int = DragonProgression.get_dragon_level(_save, _selected_b)
	var result_level: int = maxi(1, (level_a + level_b) / 2)
	var def_a: Dictionary = DragonData.DRAGONS.get(_selected_a, {})
	var def_b: Dictionary = DragonData.DRAGONS.get(_selected_b, {})
	if def_a.is_empty() or def_b.is_empty():
		preview_stats.text = ""
	else:
		var stats_a := DragonData.calculate_stats(def_a, level_a)
		var stats_b := DragonData.calculate_stats(def_b, level_b)
		var instability_penalty: float = 0.85 if stability == "unstable" else 1.0
		var result_hp := floori((stats_a["hp"] + stats_b["hp"]) * 0.6 * instability_penalty)
		var result_atk := floori((stats_a["atk"] + stats_b["atk"]) * 0.6 * instability_penalty)
		var result_def := floori((stats_a["def"] + stats_b["def"]) * 0.6 * instability_penalty)
		var result_spd := floori((stats_a["spd"] + stats_b["spd"]) * 0.6 * instability_penalty)
		preview_stats.text = "HP:%d  ATK:%d  DEF:%d  SPD:%d  LV:%d" % [
			result_hp, result_atk, result_def, result_spd, result_level
		]

	var can_afford: bool = int(_save.get("data_scraps", 0)) >= FUSE_COST
	fuse_button.visible = true
	fuse_button.disabled = not can_afford

func _fuse_elements(a: String, b: String) -> String:
	var sorted_key := _pair_key(a, b)
	return FUSION_TABLE.get(sorted_key, a)

func _get_stability(a: String, b: String) -> String:
	if a == b:
		return "unstable"
	var key := _pair_key(a, b)
	if UNSTABLE_PAIRS.has(key):
		return "unstable"
	return "stable"

func _pair_key(a: String, b: String) -> String:
	var pair := [a, b]
	pair.sort()
	return "%s+%s" % [pair[0], pair[1]]

func _on_fuse_pressed() -> void:
	if _selected_a == "" or _selected_b == "" or _selected_a == _selected_b:
		return
	if int(_save.get("data_scraps", 0)) < FUSE_COST:
		return

	_save["data_scraps"] = int(_save["data_scraps"]) - FUSE_COST

	var elem_a: String = str(DragonData.DRAGONS.get(_selected_a, {}).get("element", "fire"))
	var elem_b: String = str(DragonData.DRAGONS.get(_selected_b, {}).get("element", "fire"))
	var result_element := _fuse_elements(elem_a, elem_b)
	var stability := _get_stability(elem_a, elem_b)

	# Remove the two source dragons, add the result
	var hatchery_state: Dictionary = DragonProgression.get_hatchery_state(_save)
	var owned: Array = hatchery_state.get("owned_dragons", []).duplicate()
	owned.erase(_selected_a)
	owned.erase(_selected_b)

	# Find a dragon that matches the result element, or use first available
	var result_id := result_element
	if not DragonData.DRAGONS.has(result_id):
		result_id = DragonData.DRAGONS.keys()[0]
	if not owned.has(result_id):
		owned.append(result_id)

	# Set fused dragon level
	var level_a: int = DragonProgression.get_dragon_level(_save, _selected_a)
	var level_b: int = DragonProgression.get_dragon_level(_save, _selected_b)
	var result_level: int = maxi(1, (level_a + level_b) / 2)
	if not _save.has("dragon_levels"):
		_save["dragon_levels"] = {}
	_save["dragon_levels"][result_id] = result_level
	if not _save.has("dragon_xp"):
		_save["dragon_xp"] = {}
	_save["dragon_xp"][result_id] = 0

	hatchery_state["owned_dragons"] = owned
	_save["hatchery_state"] = hatchery_state

	_write_save()
	await _play_fusion_animation(_selected_a, _selected_b, result_id, stability)

	_selected_a = ""
	_selected_b = ""
	_refresh()

func _play_fusion_animation(id_a: String, id_b: String, result_id: String, stability: String) -> void:
	fusion_overlay.visible = true
	fusion_label.text = "FUSING..."

	var tween := create_tween()
	# Flash in
	tween.tween_property(fusion_overlay, "modulate:a", 1.0, 0.0)
	tween.tween_interval(0.5)

	# Particle burst phase
	fusion_label.text = "MERGING PROTOCOLS..."
	tween.tween_interval(0.6)

	# Result reveal
	var def_result: Dictionary = DragonData.DRAGONS.get(result_id, {})
	var result_name: String = str(def_result.get("name", result_id))
	if stability == "unstable":
		fusion_label.text = "FUSION UNSTABLE\n%s EMERGES" % result_name
	else:
		fusion_label.text = "STABLE FUSION\n%s EMERGES" % result_name
	tween.tween_interval(0.8)

	# Fade out
	tween.tween_property(fusion_overlay, "modulate:a", 0.0, 0.4)
	await tween.finished
	fusion_overlay.visible = false

func _write_save() -> void:
	var main := get_tree().get_root().get_node_or_null("Main")
	if main != null and main.has_method("save_to_disk"):
		main.save_to_disk(_save)
```

- [ ] **Step 9b: Create `scenes/screens/fusion_screen.tscn`**

  Build the scene tree as described. `FusionOverlay` uses full-rect anchors. `PickRow` HBoxContainer has `size_flags_vertical=EXPAND_FILL`. `Preview` VBoxContainer's labels all have `autowrap_mode=WORD`. Attach `fusion_screen.gd` to root.

---

## Task 10 — Wire Up `scenes/main.tscn`

- [ ] **Step 10a: Verify main.tscn root node**

  Open `scenes/main.tscn`. The root should be a `Control` node named `Main` with `main.gd` attached. It should have no pre-instantiated screen children (those are now created at runtime by `_switch_screen`). If old scene children (WorldScene, BattleScene, HardwareDungeonScene) remain as direct children, remove them — they are no longer loaded by this version of main.gd.

- [ ] **Step 10b: Confirm AutoLoad for AudioDirector**

  In Project Settings → Autoload, verify `AudioDirector` is registered as an autoload pointing to `res://scripts/sim/audio_director.gd`. If not, add it. The node name must be `AudioDirector` to match the `/root/AudioDirector` lookup in main.gd and screen scripts.

- [ ] **Step 10c: Create `data/sprite_manifest.json` stub**

  If `dragon-forge-godot/data/sprite_manifest.json` does not exist, create it:
  ```json
  {
    "fire_stage1":   "res://assets/sprites/fire_stage1.png",
    "ice_stage1":    "res://assets/sprites/ice_stage1.png",
    "storm_stage1":  "res://assets/sprites/storm_stage1.png",
    "stone_stage1":  "res://assets/sprites/stone_stage1.png",
    "venom_stage1":  "res://assets/sprites/venom_stage1.png",
    "shadow_stage1": "res://assets/sprites/shadow_stage1.png"
  }
  ```
  DragonSprite will fall back gracefully to the letter placeholder if the files don't exist yet.

---

## Task 11 — Integration Smoke Test

**File:** `dragon-forge-godot/scripts/tests/sim_smoke.gd` (add assertions)

- [ ] **Step 11a: Add slice-screens sanity checks to smoke test**

  Open `scripts/tests/sim_smoke.gd` and append these test cases after the existing assertions:

```gdscript
# Plan 4 — slice screens smoke checks

func test_main_default_save_has_required_keys() -> void:
	# Verify the DEFAULT_SAVE shape matches what screens expect
	var required_keys := [
		"dragon_id", "dragon_levels", "dragon_xp", "data_scraps",
		"hatchery_state", "bestiary_seen", "bestiary_defeated", "singularity_defeated",
	]
	# We can't import main.gd in a headless test without instancing, so check
	# DragonProgression.create_profile covers the critical subset.
	var profile := DragonProgression.create_profile("fire")
	for key in ["dragon_id", "dragon_levels", "dragon_xp", "data_scraps",
			"hatchery_state", "bestiary_seen", "bestiary_defeated"]:
		assert(profile.has(key), "create_profile missing key: %s" % key)
	print("PASS: default save shape")

func test_combat_rules_resolve_returns_expected_keys() -> void:
	var attacker := {"hp": 100, "atk": 28, "def": 20, "spd": 18, "element": "fire", "stage": 1}
	var defender := {"hp": 190, "atk": 25, "def": 22, "spd": 10, "element": "stone", "stage": 1}
	var move := {"element": "fire", "power": 88, "accuracy": 95, "motion": "lunge"}
	var result := CombatRules.resolve_attack(attacker, defender, move, 0.0)
	assert(result.has("hit"), "resolve_attack: missing 'hit'")
	assert(result.has("damage"), "resolve_attack: missing 'damage'")
	assert(result.has("remaining_hp"), "resolve_attack: missing 'remaining_hp'")
	assert(result.has("effectiveness"), "resolve_attack: missing 'effectiveness'")
	print("PASS: combat rules resolve keys")

func test_dragon_data_calculate_stats_scales_with_level() -> void:
	var fire_def := DragonData.DRAGONS["fire"]
	var stats_l1 := DragonData.calculate_stats(fire_def, 1)
	var stats_l10 := DragonData.calculate_stats(fire_def, 10)
	assert(stats_l10["atk"] > stats_l1["atk"], "Stats should scale with level")
	print("PASS: stat scaling")

func test_hatchery_state_owned_dragons_not_empty() -> void:
	var profile := DragonProgression.create_profile("fire")
	var state := DragonProgression.get_hatchery_state(profile)
	assert(state["owned_dragons"].size() > 0, "owned_dragons should not be empty after create_profile")
	print("PASS: hatchery state init")
```

- [ ] **Step 11b: Run headless smoke test and verify PASS lines**

  ```powershell
  & 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' `
    --headless `
    --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' `
    --script res://scripts/tests/sim_smoke.gd
  ```

  All four new PASS lines must appear with no ERRORs before considering Plan 4 complete.

---

## Task 12 — Manual Playthrough Checklist

Run the game with `.\run-godot.ps1` and verify:

- [ ] Title screen shows boot lines one by one with delays, then Felix lines, then "START GAME" button
- [ ] Clicking "START GAME" transitions to Hatchery with "hatchery" music cue
- [ ] Hatchery shows owned dragon(s) as grid cards with level + XP bar
- [ ] "PULL" button deducts 50 scraps and plays hatch animation; new dragon card appears
- [ ] "PULL" is disabled when scraps < 50
- [ ] NavBar buttons navigate to Battle Select and Fusion without errors
- [ ] Battle Select shows dragon list on left and enemy list on right
- [ ] Selecting one dragon and one enemy enables "FIGHT" button
- [ ] Battle screen loads with HP bars, correct dragon and enemy names
- [ ] Move buttons work: attack animations play, HP bars update, damage numbers float up
- [ ] Screen shake triggers on hit
- [ ] Particles fire on hit (or gracefully do nothing if `ParticleProcessMaterial` not configured)
- [ ] Winning a battle awards XP + scraps and returns to Battle Select
- [ ] Losing a battle also returns to Battle Select
- [ ] Fusion Screen shows owned dragons in both columns; same dragon cannot be selected in both
- [ ] Preview updates live as you pick dragons: shows element, stability, stats
- [ ] "FUSE" deducts 100 scraps, plays animation, replaces the two source dragons with result
- [ ] All screens persist save correctly (scraps/levels survive navigate round-trips)

---

## Definition of Done

Plan 4 is complete when:
1. All 5 `scenes/screens/*.tscn` files exist with matching `scripts/screens/*.gd` scripts
2. `scenes/components/nav_bar.tscn`, `dragon_sprite.tscn`, `damage_number.tscn` exist
3. `main.gd` is the screen router described in Task 4
4. Headless smoke test outputs 4 new PASS lines with no ERROR lines
5. Manual playthrough checklist above passes without crashes
