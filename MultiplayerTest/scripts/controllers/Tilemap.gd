class_name Tilemap
extends TileMapLayer

const EMPTY_TILE: int = -1

func _ready() -> void:
	if not Multiplayer.on_received_tile.is_connected(_update_tile):
		Multiplayer.on_received_tile.connect(_update_tile)

func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 \
		and cell.x < WorldState.map_width and cell.y < WorldState.map_height

func _is_boundary_at_point(world_pos: Vector2) -> bool:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = world_pos
	params.collide_with_bodies = true
	params.collide_with_areas = true

	var results := get_world_2d().direct_space_state.intersect_point(params, 16)
	for r in results:
		var c: Object = r.get("collider")
		if c and (c.is_in_group("boundary") or c.get_meta("indestructible", false)):
			return true
	return false

func _is_boundary_at_cell(cell: Vector2i) -> bool:
	var local_pos: Vector2 = map_to_local(cell)
	var world_pos: Vector2 = to_global(local_pos)
	return _is_boundary_at_point(world_pos)

func create_tilemap():
	var width: int = WorldState.map_width
	var height: int = WorldState.map_height

	var cells_to_update: Array[Vector2i] = []
	for j in range(height):
		for i in range(width):
			var cell: Vector2i = Vector2i(i, j)
			if WorldState.get_tile_data(cell) != EMPTY_TILE:
				cells_to_update.append(cell)

	set_cells_terrain_connect(cells_to_update, 0, WorldState.get_tileset(), false)

func update_tile(cell: Vector2i, tile_id: int, radius: int):
	for y_offset in range(-radius, radius + 1):
		for x_offset in range(-radius, radius + 1):
			var c := cell + Vector2i(x_offset, y_offset)
			if _is_protected(c):
				continue

	Multiplayer.update_tile(cell, tile_id, radius)
	_update_tile(cell, tile_id, radius)

	if not _in_bounds(cell):
		return
	if tile_id == -1 and _is_boundary_at_cell(cell):
		return

func _update_tile(cell: Vector2i, tile_id: int, radius: int) -> void:
	if not _in_bounds(cell):
		return
	set_cells(cell, tile_id, radius)

func take_hit(hit_position: Vector2, radius: int) -> int:
	var local_pos: Vector2 = to_local(hit_position)
	var cell: Vector2i = local_to_map(local_pos)
	var cell_count = cells_in_range(cell, -1, radius)
	update_tile(cell, -1, radius)
	return cell_count

func set_cells(cell: Vector2i, tile_id: int, radius: int):
	var cells_to_erase: Array[Vector2i] = []
	for y_offset in range(-radius, radius + 1):
		for x_offset in range(-radius, radius + 1):
			var c := cell + Vector2i(x_offset, y_offset)
			if _is_protected(c):
				continue
			cells_to_erase.append(c)
	set_cells_terrain_connect(cells_to_erase, 0, -1, false)

func cells_in_range(cell: Vector2i, tile_id: int, radius: int) -> int:
	var cells: int = 0
	for y_offset in range(-radius, radius + 1):
		for x_offset in range(-radius, radius + 1):
			var c := cell + Vector2i(x_offset, y_offset)
			var data := get_cell_tile_data(c)
			if data != null and data.terrain != -1:
				cells += 1
	return cells

var _protected_cells := {} 

func add_protected_cell(cell: Vector2i) -> void:
	if not _in_bounds(cell):
		return
	_protected_cells["%d,%d" % [cell.x, cell.y]] = true

func _is_protected(cell: Vector2i) -> bool:
	return _protected_cells.has("%d,%d" % [cell.x, cell.y])

func _cell_is_empty(c: Vector2i) -> bool:
	if not _in_bounds(c):
		return false
	var td := get_cell_tile_data(c)
	var terrain_empty: bool = (td == null or td.terrain == -1)
	return terrain_empty and not _is_boundary_at_cell(c) and not _is_protected(c)
