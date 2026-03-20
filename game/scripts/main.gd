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
@export var difficulty_step_seconds: float = 30.0
@export var wave_length_seconds: float = 30.0
@export var demo_goal_seconds: float = 180.0
@export var enemy_scene: PackedScene
@export var fast_enemy_scene: PackedScene
@export var tank_enemy_scene: PackedScene
@export var projectile_scene: PackedScene
@export var xp_orb_scene: PackedScene
@export var damage_popup_scene: PackedScene

var elapsed_time: float = 0.0
var kill_count: int = 0
var difficulty_stage: int = 0
var wave_index: int = 1
var game_over: bool = false
var demo_clear: bool = false
var _last_health: int = -1
var _last_level: int = 1
var _browser_hint_acknowledged: bool = false
var _heals_awarded_by_kills: int = 0
var _elites_spawned_total: int = 0
var _camera_shake_strength: float = 0.0
var _camera_shake_time: float = 0.0
var _camera_base_offset: Vector2 = Vector2.ZERO
var _kill_streak: int = 0
var _kill_streak_timer: float = 0.0
var _tempo_boost_timer: float = 0.0
var _tempo_boost_active_last_frame: bool = false
var _objective_stage_cleared: int = 0

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
@onready var banner_label: Label = $HUD/TopCenter/BannerLabel
@onready var focus_overlay: Control = $HUD/FocusOverlay
@onready var focus_title: Label = $HUD/FocusOverlay/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var focus_detail: Label = $HUD/FocusOverlay/PanelContainer/MarginContainer/VBoxContainer/DetailLabel
@onready var restart_button: Button = $HUD/RestartButton
@onready var joystick: Control = $HUD/TouchJoystick
@onready var dash_button: Button = $HUD/DashButton
@onready var mobile_hint: Label = $HUD/MobileHint

func _ready() -> void:
	randomize()

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

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	attack_timer.timeout.connect(_on_attack_timer_timeout)

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
	if player_camera != null:
		_camera_base_offset = player_camera.offset

	_apply_spawn_profile(true)
	_refresh_attack_timer()
	spawn_timer.start()
	attack_timer.start()
	_on_player_xp_changed(player.xp, player.xp_to_next, player.level)
	_on_player_stats_changed(player.health, player.max_health, player.level)
	_on_player_dash_state_changed(true, 0.0, false)
	_update_enemy_count()
	_update_meta_hud()
	_setup_web_ui()
	_show_banner("Wave 1 · 热身开局")
	_update_tip_text()

	print("survivor-demo combat pacing pass ready")

func _process(delta: float) -> void:
	if not game_over and not demo_clear:
		elapsed_time += delta
		_update_difficulty()
		_update_wave_progress()
		_update_tempo_feedback(delta)
		_update_objective_progress()
		if elapsed_time >= demo_goal_seconds:
			_on_demo_clear()
	_update_enemy_count()
	_update_meta_hud()
	_update_focus_overlay()
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
	if (game_over or demo_clear) and event.is_action_pressed("restart_run"):
		_reload_scene()

func _setup_web_ui() -> void:
	var show_touch_ui := OS.has_feature("web") or OS.has_feature("mobile")
	if joystick != null:
		joystick.visible = show_touch_ui
	if dash_button != null:
		dash_button.visible = show_touch_ui
	if mobile_hint != null:
		mobile_hint.visible = show_touch_ui
	if focus_overlay != null:
		focus_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if restart_button != null:
		restart_button.visible = false

func _update_focus_overlay() -> void:
	if focus_overlay == null or focus_title == null or focus_detail == null:
		return
	var needs_hint := false
	if OS.has_feature("web"):
		needs_hint = not _browser_hint_acknowledged
		if not needs_hint and not get_window().has_focus():
			needs_hint = true
	if game_over or demo_clear:
		needs_hint = false
	focus_overlay.visible = needs_hint
	if not needs_hint:
		return
	focus_title.text = "轻触画面开始 / 恢复操控"
	focus_detail.text = "网页端首次进入或浏览器失焦后，需要先点一下游戏区域。\n桌面端可用 WASD + Space 闪避，手机端拖动左下角摇杆并点右下闪避。"

func _update_difficulty() -> void:
	var next_stage := int(floor(elapsed_time / difficulty_step_seconds))
	if next_stage == difficulty_stage:
		return

	difficulty_stage = next_stage
	_apply_spawn_profile(false)
	if difficulty_stage > 0:
		_show_banner("危险升级 · Stage %d" % (difficulty_stage + 1))
		_add_camera_shake(5.0, 0.18)

