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

func _ready() -> void:
	var tab_buttons := ButtonGroup.new()
	tab_buttons.allow_unpress = false
	for button in [_inventory_button, _skills_button]:
		button.toggle_mode = true
		button.button_group = tab_buttons
	_inventory_button.pressed.connect(func(): select_tab("inventory"))
	_skills_button.pressed.connect(func(): select_tab("skills"))
	select_tab("inventory")

func select_tab(tab_name: String) -> void:
	var show_inventory := tab_name == "inventory"
	_inventory_tab.visible = show_inventory
	_skills_tab.visible = not show_inventory
	_inventory_button.set_pressed_no_signal(show_inventory)
	_skills_button.set_pressed_no_signal(not show_inventory)
