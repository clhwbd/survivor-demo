extends CharacterBody2D
class_name EnemyBasic

signal died(enemy: EnemyBasic, position: Vector2)

@export var move_speed: float = 130.0
@export var contact_damage: int = 1
@export var max_health: int = 1
@export var target_path: NodePath

var target: Node2D
var health: int
var _last_hit_msec: int = 0

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
    if to_target.length_squared() <= 324.0:
        velocity = Vector2.ZERO
        var now := Time.get_ticks_msec()
        if now - _last_hit_msec >= 700:
            _last_hit_msec = now
            if target.has_method("take_damage"):
                target.take_damage(contact_damage)
    else:
        velocity = to_target.normalized() * move_speed

    move_and_slide()

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        died.emit(self, global_position)
        queue_free()
