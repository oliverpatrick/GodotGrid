extends RefCounted

const NetworkClient = preload("res://network/network_client.gd")

static func run() -> bool:
	var client: Node = NetworkClient.new()
	var connect: PackedByteArray = client.build_connect_frame("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ")
	var hello: PackedByteArray = client.build_content_hello("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef")
	var ok: bool = connect.size() == 48 and connect[0] == 0 and connect[1] == 1 and connect[2] == 0 and connect[3] == 44
	ok = ok and hello.size() == 36 and hello[0] == 0 and hello[1] == 2 and hello[2] == 0 and hello[3] == 32
	if client.next_world_sequence() != 1 or client.next_world_sequence() != 2:
		printerr("world sequence did not increase from one")
		client.free()
		return false
	client.connect_to_world("127.0.0.1", 1, "", "")
	if client.next_world_sequence() != 1:
		printerr("world sequence did not reset for a new connection")
		client.close()
		client.free()
		return false
	client.close()
	client.free()
	return ok
