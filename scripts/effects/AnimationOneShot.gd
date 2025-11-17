extends AnimatedSprite2D

func _ready() -> void:
	play("default")
	animation_finished.connect(destroy)

func destroy():
	queue_free()
