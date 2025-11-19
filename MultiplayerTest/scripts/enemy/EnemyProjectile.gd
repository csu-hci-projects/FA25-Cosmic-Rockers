extends Area2D

var velocity: Vector2 = Vector2.ZERO
@export var damage: int = 5

func _physics_process(delta):
	position += velocity * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
