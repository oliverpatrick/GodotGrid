class_name RemotePlayer
extends Node3D

const TerrainHeightScript = preload("uid://ctl1kxhgld3tn") # world/terrain_height.gd
const PlayerAnimationControllerScript = preload("uid://ch55e8gtqv5nx") # world/player_animation_controller.gd
const HealthBar3DScript = preload("res://world/health_bar_3d.gd")

var player_index := -1
var display_name := ""
var plane := 0
var terrain_bundle
var _from := Vector3.ZERO
var _target := Vector3.ZERO
var _elapsed := 0.0
var _duration := 0.6
var animation_controller
var health_bar

func _ready() -> void:
	if get_child_count() == 0:
		var body := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.32
		capsule.height = 1.65
		body.mesh = capsule
		body.position.y = 0.825
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.28, 0.78, 0.62) if player_index >= 0 else Color(0.7, 0.7, 0.7)
		material.roughness = 0.8
		body.material_override = material
		add_child(body)
	health_bar = HealthBar3DScript.new()
	health_bar.name = "HealthBar3D"
	add_child(health_bar)

func configure(index: int, player_name: String, bundle) -> void:
	player_index = index
	display_name = player_name
	terrain_bundle = bundle
	_ensure_animation_controller()

func snap_to_tile(x: int, z: int, next_plane: int) -> void:
	plane = next_plane
	_target = _tile_position(x, z, plane)
	_from = _target
	position = _target
	_elapsed = _duration
	_ensure_animation_controller()
	if animation_controller != null:
		animation_controller.movement_finished()

func confirm_tile(x: int, z: int, next_plane: int, tick_seconds: float) -> void:
	var next := _tile_position(x, z, next_plane)
	if next_plane != plane:
		snap_to_tile(x, z, next_plane)
		return
	if next.is_equal_approx(_target):
		return
	var tile_distance := maxi(absi(int(round(next.x - _target.x))), absi(int(round(next.z - _target.z))))
	_from = position
	_target = next
	_elapsed = 0.0
	_duration = maxf(tick_seconds, 0.001)
	_ensure_animation_controller()
	if animation_controller != null:
		animation_controller.movement_started(tile_distance)

func _process(delta: float) -> void:
	advance_interpolation(delta)

func advance_interpolation(delta: float) -> void:
	var was_moving := _elapsed < _duration
	_elapsed = minf(_elapsed + delta, _duration)
	position = _from.lerp(_target, _elapsed / _duration)
	if is_inside_tree() and position.distance_squared_to(_target) > 0.0001:
		look_at(Vector3(_target.x, position.y, _target.z), Vector3.UP)
	if was_moving and _elapsed >= _duration and animation_controller != null:
		animation_controller.movement_finished()

func set_action(action: int) -> void:
	_ensure_animation_controller()
	if animation_controller != null:
		animation_controller.set_action(action)

func set_health(hp: int, maximum: int) -> void:
	health_bar.set_health(hp, maximum)

func face_towards(target_position: Vector3) -> void:
	var flat_target := Vector3(target_position.x, position.y, target_position.z)
	if position.distance_squared_to(flat_target) <= 0.0001:
		return
	look_at_from_position(position, flat_target, Vector3.UP)

func _ensure_animation_controller() -> void:
	if animation_controller != null:
		return
	var player := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player != null:
		animation_controller = PlayerAnimationControllerScript.new(player)

func _tile_position(x: int, z: int, at_plane: int) -> Vector3:
	var centre_x := x + 0.5
	var centre_z := z + 0.5
	return Vector3(centre_x, TerrainHeightScript.sample(terrain_bundle, centre_x, centre_z, at_plane), centre_z)
