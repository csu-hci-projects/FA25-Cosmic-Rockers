extends Network

signal on_received_ready_status(steam_id: int, data: Dictionary)
signal on_received_position(steam_id: int, data: Dictionary)

func update_ready_status(value: Dictionary) -> bool:
	return send_update("ready_status", value)

func update_position(value: Dictionary) -> bool:
	return send_update("position", value)
