extends CharacterBody2D

@export var move_speed : float = 200.0
@export var jump_force : float = 400.0
@export var gravity : float = 1200.0
@export var coyote_time : float = 0.1   
@export var jump_buffer_time : float = 0.1 
@export var air_control : float = 0.9

var coyote_timer : float = 0.0
var jump_buffer : float = 0.0

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("ui_left", "ui_right")

	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer = jump_buffer_time
	else:
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

	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5

	move_and_slide()
