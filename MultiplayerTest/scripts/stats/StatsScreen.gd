extends HBoxContainer

var player_scene = preload("res://scenes/ui/end_screen_player.tscn")
var stat_scene = preload("res://scenes/ui/end_screen_stat.tscn")

@onready var player_list = $player_list
@onready var stat_list = $stat_list

var current_player: int = 0
var all_player_data: Dictionary

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
	var player_stats = all_player_data[Global.steam_id]["stats"]
	for player_stat in player_stats.keys():
		var stat = stat_scene.instantiate()
		stat_list.add_child(stat)
		stat.load_stat(player_stat, player_stats[player_stat])


func _on_left_pressed() -> void:
	current_player += 1
	#if current_player >= max:
		#current_player = 0
	load_stats()


func _on_right_pressed() -> void:
	current_player -= 1
	#if current_player < 0:
		#current_player = max
	load_stats()
