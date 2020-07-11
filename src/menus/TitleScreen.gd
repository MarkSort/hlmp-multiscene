extends Node2D

signal start_game

onready var address = $TopCenter/TopVBox/Join/Address

func _on_HostButton_pressed():
	emit_signal("start_game")


func _on_JoinButton_pressed():
	emit_signal("start_game", address.text)
