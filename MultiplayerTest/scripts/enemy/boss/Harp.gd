class_name Harp extends Sprite2D

@export var play_intensity = .6
@export var intensity_cooldown_rate = .3
var intensity_cooldowns = []

@export var string_parent: Node

func _ready() -> void:
	for i in range(string_parent.get_child_count()):
		add_midpoint(i)
		intensity_cooldowns.append(0.0)
		mute_string(i)

func add_midpoint(id: int):
	var string: Line2D = string_parent.get_child(id)
	var points = string.points
	if points.size() == 2:
		var midpoint: Vector2 = (points[0] + points[1]) / 2.0
		string.clear_points()
		string.add_point(points[0])
		string.add_point(midpoint)
		string.add_point(points[1])

func _process(delta: float):
	for i in intensity_cooldowns.size():
		if intensity_cooldowns[i] > 0:
			intensity_cooldowns[i] -= intensity_cooldown_rate * delta
			vibrate_string(i)
		else:
			mute_string(i)

func mute_string(id: int):
	if id < 0 or id >= string_parent.get_child_count():
		return
	
	var string: Line2D = string_parent.get_child(id)
	var points = string.points
	var midpoint: Vector2 = (points[0] + points[2]) / 2.0
	points[1] = midpoint
	
	string.clear_points()
	for point in points:
		string.add_point(point)

func vibrate_string(id: int):
	if id < 0 or id >= string_parent.get_child_count():
		return
	
	var string: Line2D = string_parent.get_child(id)
	var points = string.points
	var midpoint: Vector2 = (points[0] + points[2]) / 2.0
	points[1] = midpoint + Vector2(randf_range(-intensity_cooldowns[id], intensity_cooldowns[id]), randf_range(-intensity_cooldowns[id], intensity_cooldowns[id]))

	string.clear_points()
	for point in points:
		string.add_point(point)

func play_string(id: int):
	intensity_cooldowns[id] = play_intensity

func get_passed_strings(last_x: float, current_x: float) -> Array:
	var passed := []
	
	if current_x <= last_x:
		return passed
		
	for i in range(string_parent.get_child_count()):
		var string: Line2D = string_parent.get_child(i)
		
		var point_local = string.get_point_position(1)
		var point_in_viewport = string.to_global(point_local)
		var container = string.get_viewport().get_parent()
		var point_global = container.global_position + point_in_viewport
		
		if point_global.x > last_x and point_global.x <= current_x:
			passed.append(i)
	
	return passed
