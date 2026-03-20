extends Node2D

@export var tracked_node_path: NodePath = NodePath("../Player")
@export var medium_safe_radius: float = 170.0
@export var draw_margin: Vector2 = Vector2(320.0, 260.0)
@export var base_tile_size: float = 192.0
@export var scatter_cell_size: float = 96.0
@export var landmark_cell_size: float = 256.0
@export var zone_cell_size: float = 576.0

const STYLE_ROAD := 0
const STYLE_GRAVEL := 1
const STYLE_BARREN := 2
const STYLE_MOSS := 3

const GROUND_BASE := Color(0.82, 0.74, 0.55, 1.0)
const GROUND_SHADE := Color(0.58, 0.48, 0.31, 0.12)
const GROUND_MOSS := Color(0.36, 0.42, 0.24, 0.10)
const GROUND_DUST := Color(0.72, 0.58, 0.40, 0.18)
const ROAD_COLOR := Color(0.70, 0.56, 0.38, 0.18)
const GRAVEL_COLOR := Color(0.54, 0.48, 0.40, 0.16)
const BARREN_COLOR := Color(0.59, 0.43, 0.27, 0.14)
const VERGE_COLOR := Color(0.42, 0.49, 0.28, 0.14)
const STONE_SHADOW := Color(0.10, 0.08, 0.06, 0.10)
const STONE_COLOR := Color(0.48, 0.43, 0.36, 0.56)
const GRASS_COLOR := Color(0.48, 0.46, 0.25, 0.42)
const SHARD_COLOR := Color(0.62, 0.49, 0.34, 0.34)
const MARK_COLOR := Color(0.51, 0.37, 0.23, 0.25)
const LEAF_COLOR := Color(0.67, 0.49, 0.24, 0.20)
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
		"terrain_bands": 0,
		"road_tiles": 0,
		"gravel_tiles": 0,
		"barren_tiles": 0,
		"moss_tiles": 0,
		"stones": 0,
		"grass": 0,
		"shards": 0,
		"ruts": 0,
		"landmarks": 0,
		"anchor_rhythm": 0,
		"decor_clusters": 0,
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
			var terrain_style := _terrain_style_from_world(Vector2((cell_x + 0.5) * base_tile_size, (cell_y + 0.5) * base_tile_size))
			snapshot["signature"] += _hash_i(cell_x, cell_y, 1 + terrain_style * 17)
			match terrain_style:
				STYLE_ROAD:
					snapshot["road_tiles"] += 1
				STYLE_GRAVEL:
					snapshot["gravel_tiles"] += 1
				STYLE_BARREN:
					snapshot["barren_tiles"] += 1
				STYLE_MOSS:
					snapshot["moss_tiles"] += 1
			if _rand01(cell_x, cell_y, 8) > 0.22:
				snapshot["ground_patches"] += 1
			if _rand01(cell_x, cell_y, 15) > 0.50:
				snapshot["trail_marks"] += 1
			if _has_terrain_band(cell_x, cell_y, terrain_style):
				snapshot["terrain_bands"] += 1

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
			if not _should_place_landmark(cell_x, cell_y):
				continue
			var landmark_pos := _landmark_position(cell_x, cell_y)
			if landmark_pos.distance_to(center) < medium_safe_radius:
				continue
			snapshot["landmarks"] += 1
			snapshot["anchor_rhythm"] += 1
			snapshot["decor_clusters"] += 1
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
			var tile_center := tile_pos + Vector2(base_tile_size * 0.5, base_tile_size * 0.5)
			var terrain_style := _terrain_style_from_world(tile_center)
			var tint_mix := _rand01(cell_x, cell_y, 5)
			var zone_tint := _terrain_style_tint(terrain_style)
			var tile_color := GROUND_BASE.lerp(zone_tint, 0.10 + tint_mix * 0.14)
			tile_color = tile_color.lerp(GROUND_SHADE, 0.06 + _rand01(cell_x, cell_y, 6) * 0.12)
			tile_color.a = 0.18
			draw_rect(tile_rect, tile_color)
			if _rand01(cell_x, cell_y, 8) > 0.22:
				_draw_ground_patch(tile_center, cell_x, cell_y, terrain_style)
			if _rand01(cell_x, cell_y, 15) > 0.50:
				_draw_travel_marks(tile_pos, cell_x, cell_y, terrain_style)
			_draw_terrain_band(tile_rect, cell_x, cell_y, terrain_style)

