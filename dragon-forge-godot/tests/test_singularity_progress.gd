extends GutTest

const SingularityProgress = preload("res://scripts/sim/singularity_progress.gd")

func _make_save(owned: Array = [], defeated: Dictionary = {},
		has_elder: bool = false, complete: bool = false) -> Dictionary:
	var levels := {}
	for i in range(owned.size()):
		levels[owned[i]] = 50 if (has_elder and i == 0) else 1
	var flags: Array = []
	if complete:
		flags.append("singularity_defeated")
	return {
		"hatchery_state": { "owned_dragons": owned.duplicate() },
		"dragon_levels":  levels,
		"bestiary_defeated": defeated.duplicate(),
		"mission_flags":  flags,
	}

func test_stage_0_no_dragons() -> void:
	assert_eq(SingularityProgress.get_singularity_stage(_make_save()), 0)

func test_stage_1_two_owned() -> void:
	assert_eq(SingularityProgress.get_singularity_stage(_make_save(["fire", "ice"])), 1)

func test_stage_2_four_owned() -> void:
	assert_eq(SingularityProgress.get_singularity_stage(
		_make_save(["fire", "ice", "storm", "stone"])), 2)

func test_stage_3_six_owned() -> void:
	assert_eq(SingularityProgress.get_singularity_stage(
		_make_save(["fire", "ice", "storm", "stone", "venom", "shadow"])), 3)

func test_stage_4_has_elder() -> void:
	assert_eq(SingularityProgress.get_singularity_stage(
		_make_save(["fire"], {}, true)), 4)

func test_stage_5_all_base_npcs_defeated() -> void:
	var defeated := {
		"firewall_sentinel": 1, "bit_wraith": 1,
		"glitch_hydra": 1, "recursive_golem": 1,
	}
	assert_eq(SingularityProgress.get_singularity_stage(_make_save([], defeated)), 5)

func test_singularity_complete_returns_0() -> void:
	assert_eq(SingularityProgress.get_singularity_stage(
		_make_save([], {}, false, true)), 0)

func test_not_unlocked_without_vulture() -> void:
	assert_false(SingularityProgress.is_singularity_unlocked(
		_make_save([], {"firewall_sentinel": 1})))

func test_unlocked_when_protocol_vulture_defeated() -> void:
	assert_true(SingularityProgress.is_singularity_unlocked(
		_make_save([], {"protocol_vulture": 1})))

func test_unlocked_when_singularity_complete() -> void:
	assert_true(SingularityProgress.is_singularity_unlocked(
		_make_save([], {}, false, true)))
