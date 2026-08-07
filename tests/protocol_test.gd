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
	for action_id in range(5):
		var action = Protocol.decode_message(Protocol.PLAYER_ACTION, PackedByteArray([0, 0, 0, 42, action_id]))
		if action != {"entity": 42, "action": action_id}:
			return false
	if Protocol.decode_message(Protocol.PLAYER_ACTION, PackedByteArray([0, 0, 0, 42, 5])) != null:
		return false
	var face = Protocol.decode_message(Protocol.ENTITY_FACE, PackedByteArray([0, 0, 0, 42, 0x80, 0, 0, 42]))
	if face != {"entity": 42, "target": 0x8000002a}:
		return false
	var health = Protocol.decode_message(Protocol.ENTITY_HEALTH, PackedByteArray([0, 0, 0, 42, 0, 0, 0, 7, 0, 0, 0, 10]))
	if health != {"entity": 42, "hp": 7, "maximum": 10}:
		return false
	var hit = Protocol.decode_message(Protocol.ENTITY_HIT, PackedByteArray([0x80, 0, 0, 42, 0, 0, 0, 1]))
	if hit != {"target": 0x8000002a, "damage": 1}:
		return false
	var dialogue_bytes := "Hello there.".to_utf8_buffer()
	var dialogue_payload := PackedByteArray([0x80, 0, 0, 42, dialogue_bytes.size()])
	dialogue_payload.append_array(dialogue_bytes)
	var dialogue = Protocol.decode_message(Protocol.DIALOGUE, dialogue_payload)
	if dialogue != {"speaker": 0x8000002a, "text": "Hello there."}:
		return false
	var malformed_dialogues := [
		PackedByteArray([0, 0, 0, 42, 0]),
		PackedByteArray([0, 0, 0, 42, 2, 65]),
		PackedByteArray([0, 0, 0, 42, 1, 65, 66]),
		PackedByteArray([0, 0, 0, 42, 1, 0xff]),
	]
	for malformed in malformed_dialogues:
		if Protocol.decode_message(Protocol.DIALOGUE, malformed) != null:
			return false
	return true
