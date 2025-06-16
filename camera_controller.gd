# camera.gd - Improved version with better debugging
extends Camera3D

@export var distance: float = 20.0
@export var height: float = 10.0
@export var rotation_speed: float = 1.0
@export var zoom_speed: float = 10.0
@export var scroll_zoom_speed: float = 2.0
@export var min_distance: float = 5.0
@export var max_distance: float = 25.0
@export var follow_smoothness: float = 5.0

@onready var terrain = get_parent().get_parent()
@onready var player = get_parent()
@onready var tile_indicator_scene = preload("res://tile_indicator.tscn")

var tile_indicator: Node3D = null
var angle: float = 0.0
var current_position: Vector3

func _ready():
	current_position = global_position
	position_camera(true)

func _process(delta):
	if Input.is_action_pressed("ui_left"):
		angle -= rotation_speed * delta
	elif Input.is_action_pressed("ui_right"):
		angle += rotation_speed * delta

	if Input.is_action_pressed("ui_up"):
		distance = max(min_distance, distance - zoom_speed * delta)
	elif Input.is_action_pressed("ui_down"):
		distance = min(max_distance, distance + zoom_speed * delta)

	position_camera(false, delta)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = max(min_distance, distance - scroll_zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = min(max_distance, distance + scroll_zoom_speed)
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			handle_mouse_click(event.position)

func position_camera(force: bool = false, delta := 0.0):
	var offset = Vector3(
		cos(angle) * distance,
		height,
		sin(angle) * distance
	)
	var target_pos = player.global_position + offset

	if force:
		current_position = target_pos
	else:
		current_position = current_position.lerp(target_pos, delta * follow_smoothness)

	global_position = current_position
	look_at(player.global_position, Vector3.UP)

func handle_mouse_click(mouse_pos: Vector2):
	print("=== Mouse Click Debug ===")
	var from = project_ray_origin(mouse_pos)
	var to = from + project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	
	# First check for interactable objects (trees)
	if result and result.collider.is_in_group("Interactable"):
		print("Clicked on interactable at:", result.collider.global_position)
		print("Player position:", player.global_position)
		
		# Find nearest walkable tile to the tree
		var move_to_pos = player.pathfinder.find_nearest_available_tile(
			result.collider.global_position, 
			player.global_position
		)
		
		print("Nearest available tile:", move_to_pos)
		
		# Check if we got a valid position
		if move_to_pos == result.collider.global_position:
			print("WARNING: No adjacent walkable tile found!")
			return
		
		# Find path to that position
		var path = player.pathfinder.find_path(player.global_position, move_to_pos)
		print("Path found with", path.size(), "waypoints")
		
		if path.size() > 0:
			print("Starting movement to tree...")
			update_tile_indicator(move_to_pos)
			player.call("move_to", move_to_pos)
			
			# Wait until player reaches destination before starting tree cutting
			await player.movement_finished
			
			print("Player reached tree, starting cutting...")
			player.call("start_cutting_tree", result.collider)
		else:
			print("ERROR: No path found to tree!")
		return
	
	# Handle regular ground clicks
	var plane = Plane(Vector3.UP, 0)
	var hit = plane.intersects_ray(from, to)
	
	if hit == null:
		print("No intersection with ground plane")
		return
	
	var grid_x = int(floor(hit.x / terrain.tile_size))
	var grid_y = int(floor(hit.z / terrain.tile_size))
	
	if not is_valid_grid_position(grid_x, grid_y):
		print("Clicked outside terrain bounds")
		return
	
	var tile = terrain.tile_data[grid_x][grid_y]
	
	if not tile or not tile.walkable:
		print("Tile not walkable at grid position:", grid_x, grid_y)
		return
	
	print("Moving to grid position (%d, %d) - World position: %s" % [grid_x, grid_y, tile.world_position])
	update_tile_indicator(tile.world_position)
	player.call("move_to", tile.world_position)

func is_valid_grid_position(grid_x: int, grid_y: int) -> bool:
	return (grid_x >= 0 and grid_x < terrain.terrain_width and 
			grid_y >= 0 and grid_y < terrain.terrain_height)

func update_tile_indicator(world_position: Vector3):
	var grid_x = int(floor(world_position.x / terrain.tile_size))
	var grid_y = int(floor(world_position.z / terrain.tile_size))
	
	if not is_valid_grid_position(grid_x, grid_y):
		return
	
	var tile = terrain.tile_data[grid_x][grid_y]
	
	if tile_indicator == null:
		tile_indicator = tile_indicator_scene.instantiate()
		terrain.add_child(tile_indicator)
	
	tile_indicator.global_position = tile.world_position
	
	if tile_indicator.has_method("set_tile_shape"):
		tile_indicator.set_tile_shape(tile.corners)
