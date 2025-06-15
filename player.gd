# player.gd - Attach to Player (CharacterBody3D)
extends CharacterBody3D

@export var move_speed: float = 5.0
@export var path_debug: bool = true

var pathfinder: Pathfinder
var current_path: Array = []
var current_path_index: int = 0
var target_position: Vector3
var is_moving: bool = false
var current_tree = null

@onready var terrain_generator = get_parent()  # Adjust path as needed
@onready var rig = $Rig
@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("Idle")
	# Initialize pathfinder
	pathfinder = Pathfinder.new()
	
	# Wait a frame to ensure terrain is generated
	await get_tree().process_frame
	
	# Setup pathfinder with terrain reference
	pathfinder.setup(terrain_generator)
	
	print("Player ready, pathfinder initialized")

func move_to(destination: Vector3):
	"""Move to destination using pathfinding"""
	print("Player moving from ", global_position, " to ", destination)
	
	# Find path using A*
	current_path = pathfinder.find_path(global_position, destination)
	
	if current_path.size() == 0:
		print("No path found to destination")
		return
	
	if path_debug:
		pathfinder.print_path(current_path)
	
	# Start following the path
	current_path_index = 0
	is_moving = true
	
	# Set first target (skip current position if it's the start)
	if current_path.size() > 1:
		current_path_index = 1  # Skip the starting position
	
	set_current_target()

func set_current_target():
	"""Set the current waypoint as the target"""
	if current_path_index < current_path.size():
		target_position = current_path[current_path_index]
		print("Moving to waypoint %d: %s" % [current_path_index, target_position])
	else:
		# Reached the end of the path
		is_moving = false
		current_path.clear()
		print("Reached destination!")

func _physics_process(delta):
	if is_moving and current_path.size() > 0:
		animation_player.play("Walk")
		var direction = (target_position - global_position)
		direction.y = 0  # Keep movement on the horizontal plane
		
		var distance_to_target = direction.length()
		
		# Check if we've reached the current waypoint
		if distance_to_target < 0.2:  # Small threshold for reaching waypoint
			current_path_index += 1
			
			if current_path_index < current_path.size():
				# Move to next waypoint
				set_current_target()
			else:
				# Reached final destination
				is_moving = false
				animation_player.play("Idle")
				velocity = Vector3.ZERO
				current_path.clear()
				print("Path completed!")
		else:
			# Continue moving toward current waypoint
			velocity = direction.normalized() * move_speed
			print(rotation.y)
			# Optional: Face movement direction
			if direction.length() > 0.1:
				#var target_rotation = atan2(direction.x, direction.z)
				##rig.rotation.y = lerp_angle(rotation.y, target_rotation, delta * 8.0)
				#rig.rotation.y = rotation.y
				var target_rotation = atan2(direction.x, direction.z)
				rig.rotation.y = lerp_angle(rig.rotation.y, target_rotation, delta * 10.0)

		
		move_and_slide()

func start_cutting_tree(tree):
	"""Start cutting a tree (stops current movement)"""
	current_tree = tree
	is_moving = false
	current_path.clear()
	velocity = Vector3.ZERO
	
	# Start a timer or animation
	if has_node("CutTimer"):
		$CutTimer.start()

func _on_cut_timer_timeout():
	"""Called when tree cutting is complete"""
	if current_tree:
		print("Tree cut down!")
		current_tree.queue_free()
		current_tree = null

# Debug function to visualize current path
func get_current_path() -> Array:
	"""Get the current path for debugging"""
	return current_path

func is_path_following() -> bool:
	"""Check if currently following a path"""
	return is_moving and current_path.size() > 0
