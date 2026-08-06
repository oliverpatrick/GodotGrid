class_name UseTargeting
extends RefCounted

var _source_slot := -1

func select_source(slot: int) -> void:
	_source_slot = slot

func source_slot() -> int:
	return _source_slot

func take_source() -> int:
	var result := _source_slot
	_source_slot = -1
	return result

func cancel() -> void:
	_source_slot = -1

func active() -> bool:
	return _source_slot >= 0
