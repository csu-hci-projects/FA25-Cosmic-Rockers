extends Node

var LEVELS: Dictionary = {}

var enemy_count = 10

var map_width: int = 0
var map_height: int = 0

var spawn_room_position: Vector2i
var end_room_position: Vector2i
var room_size: int
var level_id: int = 0

var map_data: Array = []
var room_data: Array = []

var received_map_chunks := {}
var level_loaded = false

signal on_level_loaded()
signal on_game_loaded()

func _ready():
	load_all_levels("res://level_data")

func load_all_levels(path: String):
	var dir = DirAccess.open(path)
	if not dir:
		push_error("Could not open directory: " + path)
		return
	
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if filename.ends_with(".tres"):
			var resource = load(path + "/" + filename)
			if resource is LevelData:
				LEVELS[resource.level_id] = resource
			else:
				push_warning("File %s is not a LevelData resource." % filename)
		filename = dir.get_next()
	dir.list_dir_end()

func get_next_level() -> int:
	if LEVELS.has(level_id + 1):
		return level_id + 1
	else:
		return level_id

func initialize(level: int = 0) -> Dictionary:
	level_id = level
	
	map_width = 200
	map_height = 100
	spawn_room_position = Vector2i(randi_range(5, map_width - 10),5)
	end_room_position = Vector2i(randi_range(5, map_width - 10), map_height - 10)
	room_size = 5
	
	var level_data = LEVELS[level_id]
	var data = TerrainGenerator.generate(
		map_width, 
		map_height, 
		level_data["floor_range"], 
		level_data["roof_range"], 
		level_data["x_offset_range"], 
		level_data["y_offset_range"])
	enemy_count = level_data["enemy_count"]
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
		"level_id" : level_id
	}

func get_collectible_sprite() -> Texture2D:
	return LEVELS[level_id]["collectable"]

func get_tileset() -> int:
	return LEVELS[level_id]["tileset"]

func get_background() -> String:
	return LEVELS[level_id]["background"]

func get_music() -> Array[AudioStream]:
	return LEVELS[level_id]["songs"]

func get_level_name() -> String:
	return LEVELS[level_id]["level_name"]

func get_level_name_alien() -> String:
	return LEVELS[level_id]["level_name_alien"]

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
	level_id = data.get("level_id", 0)
	
	level_loaded = true
	emit_signal("on_level_loaded")

func update_tile(cell: Vector2i, value: int):
	var tile_id = get_tile_id(cell)
	if map_data.has(tile_id):
		map_data[tile_id] = value

func clear():
	map_width = 0
	map_height = 0
	map_data.clear()

func get_enemy_spawn_locations() -> Array:
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
