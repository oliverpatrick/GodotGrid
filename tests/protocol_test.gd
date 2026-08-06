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
	var spawn_bytes: PackedByteArray = str(vectors[5].hex).hex_decode()
	var spawn_frame = Protocol.decode_frame(spawn_bytes)
	var spawn = Protocol.decode_message(spawn_frame.id, spawn_frame.payload)
	if spawn == null or spawn.entity != 42 or spawn.x != 80 or spawn.name != "tree":
		return false
	var action = Protocol.decode_message(Protocol.PLAYER_ACTION, PackedByteArray([0, 0, 0, 42, 1]))
	if action != {"entity": 42, "action": 1}:
		return false
	return Protocol.decode_message(Protocol.PLAYER_ACTION, PackedByteArray([0, 0, 0, 42, 2])) == null
