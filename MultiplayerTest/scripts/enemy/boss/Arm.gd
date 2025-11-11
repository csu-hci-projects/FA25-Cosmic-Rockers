@tool
class_name Arm extends Node2D

#region Exports
@export_group("Node References")
@export var base_node: Line2D:
	set(value):
		base_node = value
		if base_node:
			_base_position = base_node.global_position
		_apply_line_width()
		_apply_width_curve()
		_initialize_segments()

@export var target: Node2D

@export_group("IK Configuration")
@export_range(3, 50, 1) var num__segments: int = 24:
	set(value):
		num__segments = value
		_initialize_segments()
@export var max_length: float = 128.0:
	set(value):
		max_length = value
		_initialize_segments()
@export_range(1, 10, 1) var ik_iterations: int = 2
@export_range(1, 20, 1) var constraint_iterations: int = 10
@export var enable_contraint: bool = true

@export_group("Wave Motion")
@export_range(0.0, 5.0, 0.5) var wave_amplitude: float = 2.5
@export_range(0.0, 5, 0.1) var wave_frequency: float = 2.0
@export_range(0.0, 10.0, 0.1) var wave_speed: float = 3.0

@export_group("Force")
@export var idle_force: Vector2 = Vector2.ZERO
@export var idle_force_strength: float = 0.0

@export_group("Visual Properties")
@export_range(1.0, 100.0, 0.5) var line_width: float = 24.0:
	set(value):
		line_width = value
		_apply_line_width()
@export var width_curve: Curve:
	set(value):
		width_curve = value
		_apply_width_curve()

#endregion

#region Private Var
var _segments: Array[Vector2] = []
var _segment_lengths: Array[float] = []
var _base_position: Vector2
var _wave_time: float = 0.0
var is_dead: bool = false
#endregion


func _ready() -> void:
	if base_node:
		_base_position = base_node.global_position
	_initialize_segments()


func _physics_process(delta: float) -> void:
	var target_pos: Vector2 = target.global_position if target else get_global_mouse_position()
	target_pos += _base_position - global_position
	solve_ik(target_pos)
	apply_constraints()
	
	if !is_dead:
		apply_wave_motion(delta)
		apply_constraints()
		apply_idle_force(delta)
		apply_constraints()

	update_line2d()


func solve_ik(target_position: Vector2) -> void:
	_segments[-1] = target_position

	for _iter in range(ik_iterations):
		for i in range(num__segments - 1, -1, -1):
			var vec: Vector2 = _segments[i] - _segments[i + 1]
			var direction: Vector2 = vec.normalized()
			_segments[i] = _segments[i + 1] + direction * _segment_lengths[i]

		_segments[0] = _base_position
		for i in range(num__segments):
			var vec: Vector2 = _segments[i + 1] - _segments[i]
			var direction: Vector2 = vec.normalized()
			_segments[i + 1] = _segments[i] + direction * _segment_lengths[i]


func apply_idle_force(delta: float) -> void:
	if idle_force == Vector2.ZERO or idle_force_strength <= 0.0:
		return

	# Apply the idle force evenly across all segments except the base
	for i in range(1, _segments.size()):
		_segments[i] += idle_force.normalized() * idle_force_strength * delta


func apply_constraints() -> void:
	if not enable_contraint:
		return
	_segments[0] = _base_position

	for _iter in range(constraint_iterations):
		for i in range(num__segments):
			var current_vec: Vector2 = _segments[i + 1] - _segments[i]
			var distance: float = current_vec.length()

			if distance < 0.0001:
				_segments[i + 1] = _segments[i] + Vector2.RIGHT * _segment_lengths[i]
				continue

			var target_vec: Vector2 = current_vec.normalized() * _segment_lengths[i]
			var error_vec: Vector2 = target_vec - current_vec

			if i > 0:
				_segments[i] -= error_vec * 0.25
			_segments[i + 1] += error_vec * 0.25

		_segments[0] = _base_position


func apply_wave_motion(delta: float) -> void:
	if wave_amplitude <= 0.0:
		return

	_wave_time += delta * wave_speed

	var total_length: float = 0.0
	for length in _segment_lengths:
		total_length += length

	var accumulated_length: float = 0.0
	for i in range(1, _segments.size()):
		accumulated_length += _segment_lengths[i - 1]

		var t: float = accumulated_length / total_length

		var vec: Vector2 = _segments[i] - _segments[i - 1]
		var direction: Vector2 = vec.normalized()
		var perpendicular: Vector2 = direction.orthogonal()

		var wave_phase: float = _wave_time + t * wave_frequency * TAU
		var wave_offset: float = sin(wave_phase) * wave_amplitude
		_segments[i] += perpendicular * wave_offset


func update_line2d() -> void:
	base_node.clear_points()
	for pos in _segments:
		base_node.add_point(base_node.to_local(pos))

func _initialize_segments() -> void:
	if not base_node:
		return

	_segments.clear()
	_segment_lengths.clear()

	_segments.append(_base_position)
	for i in range(num__segments):
		var length: float = max_length / num__segments
		_segment_lengths.append(length)
		_segments.append(_base_position + Vector2(length * (i + 1), 0))

	update_line2d()


func _apply_line_width() -> void:
	if base_node:
		base_node.width = line_width


func _apply_width_curve() -> void:
	if not width_curve:
		return

	if base_node:
		base_node.width_curve = width_curve

func get_segments() -> Array[Vector2]:
	return _segments


func get_segment_lengths() -> Array:
	return _segment_lengths


func get_last_segment() -> Vector2:
	return base_node.to_local(_segments[-1])
