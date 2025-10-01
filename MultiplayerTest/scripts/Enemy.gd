extends Entity

@export var patrol_points: Array = []        
@export var patrol_speed: float = 60.0
@export var chase_speed: float = 120.0
@export var detection_radius: float = 200.0
@export var attack_range: float = 20.0
@export var attack_cooldown: float = 1.0
@export var flee_threshold: int = 10

var _current_patrol_index: int = 0
var _target: Node2D = null
var _attack_timer: float = 0.0

func _ready():
    ._ready()

func _physics_process(delta: float) -> void:
    _attack_timer = max(0.0, _attack_timer - delta)
    if health <= flee_threshold:
        _flee_behavior(delta)
        return

    _detect_target()

    if _target:
        var dist = global_position.distance_to(_target.global_position)
        if dist <= attack_range:
            _attack_behavior(delta)
        else:
            _chase_behavior(delta)
    else:
        if patrol_points.size() > 0:
            _patrol_behavior(delta)
        else:
            _idle_behavior(delta)

# Behavior stouff

func _idle_behavior(delta: float) -> void:
    velocity = Vector2.ZERO
    move_and_slide()

func _patrol_behavior(delta: float) -> void:
    var target_pos = to_global(patrol_points[_current_patrol_index]) if patrol_points.size() > 0 else global_position
    var dir = (target_pos - global_position)
    if dir.length() < 4.0:
        _current_patrol_index = (_current_patrol_index + 1) % patrol_points.size()
        return
    dir = dir.normalized()
    velocity = dir * patrol_speed
    move_and_slide()

func _detect_target() -> void:
    var nearest = null
    var nearest_dist = detection_radius
    for p in get_tree().get_nodes_in_group("players"):
        if not p is Node2D:
            continue
        var d = global_position.distance_to(p.global_position)
        if d < nearest_dist:
            nearest_dist = d
            nearest = p
    _target = nearest

func _chase_behavior(delta: float) -> void:
    if not _target:
        return
    var dir = (_target.global_position - global_position).normalized()
    velocity = dir * chase_speed
    move_and_slide()

func _attack_behavior(delta: float) -> void:
    velocity = Vector2.ZERO
    move_and_slide()
    if _attack_timer <= 0.0 and _target:
        _perform_attack()
        _attack_timer = attack_cooldown

func _perform_attack() -> void:
    var dmg = 5
    if _target and _target.has_method("take_damage"):
        _target.take_damage(dmg)

func _flee_behavior(delta: float) -> void:
    var nearest = null
    var nearest_dist = 999999
    for p in get_tree().get_nodes_in_group("players"):
        if not p is Node2D:
            continue
        var d = global_position.distance_to(p.global_position)
        if d < nearest_dist:
            nearest_dist = d
            nearest = p
    if nearest:
        var dir = (global_position - nearest.global_position).normalized()
        velocity = dir * chase_speed
    else:
        velocity = Vector2.ZERO
    move_and_slide()

# Damage tingz

func take_damage(amt: int) -> void:
    .take_damage(amt)
    _on_took_damage()

func _on_took_damage() -> void:
    if has_meta("last_attacker"):
        var attacker = get_meta("last_attacker")
        if attacker and attacker is Node2D:
            _target = attacker