func _draw_ground_patch(center: Vector2, cell_x: int, cell_y: int, terrain_style: int) -> void:
	var patch_radius_x := 42.0 + _rand01(cell_x, cell_y, 9) * 74.0
	var patch_radius_y := 28.0 + _rand01(cell_x, cell_y, 10) * 56.0
	var offset := Vector2(_rand_signed(cell_x, cell_y, 11) * 34.0, _rand_signed(cell_x, cell_y, 12) * 26.0)
	var rotation_value := _rand_signed(cell_x, cell_y, 13) * 0.85
	var patch_color := GROUND_DUST.lerp(GROUND_MOSS, _rand01(cell_x, cell_y, 14) * 0.50)
	patch_color = patch_color.lerp(_terrain_style_tint(terrain_style), 0.35)
	patch_color.a = 0.12 + _rand01(cell_x, cell_y, 16) * 0.06
	draw_colored_polygon(_ellipse_polygon(center + offset, patch_radius_x, patch_radius_y, rotation_value, 8), patch_color)

func _draw_travel_marks(tile_pos: Vector2, cell_x: int, cell_y: int, terrain_style: int) -> void:
	var segment_count := 2 + int(_hash_i(cell_x, cell_y, 17) % 3)
	var base_y := tile_pos.y + 36.0 + _rand01(cell_x, cell_y, 18) * 98.0
	var angle := _rand_signed(cell_x, cell_y, 19) * 0.34
	if terrain_style == STYLE_ROAD:
		segment_count += 1
		angle *= 0.5
	for segment in range(segment_count):
		var x := tile_pos.x + 20.0 + segment * 46.0 + _rand01(cell_x + segment, cell_y, 20) * 22.0
		var seg_center := Vector2(x, base_y + segment * 10.0)
		var seg_color := MARK_COLOR.lerp(_terrain_style_tint(terrain_style), 0.28)
		seg_color.a = 0.13 + _rand01(cell_x, cell_y + segment, 21) * 0.08
		draw_colored_polygon(_ellipse_polygon(seg_center, 26.0, 7.0, angle, 6), seg_color)

func _draw_terrain_band(tile_rect: Rect2, cell_x: int, cell_y: int, terrain_style: int) -> void:
	if not _has_terrain_band(cell_x, cell_y, terrain_style):
		return
	match terrain_style:
		STYLE_ROAD:
			_draw_road_band(tile_rect, cell_x, cell_y)
		STYLE_GRAVEL:
			_draw_gravel_band(tile_rect, cell_x, cell_y)
		STYLE_BARREN:
			_draw_barren_band(tile_rect, cell_x, cell_y)
		STYLE_MOSS:
			_draw_moss_band(tile_rect, cell_x, cell_y)

func _draw_road_band(tile_rect: Rect2, cell_x: int, cell_y: int) -> void:
	var center := tile_rect.position + tile_rect.size * 0.5 + Vector2(_rand_signed(cell_x, cell_y, 101) * 16.0, _rand_signed(cell_x, cell_y, 102) * 10.0)
	var length := 78.0 + _rand01(cell_x, cell_y, 103) * 38.0
	var width := 20.0 + _rand01(cell_x, cell_y, 104) * 14.0
	var rotation_value := _road_angle(cell_x, cell_y)
	var swath_color := ROAD_COLOR
	swath_color.a = 0.13 + _rand01(cell_x, cell_y, 105) * 0.05
	draw_colored_polygon(_ellipse_polygon(center, length, width, rotation_value, 10), swath_color)
	var direction := Vector2.RIGHT.rotated(rotation_value)
	var right := Vector2(-direction.y, direction.x)
	for lane in [-1.0, 1.0]:
		var start_pos: Vector2 = center - direction * (length * 0.66) + right * lane * 8.0
		var end_pos: Vector2 = center + direction * (length * 0.66) + right * lane * 8.0
		var line_color := MARK_COLOR
		line_color.a = 0.10
		draw_line(start_pos, end_pos, line_color, 2.0, true)

