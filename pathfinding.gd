# pathfinder.gd - Simple A* pathfinding for grid-based terrain
class_name Pathfinder
extends RefCounted

# Simple node class for A* algorithm
class PathNode:
	var grid_x: int
	var grid_y: int
	var g_cost: float = 0.0  # Distance from start
	var h_cost: float = 0.0  # Heuristic distance to goal
	var f_cost: float = 0.0  # Total cost (g + h)
	var parent: PathNode = null
	
	func _init(x: int, y: int):
		grid_x = x
		grid_y = y
	
	func calculate_f_cost():
		f_cost = g_cost + h_cost

# 8-directional movement (including diagonals)
const DIRECTIONS = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),  # North-west, North, North-east
	Vector2i(-1,  0),                  Vector2i(1,  0),  # West, East
	Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1)   # South-west, South, South-east
]

# Movement costs (diagonal movement costs more)
const MOVE_COST_STRAIGHT = 10
const MOVE_COST_DIAGONAL = 14

var terrain_generator: TerrainGenerator

func _init():
	pass

func setup(terrain_gen: TerrainGenerator):
	terrain_generator = terrain_gen

func find_path(start_world_pos: Vector3, end_world_pos: Vector3) -> Array:
	"""
	Find a path from start to end position using A* algorithm.
	Returns array of world positions representing the path.
	"""
	
	# Convert world positions to grid coordinates
	var start_grid = world_to_grid(start_world_pos)
	var end_grid = world_to_grid(end_world_pos)
	
	# Validate positions
	if not is_valid_grid_pos(start_grid) or not is_valid_grid_pos(end_grid):
		print("Invalid start or end position")
		return []
	
	if not is_tile_walkable(end_grid.x, end_grid.y):
		print("Destination tile is not walkable")
		return []
	
	# A* algorithm
	var open_list: Array[PathNode] = []
	var closed_list: Array[PathNode] = []
	var node_map: Dictionary = {}  # For quick lookup: "x,y" -> PathNode
	
	# Create start node
	var start_node = PathNode.new(start_grid.x, start_grid.y)
	start_node.g_cost = 0
	start_node.h_cost = calculate_heuristic(start_grid, end_grid)
	start_node.calculate_f_cost()
	
	open_list.append(start_node)
	node_map["%d,%d" % [start_grid.x, start_grid.y]] = start_node
	
	while open_list.size() > 0:
		# Find node with lowest f_cost
		var current_node = get_lowest_f_cost_node(open_list)
		
		# Remove from open list and add to closed list
		open_list.erase(current_node)
		closed_list.append(current_node)
		
		# Check if we reached the goal
		if current_node.grid_x == end_grid.x and current_node.grid_y == end_grid.y:
			return reconstruct_path(current_node)
		
		# Check all neighbors
		for direction in DIRECTIONS:
			var neighbor_x = current_node.grid_x + direction.x
			var neighbor_y = current_node.grid_y + direction.y
			var neighbor_key = "%d,%d" % [neighbor_x, neighbor_y]
			
			# Skip if out of bounds or not walkable
			if not is_valid_grid_pos(Vector2i(neighbor_x, neighbor_y)):
				continue
			if not is_tile_walkable(neighbor_x, neighbor_y):
				continue
			
			# Skip if already in closed list
			if is_in_closed_list(neighbor_x, neighbor_y, closed_list):
				continue
			
			# Calculate movement cost
			var movement_cost = MOVE_COST_DIAGONAL if is_diagonal_move(direction) else MOVE_COST_STRAIGHT
			var tentative_g_cost = current_node.g_cost + movement_cost
			
			# Get or create neighbor node
			var neighbor_node: PathNode
			if neighbor_key in node_map:
				neighbor_node = node_map[neighbor_key]
			else:
				neighbor_node = PathNode.new(neighbor_x, neighbor_y)
				neighbor_node.h_cost = calculate_heuristic(Vector2i(neighbor_x, neighbor_y), end_grid)
				node_map[neighbor_key] = neighbor_node
			
			# Check if this path is better
			var is_in_open = neighbor_node in open_list
			if not is_in_open or tentative_g_cost < neighbor_node.g_cost:
				neighbor_node.parent = current_node
				neighbor_node.g_cost = tentative_g_cost
				neighbor_node.calculate_f_cost()
				
				if not is_in_open:
					open_list.append(neighbor_node)
	
	# No path found
	print("No path found from ", start_world_pos, " to ", end_world_pos)
	return []

