extends RefCounted

const HUDScene = preload("res://ui/hud.tscn")

static func run() -> bool:
	var hud = HUDScene.instantiate()
	var root := Node.new()
	Engine.get_main_loop().root.add_child(root)
	root.add_child(hud)
	var button: Button = hud.get_node("RunButton")
	if button.text != "Run" or hud.is_run_enabled():
		printerr("Run button has wrong initial state")
		root.free()
		return false
	var emitted: Array[bool] = []
	hud.run_toggled.connect(func(enabled: bool): emitted.append(enabled))
	hud.set_run_enabled(true)
	var active_style := button.get_theme_stylebox("pressed") as StyleBoxFlat
	if not hud.is_run_enabled() or emitted != [true] or active_style == null or active_style.bg_color.g <= active_style.bg_color.r:
		printerr("Run button did not enter green active state")
		root.free()
		return false
	hud.set_run_enabled(false)
	if hud.is_run_enabled() or emitted != [true, false] or button.text != "Run":
		printerr("Run button did not return to neutral state")
		root.free()
		return false
	root.free()
	return true
