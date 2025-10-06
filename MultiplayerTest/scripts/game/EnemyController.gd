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

func _process(delta: float):
	if !Multiplayer.is_host:
		return
	if !WorldState.level_loaded:
		return
	
	var keys: Array = enemies.keys()
	for key in keys:
		var enemy = enemies[key]
		enemy._process_state(delta)
	
	if position_sync_timer <= 0:
		position_sync_timer = position_sync_frames
		var data = {}
		for i in range(position_chunk_offset, (position_chunk_offset + position_chunk_size) % keys.size()):
			data[keys[i]] = enemies[keys[i]].position
		Multiplayer.update_entity_positions(data)
		
		position_chunk_offset += position_chunk_size
		if position_chunk_offset >= keys.size():
			position_chunk_offset %= keys.size()
	position_sync_timer-=1

func send_state(entity_id: String, state: Enemy.State, target: String):
	Multiplayer.update_entity_state(entity_id, {"state":state, "target":target})

func spawn_enemies():
	var enemy_spawns = WorldState.get_enemy_spawn_locations(50)
	var entity_id: int = 0
	for spawn_location in enemy_spawns:
		var enemy_name = "enemy_"+str(entity_id)
		entity_id += 1
		_spawn_enemy(enemy_name, {"position":spawn_location}).on_state_change.connect(send_state)
		Multiplayer.entity_spawn(enemy_name, spawn_location)

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
