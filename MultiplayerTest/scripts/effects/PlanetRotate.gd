@tool
extends Sprite2D

@export var speed: float = 10
@export var start_rotation: float = 0

func _ready() -> void:
	rotation_degrees = start_rotation

func _process(delta: float) -> void:
	rotate(speed * delta)
