extends RefCounted

const Protocol = preload("res://network/protocol.gd")

static func run() -> bool:
	var root := OS.get_environment("GAME_CONTENT_ROOT")
	var vectors = JSON.parse_string(FileAccess.get_file_as_string(root.path_join("protocol/golden.json")))
	if not vectors is Array:
		return false
	for vector in vectors:
		var bytes: PackedByteArray = str(vector.hex).hex_decode()
		var frame = Protocol.decode_frame(bytes)
		if frame == null or Protocol.encode_frame(frame.id, frame.payload) != bytes:
			return false
	var move: PackedByteArray = Protocol.encode_move(80, 81, 0, 1, 7)
	if move.hex_encode() != vectors[0].hex:
		return false
	var requests := [
		[Protocol.encode_inspect_world(0x8000002a), "001300048000002a"],
		[Protocol.encode_inspect_inventory(3), "0014000103"],
		[Protocol.encode_use_inventory(3, 4), "001500020304"],
		[Protocol.encode_use_world(3, 0x8000002a, 9), "00160009038000002a00000009"],
	]
	for request in requests:
		if request[0].hex_encode() != request[1]:
			return false
	var spawn_bytes: PackedByteArray = str(vectors[5].hex).hex_decode()
	var spawn_frame = Protocol.decode_frame(spawn_bytes)
	var spawn = Protocol.decode_message(spawn_frame.id, spawn_frame.payload)
	if spawn == null or spawn.entity != 42 or spawn.x != 80 or spawn.name != "tree" or spawn.definition_id != "resource.mutated_tree":
		return false
	var action = Protocol.decode_message(Protocol.PLAYER_ACTION, PackedByteArray([0, 0, 0, 42, 1]))
	if action != {"entity": 42, "action": 1}:
		return false
	return Protocol.decode_message(Protocol.PLAYER_ACTION, PackedByteArray([0, 0, 0, 42, 2])) == null
