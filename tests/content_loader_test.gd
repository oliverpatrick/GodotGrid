extends RefCounted

const ContentLoader = preload("res://content/content_loader.gd")

static func run() -> bool:
	var root := OS.get_environment("GAME_CONTENT_ROOT")
	if root.is_empty():
		printerr("GAME_CONTENT_ROOT is required")
		return false
	var bundle = ContentLoader.load_bundle(root)
	if bundle == null:
		printerr(ContentLoader.last_error)
		return false
	return bundle.regions.size() == 64 and bundle.gameplay_hash.length() == 64
