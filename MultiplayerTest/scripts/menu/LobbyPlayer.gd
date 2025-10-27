extends Control

var steam_id: int = 0

@onready var picture = $margin/hbox/picture
@onready var username = $margin/hbox/username
@onready var ready_check = $margin/hbox/ready_check

var ready_sprite = preload("res://sprites/ui/green_check.png")
var unready_sprite = preload("res://sprites/ui/red_cross.png")

func _ready():
	Multiplayer.on_received_player_customization.connect(_set_color)
	PlayerState.on_customization_changed.connect(_set_color)
	set_color(0)

func _set_color(this_steam_id: int, data: Dictionary):
	if this_steam_id == steam_id and data.has("color"):
		set_color(data.get("color"))

func set_color(color: int):
	material.set_shader_parameter("target_color", PlayerState.COLORS[color])
	username.add_theme_color_override("font_color", PlayerState.COLORS[color])

func load_player(this_steam_id: int, this_steam_name: String):
	var player_data = PlayerState.get_player_data(this_steam_id)
	
	steam_id = this_steam_id
	username.text = this_steam_name
	load_avatar(this_steam_id)
	
	var ready_status: bool = false
	if player_data.has("ready_status"):
		ready_status = player_data["ready_status"]["status"]
	
	set_ready_status(ready_status)

func load_avatar(this_steam_id: int):
	var avatar_id = Steam.getMediumFriendAvatar(this_steam_id)

	if avatar_id == 0:
		return
	
	var avatar = Steam.getImageRGBA(avatar_id)
	var avatar_size = Steam.getImageSize(avatar_id)

	if avatar and avatar.has("success") and avatar["success"] \
	and avatar_size and avatar_size.has("success") and avatar_size["success"]:
		var width  = avatar_size["width"]
		var height = avatar_size["height"]
		var img = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, avatar["buffer"])
		var tex = ImageTexture.create_from_image(img)
		picture.texture = tex

func set_ready_status(status: bool):
	if status:
		ready_check.texture = ready_sprite
	else:
		ready_check.texture = unready_sprite
