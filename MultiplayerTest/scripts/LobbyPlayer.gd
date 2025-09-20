extends Control

var steam_id: int = 0

@onready var picture = $picture
@onready var username = $username
@onready var ready_check = $ready_check

var ready_sprite = preload("res://sprites/ui/green_check.png")
var unready_sprite = preload("res://sprites/ui/red_cross.png")

func load_player(this_steam_id: int, this_steam_name: String):
	steam_id = this_steam_id
	username.text = this_steam_name
	load_avatar(steam_id)

func load_avatar(steam_id: int):
	var avatar_id = Steam.getSmallFriendAvatar(steam_id)

	if avatar_id == 0:
		return
	
	var avatar = Steam.getImageRGBA(avatar_id)
	var size   = Steam.getImageSize(avatar_id)

	if avatar and avatar.has("success") and avatar["success"] \
	and size and size.has("success") and size["success"]:
		var width  = size["width"]
		var height = size["height"]
		var img = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, avatar["buffer"])
		var tex = ImageTexture.create_from_image(img)
		picture.texture = tex

func set_ready_status(status: bool):
	if status:
		ready_check.texture = ready_sprite
	else:
		ready_check.texture = unready_sprite
