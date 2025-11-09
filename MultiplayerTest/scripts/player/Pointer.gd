extends Label

func _ready() -> void:
	visible = true
	await get_tree().create_timer(5.0).timeout
	if !Input.is_action_pressed("show_player_info"):
		visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("show_player_info"):
		visible = true
	if Input.is_action_just_released("show_player_info"):
		visible = false

func set_pointer(_color: Color, _text: String):
	label_settings.font_color = _color
	text = _text
