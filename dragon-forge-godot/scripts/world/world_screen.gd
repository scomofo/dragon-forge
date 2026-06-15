extends Control

signal navigate(target: String, payload: Variant)

const DragonData        = preload("res://scripts/sim/dragon_data.gd")
const DragonProgression = preload("res://scripts/sim/dragon_progression.gd")
const PlayerDragon      = preload("res://scripts/world/player_dragon.gd")
const EncounterZone     = preload("res://scripts/world/encounter_zone.gd")
const BossGate          = preload("res://scripts/world/boss_gate.gd")

const TILE: int   = 32
const COLS: int   = 20
const ROWS: int   = 10
const MAP_W: float = COLS * TILE
const MAP_H: float = ROWS * TILE

const PLAYER_START   := Vector2i(2, 8)
const HATCHERY_TILE  := Vector2i(2, 2)

# ── Zone 1 ───────────────────────────────────────────────────────────────────
const ZONE_TILES     := [Vector2i(6, 3), Vector2i(11, 6), Vector2i(16, 3)]
const BOSS_GATE_TILE := Vector2i(17, 5)
const BOSS_TILE      := Vector2i(19, 5)

const ZONE_NPC_IDS := ["firewall_sentinel", "buffer_overflow", "bit_wraith"]
const BOSS_NPC_ID  := "recursive_golem"
const BOSS_FLAG    := "recursive_golem_defeated"

# ── Zone 2 ───────────────────────────────────────────────────────────────────
# Occupies the bottom strip of the map (rows 7-9), clearly separated from
# Zone 1 (rows 3-6).  No tile coordinates overlap with Zone 1.
const ZONE2_TILES     := [Vector2i(4, 8), Vector2i(8, 8), Vector2i(13, 8), Vector2i(17, 8)]
const BOSS2_GATE_TILE := Vector2i(18, 7)
const BOSS2_TILE      := Vector2i(19, 8)

const ZONE2_NPC_IDS := ["glitch_hydra", "crypto_crab", "logic_bomb", "phishing_siren"]
const BOSS2_NPC_ID  := "protocol_vulture"
const BOSS2_FLAG    := "protocol_vulture_defeated"

# Zone 2 is gated on Zone 1 boss defeat.
const ZONE2_UNLOCK_FLAG := "recursive_golem_defeated"

var _save: Dictionary = {}
var _player: CharacterBody2D = null
var _zones: Array = []
var _boss_zone: Area2D = null
var _boss_gate: StaticBody2D = null
var _zones2: Array = []
var _boss_zone2: Area2D = null
var _boss_gate2: StaticBody2D = null
var _zone2_root: Node2D = null   # parent node for all Zone 2 visuals/nodes
var _dragon_select: OptionButton = null
var _status_label: Label = null
var _selected_dragon_id: String = ""
var _in_battle: bool = false

func setup(save: Dictionary) -> void:
	_save = save.duplicate(true)
	_selected_dragon_id = str(_save.get("dragon_id", "fire"))
	_refresh_dragon_select()
	_refresh_zone_states()
	_refresh_boss_gate()
	_refresh_zone2_visibility()
	_refresh_zone2_states()
	_refresh_boss_gate2()

func _ready() -> void:
	_build_world()

func _tp(col: int, row: int) -> Vector2:
	return Vector2(col * TILE + TILE * 0.5, row * TILE + TILE * 0.5)

func _build_world() -> void:
	var root := Node2D.new()
	root.name = "WorldRoot"
	add_child(root)
	_build_floor(root)
	_build_walls(root)
	_build_hatchery_hub(root)
	_build_encounter_zones(root)
	_build_boss_gate_node(root)
	_build_boss_zone(root)
	_build_zone2(root)
	_build_player(root)
	_build_hud()
	# Refresh visual state after zones are built (no-op when _save is empty;
	# setup() does the real refresh once the save is provided).
	_refresh_zone_states()
	_refresh_boss_gate()
	_refresh_zone2_visibility()
	_refresh_zone2_states()
	_refresh_boss_gate2()

