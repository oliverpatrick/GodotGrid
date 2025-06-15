# # ShapedTile.gd - Complex shaped tile with triangular mesh
# class_name ShapedTile
# extends RefCounted

# var vertex_x: Array[int] = []
# var vertex_y: Array[int] = []
# var vertex_z: Array[int] = []
# var triangle_hsla: Array[int] = []
# var triangle_hslb: Array[int] = []
# var triangle_hslc: Array[int] = []
# var triangle_a: Array[int] = []
# var triangle_b: Array[int] = []
# var triangle_c: Array[int] = []
# var triangle_texture: Array[int] = []
# var flat: bool
# var shape: int
# var rotation: int
# var underlay_rgb: int
# var overlay_rgb: int

# # Static arrays for screen/viewspace coordinates
# static var screen_x: Array[int] = []
# static var screen_y: Array[int] = []
# static var viewspace_x: Array[int] = []
# static var viewspace_y: Array[int] = []
# static var viewspace_z: Array[int] = []

# # Shape data - defines which vertices to use for each shape
# static var shaped_tile_point_data: Array[Array] = [
# 	[1, 3, 5, 7], [1, 3, 5, 7], [1, 3, 5, 7],
# 	[1, 3, 5, 7, 6], [1, 3, 5, 7, 6], [1, 3, 5, 7, 6], [1, 3, 5, 7, 6], [1, 3, 5, 7, 2, 6],
# 	[1, 3, 5, 7, 2, 8], [1, 3, 5, 7, 2, 8], [1, 3, 5, 7, 11, 12], [1, 3, 5, 7, 11, 12],
# 	[1, 3, 5, 7, 13, 14]
# ]

# # Triangle data - defines how vertices connect to form triangles
# static var shaped_tile_element_data: Array[Array] = [
# 	[0, 1, 2, 3, 0, 0, 1, 3], [1, 1, 2, 3, 1, 0, 1, 3],
# 	[0, 1, 2, 3, 1, 0, 1, 3], [0, 0, 1, 2, 0, 0, 2, 4, 1, 0, 4, 3], [0, 0, 1, 4, 0, 0, 4, 3, 1, 1, 2, 4],
# 	[0, 0, 4, 3, 1, 0, 1, 2, 1, 0, 2, 4], [0, 1, 2, 4, 1, 0, 1, 4, 1, 0, 4, 3],
# 	[0, 4, 1, 2, 0, 4, 2, 5, 1, 0, 4, 5, 1, 0, 5, 3], [0, 4, 1, 2, 0, 4, 2, 3, 0, 4, 3, 5, 1, 0, 4, 5],
# 	[0, 0, 4, 5, 1, 4, 1, 2, 1, 4, 2, 3, 1, 4, 3, 5],
# 	[0, 0, 1, 5, 0, 1, 4, 5, 0, 1, 2, 4, 1, 0, 5, 3, 1, 5, 4, 3, 1, 4, 2, 3],
# 	[1, 0, 1, 5, 1, 1, 4, 5, 1, 1, 2, 4, 0, 0, 5, 3, 0, 5, 4, 3, 0, 4, 2, 3],
# 	[1, 0, 5, 4, 1, 0, 1, 5, 0, 0, 4, 3, 0, 4, 5, 3, 0, 5, 2, 3, 0, 1, 2, 5]
# ]

# func _init(tile_x: int, height_sw: int, height_se: int, height_nw: int, height_ne: int, 
# 		  tile_z: int, p_rotation: int, texture: int, p_shape: int, 
# 		  overlay_sw: int, underlay_sw: int, overlay_se: int, underlay_se: int,
# 		  overlay_nw: int, underlay_nw: int, overlay_ne: int, underlay_ne: int,
# 		  p_overlay_rgb: int, p_underlay_rgb: int):
	
# 	# Check if tile is flat
# 	flat = (height_sw == height_se and height_sw == height_ne and height_sw == height_nw)
# 	shape = p_shape
# 	rotation = p_rotation
# 	underlay_rgb = p_underlay_rgb
# 	overlay_rgb = p_overlay_rgb
	
