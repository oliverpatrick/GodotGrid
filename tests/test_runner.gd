extends SceneTree


func _initialize() -> void:
	var suites := [preload("res://tests/smoke_test.gd")]
	for suite in suites:
		if not suite.run():
			printerr("GODOT_TEST_FAILED: %s" % suite.resource_path)
			quit(1)
			return
	print("GODOT_TESTS_OK")
	quit(0)
