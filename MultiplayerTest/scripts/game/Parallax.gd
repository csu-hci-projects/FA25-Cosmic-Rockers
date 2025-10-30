extends Node2D

var layer_scene = preload("res://scenes/game/background_layer.tscn")
@export var parallax_strengths: Array[float] = [0, -0.1, -0.2, -0.3]
@export var sprite_width: float = 480

@export var load_on_ready: bool = false

func _ready():
	Settings.on_zoom_changed.connect(_set_zoom)
	_set_zoom(Settings.get_zoom())
	if load_on_ready:
		create_background()

func create_background():
	var background_id = 0
	for sprite in get_background_sprites(WorldState.get_background()):
		var layer = layer_scene.instantiate()
		add_child(layer)
		for child in layer.get_children():
			if child is Sprite2D:
				child.texture = sprite
		background_id += 1

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
	
	var camera_position_x = get_viewport().get_camera_2d().global_position.x
	var children = get_children()
	
	for i in children.size():
		var layer = children[i]
		layer.position.x = camera_position_x * parallax_strengths[i]

func _set_zoom(value: float):
	var scale_value = 2 / value
	scale = Vector2(scale_value, scale_value)
