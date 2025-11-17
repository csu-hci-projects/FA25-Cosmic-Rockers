class_name GameController
extends Node

var player_scene = preload("res://scenes/game/player.tscn")
var collectable_scene = preload("res://scenes/game/collectable.tscn")
var ship_scene = preload("res://scenes/game/ship.tscn")
var end_screen_scene = preload("res://scenes/ui/end_screen.tscn")
var cobblestone_texture = preload("res://sprites/tilesets/Cobblestone.png")

@onready var tilemap = $tilemap
@onready var background = $camera/background
@onready var foreground_particles = $camera/foreground_particles
@onready var camera = $camera
@onready var enemy_controller = $enemy_controller
@onready var player_status = $CanvasLayer/status
@onready var music_controller = $music_controller

var remote_players = {}

func _ready() -> void:
	if WorldState.level_loaded:
		initialize_game()
	else:
		WorldState.on_level_loaded.connect(initialize_game)
	
	Multiplayer.transition_started.connect(despawn_players)
	
	Multiplayer.on_received_input.connect(_update_input)
	Multiplayer.on_received_position.connect(_update_position)
	Multiplayer.on_received_gun_direction.connect(_update_direction)
	Multiplayer.on_received_gun_shoot.connect(_update_shoot)

func get_entity(entity_id: String) -> Node2D:
	var entities = get_tree().get_nodes_in_group("entity")
	for entity in entities:
		if entity.entity_id == entity_id:
			return entity
	return null

func initialize_game() -> void:
	tilemap.create_tilemap()
	await get_tree().process_frame # let visuals update
	await get_tree().physics_frame # let physics finish
	background.create_background()
	foreground_particles.create_level_effects()
	spawn_collectable()
	enemy_controller.spawn_enemies()
	_create_out_of_bounds(tilemap)
	
	WorldState.emit_signal("on_game_loaded")
	
	await get_tree().create_timer(4).timeout
	
	WorldState.emit_signal("on_game_ready")
	music_controller.play_intro()
	start_drop_sequence()

func _update_input(steam_id: int, data: Dictionary):
	if remote_players.has(steam_id):
		remote_players[steam_id]._update_input(data)

func _update_position(steam_id: int, data: Dictionary):
	if remote_players.has(steam_id):
		remote_players[steam_id]._update_position(data)

func _update_direction(steam_id: int, data: Dictionary):
	if remote_players.has(steam_id):
		var player = remote_players[steam_id]
		for child in player.get_children():
			if child is Gun:
				child.on_set_direction(data)

func _update_shoot(steam_id: int, data: Dictionary):
	if remote_players.has(steam_id):
		var player = remote_players[steam_id]
		for child in player.get_children():
			if child is Gun:
				child.on_shoot(data)

func spawn_players():
	var players = PlayerState.get_all_players_data()
	for key in players.keys():
		var remote_player: PlayerMovement = player_scene.instantiate()
		remote_players.set(key, remote_player)
		
		remote_player.entity_id = str(key)
		
		add_child(remote_player)
		
		var player_data = PlayerState.get_player_data(key).get("player_customization", {})
		var player_username = players[key]["steam_username"]
		var player_color = PlayerState.COLORS[player_data.get("color", 0)]
		
		remote_player.pointer.set_pointer(player_color, player_username	)
		remote_player.sprite.sprite_frames = PlayerState.CHARACTERS[player_data.get("character", 0)]
		remote_player.on_die.connect(_on_player_die)
		
		var gun: Gun = PlayerState.WEAPONS[player_data.get("weapon", 0)].instantiate()
		gun.player_owner = remote_player
		remote_player.add_child(gun)
		
		move_to_spawn(remote_player)
		player_status.create_status_bar(remote_player, player_username, player_color)
	
	var local_player = get_local_player()
	local_player.is_local_player = true
	camera.set_target(local_player, true, 5)
	local_player.on_die.connect(music_controller.enable_effects)

func despawn_players():
	camera.set_target(null, true, 0)
	for key in remote_players.keys():
		remote_players[key].despawn()
	remote_players.clear()

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
	collectable.game_controller = self
	collectable.set_sprite(WorldState.get_collectible_sprite())
	
func start_drop_sequence():
	music_controller.enable_effects()
	var ship = ship_scene.instantiate()
	add_child(ship)
	move_to_spawn(ship)
	ship.set_drop(ship.position)
	ship.on_dropped.connect(_on_ship_dropped)
	camera.set_target(ship, false, 10) 

func _on_ship_dropped():
	music_controller.disable_effects()
	music_controller.play_music()
	spawn_players()
	var spawn_room_position = tilemap.map_to_local(Vector2i(
		WorldState.spawn_room_position.x + WorldState.room_size / 2,
		WorldState.spawn_room_position.y + WorldState.room_size / 2
		))
	enemy_controller.kill_in_radius(spawn_room_position, 250)

func _create_out_of_bounds(tilemap: TileMapLayer) -> void:
	var margin_px: int = -30
	var thickness_px: int = 200

	var used: Rect2i = tilemap.get_used_rect()
	if used.size == Vector2i.ZERO:
		return

	var cell_min: Vector2 = tilemap.map_to_local(used.position)
	var cell_max: Vector2 = tilemap.map_to_local(used.position + used.size)

	var left: float   = min(cell_min.x, cell_max.x)
	var right: float  = max(cell_min.x, cell_max.x)
	var top: float    = min(cell_min.y, cell_max.y)
	var bottom: float = max(cell_min.y, cell_max.y)

	left   -= float(margin_px)
	right  += float(margin_px)
	top    -= float(margin_px)
	bottom += float(margin_px)

	var w: float = right - left
	var h: float = bottom - top
	var t: float = float(thickness_px)

	_make_boundary_zone(Rect2(Vector2(left - t, top - t),   Vector2(w + 2.0 * t, t))) # top
	_make_boundary_zone(Rect2(Vector2(left - t, bottom),    Vector2(w + 2.0 * t, t))) # bottom
	_make_boundary_zone(Rect2(Vector2(left - t, top),       Vector2(t, h)))           # left
	_make_boundary_zone(Rect2(Vector2(right,  top),         Vector2(t, h)))           # right


func _make_boundary_zone(rect: Rect2) -> void:
	var wall: StaticBody2D = StaticBody2D.new()
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	var sprite: Sprite2D = Sprite2D.new()
	
	shape.size= rect.size
	col.shape = shape
	sprite.texture = cobblestone_texture
	
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, rect.size)
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.centered = false
	sprite.position = -rect.size * 0.5
	wall.position = rect.position + rect.size * 0.5

	wall.set_collision_layer_value(1, true)
	wall.set_collision_layer_value(4, true)
	wall.set_collision_mask_value(1, true)

	add_child(wall)
	wall.add_child(col)
	wall.add_child(sprite)

func _on_player_die():
	var all_dead = true
	for key in remote_players:
		if !remote_players[key].is_dead:
			all_dead = false
	if all_dead:
		show_end_screen()

func show_end_screen():
	var end_screen = end_screen_scene.instantiate()
	var canvas_layer := get_tree().current_scene.get_node_or_null("CanvasLayer")
	if canvas_layer:
		canvas_layer.add_child(end_screen)
	else:
		get_tree().current_scene.add_child(end_screen)
