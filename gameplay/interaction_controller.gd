class_name InteractionController
extends Node

const Protocol = preload("res://network/protocol.gd")
var network

func configure(network_client) -> void:
	network = network_client

func interact(entity: int, action: int = 0) -> void:
	_send(build_interaction_request(entity, action))

func build_interaction_request(entity: int, action: int = 0) -> PackedByteArray:
	if network == null:
		return PackedByteArray()
	return Protocol.encode_interaction(entity, action, network.next_world_sequence())

func drop_slot(slot: int) -> void:
	_send(build_drop_request(slot))

func build_drop_request(slot: int) -> PackedByteArray:
	if network == null:
		return PackedByteArray()
	return Protocol.encode_drop(slot, 1, network.next_world_sequence())

func send_nearby_chat(text: String) -> void:
	_send(Protocol.encode_chat(text.strip_edges()))

func _send(frame: PackedByteArray) -> void:
	if network != null and not frame.is_empty():
		network.send_frame(frame)
