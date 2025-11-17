class_name EnemyBoss extends Entity

enum State {
	IDLE,
	ATTACK_LASER,
	ATTACK_PROJECTILE,
	ATTACK_MELEE,
	DEAD
}

var current_state : State = State.IDLE
var player_target: PlayerMovement

var _attack_timer: float

@export_group("Attack")
@export var attack_timer: float = 1
var is_attacking = false
var attack_scene: BossAttack

var melee_attack_scene = preload("res://scenes/enemies/boss/boss_laser.tscn")
@export var melee_range: float = 100
var projectile_attack_scene = preload("res://scenes/enemies/boss/boss_laser.tscn")
@export var projectile_range: float = 300
var laser_attack_scene = preload("res://scenes/enemies/boss/boss_laser.tscn")
@export var laser_range: float = 1000

@export_group("Harp")
@export var harp: Harp
## effectively attack speed
@export var play_speed := 1.0

@export_group("Arms")
@export var head: Arm
@export var head_target: Node2D
@export var arm_1: Arm
@export var arm_1_target: PathFollow2D
@export var arm_2: Arm
@export var arm_2_target: PathFollow2D

var arms: Array = []
var eye: Eye

@export_group("Death")
var death_target_scene = preload("res://scenes/enemies/boss/death_target.tscn")
@export var target_speed: float = 200.0
@export var target_lifetime: float = 2.0

signal on_attack_player(entity_id: String, target_id: String, damage: int)

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
	
	eye = find_child("eye") as Eye
	if eye:
		eye.parent_entity = self


func _physics_process(delta: float) -> void:
	move_and_slide()


func _process(delta: float):
	if !is_on_floor():
		velocity.y += get_gravity().y * delta
	
	if is_dead:
		return
	
	find_player()
	
	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.ATTACK_PROJECTILE:
			_attack_projectile_behavior(delta)
		State.ATTACK_LASER:
			_attack_laser_behavior(delta)
		State.ATTACK_MELEE:
			_attack_melee_behavior(delta)
		State.DEAD:
			pass


func find_player():
	for p in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(p.global_position) < laser_range:
			set_target(p as PlayerMovement)


func _process_state(delta: float):
	if _attack_timer > 0:
		return
	
	var players: Array[PlayerMovement] = []
	for p in get_tree().get_nodes_in_group("player"):
		players.append(p as PlayerMovement)
	current_state = get_attack_type(players)
	_attack_timer = attack_timer


func get_attack_type(players: Array[PlayerMovement]) -> State:
	var chance_none = .5
	var chance_laser = 100
	var chance_projectile = 1
	var chance_melee = 0
	
	for player in players:
		var distance = global_position.distance_to(player.global_position)
		if distance < melee_range:
			chance_melee += 2
			chance_projectile += .5
		elif distance < projectile_range:
			chance_projectile += 1
			chance_laser += .5
		elif distance < laser_range:
			chance_laser += 1
	
	var random = randf_range(0, chance_none + chance_laser + chance_projectile + chance_melee)
	
	if random > chance_none +chance_laser + chance_projectile:
		return State.ATTACK_MELEE
	elif random > chance_none +chance_laser:
		return State.ATTACK_PROJECTILE
	elif random > chance_none:
		return State.ATTACK_LASER
	return State.IDLE


func set_target(player: PlayerMovement):
	player_target = player
	if eye:
		eye.look_target = player

## recharge next attack
func _idle_behavior(delta):
	if !is_attacking:
		_attack_timer -= delta


## slam tentacle on ground
func _attack_melee_behavior(delta):
	_finish_attack()


## use eye to shoot laser
func _attack_laser_behavior(delta):
	if !player_target:
		_finish_attack()
		return
	
	for arm_state in arms:
		move_arm_target_along_path(arm_state, delta)
	
	if !is_attacking:
		is_attacking = true
		attack_scene = laser_attack_scene.instantiate()
		
		attack_scene.init([player_target])
		attack_scene.attack_finished.connect(_finish_attack)
		attack_scene.on_attack_player.connect(_attack_player)
		
		add_child(attack_scene)
	
	attack_scene.update(eye.get_real_global_position(), player_target.global_position)


## play the harp and shoot note projectiles
func _attack_projectile_behavior(delta):
	for arm_state in arms:
		move_arm_target_along_path(arm_state, delta)
	_finish_attack()


func _finish_attack():
	if attack_scene:
		attack_scene.queue_free()
		attack_scene = null
	is_attacking = false
	current_state = State.IDLE


func _attack_player(target_id: String, damage: int):
	emit_signal("on_attack_player", entity_id, target_id, damage)


func move_arm_target_along_path(arm_state: ArmState, delta: float):
	var target = arm_state.target
	var last_pos = arm_state.last_pos
	var strings_played = arm_state.strings_played

	if target.progress_ratio + delta * play_speed >= 1.0:
		target.progress_ratio = 0.0
		strings_played.clear()

	target.progress_ratio += delta * play_speed

	if target.global_position.x > last_pos.x:
		var passed_strings = harp.get_passed_strings(last_pos.x, target.global_position.x)
		for string_index in passed_strings:
			if !strings_played.has(string_index):
				harp.play_string(string_index)
				strings_played.append(string_index)

	arm_state.last_pos = target.global_position


func die():
	super()
	_finish_attack()
	current_state = State.DEAD
	eye.look_target = null
	spawn_death_targets()


func spawn_death_targets():
	var dead_arms = [arm_1, arm_2, head]
	var dead_arm_targets = [arm_1_target, arm_2_target, head_target]
	for arm in range(dead_arms.size()):
		var target = death_target_scene.instantiate()
		add_child(target)
		target.global_position = dead_arm_targets[arm].global_position
		dead_arms[arm].target = target
		dead_arms[arm].is_dead = true

		var angle_deg = randf_range(-25, 25)
		var angle_rad = deg_to_rad(angle_deg - 90)
		var vel = Vector2(cos(angle_rad), sin(angle_rad)) * target_speed
		target.linear_velocity = vel
