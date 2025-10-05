extends Node

var enemy_scene = preload("res://scenes/enemy.tscn")

@onready var game_controller = $".." 

var enemies = {}

func _process(delta: float):
	if !Multiplayer.is_host:
		return
	if !WorldState.level_loaded:
		return
	
	for key in enemies.keys():
		var enemy = enemies[key]
		enemy._process_state(delta)

func spawn_enemies():
	var enemy_spawns = WorldState.get_enemy_spawn_locations(50)
	var entity_id: int = 0
	for spawn_location in enemy_spawns:
		var enemy_name = "enemy_"+str(entity_id)
		entity_id += 1
		spawn_enemy(enemy_name, spawn_location)
		Multiplayer.entity_spawn(enemy_name, spawn_location)

func spawn_enemy(entity_id: String, spawn_location: Vector2):
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.name = entity_id
	game_controller.move_to_tile(enemy, spawn_location)
	enemies.set(entity_id, enemy)
