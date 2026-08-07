class_name PlayerRegistry
extends Node3D

const Protocol = preload("uid://bvppiqbq80y0l") # network/protocol.gd
const PLAYER_SCENE = preload("uid://tvjj76iceovt") # assets/player/player.tscn
const NPC_HUMAN_MAN_SCENE = preload("uid://dmfqsfcnawdue") # assets/mobs/human/human_man.tscn

signal local_player_ready(player: Node3D)

var players: Dictionary = {}
var npcs: Dictionary = {}
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
			elif message.type == 1:
				_spawn_npc(message)
		Protocol.ENTITY_MOVE:
			var character = _character_for(message.entity)
			if character != null:
				character.confirm_tile(message.x, message.z, message.plane, tick_seconds)
		Protocol.ENTITY_HEALTH:
			var character = _character_for(message.entity)
			if character != null:
				character.set_health(message.hp, message.maximum)
		Protocol.ENTITY_DESPAWN:
			var character = _character_for(message.entity)
			if character != null:
				character.queue_free()
				players.erase(message.entity)
				npcs.erase(message.entity)
		Protocol.PLAYER_ACTION:
			apply_action(message.entity, message.action)
		Protocol.ENTITY_FACE:
			face_entity(message.entity, message.target)

func _spawn_player(message: Dictionary) -> void:
	var index: int = message.entity
	if players.has(index):
		players[index].snap_to_tile(message.x, message.z, message.plane)
		return
	var player: Node3D = PLAYER_SCENE.instantiate()
	player.name = "Player_%d" % index
	player.configure(index, message.name, bundle)
	player.snap_to_tile(message.x, message.z, message.plane)
	add_child(player)
	players[index] = player
	if index == local_index:
		local_player_ready.emit(player)

func _spawn_npc(message: Dictionary) -> void:
	var entity: int = message.entity
	if npcs.has(entity):
		npcs[entity].snap_to_tile(message.x, message.z, message.plane)
		return
	var definition = bundle.npc_by_id(str(message.get("definition_id", "")))
	if definition == null or str(definition.get("presentation", {}).get("model_id", "")) != "model.player":
		push_error("Unknown or unsupported NPC definition: %s" % message.get("definition_id", ""))
		return
	var npc: Node3D = NPC_HUMAN_MAN_SCENE.instantiate()
	npc.name = "NPC_%d" % entity
	npc.configure(entity, str(definition.get("name", "")), bundle)
	npc.set_meta("entity_id", entity)
	npc.set_meta("definition_id", str(definition.id))
	npc.set_meta("context_kind", "npc")
	npc.set_meta("npc_level", int(definition.get("combat", {}).get("level", 0)))
	npc.set_meta("npc_actions", definition.get("actions", []).duplicate())
	if not npc.is_in_group("Interactable"):
		npc.add_to_group("Interactable")
	npc.snap_to_tile(message.x, message.z, message.plane)
	add_child(npc)
	npcs[entity] = npc

func apply_action(entity: int, action: int) -> void:
	var character = _character_for(entity)
	if character != null:
		character.set_action(action)

func _character_for(entity: int):
	return players.get(entity, npcs.get(entity))

func is_npc(entity: int) -> bool:
	return npcs.has(entity)

func npc_context_actions(entity: int) -> Array:
	var npc = npcs.get(entity)
	return npc.get_meta("npc_actions", []).duplicate() if npc != null else []

func npc_definition(entity: int):
	var npc = npcs.get(entity)
	return bundle.npc_by_id(str(npc.get_meta("definition_id", ""))) if npc != null and bundle != null else null

func display_name_for(entity: int) -> String:
	var character = _character_for(entity)
	return str(character.display_name) if character != null else "Unknown"

func face_entity(entity: int, target: int) -> void:
	var character = _character_for(entity)
	var target_character = _character_for(target)
	if character == null or target_character == null:
		return
	character.face_towards(target_character.position)
