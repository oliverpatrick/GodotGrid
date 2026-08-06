extends RefCounted

const NetworkClient = preload("res://network/network_client.gd")
const ClickToMove = preload("res://world/click_to_move.gd")
const InteractionController = preload("res://gameplay/interaction_controller.gd")

static func _sequence(frame: PackedByteArray) -> int:
	var size := frame.size()
	return (frame[size - 4] << 24) | (frame[size - 3] << 16) | (frame[size - 2] << 8) | frame[size - 1]

static func run() -> bool:
	var network := NetworkClient.new()
	var movement := ClickToMove.new()
	var interaction := InteractionController.new()
	movement.configure(null, null, network)
	interaction.configure(network)
	var first_move: PackedByteArray = movement.build_move_request(Vector3i(80, 0, 80), 0)
	var second_move: PackedByteArray = movement.build_move_request(Vector3i(81, 0, 80), 0)
	var object_click: PackedByteArray = interaction.build_interaction_request(0x8000002a, 0)
	var drop: PackedByteArray = interaction.build_drop_request(3)
	var ok := [_sequence(first_move), _sequence(second_move), _sequence(object_click), _sequence(drop)] == [1, 2, 3, 4]
	movement.free()
	interaction.free()
	network.free()
	return ok
