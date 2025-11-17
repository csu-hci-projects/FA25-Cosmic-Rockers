extends AudioStreamPlayer

var sfx_pressed: AudioStream = preload("res://audio/effects/press.wav")
var sfx_released: AudioStream = preload("res://audio/effects/release.wav")

func _ready()->void:
	var buttons: Array = get_tree().get_nodes_in_group("Button")
	for button in buttons:
		button.connect("button_down", on_button_pressed)
		button.connect("button_up", on_button_released)
	get_tree().node_added.connect(_add_button)

func _add_button(node: Node):
	if node.is_in_group("Button"):
		node.connect("button_down", on_button_pressed)
		node.connect("button_up", on_button_released)

func on_button_pressed():
	stream = sfx_pressed
	play()

func on_button_released():
	stream = sfx_released
	play()
