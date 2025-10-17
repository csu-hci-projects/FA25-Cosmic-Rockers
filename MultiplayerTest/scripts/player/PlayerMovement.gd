class_name PlayerMovement
extends Entity

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

@export var is_local_player: bool = false
var position_sync_frames: int = 20

@onready var sprite: AnimatedSprite2D = $sprite

var collectable: Collectable = null

func _ready() -> void:
	super()
	set_animation("default")
	sprite.animation_finished.connect(_animation_finished)
	on_die.connect(_on_die)

func _physics_process(delta: float) -> void:
	jump_buffer -= delta
	
	var target_speed = input_dir * move_speed
	if is_on_floor():
		coyote_timer = coyote_time
		velocity.x = target_speed
		velocity.y = 0
		
		if abs(velocity.x) > 0.1:
			set_animation("walk")
		else:
			set_animation("default")
	else:
		coyote_timer -= delta
		velocity.x = lerp(velocity.x, target_speed, air_control * delta * 10.0)
		velocity.y += gravity * delta
		
		set_animation("fall")
	
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

	if jump_buffer > 0 and coyote_timer > 0:
		velocity.y = -jump_force
		jump_buffer = 0
		coyote_timer = 0

	move_and_slide()


func set_animation(animation_name: String):
	if animation_name != "death" and is_dead:
		return
	
	sprite.play(animation_name)

func _process(delta: float):
	if !is_local_player: #only local player controls their player
		return
	if is_dead:
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
	set_animation("jump")


func jump_release():
	if velocity.y < 0:
		velocity.y *= 0.5


func move(input: float):
	input_dir = input


func _animation_finished():
	if sprite.animation == "jump":
		set_animation("fall")
	if sprite.animation == "land":
		set_animation("default")


func _update_input(data: Dictionary):
	if data.has("jump"):
		if data["jump"]:
			jump()
		else:
			jump_release()
	
	if data.has("move"):
		move(data["move"])


func _update_position(data: Dictionary):
	if data.has("position"):
		position = data["position"]

func _on_die():
	input_dir = 0
	set_animation("death")
	
	if !is_local_player:
		return
	
	if collectable:
		collectable._set_target(null)
		Multiplayer.update_collectable(false)

func grab_collectable(_collectable: Collectable):
	collectable = _collectable
	Multiplayer.update_collectable(true)
