class_name TerrainGenerator
extends Node3D

const ContentLoaderScript = preload("uid://1wwkkod0bsqn") # content/content_loader.gd
const WorldStreamScript = preload("uid://bmypmfoti27gk") # world/world_stream.gd

@export_dir var content_root := ""
var content_bundle
var stream: Node3D

func _ready() -> void:
	var root := content_root
	if root.is_empty():
		root = OS.get_environment("GAME_CONTENT_ROOT")
	if root.is_empty():
		push_error("GAME_CONTENT_ROOT or content_root is required")
		return
	if not load_world(root):
		push_error("Unable to load game content: %s" % ContentLoaderScript.last_error)

func load_world(root: String, load_all_regions: bool = true) -> bool:
	content_bundle = ContentLoaderScript.load_bundle(root)
	if content_bundle == null:
		return false
	if stream != null:
		stream.free()
	stream = WorldStreamScript.new()
	stream.name = "WorldStream"
	add_child(stream)
	stream.configure(content_bundle)
	if not load_all_regions:
		return true
	for z in range(4):
		for x in range(4):
			if not stream.load_region("%d:%d:0" % [x, z]):
				return false
	return true
