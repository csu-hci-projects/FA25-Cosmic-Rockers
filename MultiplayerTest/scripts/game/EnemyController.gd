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
		var enemy = enemy_scene.instantiate()
		var enemy_name = "enemy_"+str(entity_id)
		add_child(enemy)
		enemy.name = enemy_name
		game_controller.move_to_tile(enemy, spawn_location)
		enemies.set(enemy_name, enemy)
		entity_id += 1
