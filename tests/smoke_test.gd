extends RefCounted


static func run() -> bool:
	var scene: PackedScene = load("res://terrain_generator.tscn")
	if ProjectSettings.get_setting("application/config/name") != "GodotGrid" or scene == null:
		return false
	var instance := scene.instantiate()
	var ok: bool = instance.get_script() != null
	instance.free()
	return ok
