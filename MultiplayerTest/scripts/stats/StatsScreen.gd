extends Control

var player_scene = preload("res://scenes/ui/end_screen_player.tscn")
var stat_scene = preload("res://scenes/ui/end_screen_stat.tscn")
var lobby_scene = preload("res://scenes/menu.tscn")

@onready var player_list = $stats/player_list
@onready var stat_list = $stats/stat_list
@onready var stat_player: Label = $stats/stat_list/player/username

var current_player: int = 0
var all_player_data: Dictionary

signal on_load_lobby()

func _ready():
	all_player_data = PlayerState.get_all_players_data()
	load_players()
	load_stats()

func load_players():
	for key in all_player_data:
		var player_data = all_player_data[key]
		var player = player_scene.instantiate()
		player_list.add_child(player)
		player.load_player(key, player_data)


func load_stats():
	for child in stat_list.get_children():
		if child is StatsScreenStat:
			child.queue_free()
	
	var current_player_steam_id = all_player_data.keys()[current_player]
	stat_player.text = all_player_data[current_player_steam_id]["steam_username"]
	var player_stats = all_player_data[current_player_steam_id]["stats"]
	for player_stat in player_stats.keys():
		var stat = stat_scene.instantiate()
		stat_list.add_child(stat)
		stat.load_stat(player_stat, player_stats[player_stat])


func _on_left_pressed() -> void:
	current_player += 1
	if current_player >= all_player_data.size():
		current_player = 0
	load_stats()


func _on_right_pressed() -> void:
	current_player -= 1
	if current_player < 0:
		current_player = all_player_data.size() - 1
	load_stats()


func _on_menu_pressed() -> void:
	Multiplayer.disconnect_lobby()
	PlayerState.clear()
	load_lobby()


func _on_lobby_pressed() -> void:
	PlayerState.reset()
	load_lobby()


func load_lobby():
	WorldState.reset()
	get_tree().change_scene_to_packed(lobby_scene)
	emit_signal("on_load_lobby")
