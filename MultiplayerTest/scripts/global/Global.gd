extends Node

var steam_id: int = 480
var steam_username: String = ""

func _init():
	OS.set_environment("SteamAppID", str(480))
	OS.set_environment("SteamGameID", str(480))

func _ready():
	Steam.steamInit()
	
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

func _process(delta):
	Steam.run_callbacks()
