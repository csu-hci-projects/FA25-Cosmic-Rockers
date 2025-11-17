extends BoxContainer

@onready var master_slider = $MarginContainer/GridContainer/master_slider
@onready var music_slider = $MarginContainer/GridContainer/music_slider
@onready var effects_slider = $MarginContainer/GridContainer/effects_slider

var master_bus = AudioServer.get_bus_index("Master")
var music_bus = AudioServer.get_bus_index("Music")
var effects_bus = AudioServer.get_bus_index("Effects")

func _ready() -> void:
	master_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(master_bus)))
	music_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(music_bus)))
	effects_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(effects_bus)))

func _on_master_slider_value_changed(value: float) -> void:
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(master_bus, db_value)


func _on_music_slider_value_changed(value: float) -> void:
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(music_bus, db_value)


func _on_effects_slider_value_changed(value: float) -> void:
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(effects_bus, db_value)
