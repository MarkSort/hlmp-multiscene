extends Node2D

signal room_change

var player

func _on_RightDoor_body_entered(body):
	if player == body:
		emit_signal("room_change", "BlueRoom", "LeftSpawn")
