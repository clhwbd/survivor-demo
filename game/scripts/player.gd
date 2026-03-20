extends CharacterBody2D

signal xp_changed(current_xp: int, xp_to_next: int, level: int)
signal xp_collected(amount: int, world_position: Vector2)
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
var _cape_base_rotation: float = 0.0
var _staff_base_rotation: float = 0.0
var _shadow_base_scale: Vector2 = Vector2.ONE
var _aura_base_scale: Vector2 = Vector2.ONE
var _face_base_position: Vector2 = Vector2.ZERO
var _eyes_base_position: Vector2 = Vector2.ZERO
var _brow_base_rotation: float = 0.0
var _skirt_base_position: Vector2 = Vector2.ZERO

@onready var aura_polygon: Polygon2D = get_node_or_null("Aura") as Polygon2D
@onready var body_polygon: Polygon2D = $Body
@onready var cape_polygon: Polygon2D = $Cape
@onready var headband_polygon: Polygon2D = $Headband
@onready var face_polygon: Polygon2D = get_node_or_null("Face") as Polygon2D
@onready var eyes_polygon: Polygon2D = get_node_or_null("Eyes") as Polygon2D
@onready var brow_polygon: Polygon2D = get_node_or_null("Brow") as Polygon2D
@onready var skirt_polygon: Polygon2D = get_node_or_null("Skirt") as Polygon2D
@onready var staff_polygon: Polygon2D = $Staff
@onready var shadow_polygon: Polygon2D = $Shadow

func _ready() -> void:
	health = max_health
	if cape_polygon != null:
		_cape_base_rotation = cape_polygon.rotation
	if staff_polygon != null:
		_staff_base_rotation = staff_polygon.rotation
	if shadow_polygon != null:
		_shadow_base_scale = shadow_polygon.scale
	if aura_polygon != null:
		_aura_base_scale = aura_polygon.scale
	if face_polygon != null:
		_face_base_position = face_polygon.position
	if eyes_polygon != null:
		_eyes_base_position = eyes_polygon.position
	if brow_polygon != null:
		_brow_base_rotation = brow_polygon.rotation
	if skirt_polygon != null:
		_skirt_base_position = skirt_polygon.position
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
	_update_visuals(delta, input_dir)
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
	scale = Vector2(1.18, 0.84)
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
	scale = Vector2(0.88, 1.12)
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
		var xp_growth := 1.24
		if level >= 5:
			xp_growth = 1.30
		if level >= 8:
			xp_growth = 1.34
		xp_to_next = int(round(float(xp_to_next) * xp_growth)) + 1
		leveled_up = true
		if level % 3 == 0 and max_health < 8:
			max_health += 1
		if level % 4 == 0:
			speed += 8.0

	if leveled_up:
		health = min(max_health, health + 2)
		_flash(Color(0.5, 1.0, 0.6, 1.0), 0.15)
		scale = Vector2(1.12, 0.9)

	xp_changed.emit(xp, xp_to_next, level)
	stats_changed.emit(health, max_health, level)
	xp_collected.emit(amount, global_position)

func _flash(color_value: Color, duration: float) -> void:
	if body_polygon == null:
		return
	var original := body_polygon.color
	body_polygon.color = color_value
	var tween := create_tween()
	tween.tween_property(body_polygon, "color", original, duration)

func _update_visuals(delta: float, input_dir: Vector2) -> void:
	var motion_dir := velocity.normalized() if velocity.length() > 0.0 else _last_move_direction
	if motion_dir == Vector2.ZERO:
		motion_dir = Vector2.DOWN
	var move_ratio := clampf(velocity.length() / maxf(1.0, dash_speed), 0.0, 1.0)
	var dash_ratio := clampf(_dash_remaining / maxf(0.01, dash_duration), 0.0, 1.0)
	var bob := sin(Time.get_ticks_msec() * (0.012 + move_ratio * 0.02))
	rotation = lerpf(rotation, motion_dir.x * 0.08 + dash_ratio * _dash_direction.x * 0.10, delta * 10.0)
	if shadow_polygon != null:
		shadow_polygon.scale = shadow_polygon.scale.lerp(_shadow_base_scale * Vector2(1.0 + move_ratio * 0.18, 1.0 - move_ratio * 0.10), delta * 8.0)
	if aura_polygon != null:
		aura_polygon.rotation = lerpf(aura_polygon.rotation, -motion_dir.x * 0.14 + bob * 0.04 + dash_ratio * 0.10, delta * 5.0)
		aura_polygon.scale = aura_polygon.scale.lerp(_aura_base_scale * Vector2(1.0 + move_ratio * 0.16 + dash_ratio * 0.10, 1.0 + move_ratio * 0.06), delta * 6.0)
		aura_polygon.color.a = lerpf(aura_polygon.color.a, 0.14 + move_ratio * 0.16 + dash_ratio * 0.18, delta * 6.0)
	if cape_polygon != null:
		cape_polygon.rotation = lerpf(cape_polygon.rotation, _cape_base_rotation - motion_dir.x * 0.30 - move_ratio * 0.26 + bob * 0.06 - dash_ratio * 0.16, delta * 8.0)
		cape_polygon.position.y = lerpf(cape_polygon.position.y, 2.0 + abs(motion_dir.y) * 1.6 + bob * 1.4 - dash_ratio * 2.0, delta * 8.0)
	if face_polygon != null:
		face_polygon.position = face_polygon.position.lerp(_face_base_position + Vector2(0.0, bob * 0.9 - dash_ratio * 1.6), delta * 7.5)
	if eyes_polygon != null:
		eyes_polygon.position = eyes_polygon.position.lerp(_eyes_base_position + Vector2(motion_dir.x * 1.2, bob * 0.35), delta * 9.0)
	if brow_polygon != null:
		brow_polygon.rotation = lerpf(brow_polygon.rotation, _brow_base_rotation - motion_dir.x * 0.08 - dash_ratio * 0.16, delta * 8.0)
	if skirt_polygon != null:
		skirt_polygon.position = skirt_polygon.position.lerp(_skirt_base_position + Vector2(0.0, abs(motion_dir.y) * 0.8 + bob * 0.8 + dash_ratio * 1.4), delta * 7.0)
	if staff_polygon != null:
		staff_polygon.rotation = lerpf(staff_polygon.rotation, _staff_base_rotation + motion_dir.x * 0.18 + move_ratio * 0.10 + dash_ratio * 0.22, delta * 9.0)
	if headband_polygon != null:
		headband_polygon.rotation = lerpf(headband_polygon.rotation, -motion_dir.x * 0.10 + bob * 0.05 + dash_ratio * 0.10, delta * 8.0)
	scale = scale.lerp(Vector2(1.0 + move_ratio * 0.08 + dash_ratio * 0.10, 1.0 - move_ratio * 0.06 - dash_ratio * 0.12), delta * 8.0)
