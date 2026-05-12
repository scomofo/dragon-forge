extends GutTest

const FusionEngine = preload("res://scripts/sim/fusion_engine.gd")

func test_same_element_fusion_returns_self() -> void:
	assert_eq(FusionEngine.get_fusion_element("fire",   "fire"),   "fire")
	assert_eq(FusionEngine.get_fusion_element("shadow", "shadow"), "shadow")

func test_fire_plus_ice_is_storm() -> void:
	assert_eq(FusionEngine.get_fusion_element("fire", "ice"), "storm")
	assert_eq(FusionEngine.get_fusion_element("ice",  "fire"), "storm")

func test_fire_plus_venom_is_shadow() -> void:
	assert_eq(FusionEngine.get_fusion_element("fire",  "venom"), "shadow")
	assert_eq(FusionEngine.get_fusion_element("venom", "fire"),  "shadow")

func test_fusion_element_is_commutative() -> void:
	assert_eq(FusionEngine.get_fusion_element("ice",    "storm"),
			  FusionEngine.get_fusion_element("storm",  "ice"))
	assert_eq(FusionEngine.get_fusion_element("stone",  "shadow"),
			  FusionEngine.get_fusion_element("shadow", "stone"))

func test_same_element_is_stable() -> void:
	assert_eq(FusionEngine.get_stability_tier("fire", "fire"), "stable")

func test_opposing_elements_are_unstable() -> void:
	assert_eq(FusionEngine.get_stability_tier("fire",  "ice"),    "unstable")
	assert_eq(FusionEngine.get_stability_tier("storm", "stone"),  "unstable")
	assert_eq(FusionEngine.get_stability_tier("venom", "shadow"), "unstable")

func test_non_opposing_different_is_normal() -> void:
	assert_eq(FusionEngine.get_stability_tier("fire",  "storm"), "normal")
	assert_eq(FusionEngine.get_stability_tier("ice",   "venom"), "normal")

func test_normal_fusion_10pct_bonus() -> void:
	var a := { "hp": 100, "atk": 30, "def": 20, "spd": 20 }
	var b := { "hp": 80,  "atk": 20, "def": 30, "spd": 10 }
	assert_eq(FusionEngine.calculate_fusion_stats(a, b, "normal"),
			  { "hp": 99, "atk": 27, "def": 27, "spd": 16 })

func test_stable_fusion_25pct_bonus() -> void:
	var a := { "hp": 100, "atk": 30, "def": 20, "spd": 20 }
	var b := { "hp": 80,  "atk": 20, "def": 30, "spd": 10 }
	assert_eq(FusionEngine.calculate_fusion_stats(a, b, "stable"),
			  { "hp": 123, "atk": 33, "def": 33, "spd": 20 })

func test_unstable_fusion_hp_penalty_atk_bonus() -> void:
	var a := { "hp": 100, "atk": 30, "def": 20, "spd": 20 }
	var b := { "hp": 80,  "atk": 20, "def": 30, "spd": 10 }
	assert_eq(FusionEngine.calculate_fusion_stats(a, b, "unstable"),
			  { "hp": 79, "atk": 29, "def": 27, "spd": 16 })

func test_execute_fusion_element_and_stability() -> void:
	var a := { "id": "fire", "element": "fire",
			   "stats": { "hp": 110, "atk": 28, "def": 20, "spd": 18 },
			   "level": 12, "shiny": false }
	var b := { "id": "ice",  "element": "ice",
			   "stats": { "hp": 100, "atk": 24, "def": 26, "spd": 20 },
			   "level": 10, "shiny": false }
	var result := FusionEngine.execute_fusion(a, b)
	assert_eq(result.element,        "storm")
	assert_eq(result.stability_tier, "unstable")
	assert_true(result.fused_base_stats.has("hp"))
	assert_eq(result.level, 1)
	assert_false(result.shiny)

func test_execute_fusion_inherits_shiny_from_parent_a() -> void:
	var a := { "id": "fire",  "element": "fire",  "stats": { "hp": 100, "atk": 20, "def": 20, "spd": 20 }, "level": 12, "shiny": true  }
	var b := { "id": "storm", "element": "storm", "stats": { "hp": 100, "atk": 20, "def": 20, "spd": 20 }, "level": 12, "shiny": false }
	assert_true(FusionEngine.execute_fusion(a, b).shiny)

func test_execute_fusion_stage_iv_elder_when_both_stage_iii() -> void:
	var a := { "id": "fire", "element": "fire",
			   "stats": { "hp": 200, "atk": 50, "def": 40, "spd": 40 }, "level": 30, "shiny": false }
	var b := { "id": "fire", "element": "fire",
			   "stats": { "hp": 200, "atk": 50, "def": 40, "spd": 40 }, "level": 25, "shiny": false }
	assert_eq(FusionEngine.execute_fusion(a, b).level, 50)

func test_execute_fusion_stays_level_1_if_not_both_stage_iii() -> void:
	var a := { "id": "fire", "element": "fire",
			   "stats": { "hp": 100, "atk": 20, "def": 20, "spd": 20 }, "level": 24, "shiny": false }
	var b := { "id": "fire", "element": "fire",
			   "stats": { "hp": 100, "atk": 20, "def": 20, "spd": 20 }, "level": 25, "shiny": false }
	assert_eq(FusionEngine.execute_fusion(a, b).level, 1)
