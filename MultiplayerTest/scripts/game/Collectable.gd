class_name Collectable
extends Area2D

var game_controller
var target: Node2D = null
var lerp_speed: float = 10

@onready var sprite = $Sprite2D

@export var float_amplitude: float = 5.0
@export var float_speed: float = 2.0

var _base_y: float
var _time: float = 0.0

func _ready():
	await get_tree().process_frame
	_base_y = position.y
	
	Multiplayer.on_received_collectable.connect(_on_collectable_update)

func _process(delta: float) -> void:
	if !target:
		_time += delta * float_speed
		position.y = _base_y + sin(_time) * float_amplitude
	else:
		position = lerp(position, target.position, delta * lerp_speed)

func set_sprite(texture: Texture2D):
	sprite.texture = texture

func _on_body_entered(body: Node2D) -> void:
	if !target and body is PlayerMovement and body.is_local_player:
		body.grab_collectable(self)
		_set_target(body)

func _on_collectable_update(steam_id: int, data: Dictionary):
	if data["carrying"]:
		var player = game_controller.get_entity(str(steam_id))
		_set_target(player)
	else:
		_set_target(null)

func _set_target(player: Node2D):
	target = player
	if !target:
		_base_y = position.y
