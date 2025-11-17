extends Node2D

@export var fade_time: float = 0.2
@onready var sprite: Sprite2D = $Sprite2D

func setup(texture: Texture2D, position: Vector2, flip_h: bool, rotation: float) -> void:
	if sprite == null:
		push_error("Sprite2D node not found in AfterImage scene.")
		return
	if texture == null:
		push_error("No texture passed to AfterImage setup.")
		return

	sprite.texture = texture
	sprite.flip_h = flip_h
	global_position = position
	self.rotation = rotation
	_fade_out()

func _fade_out() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, fade_time)
	tween.tween_callback(Callable(self, "queue_free"))
