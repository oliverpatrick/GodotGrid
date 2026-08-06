extends RefCounted

const ContentLoader = preload("res://content/content_loader.gd")
const PlayerScene = preload("res://assets/player/player.tscn")

static func run() -> bool:
	var bundle = ContentLoader.load_bundle(OS.get_environment("GAME_CONTENT_ROOT"))
	var player = PlayerScene.instantiate()
	var animations: AnimationPlayer = player.get_node("AnimationPlayer")
	for animation in [&"Idle", &"Walk", &"Jog_Fwd", &"Sword_Attack"]:
		if not animations.has_animation(animation):
			printerr("missing animation: %s; available=%s" % [animation, animations.get_animation_list()])
			player.free()
			return false
	player.configure(1, "Test", bundle)
	player.snap_to_tile(10, 10, 0)
	if animations.current_animation != "Idle":
		printerr("initial animation=%s" % animations.current_animation)
		player.free()
		return false
	player.confirm_tile(11, 10, 0, 0.6)
	if animations.current_animation != "Walk":
		printerr("walk animation=%s" % animations.current_animation)
		player.free()
		return false
	player.advance_interpolation(0.6)
	player.snap_to_tile(10, 10, 0)
	player.confirm_tile(12, 10, 0, 0.6)
	if animations.current_animation != "Jog_Fwd":
		printerr("jog animation=%s" % animations.current_animation)
		player.free()
		return false
	player.advance_interpolation(0.6)
	player.set_action(1)
	if animations.current_animation != "Sword_Attack":
		printerr("harvest animation=%s" % animations.current_animation)
		player.free()
		return false
	player.confirm_tile(11, 10, 0, 0.6)
	if animations.current_animation != "Walk":
		printerr("harvest movement animation=%s" % animations.current_animation)
		player.free()
		return false
	player.advance_interpolation(0.6)
	if animations.current_animation != "Sword_Attack":
		printerr("resumed animation=%s" % animations.current_animation)
		player.free()
		return false
	player.set_action(0)
	var ok := animations.current_animation == "Idle"
	player.free()
	return ok
