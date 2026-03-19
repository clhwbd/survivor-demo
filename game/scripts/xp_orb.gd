extends Area2D
class_name XpOrb

@export var xp_value: int = 1
@export var magnet_distance: float = 110.0
@export var move_speed: float = 180.0

var target: Node2D

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    if target == null or not is_instance_valid(target):
        return

    var to_target := target.global_position - global_position
    if to_target.length() <= magnet_distance:
        global_position += to_target.normalized() * move_speed * delta

func _on_body_entered(body: Node) -> void:
    if body != null and body.has_method("collect_xp"):
        body.collect_xp(xp_value)
        queue_free()
