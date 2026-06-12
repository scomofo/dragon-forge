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
const ZONE_TILES     := [Vector2i(6, 3), Vector2i(11, 6), Vector2i(16, 3)]
const BOSS_GATE_TILE := Vector2i(17, 5)
const BOSS_TILE      := Vector2i(19, 5)

const ZONE_NPC_IDS := ["firewall_sentinel", "buffer_overflow", "bit_wraith"]
const BOSS_NPC_ID  := "recursive_golem"
const BOSS_FLAG    := "recursive_golem_defeated"

var _save: Dictionary = {}
var _player: CharacterBody2D = null
var _zones: Array = []
var _boss_zone: Area2D = null
var _boss_gate: StaticBody2D = null
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
	_build_player(root)
	_build_hud()
	# Refresh visual state after zones are built (no-op when _save is empty;
	# setup() does the real refresh once the save is provided).
	_refresh_zone_states()
	_refresh_boss_gate()

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

	# Area highlight tiles
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
