class_name Harp extends Sprite2D

@export var play_intensity = .6
@export var intensity_cooldown_rate = .3
var intensity_cooldowns = []

func _ready() -> void:
	for i in range(get_child_count()):
		intensity_cooldowns.append(0.0)
		mute_string(i)

func _process(delta: float):
	for i in intensity_cooldowns.size():
		if intensity_cooldowns[i] > 0:
			intensity_cooldowns[i] -= intensity_cooldown_rate * delta
			vibrate_string(i)
		else:
			mute_string(i)

func mute_string(id: int):
	if id < 0 or id >= get_child_count():
		return
	
	var string: Line2D = get_child(id)
	var points = string.points
	var midpoint: Vector2 = (points[0] + points[2]) / 2.0
	points[1] = midpoint
	
	string.clear_points()
	for point in points:
		string.add_point(point)

func vibrate_string(id: int):
	if id < 0 or id >= get_child_count():
		return
	
	var string: Line2D = get_child(id)
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

	for i in range(get_child_count()):
		var string: Line2D = get_child(i)
		var point_x = string.to_global(string.get_point_position(1)).x

		if point_x > last_x and point_x <= current_x:
			passed.append(i)
	
	return passed
