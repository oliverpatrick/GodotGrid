extends RefCounted

const RemotePlayer = preload("res://world/remote_player.gd")
const ClickToMove = preload("res://world/click_to_move.gd")
const ObjectRegistry = preload("res://world/object_registry.gd")

static func run() -> bool:
	var player: Node3D = RemotePlayer.new()
	player.snap_to_tile(10, 10, 0)
	player.confirm_tile(11, 10, 0, 0.6)
	player.advance_interpolation(0.3)
	if not is_equal_approx(player.position.x, 11.0) or not is_equal_approx(player.position.z, 10.5):
		player.free()
		return false
	player.free()
	var loaded := {"1:1:0": true}
	var tile = ClickToMove.world_to_visible_tile(Vector3(80.9, 0, 81.2), loaded)
	if tile == null or tile.x != 80 or tile.z != 81:
		return false
	if ClickToMove.world_to_visible_tile(Vector3(-1, 0, 20), loaded) != null or ClickToMove.world_to_visible_tile(Vector3(200, 0, 200), loaded) != null:
		return false
	var controller: Node = ClickToMove.new()
	var messages: Array[String] = []
	controller.system_message.connect(func(text: String): messages.append(text))
	controller.reject_unreachable()
	if messages != ["I can't reach that"]:
		controller.free()
		return false
	if controller.is_run_enabled():
		printerr("run toggle starts enabled")
		controller.free()
		return false
	if controller.effective_movement_mode(false) != 0:
		printerr("disabled toggle does not walk without Ctrl")
		controller.free()
		return false
	if controller.effective_movement_mode(true) != 1:
		printerr("Ctrl does not temporarily run")
		controller.free()
		return false
	controller.set_run_enabled(true)
	if not controller.is_run_enabled() or controller.effective_movement_mode(false) != 1:
		printerr("persistent toggle does not run")
		controller.free()
		return false
	controller.set_run_enabled(false)
	if controller.effective_movement_mode(false) != 0:
		printerr("turning run off does not restore walking")
		controller.free()
		return false
	controller.free()
	var registry := ObjectRegistry.new()
	var sentinel := Node3D.new()
	registry.objects[42] = sentinel
	var lookup_ok: bool = registry.object_for(42) == sentinel and registry.object_for(99) == null
	sentinel.free()
	registry.free()
	return lookup_ok
