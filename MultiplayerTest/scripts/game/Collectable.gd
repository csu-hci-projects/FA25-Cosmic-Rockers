extends Area2D

var target: Node2D = null
var lerp_speed: float = 1

@onready var sprite = $Sprite2D

@export var float_amplitude: float = 5.0
@export var float_speed: float = 2.0

var _base_y: float
var _time: float = 0.0

func _ready():
	await get_tree().process_frame
	_base_y = position.y

func _process(delta: float) -> void:
	if !target:
		_time += delta * float_speed
		position.y = _base_y + sin(_time) * float_amplitude
	else:
		position = lerp(position, target.position, delta * lerp_speed)

func set_sprite(texture: Texture2D):
	sprite.texture = texture
