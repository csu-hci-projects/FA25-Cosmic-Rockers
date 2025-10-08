extends TextureProgressBar

func _set_fill(percentage: float):
	if percentage >= 100 or percentage <= 0:
		visible = false
	else:
		visible = true
	value = percentage
