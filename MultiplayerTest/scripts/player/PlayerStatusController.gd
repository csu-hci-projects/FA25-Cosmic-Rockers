extends VBoxContainer

var player_status_scene = preload("res://scenes/ui/player_status.tscn")

func create_status_bar(entity: Entity, player_name: String, color: Color):
	var player_status = player_status_scene.instantiate()
	add_child(player_status)
	player_status.set_entity(entity, player_name, color)
