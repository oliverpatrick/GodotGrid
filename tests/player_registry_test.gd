extends RefCounted

const ContentLoader = preload("res://content/content_loader.gd")
const PlayerRegistry = preload("res://world/player_registry.gd")
const Protocol = preload("res://network/protocol.gd")

static func run() -> bool:
	var bundle = ContentLoader.load_bundle(OS.get_environment("GAME_CONTENT_ROOT"))
	var registry := PlayerRegistry.new()
	registry.configure(bundle, 42, 0.6)
	registry.handle_message(Protocol.ENTITY_SPAWN, {"entity": 42, "type": 0, "x": 80, "z": 80, "plane": 0, "name": "Test", "definition_id": ""})
	if not registry.players.has(42):
		registry.free()
		return false
	var player = registry.players[42]
	if player.scene_file_path != "res://assets/player/player.tscn":
		registry.free()
		return false
	registry.handle_message(Protocol.PLAYER_ACTION, {"entity": 42, "action": 1})
	var animations: AnimationPlayer = player.get_node("AnimationPlayer")
	if animations.current_animation != "Sword_Attack":
		registry.free()
		return false
	registry.handle_message(Protocol.PLAYER_ACTION, {"entity": 999, "action": 1})
	var npc_entity := 0x8000002a
	registry.handle_message(Protocol.ENTITY_SPAWN, {"entity": npc_entity, "type": 1, "x": 85, "z": 85, "plane": 0, "name": "Man", "definition_id": "npc.man"})
	if not registry.npcs.has(npc_entity):
		registry.free()
		return false
	var npc = registry.npcs[npc_entity]
	if npc.scene_file_path != "res://assets/mobs/human/human_man.tscn" or npc.display_name != "Man" \
		or npc.get_meta("entity_id", 0) != npc_entity or npc.get_meta("definition_id", "") != "npc.man" \
		or not is_equal_approx(npc.position.x, 85.5) or not is_equal_approx(npc.position.z, 85.5):
		registry.free()
		return false
	registry.handle_message(Protocol.ENTITY_MOVE, {"entity": npc_entity, "x": 86, "z": 85, "plane": 0})
	npc.advance_interpolation(0.6)
	if not is_equal_approx(npc.position.x, 86.5):
		registry.free()
		return false
	registry.handle_message(Protocol.ENTITY_DESPAWN, {"entity": npc_entity})
	var ok: bool = registry.players.size() == 1 and not registry.npcs.has(npc_entity)
	registry.free()
	return ok
