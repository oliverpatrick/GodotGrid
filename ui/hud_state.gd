class_name HUDState
extends RefCounted

var slots: Array = []
var harvesting_xp := 0
var harvesting_level := 1
var resources: Dictionary = {}
var messages: Array[String] = []

func _init() -> void:
	slots.resize(30)
	for index in range(30):
		slots[index] = null

func apply_inventory(incoming: Array) -> void:
	for index in range(30):
		slots[index] = null
	for item in incoming:
		var slot: int = item.slot
		if slot >= 0 and slot < 30:
			slots[slot] = item.duplicate()

func apply_skill(skill: int, xp: int) -> void:
	if skill != 0:
		return
	harvesting_xp = xp
	harvesting_level = level_for_xp(xp)

func apply_resource(entity: int, state: int) -> void:
	resources[entity] = state

func add_message(text: String) -> void:
	messages.append(text)
	if messages.size() > 200:
		messages.pop_front()

static func level_for_xp(xp: int) -> int:
	var level := 1
	var points := 0.0
	while level < 10000:
		points += level + floor(280.0 * pow(2.0, level / 7.25))
		if int(points / 4.0) > xp:
			return level
		level += 1
	return level
