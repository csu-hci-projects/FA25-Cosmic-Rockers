class_name Entity
extends CharacterBody2D

var entity_id: String
var max_health: int
var health: int

signal on_health_changed
signal on_death

func _ready():
	health = max_health

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
	
	emit_signal("on_health_changed")

func die():
	emit_signal("on_death")
