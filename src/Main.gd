extends Node

var TitleScreen = preload("res://src/menus/TitleScreen.tscn")
var Client = preload("res://src/networking/Client.tscn")
var Server = preload("res://src/networking/Server.tscn")

var current_scene

func _ready():
	randomize()

	current_scene = TitleScreen.instance()
	current_scene.connect("start_game", self, "start_game")
	add_child(current_scene)

func start_game(address = null):
	remove_child(current_scene)
	current_scene.queue_free()

	var server = Server.instance()

	var client = Client.instance()
	client.address = address

	# So they can RPC to each other
	client.server = server
	server.client = client

	# just so Client.process runs and only a single node to remove when
	# implement "Leave Game" in in-game menu
	server.add_child(client)

	current_scene = server
	add_child(current_scene)
