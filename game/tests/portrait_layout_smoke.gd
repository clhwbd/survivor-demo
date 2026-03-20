extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")
const PORTRAIT_SIZES := [
	Vector2i(360, 800),
	Vector2i(390, 844),
	Vector2i(430, 932)
]

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for target_size in PORTRAIT_SIZES:
		await _validate_portrait_layout(target_size)

	if _failures.is_empty():
		print("portrait_layout_smoke: ok")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _validate_portrait_layout(target_size: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.name = "PortraitViewport_%dx%d" % [target_size.x, target_size.y]
	viewport.disable_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = target_size
	root.add_child(viewport)

	var scene := MAIN_SCENE.instantiate()
	viewport.add_child(scene)
	await process_frame
	await process_frame

	var joystick := scene.get_node("HUD/TouchJoystick") as Control
	var dash_button := scene.get_node("HUD/DashButton") as Control
	var mobile_hint_bg := scene.get_node("HUD/MobileHintBg") as Control
	var mobile_hint_title := scene.get_node("HUD/MobileHintTitle") as Label
	var mobile_hint := scene.get_node("HUD/MobileHint") as Label
	joystick.visible = true
	dash_button.visible = true
	mobile_hint_bg.visible = true
	mobile_hint_title.visible = true
	mobile_hint.visible = true
	scene.call("_refresh_hud_layout")
	await process_frame

	var viewport_rect := Rect2(Vector2.ZERO, Vector2(target_size))
	_assert_rect_inside(viewport_rect, (scene.get_node("HUD/HudCardBg") as Control).get_global_rect(), "HudCardBg", target_size)
	_assert_rect_inside(viewport_rect, (scene.get_node("HUD/StatusCardBg") as Control).get_global_rect(), "StatusCardBg", target_size)
	_assert_rect_inside(viewport_rect, (scene.get_node("HUD/TopCenter") as Control).get_global_rect(), "TopCenter", target_size)
	_assert_rect_inside(viewport_rect, (scene.get_node("HUD/ActionTrayBg") as Control).get_global_rect(), "ActionTrayBg", target_size)
	_assert_rect_inside(viewport_rect, (scene.get_node("HUD/PauseButton") as Control).get_global_rect(), "PauseButton", target_size)
	_assert_rect_inside(viewport_rect, joystick.get_global_rect(), "TouchJoystick", target_size)
	_assert_rect_inside(viewport_rect, dash_button.get_global_rect(), "DashButton", target_size)
	_assert_rect_inside(viewport_rect, mobile_hint_bg.get_global_rect(), "MobileHintBg", target_size)

	var joystick_rect := joystick.get_global_rect()
	var dash_rect := dash_button.get_global_rect()
	var tray_rect := (scene.get_node("HUD/ActionTrayBg") as Control).get_global_rect()
	var hint_rect := mobile_hint_bg.get_global_rect()
	_assert(joystick_rect.end.x <= dash_rect.position.x - 10.0, "%s: joystick and dash button should not overlap" % _fmt_size(target_size))
	_assert(hint_rect.end.y <= tray_rect.position.y - 8.0, "%s: mobile hint should stay above action tray" % _fmt_size(target_size))
	_assert(joystick_rect.end.y <= tray_rect.position.y - 8.0, "%s: joystick should stay above action tray" % _fmt_size(target_size))
	_assert(dash_rect.end.y <= tray_rect.position.y - 32.0, "%s: dash button should stay above action tray buttons" % _fmt_size(target_size))

	viewport.queue_free()
	await process_frame

func _assert_rect_inside(viewport_rect: Rect2, rect: Rect2, node_name: String, target_size: Vector2i) -> void:
	_assert(rect.position.x >= viewport_rect.position.x - 0.5, "%s: %s left overflow %.1f" % [_fmt_size(target_size), node_name, rect.position.x])
	_assert(rect.position.y >= viewport_rect.position.y - 0.5, "%s: %s top overflow %.1f" % [_fmt_size(target_size), node_name, rect.position.y])
	_assert(rect.end.x <= viewport_rect.end.x + 0.5, "%s: %s right overflow %.1f > %.1f" % [_fmt_size(target_size), node_name, rect.end.x, viewport_rect.end.x])
	_assert(rect.end.y <= viewport_rect.end.y + 0.5, "%s: %s bottom overflow %.1f > %.1f" % [_fmt_size(target_size), node_name, rect.end.y, viewport_rect.end.y])

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _fmt_size(size: Vector2i) -> String:
	return "%dx%d" % [size.x, size.y]
