extends Enemy

@export var jump_force : float = 400.0

func move():
	var horizontal_dir = sign(move_dir.x)
	velocity.x = horizontal_dir * move_speed
	
	var space_state := get_world_2d().direct_space_state
	var start := global_position
	var end := start + Vector2(20 * horizontal_dir, 0)
	
	var query := PhysicsRayQueryParameters2D.create(start, end)
	query.collision_mask = 1
	
	var result := space_state.intersect_ray(query)
	
	if result:
		_jump()

func _jump():
	if is_on_floor():
		velocity.y = -jump_force
