extends Node2D

var music_bus = AudioServer.get_bus_index("Music")
var effects_bus = AudioServer.get_bus_index("Music Effects")
var master_bus = AudioServer.get_bus_index("Master")

func play_music():
	var music_clips: Array[AudioStream] = WorldState.get_music()
	
	for clip in music_clips:
		var player = AudioStreamPlayer.new()
		player.bus = "Music"
		player.stream = clip
		add_child(player)
		player.play()

func enable_effects():
	AudioServer.set_bus_send(music_bus, "Music Effects")

func disable_effects():
	AudioServer.set_bus_send(music_bus, "Master")
