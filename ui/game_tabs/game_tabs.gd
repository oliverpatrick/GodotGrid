class_name GameTabs
extends Control

signal combat_style_requested(style: int)

@onready var inventory: PanelContainer = $HSplitContainer/TabContainer/InventoryTab/InventoryPanel
@onready var health_label: Label = $HSplitContainer/TabContainer/SkillsTab/SkillGrid/Health
@onready var attack_label: Label = $HSplitContainer/TabContainer/SkillsTab/SkillGrid/Attack
@onready var defence_label: Label = $HSplitContainer/TabContainer/SkillsTab/SkillGrid/Defence
@onready var harvesting_label: Label = $HSplitContainer/TabContainer/SkillsTab/SkillGrid/Harvesting
@onready var perception_label: Label = $HSplitContainer/TabContainer/SkillsTab/SkillGrid/Perception

@onready var _inventory_tab: Control = $HSplitContainer/TabContainer/InventoryTab
@onready var _skills_tab: Control = $HSplitContainer/TabContainer/SkillsTab
@onready var _combat_tab: Control = $HSplitContainer/TabContainer/CombatTab
@onready var _inventory_button: Button = $HSplitContainer/GridContainer/InventoryTabButton
@onready var _skills_button: Button = $HSplitContainer/GridContainer/SkillsTabButton
@onready var _combat_button: Button = $HSplitContainer/GridContainer/CombatButton
@onready var _aggressive_button: Button = $HSplitContainer/TabContainer/CombatTab/StyleOptions/Aggressive
@onready var _defensive_button: Button = $HSplitContainer/TabContainer/CombatTab/StyleOptions/Defensive
@onready var _tab_container: Control = $HSplitContainer/TabContainer
var _active_tab := ""
var _acknowledged_style := -1

func _ready() -> void:
	var tab_buttons := ButtonGroup.new()
	tab_buttons.allow_unpress = true
	for button in [_inventory_button, _skills_button, _combat_button]:
		button.toggle_mode = true
		button.button_group = tab_buttons
	_inventory_button.pressed.connect(func(): toggle_tab("inventory"))
	_skills_button.pressed.connect(func(): toggle_tab("skills"))
	_combat_button.pressed.connect(func(): toggle_tab("combat"))
	var style_buttons := ButtonGroup.new()
	for button in [_aggressive_button, _defensive_button]:
		button.button_group = style_buttons
	_aggressive_button.pressed.connect(func(): _request_combat_style(0))
	_defensive_button.pressed.connect(func(): _request_combat_style(1))
	select_tab("inventory")

func select_tab(tab_name: String) -> void:
	_active_tab = tab_name
	_tab_container.visible = true
	_inventory_tab.visible = tab_name == "inventory"
	_skills_tab.visible = tab_name == "skills"
	_combat_tab.visible = tab_name == "combat"
	_inventory_button.set_pressed_no_signal(tab_name == "inventory")
	_skills_button.set_pressed_no_signal(tab_name == "skills")
	_combat_button.set_pressed_no_signal(tab_name == "combat")

func toggle_tab(tab_name: String) -> void:
	if _active_tab == tab_name:
		_active_tab = ""
		_tab_container.visible = false
		_inventory_tab.visible = false
		_skills_tab.visible = false
		_combat_tab.visible = false
		_inventory_button.set_pressed_no_signal(false)
		_skills_button.set_pressed_no_signal(false)
		_combat_button.set_pressed_no_signal(false)
		return
	select_tab(tab_name)

func acknowledge_combat_style(style: int) -> void:
	if style < 0 or style > 1:
		return
	_acknowledged_style = style
	_aggressive_button.disabled = false
	_defensive_button.disabled = false
	_restore_style_buttons()

func _request_combat_style(style: int) -> void:
	_restore_style_buttons()
	combat_style_requested.emit(style)

func _restore_style_buttons() -> void:
	_aggressive_button.set_pressed_no_signal(_acknowledged_style == 0)
	_defensive_button.set_pressed_no_signal(_acknowledged_style == 1)
