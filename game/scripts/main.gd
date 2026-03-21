extends Node2D

@export var move_speed: float = 130.0
@export var spawn_interval: float = 1.0
@export var spawn_count_per_wave: int = 1
@export var max_alive_enemies: int = 16
@export var spawn_radius_min: float = 420.0
@export var spawn_radius_max: float = 560.0
@export var attack_interval: float = 0.55
@export var attack_range: float = 260.0
@export var projectile_speed: float = 520.0
@export var xp_orb_value: int = 1
@export var difficulty_step_seconds: float = 20.0
@export var wave_length_seconds: float = 30.0
@export var demo_goal_seconds: float = 180.0
@export var enemy_scene: PackedScene
@export var fast_enemy_scene: PackedScene
@export var tank_enemy_scene: PackedScene
@export var projectile_scene: PackedScene
@export var xp_orb_scene: PackedScene
@export var damage_popup_scene: PackedScene
@export var feedback_burst_scene: PackedScene
@export var slash_fx_scene: PackedScene
@export var reward_pulse_scene: PackedScene
@export var milestone_flare_scene: PackedScene
@export var collect_pulse_scene: PackedScene

const WAVE_TITLES := [
	"花果山热身",
	"山门妖风",
	"流沙急袭",
	"白骨夜行",
	"火云压阵",
	"金箍镇场"
]

const DIFFICULTY_TITLES := [
	"初入山门",
	"妖气渐浓",
	"群怪躁动",
	"魔障翻涌",
	"压迫成潮",
	"大圣护场"
]

const HUD_GOLD := Color(0.96, 0.84, 0.56, 1.0)
const HUD_INK := Color(0.18, 0.14, 0.10, 1.0)
const HUD_PAPER := Color(0.96, 0.91, 0.78, 1.0)
const HUD_PANEL := Color(0.17, 0.10, 0.08, 0.82)
const HUD_PANEL_SOFT := Color(0.34, 0.22, 0.15, 0.74)
const HUD_ACCENT := Color(0.80, 0.36, 0.25, 1.0)
const HUD_MINT := Color(0.62, 0.94, 0.75, 1.0)
const HUD_SKY := Color(0.60, 0.86, 1.0, 1.0)
const HUD_WARNING := Color(1.0, 0.76, 0.46, 1.0)
const HUD_DANGER := Color(1.0, 0.48, 0.48, 1.0)
const HUD_ROSE := Color(1.0, 0.62, 0.70, 1.0)

const OBJECTIVE_LABELS := {
	"survive": "稳住阵脚",
	"kills": "清妖试锋",
	"elite": "伏诛头目"
}

const OBJECTIVE_DETAILS := {
	"survive": "扛住这一劫的开场压迫，别急着硬换。",
	"kills": "稳步清边路，把妖潮人数压下去。",
	"elite": "盯住压阵头目，拆掉它就能拿回节奏。"
}

const SPAWN_TYPE_BASIC := "basic"
const SPAWN_TYPE_FAST := "fast"
const SPAWN_TYPE_TANK := "tank"

var elapsed_time: float = 0.0
var kill_count: int = 0
var difficulty_stage: int = 0
var wave_index: int = 1
var game_over: bool = false
var demo_clear: bool = false
var pause_requested: bool = false
var _last_health: int = -1
var _last_level: int = 1
var _browser_hint_acknowledged: bool = false
var _heals_awarded_by_kills: int = 0
var _elites_spawned_total: int = 0
var _camera_shake_strength: float = 0.0
var _camera_shake_time: float = 0.0
var _camera_base_offset: Vector2 = Vector2.ZERO
var _focus_overlay_visible_state: bool = false
var _center_notice_tween: Tween
var _screen_flash_tween: Tween
var _ui_motion_time: float = 0.0
var _center_notice_base_position: Vector2 = Vector2.ZERO
var _focus_panel_base_position: Vector2 = Vector2.ZERO
var _kill_streak: int = 0
var _best_kill_streak: int = 0
var _kill_streak_timer: float = 0.0
var _low_health_pulse_time: float = 0.0
var _combo_meter_base_position: Vector2 = Vector2.ZERO
var _combo_meter_tween: Tween
var _settlement_stamp_tween: Tween
var _settlement_stamp_visible_state: bool = false
var _respite_time_remaining: float = 0.0
var _respite_spawn_multiplier: float = 1.0
var _respite_fast_penalty: float = 0.0
var _respite_tank_penalty: float = 0.0
var _bonus_attack_speed_time: float = 0.0
var _bonus_damage_time: float = 0.0
var _bonus_multishot_time: float = 0.0
var _bonus_pierce_time: float = 0.0
var _merit_stacks: int = 0
var _wave_objective_type: String = "survive"
var _wave_objective_target: int = 0
var _wave_objective_progress: int = 0
var _wave_objective_completed: bool = false
var _wave_objective_reward_text: String = ""
var _wave_started_at: float = 0.0
var _last_objective_kill_count: int = 0
var _last_objective_elite_kill_count: int = 0
var _elite_kill_count: int = 0
var _queued_spawn_entries: Array[Dictionary] = []
var _mobile_lite_mode: bool = false
var _boot_variant_label: String = "标准验收版"

@onready var player: CharacterBody2D = $Player
@onready var player_camera: Camera2D = $Player/Camera2D
@onready var enemies: Node2D = $Enemies
@onready var projectiles: Node2D = $Projectiles
@onready var pickups: Node2D = $Pickups
@onready var feedback: Node2D = $Feedback
@onready var spawn_timer: Timer = $SpawnTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var hud_margin_container: MarginContainer = $HUD/MarginContainer
@onready var hud_level: Label = $HUD/MarginContainer/VBoxContainer/LevelLabel
@onready var hud_health: Label = $HUD/MarginContainer/VBoxContainer/HealthLabel
@onready var hud_enemies: Label = $HUD/MarginContainer/VBoxContainer/EnemyLabel
@onready var hud_timer: Label = $HUD/MarginContainer/VBoxContainer/TimerLabel
@onready var hud_kills: Label = $HUD/MarginContainer/VBoxContainer/KillLabel
@onready var hud_meta_divider: ColorRect = get_node_or_null("HUD/MarginContainer/VBoxContainer/MetaDivider") as ColorRect
@onready var hud_weapon: Label = $HUD/MarginContainer/VBoxContainer/WeaponLabel
@onready var hud_objective_divider: ColorRect = get_node_or_null("HUD/MarginContainer/VBoxContainer/ObjectiveDivider") as ColorRect
@onready var hud_wave: Label = $HUD/MarginContainer/VBoxContainer/WaveLabel
@onready var hud_objective: Label = $HUD/MarginContainer/VBoxContainer/ObjectiveLabel
@onready var hud_tip: Label = $HUD/MarginContainer/VBoxContainer/TipLabel
@onready var hud_xp_label: Label = $HUD/MarginContainer/VBoxContainer/XPLabel
@onready var hud_xp_bar: ProgressBar = $HUD/MarginContainer/VBoxContainer/XPBar
@onready var screen_flash: ColorRect = get_node_or_null("HUD/ScreenFlash") as ColorRect
@onready var low_health_vignette: ColorRect = get_node_or_null("HUD/LowHealthVignette") as ColorRect
@onready var hud_card_bg: ColorRect = get_node_or_null("HUD/HudCardBg") as ColorRect
@onready var hud_card_border: ColorRect = get_node_or_null("HUD/HudCardBorder") as ColorRect
@onready var status_card_bg: ColorRect = $HUD/StatusCardBg
@onready var status_card_accent: ColorRect = $HUD/StatusCardAccent
@onready var status_badge: Label = get_node_or_null("HUD/StatusBadge") as Label
@onready var status_label: Label = $HUD/StatusLabel
@onready var top_center: Control = $HUD/TopCenter
@onready var banner_backing: ColorRect = $HUD/TopCenter/BannerBacking
@onready var banner_accent: ColorRect = $HUD/TopCenter/BannerAccent
@onready var banner_label: Label = $HUD/TopCenter/BannerLabel
@onready var banner_sub_label: Label = get_node_or_null("HUD/TopCenter/BannerSubLabel") as Label
@onready var combo_meter: Label = get_node_or_null("HUD/ComboMeter") as Label
@onready var center_notice: Control = get_node_or_null("HUD/CenterNotice") as Control
@onready var center_notice_backing: ColorRect = get_node_or_null("HUD/CenterNotice/Backing") as ColorRect
@onready var center_notice_accent: ColorRect = get_node_or_null("HUD/CenterNotice/Accent") as ColorRect
@onready var center_notice_label: Label = get_node_or_null("HUD/CenterNotice/Label") as Label
@onready var focus_overlay: Control = $HUD/FocusOverlay
@onready var focus_tint: ColorRect = $HUD/FocusOverlay/Tint
@onready var focus_panel: PanelContainer = $HUD/FocusOverlay/PanelContainer
@onready var focus_badge: Label = $HUD/FocusOverlay/PanelContainer/MarginContainer/VBoxContainer/BadgeLabel
@onready var focus_title: Label = $HUD/FocusOverlay/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var medal_label: Label = get_node_or_null("HUD/FocusOverlay/PanelContainer/MarginContainer/VBoxContainer/MedalLabel") as Label
@onready var focus_detail: Label = $HUD/FocusOverlay/PanelContainer/MarginContainer/VBoxContainer/DetailLabel
@onready var settlement_stamp: Label = get_node_or_null("HUD/FocusOverlay/PanelContainer/MarginContainer/VBoxContainer/SettlementStamp") as Label
@onready var summary_label: Label = $HUD/FocusOverlay/PanelContainer/MarginContainer/VBoxContainer/SummaryLabel
@onready var action_tray_bg: ColorRect = get_node_or_null("HUD/ActionTrayBg") as ColorRect
@onready var action_tray_accent: ColorRect = get_node_or_null("HUD/ActionTrayAccent") as ColorRect
@onready var action_tray_label: Label = get_node_or_null("HUD/ActionTrayLabel") as Label
@onready var restart_button: Button = $HUD/RestartButton
@onready var continue_button: Button = $HUD/ContinueButton
@onready var pause_button: Button = $HUD/PauseButton
@onready var joystick: Control = $MobileControls/TouchJoystick
@onready var dash_button: Button = $MobileControls/DashButton
@onready var dash_cooldown_bar: ColorRect = get_node_or_null("MobileControls/DashButton/CooldownBar")
@onready var mobile_hint_bg: ColorRect = $MobileControls/MobileHintBg
@onready var mobile_hint_accent: ColorRect = get_node_or_null("MobileControls/MobileHintAccent") as ColorRect
@onready var mobile_hint_title: Label = get_node_or_null("MobileControls/MobileHintTitle") as Label
@onready var mobile_hint: Label = $MobileControls/MobileHint

func _ready() -> void:
	randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS

	if enemy_scene == null:
		enemy_scene = load("res://scenes/enemy_basic.tscn")
	if fast_enemy_scene == null:
		fast_enemy_scene = load("res://scenes/enemy_runner.tscn")
	if tank_enemy_scene == null:
		tank_enemy_scene = load("res://scenes/enemy_tank.tscn")
	if projectile_scene == null:
		projectile_scene = load("res://scenes/projectile.tscn")
	if xp_orb_scene == null:
		xp_orb_scene = load("res://scenes/xp_orb.tscn")
	if damage_popup_scene == null:
		damage_popup_scene = load("res://scenes/damage_popup.tscn")
	if feedback_burst_scene == null:
		feedback_burst_scene = load("res://scenes/feedback_burst.tscn")
	if slash_fx_scene == null:
		slash_fx_scene = load("res://scenes/slash_fx.tscn")
	if reward_pulse_scene == null:
		reward_pulse_scene = load("res://scenes/reward_pulse.tscn")
	if milestone_flare_scene == null:
		milestone_flare_scene = load("res://scenes/milestone_flare.tscn")
	if collect_pulse_scene == null:
		collect_pulse_scene = load("res://scenes/collect_pulse.tscn")

	_mobile_lite_mode = _detect_mobile_lite_mode()
	_boot_variant_label = "掌中轻量验收版" if _mobile_lite_mode else "标准验收版"
	if _mobile_lite_mode:
		print("survivor-demo mobile lite mode enabled")

	_apply_ui_style()
	call_deferred("_apply_ui_font_overrides")
	_refresh_hud_layout()

	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

	attack_timer.wait_time = attack_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()

	player.xp_changed.connect(_on_player_xp_changed)
	player.xp_collected.connect(_on_xp_collected)
	player.stats_changed.connect(_on_player_stats_changed)
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	if player.has_signal("dash_state_changed"):
		player.dash_state_changed.connect(_on_player_dash_state_changed)

	if joystick != null:
		joystick.vector_changed.connect(_on_joystick_vector_changed)
	if dash_button != null:
		dash_button.pressed.connect(_on_dash_button_pressed)
	if restart_button != null:
		restart_button.pressed.connect(_reload_scene)
	if continue_button != null:
		continue_button.pressed.connect(_resume_run)
	if pause_button != null:
		pause_button.pressed.connect(_toggle_pause)
	if player_camera != null:
		_camera_base_offset = player_camera.offset
	if focus_overlay != null:
		focus_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if restart_button != null:
		restart_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if continue_button != null:
		continue_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if pause_button != null:
		pause_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if center_notice != null:
		_center_notice_base_position = center_notice.position
	if focus_panel != null:
		_focus_panel_base_position = focus_panel.position
	if combo_meter != null:
		_combo_meter_base_position = combo_meter.position
	if screen_flash != null:
		screen_flash.color = Color(1.0, 0.88, 0.58, 0.0)
		screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_on_player_xp_changed(player.xp, player.xp_to_next, player.level)
	_on_player_stats_changed(player.health, player.max_health, player.level)
	_on_player_dash_state_changed(true, 0.0, false)
	_update_enemy_count()
	_update_meta_hud()
	_apply_wave_state(true)
	_setup_web_ui()
	_show_banner("第一劫 · %s" % _get_wave_title(1), _boot_variant_label)
	_show_center_notice("花果山开场 · %s" % _boot_variant_label, HUD_GOLD)
	_update_tip_text()

	print("survivor-demo polished demo ready")