# 	const TILE_WIDTH = 128  # '\200' in char is 128
# 	const HALF_TILE = TILE_WIDTH / 2
# 	const QUARTER_TILE = TILE_WIDTH / 4
# 	const THREE_QUARTER_TILE = (TILE_WIDTH * 3) / 4
	
# 	var shaped_tile_mesh = shaped_tile_point_data[shape]
# 	var mesh_length = shaped_tile_mesh.size()
	
# 	# Initialize vertex arrays
# 	vertex_x.resize(mesh_length)
# 	vertex_y.resize(mesh_length)
# 	vertex_z.resize(mesh_length)
# 	var vertex_colour_overlay: Array[int] = []
# 	var vertex_colour_underlay: Array[int] = []
# 	vertex_colour_overlay.resize(mesh_length)
# 	vertex_colour_underlay.resize(mesh_length)
	
# 	var tile_pos_x = tile_x * TILE_WIDTH
# 	var tile_pos_y = tile_z * TILE_WIDTH
	
# 	# Generate vertices
# 	for vertex in range(mesh_length):
# 		var vertex_type = shaped_tile_mesh[vertex]
		
# 		# Apply rotation to vertex type
# 		if (vertex_type & 1) == 0 and vertex_type <= 8:
# 			vertex_type = (vertex_type - rotation - rotation - 1) & 7 + 1
# 		if vertex_type > 8 and vertex_type <= 12:
# 			vertex_type = (vertex_type - 9 - rotation) & 3 + 9
# 		if vertex_type > 12 and vertex_type <= 16:
# 			vertex_type = (vertex_type - 13 - rotation) & 3 + 13
		
# 		var v_x: int
# 		var v_z: int
# 		var v_y: int
# 		var v_c_overlay: int
# 		var v_c_underlay: int
		
# 		# Calculate vertex position and color based on vertex type
# 		match vertex_type:
# 			1: # SW corner
# 				v_x = tile_pos_x
# 				v_z = tile_pos_y
# 				v_y = height_sw
# 				v_c_overlay = overlay_sw
# 				v_c_underlay = underlay_sw
# 			2: # S edge middle
# 				v_x = tile_pos_x + HALF_TILE
# 				v_z = tile_pos_y
# 				v_y = (height_sw + height_se) >> 1
# 				v_c_overlay = (overlay_sw + overlay_se) >> 1
# 				v_c_underlay = (underlay_sw + underlay_se) >> 1
# 			3: # SE corner
# 				v_x = tile_pos_x + TILE_WIDTH
# 				v_z = tile_pos_y
# 				v_y = height_se
# 				v_c_overlay = overlay_se
# 				v_c_underlay = underlay_se
# 			4: # E edge middle
# 				v_x = tile_pos_x + TILE_WIDTH
# 				v_z = tile_pos_y + HALF_TILE
# 				v_y = (height_se + height_ne) >> 1
# 				v_c_overlay = (overlay_se + overlay_ne) >> 1
# 				v_c_underlay = (underlay_se + underlay_ne) >> 1
# 			5: # NE corner
# 				v_x = tile_pos_x + TILE_WIDTH
# 				v_z = tile_pos_y + TILE_WIDTH
# 				v_y = height_ne
# 				v_c_overlay = overlay_ne
# 				v_c_underlay = underlay_ne
# 			6: # N edge middle
# 				v_x = tile_pos_x + HALF_TILE
# 				v_z = tile_pos_y + TILE_WIDTH
# 				v_y = (height_ne + height_nw) >> 1
# 				v_c_overlay = (overlay_ne + overlay_nw) >> 1
# 				v_c_underlay = (underlay_ne + underlay_nw) >> 1
# 			7: # NW corner
# 				v_x = tile_pos_x
# 				v_z = tile_pos_y + TILE_WIDTH
# 				v_y = height_nw
# 				v_c_overlay = overlay_nw
# 				v_c_underlay = underlay_nw
# 			8: # W edge middle
# 				v_x = tile_pos_x
# 				v_z = tile_pos_y + HALF_TILE
# 				v_y = (height_nw + height_sw) >> 1
# 				v_c_overlay = (overlay_nw + overlay_sw) >> 1
# 				v_c_underlay = (underlay_nw + underlay_sw) >> 1
# 			_: # Additional vertex types for complex shapes
# 				v_x = tile_pos_x + HALF_TILE
# 				v_z = tile_pos_y + HALF_TILE
# 				v_y = (height_sw + height_se + height_ne + height_nw) >> 2
# 				v_c_overlay = (overlay_sw + overlay_se + overlay_ne + overlay_nw) >> 2
# 				v_c_underlay = (underlay_sw + underlay_se + underlay_ne + underlay_nw) >> 2
		
