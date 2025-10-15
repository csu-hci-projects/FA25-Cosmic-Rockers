extends Node2D

var layer_scene = preload("res://scenes/game/background_layer.tscn")
@export var parallax_strengths: Array[float] = [0, -0.1, -0.2, -0.3]
@export var sprite_width: float = 480

func create_background():
	for sprite in get_background_sprites(WorldState.get_background()):
		var layer = layer_scene.instantiate()
		add_child(layer)
		for child in layer.get_children():
			if child is Sprite2D:
				child.texture = sprite

func get_background_sprites(type: String) -> Array[CompressedTexture2D]:
	var path = "res://sprites/background/" + type
	var dir := DirAccess.open(path)
	var textures: Array[CompressedTexture2D] = []
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".png"):
				var texture = load(path + "/" + file_name)
				if texture is CompressedTexture2D:
					textures.append(texture)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_warning("Directory not found: " + path)
	
	return textures

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
