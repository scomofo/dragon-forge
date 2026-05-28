extends GutTest

const SCENE_FLOW_SERVICE_PATH: String = "res://src/scene_flow/scene_flow_service.gd"
const SETUP_FAILURE_SCREEN_PATH: String = "res://tests/fixtures/scene_flow/setup_failure_screen.gd"


func test_registers_screens_and_changes_active_screen_by_stable_id() -> void:
	var service: Node = _make_service()
	if service == null:
		return

	var hub_registration: RefCounted = service.register_screen(&"hub", _make_packed_screen("HubScreen"))
	var map_registration: RefCounted = service.register_screen(&"campaign_map", _make_packed_screen("CampaignMapScreen"))
	var changed_results: Array[RefCounted] = []
	var on_changed: Callable = func(result: RefCounted) -> void:
		changed_results.append(result)
	service.screen_changed.connect(on_changed)

	var hub_result: RefCounted = service.change_screen(&"hub")
	var map_result: RefCounted = service.change_screen(&"campaign_map")

	service.screen_changed.disconnect(on_changed)
	assert_true(hub_registration.success)
	assert_true(map_registration.success)
	assert_true(hub_result.success)
	assert_true(map_result.success)
	assert_eq(service.get_active_screen_id(), &"campaign_map")
	assert_eq(service.get_active_screen().name, "CampaignMapScreen")
	assert_eq(changed_results.size(), 2)
	assert_eq(changed_results[1].screen_id, &"campaign_map")


func test_duplicate_registration_returns_explicit_failure_result() -> void:
	var service: Node = _make_service()
	if service == null:
		return

	var first_result: RefCounted = service.register_screen(&"hub", _make_packed_screen("HubScreen"))
	var duplicate_result: RefCounted = service.register_screen(&"hub", _make_packed_screen("OtherHubScreen"))

	assert_true(first_result.success)
	assert_false(duplicate_result.success)
	assert_eq(duplicate_result.reason, &"duplicate_registration")
	assert_eq(duplicate_result.screen_id, &"hub")
	assert_true(service.change_screen(&"hub").success)
	assert_eq(service.get_active_screen().name, "HubScreen")


func test_unregistered_screen_failure_preserves_current_screen() -> void:
	var service: Node = _make_service()
	if service == null:
		return
	var failed_results: Array[RefCounted] = []
	var on_failed: Callable = func(result: RefCounted) -> void:
		failed_results.append(result)
	service.screen_change_failed.connect(on_failed)
	service.register_screen(&"hub", _make_packed_screen("HubScreen"))
	assert_true(service.change_screen(&"hub").success)
	var active_before: Node = service.get_active_screen()

	var missing_result: RefCounted = service.change_screen(&"missing")

	service.screen_change_failed.disconnect(on_failed)
	assert_false(missing_result.success)
	assert_eq(missing_result.reason, &"unregistered_screen_id")
	assert_eq(missing_result.screen_id, &"missing")
	assert_eq(service.get_active_screen(), active_before)
	assert_eq(service.get_active_screen_id(), &"hub")
	assert_eq(failed_results.size(), 1)
	assert_eq(failed_results[0].reason, &"unregistered_screen_id")


func test_instantiation_failure_preserves_current_screen_and_emits_failure() -> void:
	var service: Node = _make_service()
	if service == null:
		return
	var failed_results: Array[RefCounted] = []
	var on_failed: Callable = func(result: RefCounted) -> void:
		failed_results.append(result)
	service.screen_change_failed.connect(on_failed)
	service.register_screen(&"hub", _make_packed_screen("HubScreen"))
	service.register_screen(&"empty_scene", PackedScene.new())
	assert_true(service.change_screen(&"hub").success)
	var active_before: Node = service.get_active_screen()

	var failure_result: RefCounted = service.change_screen(&"empty_scene")

	service.screen_change_failed.disconnect(on_failed)
	assert_false(failure_result.success)
	assert_eq(failure_result.reason, &"instantiation_failure")
	assert_eq(service.get_active_screen(), active_before)
	assert_eq(service.get_active_screen_id(), &"hub")
	assert_eq(failed_results.size(), 1)
	assert_eq(failed_results[0].reason, &"instantiation_failure")


func test_setup_failure_preserves_current_screen_and_emits_failure() -> void:
	var service: Node = _make_service()
	if service == null:
		return
	var failed_results: Array[RefCounted] = []
	var on_failed: Callable = func(result: RefCounted) -> void:
		failed_results.append(result)
	service.screen_change_failed.connect(on_failed)
	service.register_screen(&"hub", _make_packed_screen("HubScreen"))
	service.register_screen(&"broken", _make_packed_screen("BrokenScreen", load(SETUP_FAILURE_SCREEN_PATH)))
	assert_true(service.change_screen(&"hub").success)
	var active_before: Node = service.get_active_screen()

	var failure_result: RefCounted = service.change_screen(&"broken", {"reason": &"test"})

	service.screen_change_failed.disconnect(on_failed)
	assert_false(failure_result.success)
	assert_eq(failure_result.reason, &"setup_failure")
	assert_eq(service.get_active_screen(), active_before)
	assert_eq(service.get_active_screen_id(), &"hub")
	assert_eq(failed_results.size(), 1)
	assert_eq(failed_results[0].reason, &"setup_failure")


func _make_service() -> Node:
	assert_true(ResourceLoader.exists(SCENE_FLOW_SERVICE_PATH), "SceneFlowService script should exist.")
	if not ResourceLoader.exists(SCENE_FLOW_SERVICE_PATH):
		return null
	var script: GDScript = load(SCENE_FLOW_SERVICE_PATH)
	assert_not_null(script)
	if script == null:
		return null
	return add_child_autofree(script.new())


func _make_packed_screen(node_name: String, script: Script = null) -> PackedScene:
	var root: Control = Control.new()
	root.name = node_name
	if script != null:
		root.set_script(script)
	var packed_scene := PackedScene.new()
	var pack_result: Error = packed_scene.pack(root)
	root.free()
	assert_eq(pack_result, OK)
	return packed_scene
