extends Network

signal on_received_ready_status(steam_id: int, data: Dictionary)
signal on_received_position(steam_id: int, data: Dictionary)
signal on_received_tile(cell: Vector2i, id: int)

# SEND TYPES:
# 0 -> Packets may be dropped. No guarantee of order or arrival
# 1 -> Like unreliable, but packets are dropped if they arrive out of order
# 2 -> Packets are always delivered and in the right order. Retries until acknowledged

func update_ready_status(status: bool) -> bool:
	var value: Dictionary = {"status": status}
	return send_player_update("ready_status", value, 2)

func update_position(position: Vector2) -> bool:
	var value: Dictionary = {"x": position.x, "y": position.y}
	return send_player_update("position", value, 1)

func update_tile(cell: Vector2i, id: int):
	return send_world_update(cell, id)