func _update_wave_progress() -> void:
	var target_wave := mini(int(floor(elapsed_time / wave_length_seconds)) + 1, int(ceil(demo_goal_seconds / wave_length_seconds)))
	if target_wave > wave_index:
		wave_index = target_wave
		_apply_spawn_profile(false)

func _apply_spawn_profile(is_initial: bool) -> void:
	var profile := _get_wave_profile(wave_index)
	spawn_count_per_wave = int(profile.get("batch", 1)) + int(mini(difficulty_stage, 2))
	max_alive_enemies = int(profile.get("alive", 16)) + difficulty_stage * 3
	spawn_timer.wait_time = maxf(0.36, float(profile.get("interval", spawn_interval)) - difficulty_stage * 0.03)
	_refresh_attack_timer()
	if not is_initial:
		player.heal(1)
		_show_banner("Wave %d · %s" % [wave_index, str(profile.get("label", "火力升级"))])
		_spawn_popup(player.global_position + Vector2(0, -32), "+1 HP", Color(0.55, 1.0, 0.65, 1.0))
		_add_camera_shake(7.0, 0.26)
		_spawn_elite_pack_for_wave(int(profile.get("elite_count", 0)))
	_update_tip_text()

func _get_wave_profile(target_wave: int) -> Dictionary:
	match target_wave:
		1:
			return {
				"batch": 1,
				"alive": 12,
				"interval": 1.05,
				"fast_weight": 0.02,
				"tank_weight": 0.0,
				"elite_count": 0,
				"label": "热身开局"
			}
		2:
			return {
				"batch": 2,
				"alive": 18,
				"interval": 0.92,
				"fast_weight": 0.22,
				"tank_weight": 0.0,
				"elite_count": 0,
				"label": "追兵提速"
			}
		3:
			return {
				"batch": 2,
				"alive": 24,
				"interval": 0.82,
				"fast_weight": 0.30,
				"tank_weight": 0.0,
				"elite_count": 1,
				"label": "精英试炼"
			}
		4:
			return {
				"batch": 3,
				"alive": 30,
				"interval": 0.76,
				"fast_weight": 0.28,
				"tank_weight": 0.12,
				"elite_count": 1,
				"label": "重装入场"
			}
		5:
			return {
				"batch": 3,
				"alive": 36,
				"interval": 0.68,
				"fast_weight": 0.34,
				"tank_weight": 0.16,
				"elite_count": 2,
				"label": "双精英压阵"
			}
		_:
			return {
				"batch": 4,
				"alive": 42,
				"interval": 0.60,
				"fast_weight": 0.38,
				"tank_weight": 0.22,
				"elite_count": 2,
				"label": "终局冲阵"
			}

func _spawn_elite_pack_for_wave(elite_count: int) -> void:
	if elite_count <= 0 or game_over or demo_clear:
		return
	for _i in elite_count:
		if enemies.get_child_count() >= max_alive_enemies:
			break
		_spawn_enemy(true)
	_spawn_popup(player.global_position + Vector2(0, -58), "ELITE INBOUND", Color(1.0, 0.8, 0.3, 1.0))

func _on_spawn_timer_timeout() -> void:
	if enemy_scene == null or not is_instance_valid(player) or game_over or demo_clear:
		return

	var available_slots := max_alive_enemies - enemies.get_child_count()
	if available_slots <= 0:
		return

	var batch := spawn_count_per_wave
	if player.health <= 2:
		batch = maxi(1, batch - 1)
	if player.level >= 6 and wave_index >= 5:
		batch += 1
	var spawn_total := mini(batch, available_slots)
	for _i in spawn_total:
		_spawn_enemy()

