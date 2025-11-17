extends Node2D

var target_position: Vector2
var drop_height = 2500
var drop_speed = 500
var can_drop = false

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var drill_particles: CPUParticles2D = $drill_particles
@onready var land_particles: CPUParticles2D = $land_particles

var rumble_strength = 2.0
var rumble_speed = 30.0
var _rumble_timer = 0.0
var _original_sprite_pos: Vector2

signal on_dropped()

func _ready() -> void:
	sprite.play("default")
	_original_sprite_pos = sprite.position

func set_drop(_target_position):
	target_position = _target_position
	position = Vector2(target_position.x, target_position.y - drop_height)
	can_drop = true

func _process(delta: float) -> void:
	if can_drop:
		if position.y < target_position.y:
			position.y += delta * drop_speed
			rumble(delta)
			
			if position.y > -200:
				drill_particles.emitting = true
		else:
			position = target_position
			sprite.position = _original_sprite_pos
			land_particles.emitting = true
			drill_particles.emitting = false
			can_drop = false
			emit_signal("on_dropped")

func rumble(delta: float):
	_rumble_timer += delta * rumble_speed
	var offset_x = randf_range(-rumble_strength, rumble_strength)
	var offset_y = randf_range(-rumble_strength, rumble_strength)
	sprite.position = _original_sprite_pos + Vector2(offset_x, offset_y)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerMovement and body.is_local_player:
		if body.collectable != null:
			body.call_deferred("submit_collectable", self)
