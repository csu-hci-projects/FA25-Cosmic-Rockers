extends Control

@onready var lobby_id = $menu/lobby_id

func _on_host_pressed():
	Network.create_lobby()
	
func _on_join_pressed():
	var id: int = int(lobby_id.text)
	Network.join_lobby(id)
