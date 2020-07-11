extends Node

const InputHandler = preload("res://src/InputHandler.tscn")
const Player = preload("res://src/Player.tscn")

var server

var address
var current_room
var current_room_name
var input_handler
var my_player

# TODO server should tell client what room is default?
var next_room = "RedRoom"
var next_spawn = "DefaultSpawn"
var players = []
var since_last_update = .2
var last_update_position = null


func _ready():
	input_handler = InputHandler.instance()
	add_child(input_handler)

	if !address:
		return

	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(address, 1337)
	get_tree().network_peer = peer

	get_tree().connect("connected_to_server", self, "connected_to_server")
	get_tree().connect("connection_failed", self, "connection_failed")
	get_tree().connect("server_disconnected", self, "server_disconnected")

# Client signals
func connected_to_server():
	print("connected_to_server")

func connection_failed():
	print("connection_failed")

func server_disconnected():
	print("server_disconnected")

func room_change(new_room, spawn):
	call_deferred("room_change_deferred")

	next_spawn = spawn
	next_room = new_room
	input_handler.player = null
	my_player = null

func room_change_deferred():
	remove_child(current_room)
	current_room.free()

	players = []
	current_room = null
	current_room_name = null

	server.rpc_unreliable_id(1, "change_room", next_room)

# Client helpers
func load_room():
	current_room_name = next_room
	current_room = load("res://src/rooms/" + next_room + ".tscn").instance()
	current_room.connect("room_change", self, "room_change")
	add_child(current_room)

	my_player = add_player(
		get_tree().get_network_unique_id(),
		current_room.get_node(next_spawn).position + Vector2(rand_range(-20, 20), rand_range(-20, 20))
	)
	my_player.get_node("MeshInstance2D").modulate = Color(.5, .6, 0, 1)

	if last_update_position:
		my_player.position.y = last_update_position.y

	current_room.player = my_player
	input_handler.player = my_player
	send_update()

	input_handler.auto_move_room = current_room_name

func add_player(id, position):
	var player = Player.instance()
	player.set_name(str(id))
	player.position = position
	current_room.get_node("Players").add_child(player)

	return player

func send_update():
	reset_since_last_update()
	last_update_position = my_player.position
	server.rpc_unreliable_id(1, "player_self_update", my_player.position)

func reset_since_last_update():
	since_last_update = 0

# Client rpcs
remotesync func set_room_players(room, positions):
	if current_room_name != room && next_room != room: return

	if !current_room:
		load_room()

	var myId = get_tree().get_network_unique_id()

	for player_node in current_room.get_node("Players").get_children():
		var intId = int(player_node.name)
		if intId != myId && !positions.has(intId):
			current_room.get_node("Players").remove_child(player_node)
			player_node.free()

	players = []
	for id in positions:
		if id == myId: continue

		players.append(id)
		if positions[id] != null:
			player_update(room, id, positions[id])

remotesync func add_new_player(room, id):
	if current_room_name != room: return
	players.append(id)

remotesync func player_update(room, id, position):
	if !current_room: return
	if current_room_name != room: return

	if id == get_tree().get_network_unique_id():
		return print("got invalid update for self")

	var strId = "Players/" + str(id)
	if current_room.has_node(strId):
		current_room.get_node(strId).position = position
	elif players.has(id):
		add_player(id, position)
	# else we don't have the node, and haven't been told about the player.
	#     so ignore the update

remotesync func remove_player(room, id):
	if !current_room: return
	if current_room_name != room: return

	var strId = "Players/" + str(id)
	if current_room.has_node(strId):
		current_room.get_node("Players/").remove_child(current_room.get_node(strId))

	players.erase(id)

# Client process
func _process(delta):
	since_last_update += delta

	if !current_room && since_last_update >= .05:
		reset_since_last_update()
		server.rpc_unreliable_id(1, "change_room", next_room)
	elif since_last_update >= .0333 && my_player:
		if last_update_position != my_player.position || since_last_update >= .05:
			send_update()
