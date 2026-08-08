class_name HealthBar3D
extends Node3D

const WIDTH := 1.0
const HEIGHT := 0.12

var _ratio := 1.0
var _fill: MeshInstance3D
var _fill_mesh: QuadMesh

func _ready() -> void:
	position.y = 2.15
	visible = false

	var background := MeshInstance3D.new()
	var background_mesh := QuadMesh.new()
	background_mesh.size = Vector2(WIDTH, HEIGHT)
	background.mesh = background_mesh
	background.material_override = _material(Color(0.35, 0.04, 0.04))
	add_child(background)

	_fill = MeshInstance3D.new()
	_fill_mesh = QuadMesh.new()
	_fill_mesh.size = Vector2(WIDTH, HEIGHT)
	_fill_mesh.center_offset.z = 0.001
	_fill.mesh = _fill_mesh
	_fill.material_override = _material(Color(0.1, 0.8, 0.2))
	add_child(_fill)

func set_health(hp: int, maximum: int) -> void:
	if maximum <= 0:
		return
	_ratio = clampf(float(hp) / float(maximum), 0.0, 1.0)
	visible = hp < maximum
	_fill.visible = _ratio > 0.0
	var fill_size := _fill_mesh.size
	fill_size.x = WIDTH * _ratio
	_fill_mesh.size = fill_size
	var fill_offset := _fill_mesh.center_offset
	fill_offset.x = -(WIDTH - fill_size.x) * 0.5
	_fill_mesh.center_offset = fill_offset

func health_ratio() -> float:
	return _ratio

func fill_visible() -> bool:
	return _fill.visible

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	return material
