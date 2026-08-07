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
	var axe = bundle.item_by_wire_id(0)
	var log = bundle.item_by_wire_id(1)
	var tree = bundle.definition_by_id("resource.mutated_tree")
	return bundle.regions.size() == 64 and bundle.gameplay_hash.length() == 64 \
		and axe.perception_xp == 10 and not axe.droppable \
		and log.perception_xp == 10 and log.droppable \
		and tree.perception_xp == 10 and not str(tree.inspect_text).is_empty()
