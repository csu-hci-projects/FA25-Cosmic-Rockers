extends Camera2D

@export var target: Node2D
var follow_speed: float = 5

func _ready():
	Settings.on_zoom_changed.connect(_set_zoom)
	_set_zoom(Settings.get_zoom())

func _set_zoom(value: float):
	zoom = Vector2(value, value)

func _process(delta: float):
	if target:
		position = lerp(position, target.position, delta * follow_speed)

func set_target(node:Node2D, smooth: bool = true, _follow_speed: float = follow_speed):
	target = node
	if !smooth:
		position = target.position
	follow_speed = _follow_speed
