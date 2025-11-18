extends Control

func _ready():
	position.y = 0

	Multiplayer.lobby_joined.connect(_on_lobby_joined)
	Multiplayer.lobby_left.connect(_on_lobby_left)


func _on_lobby_joined():
	var distance := size.y
	var tween = create_tween()
	tween.tween_property(self, "position:y", distance, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_lobby_left():
	var tween = create_tween()
	tween.tween_property(self, "position:y", 0, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
