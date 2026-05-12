extends GutTest

const SingularityProgress = preload("res://scripts/sim/singularity_progress.gd")

func _save(owned_elements: Array = [], defeated_npcs: Array = [],
		   has_elder: bool = false, singularity_complete: bool = false) -> Dictionary:
	var dragons := {}
	for el in ["fire", "ice", "storm", "stone", "venom", "shadow"]:
		dragons[el] = {
			"owned": owned_elements.has(el),
			"level": 50 if (has_elder and owned_elements.has(el)) else 1,
		}
	return {
		"dragons":             dragons,
		"defeated_npcs":       defeated_npcs,
		"singularity_complete": singularity_complete,
	}

func test_stage_0_no_dragons() -> void:
	assert_eq(SingularityProgress.get_singularity_stage(_save()), 0)

func test_stage_1_two_owned() -> void:
	assert_eq(SingularityProgress.get_singularity_stage(_save(["fire", "ice"])), 1)

func test_stage_2_four_owned() -> void:
	assert_eq(SingularityProgress.get_singularity_stage(
		_save(["fire", "ice", "storm", "stone"])), 2)

func test_stage_3_six_owned() -> void:
	assert_eq(SingularityProgress.get_singularity_stage(
		_save(["fire", "ice", "storm", "stone", "venom", "shadow"])), 3)

func test_stage_4_has_elder() -> void:
	assert_eq(SingularityProgress.get_singularity_stage(
		_save(["fire"], [], true)), 4)

func test_stage_5_all_base_npcs_defeated() -> void:
	var npcs := ["firewall_sentinel", "bit_wraith", "glitch_hydra", "recursive_golem"]
	assert_eq(SingularityProgress.get_singularity_stage(_save([], npcs)), 5)

func test_singularity_complete_returns_3() -> void:
	assert_eq(SingularityProgress.get_singularity_stage(
		_save([], [], false, true)), 3)

func test_not_unlocked_without_all_npcs() -> void:
	assert_false(SingularityProgress.is_singularity_unlocked(
		_save([], ["firewall_sentinel"])))

func test_unlocked_when_all_base_npcs_defeated() -> void:
	var npcs := ["firewall_sentinel", "bit_wraith", "glitch_hydra", "recursive_golem"]
	assert_true(SingularityProgress.is_singularity_unlocked(_save([], npcs)))

func test_unlocked_when_singularity_complete() -> void:
	assert_true(SingularityProgress.is_singularity_unlocked(
		_save([], [], false, true)))
