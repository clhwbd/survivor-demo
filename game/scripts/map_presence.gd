extends Node2D

@export var tracked_node_path: NodePath = NodePath("../Player")
@export var medium_safe_radius: float = 170.0
@export var draw_margin: Vector2 = Vector2(320.0, 260.0)
@export var base_tile_size: float = 192.0
@export var scatter_cell_size: float = 96.0
@export var landmark_cell_size: float = 256.0

const GROUND_BASE := Color(0.82, 0.74, 0.55, 1.0)
const GROUND_SHADE := Color(0.58, 0.48, 0.31, 0.12)
const GROUND_MOSS := Color(0.36, 0.42, 0.24, 0.10)
const GROUND_DUST := Color(0.72, 0.58, 0.40, 0.18)
const STONE_SHADOW := Color(0.10, 0.08, 0.06, 0.10)
const STONE_COLOR := Color(0.48, 0.43, 0.36, 0.56)
const GRASS_COLOR := Color(0.48, 0.46, 0.25, 0.42)
const SHARD_COLOR := Color(0.62, 0.49, 0.34, 0.34)
const MARK_COLOR := Color(0.51, 0.37, 0.23, 0.25)
const STELE_COLOR := Color(0.44, 0.41, 0.35, 0.44)
const WOOD_COLOR := Color(0.42, 0.25, 0.16, 0.45)
const BANNER_COLOR := Color(0.65, 0.28, 0.22, 0.26)
const TREE_COLOR := Color(0.32, 0.40, 0.23, 0.30)
const LANTERN_COLOR := Color(0.83, 0.64, 0.32, 0.20)

var _tracked_node: Node2D

func _ready() -> void:
	z_index = -20
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_tracked_node = get_node_or_null(tracked_node_path) as Node2D
	queue_redraw()

func _process(_delta: float) -> void:
	if _tracked_node == null or not is_instance_valid(_tracked_node):
		_tracked_node = get_node_or_null(tracked_node_path) as Node2D
	queue_redraw()

func collect_debug_snapshot(view_center: Vector2 = Vector2.ZERO, viewport_size: Vector2 = Vector2.ZERO) -> Dictionary:
	var center := view_center
	if center == Vector2.ZERO and _tracked_node != null and is_instance_valid(_tracked_node):
		center = _tracked_node.global_position
	var size := viewport_size
	if size == Vector2.ZERO:
		size = get_viewport_rect().size
	var world_rect := _compute_world_rect(center, size)
	var snapshot := {
		"base_tiles": 0,
		"ground_patches": 0,
		"trail_marks": 0,
		"stones": 0,
		"grass": 0,
		"shards": 0,
		"ruts": 0,
		"landmarks": 0,
		"signature": 0
	}
	_accumulate_base_tiles(world_rect, snapshot)
	_accumulate_scatter(world_rect, center, snapshot)
	_accumulate_landmarks(world_rect, center, snapshot)
	return snapshot

func _draw() -> void:
	var center := global_position
	if _tracked_node != null and is_instance_valid(_tracked_node):
		center = _tracked_node.global_position
	var viewport_size := get_viewport_rect().size
	var world_rect := _compute_world_rect(center, viewport_size)
	_draw_base_ground(world_rect)
	_draw_scatter(world_rect, center)
	_draw_landmarks(world_rect, center)

func _compute_world_rect(center: Vector2, viewport_size: Vector2) -> Rect2:
	var half := viewport_size * 0.5
	return Rect2(center - half - draw_margin, viewport_size + draw_margin * 2.0)

func _accumulate_base_tiles(world_rect: Rect2, snapshot: Dictionary) -> void:
	var start_x := int(floor(world_rect.position.x / base_tile_size)) - 1
	var end_x := int(ceil(world_rect.end.x / base_tile_size)) + 1
	var start_y := int(floor(world_rect.position.y / base_tile_size)) - 1
	var end_y := int(ceil(world_rect.end.y / base_tile_size)) + 1
	for cell_y in range(start_y, end_y + 1):
		for cell_x in range(start_x, end_x + 1):
			snapshot["base_tiles"] += 1
			snapshot["signature"] += _hash_i(cell_x, cell_y, 1)
			if _rand01(cell_x, cell_y, 8) > 0.22:
				snapshot["ground_patches"] += 1
			if _rand01(cell_x, cell_y, 15) > 0.50:
				snapshot["trail_marks"] += 1

