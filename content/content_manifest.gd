class_name ContentBundle
extends RefCounted

var root: String
var manifest: Dictionary
var definitions: Dictionary
var regions: Dictionary = {}
var gameplay_hash: String

func item_by_wire_id(wire_id: int):
	var items: Array = definitions.get("items", [])
	return items[wire_id] if wire_id >= 0 and wire_id < items.size() else null

func definition_by_id(definition_id: String):
	for group in [definitions.get("items", []), definitions.get("resources", [])]:
		for definition in group:
			if str(definition.get("id", "")) == definition_id:
				return definition
	return null
