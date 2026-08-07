class_name FollowCamera
extends Camera3D

@export var distance := 14.0
@export var pitch_degrees := 38.0
@export var orbit_speed := 1.4
@export var follow_speed := 8.0
@export var min_distance := 6.0
@export var max_distance := 24.0
var target: Node3D
var yaw := deg_to_rad(45.0)

func configure(follow_target: Node3D) -> void:
	target = follow_target
	current = true
	_update_transform(1.0)

func _process(delta: float) -> void:
	if target == null:
		return
	if Input.is_action_pressed("ui_left"):
		yaw -= orbit_speed * delta
	if Input.is_action_pressed("ui_right"):
		yaw += orbit_speed * delta
	_update_transform(clampf(delta * follow_speed, 0.0, 1.0))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(min_distance, distance - 1.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(max_distance, distance + 1.5)

func _update_transform(weight: float) -> void:
	var pitch := deg_to_rad(clampf(pitch_degrees, 20.0, 65.0))
	var horizontal := cos(pitch) * distance
	var offset := Vector3(cos(yaw) * horizontal, sin(pitch) * distance, sin(yaw) * horizontal)
	global_position = global_position.lerp(target.global_position + offset, weight)
	look_at(target.global_position + Vector3.UP * 0.8, Vector3.UP)
