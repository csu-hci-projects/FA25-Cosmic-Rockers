extends Entity

@export var harp: Harp
@export var move_speed := 1.0

@export var arm_1: Arm
@export var arm_1_target: PathFollow2D
@export var arm_2: Arm
@export var arm_2_target: PathFollow2D

var arms: Array = []

var death_target_scene = preload("res://scenes/enemies/boss/death_target.tscn")
@export var target_speed: float = 200.0
@export var target_lifetime: float = 2.0

class ArmState:
	var arm: Arm
	var target: PathFollow2D
	var last_pos: Vector2
	var strings_played: Array[int] = []
	
	func _init(_arm: Arm, _target: PathFollow2D):
		arm = _arm
		target = _target
		last_pos = _target.global_position
		strings_played = []

func _ready():
	super()
	arms.append(ArmState.new(arm_1, arm_1_target))
	arms.append(ArmState.new(arm_2, arm_2_target))
	arm_2_target.progress_ratio = 0.5

func _process(delta: float):
	if !is_dead:
		for arm_state in arms:
			move_arm_target_along_path(arm_state, delta)

func move_arm_target_along_path(arm_state: ArmState, delta: float):
	var target = arm_state.target
	var last_pos = arm_state.last_pos
	var strings_played = arm_state.strings_played

	if target.progress_ratio + delta * move_speed >= 1.0:
		target.progress_ratio = 0.0
		strings_played.clear()

	target.progress_ratio += delta * move_speed

	if target.global_position.x > last_pos.x:
		var passed_strings = harp.get_passed_strings(last_pos.x, target.global_position.x)
		for string_index in passed_strings:
			if !strings_played.has(string_index):
				harp.play_string(string_index)
				strings_played.append(string_index)

	arm_state.last_pos = target.global_position

func die():
	super()
	spawn_death_targets()

func spawn_death_targets():
	for arm in arms:
		var arm_obj: Arm = arm.arm
		var target = death_target_scene.instantiate()
		add_child(target)
		target.global_position = arm.target.global_position
		arm_obj.target = target
		arm_obj.is_dead = true

		var angle_deg = randf_range(-25, 25)
		var angle_rad = deg_to_rad(angle_deg - 90)
		var vel = Vector2(cos(angle_rad), sin(angle_rad)) * target_speed
		target.linear_velocity = vel
