class_name RemotePlayer
extends Node3D

const TerrainHeight = preload("res://world/terrain_height.gd")

var player_index := -1
var display_name := ""
var plane := 0
var terrain_bundle
var _from := Vector3.ZERO
var _target := Vector3.ZERO
var _elapsed := 0.0
var _duration := 0.6

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

func configure(index: int, name: String, bundle) -> void:
	player_index = index
	display_name = name
	terrain_bundle = bundle

func snap_to_tile(x: int, z: int, next_plane: int) -> void:
	plane = next_plane
	_target = _tile_position(x, z, plane)
	_from = _target
	position = _target
	_elapsed = _duration

func confirm_tile(x: int, z: int, next_plane: int, tick_seconds: float) -> void:
	var next := _tile_position(x, z, next_plane)
	if next_plane != plane:
		snap_to_tile(x, z, next_plane)
		return
	if next.is_equal_approx(_target):
		return
	_from = position
	_target = next
	_elapsed = 0.0
	_duration = maxf(tick_seconds, 0.001)

func _process(delta: float) -> void:
	advance_interpolation(delta)

func advance_interpolation(delta: float) -> void:
	_elapsed = minf(_elapsed + delta, _duration)
	position = _from.lerp(_target, _elapsed / _duration)
	if is_inside_tree() and position.distance_squared_to(_target) > 0.0001:
		look_at(Vector3(_target.x, position.y, _target.z), Vector3.UP)

func _tile_position(x: int, z: int, at_plane: int) -> Vector3:
	var centre_x := x + 0.5
	var centre_z := z + 0.5
	return Vector3(centre_x, TerrainHeight.sample(terrain_bundle, centre_x, centre_z, at_plane), centre_z)
