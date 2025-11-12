@tool
extends Node2D

@export var arm: Arm
@export var eye_color: Color = Color.BLACK
@export var lid_color: Color = Color.BLACK
@export var pupil_color: Color = Color.BLACK
@export var outline_color: Color = Color.BLACK

@export var pupil_offset: Vector2 = Vector2(-5, 0)
@export_range(0, 90, 1) var lid_angle: float = 40

@export var blink_interval_min: float = 2.0
@export var blink_interval_max: float = 5.0
@export var blink_duration: float = 0.1

var _blink_timer := 0.0
var _next_blink_time := 0.0
var _is_blinking := false

var parent_entity: Entity = null

func _process(delta):
	if parent_entity and !parent_entity.is_dead:
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
	
	draw_circle(target_position, 8, eye_color)
	draw_circle(target_position + pupil_offset, 2, pupil_color)
	
	var top_angle = deg_to_rad(-180 + lid_angle)
	var bottom_angle = deg_to_rad(180 - lid_angle)
	
	draw_arc(target_position, 4, top_angle, bottom_angle, 50, lid_color, 8)
	draw_line(target_position, target_position + Vector2(cos(top_angle), sin(top_angle)) * 8, outline_color, 1)
	draw_line(target_position, target_position + Vector2(cos(bottom_angle), sin(bottom_angle)) * 8, outline_color, 1)
	draw_line(target_position, target_position + Vector2(2, 0), outline_color, 1)
