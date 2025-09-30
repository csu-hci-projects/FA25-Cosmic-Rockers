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
	
	Multiplayer.on_received_input.connect(_update_input)
	Multiplayer.on_received_position.connect(_update_position)

func _update_input(steam_id: int, data: Dictionary):
	if remote_players.has(steam_id):
		remote_players[steam_id]._update_input(data)

func _update_position(steam_id: int, data: Dictionary):
	if remote_players.has(steam_id):
		remote_players[steam_id]._update_position(data)

func spawn_players():
	var players = PlayerState.get_all_players_data()
	for key in players.keys():
		var remote_player = player_scene.instantiate()
		remote_players.set(key, remote_player)
		
		add_child(remote_player)
		remote_player.name = players[key]["steam_username"]
		remote_player.entity_id = str(key)
		move_to_spawn(remote_player)
	
	get_local_player().is_local_player = true
	camera.set_target(get_local_player())

func get_local_player() -> Node2D:
	if !remote_players.has(Global.steam_id):
		return null
	return remote_players[Global.steam_id]

func move_to_spawn(node: Node2D):
	node.position = Vector2i(
		WorldState.spawn_room_position.x + WorldState.room_size / 2,
		WorldState.spawn_room_position.y + WorldState.room_size / 2
		) * 16
