extends Node

var map_width: int = 0
var map_height: int = 0
var map_data: Array = []

func initialize() -> Dictionary:
	map_width = 10
	map_height = 10
	map_data = []
	
	for j in range(map_height):
		for i in range(map_width):
			map_data.append(randi_range(0,1))
	
	return {"map_data": map_data, "map_width": map_width, "map_height": map_height}

func get_tile_id(cell: Vector2i):
	return cell.x + cell.y * map_width

func get_tile_data(cell: Vector2i):
	return map_data[cell.x + cell.y * map_width]

func set_map_data(data: Array, width: int, height: int):
	if data.size() != width * height:
		push_error("Map data length does not match width * height")
	
	map_width = width
	map_height = height
	map_data = data

func update_tile(cell: Vector2i, value: int):
	map_data[get_tile_id(cell)] = value

func clear():
	map_width = 0
	map_height = 0
	map_data.clear()
