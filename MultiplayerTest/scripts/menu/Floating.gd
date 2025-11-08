@tool
extends Node2D

@export var amplitude: float = 10.0       # how far it moves
@export var speed: float = 1.0            # how fast it floats
@export var direction: Vector2 = Vector2(0, 1)  # movement direction
@export var rotation_amplitude: float = 5.0     # degrees of rotation sway

var _base_position: Vector2
var _base_rotation: float

@onready var ship: AnimatedSprite2D = $ship
var ship_target: Node2D = null

@export var travel_time: float = 4.0

var elapsed := 0.0
var start_pos: Vector2
var start_rot: float
var moving := false

func _ready():
	ship.play()
	_base_position = position
	_base_rotation = rotation_degrees
	
	if Engine.is_editor_hint():
		set_process(true)
		set_physics_process(true)
		set_notify_transform(true)
		set_notify_local_transform(true)

func move_to_target(target: Node2D):
	ship_target = target
	start_pos = ship.global_position
	elapsed = 0.0
	moving = true

func _process(delta: float):
	_apply_float_effect()
	if not moving or not ship_target:
		return

	elapsed += delta
	var t: float = clamp(elapsed / travel_time, 0.0, 1.0)

	var distance = start_pos.distance_to(ship_target.global_position)
	var control := (start_pos + ship_target.global_position) / 2.0 + Vector2(0, distance / 2)
	var pos := _bezier_point(start_pos, control, ship_target.global_position, t)
	ship.global_position = pos

	if t < 1.0:
		var next_t = clamp(t + 0.1, 0.0, 1.0)
		var next_pos = _bezier_point(start_pos, control, ship_target.global_position, next_t)
		var move_angle = (next_pos - pos).angle()

		ship.global_rotation = lerp_angle(ship.global_rotation, move_angle - PI / 2, 0.2)

	var scale_factor = lerp(1.0, 0.01, t)
	ship.scale = Vector2(scale_factor, scale_factor)

	if t >= 1.0:
		moving = false
		ship.visible = false

func _bezier_point(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2

func _editor_process(delta: float):
	_apply_float_effect()

func _apply_float_effect():
	if _base_position == Vector2.ZERO:
		_base_position = position
	if _base_rotation == 0.0:
		_base_rotation = rotation_degrees

	var t = Time.get_ticks_msec() / 1000.0 * speed
	var offset = sin(t) * amplitude
	var rot_offset = sin(t) * rotation_amplitude
	
	position = _base_position + direction.normalized() * offset
	rotation_degrees = _base_rotation + rot_offset
