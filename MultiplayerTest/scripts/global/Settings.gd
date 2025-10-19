extends Node

const ZOOM_FROM: float = 2.0
const ZOOM_TO: float = 3.0
const ZOOM_DEFAULT: float = 2.0
const BRIGHTNESS_FROM: float = 0.5
const BRIGHTNESS_TO: float = 2
const BRIGHTNESS_DEFAULT: float = 1.0

var zoom: int = 0
var brightness: int = 0

signal on_zoom_changed(value: float)
signal on_brightness_changed(value: float)

func _ready():
	zoom = get_zoom_default()
	brightness = get_brightness_default()

func get_zoom_default() -> float:
	return inverse_lerp(ZOOM_FROM, ZOOM_TO, ZOOM_DEFAULT) * 100

func set_zoom(value: int):
	zoom = value
	emit_signal("on_zoom_changed", get_zoom())

func get_zoom() -> float:
	return lerp(ZOOM_FROM, ZOOM_TO, zoom / 100.0)

func get_brightness_default() -> float:
	return inverse_lerp(BRIGHTNESS_FROM, BRIGHTNESS_TO, BRIGHTNESS_DEFAULT) * 100

func set_brightness(value: int):
	brightness = value
	emit_signal("on_brightness_changed", get_brightness())

func get_brightness() -> float:
	return lerp(BRIGHTNESS_FROM, BRIGHTNESS_TO, brightness / 100.0)
