extends Gun
class_name GunProjectile

@export var projectile_scene: PackedScene = preload("res://scenes/game/projectile.tscn")
@export var recoil_velocity: float = 600
@export var recoil_distance: float = 50

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

func _handle_hit(object: Node2D, hit_position: Vector2):
	super(object, hit_position)
	recoil(hit_position)

func recoil(hit_position: Vector2):
	if not player_owner.is_local_player:
		return
	
	var distance = hit_position.distance_to(player_owner.position)
	var direction = hit_position.direction_to(player_owner.position)
	
	if distance <= recoil_distance:
		player_owner.jump_buffer = 0
		player_owner.coyote_timer = 0
		player_owner.velocity = direction * recoil_velocity
		player_owner.move_and_slide()
