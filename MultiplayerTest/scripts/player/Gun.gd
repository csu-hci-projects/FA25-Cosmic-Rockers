extends Node2D

@export var damage = 10

@onready var ray_start = $ray_start
@onready var sprite = $sprite

var sprite_offset = 0
var ray_offset = 0
var max_distance := 500.0

func _ready() -> void:
	sprite_offset = sprite.offset.x
	ray_offset = ray_start.position.x

func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	
	if dir.x > 0:
		sprite.flip_h = false
		sprite.offset.x = sprite_offset
		ray_start.position.x = ray_offset
		rotation = atan2(dir.y, dir.x)
	elif dir.x < 0:
		sprite.flip_h = true
		sprite.offset.x = -sprite_offset
		ray_start.position.x = -ray_offset
		rotation = atan2(-dir.y, -dir.x)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_shoot()

func _shoot():
	var space_state = get_world_2d().direct_space_state
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()

	var to_position = global_position + dir * max_distance
	var query = PhysicsRayQueryParameters2D.create(global_position, to_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = (1 << 0) | (1 << 2) #set bits 0 and 2 (layers 1 and 3) to 1

	var result = space_state.intersect_ray(query)
	
	if result.size() > 0:
		if result.has("collider") and result["collider"] is Node2D:
			_handle_hit(result["collider"], result["position"])
	
	var hit_position: Vector2 = result.get("position", to_position)
	var line = Line2D.new()
	line.width = 1
	line.default_color = Color("#FF0147")
	line.add_point(ray_start.global_position)
	line.add_point(hit_position)

	get_tree().root.add_child(line)

	await get_tree().create_timer(0.1).timeout
	line.queue_free()

func _handle_hit(object: Node2D, hit_position: Vector2):
	if object is Entity:
		object.take_damage(damage)
	
	if object is Tilemap:
		object.take_hit(hit_position)
