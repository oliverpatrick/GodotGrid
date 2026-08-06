extends "res://terrain_generator.gd"

const ContentLoaderScript = preload("res://content/content_loader.gd")
const Protocol = preload("res://network/protocol.gd")
const ContextActions = preload("res://gameplay/context_actions.gd")
const UseTargeting = preload("res://gameplay/use_targeting.gd")
const ContextMenuScene = preload("res://ui/context_menu.tscn")
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
@onready var object_registry: Node3D = $ObjectRegistry
@onready var interaction_controller: Node = $InteractionController
@onready var selection_feedback: Node3D = $SelectionFeedback
@onready var hud: CanvasLayer = $HUD
var context_menu: PopupMenu
var resolved_content_root := ""
var use_targeting = UseTargeting.new()
var _context_kind := ""
var _context_entity := 0
var _context_slot := -1

func _ready() -> void:
	context_menu = ContextMenuScene.instantiate()
	add_child(context_menu)
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
	selection_feedback.configure(content_bundle)
	login_screen.submitted.connect(_on_login_submitted)
	auth_client.login_succeeded.connect(_on_login_succeeded)
	auth_client.login_failed.connect(login_screen.show_error)
	network_client.connected.connect(_on_world_connected)
	network_client.disconnected.connect(login_screen.show_error)
	network_client.message_received.connect(player_registry.handle_message)
	network_client.message_received.connect(object_registry.handle_message)
	network_client.message_received.connect(hud.handle_message)
	network_client.message_received.connect(_on_world_message)
	player_registry.local_player_ready.connect(follow_camera.configure)
	click_to_move.system_message.connect(local_system_message.emit)
	click_to_move.system_message.connect(hud.add_system_message)
	click_to_move.system_message.connect(func(_text: String): _cancel_use())
	click_to_move.entity_clicked.connect(_on_entity_clicked)
	click_to_move.context_requested.connect(_on_world_context_requested)
	click_to_move.destination_requested.connect(_on_destination_requested)
	context_menu.action_selected.connect(_on_context_action)
	hud.inventory.context_requested.connect(_on_inventory_context_requested)
	hud.inventory.slot_clicked.connect(_on_inventory_slot_clicked)
	wire_run_toggle(hud, click_to_move)
	var automatic_email := OS.get_environment("MVP_EMAIL")
	var automatic_password := OS.get_environment("MVP_PASSWORD")
	if not automatic_email.is_empty() and not automatic_password.is_empty():
		_on_login_submitted.call_deferred(automatic_email, automatic_password)

static func wire_run_toggle(hud_node, movement) -> void:
	hud_node.run_toggled.connect(movement.set_run_enabled)
	movement.set_run_enabled(hud_node.is_run_enabled())

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
		object_registry.configure(content_bundle)
		interaction_controller.configure(network_client)
		click_to_move.configure(follow_camera, stream, network_client)
		hud.configure(content_bundle)
		login_screen.hide()
		hud.show()
	else:
		login_screen.show_error("Unable to load world")

func _on_world_message(id: int, message) -> void:
	if stream == null or message == null:
		return
	if id == Protocol.REGION_LOAD:
		stream.load_region("%d:%d:%d" % [message.x, message.z, message.plane])
	elif id == Protocol.REGION_UNLOAD:
		stream.unload_region("%d:%d:%d" % [message.x, message.z, message.plane])

func _on_entity_selected(entity: int) -> void:
	var object = object_registry.object_for(entity)
	if object != null:
		selection_feedback.select_object(object)

func _on_entity_clicked(entity: int) -> void:
	_on_entity_selected(entity)
	if use_targeting.active():
		interaction_controller.use_world(use_targeting.take_source(), entity)
		hud.inventory.set_selected_slot(-1)
	else:
		interaction_controller.interact(entity)

func _on_destination_requested(tile: Vector3i, _mode: int, _sequence: int) -> void:
	selection_feedback.select_tile(tile)
	_cancel_use()

func _on_world_context_requested(entity: int, screen_position: Vector2) -> void:
	_context_kind = "world"
	_context_entity = entity
	_context_slot = -1
	var kind: String = object_registry.kind_for(entity)
	if not kind.is_empty():
		context_menu.open(ContextActions.world_actions(kind), screen_position)

func _on_inventory_context_requested(slot: int, screen_position: Vector2) -> void:
	_context_kind = "inventory"
	_context_slot = slot
	_context_entity = 0
	context_menu.open(ContextActions.inventory_actions(hud.inventory.item_droppable(slot)), screen_position)

func _on_context_action(action_id: String) -> void:
	match action_id:
		"world.primary": interaction_controller.interact(_context_entity)
		"world.inspect": interaction_controller.inspect_world(_context_entity)
		"inventory.use":
			use_targeting.select_source(_context_slot)
			hud.inventory.set_selected_slot(_context_slot)
		"inventory.inspect": interaction_controller.inspect_inventory(_context_slot)
		"inventory.drop": interaction_controller.drop_slot(_context_slot)

func _on_inventory_slot_clicked(slot: int) -> void:
	if not use_targeting.active():
		return
	interaction_controller.use_inventory(use_targeting.take_source(), slot)
	hud.inventory.set_selected_slot(-1)

func _cancel_use() -> void:
	use_targeting.cancel()
	if is_instance_valid(hud) and is_instance_valid(hud.inventory):
		hud.inventory.set_selected_slot(-1)
