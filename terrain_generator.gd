class_name TerrainGenerator
extends Node3D

const ContentLoader = preload("res://content/content_loader.gd")
const WorldStream = preload("res://world/world_stream.gd")

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
		push_error("Unable to load game content: %s" % ContentLoader.last_error)

func load_world(root: String, load_all_regions: bool = true) -> bool:
	content_bundle = ContentLoader.load_bundle(root)
	if content_bundle == null:
		return false
	if stream != null:
		stream.free()
	stream = WorldStream.new()
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
