extends Camera2D

@export var target: Node2D
var follow_speed: float = 5
var fast_speed: float = 10
var fast_distance = 50
var _speed = 0

func _process(delta: float):
	if target:
		if position.distance_to(target.position) > fast_distance:
			_speed = fast_speed
		else:
			_speed = follow_speed
		
		position = lerp(position, target.position, delta * _speed)

func set_target(node:Node2D, smooth: bool = true):
	target = node
	if !smooth:
		position = target.position
