class_name Gun
extends Node2D

@export var damage = 10
@export var tile_damage: int = 1

@export var fire_rate := 0.2
var fire_cooldown := 0.0
var is_firing := false

@onready var ray_start = $ray_start
@onready var sprite: Sprite2D = $sprite

var sprite_offset = 0
var ray_offset = 0

var direction: Vector2
var target_direction: Vector2

@export var player_owner: PlayerMovement = null

func _ready() -> void:
	sprite_offset = sprite.offset.x
	ray_offset = ray_start.position.x
	player_owner.on_sync.connect(sync_direction)

func _update_direction(data: Dictionary):
	if data.has("direction"):
		direction = data["direction"]

func _process(delta: float) -> void:
	if player_owner.is_dead:
		return
	
	if player_owner.is_local_player:
		var mouse_pos = get_global_mouse_position()
		_set_direction((mouse_pos - global_position).normalized())
		
		if fire_cooldown > 0:
			fire_cooldown -= delta
		if is_firing:
			if fire_cooldown <= 0.0:
				_shoot()
				fire_cooldown = fire_rate
	else:
		direction = lerp(direction, target_direction, delta * 5)
	
	if direction.x > 0:
		sprite.flip_h = false
		sprite.offset.x = sprite_offset
		ray_start.position.x = ray_offset
		rotation = atan2(direction.y, direction.x)
	elif direction.x < 0:
		sprite.flip_h = true
		sprite.offset.x = -sprite_offset
		ray_start.position.x = -ray_offset
		rotation = atan2(-direction.y, -direction.x)

func sync_direction():
	Multiplayer.update_gun_direction(direction)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_firing = event.pressed

func _shoot():
	#Extend this
	pass

func on_set_direction(data: Dictionary):
	target_direction = data["direction"]

func on_shoot(data: Dictionary):
	#Extend this
	pass

func _handle_hit(object: Node2D, hit_position: Vector2):
	if not player_owner.is_local_player:
		return
	
	if object is Entity:
		object.take_damage(damage)
	
	if object is Tilemap:
		object.take_hit(hit_position, tile_damage)

func _set_direction(_direction: Vector2):
	direction = _direction
