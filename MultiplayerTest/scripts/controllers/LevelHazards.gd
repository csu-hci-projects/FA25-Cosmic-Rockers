class_name LevelHazards extends Node2D

@export var pools_count_range: Vector2i = Vector2i(10, 15)
@export var min_distance_between_pools_tiles: int = 6

# unbreakable bands (ONLY sides + bottom)
@export var unbreakable_side_margin_tiles: int = 1
@export var unbreakable_bottom_extra_tiles: int = 0

# choose kind (visual only)
@export var force_kind: int = -1   # -1 auto, 0 = water, 1 = lava
@export var water_texture: Texture2D = preload("res://sprites/tilesets/water.png")
@export var lava_texture:  Texture2D = preload("res://sprites/tilesets/lava.png")

# rectangular pools
@export var pool_width_min: int = 3
@export var pool_width_max: int = 10
@export var pool_height_min: int = 1
@export var pool_height_max: int = 4

#STATE 
var _tilemap: TileMapLayer
var _tile_size: int = 16
var _unbreakable_rects_world: Array[Rect2] = []   # for is_cell_protected()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

#HELPERS 
func _get_tile_size() -> int:
	if _tilemap and _tilemap.tile_set:
		return int(_tilemap.tile_set.tile_size.x)
	return 16

func _in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < WorldState.map_width and c.y < WorldState.map_height

func _is_solid(c: Vector2i) -> bool:
	return _in_bounds(c) and WorldState.get_tile_data(c) != -1

func _cell_to_world_top_left(cell: Vector2i) -> Vector2:
	return _tilemap.map_to_local(cell)

func _tile_rect_to_world(tl: Vector2i, size: Vector2i) -> Rect2:
	return Rect2(_cell_to_world_top_left(tl), Vector2(size.x * _tile_size, size.y * _tile_size))

func is_cell_protected(cell: Vector2i) -> bool:
	for r in _unbreakable_rects_world:
		var cell_world: Vector2 = _cell_to_world_top_left(cell)
		var cell_rect: Rect2 = Rect2(cell_world, Vector2(_tile_size, _tile_size))
		if r.intersects(cell_rect):
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
	var L := top_left.x
	var T := top_left.y
	var R := L + w - 1
	var B := T + h - 1

	
	for x in range(L, L + w):
		if not _is_solid(Vector2i(x, B + 1)):
			return false
	
	for y in range(T, T + h):
		if not _is_solid(Vector2i(L - 1, y)):
			return false
	
	for y in range(T, T + h):
		if not _is_solid(Vector2i(R + 1, y)):
			return false
	return true

func _carve_rect_tiles(top_left: Vector2i, size: Vector2i) -> void:
	var cells_to_erase: Array[Vector2i] = []
	for y in range(top_left.y, top_left.y + size.y):
		for x in range(top_left.x, top_left.x + size.x):
			if _in_bounds(Vector2i(x, y)):
				cells_to_erase.append(Vector2i(x, y))
	_tilemap.set_cells_terrain_connect(cells_to_erase, 0, -1, false)

func _protect_sides_and_bottom(top_left: Vector2i, size: Vector2i) -> void:
	var L := top_left.x
	var T := top_left.y
	var W := size.x
	var H := size.y
	var R := L + W - 1
	var B := T + H - 1

	var side_thickness: int = max(0, unbreakable_side_margin_tiles)
	var bottom_thickness: int = max(1, 1 + unbreakable_bottom_extra_tiles)

	# LEFT band (tiles)
	if side_thickness > 0:
		for x in range(L - side_thickness, L):
			for y in range(T, B + 1):
				var c := Vector2i(x, y)
				if _in_bounds(c) and _tilemap.has_method("add_protected_cell"):
					_tilemap.add_protected_cell(c)
		_unbreakable_rects_world.append(_tile_rect_to_world(Vector2i(L - side_thickness, T), Vector2i(side_thickness, H)))

	if side_thickness > 0:
		for x in range(R + 1, R + 1 + side_thickness):
			for y in range(T, B + 1):
				var c := Vector2i(x, y)
				if _in_bounds(c) and _tilemap.has_method("add_protected_cell"):
					_tilemap.add_protected_cell(c)
		_unbreakable_rects_world.append(_tile_rect_to_world(Vector2i(R + 1, T), Vector2i(side_thickness, H)))

	for y in range(B + 1, B + 1 + bottom_thickness):
		for x in range(L, R + 1):
			var c := Vector2i(x, y)
			if _in_bounds(c) and _tilemap.has_method("add_protected_cell"):
				_tilemap.add_protected_cell(c)
	_unbreakable_rects_world.append(_tile_rect_to_world(Vector2i(L, B + 1), Vector2i(W, bottom_thickness)))

