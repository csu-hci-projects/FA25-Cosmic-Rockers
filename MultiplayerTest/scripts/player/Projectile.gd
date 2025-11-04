extends Area2D
class_name Projectile

@onready var explosion_particle_scene = preload("res://scenes/particles/explosion.tscn")

@export var shoot_velocity := 600.0
@export var lifetime := 5.0

var direction := Vector2.ZERO
var velocity := Vector2.ZERO
var gun_owner: Gun = null

func _ready() -> void:
	velocity = direction * shoot_velocity
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta: float) -> void:
	velocity.y += gravity * delta
	position += velocity * delta

func _on_body_entered(body: Node) -> void:
	gun_owner._handle_hit(body, position)
	
	var explosion_particle: CPUParticles2D = explosion_particle_scene.instantiate()
	explosion_particle.position = position
	get_tree().root.add_child(explosion_particle)
	explosion_particle.emitting = true
	
	queue_free()
