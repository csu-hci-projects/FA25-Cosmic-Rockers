class_name Enemy
extends Entity

enum State {
	IDLE,
	CHASE,
	ATTACK,
	FLEE,
	DEAD
}

var current_state : State = State.IDLE

@export var is_flying: bool = true
@export var move_speed: float = 120.0
@export var detection_radius: float = 200.0
@export var attack_range: float = 20.0
@export var attack_cooldown: float = 1.0
@export var flee_threshold: int = 15
@export var flee_radius: float = 250
@export var dmg = 5

var _target: Node2D = null
var _attack_timer: float = 0.0

@onready var collision: CollisionShape2D = $collision
var ai_enabled: bool = false
var move_dir: Vector2 = Vector2.ZERO

var attack_effect_scene = preload("res://scenes/enemies/melee_effect.tscn")

signal on_state_change(entity_id: String, current_state: State, target_id: String)
signal on_attack_player(entity_id: String, target_id: String, damage: int)

func _ready() -> void:
	super()
	set_animation("default")
	sprite.animation_finished.connect(_animation_finished)

func enable_ai() -> void:
	collision.disabled = false
	ai_enabled = true

func _process(delta: float) -> void:
	if !ai_enabled:
		return
	
	if is_dead or !is_flying:
		if !is_on_floor():
			velocity.y += get_gravity().y * delta
		else:
			velocity = Vector2.ZERO

	if is_dead:
		return

	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true
	
	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.CHASE:
			_chase_behavior(delta)
		State.ATTACK:
			_attack_behavior(delta)
		State.FLEE:
			_flee_behavior(delta)
		State.DEAD:
			pass
	
	move()

func move():
	velocity = move_dir * move_speed

func _physics_process(delta: float) -> void:
	move_and_slide()

func _process_state(delta: float):
	if is_dead:
		return
	
	_attack_timer = max(0.0, _attack_timer - delta)
	if health <= flee_threshold:
		set_state(State.FLEE)
		return
	
	_detect_target()
	
	if _target:
		var dist = global_position.distance_to(_target.global_position)
		if dist <= attack_range:
			set_state(State.ATTACK)
		else:
			set_state(State.CHASE)
	else:
		set_state(State.IDLE)

func emit_state():
	var target_id: String = ""
	if _target and "entity_id" in _target:
		target_id = _target.entity_id
	emit_signal("on_state_change", entity_id, current_state, target_id)

func set_state(new_state: State):
	if current_state == new_state:
		return
	
	if false:
		match new_state:
			State.IDLE: print("IDLE")
			State.CHASE: print("CHASE")
			State.ATTACK: print("ATTACK")
			State.FLEE: print("FLEE")
			State.DEAD: print("DEAD")
	
	current_state = new_state
	emit_state()

# Behavior stuff

func _idle_behavior(delta: float) -> void:
	move_dir = Vector2.ZERO


func _detect_target() -> void:
	var nearest = null
	var nearest_dist = detection_radius
	for p in get_tree().get_nodes_in_group("player"):
		if not p is Node2D:
			continue
		if p.is_dead:
			continue
		var d = global_position.distance_to(p.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = p
	
	if _target != nearest:
		_target = nearest
		emit_state()


func _chase_behavior(delta: float) -> void:
	if not _target:
		return
	move_dir = (_target.global_position - global_position).normalized()

func _attack_behavior(delta: float) -> void:
	move_dir = Vector2.ZERO
	if _attack_timer <= 0.0 and _target:
		_perform_attack()
		_attack_timer = attack_cooldown

func _perform_attack() -> void:
	if _target.position.x > position.x:
		sprite.flip_h = false
	elif _target.position.x < position.x:
		sprite.flip_h = true
	
	set_animation("attack")
	
	var attack_effect: AnimatedSprite2D = attack_effect_scene.instantiate()
	var attack_direction = (_target.global_position - global_position).normalized()
	attack_effect.position = position + attack_direction * 16
	
	if attack_direction.x > 0:
		attack_effect.flip_h = false
		attack_effect.rotation = atan2(attack_direction.y, attack_direction.x)
	elif attack_direction.x < 0:
		attack_effect.flip_h = true
		attack_effect.rotation = atan2(-attack_direction.y, -attack_direction.x)
	
	get_tree().root.add_child(attack_effect)
	
	if _target and _target.has_method("take_damage"):
		emit_signal("on_attack_player", entity_id, _target.entity_id, dmg)

func _flee_behavior(delta: float) -> void:
	var nearest = null
	var nearest_dist = flee_radius
	for p in get_tree().get_nodes_in_group("player"):
		if not p is Node2D:
			continue
		var d = global_position.distance_to(p.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = p
	
	if nearest:
		move_dir = (global_position - nearest.global_position).normalized()
	else:
		move_dir = Vector2.ZERO

func take_damage(amt: int) -> void:
	super(amt)
	
	if has_meta("last_attacker"):
		var attacker = get_meta("last_attacker")
		if attacker and attacker is Node2D:
			_target = attacker

func set_animation(animation_name: String):
	if animation_name != "death" and is_dead:
		return
	
	sprite.play(animation_name)

func _animation_finished():
	if sprite.animation == "attack":
		set_animation("default")

func die():
	super()
	move_dir = Vector2.ZERO
	set_state(State.DEAD)
	set_animation("death")