# 		vertex_x[vertex] = v_x
# 		vertex_y[vertex] = v_y
# 		vertex_z[vertex] = v_z
# 		vertex_colour_overlay[vertex] = v_c_overlay
# 		vertex_colour_underlay[vertex] = v_c_underlay
	
# 	# Generate triangles
# 	var shaped_tile_elements = shaped_tile_element_data[shape]
# 	var vertex_count = shaped_tile_elements.size() / 4
	
# 	triangle_a.resize(vertex_count)
# 	triangle_b.resize(vertex_count)
# 	triangle_c.resize(vertex_count)
# 	triangle_hsla.resize(vertex_count)
# 	triangle_hslb.resize(vertex_count)
# 	triangle_hslc.resize(vertex_count)
	
# 	if texture != -1:
# 		triangle_texture.resize(vertex_count)
	
# 	var offset = 0
# 	for i in range(vertex_count):
# 		var overlay_or_underlay = shaped_tile_elements[offset]
# 		var idx_a = shaped_tile_elements[offset + 1]
# 		var idx_b = shaped_tile_elements[offset + 2]
# 		var idx_c = shaped_tile_elements[offset + 3]
# 		offset += 4
		
# 		# Apply rotation to indices
# 		if idx_a < 4:
# 			idx_a = (idx_a - rotation) & 3
# 		if idx_b < 4:
# 			idx_b = (idx_b - rotation) & 3
# 		if idx_c < 4:
# 			idx_c = (idx_c - rotation) & 3
		
# 		triangle_a[i] = idx_a
# 		triangle_b[i] = idx_b
# 		triangle_c[i] = idx_c
		
# 		if overlay_or_underlay == 0:
# 			# Use overlay colors
# 			triangle_hsla[i] = vertex_colour_overlay[idx_a]
# 			triangle_hslb[i] = vertex_colour_overlay[idx_b]
# 			triangle_hslc[i] = vertex_colour_overlay[idx_c]
# 			if triangle_texture.size() > 0:
# 				triangle_texture[i] = -1
# 		else:
# 			# Use underlay colors
# 			triangle_hsla[i] = vertex_colour_underlay[idx_a]
# 			triangle_hslb[i] = vertex_colour_underlay[idx_b]
# 			triangle_hslc[i] = vertex_colour_underlay[idx_c]
# 			if triangle_texture.size() > 0:
# 				triangle_texture[i] = texture

# # Convert to Godot mesh
# func create_mesh() -> ArrayMesh:
# 	var array_mesh = ArrayMesh.new()
# 	var arrays = []
# 	arrays.resize(Mesh.ARRAY_MAX)
	
# 	var vertices: PackedVector3Array = []
# 	var uvs: PackedVector2Array = []
# 	var colors: PackedColorArray = []
# 	var indices: PackedInt32Array = []
	
# 	# Convert vertices to Godot format
# 	for i in range(vertex_x.size()):
# 		vertices.append(Vector3(vertex_x[i], vertex_y[i], vertex_z[i]))
# 		# Simple UV mapping
# 		uvs.append(Vector2(float(vertex_x[i] % 128) / 128.0, float(vertex_z[i] % 128) / 128.0))
# 		# Convert HSL color to RGB (simplified)
# 		var color = Color.WHITE  # You'd implement HSL to RGB conversion here
# 		colors.append(color)
	
# 	# Convert triangles to indices
# 	for i in range(triangle_a.size()):
# 		indices.append(triangle_a[i])
# 		indices.append(triangle_b[i])
# 		indices.append(triangle_c[i])
	
# 	arrays[Mesh.ARRAY_VERTEX] = vertices
# 	arrays[Mesh.ARRAY_TEX_UV] = uvs
# 	arrays[Mesh.ARRAY_COLOR] = colors
# 	arrays[Mesh.ARRAY_INDEX] = indices
	
# 	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
# 	return array_mesh