func _spawn_enemy(force_elite: bool = false) -> void:
	var profile := _get_wave_profile(wave_index)
	var spawn_roll := randf()
	var scene_to_spawn: PackedScene = enemy_scene
	var fast_weight := float(profile.get("fast_weight", 0.14)) + float(player.level - 1) * 0.01
	var tank_weight := float(profile.get("tank_weight", 0.0))
	if player.health <= 2:
		fast_weight = maxf(0.0, fast_weight - 0.10)
		tank_weight = maxf(0.0, tank_weight - 0.05)
	fast_weight = minf(0.54, fast_weight)
	tank_weight = minf(0.24, tank_weight)

	if tank_enemy_scene != null and spawn_roll < tank_weight:
		scene_to_spawn = tank_enemy_scene
	elif fast_enemy_scene != null and spawn_roll < tank_weight + fast_weight:
		scene_to_spawn = fast_enemy_scene

	var enemy: Node = scene_to_spawn.instantiate()
	if enemy == null:
		return

	enemy.global_position = _get_spawn_position()
	enemy.set("move_speed", float(enemy.get("move_speed")) + difficulty_stage * 4.0 + max(0, wave_index - 1) * 3.0 + max(0, player.level - 1) * 2.0)
	enemy.set("max_health", int(enemy.get("max_health")) + int((difficulty_stage + wave_index - 1) / 4))
	enemy.set("contact_damage", int(enemy.get("contact_damage")) + int((difficulty_stage + wave_index - 1) / 6))
	enemy.set("xp_reward", int(enemy.get("xp_reward")) + int((wave_index - 1) / 2))
	enemy.set("target", player)
	if enemy.has_method("set_spawn_grace"):
		enemy.set_spawn_grace(0.45)
	if force_elite and enemy.has_method("make_elite"):
		enemy.make_elite(1.24 + minf(0.14, float(wave_index - 2) * 0.02))
		_elites_spawned_total += 1
		_add_camera_shake(9.0, 0.25)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	enemies.add_child(enemy)

func _on_attack_timer_timeout() -> void:
	if projectile_scene == null or not is_instance_valid(player) or game_over or demo_clear:
		return

	var range_value := float(attack_range) + float(player.level) * 14.0
	var target: Node2D = _get_nearest_enemy_in_range(range_value)
	if target == null:
		return

	var shot_count := 1 + int((player.level - 1) / 4)
	shot_count = mini(shot_count, 4)
	var pierce_count := int((player.level - 1) / 5)
	var base_direction := (target.global_position - player.global_position).normalized()
	var spread_step := deg_to_rad(10.0)
	var start_angle := -spread_step * float(shot_count - 1) * 0.5

	for i in shot_count:
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
	_kill_streak += 1
	_kill_streak_timer = 3.2
	var popup_color := Color(0.5, 1.0, 0.6, 1.0)
	var popup_text := "+%d" % xp_reward
	if enemy != null and bool(enemy.get("is_elite")):
		popup_color = Color(1.0, 0.82, 0.36, 1.0)
		popup_text = "ELITE +%d" % xp_reward
		_add_camera_shake(8.0, 0.22)
	_spawn_popup(death_position, popup_text, popup_color)
	if _kill_streak == 5 or _kill_streak == 10:
		_spawn_popup(player.global_position + Vector2(0, -46), "%d 连斩" % _kill_streak, Color(1.0, 0.9, 0.52, 1.0))
	if _kill_streak > 0 and _kill_streak % 12 == 0:
		_tempo_boost_timer = 5.0
		_refresh_attack_timer()
		_show_banner("杀势已起 · 5 秒急速射击")
		_spawn_popup(player.global_position + Vector2(0, -64), "Tempo Up", Color(1.0, 0.95, 0.58, 1.0))
	var expected_heal_rewards := int(kill_count / 28)
	if expected_heal_rewards > _heals_awarded_by_kills:
		_heals_awarded_by_kills = expected_heal_rewards
		player.heal(1)
		_spawn_popup(player.global_position + Vector2(0, -28), "连杀补给 +1 HP", Color(0.6, 0.95, 1.0, 1.0))
	_update_objective_progress()
	if xp_orb_scene == null:
		return

	_spawn_xp_orb_deferred(
		death_position,
		xp_orb_value + xp_reward - 1,
		116.0 + player.level * 8.0 + (22.0 if enemy != null and bool(enemy.get("is_elite")) else 0.0),
		190.0 + player.level * 8.0
	)

