extends AudioStreamPlayer

@export var intro_clip: AudioStream

var music_bus = AudioServer.get_bus_index("Music")
var effects_bus = AudioServer.get_bus_index("Music Effects")
var master_bus = AudioServer.get_bus_index("Master")

func play_music():
	stop()
	var music_clip: AudioStream = WorldState.get_music()
	if music_clip:
		stream = music_clip
		play()

func play_intro():
	stream = intro_clip
	play()

func enable_effects():
	AudioServer.set_bus_send(music_bus, "Music Effects")

func disable_effects():
	AudioServer.set_bus_send(music_bus, "Master")
