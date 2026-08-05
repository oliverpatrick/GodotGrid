class_name ObjectRegistry
extends Node3D

const Protocol = preload("res://network/protocol.gd")
const TerrainHeight = preload("res://world/terrain_height.gd")
var objects: Dictionary = {}
var bundle

func configure(content_bundle) -> void:
	bundle = content_bundle

func handle_message(id: int, message) -> void:
	if message == null:
		return
	match id:
		Protocol.ENTITY_SPAWN:
			if message.type == 3:
				_spawn_object(message)
		Protocol.ENTITY_DESPAWN:
			if objects.has(message.entity):
				objects[message.entity].queue_free()
				objects.erase(message.entity)
		Protocol.RESOURCE_STATE:
			if objects.has(message.entity):
				objects[message.entity].visible = message.state != 2

func _spawn_object(message: Dictionary) -> void:
	if objects.has(message.entity):
		return
	var body := StaticBody3D.new()
	body.name = "Object_%d" % message.entity
	body.set_meta("entity_id", message.entity)
	body.add_to_group("Interactable")
	var mesh_instance := MeshInstance3D.new()
	var collision := CollisionShape3D.new()
	var material := StandardMaterial3D.new()
	material.roughness = 0.86
	if str(message.name).begins_with("tree."):
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.35
		trunk.bottom_radius = 0.5
		trunk.height = 3.2
		mesh_instance.mesh = trunk
		mesh_instance.position.y = 1.6
		var shape := CapsuleShape3D.new()
		shape.radius = 0.55
		shape.height = 3.2
		collision.shape = shape
		collision.position.y = 1.6
		material.albedo_color = Color(0.19, 0.34, 0.16)
		material.emission_enabled = true
		material.emission = Color(0.08, 0.32, 0.11)
		material.emission_energy_multiplier = 0.8
		for offset in [Vector3(-0.65, 3.0, 0.0), Vector3(0.55, 3.25, 0.25), Vector3(0.0, 3.65, -0.35)]:
			var growth := MeshInstance3D.new()
			var growth_mesh := SphereMesh.new()
			growth_mesh.radius = 0.9
			growth_mesh.height = 1.8
			growth.mesh = growth_mesh
			growth.position = offset
			growth.material_override = material
			body.add_child(growth)
	elif "axe" in str(message.name):
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
	var centre_x: float = message.x + 0.5
	var centre_z: float = message.z + 0.5
	body.position = Vector3(centre_x, TerrainHeight.sample(bundle, centre_x, centre_z, message.plane), centre_z)
	add_child(body)
	objects[message.entity] = body
