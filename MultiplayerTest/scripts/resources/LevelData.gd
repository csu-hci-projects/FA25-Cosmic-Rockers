extends Resource
class_name LevelData

@export_group("Level")
@export var level_id: int
@export var tileset: int
@export var backgrounds: Array[Texture2D]
@export var collectable: Texture2D
@export var songs: Array[AudioStream]

@export_group("Naming")
@export var level_name: String
@export var level_name_alien: String

@export_group("Terrain Generation")
@export var floor_range: Vector2
@export var roof_range: Vector2
@export var x_offset_range: Vector2
@export var y_offset_range: Vector2
@export var enemy_count: int = 0

enum LEVEL_EFFECT {
	DUST_PARTICLE,
	ASH_PARTICLE,
	HEAT_DISTORT,
	LEAF_PARTICLE,
	GLOW_PARTICLE,
	RAIN_PARTICLE,
}

@export_group("Effects")
@export var effects: Array[LEVEL_EFFECT]
