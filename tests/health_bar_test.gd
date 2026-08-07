extends RefCounted

const HealthBar3D = preload("res://world/health_bar_3d.gd")

static func run() -> bool:
	var root := Node3D.new()
	Engine.get_main_loop().root.add_child(root)
	var character := Node3D.new()
	root.add_child(character)
	var bar = HealthBar3D.new()
	character.add_child(bar)
	var background := bar.get_child(0) as MeshInstance3D
	var fill := bar.get_child(1) as MeshInstance3D
	var fill_mesh := fill.mesh as QuadMesh
	var camera := Camera3D.new()
	root.add_child(camera)
	for character_rotation in [0.0, PI * 0.5]:
		character.rotation.y = character_rotation
		for camera_position in [Vector3(0.0, 4.0, 6.0), Vector3(6.0, 3.0, 0.0)]:
			camera.position = camera_position
			camera.look_at(bar.global_position)
			var billboard_offset := camera.global_basis * fill_mesh.center_offset
			var toward_camera: Vector3 = bar.global_position.direction_to(camera.global_position)
			if not fill.global_position.is_equal_approx(background.global_position) \
				or not is_equal_approx(billboard_offset.length(), 0.001) \
				or billboard_offset.normalized().dot(toward_camera) < 0.999:
				root.free()
				return false
	bar.set_health(10, 10)
	if bar.visible:
		root.free()
		return false
	bar.set_health(5, 10)
	if not bar.visible or not is_equal_approx(bar.health_ratio(), 0.5):
		root.free()
		return false
	bar.set_health(5, 0)
	if not bar.visible or not is_equal_approx(bar.health_ratio(), 0.5):
		root.free()
		return false
	bar.set_health(20, 10)
	if bar.visible or not is_equal_approx(bar.health_ratio(), 1.0):
		root.free()
		return false
	bar.set_health(0, 10)
	var ok: bool = bar.visible and not bar.fill_visible()
	root.free()
	return ok
