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

func join_lobby(this_lobby_id: int):
	Steam.joinLobby(this_lobby_id)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		
		NetworkState.set_player_data(Global.steam_id, {"steam_username": Global.steam_username})
		
		emit_signal("lobby_joined")
		get_lobby_members()
		send_user_packet("handshake")

func _on_lobby_chat_update(lobby_id: int, changed_id: int, making_changed_id: int, chat_state: int):
	if chat_state == 1:
		return
	
	var steam_username = NetworkState.get_player_data(changed_id)["steam_username"]
	
	if chat_state == 2:  # Left
		emit_signal("chat_received", "SYSTEM", "user "+steam_username+" left")
	elif chat_state == 4:  # Disconnected
		emit_signal("chat_received", "SYSTEM", "user "+steam_username+" disconnected")
	elif chat_state == 8:  # Kicked
		emit_signal("chat_received", "SYSTEM", "user "+steam_username+" kicked")
	elif chat_state == 16: # Banned
		emit_signal("chat_received", "SYSTEM", "user "+steam_username+" banned")
	
	NetworkState.remove_player(changed_id)

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
	if send_user_packet("chat", {"chat": message}):
		emit_signal("chat_received", Global.steam_username, message)
		return true
	return false

func send_update(key: String, value: Dictionary) -> bool:
	NetworkState.set_player_data(Global.steam_id, {key: value})
	return send_user_packet("update_" + key, {"data": value})

func send_user_packet(type: String, data: Dictionary = {}) -> bool:
	data['type'] = type
	data['steam_id'] = Global.steam_id
	data['steam_username'] = Global.steam_username
	return send_p2p_packet(0, data)

func _on_p2p_session_request(remote_id: int):
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	Steam.acceptP2PSessionWithUser(remote_id)

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
			NetworkState.set_player_data(readable_data["steam_id"], {"steam_username": readable_data["steam_username"]})
			get_lobby_members()
			if is_host:
				var data = {}
				data['type'] = "initialize_state"
				data['players'] = NetworkState.get_all_players_data()
				send_p2p_packet(0, data)
		"initialize_state":
			for steam_id in readable_data["players"]:
				NetworkState.set_player_data(steam_id, readable_data["players"][steam_id])
		"chat":
			emit_signal("chat_received", readable_data["steam_username"], readable_data["chat"])
		"start_game":
			start_game()
	
	if data_type.begins_with("update_"):
		var type = data_type.replace("update_", "")
		NetworkState.set_player_data(readable_data["steam_id"], { type: readable_data["data"] })
		if has_signal("on_received_" + type):
			emit_signal("on_received_" + type, readable_data["steam_id"], readable_data["data"])
		else:
			push_warning("No signal called %s exists!" % readable_data["type"])

func start_game():
	if is_host:
		send_p2p_packet(0, {"type": "start_game"})
	get_tree().change_scene_to_packed(game_scene)
