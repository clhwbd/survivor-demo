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

	var viewport_rect := Rect2(Vector2.ZERO, Vector2(target_size))

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
	var focus_panel_node := scene.get_node_or_null("HUD/FocusOverlay/PanelContainer") as Control
	var center_notice_node := scene.get_node_or_null("HUD/CenterNotice") as Control
	var weapon_label_node := scene.get_node_or_null("HUD/MarginContainer/VBoxContainer/WeaponLabel") as Control
	var tip_label_node := scene.get_node_or_null("HUD/MarginContainer/VBoxContainer/TipLabel") as Control
	if hud_card_bg_node != null:
		_assert_rect_inside(viewport_rect, hud_card_bg_node.get_global_rect(), "HudCardBg", target_size)
	if status_card_bg_node != null:
		_assert_rect_inside(viewport_rect, status_card_bg_node.get_global_rect(), "StatusCardBg", target_size)
	if top_center_node != null:
		_assert_rect_inside(viewport_rect, top_center_node.get_global_rect(), "TopCenter", target_size)
	if action_tray_bg_node != null and action_tray_bg_node.visible:
		_assert_rect_inside(viewport_rect, action_tray_bg_node.get_global_rect(), "ActionTrayBg", target_size)
	if pause_button_node != null and pause_button_node.visible:
		_assert_rect_inside(viewport_rect, pause_button_node.get_global_rect(), "PauseButton", target_size)
	if center_notice_node != null:
		scene.call("_show_center_notice", "修为精进 · 行者 2 重", Color(0.62, 0.94, 0.75, 1.0))
		await process_frame
		_assert_rect_inside(viewport_rect, center_notice_node.get_global_rect(), "CenterNotice", target_size)

	# MobileControls nodes are in CanvasLayer (layer=2) — their get_global_rect() returns
	# root viewport space, NOT SubViewport space, so cross-layer rect comparisons are invalid.
	# We only check bounds and same-layer overlaps.
	var joystick_rect := Rect2()
	if joystick != null:
		joystick_rect = joystick.get_global_rect()
		_assert_rect_inside(viewport_rect, joystick_rect, "TouchJoystick", target_size)
	if dash_button != null:
		var brect := dash_button.get_global_rect()
		_assert_rect_inside(viewport_rect, brect, "DashButton", target_size)
	if mobile_hint_bg != null:
		var hrect := mobile_hint_bg.get_global_rect()
		_assert_rect_inside(viewport_rect, hrect, "MobileHintBg", target_size)
		if joystick != null:
			_assert(not joystick_rect.intersects(hrect), "%s: mobile hint should not overlap joystick" % _fmt_size(target_size))
		if dash_button != null:
			_assert(not dash_button.get_global_rect().intersects(hrect), "%s: mobile hint should not overlap dash button" % _fmt_size(target_size))
	if action_tray_bg_node != null:
		_assert(not action_tray_bg_node.visible, "%s: action tray should stay hidden during active portrait combat" % _fmt_size(target_size))
	if weapon_label_node != null:
		_assert(not weapon_label_node.visible, "%s: weapon label should collapse in active portrait combat" % _fmt_size(target_size))
	if tip_label_node != null:
		_assert(not tip_label_node.visible, "%s: tip label should collapse in active portrait combat" % _fmt_size(target_size))
	if center_notice_node != null and top_center_node != null:
		scene.call("_show_center_notice", "修为精进 · 行者 2 重", Color(0.62, 0.94, 0.75, 1.0))
		await process_frame
		_assert(center_notice_node.get_global_rect().position.y >= top_center_node.get_global_rect().end.y - 1.0, "%s: center notice should stay below top banner block" % _fmt_size(target_size))

	# Pause / settlement state should still fit on mobile.
	scene.call("_set_pause_state", true)
	await process_frame
	await process_frame
	if focus_panel_node != null:
		_assert(focus_panel_node.size.x <= target_size.x + 0.5, "%s: focus panel width %.1f should fit viewport width %d" % [_fmt_size(target_size), focus_panel_node.size.x, target_size.x])
		_assert(focus_panel_node.size.y <= target_size.y + 0.5, "%s: focus panel height %.1f should fit viewport height %d" % [_fmt_size(target_size), focus_panel_node.size.y, target_size.y])
	if action_tray_bg_node != null and action_tray_bg_node.visible:
		var tray_rect := action_tray_bg_node.get_global_rect()
		_assert_rect_inside(viewport_rect, tray_rect, "PauseActionTray", target_size)
	var continue_button_node := scene.get_node_or_null("HUD/ContinueButton") as Control
	var restart_button_node := scene.get_node_or_null("HUD/RestartButton") as Control
	if continue_button_node != null and continue_button_node.visible:
		_assert_rect_inside(viewport_rect, continue_button_node.get_global_rect(), "ContinueButton", target_size)
	if restart_button_node != null and restart_button_node.visible:
		_assert_rect_inside(viewport_rect, restart_button_node.get_global_rect(), "RestartButton", target_size)
		if continue_button_node != null and continue_button_node.visible:
			_assert(not continue_button_node.get_global_rect().intersects(restart_button_node.get_global_rect()), "%s: continue / restart buttons should not overlap" % _fmt_size(target_size))

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
