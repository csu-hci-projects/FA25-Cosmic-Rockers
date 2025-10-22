extends Node

var settings_scene = preload("res://scenes/ui/settings.tscn")
var settings = null

var steam_id: int = 0
var steam_username: String = ""

signal on_steam_error(message: String)

var error_message: String = ""

func _init():
	OS.set_environment("SteamAppID", str(480))
	OS.set_environment("SteamGameID", str(480))

func _ready():
	initialize_steam()

func initialize_steam():
	error_message = ""
	var init_success := Steam.steamInit()
	
	if not init_success:
		steam_error("Steam initialization failed")
		return
	
	if not Steam.isSteamRunning():
		steam_error("Steam client not running")
		return
	
	if not Steam.loggedOn():
		steam_error("No Steam user logged in")
		return
	
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

func steam_error(message: String):
	error_message = message
	emit_signal("on_steam_error", message)

func _process(delta):
	Steam.run_callbacks()
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if settings:
			settings.close()
			settings = null
		else:
			open_settings()

func open_settings():
	if not settings:
		settings = settings_scene.instantiate()
		
		var canvas_layer := get_tree().current_scene.get_node_or_null("CanvasLayer")
		if canvas_layer:
			canvas_layer.add_child(settings)
		else:
			get_tree().current_scene.add_child(settings)
