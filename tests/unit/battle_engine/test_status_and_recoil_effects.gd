extends GutTest

const CombatantBattleStateScript = preload("res://src/battle/runtime/combatant_battle_state.gd")
const BattleSessionScript = preload("res://src/battle/runtime/battle_session.gd")
const StatusRuntimeStateScript = preload("res://src/battle/runtime/status_runtime_state.gd")


func test_status_apply_rate_and_overwrite_use_fixed_rolls_and_single_slot() -> void:
	var session: BattleSession = BattleSessionScript.new()
	var target: RefCounted = _make_combatant(100, 100, 40)
	var applied_count: int = 0

	for index in range(1000):
		target.clear_status()
		var roll: float = float(index) / 1000.0
		if session.try_apply_status(target, session.STATUS_BURN, roll).applied:
			applied_count += 1

	assert_between(applied_count, 250, 350, "Status apply should land at 30% +/- 5%.")

	var poison_result: RefCounted = session.try_apply_status(target, session.STATUS_POISON, 0.0)
	var freeze_result: RefCounted = session.try_apply_status(target, session.STATUS_FREEZE, 0.0)

	assert_true(poison_result.applied)
	assert_true(freeze_result.applied)
	assert_eq(target.active_status.status_id, session.STATUS_FREEZE)
	assert_eq(target.active_status.duration_turns, 1)
	assert_true(target.pending_skip == session.STATUS_FREEZE)

	var burn_result: RefCounted = session.try_apply_status(target, session.STATUS_BURN, 0.0)

	assert_true(burn_result.applied)
	assert_eq(target.active_status.status_id, session.STATUS_BURN)
	assert_eq(target.pending_skip, &"")
	assert_false(session.should_skip_telegraph_action(target, 1.0))


func test_burn_and_poison_dot_use_max_hp_last_two_turns_and_can_ko() -> void:
	var session: BattleSession = BattleSessionScript.new()
	var burned: RefCounted = _make_combatant(100, 13, 30)
	var poisoned: RefCounted = _make_combatant(50, 5, 20)
	burned.active_status = _make_status(session.STATUS_BURN, 2)
	poisoned.active_status = _make_status(session.STATUS_POISON, 2)

	var first_recoil: RefCounted = session.resolve_recoil(burned, poisoned)
	assert_eq(first_recoil.player_dot_damage, 8)
	assert_eq(first_recoil.enemy_dot_damage, 3)
	assert_eq(burned.current_hp, 5)
	assert_eq(poisoned.current_hp, 2)
	assert_eq(first_recoil.tick_order, [&"player", &"enemy"])

	var second_recoil: RefCounted = session.resolve_recoil(burned, poisoned)
	assert_eq(second_recoil.player_dot_damage, 8)
	assert_eq(second_recoil.enemy_dot_damage, 3)
	assert_eq(burned.current_hp, 0)
	assert_eq(poisoned.current_hp, 0)
	assert_true(second_recoil.player_ko)
	assert_true(second_recoil.enemy_ko)
	assert_null(burned.active_status)
	assert_null(poisoned.active_status)

	var third_recoil: RefCounted = session.resolve_recoil(burned, poisoned)
	assert_eq(third_recoil.player_dot_damage, 0)
	assert_eq(third_recoil.enemy_dot_damage, 0)


func test_freeze_and_paralysis_skip_telegraph_with_deterministic_rolls() -> void:
	var session: BattleSession = BattleSessionScript.new()
	var frozen: RefCounted = _make_combatant(80, 80, 25)
	var paralyzed: RefCounted = _make_combatant(80, 80, 25)
	var paralysis_skips: int = 0
	frozen.active_status = _make_status(session.STATUS_FREEZE, 1)
	frozen.pending_skip = session.STATUS_FREEZE

	assert_true(session.should_skip_telegraph_action(frozen, 1.0))
	assert_false(session.should_skip_telegraph_action(frozen, 1.0))

	paralyzed.active_status = _make_status(session.STATUS_PARALYSIS, 2)
	for index in range(1000):
		var roll: float = float(index) / 1000.0
		if session.should_skip_telegraph_action(paralyzed, roll):
			paralysis_skips += 1

	assert_between(paralysis_skips, 450, 550, "Paralysis should skip at 50% +/- 5%.")


func test_guard_break_uses_base_defense_and_reapply_does_not_stack() -> void:
	var session: BattleSession = BattleSessionScript.new()
	var defender: RefCounted = _make_combatant(100, 100, 90)

	session.try_apply_status(defender, session.STATUS_GUARD_BREAK, 0.0)
	assert_eq(session.effective_defense(defender), 54)

	session.try_apply_status(defender, session.STATUS_GUARD_BREAK, 0.0)

	assert_eq(session.effective_defense(defender), 54)
	assert_eq(defender.base_defense, 90)
	assert_eq(defender.active_status.duration_turns, 2)


func test_recoil_ticks_player_then_enemy_even_when_player_reaches_zero() -> void:
	var session: BattleSession = BattleSessionScript.new()
	var player: RefCounted = _make_combatant(100, 1, 20)
	var enemy: RefCounted = _make_combatant(100, 1, 20)
	player.active_status = _make_status(session.STATUS_BURN, 1)
	enemy.active_status = _make_status(session.STATUS_POISON, 1)

	var recoil: RefCounted = session.resolve_recoil(player, enemy)

	assert_eq(recoil.tick_order, [&"player", &"enemy"])
	assert_eq(player.current_hp, 0)
	assert_eq(enemy.current_hp, 0)
	assert_true(recoil.player_ko)
	assert_true(recoil.enemy_ko)
	assert_true(recoil.resolution_required)


func _make_combatant(max_hp: int, current_hp: int, base_defense: int) -> RefCounted:
	var combatant: RefCounted = CombatantBattleStateScript.new()
	combatant.max_hp = max_hp
	combatant.current_hp = current_hp
	combatant.base_defense = base_defense
	return combatant


func _make_status(status_id: StringName, duration_turns: int) -> RefCounted:
	var status: RefCounted = StatusRuntimeStateScript.new()
	status.status_id = status_id
	status.duration_turns = duration_turns
	return status
