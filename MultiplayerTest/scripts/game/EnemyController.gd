extends Node

var enemy_scene = preload("res://scenes/enemy.tscn")

@onready var game_controller = $".." 

var enemies = {}

func _ready() -> void:
	Multiplayer.on_received_entity_spawn.connect(_spawn_enemy)
	Multiplayer.on_received_entity_state.connect(_set_state)

func _process(delta: float):
	if !Multiplayer.is_host:
		return
	if !WorldState.level_loaded:
		return
	
	for key in enemies.keys():
		var enemy = enemies[key]
		enemy._process_state(delta)

func send_state(entity_id: String, state: Enemy.State, target: String):
	Multiplayer.update_entity_state(entity_id, {"state":state, "target":target})

func spawn_enemies():
	var enemy_spawns = WorldState.get_enemy_spawn_locations(50)
	var entity_id: int = 0
	for spawn_location in enemy_spawns:
		var enemy_name = "enemy_"+str(entity_id)
		entity_id += 1
		_spawn_enemy(enemy_name, {"x":spawn_location.x, "y":spawn_location.y}).on_state_change.connect(send_state)
		Multiplayer.entity_spawn(enemy_name, spawn_location)

func _spawn_enemy(entity_id: String, data: Dictionary) -> Enemy:
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.name = entity_id
	enemy.entity_id = entity_id
	game_controller.move_to_tile(enemy, Vector2(data["x"], data["y"]))
	enemies.set(entity_id, enemy)
	return enemy

func _set_state(entity_id: String, data: Dictionary):
	var state: Enemy.State = data["state"]
	var target: Node2D = game_controller.get_entity(data["target"])
	
	enemies[entity_id].current_state = state
	enemies[entity_id]._target = target
