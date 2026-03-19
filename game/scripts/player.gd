extends CharacterBody2D

signal xp_changed(current_xp: int, xp_to_next: int, level: int)
signal stats_changed(health: int, max_health: int, level: int)
signal died

@export var speed: float = 240.0
@export var max_health: int = 5

var health: int
var level: int = 1
var xp: int = 0
var xp_to_next: int = 5
var invulnerable_until_msec: int = 0
var external_input_vector: Vector2 = Vector2.ZERO

@onready var body_polygon: Polygon2D = $Body

func _ready() -> void:
	health = max_health
	xp_changed.emit(xp, xp_to_next, level)
	stats_changed.emit(health, max_health, level)

func _physics_process(_delta: float) -> void:
	var keyboard_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input_dir := keyboard_dir
	if external_input_vector.length() > keyboard_dir.length():
		input_dir = external_input_vector
	velocity = input_dir.limit_length(1.0) * speed
	move_and_slide()

func set_external_input_vector(direction: Vector2) -> void:
	external_input_vector = direction.limit_length(1.0)

func take_damage(amount: int) -> void:
	var now := Time.get_ticks_msec()
	if now < invulnerable_until_msec or health <= 0:
		return

	invulnerable_until_msec = now + 500
	health = max(0, health - amount)
	_flash(Color(1.0, 0.4, 0.4, 1.0), 0.12)
	stats_changed.emit(health, max_health, level)
	if health <= 0:
		died.emit()

func heal(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	health = min(max_health, health + amount)
	_flash(Color(0.45, 1.0, 0.7, 1.0), 0.12)
	stats_changed.emit(health, max_health, level)

func collect_xp(amount: int) -> void:
	xp += amount
	var leveled_up := false
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = int(round(xp_to_next * 1.35)) + 1
		leveled_up = true

	if leveled_up:
		health = min(max_health, health + 1)
		_flash(Color(0.5, 1.0, 0.6, 1.0), 0.15)

	xp_changed.emit(xp, xp_to_next, level)
	stats_changed.emit(health, max_health, level)

func _flash(color_value: Color, duration: float) -> void:
	if body_polygon == null:
		return
	var original := body_polygon.color
	body_polygon.color = color_value
	var tween := create_tween()
	tween.tween_property(body_polygon, "color", original, duration)
