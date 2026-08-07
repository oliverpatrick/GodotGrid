class_name GameProtocol
extends RefCounted

const MAX_PAYLOAD := 32768
const CONNECT := 0x0001
const CONTENT_HELLO := 0x0002
const MOVE_REQUEST := 0x0010
const INTERACT := 0x0011
const DROP_ITEM := 0x0012
const INSPECT_WORLD := 0x0013
const INSPECT_INVENTORY := 0x0014
const USE_INVENTORY := 0x0015
const USE_WORLD := 0x0016
const CHAT := 0x0020
const SET_COMBAT_STYLE := 0x0021
const CONNECT_ACK := 0x0101
const ENTITY_SPAWN := 0x0103
const ENTITY_DESPAWN := 0x0104
const ENTITY_MOVE := 0x0105
const CHAT_MESSAGE := 0x0106
const REGION_LOAD := 0x0110
const REGION_UNLOAD := 0x0111
const INVENTORY := 0x0120
const SKILL := 0x0121
const GROUND_ITEM := 0x0122
const SYSTEM_MESSAGE := 0x0123
const RESOURCE_STATE := 0x0124
const PLAYER_ACTION := 0x0125
const ENTITY_FACE := 0x0126
const ENTITY_HEALTH := 0x0127
const ENTITY_HIT := 0x0128
const DIALOGUE := 0x0129
const COMBAT_STYLE := 0x012A

const COMBAT_STYLE_AGGRESSIVE := 0
const COMBAT_STYLE_DEFENSIVE := 1

const SKILL_HEALTH := 0
const SKILL_ATTACK := 1
const SKILL_DEFENCE := 2
const SKILL_HARVESTING := 3
const SKILL_PERCEPTION := 4

static func encode_frame(id: int, payload: PackedByteArray) -> PackedByteArray:
	if payload.size() > MAX_PAYLOAD:
		return PackedByteArray()
	var result := PackedByteArray()
	_put_u16(result, id)
	_put_u16(result, payload.size())
	result.append_array(payload)
	return result

static func decode_frame(data: PackedByteArray):
	if data.size() < 4:
		return null
	var size := _u16(data, 2)
	if size > MAX_PAYLOAD or data.size() != 4 + size:
		return null
	return {"id": _u16(data, 0), "payload": data.slice(4)}

static func encode_move(x: int, z: int, plane: int, mode: int, sequence: int) -> PackedByteArray:
	if plane < 0 or plane > 3 or mode < 0 or mode > 1:
		return PackedByteArray()
	var payload := PackedByteArray()
	_put_u32(payload, x)
	_put_u32(payload, z)
	payload.append(plane)
	payload.append(mode)
	_put_u32(payload, sequence)
	return encode_frame(MOVE_REQUEST, payload)

static func encode_interaction(target: int, action: int, sequence: int) -> PackedByteArray:
	if action < 0 or action > 1:
		return PackedByteArray()
	var payload := PackedByteArray()
	_put_u32(payload, target)
	payload.append(action)
	_put_u32(payload, sequence)
	return encode_frame(INTERACT, payload)

static func encode_drop(slot: int, quantity: int, sequence: int) -> PackedByteArray:
	if slot < 0 or slot >= 30 or quantity <= 0 or quantity > 65535:
		return PackedByteArray()
	var payload := PackedByteArray([slot])
	_put_u16(payload, quantity)
	_put_u32(payload, sequence)
	return encode_frame(DROP_ITEM, payload)

static func encode_inspect_world(target: int) -> PackedByteArray:
	if (target & 0x80000000) == 0:
		return PackedByteArray()
	var payload := PackedByteArray(); _put_u32(payload, target)
	return encode_frame(INSPECT_WORLD, payload)

static func encode_inspect_inventory(slot: int) -> PackedByteArray:
	if slot < 0 or slot >= 30:
		return PackedByteArray()
	return encode_frame(INSPECT_INVENTORY, PackedByteArray([slot]))

static func encode_use_inventory(source_slot: int, target_slot: int) -> PackedByteArray:
	if source_slot < 0 or source_slot >= 30 or target_slot < 0 or target_slot >= 30:
		return PackedByteArray()
	return encode_frame(USE_INVENTORY, PackedByteArray([source_slot, target_slot]))

static func encode_use_world(source_slot: int, target: int, sequence: int) -> PackedByteArray:
	if source_slot < 0 or source_slot >= 30 or (target & 0x80000000) == 0:
		return PackedByteArray()
	var payload := PackedByteArray([source_slot]); _put_u32(payload, target); _put_u32(payload, sequence)
	return encode_frame(USE_WORLD, payload)

static func encode_chat(text: String) -> PackedByteArray:
	var bytes := text.to_utf8_buffer()
	if bytes.is_empty() or bytes.size() > 160:
		return PackedByteArray()
	var payload := PackedByteArray([bytes.size()])
	payload.append_array(bytes)
	return encode_frame(CHAT, payload)

static func encode_combat_style(style: int) -> PackedByteArray:
	if style < COMBAT_STYLE_AGGRESSIVE or style > COMBAT_STYLE_DEFENSIVE:
		return PackedByteArray()
	return encode_frame(SET_COMBAT_STYLE, PackedByteArray([style]))

