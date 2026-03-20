extends Label
class_name DamagePopup

@export var rise_distance: float = 36.0
@export var life_time: float = 0.45

func setup(text_value: String, color_value: Color) -> void:
    text = text_value
    modulate = color_value

func _ready() -> void:
    z_index = 50
    scale = Vector2(0.82, 0.82)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "position:y", position.y - rise_distance, life_time)
    tween.tween_property(self, "modulate:a", 0.0, life_time)
    tween.tween_property(self, "scale", Vector2(1.08, 1.08), life_time * 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.finished.connect(queue_free)
