extends RefCounted

const RemotePlayer = preload("res://world/remote_player.gd")
const ClickToMove = preload("res://world/click_to_move.gd")

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
	controller.free()
	return messages == ["I can't reach that"]
