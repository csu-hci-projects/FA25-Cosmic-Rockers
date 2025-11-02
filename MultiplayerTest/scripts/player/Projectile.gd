extends Area2D
class_name Projectile

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
	queue_free()
