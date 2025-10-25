extends Node2D

@export var damage = 10
@export var ray_color: Color

@onready var ray_start = $ray_start
@onready var sprite = $sprite

var sprite_offset = 0
var ray_offset = 0
var max_distance := 500.0
var ray_extend := 10

var direction: Vector2
var target_direction: Vector2

var player_owner: PlayerMovement = null

func _ready() -> void:
	sprite_offset = sprite.offset.x
	ray_offset = ray_start.position.x
	player_owner = find_parent("player")
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
	var space_state = get_world_2d().direct_space_state
	var mouse_pos = get_global_mouse_position()
	var shoot_direction = (mouse_pos - global_position).normalized()

	var to_position = global_position + shoot_direction * max_distance
	var query = PhysicsRayQueryParameters2D.create(global_position, to_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = (1 << 3) #set bit 3 (layer 4) to 1

	var result = space_state.intersect_ray(query)
	
	if result.has("collider") and result["collider"] is Node2D:
		_handle_hit(result["collider"], result["position"])
	
	var hit_position: Vector2 = result.get("position", to_position)
	var from = ray_start.global_position
	var to = hit_position + (ray_extend * shoot_direction)
	
	on_shoot(0, {"from": from, "to": to})
	Multiplayer.update_gun_shoot(from, to)

func on_set_direction(_steam_id: int, data: Dictionary):
	target_direction = data["direction"]

func on_shoot(_steam_id: int, data: Dictionary):
	var from = data["from"]
	var to = data["to"]
	var line = Line2D.new()
	line.width = 1
	line.default_color = ray_color
	line.add_point(from)
	line.add_point(to)

	get_tree().root.add_child(line)

	await get_tree().create_timer(0.1).timeout
	line.queue_free()

func _handle_hit(object: Node2D, hit_position: Vector2):
	if object is Entity:
		object.take_damage(damage)
	
	if object is Tilemap:
		object.take_hit(hit_position)

func _set_direction(_direction: Vector2):
	direction = _direction
