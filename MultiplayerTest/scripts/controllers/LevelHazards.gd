extends Node2D


@export var pools_count_range: Vector2i = Vector2i(10, 15)   # number of pools
@export var min_distance_between_pools_tiles: int = 6        # min spacing between pools


@export var unbreakable_side_margin_tiles: int = 1           # unbreakable thickness at left/right (in tiles)
@export var unbreakable_bottom_extra_tiles: int = 1          # extra unbreakable thickness below bottom (in tiles)

@export var force_kind: int = -1                             # -1 auto, 0 = water, 1 = lava
@export var water_texture: Texture2D = preload("res://sprites/tilesets/Water.png")
@export var lava_texture:  Texture2D = preload("res://sprites/tilesets/Lava.png")

@export var enable_damage: bool = true
@export var lava_tick_damage: int = 5
@export var lava_tick_count: int = 5
@export var lava_tick_interval: float = 0.5


@export var pool_width_min: int = 3
@export var pool_width_max: int = 10
@export var pool_height_min: int = 1
@export var pool_height_max: int = 4

var _tilemap: TileMapLayer
var _tile_size: int = 16
var _unbreakable_rects_world: Array[Rect2] = []   
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _lava_ticks_remaining: Dictionary = {}        

func _get_tile_size() -> int:
	if _tilemap and _tilemap.tile_set:
		return int(_tilemap.tile_set.tile_size.x)
	return 16

func _in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < WorldState.map_width and c.y < WorldState.map_height

func _is_solid(c: Vector2i) -> bool:
	if not _in_bounds(c):
		return false
	return WorldState.get_tile_data(c) != -1

func _cell_to_world_top_left(cell: Vector2i) -> Vector2:
	return _tilemap.map_to_local(cell)

func _rect_contains_cell(rect_world: Rect2, cell: Vector2i) -> bool:
	var cell_world: Vector2 = _cell_to_world_top_left(cell)
	var cell_rect: Rect2 = Rect2(cell_world, Vector2(_tile_size, _tile_size))
	return rect_world.intersects(cell_rect)

func is_cell_protected(cell: Vector2i) -> bool:
	for r in _unbreakable_rects_world:
		if _rect_contains_cell(r, cell):
			return true
	return false

func _rect_center_tile(r: Rect2) -> Vector2i:
	var center_local: Vector2 = r.position + r.size * 0.5
	return _tilemap.local_to_map(center_local)

func _far_enough(pool_rect: Rect2, placed_rects: Array[Rect2]) -> bool:
	var c_new: Vector2i = _rect_center_tile(pool_rect)
	for r in placed_rects:
		var c_old: Vector2i = _rect_center_tile(r)
		if max(abs(c_new.x - c_old.x), abs(c_new.y - c_old.y)) < min_distance_between_pools_tiles:
			return false
	return true

func _has_support(top_left: Vector2i, w: int, h: int) -> bool:
	var left_x: int = top_left.x
	var top_y: int = top_left.y
	var right_x: int = left_x + w - 1
	var bottom_y: int = top_y + h - 1

	# bottom support: every cell directly below the bottom row
	for x in range(left_x, left_x + w):
		var under := Vector2i(x, bottom_y + 1)
		if not _is_solid(under):
			return false

	# left wall support
	for y in range(top_y, top_y + h):
		var left_side := Vector2i(left_x - 1, y)
		if not _is_solid(left_side):
			return false

	# right wall support
	for y in range(top_y, top_y + h):
		var right_side := Vector2i(right_x + 1, y)
		if not _is_solid(right_side):
			return false

	return true

func _carve_rect_world_as_empty(rect_world: Rect2) -> void:
	var tl: Vector2i = _tilemap.local_to_map(rect_world.position)
	var br: Vector2i = _tilemap.local_to_map(rect_world.position + rect_world.size - Vector2(1,1))
	var cells_to_erase: Array[Vector2i] = []
	for y in range(tl.y, br.y + 1):
		for x in range(tl.x, br.x + 1):
			if _in_bounds(Vector2i(x, y)):
				cells_to_erase.append(Vector2i(x, y))
	_tilemap.set_cells_terrain_connect(cells_to_erase, 0, -1, false)

func _band_rects_for_pool(pool_rect_world: Rect2) -> Array:
	var side_px: float = float(max(0, unbreakable_side_margin_tiles) * _tile_size)
	var bottom_px: float = float(max(0, 1 + unbreakable_bottom_extra_tiles) * _tile_size)

	var left_band := Rect2(
		Vector2(pool_rect_world.position.x - side_px, pool_rect_world.position.y),
		Vector2(side_px, pool_rect_world.size.y)
	)
	var right_band := Rect2(
		Vector2(pool_rect_world.position.x + pool_rect_world.size.x, pool_rect_world.position.y),
		Vector2(side_px, pool_rect_world.size.y)
	)
	var bottom_band := Rect2(
		Vector2(pool_rect_world.position.x, pool_rect_world.position.y + pool_rect_world.size.y),
		Vector2(pool_rect_world.size.x, bottom_px)
	)
	return [left_band, right_band, bottom_band]

func _mark_unbreakable_band_cells(pool_rect_world: Rect2) -> void:
	if _tilemap == null:
		return
	var bands: Array = _band_rects_for_pool(pool_rect_world)
	for band in bands:
		var tl: Vector2i = _tilemap.local_to_map(band.position)
		var br: Vector2i = _tilemap.local_to_map(band.position + band.size - Vector2(1,1))
		for y in range(tl.y, br.y + 1):
			for x in range(tl.x, br.x + 1):
				var c := Vector2i(x, y)
				if _in_bounds(c) and _tilemap.has_method("add_protected_cell"):
					_tilemap.add_protected_cell(c)

