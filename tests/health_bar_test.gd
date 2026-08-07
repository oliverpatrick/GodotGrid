extends RefCounted

const HealthBar3D = preload("res://world/health_bar_3d.gd")

static func run() -> bool:
	var root := Node3D.new()
	Engine.get_main_loop().root.add_child(root)
	var bar = HealthBar3D.new()
	root.add_child(bar)
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