func _draw_gravel_band(tile_rect: Rect2, cell_x: int, cell_y: int) -> void:
	var center := tile_rect.position + tile_rect.size * 0.5
	var halo_color := GRAVEL_COLOR
	halo_color.a = 0.09 + _rand01(cell_x, cell_y, 110) * 0.04
	draw_colored_polygon(_ellipse_polygon(center, 70.0, 34.0, _rand_signed(cell_x, cell_y, 111) * 0.6, 8), halo_color)
	var pebble_count := 3 + int(_hash_i(cell_x, cell_y, 112) % 3)
	for pebble in range(pebble_count):
		var pebble_pos := center + Vector2(_rand_signed(cell_x, cell_y, 113 + pebble) * 56.0, _rand_signed(cell_x, cell_y, 118 + pebble) * 24.0)
		var pebble_color := STONE_COLOR
		pebble_color.a = 0.20 + _rand01(cell_x, cell_y, 123 + pebble) * 0.08
		draw_colored_polygon(_ellipse_polygon(pebble_pos, 5.0 + pebble, 3.0 + float(pebble % 2), _rand_signed(cell_x, cell_y, 128 + pebble) * 0.9, 5), pebble_color)

func _draw_barren_band(tile_rect: Rect2, cell_x: int, cell_y: int) -> void:
	var center := tile_rect.position + tile_rect.size * 0.5 + Vector2(_rand_signed(cell_x, cell_y, 131) * 18.0, _rand_signed(cell_x, cell_y, 132) * 16.0)
	var dust_color := BARREN_COLOR
	dust_color.a = 0.10 + _rand01(cell_x, cell_y, 133) * 0.05
	draw_colored_polygon(_ellipse_polygon(center, 62.0, 26.0, _rand_signed(cell_x, cell_y, 134) * 0.9, 7), dust_color)
	for crack in range(2):
		var crack_dir := Vector2(1.0, _rand_signed(cell_x, cell_y, 135 + crack) * 0.4).normalized()
		var crack_pos := center + Vector2(_rand_signed(cell_x, cell_y, 140 + crack) * 24.0, _rand_signed(cell_x, cell_y, 145 + crack) * 10.0)
		var crack_len := 22.0 + _rand01(cell_x, cell_y, 150 + crack) * 14.0
		var crack_color := MARK_COLOR
		crack_color.a = 0.08
		draw_line(crack_pos - crack_dir * crack_len * 0.5, crack_pos + crack_dir * crack_len * 0.5, crack_color, 1.5, true)

func _draw_moss_band(tile_rect: Rect2, cell_x: int, cell_y: int) -> void:
	var center := tile_rect.position + tile_rect.size * 0.5
	var band_color := VERGE_COLOR
	band_color.a = 0.10 + _rand01(cell_x, cell_y, 160) * 0.05
	draw_colored_polygon(_ellipse_polygon(center + Vector2(-12.0, 8.0), 74.0, 28.0, _rand_signed(cell_x, cell_y, 161) * 0.4, 9), band_color)
	for leaf in range(2):
		var leaf_pos := center + Vector2(_rand_signed(cell_x, cell_y, 162 + leaf) * 42.0, _rand_signed(cell_x, cell_y, 168 + leaf) * 18.0)
		var leaf_color := LEAF_COLOR
		leaf_color.a = 0.10 + _rand01(cell_x, cell_y, 174 + leaf) * 0.04
		draw_colored_polygon(_ellipse_polygon(leaf_pos, 9.0, 4.0, _rand_signed(cell_x, cell_y, 180 + leaf) * 0.8, 5), leaf_color)

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
			if not _should_place_landmark(cell_x, cell_y):
				continue
			var landmark_pos := _landmark_position(cell_x, cell_y)
			if landmark_pos.distance_to(center) < medium_safe_radius:
				continue
			var terrain_style := _terrain_style_from_world(landmark_pos)
			match _landmark_variant(cell_x, cell_y, terrain_style):
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
			_draw_landmark_cluster(landmark_pos, cell_x, cell_y, terrain_style)

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

