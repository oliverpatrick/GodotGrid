# player.gd - Improved version with signals and better debugging
extends CharacterBody3D

signal movement_finished  # Signal emitted when movement is complete

@export var move_speed: float = 3.0
@export var path_debug: bool = true

var pathfinder: Pathfinder
var current_path: Array = []
var current_path_index: int = 0
var target_position: Vector3
var is_moving: bool = false
var current_tree = null

@onready var terrain_generator = get_parent()
@onready var rig = $Rig
@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("Idle")
	pathfinder = Pathfinder.new()
	
	await get_tree().process_frame
	pathfinder.setup(terrain_generator)
	
	snap_to_terrain()
	
	print("Player ready, pathfinder initialized")

# Method 1A: Use terrain tile data directly
func snap_to_terrain():
	"""Snap character to terrain height using tile data"""
	if not terrain_generator:
		return
	
	var grid_pos = pathfinder.world_to_grid(global_position)
	
	if pathfinder.is_valid_grid_pos(grid_pos):
		var tile = terrain_generator.tile_data[grid_pos.x][grid_pos.y]
		if tile:
			# Set Y position to tile's world position Y
			global_position.y = tile.world_position.y

func move_to(destination: Vector3):
	"""Move to destination using pathfinding"""
	print("=== MOVE_TO DEBUG ===")
	print("Player position: ", global_position)
	print("Destination: ", destination)
	
	# Stop any current movement
	is_moving = false
	current_path.clear()
	velocity = Vector3.ZERO
	
	# Find path using A*
	current_path = pathfinder.find_path(global_position, destination)
	
	if current_path.size() == 0:
		print("ERROR: No path found to destination")
		movement_finished.emit()  # Emit signal even on failure
		return
	
	if path_debug:
		print("Path found with ", current_path.size(), " waypoints:")
		for i in range(current_path.size()):
			print("  Waypoint %d: %s" % [i, current_path[i]])
	
	# Start following the path
	current_path_index = 0
	is_moving = true
	
	# Set first target (skip current position if it's the start)
	if current_path.size() > 1:
		current_path_index = 1  # Skip the starting position
	
	set_current_target()

# func smooth_snap_to_terrain(delta: float):
# 	"""Smoothly snap character to terrain height"""
# 	if not terrain_generator:
# 		return
	
# 	var grid_pos = pathfinder.world_to_grid(global_position)
	
# 	if pathfinder.is_valid_grid_pos(grid_pos):
# 		var tile = terrain_generator.tile_data[grid_pos.x][grid_pos.y]
# 		if tile:
# 			var target_y = tile.world_position.y
# 			global_position.y = lerp(global_position.y, target_y, 10.0 * delta)

func set_current_target():
	"""Set the current waypoint as the target"""
	if current_path_index < current_path.size():
		target_position = current_path[current_path_index]
		print("Moving to waypoint %d: %s" % [current_path_index, target_position])
	else:
		# Reached the end of the path
		finish_movement()

func finish_movement():
	"""Complete the movement and emit signal"""
	is_moving = false
	current_path.clear()
	velocity = Vector3.ZERO
	animation_player.play("Idle")
	print("Movement completed!")
	movement_finished.emit()

func _physics_process(delta):
	# smooth_snap_to_terrain(delta)

	if not is_moving or current_path.size() == 0:
		return
		
	# Play walking animation
	if animation_player.current_animation != "Walk":
		animation_player.play("Walk")
	
	var direction = (target_position - global_position)
	direction.y = 0  # Keep movement on the horizontal plane
	
	var distance_to_target = direction.length()
	
	# Check if we've reached the current waypoint
	if distance_to_target < 0.5:  # Increased threshold for more reliable detection
		print("Reached waypoint %d" % current_path_index)
		current_path_index += 1
		
		if current_path_index < current_path.size():
			# Move to next waypoint
			set_current_target()
		else:
			# Reached final destination
			finish_movement()
	else:
		# Continue moving toward current waypoint
		velocity = direction.normalized() * move_speed
		
		# Face movement direction
		if direction.length() > 0.1:
			var target_rotation = atan2(direction.x, direction.z)
			rig.rotation.y = lerp_angle(rig.rotation.y, target_rotation, delta * 10.0)
	
	move_and_slide()

func start_cutting_tree(tree):
	"""Start cutting a tree (stops current movement)"""
	print("Starting to cut tree at:", tree.global_position)
	current_tree = tree
	# Make sure we're not moving
	is_moving = false
	current_path.clear()
	velocity = Vector3.ZERO
	
	# Face the tree
	var direction_to_tree = (tree.global_position - global_position)
	direction_to_tree.y = 0
	if direction_to_tree.length() > 0.1:
		var target_rotation = atan2(direction_to_tree.x, direction_to_tree.z)
		rig.rotation.y = target_rotation
	
	animation_player.play("Sword_Attack", 0.3)
	await get_tree().create_timer(2.0).timeout
	# Start cutting animation/timer
	print("Tree cutting started...")
	# await animation_player.animation_finished
	# animation_player.play("Sword_Attack")
	# await animation_player.animation_finished
	# animation_player.play("Sword_Attack")
	# await animation_player.animation_finished

	# For now, just wait a bit then remove the tree
	finish_cutting_tree()

func finish_cutting_tree():
	"""Complete tree cutting"""
	if current_tree:
		print("Tree cut down!")
		current_tree.queue_free()
		current_tree = null
		animation_player.play("Idle")

# Debug functions
func get_current_path() -> Array:
	return current_path

func is_path_following() -> bool:
	return is_moving and current_path.size() > 0

func debug_current_state():
	print("=== Player Debug State ===")
	print("Position: ", global_position)
	print("Is moving: ", is_moving)
	print("Current path size: ", current_path.size())
	print("Path index: ", current_path_index)
	if current_path.size() > 0:
		print("Current target: ", target_position)
	print("Velocity: ", velocity)
	print("==========================")
