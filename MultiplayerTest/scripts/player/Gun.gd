class_name Gun
extends Node2D

@export var damage = 10

@onready var ray_start = $ray_start
@onready var sprite: Sprite2D = $sprite

var sprite_offset = 0
var ray_offset = 0

var direction: Vector2
var target_direction: Vector2

var player_owner: PlayerMovement = null

func _ready() -> void:
	sprite_offset = sprite.offset.x
	ray_offset = ray_start.position.x
	player_owner.on_sync.connect(sync_direction)
	
	Multiplayer.on_received_gun_direction.connect(on_set_direction)
	Multiplayer.on_received_gun_shoot.connect(on_shoot)

func _update_direction(data: Dictionary):
	if data.has("direction"):
		direction = data["direction"]

func _process(delta: float) -> void:
	if player_owner.is_dead:
		return
	
	if player_owner.is_local_player:
		var mouse_pos = get_global_mouse_position()
		_set_direction((mouse_pos - global_position).normalized())
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
	if player_owner.is_dead:
			return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if player_owner.is_local_player:
			_shoot()

func _shoot():
	#Extend this
	pass

func on_set_direction(_steam_id: int, data: Dictionary):
	if _steam_id == int(player_owner.entity_id):
		target_direction = data["direction"]

func on_shoot(_steam_id: int, data: Dictionary):
	#Extend this
	pass

func _handle_hit(object: Node2D, hit_position: Vector2):
	if object is Entity:
		object.take_damage(damage)
	
	if object is Tilemap:
		object.take_hit(hit_position)

func _set_direction(_direction: Vector2):
	direction = _direction