func _draw_landmark_cluster(pos: Vector2, cell_x: int, cell_y: int, terrain_style: int) -> void:
	var cluster_seed := int(_hash_i(cell_x, cell_y, 191) % 3)
	match cluster_seed:
		0:
			_draw_cluster_stele_stones(pos, cell_x, cell_y)
		1:
			_draw_cluster_banner_posts(pos, cell_x, cell_y)
		_:
			_draw_cluster_tree_leaves(pos, cell_x, cell_y, terrain_style)

func _draw_cluster_stele_stones(pos: Vector2, cell_x: int, cell_y: int) -> void:
	for stone in range(3):
		var stone_pos := pos + Vector2(-18.0 + stone * 12.0 + _rand_signed(cell_x, cell_y, 192 + stone) * 3.0, 8.0 + _rand01(cell_x, cell_y, 198 + stone) * 14.0)
		_draw_stone(stone_pos, cell_x + stone + 31, cell_y + 11)
	var dust_color := BARREN_COLOR
	dust_color.a = 0.08
	draw_colored_polygon(_ellipse_polygon(pos + Vector2(0.0, 10.0), 34.0, 14.0, _rand_signed(cell_x, cell_y, 204) * 0.35, 7), dust_color)

func _draw_cluster_banner_posts(pos: Vector2, cell_x: int, cell_y: int) -> void:
	for post in range(2):
		var post_pos := pos + Vector2(-20.0 + post * 28.0, 6.0 + _rand01(cell_x, cell_y, 205 + post) * 10.0)
		draw_line(post_pos, post_pos + Vector2(0.0, -18.0 - post * 4.0), WOOD_COLOR.darkened(0.12), 3.0, true)
		draw_colored_polygon(_ellipse_polygon(post_pos + Vector2(0.0, 3.0), 7.0, 3.0, 0.0, 5), STONE_SHADOW)
	for mark in range(2):
		var mark_pos := pos + Vector2(-14.0 + mark * 20.0, 16.0 + mark * 3.0)
		var mark_color := ROAD_COLOR
		mark_color.a = 0.08
		draw_colored_polygon(_ellipse_polygon(mark_pos, 10.0, 4.0, _road_angle(cell_x + mark, cell_y), 5), mark_color)

func _draw_cluster_tree_leaves(pos: Vector2, cell_x: int, cell_y: int, terrain_style: int) -> void:
	for leaf in range(4):
		var leaf_pos := pos + Vector2(_rand_signed(cell_x, cell_y, 210 + leaf) * 26.0, 10.0 + _rand01(cell_x, cell_y, 216 + leaf) * 18.0)
		var leaf_color := LEAF_COLOR.lerp(_terrain_style_tint(terrain_style), 0.22)
		leaf_color.a = 0.11 + _rand01(cell_x, cell_y, 222 + leaf) * 0.04
		draw_colored_polygon(_ellipse_polygon(leaf_pos, 7.0, 3.0, _rand_signed(cell_x, cell_y, 228 + leaf) * 1.1, 5), leaf_color)
	var verge_shadow := VERGE_COLOR
	verge_shadow.a = 0.07
	draw_colored_polygon(_ellipse_polygon(pos + Vector2(0.0, 12.0), 26.0, 10.0, 0.0, 6), verge_shadow)

func _scatter_position(cell_x: int, cell_y: int) -> Vector2:
	return Vector2(
		cell_x * scatter_cell_size + 18.0 + _rand01(cell_x, cell_y, 33) * (scatter_cell_size - 36.0),
		cell_y * scatter_cell_size + 18.0 + _rand01(cell_x, cell_y, 34) * (scatter_cell_size - 36.0)
	)

