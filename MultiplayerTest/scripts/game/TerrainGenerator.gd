class_name TerrainGenerator

const EMPTY_TILE: int = -1
const CAVE_TILE: int = 0

static func generate(width: int, height: int, floor_range: Array = [0, 0], roof_range: Array = [0, 0], x_offset_range: Array = [0, 0], y_offset_range: Array = [0, 0]) -> Array:
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = .05                       # Controls zoom level
	
	var y_offsets = []
	for x in range(width):
		y_offsets.append(randf_range(y_offset_range[0], y_offset_range[1]))
	
	var x_offsets = []
	for y in range(height):
		x_offsets.append(randf_range(x_offset_range[0], x_offset_range[1]))

	var result = []
	for y in range(height):
		var row = []
		for x in range(width):
			var value = noise.get_noise_2d(x + x_offsets[y], y + y_offsets[x])    # Returns a float between -1 and 1
			if value > 0.1:
				row.append(EMPTY_TILE)
			else:
				row.append(CAVE_TILE)
		result.append(row)
	
	result = add_border(result, 5)
	result = create_flat_rooms(result, floor_range, roof_range)
	result = remove_islands(result, 20)
	
	var flatten: Array = []
	for row in result:
		for value in row:
			flatten.append(value)
	return flatten

static func add_border(data: Array, width: int) -> Array:
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

	return data

static func remove_islands(data: Array, min_size: int) -> Array:
	var visited := {}
	for j in data.size():
		for i in data[j].size():
			var cell = Vector2i(i,j)
			if cell in visited:
				continue
			
			var group = get_connected_tiles(data, cell, data[j][i])
			for c in group:
				visited[c] = true

			if group.size() > 0 and group.size() < min_size:
				var set_value = EMPTY_TILE
				if data[j][i] == EMPTY_TILE:
					set_value = CAVE_TILE
				
				for c in group:
					data[c.y][c.x] = set_value
	
	return data

static func create_flat_rooms(data: Array, floor_height_range: Array, roof_height_range: Array) -> Array:
	var visited := {}
	for j in data.size():
		for i in data[j].size():
			var cell = Vector2i(i,j)
			if cell in visited or data[j][i] == CAVE_TILE:
				continue
			
			var group = get_connected_tiles(data, cell, data[j][i])
			var min_height: int = cell.y
			var max_height: int = cell.y
			for c in group:
				visited[c] = true
				if c.y > max_height:
					max_height = c.y
				if c.y < min_height:
					min_height = c.y
			
			var floor_height = randf_range(floor_height_range[0], floor_height_range[1])
			var roof_height = randf_range(roof_height_range[0], roof_height_range[1])
			var floor_level = max_height - ((max_height - min_height) * floor_height)
			var roof_level = min_height + ((max_height - min_height) * roof_height)
			
			for c in group:
				if c.y >= floor_level or c.y <= roof_level:
					data[c.y][c.x] = CAVE_TILE
	
	return data

static func get_connected_tiles(data: Array, start: Vector2i, value) -> Array:
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
