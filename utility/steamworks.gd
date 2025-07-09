extends Node


const PACKET_READ_LIMIT: int = 32
var lobby_data
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 10
var lobby_vote_kick: bool = false
var steam_id: int = 0
var steam_username: String = ""

var lobby_agents : Dictionary[int,FreeAgent]

func _ready() -> void:
	initialize_steam()
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created)
	#Steam.lobby_data_update.connect(_on_lobby_data_update)
	#Steam.lobby_invite.connect(_on_lobby_invite)
	Steam.lobby_joined.connect(_on_lobby_joined)
	#Steam.lobby_match_list.connect(_on_lobby_match_list)
	#Steam.lobby_message.connect(_on_lobby_message)
	Steam.persona_state_change.connect(_on_persona_change)
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	Steam.p2p_session_connect_fail.connect(_on_p2p_session_connect_fail)
	
	check_command_line()
	
	
func _process(delta: float) -> void:
	Steam.run_callbacks()
	if lobby_id > 0:
		read_all_p2p_packets()

func read_all_p2p_packets(read_count: int = 0):
	if read_count >= PACKET_READ_LIMIT:
		return
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count+1)

func read_p2p_packet():
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size,0)
		if this_packet.is_empty() or this_packet == null:
			print("empty packet")
		var packet_sender: int = this_packet["remote_steam_id"]
		var packet_code: PackedByteArray = this_packet["data"]
		var readable_data: Dictionary = bytes_to_var(packet_code.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
		print("Packet: %s" % readable_data)
		#todo: actually interpret packet here
		if lobby_agents.has(packet_sender):
			match readable_data.type:
				"pos":
					var pos = Vector2(readable_data.x,readable_data.y)
					lobby_agents[packet_sender].position = pos

func send_p2p_packet(this_target: int, packet_data: Dictionary):
	var send_type: int = Steam.P2P_SEND_RELIABLE
	var channel: int = 0
	
	var this_data: PackedByteArray
	var compressed_data: PackedByteArray = var_to_bytes(packet_data).compress(FileAccess.COMPRESSION_GZIP)
	this_data.append_array(compressed_data)
	if this_target == 0:
		if lobby_members.size() > 1:
			for this_member in lobby_members:
				if this_member["steam_id"] != steam_id:
					Steam.sendP2PPacket(this_member["steam_id"],this_data,send_type,channel)
	else:
		Steam.sendP2PPacket(this_target, this_data, send_type, channel)
		
func _on_p2p_session_request(remote_id: int):
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	print("%s is requesting a P2P session" % this_requester)
	Steam.acceptP2PSessionWithUser(remote_id)
	make_p2p_handshake()
	
func _on_p2p_session_connect_fail(steam_id: int, session_error: int):
	if session_error == 0:
		print("WARNING: Session failure with %s: no error given" % steam_id)
	elif session_error == 1:
		print("WARNING: Session failure with %s: target user not running the same game" % steam_id)
	elif session_error == 2:
		print("WARNING: Session failure with %s: local user doesn't own app / game" % steam_id)
	elif session_error == 3:
		print("WARNING: Session failure with %s: target user isn't connected to Steam" % steam_id)
	elif session_error == 4:
		print("WARNING: Session failure with %s: connection timed out" % steam_id)
	elif session_error == 5:
		print("WARNING: Session failure with %s: unused" % steam_id)
	else:
		print("WARNING: Session failure with %s: unknown error %s" % [steam_id, session_error])
		
func initialize_steam():
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Did Steam initialize?: %s " % initialize_response)
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

func check_command_line() -> void:
	var these_arguments = OS.get_cmdline_args()
	if these_arguments.size() > 0:
		if these_arguments[0] == "+connect_lobby":
			if int(these_arguments[1]) > 0:
				print("Command line lobby ID: %s" % these_arguments[1])
				join_lobby(int(these_arguments[1]))


func create_lobby():
	if lobby_id == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC,lobby_members_max)
		
func _on_lobby_created(connect: int, this_lobby_id: int):
	if connect == 1:
		lobby_id = this_lobby_id
		print("Created a lobby: %s" % lobby_id)
		Steam.setLobbyJoinable(lobby_id,true)
		
		Steam.setLobbyData(lobby_id,"name","RowanTest")
		Steam.setLobbyData(lobby_id,"mode","TEST")
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: %s" % set_relay)
		
func join_lobby(this_lobby_id: int):
	print("Attempting to join lobby %s" % lobby_id)
	lobby_members.clear()
	Steam.joinLobby(this_lobby_id)
	
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		get_lobby_members()
		#make new agents
		for member in lobby_members:
			if member.steam_id == steam_id:
				continue
			Util.main.make_new_character(member.steam_id,member.steam_name)
			
		make_p2p_handshake()
	else:
		var fail_reason: String
		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."
		print("Failed to join this chat room: %s" % fail_reason)
		

func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	var owner_name : String = Steam.getFriendPersonaName(friend_id)
	print("Joining %s's lobby..." % owner_name)
	join_lobby(this_lobby_id)
	
func get_lobby_members() -> void:
	lobby_members.clear()
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)
	for this_member in range(0,num_of_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id,this_member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		lobby_members.append({"steam_id":member_steam_id, "steam_name":member_steam_name})
		
func _on_persona_change(this_steam_id: int, _flag: int):
	if lobby_id > 0:
		print("A user (%s) had information change, update the lobby list" % this_steam_id)
		get_lobby_members()

func make_p2p_handshake():
	print("Sending P2P handshake to the lobby")
	send_p2p_packet(0, {"message": "handshake", "from": steam_id})
	
func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	var changer_name : String = Steam.getFriendPersonaName(change_id)
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s has joined the lobby." % changer_name)
		Util.main.make_new_character(change_id,changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		print("%s has left the lobby." % changer_name)
		if lobby_agents.has(change_id):
			var agent = lobby_agents[change_id]
			agent.queue_free()
			lobby_agents.erase(change_id)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		print("%s has been kicked from the lobby." % changer_name)
	get_lobby_members()
	
func _on_chat_send_pressed():
	#todo: make a chat box, probably just a line edit
	var this_message: String = "cat"
	if this_message.length() > 0:
		var was_sent : bool = Steam.sendLobbyChatMsg(lobby_id,this_message)
		if not was_sent:
			print("error: chat didn't send")
	#todo clear method of chat input
	
func leave_lobby():
	if lobby_id != 0:
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
		for this_member in lobby_members:
			if this_member["steam_id"] != steam_id:
				Steam.closeP2PSessionWithUser(this_member["steam_id"])
		lobby_members.clear()
