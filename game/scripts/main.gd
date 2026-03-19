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
@export var enemy_scene: PackedScene
@export var projectile_scene: PackedScene
@export var xp_orb_scene: PackedScene

@onready var player: CharacterBody2D = $Player
@onready var enemies: Node2D = $Enemies
@onready var projectiles: Node2D = $Projectiles
@onready var pickups: Node2D = $Pickups
@onready var spawn_timer: Timer = $SpawnTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var hud_level: Label = $HUD/MarginContainer/VBoxContainer/LevelLabel
@onready var hud_health: Label = $HUD/MarginContainer/VBoxContainer/HealthLabel
@onready var hud_enemies: Label = $HUD/MarginContainer/VBoxContainer/EnemyLabel
@onready var hud_xp_bar: ProgressBar = $HUD/MarginContainer/VBoxContainer/XPBar

func _ready() -> void:
    randomize()

    if enemy_scene == null:
        enemy_scene = load("res://scenes/enemy_basic.tscn")
    if projectile_scene == null:
        projectile_scene = load("res://scenes/projectile.tscn")
    if xp_orb_scene == null:
        xp_orb_scene = load("res://scenes/xp_orb.tscn")

    spawn_timer.wait_time = spawn_interval
    spawn_timer.timeout.connect(_on_spawn_timer_timeout)
    spawn_timer.start()

    attack_timer.wait_time = attack_interval
    attack_timer.timeout.connect(_on_attack_timer_timeout)
    attack_timer.start()

    player.xp_changed.connect(_on_player_xp_changed)
    player.stats_changed.connect(_on_player_stats_changed)
    _on_player_xp_changed(player.xp, player.xp_to_next, player.level)
    _on_player_stats_changed(player.health, player.max_health, player.level)
    _update_enemy_count()

    print("survivor-demo v0 playable scene ready")

func _process(_delta: float) -> void:
    _update_enemy_count()

func _on_spawn_timer_timeout() -> void:
    if enemy_scene == null or not is_instance_valid(player):
        return

    var available_slots := max_alive_enemies - enemies.get_child_count()
    if available_slots <= 0:
        return

    var spawn_total := mini(spawn_count_per_wave, available_slots)
    for _i in spawn_total:
        _spawn_enemy()

func _spawn_enemy() -> void:
    var enemy := enemy_scene.instantiate()
    if enemy == null:
        return

    enemy.global_position = _get_spawn_position()
    enemy.set("move_speed", move_speed + max(0, player.level - 1) * 4.0)
    enemy.set("target", player)
    if enemy.has_signal("died"):
        enemy.died.connect(_on_enemy_died)
    enemies.add_child(enemy)

func _on_attack_timer_timeout() -> void:
    if projectile_scene == null or not is_instance_valid(player):
        return

    var target := _get_nearest_enemy_in_range(attack_range + player.level * 14.0)
    if target == null:
        return

    var projectile := projectile_scene.instantiate()
    if projectile == null:
        return

    var direction := (target.global_position - player.global_position).normalized()
    projectile.global_position = player.global_position
    projectile.set("direction", direction)
    projectile.set("speed", projectile_speed + player.level * 18.0)
    projectile.set("damage", 1 + int((player.level - 1) / 3))
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

func _on_enemy_died(_enemy: Node, death_position: Vector2) -> void:
    if xp_orb_scene == null:
        return

    var xp_orb := xp_orb_scene.instantiate()
    if xp_orb == null:
        return

    xp_orb.global_position = death_position
    xp_orb.set("xp_value", xp_orb_value)
    xp_orb.set("target", player)
    pickups.add_child(xp_orb)

func _on_player_xp_changed(current_xp: int, xp_to_next: int, level: int) -> void:
    attack_timer.wait_time = max(0.15, attack_interval - (level - 1) * 0.02)
    hud_level.text = "Level %d" % level
    hud_xp_bar.max_value = max(1, xp_to_next)
    hud_xp_bar.value = current_xp
    hud_xp_bar.show_percentage = false
    hud_xp_bar.tooltip_text = "XP %d / %d" % [current_xp, xp_to_next]

func _on_player_stats_changed(health: int, max_health: int, level: int) -> void:
    hud_health.text = "HP %d/%d  攻速 %.2fs" % [health, max_health, attack_timer.wait_time]
    if health <= 0:
        spawn_timer.stop()
        attack_timer.stop()
        hud_health.text += "  · GAME OVER"

func _update_enemy_count() -> void:
    hud_enemies.text = "Enemies %d/%d" % [enemies.get_child_count(), max_alive_enemies]

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
