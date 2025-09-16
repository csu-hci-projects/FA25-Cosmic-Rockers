extends Control

@onready var lobby_id = $menu/lobby_id
@onready var players = $players

@onready var chat = $chat
@onready var chatbox = $chat/chatbox
@onready var chatinput = $chat/chatinput

@onready var menu = $menu
@onready var lobby_menu = $lobby_menu
@onready var start_button = $lobby_menu/start

func _ready():
	Network.chat_received.connect(_add_chat_message)
	Network.lobby_members_updated.connect(_update_lobby)
	Network.lobby_joined.connect(_on_lobby_joined)
	Network.lobby_left.connect(_on_lobby_left)
	
	chat.visible = false
	lobby_menu.visible = false

func _on_host_pressed():
	Network.create_lobby()
	
func _on_join_pressed():
	var id: int = int(lobby_id.text)
	Network.join_lobby(id)

func _on_chatinput_text_submitted(new_text: String):
	_on_send_pressed()

func _on_send_pressed():
	var message: String = chatinput.text
	Network.send_chat(message)
	chatinput.clear()

func _update_lobby(lobby_members: Array):
	for child in players.get_children():
		child.queue_free()
	
	for member in lobby_members:
		var label = Label.new()
		label.text = member['steam_name']
		players.add_child(label)

func _on_lobby_joined():
	menu.visible = false
	lobby_menu.visible = true
	chat.visible = true
	
	if !Network.is_host:
		start_button.visible = false
	else:
		start_button.visible = true

func _add_chat_message(username: String, message: String):
	var new_chat: String = "[" + username + "]: " + message
	chatbox.text = chatbox.text + '\n' + new_chat

func _on_ready_toggled(toggled_on: bool) -> void:
	Network.send_update("ready", { "status": toggled_on })

func _on_start_pressed(toggled_on: bool) -> void:
	pass # Replace with function body.

func _on_disconnect_pressed() -> void:
	Network.disconnect_lobby()

func _on_lobby_left():
	menu.visible = true
	lobby_menu.visible = false
	chat.visible = false
	chatbox.text = ""