func _build_floor(parent: Node2D) -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0f0f1a")
	bg.size = Vector2(MAP_W, MAP_H)
	bg.z_index = -10
	parent.add_child(bg)

	for c in range(COLS + 1):
		var vline := ColorRect.new()
		vline.color = Color(1, 1, 1, 0.03)
		vline.position = Vector2(c * TILE, 0)
		vline.size = Vector2(1, MAP_H)
		parent.add_child(vline)
	for r in range(ROWS + 1):
		var hline := ColorRect.new()
		hline.color = Color(1, 1, 1, 0.03)
		hline.position = Vector2(0, r * TILE)
		hline.size = Vector2(MAP_W, 1)
		parent.add_child(hline)

	# Area highlight tiles — Zone 1
	var hatch_vis := ColorRect.new()
	hatch_vis.color = Color(0.1, 0.22, 0.16, 0.8)
	hatch_vis.position = _tp(HATCHERY_TILE.x - 1, HATCHERY_TILE.y - 1)
	hatch_vis.size = Vector2(TILE * 2, TILE * 2)
	parent.add_child(hatch_vis)

	var zone_colors := [Color(0.16, 0.1, 0.06, 0.8), Color(0.06, 0.1, 0.16, 0.8), Color(0.1, 0.06, 0.16, 0.8)]
	for i in range(ZONE_TILES.size()):
		var vis := ColorRect.new()
		vis.color = zone_colors[i]
		vis.position = _tp(ZONE_TILES[i].x, ZONE_TILES[i].y) - Vector2(TILE, TILE) * 0.5
		vis.size = Vector2(TILE, TILE)
		parent.add_child(vis)

	var boss_vis := ColorRect.new()
	boss_vis.color = Color(0.16, 0.0, 0.0, 0.8)
	boss_vis.position = _tp(BOSS_TILE.x, BOSS_TILE.y) - Vector2(TILE, TILE) * 0.5
	boss_vis.size = Vector2(TILE, TILE)
	parent.add_child(boss_vis)

func _build_walls(parent: Node2D) -> void:
	var wall_defs := [
		[Vector2(MAP_W * 0.5, -4),     Vector2(MAP_W, 8)],
		[Vector2(MAP_W * 0.5, MAP_H + 4), Vector2(MAP_W, 8)],
		[Vector2(-4, MAP_H * 0.5),     Vector2(8, MAP_H)],
		[Vector2(MAP_W + 4, MAP_H * 0.5), Vector2(8, MAP_H)],
	]
	for wd in wall_defs:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		parent.add_child(body)
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = wd[1]
		cs.shape = rs
		cs.position = wd[0]
		body.add_child(cs)

func _build_hatchery_hub(parent: Node2D) -> void:
	var zone := Area2D.new()
	zone.name = "HatcheryHub"
	zone.position = _tp(HATCHERY_TILE.x, HATCHERY_TILE.y)
	zone.collision_layer = 0
	zone.collision_mask = 1
	zone.monitoring = true
	zone.monitorable = false
	parent.add_child(zone)

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(56, 56)
	cs.shape = rs
	zone.add_child(cs)

	var lbl := Label.new()
	lbl.text = "HATCHERY"
	lbl.position = Vector2(-28, -28)
	lbl.add_theme_font_size_override("font_size", 10)
	zone.add_child(lbl)

	zone.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player") and not _in_battle:
			_in_battle = true
			navigate.emit("hatchery", null)
	)

func _build_encounter_zones(parent: Node2D) -> void:
	_zones.clear()
	for i in range(ZONE_TILES.size()):
		var node := EncounterZone.new()
		node.name = "Zone%d" % i
		node.npc_id = ZONE_NPC_IDS[i]
		node.position = _tp(ZONE_TILES[i].x, ZONE_TILES[i].y)
		parent.add_child(node)
		node.player_entered.connect(_on_zone_entered)
		_zones.append(node)

func _build_boss_gate_node(parent: Node2D) -> void:
	var gate := BossGate.new()
	gate.name = "BossGate"
	gate.position = _tp(BOSS_GATE_TILE.x, BOSS_GATE_TILE.y)
	parent.add_child(gate)
	_boss_gate = gate

func _build_boss_zone(parent: Node2D) -> void:
	var node := EncounterZone.new()
	node.name = "BossZone"
	node.npc_id = BOSS_NPC_ID
	node.position = _tp(BOSS_TILE.x, BOSS_TILE.y)
	parent.add_child(node)
	node.player_entered.connect(_on_zone_entered)
	_boss_zone = node

