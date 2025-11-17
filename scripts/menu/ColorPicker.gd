extends HBoxContainer

@onready var texture: TextureRect = $texture
var current_color: int = 0

func _ready() -> void:
	set_color()

func set_color():
	if current_color >= PlayerState.COLORS.size():
		current_color = 0
	elif current_color < 0:
		current_color = PlayerState.COLORS.size() - 1
	texture.material.set_shader_parameter("target_color", PlayerState.COLORS[current_color])
	
	Multiplayer.update_player_customization({"color": current_color})


func _on_button_left_pressed() -> void:
	current_color -= 1
	set_color()


func _on_button_right_pressed() -> void:
	current_color += 1
	set_color()
