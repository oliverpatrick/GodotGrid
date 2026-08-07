class_name PlayerRegistry
extends Node3D

const Protocol = preload("res://network/protocol.gd")
const RemotePlayerScript = preload("res://world/remote_player.gd")

signal local_player_ready(player: Node3D)

var players: Dictionary = {}
var local_index := -1
var bundle
var tick_seconds := 0.6

func configure(content_bundle, index: int, tick: float = 0.6) -> void:
	bundle = content_bundle
	local_index = index
	tick_seconds = tick

func handle_message(id: int, message) -> void:
	if message == null:
		return
	match id:
		Protocol.ENTITY_SPAWN:
			if message.type == 0:
				_spawn_player(message)
		Protocol.ENTITY_MOVE:
			if players.has(message.entity):
				players[message.entity].confirm_tile(message.x, message.z, message.plane, tick_seconds)
		Protocol.ENTITY_DESPAWN:
			if players.has(message.entity):
				players[message.entity].queue_free()
				players.erase(message.entity)

func _spawn_player(message: Dictionary) -> void:
	var index: int = message.entity
	if players.has(index):
		players[index].snap_to_tile(message.x, message.z, message.plane)
		return
	var player: Node3D = RemotePlayerScript.new()
	player.name = "Player_%d" % index
	player.configure(index, message.name, bundle)
	player.snap_to_tile(message.x, message.z, message.plane)
	add_child(player)
	players[index] = player
	if index == local_index:
		local_player_ready.emit(player)
