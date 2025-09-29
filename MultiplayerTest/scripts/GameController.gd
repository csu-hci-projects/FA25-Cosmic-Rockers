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
	var players = PlayerState.get_all_players_data()
	for key in players.keys():
		var remote_player = player_scene.instantiate()
		remote_players.set(key, remote_player)
		
		add_child(remote_player)
		remote_player.name = players[key]["steam_username"]
		move_to_empty_tile(remote_player)
	
	get_local_player().is_local_player = true
	camera.set_target(get_local_player())

func get_local_player() -> Node2D:
	if !remote_players.has(Global.steam_id):
		return null
	return remote_players[Global.steam_id]

func move_to_empty_tile(node: Node2D):
	for i in range(WorldState.map_data.size()):
		if WorldState.map_data[i] == -1:
			node.position = WorldState.get_tile_position(i)
			return
