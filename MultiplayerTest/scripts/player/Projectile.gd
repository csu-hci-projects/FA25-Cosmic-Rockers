extends Area2D
class_name Projectile

@export var speed := 800.0
@export var damage := 10
@export var lifetime := 2.0
@export var projectile_texture: Texture2D = preload("res://sprites/sprite_sheets/player/note.png")

var direction := Vector2.ZERO
var owner_id: int = 0

func _ready() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.texture = projectile_texture
	connect("body_entered", Callable(self, "_on_body_entered"))
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body is Entity and body.get_instance_id() != owner_id:
		body.take_damage(damage)
	queue_free()
