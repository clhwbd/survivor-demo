extends CharacterBody2D

signal xp_changed(current_xp: int, xp_to_next: int, level: int)
signal stats_changed(health: int, max_health: int, level: int)
signal died
signal dash_state_changed(is_ready: bool, cooldown_remaining: float, is_dashing: bool)

@export var speed: float = 240.0
@export var max_health: int = 5
@export var dash_speed: float = 560.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 1.35

var health: int
var level: int = 1
var xp: int = 0
var xp_to_next: int = 5
var invulnerable_until_msec: int = 0
var external_input_vector: Vector2 = Vector2.ZERO
var _dash_remaining: float = 0.0
var _dash_cooldown_remaining: float = 0.0
var _dash_direction: Vector2 = Vector2.RIGHT
var _last_move_direction: Vector2 = Vector2.DOWN

@onready var body_polygon: Polygon2D = $Body

func _ready() -> void:
	health = max_health
	xp_changed.emit(xp, xp_to_next, level)
	stats_changed.emit(health, max_health, level)
	dash_state_changed.emit(true, 0.0, false)

func _physics_process(delta: float) -> void:
	var keyboard_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input_dir := keyboard_dir
	if external_input_vector.length() > keyboard_dir.length():
		input_dir = external_input_vector
	input_dir = input_dir.limit_length(1.0)
	if input_dir.length() > 0.0:
		_last_move_direction = input_dir

	if _dash_cooldown_remaining > 0.0:
		_dash_cooldown_remaining = maxf(0.0, _dash_cooldown_remaining - delta)

	if Input.is_action_just_pressed("dash_run"):
		request_dash(input_dir)

	if _dash_remaining > 0.0:
		_dash_remaining = maxf(0.0, _dash_remaining - delta)
		velocity = _dash_direction * dash_speed
	else:
		velocity = input_dir * speed

	move_and_slide()
	dash_state_changed.emit(_dash_cooldown_remaining <= 0.0, _dash_cooldown_remaining, _dash_remaining > 0.0)

func set_external_input_vector(direction: Vector2) -> void:
	external_input_vector = direction.limit_length(1.0)

func request_dash(preferred_direction: Vector2 = Vector2.ZERO) -> bool:
	if health <= 0 or _dash_remaining > 0.0 or _dash_cooldown_remaining > 0.0:
		return false

	var dash_dir := preferred_direction.limit_length(1.0)
	if dash_dir == Vector2.ZERO:
		var keyboard_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var input_dir := keyboard_dir
		if external_input_vector.length() > keyboard_dir.length():
			input_dir = external_input_vector
		dash_dir = input_dir.limit_length(1.0)
	if dash_dir == Vector2.ZERO:
		dash_dir = _last_move_direction.limit_length(1.0)
	if dash_dir == Vector2.ZERO:
		return false

	_dash_direction = dash_dir
	_last_move_direction = dash_dir
	_dash_remaining = dash_duration
	_dash_cooldown_remaining = dash_cooldown
	invulnerable_until_msec = max(invulnerable_until_msec, Time.get_ticks_msec() + int(dash_duration * 1000.0) + 80)
	_flash(Color(1.0, 0.95, 0.6, 1.0), 0.10)
	dash_state_changed.emit(false, _dash_cooldown_remaining, true)
	return true

func is_dashing() -> bool:
	return _dash_remaining > 0.0

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
