class_name GameNetworkClient
extends Node

const Protocol = preload("uid://bvppiqbq80y0l") # network/protocol.gd

signal connected(entity: int)
signal disconnected(reason: String)
signal message_received(id: int, message: Variant)
signal content_mismatch

var peer := StreamPeerTCP.new()
var receive_buffer := PackedByteArray()
var _ticket := ""
var _content_hash := ""
var _handshake_sent := false
var entity_id := 0
var _was_transport_connected := false
var _disconnect_reported := false
var _world_sequence := 0

func connect_to_world(host: String, port: int, ticket: String, content_hash: String) -> Error:
	_world_sequence = 0
	_ticket = ticket
	_content_hash = content_hash
	_handshake_sent = false
	_was_transport_connected = false
	_disconnect_reported = false
	entity_id = 0
	receive_buffer.clear()
	return peer.connect_to_host(host, port)

func next_world_sequence() -> int:
	_world_sequence += 1
	return _world_sequence

func _process(_delta: float) -> void:
	peer.poll()
	var status := peer.get_status()
	if status == StreamPeerTCP.STATUS_CONNECTED and not _handshake_sent:
		_was_transport_connected = true
		peer.put_data(build_connect_frame(_ticket))
		peer.put_data(build_content_hello(_content_hash))
		_handshake_sent = true
	elif status == StreamPeerTCP.STATUS_ERROR:
		_report_disconnect("Connection failed")
	elif status == StreamPeerTCP.STATUS_NONE and _was_transport_connected:
		if entity_id == 0:
			content_mismatch.emit()
			_report_disconnect("Content mismatch or rejected session")
		else:
			_report_disconnect("Disconnected from world")
	if status != StreamPeerTCP.STATUS_CONNECTED:
		return
	var available := peer.get_available_bytes()
	if available > 0:
		var result := peer.get_data(available)
		if result[0] == OK:
			receive_buffer.append_array(result[1])
			_drain_frames()

func build_connect_frame(ticket: String) -> PackedByteArray:
	var ticket_bytes := ticket.to_utf8_buffer()
	if ticket_bytes.size() != 43:
		return PackedByteArray()
	var payload := PackedByteArray([43])
	payload.append_array(ticket_bytes)
	return Protocol.encode_frame(Protocol.CONNECT, payload)

func build_content_hello(content_hash: String) -> PackedByteArray:
	var digest := content_hash.hex_decode()
	if digest.size() != 32:
		return PackedByteArray()
	return Protocol.encode_frame(Protocol.CONTENT_HELLO, digest)

func send_frame(frame: PackedByteArray) -> Error:
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED or frame.is_empty():
		return ERR_UNAVAILABLE
	return peer.put_data(frame)

func close() -> void:
	peer.disconnect_from_host()

func _report_disconnect(reason: String) -> void:
	if _disconnect_reported:
		return
	_disconnect_reported = true
	disconnected.emit(reason)
	set_process(false)

func _drain_frames() -> void:
	while receive_buffer.size() >= 4:
		var payload_size := (receive_buffer[2] << 8) | receive_buffer[3]
		if payload_size > Protocol.MAX_PAYLOAD:
			close()
			disconnected.emit("Invalid server frame")
			return
		var frame_size := 4 + payload_size
		if receive_buffer.size() < frame_size:
			return
		var frame_bytes := receive_buffer.slice(0, frame_size)
		receive_buffer = receive_buffer.slice(frame_size)
		var frame = Protocol.decode_frame(frame_bytes)
		var message = Protocol.decode_message(frame.id, frame.payload)
		if frame.id == Protocol.CONNECT_ACK and message != null:
			entity_id = message.entity
			connected.emit(entity_id)
		message_received.emit(frame.id, message)