func _on_player_xp_changed(current_xp: int, xp_to_next: int, level: int) -> void:
	_refresh_attack_timer()
	hud_level.text = "Level %d  ·  难度 %d" % [level, difficulty_stage + 1]
	hud_xp_bar.max_value = max(1, xp_to_next)
	hud_xp_bar.value = current_xp
	hud_xp_bar.show_percentage = false
	hud_xp_bar.tooltip_text = "XP %d / %d" % [current_xp, xp_to_next]
	var shots := 1 + int((level - 1) / 4)
	shots = mini(shots, 4)
	var pierce := int((level - 1) / 5)
	var speed_tag := ""
	if level % 3 == 0 or level % 4 == 0:
		speed_tag = " · 成长中"
	hud_weapon.text = "Weapon %d dmg · %d shots · %d pierce%s" % [1 + int((level - 1) / 3) + int((wave_index - 1) / 4), shots, pierce, speed_tag]
	if level > _last_level:
		_show_banner("LEVEL UP · Lv.%d" % level)
		_add_camera_shake(6.0, 0.18)
	_last_level = level

func _on_player_stats_changed(health: int, max_health: int, _level: int) -> void:
	hud_health.text = "HP %d/%d  攻速 %.2fs" % [health, max_health, attack_timer.wait_time]
	if _last_health >= 0 and health < _last_health and not game_over:
		_spawn_popup(player.global_position + Vector2(0, -22), "-%d" % (_last_health - health), Color(1.0, 0.45, 0.45, 1.0))
		_add_camera_shake(10.0, 0.16)
	_last_health = health
	if health <= 0 and not game_over:
		_on_player_died()
	_update_tip_text()

func _on_player_dash_state_changed(is_ready: bool, cooldown_remaining: float, is_dashing: bool) -> void:
	if dash_button == null:
		return
	if is_dashing:
		dash_button.text = "闪避!"
		dash_button.disabled = false
	elif is_ready:
		dash_button.text = "闪避"
		dash_button.disabled = false
	else:
		dash_button.text = "%.1fs" % cooldown_remaining
		dash_button.disabled = true

func _on_dash_button_pressed() -> void:
	if player != null and player.has_method("request_dash"):
		if player.request_dash():
			_browser_hint_acknowledged = true
			_spawn_popup(player.global_position + Vector2(0, -38), "Dash", Color(1.0, 0.92, 0.52, 1.0))
			_add_camera_shake(4.0, 0.12)

func _on_player_died() -> void:
	if game_over:
		return
	game_over = true
	spawn_timer.stop()
	attack_timer.stop()
	hud_tip.text = "GAME OVER · 按 R 或点按钮重开"
	_show_banner("战斗结束 · 击杀 %d" % kill_count)
	_add_camera_shake(12.0, 0.28)
	if restart_button != null:
		restart_button.visible = true

func _on_demo_clear() -> void:
	if demo_clear:
		return
	demo_clear = true
	spawn_timer.stop()
	attack_timer.stop()
	hud_tip.text = "DEMO CLEAR · 按 R 或点按钮再来一局"
	_show_banner("Demo Clear · 存活 %02d:%02d" % [int(elapsed_time) / 60, int(elapsed_time) % 60])
	_add_camera_shake(10.0, 0.35)
	if restart_button != null:
		restart_button.visible = true

func _update_enemy_count() -> void:
	hud_enemies.text = "Enemies %d/%d" % [enemies.get_child_count(), max_alive_enemies]

func _update_meta_hud() -> void:
	var total_seconds := int(elapsed_time)
	var minutes := int(total_seconds / 60)
	var seconds := total_seconds % 60
	var next_wave_in := maxi(0, int(ceil(float(wave_index) * wave_length_seconds - elapsed_time)))
	hud_timer.text = "Time %02d:%02d / %02d:%02d" % [minutes, seconds, int(demo_goal_seconds) / 60, int(demo_goal_seconds) % 60]
	var streak_text := ""
	if _kill_streak > 1:
		streak_text = " · Streak %d" % _kill_streak
	hud_kills.text = "Kills %d · Elite %d%s" % [kill_count, _elites_spawned_total, streak_text]
	hud_wave.text = "Wave %d  ·  Next %02ds" % [wave_index, next_wave_in]
	var objective_text := _get_objective_text()
	hud_objective.text = objective_text

func _get_objective_text() -> String:
	if elapsed_time < 60.0:
		return "首分钟目标：击杀 20（当前 %d/20）并升到 Lv.3" % kill_count
	if elapsed_time < 120.0:
		return "次分钟目标：击杀 55（当前 %d/55），准备迎接重装" % kill_count
	return "终局目标：撑到 03:00（当前击杀 %d），双精英后稳住走位" % kill_count

