extends Node

const PACKET_READ_LIMIT: int = 32

var is_host: bool = false
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 8

func _ready():
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.p2p_session_request.connect(_on_p2p_session_request)

func _process(delta):
	if lobby_id > 0:
		read_all_p2p_packets()

func create_lobby():
	if lobby_id == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_members_max) 

func _on_lobby_created(connect: int, this_lobby_id: int):
	if connect == 1:
		lobby_id = this_lobby_id
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id, "name", "My Lobby")
		
		print("lobby created: ", lobby_id)
		
		var set_relay: bool = Steam.allowP2PPacketRelay(true)

func join_lobby(this_lobby_id: int):
	Steam.joinLobby(this_lobby_id)
	
	get_lobby_members()
	make_p2p_handshake()

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		print("joined lobby: ", lobby_id)

func get_lobby_members():
	lobby_members.clear()
	
	var num_lobby_members: int = Steam.getNumLobbyMembers(lobby_id)
	for member in range(0,num_lobby_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		lobby_members.append({"steam_id": member_steam_id, "steam_name": member_steam_name})

func send_p2p_packet(this_target: int, packet_data: Dictionary, send_type: int = 0):
	var channel: int = 0
	var this_data: PackedByteArray
	this_data.append_array(var_to_bytes(packet_data))
	
	if this_target == 0:
		if lobby_members.size():
			for member in lobby_members:
				if member['steam_id'] != Global.steam_id:
					Steam.sendP2PPacket(member['steam_id'], this_data, send_type, channel)
	else:
		Steam.sendP2PPacket(this_target, this_data, send_type, channel)

func _on_p2p_session_request(remote_id: int):
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	Steam.acceptP2PSessionWithUser(remote_id)

func make_p2p_handshake():
	send_p2p_packet(0, {
		"message": "handshake", 
		"steam_id": Global.steam_id, 
		"steam_username": Global.steam_username})

func read_all_p2p_packets(read_count: int = 0):
	if read_count > PACKET_READ_LIMIT:
		return
		
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count + 1)

func read_p2p_packet():
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0)
		var packet_sender: int = this_packet['remote_steam_id']
		var packet_code: PackedByteArray = this_packet['data']
		var readable_data: Dictionary = bytes_to_var(packet_code)
		
		if readable_data.has("message"):
			match readable_data["message"]:
				"handshake":
					print("player: ", readable_data["player_username"]," has joined.")
					get_lobby_members()
