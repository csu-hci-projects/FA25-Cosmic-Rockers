extends Control


@onready var chat = $chat
@onready var menu = $menu
@onready var lobby_menu = $lobby_menu
@onready var players = $players
@onready var error = $steam_error

@onready var lobby_id = $menu/lobby_id

@onready var chatbox = $chat/chatbox
@onready var chatinput: LineEdit = $chat/chatinput

@onready var start_button: Button = $lobby_menu/start
@onready var ready_button: Button = $lobby_menu/ready
@onready var level_select: LineEdit = $lobby_menu/level_select

@onready var error_message = $steam_error/VBoxContainer/Label

var lobby_player = preload("res://scenes/ui/lobby_player.tscn")

func _ready():
	chat.visible = false
	lobby_menu.visible = false
	error.visible = false
	
	Multiplayer.chat_received.connect(_add_chat_message)
	Multiplayer.lobby_members_updated.connect(_update_lobby)
	Multiplayer.lobby_joined.connect(_on_lobby_joined)
	Multiplayer.lobby_left.connect(_on_lobby_left)
	Multiplayer.on_received_ready_status.connect(_on_ready_status_changed)
	Global.on_steam_error.connect(_display_error)
	if Global.error_message != "":
		_display_error(Global.error_message)

func _display_error(message: String):
	error_message.text = "Steam Error:\n(" + message + ")\nPlease restart steam and try again."
	error.reset_size()
	error.position = (get_viewport_rect().size - error.size) / 2
	
	chat.visible = false
	lobby_menu.visible = false
	menu.visible = false
	error.visible = true

func _on_host_pressed():
	Multiplayer.create_lobby()
	
func _on_join_pressed():
	var id: int = int(lobby_id.text)
	Multiplayer.join_lobby(id)

func _on_chatinput_text_submitted(new_text: String):
	_on_send_pressed()

func _on_send_pressed():
	var message: String = chatinput.text
	Multiplayer.send_chat(message)
	chatinput.clear()

func _update_lobby(lobby_members: Array):
	for child in players.get_children():
		child.queue_free()
	
	for member in lobby_members:
		var player = lobby_player.instantiate()
		players.add_child(player)
		player.load_player(member["steam_id"], member["steam_name"])

func _on_lobby_joined():
	menu.visible = false
	lobby_menu.visible = true
	chat.visible = true
	
	if !Multiplayer.is_host:
		start_button.visible = false
	else:
		start_button.visible = true

func _add_chat_message(username: String, message: String):
	var new_chat: String = "[" + username + "]: " + message
	chatbox.text = chatbox.text + '\n' + new_chat

func _on_ready_toggled(toggled_on: bool) -> void:
	_on_ready_status_changed(Global.steam_id, {"status": toggled_on})
	Multiplayer.update_ready_status(toggled_on)

func _on_ready_status_changed(steam_id: int, data: Dictionary):
	for player in players.get_children():
		if player.steam_id == steam_id:
			player.set_ready_status(data["status"])

func _on_start_pressed() -> void:
	if PlayerState.all_ready():
		var level_id = int(level_select.text) if level_select.text.is_valid_int() else 0
		Multiplayer.start_game(level_id)

func _on_disconnect_pressed() -> void:
	Multiplayer.disconnect_lobby()

func _on_lobby_left():
	PlayerState.clear()
	WorldState.clear()
	
	menu.visible = true
	lobby_menu.visible = false
	chat.visible = false
	chatbox.text = ""
	ready_button.set_pressed_no_signal(false)
	
	_update_lobby([])

func _on_invite_pressed() -> void:
	Multiplayer.open_invite_tab()

func _on_retry_pressed() -> void:
	error_message.text = ""
	Global.initialize_steam()
	
	chat.visible = false
	lobby_menu.visible = false
	menu.visible = true
	error.visible = false