func _update_objective_progress() -> void:
	if _objective_stage_cleared < 1 and elapsed_time < 60.0 and kill_count >= 20:
		_objective_stage_cleared = 1
		_show_banner("首分钟目标达成")
		_spawn_popup(player.global_position + Vector2(0, -54), "+节奏稳定", Color(0.62, 1.0, 0.72, 1.0))
	elif _objective_stage_cleared < 2 and elapsed_time < 120.0 and kill_count >= 55:
		_objective_stage_cleared = 2
		_show_banner("二阶段目标达成")
		_spawn_popup(player.global_position + Vector2(0, -54), "+终局准备完成", Color(0.62, 1.0, 0.72, 1.0))

func _update_tempo_feedback(delta: float) -> void:
	if _kill_streak_timer > 0.0:
		_kill_streak_timer = maxf(0.0, _kill_streak_timer - delta)
		if _kill_streak_timer <= 0.0:
			_kill_streak = 0
	if _tempo_boost_timer > 0.0:
		_tempo_boost_timer = maxf(0.0, _tempo_boost_timer - delta)
	var tempo_active := _tempo_boost_timer > 0.0
	if tempo_active != _tempo_boost_active_last_frame:
		_tempo_boost_active_last_frame = tempo_active
		_refresh_attack_timer()
		_update_tip_text()

func _refresh_attack_timer() -> void:
	if attack_timer == null or player == null:
		return
	var bonus := 0.0
	if _tempo_boost_timer > 0.0:
		bonus += 0.08
	var wave_bonus := maxf(0.0, float(wave_index - 3) * 0.01)
	attack_timer.wait_time = maxf(0.12, attack_interval - float(player.level - 1) * 0.018 - wave_bonus - bonus)

func _spawn_xp_orb_deferred(world_position: Vector2, value: int, magnet_distance: float, orb_speed: float) -> void:
	call_deferred("_spawn_xp_orb_now", world_position, value, magnet_distance, orb_speed)

func _spawn_xp_orb_now(world_position: Vector2, value: int, magnet_distance: float, orb_speed: float) -> void:
	if xp_orb_scene == null or pickups == null:
		return
	var xp_orb := xp_orb_scene.instantiate()
	if xp_orb == null:
		return
	xp_orb.global_position = world_position
	xp_orb.set("xp_value", value)
	xp_orb.set("target", player)
	xp_orb.set("magnet_distance", magnet_distance)
	xp_orb.set("move_speed", orb_speed)
	pickups.add_child(xp_orb)

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
	var tween := create_tween()
	tween.tween_interval(1.1)
	tween.tween_property(banner_label, "modulate", Color(1, 1, 1, 0), 0.45)
	tween.finished.connect(func():
		banner_label.visible = false
	)

func _update_tip_text() -> void:
	if game_over or demo_clear:
		return
	var tip := "WASD 移动 · Space 闪避 · 自动攻击"
	if OS.has_feature("web"):
		tip = "网页端先点一下画面再操作 · WASD / 摇杆移动 · Space / 右下闪避"
	if _tempo_boost_timer > 0.0:
		tip = "杀势已起！现在火力更快，抓紧清场滚雪球"
	elif player.health <= 2:
		tip = "低血量！新刷敌人有短暂起手保护，优先闪避拉开再收割"
	elif wave_index >= 5:
		tip = "双精英阶段，先拆跑得快的，再绕开重装慢慢清"
	elif wave_index >= 4:
		tip = "重装已入场，别顶脸硬吃，拉扯出射线更稳"
	hud_tip.text = tip
	if mobile_hint != null:
		mobile_hint.text = "左手摇杆走位\n右下闪避穿怪\nR / 按钮重开"

func _get_spawn_position() -> Vector2:
	var player_position := player.global_position
	var viewport_size := get_viewport_rect().size
	var visible_rect := Rect2(player_position - viewport_size * 0.5, viewport_size)
	var spawn_min := minf(spawn_radius_min, spawn_radius_max)
	var spawn_max := maxf(spawn_radius_min, spawn_radius_max)

	for _attempt in 10:
		var angle := randf_range(0.0, TAU)
		var distance := randf_range(spawn_min, spawn_max)
		var candidate := player_position + Vector2.RIGHT.rotated(angle) * distance
		if visible_rect.has_point(candidate):
			continue
		if candidate.distance_to(player_position) < spawn_min * 0.92:
			continue
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

func _reload_scene() -> void:
	get_tree().reload_current_scene()
