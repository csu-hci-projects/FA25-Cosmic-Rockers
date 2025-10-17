extends Control

@onready var tab_container = $TabContainer

func _ready():
	set_min_width()

func set_min_width():
	tab_container.use_hidden_tabs_for_min_size = false
	var max_width = 0
	for child in tab_container.get_children():
		if child is Control:
			child.visible = true
			max_width = max(max_width, child.get_combined_minimum_size().x)
			child.visible = false
	tab_container.custom_minimum_size.x = max_width

func close():
	queue_free()

func _on_back_pressed() -> void:
	close()
