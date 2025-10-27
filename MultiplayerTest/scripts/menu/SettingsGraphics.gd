extends BoxContainer

@onready var zoom_slider = $MarginContainer/GridContainer/zoom_box/zoom_slider
@onready var brightness_slider = $MarginContainer/GridContainer/brightness_box/brightness_slider

func _ready() -> void:
	zoom_slider.set_value_no_signal(Settings.zoom)
	brightness_slider.set_value_no_signal(Settings.brightness)

func _on_zoom_slider_value_changed(value: float) -> void:
	Settings.set_zoom(value)

func _on_brightness_slider_value_changed(value: float) -> void:
	Settings.set_brightness(value)

func _on_brightness_reset_pressed() -> void:
	brightness_slider.value = Settings.get_brightness_default()

func _on_zoom_reset_pressed() -> void:
	zoom_slider.value = Settings.get_zoom_default()
