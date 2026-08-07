class_name GameTabs
extends Control

@onready var inventory: PanelContainer = $HSplitContainer/TabContainer/InventoryTab/InventoryPanel
@onready var health_label: Label = $HSplitContainer/TabContainer/SkillsTab/SkillGrid/Health
@onready var attack_label: Label = $HSplitContainer/TabContainer/SkillsTab/SkillGrid/Attack
@onready var defence_label: Label = $HSplitContainer/TabContainer/SkillsTab/SkillGrid/Defence
@onready var harvesting_label: Label = $HSplitContainer/TabContainer/SkillsTab/SkillGrid/Harvesting
@onready var perception_label: Label = $HSplitContainer/TabContainer/SkillsTab/SkillGrid/Perception

@onready var _inventory_tab: Control = $HSplitContainer/TabContainer/InventoryTab
@onready var _skills_tab: Control = $HSplitContainer/TabContainer/SkillsTab
@onready var _inventory_button: Button = $HSplitContainer/GridContainer/InventoryTabButton
@onready var _skills_button: Button = $HSplitContainer/GridContainer/SkillsTabButton
@onready var _tab_container: Control = $HSplitContainer/TabContainer
var _active_tab := ""

func _ready() -> void:
	var tab_buttons := ButtonGroup.new()
	tab_buttons.allow_unpress = true
	for button in [_inventory_button, _skills_button]:
		button.toggle_mode = true
		button.button_group = tab_buttons
	_inventory_button.pressed.connect(func(): toggle_tab("inventory"))
	_skills_button.pressed.connect(func(): toggle_tab("skills"))
	select_tab("inventory")

func select_tab(tab_name: String) -> void:
	var show_inventory := tab_name == "inventory"
	_active_tab = tab_name
	_tab_container.visible = true
	_inventory_tab.visible = show_inventory
	_skills_tab.visible = not show_inventory
	_inventory_button.set_pressed_no_signal(show_inventory)
	_skills_button.set_pressed_no_signal(not show_inventory)

func toggle_tab(tab_name: String) -> void:
	if _active_tab == tab_name:
		_active_tab = ""
		_tab_container.visible = false
		_inventory_tab.visible = false
		_skills_tab.visible = false
		_inventory_button.set_pressed_no_signal(false)
		_skills_button.set_pressed_no_signal(false)
		return
	select_tab(tab_name)
