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

@onready var player: CharacterBody2D = $Player
@onready var player_camera: Camera2D = $Player/Camera2D
@onready var enemies: Node2D = $Enemies
@onready var projectiles: Node2D = $Projectiles
@onready var pickups: Node2D = $Pickups
@onready var feedback: Node2D = $Feedback
@onready var spawn_timer: Timer = $SpawnTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var hud_level: Label = $HUD/MarginContainer/VBoxContainer/LevelLabel
@onready var hud_health: Label = $HUD/MarginContainer/VBoxContainer/HealthLabel
@onready var hud_enemies: Label = $HUD/MarginContainer/VBoxContainer/EnemyLabel
@onready var hud_timer: Label = $HUD/MarginContainer/VBoxContainer/TimerLabel
@onready var hud_kills: Label = $HUD/MarginContainer/VBoxContainer/KillLabel
@onready var hud_weapon: Label = $HUD/MarginContainer/VBoxContainer/WeaponLabel
@onready var hud_wave: Label = $HUD/MarginContainer/VBoxContainer/WaveLabel
@onready var hud_objective: Label = $HUD/MarginContainer/VBoxContainer/ObjectiveLabel
@onready var hud_tip: Label = $HUD/MarginContainer/VBoxContainer/TipLabel
@onready var hud_xp_bar: ProgressBar = $HUD/MarginContainer/VBoxContainer/XPBar
@onready var status_card_bg: ColorRect = $HUD/StatusCardBg
@onready var status_card_accent: ColorRect = $HUD/StatusCardAccent
@onready var status_label: Label = $HUD/StatusLabel
@onready var banner_backing: ColorRect = $HUD/TopCenter/BannerBacking
@onready var banner_accent: ColorRect = $HUD/TopCenter/BannerAccent
@onready var banner_label: Label = $HUD/TopCenter/BannerLabel
@onready var focus_overlay: Control = $HUD/FocusOverlay
@onready var focus_badge: Label = $HUD/FocusOverlay/PanelContainer/MarginContainer/VBoxContainer/BadgeLabel
@onready var focus_title: Label = $HUD/FocusOverlay/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var focus_detail: Label = $HUD/FocusOverlay/PanelContainer/MarginContainer/VBoxContainer/DetailLabel
@onready var summary_label: Label = $HUD/FocusOverlay/PanelContainer/MarginContainer/VBoxContainer/SummaryLabel
@onready var restart_button: Button = $HUD/RestartButton
@onready var continue_button: Button = $HUD/ContinueButton
@onready var pause_button: Button = $HUD/PauseButton
@onready var joystick: Control = $HUD/TouchJoystick
@onready var dash_button: Button = $HUD/DashButton
@onready var mobile_hint_bg: ColorRect = $HUD/MobileHintBg
@onready var mobile_hint: Label = $HUD/MobileHint

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

	_apply_ui_style()

	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

	attack_timer.wait_time = attack_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()

	player.xp_changed.connect(_on_player_xp_changed)
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

	_on_player_xp_changed(player.xp, player.xp_to_next, player.level)
	_on_player_stats_changed(player.health, player.max_health, player.level)
	_on_player_dash_state_changed(true, 0.0, false)
	_update_enemy_count()
	_update_meta_hud()
	_apply_wave_state(true)
	_setup_web_ui()
	_show_banner("第一劫 · %s" % _get_wave_title(1))
	_update_tip_text()

	print("survivor-demo polished demo ready")