func _accumulate_scatter(world_rect: Rect2, center: Vector2, snapshot: Dictionary) -> void:
	var start_x := int(floor(world_rect.position.x / scatter_cell_size)) - 1
	var end_x := int(ceil(world_rect.end.x / scatter_cell_size)) + 1
	var start_y := int(floor(world_rect.position.y / scatter_cell_size)) - 1
	var end_y := int(ceil(world_rect.end.y / scatter_cell_size)) + 1
	for cell_y in range(start_y, end_y + 1):
		for cell_x in range(start_x, end_x + 1):
			var chance := _rand01(cell_x, cell_y, 30)
			if chance < 0.24:
				continue
			var element_pos := _scatter_position(cell_x, cell_y)
			if element_pos.distance_to(center) < 28.0:
				continue
			var flavor := int(_hash_i(cell_x, cell_y, 31) % 4)
			snapshot["signature"] += _hash_i(cell_x, cell_y, 32)
			match flavor:
				0:
					snapshot["stones"] += 1
				1:
					snapshot["grass"] += 1
				2:
					snapshot["shards"] += 1
				_:
					snapshot["ruts"] += 1

func _accumulate_landmarks(world_rect: Rect2, center: Vector2, snapshot: Dictionary) -> void:
	var start_x := int(floor(world_rect.position.x / landmark_cell_size)) - 1
	var end_x := int(ceil(world_rect.end.x / landmark_cell_size)) + 1
	var start_y := int(floor(world_rect.position.y / landmark_cell_size)) - 1
	var end_y := int(ceil(world_rect.end.y / landmark_cell_size)) + 1
	for cell_y in range(start_y, end_y + 1):
		for cell_x in range(start_x, end_x + 1):
			if _rand01(cell_x, cell_y, 70) < 0.44:
				continue
			var landmark_pos := _landmark_position(cell_x, cell_y)
			if landmark_pos.distance_to(center) < medium_safe_radius:
				continue
			snapshot["landmarks"] += 1
			snapshot["signature"] += _hash_i(cell_x, cell_y, 71)

func _draw_base_ground(world_rect: Rect2) -> void:
	draw_rect(world_rect, GROUND_BASE)
	var start_x := int(floor(world_rect.position.x / base_tile_size)) - 1
	var end_x := int(ceil(world_rect.end.x / base_tile_size)) + 1
	var start_y := int(floor(world_rect.position.y / base_tile_size)) - 1
	var end_y := int(ceil(world_rect.end.y / base_tile_size)) + 1
	for cell_y in range(start_y, end_y + 1):
		for cell_x in range(start_x, end_x + 1):
			var tile_pos := Vector2(cell_x * base_tile_size, cell_y * base_tile_size)
			var tile_rect := Rect2(tile_pos, Vector2(base_tile_size, base_tile_size))
			var tint_mix := _rand01(cell_x, cell_y, 5)
			var tile_color := GROUND_BASE.lerp(GROUND_SHADE, 0.12 + tint_mix * 0.20)
			tile_color = tile_color.lerp(GROUND_MOSS, _rand01(cell_x, cell_y, 6) * 0.22)
			tile_color.a = 0.18
			draw_rect(tile_rect, tile_color)
			if _rand01(cell_x, cell_y, 8) > 0.22:
				_draw_ground_patch(tile_pos + Vector2(base_tile_size * 0.5, base_tile_size * 0.5), cell_x, cell_y)
			if _rand01(cell_x, cell_y, 15) > 0.50:
				_draw_travel_marks(tile_pos, cell_x, cell_y)

func _draw_ground_patch(center: Vector2, cell_x: int, cell_y: int) -> void:
	var patch_radius_x := 42.0 + _rand01(cell_x, cell_y, 9) * 74.0
	var patch_radius_y := 28.0 + _rand01(cell_x, cell_y, 10) * 56.0
	var offset := Vector2(_rand_signed(cell_x, cell_y, 11) * 34.0, _rand_signed(cell_x, cell_y, 12) * 26.0)
	var rotation_value := _rand_signed(cell_x, cell_y, 13) * 0.85
	var patch_color := GROUND_DUST.lerp(GROUND_MOSS, _rand01(cell_x, cell_y, 14) * 0.50)
	patch_color.a = 0.14 + _rand01(cell_x, cell_y, 16) * 0.06
	draw_colored_polygon(_ellipse_polygon(center + offset, patch_radius_x, patch_radius_y, rotation_value, 8), patch_color)