# Visual + Area2D
func _place_sprite_and_area(pool_rect_world: Rect2, is_lava: bool) -> void:
	var tex: Texture2D 
	if is_lava:
		tex = lava_texture
	else:
		tex = water_texture

	if tex == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		if is_lava:
			img.fill(Color(1.0, 0.25, 0.1, 0.9))
		else:
			img.fill(Color(0.2, 0.5, 1.0, 0.9))
		tex = ImageTexture.create_from_image(img)

	var base_w: float = float(max(1, tex.get_width()))
	var base_h: float = float(max(1, tex.get_height()))

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.z_as_relative = true
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.z_index = 0
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, pool_rect_world.size)
	sprite.position = pool_rect_world.position
	add_child(sprite)

	var area := Area2D.new()
	area.position = pool_rect_world.position
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = pool_rect_world.size
	shape.shape = rect_shape
	shape.position = pool_rect_world.size * 0.5
	area.add_child(shape)
	add_child(area)

	area.body_entered.connect(Callable(self, "_area_body_entered").bind(is_lava))
	area.body_exited.connect(Callable(self, "_area_body_exited").bind(is_lava))

#POOL PLACEMENT
func _spawn_pools_for(is_lava: bool) -> void:
	var want: int = _rng.randi_range(pools_count_range.x, pools_count_range.y)
	var placed_rects: Array[Rect2] = []

	var attempts: int = want * 60
	var safety: int = 0
	while placed_rects.size() < want and safety < attempts:
		safety += 1

		var w: int = _rng.randi_range(pool_width_min, pool_width_max)
		var h: int = _rng.randi_range(pool_height_min, pool_height_max)
		# more rectangular (wider than tall)
		if w < h:
			var t := w; w = h; h = t

		if w <= 0 or h <= 0:
			continue
		if WorldState.map_width <= w + 2 or WorldState.map_height <= h + 2:
			continue

		var left_x: int = _rng.randi_range(1, WorldState.map_width - w - 2)
		var top_y: int  = _rng.randi_range(1, WorldState.map_height - h - 2)
		var top_left_cell: Vector2i = Vector2i(left_x, top_y)

		if not _has_support(top_left_cell, w, h):
			continue

		var rect_world: Rect2 = _tile_rect_to_world(top_left_cell, Vector2i(w - 1, h - 1))

		if not _far_enough(rect_world, placed_rects):
			continue

		_carve_rect_tiles(top_left_cell, Vector2i(w, h))
		_protect_sides_and_bottom(top_left_cell, Vector2i(w, h))
		_place_sprite_and_area(rect_world, is_lava)

		placed_rects.append(rect_world)

#LIFECYCLE
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
		is_lava = (WorldState.level_id == 1) # level 2 → lava (0-based)

	add_to_group("level_hazards")
	self.z_as_relative = true
	self.z_index = 1
	_spawn_pools_for(is_lava)

# --------------- AREA CALLBACKS ---------------
func _area_body_entered(b: Node, is_lava: bool) -> void:
	if (not is_lava) and (b is PlayerMovement) and b.has_method("_enter_water"):
		b._enter_water()

func _area_body_exited(b: Node, is_lava: bool) -> void:
	if (not is_lava) and (b is PlayerMovement) and b.has_method("_exit_water"):
		b._exit_water()
