class_name AuthClient
extends Node

signal login_succeeded(ticket: Dictionary)
signal login_failed(message: String)

var request: HTTPRequest

static func build_login_body(email: String, password: String) -> String:
	return JSON.stringify({"email": email.strip_edges().to_lower(), "password": password})

func login(base_url: String, email: String, password: String) -> void:
	if request != null:
		request.queue_free()
	request = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_request_completed)
	var error := request.request(
		base_url.trim_suffix("/") + "/v1/login",
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		build_login_body(email, password)
	)
	if error != OK:
		login_failed.emit("Unable to contact login server")

func _on_request_completed(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		login_failed.emit("Unable to contact login server")
		return
	if status != 200:
		login_failed.emit("Login failed (%d)" % status)
		return
	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response is Dictionary or str(response.get("ticket", "")).length() != 43:
		login_failed.emit("Invalid login response")
		return
	login_succeeded.emit(response)
