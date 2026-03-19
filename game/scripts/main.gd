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
@export var enemy_scene: PackedScene
@export var fast_enemy_scene: PackedScene
@export var projectile_scene: PackedScene
@export var xp_orb_scene: PackedScene
@export var damage_popup_scene: PackedScene

var elapsed_time: float = 0.0
var kill_count: int = 0
var difficulty_stage: int = 0
var game_over: bool = false
var _last_health: int = -1

@onready var player: CharacterBody2D = $Player
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
@onready var hud_tip: Label = $HUD/MarginContainer/VBoxContainer/TipLabel
@onready var hud_xp_bar: ProgressBar = $HUD/MarginContainer/VBoxContainer/XPBar

func _ready() -> void:
    randomize()

    if enemy_scene == null:
        enemy_scene = load("res://scenes/enemy_basic.tscn")
    if fast_enemy_scene == null:
        fast_enemy_scene = load("res://scenes/enemy_runner.tscn")
    if projectile_scene == null:
        projectile_scene = load("res://scenes/projectile.tscn")
    if xp_orb_scene == null:
        xp_orb_scene = load("res://scenes/xp_orb.tscn")
    if damage_popup_scene == null:
        damage_popup_scene = load("res://scenes/damage_popup.tscn")

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
    _on_player_xp_changed(player.xp, player.xp_to_next, player.level)
    _on_player_stats_changed(player.health, player.max_health, player.level)
    _update_enemy_count()
    _update_meta_hud()
    hud_tip.text = "WASD 移动 · 自动攻击 · R 重开"

    print("survivor-demo v0 playable scene ready")

func _process(delta: float) -> void:
    if not game_over:
        elapsed_time += delta
        _update_difficulty()
    _update_enemy_count()
    _update_meta_hud()

func _unhandled_input(event: InputEvent) -> void:
    if game_over and event.is_action_pressed("restart_run"):
        get_tree().reload_current_scene()

func _update_difficulty() -> void:
    var next_stage := int(floor(elapsed_time / difficulty_step_seconds))
    if next_stage == difficulty_stage:
        return

    difficulty_stage = next_stage
    spawn_timer.wait_time = max(0.3, spawn_interval - difficulty_stage * 0.08)
    spawn_count_per_wave = min(6, 1 + int(difficulty_stage / 2))
    max_alive_enemies = min(72, 16 + difficulty_stage * 4)

func _on_spawn_timer_timeout() -> void:
    if enemy_scene == null or not is_instance_valid(player) or game_over:
        return

    var available_slots := max_alive_enemies - enemies.get_child_count()
    if available_slots <= 0:
        return

    var spawn_total := mini(spawn_count_per_wave, available_slots)
    for _i in spawn_total:
        _spawn_enemy()

func _spawn_enemy() -> void:
    var scene_to_spawn := enemy_scene
    if fast_enemy_scene != null and randf() < min(0.45, 0.08 + difficulty_stage * 0.04):
        scene_to_spawn = fast_enemy_scene

    var enemy := scene_to_spawn.instantiate()
    if enemy == null:
        return

    enemy.global_position = _get_spawn_position()
    enemy.set("move_speed", float(enemy.get("move_speed")) + difficulty_stage * 6.0 + max(0, player.level - 1) * 4.0)
    enemy.set("max_health", int(enemy.get("max_health")) + int(difficulty_stage / 3))
    enemy.set("contact_damage", int(enemy.get("contact_damage")) + int(difficulty_stage / 5))
    enemy.set("xp_reward", int(enemy.get("xp_reward")) + int(difficulty_stage / 4))
    enemy.set("target", player)
    if enemy.has_signal("died"):
        enemy.died.connect(_on_enemy_died)
    enemies.add_child(enemy)

func _on_attack_timer_timeout() -> void:
    if projectile_scene == null or not is_instance_valid(player) or game_over:
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

    for i in shot_count:
        var projectile := projectile_scene.instantiate()
        if projectile == null:
            continue
        var angle_offset := start_angle + spread_step * i
        var direction := base_direction.rotated(angle_offset)
        projectile.global_position = player.global_position
        projectile.set("direction", direction)
        projectile.set("speed", projectile_speed + player.level * 18.0)
        projectile.set("damage", 1 + int((player.level - 1) / 3))
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

func _on_enemy_died(_enemy: Node, death_position: Vector2, xp_reward: int) -> void:
    kill_count += 1
    _spawn_popup(death_position, "+%d" % xp_reward, Color(0.5, 1.0, 0.6, 1.0))
    if xp_orb_scene == null:
        return

    var xp_orb := xp_orb_scene.instantiate()
    if xp_orb == null:
        return

    xp_orb.global_position = death_position
    xp_orb.set("xp_value", xp_orb_value + xp_reward - 1)
    xp_orb.set("target", player)
    pickups.add_child(xp_orb)

func _on_player_xp_changed(current_xp: int, xp_to_next: int, level: int) -> void:
    attack_timer.wait_time = max(0.15, attack_interval - (level - 1) * 0.02)
    hud_level.text = "Level %d  ·  难度 %d" % [level, difficulty_stage + 1]
    hud_xp_bar.max_value = max(1, xp_to_next)
    hud_xp_bar.value = current_xp
    hud_xp_bar.show_percentage = false
    hud_xp_bar.tooltip_text = "XP %d / %d" % [current_xp, xp_to_next]
    var shots := 1 + int((level - 1) / 4)
    shots = mini(shots, 4)
    var pierce := int((level - 1) / 5)
    hud_weapon.text = "Weapon %d dmg · %d shots · %d pierce" % [1 + int((level - 1) / 3), shots, pierce]

func _on_player_stats_changed(health: int, max_health: int, _level: int) -> void:
    hud_health.text = "HP %d/%d  攻速 %.2fs" % [health, max_health, attack_timer.wait_time]
    if _last_health >= 0 and health < _last_health and not game_over:
        _spawn_popup(player.global_position + Vector2(0, -22), "-%d" % (_last_health - health), Color(1.0, 0.45, 0.45, 1.0))
    _last_health = health
    if health <= 0 and not game_over:
        _on_player_died()

func _on_player_died() -> void:
    if game_over:
        return
    game_over = true
    spawn_timer.stop()
    attack_timer.stop()
    hud_tip.text = "GAME OVER · 按 R 重新开始"

func _update_enemy_count() -> void:
    hud_enemies.text = "Enemies %d/%d" % [enemies.get_child_count(), max_alive_enemies]

func _update_meta_hud() -> void:
    var total_seconds := int(elapsed_time)
    var minutes := int(total_seconds / 60)
    var seconds := total_seconds % 60
    hud_timer.text = "Time %02d:%02d" % [minutes, seconds]
    hud_kills.text = "Kills %d" % kill_count

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

func _get_spawn_position() -> Vector2:
    var player_position := player.global_position
    var viewport_size := get_viewport_rect().size
    var visible_rect := Rect2(player_position - viewport_size * 0.5, viewport_size)
    var spawn_min := minf(spawn_radius_min, spawn_radius_max)
    var spawn_max := maxf(spawn_radius_min, spawn_radius_max)

    for _attempt in 8:
        var angle := randf_range(0.0, TAU)
        var distance := randf_range(spawn_min, spawn_max)
        var candidate := player_position + Vector2.RIGHT.rotated(angle) * distance
        if not visible_rect.has_point(candidate):
            return candidate

    var fallback_angle := randf_range(0.0, TAU)
    return player_position + Vector2.RIGHT.rotated(fallback_angle) * spawn_max
