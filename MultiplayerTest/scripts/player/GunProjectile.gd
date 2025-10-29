extends Gun
class_name GunProjectile

@export var projectile_scene: PackedScene = preload("res://scenes/game/projectile.tscn")

func _ready():
	super()

func _shoot():
	var from = global_position
	var to = get_global_mouse_position()
	
	on_shoot({"from": from, "to": to})
	Multiplayer.update_gun_shoot(from, to)

func on_shoot(data: Dictionary):
	var from = data["from"]
	var to = data["to"]
	var shoot_direction = (to - from).normalized()
	
	var projectile = projectile_scene.instantiate()
	projectile.global_position = ray_start.global_position
	projectile.direction = shoot_direction
	projectile.gun_owner = self

	get_tree().root.add_child(projectile)
