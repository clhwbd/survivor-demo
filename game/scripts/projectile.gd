extends Area2D
class_name Projectile

@export var speed: float = 520.0
@export var damage: int = 1
@export var life_time: float = 1.2
@export var pierce: int = 0

var direction: Vector2 = Vector2.RIGHT
var _hit_bodies: Array[int] = []

@onready var life_timer: Timer = $LifeTimer
@onready var body_polygon: Polygon2D = $Body

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	life_timer.wait_time = life_time
	life_timer.timeout.connect(queue_free)
	life_timer.start()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	rotation = direction.angle() + sin(Time.get_ticks_msec() * 0.03) * 0.08
	if body_polygon != null:
		body_polygon.scale = body_polygon.scale.lerp(Vector2(1.0 + speed / 1200.0, 1.0), delta * 10.0)

func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_method("take_damage"):
		return

	var body_id := body.get_instance_id()
	if body_id in _hit_bodies:
		return
	_hit_bodies.append(body_id)

	body.take_damage(damage)
	if pierce <= 0:
		queue_free()
	else:
		pierce -= 1
