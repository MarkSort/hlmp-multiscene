extends Node

var TitleScreen = preload("res://src/menus/TitleScreen.tscn")
var Client = preload("res://src/networking/Client.tscn")
var Server = preload("res://src/networking/Server.tscn")

var currentScene

func _ready():
	randomize()

	currentScene = TitleScreen.instance()
	currentScene.connect("start_game", self, "start_game")
	add_child(currentScene)

func start_game(address = null):
	remove_child(currentScene)
	currentScene.queue_free()

	var server = Server.instance()

	var client = Client.instance()
	client.address = address

	# So they can RPC to each other
	client.server = server
	server.client = client

	# just so Client.process runs and only a single node to remove when
	# implement "Leave Game" in in-game menu
	server.add_child(client)

	currentScene = server
	add_child(currentScene)
