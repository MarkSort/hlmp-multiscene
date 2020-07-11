extends Node

var player
var moveInput = Vector2.ZERO
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
				moveInput = Vector2.RIGHT
			else:
				moveInput = Vector2.LEFT
		return

	moveInput = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		moveInput.y -= 1
	if Input.is_action_pressed("move_down"):
		moveInput.y += 1
	if Input.is_action_pressed("move_right"):
		moveInput.x += 1
	if Input.is_action_pressed("move_left"):
		moveInput.x -= 1

	moveInput = moveInput.normalized()

func _physics_process(delta):
	if !player:
		return

	player.move_and_slide(moveInput * 600)