# ── Zone 2 construction ───────────────────────────────────────────────────────
# All Zone 2 nodes are children of _zone2_root so they can be shown/hidden
# together by toggling _zone2_root.visible.

func _build_zone2(parent: Node2D) -> void:
	_zone2_root = Node2D.new()
	_zone2_root.name = "Zone2Root"
	_zone2_root.visible = false   # hidden until Zone 1 boss defeated
	parent.add_child(_zone2_root)

	# Floor highlight tiles for Zone 2 encounters
	var zone2_colors := [
		Color(0.06, 0.16, 0.16, 0.8),
		Color(0.06, 0.16, 0.08, 0.8),
		Color(0.10, 0.04, 0.16, 0.8),
		Color(0.04, 0.10, 0.16, 0.8),
	]
	for i in range(ZONE2_TILES.size()):
		var vis := ColorRect.new()
		vis.color = zone2_colors[i]
		vis.position = _tp(ZONE2_TILES[i].x, ZONE2_TILES[i].y) - Vector2(TILE, TILE) * 0.5
		vis.size = Vector2(TILE, TILE)
		_zone2_root.add_child(vis)

	# Boss tile highlight
	var boss2_vis := ColorRect.new()
	boss2_vis.color = Color(0.10, 0.0, 0.16, 0.8)
	boss2_vis.position = _tp(BOSS2_TILE.x, BOSS2_TILE.y) - Vector2(TILE, TILE) * 0.5
	boss2_vis.size = Vector2(TILE, TILE)
	_zone2_root.add_child(boss2_vis)

	# Encounter zones
	_zones2.clear()
	for i in range(ZONE2_TILES.size()):
		var node := EncounterZone.new()
		node.name = "Zone2_%d" % i
		node.npc_id = ZONE2_NPC_IDS[i]
		node.position = _tp(ZONE2_TILES[i].x, ZONE2_TILES[i].y)
		_zone2_root.add_child(node)
		node.player_entered.connect(_on_zone_entered)
		_zones2.append(node)

	# Boss gate
	var gate2 := BossGate.new()
	gate2.name = "BossGate2"
	gate2.position = _tp(BOSS2_GATE_TILE.x, BOSS2_GATE_TILE.y)
	_zone2_root.add_child(gate2)
	_boss_gate2 = gate2

	# Boss encounter zone
	var boss_node := EncounterZone.new()
	boss_node.name = "BossZone2"
	boss_node.npc_id = BOSS2_NPC_ID
	boss_node.position = _tp(BOSS2_TILE.x, BOSS2_TILE.y)
	_zone2_root.add_child(boss_node)
	boss_node.player_entered.connect(_on_zone_entered)
	_boss_zone2 = boss_node

func _build_player(parent: Node2D) -> void:
	_player = PlayerDragon.new()
	_player.name = "Player"
	_player.position = _tp(PLAYER_START.x, PLAYER_START.y)
	_player.collision_layer = 1
	_player.collision_mask = 1
	parent.add_child(_player)

	var cs := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 10.0
	cap.height = 20.0
	cs.shape = cap
	_player.add_child(cs)

	var vis := ColorRect.new()
	vis.color = Color(0.0, 1.0, 0.8)
	vis.size = Vector2(16, 16)
	vis.position = Vector2(-8, -8)
	_player.add_child(vis)

	var cam := Camera2D.new()
	cam.name = "Camera"
	cam.enabled = true
	_player.add_child(cam)

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 10
	add_child(hud)

	var panel := VBoxContainer.new()
	panel.position = Vector2(8, 8)
	hud.add_child(panel)

	_dragon_select = OptionButton.new()
	_dragon_select.item_selected.connect(_on_dragon_selected)
	panel.add_child(_dragon_select)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 11)
	panel.add_child(_status_label)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	back_btn.offset_top = -36
	back_btn.offset_bottom = -8
	back_btn.offset_left = 8
	back_btn.offset_right = 80
	back_btn.pressed.connect(func() -> void:
		if not _in_battle:
			_in_battle = true
			navigate.emit("hatchery", null)
	)
	hud.add_child(back_btn)

