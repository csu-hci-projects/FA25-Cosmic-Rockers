class_name Network
extends Node

const PACKET_READ_LIMIT: int = 32

var is_host: bool = false
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 8

signal lobby_members_updated(lobby_members: Array)
signal chat_received(username: String, message: String)
signal lobby_joined()
signal lobby_left()

var game_scene = preload("res://scenes/game.tscn")


func _ready():
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.join_requested.connect(_on_join_requested)


func _process(delta):
	if lobby_id > 0:
		read_all_p2p_packets()


func _on_join_requested(this_lobby_id: int, steam_id: int):
	join_lobby(this_lobby_id)


func _on_lobby_created(connect: int, this_lobby_id: int):
	if connect == 1:
		lobby_id = this_lobby_id
		is_host = true
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id, "name", "My Lobby")
		Steam.setLobbyData(lobby_id, "connect", str(lobby_id))
		Steam.setRichPresence("connect", str(lobby_id))
		
		emit_signal("chat_received", "SYSTEM", "lobby created: " + str(lobby_id))
		
		var set_relay: bool = Steam.allowP2PPacketRelay(true)


func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		
		PlayerState.set_player_data(Global.steam_id, {"steam_username": Global.steam_username})
		
		emit_signal("lobby_joined")
		get_lobby_members()
		send_user_packet("handshake", {}, 2)


func _on_lobby_chat_update(lobby_id: int, changed_id: int, making_changed_id: int, chat_state: int):
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		return
	
	var steam_username = PlayerState.get_player_data(changed_id)["steam_username"]
	
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		emit_signal("chat_received", "SYSTEM", "user "+steam_username+" left")
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
		emit_signal("chat_received", "SYSTEM", "user "+steam_username+" disconnected")
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		emit_signal("chat_received", "SYSTEM", "user "+steam_username+" kicked")
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		emit_signal("chat_received", "SYSTEM", "user "+steam_username+" banned")
	
	PlayerState.remove_player(changed_id)
	get_lobby_members()


func _on_p2p_session_request(remote_id: int):
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	Steam.acceptP2PSessionWithUser(remote_id)


func open_invite_tab():
	if Steam.isOverlayEnabled():
		if lobby_id > 0:
			Steam.activateGameOverlayInviteDialog(lobby_id)
		else:
			print("No active lobby to invite friends to.")
	else:
		print("Steam overlay is not enabled or not available.")


func create_lobby():
	if lobby_id == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_members_max) 


func join_lobby(this_lobby_id: int):
	Steam.joinLobby(this_lobby_id)


func disconnect_lobby():
	Steam.leaveLobby(lobby_id)
	lobby_id = 0
	is_host = false
	lobby_members.clear()
	emit_signal("lobby_left")


func get_lobby_members():
	lobby_members.clear()
	
	var num_lobby_members: int = Steam.getNumLobbyMembers(lobby_id)
	for member in range(0,num_lobby_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		lobby_members.append({"steam_id": member_steam_id, "steam_name": member_steam_name})
	
	emit_signal("lobby_members_updated", lobby_members)


func send_p2p_packet(this_target: int, packet_data: Dictionary, send_type: int = 0) -> bool:
	var channel: int = 0
	var this_data: PackedByteArray
	this_data.append_array(var_to_bytes(packet_data))
	
	if this_target == 0: 
		#SEND TO ALL USERS
		if lobby_members.size():
			var success = true
			for member in lobby_members:
				if member['steam_id'] != Global.steam_id:
					print("Sending ", packet_data["type"])
					if !Steam.sendP2PPacket(member['steam_id'], this_data, send_type, channel):
						success = false
			return success
		else: 
			#NO MEMBERS IN LOBBY
			return false
	else: 
		#SEND TO SPECIFIC USER
		return Steam.sendP2PPacket(this_target, this_data, send_type, channel)


func send_chat(message: String) -> bool:
	if send_user_packet("chat", {"chat": message}, 2):
		emit_signal("chat_received", Global.steam_username, message)
		return true
	return false


func send_player_update(key: String, value: Dictionary, send_type: int = 0) -> bool:
	PlayerState.set_player_data(Global.steam_id, {key: value})
	return send_user_packet("update_" + key, {"data": value}, send_type)


func send_entity_update(key: String, entity_id: String, value: Dictionary, send_type: int = 0) -> bool:
	var data: Dictionary = {}
	data['type'] = key
	data['entity_id'] = entity_id
	data['data'] = value
	return send_p2p_packet(0, data, send_type)


func send_world_update(cell: Vector2i, id: int) -> bool:
	WorldState.update_tile(cell, id)
	return send_user_packet("set_tile", {"data": {"cell": cell, "id": id}}, 2)


func send_user_packet(type: String, data: Dictionary = {}, send_type: int = 0) -> bool:
	data['type'] = type
	data['steam_id'] = Global.steam_id
	data['steam_username'] = Global.steam_username
	return send_p2p_packet(0, data, send_type)


func read_all_p2p_packets(read_count: int = 0):
	if read_count > PACKET_READ_LIMIT:
		return
	
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count + 1)


