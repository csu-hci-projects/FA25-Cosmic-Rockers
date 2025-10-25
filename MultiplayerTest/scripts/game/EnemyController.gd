extends Node

const position_chunk_size: int = 10
const position_sync_frames: int = 20
var position_sync_timer: int = 0
var position_chunk_offset: int = 0

var enemy_scene_1 = preload("res://scenes/enemies/enemy.tscn")
var enemy_scene_2 = preload("res://scenes/enemies/enemy_brute.tscn")
@onready var game_controller = $".."
var enemies = {}
var enabled_enemies: int = 0

func _ready() -> void:
	Multiplayer.on_received_entity_spawn.connect(_spawn_enemy)
	Multiplayer.on_received_entity_state.connect(_set_state)
	Multiplayer.on_received_entity_positions.connect(_set_positions)
	Multiplayer.on_received_entity_attack.connect(_attack_player)
	Multiplayer.on_received_entity_hit.connect(_take_hit)

func _process(delta: float):
	#CHUNKED ENEMY ENABLING
	if enabled_enemies < enemies.size():
		var entity_ids: Array = enemies.keys()
		var to = enabled_enemies + position_chunk_size
		if to >= entity_ids.size():
			to = entity_ids.size()
		for i in range(enabled_enemies, to):
			enemies[entity_ids[i]].enable_ai()
		enabled_enemies += position_chunk_size
		return
	
	if !Multiplayer.is_host():
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
			data[entity_ids[i % size]] = {
				"position": enemies[entity_ids[i % size]].position, 
				"health": enemies[entity_ids[i % size]].health
				}
		Multiplayer.update_entity_positions(data)
		
		position_chunk_offset += position_chunk_size
		if position_chunk_offset >= size:
			position_chunk_offset %= size
	position_sync_timer-=1

func send_state(entity_id: String, state: Enemy.State, target: String):
	Multiplayer.update_entity_state(entity_id, {"state":state, "target":target})

func spawn_enemies():
	var enemy_spawns = WorldState.get_enemy_spawn_locations()
	var id: int = 0
	for spawn_location in enemy_spawns:
		var entity_id = "enemy_"+str(id)
		id += 1
		var enemy_type = randi_range(0,1)
		var enemy = _spawn_enemy(entity_id, {"position":spawn_location, "type":enemy_type})
		Multiplayer.entity_spawn(entity_id, spawn_location, enemy_type)
		enemy.on_state_change.connect(send_state)
		enemy.on_attack_player.connect(attack_player)
		enemy.on_hit_taken.connect(take_hit)
		enemy._process_state(0)

func _spawn_enemy(entity_id: String, data: Dictionary) -> Enemy:
	var enemy_scene = null
	if data["type"] == 0:
		enemy_scene = enemy_scene_1
	else:
		enemy_scene = enemy_scene_2
	
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
		enemies[key].position = data[key]["position"]
		enemies[key].set_health(data[key]["health"])


func take_hit(entity_id: String, amt: int):
	Multiplayer.entity_hit(entity_id, amt)

func _take_hit(entity_id: String, data: Dictionary):
	var amt: int = data["amt"]
	if amt < 0:
		enemies[entity_id].take_damage(abs(amt))
	else:
		enemies[entity_id].take_healing(abs(amt))


func attack_player(entity_id: String, target_id: String, damage: int):
	Multiplayer.entity_attack(entity_id, target_id, damage)
	_attack_player(entity_id, {"target": target_id, "damage": damage})

func _attack_player(entity_id: String, data: Dictionary):
	var target: Entity = game_controller.get_entity(data["target"])
	target.take_damage(data["damage"])

func kill_in_radius(position: Vector2, radius: float):
	for entity_id in enemies:
		if position.distance_to(enemies[entity_id].position) <= radius:
			enemies[entity_id].set_health(0)
