extends Enemy

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 300.0
@export var mouth_offset: Vector2 = Vector2(10, -5) # relative to sprite
@export var shoot_anim: String = "shoot"

func _attack_behavior(delta: float) -> void:
	# Shooter enemies don't move during attack
	move_dir = Vector2.ZERO
	
	if _attack_timer <= 0.0 and _target:
		_shoot_projectile()
		_attack_timer = attack_cooldown

func _shoot_projectile():
	# Flip to face target
	if _target.position.x > position.x:
		sprite.flip_h = false
	else:
		sprite.flip_h = true

	# Play attack animation
	set_animation(shoot_anim)
	
	# Spawn projectile
	var proj = projectile_scene.instantiate()

	# Determine direction
	var direction = (_target.global_position - global_position).normalized()

	# Spawn point at mouth
	var mouth_global_pos = global_position
	var offset = mouth_offset

	# Flip offset depending on direction
	if direction.x < 0:
		offset.x *= -1

	mouth_global_pos += offset

	proj.global_position = mouth_global_pos

	# Give projectile velocity (assumes projectile has a velocity variable)
	if proj.has_variable("velocity"):
		proj.velocity = direction * projectile_speed
	elif proj.has_method("set_velocity"):
		proj.set_velocity(direction * projectile_speed)

	# Add to scene tree
	get_tree().root.add_child(proj)

	# Damage signal (optional for logging)
	emit_signal("on_attack_player", entity_id, _target.entity_id, dmg)