func read_p2p_packet():
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	
	if packet_size == 0:
		return
	
	var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0)
	var packet_sender: int = this_packet['remote_steam_id']
	var packet_code: PackedByteArray = this_packet['data']
	var readable_data: Dictionary = bytes_to_var(packet_code)
	
	if !readable_data.has("type"):
		return
	
	var data_type = readable_data["type"]
	
	match data_type:
		"handshake":
			emit_signal("chat_received", "SYSTEM", readable_data["steam_username"] + " joined")
			PlayerState.set_player_data(readable_data["steam_id"], {"steam_username": readable_data["steam_username"]})
			get_lobby_members()
			if is_host:
				var data = {}
				data['type'] = "initialize_state"
				data['players'] = PlayerState.get_all_players_data()
				send_p2p_packet(0, data)
		"initialize_state":
			for steam_id in readable_data["players"]:
				PlayerState.set_player_data(steam_id, readable_data["players"][steam_id])
				get_lobby_members()
		"chat":
			emit_signal("chat_received", readable_data["steam_username"], readable_data["chat"])
		"start_game":
			start_game()
		"set_tile":
			var cell: Vector2i = readable_data["data"]["cell"]
			var id: int = readable_data["data"]["id"]
			emit_signal("on_received_tile", cell, id)
		"map_chunk":
			handle_map_chunk(packet_sender, readable_data)
	
	#player specific functions
	if data_type.begins_with("update_"):
		var type = data_type.replace("update_", "")
		PlayerState.set_player_data(readable_data["steam_id"], { type: readable_data["data"] })
		if has_signal("on_received_" + type):
			emit_signal("on_received_" + type, readable_data["steam_id"], readable_data["data"])
		else:
			push_warning("No signal called %s exists!" % readable_data["type"])
	
	#entity specific functions
	if data_type.begins_with("entity_"):
		print("received",data_type)
		if has_signal("on_received_" + data_type):
			emit_signal("on_received_" + data_type, readable_data["entity_id"], readable_data["data"])
		else:
			push_warning("No signal called %s exists!" % readable_data["type"])


func start_game():
	if is_host:
		send_p2p_packet(0, {"type": "start_game"})
		send_map_data(0, WorldState.initialize())
	get_tree().change_scene_to_packed(game_scene)


func send_map_data(this_target: int, data: Dictionary, chunk_size: int = 1000) -> void:
	var map_data = data["map_data"]
	var map_width = data["map_width"]
	var map_height = data["map_height"]
	var spawn_room_position = data["spawn_room_position"]
	var end_room_position = data["end_room_position"]
	var room_size = data["room_size"]
	
	var total_chunks: int = int(ceil(float(map_data.size()) / chunk_size))
	var chunk_index := 0
	var i := 0
	while i < map_data.size():
		var start = i
		var end = min(i + chunk_size, map_data.size())
		var chunk: Array = map_data.slice(start, end)

		var packet := {
			"type": "map_chunk",
			"chunk_index": chunk_index,
			"total_chunks": total_chunks,
			"map_width": map_width,
			"map_height": map_height,
			"spawn_room_position": spawn_room_position,
			"end_room_position": end_room_position,
			"room_size": room_size,
			"chunk_data": chunk
		}
		
		send_p2p_packet(this_target, packet, 2)
		i += chunk_size
		chunk_index += 1


func handle_map_chunk(sender_id: int, packet: Dictionary) -> void:
	WorldState.level_loaded = false
	
	if !WorldState.received_map_chunks.has(sender_id):
		WorldState.received_map_chunks[sender_id] = {
			"chunks": {},
			"expected": packet["total_chunks"],
			"map_width": packet["map_width"],
			"map_height": packet["map_height"],
			"spawn_room_position": packet["spawn_room_position"],
			"end_room_position": packet["end_room_position"],
			"room_size": packet["room_size"]
		}

	var entry = WorldState.received_map_chunks[sender_id]
	entry["chunks"][packet["chunk_index"]] = packet["chunk_data"]

	if entry["chunks"].size() == entry["expected"]:
		var map_data: Array = []
		for i in range(entry["expected"]):
			if entry["chunks"].has(i):
				map_data += entry["chunks"][i]
			else:
				push_error("Missing chunk index %d from sender %d" % [i, sender_id])
				return
		
		WorldState.set_map_data(
			map_data, 
			entry["map_width"], 
			entry["map_height"], 
			entry["spawn_room_position"], 
			entry["end_room_position"], 
			entry["room_size"]
			)
		WorldState.received_map_chunks.erase(sender_id)
