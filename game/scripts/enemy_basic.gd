extends CharacterBody2D
class_name EnemyBasic

signal died(enemy: EnemyBasic, position: Vector2, xp_reward: int)

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

@onready var body_polygon: Polygon2D = $Body

func _ready() -> void:
	health = max_health
	if target == null and not target_path.is_empty():
		target = get_node_or_null(target_path) as Node2D

func _physics_process(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target := target.global_position - global_position
	var hit_distance_sq := 324.0
	if is_elite:
		hit_distance_sq = 484.0
	if to_target.length_squared() <= hit_distance_sq:
		velocity = Vector2.ZERO
		var now := Time.get_ticks_msec()
		var hit_cooldown := 700
		if is_elite:
			hit_cooldown = 520
		if now - _last_hit_msec >= hit_cooldown:
			_last_hit_msec = now
			if target.has_method("take_damage"):
				target.take_damage(contact_damage)
	else:
		velocity = to_target.normalized() * move_speed

	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if is_elite:
		_flash(Color(1.0, 0.92, 0.35, 1.0), 0.10)
	else:
		_flash(Color(1.0, 1.0, 1.0, 1.0), 0.08)
	if health <= 0:
		died.emit(self, global_position, xp_reward)
		queue_free()

func make_elite(scale_bonus: float = 1.22) -> void:
	if is_elite:
		return
	is_elite = true
	elite_bonus_scale = scale_bonus
	move_speed = move_speed * 1.10
	max_health = maxi(max_health + 3, int(round(float(max_health) * 2.2)))
	health = max_health
	contact_damage += 1
	xp_reward = maxi(xp_reward + 3, xp_reward * 2)
	scale = Vector2.ONE * scale_bonus
	if body_polygon != null:
		body_polygon.color = Color(1.0, 0.72, 0.26, 1.0)

func _flash(color_value: Color, duration: float) -> void:
	if body_polygon == null:
		return
	var original := body_polygon.color
	body_polygon.color = color_value
	var tween := create_tween()
	tween.tween_property(body_polygon, "color", original, duration)
