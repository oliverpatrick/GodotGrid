extends RefCounted

const ContentLoader = preload("res://content/content_loader.gd")
const RegionMeshBuilder = preload("res://world/region_mesh_builder.gd")

static func run() -> bool:
	var bundle = ContentLoader.load_bundle(OS.get_environment("GAME_CONTENT_ROOT"))
	if bundle == null:
		return false
	var region: Dictionary = bundle.regions["0:0:0"]
	var instance := RegionMeshBuilder.build(region)
	if instance == null or instance.mesh == null:
		return false
	var arrays := instance.mesh.surface_get_arrays(0)
	var ok: bool = arrays[Mesh.ARRAY_VERTEX].size() == 4225 and arrays[Mesh.ARRAY_INDEX].size() == 24576
	instance.free()
	return ok
