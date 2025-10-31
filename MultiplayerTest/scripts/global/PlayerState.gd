extends Node

const WEAPONS = [
	preload("res://scenes/weapons/gun_raycast.tscn"),
	preload("res://scenes/weapons/gun_projectile.tscn")
]

const WEAPON_SPRITES = [
	preload("res://sprites/sprite_sheets/player/weapons/gun.png"),
	preload("res://sprites/sprite_sheets/player/weapons/gun_2.png")
]

const CHARACTERS = [
	preload("res://sprites/sprite_sheets/player/player_animation.tres"),
	preload("res://sprites/sprite_sheets/player/player_black_animation.tres"),
	preload("res://sprites/sprite_sheets/player/player_green_animation.tres")
]

const COLORS = [
	Color("#FF5733"), # red-orange
	Color("#33FF57"), # green
	Color("#3357FF"), # blue
	Color("#FF33A8"), # pink
	Color("#FFD633"), # yellow
	Color("#33FFF3"), # cyan
	Color("#A833FF"), # purple
	Color("#FF8C33")  # orange
]

# Stores the latest data for each player
var players: Dictionary = {}  # Dictionary keyed by Steam ID

func set_this_stat(key: String, value):
	set_stat(Global.steam_id, key, value)

func set_stat(steam_id: int, key: String, value):
	if not players.has(steam_id):
		players[steam_id] = {}
	if not players[steam_id].has("stats"):
		players[steam_id]["stats"] = {}
	
	players[steam_id]["stats"][key] = value

func get_stats(steam_id: int):
	if not players.has(steam_id):
		return {}
	if not players[steam_id].has("stats"):
		return {}
	return players[steam_id]["stats"]

# Update or add a player's data
func set_player_data(steam_id: int, data: Dictionary):
	if not players.has(steam_id):
		players[steam_id] = {}
	for key in data.keys():
		if data[key] is Dictionary:
			if !players[steam_id].has(key):
				players[steam_id][key] = {}
			
			for data_key in data[key]:
				players[steam_id][key][data_key] = data[key][data_key]
		else:
			players[steam_id][key] = data[key]

# Get a player's data
func get_player_data(steam_id: int) -> Dictionary:
	if players.has(steam_id):
		return players[steam_id].duplicate(true)  # Return a copy
	return {}

# Get all players' data
func get_all_players_data() -> Dictionary:
	var copy := {}
	for steam_id in players.keys():
		copy[steam_id] = players[steam_id].duplicate(true)
	return copy

# Remove a player
func remove_player(steam_id: int):
	players.erase(steam_id)

func all_ready() -> bool:
	for steam_id in players.keys():
		if !players[steam_id].has("ready_status") || !players[steam_id]["ready_status"]["status"]:
			return false
	return true

func clear():
	players.clear()
