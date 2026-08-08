class_name ObjectRegistry
extends Node3D

const Protocol = preload("uid://bvppiqbq80y0l") # network/protocol.gd
const TerrainHeightScript = preload("uid://ctl1kxhgld3tn") # world/terrain_height.gd
const TreeScene = preload("uid://b5sbv81foeoy2") # assets/world/mutated_tree.tscn
var objects: Dictionary = {}
var pending_quantities: Dictionary = {}
var bundle

func configure(content_bundle) -> void:
	bundle = content_bundle

func object_for(entity: int):
	return objects.get(entity)

func kind_for(entity: int) -> String:
	var object = object_for(entity)
	return str(object.get_meta("context_kind", "")) if object != null else ""

func handle_message(id: int, message) -> void:
	if message == null:
		return
	match id:
		Protocol.ENTITY_SPAWN:
			if message.type == 3:
				_spawn_object(message)
		Protocol.ENTITY_DESPAWN:
			pending_quantities.erase(message.entity)
			if objects.has(message.entity):
				objects[message.entity].queue_free()
				objects.erase(message.entity)
		Protocol.GROUND_ITEM:
			if objects.has(message.entity):
				objects[message.entity].set_meta("quantity", message.quantity)
			else:
				pending_quantities[message.entity] = message.quantity
		Protocol.RESOURCE_STATE:
			if objects.has(message.entity):
				_set_resource_state(objects[message.entity], message.state)

func _spawn_object(message: Dictionary) -> void:
	if objects.has(message.entity):
		return
	var definition_id := str(message.get("definition_id", ""))
	var is_tree := definition_id == "resource.mutated_tree"
	var body: StaticBody3D = TreeScene.instantiate() if is_tree else StaticBody3D.new()
	body.name = "Object_%d" % message.entity
	body.set_meta("entity_id", message.entity)
	body.set_meta("definition_id", definition_id)
	body.set_meta("context_kind", "resource" if is_tree else "ground_item")
	body.set_meta("tile_x", int(message.x))
	body.set_meta("tile_z", int(message.z))
	body.set_meta("plane", int(message.plane))
	if not is_tree:
		body.set_meta("quantity", pending_quantities.get(message.entity, 1))
		pending_quantities.erase(message.entity)
	if not body.is_in_group("Interactable"):
		body.add_to_group("Interactable")
	if is_tree:
		_add_stump(body)
		_place_object(body, message)
		return
	var mesh_instance := MeshInstance3D.new()
	var collision := CollisionShape3D.new()
	var material := StandardMaterial3D.new()
	material.roughness = 0.86
	if definition_id == "item.basic_axe":
		mesh_instance.mesh = BoxMesh.new()
		mesh_instance.scale = Vector3(0.18, 0.7, 0.12)
		mesh_instance.position.y = 0.35
		var axe_shape := BoxShape3D.new()
		axe_shape.size = Vector3(0.5, 0.8, 0.5)
		collision.shape = axe_shape
		collision.position.y = 0.4
		material.albedo_color = Color(0.55, 0.65, 0.58)
	else:
		mesh_instance.mesh = CylinderMesh.new()
		mesh_instance.scale = Vector3(0.45, 0.7, 0.45)
		mesh_instance.rotation.z = PI / 2.0
		mesh_instance.position.y = 0.25
		var item_shape := SphereShape3D.new()
		item_shape.radius = 0.45
		collision.shape = item_shape
		collision.position.y = 0.35
		material.albedo_color = Color(0.32, 0.21, 0.14)
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	body.add_child(collision)
	_place_object(body, message)

func _place_object(body: StaticBody3D, message: Dictionary) -> void:
	var centre_x: float = message.x + 0.5
	var centre_z: float = message.z + 0.5
	body.position = Vector3(centre_x, TerrainHeightScript.sample(bundle, centre_x, centre_z, message.plane), centre_z)
	add_child(body)
	objects[message.entity] = body

func ground_items_at(entity: int) -> Array:
	var target = objects.get(entity)
	if target == null or str(target.get_meta("context_kind", "")) != "ground_item":
		return []
	var stacks: Array = []
	for item_entity in objects:
		var object = objects[item_entity]
		if str(object.get_meta("context_kind", "")) != "ground_item":
			continue
		if object.get_meta("tile_x") != target.get_meta("tile_x") or object.get_meta("tile_z") != target.get_meta("tile_z") or object.get_meta("plane") != target.get_meta("plane"):
			continue
		var definition_id := str(object.get_meta("definition_id", ""))
		var definition = bundle.definition_by_id(definition_id) if bundle != null else null
		stacks.append({
			"entity": int(item_entity),
			"definition_id": definition_id,
			"name": str(definition.get("name", definition_id)) if definition != null else definition_id,
			"quantity": int(object.get_meta("quantity", 1)),
		})
	stacks.sort_custom(func(a: Dictionary, b: Dictionary): return a.entity < b.entity)
	return stacks

func _add_stump(tree: StaticBody3D) -> void:
	var stump := MeshInstance3D.new()
	stump.name = "Stump"
	var stump_mesh := CylinderMesh.new()
	stump_mesh.top_radius = 0.4
	stump_mesh.bottom_radius = 0.5
	stump_mesh.height = 0.5
	stump.mesh = stump_mesh
	stump.position.y = 0.25
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.28, 0.12, 0.035)
	material.roughness = 0.9
	stump.material_override = material
	stump.visible = false
	tree.add_child(stump)

func _set_resource_state(tree: StaticBody3D, state: int) -> void:
	var depleted := state == 2
	var stump := tree.get_node_or_null("Stump") as MeshInstance3D
	if stump != null:
		stump.visible = depleted
	for child in tree.find_children("*", "MeshInstance3D", true, false):
		if child != stump:
			child.visible = not depleted
	var collision := tree.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null:
		collision.disabled = depleted
	if depleted:
		tree.remove_from_group("Interactable")
	elif not tree.is_in_group("Interactable"):
		tree.add_to_group("Interactable")
