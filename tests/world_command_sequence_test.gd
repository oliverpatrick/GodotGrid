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
	var inspect_world: PackedByteArray = interaction.build_inspect_world_request(0x8000002a)
	var inspect_inventory: PackedByteArray = interaction.build_inspect_inventory_request(3)
	var use_inventory: PackedByteArray = interaction.build_use_inventory_request(3, 4)
	var use_world: PackedByteArray = interaction.build_use_world_request(3, 0x8000002a)
	var ok := [_sequence(first_move), _sequence(second_move), _sequence(use_world)] == [1, 2, 3]
	ok = ok and inspect_world.hex_encode() == "001300048000002a"
	ok = ok and inspect_inventory.hex_encode() == "0014000103"
	ok = ok and use_inventory.hex_encode() == "001500020304"
	movement.free()
	interaction.free()
	network.free()
	return ok
