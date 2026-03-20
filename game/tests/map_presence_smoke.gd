extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var viewport := SubViewport.new()
	viewport.name = "MapPresenceViewport"
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = Vector2i(1280, 720)
	root.add_child(viewport)

	var scene := MAIN_SCENE.instantiate()
	viewport.add_child(scene)
	await process_frame
	await process_frame

	var map_presence := scene.get_node_or_null("MapPresence")
	_assert(map_presence != null, "main scene should mount MapPresence")
	if map_presence == null:
		_quit_now(viewport)
		return

	var snapshot_a: Dictionary = map_presence.call("collect_debug_snapshot", Vector2(640, 360), Vector2(1280, 720))
	var snapshot_b: Dictionary = map_presence.call("collect_debug_snapshot", Vector2(1640, 1040), Vector2(1280, 720))

	var terrain_zone_types := 0
	terrain_zone_types += int(snapshot_a.get("road_tiles", 0) > 0)
	terrain_zone_types += int(snapshot_a.get("gravel_tiles", 0) > 0)
	terrain_zone_types += int(snapshot_a.get("barren_tiles", 0) > 0)
	terrain_zone_types += int(snapshot_a.get("moss_tiles", 0) > 0)

	_assert(snapshot_a.get("base_tiles", 0) >= 40, "should generate enough base tiles for one screen")
	_assert(snapshot_a.get("ground_patches", 0) >= 20, "should generate ground variation patches")
	_assert(snapshot_a.get("trail_marks", 0) >= 12, "should generate travel marks / road hints")
	_assert(snapshot_a.get("terrain_bands", 0) >= 20, "should generate more obvious terrain bands / block expressions")
	_assert(terrain_zone_types >= 3, "single view should cover multiple terrain vocab blocks")
	_assert(snapshot_a.get("stones", 0) + snapshot_a.get("grass", 0) + snapshot_a.get("shards", 0) + snapshot_a.get("ruts", 0) >= 50, "should generate dense small scatter props")
	_assert(snapshot_a.get("landmarks", 0) >= 8, "should generate medium reference landmarks")
	_assert(snapshot_a.get("anchor_rhythm", 0) == snapshot_a.get("landmarks", 0), "landmarks should now follow a stable anchor rhythm pass")
	_assert(snapshot_a.get("decor_clusters", 0) >= 8, "landmarks should carry lightweight decor clusters")
	_assert(snapshot_a.get("signature", 0) != snapshot_b.get("signature", 0), "moving the camera should reveal a different landmark signature")
	_assert(snapshot_a.get("road_tiles", 0) != snapshot_b.get("road_tiles", 0) or snapshot_a.get("moss_tiles", 0) != snapshot_b.get("moss_tiles", 0), "moving the camera should reveal a different terrain block mix")

	_quit_now(viewport)

func _quit_now(viewport: SubViewport) -> void:
	viewport.queue_free()
	await process_frame
	if _failures.is_empty():
		print("map_presence_smoke: ok")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
