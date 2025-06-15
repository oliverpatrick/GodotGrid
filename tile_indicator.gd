class_name TileIndicator
extends Node3D

@onready var mesh_instance: MeshInstance3D = $IndicatorMesh

func set_tile_shape(corners: Array):
	# Calculate local vertices by subtracting the center (indicator origin)
	var center = Vector3.ZERO  # This node's origin is local 0,0,0
	var local_vertices = PackedVector3Array()
	for corner in corners:
		local_vertices.append(corner - global_position)  # make vertices relative to indicator's position
	
	var indices = PackedInt32Array([0, 1, 2, 0, 2, 3])
	
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = local_vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 0, 0.4)  
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	mat.vertex_color_use_as_albedo = false

	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
