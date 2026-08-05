class_name InteractionController
extends Node

const Protocol = preload("res://network/protocol.gd")
var network
var sequence := 0

func configure(network_client) -> void:
	network = network_client

func interact(entity: int, action: int = 0) -> void:
	sequence += 1
	_send(Protocol.encode_interaction(entity, action, sequence))

func drop_slot(slot: int) -> void:
	_send(build_drop_request(slot))

func build_drop_request(slot: int) -> PackedByteArray:
	sequence += 1
	return Protocol.encode_drop(slot, 1, sequence)

func send_nearby_chat(text: String) -> void:
	_send(Protocol.encode_chat(text.strip_edges()))

func _send(frame: PackedByteArray) -> void:
	if network != null and not frame.is_empty():
		network.send_frame(frame)