func world_to_grid(world_pos: Vector3) -> Vector2i:
	"""Convert world position to grid coordinates"""
	var grid_x = int(floor(world_pos.x / terrain_generator.tile_size))
	var grid_y = int(floor(world_pos.z / terrain_generator.tile_size))
	return Vector2i(grid_x, grid_y)

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	"""Convert grid coordinates to world position (center of tile)"""
	if not is_valid_grid_pos(grid_pos):
		return Vector3.ZERO
	
	var tile = terrain_generator.tile_data[grid_pos.x][grid_pos.y]
	return tile.world_position

func is_valid_grid_pos(grid_pos: Vector2i) -> bool:
	"""Check if grid position is within terrain bounds"""
	return (grid_pos.x >= 0 and grid_pos.x < terrain_generator.terrain_width and 
			grid_pos.y >= 0 and grid_pos.y < terrain_generator.terrain_height)

func is_tile_walkable(grid_x: int, grid_y: int) -> bool:
	"""Check if a tile is walkable"""
	if not is_valid_grid_pos(Vector2i(grid_x, grid_y)):
		return false
	
	var tile = terrain_generator.tile_data[grid_x][grid_y]
	return tile != null and tile.walkable

func calculate_heuristic(from: Vector2i, to: Vector2i) -> float:
	"""Calculate heuristic distance (Manhattan distance with diagonal consideration)"""
	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	
	# Use Chebyshev distance for 8-directional movement
	return max(dx, dy) * MOVE_COST_STRAIGHT

func is_diagonal_move(direction: Vector2i) -> bool:
	"""Check if the movement direction is diagonal"""
	return direction.x != 0 and direction.y != 0

func get_lowest_f_cost_node(open_list: Array[PathNode]) -> PathNode:
	"""Find the node with the lowest f_cost in the open list"""
	var lowest_node = open_list[0]
	for node in open_list:
		if node.f_cost < lowest_node.f_cost or (node.f_cost == lowest_node.f_cost and node.h_cost < lowest_node.h_cost):
			lowest_node = node
	return lowest_node

func is_in_closed_list(grid_x: int, grid_y: int, closed_list: Array[PathNode]) -> bool:
	"""Check if a position is in the closed list"""
	for node in closed_list:
		if node.grid_x == grid_x and node.grid_y == grid_y:
			return true
	return false

func reconstruct_path(end_node: PathNode) -> Array:
	"""Reconstruct the path from start to end by following parent nodes"""
	var path: Array = []
	var current_node = end_node
	
	while current_node != null:
		var world_pos = grid_to_world(Vector2i(current_node.grid_x, current_node.grid_y))
		path.push_front(world_pos)  # Add to front to reverse the path
		current_node = current_node.parent
	
	return path
	
func find_nearest_available_tile(target_world_pos: Vector3, seeker_world_pos: Vector3) -> Vector3:
	"""
	Given a target tile (e.g. an interactable), return the world position of the nearest
	adjacent walkable tile for the seeker to move to.
	"""
	var target_grid = world_to_grid(target_world_pos)
	var seeker_grid = world_to_grid(seeker_world_pos)

	var nearest_tile = null
	var shortest_distance := INF

	for direction in DIRECTIONS:
		var neighbor_grid = target_grid + direction
		
		if not is_valid_grid_pos(neighbor_grid):
			continue
		if not is_tile_walkable(neighbor_grid.x, neighbor_grid.y):
			continue

		# Optional: Avoid picking the same tile as the seeker
		if neighbor_grid == seeker_grid:
			continue

		# Check distance to seeker
		var dist = seeker_grid.distance_to(neighbor_grid)
		if dist < shortest_distance:
			shortest_distance = dist
			nearest_tile = neighbor_grid

	if nearest_tile != null:
		return grid_to_world(nearest_tile)
	
	# If no adjacent tile found
	print("No adjacent walkable tile found near ", target_grid)
	return target_world_pos  # Fallback


# Utility function for debugging
func print_path(path: Array):
	"""Print the path for debugging"""
	print("Path found with ", path.size(), " waypoints:")
	for i in range(path.size()):
		var world_pos = path[i]
		var grid_pos = world_to_grid(world_pos)
		print("  %d: Grid(%d,%d) -> World(%.1f, %.1f, %.1f)" % [i, grid_pos.x, grid_pos.y, world_pos.x, world_pos.y, world_pos.z])