func _draw_travel_marks(tile_pos: Vector2, cell_x: int, cell_y: int) -> void:
	var segment_count := 2 + int(_hash_i(cell_x, cell_y, 17) % 3)
	var base_y := tile_pos.y + 36.0 + _rand01(cell_x, cell_y, 18) * 98.0
	var angle := _rand_signed(cell_x, cell_y, 19) * 0.34
	for segment in range(segment_count):
		var x := tile_pos.x + 20.0 + segment * 46.0 + _rand01(cell_x + segment, cell_y, 20) * 22.0
		var seg_center := Vector2(x, base_y + segment * 10.0)
		var seg_color := MARK_COLOR
		seg_color.a = 0.15 + _rand01(cell_x, cell_y + segment, 21) * 0.08
		draw_colored_polygon(_ellipse_polygon(seg_center, 26.0, 7.0, angle, 6), seg_color)

func _draw_scatter(world_rect: Rect2, center: Vector2) -> void:
	var start_x := int(floor(world_rect.position.x / scatter_cell_size)) - 1
	var end_x := int(ceil(world_rect.end.x / scatter_cell_size)) + 1
	var start_y := int(floor(world_rect.position.y / scatter_cell_size)) - 1
	var end_y := int(ceil(world_rect.end.y / scatter_cell_size)) + 1
	for cell_y in range(start_y, end_y + 1):
		for cell_x in range(start_x, end_x + 1):
			if _rand01(cell_x, cell_y, 30) < 0.24:
				continue
			var element_pos := _scatter_position(cell_x, cell_y)
			if element_pos.distance_to(center) < 28.0:
				continue
			match int(_hash_i(cell_x, cell_y, 31) % 4):
				0:
					_draw_stone(element_pos, cell_x, cell_y)
				1:
					_draw_grass_tuft(element_pos, cell_x, cell_y)
				2:
					_draw_shards(element_pos, cell_x, cell_y)
				_:
					_draw_rut(element_pos, cell_x, cell_y)

func _draw_landmarks(world_rect: Rect2, center: Vector2) -> void:
	var start_x := int(floor(world_rect.position.x / landmark_cell_size)) - 1
	var end_x := int(ceil(world_rect.end.x / landmark_cell_size)) + 1
	var start_y := int(floor(world_rect.position.y / landmark_cell_size)) - 1
	var end_y := int(ceil(world_rect.end.y / landmark_cell_size)) + 1
	for cell_y in range(start_y, end_y + 1):
		for cell_x in range(start_x, end_x + 1):
			if _rand01(cell_x, cell_y, 70) < 0.44:
				continue
			var landmark_pos := _landmark_position(cell_x, cell_y)
			if landmark_pos.distance_to(center) < medium_safe_radius:
				continue
			match int(_hash_i(cell_x, cell_y, 72) % 5):
				0:
					_draw_stele(landmark_pos, cell_x, cell_y)
				1:
					_draw_prayer_banner(landmark_pos, cell_x, cell_y)
				2:
					_draw_broken_pillar(landmark_pos, cell_x, cell_y)
				3:
					_draw_lantern_post(landmark_pos, cell_x, cell_y)
				_:
					_draw_small_tree(landmark_pos, cell_x, cell_y)

func _draw_stone(pos: Vector2, cell_x: int, cell_y: int) -> void:
	var radius := 8.0 + _rand01(cell_x, cell_y, 40) * 9.0
	draw_colored_polygon(_ellipse_polygon(pos + Vector2(2.0, 5.0), radius * 1.05, radius * 0.58, 0.0, 7), STONE_SHADOW)
	var stone_color := STONE_COLOR
	stone_color.a = 0.34 + _rand01(cell_x, cell_y, 41) * 0.18
	draw_colored_polygon(_ellipse_polygon(pos, radius, radius * (0.66 + _rand01(cell_x, cell_y, 42) * 0.20), _rand_signed(cell_x, cell_y, 43) * 0.6, 7), stone_color)

