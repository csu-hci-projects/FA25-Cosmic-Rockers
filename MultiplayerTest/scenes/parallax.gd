extends Node2D

@export var parallax_strengths: Array = [0, 0.3, 0.2, 0.1]
@export var sprite_width: float = 480

func _process(delta: float) -> void:
	if get_parent() == null:
		return
	
	var parent_global_x = get_parent().global_position.x
	var children = get_children()
	
	for i in children.size():
		var layer = children[i]
		layer.position.x = parent_global_x * parallax_strengths[i]
		
		for sprite in layer.get_children():
			if sprite.position.x + layer.position.x < -sprite_width:
				sprite.position.x += sprite_width * layer.get_child_count()
			elif sprite.position.x + layer.position.x > sprite_width * (layer.get_child_count() - 1):
				sprite.position.x -= sprite_width * layer.get_child_count()
