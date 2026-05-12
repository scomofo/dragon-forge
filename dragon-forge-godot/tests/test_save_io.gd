# test_save_io.gd
# GUT test suite for SaveData and SaveIO round-trip serialisation.
# Run headless:
#   & 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' \
#     --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' \
#     -s res://addons/gut/gut_cmdln.gd \
#     -gdir=res://tests -ginclude_subdirs -gexit
extends GutTest

const TEMP_PATH := "user://test_save_roundtrip.tres"

# ── helpers ──────────────────────────────────────────────────────────────

func _save_and_reload(s: SaveData) -> SaveData:
	var err := ResourceSaver.save(s, TEMP_PATH)
	assert_eq(err, OK, "ResourceSaver should return OK")
	var loaded: Resource = ResourceLoader.load(TEMP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_not_null(loaded, "ResourceLoader should return a resource")
	assert_true(loaded is SaveData, "Loaded resource should be a SaveData")
	return loaded as SaveData

func after_each() -> void:
	if FileAccess.file_exists(TEMP_PATH):
		DirAccess.remove_absolute(TEMP_PATH)

# ── tests ─────────────────────────────────────────────────────────────────

func test_default_save_has_all_seven_dragons() -> void:
	var s := SaveData.make_default()
	var expected := ["fire", "ice", "storm", "stone", "venom", "shadow", "void"]
	for el in expected:
		assert_true(s.dragons.has(el), "Default save should have dragon: %s" % el)

func test_default_save_dragons_not_owned() -> void:
	var s := SaveData.make_default()
	for el in s.dragons:
		assert_false(bool(s.dragons[el].get("owned", true)),
			"Dragon %s should start unowned" % el)

func test_default_data_scraps_zero() -> void:
	var s := SaveData.make_default()
	assert_eq(s.data_scraps, 0)

func test_default_schema_version() -> void:
	var s := SaveData.make_default()
	assert_eq(s.version, SaveData.SCHEMA_VERSION)

func test_roundtrip_preserves_data_scraps() -> void:
	var s := SaveData.make_default()
	s.data_scraps = 1337
	var reloaded := _save_and_reload(s)
	assert_eq(reloaded.data_scraps, 1337, "data_scraps should survive round-trip")

func test_roundtrip_preserves_dragon_ownership() -> void:
	var s := SaveData.make_default()
	s.dragons["fire"]["owned"] = true
	s.dragons["fire"]["level"] = 5
	s.dragons["fire"]["shiny"] = true
	var reloaded := _save_and_reload(s)
	var fire: Dictionary = reloaded.dragons.get("fire", {})
	assert_true(bool(fire.get("owned")), "fire should be owned after round-trip")
	assert_eq(int(fire.get("level")), 5, "fire level should be 5 after round-trip")
	assert_true(bool(fire.get("shiny")), "fire should be shiny after round-trip")

func test_roundtrip_preserves_milestones() -> void:
	var s := SaveData.make_default()
	s.milestones = ["first_discovery", "battle_veteran"]
	var reloaded := _save_and_reload(s)
	assert_true(reloaded.milestones.has("first_discovery"),
		"milestones should contain first_discovery after round-trip")
	assert_true(reloaded.milestones.has("battle_veteran"),
		"milestones should contain battle_veteran after round-trip")

func test_roundtrip_preserves_stats() -> void:
	var s := SaveData.make_default()
	s.stats["battles_won"] = 42
	s.stats["fusions_completed"] = 7
	var reloaded := _save_and_reload(s)
	assert_eq(int(reloaded.stats.get("battles_won")), 42)
	assert_eq(int(reloaded.stats.get("fusions_completed")), 7)

func test_roundtrip_preserves_flags() -> void:
	var s := SaveData.make_default()
	s.flags["met_felix"] = true
	s.flags["current_act"] = 3
	s.flags["fragments_unlocked"] = ["001", "007"]
	var reloaded := _save_and_reload(s)
	assert_true(bool(reloaded.flags.get("met_felix")),
		"met_felix should be true after round-trip")
	assert_eq(int(reloaded.flags.get("current_act")), 3)
	assert_true(reloaded.has_fragment("007"),
		"has_fragment('007') should return true after round-trip")

func test_roundtrip_preserves_singularity_progress() -> void:
	var s := SaveData.make_default()
	s.singularity_progress["defeated"] = ["data_corruption", "memory_leak"]
	s.singularity_progress["final_boss_phase"] = 2
	var reloaded := _save_and_reload(s)
	var prog: Dictionary = reloaded.singularity_progress
	assert_true((prog.get("defeated") as Array).has("data_corruption"))
	assert_eq(int(prog.get("final_boss_phase")), 2)

func test_roundtrip_preserves_skye() -> void:
	var s := SaveData.make_default()
	s.skye["wrench_tier"] = 3
	s.skye["relics_owned"] = ["iron_knuckle", "hydra_cog"]
	s.skye["bounties_cleared"] = 4
	var reloaded := _save_and_reload(s)
	assert_eq(int(reloaded.skye.get("wrench_tier")), 3)
	assert_true((reloaded.skye.get("relics_owned") as Array).has("iron_knuckle"))
	assert_eq(int(reloaded.skye.get("bounties_cleared")), 4)

func test_roundtrip_preserves_inventory_cores() -> void:
	var s := SaveData.make_default()
	s.inventory["cores"] = {"fire": 3, "ice": 1}
	s.inventory["xp_boost_battles"] = 3
	var reloaded := _save_and_reload(s)
	var cores: Dictionary = reloaded.inventory.get("cores", {})
	assert_eq(int(cores.get("fire")), 3)
	assert_eq(int(reloaded.inventory.get("xp_boost_battles")), 3)

func test_roundtrip_preserves_records() -> void:
	var s := SaveData.make_default()
	s.records["fastest_win"] = 4
	s.records["highest_damage"] = 210
	s.records["longest_streak"] = 9
	var reloaded := _save_and_reload(s)
	assert_eq(int(reloaded.records.get("fastest_win")), 4)
	assert_eq(int(reloaded.records.get("highest_damage")), 210)
	assert_eq(int(reloaded.records.get("longest_streak")), 9)

func test_default_records_fastest_win_is_minus_one() -> void:
	# JS uses null; GDScript uses -1 to indicate "never won"
	var s := SaveData.make_default()
	assert_eq(int(s.records.get("fastest_win")), -1,
		"fastest_win default should be -1 (never won)")

func test_migration_v1_adds_void_dragon() -> void:
	# Simulate a v1 save missing the void dragon
	var old_save := SaveData.make_default()
	old_save.version = 1
	old_save.dragons.erase("void")
	assert_false(old_save.dragons.has("void"), "Setup: void removed for migration test")
	# Run through migration using a temporary SaveIO node
	var save_io_node := Node.new()
	save_io_node.set_script(load("res://scripts/sim/save_io.gd"))
	add_child(save_io_node)
	var migrated: SaveData = save_io_node.migrate(old_save)
	assert_true(migrated.dragons.has("void"),
		"Migration v1 to v2 should add void dragon")
	assert_eq(migrated.version, 2, "Version should be 2 after migration")
	save_io_node.queue_free()

func test_owns_dragon_helper() -> void:
	var s := SaveData.make_default()
	assert_false(s.owns_dragon("fire"), "fire should not be owned by default")
	s.dragons["fire"]["owned"] = true
	assert_true(s.owns_dragon("fire"), "fire should be owned after setting owned=true")

func test_has_fragment_helper() -> void:
	var s := SaveData.make_default()
	assert_false(s.has_fragment("001"))
	s.flags["fragments_unlocked"] = ["001", "003"]
	assert_true(s.has_fragment("001"))
	assert_false(s.has_fragment("007"))
