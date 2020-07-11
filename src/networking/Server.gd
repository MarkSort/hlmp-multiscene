extends Node

var client

var players = {}
var rooms = { "RedRoom": [], "BlueRoom": [] }
var since_update = 0

func _ready():
	if client.address:
		return

	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(1337)
	get_tree().network_peer = peer

	get_tree().connect("network_peer_connected", self, "network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "network_peer_disconnected")

	network_peer_connected(1)
	client.connected_to_server()

# Server signals
func network_peer_connected(id):
	players[id] = {
		"room": null,
		"position": null
	}
	add_player_to_room(id, "RedRoom")

func network_peer_disconnected(id):
	remove_player_from_room(id)
	players.erase(id)

# Server helpers
func remove_player_from_room(id):
	players[id].position = null

	var room = players[id]["room"]

	rooms[room].erase(id)

	for playerId in rooms[room]:
		client.rpc_unreliable_id(playerId, "remove_player", room, id)

func add_player_to_room(id, room):
	players[id].room = room

	var positions = {}
	for playerId in rooms[room]:
		client.rpc_unreliable_id(playerId, "add_new_player", room, id)
		positions[playerId] = players[playerId].position

	client.rpc_unreliable_id(id, "set_room_players", room, positions)

	rooms[room].append(id)

# Server rpcs
remotesync func player_self_update(position):
	var id = get_tree().get_rpc_sender_id()
	players[id].position = position
	for playerId in rooms[players[id].room]:
		if playerId != id:
			client.rpc_unreliable_id(playerId, "player_update", players[id].room, id, position)

remotesync func change_room(new_room):
	var id = get_tree().get_rpc_sender_id()

	if players[id].room == new_room: return

	remove_player_from_room(id)
	add_player_to_room(id, new_room)

# Server process
func _process(delta):
	since_update += delta

	if since_update < 1: return

	since_update = 0
	for room in rooms:
		var positions = {}
		for playerId in rooms[room]:
			positions[playerId] = players[playerId].position
		for playerId in rooms[room]:
			client.rpc_unreliable_id(playerId, "set_room_players", room, positions)


