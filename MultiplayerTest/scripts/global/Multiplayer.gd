extends Network

signal on_received_ready_status(steam_id: int, data: Dictionary)
signal on_received_player_customization(steam_id: int, data: Dictionary)

signal on_received_tile(cell: Vector2i, id: int)
signal on_received_input(steam_id: int, data: Dictionary)
signal on_received_position(steam_id: int, data: Dictionary)
signal on_received_collectable(steam_id: int, data: Dictionary)
signal on_received_collectable_submit(steam_id: int, data: Dictionary)
signal on_received_gun_direction(steam_id: int, data: Dictionary)
signal on_received_gun_shoot(steam_id: int, data: Dictionary)

signal on_received_entity_spawn(entity_id: int, data: Dictionary)
signal on_received_entity_state(entity_id: int, data: Dictionary)
signal on_received_entity_positions(entity_id: int, data: Dictionary)
signal on_received_entity_attack(entity_id: int, data: Dictionary)
signal on_received_entity_hit(entity_id: int, data: Dictionary)

# SEND TYPES:
# 0 -> Packets may be dropped. No guarantee of order or arrival
# 1 -> Like unreliable, but packets are dropped if they arrive out of order
# 2 -> Packets are always delivered and in the right order. Retries until acknowledged

func update_ready_status(status: bool) -> bool:
	var data: Dictionary = {"status": status}
	return send_player_update("ready_status", data, 2)
	
func update_player_customization(data: Dictionary) -> bool:
	var sent = send_player_update("player_customization", data, 2)
	emit_signal("on_received_player_customization", Global.steam_id, data)
	return sent

func update_tile(cell: Vector2i, id: int) -> bool:
	return send_world_update(cell, id)

func update_input(data: Dictionary) -> bool:
	return send_player_update("input", data, 1)

func update_position(position: Vector2) -> bool:
	var data: Dictionary = {"position": position}
	return send_player_update("position", data, 2)

func update_collectable(carrying: bool) -> bool:
	var data: Dictionary = {"carrying": carrying}
	return send_player_update("collectable", data, 2)

func update_gun_direction(direction) -> bool:
	var data: Dictionary = {"direction": direction}
	return send_player_update("gun_direction", data, 2)

func update_gun_shoot(from, to) -> bool:
	var data: Dictionary = {"from": from, "to": to}
	return send_player_update("gun_shoot", data, 2)


func entity_spawn(entity_id: String, position: Vector2, enemy_type: int) -> bool:
	var data: Dictionary = {"position": position, "type":enemy_type}
	return send_entity_update("entity_spawn", entity_id, data, 2)

func update_entity_state(entity_id: String, state: Dictionary) -> bool:
	return send_entity_update("entity_state", entity_id, state, 1)

func update_entity_positions(data: Dictionary) -> bool:
	return send_entity_update("entity_positions", "0", data, 2)

func entity_attack(entity_id: String, target_id: String, damage: int) -> bool:
	var data: Dictionary = {"target": target_id, "damage": damage}
	return send_entity_update("entity_attack", entity_id, data, 2)

func entity_hit(entity_id: String, amt: int) -> bool:
	var data: Dictionary = {"amt": amt}
	return send_entity_update("entity_hit", entity_id, data, 2)


func level_complete() -> bool:
	if is_host:
		next_level()
		return true
	else:
		return send_user_packet("level_complete", {}, 2)
