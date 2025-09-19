extends Network

signal on_received_ready_status(steam_id: int, data: Dictionary)
signal on_received_position(steam_id: int, data: Dictionary)
signal on_received_tile(cell: Vector2i, id: int)

func update_ready_status(status: bool) -> bool:
	var value: Dictionary = {"status": status}
	return send_player_update("ready_status", value)

func update_position(position: Vector2) -> bool:
	var value: Dictionary = {"x": position.x, "y": position.y}
	return send_player_update("position", value)

func update_tile(cell: Vector2i, id: int):
	return send_world_update(cell, id)
