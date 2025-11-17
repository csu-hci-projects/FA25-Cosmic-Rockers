class_name SwordSlash
extends Gun

# Sword-specific properties
@export var swing_cooldown_time: float = 0
@export var dash_cooldown_time: float = 0.6
@export var dash_distance: float = 50.0      # distance the dash covers
@export var dash_time: float = 0.15           # duration of dash
@export var pogo_strength: float = 800.0
@export var slash_arc_angle: float = 45.0
@export var slash_ray_count: int = 5
@export var slash_range: float = 60.0
@export var slash_effect: PackedScene = preload("res://scenes/enemies/melee_effect.tscn")
@export var tilemap: TileMap = null

# Internal state
var dash_dir: Vector2 = Vector2.ZERO
var swing_cooldown: float = 0.0
var dash_cooldown: float = 0.0
var dash_timer: float = 0.0
var dash_velocity: Vector2 = Vector2.ZERO
var is_slashing := false
var post_dash_velocity: Vector2 = Vector2.ZERO
var post_dash_friction: float = 10.0 

func _process(delta: float) -> void:
	if not player_owner or player_owner.is_dead:
		return

	if player_owner.is_local_player:
		var mouse_pos = get_global_mouse_position()
		_set_direction((mouse_pos - global_position).normalized())

		swing_cooldown = max(0, swing_cooldown - delta)
		dash_cooldown = max(0, dash_cooldown - delta)

		# Sword input
		if Input.is_action_just_pressed("attack") and swing_cooldown <= 0:
			_slash()
		if (Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("alt_fire")) and dash_cooldown <= 0:
			_start_dash()
	else:
		direction = lerp(direction, target_direction, delta * 5)

	# Apply dash if active
	if dash_timer > 0:
		var move_amount = dash_velocity * delta
		player_owner.move_and_collide(move_amount)
		dash_timer -= delta
	else:
		# Apply post-dash momentum with friction
		if post_dash_velocity.length() > 0.1:
			player_owner.move_and_collide(post_dash_velocity * delta)
			post_dash_velocity = post_dash_velocity.move_toward(Vector2.ZERO, post_dash_friction * delta)
		else:
			post_dash_velocity = Vector2.ZERO

	# Update sprite flip
	if sprite:
		sprite.flip_h = direction.x < 0
		sprite.offset.x = sprite_offset if direction.x >= 0 else -sprite_offset
	if ray_start:
		ray_start.position.x = ray_offset if direction.x >= 0 else -ray_offset
	rotation = direction.angle()

func _slash():
	if not player_owner:
		return

	swing_cooldown = swing_cooldown_time
	is_slashing = true

	# Spawn visual effect
	if slash_effect:
		var effect_instance = slash_effect.instantiate()
		effect_instance.global_position = ray_start.global_position if ray_start else global_position
		effect_instance.rotation = direction.angle()
		get_tree().current_scene.add_child(effect_instance)

	var origin = ray_start.global_position if ray_start else global_position
	var space = get_world_2d().direct_space_state
	var base_angle = direction.angle()
	var half_arc = deg_to_rad(slash_arc_angle) / 2.0

	# Track enemies already hit so multiple rays can hit different targets
	var hit_enemies := []

	for i in range(slash_ray_count):
		var t = float(i) / float(max(slash_ray_count - 1, 1))
		var angle = base_angle - half_arc + t * deg_to_rad(slash_arc_angle)
		var dir = Vector2.RIGHT.rotated(angle)
		var to = origin + dir * slash_range

		var params = PhysicsRayQueryParameters2D.new()
		params.from = origin
		params.to = to
		params.exclude = [player_owner]
		params.collision_mask = 1
		params.collide_with_areas = true
		params.collide_with_bodies = true

		var result = space.intersect_ray(params)
		if result:
			var collider = result.collider
			if collider not in hit_enemies:
				_handle_hit(collider, result.position)
				hit_enemies.append(collider)

			# Tile breaking at collision point
			if tilemap:
				tilemap.take_hit(result.position, tile_damage)

	# Notify multiplayer
	if player_owner:
		Multiplayer.update_gun_shoot(Global.steam_id, {"type":"slash"})

func _start_dash():
	if not player_owner:
		return
	dash_cooldown = dash_cooldown_time
	dash_timer = dash_time

	dash_dir = direction.normalized()
	if dash_dir == Vector2.ZERO:
		dash_dir = Vector2.RIGHT if (sprite and not sprite.flip_h) else Vector2.LEFT
	dash_velocity = dash_dir * (dash_distance / dash_time)
	post_dash_velocity = dash_velocity  # initialize post-dash momentum


func _pogo():
	if not player_owner:
		return
	player_owner.velocity.y = -pogo_strength

# Override shoot to do nothing for sword
func _shoot():
	_slash()  # Optionally make left-click use sword

# Override multiplayer shoot call
func on_shoot(data: Dictionary):
	if data.has("type") and data["type"] == "slash":
		_slash()