func _refresh_dragon_select() -> void:
	if _dragon_select == null:
		return
	_dragon_select.clear()
	var owned: Array = DragonProgression.get_hatchery_state(_save).get("owned_dragons", [])
	if owned.is_empty():
		owned = [str(_save.get("dragon_id", "fire"))]
	for did in owned:
		var def: Dictionary = DragonData.DRAGONS.get(str(did), {})
		_dragon_select.add_item(str(def.get("name", did)))
		_dragon_select.set_item_metadata(_dragon_select.item_count - 1, str(did))
	for i in range(_dragon_select.item_count):
		if str(_dragon_select.get_item_metadata(i)) == _selected_dragon_id:
			_dragon_select.select(i)
			break
	_update_status_label()

func _update_status_label() -> void:
	if _status_label == null:
		return
	var def: Dictionary = DragonData.DRAGONS.get(_selected_dragon_id, {})
	var lvl: int = DragonProgression.get_dragon_level(_save, _selected_dragon_id)
	_status_label.text = "Lv%d  %s" % [lvl, str(def.get("element", "?")).capitalize()]

# ── Zone 1 state refresh ──────────────────────────────────────────────────────

func _refresh_zone_states() -> void:
	var defeated: Dictionary = _save.get("bestiary_defeated", {})
	for i in range(_zones.size()):
		if i < ZONE_NPC_IDS.size():
			_zones[i].set_defeated(defeated.has(ZONE_NPC_IDS[i]) and int(defeated.get(ZONE_NPC_IDS[i], 0)) > 0)
	if _boss_zone != null:
		_boss_zone.set_defeated(_save.get("mission_flags", []).has(BOSS_FLAG))

func _refresh_boss_gate() -> void:
	if _boss_gate == null:
		return
	var defeated: Dictionary = _save.get("bestiary_defeated", {})
	var all_clear: bool = true
	for npc_id in ZONE_NPC_IDS:
		if not (defeated.has(npc_id) and int(defeated.get(npc_id, 0)) > 0):
			all_clear = false
			break
	_boss_gate.set_locked(not all_clear)

# ── Zone 2 state refresh ──────────────────────────────────────────────────────

func _is_zone2_unlocked() -> bool:
	# Zone 2 is accessible once the Zone 1 boss (recursive_golem) is defeated.
	var defeated: Dictionary = _save.get("bestiary_defeated", {})
	return defeated.has("recursive_golem") and int(defeated.get("recursive_golem", 0)) > 0

func _refresh_zone2_visibility() -> void:
	if _zone2_root == null:
		return
	_zone2_root.visible = _is_zone2_unlocked()

func _refresh_zone2_states() -> void:
	if not _is_zone2_unlocked():
		return
	var defeated: Dictionary = _save.get("bestiary_defeated", {})
	for i in range(_zones2.size()):
		if i < ZONE2_NPC_IDS.size():
			_zones2[i].set_defeated(defeated.has(ZONE2_NPC_IDS[i]) and int(defeated.get(ZONE2_NPC_IDS[i], 0)) > 0)
	if _boss_zone2 != null:
		_boss_zone2.set_defeated(_save.get("mission_flags", []).has(BOSS2_FLAG))

func _refresh_boss_gate2() -> void:
	if _boss_gate2 == null or not _is_zone2_unlocked():
		return
	var defeated: Dictionary = _save.get("bestiary_defeated", {})
	var all_clear: bool = true
	for npc_id in ZONE2_NPC_IDS:
		if not (defeated.has(npc_id) and int(defeated.get(npc_id, 0)) > 0):
			all_clear = false
			break
	_boss_gate2.set_locked(not all_clear)

# ── Shared handlers ───────────────────────────────────────────────────────────

func _on_dragon_selected(index: int) -> void:
	_selected_dragon_id = str(_dragon_select.get_item_metadata(index))
	_update_status_label()

func _write_save() -> void:
	SaveIO.flush(_save)

func _on_zone_entered(npc_id: String) -> void:
	if _in_battle:
		return
	_in_battle = true
	navigate.emit("battle", {
		"dragon_id": _selected_dragon_id,
		"npc_id":    npc_id,
		"return_screen": "world",
	})
