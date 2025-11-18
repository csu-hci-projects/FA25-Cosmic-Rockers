extends CanvasLayer

var previous_scene: Node = null
var next_scene_path: String = "res://scenes/game/game.tscn"

@onready var system: Control = $system
@onready var fade_rect: ColorRect = $fade_rect
@onready var target: Node2D = $system/planets/target
@onready var ship = $system/ship

@export var transition_time: float = 2.0
@export var zoom_scale: float = 10

@export var planets: Array[Node2D]
@onready var planets_parent: Control = $system/planets
@onready var orbits_parent: Control = $system/orbits

var _thread: Thread
var _loaded_scene: PackedScene = null

var end_screen_scene = preload("res://scenes/ui/end_screen.tscn")

func _ready():
	if WorldState.win_state:
		target.visible = false
	if WorldState.level_loaded:
		set_target()
	else:
		WorldState.on_level_loaded.connect(set_target)
	
	system.scale = Vector2.ZERO
	fade_rect.modulate.a = 0.0
	fade_in_transition()

func set_target():
	var level_id = WorldState.level_id
	if level_id >= planets.size():
		level_id = planets.size() - 1
	target.position = planets[level_id].position

func fade_in_transition():
	var tween = create_tween()
	
	tween.parallel().tween_property(fade_rect, "modulate:a", 1.0, transition_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(system, "scale", Vector2.ONE, transition_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(Callable(self, "_on_fade_in_complete"))

func _on_fade_in_complete():
	if previous_scene:
		previous_scene.free()
	if !WorldState.win_state:
		_thread = Thread.new()
		_thread.start(Callable(self, "_load_scene_thread"))
	else:
		var end_screen = end_screen_scene.instantiate()
		add_child(end_screen)
		end_screen.on_load_lobby.connect(queue_free)

func fade_out_transition():
	var tween = create_tween()

	tween.parallel().tween_property(fade_rect, "modulate:a", 0.0, transition_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	tween.parallel().tween_property(target, "modulate:a", 0.0, transition_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	for planet in planets_parent.get_children():
		tween.parallel().tween_property(planet, "modulate:a", 0.0, transition_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	for orbit in orbits_parent.get_children():
		var to_color = orbit["dot_color"]
		to_color.a = 0
		tween.parallel().tween_property(orbit, "dot_color", to_color, transition_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	var target = system.get_child(1).get_child(0)
	var viewport_center = get_viewport().get_visible_rect().size / 2
	
	var target_local = target.position
	
	var final_scale = Vector2(zoom_scale, zoom_scale)
	var planet_offset = viewport_center - target_local * zoom_scale
	
	tween.parallel().tween_property(system, "scale", final_scale, transition_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(system, "position", planet_offset, transition_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_callback(Callable(self, "_on_fade_out_complete"))

func _on_fade_out_complete():
	await _thread.wait_to_finish()
	queue_free()

func _load_scene_thread() -> void:
	_loaded_scene = ResourceLoader.load(next_scene_path)
	call_deferred("_on_scene_loaded")

func _on_scene_loaded():
	if not _loaded_scene:
		return

	get_tree().change_scene_to_packed(_loaded_scene)
	WorldState.on_game_ready.connect(_on_game_ready)
	WorldState.on_game_loaded.connect(_on_game_loaded)

func _on_game_loaded():
	ship.move_to_target(target)

func _on_game_ready():
	fade_out_transition()
