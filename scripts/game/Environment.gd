extends WorldEnvironment

func _ready():
	Settings.on_brightness_changed.connect(_set_brightness)
	_set_brightness(Settings.get_brightness())

func _set_brightness(value: float):
	environment.adjustment_brightness = value
