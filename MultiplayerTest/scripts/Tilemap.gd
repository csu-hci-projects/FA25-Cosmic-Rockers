extends TileMapLayer

func _ready() -> void:
	fill_tilemap()
	Multiplayer.on_received_tile.connect(_update_tile)

func fill_tilemap():
	var width: int = WorldState.map_width 
	var height: int = WorldState.map_height
	
	for j in range(height):
		for i in range(width):
			var cell: Vector2i = Vector2i(i, j)
			set_cell(cell, WorldState.get_tile_data(cell), Vector2i.ZERO, 0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_pos: Vector2 = get_viewport().get_camera_2d().get_global_mouse_position()
		var local_pos: Vector2 = to_local(world_pos)
		var cell: Vector2i = local_to_map(local_pos)
		
		update_tile(cell, -1)

func update_tile(cell: Vector2i, tile_id: int):
	Multiplayer.update_tile(cell, tile_id)
	_update_tile(cell, tile_id)

func _update_tile(cell: Vector2i, tile_id: int):
	if get_cell_source_id(cell) != -1 && tile_id == -1: # only if tile exists
		erase_cell(cell)
	else:
		set_cell(cell, tile_id, Vector2i.ZERO, 0)
