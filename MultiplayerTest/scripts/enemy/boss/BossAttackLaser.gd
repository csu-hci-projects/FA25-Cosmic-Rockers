class_name BossAttackLaser extends BossAttack

@export var line: Line2D
@export var audio_player: AudioStreamPlayer2D
@export var timer: float = 5

@export var charge_timer: float = 2
var _charge_timer: float
var _width: float
@export var charge_color: Color
@export var laser_color: Color

var _damage_timer: float
var damage_timer: float = .2

func _ready() -> void:
	_charge_timer = charge_timer
	_width = float(line.width)
	global_position = Vector2.ZERO
	audio_player.play()
	audio_player.global_position = get_parent().global_position

func _process(delta: float) -> void:
	timer -= delta
	if timer < 0:
		finish_attack()
	
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsRayQueryParameters2D.create(from, target)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.hit_from_inside = true
	query.collision_mask = (1 << 0 | 1 << 4) #set bit 0 (layer 1) and bit 4 (layer 5) to 1

	var result = space_state.intersect_ray(query)
	var hit_position: Vector2 = result.get("position", target)
	
	line.clear_points()
	line.add_point(from)
	line.add_point(hit_position)
	
	if _charge_timer > 0:
		_charge_timer -= delta
		line.width = lerpf(0, _width, (charge_timer - _charge_timer) / charge_timer)
		line.default_color = charge_color
		
		if _charge_timer < 0:
			line.default_color = laser_color
			line.width = _width
		return
	
	_damage_timer -= delta
	if _damage_timer < 0:
		if result.has("collider") and result["collider"] is PlayerMovement:
			deal_damage([result["collider"]])
		_damage_timer = damage_timer

func attack():
	pass
