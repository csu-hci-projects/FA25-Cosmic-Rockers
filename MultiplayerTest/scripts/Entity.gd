class_name Entity
extends CharacterBody2D

var health_bar_scene = preload("res://scenes/ui/health_bar.tscn")

@onready var sprite: AnimatedSprite2D = $sprite

var entity_id: String
@export var max_health: int = 100
var health: int

var is_dead: bool = false

signal on_health_changed(percentage: float)
signal on_hit_taken(amt: int)
signal on_die()

func _ready():
	if sprite == null:
		push_error("Entity class must have a child of type AnimatedSprite2D named \"sprite\"")
	add_to_group("entity")
	is_dead = false
	create_health_bar()
	set_health(max_health)

func create_health_bar():
	var health_bar = health_bar_scene.instantiate()
	add_child(health_bar)
	on_health_changed.connect(health_bar._set_fill)

func take_damage(amt: int):
	emit_signal("on_hit_taken", entity_id, amt)
	_take_damage(amt)

func _take_damage(amt: int):
	hit_effect()
	set_health(health - amt)

func take_healing(amt: int):
	set_health(health + amt)

func set_health(amt: int):
	health = amt
	
	if health <= 0:
		health = 0
		die()
	
	if health > max_health:
		health = max_health
	
	emit_signal("on_health_changed", float(health) / float(max_health) * 100)

func die():
	is_dead = true
	set_collision_layer_value(4, false)
	emit_signal("on_die")

func hit_effect():
	for i in 1:
		sprite.self_modulate = Color.INDIAN_RED
		await get_tree().create_timer(0.1).timeout
		sprite.self_modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout
	
