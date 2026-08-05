extends RefCounted


static func run() -> bool:
	return ProjectSettings.get_setting("application/config/name") == "GodotGrid"
