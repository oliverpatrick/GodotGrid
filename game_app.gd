extends "res://terrain_generator.gd"

const ContentLoaderScript = preload("res://content/content_loader.gd")
const Protocol = preload("res://network/protocol.gd")
signal local_system_message(text: String)

@export var auth_url := "http://127.0.0.1:8080"
@export var world_host := "127.0.0.1"
@export var world_port := 7777

@onready var auth_client: Node = $AuthClient
@onready var network_client: Node = $NetworkClient
@onready var login_screen: CanvasLayer = $LoginScreen
@onready var player_registry: Node3D = $PlayerRegistry
@onready var click_to_move: Node = $ClickToMove
@onready var follow_camera: Camera3D = $FollowCamera
var resolved_content_root := ""

func _ready() -> void:
	resolved_content_root = content_root
	if resolved_content_root.is_empty():
		resolved_content_root = OS.get_environment("GAME_CONTENT_ROOT")
	var configured_auth := OS.get_environment("AUTH_HTTP_URL")
	if not configured_auth.is_empty():
		auth_url = configured_auth
	var configured_host := OS.get_environment("WORLD_HOST")
	if not configured_host.is_empty():
		world_host = configured_host
	var configured_port := OS.get_environment("WORLD_PORT")
	if configured_port.is_valid_int():
		world_port = configured_port.to_int()
	if resolved_content_root.is_empty():
		login_screen.show_error("Game content is not configured")
		return
	content_bundle = ContentLoaderScript.load_bundle(resolved_content_root)
	if content_bundle == null:
		login_screen.show_error("Game content failed validation")
		return
	login_screen.submitted.connect(_on_login_submitted)
	auth_client.login_succeeded.connect(_on_login_succeeded)
	auth_client.login_failed.connect(login_screen.show_error)
	network_client.connected.connect(_on_world_connected)
	network_client.disconnected.connect(login_screen.show_error)
	network_client.message_received.connect(player_registry.handle_message)
	network_client.message_received.connect(_on_world_message)
	player_registry.local_player_ready.connect(follow_camera.configure)
	click_to_move.system_message.connect(local_system_message.emit)

func _on_login_submitted(email: String, password: String) -> void:
	auth_client.login(auth_url, email, password)

func _on_login_succeeded(ticket: Dictionary) -> void:
	var error: Error = network_client.connect_to_world(world_host, world_port, str(ticket.ticket), content_bundle.gameplay_hash)
	if error != OK:
		login_screen.show_error("Unable to connect to world")

func _on_world_connected(_entity: int) -> void:
	if load_world(resolved_content_root, false):
		var tick_seconds := 0.6
		var configured_tick := OS.get_environment("WORLD_TICK_MS")
		if configured_tick.is_valid_int():
			tick_seconds = configured_tick.to_float() / 1000.0
		player_registry.configure(content_bundle, network_client.entity_id, tick_seconds)
		click_to_move.configure(follow_camera, stream, network_client)
		login_screen.hide()
	else:
		login_screen.show_error("Unable to load world")

func _on_world_message(id: int, message) -> void:
	if stream == null or message == null:
		return
	if id == Protocol.REGION_LOAD:
		stream.load_region("%d:%d:%d" % [message.x, message.z, message.plane])
	elif id == Protocol.REGION_UNLOAD:
		stream.unload_region("%d:%d:%d" % [message.x, message.z, message.plane])
