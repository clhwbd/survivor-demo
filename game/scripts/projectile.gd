extends Area2D
class_name Projectile

@export var speed: float = 520.0
@export var damage: int = 1
@export var life_time: float = 1.2

var direction: Vector2 = Vector2.RIGHT

@onready var life_timer: Timer = $LifeTimer

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    life_timer.wait_time = life_time
    life_timer.timeout.connect(queue_free)
    life_timer.start()

func _physics_process(delta: float) -> void:
    global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
    if body != null and body.has_method("take_damage"):
        body.take_damage(damage)
        queue_free()
