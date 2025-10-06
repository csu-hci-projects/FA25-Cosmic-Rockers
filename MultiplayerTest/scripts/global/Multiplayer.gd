extends Network

signal on_received_ready_status(steam_id: int, data: Dictionary)
signal on_received_tile(cell: Vector2i, id: int)
signal on_received_input(steam_id: int, data: Dictionary)
signal on_received_position(steam_id: int, data: Dictionary)

signal on_received_entity_spawn(entity_id: int, data: Dictionary)
signal on_received_entity_state(entity_id: int, data: Dictionary)
signal on_received_entity_positions(entity_id: int, data: Dictionary)

# SEND TYPES:
# 0 -> Packets may be dropped. No guarantee of order or arrival
# 1 -> Like unreliable, but packets are dropped if they arrive out of order
# 2 -> Packets are always delivered and in the right order. Retries until acknowledged

func update_ready_status(status: bool) -> bool:
	var value: Dictionary = {"status": status}
	return send_player_update("ready_status", value, 2)

func update_tile(cell: Vector2i, id: int) -> bool:
	return send_world_update(cell, id)

func update_input(value: Dictionary) -> bool:
	return send_player_update("input", value, 1)

func update_position(position: Vector2) -> bool:
	var value: Dictionary = {"position": position}
	return send_player_update("position", value, 2)


func entity_spawn(entity_id: String, position: Vector2) -> bool:
	var value: Dictionary = {"position": position}
	return send_entity_update("entity_spawn", entity_id, value, 2)

func update_entity_state(entity_id: String, state: Dictionary) -> bool:
	return send_entity_update("entity_state", entity_id, state, 1)

func update_entity_positions(data: Dictionary) -> bool:
	return send_entity_update("entity_positions", "0", data, 2)
