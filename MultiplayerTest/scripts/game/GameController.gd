extends Node

var player_scene = preload("res://scenes/game/player.tscn")
var collectable_scene = preload("res://scenes/game/collectable.tscn")

@onready var tilemap = $tilemap
@onready var background = $camera/background
@onready var camera = $camera
@onready var enemy_controller = $enemy_controller
@onready var player_status = $CanvasLayer/status

var remote_players = {}

func _ready() -> void:
	WorldState.on_level_loaded.connect(initialize_game)
	if WorldState.level_loaded:
		initialize_game()
	
	Multiplayer.on_received_input.connect(_update_input)
	Multiplayer.on_received_position.connect(_update_position)

func get_entity(entity_id: String) -> Node2D:
	var entities = get_tree().get_nodes_in_group("entity")
	for entity in entities:
		if entity.entity_id == entity_id:
			return entity
	return null

func initialize_game():
	tilemap.create_tilemap()
	background.create_background()
	spawn_collectable()
	spawn_players()
	enemy_controller.spawn_enemies()

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
		player_status.create_status_bar(remote_player, players[key]["steam_username"])
	
	get_local_player().is_local_player = true
	camera.set_target(get_local_player())

func get_local_player() -> Node2D:
	if !remote_players.has(Global.steam_id):
		return null
	return remote_players[Global.steam_id]

func move_to_spawn(node: Node2D):
	move_to_tile(node, Vector2i(
		WorldState.spawn_room_position.x + WorldState.room_size / 2,
		WorldState.spawn_room_position.y + WorldState.room_size / 2
		))

func move_to_end(node: Node2D):
	move_to_tile(node, Vector2i(
		WorldState.end_room_position.x + WorldState.room_size / 2,
		WorldState.end_room_position.y + WorldState.room_size / 2
		))

func move_to_tile(node: Node2D, tile: Vector2i):
	node.position = tilemap.map_to_local(tile)

func spawn_collectable():
	var collectable = collectable_scene.instantiate()
	add_child(collectable)
	move_to_end(collectable)
	collectable.set_sprite(WorldState.get_collectible_sprite())
	collectable.on_player_grab.connect(_player_grab_collectable)

func _player_grab_collectable(player_id: String):
	print(player_id, " grabbed collectable")
