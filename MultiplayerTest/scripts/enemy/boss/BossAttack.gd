class_name BossAttack extends Node2D

@export var damage: int = 2

var boss = null
var from: Vector2
var target: Vector2
var player_targets: Array[PlayerMovement]

signal attack_finished()
signal on_attack_player(target_id: String, damage: int)

func init(_player_targets: Array[PlayerMovement]):
	player_targets = _player_targets

func update(_from, _target):
	from = _from
	target = _target

func deal_damage(recepients: Array[PlayerMovement]):
	for player in recepients:
		emit_signal("on_attack_player", player.entity_id, damage)

func finish_attack():
	emit_signal("attack_finished")
