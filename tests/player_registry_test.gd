extends RefCounted

const ContentLoader = preload("res://content/content_loader.gd")
const PlayerRegistry = preload("res://world/player_registry.gd")
const Protocol = preload("res://network/protocol.gd")

static func run() -> bool:
	var bundle = ContentLoader.load_bundle(OS.get_environment("GAME_CONTENT_ROOT"))
	var registry := PlayerRegistry.new()
	Engine.get_main_loop().root.add_child(registry)
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
		or npc.get_meta("npc_level", 0) != 2 or npc.get_meta("npc_actions", []) != ["Talk-to", "Attack", "Inspect"] \
		or not npc.is_in_group("Interactable") \
		or not is_equal_approx(npc.position.x, 85.5) or not is_equal_approx(npc.position.z, 85.5):
		registry.free()
		return false
	if registry.npc_context_actions(npc_entity) != ["Talk-to", "Attack", "Inspect"] or registry.display_name_for(npc_entity) != "Man":
		registry.free()
		return false
	registry.handle_message(Protocol.ENTITY_HEALTH, {"entity": 42, "hp": 7, "maximum": 10})
	registry.handle_message(Protocol.ENTITY_HEALTH, {"entity": npc_entity, "hp": 3, "maximum": 8})
	if not player.health_bar.visible or not is_equal_approx(player.health_bar.health_ratio(), 0.7) \
		or not npc.health_bar.visible or not is_equal_approx(npc.health_bar.health_ratio(), 0.375):
		registry.free()
		return false
	registry.handle_message(Protocol.ENTITY_HEALTH, {"entity": 42, "hp": 10, "maximum": 10})
	if player.health_bar.visible:
		registry.free()
		return false
	var npc_ratio: float = npc.health_bar.health_ratio()
	registry.handle_message(Protocol.ENTITY_HEALTH, {"entity": 999, "hp": 1, "maximum": 10})
	if player.health_bar.visible or not is_equal_approx(npc.health_bar.health_ratio(), npc_ratio):
		registry.free()
		return false
	var npc_animations: AnimationPlayer = npc.get_node("AnimationPlayer")
	registry.handle_message(Protocol.PLAYER_ACTION, {"entity": npc_entity, "action": 2})
	if npc_animations.current_animation != "Punch_Cross":
		registry.free()
		return false
	npc_animations.advance(0.25)
	registry.handle_message(Protocol.PLAYER_ACTION, {"entity": npc_entity, "action": 2})
	if npc_animations.current_animation != "Punch_Cross" or npc_animations.current_animation_position > 0.01:
		registry.free()
		return false
	npc_animations.advance(1.1)
	if npc_animations.current_animation != "Idle":
		registry.free()
		return false
	registry.handle_message(Protocol.PLAYER_ACTION, {"entity": npc_entity, "action": 3})
	if npc_animations.current_animation != "Punch_Jab":
		registry.free()
		return false
	npc_animations.advance(0.25)
	registry.handle_message(Protocol.PLAYER_ACTION, {"entity": npc_entity, "action": 3})
	if npc_animations.current_animation != "Punch_Jab" or npc_animations.current_animation_position > 0.01:
		registry.free()
		return false
	npc_animations.advance(1.0)
	if npc_animations.current_animation != "Idle":
		registry.free()
		return false
	registry.handle_message(Protocol.PLAYER_ACTION, {"entity": npc_entity, "action": 4})
	registry.handle_message(Protocol.PLAYER_ACTION, {"entity": npc_entity, "action": 2})
	if npc_animations.current_animation != "Death01":
		registry.free()
		return false
	npc_animations.advance(2.5)
	if npc_animations.assigned_animation != "Death01" or npc_animations.is_playing():
		registry.free()
		return false
	registry.handle_message(Protocol.PLAYER_ACTION, {"entity": npc_entity, "action": 0})
	if npc_animations.current_animation != "Idle":
		registry.free()
		return false
	var rotation_before: float = player.rotation.y
	registry.face_entity(42, npc_entity)
	if is_equal_approx(player.rotation.y, rotation_before):
		registry.free()
		return false
	registry.face_entity(42, 0x8000ffff)
	registry.handle_message(Protocol.ENTITY_MOVE, {"entity": npc_entity, "x": 86, "z": 85, "plane": 0})
	npc.advance_interpolation(0.6)
	if not is_equal_approx(npc.position.x, 86.5):
		registry.free()
		return false
	registry.handle_message(Protocol.ENTITY_DESPAWN, {"entity": npc_entity})
	var ok: bool = registry.players.size() == 1 and not registry.npcs.has(npc_entity)
	registry.free()
	return ok
