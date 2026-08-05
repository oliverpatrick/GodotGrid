extends RefCounted

const ContentLoader = preload("res://content/content_loader.gd")
const SelectionFeedback = preload("res://gameplay/selection_feedback.gd")

static func run() -> bool:
	var bundle = ContentLoader.load_bundle(OS.get_environment("GAME_CONTENT_ROOT"))
	var feedback := SelectionFeedback.new()
	feedback.configure(bundle)
	feedback.select_tile(Vector3i(80, 0, 81))
	if feedback.selection_kind != "tile" or feedback.marker == null:
		feedback.free()
		return false
	if not is_equal_approx(feedback.marker.position.x, 80.5) or not is_equal_approx(feedback.marker.position.z, 81.5):
		feedback.free()
		return false
	var tree := Node3D.new()
	feedback.add_child(tree)
	feedback.select_object(tree)
	if feedback.selection_kind != "object" or feedback.marker.get_parent() != tree:
		feedback.free()
		return false
	feedback.select_tile(Vector3i(82, 0, 83))
	var ok := feedback.selection_kind == "tile" and feedback.marker.get_parent() == feedback
	feedback.free()
	return ok