func _landmark_position(cell_x: int, cell_y: int) -> Vector2:
	var base_pos := Vector2(
		cell_x * landmark_cell_size + 40.0 + _rand01(cell_x, cell_y, 73) * (landmark_cell_size - 80.0),
		cell_y * landmark_cell_size + 52.0 + _rand01(cell_x, cell_y, 74) * (landmark_cell_size - 104.0)
	)
	var rhythm_offset := Vector2(_rand_signed(cell_x, cell_y, 75) * 18.0, _rand_signed(cell_x, cell_y, 76) * 14.0)
	return base_pos + rhythm_offset

func _terrain_style_from_world(world_pos: Vector2) -> int:
	var zone_x := int(floor(world_pos.x / zone_cell_size))
	var zone_y := int(floor(world_pos.y / zone_cell_size))
	return int(_hash_i(zone_x, zone_y, 91) % 4)

func _terrain_style_tint(terrain_style: int) -> Color:
	match terrain_style:
		STYLE_ROAD:
			return ROAD_COLOR
		STYLE_GRAVEL:
			return GRAVEL_COLOR
		STYLE_BARREN:
			return BARREN_COLOR
		_:
			return VERGE_COLOR

func _has_terrain_band(cell_x: int, cell_y: int, terrain_style: int) -> bool:
	match terrain_style:
		STYLE_ROAD:
			return _rand01(cell_x, cell_y, 95) > 0.18
		STYLE_GRAVEL:
			return _rand01(cell_x, cell_y, 96) > 0.32
		STYLE_BARREN:
			return _rand01(cell_x, cell_y, 97) > 0.28
		_:
			return _rand01(cell_x, cell_y, 98) > 0.30

func _road_angle(cell_x: int, cell_y: int) -> float:
	var world_pos := Vector2((cell_x + 0.5) * base_tile_size, (cell_y + 0.5) * base_tile_size)
	var zone_x := int(floor(world_pos.x / zone_cell_size))
	var zone_y := int(floor(world_pos.y / zone_cell_size))
	var axis_bias := int(_hash_i(zone_x, zone_y, 99) % 3)
	match axis_bias:
		0:
			return _rand_signed(zone_x, zone_y, 100) * 0.20
		1:
			return PI * 0.5 + _rand_signed(zone_x, zone_y, 101) * 0.20
		_:
			return PI * 0.25 + _rand_signed(zone_x, zone_y, 102) * 0.16

func _should_place_landmark(cell_x: int, cell_y: int) -> bool:
	var world_pos := Vector2((cell_x + 0.5) * landmark_cell_size, (cell_y + 0.5) * landmark_cell_size)
	var zone_x := int(floor(world_pos.x / zone_cell_size))
	var zone_y := int(floor(world_pos.y / zone_cell_size))
	var rhythm_kind := int(_hash_i(zone_x, zone_y, 200) % 3)
	var follows_lane := false
	match rhythm_kind:
		0:
			follows_lane = int(posmod(cell_x + zone_y, 2)) == 0
		1:
			follows_lane = int(posmod(cell_y + zone_x, 2)) == 0
		_:
			follows_lane = int(posmod(cell_x + cell_y + zone_x, 3)) == 0
	if not follows_lane:
		return false
	return _rand01(cell_x, cell_y, 70) > 0.28

func _landmark_variant(cell_x: int, cell_y: int, terrain_style: int) -> int:
	var variant_seed := int(_hash_i(cell_x, cell_y, 72) % 100)
	match terrain_style:
		STYLE_ROAD:
			if variant_seed < 34:
				return 1
			if variant_seed < 56:
				return 3
			if variant_seed < 78:
				return 0
			return 4
		STYLE_GRAVEL:
			if variant_seed < 38:
				return 0
			if variant_seed < 68:
				return 2
			if variant_seed < 84:
				return 3
			return 1
		STYLE_BARREN:
			if variant_seed < 44:
				return 2
			if variant_seed < 72:
				return 0
			if variant_seed < 88:
				return 3
			return 1
		_:
			if variant_seed < 44:
				return 4
			if variant_seed < 66:
				return 1
			if variant_seed < 84:
				return 0
			return 3

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
