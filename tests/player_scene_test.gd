extends RefCounted

const ContentLoader = preload("res://content/content_loader.gd")
const PlayerScene = preload("res://assets/player/player.tscn")

static func run() -> bool:
	var bundle = ContentLoader.load_bundle(OS.get_environment("GAME_CONTENT_ROOT"))
	var player = PlayerScene.instantiate()
	var animations: AnimationPlayer = player.get_node("AnimationPlayer")
	var skeleton: Skeleton3D = player.get_node("Rig/Skeleton3D")
	var mannequin: MeshInstance3D = player.get_node("Rig/Skeleton3D/Mannequin")
	if mannequin.skeleton != NodePath(".."):
		printerr("mannequin skeleton path=%s" % mannequin.skeleton)
		player.free()
		return false
	if mannequin.skin == null or mannequin.mesh == null:
		printerr("mannequin has no skin or mesh")
		player.free()
		return false
	var arrays := mannequin.mesh.surface_get_arrays(0)
	if arrays[Mesh.ARRAY_BONES].is_empty() or arrays[Mesh.ARRAY_WEIGHTS].is_empty():
		printerr("mannequin has no weighted bone data")
		player.free()
		return false
	for animation in [&"Idle", &"Walk", &"Jog_Fwd", &"Sword_Attack", &"Punch_Jab", &"Punch_Cross", &"Death01"]:
		if not animations.has_animation(animation):
			printerr("missing animation: %s; available=%s" % [animation, animations.get_animation_list()])
			player.free()
			return false
	player.configure(1, "Test", bundle)
	player.snap_to_tile(10, 10, 0)
	var test_root := Node3D.new()
	Engine.get_main_loop().root.add_child(test_root)
	test_root.add_child(player)
	if animations.current_animation != "Idle":
		printerr("live initial animation=%s" % animations.current_animation)
		test_root.free()
		return false
	var bone := skeleton.find_bone("DEF-upper_arm.L")
	if bone < 0:
		printerr("missing animated upper-arm bone")
		test_root.free()
		return false
	var before := skeleton.get_bone_pose_rotation(bone)
	animations.advance(0.2)
	var after := skeleton.get_bone_pose_rotation(bone)
	if before.is_equal_approx(after):
		printerr("Idle advanced without changing the upper-arm pose")
		test_root.free()
		return false
	player.confirm_tile(11, 10, 0, 0.6)
	if animations.current_animation != "Walk":
		printerr("walk animation=%s" % animations.current_animation)
		test_root.free()
		return false
	player.advance_interpolation(0.6)
	player.snap_to_tile(10, 10, 0)
	player.confirm_tile(12, 10, 0, 0.6)
	if animations.current_animation != "Jog_Fwd":
		printerr("jog animation=%s" % animations.current_animation)
		test_root.free()
		return false
	player.advance_interpolation(0.6)
	player.set_action(1)
	if animations.current_animation != "Sword_Attack":
		printerr("harvest animation=%s" % animations.current_animation)
		test_root.free()
		return false
	player.confirm_tile(11, 10, 0, 0.6)
	if animations.current_animation != "Walk":
		printerr("harvest movement animation=%s" % animations.current_animation)
		test_root.free()
		return false
	player.advance_interpolation(0.6)
	if animations.current_animation != "Sword_Attack":
		printerr("resumed animation=%s" % animations.current_animation)
		test_root.free()
		return false
	player.set_action(0)
	var ok := animations.current_animation == "Idle"
	test_root.free()
	return ok
