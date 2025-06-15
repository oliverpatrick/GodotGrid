# terrain_generator.gd - Attach to TerrainGenerator (Node3D)
class_name TerrainGenerator
extends Node3D

@export var terrain_width: int = 32  # Smaller for testing
@export var terrain_height: int = 32
@export var tile_size: float = 2.0
@export var height_variation: float = 2.0
@export var noise_scale: float = 0.15
@export var debug_mode: bool = true

@export var tree_scene: PackedScene
@export var tree_density: float = 0.05  # ~5% of tiles get a tree
var pathfinder: Pathfinder

var noise: FastNoiseLite
var mesh_instances: Array = []
var tile_map: Dictionary = {}
var tile_data: Array = []

const Tile = preload("res://tile.gd")

func _ready():
	debug_print("=== TERRAIN GENERATOR STARTING ===")
	generate_terrain()

func _input(event):
	if event.is_action_pressed("ui_accept"): # Space
		debug_print("=== REGENERATING TERRAIN ===")
		regenerate_terrain()

func generate_terrain():
	debug_print("Generating terrain...")
	
	tile_data = []
	for x in range(terrain_width):
		var row: Array = []
		for y in range(terrain_height):
			row.append(null) # or dummy data for now
		tile_data.append(row)
	
	clear_existing_meshes()
	setup_noise()
	create_terrain_tiles()
	
	debug_print("Terrain generation complete!")
	debug_print("Generated %d mesh instances" % mesh_instances.size())

func setup_noise():
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_scale
	
	debug_print("Noise setup complete, seed: %d" % noise.seed)

func clear_existing_meshes():
	for instance in mesh_instances:
		if is_instance_valid(instance):
			instance.queue_free()
	mesh_instances.clear()

func create_terrain_tiles():
	var tiles_created = 0
	var tiles_failed = 0
	
	for y in range(terrain_height):
		for x in range(terrain_width):
			if create_single_tile(x, y):
				tiles_created += 1

				if tile_data[x][y].walkable and randf() < tree_density:
					spawn_tree_on_tile(tile_data[x][y])
			else:
				tiles_failed += 1
	
	debug_print("Successfully created %d tiles, failed %d" % [tiles_created, tiles_failed])


func create_single_tile(x: int, y: int) -> bool:
	# Get heights at the four corners
	var height_sw = get_height_at(x, y)
	var height_se = get_height_at(x + 1, y)
	var height_nw = get_height_at(x, y + 1)
	var height_ne = get_height_at(x + 1, y + 1)
	
	var avg_height = (height_sw + height_se + height_nw + height_ne) / 4.0
	var world_pos = Vector3((x + 0.5) * tile_size, avg_height, (y + 0.5) * tile_size)
	var tile = Tile.new()
	tile.height = avg_height
	tile.walkable = true  # Add logic here if needed
	tile.world_position = world_pos

	tile_data[x][y] = tile

	# Create world positions for the four corners
	var world_x = x * tile_size
	var world_z = y * tile_size
	
	var pos_sw = Vector3(world_x, height_sw, world_z)
	var pos_se = Vector3(world_x + tile_size, height_se, world_z)
	var pos_nw = Vector3(world_x, height_nw, world_z + tile_size)
	var pos_ne = Vector3(world_x + tile_size, height_ne, world_z + tile_size)
	tile.corners = [pos_sw, pos_se, pos_ne, pos_nw]
	
	# Create mesh arrays
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	
	# Add the four vertices
	vertices.append(pos_sw)  # 0
	vertices.append(pos_se)  # 1
	vertices.append(pos_ne)  # 2
	vertices.append(pos_nw)  # 3
	
	# Calculate proper normals for each vertex
	for i in range(4):
		var normal = calculate_vertex_normal(i, pos_sw, pos_se, pos_ne, pos_nw)
		normals.append(normal)
	
	# UV coordinates
	uvs.append(Vector2(0, 0))  # SW
	uvs.append(Vector2(1, 0))  # SE
	uvs.append(Vector2(1, 1))  # NE
	uvs.append(Vector2(0, 1))  # NW
	
	# Colors based on height
	for pos in [pos_sw, pos_se, pos_ne, pos_nw]:
		var height_factor = clamp((pos.y + height_variation) / (height_variation * 2), 0.0, 1.0)
		var color = Color.FOREST_GREEN.lerp(Color.SANDY_BROWN, height_factor)
		colors.append(color)
	
	# Create two triangles for the quad
	# Triangle 1: SW -> SE -> NE (0 -> 1 -> 2)
	indices.append(0)
	indices.append(1) 
	indices.append(2)
	
	# Triangle 2: SW -> NE -> NW (0 -> 2 -> 3)
	indices.append(0)
	indices.append(2)
	indices.append(3)
	
	# Create the actual mesh
	return create_mesh_instance(vertices, normals, uvs, colors, indices, x, y)

