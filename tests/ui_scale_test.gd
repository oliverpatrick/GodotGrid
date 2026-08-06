extends RefCounted

const UIScale = preload("res://ui/ui_scale.gd")

static func run() -> bool:
	if UIScale.parse_override("") != 1.0 or UIScale.parse_override("invalid") != 1.0:
		return false
	if UIScale.parse_override("250") != 2.0 or UIScale.parse_override("40") != 0.8:
		return false
	var cases := [
		[Vector2i(1280, 720), Rect2i(0, 0, 1280, 720)],
		[Vector2i(1280, 800), Rect2i(0, 0, 1280, 800)],
		[Vector2i(1920, 1080), Rect2i(0, 0, 1920, 1080)],
		[Vector2i(2400, 1080), Rect2i(80, 0, 2240, 1080)],
		[Vector2i(5120, 2880), Rect2i(0, 0, 5120, 2880)],
	]
	for item in cases:
		var layout := UIScale.safe_layout(item[0], item[1], 1.0)
		if not layout.content_rect.encloses(layout.chat_rect):
			return false
		if not layout.content_rect.encloses(layout.inventory_rect):
			return false
		if not layout.content_rect.encloses(layout.skill_rect):
			return false
		if not layout.content_rect.encloses(layout.run_rect):
			printerr("run control outside safe content at %s" % item[0])
			return false
		if layout.run_rect.intersects(layout.skill_rect) or layout.run_rect.intersects(layout.inventory_rect) or layout.run_rect.intersects(layout.chat_rect):
			printerr("run control overlaps HUD at %s" % item[0])
			return false
		if layout.run_rect.size.x < layout.minimum_control_size.x or layout.run_rect.size.y < layout.minimum_control_size.y:
			printerr("run control is below minimum touch size at %s" % item[0])
			return false
		if layout.chat_rect.intersects(layout.inventory_rect):
			return false
		if layout.minimum_control_size.x < 48.0 or layout.minimum_control_size.y < 48.0:
			return false
	var hd := UIScale.safe_layout(Vector2i(1920, 1080), Rect2i(0, 0, 1920, 1080), 1.0)
	if hd.logical_scale < 1.0:
		return false
	var mobile := UIScale.safe_layout(Vector2i(2400, 1080), Rect2i(80, 0, 2240, 1080), 1.0)
	return mobile.content_rect.position.x >= 80
