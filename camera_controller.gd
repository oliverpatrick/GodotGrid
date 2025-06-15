extends Camera3D

@export var distance: float = 20.0
@export var height: float = 15.0
@export var rotation_speed: float = 1.0
@export var zoom_speed: float = 10.0
@export var min_distance: float = 5.0
@export var max_distance: float = 50.0

@onready var terrain = get_parent().get_parent()
@onready var player = get_parent()
@onready var tile_indicator_scene = preload("res://tile_indicator.tscn")

var tile_indicator: Node3D = null
var angle: float = 0.0

func _ready():
	# Position camera to look at terrain
	position_camera()

func _process(delta):
	# Camera rotation controls
	if Input.is_action_pressed("ui_left"):
		angle -= rotation_speed * delta
		position_camera()
	elif Input.is_action_pressed("ui_right"):
		angle += rotation_speed * delta
		position_camera()
	
	# Zoom controls
	if Input.is_action_pressed("ui_up"):
		distance = max(min_distance, distance - zoom_speed * delta)
		position_camera()
	elif Input.is_action_pressed("ui_down"):
		distance = min(max_distance, distance + zoom_speed * delta)
		position_camera()

func position_camera():
	var offset = Vector3(
		cos(angle) * distance,
		height,
		sin(angle) * distance
	)
	
	global_position = player.global_position + offset
	look_at(player.global_position, Vector3.UP)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_mouse_click(event.position)

func handle_mouse_click(mouse_pos: Vector2):
	"""Handle mouse click for movement or tree interaction"""
	
	# Cast ray from camera
	var from = project_ray_origin(mouse_pos)
	var to = from + project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.collision_mask = 1  # Adjust if using different physics layers
	
	var result = space_state.intersect_ray(query)
	
	# Check if we hit a tree first
	if result and result.collider.is_in_group("Trees"):
		print("Clicked on tree at:", result.collider.global_position)
		
		# Move to tree location and start cutting
		player.call("move_to", result.collider.global_position)
		player.call("start_cutting_tree", result.collider)
		
		# Update tile indicator
		update_tile_indicator(result.collider.global_position)
		return
	
	# If no tree hit, check ground plane intersection
	var plane = Plane(Vector3.UP, 0)  # y=0 plane
	var hit = plane.intersects_ray(from, to)
	
	if hit == null:
		print("No intersection with ground plane")
		return
	
	# Convert world position to grid coordinates
	var grid_x = int(floor(hit.x / terrain.tile_size))
	var grid_y = int(floor(hit.z / terrain.tile_size))
	
	# Validate grid position
	if not is_valid_grid_position(grid_x, grid_y):
		print("Clicked outside terrain bounds")
		return
	
	var tile = terrain.tile_data[grid_x][grid_y]
	
	if not tile or not tile.walkable:
		print("Tile not walkable at grid position:", grid_x, grid_y)
		return
	
	print("Moving to grid position (%d, %d) - World position: %s" % [grid_x, grid_y, tile.world_position])
	
	# Update tile indicator
	update_tile_indicator(tile.world_position)
	
	# Tell player to move using pathfinding
	player.call("move_to", tile.world_position)

func is_valid_grid_position(grid_x: int, grid_y: int) -> bool:
	"""Check if grid coordinates are within terrain bounds"""
	return (grid_x >= 0 and grid_x < terrain.terrain_width and 
			grid_y >= 0 and grid_y < terrain.terrain_height)

func update_tile_indicator(world_position: Vector3):
	"""Update the tile indicator position and shape"""
	
	# Convert world position back to grid to get exact tile
	var grid_x = int(floor(world_position.x / terrain.tile_size))
	var grid_y = int(floor(world_position.z / terrain.tile_size))
	
	if not is_valid_grid_position(grid_x, grid_y):
		return
	
	var tile = terrain.tile_data[grid_x][grid_y]
	
	# Create or update tile indicator
	if tile_indicator == null:
		tile_indicator = tile_indicator_scene.instantiate()
		terrain.add_child(tile_indicator)
	
	tile_indicator.global_position = tile.world_position
	
	# Update indicator shape if it has corners
	if tile_indicator.has_method("set_tile_shape"):
		tile_indicator.set_tile_shape(tile.corners)
