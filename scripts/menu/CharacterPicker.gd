extends HBoxContainer

@onready var texture: TextureRect = $texture
var current_character: int = 0

func _ready() -> void:
	set_character()

func set_character():
	if current_character >= PlayerState.CHARACTERS.size():
		current_character = 0
	elif current_character < 0:
		current_character = PlayerState.CHARACTERS.size() - 1
	texture.set_frames(PlayerState.CHARACTERS[current_character])
	
	Multiplayer.update_player_customization({"character": current_character})


func _on_button_left_pressed() -> void:
	current_character -= 1
	set_character()


func _on_button_right_pressed() -> void:
	current_character += 1
	set_character()
