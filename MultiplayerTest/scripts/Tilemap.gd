extends TileMapLayer

func _ready() -> void:
	create_tilemap()
	Multiplayer.on_received_tile.connect(_update_tile)

##for testing purposes
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_pos: Vector2 = get_viewport().get_camera_2d().get_global_mouse_position()
		var local_pos: Vector2 = to_local(world_pos)
		var cell: Vector2i = local_to_map(local_pos)
		
		update_tile(cell, -1)
##testing end

func create_tilemap():
	var width: int = WorldState.map_width 
	var height: int = WorldState.map_height
	
	var cells_to_update = []
	
	for j in range(height):
		for i in range(width):
			var cell: Vector2i = Vector2i(i, j)
			if WorldState.get_tile_data(cell) != -1:
				cells_to_update.append(cell)
	
	set_cells_terrain_connect(cells_to_update, 0, 0, false)

func update_tile(cell: Vector2i, tile_id: int):
	Multiplayer.update_tile(cell, tile_id)
	_update_tile(cell, tile_id)

func _update_tile(cell: Vector2i, tile_id: int):
	set_3x3(cell, tile_id)

func set_3x3(cell: Vector2i, tile_id: int):
	var cells_to_erase := []
	
	for y_offset in range(-1,2):
		for x_offset in range(-1,2):
			var c := cell + Vector2i(x_offset, y_offset)
			cells_to_erase.append(c)
	
	set_cells_terrain_connect(cells_to_erase, 0, -1, false)
