extends HBoxContainer

@onready var type = $type
@onready var score = $score

func load_stat(key, value):
	type.text = PlayerState.get_stat_name(key)
	score.text = str(value)