static func decode_message(id: int, payload: PackedByteArray):
	match id:
		CONNECT_ACK, ENTITY_DESPAWN:
			if payload.size() != 4:
				return null
			return {"entity": _u32(payload, 0)}
		REGION_LOAD, REGION_UNLOAD:
			if payload.size() != 5 or payload[4] > 3:
				return null
			return {"x": _s16(payload, 0), "z": _s16(payload, 2), "plane": payload[4]}
		ENTITY_SPAWN:
			if payload.size() < 16 or payload[13] > 3:
				return null
			var name_end := 16 + payload[14]
			var definition_end := name_end + payload[15]
			if definition_end != payload.size():
				return null
			return {"entity": _u32(payload, 0), "type": payload[4], "x": _s32(payload, 5), "z": _s32(payload, 9), "plane": payload[13], "name": payload.slice(16, name_end).get_string_from_utf8(), "definition_id": payload.slice(name_end, definition_end).get_string_from_utf8()}
		ENTITY_MOVE:
			if payload.size() != 13 or payload[12] > 3:
				return null
			return {"entity": _u32(payload, 0), "x": _s32(payload, 4), "z": _s32(payload, 8), "plane": payload[12]}
		CHAT_MESSAGE:
			if payload.size() < 5 or payload[4] > 160 or payload.size() != 5 + payload[4]:
				return null
			return {"sender": _u32(payload, 0), "text": payload.slice(5).get_string_from_utf8()}
		INVENTORY:
			if payload.is_empty() or payload[0] > 30 or payload.size() != 1 + payload[0] * 5:
				return null
			var slots: Array = []
			for index in range(payload[0]):
				var offset := 1 + index * 5
				if payload[offset] >= 30 or _u16(payload, offset + 3) == 0:
					return null
				slots.append({"slot": payload[offset], "item": _u16(payload, offset + 1), "quantity": _u16(payload, offset + 3)})
			return {"slots": slots}
		SKILL:
			if payload.size() != 9:
				return null
			return {"skill": payload[0], "xp": _u64(payload, 1)}
		GROUND_ITEM:
			if payload.size() != 8:
				return null
			var quantity := _u32(payload, 4)
			if quantity == 0:
				return null
			return {"entity": _u32(payload, 0), "quantity": quantity}
		SYSTEM_MESSAGE:
			if payload.is_empty() or payload[0] > 160 or payload.size() != 1 + payload[0]:
				return null
			return {"text": payload.slice(1).get_string_from_utf8()}
		RESOURCE_STATE:
			if payload.size() != 7:
				return null
			return {"entity": _u32(payload, 0), "state": payload[4], "remaining": _u16(payload, 5)}
		PLAYER_ACTION:
			if payload.size() != 5 or payload[4] > 4:
				return null
			return {"entity": _u32(payload, 0), "action": payload[4]}
		ENTITY_FACE:
			if payload.size() != 8:
				return null
			return {"entity": _u32(payload, 0), "target": _u32(payload, 4)}
		ENTITY_HEALTH:
			if payload.size() != 12:
				return null
			return {"entity": _u32(payload, 0), "hp": _u32(payload, 4), "maximum": _u32(payload, 8)}
		ENTITY_HIT:
			if payload.size() != 8:
				return null
			return {"target": _u32(payload, 0), "damage": _u32(payload, 4)}
		DIALOGUE:
			if payload.size() < 5 or payload[4] == 0 or payload.size() != 5 + payload[4]:
				return null
			var bytes := payload.slice(5)
			var text = _strict_utf8(bytes)
			if text == null:
				return null
			return {"speaker": _u32(payload, 0), "text": text}
		COMBAT_STYLE:
			if payload.size() != 1 or payload[0] > COMBAT_STYLE_DEFENSIVE:
				return null
			return {"style": payload[0]}
	return null

static func _strict_utf8(bytes: PackedByteArray):
	var text := bytes.get_string_from_utf8()
	if text.to_utf8_buffer() != bytes:
		return null
	return text

static func _put_u16(bytes: PackedByteArray, value: int) -> void:
	bytes.append((value >> 8) & 0xff)
	bytes.append(value & 0xff)

static func _put_u32(bytes: PackedByteArray, value: int) -> void:
	bytes.append((value >> 24) & 0xff)
	bytes.append((value >> 16) & 0xff)
	bytes.append((value >> 8) & 0xff)
	bytes.append(value & 0xff)

static func _u16(bytes: PackedByteArray, offset: int) -> int:
	return (bytes[offset] << 8) | bytes[offset + 1]

static func _s16(bytes: PackedByteArray, offset: int) -> int:
	var value := _u16(bytes, offset)
	return value - 65536 if value >= 32768 else value

static func _u32(bytes: PackedByteArray, offset: int) -> int:
	return (bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3]

static func _s32(bytes: PackedByteArray, offset: int) -> int:
	var value := _u32(bytes, offset)
	return value - 4294967296 if value >= 2147483648 else value

static func _u64(bytes: PackedByteArray, offset: int) -> int:
	return (_u32(bytes, offset) << 32) | _u32(bytes, offset + 4)
