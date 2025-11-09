extends VBoxContainer

@onready var name_field: Label = $name
@onready var fill: TextureProgressBar = $health

func set_entity(entity: Entity, player_name: String, color: Color):
	name_field.text = player_name
	entity.on_health_changed.connect(_set_fill)
	fill.tint_progress = color

func _set_fill(percentage: float):
	fill.value = percentage
