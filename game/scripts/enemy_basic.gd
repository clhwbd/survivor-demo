extends CharacterBody2D
class_name EnemyBasic

signal died(enemy: EnemyBasic, position: Vector2, xp_reward: int)
signal damaged(enemy: EnemyBasic, position: Vector2, remaining_health: int, max_health_value: int, was_elite: bool)

@export var move_speed: float = 130.0
@export var contact_damage: int = 1
@export var max_health: int = 1
@export var xp_reward: int = 1
@export var target_path: NodePath

var target: Node2D
var health: int
var _last_hit_msec: int = 0
var is_elite: bool = false
var elite_bonus_scale: float = 1.0
var _spawn_grace_remaining: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _body_base_scale: Vector2 = Vector2.ONE
var _shadow_base_scale: Vector2 = Vector2.ONE
var _ornament_base_rotation: float = 0.0
var _ornament_base_position: Vector2 = Vector2.ZERO

@onready var body_polygon: Polygon2D = $Body
@onready var shadow_polygon: Polygon2D = get_node_or_null("Shadow") as Polygon2D
@onready var ornament_polygon: Polygon2D = get_node_or_null("Crest") as Polygon2D

func _ready() -> void:
	health = max_health
	if target == null and not target_path.is_empty():
		target = get_node_or_null(target_path) as Node2D
	if body_polygon != null:
		_body_base_scale = body_polygon.scale
	if shadow_polygon != null:
		_shadow_base_scale = shadow_polygon.scale
	if ornament_polygon != null:
		_ornament_base_rotation = ornament_polygon.rotation
		_ornament_base_position = ornament_polygon.position
	for node_name in ["BackRibbon", "Mask", "Scarf", "Armor", "Crown"]:
		if ornament_polygon == null:
			ornament_polygon = get_node_or_null(node_name) as Polygon2D
			if ornament_polygon != null:
				_ornament_base_rotation = ornament_polygon.rotation
				_ornament_base_position = ornament_polygon.position
				break

func _physics_process(delta: float) -> void:
	if _spawn_grace_remaining > 0.0:
		_spawn_grace_remaining = maxf(0.0, _spawn_grace_remaining - delta)
		if body_polygon != null:
			body_polygon.modulate = Color(1.0, 1.0, 1.0, 0.55 + sin(Time.get_ticks_msec() * 0.015) * 0.18)
	elif body_polygon != null:
		body_polygon.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if target == null or not is_instance_valid(target):
		velocity = _knockback_velocity
		_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, delta * 10.0)
		move_and_slide()
		_update_visuals(delta)
		return

	var to_target := target.global_position - global_position
	var desired_velocity := Vector2.ZERO
	if to_target != Vector2.ZERO:
		desired_velocity = to_target.normalized() * move_speed
		if _spawn_grace_remaining > 0.0:
			desired_velocity *= 0.82

	var hit_distance_sq := 324.0
	if is_elite:
		hit_distance_sq = 484.0
	if _spawn_grace_remaining <= 0.0 and to_target.length_squared() <= hit_distance_sq:
		desired_velocity = Vector2.ZERO
		var now := Time.get_ticks_msec()
		var hit_cooldown := 700
		if is_elite:
			hit_cooldown = 520
		if now - _last_hit_msec >= hit_cooldown:
			_last_hit_msec = now
			if target.has_method("take_damage"):
				target.take_damage(contact_damage)

	velocity = desired_velocity + _knockback_velocity
	_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, delta * 11.0)
	move_and_slide()
	_update_visuals(delta)

func take_damage(amount: int) -> void:
	health -= amount
	var away := Vector2.ZERO
	if target != null and is_instance_valid(target):
		away = (global_position - target.global_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.UP
	_knockback_velocity = away * (70.0 + float(amount) * 42.0)
	_punch_scale()
	if is_elite:
		_flash(Color(1.0, 0.92, 0.35, 1.0), 0.10)
	else:
		_flash(Color(1.0, 1.0, 1.0, 1.0), 0.08)
	damaged.emit(self, global_position, max(0, health), max_health, is_elite)
	if health <= 0:
		died.emit(self, global_position, xp_reward)
		queue_free()

func make_elite(scale_bonus: float = 1.22) -> void:
	if is_elite:
		return
	is_elite = true
	elite_bonus_scale = scale_bonus
	move_speed = move_speed * 1.08
	max_health = maxi(max_health + 3, int(round(float(max_health) * 2.0)))
	health = max_health
	contact_damage += 1
	xp_reward = maxi(xp_reward + 3, xp_reward * 2)
	scale = Vector2.ONE * scale_bonus
	if body_polygon != null:
		body_polygon.color = Color(1.0, 0.72, 0.26, 1.0)

func set_spawn_grace(duration: float = 0.45) -> void:
	_spawn_grace_remaining = maxf(_spawn_grace_remaining, duration)

func _flash(color_value: Color, duration: float) -> void:
	if body_polygon == null:
		return
	var original := body_polygon.color
	body_polygon.color = color_value
	var tween := create_tween()
	tween.tween_property(body_polygon, "color", original, duration)

func _punch_scale() -> void:
	var base_scale := Vector2.ONE * elite_bonus_scale
	scale = base_scale * 1.08
	var tween := create_tween()
	tween.tween_property(self, "scale", base_scale, 0.10)

func _update_visuals(delta: float) -> void:
	var move_ratio := clampf(velocity.length() / maxf(1.0, move_speed * 1.6), 0.0, 1.0)
	var bob := sin(Time.get_ticks_msec() * (0.010 + move_ratio * 0.025) + float(get_instance_id() % 17))
	rotation = lerpf(rotation, clampf(velocity.normalized().x, -1.0, 1.0) * 0.08, delta * 8.0)
	if body_polygon != null:
		body_polygon.scale = body_polygon.scale.lerp(_body_base_scale * Vector2(1.0 + move_ratio * 0.05, 1.0 - move_ratio * 0.04), delta * 7.0)
	if shadow_polygon != null:
		shadow_polygon.scale = shadow_polygon.scale.lerp(_shadow_base_scale * Vector2(1.0 + move_ratio * 0.12, 1.0 - move_ratio * 0.08), delta * 7.0)
	if ornament_polygon != null:
		ornament_polygon.rotation = lerpf(ornament_polygon.rotation, _ornament_base_rotation - velocity.normalized().x * 0.12 + bob * 0.05, delta * 7.0)
		ornament_polygon.position = ornament_polygon.position.lerp(_ornament_base_position + Vector2(0.0, bob * 0.6), delta * 6.0)
