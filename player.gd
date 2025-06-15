# player.gd - Attach to Player (CharacterBody3D)
extends CharacterBody3D

var target_position: Vector3
var is_moving: bool = false
@export var move_speed := 5.0
var current_tree = null

func move_to(destination: Vector3):
	target_position = destination
	is_moving = true

func _physics_process(delta):
	if is_moving:
		var direction = (target_position - global_transform.origin)
		direction.y = 0
		if direction.length() < 0.1:
			is_moving = false
			velocity = Vector3.ZERO
		else:
			velocity = direction.normalized() * move_speed
			move_and_slide()

func start_cutting_tree(tree):
	current_tree = tree
	# Start a timer or animation
	$CutTimer.start() # Add Timer node in the scene

func _on_cut_timer_timeout():
	if current_tree:
		current_tree.queue_free()
		current_tree = null
