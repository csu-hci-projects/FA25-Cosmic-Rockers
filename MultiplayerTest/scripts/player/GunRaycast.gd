extends Gun

@export var ray_color: Color

var max_distance := 500.0
var ray_extend := 10

func _ready() -> void:
	super()
	var player_data = PlayerState.get_player_data(int(player_owner.entity_id))
	ray_color = PlayerState.COLORS[player_data.get("color", 0)]

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
