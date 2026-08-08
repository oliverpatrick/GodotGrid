extends RefCounted

const PlayerAnimationController = preload("res://world/player_animation_controller.gd")


static func run() -> bool:
	if not _missing_punch_falls_back_to_idle():
		return false
	for punch in [[2, "Punch_Cross"], [3, "Punch_Jab"]]:
		if not _movement_start_waits_for_punch(punch[0], punch[1]):
			return false
		if not _movement_finish_waits_for_punch(punch[0], punch[1]):
			return false
	return _missing_death_keeps_current_pose()


static func _movement_start_waits_for_punch(action: int, punch: String) -> bool:
	var fixture := _new_fixture()
	var animations: AnimationPlayer = fixture.animations
	var controller: PlayerAnimationController = fixture.controller
	controller.set_action(action)
	animations.advance(0.1)
	controller.movement_started(1)
	if animations.current_animation != punch:
		printerr("movement start interrupted %s with %s" % [punch, animations.current_animation])
		fixture.root.free()
		return false
	animations.advance(1.0)
	var ok := animations.current_animation == "Walk"
	if not ok:
		printerr("movement did not resume after %s: %s" % [punch, animations.current_animation])
	fixture.root.free()
	return ok


static func _movement_finish_waits_for_punch(action: int, punch: String) -> bool:
	var fixture := _new_fixture()
	var animations: AnimationPlayer = fixture.animations
	var controller: PlayerAnimationController = fixture.controller
	controller.movement_started(1)
	controller.set_action(action)
	animations.advance(0.1)
	controller.movement_finished()
	if animations.current_animation != punch:
		printerr("movement finish interrupted %s with %s" % [punch, animations.current_animation])
		fixture.root.free()
		return false
	animations.advance(1.0)
	var ok := animations.current_animation == "Idle"
	if not ok:
		printerr("idle did not resume after %s: %s" % [punch, animations.current_animation])
	fixture.root.free()
	return ok


static func _missing_punch_falls_back_to_idle() -> bool:
	var fixture := _new_fixture(["Punch_Cross"])
	var animations: AnimationPlayer = fixture.animations
	var controller: PlayerAnimationController = fixture.controller
	controller.movement_started(1)
	controller.set_action(2)
	var ok := animations.current_animation == "Idle"
	if not ok:
		printerr("missing punch fallback=%s" % animations.current_animation)
	fixture.root.free()
	return ok


static func _missing_death_keeps_current_pose() -> bool:
	var fixture := _new_fixture(["Death01"])
	var animations: AnimationPlayer = fixture.animations
	var controller: PlayerAnimationController = fixture.controller
	controller.movement_started(1)
	animations.advance(0.2)
	var pose_before: Vector2 = fixture.pose_target.position
	controller.set_action(4)
	var ok: bool = animations.assigned_animation == "Walk" and not animations.is_playing() \
		and fixture.pose_target.position.is_equal_approx(pose_before)
	if not ok:
		printerr("missing death fallback assigned=%s playing=%s pose=%s before=%s" % [
			animations.assigned_animation,
			animations.is_playing(),
			fixture.pose_target.position,
			pose_before,
		])
	fixture.root.free()
	return ok


static func _new_fixture(omitted: Array[String] = []) -> Dictionary:
	var root := Node.new()
	var pose_target := Node2D.new()
	pose_target.name = "PoseTarget"
	root.add_child(pose_target)
	var animations := AnimationPlayer.new()
	var library := AnimationLibrary.new()
	for animation_name in ["Idle", "Walk", "Jog_Fwd", "Sword_Attack", "Punch_Cross", "Punch_Jab", "Death01"]:
		if animation_name in omitted:
			continue
		var animation := Animation.new()
		animation.length = 0.5
		if animation_name == "Walk":
			animation.loop_mode = Animation.LOOP_LINEAR
			var pose_track := animation.add_track(Animation.TYPE_VALUE)
			animation.track_set_path(pose_track, NodePath("PoseTarget:position"))
			animation.track_insert_key(pose_track, 0.0, Vector2.ZERO)
			animation.track_insert_key(pose_track, 0.5, Vector2(10.0, 0.0))
		library.add_animation(animation_name, animation)
	animations.add_animation_library("", library)
	root.add_child(animations)
	Engine.get_main_loop().root.add_child(root)
	return {
		"root": root,
		"pose_target": pose_target,
		"animations": animations,
		"controller": PlayerAnimationController.new(animations),
	}
