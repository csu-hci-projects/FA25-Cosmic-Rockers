extends Control

@onready var lobby_id = $menu/lobby_id
@onready var players = $players

@onready var chatbox = $chat/chatbox
@onready var chatinput = $chat/chatinput

func _ready():
	Network.chat_received.connect(_add_chat_message)
	Network.lobby_members_updated.connect(_display_members)

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

func _display_members(lobby_members: Array):
	for child in players.get_children():
		child.queue_free()
	
	for member in lobby_members:
		var label = Label.new()
		label.text = member['steam_name']
		players.add_child(label)

func _add_chat_message(username: String, message: String):
	var new_chat: String = "[" + username + "]: " + message
	chatbox.text = chatbox.text + '\n' + new_chat