func _draw_grass_tuft(pos: Vector2, cell_x: int, cell_y: int) -> void:
	var height := 11.0 + _rand01(cell_x, cell_y, 44) * 10.0
	var color_value := GRASS_COLOR
	color_value.a = 0.26 + _rand01(cell_x, cell_y, 45) * 0.18
	for blade in range(3):
		var lean := (-0.36 + blade * 0.36) + _rand_signed(cell_x, cell_y, 46 + blade) * 0.10
		draw_line(pos, pos + Vector2(lean * height * 0.55, -height), color_value, 2.0, true)

func _draw_shards(pos: Vector2, cell_x: int, cell_y: int) -> void:
	var color_value := SHARD_COLOR
	color_value.a = 0.24 + _rand01(cell_x, cell_y, 50) * 0.12
	for shard in range(2):
		var offset := Vector2(_rand_signed(cell_x, cell_y, 51 + shard) * 8.0, _rand_signed(cell_x, cell_y, 56 + shard) * 6.0)
		draw_colored_polygon(_ellipse_polygon(pos + offset, 5.0 + shard * 2.0, 3.0 + shard, _rand_signed(cell_x, cell_y, 60 + shard) * 0.9, 4), color_value)

func _draw_rut(pos: Vector2, cell_x: int, cell_y: int) -> void:
	var color_value := MARK_COLOR
	color_value.a = 0.18 + _rand01(cell_x, cell_y, 65) * 0.08
	var direction := Vector2(1.0, _rand_signed(cell_x, cell_y, 66) * 0.35).normalized()
	var right := Vector2(-direction.y, direction.x)
	var length := 16.0 + _rand01(cell_x, cell_y, 67) * 16.0
	for lane in [-1.0, 1.0]:
		var start_pos: Vector2 = pos - direction * length * 0.5 + right * lane * 4.0
		var end_pos: Vector2 = pos + direction * length * 0.5 + right * lane * 4.0
		draw_line(start_pos, end_pos, color_value, 2.0, true)

func _draw_stele(pos: Vector2, cell_x: int, cell_y: int) -> void:
	draw_colored_polygon(_ellipse_polygon(pos + Vector2(0.0, 14.0), 22.0, 9.0, 0.0, 7), STONE_SHADOW)
	var height := 42.0 + _rand01(cell_x, cell_y, 80) * 18.0
	var width := 20.0 + _rand01(cell_x, cell_y, 81) * 10.0
	var base_color := STELE_COLOR
	base_color.a = 0.34 + _rand01(cell_x, cell_y, 82) * 0.14
	draw_rect(Rect2(pos + Vector2(-width * 0.5, -height), Vector2(width, height)), base_color)
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-width * 0.58, -height),
		pos + Vector2(0.0, -height - 12.0),
		pos + Vector2(width * 0.58, -height),
		pos + Vector2(width * 0.36, -height + 6.0),
		pos + Vector2(-width * 0.36, -height + 6.0)
	]), base_color.lightened(0.08))
	draw_line(pos + Vector2(-2.0, -height + 8.0), pos + Vector2(4.0, -10.0), Color(0.16, 0.12, 0.10, 0.20), 2.0, true)

func _draw_prayer_banner(pos: Vector2, cell_x: int, cell_y: int) -> void:
	draw_colored_polygon(_ellipse_polygon(pos + Vector2(0.0, 10.0), 18.0, 7.0, 0.0, 6), STONE_SHADOW)
	var height := 48.0 + _rand01(cell_x, cell_y, 83) * 16.0
	draw_line(pos, pos + Vector2(0.0, -height), WOOD_COLOR, 4.0, true)
	var top := pos + Vector2(0.0, -height + 8.0)
	var flag_color := BANNER_COLOR
	flag_color.a = 0.18 + _rand01(cell_x, cell_y, 84) * 0.12
	draw_colored_polygon(PackedVector2Array([
		top,
		top + Vector2(26.0, 3.0),
		top + Vector2(12.0, 16.0),
		top + Vector2(28.0, 18.0),
		top + Vector2(0.0, 24.0)
	]), flag_color)

