class_name SelectionFeedback
extends Node3D

const TerrainHeight = preload("res://world/terrain_height.gd")

var bundle
var marker: Node3D
var selection_kind := ""
var _pulse_time := 0.0

func configure(content_bundle) -> void:
	bundle = content_bundle

func clear_selection() -> void:
	if is_instance_valid(marker):
		marker.free()
	marker = null
	selection_kind = ""

func select_tile(tile: Vector3i) -> void:
	clear_selection()
	marker = _build_tile_marker()
	add_child(marker)
	var x := tile.x + 0.5
	var z := tile.z + 0.5
	marker.position = Vector3(x, TerrainHeight.sample(bundle, x, z, tile.y) + 0.035, z)
	selection_kind = "tile"

func select_object(object: Node3D) -> void:
	clear_selection()
	if not is_instance_valid(object):
		return
	marker = _build_object_ring()
	object.add_child(marker)
	marker.position = Vector3(0.0, 0.04, 0.0)
	selection_kind = "object"
	_pulse_time = 0.0

func _process(delta: float) -> void:
	if marker == null:
		return
	if not is_instance_valid(marker):
		marker = null
		selection_kind = ""
		return
	if selection_kind != "object":
		return
	_pulse_time += delta
	var pulse := 1.0 + sin(_pulse_time * 5.0) * 0.08
	marker.scale = Vector3(pulse, 1.0, pulse)

func _build_tile_marker() -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.9, 0.9)
	mesh_instance.mesh = plane
	mesh_instance.material_override = _marker_material(Color(0.1, 0.85, 1.0, 0.32), false)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh_instance

func _build_object_ring() -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.62
	ring.outer_radius = 0.78
	mesh_instance.mesh = ring
	mesh_instance.material_override = _marker_material(Color(1.0, 0.58, 0.08, 0.88), true)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh_instance

func _marker_material(color: Color, emissive: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	if emissive:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b)
		material.emission_energy_multiplier = 1.5
	return material
