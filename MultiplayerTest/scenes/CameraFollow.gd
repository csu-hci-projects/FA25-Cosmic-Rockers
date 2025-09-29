extends Camera2D

@export var target: Node2D

func _process(delta: float):
	if target:
		position = lerp(position, target.position, delta * 5)
