extends Node

const InputHandler = preload("res://src/InputHandler.tscn")
const Player = preload("res://src/Player.tscn")

var server

var address
var currentRoom
var inputHandler
var myPlayer
var currentRoomName

# TODO server should tell client what room is default?
var next_room = "RedRoom"
var next_spawn = "DefaultSpawn"
var players = []
var since_last_update = .2
var last_update_position = null


func _ready():
	inputHandler = InputHandler.instance()
	add_child(inputHandler)

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
	inputHandler.player = null
	myPlayer = null

func room_change_deferred():
	remove_child(currentRoom)
	currentRoom.free()

	players = []
	currentRoomName = null
	currentRoom = null

	server.rpc_unreliable_id(1, "change_room", next_room)

# Client helpers
func load_room():
	currentRoomName = next_room
	currentRoom = load("res://src/rooms/" + next_room + ".tscn").instance()
	currentRoom.connect("room_change", self, "room_change")
	add_child(currentRoom)

	myPlayer = addPlayer(
		get_tree().get_network_unique_id(),
		currentRoom.get_node(next_spawn).position + Vector2(rand_range(-20, 20), rand_range(-20, 20))
	)
	myPlayer.get_node("MeshInstance2D").modulate = Color(.5, .6, 0, 1)

	if last_update_position:
		myPlayer.position.y = last_update_position.y

	currentRoom.player = myPlayer
	inputHandler.player = myPlayer
	send_update()

	inputHandler.auto_move_room = currentRoomName

func addPlayer(id, position):
	var player = Player.instance()
	player.set_name(str(id))
	player.position = position
	currentRoom.get_node("Players").add_child(player)

	return player

func send_update():
	reset_since_last_update()
	last_update_position = myPlayer.position
	server.rpc_unreliable_id(1, "playerSelfUpdate", myPlayer.position)

func reset_since_last_update():
	since_last_update = 0

# Client rpcs
remotesync func set_room_players(room, positions):
	if currentRoomName != room && next_room != room: return

	if !currentRoom:
		load_room()

	var myId = get_tree().get_network_unique_id()

	for player_node in currentRoom.get_node("Players").get_children():
		var intId = int(player_node.name)
		if intId != myId && !positions.has(intId):
			print("removing stale player: ", player_node.name)
			currentRoom.get_node("Players").remove_child(player_node)
			player_node.free()

	players = []
	for id in positions:
		if id == myId: continue

		players.append(id)
		if positions[id] != null:
			playerUpdate(room, id, positions[id])

remotesync func add_new_player(room, id):
	if currentRoomName != room: return
	players.append(id)

remotesync func playerUpdate(room, id, position):
	if !currentRoom: return
	if currentRoomName != room: return

	if id == get_tree().get_network_unique_id():
		return print("got invalid update for self")

	var strId = "Players/" + str(id)
	if currentRoom.has_node(strId):
		currentRoom.get_node(strId).position = position
	elif players.has(id):
		addPlayer(id, position)
	# else we don't have the node, and haven't been told about the player.
	#     so ignore the update

remotesync func removePlayer(room, id):
	if !currentRoom: return
	if currentRoomName != room: return

	var strId = "Players/" + str(id)
	if currentRoom.has_node(strId):
		currentRoom.get_node("Players/").remove_child(currentRoom.get_node(strId))

	players.erase(id)

# Client process
func _process(delta):
	since_last_update += delta

	if !currentRoom && since_last_update >= .05:
		reset_since_last_update()
		server.rpc_unreliable_id(1, "change_room", next_room)
	elif since_last_update >= .0333 && myPlayer:
		if last_update_position != myPlayer.position || since_last_update >= .05:
			send_update()
