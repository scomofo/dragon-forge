extends GutTest

const EconomyLedgerScript = preload("res://src/economy/economy_ledger.gd")
const SaveDataScript = preload("res://src/save/save_data.gd")
const SaveServiceScript = preload("res://src/save/save_service.gd")

const TEST_SAVE_PATH: String = "user://gut_scrap_spend_transaction_slot.tres"
const TEST_TEMP_PATH: String = "user://gut_scrap_spend_transaction_slot.tmp.tres"
const TEST_BACKUP_PATH: String = "user://gut_scrap_spend_transaction_slot.bak.tres"


func before_each() -> void:
	_remove_save_files()


func after_each() -> void:
	_remove_save_files()


func test_exact_price_spend_commits_zero_balance() -> void:
	var services: Dictionary = _make_initialized_services(50)
	var ledger: EconomyLedger = services.ledger
	var save_service: SaveService = services.save

	var tx: SaveTransaction = save_service.begin_transaction(&"exact_price_spend")
	var spend_result: EconomyResult = ledger.spend_scraps(tx, 50, &"field_kit")
	var commit_result: SaveCommitResult = save_service.commit_transaction(tx)
	var committed_save: SaveData = _load_save(TEST_SAVE_PATH)

	assert_true(spend_result.success, spend_result.error_message)
	assert_eq(spend_result.reason, &"ok")
	assert_eq(spend_result.sink_id, &"field_kit")
	assert_eq(spend_result.amount, 50)
	assert_eq(spend_result.balance_before, 50)
	assert_eq(spend_result.balance_after, 0)
	assert_true(commit_result.success, commit_result.error_message)
	assert_eq(committed_save.player_scraps, 0)


func test_partial_spend_mutates_only_staged_save_before_commit() -> void:
	var services: Dictionary = _make_initialized_services(50)
	var ledger: EconomyLedger = services.ledger
	var save_service: SaveService = services.save

	var tx: SaveTransaction = save_service.begin_transaction(&"partial_spend")
	var spend_result: EconomyResult = ledger.spend_scraps(tx, 35, &"defrag_patch")
	var canonical_before_commit: SaveData = _load_save(TEST_SAVE_PATH)

	assert_true(spend_result.success, spend_result.error_message)
	assert_eq(spend_result.balance_before, 50)
	assert_eq(spend_result.balance_after, 15)
	assert_eq(tx.staged_save.player_scraps, 15)
	assert_eq(canonical_before_commit.player_scraps, 50)

	var commit_result: SaveCommitResult = save_service.commit_transaction(tx)
	var committed_save: SaveData = _load_save(TEST_SAVE_PATH)

	assert_true(commit_result.success, commit_result.error_message)
	assert_eq(committed_save.player_scraps, 15)


func test_insufficient_negative_and_zero_spends_do_not_mutate() -> void:
	var services: Dictionary = _make_initialized_services(10)
	var ledger: EconomyLedger = services.ledger
	var save_service: SaveService = services.save

	var insufficient_tx: SaveTransaction = save_service.begin_transaction(&"insufficient_spend")
	var insufficient_result: EconomyResult = ledger.spend_scraps(insufficient_tx, 35, &"defrag_patch")
	assert_false(insufficient_result.success)
	assert_eq(insufficient_result.reason, &"insufficient_scraps")
	assert_eq(insufficient_result.balance_before, 10)
	assert_eq(insufficient_result.balance_after, 10)
	assert_eq(insufficient_tx.staged_save.player_scraps, 10)
	assert_eq(_load_save(TEST_SAVE_PATH).player_scraps, 10)

	var negative_tx: SaveTransaction = save_service.begin_transaction(&"negative_spend")
	var negative_result: EconomyResult = ledger.spend_scraps(negative_tx, -1, &"invalid")
	assert_false(negative_result.success)
	assert_eq(negative_result.reason, &"invalid_amount")
	assert_eq(negative_tx.staged_save.player_scraps, 10)

	var zero_tx: SaveTransaction = save_service.begin_transaction(&"zero_spend")
	var zero_result: EconomyResult = ledger.spend_scraps(zero_tx, 0, &"no_op")
	assert_true(zero_result.success, zero_result.error_message)
	assert_eq(zero_result.reason, &"ok")
	assert_eq(zero_result.balance_before, 10)
	assert_eq(zero_result.balance_after, 10)
	assert_eq(zero_tx.staged_save.player_scraps, 10)
	assert_eq(_load_save(TEST_SAVE_PATH).player_scraps, 10)


func test_invalid_transaction_spend_returns_named_failure() -> void:
	var ledger: EconomyLedger = EconomyLedgerScript.new()

	var null_result: EconomyResult = ledger.spend_scraps(null, 10, &"field_kit")
	assert_false(null_result.success)
	assert_eq(null_result.reason, &"invalid_transaction")
	assert_eq(null_result.sink_id, &"field_kit")

	var inactive_tx: SaveTransaction = SaveTransaction.new()
	inactive_tx.active = false
	var inactive_result: EconomyResult = ledger.spend_scraps(inactive_tx, 10, &"field_kit")
	assert_false(inactive_result.success)
	assert_eq(inactive_result.reason, &"invalid_transaction")


func test_failed_commit_rolls_back_successful_staged_spend() -> void:
	var services: Dictionary = _make_initialized_services(50)
	var ledger: EconomyLedger = services.ledger
	var save_service: SaveService = services.save
	save_service.set_failure_injection(SaveService.FAILURE_AFTER_TEMP_WRITE_BEFORE_SWAP, true)

	var tx: SaveTransaction = save_service.begin_transaction(&"rollback_spend")
	var spend_result: EconomyResult = ledger.spend_scraps(tx, 35, &"defrag_patch")
	var failed_commit: SaveCommitResult = save_service.commit_transaction(tx)
	var canonical_after_failure: SaveData = _load_save(TEST_SAVE_PATH)

	assert_true(spend_result.success, spend_result.error_message)
	assert_eq(spend_result.balance_after, 15)
	assert_false(failed_commit.success)
	assert_eq(failed_commit.failure_point, SaveService.FAILURE_AFTER_TEMP_WRITE_BEFORE_SWAP)
	assert_eq(canonical_after_failure.player_scraps, 50)
	assert_true(FileAccess.file_exists(TEST_TEMP_PATH), "Injected failure should leave temp file for recovery coverage.")


func _make_initialized_services(scraps: int) -> Dictionary:
	var save_service: SaveService = SaveServiceScript.new()
	save_service.configure(TEST_SAVE_PATH, 0)
	var initialize_result: SaveCommitResult = save_service.initialize_slot(_make_save_data(scraps))
	assert_true(initialize_result.success, initialize_result.error_message)
	return {
		"save": save_service,
		"ledger": EconomyLedgerScript.new(),
	}


func _make_save_data(scraps: int) -> SaveData:
	var save_data: SaveData = SaveDataScript.new()
	save_data.player_scraps = scraps
	return save_data


func _load_save(path: String) -> SaveData:
	if not ResourceLoader.exists(path):
		return null
	var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded is SaveData:
		return loaded
	return null


func _remove_save_files() -> void:
	for path in [TEST_SAVE_PATH, TEST_TEMP_PATH, TEST_BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
