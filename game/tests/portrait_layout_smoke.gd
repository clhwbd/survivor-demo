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

	# MobileControls is a CanvasLayer (layer=2) — its rect is in root viewport space,
	# not SubViewport space, so we validate it separately via scene-local rect checks.
	var joystick := scene.get_node_or_null("MobileControls/TouchJoystick") as Control
	var dash_button := scene.get_node_or_null("MobileControls/DashButton") as Control
	var mobile_hint_bg := scene.get_node_or_null("MobileControls/MobileHintBg") as Control
	if joystick != null:
		joystick.visible = true
	if dash_button != null:
		dash_button.visible = true
	if mobile_hint_bg != null:
		mobile_hint_bg.visible = true
	scene.call("_refresh_hud_layout")
	await process_frame

	# HUD nodes live inside a regular Control hierarchy — get_global_rect works correctly.
	var hud_card_bg_node := scene.get_node_or_null("HUD/HudCardBg") as Control
	var status_card_bg_node := scene.get_node_or_null("HUD/StatusCardBg") as Control
	var top_center_node := scene.get_node_or_null("HUD/TopCenter") as Control
	var action_tray_bg_node := scene.get_node_or_null("HUD/ActionTrayBg") as Control
	var pause_button_node := scene.get_node_or_null("HUD/PauseButton") as Control
	if hud_card_bg_node != null:
		_assert_rect_inside(Rect2(Vector2.ZERO, Vector2(target_size)), hud_card_bg_node.get_global_rect(), "HudCardBg", target_size)
	if status_card_bg_node != null:
		_assert_rect_inside(Rect2(Vector2.ZERO, Vector2(target_size)), status_card_bg_node.get_global_rect(), "StatusCardBg", target_size)
	if top_center_node != null:
		_assert_rect_inside(Rect2(Vector2.ZERO, Vector2(target_size)), top_center_node.get_global_rect(), "TopCenter", target_size)
	if action_tray_bg_node != null:
		_assert_rect_inside(Rect2(Vector2.ZERO, Vector2(target_size)), action_tray_bg_node.get_global_rect(), "ActionTrayBg", target_size)
	if pause_button_node != null:
		_assert_rect_inside(Rect2(Vector2.ZERO, Vector2(target_size)), pause_button_node.get_global_rect(), "PauseButton", target_size)

	# MobileControls nodes are in CanvasLayer (layer=2) — their get_global_rect() returns
	# root viewport space, NOT SubViewport space, so cross-layer rect comparisons are invalid.
	# We only check basic bounds (within viewport area).
	if joystick != null:
		var jrect := joystick.get_global_rect()
		_assert(jrect.position.x >= 0.0, "%s: joystick left %.1f should be within width" % [_fmt_size(target_size), jrect.position.x])
		_assert(jrect.end.x <= target_size.x, "%s: joystick right edge %.1f should be within width %d" % [_fmt_size(target_size), jrect.end.x, target_size.x])
		_assert(jrect.position.y >= 0.0, "%s: joystick top %.1f should be within height" % [_fmt_size(target_size), jrect.position.y])
		_assert(jrect.end.y <= target_size.y, "%s: joystick bottom %.1f should be within height %d" % [_fmt_size(target_size), jrect.end.y, target_size.y])
	if dash_button != null:
		var brect := dash_button.get_global_rect()
		_assert(brect.position.x >= 0.0, "%s: dash button left %.1f should be within width" % [_fmt_size(target_size), brect.position.x])
		_assert(brect.end.x <= target_size.x, "%s: dash button right %.1f should be within width %d" % [_fmt_size(target_size), brect.end.x, target_size.x])
		_assert(brect.position.y >= 0.0, "%s: dash button top %.1f should be within height" % [_fmt_size(target_size), brect.position.y])
		_assert(brect.end.y <= target_size.y, "%s: dash button bottom %.1f should be within height %d" % [_fmt_size(target_size), brect.end.y, target_size.y])
	if mobile_hint_bg != null:
		var hrect := mobile_hint_bg.get_global_rect()
		_assert(hrect.position.x >= 0.0, "%s: mobile hint left %.1f should be within width" % [_fmt_size(target_size), hrect.position.x])
		_assert(hrect.end.x <= target_size.x, "%s: mobile hint right %.1f should be within width %d" % [_fmt_size(target_size), hrect.end.x, target_size.x])

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
