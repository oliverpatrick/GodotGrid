extends RefCounted


static func run() -> bool:
	var configured_main_scene := str(ProjectSettings.get_setting("application/run/main_scene"))
	if configured_main_scene.is_empty() or load(configured_main_scene) == null:
		return false
	var scene: PackedScene = load("res://terrain_generator.tscn")
	if ProjectSettings.get_setting("application/config/name") != "GodotGrid" or scene == null:
		return false
	var instance := scene.instantiate()
	var login := instance.get_node_or_null("LoginScreen")
	var hud := instance.get_node_or_null("HUD")
	var ok: bool = (
		instance.get_script() != null
		and instance.get_node_or_null("SelectionFeedback") != null
		and login != null and login.get_script() != null
		and hud != null and hud.get_script() != null
	)
	instance.free()
	return ok
