extends Node

const position_chunk_size: int = 10
const position_sync_frames: int = 20
var position_sync_timer: int = 0
var position_chunk_offset: int = 0

var enemy_scene = preload("res://scenes/enemy.tscn")
@onready var game_controller = $".." 
var enemies = {}

func _ready() -> void:
	Multiplayer.on_received_entity_spawn.connect(_spawn_enemy)
	Multiplayer.on_received_entity_state.connect(_set_state)
	Multiplayer.on_received_entity_positions.connect(_set_positions)

func _process(delta: float):
	if !Multiplayer.is_host:
		return
	if !WorldState.level_loaded:
		return
	if enemies.size() == 0:
		return
	
	var entity_ids: Array = enemies.keys()
	for key in entity_ids:
		var enemy = enemies[key]
		enemy._process_state(delta)
	
	if position_sync_timer <= 0:
		position_sync_timer = position_sync_frames
		var data = {}
		var size = enemies.size()
		for i in range(position_chunk_offset, position_chunk_offset + position_chunk_size):
			data[entity_ids[i % size]] = enemies[entity_ids[i % size]].position
		Multiplayer.update_entity_positions(data)
		
		position_chunk_offset += position_chunk_size
		if position_chunk_offset >= size:
			position_chunk_offset %= size
	position_sync_timer-=1

func send_state(entity_id: String, state: Enemy.State, target: String):
	Multiplayer.update_entity_state(entity_id, {"state":state, "target":target})

func spawn_enemies():
	var enemy_spawns = WorldState.get_enemy_spawn_locations(50)
	var id: int = 0
	for spawn_location in enemy_spawns:
		var entity_id = "enemy_"+str(id)
		id += 1
		var enemy = _spawn_enemy(entity_id, {"position":spawn_location})
		Multiplayer.entity_spawn(entity_id, spawn_location)
		enemy.on_state_change.connect(send_state)
		enemy._process_state(0)

func _spawn_enemy(entity_id: String, data: Dictionary) -> Enemy:
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.name = entity_id
	enemy.entity_id = entity_id
	game_controller.move_to_tile(enemy, data["position"])
	enemies.set(entity_id, enemy)
	return enemy

func _set_state(entity_id: String, data: Dictionary):
	var state: Enemy.State = data["state"]
	var target: Node2D = game_controller.get_entity(data["target"])
	
	enemies[entity_id].current_state = state
	enemies[entity_id]._target = target

func _set_positions(entity_id: String, data: Dictionary):
	for key in data.keys():
		enemies[key].position = data[key]
