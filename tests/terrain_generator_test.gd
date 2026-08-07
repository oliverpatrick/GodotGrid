extends RefCounted

const TerrainGenerator = preload("res://terrain_generator.gd")

static func run() -> bool:
	var terrain := TerrainGenerator.new()
	var loaded: bool = terrain.load_world(OS.get_environment("GAME_CONTENT_ROOT"))
	var ok: bool = loaded and terrain.stream != null and terrain.stream.loaded.size() == 16
	terrain.free()
	return ok
