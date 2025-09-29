extends CharacterBody2D

@export var move_speed : float = 200.0
@export var jump_force : float = 400.0
@export var gravity : float = 1200.0
@export var coyote_time : float = 0.1
@export var jump_buffer_time : float = 0.1
@export var air_control : float = 0.9

var coyote_timer : float = 0.0
var jump_buffer : float = 0.0
var input_dir: float = 0
var position_sync_timer: int = 0

var is_local_player: bool = false
var position_sync_frames: int = 20

func _physics_process(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
	
	jump_buffer -= delta
	
	var target_speed = input_dir * move_speed
	if is_on_floor():
		velocity.x = target_speed
	else:
		velocity.x = lerp(velocity.x, target_speed, air_control * delta * 10.0)

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	if jump_buffer > 0 and coyote_timer > 0:
		velocity.y = -jump_force
		jump_buffer = 0
		coyote_timer = 0

	move_and_slide()


func _process(delta: float):
	if !is_local_player: #only local player controls their player
		return
	
	if position_sync_timer <= 0:
		position_sync_timer = position_sync_frames
		Multiplayer.update_position(position)
	position_sync_timer-=1
	
	if Input.is_action_just_pressed("jump"):
		jump()
		Multiplayer.update_input({ "jump":true })
	
	if Input.is_action_just_released("jump"):
		jump_release()
		Multiplayer.update_input({ "jump":false })
	
	if Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("move_left") \
	or Input.is_action_just_released("move_right") or Input.is_action_just_released("move_left"):
		var input = Input.get_axis("move_left", "move_right")
		move(input)
		Multiplayer.update_input({ "move":input })


func jump():
	jump_buffer = jump_buffer_time


func jump_release():
	if velocity.y < 0:
		velocity.y *= 0.5


func move(input: float):
	input_dir = input


func _update_input(data: Dictionary):
	if data.has("jump"):
		if data["jump"]:
			jump()
		else:
			jump_release()
	
	if data.has("move"):
		move(data["move"])

func _update_position(data: Dictionary):
	print(data)
	if data.has("x") and data.has("y"):
		position = Vector2(data["x"], data["y"])
