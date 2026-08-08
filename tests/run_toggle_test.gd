extends RefCounted

const HUDScene = preload("uid://01ughi8s4iax") # ui/player_hud/hud.tscn
const GameApp = preload("res://game_app.gd")
const ClickToMove = preload("res://world/click_to_move.gd")

static func run() -> bool:
	var hud = HUDScene.instantiate()
	var root := Node.new()
	Engine.get_main_loop().root.add_child(root)
	root.add_child(hud)
	var button: Button = hud.get_node("RunButton")
	var skill_grid: GridContainer = hud.get_node("GameTabs/HSplitContainer/TabContainer/SkillsTab/SkillGrid")
	var inventory_tab: Control = hud.get_node("GameTabs/HSplitContainer/TabContainer/InventoryTab")
	var skills_tab: Control = hud.get_node("GameTabs/HSplitContainer/TabContainer/SkillsTab")
	var combat_tab: Control = hud.get_node("GameTabs/HSplitContainer/TabContainer/CombatTab")
	if skill_grid.columns != 2 or skill_grid.get_child_count() != 5:
		root.free()
		return false
	if not inventory_tab.visible or skills_tab.visible or combat_tab.visible:
		printerr("Inventory tab is not selected initially")
		root.free()
		return false
	hud.game_tabs.select_tab("skills")
	if inventory_tab.visible or not skills_tab.visible or combat_tab.visible:
		printerr("Skills tab did not replace the inventory tab")
		root.free()
		return false
	hud.game_tabs.toggle_tab("skills")
	if inventory_tab.visible or skills_tab.visible or combat_tab.visible:
		printerr("Selecting the active tab did not close it")
		root.free()
		return false
	hud.game_tabs.toggle_tab("skills")
	if inventory_tab.visible or not skills_tab.visible or combat_tab.visible:
		printerr("Closed skills tab did not reopen")
		root.free()
		return false
	hud.game_tabs.select_tab("combat")
	if inventory_tab.visible or skills_tab.visible or not combat_tab.visible:
		printerr("Combat tab did not replace the skills tab")
		root.free()
		return false
	hud.game_tabs.toggle_tab("combat")
	if inventory_tab.visible or skills_tab.visible or combat_tab.visible:
		printerr("Selecting the active combat tab did not close it")
		root.free()
		return false
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
	var movement := ClickToMove.new()
	GameApp.wire_run_toggle(hud, movement)
	hud.set_run_enabled(true)
	if movement.effective_movement_mode(false) != 1:
		printerr("HUD toggle did not enable movement running")
		movement.free()
		root.free()
		return false
	hud.set_run_enabled(false)
	if movement.effective_movement_mode(false) != 0:
		printerr("HUD toggle did not restore movement walking")
		movement.free()
		root.free()
		return false
	movement.free()
	root.free()
	return true
