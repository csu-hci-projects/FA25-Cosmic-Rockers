@tool
extends Node2D

@export var arm: Arm

func _process(_delta):
	queue_redraw()

func _draw():
	if !arm:
		return
	
	var target_position = arm.get_last_segment()
	draw_circle(target_position, 8, Color.RED)
