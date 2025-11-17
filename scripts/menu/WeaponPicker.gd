extends HBoxContainer

@onready var texture: TextureRect = $texture
var current_weapon: int = 0

func _ready() -> void:
	set_weapon()

func set_weapon():
	if current_weapon >= PlayerState.WEAPON_SPRITES.size():
		current_weapon = 0
	elif current_weapon < 0:
		current_weapon = PlayerState.WEAPON_SPRITES.size() - 1
		
	texture.texture = PlayerState.WEAPON_SPRITES[current_weapon]
	
	Multiplayer.update_player_customization({"weapon": current_weapon})


func _on_button_left_pressed() -> void:
	current_weapon -= 1
	set_weapon()


func _on_button_right_pressed() -> void:
	current_weapon += 1
	set_weapon()
