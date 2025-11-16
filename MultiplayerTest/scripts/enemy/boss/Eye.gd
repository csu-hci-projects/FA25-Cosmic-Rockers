@tool
class_name Eye extends Node2D

@export var look_target: Node2D
var _target_direction: Vector2

@export var arm: Arm
@export var eye_color: Color = Color.BLACK
@export var lid_color: Color = Color.BLACK
@export var pupil_color: Color = Color.BLACK
@export var outline_color: Color = Color.BLACK

@export var pupil_offset: float = -5
@export_range(0, 90, 1) var lid_angle: float = 40

@export var blink_interval_min: float = 2.0
@export var blink_interval_max: float = 5.0
@export var blink_duration: float = 0.1

var _blink_timer := 0.0
var _next_blink_time := 0.0
var _is_blinking := false

var parent_entity: Entity = null

func _process(delta):
	if Engine.is_editor_hint():
		_blink_timer += delta
		if !_is_blinking and _blink_timer >= _next_blink_time:
			blink()
	elif parent_entity and !parent_entity.is_dead:
		_blink_timer += delta
		if !_is_blinking and _blink_timer >= _next_blink_time:
			blink()
	else:
		lid_angle = 0
	
	queue_redraw()

func blink():
	_is_blinking = true
	_blink_timer = 0.0

	var tween = create_tween()
	tween.tween_property(self, "lid_angle", 0.0, blink_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "lid_angle", 40.0, blink_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func ():
		_is_blinking = false
		_blink_timer = 0.0
		_next_blink_time = randf_range(blink_interval_min, blink_interval_max)
	)

func _draw():
	if !arm:
		return
	
	var target_position = arm.get_last_segment()
	
	_target_direction = Vector2.LEFT
	if look_target:
		var look_target_position = arm.to_local(look_target.global_position)
		_target_direction = target_position.direction_to(look_target_position)
	var target_angle = atan2(-_target_direction.y, -_target_direction.x)
	arm.idle_force = _target_direction * Vector2(-1, 0)
	
	var top_angle = deg_to_rad(-180 + lid_angle) + target_angle
	var bottom_angle = deg_to_rad(180 - lid_angle) + target_angle
	
	draw_circle(target_position, 8, eye_color)
	draw_circle(target_position + _target_direction * pupil_offset, 2, pupil_color)
	
	draw_arc(target_position, 4, top_angle, bottom_angle, 50, lid_color, 8)
	draw_line(target_position, target_position + Vector2(cos(top_angle), sin(top_angle)) * 8, outline_color, 1)
	draw_line(target_position, target_position + Vector2(cos(bottom_angle), sin(bottom_angle)) * 8, outline_color, 1)
	draw_line(target_position, target_position + -2 * _target_direction, outline_color, 1)

func get_real_global_position() -> Vector2:
	return arm.get_last_segment_global() + _target_direction * pupil_offset
