extends Area2D
class_name XpOrb

@export var xp_value: int = 1
@export var magnet_distance: float = 110.0
@export var move_speed: float = 180.0
@export var rush_speed: float = 420.0

var target: Node2D
var _rushing: bool = false
var _trail_positions: Array[Vector2] = []
var _age: float = 0.0

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    _age += delta
    if target == null or not is_instance_valid(target):
        return

    var to_target := target.global_position - global_position
    var dist := to_target.length()

    if dist <= magnet_distance * 0.55 or _rushing:
        # Rush phase: accelerate toward player, don't just drift
        _rushing = true
        var speed := rush_speed
        if dist <= 28.0:
            speed = rush_speed * 2.2
        elif dist <= 60.0:
            speed = rush_speed * 1.6
        global_position += to_target.normalized() * speed * delta
    elif dist <= magnet_distance:
        # Attract phase: gentle pull-in
        _rushing = false
        global_position += to_target.normalized() * move_speed * delta
    else:
        _rushing = false

func _on_body_entered(body: Node) -> void:
    if body != null and body.has_method("collect_xp"):
        body.collect_xp(xp_value)
        queue_free()
