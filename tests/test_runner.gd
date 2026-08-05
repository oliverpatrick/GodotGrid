extends SceneTree


func _initialize() -> void:
	var suites := [
		preload("res://tests/smoke_test.gd"),
		preload("res://tests/content_loader_test.gd"),
		preload("res://tests/region_mesh_test.gd"),
		preload("res://tests/terrain_generator_test.gd"),
		preload("res://tests/protocol_test.gd"),
		preload("res://tests/network_client_test.gd"),
		preload("res://tests/auth_client_test.gd"),
		preload("res://tests/movement_view_test.gd"),
		preload("res://tests/hud_state_test.gd"),
	]
	for suite in suites:
		if not suite.run():
			printerr("GODOT_TEST_FAILED: %s" % suite.resource_path)
			quit(1)
			return
	print("GODOT_TESTS_OK")
	quit(0)
