extends Node2D
class_name GunProjectile

@export var projectile_scene: PackedScene = preload("res://scenes/game/Projectile.tscn")
@export var fire_rate := 0.3
@export var weapon_owner: Node
@export var gun_texture: Texture2D = preload("res://sprites/sprite_sheets/player/otamatone.png")

var can_fire := true

func _ready():
	if has_node("Sprite"):
		$Sprite.texture = gun_texture

func shoot():
	if not can_fire:
		return
	can_fire = false

	# spawn projectile
	var projectile = projectile_scene.instantiate()
	projectile.global_position = $Muzzle.global_position
	projectile.direction = Vector2.RIGHT.rotated(global_rotation)
	projectile.owner_id = owner.get_instance_id()

	get_tree().root.add_child(projectile)

	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
