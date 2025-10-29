class_name Tilemap
extends TileMapLayer

const EMPTY_TILE: int = -1

func _ready() -> void:
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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_pos: Vector2 = get_viewport().get_camera_2d().get_global_mouse_position()

		if _is_boundary_at_point(world_pos):
			return

		var local_pos: Vector2 = to_local(world_pos)
		var cell: Vector2i = local_to_map(local_pos)
		update_tile(cell, -1)

func create_tilemap():
	var width: int = WorldState.map_width 
	var height: int = WorldState.map_height
	
	var cells_to_update = []
	
	for j in range(height):
		for i in range(width):
			var cell: Vector2i = Vector2i(i, j)
			if WorldState.get_tile_data(cell) != EMPTY_TILE:
				cells_to_update.append(cell)
	
	set_cells_terrain_connect(cells_to_update, 0, WorldState.get_tileset(), false)


func update_tile(cell: Vector2i, tile_id: int):
	Multiplayer.update_tile(cell, tile_id)
	_update_tile(cell, tile_id)

	if not _in_bounds(cell):
		return
	if tile_id == -1 and _is_boundary_at_cell(cell):
		return

func _update_tile(cell: Vector2i, tile_id: int):
	if not _in_bounds(cell):
		return
	set_3x3(cell, tile_id)

func take_hit(hit_position: Vector2):
	var local_pos: Vector2 = to_local(hit_position)
	var cell: Vector2i = local_to_map(local_pos)
	update_tile(cell, -1)

func set_3x3(cell: Vector2i, tile_id: int):
	var cells_to_erase: Array[Vector2i] = []
	
	for y_offset in range(-1,2):
		for x_offset in range(-1,2):
			var c := cell + Vector2i(x_offset, y_offset)
			cells_to_erase.append(c)
	
	set_cells_terrain_connect(cells_to_erase, 0, -1, false)
