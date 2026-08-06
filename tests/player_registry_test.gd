extends RefCounted

const ContentLoader = preload("res://content/content_loader.gd")
const PlayerRegistry = preload("res://world/player_registry.gd")
const Protocol = preload("res://network/protocol.gd")

static func run() -> bool:
	var bundle = ContentLoader.load_bundle(OS.get_environment("GAME_CONTENT_ROOT"))
	var registry := PlayerRegistry.new()
	registry.configure(bundle, 42, 0.6)
	registry.handle_message(Protocol.ENTITY_SPAWN, {"entity": 42, "type": 0, "x": 80, "z": 80, "plane": 0, "name": "Test"})
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
	var ok := registry.players.size() == 1
	registry.free()
	return ok
