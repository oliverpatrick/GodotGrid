extends RefCounted

static func create(next_label: String, next_action_id: String, next_children: Array = []) -> Dictionary:
	return {"label": next_label, "action_id": next_action_id, "children": next_children}
