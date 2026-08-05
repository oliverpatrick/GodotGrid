class_name RegionMeshBuilder
extends RefCounted

const REGION_SIZE := 64
const HEIGHT_SCALE := 0.18

static func build(region: Dictionary) -> MeshInstance3D:
	if region.get("plane", -1) != 0 or region.get("heights", []).size() != 65:
		return null
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var heights: Array = region.heights
	for z in range(65):
		for x in range(65):
			var height := float(heights[z][x]) * HEIGHT_SCALE
			vertices.append(Vector3(x, height, z))
			var left := float(heights[z][maxi(0, x - 1)]) * HEIGHT_SCALE
			var right := float(heights[z][mini(64, x + 1)]) * HEIGHT_SCALE
			var back := float(heights[maxi(0, z - 1)][x]) * HEIGHT_SCALE
			var front := float(heights[mini(64, z + 1)][x]) * HEIGHT_SCALE
			normals.append(Vector3(left - right, 2.0, back - front).normalized())
			uvs.append(Vector2((region.x * 64 + x) / 16.0, (region.z * 64 + z) / 16.0))
			var blend := clampf((height + 3.0) / 6.0, 0.0, 1.0)
			colors.append(Color(0.12, 0.2, 0.11).lerp(Color(0.35, 0.28, 0.18), blend))
	for z in range(REGION_SIZE):
		for x in range(REGION_SIZE):
			var southwest := z * 65 + x
			var southeast := southwest + 1
			var northwest := (z + 1) * 65 + x
			var northeast := northwest + 1
			indices.append_array([southwest, southeast, northeast, southwest, northeast, northwest])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.name = "Region_%d_%d_%d" % [region.x, region.z, region.plane]
	instance.position = Vector3(region.x * 64, 0, region.z * 64)
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.92
	instance.material_override = material
	var static_body := StaticBody3D.new()
	static_body.name = "TerrainCollision"
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	static_body.add_child(collision)
	instance.add_child(static_body)
	return instance
