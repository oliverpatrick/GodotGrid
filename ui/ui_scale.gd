class_name UIScale
extends RefCounted

const REFERENCE_SIZE := Vector2(1280.0, 720.0)
const MIN_USER_SCALE := 0.8
const MAX_USER_SCALE := 2.0

static func parse_override(text: String) -> float:
	var value := text.strip_edges()
	if value.is_empty() or not value.is_valid_float():
		return 1.0
	return clampf(value.to_float() / 100.0, MIN_USER_SCALE, MAX_USER_SCALE)

static func safe_layout(viewport_size: Vector2i, safe_rect: Rect2i, user_scale: float) -> Dictionary:
	var viewport := Rect2(Vector2.ZERO, Vector2(viewport_size))
	var safe := Rect2(safe_rect).intersection(viewport)
	if safe.size.x <= 0.0 or safe.size.y <= 0.0:
		safe = viewport
	var base_scale := minf(float(viewport_size.x) / REFERENCE_SIZE.x, float(viewport_size.y) / REFERENCE_SIZE.y)
	var scale := maxf(base_scale, 0.001) * clampf(user_scale, MIN_USER_SCALE, MAX_USER_SCALE)
	var margin := 18.0 * scale
	var content := safe.grow(-margin)
	var inventory_size := Vector2(292.0, 326.0) * scale
	var skill_size := Vector2(172.0, 68.0) * scale
	var chat_size := Vector2(468.0, 202.0) * scale
	inventory_size = inventory_size.min(content.size)
	chat_size.x = minf(chat_size.x, maxf(0.0, content.size.x - inventory_size.x - margin))
	chat_size.y = minf(chat_size.y, content.size.y)
	skill_size = skill_size.min(content.size)
	var inventory := Rect2(Vector2(content.end.x - inventory_size.x, content.position.y), inventory_size)
	var skill := Rect2(content.position, skill_size)
	var chat := Rect2(Vector2(content.position.x, content.end.y - chat_size.y), chat_size)
	return {
		"logical_scale": scale,
		"content_rect": content,
		"skill_rect": skill,
		"inventory_rect": inventory,
		"chat_rect": chat,
		"minimum_control_size": Vector2(48.0, 48.0) * maxf(scale, 1.0),
	}
