extends Gun

@export var swing_cooldown_time: float = 0
@export var dash_cooldown_time: float = 0.6
@export var dash_distance: float = 50.0     
@export var dash_time: float = 0.15           
@export var pogo_strength: float = 400.0
@export var slash_arc_angle: float = 45.0
@export var mining_ray_count: int = 5
@export var slash_range: float = 60.0
@export var slash_hitbox_radius: float = 25.0
@export var slash_duration: float = 0.3
@export var dash_momentum_time: float = 0.25
@export var slash_effect: PackedScene = preload("res://scenes/weapons/weapon anamation/slash.tscn")
@export var tilemap: TileMap = null
@export var aim_arrow_scene: PackedScene = preload("res://scenes/ui/aim_arrow.tscn")
@export var slash_hitbox_layer: int = 1
@export var slash_hitbox_mask: int = 1
@export var show_slash_preview: bool = true
@export var slash_preview_segments: int = 12
@export var preview_color: Color = Color(1, 1, 1, 0.35)
@export var active_slash_color: Color = Color(1, 0.2, 0.2, 0.6)
@export var enemy_layer_index: int = 4
@export var aim_arrow_distance: float = 40.0
@export var max_aim_time: float = 2.0
@export var disable_player_physics_during_aim: bool = true
@export var aim_preview_color: Color = Color(0.4, 0.8, 1.0, 0.5)
@export var alt_fire_action: StringName = &"alt_fire"
@export var aim_ring_radius: float = 36.0
@export var aim_drift_speed: float = 20.0
@export var aim_drift_max_speed: float = 6.0
@export var aim_shake_max_pixels: float = 1.5
@export var aim_shake_power: float = 2.0
@export var aim_shake_frequency: float = 18.0
@export var aim_preserve_velocity: bool = true
@export var aim_gravity_scale: float = 0.0
@export var aim_bullet_time_scale: float = 0.08

var swing_cooldown: float = 0.0
var dash_cooldown: float = 0.0
var dash_timer: float = 0.0
var dash_velocity: Vector2 = Vector2.ZERO
var is_slashing := false
var slash_timer: float = 0.0
var post_dash_timer: float = 0.0
var momentum_timer: float = 0.0
var momentum_velocity: Vector2 = Vector2.ZERO
var original_gravity := 0.0
var gravity_disabled := false
var slash_hitbox: Area2D = null
var slash_hit_enemies: Array = []
var slash_start_angle: float = 0.0
var is_aiming_dash := false
var aim_arrow: Node2D = null
var aim_arrow_sprite: AnimatedSprite2D = null
var aimed_dash_dir: Vector2 = Vector2.ZERO
var aim_time: float = 0.0
var warned_missing_alt_fire: bool = false
var dash_locked_until_ground: bool = false
var prev_on_floor: bool = false
var aim_drift_velocity: Vector2 = Vector2.ZERO
var stored_floor_snap_length: float = -1.0
var aim_shake_elapsed: float = 0.0
var aim_shake_current_offset: Vector2 = Vector2.ZERO
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var aim_entry_velocity: Vector2 = Vector2.ZERO
var aim_natural_velocity: Vector2 = Vector2.ZERO
var aim_scaled_velocity: Vector2 = Vector2.ZERO
var aim_prev_natural_velocity: Vector2 = Vector2.ZERO
var aim_original_input_dir: float = 0.0

func _ready() -> void:
	super()
	_create_slash_hitbox()
	set_physics_process(true)
	process_priority = 200
	if aim_arrow_scene:
		aim_arrow = aim_arrow_scene.instantiate()
		aim_arrow.visible = false
		get_tree().current_scene.add_child(aim_arrow)
		aim_arrow_sprite = aim_arrow.get_node_or_null("AnimatedSprite2D")
		if aim_arrow_sprite:
			aim_arrow_sprite.play()
			aim_arrow_sprite.visible = true

	rng.randomize()