func _process(delta: float) -> void:
	if not pause_requested and not game_over and not demo_clear:
		elapsed_time += delta
		_update_difficulty()
		_update_wave_progress()
		_update_kill_streak(delta)
		_update_temporary_bonuses(delta)
		_update_wave_objective_progress()
		if elapsed_time >= demo_goal_seconds:
			_on_demo_clear()
	_update_enemy_count()
	_update_meta_hud()
	_update_focus_overlay()
	_update_status_card()
	_update_pause_button()
	_update_camera_feedback(delta)
	_update_ui_motion(delta)
	_update_combo_meter(delta)
	_update_low_health_vignette(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_browser_hint_acknowledged = true
	elif event is InputEventScreenTouch and event.pressed:
		_browser_hint_acknowledged = true
	elif event is InputEventKey and event.pressed:
		_browser_hint_acknowledged = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_reset_touch_input_state()
		if OS.has_feature("web"):
			_browser_hint_acknowledged = false
	elif what == NOTIFICATION_WM_SIZE_CHANGED:
		_refresh_hud_layout()

func _unhandled_input(event: InputEvent) -> void:
	if _handle_free_touch_joystick_input(event):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			_toggle_pause()
			return
	if (game_over or demo_clear or pause_requested) and event.is_action_pressed("restart_run"):
		_reload_scene()

func _handle_free_touch_joystick_input(event: InputEvent) -> bool:
	if joystick == null or not joystick.visible:
		return false
	if not (OS.has_feature("web") or OS.has_feature("mobile")):
		return false
	if game_over or demo_clear or pause_requested:
		return false
	if event is InputEventScreenTouch:
		var screen_touch := event as InputEventScreenTouch
		if screen_touch.pressed:
			joystick.call("begin_pointer", screen_touch.index, screen_touch.position)
		else:
			joystick.call("end_pointer", screen_touch.index)
		get_viewport().set_input_as_handled()
		return true
	if event is InputEventScreenDrag:
		var screen_drag := event as InputEventScreenDrag
		joystick.call("update_pointer", screen_drag.index, screen_drag.position)
		get_viewport().set_input_as_handled()
		return true
	return false

func _is_portrait_layout() -> bool:
	var viewport_size := get_viewport_rect().size
	return viewport_size.y > viewport_size.x

func _set_portrait_combat_hud_compact(portrait_layout: bool, overlay_actions: bool) -> void:
	var compact_battle_hud := portrait_layout and not overlay_actions
	if hud_weapon != null:
		hud_weapon.visible = not compact_battle_hud
	if hud_tip != null:
		hud_tip.visible = not compact_battle_hud
	if hud_meta_divider != null:
		hud_meta_divider.visible = true
	if hud_objective_divider != null:
		hud_objective_divider.visible = not compact_battle_hud
	if banner_sub_label != null and banner_sub_label.visible:
		banner_sub_label.visible = not compact_battle_hud

func _refresh_hud_layout() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var portrait_layout := viewport_size.y > viewport_size.x
	var compact_width := viewport_size.x < 1320.0
	var compact_height := viewport_size.y < 760.0
	var compact_layout := compact_width or compact_height or portrait_layout
	var overlay_actions := pause_requested or game_over or demo_clear
	var side_margin := 12.0
	var top_margin := 12.0
	var bottom_margin := 18.0
	var overlay_panel_width := minf(viewport_size.x - side_margin * 2.0, 544.0 if not compact_layout else 504.0)
	var overlay_panel_height := clampf(viewport_size.y * (0.36 if portrait_layout else (0.42 if compact_layout else 0.34)), 248.0, 352.0 if portrait_layout else 292.0)
	var overlay_center_y := minf(viewport_size.y * (0.40 if portrait_layout else 0.50), viewport_size.y - overlay_panel_height * 0.5 - bottom_margin - 26.0)
	var center_notice_width := minf(viewport_size.x - side_margin * 2.0, 488.0 if not compact_layout else 452.0)
	var center_notice_height := 72.0 if portrait_layout else 60.0
	var portrait_center_notice_top := viewport_size.y * 0.52
	_set_portrait_combat_hud_compact(portrait_layout, overlay_actions)

	if portrait_layout:
		var hud_card_bottom := minf(viewport_size.y * 0.31, 278.0)
		if hud_card_bg != null:
			hud_card_bg.offset_left = side_margin
			hud_card_bg.offset_top = top_margin
			hud_card_bg.offset_right = viewport_size.x - side_margin
			hud_card_bg.offset_bottom = hud_card_bottom
		if hud_card_border != null:
			hud_card_border.offset_left = side_margin
			hud_card_border.offset_top = top_margin
			hud_card_border.offset_right = viewport_size.x - side_margin
			hud_card_border.offset_bottom = top_margin + 2.0
		if hud_margin_container != null:
			hud_margin_container.offset_left = side_margin + 8.0
			hud_margin_container.offset_top = top_margin + 6.0
			hud_margin_container.offset_right = viewport_size.x - side_margin - 8.0
			hud_margin_container.offset_bottom = hud_card_bottom - 10.0

		var status_top := hud_card_bottom + 10.0
		var status_bottom := status_top + 72.0
		if status_card_bg != null:
			status_card_bg.anchor_left = 0.0
			status_card_bg.anchor_right = 1.0
			status_card_bg.offset_left = side_margin
			status_card_bg.offset_right = -side_margin
			status_card_bg.offset_top = status_top
			status_card_bg.offset_bottom = status_bottom
		if status_card_accent != null:
			status_card_accent.anchor_left = 0.0
			status_card_accent.anchor_right = 1.0
			status_card_accent.offset_left = side_margin
			status_card_accent.offset_right = -side_margin
			status_card_accent.offset_top = status_top
			status_card_accent.offset_bottom = status_top + 3.0
		if status_badge != null:
			status_badge.anchor_left = 0.0
			status_badge.anchor_right = 1.0
			status_badge.offset_left = side_margin + 12.0
			status_badge.offset_right = -side_margin - 12.0
			status_badge.offset_top = status_top + 6.0
			status_badge.offset_bottom = status_top + 28.0
			status_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if status_label != null:
			status_label.anchor_left = 0.0
			status_label.anchor_right = 1.0
			status_label.offset_left = side_margin + 12.0
			status_label.offset_right = -side_margin - 12.0
			status_label.offset_top = status_top + 24.0
			status_label.offset_bottom = status_bottom - 8.0
			status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

		var top_center_top := status_bottom + 6.0
		var top_center_bottom := top_center_top + 52.0
		portrait_center_notice_top = top_center_bottom + 14.0
		if top_center != null:
			top_center.anchor_left = 0.0
			top_center.anchor_right = 1.0
			top_center.offset_left = side_margin
			top_center.offset_right = -side_margin
			top_center.offset_top = top_center_top
			top_center.offset_bottom = top_center_bottom
		if banner_backing != null:
			banner_backing.offset_left = 0.0
			banner_backing.offset_top = 6.0
			banner_backing.offset_right = viewport_size.x - side_margin * 2.0
			banner_backing.offset_bottom = 44.0
		if banner_accent != null:
			banner_accent.offset_left = 20.0
			banner_accent.offset_top = 8.0
			banner_accent.offset_right = viewport_size.x - side_margin * 2.0 - 20.0
			banner_accent.offset_bottom = 12.0
		if banner_label != null:
			banner_label.offset_left = 0.0
			banner_label.offset_top = 0.0
			banner_label.offset_right = viewport_size.x - side_margin * 2.0
			banner_label.offset_bottom = 40.0
		if banner_sub_label != null:
			banner_sub_label.offset_left = 0.0
			banner_sub_label.offset_top = 24.0
			banner_sub_label.offset_right = viewport_size.x - side_margin * 2.0
			banner_sub_label.offset_bottom = 50.0
		if combo_meter != null:
			combo_meter.anchor_left = 0.0
			combo_meter.anchor_right = 1.0
			combo_meter.offset_left = side_margin + 14.0
			combo_meter.offset_right = -side_margin - 14.0
			combo_meter.offset_top = top_center_bottom + 8.0
			combo_meter.offset_bottom = top_center_bottom + 48.0

		var pause_top := top_center_bottom + 10.0
		var pause_bottom := pause_top + 54.0
		if pause_button != null:
			pause_button.anchor_left = 1.0
			pause_button.anchor_top = 0.0
			pause_button.anchor_right = 1.0
			pause_button.anchor_bottom = 0.0
			pause_button.offset_left = -144.0
			pause_button.offset_right = -side_margin
			pause_button.offset_top = pause_top
			pause_button.offset_bottom = pause_bottom
		if continue_button != null:
			continue_button.anchor_left = 0.0
			continue_button.anchor_top = 0.0
			continue_button.anchor_right = 0.5
			continue_button.anchor_bottom = 0.0
		if restart_button != null:
			restart_button.anchor_left = 0.5
			restart_button.anchor_top = 0.0
			restart_button.anchor_right = 1.0
			restart_button.anchor_bottom = 0.0

		var joystick_size := clampf(viewport_size.x * 0.54, 212.0, 250.0)
		var joystick_visual_size := joystick_size
		var dash_w := clampf(viewport_size.x * 0.36, 142.0, 172.0)
		var dash_h := 82.0
		if joystick != null:
			var touch_joystick := joystick as TouchJoystick
			if touch_joystick != null:
				touch_joystick.configure_layout(clampf(joystick_size * 0.37, 78.0, 92.0), clampf(joystick_size * 0.16, 32.0, 38.0), clampf(joystick_size * 0.50, 108.0, 126.0))
				joystick_visual_size = touch_joystick.custom_minimum_size.y
			else:
				joystick.custom_minimum_size = Vector2(joystick_size, joystick_size)
			joystick.offset_left = side_margin
			joystick.offset_right = side_margin + joystick_size
			joystick.offset_top = -joystick_size - 14.0
			joystick.offset_bottom = -14.0
		if dash_button != null:
			dash_button.custom_minimum_size = Vector2(dash_w, dash_h)
			dash_button.offset_left = -dash_w - side_margin
			dash_button.offset_right = -side_margin
			dash_button.offset_top = -dash_h - 14.0
			dash_button.offset_bottom = -14.0

		var hint_width := clampf(viewport_size.x * 0.48, 176.0, 236.0)
		var hint_height := 118.0
		var hint_top := viewport_size.y - maxf(joystick_visual_size, dash_h) - hint_height - 28.0
		if mobile_hint_bg != null:
			mobile_hint_bg.anchor_left = 1.0
			mobile_hint_bg.anchor_top = 0.0
			mobile_hint_bg.anchor_right = 1.0
			mobile_hint_bg.anchor_bottom = 0.0
			mobile_hint_bg.offset_left = -hint_width - side_margin
			mobile_hint_bg.offset_right = -side_margin
			mobile_hint_bg.offset_top = hint_top
			mobile_hint_bg.offset_bottom = hint_top + hint_height
		if mobile_hint_accent != null:
			mobile_hint_accent.anchor_left = 1.0
			mobile_hint_accent.anchor_top = 0.0
			mobile_hint_accent.anchor_right = 1.0
			mobile_hint_accent.anchor_bottom = 0.0
			mobile_hint_accent.offset_left = -hint_width - side_margin + 12.0
			mobile_hint_accent.offset_right = -side_margin - 12.0
			mobile_hint_accent.offset_top = hint_top + 4.0
			mobile_hint_accent.offset_bottom = hint_top + 8.0
		if mobile_hint_title != null:
			mobile_hint_title.anchor_left = 1.0
			mobile_hint_title.anchor_top = 0.0
			mobile_hint_title.anchor_right = 1.0
			mobile_hint_title.anchor_bottom = 0.0
			mobile_hint_title.offset_left = -hint_width - side_margin + 16.0
			mobile_hint_title.offset_right = -side_margin - 16.0
			mobile_hint_title.offset_top = hint_top + 10.0
			mobile_hint_title.offset_bottom = hint_top + 36.0
			mobile_hint_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if mobile_hint != null:
			mobile_hint.anchor_left = 1.0
			mobile_hint.anchor_top = 0.0
			mobile_hint.anchor_right = 1.0
			mobile_hint.anchor_bottom = 0.0
			mobile_hint.offset_left = -hint_width - side_margin + 16.0
			mobile_hint.offset_right = -side_margin - 16.0
			mobile_hint.offset_top = hint_top + 36.0
			mobile_hint.offset_bottom = hint_top + hint_height - 8.0
			mobile_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		var action_region_top := minf(overlay_center_y + overlay_panel_height * 0.5 + 12.0, viewport_size.y - joystick_visual_size - 134.0)
		var action_region_bottom := action_region_top + 104.0
		if action_tray_bg != null:
			action_tray_bg.anchor_left = 0.0
			action_tray_bg.anchor_top = 0.0
			action_tray_bg.anchor_right = 1.0
			action_tray_bg.anchor_bottom = 0.0
			action_tray_bg.offset_left = side_margin
			action_tray_bg.offset_right = -side_margin
			action_tray_bg.offset_top = action_region_top
			action_tray_bg.offset_bottom = action_region_top + 44.0
		if action_tray_accent != null:
			action_tray_accent.anchor_left = 0.0
			action_tray_accent.anchor_top = 0.0
			action_tray_accent.anchor_right = 1.0
			action_tray_accent.anchor_bottom = 0.0
			action_tray_accent.offset_left = side_margin + 12.0
			action_tray_accent.offset_right = -side_margin - 12.0
			action_tray_accent.offset_top = action_region_top + 2.0
			action_tray_accent.offset_bottom = action_region_top + 6.0
		if action_tray_label != null:
			action_tray_label.anchor_left = 0.0
			action_tray_label.anchor_top = 0.0
			action_tray_label.anchor_right = 1.0
			action_tray_label.anchor_bottom = 0.0
			action_tray_label.offset_left = side_margin + 12.0
			action_tray_label.offset_right = -side_margin - 12.0
			action_tray_label.offset_top = action_region_top + 8.0
			action_tray_label.offset_bottom = action_region_top + 34.0
		var action_button_top := action_region_top + 50.0
		var action_button_bottom := minf(action_button_top + 48.0, action_region_bottom)
		if continue_button != null:
			continue_button.offset_left = side_margin + 6.0
			continue_button.offset_right = -6.0
			continue_button.offset_top = action_button_top
			continue_button.offset_bottom = action_button_bottom
		if restart_button != null:
			restart_button.offset_left = 6.0
			restart_button.offset_right = -side_margin - 6.0
			restart_button.offset_top = action_button_top
			restart_button.offset_bottom = action_button_bottom
	else:
		if hud_card_bg != null:
			hud_card_bg.offset_left = 12.0
			hud_card_bg.offset_top = 12.0
			hud_card_bg.offset_right = 382.0 if compact_layout else 438.0
			hud_card_bg.offset_bottom = 354.0 if compact_layout else 336.0
		if hud_card_border != null:
			hud_card_border.offset_left = 12.0
			hud_card_border.offset_top = 12.0
			hud_card_border.offset_right = 382.0 if compact_layout else 438.0
			hud_card_border.offset_bottom = 14.0
		if hud_margin_container != null:
			hud_margin_container.offset_left = 20.0
			hud_margin_container.offset_top = 18.0
			hud_margin_container.offset_right = 420.0
			hud_margin_container.offset_bottom = 320.0

		if status_card_bg != null:
			status_card_bg.anchor_left = 1.0
			status_card_bg.anchor_right = 1.0
			status_card_bg.offset_left = -288.0 if compact_layout else -328.0
			status_card_bg.offset_top = 14.0
			status_card_bg.offset_right = -16.0
			status_card_bg.offset_bottom = 104.0 if compact_layout else 96.0
		if status_card_accent != null:
			status_card_accent.anchor_left = 1.0
			status_card_accent.anchor_right = 1.0
			status_card_accent.offset_left = status_card_bg.offset_left if status_card_bg != null else (-288.0 if compact_layout else -328.0)
			status_card_accent.offset_top = 14.0
			status_card_accent.offset_right = -16.0
			status_card_accent.offset_bottom = 17.0
		if status_badge != null:
			status_badge.anchor_left = 1.0
			status_badge.anchor_right = 1.0
			status_badge.offset_left = -274.0 if compact_layout else -314.0
			status_badge.offset_top = 20.0
			status_badge.offset_right = -28.0
			status_badge.offset_bottom = 42.0
			status_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if status_label != null:
			status_label.anchor_left = 1.0
			status_label.anchor_right = 1.0
			status_label.offset_left = -274.0 if compact_layout else -314.0
			status_label.offset_top = 40.0
			status_label.offset_right = -28.0
			status_label.offset_bottom = 90.0
			status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		if top_center != null:
			top_center.anchor_left = 0.5
			top_center.anchor_right = 0.5
			top_center.offset_left = -280.0
			top_center.offset_top = 20.0
			top_center.offset_right = 280.0
			top_center.offset_bottom = 96.0
		if banner_backing != null:
			banner_backing.offset_left = 76.0
			banner_backing.offset_top = 6.0
			banner_backing.offset_right = 484.0
			banner_backing.offset_bottom = 58.0
		if banner_accent != null:
			banner_accent.offset_left = 104.0
			banner_accent.offset_top = 8.0
			banner_accent.offset_right = 456.0
			banner_accent.offset_bottom = 12.0
		if banner_label != null:
			banner_label.offset_left = 0.0
			banner_label.offset_top = -2.0
			banner_label.offset_right = 560.0
			banner_label.offset_bottom = 40.0
		if banner_sub_label != null:
			banner_sub_label.offset_left = 48.0
			banner_sub_label.offset_top = 34.0
			banner_sub_label.offset_right = 512.0
			banner_sub_label.offset_bottom = 64.0
		if combo_meter != null:
			combo_meter.anchor_left = 0.5
			combo_meter.anchor_right = 0.5
			combo_meter.offset_left = -176.0
			combo_meter.offset_top = 104.0
			combo_meter.offset_right = 176.0
			combo_meter.offset_bottom = 150.0

		if action_tray_bg != null:
			action_tray_bg.anchor_left = 0.5
			action_tray_bg.anchor_right = 0.5
			action_tray_bg.offset_left = -252.0
			action_tray_bg.offset_top = -120.0
			action_tray_bg.offset_right = 252.0
			action_tray_bg.offset_bottom = -18.0
		if action_tray_accent != null:
			action_tray_accent.anchor_left = 0.5
			action_tray_accent.anchor_right = 0.5
			action_tray_accent.offset_left = -236.0
			action_tray_accent.offset_top = -116.0
			action_tray_accent.offset_right = 236.0
			action_tray_accent.offset_bottom = -112.0
		if action_tray_label != null:
			action_tray_label.anchor_left = 0.5
			action_tray_label.anchor_right = 0.5
			action_tray_label.offset_left = -228.0
			action_tray_label.offset_top = -112.0
			action_tray_label.offset_right = 228.0
			action_tray_label.offset_bottom = -84.0
		if continue_button != null:
			continue_button.anchor_left = 0.5
			continue_button.anchor_right = 0.5
			continue_button.offset_left = -232.0
			continue_button.offset_top = -78.0
			continue_button.offset_right = -20.0
			continue_button.offset_bottom = -24.0
		if restart_button != null:
			restart_button.anchor_left = 0.5
			restart_button.anchor_right = 0.5
			restart_button.offset_left = 20.0
			restart_button.offset_top = -78.0
			restart_button.offset_right = 232.0
			restart_button.offset_bottom = -24.0
		if pause_button != null:
			pause_button.anchor_left = 0.5
			pause_button.anchor_right = 0.5
			pause_button.offset_left = -106.0
			pause_button.offset_top = -78.0
			pause_button.offset_right = 106.0
			pause_button.offset_bottom = -24.0
		if joystick != null:
			var landscape_joystick := joystick as TouchJoystick
			if landscape_joystick != null:
				landscape_joystick.configure_layout(68.0, 28.0, 86.0)
			else:
				joystick.custom_minimum_size = Vector2(180.0, 180.0)
			joystick.offset_left = 18.0
			joystick.offset_top = -198.0
			joystick.offset_right = 198.0
			joystick.offset_bottom = -18.0
		if dash_button != null:
			dash_button.offset_left = -226.0
			dash_button.offset_top = -214.0
			dash_button.offset_right = -34.0
			dash_button.offset_bottom = -108.0
		if mobile_hint_bg != null:
			mobile_hint_bg.anchor_left = 1.0
			mobile_hint_bg.anchor_right = 1.0
			mobile_hint_bg.offset_left = -276.0
			mobile_hint_bg.offset_top = -334.0
			mobile_hint_bg.offset_right = -24.0
			mobile_hint_bg.offset_bottom = -222.0
		if mobile_hint_accent != null:
			mobile_hint_accent.anchor_left = 1.0
			mobile_hint_accent.anchor_right = 1.0
			mobile_hint_accent.offset_left = -260.0
			mobile_hint_accent.offset_top = -330.0
			mobile_hint_accent.offset_right = -40.0
			mobile_hint_accent.offset_bottom = -326.0
		if mobile_hint_title != null:
			mobile_hint_title.anchor_left = 1.0
			mobile_hint_title.anchor_right = 1.0
			mobile_hint_title.offset_left = -248.0
			mobile_hint_title.offset_top = -324.0
			mobile_hint_title.offset_right = -38.0
			mobile_hint_title.offset_bottom = -296.0
			mobile_hint_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if mobile_hint != null:
			mobile_hint.anchor_left = 1.0
			mobile_hint.anchor_right = 1.0
			mobile_hint.offset_left = -248.0
			mobile_hint.offset_top = -292.0
			mobile_hint.offset_right = -38.0
			mobile_hint.offset_bottom = -232.0
			mobile_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	if center_notice != null:
		center_notice.anchor_left = 0.5
		center_notice.anchor_top = 0.0
		center_notice.anchor_right = 0.5
		center_notice.anchor_bottom = 0.0
		center_notice.offset_left = -center_notice_width * 0.5
		center_notice.offset_top = portrait_center_notice_top if portrait_layout else (viewport_size.y * 0.34)
		center_notice.offset_right = center_notice_width * 0.5
		center_notice.offset_bottom = center_notice.offset_top + center_notice_height
		if center_notice_backing != null:
			center_notice_backing.offset_left = 16.0
			center_notice_backing.offset_top = 10.0
			center_notice_backing.offset_right = center_notice_width - 16.0
			center_notice_backing.offset_bottom = center_notice_height - 8.0
		if center_notice_accent != null:
			center_notice_accent.offset_left = 44.0
			center_notice_accent.offset_top = 12.0
			center_notice_accent.offset_right = center_notice_width - 44.0
			center_notice_accent.offset_bottom = 16.0
		if center_notice_label != null:
			center_notice_label.offset_left = 0.0
			center_notice_label.offset_top = 0.0
			center_notice_label.offset_right = center_notice_width
			center_notice_label.offset_bottom = center_notice_height
		_center_notice_base_position = center_notice.position

	if focus_panel != null:
		var overlay_panel_left := (viewport_size.x - overlay_panel_width) * 0.5
		var overlay_panel_top := overlay_center_y - overlay_panel_height * 0.5
		focus_panel.anchor_left = 0.0
		focus_panel.anchor_top = 0.0
		focus_panel.anchor_right = 0.0
		focus_panel.anchor_bottom = 0.0
		focus_panel.offset_left = overlay_panel_left
		focus_panel.offset_top = overlay_panel_top
		focus_panel.offset_right = overlay_panel_left + overlay_panel_width
		focus_panel.offset_bottom = overlay_panel_top + overlay_panel_height
		_focus_panel_base_position = focus_panel.position

	if combo_meter != null:
		_combo_meter_base_position = combo_meter.position

	if action_tray_bg != null:
		action_tray_bg.visible = overlay_actions or (compact_layout and not portrait_layout)
	if action_tray_accent != null:
		action_tray_accent.visible = action_tray_bg != null and action_tray_bg.visible
	if action_tray_label != null:
		action_tray_label.visible = action_tray_bg != null and action_tray_bg.visible
		if portrait_layout:
			action_tray_label.text = "戏台战报 · 继续 / 重开"
		elif compact_layout:
			action_tray_label.text = "戏台操作 · 底部续战与重开"
		else:
			action_tray_label.text = "戏台操作 · 暂停 / 续战 / 再闯"
	if joystick != null and joystick.has_method("sync_layout_position"):
		joystick.call("sync_layout_position")
	_apply_mobile_font_scaling()

func _setup_web_ui() -> void:
	var show_touch_ui := OS.has_feature("web") or OS.has_feature("mobile")
	if joystick != null:
		joystick.visible = show_touch_ui
	if dash_button != null:
		dash_button.visible = show_touch_ui
	if mobile_hint_bg != null:
		mobile_hint_bg.visible = show_touch_ui
	if mobile_hint_accent != null:
		mobile_hint_accent.visible = show_touch_ui
	if mobile_hint_title != null:
		mobile_hint_title.visible = show_touch_ui
	if mobile_hint != null:
		mobile_hint.visible = show_touch_ui
	if focus_overlay != null:
		focus_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if restart_button != null:
		restart_button.visible = false
	if continue_button != null:
		continue_button.visible = false
	_refresh_hud_layout()

func _detect_mobile_lite_mode() -> bool:
	if not OS.has_feature("web"):
		return false
	var args := OS.get_cmdline_user_args()
	if args.has("--full-web"):
		return false
	if args.has("--mobile-lite"):
		return true
	var viewport_size := get_viewport_rect().size
	return OS.has_feature("mobile") or viewport_size.x <= 540.0 or viewport_size.y <= 960.0 or viewport_size.y > viewport_size.x

func _apply_mobile_lite_scaling() -> void:
	if not _mobile_lite_mode:
		return
	spawn_count_per_wave = maxi(1, int(ceil(float(spawn_count_per_wave) * 0.68)))
	max_alive_enemies = maxi(10, int(round(float(max_alive_enemies) * 0.58)))
	spawn_timer.wait_time = maxf(0.42, spawn_timer.wait_time + 0.10)

func _should_trim_feedback_fx() -> bool:
	return _mobile_lite_mode and feedback != null and feedback.get_child_count() >= 9

func _update_focus_overlay() -> void:
	if focus_overlay == null or focus_title == null or focus_detail == null:
		return
	var overlay_visible := false
	var badge_text := "花果山戏报"
	if pause_requested:
		overlay_visible = true
		badge_text = "西游小戏台 · 暂歇"
		focus_title.text = "戏台暂歇，行者可先缓一口气"
		focus_detail.text = "此处会保留本局战报。按 Esc / P 或点下方“继续试炼”回战场；若想换一局手感，也可直接重开。"
		if summary_label != null:
			summary_label.text = _build_run_summary("暂歇整装")
	elif game_over:
		overlay_visible = true
		badge_text = "花果山战报 · 败阵"
		focus_title.text = "此局止步，行者请再整旗鼓"
		focus_detail.text = "本局斩妖 %d，头目来袭 %d 次。按 R 或点“再闯一局”，马上回到花果山继续清妖。" % [kill_count, _elites_spawned_total]
		if summary_label != null:
			summary_label.text = _build_run_summary(_get_settlement_title(false))
	elif demo_clear:
		overlay_visible = true
		badge_text = "花果山战报 · 通关"
		focus_title.text = "三分钟试炼已过，花果山喝彩"
		focus_detail.text = "你已撑过 %02d:%02d，当前修为 %d 重。按 R 或点按钮再走一遭，还能继续压更高斩妖分数。" % [int(elapsed_time) / 60, int(elapsed_time) % 60, player.level]
		if summary_label != null:
			summary_label.text = _build_run_summary(_get_settlement_title(true))
	else:
		var needs_hint := false
		if OS.has_feature("web"):
			needs_hint = not _browser_hint_acknowledged
			if not needs_hint and not get_window().has_focus():
				needs_hint = true
		overlay_visible = needs_hint
		if needs_hint:
			badge_text = "西游小戏台 · 开场"
			focus_title.text = "轻点戏台，唤醒身法"
			focus_detail.text = "网页端首次进入或浏览器失焦后，需要先点一下游戏画面。\n桌面端：WASD 走位、Space 筋斗闪；手机端：左下摇杆走位、右下按钮闪身。"
			if _mobile_lite_mode:
				focus_detail.text += "\n当前已启用掌中轻量验收版：敌潮与演出已适度降级，优先保证能打开、能试玩。"
	if focus_badge != null:
		focus_badge.text = badge_text
	if medal_label != null:
		medal_label.visible = pause_requested or game_over or demo_clear
		medal_label.text = _get_medal_line()
	if settlement_stamp != null:
		var stamp_visible: bool = pause_requested or game_over or demo_clear
		settlement_stamp.visible = stamp_visible
		settlement_stamp.text = _get_settlement_stamp_text()
		if stamp_visible != _settlement_stamp_visible_state:
			_settlement_stamp_visible_state = stamp_visible
			if stamp_visible:
				_animate_settlement_stamp()
	if summary_label != null:
		summary_label.visible = pause_requested or game_over or demo_clear
		if not summary_label.visible:
			summary_label.text = ""
	_set_focus_overlay_visible(overlay_visible)
	if continue_button != null:
		continue_button.visible = pause_requested
	if restart_button != null:
		restart_button.visible = pause_requested or game_over or demo_clear
	if pause_button != null:
		pause_button.visible = not game_over and not demo_clear and not pause_requested
	_refresh_hud_layout()

func _update_difficulty() -> void:
	var next_stage := int(floor(elapsed_time / difficulty_step_seconds))
	if next_stage == difficulty_stage:
		return

	difficulty_stage = next_stage
	spawn_timer.wait_time = maxf(0.28, spawn_interval - difficulty_stage * 0.06)
	max_alive_enemies = mini(88, 18 + difficulty_stage * 5 + wave_index * 2)
	_apply_mobile_lite_scaling()
	if difficulty_stage > 0:
		_show_banner("妖势渐盛 · %s" % _get_stage_title(difficulty_stage + 1), "妖潮播报")
		_show_center_notice("妖势升级 · %s" % _get_stage_title(difficulty_stage + 1), HUD_WARNING)
		_add_camera_shake(5.0, 0.18)

func _update_wave_progress() -> void:
	var target_wave: int = mini(int(floor(elapsed_time / wave_length_seconds)) + 1, int(ceil(demo_goal_seconds / wave_length_seconds)))
	if target_wave > wave_index:
		wave_index = target_wave
		_apply_wave_state(false)

func _apply_wave_state(is_initial: bool) -> void:
	spawn_count_per_wave = mini(8, 1 + int((wave_index - 1) / 1.5))
	max_alive_enemies = mini(88, 14 + wave_index * 8 + difficulty_stage * 4)
	spawn_timer.wait_time = maxf(0.28, spawn_interval - wave_index * 0.08 - difficulty_stage * 0.05)
	_apply_mobile_lite_scaling()
	_trigger_respite(1.55 if is_initial else 2.05, 0.58 if wave_index <= 2 else 0.46, 0.12 if wave_index <= 3 else 0.18, 0.16 if wave_index <= 4 else 0.24)
	_setup_wave_objective()
	_queue_wave_spawn_patterns()
	if not is_initial:
		player.heal(1)
		_show_banner("第%d劫 · %s" % [wave_index, _get_wave_title(wave_index)], "劫波播报")
		_show_center_notice("第%d劫开场 · %s" % [wave_index, _get_wave_title(wave_index)], HUD_GOLD)
		_spawn_popup(player.global_position + Vector2(0, -32), "+1 命", HUD_MINT)
		_spawn_burst(player.global_position, HUD_MINT, 1.2, 1.15)
		_spawn_reward_pulse(player.global_position, HUD_GOLD, 1.08, 1.18, 6 + mini(3, wave_index / 2))
		_spawn_milestone_flare(player.global_position + Vector2(0, -14), HUD_GOLD, 0.88 + float(wave_index) * 0.04, 0.82, 4 + mini(2, wave_index / 3))
		_flash_screen(HUD_GOLD, 0.10, 0.14)
		_add_camera_shake(7.0, 0.26)
		_spawn_elite_pack_for_wave()
	_update_tip_text()

func _spawn_elite_pack_for_wave() -> void:
	if wave_index < 2 or game_over or demo_clear:
		return
	var elite_count := 0
	if wave_index % 2 == 0:
		elite_count += 1
	if wave_index >= 5:
		elite_count += 1
	if player.health <= 2 or _get_spawn_pressure_tier() >= 2:
		elite_count = maxi(0, elite_count - 1)
	if _mobile_lite_mode:
		elite_count = maxi(0, elite_count - 1)
	for _i in range(elite_count):
		if enemies.get_child_count() >= max_alive_enemies:
			break
		_spawn_enemy(true)
	if elite_count > 0:
		_spawn_popup(player.global_position + Vector2(0, -58), "头目现身", HUD_WARNING)
		_show_center_notice("头目压阵 · 当心贴脸", HUD_WARNING)

func _on_spawn_timer_timeout() -> void:
	if enemy_scene == null or not is_instance_valid(player) or game_over or demo_clear:
		return

	var available_slots := max_alive_enemies - enemies.get_child_count()
	if available_slots <= 0:
		return

	var respite_factor := _respite_spawn_multiplier if _respite_time_remaining > 0.0 else 1.0
	var spawn_total := mini(int(ceil((spawn_count_per_wave + int(wave_index / 3)) * respite_factor)), available_slots)
	spawn_total = maxi(1, spawn_total)
	var pressure_tier := _get_spawn_pressure_tier()
	if pressure_tier >= 3:
		spawn_total = maxi(1, spawn_total - 2)
	elif pressure_tier >= 2:
		spawn_total = maxi(1, spawn_total - 1)
	while spawn_total > 0 and available_slots > 0 and _queued_spawn_entries.size() > 0:
		var queued_entry: Dictionary = _queued_spawn_entries.pop_front()
		if pressure_tier >= 3 and String(queued_entry.get("preferred_type", SPAWN_TYPE_BASIC)) != SPAWN_TYPE_BASIC:
			continue
		var queued_position: Vector2 = queued_entry.get("position", _get_spawn_position())
		_spawn_enemy_at_position(queued_position, bool(queued_entry.get("force_elite", false)), String(queued_entry.get("preferred_type", SPAWN_TYPE_BASIC)))
		spawn_total -= 1
		available_slots -= 1
	for _i in range(mini(spawn_total, available_slots)):
		_spawn_enemy(false, SPAWN_TYPE_BASIC if pressure_tier >= 3 else "")

func _spawn_enemy(force_elite: bool = false, preferred_type: String = "") -> void:
	_spawn_enemy_at_position(_get_spawn_position(), force_elite, preferred_type)

func _spawn_enemy_at_position(spawn_position: Vector2, force_elite: bool = false, preferred_type: String = "") -> void:
	var weights := _get_enemy_spawn_weights()
	var spawn_roll := randf()
	var scene_to_spawn: PackedScene = enemy_scene
	var tank_weight: float = weights.y
	var fast_weight: float = weights.x
	if preferred_type == SPAWN_TYPE_TANK and tank_enemy_scene != null:
		scene_to_spawn = tank_enemy_scene
	elif preferred_type == SPAWN_TYPE_FAST and fast_enemy_scene != null:
		scene_to_spawn = fast_enemy_scene
	elif preferred_type == SPAWN_TYPE_BASIC:
		scene_to_spawn = enemy_scene
	elif tank_enemy_scene != null and spawn_roll < tank_weight:
		scene_to_spawn = tank_enemy_scene
	elif fast_enemy_scene != null and spawn_roll < tank_weight + fast_weight:
		scene_to_spawn = fast_enemy_scene

	var enemy: Node = scene_to_spawn.instantiate()
	if enemy == null:
		return

	enemy.global_position = spawn_position
	enemy.set("move_speed", float(enemy.get("move_speed")) + difficulty_stage * 5.0 + max(0, wave_index - 1) * 4.0 + max(0, player.level - 1) * 3.0)
	enemy.set("max_health", int(enemy.get("max_health")) + int((difficulty_stage + wave_index - 1) / 3))
	enemy.set("contact_damage", int(enemy.get("contact_damage")) + int((difficulty_stage + wave_index - 1) / 5))
	enemy.set("xp_reward", int(enemy.get("xp_reward")) + int((wave_index - 1) / 2))
	enemy.set("target", player)
	if enemy.has_method("set_spawn_grace"):
		enemy.set_spawn_grace(0.55 if wave_index <= 2 else 0.42)
	if force_elite and enemy.has_method("make_elite"):
		enemy.make_elite(1.28 + minf(0.14, float(wave_index - 2) * 0.02))
		_elites_spawned_total += 1
		_add_camera_shake(9.0, 0.25)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	if enemy.has_signal("damaged"):
		enemy.damaged.connect(_on_enemy_damaged)
	enemies.add_child(enemy)

func _get_enemy_spawn_weights() -> Vector2:
	var fast_weight: float = minf(0.52, 0.14 + wave_index * 0.05 + difficulty_stage * 0.02)
	var tank_weight: float = 0.0
	if wave_index >= 3:
		tank_weight = minf(0.26, 0.06 + (wave_index - 2) * 0.04)
	match _wave_objective_type:
		"survive":
			fast_weight *= 0.72
			tank_weight *= 0.58
		"kills":
			fast_weight *= 1.10
			tank_weight *= 0.74
		"elite":
			fast_weight *= 0.78
			tank_weight *= 1.14 if wave_index >= 3 else 1.0
	if _respite_time_remaining > 0.0:
		fast_weight *= maxf(0.45, 1.0 - _respite_fast_penalty)
		tank_weight *= maxf(0.30, 1.0 - _respite_tank_penalty)
	var alive_tanks := 0
	var alive_fast := 0
	var close_pressure := 0.0
	for child in enemies.get_children():
		if child == null or not is_instance_valid(child):
			continue
		var scene_file := String(child.scene_file_path)
		if scene_file.ends_with("enemy_tank.tscn"):
			alive_tanks += 1
		elif scene_file.ends_with("enemy_runner.tscn"):
			alive_fast += 1
		if child is Node2D:
			var distance := player.global_position.distance_to((child as Node2D).global_position)
			if distance < 180.0:
				close_pressure += 1.0
				if scene_file.ends_with("enemy_tank.tscn"):
					close_pressure += 0.9
				elif scene_file.ends_with("enemy_runner.tscn"):
					close_pressure += 0.45
	if alive_tanks >= 2 and wave_index < 6:
		tank_weight *= 0.35
	if alive_fast >= int(maxi(3, wave_index + 1)):
		fast_weight *= 0.65
	var pressure_tier := _get_spawn_pressure_tier(close_pressure, alive_fast, alive_tanks)
	if pressure_tier >= 3:
		fast_weight *= 0.32
		tank_weight *= 0.22
	elif pressure_tier >= 2:
		fast_weight *= 0.55
		tank_weight *= 0.42
	return Vector2(clampf(fast_weight, 0.0, 0.65), clampf(tank_weight, 0.0, 0.32))

func _on_attack_timer_timeout() -> void:
	if projectile_scene == null or not is_instance_valid(player) or game_over or demo_clear:
		return

	var range_value: float = float(attack_range) + float(player.level) * 14.0
	var target: Node2D = _get_nearest_enemy_in_range(range_value)
	if target == null:
		return

	var bonus_attack_speed := 0.18 if _bonus_attack_speed_time > 0.0 else 0.0
	attack_timer.wait_time = maxf(0.12, attack_interval - (player.level - 1) * 0.02 - bonus_attack_speed - minf(0.12, float(_merit_stacks) * 0.02))
	var shot_count := 1 + int((player.level - 1) / 4) + (1 if _bonus_multishot_time > 0.0 else 0)
	shot_count = mini(shot_count, 5)
	var pierce_count := int((player.level - 1) / 5) + (1 if _bonus_pierce_time > 0.0 else 0)
	var base_direction := (target.global_position - player.global_position).normalized()
	var spread_step := deg_to_rad(10.0)
	var start_angle := -spread_step * float(shot_count - 1) * 0.5
	_spawn_burst(player.global_position + base_direction * 18.0, HUD_GOLD, 0.48, 0.75)

	for i in range(shot_count):
		var projectile := projectile_scene.instantiate()
		if projectile == null:
			continue
		var angle_offset := start_angle + spread_step * i
		var direction := base_direction.rotated(angle_offset)
		projectile.global_position = player.global_position
		projectile.set("direction", direction)
		projectile.set("speed", projectile_speed + player.level * 18.0 + wave_index * 6.0 + _merit_stacks * 10.0)
		var projectile_damage := 1 + int((player.level - 1) / 3) + int((wave_index - 1) / 4) + int(_merit_stacks / 2) + (1 if _bonus_damage_time > 0.0 else 0)
		projectile.set("damage", projectile_damage)
		projectile.set("pierce", pierce_count)
		projectiles.add_child(projectile)

func _get_nearest_enemy_in_range(range_limit: float) -> Node2D:
	var nearest: Node2D = null
	var nearest_distance_sq := range_limit * range_limit

	for child in enemies.get_children():
		if child == null or not is_instance_valid(child):
			continue
		var distance_sq := player.global_position.distance_squared_to(child.global_position)
		if distance_sq <= nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest = child as Node2D

	return nearest

func _on_enemy_damaged(enemy: Node, hit_position: Vector2, remaining_health: int, max_health_value: int, was_elite: bool) -> void:
	var color_value := HUD_WARNING if was_elite else HUD_GOLD
	var radius_scale := 0.82 + (0.35 if was_elite else 0.0)
	var hit_direction := Vector2.RIGHT
	if enemy != null and enemy is Node2D:
		hit_direction = ((enemy as Node2D).global_position - player.global_position).normalized()
	if hit_direction == Vector2.ZERO:
		hit_direction = Vector2.RIGHT
	_spawn_burst(hit_position, color_value, radius_scale, 0.78)
	_spawn_slash(hit_position, hit_direction.angle(), color_value, 0.72 + (0.22 if was_elite else 0.0), 0.82)
	if remaining_health == 1:
		_spawn_popup(hit_position + Vector2(0, -30), "破势", HUD_ROSE if was_elite else HUD_WARNING)
	if was_elite:
		_flash_screen(color_value, 0.08, 0.12)
		_spawn_milestone_flare(hit_position, color_value, 0.82, 0.82, 4)
	if remaining_health > 0 and max_health_value >= 4:
		_spawn_popup(hit_position + Vector2(0, -18), "%d/%d" % [remaining_health, max_health_value], HUD_PAPER)

func _on_enemy_died(enemy: Node, death_position: Vector2, xp_reward: int) -> void:
	kill_count += 1
	_kill_streak += 1
	_kill_streak_timer = 2.4
	_best_kill_streak = maxi(_best_kill_streak, _kill_streak)
	var popup_color := HUD_MINT
	var popup_text := "修为 +%d" % xp_reward
	var burst_scale := 1.1
	var slash_scale := 1.0
	var flash_alpha := 0.10
	var enemy_is_elite := enemy != null and bool(enemy.get("is_elite"))
	if enemy_is_elite:
		_elite_kill_count += 1
	_update_wave_objective_from_kill(enemy)
	if enemy_is_elite:
		popup_color = HUD_WARNING
		popup_text = "头目修为 +%d" % xp_reward
		burst_scale = 1.55
		slash_scale = 1.32
		flash_alpha = 0.16
		_add_camera_shake(8.0, 0.22)
		_spawn_milestone_flare(death_position, popup_color, 1.12, 0.96, 5)
	_spawn_popup(death_position, popup_text, popup_color)
	_spawn_burst(death_position, popup_color, burst_scale, 1.0)
	_spawn_slash(death_position, randf_range(-0.65, 0.65), popup_color, slash_scale, 1.0)
	_spawn_reward_pulse(death_position, popup_color, 0.72 + burst_scale * 0.28, 0.82, 6 + mini(4, _kill_streak / 3))
	_show_combo_meter()
	if _kill_streak >= 4 and _kill_streak % 4 == 0:
		var streak_color := HUD_WARNING if _kill_streak < 12 else HUD_MINT
		_spawn_reward_pulse(player.global_position, streak_color, 1.02 + float(_kill_streak) * 0.02, 0.92, 8 + mini(6, _kill_streak / 2))
		if _kill_streak >= 8:
			_spawn_milestone_flare(player.global_position + Vector2(0, -10), streak_color, 0.92 + float(_kill_streak) * 0.015, 0.86, 5 + mini(2, _kill_streak / 8))
	_flash_screen(popup_color, flash_alpha, 0.15)
	if _kill_streak == 6 or _kill_streak == 12 or _kill_streak == 20:
		_show_center_notice("连斩 %d · 妖群失势" % _kill_streak, HUD_WARNING if _kill_streak < 20 else HUD_MINT)
		_spawn_burst(player.global_position, HUD_WARNING if _kill_streak < 20 else HUD_MINT, 1.35 + _kill_streak * 0.02, 1.05)
		_spawn_slash(player.global_position, -PI * 0.5, HUD_WARNING if _kill_streak < 20 else HUD_MINT, 1.22 + _kill_streak * 0.01, 1.12)
	var expected_heal_rewards := int(kill_count / 25)
	if expected_heal_rewards > _heals_awarded_by_kills:
		_heals_awarded_by_kills = expected_heal_rewards
		player.heal(1)
		_spawn_popup(player.global_position + Vector2(0, -28), "连斩福泽 +1 命", HUD_SKY)
		_show_center_notice("连斩福泽 · 命火回涌", HUD_SKY)
		_spawn_burst(player.global_position, HUD_SKY, 1.15, 1.05)
		_spawn_slash(player.global_position, -PI * 0.5, HUD_SKY, 1.18, 1.05)
		_flash_screen(HUD_SKY, 0.12, 0.16)
	# Kill milestones: explicit achievement moments at key thresholds
	var milestone_threshold := 0
	var milestone_label := ""
	var milestone_color := HUD_GOLD
	var milestone_xp_bonus := 0
	var milestone_extra := ""
	match kill_count:
		25:
			milestone_threshold = 25
			milestone_label = "初露锋芒"
			milestone_color = HUD_MINT
			milestone_xp_bonus = 3
			milestone_extra = "斩妖 25"
		50:
			milestone_threshold = 50
			milestone_label = "斩妖除魔"
			milestone_color = HUD_MINT
			milestone_xp_bonus = 5
			milestone_extra = "斩妖 50"
		75:
			milestone_threshold = 75
			milestone_label = "威震四方"
			milestone_color = HUD_GOLD
			milestone_xp_bonus = 7
			milestone_extra = "斩妖 75"
		100:
			milestone_threshold = 100
			milestone_label = "威名远扬"
			milestone_color = HUD_GOLD
			milestone_xp_bonus = 10
			milestone_extra = "斩妖破百"
		150:
			milestone_threshold = 150
			milestone_label = "绝代风华"
			milestone_color = HUD_MINT
			milestone_xp_bonus = 15
			milestone_extra = "斩妖 150"
	if milestone_threshold > 0:
		_show_center_notice("%s · %s" % [milestone_label, milestone_extra], milestone_color)
		_spawn_popup(player.global_position + Vector2(0, -90), milestone_label, milestone_color)
		_spawn_burst(player.global_position, milestone_color, 1.42, 1.15)
		_spawn_slash(player.global_position, -PI * 0.5, milestone_color, 1.48, 1.18)
		_spawn_reward_pulse(player.global_position, milestone_color, 1.28, 1.05, 12)
		_spawn_milestone_flare(player.global_position + Vector2(0, -14), milestone_color, 1.15, 0.92, 7)
		_flash_screen(milestone_color, 0.13, 0.18)
		_add_camera_shake(9.0, 0.22)
		if player != null and player.has_method("collect_xp"):
			player.collect_xp(milestone_xp_bonus)
		# Extra temporary buffs for high milestones
		if milestone_threshold >= 50:
			_bonus_attack_speed_time = maxf(_bonus_attack_speed_time, 6.0)
		if milestone_threshold >= 75:
			_bonus_damage_time = maxf(_bonus_damage_time, 6.0)
		if milestone_threshold >= 100:
			player.heal(1)
			_bonus_multishot_time = maxf(_bonus_multishot_time, 8.0)
	if xp_orb_scene == null:
		return

	var xp_orb := xp_orb_scene.instantiate()
	if xp_orb == null:
		return

	xp_orb.global_position = death_position
	xp_orb.set("xp_value", xp_orb_value + xp_reward - 1)
	xp_orb.set("target", player)
	xp_orb.set("magnet_distance", 110.0 + player.level * 6.0 + (18.0 if enemy != null and bool(enemy.get("is_elite")) else 0.0))
	xp_orb.set("move_speed", 180.0 + player.level * 7.0)
	xp_orb.set("rush_speed", 420.0 + player.level * 12.0 + (60.0 if enemy != null and bool(enemy.get("is_elite")) else 0.0))
	pickups.call_deferred("add_child", xp_orb)

func _on_player_xp_changed(current_xp: int, xp_to_next: int, level: int) -> void:
	attack_timer.wait_time = maxf(0.12, attack_interval - (level - 1) * 0.02 - (0.18 if _bonus_attack_speed_time > 0.0 else 0.0) - minf(0.12, float(_merit_stacks) * 0.02))
	hud_level.text = "行者 %d重  ·  %s" % [level, _get_stage_title(difficulty_stage + 1)]
	hud_xp_bar.max_value = max(1, xp_to_next)
	hud_xp_bar.value = current_xp
	hud_xp_bar.show_percentage = false
	hud_xp_bar.tooltip_text = "修为 %d / %d" % [current_xp, xp_to_next]
	if hud_xp_label != null:
		hud_xp_label.text = "修为 %d / %d" % [current_xp, xp_to_next]
	var bonus_attack_speed := " · 急速" if _bonus_attack_speed_time > 0.0 else ""
	var shots := 1 + int((level - 1) / 4) + (1 if _bonus_multishot_time > 0.0 else 0)
	shots = mini(shots, 5)
	var pierce := int((level - 1) / 5) + (1 if _bonus_pierce_time > 0.0 else 0)
	var damage := 1 + int((level - 1) / 3) + int((wave_index - 1) / 4) + int(_merit_stacks / 2) + (1 if _bonus_damage_time > 0.0 else 0)
	hud_weapon.text = "法术：%d 伤 · %d 连发 · %d 穿透%s · 军功 %d" % [damage, shots, pierce, bonus_attack_speed, _merit_stacks]
	if level > _last_level:
		_show_banner("修为精进 · 行者 %d重" % level, "修为播报")
		_show_center_notice("修为精进 · 行者 %d 重" % level, HUD_MINT)
		_spawn_burst(player.global_position, HUD_MINT, 1.45, 1.25)
		_spawn_slash(player.global_position, -PI * 0.5, HUD_MINT, 1.55, 1.24)
		_spawn_reward_pulse(player.global_position, HUD_MINT, 1.32, 1.12, 10)
		_spawn_milestone_flare(player.global_position + Vector2(0, -16), HUD_MINT, 1.08 + float(level) * 0.04, 1.0, 5 + mini(3, level / 3))
		_flash_screen(HUD_MINT, 0.14, 0.18)
		_add_camera_shake(6.0, 0.18)
		_hud_card_glow(HUD_GOLD, 0.55, 0.45)
	_last_level = level

func _on_player_stats_changed(health: int, max_health: int, _level: int) -> void:
	hud_health.text = "命火 %d/%d  ·  出手 %.2fs" % [health, max_health, attack_timer.wait_time]
	if health <= 2:
		hud_health.add_theme_color_override("font_color", HUD_DANGER)
	else:
		hud_health.add_theme_color_override("font_color", HUD_PAPER)
	if _last_health >= 0 and health < _last_health and not game_over:
		_trigger_respite(1.6, 0.52, 0.24, 0.30)
		_spawn_popup(player.global_position + Vector2(0, -22), "-%d 命" % (_last_health - health), HUD_DANGER)
		_spawn_burst(player.global_position, HUD_DANGER, 1.05, 0.95)
		_spawn_slash(player.global_position, PI * 0.5, HUD_DANGER, 1.12, 0.92)
		_flash_screen(HUD_DANGER, 0.16, 0.14)
		_show_center_notice("命火受创 · 先拉开身位", HUD_DANGER)
		_spawn_reward_pulse(player.global_position, HUD_DANGER, 0.96, 0.82, 7)
		_add_camera_shake(10.0, 0.16)
	_last_health = health
	if health <= 0 and not game_over:
		_on_player_died()
	_update_tip_text()

func _on_player_dash_state_changed(is_ready: bool, cooldown_remaining: float, is_dashing: bool) -> void:
	if dash_button == null:
		return
	if is_dashing:
		dash_button.text = "筋斗闪!"
		dash_button.disabled = false
		_hide_dash_cooldown_bar()
	elif is_ready:
		dash_button.text = "筋斗闪"
		dash_button.disabled = false
		_hide_dash_cooldown_bar()
	else:
		dash_button.text = "%.1fs" % cooldown_remaining
		dash_button.disabled = true
		_show_dash_cooldown_bar(cooldown_remaining)

func _show_dash_cooldown_bar(remaining: float) -> void:
	if dash_cooldown_bar == null or player == null:
		return
	var total: float = player.dash_cooldown
	if total <= 0.0:
		return
	var fill_ratio := clampf(remaining / total, 0.0, 1.0)
	var bar_height := maxf(1.0, fill_ratio * 10.0)
	dash_cooldown_bar.visible = true
	dash_cooldown_bar.offset_top = -bar_height
	dash_cooldown_bar.offset_bottom = 0.0

func _hide_dash_cooldown_bar() -> void:
	if dash_cooldown_bar == null:
		return
	dash_cooldown_bar.visible = false
	dash_cooldown_bar.offset_top = -10.0
	dash_cooldown_bar.offset_bottom = 0.0

func _on_dash_button_pressed() -> void:
	if player != null and player.has_method("request_dash"):
		if player.request_dash():
			_browser_hint_acknowledged = true
			_spawn_popup(player.global_position + Vector2(0, -38), "筋斗闪", HUD_WARNING)
			_spawn_burst(player.global_position, HUD_WARNING, 0.95, 0.82)
			_spawn_slash(player.global_position, player.rotation, HUD_WARNING, 0.92, 0.78)
			_add_camera_shake(4.0, 0.12)

func _on_player_died() -> void:
	if game_over:
		return
	game_over = true
	_reset_touch_input_state()
	spawn_timer.stop()
	attack_timer.stop()
	hud_tip.text = "功行散尽 · 按 R 或点右下再闯一局"
	_set_pause_state(false)
	_show_banner("此局止步 · 斩妖 %d" % kill_count, "战报播报")
	_show_center_notice("此局止步 · 再闯一局", HUD_DANGER)
	_spawn_burst(player.global_position, HUD_DANGER, 1.9, 1.35)
	_spawn_reward_pulse(player.global_position, HUD_DANGER, 1.55, 1.28, 12)
	_spawn_milestone_flare(player.global_position + Vector2(0, -16), HUD_DANGER, 1.28, 1.06, 6)
	_spawn_slash(player.global_position, PI * 0.5, HUD_DANGER, 1.75, 1.22)
	_flash_screen(HUD_DANGER, 0.22, 0.22)
	_add_camera_shake(12.0, 0.28)
	if restart_button != null:
		restart_button.visible = true

func _on_demo_clear() -> void:
	if demo_clear:
		return
	demo_clear = true
	_reset_touch_input_state()
	spawn_timer.stop()
	attack_timer.stop()
	hud_tip.text = "试炼通关 · 按 R 或点右下再走一遭"
	_set_pause_state(false)
	_show_banner("大圣护场 · 存活 %02d:%02d" % [int(elapsed_time) / 60, int(elapsed_time) % 60], "喝彩播报")
	_show_center_notice("通关喝彩 · 大圣护场", HUD_MINT)
	_spawn_burst(player.global_position, HUD_MINT, 2.1, 1.5)
	_spawn_reward_pulse(player.global_position, HUD_MINT, 1.72, 1.35, 14)
	_spawn_milestone_flare(player.global_position + Vector2(0, -18), HUD_MINT, 1.62, 1.18, 7)
	_spawn_milestone_flare(player.global_position + Vector2(-48, -8), HUD_GOLD, 1.12, 1.02, 5)
	_spawn_milestone_flare(player.global_position + Vector2(48, -8), HUD_GOLD, 1.12, 1.02, 5)
	_spawn_slash(player.global_position, -PI * 0.5, HUD_MINT, 1.9, 1.38)
	_flash_screen(HUD_MINT, 0.18, 0.22)
	_add_camera_shake(10.0, 0.35)
	if restart_button != null:
		restart_button.visible = true

func _update_enemy_count() -> void:
	hud_enemies.text = "妖群 %d/%d" % [enemies.get_child_count(), max_alive_enemies]

func _update_meta_hud() -> void:
	var total_seconds := int(elapsed_time)
	var minutes := int(total_seconds / 60)
	var seconds := total_seconds % 60
	var next_wave_in := maxi(0, int(ceil(float(wave_index) * wave_length_seconds - elapsed_time)))
	var portrait_layout := _is_portrait_layout()
	if portrait_layout:
		hud_timer.text = "时辰 %02d:%02d" % [minutes, seconds]
		hud_kills.text = "斩 %d · 头目 %d" % [kill_count, _elites_spawned_total]
		hud_enemies.text = "场上 %d/%d" % [enemies.get_child_count(), max_alive_enemies]
		hud_wave.text = "第%d劫 · %s · %02ds" % [wave_index, _get_wave_title(wave_index), next_wave_in]
	else:
		hud_timer.text = "时辰 %02d:%02d / %02d:%02d" % [minutes, seconds, int(demo_goal_seconds) / 60, int(demo_goal_seconds) % 60]
		hud_kills.text = "斩妖 %d  ·  头目 %d" % [kill_count, _elites_spawned_total]
		hud_wave.text = "第%d劫：%s  ·  下波 %02ds" % [wave_index, _get_wave_title(wave_index), next_wave_in]
	var target_label: String = String(OBJECTIVE_LABELS.get(_wave_objective_type, "稳住阵脚"))
	var objective_progress := "%d/%d" % [_wave_objective_progress, max(1, _wave_objective_target)]
	if _wave_objective_type == "survive":
		objective_progress = "%ds/%ds" % [_wave_objective_progress, max(1, _wave_objective_target)]
	var reward_tail := ""
	if _wave_objective_completed and _wave_objective_reward_text != "":
		reward_tail = " · 已得 %s" % _wave_objective_reward_text
	if portrait_layout:
		if _wave_objective_completed and _wave_objective_reward_text != "":
			reward_tail = " · 奖 %s" % _wave_objective_reward_text
		hud_objective.text = "军令：%s %s%s" % [target_label, objective_progress, reward_tail]
	else:
		hud_objective.text = "本劫军令：%s %s%s" % [target_label, objective_progress, reward_tail]

func _update_status_card() -> void:
	if status_label == null:
		return
	var next_heal_goal := (_heals_awarded_by_kills + 1) * 25
	var kills_to_heal := maxi(0, next_heal_goal - kill_count)
	var portrait_layout := _is_portrait_layout()
	var badge_text := "香火签"
	var status_title := "金箍势稳"
	var status_detail := "福泽香火未满，离下一口回命还差 %d 斩妖。当前军功 %d。" % [kills_to_heal, _merit_stacks]
	if portrait_layout:
		status_detail = "回命还差 %d 斩 · 军功 %d" % [kills_to_heal, _merit_stacks]
	if not _wave_objective_completed:
		status_detail = "当前军令：%s · 已攒军功 %d" % [OBJECTIVE_DETAILS.get(_wave_objective_type, "先稳住这一劫的节奏。"), _merit_stacks]
		if portrait_layout:
			status_detail = "军令未完 · %s" % OBJECTIVE_LABELS.get(_wave_objective_type, "稳住阵脚")
	if _kill_streak >= 4 and _kill_streak_timer > 0.0:
		badge_text = "连斩签"
		status_title = "连斩起势"
		status_detail = "当前连斩 %d · 再接住节奏，可把妖潮压成空档。" % _kill_streak
		if portrait_layout:
			status_detail = "连斩 %d · 继续压场" % _kill_streak
	var status_color := HUD_PAPER
	var accent_color := HUD_GOLD
	var background_color := HUD_PANEL
	if game_over:
		badge_text = "败阵签"
		status_title = "败阵回看"
		status_detail = "本局招式已经记下，按 R / 按钮重开，再试一套更顺的走位。"
		if portrait_layout:
			status_detail = "本局已记档 · 右下可重开"
		status_color = HUD_DANGER
		accent_color = HUD_DANGER
		background_color = Color(0.22, 0.08, 0.08, 0.82)
	elif demo_clear:
		badge_text = "喝彩签"
		status_title = "大圣喝彩"
		status_detail = "三分钟试炼已过，可立刻再闯一局，继续冲更高斩妖与修为。"
		if portrait_layout:
			status_detail = "试炼已过 · 可继续冲分"
		status_color = HUD_MINT
		accent_color = HUD_MINT
		background_color = Color(0.10, 0.16, 0.12, 0.82)
	elif pause_requested:
		badge_text = "暂歇签"
		status_title = "戏台暂歇"
		status_detail = "当前波次与战报都保留着，点继续试炼即可无缝回场。"
		if portrait_layout:
			status_detail = "战报保留中 · 可直接续战"
		status_color = HUD_SKY
		accent_color = HUD_SKY
		background_color = Color(0.08, 0.12, 0.18, 0.82)
	elif player.health <= 2:
		badge_text = "告急签"
		status_title = "命火告急"
		status_detail = "先筋斗闪拉位，再收修为球续命；这局别跟妖群硬换。"
		if portrait_layout:
			status_detail = "先闪再拉位 · 别硬换"
		status_color = HUD_DANGER
		accent_color = HUD_DANGER
		background_color = Color(0.22, 0.08, 0.08, 0.82)
	elif wave_index >= 5:
		badge_text = "压阵签"
		status_title = "火云压阵"
		status_detail = "终局妖潮已起：先避重装贴脸，留一段筋斗闪穿出包围。"
		if portrait_layout:
			status_detail = "先拆边路 · 留闪出围"
		status_color = HUD_WARNING
		accent_color = HUD_WARNING
		background_color = Color(0.20, 0.12, 0.05, 0.82)
	elif _bonus_attack_speed_time > 0.0 or _bonus_damage_time > 0.0 or _bonus_multishot_time > 0.0 or _bonus_pierce_time > 0.0:
		badge_text = "军令签"
		status_title = "赏功加身"
		status_detail = "%s，趁赏功时段把妖潮再往回压。当前军功 %d。" % [_wave_objective_reward_text, _merit_stacks]
		if portrait_layout:
			status_detail = "赏功生效 · 趁势压回去"
		status_color = HUD_MINT
		accent_color = HUD_MINT
		background_color = Color(0.10, 0.16, 0.12, 0.82)
	elif kills_to_heal <= 5:
		badge_text = "福泽签"
		status_title = "福泽将满"
		status_detail = "再斩 %d 妖，就有一口回命香火续上。" % kills_to_heal
		if portrait_layout:
			status_detail = "再斩 %d 妖回命" % kills_to_heal
		status_color = HUD_MINT
		accent_color = HUD_MINT
		background_color = Color(0.10, 0.16, 0.12, 0.82)
	status_label.text = ("%s · %s" if portrait_layout and not (pause_requested or game_over or demo_clear) else "%s\n%s") % [status_title, status_detail]
	status_label.add_theme_color_override("font_color", status_color)
	if status_badge != null:
		status_badge.text = badge_text
		status_badge.add_theme_color_override("font_color", accent_color)
	if status_card_accent != null:
		status_card_accent.color = accent_color
	if status_card_bg != null:
		status_card_bg.color = background_color

func _update_kill_streak(delta: float) -> void:
	if _kill_streak_timer > 0.0:
		_kill_streak_timer = maxf(0.0, _kill_streak_timer - delta)
		if _kill_streak_timer == 0.0:
			if _kill_streak >= 8:
				_show_center_notice("连斩收势 · 最长 %d" % _kill_streak, HUD_SKY)
			_kill_streak = 0

func _spawn_popup(world_position: Vector2, text_value: String, color_value: Color) -> void:
	if damage_popup_scene == null:
		return
	var popup := damage_popup_scene.instantiate()
	if popup == null:
		return
	popup.position = world_position
	if popup.has_method("setup"):
		popup.setup(text_value, color_value)
	feedback.add_child(popup)

func _spawn_collect_pulse(world_position: Vector2, color_value: Color, scale_mul: float = 1.0, duration_mul: float = 1.0) -> void:
	if collect_pulse_scene == null or _mobile_lite_mode:
		return
	var pulse := collect_pulse_scene.instantiate()
	if pulse == null:
		return
	if pulse is Node2D:
		(pulse as Node2D).position = world_position
	if pulse.has_method("setup"):
		pulse.setup(color_value, Color(1.0, 0.98, 0.92, 0.95), scale_mul, duration_mul)
	feedback.add_child(pulse)

func _on_xp_collected(amount: int, world_position: Vector2) -> void:
	var scale_mul := 1.0
	if amount >= 5:
		scale_mul = 1.45
	elif amount >= 3:
		scale_mul = 1.18
	else:
		scale_mul = 0.92
	_spawn_collect_pulse(world_position, HUD_GOLD, scale_mul, 1.0)

func _spawn_burst(world_position: Vector2, color_value: Color, scale_mul: float = 1.0, duration_mul: float = 1.0) -> void:
	if feedback_burst_scene == null or _should_trim_feedback_fx():
		return
	if _mobile_lite_mode:
		scale_mul *= 0.82
		duration_mul *= 0.8
	var burst := feedback_burst_scene.instantiate()
	if burst == null:
		return
	burst.position = world_position
	if burst.has_method("setup"):
		burst.setup(color_value, Color(1.0, 1.0, 1.0, 0.9), scale_mul, duration_mul)
	feedback.add_child(burst)

func _spawn_slash(world_position: Vector2, rotation_value: float, color_value: Color, scale_mul: float = 1.0, duration_mul: float = 1.0) -> void:
	if slash_fx_scene == null or _should_trim_feedback_fx():
		return
	if _mobile_lite_mode:
		scale_mul *= 0.84
		duration_mul *= 0.82
	var slash := slash_fx_scene.instantiate()
	if slash == null:
		return
	if slash is Node2D:
		(slash as Node2D).position = world_position
		(slash as Node2D).rotation = rotation_value
	if slash.has_method("setup"):
		slash.setup(color_value, Color(1.0, 0.98, 0.92, 0.96), scale_mul, duration_mul)
	feedback.add_child(slash)

func _spawn_reward_pulse(world_position: Vector2, color_value: Color, scale_mul: float = 1.0, duration_mul: float = 1.0, ray_count: int = 8) -> void:
	if reward_pulse_scene == null or _should_trim_feedback_fx():
		return
	if _mobile_lite_mode:
		scale_mul *= 0.86
		duration_mul *= 0.82
		ray_count = mini(ray_count, 5)
	var pulse := reward_pulse_scene.instantiate()
	if pulse == null:
		return
	if pulse is Node2D:
		(pulse as Node2D).position = world_position
	pulse.set("ray_count", ray_count)
	if pulse.has_method("setup"):
		pulse.setup(color_value, Color(1.0, 0.98, 0.92, 0.96), scale_mul, duration_mul)
	feedback.add_child(pulse)

func _spawn_milestone_flare(world_position: Vector2, color_value: Color, scale_mul: float = 1.0, duration_mul: float = 1.0, fan_total: int = 5) -> void:
	if milestone_flare_scene == null or _mobile_lite_mode or _should_trim_feedback_fx():
		return
	var flare := milestone_flare_scene.instantiate()
	if flare == null:
		return
	if flare is Node2D:
		(flare as Node2D).position = world_position
	if flare.has_method("setup"):
		flare.setup(color_value, Color(1.0, 0.98, 0.92, 0.96), scale_mul, duration_mul, fan_total)
	feedback.add_child(flare)

func _show_combo_meter() -> void:
	if combo_meter == null or _mobile_lite_mode:
		return
	if _kill_streak < 4 and not (_kill_streak_timer > 0.0 and _best_kill_streak >= 4):
		return
	var rank_text := _get_combo_rank_text(_kill_streak)
	combo_meter.text = "连斩 %d · %s" % [maxi(4, _kill_streak), rank_text]
	combo_meter.visible = true
	combo_meter.modulate = Color(1, 1, 1, 1)
	combo_meter.scale = Vector2(0.86, 0.86)
	combo_meter.position = _combo_meter_base_position + Vector2(0.0, 8.0)
	if _combo_meter_tween != null:
		_combo_meter_tween.kill()
	_combo_meter_tween = create_tween()
	_combo_meter_tween.set_parallel(true)
	_combo_meter_tween.tween_property(combo_meter, "position", _combo_meter_base_position, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_combo_meter_tween.tween_property(combo_meter, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_combo_meter_tween.chain().tween_interval(0.48)
	_combo_meter_tween.set_parallel(true)
	_combo_meter_tween.tween_property(combo_meter, "modulate", Color(1, 1, 1, 0), 0.20)
	_combo_meter_tween.tween_property(combo_meter, "position", _combo_meter_base_position + Vector2(0.0, -6.0), 0.20)
	_combo_meter_tween.finished.connect(func():
		_combo_meter_tween = null
		if combo_meter != null:
			combo_meter.visible = false
			combo_meter.position = _combo_meter_base_position
			combo_meter.scale = Vector2.ONE
	)

func _animate_settlement_stamp() -> void:
	if settlement_stamp == null:
		return
	if _settlement_stamp_tween != null:
		_settlement_stamp_tween.kill()
	settlement_stamp.modulate = Color(1, 1, 1, 0)
	settlement_stamp.scale = Vector2(0.88, 0.88)
	settlement_stamp.rotation = deg_to_rad(-3.0)
	_settlement_stamp_tween = create_tween()
	_settlement_stamp_tween.set_parallel(true)
	_settlement_stamp_tween.tween_property(settlement_stamp, "modulate", Color(1, 1, 1, 1), 0.16)
	_settlement_stamp_tween.tween_property(settlement_stamp, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_settlement_stamp_tween.tween_property(settlement_stamp, "rotation", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_settlement_stamp_tween.finished.connect(func():
		_settlement_stamp_tween = null
	)

func _flash_screen(color_value: Color, alpha: float = 0.12, duration: float = 0.16) -> void:
	if screen_flash == null:
		return
	if _mobile_lite_mode:
		alpha *= 0.45
		duration *= 0.75
	var flash_color := color_value
	flash_color.a = clampf(alpha, 0.0, 0.45)
	screen_flash.color = flash_color
	if _screen_flash_tween != null:
		_screen_flash_tween.kill()
	screen_flash.visible = true
	_screen_flash_tween = create_tween()
	_screen_flash_tween.tween_property(screen_flash, "color", Color(flash_color.r, flash_color.g, flash_color.b, 0.0), maxf(0.08, duration))
	_screen_flash_tween.finished.connect(func():
		screen_flash.visible = false
	)

func _hud_card_glow(glow_color: Color, alpha: float = 0.55, duration: float = 0.45) -> void:
	if hud_card_bg == null:
		return
	var tween := create_tween()
	hud_card_bg.modulate = Color(glow_color.r, glow_color.g, glow_color.b, alpha)
	hud_card_border.modulate = Color(glow_color.r, glow_color.g, glow_color.b, alpha * 1.2)
	tween.tween_interval(maxf(0.08, duration * 0.45))
	tween.parallel().tween_property(hud_card_bg, "modulate", Color(1, 1, 1, 1), maxf(0.1, duration * 0.55))
	tween.parallel().tween_property(hud_card_border, "modulate", Color(1, 1, 1, 1), maxf(0.1, duration * 0.55))

func _show_banner(text_value: String, subtitle_text: String = "妖潮播报") -> void:
	if banner_label == null:
		return
	var portrait_compact := _is_portrait_layout() and not (pause_requested or game_over or demo_clear)
	banner_label.text = text_value
	banner_label.modulate = Color(1, 1, 1, 1)
	banner_label.visible = true
	if banner_sub_label != null:
		banner_sub_label.text = subtitle_text
		banner_sub_label.modulate = Color(1, 1, 1, 1)
		banner_sub_label.visible = not portrait_compact
	if banner_backing != null:
		banner_backing.modulate = Color(1, 1, 1, 1)
		banner_backing.visible = true
	if banner_accent != null:
		banner_accent.modulate = Color(1, 1, 1, 1)
		banner_accent.visible = true
	var tween := create_tween()
	tween.tween_interval(0.86 if portrait_compact else 1.15)
	tween.parallel().tween_property(banner_label, "modulate", Color(1, 1, 1, 0), 0.36 if portrait_compact else 0.45)
	if banner_sub_label != null:
		tween.parallel().tween_property(banner_sub_label, "modulate", Color(1, 1, 1, 0), 0.24 if portrait_compact else 0.45)
	if banner_backing != null:
		tween.parallel().tween_property(banner_backing, "modulate", Color(1, 1, 1, 0), 0.30 if portrait_compact else 0.45)
	if banner_accent != null:
		tween.parallel().tween_property(banner_accent, "modulate", Color(1, 1, 1, 0), 0.30 if portrait_compact else 0.45)
	tween.finished.connect(func():
		banner_label.visible = false
		if banner_sub_label != null:
			banner_sub_label.visible = false
		if banner_backing != null:
			banner_backing.visible = false
		if banner_accent != null:
			banner_accent.visible = false
	)

func _show_center_notice(text_value: String, accent_color: Color = HUD_GOLD) -> void:
	if center_notice == null or center_notice_label == null:
		return
	var portrait_compact := _is_portrait_layout() and not (pause_requested or game_over or demo_clear)
	var hold_time := 0.42 if portrait_compact else 0.72
	var fade_time := 0.18 if portrait_compact else 0.24
	center_notice.visible = true
	center_notice.position = _center_notice_base_position + Vector2(0.0, 8.0)
	center_notice.scale = Vector2(0.96, 0.96)
	center_notice.rotation = deg_to_rad(-1.2)
	center_notice_label.text = text_value
	center_notice_label.modulate = Color(1, 1, 1, 1)
	center_notice_label.scale = Vector2(0.92, 0.92)
	center_notice_backing.color = Color(0.12, 0.08, 0.06, 0.84)
	center_notice_backing.modulate = Color(1, 1, 1, 0.0)
	center_notice_accent.color = accent_color
	center_notice_accent.modulate = Color(1, 1, 1, 0.0)
	if _center_notice_tween != null:
		_center_notice_tween.kill()
	_center_notice_tween = create_tween()
	_center_notice_tween.set_parallel(true)
	_center_notice_tween.tween_property(center_notice_backing, "modulate", Color(1, 1, 1, 1), 0.10 if portrait_compact else 0.12)
	_center_notice_tween.tween_property(center_notice_accent, "modulate", Color(1, 1, 1, 1), 0.10 if portrait_compact else 0.12)
	_center_notice_tween.tween_property(center_notice, "position", _center_notice_base_position, 0.14 if portrait_compact else 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_center_notice_tween.tween_property(center_notice, "rotation", 0.0, 0.14 if portrait_compact else 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_center_notice_tween.tween_property(center_notice, "scale", Vector2.ONE, 0.16 if portrait_compact else 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_center_notice_tween.tween_property(center_notice_label, "scale", Vector2.ONE, 0.14 if portrait_compact else 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_center_notice_tween.chain().tween_interval(hold_time)
	_center_notice_tween.set_parallel(true)
	_center_notice_tween.tween_property(center_notice_backing, "modulate", Color(1, 1, 1, 0), fade_time)
	_center_notice_tween.tween_property(center_notice_accent, "modulate", Color(1, 1, 1, 0), fade_time)
	_center_notice_tween.tween_property(center_notice_label, "modulate", Color(1, 1, 1, 0), fade_time)
	_center_notice_tween.tween_property(center_notice, "position", _center_notice_base_position + Vector2(0.0, -6.0), fade_time)
	_center_notice_tween.finished.connect(func():
		center_notice.visible = false
		center_notice.position = _center_notice_base_position
		center_notice.scale = Vector2.ONE
		center_notice.rotation = 0.0
	)

func _set_focus_overlay_visible(should_show: bool) -> void:
	if focus_overlay == null:
		return
	if _focus_overlay_visible_state == should_show:
		focus_overlay.visible = should_show
		return
	_focus_overlay_visible_state = should_show
	if should_show:
		focus_overlay.visible = true
		if focus_tint != null:
			focus_tint.modulate = Color(1, 1, 1, 0)
		if focus_panel != null:
			focus_panel.modulate = Color(1, 1, 1, 0)
			focus_panel.scale = Vector2(0.90, 0.90)
			focus_panel.position = _focus_panel_base_position + Vector2(0.0, 14.0)
			focus_panel.rotation = deg_to_rad(-1.6)
		var tween_in := create_tween()
		tween_in.set_parallel(true)
		if focus_tint != null:
			tween_in.tween_property(focus_tint, "modulate", Color(1, 1, 1, 1), 0.18)
		if focus_panel != null:
			tween_in.tween_property(focus_panel, "modulate", Color(1, 1, 1, 1), 0.18)
			tween_in.tween_property(focus_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween_in.tween_property(focus_panel, "position", _focus_panel_base_position, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween_in.tween_property(focus_panel, "rotation", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		var tween_out := create_tween()
		tween_out.set_parallel(true)
		if focus_tint != null:
			tween_out.tween_property(focus_tint, "modulate", Color(1, 1, 1, 0), 0.14)
		if focus_panel != null:
			tween_out.tween_property(focus_panel, "modulate", Color(1, 1, 1, 0), 0.14)
			tween_out.tween_property(focus_panel, "scale", Vector2(0.96, 0.96), 0.14)
			tween_out.tween_property(focus_panel, "position", _focus_panel_base_position + Vector2(0.0, 10.0), 0.14)
		tween_out.finished.connect(func():
			if not _focus_overlay_visible_state:
				focus_overlay.visible = false
				if focus_panel != null:
					focus_panel.position = _focus_panel_base_position
					focus_panel.rotation = 0.0
		)

func _update_ui_motion(delta: float) -> void:
	_ui_motion_time += delta
	if center_notice != null and center_notice.visible and _center_notice_tween != null:
		center_notice.scale = center_notice.scale.lerp(Vector2.ONE * (1.0 + sin(_ui_motion_time * 10.0) * 0.015), delta * 4.5)
	if focus_panel != null and _focus_overlay_visible_state and focus_panel.visible:
		var bob := sin(_ui_motion_time * 3.2) * 4.0
		focus_panel.position = focus_panel.position.lerp(_focus_panel_base_position + Vector2(0.0, bob), delta * 3.2)
		focus_panel.rotation = lerpf(focus_panel.rotation, deg_to_rad(sin(_ui_motion_time * 2.1) * 0.7), delta * 2.8)
		focus_panel.scale = focus_panel.scale.lerp(Vector2.ONE * (1.0 + sin(_ui_motion_time * 4.0) * 0.01), delta * 3.4)
	elif focus_panel != null and not _focus_overlay_visible_state:
		focus_panel.position = focus_panel.position.lerp(_focus_panel_base_position, delta * 6.0)
		focus_panel.rotation = lerpf(focus_panel.rotation, 0.0, delta * 6.0)

func _update_tip_text() -> void:
	if game_over or demo_clear:
		return
	var tip := "行者起手：WASD 挪身 · Space 筋斗闪 · 如意法术会自动寻妖。"
	if OS.has_feature("web"):
		tip = "网页端先轻点画面，再用 WASD / 摇杆走位；Space / 右下按钮可使筋斗闪。"
		if _mobile_lite_mode:
			tip += " 当前默认走掌中轻量验收版，优先保可开局与可试玩。"
	if pause_requested:
		tip = "戏台暂歇中：继续试炼会原地接回，不会丢当前节奏。"
	elif player.health <= 2:
		tip = "命火将熄：先闪身穿妖群，收修为球冲等级，别跟贴脸怪硬换。"
	elif wave_index >= 5:
		tip = "火云压阵：先拆边路、躲重装，再回头收尾，筋斗闪尽量留给穿围。"
	elif not _wave_objective_completed:
		tip = "本劫军令：%s，%s" % [OBJECTIVE_LABELS.get(_wave_objective_type, "稳住阵脚"), OBJECTIVE_DETAILS.get(_wave_objective_type, "先稳住这一劫的节奏。")]
	elif wave_index >= 3:
		tip = "妖潮转急：看见头目先拉开半步，再借自动法术慢慢磨。军功会持续抬高输出。"
	hud_tip.text = tip
	if mobile_hint != null:
		if mobile_hint_title != null:
			mobile_hint_title.text = "掌中戏台 · 身法提示"
		var mobile_text := "左下摇杆走位\n右下筋斗闪穿怪\n底部戏台键可暂停/重开"
		if _mobile_lite_mode:
			mobile_text += "\n当前已启用轻量验收降级"
		if pause_requested:
			if mobile_hint_title != null:
				mobile_hint_title.text = "掌中戏台 · 暂歇战报"
			mobile_text = "戏台暂歇中\n点继续试炼回场\n战报会原样保留"
		elif player.health <= 2:
			if mobile_hint_title != null:
				mobile_hint_title.text = "掌中戏台 · 告急提醒"
			mobile_text = "命火告急先走位\n筋斗闪穿包围\n吃修为球补节奏"
		elif wave_index >= 5:
			if mobile_hint_title != null:
				mobile_hint_title.text = "掌中戏台 · 压阵提醒"
			mobile_text = "火云压阵别贪站撸\n留筋斗闪过重装\n清边路再回头收尾"
		elif not _wave_objective_completed:
			if mobile_hint_title != null:
				mobile_hint_title.text = "掌中戏台 · 本劫军令"
			mobile_text = "本劫军令：%s\n%s" % [OBJECTIVE_LABELS.get(_wave_objective_type, "稳住阵脚"), _wave_objective_reward_text if _wave_objective_reward_text != "" else OBJECTIVE_DETAILS.get(_wave_objective_type, "先稳住这一劫")]
		mobile_hint.text = mobile_text

func _update_temporary_bonuses(delta: float) -> void:
	var had_bonus := _bonus_attack_speed_time > 0.0 or _bonus_damage_time > 0.0 or _bonus_multishot_time > 0.0 or _bonus_pierce_time > 0.0
	_respite_time_remaining = maxf(0.0, _respite_time_remaining - delta)
	if _respite_time_remaining == 0.0:
		_respite_spawn_multiplier = 1.0
		_respite_fast_penalty = 0.0
		_respite_tank_penalty = 0.0
	_bonus_attack_speed_time = maxf(0.0, _bonus_attack_speed_time - delta)
	_bonus_damage_time = maxf(0.0, _bonus_damage_time - delta)
	_bonus_multishot_time = maxf(0.0, _bonus_multishot_time - delta)
	_bonus_pierce_time = maxf(0.0, _bonus_pierce_time - delta)
	var has_bonus := _bonus_attack_speed_time > 0.0 or _bonus_damage_time > 0.0 or _bonus_multishot_time > 0.0 or _bonus_pierce_time > 0.0
	if had_bonus != has_bonus:
		_on_player_xp_changed(player.xp, player.xp_to_next, player.level)

func _trigger_respite(duration: float, spawn_multiplier: float, fast_penalty: float, tank_penalty: float) -> void:
	_respite_time_remaining = maxf(_respite_time_remaining, duration)
	_respite_spawn_multiplier = minf(_respite_spawn_multiplier, spawn_multiplier)
	_respite_fast_penalty = maxf(_respite_fast_penalty, fast_penalty)
	_respite_tank_penalty = maxf(_respite_tank_penalty, tank_penalty)

func _setup_wave_objective() -> void:
	_wave_objective_completed = false
	_wave_objective_reward_text = ""
	_wave_started_at = elapsed_time
	_last_objective_kill_count = kill_count
	_last_objective_elite_kill_count = _elite_kill_count
	if wave_index <= 2:
		_wave_objective_type = "survive"
		_wave_objective_target = 10 + wave_index * 3
	elif wave_index % 2 == 0:
		_wave_objective_type = "kills"
		_wave_objective_target = 7 + wave_index * 2
	else:
		_wave_objective_type = "elite"
		_wave_objective_target = 1
	_wave_objective_progress = 0

func _update_wave_objective_progress() -> void:
	if _wave_objective_completed:
		return
	if _wave_objective_type == "survive":
		var wave_start_time := float(maxi(0, wave_index - 1)) * wave_length_seconds
		_wave_objective_progress = mini(_wave_objective_target, int(elapsed_time - wave_start_time))
		if _wave_objective_progress >= _wave_objective_target:
			_complete_wave_objective()
	_update_tip_text()

func _update_wave_objective_from_kill(enemy: Node) -> void:
	if _wave_objective_completed:
		return
	if _wave_objective_type == "kills":
		_wave_objective_progress = kill_count - _last_objective_kill_count
		if _wave_objective_progress >= _wave_objective_target:
			_complete_wave_objective()
	elif _wave_objective_type == "elite" and enemy != null and bool(enemy.get("is_elite")):
		_wave_objective_progress = _elite_kill_count - _last_objective_elite_kill_count
		if _wave_objective_progress >= _wave_objective_target:
			_complete_wave_objective()

func _complete_wave_objective() -> void:
	if _wave_objective_completed:
		return
	_wave_objective_completed = true
	_wave_objective_progress = _wave_objective_target
	match _wave_objective_type:
		"survive":
			player.heal(1)
			_bonus_attack_speed_time = maxf(_bonus_attack_speed_time, 7.0)
			_wave_objective_reward_text = "回命 + 急速 7 秒"
		"kills":
			_bonus_damage_time = maxf(_bonus_damage_time, 9.0)
			_bonus_multishot_time = maxf(_bonus_multishot_time, 9.0)
			_wave_objective_reward_text = "额外伤害 + 连发 9 秒"
		"elite":
			player.heal(1)
			_bonus_pierce_time = maxf(_bonus_pierce_time, 10.0)
			_bonus_attack_speed_time = maxf(_bonus_attack_speed_time, 6.0)
			_wave_objective_reward_text = "回命 + 穿透 + 急速"
	_gain_merit_stack()
	var objective_clear_time := elapsed_time - _wave_started_at
	_trigger_respite(1.35, 0.48, 0.22, 0.24)
	if player != null and player.has_method("collect_xp"):
		player.collect_xp(2 + mini(4, wave_index - 1))
	if objective_clear_time <= wave_length_seconds * 0.5 and player != null and player.has_method("collect_xp"):
		player.collect_xp(2)
		_bonus_attack_speed_time = maxf(_bonus_attack_speed_time, 8.0)
		_wave_objective_reward_text += " + 速决赏"
		_show_center_notice("速决赏功 · 额外修为 + 急速续杯", HUD_GOLD)
		_spawn_popup(player.global_position + Vector2(0, -90), "速决赏", HUD_GOLD)
		_spawn_milestone_flare(player.global_position + Vector2(0, -20), HUD_GOLD, 1.0, 0.90, 5)
	_show_center_notice("军令达成 · %s" % _wave_objective_reward_text, HUD_MINT)
	_spawn_popup(player.global_position + Vector2(0, -46), "军令达成", HUD_MINT)
	_spawn_popup(player.global_position + Vector2(0, -68), "+1 军功", HUD_GOLD)
	_spawn_burst(player.global_position, HUD_MINT, 1.28, 1.12)
	_spawn_slash(player.global_position, -PI * 0.5, HUD_MINT, 1.26, 1.0)
	_spawn_reward_pulse(player.global_position, HUD_GOLD, 1.18, 1.0, 9)
	_spawn_milestone_flare(player.global_position + Vector2(0, -18), HUD_MINT, 1.18, 0.98, 6)
	_flash_screen(HUD_MINT, 0.10, 0.14)
	_on_player_xp_changed(player.xp, player.xp_to_next, player.level)

func _gain_merit_stack() -> void:
	_merit_stacks += 1
	if _merit_stacks % 3 == 0 and player != null:
		player.max_health += 1
		player.heal(1)
		player.stats_changed.emit(player.health, player.max_health, player.level)
		_show_center_notice("军功满三层 · 命火上限 +1", HUD_GOLD)
		_spawn_popup(player.global_position + Vector2(0, -90), "命火上限 +1", HUD_GOLD)
		_spawn_burst(player.global_position, HUD_GOLD, 1.25, 1.08)
		_spawn_slash(player.global_position, -PI * 0.5, HUD_GOLD, 1.22, 1.12)
		_spawn_reward_pulse(player.global_position, HUD_GOLD, 1.15, 0.98, 8)
		_spawn_milestone_flare(player.global_position + Vector2(0, -18), HUD_GOLD, 1.18, 0.88, 6)
		_flash_screen(HUD_GOLD, 0.11, 0.16)
		_add_camera_shake(7.0, 0.18)

func _queue_wave_spawn_patterns() -> void:
	_queued_spawn_entries.clear()
	if wave_index < 3:
		return
	var flank_distance := minf(spawn_radius_max, maxf(spawn_radius_min + 30.0, 470.0))
	var left_flank := player.global_position + Vector2(-flank_distance, randf_range(-120.0, 120.0))
	var right_flank := player.global_position + Vector2(flank_distance, randf_range(-120.0, 120.0))
	var forward_center := player.global_position + Vector2.RIGHT.rotated(randf_range(-0.32, 0.32) + PI) * minf(spawn_radius_max, 500.0)
	match _wave_objective_type:
		"survive":
			_queue_spawn_entry(left_flank, SPAWN_TYPE_BASIC)
			if wave_index >= 4:
				_queue_spawn_entry(forward_center, SPAWN_TYPE_BASIC)
		"kills":
			_queue_spawn_entry(left_flank, SPAWN_TYPE_FAST if wave_index >= 4 else SPAWN_TYPE_BASIC)
			_queue_spawn_entry(right_flank, SPAWN_TYPE_BASIC)
			if wave_index >= 4:
				_queue_spawn_entry(forward_center + Vector2(-60.0, 22.0), SPAWN_TYPE_BASIC)
				_queue_spawn_entry(forward_center + Vector2(60.0, -22.0), SPAWN_TYPE_BASIC)
		"elite":
			_queue_spawn_entry(left_flank, SPAWN_TYPE_BASIC)
			_queue_spawn_entry(right_flank, SPAWN_TYPE_FAST if wave_index >= 5 else SPAWN_TYPE_BASIC)
			_queue_spawn_entry(forward_center, SPAWN_TYPE_TANK if wave_index >= 5 else SPAWN_TYPE_BASIC)
			if wave_index >= 4:
				_queue_spawn_entry(forward_center + Vector2(-54.0, 26.0), SPAWN_TYPE_BASIC)
				_queue_spawn_entry(forward_center + Vector2(54.0, -26.0), SPAWN_TYPE_FAST if wave_index >= 5 else SPAWN_TYPE_BASIC)

func _queue_spawn_entry(spawn_position: Vector2, preferred_type: String = SPAWN_TYPE_BASIC, force_elite: bool = false) -> void:
	_queued_spawn_entries.append({
		"position": spawn_position,
		"preferred_type": preferred_type,
		"force_elite": force_elite
	})

func _get_spawn_pressure_tier(close_pressure_override: float = -1.0, alive_fast_override: int = -1, alive_tank_override: int = -1) -> int:
	var close_pressure := close_pressure_override
	var alive_fast := alive_fast_override
	var alive_tanks := alive_tank_override
	if close_pressure < 0.0 or alive_fast < 0 or alive_tanks < 0:
		close_pressure = 0.0
		alive_fast = 0
		alive_tanks = 0
		for child in enemies.get_children():
			if child == null or not is_instance_valid(child):
				continue
			var scene_file := String(child.scene_file_path)
			if scene_file.ends_with("enemy_runner.tscn"):
				alive_fast += 1
			elif scene_file.ends_with("enemy_tank.tscn"):
				alive_tanks += 1
			if child is Node2D and player.global_position.distance_to((child as Node2D).global_position) < 180.0:
				close_pressure += 1.0
	var pressure_score := close_pressure + float(alive_fast) * 0.45 + float(alive_tanks) * 0.9
	if player.health <= 2:
		pressure_score += 1.8
	if _respite_time_remaining > 0.0:
		pressure_score -= 0.8
	if pressure_score >= 8.0:
		return 3
	if pressure_score >= 5.0:
		return 2
	if pressure_score >= 3.0:
		return 1
	return 0

func _get_spawn_position() -> Vector2:
	var player_position := player.global_position
	var viewport_size := get_viewport_rect().size
	var visible_rect := Rect2(player_position - viewport_size * 0.5, viewport_size)
	var spawn_min := minf(spawn_radius_min, spawn_radius_max)
	var spawn_max := maxf(spawn_radius_min, spawn_radius_max)

	for _attempt in range(8):
		var angle := randf_range(0.0, TAU)
		var distance := randf_range(spawn_min, spawn_max)
		var candidate := player_position + Vector2.RIGHT.rotated(angle) * distance
		if not visible_rect.has_point(candidate):
			return candidate

	var fallback_angle := randf_range(0.0, TAU)
	return player_position + Vector2.RIGHT.rotated(fallback_angle) * spawn_max

func _reset_touch_input_state() -> void:
	if joystick != null and joystick.has_method("cancel_input"):
		joystick.cancel_input()
	if player != null and player.has_method("set_external_input_vector"):
		player.set_external_input_vector(Vector2.ZERO)

func _on_joystick_vector_changed(direction: Vector2) -> void:
	if player != null and player.has_method("set_external_input_vector"):
		player.set_external_input_vector(direction)
	if direction.length() > 0.0:
		_browser_hint_acknowledged = true

func _add_camera_shake(strength: float, duration: float) -> void:
	if _mobile_lite_mode:
		strength *= 0.35
		duration *= 0.7
	_camera_shake_strength = maxf(_camera_shake_strength, strength)
	_camera_shake_time = maxf(_camera_shake_time, duration)

func _update_combo_meter(delta: float) -> void:
	if combo_meter == null:
		return
	if combo_meter.visible and _combo_meter_tween == null:
		combo_meter.modulate.a = maxf(0.0, combo_meter.modulate.a - delta * 1.8)
		if combo_meter.modulate.a <= 0.01:
			combo_meter.visible = false

func _update_low_health_vignette(delta: float) -> void:
	if low_health_vignette == null:
		return
	_low_health_pulse_time += delta
	var target_alpha := 0.0
	if game_over:
		target_alpha = 0.22
	elif not pause_requested and not demo_clear and player != null and player.health <= 2:
		target_alpha = 0.06 + (sin(_low_health_pulse_time * 5.4) * 0.5 + 0.5) * 0.10
	low_health_vignette.color = Color(HUD_DANGER.r, HUD_DANGER.g * 0.58, HUD_DANGER.b * 0.52, lerpf(low_health_vignette.color.a, target_alpha, delta * 6.0))

func _update_camera_feedback(delta: float) -> void:
	if player_camera == null:
		return
	if _camera_shake_time > 0.0:
		_camera_shake_time = maxf(0.0, _camera_shake_time - delta)
		_camera_shake_strength = lerpf(_camera_shake_strength, 0.0, delta * 10.0)
		player_camera.offset = _camera_base_offset + Vector2(randf_range(-_camera_shake_strength, _camera_shake_strength), randf_range(-_camera_shake_strength, _camera_shake_strength))
	else:
		_camera_shake_strength = 0.0
		player_camera.offset = player_camera.offset.lerp(_camera_base_offset, delta * 12.0)

func _toggle_pause() -> void:
	if game_over or demo_clear:
		return
	_set_pause_state(not pause_requested)

func _resume_run() -> void:
	_show_center_notice("继续试炼 · 戏台再开", HUD_SKY)
	_spawn_milestone_flare(player.global_position + Vector2(0, -12), HUD_SKY, 0.86, 0.72, 4)
	_flash_screen(HUD_SKY, 0.08, 0.10)
	_set_pause_state(false)

func _set_pause_state(should_pause: bool) -> void:
	pause_requested = should_pause
	if should_pause:
		_reset_touch_input_state()
	get_tree().paused = should_pause
	if pause_button != null:
		pause_button.text = "继续试炼" if should_pause else "暂停"
	if should_pause:
		_show_center_notice("戏台暂歇 · 可看战报", HUD_SKY)
		_spawn_milestone_flare(player.global_position + Vector2(0, -14), HUD_SKY, 0.94, 0.78, 4)
		_flash_screen(HUD_SKY, 0.06, 0.12)
	_update_focus_overlay()

func _update_pause_button() -> void:
	if pause_button == null:
		return
	pause_button.text = "继续试炼" if pause_requested else "暂停"
	pause_button.disabled = game_over or demo_clear
	if action_tray_label != null:
		if game_over:
			action_tray_label.text = "戏台战报 · 右侧主按键可立刻再闯"
		elif demo_clear:
			action_tray_label.text = "戏台喝彩 · 可继续冲更高斩妖"
		elif pause_requested:
			action_tray_label.text = "戏台暂歇 · 左续战 右重开"
		elif get_viewport_rect().size.x < 1320.0 or get_viewport_rect().size.y < 760.0:
			action_tray_label.text = "戏台操作 · 底部续战与重开"
		else:
			action_tray_label.text = "戏台操作 · 暂停 / 续战 / 再闯"

func _get_settlement_title(cleared: bool) -> String:
	if cleared:
		if kill_count >= 180:
			return "大圣巡山"
		if kill_count >= 140:
			return "金箍镇场"
		return "山门守成"
	if kill_count >= 120:
		return "披挂再战"
	if wave_index >= 5:
		return "火云鏖战"
	if wave_index >= 3:
		return "流沙试锋"
	return "花果山试手"

func _get_combo_rank_text(streak_value: int) -> String:
	if streak_value >= 20:
		return "破阵"
	if streak_value >= 12:
		return "压场"
	if streak_value >= 8:
		return "起煞"
	return "起势"

func _get_settlement_stamp_text() -> String:
	if demo_clear and kill_count >= 180:
		return "战绩总评 · 大圣巡山"
	if demo_clear:
		return "战绩总评 · 戏台喝彩"
	if game_over and wave_index >= 5:
		return "战绩总评 · 火云鏖战"
	if pause_requested:
		return "战绩总评 · 暂歇整装"
	return "战绩总评 · 山门守成"

func _get_medal_line() -> String:
	var medal := "铜符"
	var detail := "稳住节奏"
	if demo_clear and kill_count >= 180:
		medal = "金箍金章"
		detail = "大圣巡山"
	elif demo_clear and kill_count >= 140:
		medal = "花果银章"
		detail = "山门守成"
	elif wave_index >= 5 or _best_kill_streak >= 12:
		medal = "流沙铜章"
		detail = "妖潮试锋"
	if pause_requested and not game_over and not demo_clear:
		detail = "暂歇整装"
	if game_over:
		detail = "再闯可破"
	return "战绩牌：%s · %s" % [medal, detail]

func _build_run_summary(title_text: String) -> String:
	var total_seconds := int(elapsed_time)
	var kills_per_min := 0.0
	if total_seconds > 0:
		kills_per_min = floor(float(kill_count) / float(total_seconds) * 60.0)
	var objectives_completed := 0
	if wave_index >= 1:
		objectives_completed = wave_index - 1
	return "西游评语：%s\n时辰：%02d:%02d / %02d:%02d\n斩妖：%d    头目：%d\n军功：%d层    修为：行者%d重\n命火：%d/%d    极速：%.1f斩/分\n连斩：最长 %d    军令：完成 %d劫" % [
		title_text,
		int(total_seconds / 60),
		total_seconds % 60,
		int(demo_goal_seconds) / 60,
		int(demo_goal_seconds) % 60,
		kill_count,
		_elite_kill_count,
		_merit_stacks,
		player.level,
		player.health,
		player.max_health,
		kills_per_min,
		_best_kill_streak,
		objectives_completed
	]

func _reload_scene() -> void:
	_reset_touch_input_state()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _get_wave_title(index: int) -> String:
	var safe_index := maxi(1, index)
	if safe_index <= WAVE_TITLES.size():
		return WAVE_TITLES[safe_index - 1]
	return "天宫试锋"

func _get_stage_title(index: int) -> String:
	var safe_index := maxi(1, index)
	if safe_index <= DIFFICULTY_TITLES.size():
		return DIFFICULTY_TITLES[safe_index - 1]
	return DIFFICULTY_TITLES[DIFFICULTY_TITLES.size() - 1]

func _apply_mobile_font_scaling() -> void:
	# Scale HUD fonts up for small/mobile viewports so text stays readable.
	# Base desktop target is ~1280px wide; scale down for anything smaller.
	var viewport_size := get_viewport_rect().size
	var scale := clampf(viewport_size.x / 1280.0, 0.60, 1.0)
	var is_portrait := viewport_size.y > viewport_size.x
	# On portrait mobile, scale up much more aggressively so key combat and settlement text crosses the readability line.
	if is_portrait:
		scale = clampf(scale * 1.28, 0.78, 1.0)

	var base_font_size := int(24.0 * scale)
	var small_font_size := int(16.0 * scale)
	var medium_font_size := int(19.0 * scale)
	var large_font_size := int(30.0 * scale)
	var xl_font_size := int(32.0 * scale)
	var button_font_size := int(24.0 * scale)
	var portrait_emphasis := 3 if is_portrait else 0

	if hud_level != null:
		hud_level.add_theme_font_size_override("font_size", maxi(base_font_size + portrait_emphasis, 17))
	if hud_health != null:
		hud_health.add_theme_font_size_override("font_size", maxi(medium_font_size + portrait_emphasis, 16))
	if hud_enemies != null:
		hud_enemies.add_theme_font_size_override("font_size", maxi(small_font_size, 13))
	if hud_timer != null:
		hud_timer.add_theme_font_size_override("font_size", maxi(small_font_size, 13))
	if hud_kills != null:
		hud_kills.add_theme_font_size_override("font_size", maxi(small_font_size + (1 if is_portrait else 0), 13))
	if hud_wave != null:
		hud_wave.add_theme_font_size_override("font_size", maxi(medium_font_size + (1 if is_portrait else 0), 15))
	if hud_objective != null:
		hud_objective.add_theme_font_size_override("font_size", maxi(small_font_size + portrait_emphasis, 14))
	if hud_tip != null:
		hud_tip.add_theme_font_size_override("font_size", maxi(small_font_size, 14))
	if status_badge != null:
		status_badge.add_theme_font_size_override("font_size", maxi(small_font_size - 1 + (1 if is_portrait else 0), 11))
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", maxi(small_font_size + (1 if is_portrait else 0), 14))
	if banner_label != null:
		banner_label.add_theme_font_size_override("font_size", maxi(large_font_size, 20))
	if banner_sub_label != null:
		banner_sub_label.add_theme_font_size_override("font_size", maxi(small_font_size, 11))
	if combo_meter != null:
		combo_meter.add_theme_font_size_override("font_size", maxi(xl_font_size, 20))
	if center_notice_label != null:
		center_notice_label.add_theme_font_size_override("font_size", maxi(large_font_size, 20))
	if focus_badge != null:
		focus_badge.add_theme_font_size_override("font_size", maxi(small_font_size, 13))
	if focus_title != null:
		focus_title.add_theme_font_size_override("font_size", maxi(large_font_size, 20))
	if medal_label != null:
		medal_label.add_theme_font_size_override("font_size", maxi(medium_font_size, 14))
	if settlement_stamp != null:
		settlement_stamp.add_theme_font_size_override("font_size", maxi(medium_font_size, 14))
	if focus_detail != null:
		focus_detail.add_theme_font_size_override("font_size", maxi(medium_font_size, 14))
	if summary_label != null:
		summary_label.add_theme_font_size_override("font_size", maxi(small_font_size, 14))
	if action_tray_label != null:
		action_tray_label.add_theme_font_size_override("font_size", maxi(small_font_size, 14))
	if mobile_hint_title != null:
		mobile_hint_title.add_theme_font_size_override("font_size", maxi(small_font_size, 14))
	if mobile_hint != null:
		mobile_hint.add_theme_font_size_override("font_size", maxi(small_font_size, 14))
	if hud_xp_label != null:
		hud_xp_label.add_theme_font_size_override("font_size", maxi(medium_font_size, 13))
	if restart_button != null:
		restart_button.add_theme_font_size_override("font_size", maxi(button_font_size, 16))
	if continue_button != null:
		continue_button.add_theme_font_size_override("font_size", maxi(button_font_size - 2, 14))
	if pause_button != null:
		pause_button.add_theme_font_size_override("font_size", maxi(button_font_size - 2, 14))
	if dash_button != null:
		dash_button.add_theme_font_size_override("font_size", maxi(button_font_size - 2, 14))

func _apply_ui_font_overrides() -> void:
	UIFonts.apply_to_control_tree($HUD)
	UIFonts.apply_to_control_tree($MobileControls)

func _apply_ui_style() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = HUD_PANEL
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = HUD_GOLD
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.shadow_color = Color(0, 0, 0, 0.26)
	panel_style.shadow_size = 8

	var panel_soft := panel_style.duplicate() as StyleBoxFlat
	panel_soft.bg_color = HUD_PANEL_SOFT

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = HUD_ACCENT
	fill_style.corner_radius_top_left = 10
	fill_style.corner_radius_top_right = 10
	fill_style.corner_radius_bottom_right = 10
	fill_style.corner_radius_bottom_left = 10

	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color(0.12, 0.08, 0.06, 0.78)
	background_style.corner_radius_top_left = 10
	background_style.corner_radius_top_right = 10
	background_style.corner_radius_bottom_right = 10
	background_style.corner_radius_bottom_left = 10

	var primary_button := StyleBoxFlat.new()
	primary_button.bg_color = HUD_ACCENT
	primary_button.border_color = HUD_GOLD
	primary_button.border_width_left = 2
	primary_button.border_width_top = 2
	primary_button.border_width_right = 2
	primary_button.border_width_bottom = 2
	primary_button.corner_radius_top_left = 18
	primary_button.corner_radius_top_right = 18
	primary_button.corner_radius_bottom_right = 18
	primary_button.corner_radius_bottom_left = 18
	primary_button.shadow_color = Color(0, 0, 0, 0.22)
	primary_button.shadow_size = 6

	var primary_button_hover := primary_button.duplicate() as StyleBoxFlat
	primary_button_hover.bg_color = Color(0.90, 0.44, 0.31, 1.0)

	var primary_button_pressed := primary_button.duplicate() as StyleBoxFlat
	primary_button_pressed.bg_color = Color(0.64, 0.24, 0.18, 1.0)

	var primary_button_disabled := primary_button.duplicate() as StyleBoxFlat
	primary_button_disabled.bg_color = Color(0.38, 0.26, 0.21, 0.85)
	primary_button_disabled.border_color = Color(0.68, 0.58, 0.42, 0.7)

	var secondary_button := panel_soft.duplicate() as StyleBoxFlat
	secondary_button.border_color = Color(0.72, 0.63, 0.44, 0.95)
	secondary_button.border_width_left = 2
	secondary_button.border_width_top = 2
	secondary_button.border_width_right = 2
	secondary_button.border_width_bottom = 2

	var secondary_button_hover := secondary_button.duplicate() as StyleBoxFlat
	secondary_button_hover.bg_color = Color(0.28, 0.17, 0.13, 0.92)

	var secondary_button_pressed := secondary_button.duplicate() as StyleBoxFlat
	secondary_button_pressed.bg_color = Color(0.18, 0.11, 0.08, 0.95)

	var secondary_button_disabled := secondary_button.duplicate() as StyleBoxFlat
	secondary_button_disabled.bg_color = Color(0.20, 0.14, 0.11, 0.72)
	secondary_button_disabled.border_color = Color(0.56, 0.50, 0.39, 0.58)

	var label_color_map := {
		hud_level: HUD_GOLD,
		hud_health: HUD_PAPER,
		hud_enemies: HUD_PAPER,
		hud_timer: HUD_PAPER,
		hud_kills: HUD_PAPER,
		hud_wave: HUD_WARNING,
		hud_weapon: HUD_MINT,
		hud_objective: HUD_PAPER,
		hud_tip: HUD_SKY,
		status_badge: HUD_GOLD,
		status_label: HUD_PAPER,
		banner_label: HUD_GOLD,
		banner_sub_label: HUD_PAPER,
		center_notice_label: HUD_PAPER,
		focus_badge: HUD_WARNING,
		focus_title: HUD_GOLD,
		medal_label: HUD_WARNING,
		focus_detail: HUD_PAPER,
		summary_label: HUD_PAPER,
		action_tray_label: HUD_PAPER,
		mobile_hint_title: HUD_GOLD,
		mobile_hint: HUD_PAPER,
		combo_meter: HUD_WARNING,
		settlement_stamp: HUD_ROSE
	}

	for label in label_color_map.keys():
		if label == null:
			continue
		label.add_theme_color_override("font_color", label_color_map[label])
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)

	hud_level.add_theme_font_size_override("font_size", 22)
	hud_wave.add_theme_font_size_override("font_size", 20)
	hud_objective.add_theme_font_size_override("font_size", 17)
	hud_tip.add_theme_font_size_override("font_size", 16)
	if status_badge != null:
		status_badge.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_font_size_override("font_size", 16)
	banner_label.add_theme_font_size_override("font_size", 26)
	if banner_sub_label != null:
		banner_sub_label.add_theme_font_size_override("font_size", 14)
	if combo_meter != null:
		combo_meter.add_theme_font_size_override("font_size", 28)
	if center_notice_label != null:
		center_notice_label.add_theme_font_size_override("font_size", 24)
	focus_badge.add_theme_font_size_override("font_size", 15)
	focus_title.add_theme_font_size_override("font_size", 24)
	if medal_label != null:
		medal_label.add_theme_font_size_override("font_size", 18)
	if settlement_stamp != null:
		settlement_stamp.add_theme_font_size_override("font_size", 18)
	focus_detail.add_theme_font_size_override("font_size", 17)
	summary_label.add_theme_font_size_override("font_size", 16)
	if action_tray_label != null:
		action_tray_label.add_theme_font_size_override("font_size", 16)
	if mobile_hint_title != null:
		mobile_hint_title.add_theme_font_size_override("font_size", 16)
	mobile_hint.add_theme_font_size_override("font_size", 16)

	hud_xp_bar.add_theme_stylebox_override("fill", fill_style)
	hud_xp_bar.add_theme_stylebox_override("background", background_style)
	hud_xp_bar.add_theme_color_override("font_color", HUD_INK)
	if hud_meta_divider != null:
		hud_meta_divider.color = Color(HUD_GOLD.r, HUD_GOLD.g, HUD_GOLD.b, 0.42)
	if hud_objective_divider != null:
		hud_objective_divider.color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.38)
	if hud_xp_label != null:
		hud_xp_label.add_theme_color_override("font_color", HUD_GOLD)
		hud_xp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
		hud_xp_label.add_theme_constant_override("shadow_offset_x", 1)
		hud_xp_label.add_theme_constant_override("shadow_offset_y", 1)
		hud_xp_label.add_theme_font_size_override("font_size", 17)
	if action_tray_bg != null:
		action_tray_bg.color = Color(0.10, 0.07, 0.05, 0.72)
	if action_tray_accent != null:
		action_tray_accent.color = Color(HUD_GOLD.r, HUD_GOLD.g, HUD_GOLD.b, 0.92)
	if mobile_hint_bg != null:
		mobile_hint_bg.color = Color(0.10, 0.07, 0.05, 0.74)
	if mobile_hint_accent != null:
		mobile_hint_accent.color = Color(HUD_GOLD.r, HUD_GOLD.g, HUD_GOLD.b, 0.92)

	if focus_badge != null:
		focus_badge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if focus_title != null:
		focus_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if medal_label != null:
		medal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if settlement_stamp != null:
		settlement_stamp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if focus_detail != null:
		focus_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if action_tray_label != null:
		action_tray_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if mobile_hint_title != null:
		mobile_hint_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if mobile_hint != null:
		mobile_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if center_notice_label != null:
		center_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if focus_panel != null:
		focus_panel.add_theme_stylebox_override("panel", panel_style)
	if restart_button != null:
		_apply_button_style(restart_button, primary_button, primary_button_hover, primary_button_pressed, primary_button_disabled)
		restart_button.text = "再闯一局"
		restart_button.add_theme_font_size_override("font_size", 24)
	if continue_button != null:
		_apply_button_style(continue_button, secondary_button, secondary_button_hover, secondary_button_pressed, secondary_button_disabled)
		continue_button.text = "继续试炼"
		continue_button.add_theme_font_size_override("font_size", 22)
	if pause_button != null:
		_apply_button_style(pause_button, secondary_button, secondary_button_hover, secondary_button_pressed, secondary_button_disabled)
		pause_button.text = "暂停"
		pause_button.add_theme_color_override("font_color", HUD_GOLD)
		pause_button.add_theme_font_size_override("font_size", 20)
	if dash_button != null:
		_apply_button_style(dash_button, primary_button, primary_button_hover, primary_button_pressed, primary_button_disabled)
		dash_button.add_theme_color_override("font_color", HUD_PAPER)
		dash_button.add_theme_font_size_override("font_size", 22)

func _apply_button_style(button: Button, normal_style: StyleBoxFlat, hover_style: StyleBoxFlat, pressed_style: StyleBoxFlat, disabled_style: StyleBoxFlat) -> void:
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_color_override("font_color", HUD_PAPER)
	button.add_theme_color_override("font_hover_color", HUD_PAPER)
	button.add_theme_color_override("font_pressed_color", HUD_PAPER)
	button.add_theme_color_override("font_disabled_color", Color(0.85, 0.80, 0.70, 0.8))
	button.add_theme_font_size_override("font_size", 24)
