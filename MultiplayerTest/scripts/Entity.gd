class_name Entity
extends CharacterBody2D

var health_bar_scene = preload("res://scenes/ui/health_bar.tscn")

var entity_id: String 
@export var max_health: int = 100
var health: int

signal on_health_changed(percentage: float)
signal on_death()

func _ready():
	add_to_group("entity")
	create_health_bar()
	set_health(max_health)

func create_health_bar():
	var health_bar = health_bar_scene.instantiate()
	add_child(health_bar)
	on_health_changed.connect(health_bar._set_fill)

func take_damage(amt: int):
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
	emit_signal("on_death")