func _create_slash_hitbox() -> void:
	slash_hitbox = Area2D.new()
	slash_hitbox.name = "SlashHitbox"
	add_child(slash_hitbox)
	
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = slash_hitbox_radius
	
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = circle_shape
	slash_hitbox.add_child(collision_shape)
	
	slash_hitbox.area_entered.connect(_on_slash_hitbox_entered)
	slash_hitbox.body_entered.connect(_on_slash_hitbox_entered)
	slash_hitbox.set_deferred("monitoring", false)
	slash_hitbox.monitoring = false
	slash_hitbox.monitorable = false
	var layer_mask_bit := 1 << int(max(slash_hitbox_layer - 1, 0))
	var detect_enemy_bit := 1 << int(max(enemy_layer_index - 1, 0))
	var extra_mask_bit := 1 << int(max(slash_hitbox_mask - 1, 0))
	slash_hitbox.collision_layer = layer_mask_bit
	slash_hitbox.collision_mask = detect_enemy_bit | extra_mask_bit
	if player_owner:
		slash_hitbox.collision_mask &= ~player_owner.collision_layer
	slash_hitbox.monitorable = true

	var first_entity: Entity = get_tree().get_first_node_in_group("entity")
	if first_entity:
		slash_hitbox.collision_mask |= first_entity.collision_layer

