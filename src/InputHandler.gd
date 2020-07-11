extends Node

var player
var move_input = Vector2.ZERO
var auto_move = false
var auto_move_room
var auto_move_since_change = 0

func _ready():
	set_physics_process(true)

func _process(delta):
	if Input.is_action_just_pressed("toggle_auto_move"):
		auto_move = !auto_move
		if auto_move:
			auto_move_since_change = .5

	if auto_move:
		auto_move_since_change += delta
		if auto_move_since_change >= .5:
			auto_move_since_change = 0

			if auto_move_room == "RedRoom":
				move_input = Vector2.RIGHT
			else:
				move_input = Vector2.LEFT
		return

	move_input = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		move_input.y -= 1
	if Input.is_action_pressed("move_down"):
		move_input.y += 1
	if Input.is_action_pressed("move_right"):
		move_input.x += 1
	if Input.is_action_pressed("move_left"):
		move_input.x -= 1

	move_input = move_input.normalized()

func _physics_process(delta):
	if !player:
		return

	player.move_and_slide(move_input * 600)
