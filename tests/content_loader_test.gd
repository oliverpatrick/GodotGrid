extends RefCounted

const ContentLoader = preload("res://content/content_loader.gd")

static func run() -> bool:
	var root := OS.get_environment("GAME_CONTENT_ROOT")
	if root.is_empty():
		printerr("GAME_CONTENT_ROOT is required")
		return false
	var bundle = ContentLoader.load_bundle(root)
	if bundle == null:
		printerr(ContentLoader.last_error)
		return false
	var axe = bundle.item_by_wire_id(0)
	var log = bundle.item_by_wire_id(1)
	var bones = bundle.definition_by_id("item.bones")
	var coins = bundle.definition_by_id("item.coins")
	var tree = bundle.definition_by_id("resource.mutated_tree")
	var man = bundle.npc_by_id("npc.man")
	return bundle.regions.size() == 64 and bundle.gameplay_hash.length() == 64 \
		and axe.perception_xp == 10 and axe.droppable and axe.value == 10 \
		and log.perception_xp == 10 and log.droppable and log.value == 3 \
		and bones.value == 2 and not bones.stackable \
		and coins.value == 1 and coins.stackable \
		and tree.perception_xp == 10 and not str(tree.inspect_text).is_empty() \
		and man.name == "Man" and man.home == {"x": 85.0, "z": 85.0, "plane": 0.0} \
		and man.combat.health == 7 and man.combat.drop_table_id == "drop.man" \
		and man.presentation.model_id == "model.player" \
		and man.presentation.aggressive_animation == "Punch_Cross" \
		and man.presentation.defensive_animation == "Punch_Jab" \
		and man.presentation.death_animation == "Death01"