func _process(delta: float) -> void:
	if not player_owner or player_owner.is_dead:
		return

	if player_owner.is_local_player:
		var mouse_pos = get_global_mouse_position()
		_set_direction((mouse_pos - global_position).normalized())

		swing_cooldown = max(0, swing_cooldown - delta)
		dash_cooldown = max(0, dash_cooldown - delta)

		if Input.is_action_just_pressed("attack") and swing_cooldown <= 0:
			_slash()

		var has_alt := InputMap.has_action(alt_fire_action)
		if not has_alt and not warned_missing_alt_fire:
			print("[SwordSlash] WARN: action '", alt_fire_action, "' not found in InputMap")
			warned_missing_alt_fire = true
		var alt_action_pressed := has_alt and Input.is_action_pressed(alt_fire_action)
		var rmb_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		var alt_fire_pressed := alt_action_pressed or rmb_pressed
		if alt_fire_pressed:
			if not is_aiming_dash and not dash_locked_until_ground:
				print("[SwordSlash] alt_fire pressed -> start aim (action=", alt_action_pressed, ", rmb=", rmb_pressed, ")")
				_start_dash_aim()
			elif dash_locked_until_ground and not is_aiming_dash:
				print("[SwordSlash] Dash locked until you land")
		else:
			if is_aiming_dash:
				print("[SwordSlash] alt_fire released -> commit dash")
				_commit_dash()

		if alt_fire_pressed and not is_aiming_dash and dash_timer > 0:
			print("[SwordSlash] DEBUG: dash_timer=", dash_timer, " but aim still allowed")
	else:
		direction = lerp(direction, target_direction, delta * 5)

	if slash_timer > 0:
		slash_timer -= delta
		if slash_hitbox and slash_hitbox.monitoring:
			var slash_angle = slash_start_angle + (1.0 - (slash_timer / slash_duration)) * deg_to_rad(slash_arc_angle)
			var hitbox_offset = Vector2.RIGHT.rotated(slash_angle) * slash_range
			slash_hitbox.global_position = global_position + hitbox_offset
			slash_hitbox.rotation = slash_angle
			var bodies = slash_hitbox.get_overlapping_bodies()
			for b in bodies:
				if b == player_owner or b.get_parent() == player_owner:
					continue
				if b is Entity and b not in slash_hit_enemies:
					slash_hit_enemies.append(b)
					_handle_hit(b, b.global_position)
					var vb: Vector2 = (b.global_position - global_position)
					if vb.length() > 0.0:
						var dn: float = vb.normalized().dot(Vector2.DOWN)
						if dn >= 0.70710678:
							_pogo()
			var areas = slash_hitbox.get_overlapping_areas()
			for a in areas:
				if a == player_owner or a.get_parent() == player_owner:
					continue
				if a is Entity and a not in slash_hit_enemies:
					slash_hit_enemies.append(a)
					_handle_hit(a, a.global_position)
					var va: Vector2 = (a.global_position - global_position)
					if va.length() > 0.0:
						var dna: float = va.normalized().dot(Vector2.DOWN)
						if dna >= 0.70710678:
							_pogo()
		
		if slash_timer <= 0:
			slash_hitbox.set_deferred("monitoring", false)
			slash_hit_enemies.clear()

	if is_aiming_dash and dash_timer > 0:
		dash_timer = 0
		momentum_timer = 0
		player_owner.is_dashing = false

	if dash_timer > 0 and not is_aiming_dash:
		player_owner.velocity = dash_velocity
		player_owner.gravity_enabled = false
		dash_timer -= delta

		if player_owner.is_on_floor() and dash_velocity.y > 0:
			dash_timer = 0
			momentum_timer = 0
			player_owner.is_dashing = false
			player_owner.gravity_enabled = true
			player_owner.velocity.y = -pogo_strength * 0.5

	elif momentum_timer > 0:
		player_owner.velocity = momentum_velocity
		momentum_timer -= delta

		momentum_velocity = momentum_velocity.lerp(Vector2.ZERO, delta * 3.0)

		if momentum_timer <= 0:
			player_owner.gravity_enabled = true
			player_owner.is_dashing = false

	else:
		player_owner.is_dashing = false
		player_owner.gravity_enabled = true

	if is_aiming_dash:
		aim_time += delta
		player_owner.gravity_enabled = true
		var mpos = get_global_mouse_position()
		aimed_dash_dir = (mpos - global_position).normalized()
		if aim_arrow:
			aim_arrow.visible = true
			if aim_arrow_sprite and not aim_arrow_sprite.is_playing():
				aim_arrow_sprite.play()
			# Centered jitter (vibrate in place) with frequency-stepped updates
			aim_shake_elapsed += delta
			var update_interval: float = 1.0 / max(aim_shake_frequency, 0.01)
			if aim_shake_elapsed >= update_interval:
				aim_shake_elapsed = 0.0
				var progress: float = clamp(aim_time / max_aim_time, 0.0, 1.0)
				var late_progress: float = 0.0
				if progress >= 0.5:
					late_progress = (progress - 0.5) / 0.5
				var amp: float = aim_shake_max_pixels * pow(late_progress, aim_shake_power)
				var angle := rng.randf_range(0.0, TAU)
				var radius: float = 0.0
				if amp > 0.0:
					radius = rng.randf() * amp
				aim_shake_current_offset = Vector2(cos(angle), sin(angle)) * radius
			var base_pos := global_position + aimed_dash_dir * aim_arrow_distance
			aim_arrow.global_position = base_pos + aim_shake_current_offset
			aim_arrow.rotation = aimed_dash_dir.angle()
		if aim_time >= max_aim_time:
			_commit_dash()

	if ray_start:
		ray_start.position.x = ray_offset if direction.x >= 0 else -ray_offset
	rotation = direction.angle()
	if player_owner and player_owner.is_local_player and show_slash_preview:
		queue_redraw()

	if dash_locked_until_ground and player_owner.is_on_floor() and dash_timer <= 0 and not is_aiming_dash:
		dash_locked_until_ground = false
		print("[SwordSlash] Dash reset on landing")
	prev_on_floor = player_owner.is_on_floor()