func _draw_broken_pillar(pos: Vector2, cell_x: int, cell_y: int) -> void:
	draw_colored_polygon(_ellipse_polygon(pos + Vector2(0.0, 12.0), 20.0, 8.0, 0.0, 6), STONE_SHADOW)
	var width := 22.0 + _rand01(cell_x, cell_y, 85) * 8.0
	var height := 28.0 + _rand01(cell_x, cell_y, 86) * 18.0
	var body := PackedVector2Array([
		pos + Vector2(-width * 0.5, 0.0),
		pos + Vector2(width * 0.5, -4.0),
		pos + Vector2(width * 0.4, -height),
		pos + Vector2(-width * 0.36, -height + 8.0)
	])
	var color_value := STELE_COLOR.darkened(0.08)
	color_value.a = 0.32
	draw_colored_polygon(body, color_value)

func _draw_lantern_post(pos: Vector2, cell_x: int, cell_y: int) -> void:
	draw_colored_polygon(_ellipse_polygon(pos + Vector2(0.0, 10.0), 16.0, 6.0, 0.0, 6), STONE_SHADOW)
	var height := 42.0 + _rand01(cell_x, cell_y, 87) * 12.0
	draw_line(pos, pos + Vector2(0.0, -height), WOOD_COLOR, 4.0, true)
	var arm_y := pos.y - height + 12.0
	draw_line(Vector2(pos.x - 2.0, arm_y), Vector2(pos.x + 16.0, arm_y), WOOD_COLOR, 3.0, true)
	draw_rect(Rect2(Vector2(pos.x + 8.0, arm_y + 1.0), Vector2(10.0, 14.0)), LANTERN_COLOR)

func _draw_small_tree(pos: Vector2, cell_x: int, cell_y: int) -> void:
	draw_colored_polygon(_ellipse_polygon(pos + Vector2(0.0, 13.0), 24.0, 8.0, 0.0, 7), STONE_SHADOW)
	var height := 34.0 + _rand01(cell_x, cell_y, 88) * 18.0
	draw_line(pos, pos + Vector2(0.0, -height * 0.7), WOOD_COLOR, 5.0, true)
	var canopy_color := TREE_COLOR
	canopy_color.a = 0.22 + _rand01(cell_x, cell_y, 89) * 0.08
	draw_colored_polygon(_ellipse_polygon(pos + Vector2(0.0, -height * 0.72), 22.0, 18.0, _rand_signed(cell_x, cell_y, 90) * 0.25, 8), canopy_color)
	draw_colored_polygon(_ellipse_polygon(pos + Vector2(-8.0, -height * 0.54), 16.0, 13.0, -0.2, 7), canopy_color.darkened(0.06))

func _scatter_position(cell_x: int, cell_y: int) -> Vector2:
	return Vector2(
		cell_x * scatter_cell_size + 18.0 + _rand01(cell_x, cell_y, 33) * (scatter_cell_size - 36.0),
		cell_y * scatter_cell_size + 18.0 + _rand01(cell_x, cell_y, 34) * (scatter_cell_size - 36.0)
	)

func _landmark_position(cell_x: int, cell_y: int) -> Vector2:
	return Vector2(
		cell_x * landmark_cell_size + 40.0 + _rand01(cell_x, cell_y, 73) * (landmark_cell_size - 80.0),
		cell_y * landmark_cell_size + 52.0 + _rand01(cell_x, cell_y, 74) * (landmark_cell_size - 104.0)
	)

func _ellipse_polygon(center: Vector2, radius_x: float, radius_y: float, rotation_value: float, points: int) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for index in range(points):
		var angle := TAU * float(index) / float(points)
		var vertex := Vector2(cos(angle) * radius_x, sin(angle) * radius_y).rotated(rotation_value)
		polygon.append(center + vertex)
	return polygon

func _hash_i(x: int, y: int, salt: int) -> int:
	var value := int(x) * 374761393 + int(y) * 668265263 + int(salt) * 1442695041
	value = int((value ^ (value >> 13)) * 1274126177)
	value = value ^ (value >> 16)
	return abs(value)

func _rand01(x: int, y: int, salt: int) -> float:
	return float(_hash_i(x, y, salt) % 10000) / 10000.0

func _rand_signed(x: int, y: int, salt: int) -> float:
	return _rand01(x, y, salt) * 2.0 - 1.0
