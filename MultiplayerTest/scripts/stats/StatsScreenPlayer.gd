extends HBoxContainer

@onready var picture = $picture
@onready var username = $username
@onready var score = $score

func load_player(steam_id: int, player_data: Dictionary):
	username.text = player_data["steam_username"]
	score.text = str(calculate_score(player_data["stats"]))
	load_avatar(steam_id)

func calculate_score(stats: Dictionary) -> int:
	var total_score = 0
	for key in stats.keys():
		total_score += stats[key] * PlayerState.get_stat_multiplier(key)
	return total_score

func load_avatar(steam_id: int):
	var avatar_id = Steam.getMediumFriendAvatar(steam_id)

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
