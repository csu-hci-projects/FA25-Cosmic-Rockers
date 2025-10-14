extends Area2D

@export var speed := 500
var damage := 10
var owner_id: String
var direction := Vector2.RIGHT
@export var lifetime := 2.0

func _ready():
	connect("body_entered", _on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body == null:
		return

	# Damage enemies / players
	if body is Entity and body.entity_id != owner_id:
		body.take_damage(damage)
		body.set_meta("last_attacker", owner_id)
		queue_free()
	
	# Destroy breakable blocks
	elif body.has_method("apply_damage"):
		body.apply_damage(damage)
		queue_free()
