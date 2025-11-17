@tool
extends Node2D

@export var radius: float = 100.0:
	set(value):
		radius = value
		queue_redraw()

@export_range(0.0, 0.99, 0.01)
var eccentricity: float = 0.0:
	set(value):
		eccentricity = clamp(value, 0.0, 0.99)
		queue_redraw()

@export_range(0.0, 360.0, 1.0)
var orbit_rotation_deg: float = 0.0:
	set(value):
		orbit_rotation_deg = fmod(value, 360.0)
		queue_redraw()

@export var dot_count: int = 64:
	set(value):
		dot_count = max(1, value)
		queue_redraw()

@export var dot_size: float = 2.0:
	set(value):
		dot_size = value
		queue_redraw()

@export var dot_color: Color = Color(1, 1, 1, 1):
	set(value):
		dot_color = value
		queue_redraw()

@export var orbit_speed: float = 1.0  # revolutions per second
@export var animate_in_editor: bool = false

var _time: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _process(delta: float) -> void:
	# Only animate in-game or in-editor if explicitly allowed
	if not Engine.is_editor_hint() or animate_in_editor:
		_time += delta * orbit_speed
	queue_redraw()

func _draw() -> void:
	if radius <= 0 or dot_count <= 0:
		return

	var a = radius
	var b = a * sqrt(1.0 - eccentricity * eccentricity)
	var focus_offset = Vector2(-a * eccentricity, 0.0)
	var rot = deg_to_rad(orbit_rotation_deg)

	for i in range(dot_count):
		# Animate each dot's position along the orbit
		var phase = fmod(float(i) / dot_count + _time, 1.0)
		var angle = TAU * phase

		var x = cos(angle) * a
		var y = sin(angle) * b
		var pos = Vector2(x, y) + focus_offset
		pos = pos.rotated(rot)

		draw_circle(pos, dot_size, dot_color)
