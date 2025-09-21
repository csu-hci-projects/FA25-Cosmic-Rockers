extends Control

@onready var lobby_id = $menu/lobby_id
@onready var players = $players

@onready var chat = $chat
@onready var chatbox = $chat/chatbox
@onready var chatinput = $chat/chatinput

@onready var menu = $menu
@onready var lobby_menu = $lobby_menu
@onready var start_button = $lobby_menu/start

var lobby_player = preload("res://scenes/lobby_player.tscn")

func _ready():
	Multiplayer.chat_received.connect(_add_chat_message)
	Multiplayer.lobby_members_updated.connect(_update_lobby)
	Multiplayer.lobby_joined.connect(_on_lobby_joined)
	Multiplayer.lobby_left.connect(_on_lobby_left)
	Multiplayer.on_received_ready_status.connect(_on_ready_status_changed)
	
	chat.visible = false
	lobby_menu.visible = false

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
		Multiplayer.start_game()

func _on_disconnect_pressed() -> void:
	Multiplayer.disconnect_lobby()

func _on_lobby_left():
	menu.visible = true
	lobby_menu.visible = false
	chat.visible = false
	chatbox.text = ""
	_update_lobby([])

func _on_invite_pressed() -> void:
	Multiplayer.open_invite_tab()