func _physics_process(delta: float) -> void:
	if not player_owner:
		return
	if is_aiming_dash:
		player_owner.gravity_enabled = false
		var s: float = clamp(aim_bullet_time_scale, 0.0, 1.0)
		var gravity_vec: Vector2 = player_owner.get_gravity()
		var natural_v: Vector2 = player_owner.velocity
		if aim_scaled_velocity == Vector2.ZERO:
			aim_scaled_velocity = natural_v * s
		# Horizontal carries entry momentum, slowed by s (prevents input-based decay)
		aim_scaled_velocity.x = aim_entry_velocity.x * s
		# Vertical integrates scaled gravity (s^2 for true time scaling)
		aim_scaled_velocity.y += gravity_vec.y * (s * s) * delta
		# Optional extra gravity blend toward natural step if desired
		if aim_gravity_scale > 0.0:
			var natural_step_y: float = natural_v.y + gravity_vec.y * delta
			aim_scaled_velocity.y = lerp(aim_scaled_velocity.y, natural_step_y * s, clamp(aim_gravity_scale, 0.0, 1.0))
		player_owner.velocity = aim_scaled_velocity

func _slash():
	if not player_owner:
		return

	swing_cooldown = swing_cooldown_time
	is_slashing = true
	slash_timer = slash_duration
	slash_hit_enemies.clear()

	slash_start_angle = direction.angle() - deg_to_rad(slash_arc_angle) / 2.0

	if slash_hitbox:
		slash_hitbox.set_deferred("monitoring", true)
		slash_hitbox.set_deferred("monitorable", true)

	var game_controller: GameController = get_tree().get_first_node_in_group("GameController")
	if game_controller and game_controller.tilemap:
		var base_angle := direction.angle()
		var half_arc := deg_to_rad(slash_arc_angle) / 2.0
		var mined_cells := {}
		for i in range(mining_ray_count):
			var t := float(i) / float(max(mining_ray_count - 1, 1))
			var angle := base_angle - half_arc + t * deg_to_rad(slash_arc_angle)
			var hit_pos := global_position + Vector2.RIGHT.rotated(angle) * slash_range
			var local_pos: Vector2 = game_controller.tilemap.to_local(hit_pos)
			var cell: Vector2i = game_controller.tilemap.local_to_map(local_pos)
			var cell_key := str(cell.x, ":", cell.y)
			if not mined_cells.has(cell_key):
				mined_cells[cell_key] = true
				var cell_count = game_controller.tilemap.take_hit(hit_pos, tile_damage)
				PlayerState.add_stat(PlayerState.STAT.BLOCKS_BROKEN, cell_count)

	if slash_effect:
		var effect_instance = slash_effect.instantiate()
		# Parented to this weapon (which already rotates to face `direction`).
		# Use local space offset and zero local rotation to avoid double-rotation.
		effect_instance.position = Vector2.RIGHT * slash_range
		effect_instance.rotation = 0.0
		add_child(effect_instance)

func _on_slash_hitbox_entered(collider: Node2D):
	if not player_owner or not player_owner.is_local_player:
		return
	
	if collider in slash_hit_enemies:
		return
	if collider == player_owner or collider.get_parent() == player_owner:
		return
	
	slash_hit_enemies.append(collider)
	if collider is Entity:
		print("Sword hit entity: ", collider.name)
	_handle_hit(collider, collider.global_position)
	var vc: Vector2 = (collider.global_position - global_position)
	if vc.length() > 0.0:
		var dnc: float = vc.normalized().dot(Vector2.DOWN)
		if dnc >= 0.70710678:
			_pogo()

func _draw():
	if not show_slash_preview:
		return
	var color := preview_color
	if is_slashing:
		color = active_slash_color
	var base_angle := 0.0
	var half_arc := deg_to_rad(slash_arc_angle) / 2.0
	var prev_point: Vector2 = Vector2.RIGHT.rotated(-half_arc) * slash_range
	for i in range(1, slash_preview_segments + 1):
		var t := float(i) / float(slash_preview_segments)
		var angle := -half_arc + t * deg_to_rad(slash_arc_angle)
		var point := Vector2.RIGHT.rotated(angle) * slash_range
		draw_line(prev_point, point, color, 2)
		prev_point = point
	var mid_center := Vector2.RIGHT * slash_range
	draw_circle(mid_center, slash_hitbox_radius, color)
	if is_aiming_dash:
		draw_circle(Vector2.ZERO, aim_ring_radius, aim_preview_color)

