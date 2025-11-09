extends Sprite2D

@export var rotation_speed_deg: float = 90.0
@export var scaling_factor: float = 1.1
@export var scale_speed: float = 5

var _time := 0.0

func _process(delta: float) -> void:
	_time += delta
	
	rotation_degrees = fmod(rotation_degrees + rotation_speed_deg * delta, 360.0)
	var s = 1 + (sin(_time * TAU * scale_speed) * 0.5 + 0.5) * (scaling_factor - 1)
	scale = Vector2(s, s)
