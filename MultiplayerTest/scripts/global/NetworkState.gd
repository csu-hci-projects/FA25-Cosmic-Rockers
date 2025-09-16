extends Node

# Stores the latest data for each player
var players: Dictionary = {}  # Dictionary keyed by Steam ID

# Update or add a player's data
func set_player_data(steam_id: int, data: Dictionary):
	if not players.has(steam_id):
		players[steam_id] = {}
	for key in data.keys():
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
		#print(players[steam_id])
		copy[steam_id] = players[steam_id].duplicate(true)
	return copy

# Remove a player
func remove_player(steam_id: int):
	players.erase(steam_id)

func all_ready() -> bool:
	for steam_id in players.keys():
		if !players[steam_id].has("ready_status") || !players[steam_id]["ready_status"]:
			return false
	return true