func _process(delta: float) -> void:
	if not pause_requested and not game_over and not demo_clear:
		elapsed_time += delta
		_update_difficulty()
		_update_wave_progress()
		if elapsed_time >= demo_goal_seconds:
			_on_demo_clear()
	_update_enemy_count()
	_update_meta_hud()
	_update_focus_overlay()
	_update_status_card()
	_update_pause_button()
	_update_camera_feedback(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_browser_hint_acknowledged = true
	elif event is InputEventScreenTouch and event.pressed:
		_browser_hint_acknowledged = true
	elif event is InputEventKey and event.pressed:
		_browser_hint_acknowledged = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if OS.has_feature("web"):
			_browser_hint_acknowledged = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			_toggle_pause()
			return
	if (game_over or demo_clear or pause_requested) and event.is_action_pressed("restart_run"):
		_reload_scene()

func _setup_web_ui() -> void:
	var show_touch_ui := OS.has_feature("web") or OS.has_feature("mobile")
	if joystick != null:
		joystick.visible = show_touch_ui
	if dash_button != null:
		dash_button.visible = show_touch_ui
	if mobile_hint_bg != null:
		mobile_hint_bg.visible = show_touch_ui
	if mobile_hint != null:
		mobile_hint.visible = show_touch_ui
	if focus_overlay != null:
		focus_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if restart_button != null:
		restart_button.visible = false
	if continue_button != null:
		continue_button.visible = false

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
	if focus_badge != null:
		focus_badge.text = badge_text
	if summary_label != null:
		summary_label.visible = pause_requested or game_over or demo_clear
		if not summary_label.visible:
			summary_label.text = ""
	focus_overlay.visible = overlay_visible
	if continue_button != null:
		continue_button.visible = pause_requested
	if restart_button != null:
		restart_button.visible = pause_requested or game_over or demo_clear
	if pause_button != null:
		pause_button.visible = not game_over and not demo_clear

func _update_difficulty() -> void:
	var next_stage := int(floor(elapsed_time / difficulty_step_seconds))
	if next_stage == difficulty_stage:
		return

	difficulty_stage = next_stage
	spawn_timer.wait_time = maxf(0.28, spawn_interval - difficulty_stage * 0.06)
	max_alive_enemies = mini(88, 18 + difficulty_stage * 5 + wave_index * 2)
	if difficulty_stage > 0:
		_show_banner("妖势渐盛 · %s" % _get_stage_title(difficulty_stage + 1))
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
	if not is_initial:
		player.heal(1)
		_show_banner("第%d劫 · %s" % [wave_index, _get_wave_title(wave_index)])
		_spawn_popup(player.global_position + Vector2(0, -32), "+1 命", HUD_MINT)
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
	for _i in range(elite_count):
		if enemies.get_child_count() >= max_alive_enemies:
			break
		_spawn_enemy(true)
	if elite_count > 0:
		_spawn_popup(player.global_position + Vector2(0, -58), "头目现身", HUD_WARNING)

func _on_spawn_timer_timeout() -> void:
	if enemy_scene == null or not is_instance_valid(player) or game_over or demo_clear:
		return

	var available_slots := max_alive_enemies - enemies.get_child_count()
	if available_slots <= 0:
		return

	var spawn_total := mini(spawn_count_per_wave + int(wave_index / 3), available_slots)
	for _i in range(spawn_total):
		_spawn_enemy()

func _spawn_enemy(force_elite: bool = false) -> void:
	var spawn_roll := randf()
	var scene_to_spawn: PackedScene = enemy_scene
	var fast_weight: float = minf(0.52, 0.14 + wave_index * 0.05 + difficulty_stage * 0.02)
	var tank_weight: float = 0.0
	if wave_index >= 3:
		tank_weight = minf(0.26, 0.06 + (wave_index - 2) * 0.04)
	if tank_enemy_scene != null and spawn_roll < tank_weight:
		scene_to_spawn = tank_enemy_scene
	elif fast_enemy_scene != null and spawn_roll < tank_weight + fast_weight:
		scene_to_spawn = fast_enemy_scene

	var enemy: Node = scene_to_spawn.instantiate()
	if enemy == null:
		return

	enemy.global_position = _get_spawn_position()
	enemy.set("move_speed", float(enemy.get("move_speed")) + difficulty_stage * 5.0 + max(0, wave_index - 1) * 4.0 + max(0, player.level - 1) * 3.0)
	enemy.set("max_health", int(enemy.get("max_health")) + int((difficulty_stage + wave_index - 1) / 3))
	enemy.set("contact_damage", int(enemy.get("contact_damage")) + int((difficulty_stage + wave_index - 1) / 5))
	enemy.set("xp_reward", int(enemy.get("xp_reward")) + int((wave_index - 1) / 2))
	enemy.set("target", player)
	if force_elite and enemy.has_method("make_elite"):
		enemy.make_elite(1.28 + minf(0.14, float(wave_index - 2) * 0.02))
		_elites_spawned_total += 1
		_add_camera_shake(9.0, 0.25)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	enemies.add_child(enemy)

func _on_attack_timer_timeout() -> void:
	if projectile_scene == null or not is_instance_valid(player) or game_over or demo_clear:
		return

	var range_value: float = float(attack_range) + float(player.level) * 14.0
	var target: Node2D = _get_nearest_enemy_in_range(range_value)
	if target == null:
		return

	var shot_count := 1 + int((player.level - 1) / 4)
	shot_count = mini(shot_count, 4)
	var pierce_count := int((player.level - 1) / 5)
	var base_direction := (target.global_position - player.global_position).normalized()
	var spread_step := deg_to_rad(10.0)
	var start_angle := -spread_step * float(shot_count - 1) * 0.5

	for i in range(shot_count):
		var projectile := projectile_scene.instantiate()
		if projectile == null:
			continue
		var angle_offset := start_angle + spread_step * i
		var direction := base_direction.rotated(angle_offset)
		projectile.global_position = player.global_position
		projectile.set("direction", direction)
		projectile.set("speed", projectile_speed + player.level * 18.0 + wave_index * 6.0)
		projectile.set("damage", 1 + int((player.level - 1) / 3) + int((wave_index - 1) / 4))
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

func _on_enemy_died(enemy: Node, death_position: Vector2, xp_reward: int) -> void:
	kill_count += 1
	var popup_color := HUD_MINT
	var popup_text := "修为 +%d" % xp_reward
	if enemy != null and bool(enemy.get("is_elite")):
		popup_color = HUD_WARNING
		popup_text = "头目修为 +%d" % xp_reward
		_add_camera_shake(8.0, 0.22)
	_spawn_popup(death_position, popup_text, popup_color)
	var expected_heal_rewards := int(kill_count / 25)
	if expected_heal_rewards > _heals_awarded_by_kills:
		_heals_awarded_by_kills = expected_heal_rewards
		player.heal(1)
		_spawn_popup(player.global_position + Vector2(0, -28), "连斩福泽 +1 命", HUD_SKY)
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
	pickups.call_deferred("add_child", xp_orb)

func _on_player_xp_changed(current_xp: int, xp_to_next: int, level: int) -> void:
	attack_timer.wait_time = maxf(0.14, attack_interval - (level - 1) * 0.02)
	hud_level.text = "行者 %d重  ·  %s" % [level, _get_stage_title(difficulty_stage + 1)]
	hud_xp_bar.max_value = max(1, xp_to_next)
	hud_xp_bar.value = current_xp
	hud_xp_bar.show_percentage = false
	hud_xp_bar.tooltip_text = "修为 %d / %d" % [current_xp, xp_to_next]
	var shots := 1 + int((level - 1) / 4)
	shots = mini(shots, 4)
	var pierce := int((level - 1) / 5)
	var damage := 1 + int((level - 1) / 3) + int((wave_index - 1) / 4)
	hud_weapon.text = "法术：%d 伤 · %d 连发 · %d 穿透" % [damage, shots, pierce]
	if level > _last_level:
		_show_banner("修为精进 · 行者 %d重" % level)
		_add_camera_shake(6.0, 0.18)
	_last_level = level

func _on_player_stats_changed(health: int, max_health: int, _level: int) -> void:
	hud_health.text = "命火 %d/%d  ·  出手 %.2fs" % [health, max_health, attack_timer.wait_time]
	if health <= 2:
		hud_health.add_theme_color_override("font_color", HUD_DANGER)
	else:
		hud_health.add_theme_color_override("font_color", HUD_PAPER)
	if _last_health >= 0 and health < _last_health and not game_over:
		_spawn_popup(player.global_position + Vector2(0, -22), "-%d 命" % (_last_health - health), HUD_DANGER)
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
	elif is_ready:
		dash_button.text = "筋斗闪"
		dash_button.disabled = false
	else:
		dash_button.text = "%.1fs" % cooldown_remaining
		dash_button.disabled = true

func _on_dash_button_pressed() -> void:
	if player != null and player.has_method("request_dash"):
		if player.request_dash():
			_browser_hint_acknowledged = true
			_spawn_popup(player.global_position + Vector2(0, -38), "筋斗闪", HUD_WARNING)
			_add_camera_shake(4.0, 0.12)

func _on_player_died() -> void:
	if game_over:
		return
	game_over = true
	spawn_timer.stop()
	attack_timer.stop()
	hud_tip.text = "功行散尽 · 按 R 或点右下再闯一局"
	_set_pause_state(false)
	_show_banner("此局止步 · 斩妖 %d" % kill_count)
	_add_camera_shake(12.0, 0.28)
	if restart_button != null:
		restart_button.visible = true

func _on_demo_clear() -> void:
	if demo_clear:
		return
	demo_clear = true
	spawn_timer.stop()
	attack_timer.stop()
	hud_tip.text = "试炼通关 · 按 R 或点右下再走一遭"
	_set_pause_state(false)
	_show_banner("大圣护场 · 存活 %02d:%02d" % [int(elapsed_time) / 60, int(elapsed_time) % 60])
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
	hud_timer.text = "时辰 %02d:%02d / %02d:%02d" % [minutes, seconds, int(demo_goal_seconds) / 60, int(demo_goal_seconds) % 60]
	hud_kills.text = "斩妖 %d  ·  头目 %d" % [kill_count, _elites_spawned_total]
	hud_wave.text = "第%d劫：%s  ·  下波 %02ds" % [wave_index, _get_wave_title(wave_index), next_wave_in]
	hud_objective.text = "花果山小目标：撑到 %02d:%02d。每 25 连斩续 1 命，双数劫波多半会有头目压阵。" % [int(demo_goal_seconds) / 60, int(demo_goal_seconds) % 60]

func _update_status_card() -> void:
	if status_label == null:
		return
	var next_heal_goal := (_heals_awarded_by_kills + 1) * 25
	var kills_to_heal := maxi(0, next_heal_goal - kill_count)
	var status_title := "金箍势稳"
	var status_detail := "福泽香火未满，离下一口回命还差 %d 斩妖。" % kills_to_heal
	var status_color := HUD_PAPER
	var accent_color := HUD_GOLD
	var background_color := HUD_PANEL
	if game_over:
		status_title = "败阵回看"
		status_detail = "本局招式已经记下，按 R / 按钮重开，再试一套更顺的走位。"
		status_color = HUD_DANGER
		accent_color = HUD_DANGER
		background_color = Color(0.22, 0.08, 0.08, 0.82)
	elif demo_clear:
		status_title = "大圣喝彩"
		status_detail = "三分钟试炼已过，可立刻再闯一局，继续冲更高斩妖与修为。"
		status_color = HUD_MINT
		accent_color = HUD_MINT
		background_color = Color(0.10, 0.16, 0.12, 0.82)
	elif pause_requested:
		status_title = "戏台暂歇"
		status_detail = "当前波次与战报都保留着，点继续试炼即可无缝回场。"
		status_color = HUD_SKY
		accent_color = HUD_SKY
		background_color = Color(0.08, 0.12, 0.18, 0.82)
	elif player.health <= 2:
		status_title = "命火告急"
		status_detail = "先筋斗闪拉位，再收修为球续命；这局别跟妖群硬换。"
		status_color = HUD_DANGER
		accent_color = HUD_DANGER
		background_color = Color(0.22, 0.08, 0.08, 0.82)
	elif wave_index >= 5:
		status_title = "火云压阵"
		status_detail = "终局妖潮已起：先避重装贴脸，留一段筋斗闪穿出包围。"
		status_color = HUD_WARNING
		accent_color = HUD_WARNING
		background_color = Color(0.20, 0.12, 0.05, 0.82)
	elif kills_to_heal <= 5:
		status_title = "福泽将满"
		status_detail = "再斩 %d 妖，就有一口回命香火续上。" % kills_to_heal
		status_color = HUD_MINT
		accent_color = HUD_MINT
		background_color = Color(0.10, 0.16, 0.12, 0.82)
	status_label.text = "%s\n%s" % [status_title, status_detail]
	status_label.add_theme_color_override("font_color", status_color)
	if status_card_accent != null:
		status_card_accent.color = accent_color
	if status_card_bg != null:
		status_card_bg.color = background_color

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

func _show_banner(text_value: String) -> void:
	if banner_label == null:
		return
	banner_label.text = text_value
	banner_label.modulate = Color(1, 1, 1, 1)
	banner_label.visible = true
	if banner_backing != null:
		banner_backing.modulate = Color(1, 1, 1, 1)
		banner_backing.visible = true
	if banner_accent != null:
		banner_accent.modulate = Color(1, 1, 1, 1)
		banner_accent.visible = true
	var tween := create_tween()
	tween.tween_interval(1.15)
	tween.parallel().tween_property(banner_label, "modulate", Color(1, 1, 1, 0), 0.45)
	if banner_backing != null:
		tween.parallel().tween_property(banner_backing, "modulate", Color(1, 1, 1, 0), 0.45)
	if banner_accent != null:
		tween.parallel().tween_property(banner_accent, "modulate", Color(1, 1, 1, 0), 0.45)
	tween.finished.connect(func():
		banner_label.visible = false
		if banner_backing != null:
			banner_backing.visible = false
		if banner_accent != null:
			banner_accent.visible = false
	)

func _update_tip_text() -> void:
	if game_over or demo_clear:
		return
	var tip := "行者起手：WASD 挪身 · Space 筋斗闪 · 如意法术会自动寻妖。"
	if OS.has_feature("web"):
		tip = "网页端先轻点画面，再用 WASD / 摇杆走位；Space / 右下按钮可使筋斗闪。"
	if pause_requested:
		tip = "戏台暂歇中：继续试炼会原地接回，不会丢当前节奏。"
	elif player.health <= 2:
		tip = "命火将熄：先闪身穿妖群，收修为球冲等级，别跟贴脸怪硬换。"
	elif wave_index >= 5:
		tip = "火云压阵：先拆边路、躲重装，再回头收尾，筋斗闪尽量留给穿围。"
	elif wave_index >= 3:
		tip = "妖潮转急：看见头目先拉开半步，再借自动法术慢慢磨。"
	hud_tip.text = tip
	if mobile_hint != null:
		var mobile_text := "左下摇杆走位\n右下筋斗闪穿怪\n暂停/重开都在右侧"
		if pause_requested:
			mobile_text = "戏台暂歇中\n点继续试炼回场\n战报会原样保留"
		elif player.health <= 2:
			mobile_text = "命火告急先走位\n筋斗闪穿包围\n吃修为球补节奏"
		elif wave_index >= 5:
			mobile_text = "火云压阵别贪站撸\n留筋斗闪过重装\n清边路再回头收尾"
		mobile_hint.text = mobile_text

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

func _on_joystick_vector_changed(direction: Vector2) -> void:
	if player != null and player.has_method("set_external_input_vector"):
		player.set_external_input_vector(direction)
	if direction.length() > 0.0:
		_browser_hint_acknowledged = true

func _add_camera_shake(strength: float, duration: float) -> void:
	_camera_shake_strength = maxf(_camera_shake_strength, strength)
	_camera_shake_time = maxf(_camera_shake_time, duration)

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
	_set_pause_state(false)

func _set_pause_state(should_pause: bool) -> void:
	pause_requested = should_pause
	get_tree().paused = should_pause
	if pause_button != null:
		pause_button.text = "继续试炼" if should_pause else "暂停"
	_update_focus_overlay()

func _update_pause_button() -> void:
	if pause_button == null:
		return
	pause_button.text = "继续试炼" if pause_requested else "暂停"
	pause_button.disabled = game_over or demo_clear

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

func _build_run_summary(title_text: String) -> String:
	var total_seconds := int(elapsed_time)
	return "西游评语：%s\n时辰：%02d:%02d / %02d:%02d\n斩妖：%d    头目：%d\n行者：%d重    命火：%d/%d\n劫波：第%d劫 · %s" % [
		title_text,
		int(total_seconds / 60),
		total_seconds % 60,
		int(demo_goal_seconds) / 60,
		int(demo_goal_seconds) % 60,
		kill_count,
		_elites_spawned_total,
		player.level,
		player.health,
		player.max_health,
		wave_index,
		_get_wave_title(wave_index)
	]

func _reload_scene() -> void:
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
		status_label: HUD_PAPER,
		banner_label: HUD_GOLD,
		focus_badge: HUD_WARNING,
		focus_title: HUD_GOLD,
		focus_detail: HUD_PAPER,
		summary_label: HUD_PAPER,
		mobile_hint: HUD_PAPER
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
	status_label.add_theme_font_size_override("font_size", 16)
	banner_label.add_theme_font_size_override("font_size", 26)
	focus_badge.add_theme_font_size_override("font_size", 15)
	focus_title.add_theme_font_size_override("font_size", 24)
	focus_detail.add_theme_font_size_override("font_size", 17)
	summary_label.add_theme_font_size_override("font_size", 16)
	mobile_hint.add_theme_font_size_override("font_size", 16)

	hud_xp_bar.add_theme_stylebox_override("fill", fill_style)
	hud_xp_bar.add_theme_stylebox_override("background", background_style)
	hud_xp_bar.add_theme_color_override("font_color", HUD_INK)

	var focus_panel := focus_overlay.get_node("PanelContainer") as PanelContainer
	if focus_panel != null:
		focus_panel.add_theme_stylebox_override("panel", panel_style)
	if restart_button != null:
		_apply_button_style(restart_button, primary_button, primary_button_hover, primary_button_pressed, primary_button_disabled)
		restart_button.text = "再闯一局"
	if continue_button != null:
		_apply_button_style(continue_button, primary_button, primary_button_hover, primary_button_pressed, primary_button_disabled)
		continue_button.text = "继续试炼"
	if pause_button != null:
		_apply_button_style(pause_button, panel_soft, primary_button_hover, primary_button_pressed, primary_button_disabled)
		pause_button.text = "暂停"
		pause_button.add_theme_color_override("font_color", HUD_GOLD)
		pause_button.add_theme_font_size_override("font_size", 20)
	if dash_button != null:
		_apply_button_style(dash_button, panel_soft, primary_button_hover, primary_button_pressed, primary_button_disabled)
		dash_button.add_theme_color_override("font_color", HUD_GOLD)
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
