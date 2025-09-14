extends Control

@onready var lobby_id = $menu/lobby_id
@onready var players = $players

@onready var chatbox = $chat/chatbox
@onready var chatinput = $chat/chatinput

func _on_host_pressed():
	Network.create_lobby()
	
func _on_join_pressed():
	var id: int = int(lobby_id.text)
	Network.join_lobby(id)

func _on_refresh_pressed():
	display_members()

func _on_send_pressed():
	var chat: String = chatinput.text
	Network.send_user_packet("chat", {"chat": chat})

func display_members():
	var lobby_members: Array = Network.lobby_members
	
	for child in players.get_children():
		child.queue_free()
	
	for member in lobby_members:
		var label = Label.new()
		label.text = member['steam_name']
		players.add_child(label)
