extends AnimatedSprite2D

func _ready() -> void:
	stop()
	frame = 0
	frame_progress = 0.0
	play("default")
	animation_finished.connect(destroy)

func destroy():
	queue_free()
