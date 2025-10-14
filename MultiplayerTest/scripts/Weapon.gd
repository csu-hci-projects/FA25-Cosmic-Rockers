extends Node2D

@export var projectile_scene: PackedScene
@export var fire_rate := 0.3
@export var damage := 15
@export var muzzle: Node2D

var can_fire := true
var owner_id: String

func shoot(direction: Vector2):
	if not can_fire or projectile_scene == null:
		return

	can_fire = false
	if $AudioStreamPlayer2D:
		$AudioStreamPlayer2D.play()
	
	# Spawn projectile
	var proj = projectile_scene.instantiate()
	proj.global_position = muzzle.global_position
	proj.direction = direction.normalized()
	proj.damage = damage
	proj.owner_id = owner_id
	get_tree().current_scene.add_child(proj)
	
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