#VISUAL & AREA
func _place_sprite_and_area(pool_rect_world: Rect2, is_lava: bool) -> void:
	var tex: Texture2D
	if is_lava:
		tex = lava_texture
	else:
		tex = water_texture

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.z_as_relative = true
	sprite.z_index = 0
	sprite.scale = Vector2(
		pool_rect_world.size.x / float(max(1, tex.get_width())),
		pool_rect_world.size.y / float(max(1, tex.get_height()))
	)
	sprite.position = pool_rect_world.position
	add_child(sprite)

	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = pool_rect_world.size
	shape.shape = rect_shape
	shape.position = pool_rect_world.position + pool_rect_world.size * 0.5
	area.add_child(shape)
	add_child(area)

	area.body_entered.connect(Callable(self, "_area_body_entered").bind(is_lava))
	area.body_exited.connect(Callable(self, "_area_body_exited").bind(is_lava))

# POOL PLACEMENT 
func _spawn_pools_for(is_lava: bool) -> void:
	var want: int = _rng.randi_range(pools_count_range.x, pools_count_range.y)
	var placed_rects: Array[Rect2] = []

	var attempts: int = want * 60  # extra attempts so support constraints can be met
	var safety: int = 0
	while placed_rects.size() < want and safety < attempts:
		safety += 1

		var w: int = _rng.randi_range(pool_width_min, pool_width_max)
		var h: int = _rng.randi_range(pool_height_min, pool_height_max)

		# rectangular look = bias to wider if you like (optional)
		if w < h:
			var tmp := w
			w = h
			h = tmp

		if w <= 0 or h <= 0:
			continue
		if WorldState.map_width <= w + 2 or WorldState.map_height <= h + 2:
			continue

		var left_x: int = _rng.randi_range(1, WorldState.map_width - w - 2)
		var top_y: int  = _rng.randi_range(1, WorldState.map_height - h - 2)
		var top_left_cell: Vector2i = Vector2i(left_x, top_y)

		# must have solid tiles surrounding bottom & sides
		if not _has_support(top_left_cell, w, h):
			continue

		var rect_world: Rect2 = Rect2(
			_cell_to_world_top_left(top_left_cell),
			Vector2(float(w * _tile_size), float(h * _tile_size))
		)

		if not _far_enough(rect_world, placed_rects):
			continue

		_carve_rect_world_as_empty(rect_world)
		for band in _band_rects_for_pool(rect_world):
			_unbreakable_rects_world.append(band)  # lets is_cell_protected() work
		_mark_unbreakable_band_cells(rect_world)
		_place_sprite_and_area(rect_world, is_lava)

		placed_rects.append(rect_world)

#  LAVA DAMAGE (doesnt work rn)
func _start_lava_damage(p: PlayerMovement) -> void:
	var id: int = p.get_instance_id()
	if int(_lava_ticks_remaining.get(id, 0)) > 0:
		return
	_lava_ticks_remaining[id] = lava_tick_count
	_do_lava_tick(p)

func _stop_lava_damage(p: PlayerMovement) -> void:
	_lava_ticks_remaining.erase(p.get_instance_id())

func _do_lava_tick(p: PlayerMovement) -> void:
	if not is_instance_valid(p):
		return
	var id: int = p.get_instance_id()
	if not _lava_ticks_remaining.has(id):
		return

	var ticks_left: int = int(_lava_ticks_remaining[id])
	if ticks_left <= 0:
		_lava_ticks_remaining.erase(id)
		return

	if p.has_method("take_damage"):
		p.take_damage(lava_tick_damage)

	ticks_left -= 1
	if ticks_left <= 0:
		_lava_ticks_remaining.erase(id)
	else:
		_lava_ticks_remaining[id] = ticks_left
		var t: SceneTreeTimer = get_tree().create_timer(lava_tick_interval)
		t.timeout.connect(Callable(self, "_on_lava_timer_timeout").bind(p))

func _on_lava_timer_timeout(p: PlayerMovement) -> void:
	_do_lava_tick(p)

func _ready() -> void:
	_rng.randomize()
	await get_tree().process_frame

	_tilemap = get_tree().current_scene.get_node_or_null("tilemap")
	if _tilemap == null:
		_tilemap = get_parent().get_node_or_null("tilemap")
	if _tilemap == null:
		push_warning("[LevelHazards] Could not find 'tilemap' in current scene.")
		return

	_tile_size = _get_tile_size()

	var is_lava: bool
	if force_kind == 0:
		is_lava = false
	elif force_kind == 1:
		is_lava = true
	else:
		# Level 1 = water, Level 2 = lava (0-based ids)
		is_lava = (WorldState.level_id == 1)

	self.z_as_relative = true
	self.z_index = 1  # mid-ground
	_spawn_pools_for(is_lava)

func _area_body_entered(b: Node, is_lava: bool) -> void:
	if not (b is PlayerMovement):
		return
	var p: PlayerMovement = b as PlayerMovement
	if is_lava and enable_damage:
		_start_lava_damage(p)
	elif p.has_method("_enter_water"):
		p._enter_water()

func _area_body_exited(b: Node, is_lava: bool) -> void:
	if not (b is PlayerMovement):
		return
	var p: PlayerMovement = b as PlayerMovement
	if is_lava:
		_stop_lava_damage(p)
	elif p.has_method("_exit_water"):
		p._exit_water()
