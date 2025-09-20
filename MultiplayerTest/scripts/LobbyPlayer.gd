extends Control

@onready var picture = $picture
@onready var username = $username
@onready var ready_check = $ready_check

func load_player(steam_id: int, steam_name: String):
	username.text = steam_name
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