func _start_dash_aim():
	if not player_owner:
		return
	if player_owner.is_dead:
		return
	is_aiming_dash = true
	aim_time = 0.0
	aimed_dash_dir = direction if direction != Vector2.ZERO else Vector2.RIGHT
	var v := player_owner.velocity
	var hx := 0.0
	if abs(v.x) > 0.01:
		hx = sign(v.x) * min(abs(v.x), aim_drift_max_speed)
	var vy := 0.0
	if v.y < 0.0:
		vy = v.y
	aim_drift_velocity = Vector2(hx, vy)
	aim_shake_elapsed = 0.0
	if aim_arrow:
		aim_arrow.visible = true
		if aim_arrow_sprite:
			aim_arrow_sprite.play()
	else:
		if aim_arrow_scene:
			aim_arrow = aim_arrow_scene.instantiate()
			get_tree().current_scene.add_child(aim_arrow)
			aim_arrow.visible = true
			aim_arrow_sprite = aim_arrow.get_node_or_null("AnimatedSprite2D")
			if aim_arrow_sprite:
				aim_arrow_sprite.play()
	print("[SwordSlash] Aim start")
	player_owner.is_dashing = true
	aim_entry_velocity = player_owner.velocity
	aim_natural_velocity = Vector2.ZERO
	aim_scaled_velocity = Vector2.ZERO
	aim_prev_natural_velocity = Vector2.ZERO
	if "input_dir" in player_owner:
		player_owner.input_dir = 0.0
	player_owner.gravity_enabled = false
	player_owner.set_physics_process(true)
	if player_owner is CharacterBody2D:
		stored_floor_snap_length = player_owner.floor_snap_length
		player_owner.floor_snap_length = 0.0
	if slash_hitbox:
		slash_hitbox.set_deferred("monitoring", false)

func _cancel_dash_aim():
	is_aiming_dash = false
	aim_time = 0.0
	if aim_arrow:
		aim_arrow.visible = false
		if aim_arrow_sprite:
			aim_arrow_sprite.stop()
	player_owner.gravity_enabled = true
	player_owner.is_dashing = false
	# Restore natural momentum when exiting without dash
	if aim_prev_natural_velocity != Vector2.ZERO:
		player_owner.velocity = aim_prev_natural_velocity
	if "input_dir" in player_owner:
		player_owner.input_dir = Input.get_axis("move_left", "move_right")
	if disable_player_physics_during_aim:
		player_owner.set_physics_process(true)
	if stored_floor_snap_length >= 0.0 and player_owner is CharacterBody2D:
		player_owner.floor_snap_length = stored_floor_snap_length
		stored_floor_snap_length = -1.0

func _commit_dash():
	if not is_aiming_dash:
		return
	_cancel_dash_aim()
	var commit_dir = aimed_dash_dir if aimed_dash_dir != Vector2.ZERO else direction
	print("[SwordSlash] Aim commit dash")
	dash_locked_until_ground = true
	_start_dash(commit_dir)

func _start_dash(dash_dir: Vector2):
	if not player_owner:
		return
	dash_cooldown = dash_cooldown_time
	dash_timer = dash_time
	momentum_timer = dash_momentum_time
	player_owner.is_dashing = true
	if dash_dir == Vector2.ZERO:
		dash_dir = Vector2.RIGHT if (sprite and not sprite.flip_h) else Vector2.LEFT
	dash_dir = dash_dir.normalized()
	dash_velocity = dash_dir * (dash_distance / dash_time)
	momentum_velocity = dash_velocity

func _pogo():
	if not player_owner:
		return
	player_owner.velocity.y = -pogo_strength
	dash_cooldown = 0.0
	dash_locked_until_ground = false
	if dash_timer > 0:
		dash_timer = 0.0
		momentum_timer = 0.0
		player_owner.is_dashing = false
		player_owner.gravity_enabled = true

func _shoot():
	_slash()

func on_shoot(data: Dictionary):
	if data.has("type") and data["type"] == "slash":
		_slash()
