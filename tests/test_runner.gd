extends SceneTree

const ContentLoader = preload("res://content/content_loader.gd")
const RegionMeshBuilder = preload("res://world/region_mesh_builder.gd")

func _initialize() -> void:
	call_deferred("run_tests")


func run_tests() -> void:
	var suites := [
		preload("res://tests/smoke_test.gd"),
		preload("res://tests/content_loader_test.gd"),
		preload("res://tests/region_mesh_test.gd"),
		preload("res://tests/terrain_generator_test.gd"),
		preload("res://tests/protocol_test.gd"),
		preload("res://tests/network_client_test.gd"),
		preload("res://tests/auth_client_test.gd"),
		preload("res://tests/movement_view_test.gd"),
		preload("res://tests/world_command_sequence_test.gd"),
		preload("res://tests/player_scene_test.gd"),
		preload("res://tests/player_registry_test.gd"),
		preload("res://tests/selection_feedback_test.gd"),
		preload("res://tests/tree_presentation_test.gd"),
		preload("res://tests/ui_scale_test.gd"),
		preload("res://tests/run_toggle_test.gd"),
		preload("res://tests/hud_state_test.gd"),
	]
	for suite in suites:
		if not suite.run():
			printerr("GODOT_TEST_FAILED: %s" % suite.resource_path)
			quit(1)
			return
	if not await terrain_accepts_ground_clicks():
		printerr("GODOT_TEST_FAILED: terrain ground clicks do not hit the loaded region")
		quit(1)
		return
	print("GODOT_TESTS_OK")
	quit(0)


func terrain_accepts_ground_clicks() -> bool:
	var bundle = ContentLoader.load_bundle(OS.get_environment("GAME_CONTENT_ROOT"))
	if bundle == null:
		return false
	var root := Node3D.new()
	get_root().add_child(root)
	var region: Dictionary = bundle.regions["1:1:0"]
	var terrain: MeshInstance3D = RegionMeshBuilder.build(region)
	root.add_child(terrain)
	await physics_frame
	var query := PhysicsRayQueryParameters3D.create(Vector3(80.5, 100.0, 80.5), Vector3(80.5, -100.0, 80.5))
	var hit := root.get_world_3d().direct_space_state.intersect_ray(query)
	root.queue_free()
	return not hit.is_empty() and hit.collider is StaticBody3D
