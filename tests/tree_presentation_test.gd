extends RefCounted

const ContentLoader = preload("res://content/content_loader.gd")
const ObjectRegistry = preload("res://world/object_registry.gd")
const Protocol = preload("res://network/protocol.gd")
const TreeScene = preload("res://assets/world/mutated_tree.tscn")

static func run() -> bool:
	var bundle = ContentLoader.load_bundle(OS.get_environment("GAME_CONTENT_ROOT"))
	var registry := ObjectRegistry.new()
	registry.configure(bundle)
	registry.handle_message(Protocol.ENTITY_SPAWN, {"entity": 42, "type": 3, "x": 84, "z": 80, "plane": 0, "name": "object.1", "definition_id": "resource.mutated_tree"})
	if not registry.objects.has(42):
		registry.free()
		return false
	var tree: Node3D = registry.objects[42]
	if tree.scene_file_path != TreeScene.resource_path or tree.get_meta("entity_id", -1) != 42 or not tree.is_in_group("Interactable"):
		registry.free()
		return false
	var collision: CollisionShape3D = tree.get_node("CollisionShape3D")
	registry.handle_message(Protocol.RESOURCE_STATE, {"entity": 42, "state": 2, "remaining": 0})
	var stump := tree.get_node_or_null("Stump") as MeshInstance3D
	if stump == null or not stump.visible or not collision.disabled:
		registry.free()
		return false
	var stump_mesh := stump.mesh as CylinderMesh
	if stump_mesh == null or not is_equal_approx(stump_mesh.height, 0.5) or not is_equal_approx(stump.position.y, 0.25):
		registry.free()
		return false
	registry.handle_message(Protocol.RESOURCE_STATE, {"entity": 42, "state": 0, "remaining": 0})
	var ok := not stump.visible and not collision.disabled and tree.is_in_group("Interactable")
	registry.free()
	return ok
