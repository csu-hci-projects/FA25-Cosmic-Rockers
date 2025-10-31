extends Resource
class_name LevelData

@export var level_id: int
@export var tileset: int
@export var background: String
@export var collectable: Texture2D
@export var songs: Array[AudioStream]

@export var level_name: String
@export var level_name_alien: String

@export var floor_range: Vector2
@export var roof_range: Vector2
@export var x_offset_range: Vector2
@export var y_offset_range: Vector2
@export var enemy_count: int = 0

enum LEVEL_EFFECT {
	HEAT_DISTORT
}

@export var effects: Array[LEVEL_EFFECT]