func calculate_vertex_normal(vertex_index: int, pos_sw: Vector3, pos_se: Vector3, pos_ne: Vector3, pos_nw: Vector3) -> Vector3:
	# Calculate normal based on adjacent faces
	var normal = Vector3.ZERO
	
	match vertex_index:
		0: # SW corner
			var edge1 = pos_se - pos_sw
			var edge2 = pos_nw - pos_sw
			normal = edge1.cross(edge2).normalized()
		1: # SE corner
			var edge1 = pos_ne - pos_se
			var edge2 = pos_sw - pos_se
			normal = edge1.cross(edge2).normalized()
		2: # NE corner
			var edge1 = pos_nw - pos_ne
			var edge2 = pos_se - pos_ne
			normal = edge1.cross(edge2).normalized()
		3: # NW corner
			var edge1 = pos_sw - pos_nw
			var edge2 = pos_ne - pos_nw
			normal = edge1.cross(edge2).normalized()
	
	# Fallback to up vector if calculation fails
	if normal.length() < 0.1:
		normal = Vector3.UP
	
	return normal

func create_mesh_instance(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, colors: PackedColorArray, indices: PackedInt32Array, x: int, y: int) -> bool:
	# Validate data
	if vertices.size() != 4:
		debug_print("ERROR: Invalid vertex count for tile (%d, %d): %d" % [x, y, vertices.size()])
		return false
	
	if indices.size() != 6:
		debug_print("ERROR: Invalid index count for tile (%d, %d): %d" % [x, y, indices.size()])
		return false
	
	# Check for valid indices
	for idx in indices:
		if idx < 0 or idx >= vertices.size():
			debug_print("ERROR: Invalid index %d for tile (%d, %d)" % [idx, x, y])
			return false
	
	# Create the mesh
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Add the surface to the mesh
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Create MeshInstance3D
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	mesh_instance.name = "Tile_%d_%d" % [x, y]
	
	# Create and apply material
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color.WHITE
	material.roughness = 0.7
	material.metallic = 0.1
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show both sides
	mesh_instance.material_override = material
	
	# Add to scene
	add_child(mesh_instance)
	mesh_instances.append(mesh_instance)
	
	return true

func get_height_at(x: int, y: int) -> float:
	if not noise:
		return 0.0
	return noise.get_noise_2d(x * 0.5, y * 0.5) * height_variation

func regenerate_terrain():
	await get_tree().process_frame
	generate_terrain()

func spawn_tree_on_tile(tile):
	if not tree_scene:
		debug_print("No tree_scene assigned!")
		return

	var tree_instance = tree_scene.instantiate()
	tree_instance.position = tile.world_position
	tree_instance.add_to_group("Interactable")
	add_child(tree_instance)

	# Optional: mark tile as blocked
	tile.walkable = false
	
# Debug functions
func debug_print(message: String):
	if debug_mode:
		print("[TerrainGen] " + message)

func print_debug_stats():
	print("\n=== TERRAIN DEBUG STATS ===")
	print("Terrain size: %dx%d tiles" % [terrain_width, terrain_height])
	print("Total expected tiles: %d" % (terrain_width * terrain_height))
	print("Generated mesh instances: %d" % mesh_instances.size())
	print("Tile size: %f" % tile_size)
	print("Height variation: %f" % height_variation)
	print("Noise scale: %f" % noise_scale)
	
	# Check mesh validity
	var valid_meshes = 0
	for instance in mesh_instances:
		if is_instance_valid(instance) and instance.mesh:
			valid_meshes += 1
	
	print("Valid mesh instances: %d" % valid_meshes)
	
	if valid_meshes > 0:
		print("SUCCESS: Terrain is generating properly!")
	else:
		print("ERROR: No valid meshes created!")
	
	print("Terrain center: (%.1f, 0, %.1f)" % [terrain_width * tile_size * 0.5, terrain_height * tile_size * 0.5])
	print("========================\n")
