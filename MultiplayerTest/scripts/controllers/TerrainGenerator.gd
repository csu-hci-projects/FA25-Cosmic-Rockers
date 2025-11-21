class_name TerrainGenerator

const EMPTY_TILE: int = -1
const CAVE_TILE: int = 0

static var rooms: Array
static var data: Array

static func generate(width: int, height: int, \
	floor_range: Vector2 = Vector2.ZERO, roof_range: Vector2 = Vector2.ZERO, \
	x_offset_range: Vector2 = Vector2.ZERO, y_offset_range: Vector2 = Vector2.ZERO) -> Dictionary:
	
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = .05                       # Controls zoom level
	
	var y_offsets = []
	for x in range(width):
		y_offsets.append(randf_range(y_offset_range.x, y_offset_range.y))
	
	var x_offsets = []
	for y in range(height):
		x_offsets.append(randf_range(x_offset_range.x, x_offset_range.y))

	data = []
	for y in range(height):
		var row = []
		for x in range(width):
			var value = noise.get_noise_2d(x + x_offsets[y], y + y_offsets[x])    # Returns a float between -1 and 1
			if value > 0.1:
				row.append(EMPTY_TILE)
			else:
				row.append(CAVE_TILE)
		data.append(row)
	
	if WorldState.is_last_level():
		create_boss_room()
	
	add_border(5)
	create_flat_rooms(floor_range, roof_range)
	remove_islands(20)
	get_rooms()
	create_room(WorldState.room_size, WorldState.spawn_room_position)
	create_room(WorldState.room_size, WorldState.end_room_position)
	
	var flatten: Array = []
	for row in data:
		for value in row:
			flatten.append(value)
	return {"map_data": flatten, "room_data": rooms}

static func place_level_pools(
		level: int,
		target_tilemap: Tilemap,
		seed_count: int = 4,
		cover_fraction: float = 0.4,
		min_seed_distance: int = 12
	) -> void:
	if level != 1 and level != 2:
		return

	var hazards_script: Script = load("res://scripts/game/LevelHazards.gd")
	if hazards_script == null:
		push_warning("TerrainGenerator.place_level_pools: LevelHazards.gd not found.")
		return

	var hazards: Node = hazards_script.new()
	if hazards.has_variable("pools_count_range"):
		hazards.pools_count_range = Vector2i(seed_count, seed_count)

	if hazards.has_variable("enable_damage"):
		hazards.enable_damage = (level == 2)

	target_tilemap.add_child(hazards)


static func create_room(size: int, position: Vector2i):
	for x in range(size):
		for y in range(size):
			data[y + position.y][x + position.x] = -1

static func add_border(width: int):
	var rows := data.size()
	if rows == 0:
		return data
	var cols: int = data[0].size()
	
	for y in range(width):
		for x in range(cols):
			data[y][x] = CAVE_TILE
			data[rows - 1 - y][x] = CAVE_TILE

	for y in range(rows):
		for x in range(width):
			data[y][x] = CAVE_TILE
			data[y][cols - 1 - x] = CAVE_TILE

static func get_rooms():
	rooms.clear()
	var visited := {}
	for j in data.size():
		for i in data[j].size():
			if data[j][i] != -1:
				continue
			var cell = Vector2i(i,j)
			if cell in visited:
				continue
			
			var group = get_connected_tiles(cell, data[j][i])
			for c in group:
				visited[c] = true

			rooms.append(group)

static func remove_islands(min_size: int):
	var visited := {}
	for j in data.size():
		for i in data[j].size():
			var cell = Vector2i(i,j)
			if cell in visited:
				continue
			
			var group = get_connected_tiles(cell, data[j][i])
			for c in group:
				visited[c] = true

			if group.size() > 0 and group.size() < min_size:
				var set_value = EMPTY_TILE
				if data[j][i] == EMPTY_TILE:
					set_value = CAVE_TILE
				
				for c in group:
					data[c.y][c.x] = set_value

static func create_flat_rooms(floor_height_range: Vector2, roof_height_range: Vector2):
	var visited := {}
	for j in data.size():
		for i in data[j].size():
			var cell = Vector2i(i,j)
			if cell in visited or data[j][i] != EMPTY_TILE:
				continue
			
			var group = get_connected_tiles(cell, data[j][i])
			var min_height: int = cell.y
			var max_height: int = cell.y
			for c in group:
				visited[c] = true
				if c.y > max_height:
					max_height = c.y
				if c.y < min_height:
					min_height = c.y
			
			var floor_height = randf_range(floor_height_range.x, floor_height_range.y)
			var roof_height = randf_range(roof_height_range.x, roof_height_range.y)
			var floor_level = max_height - ((max_height - min_height) * floor_height)
			var roof_level = min_height + ((max_height - min_height) * roof_height)
			
			for c in group:
				if c.y >= floor_level or c.y <= roof_level:
					data[c.y][c.x] = CAVE_TILE

static func get_connected_tiles(start: Vector2i, value) -> Array:
	var height := data.size()
	if height == 0:
		return []
	var width: int = data[0].size()

	var connected: Array[Vector2i] = []
	var to_check: Array[Vector2i] = [start]
	var visited := {}

	while to_check.size() > 0:
		var cell = to_check.pop_back()

		# Skip if already visited
		if cell in visited:
			continue
		visited[cell] = true

		# Bounds check
		if cell.x < 0 or cell.x >= width or cell.y < 0 or cell.y >= height:
			continue

		# Match value check
		if data[cell.y][cell.x] == value:
			connected.append(cell)

			# Add 4-directional neighbors
			for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var neighbor = cell + dir
				if not visited.has(neighbor):
					to_check.append(neighbor)

	return connected

static func create_boss_room():
	var rows := data.size()
	if rows == 0:
		return data
	var cols: float = data[0].size()

	for x in range(cols):
		data[rows - 1][x] = CAVE_TILE

	var center_x: float = cols / 2.0
	var center_y: float = rows - 1.0
	var radius: float = rows * 0.5
	if radius > 90:
		radius = 90

	for y in range(rows):
		for x in range(cols):
			var dx = x - center_x
			var dy = y - center_y
			var dist = sqrt(dx * dx + dy * dy)

			if dy >= -radius:  
				if dist > radius and dy < 0:
					pass
				elif dist <= radius:
					data[y][x] = EMPTY_TILE

	return data
