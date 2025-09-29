extends Node

var player_scene = preload("res://scenes/player.tscn")

@onready var tilemap = $tilemap
@onready var camera = $camera

var remote_players = {}

func _ready() -> void:
	WorldState.on_level_loaded.connect(tilemap.create_tilemap)
	WorldState.on_level_loaded.connect(spawn_players)
	if WorldState.level_loaded:
		tilemap.create_tilemap()
		spawn_players()

func spawn_players():
	for key in PlayerState.get_all_players_data().keys():
		var remote_player = player_scene.instantiate()
		remote_players.set(key, remote_player)
		add_child(remote_player)
		
		remote_player.move_to_empty_tile()
	
	camera.target = get_local_player()

func get_local_player():
	if !remote_players.has(Global.steam_id):
		return null
	return remote_players[Global.steam_id]
