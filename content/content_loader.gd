class_name ContentLoader
extends RefCounted

const ContentBundle = preload("res://content/content_manifest.gd")
static var last_error := ""

static func load_bundle(root: String):
	last_error = ""
	var manifest_path := root.path_join("source/world/manifest.json")
	var definitions_path := root.path_join("source/definitions.json")
	var manifest = _read_json(manifest_path)
	var definitions = _read_json(definitions_path)
	if not manifest is Dictionary or not definitions is Dictionary:
		return _fail("content manifest or definitions are invalid")
	if manifest.get("region_size") != 64 or manifest.get("regions_x") != 4 or manifest.get("regions_z") != 4 or manifest.get("planes") != 4:
		return _fail("unsupported world dimensions")
	var references: Array = manifest.get("regions", [])
	if references.size() != 64:
		return _fail("expected 64 region references")
	var bundle = ContentBundle.new()
	bundle.root = root
	bundle.manifest = manifest
	bundle.definitions = definitions
	bundle.gameplay_hash = str(manifest.get("gameplay_hash", ""))
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(_canonical_json(definitions).to_utf8_buffer())
	for reference in references:
		if not reference is Dictionary:
			return _fail("invalid region reference")
		var relative_path := str(reference.get("path", ""))
		if relative_path.is_empty() or relative_path.is_absolute_path() or ".." in relative_path:
			return _fail("unsafe region path")
		var region = _read_json(root.path_join("source/world").path_join(relative_path))
		if not _valid_region(region, reference):
			return _fail("invalid region %s" % relative_path)
		var key := "%d:%d:%d" % [reference.x, reference.z, reference.plane]
		if bundle.regions.has(key):
			return _fail("duplicate region %s" % key)
		bundle.regions[key] = region
		hash_context.update(relative_path.to_utf8_buffer())
		hash_context.update(_canonical_json(region).to_utf8_buffer())
	if hash_context.finish().hex_encode() != bundle.gameplay_hash:
		return _fail("gameplay content hash mismatch")
	if not _edges_match(bundle.regions):
		return _fail("region height seam mismatch")
	return bundle

static func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))

static func _valid_region(region, reference: Dictionary) -> bool:
	if not region is Dictionary:
		return false
	if region.get("x") != reference.get("x") or region.get("z") != reference.get("z") or region.get("plane") != reference.get("plane"):
		return false
	if region.get("width") != 64 or region.get("depth") != 64:
		return false
	if region.plane == 0:
		var heights: Array = region.get("heights", [])
		if heights.size() != 65:
			return false
		for row in heights:
			if not row is Array or row.size() != 65:
				return false
	elif not region.get("objects", []).is_empty() or region.get("walkable_fill", false):
		return false
	return true

static func _edges_match(regions: Dictionary) -> bool:
	for z in range(4):
		for x in range(4):
			var current: Dictionary = regions["%d:%d:0" % [x, z]]
			if x < 3:
				var right: Dictionary = regions["%d:%d:0" % [x + 1, z]]
				for sample in range(65):
					if current.heights[sample][64] != right.heights[sample][0]:
						return false
			if z < 3:
				var below: Dictionary = regions["%d:%d:0" % [x, z + 1]]
				for sample in range(65):
					if current.heights[64][sample] != below.heights[0][sample]:
						return false
	return true

static func _canonical_json(value) -> String:
	if value is Dictionary:
		var keys: Array = value.keys()
		keys.sort()
		var parts: PackedStringArray = []
		for key in keys:
			parts.append(JSON.stringify(str(key)) + ":" + _canonical_json(value[key]))
		return "{" + ",".join(parts) + "}"
	if value is Array:
		var parts: PackedStringArray = []
		for item in value:
			parts.append(_canonical_json(item))
		return "[" + ",".join(parts) + "]"
	# Godot parses every JSON number as a float, while Go's canonical encoder
	# preserves integral number spelling. Content coordinates and definitions are
	# integral, so normalise them before hashing.
	if value is float and value == floor(value):
		return str(int(value))
	return JSON.stringify(value)

static func _fail(message: String):
	last_error = message
	return null
