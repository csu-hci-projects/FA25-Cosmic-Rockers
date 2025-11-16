extends Node

func _ready() -> void:
	WorldState.level_loaded = true
	
func get_entity(entity_id: String) -> Node2D:
	var entities = get_tree().get_nodes_in_group("entity")
	for entity in entities:
		if entity.entity_id == entity_id:
			return entity
	return null
