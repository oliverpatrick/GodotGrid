extends RefCounted

const AuthClient = preload("res://network/auth_client.gd")

static func run() -> bool:
	var body: String = AuthClient.build_login_body(" Player@Example.com ", "password")
	var decoded = JSON.parse_string(body)
	return decoded is Dictionary and decoded.email == "player@example.com" and decoded.password == "password"
