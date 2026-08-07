class_name InteractionController
extends Node

const Protocol = preload("uid://bvppiqbq80y0l") # network/protocol.gd
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

func inspect_world(entity: int) -> void:
	_send(build_inspect_world_request(entity))

func build_inspect_world_request(entity: int) -> PackedByteArray:
	return Protocol.encode_inspect_world(entity)

func inspect_inventory(slot: int) -> void:
	_send(build_inspect_inventory_request(slot))

func build_inspect_inventory_request(slot: int) -> PackedByteArray:
	return Protocol.encode_inspect_inventory(slot)

func use_inventory(source_slot: int, target_slot: int) -> void:
	_send(build_use_inventory_request(source_slot, target_slot))

func build_use_inventory_request(source_slot: int, target_slot: int) -> PackedByteArray:
	return Protocol.encode_use_inventory(source_slot, target_slot)

func use_world(source_slot: int, entity: int) -> void:
	_send(build_use_world_request(source_slot, entity))

func build_use_world_request(source_slot: int, entity: int) -> PackedByteArray:
	if network == null:
		return PackedByteArray()
	return Protocol.encode_use_world(source_slot, entity, network.next_world_sequence())

func send_nearby_chat(text: String) -> void:
	_send(Protocol.encode_chat(text.strip_edges()))

func set_combat_style(style: int) -> void:
	_send(build_combat_style_request(style))

func build_combat_style_request(style: int) -> PackedByteArray:
	return Protocol.encode_combat_style(style)

func _send(frame: PackedByteArray) -> void:
	if network != null and not frame.is_empty():
		network.send_frame(frame)
