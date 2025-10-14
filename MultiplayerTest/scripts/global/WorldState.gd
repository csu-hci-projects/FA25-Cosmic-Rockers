extends Node

const TILE_SET_BG: Dictionary = {
	0: "cave",
	1: "cave",
	2: "lava",
	3: "cave",
}

var map_width: int = 0
var map_height: int = 0

var spawn_room_position: Vector2i
var end_room_position: Vector2i
var room_size: int
var tile_set: int = 0

var map_data: Array = []
var room_data: Array = []

var received_map_chunks := {}
var level_loaded = false

signal on_level_loaded()

func initialize(level: int = 0) -> Dictionary:
	tile_set = level
	
	map_width = 140
	map_height = 80
	
	spawn_room_position = Vector2i(randi_range(5,130),5)
	end_room_position = Vector2i(randi_range(5,130),70)
	room_size = 5
	
	var data = TerrainGenerator.generate(map_width, map_height, [.2, .4], [0, 0], [-2, 2], [0, 0])
	map_data = data["map_data"]
	room_data = data["room_data"]
	
	level_loaded = true
	emit_signal("on_level_loaded")
	
	return {
		"map_data": map_data, 
		"map_width": map_width, 
		"map_height": map_height, 
		"spawn_room_position" : spawn_room_position, 
		"end_room_position" : end_room_position, 
		"room_size" : room_size, 
		"tile_set" : tile_set
	}

func get_background() -> String:
	return TILE_SET_BG[tile_set]

func get_tile_position(index: int) -> Vector2:
	return Vector2(int(index % map_width), int(index / map_height)) * 16

func get_tile_id(cell: Vector2i) -> int:
	return cell.x + cell.y * map_width

func get_tile_data(cell: Vector2i) -> int:
	return map_data[cell.x + cell.y * map_width]

func set_map_data(data: Dictionary):
	var _map_data: Array = data.get("map_data", [])
	var _map_width: int = data.get("map_width", 0)
	var _map_height: int = data.get("map_height", 0)
	
	if _map_data.size() != _map_width * _map_height:
		push_error("Map data length does not match width * height")
	
	map_data = _map_data
	map_width = _map_width
	map_height = _map_height
	spawn_room_position = data.get("spawn_room_position", Vector2i.ZERO)
	end_room_position = data.get("end_room_position", Vector2i.ZERO)
	room_size = data.get("room_size", 0)
	tile_set = data.get("tile_set", 0)
	
	level_loaded = true
	emit_signal("on_level_loaded")

func update_tile(cell: Vector2i, value: int):
	map_data[get_tile_id(cell)] = value

func clear():
	map_width = 0
	map_height = 0
	map_data.clear()

func get_enemy_spawn_locations(enemy_count: int) -> Array:
	var enemy_spawns: Array = []
	for i in room_data.size():
		var split = enemy_count / (room_data.size() - i)
		for j in split:
			enemy_spawns.append(get_random_room_tile(i))
		enemy_count -= split
	return enemy_spawns

func get_random_room_tile(room_id: int) -> Vector2i:
	var tile_count: int = room_data[room_id].size()
	return room_data[room_id][randi_range(0, tile_count-1)]
