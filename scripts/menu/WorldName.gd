extends Label

enum ExecutePoint {
	LEVEL_LOAD,
	GAME_LOAD,
}

@export var pretext: String = ""
@export var keep_text: bool = false

@export var execute_point: ExecutePoint = ExecutePoint.LEVEL_LOAD

func _ready() -> void:
	visible = false
	match execute_point:
		ExecutePoint.LEVEL_LOAD:
			if WorldState.level_loaded:
				start_text_sequence()
			else:
				WorldState.on_level_loaded.connect(start_text_sequence)
		ExecutePoint.GAME_LOAD:
			WorldState.on_game_loaded.connect(start_text_sequence)
	
func start_text_sequence():
	var level_name_alien = WorldState.get_level_name_alien()
	var level_name = WorldState.get_level_name()
	
	text = ""
	visible = true
	
	await add_text(pretext)
	
	await add_text(level_name_alien)
	await get_tree().create_timer(1).timeout
	await remove_text()
	
	await add_text(level_name)
	
	if !keep_text:
		await get_tree().create_timer(1).timeout
		await remove_text()
		
		visible = false

func add_text(word: String):
	for c in word:
		text += c
		await get_tree().create_timer(0.1).timeout

func remove_text():
	while text.length() > pretext.length():
		text = text.left(-1)
		await get_tree().create_timer(0.05).timeout
